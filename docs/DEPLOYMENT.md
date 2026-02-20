# Nihongo E-commerce Deployment Guide

## Production Deployment với Terraform và GitHub Actions

### Prerequisites

1. **AWS Account** với appropriate permissions
2. **GitHub Repository** với secrets được config
3. **Domain name** (optional) cho SSL
4. **Terraform** và **AWS CLI** installed locally

### 1. Setup AWS Infrastructure

#### Bước 1: Tạo AWS resources cơ bản

```bash
# Run script để setup S3 bucket, DynamoDB table, ECR repository
./scripts/setup-aws.sh
```

#### Bước 2: Cấu hình Terraform backend

Cập nhật file `terraform/main.tf`:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "nihongo-ecom/terraform.tfstate"
  region         = "us-west-2"
  dynamodb_table = "nihongo-ecom-terraform-locks"
}
```

#### Bước 3: Cấu hình variables

```bash
# Copy và chỉnh sửa file variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Cập nhật các giá trị trong terraform.tfvars
vim terraform/terraform.tfvars
```

### 2. GitHub Secrets Configuration

Thêm các secrets sau trong GitHub repository:

```
AWS_ACCESS_KEY_ID          # AWS access key
AWS_SECRET_ACCESS_KEY      # AWS secret key
DB_PASSWORD               # Database password (strong password)
RAILS_MASTER_KEY          # Rails credentials master key
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan

# Apply infrastructure
terraform apply
```

### 4. GitHub Actions Workflow

Workflow tự động chạy khi:

- **Pull Request**: Chạy tests và terraform plan
- **Push to main**: Deploy to production

#### Workflow steps:

1. **Test**: Chạy RSpec tests
2. **Security**: Chạy Brakeman và bundle audit
3. **Build**: Build Docker image và push lên ECR
4. **Deploy**: Update ECS service với image mới
5. **Migrate**: Chạy database migrations

### 5. Monitoring và Logs

#### Application Logs

```bash
# Xem logs trên CloudWatch
aws logs tail /ecs/nihongo-ecom --follow

# Hoặc từ ECS console
# https://console.aws.amazon.com/ecs/
```

#### Database

- **RDS Dashboard**: https://console.aws.amazon.com/rds/
- **Performance Insights**: Enable trong RDS configuration

#### Application Load Balancer

- **ALB Dashboard**: https://console.aws.amazon.com/ec2/v2/home#LoadBalancers

### 6. SSL/HTTPS Setup (Optional)

#### Bước 1: Request SSL Certificate

```bash
# Request certificate trong AWS Certificate Manager
aws acm request-certificate \
  --domain-name yourdomain.com \
  --domain-name www.yourdomain.com \
  --validation-method DNS
```

#### Bước 2: Update Terraform variables

```hcl
domain_name = "yourdomain.com"
certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

#### Bước 3: Update DNS

Point your domain to ALB DNS name:

```
yourdomain.com -> your-alb-dns-name.us-west-2.elb.amazonaws.com
```

### 7. Scaling Configuration

#### Auto Scaling

Cập nhật trong `terraform/ecs.tf`:

```hcl
# ECS Service Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
```

#### Database Scaling

- Enable **Multi-AZ** cho high availability
- Configure **Read Replicas** nếu cần
- Set up **Performance Insights**

### 8. Backup Strategy

#### Database Backups

- **Automated backups**: 7 days retention (configured in Terraform)
- **Manual snapshots**: Tạo trước khi deploy major changes

#### Application Data

- **EFS volumes** cho persistent data nếu cần
- **S3 backups** cho uploaded files

### 9. Security Best Practices

#### Network Security

- **Private subnets** cho database và application
- **Security groups** với least privilege
- **VPC endpoints** cho AWS services

#### Application Security

- **Secrets management** qua AWS Secrets Manager
- **IAM roles** với minimal permissions
- **Security scanning** trong CI/CD pipeline

### 10. Cost Optimization

#### Right-sizing

- Monitor **CloudWatch metrics**
- Adjust **Fargate CPU/Memory** based on usage
- Use **Spot instances** cho non-critical workloads

#### Storage

- **S3 lifecycle policies** cho logs
- **RDS storage auto-scaling**

### 11. Troubleshooting

#### Deployment Issues

```bash
# Check GitHub Actions logs
# Check ECS service events
aws ecs describe-services --cluster nihongo-ecom --services nihongo-ecom

# Check task definition
aws ecs describe-task-definition --task-definition nihongo-ecom
```

#### Database Issues

```bash
# Connect to RDS
mysql -h your-rds-endpoint -u admin -p

# Check RDS logs
aws rds describe-db-log-files --db-instance-identifier nihongo-ecom-db
```

#### Application Issues

```bash
# Check ECS tasks
aws ecs list-tasks --cluster nihongo-ecom --service-name nihongo-ecom

# Get task logs
aws logs get-log-events --log-group-name /ecs/nihongo-ecom --log-stream-name <stream-name>
```

### 12. Rolling Back

#### Application Rollback

```bash
# Rollback to previous task definition
aws ecs update-service \
  --cluster nihongo-ecom \
  --service nihongo-ecom \
  --task-definition nihongo-ecom:PREVIOUS_REVISION
```

#### Infrastructure Rollback

```bash
# Terraform rollback
terraform apply -target=specific_resource
```

### 13. Useful Commands

```bash
# Check deployment status
aws ecs describe-services --cluster nihongo-ecom --services nihongo-ecom

# Scale service manually
aws ecs update-service --cluster nihongo-ecom --service nihongo-ecom --desired-count 3

# Run one-off tasks (migrations, etc)
aws ecs run-task --cluster nihongo-ecom --task-definition nihongo-ecom:REVISION

# Update environment variables
# Update task definition và deploy lại
```

## Development vs Production

| Aspect         | Development              | Production                |
| -------------- | ------------------------ | ------------------------- |
| Docker Compose | `docker-compose.dev.yml` | `docker-compose.prod.yml` |
| Database       | Local MySQL              | RDS MySQL                 |
| Redis          | Local Redis              | ElastiCache               |
| Load Balancer  | None                     | Application Load Balancer |
| SSL            | None                     | ACM Certificate           |
| Scaling        | Single instance          | Auto Scaling              |
| Logs           | Local                    | CloudWatch                |
| Backups        | None                     | Automated                 |
