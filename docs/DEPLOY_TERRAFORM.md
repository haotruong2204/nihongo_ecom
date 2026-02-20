# Deploy Rails Backend lên AWS ECS (Terraform)

> **Lưu ý:** Guide này dành cho khi cần scale lên kiến trúc production cao cấp.
> Chi phí ước tính: **~$183/tháng**. Với traffic < 10,000 visits/ngày, dùng Lightsail ($5/tháng) — xem `DEPLOY_LIGHTSAIL.md`.

## Tổng quan kiến trúc

```
Internet → ALB (HTTPS) → ECS Fargate (Rails) → RDS MySQL + ElastiCache Redis
                                                      ↕
                                               Private Subnets
                                               NAT Gateway (outbound)
```

### AWS Resources

| Resource | Spec | Chi phí/tháng |
|----------|------|--------------|
| ECS Fargate | 2 tasks × 1vCPU + 2GB | ~$82 |
| NAT Gateway | 1 + Elastic IP | ~$37 |
| RDS MySQL | db.t3.micro, 20GB gp2 | ~$28 |
| ALB | Application Load Balancer | ~$21 |
| ElastiCache Redis | cache.t3.micro | ~$9 |
| CloudWatch | Logs + Container Insights | ~$3 |
| Misc (data transfer) | | ~$5 |
| **Tổng** | | **~$183** |

---

## Prerequisites

1. **AWS Account** với IAM user có quyền (ECS, RDS, VPC, ALB, ElastiCache, S3, ECR, IAM)
2. **AWS CLI** đã cài và config
3. **Terraform** >= 1.0
4. **Docker** (để build image)

```bash
# Verify tools
aws --version
terraform --version
docker --version
```

---

## Bước 1: Setup AWS Resources cơ bản

### 1.1. Chạy setup script

```bash
cd /Users/haotruong/Desktop/nihongo_ecom
./scripts/setup-aws.sh
```

Script sẽ tạo:
- **S3 bucket** — lưu Terraform state
- **DynamoDB table** — state locking
- **ECR repository** — lưu Docker images

### 1.2. Config Terraform backend

Sửa `terraform/main.tf`, uncomment và điền giá trị từ output của script:

```hcl
backend "s3" {
  bucket         = "nihongo-ecom-terraform-state"     # Từ script output
  key            = "nihongo-ecom/terraform.tfstate"
  region         = "ap-southeast-1"                    # Đổi sang Singapore
  dynamodb_table = "nihongo-ecom-terraform-locks"      # Từ script output
}
```

### 1.3. Tạo terraform.tfvars

```bash
cp terraform/terraform.tfvars terraform/terraform.tfvars.local
```

Sửa `terraform/terraform.tfvars.local`:

```hcl
# Region
aws_region   = "ap-southeast-1"     # Singapore — gần VN
environment  = "production"
project_name = "nihongo-ecom"

# Network
vpc_cidr = "10.0.0.0/16"

# App
app_port       = 3000
app_count      = 1                   # Bắt đầu 1 task, scale sau
fargate_cpu    = "512"               # 0.5 vCPU (tiết kiệm)
fargate_memory = "1024"              # 1GB RAM

# Database
db_instance_class = "db.t3.micro"
db_name           = "nihongo_ecom_production"
db_username       = "nihongo"
db_password       = "CHANGE_ME"      # openssl rand -base64 24

# Rails
rails_master_key = "CHANGE_ME"       # cat config/master.key

# SSL (thêm sau khi có certificate)
# domain_name     = "api.nhaikanji.com"
# certificate_arn = "arn:aws:acm:..."
```

> **Tip tiết kiệm:** `app_count = 1` + `fargate_cpu = 512` + `fargate_memory = 1024` giảm từ ~$82 xuống ~$30/tháng cho Fargate.

---

## Bước 2: Provision Infrastructure

### 2.1. Init & Plan

```bash
cd terraform

terraform init

terraform plan -var-file="terraform.tfvars.local"
```

Review plan kỹ — xác nhận resources sẽ tạo:
- 1 VPC + 4 subnets + 1 NAT Gateway
- 1 ECS Cluster + Task Definition + Service
- 1 RDS MySQL instance
- 1 ElastiCache Redis
- 1 ALB + Target Group
- 4 Security Groups
- IAM Roles

