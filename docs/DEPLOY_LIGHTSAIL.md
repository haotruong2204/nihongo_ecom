# Deploy Rails Backend lên AWS Lightsail

## Tổng quan

Deploy `nihongo_ecom` (Rails 8 API) lên AWS Lightsail $5/tháng bằng Docker Compose.

```
Internet → Cloudflare (DNS) → Lightsail (Nginx → Rails + MySQL + Redis)
```

**Chi phí:** $5/tháng (1GB RAM, 1vCPU, 40GB SSD, 2TB transfer)

---

## Bước 1: Tạo Lightsail Instance

### 1.1. Vào AWS Console

1. Truy cập [AWS Lightsail Console](https://lightsail.aws.amazon.com)
2. Click **"Create instance"**
3. Chọn:
   - **Region:** `ap-southeast-1` (Singapore — gần VN nhất)
   - **Platform:** Linux/Unix
   - **Blueprint:** OS Only → **Ubuntu 24.04 LTS**
   - **Instance plan:** $5/month (1GB RAM, 1vCPU, 40GB SSD)
   - **Instance name:** `nihongo-api`
4. Click **"Create instance"**

### 1.2. Gán Static IP

1. Vào tab **Networking** của instance
2. Click **"Create static IP"**
3. Đặt tên: `nihongo-api-ip`
4. Attach vào instance `nihongo-api`
5. **Ghi lại IP** (ví dụ: `13.xxx.xxx.xxx`)

### 1.3. Mở port

Trong tab **Networking** → Firewall, thêm rules:

| Port | Protocol | Mô tả |
|------|----------|-------|
| 22   | TCP      | SSH (có sẵn) |
| 80   | TCP      | HTTP |
| 443  | TCP      | HTTPS |

---

## Bước 2: Setup Server

### 2.1. SSH vào instance

```bash
# Dùng Lightsail browser terminal hoặc:
ssh -i ~/.ssh/LightsailDefaultKey-ap-southeast-1.pem ubuntu@<STATIC_IP>
```

Hoặc download SSH key từ Lightsail Console → Account → SSH keys.

### 2.2. Cài Docker & Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Cài Docker
curl -fsSL https://get.docker.com | sudo sh

# Thêm user ubuntu vào docker group
sudo usermod -aG docker ubuntu

# Logout rồi login lại để group có hiệu lực
exit
```

SSH lại vào, verify:

```bash
docker --version          # Docker version 27.x
docker compose version    # Docker Compose version v2.x
```

### 2.3. Tạo swap (quan trọng cho 1GB RAM)

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Persist qua reboot
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Tối ưu swap
sudo sysctl vm.swappiness=10
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf

# Verify
free -h
# → Swap: 2.0G
```

---

## Bước 3: Deploy Application

### 3.1. Clone repo lên server

```bash
cd /home/ubuntu

# Nếu repo private, tạo deploy key trước
ssh-keygen -t ed25519 -C "lightsail-deploy" -f ~/.ssh/deploy_key -N ""
cat ~/.ssh/deploy_key.pub
# → Copy public key → GitHub repo → Settings → Deploy keys → Add

cat >> ~/.ssh/config << 'EOF'
Host github.com
  IdentityFile ~/.ssh/deploy_key
  StrictHostKeyChecking no
EOF

# Clone
git clone git@github.com:<username>/nihongo_ecom.git
cd nihongo_ecom
```

### 3.2. Tạo file .env production

```bash
cat > .env.production << 'ENVFILE'
# Database
DATABASE_URL=mysql2://nihongo:CHANGE_ME_DB_PASSWORD@db:3306/nihongo_ecom_production
NIHONGO_ECOM_DATABASE_PASSWORD=CHANGE_ME_DB_PASSWORD
DB_USER=nihongo
NIHONGO_ECOM_HOST=db
DB_PORT=3306

# App
RAILS_ENV=production
RACK_ENV=production
APP_HOST=api.nhaikanji.com
APP_URL=https://api.nhaikanji.com

# Redis
REDIS_URL=redis://redis:6379

# Secrets (generate bên dưới)
DEVISE_JWT_SECRET_KEY=CHANGE_ME
SECRET_KEY_BASE=CHANGE_ME
RAILS_MASTER_KEY=CHANGE_ME

# Logging
RAILS_LOG_LEVEL=info
RAILS_SERVE_STATIC_FILES=false

# CORS
CORS_ORIGINS=https://nhaikanji.com,https://admin.nhaikanji.com
ENVFILE
```

**Generate secrets rồi paste vào file:**

```bash
# Generate từng secret
echo "DEVISE_JWT_SECRET_KEY: $(openssl rand -hex 64)"
echo "SECRET_KEY_BASE: $(openssl rand -hex 64)"
echo "DB_PASSWORD: $(openssl rand -base64 24)"

# RAILS_MASTER_KEY: copy từ máy local
# → cat config/master.key (trên máy dev)

# Sửa file .env.production, thay CHANGE_ME bằng giá trị vừa generate
nano .env.production
```

### 3.3. Build và start

```bash
# Build images
docker compose -f docker-compose.lightsail.yml build

# Start DB + Redis trước
docker compose -f docker-compose.lightsail.yml up -d db redis

# Đợi MySQL ready (~30s)
sleep 30
docker compose -f docker-compose.lightsail.yml exec db mysqladmin ping -unihongo -p

# Tạo DB + chạy migrations
docker compose -f docker-compose.lightsail.yml run --rm web bin/rails db:create db:migrate

# Start toàn bộ
docker compose -f docker-compose.lightsail.yml up -d

# Verify
curl http://localhost/health
```

---

## Bước 4: Setup Domain & SSL

### 4.1. Cloudflare DNS

Vào Cloudflare Dashboard → DNS → Add record:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A    | api  | `<STATIC_IP>` | **DNS only** (grey cloud) |

> Tắt Cloudflare proxy cho API subdomain — tránh conflict SSL.

### 4.2. SSL với Let's Encrypt

```bash
# Cài certbot
sudo apt install -y certbot

# Stop nginx tạm
docker compose -f docker-compose.lightsail.yml stop nginx

# Lấy certificate
sudo certbot certonly --standalone -d api.nhaikanji.com \
  --email your-email@gmail.com --agree-tos --no-eff-email

# Copy cert vào project
mkdir -p nginx/ssl
sudo cp /etc/letsencrypt/live/api.nhaikanji.com/fullchain.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/api.nhaikanji.com/privkey.pem nginx/ssl/
sudo chown -R ubuntu:ubuntu nginx/ssl/

# Start lại toàn bộ
docker compose -f docker-compose.lightsail.yml up -d
```

### 4.3. Auto-renew SSL (cron)

```bash
(sudo crontab -l 2>/dev/null; echo "0 2 1,15 * * cd /home/ubuntu/nihongo_ecom && docker compose -f docker-compose.lightsail.yml stop nginx && certbot renew --quiet && cp /etc/letsencrypt/live/api.nhaikanji.com/fullchain.pem nginx/ssl/ && cp /etc/letsencrypt/live/api.nhaikanji.com/privkey.pem nginx/ssl/ && docker compose -f docker-compose.lightsail.yml up -d nginx") | sudo crontab -
```

### 4.4. Verify

```bash
curl https://api.nhaikanji.com/health
```

---

## Bước 5: Deploy lần tiếp theo

Mỗi lần update code:

```bash
ssh ubuntu@<STATIC_IP>
cd /home/ubuntu/nihongo_ecom
./scripts/deploy.sh
```

Hoặc manual:

```bash
git pull origin main
docker compose -f docker-compose.lightsail.yml build web
docker compose -f docker-compose.lightsail.yml up -d web sidekiq
docker compose -f docker-compose.lightsail.yml exec web bin/rails db:migrate
```

---

## Bước 6: Monitoring

### Xem logs

```bash
docker compose -f docker-compose.lightsail.yml logs -f web        # Rails
docker compose -f docker-compose.lightsail.yml logs -f nginx      # Nginx
docker compose -f docker-compose.lightsail.yml logs -f db         # MySQL
```

### Rails console

```bash
docker compose -f docker-compose.lightsail.yml exec web bin/rails console
```

### Resource usage

```bash
docker stats --no-stream
free -h
df -h
```

### Backup Database (auto hàng ngày)

```bash
mkdir -p /home/ubuntu/backups

(crontab -l 2>/dev/null; echo '0 3 * * * docker compose -f /home/ubuntu/nihongo_ecom/docker-compose.lightsail.yml exec -T db mysqldump -unihongo -p"$NIHONGO_ECOM_DATABASE_PASSWORD" nihongo_ecom_production 2>/dev/null | gzip > /home/ubuntu/backups/db_$(date +\%Y\%m\%d).sql.gz && find /home/ubuntu/backups -name "*.sql.gz" -mtime +7 -delete') | crontab -
```

---

## Troubleshooting

| Vấn đề | Giải pháp |
|--------|----------|
| Rails không start | `docker compose logs web --tail 50` |
| MySQL connection refused | `docker compose logs db` — đợi healthy |
| Out of memory | `free -h` — tăng swap hoặc nâng plan $10 |
| SSL hết hạn | `sudo certbot renew` + copy cert lại |
| Disk full | `docker system prune -af` — dọn images cũ |

---

## Nâng cấp instance

Nếu cần thêm RAM: Lightsail → Instance → Snapshot → Tạo instance mới từ snapshot với plan $10/month (2GB RAM).

---

## Chi phí tổng kết

| Mục | Chi phí |
|-----|---------|
| Lightsail $5 plan | $5/tháng |
| Static IP | Free |
| SSL (Let's Encrypt) | Free |
| Domain DNS (Cloudflare) | Free |
| **Tổng** | **$5/tháng** |