### 2.2. Apply

```bash
terraform apply -var-file="terraform.tfvars.local"
```

Nhập `yes` để confirm. Đợi **~10-15 phút** (RDS mất lâu nhất).

### 2.3. Lưu outputs

```bash
terraform output
```

Ghi lại:
- `alb_hostname` — URL của ALB
- `database_endpoint` — RDS endpoint
- `redis_endpoint` — Redis endpoint
- `ecs_cluster_name` — tên ECS cluster
- `ecs_service_name` — tên ECS service

---

## Bước 3: Build & Push Docker Image

### 3.1. Login ECR

```bash
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-southeast-1.amazonaws.com
```

### 3.2. Build & Push

```bash
cd /Users/haotruong/Desktop/nihongo_ecom

# Build production image
docker build -t nihongo-ecom .

# Tag
docker tag nihongo-ecom:latest \
  <ACCOUNT_ID>.dkr.ecr.ap-southeast-1.amazonaws.com/nihongo-ecom:latest

# Push
docker push <ACCOUNT_ID>.dkr.ecr.ap-southeast-1.amazonaws.com/nihongo-ecom:latest
```

### 3.3. Update ECS Task Definition

Sửa container image trong `terraform/ecs.tf`:

```hcl
image = "<ACCOUNT_ID>.dkr.ecr.ap-southeast-1.amazonaws.com/nihongo-ecom:latest"
```

Rồi apply lại:

```bash
cd terraform
terraform apply -var-file="terraform.tfvars.local"
```

---

## Bước 4: Database Migration

### 4.1. Chạy migration qua ECS run-task

```bash
# Lấy task definition revision
TASK_DEF=$(aws ecs describe-services \
  --cluster nihongo-ecom \
  --services nihongo-ecom \
  --query 'services[0].taskDefinition' --output text)

# Lấy subnet + security group
SUBNET=$(terraform output -raw private_subnet_ids | cut -d',' -f1)
SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=nihongo-ecom-ecs-tasks-sg*" \
  --query 'SecurityGroups[0].GroupId' --output text)

# Chạy migration
aws ecs run-task \
  --cluster nihongo-ecom \
  --task-definition "$TASK_DEF" \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=DISABLED}" \
  --overrides '{"containerOverrides":[{"name":"nihongo-ecom","command":["bin/rails","db:create","db:migrate"]}]}'
```

### 4.2. Verify migration

```bash
# Xem logs của task vừa chạy
aws logs tail /ecs/nihongo-ecom --follow
```

---

## Bước 5: SSL & Domain

### 5.1. Request SSL Certificate (ACM)

```bash
aws acm request-certificate \
  --region ap-southeast-1 \
  --domain-name api.nhaikanji.com \
  --validation-method DNS
```

### 5.2. DNS Validation

ACM sẽ cho CNAME record → thêm vào Cloudflare DNS để validate.

```bash
# Xem CNAME cần thêm
aws acm describe-certificate \
  --certificate-arn <CERT_ARN> \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord'
```

Vào Cloudflare → DNS → Add CNAME record theo output trên.

Đợi vài phút cho certificate status = `ISSUED`.

### 5.3. Update Terraform với SSL

Sửa `terraform.tfvars.local`:

```hcl
domain_name     = "api.nhaikanji.com"
certificate_arn = "arn:aws:acm:ap-southeast-1:<ACCOUNT_ID>:certificate/<CERT_ID>"
```

```bash
terraform apply -var-file="terraform.tfvars.local"
```

### 5.4. Point domain tới ALB

Cloudflare DNS:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| CNAME | api | `<alb_hostname>` (từ terraform output) | DNS only |

### 5.5. Verify

```bash
curl https://api.nhaikanji.com/health
```

---

## Bước 6: CI/CD (GitHub Actions)

### 6.1. GitHub Secrets

Vào repo → Settings → Secrets → Actions, thêm:

| Secret | Giá trị |
|--------|---------|
| `AWS_ACCESS_KEY_ID` | IAM access key |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key |
| `DB_PASSWORD` | MySQL password |
| `RAILS_MASTER_KEY` | Từ `config/master.key` |

### 6.2. Workflow file

Tạo `.github/workflows/deploy.yml`:

```yaml
name: Deploy to ECS

on:
  push:
    branches: [main]

env:
  AWS_REGION: ap-southeast-1
  ECR_REPOSITORY: nihongo-ecom
  ECS_CLUSTER: nihongo-ecom
  ECS_SERVICE: nihongo-ecom

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: password
          MYSQL_DATABASE: nihongo_ecom_test
        ports: ["3306:3306"]
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=5
      redis:
        image: redis:7-alpine
        ports: ["6379:6379"]
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3.4
          bundler-cache: true
      - name: Run tests
        env:
          DATABASE_URL: mysql2://root:password@127.0.0.1:3306/nihongo_ecom_test
          REDIS_URL: redis://localhost:6379
          RAILS_ENV: test
        run: |
          bin/rails db:create db:migrate
          bundle exec rspec

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag, and push image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:latest .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster $ECS_CLUSTER \
            --service $ECS_SERVICE \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster $ECS_CLUSTER \
            --services $ECS_SERVICE
```

---

## Monitoring & Operations

### Xem logs

```bash
# Realtime logs
aws logs tail /ecs/nihongo-ecom --follow

# Filter errors
aws logs filter-log-events \
  --log-group-name /ecs/nihongo-ecom \
  --filter-pattern "ERROR"
```

### Scale manually

```bash
# Scale lên 3 tasks
aws ecs update-service \
  --cluster nihongo-ecom \
  --service nihongo-ecom \
  --desired-count 3
```

### Database backup (manual snapshot)

```bash
aws rds create-db-snapshot \
  --db-instance-identifier nihongo-ecom-db \
  --db-snapshot-identifier nihongo-ecom-backup-$(date +%Y%m%d)
```

### Rollback deployment

```bash
# Rollback về task definition revision trước
aws ecs update-service \
  --cluster nihongo-ecom \
  --service nihongo-ecom \
  --task-definition nihongo-ecom:<PREVIOUS_REVISION>
```

---

## Destroy Infrastructure

> **Cẩn thận:** Lệnh này xóa TẤT CẢ resources bao gồm database!

```bash
# Backup database trước
aws rds create-db-snapshot \
  --db-instance-identifier nihongo-ecom-db \
  --db-snapshot-identifier nihongo-ecom-final-backup

# Destroy
cd terraform
terraform destroy -var-file="terraform.tfvars.local"
```

---

## Tối ưu chi phí

### Giảm từ ~$183 xuống ~$100/tháng

| Thay đổi | Tiết kiệm |
|----------|-----------|
| `app_count = 1` (1 task thay vì 2) | -$41 |
| `fargate_cpu = 512`, `fargate_memory = 1024` | -$20 |
| NAT Instance thay NAT Gateway | -$25 |

### Khi nào nên dùng Terraform/ECS

- Traffic > 10,000 visits/ngày
- Cần auto-scaling (tự tăng/giảm tasks)
- Cần multi-AZ high availability
- Cần managed database (RDS auto-backup, failover)
- Team > 2 developers, cần CI/CD pipeline

### Khi nào nên dùng Lightsail

- Traffic < 10,000 visits/ngày
- 1 developer / side project
- Budget < $20/tháng
- Xem `DEPLOY_LIGHTSAIL.md`

---

## File Reference

```
terraform/
├── main.tf               # VPC, subnets, NAT Gateway, Internet Gateway
├── variables.tf           # Tất cả biến config
├── terraform.tfvars       # Template giá trị (committed, không chứa secrets)
├── terraform.tfvars.local # Giá trị thực (gitignored, chứa passwords)
├── ecs.tf                 # ECS Cluster, Task Definition, Service, IAM
├── database.tf            # RDS MySQL, ElastiCache Redis
├── load_balancer.tf       # ALB, Target Group, Listeners
├── security_groups.tf     # Security Groups (ALB, ECS, RDS, Redis)
└── outputs.tf             # Output values sau khi apply

scripts/
├── setup-aws.sh           # Tạo S3 + DynamoDB + ECR ban đầu
└── deploy.sh              # Deploy script (Lightsail)

.github/workflows/
└── deploy.yml             # CI/CD pipeline (GitHub Actions → ECS)
```
