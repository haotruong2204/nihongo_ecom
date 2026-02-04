# Nihongo E-commerce Development Guide

## Quick Start - Local Development

### 1. Khởi tạo lần đầu (First time setup)

```bash
# Clone repository và vào thư mục
cd nihongo_ecom

# Khởi tạo môi trường development
./scripts/dev-setup.sh
```

### 2. Các lệnh thường dùng (Daily commands)

#### Khởi động/Dừng services

```bash
# Khởi động tất cả services
./scripts/dev.sh start

# Dừng tất cả services
./scripts/dev.sh stop

# Restart services
./scripts/dev.sh restart

# Xem trạng thái services
./scripts/dev.sh status
```

#### Làm việc với Database

```bash
# Chạy migrations
./scripts/dev.sh db-migrate

# Seed database
./scripts/dev.sh db-seed

# Reset database (xóa tất cả data!)
./scripts/dev.sh db-reset
```

#### Debug và Development

```bash
# Xem logs của Rails app
./scripts/dev.sh logs

# Xem logs của Database
./scripts/dev.sh logs-db

# Vào shell của container
./scripts/dev.sh shell

# Mở Rails console
./scripts/dev.sh console
```

#### Testing

```bash
# Chạy test suite
./scripts/dev.sh test

# Hoặc chạy test trực tiếp
docker-compose -f docker-compose.dev.yml exec web bundle exec rspec
```

### 3. URLs và Ports

- **Application**: http://localhost:3000
- **Database (MySQL)**: localhost:3310
- **Redis**: localhost:6379
- **Health Check**: http://localhost:3000/health

### 4. File cấu hình quan trọng

- `docker-compose.dev.yml` - Cấu hình Docker cho development
- `Dockerfile.dev` - Docker image cho development
- `.env` - Environment variables (tạo tự động)
- `config/database.yml` - Cấu hình database

### 5. Troubleshooting

#### Services không start được

```bash
# Kiểm tra logs
./scripts/dev.sh logs

# Build lại images
./scripts/dev.sh build

# Clean up và start lại
./scripts/dev.sh clean
./scripts/dev.sh start
```

#### Database connection issues

```bash
# Kiểm tra database logs
./scripts/dev.sh logs-db

# Reset database
./scripts/dev.sh db-reset
```

#### Port conflicts

Nếu port 3000, 3310, hoặc 6379 đang được sử dụng:

1. Sửa ports trong `docker-compose.dev.yml`
2. Update URLs tương ứng

### 6. Development Workflow

1. **Bắt đầu ngày làm việc**:

   ```bash
   ./scripts/dev.sh start
   ```

2. **Tạo migration mới**:

   ```bash
   ./scripts/dev.sh shell
   bundle exec rails generate migration CreateNewTable
   ./scripts/dev.sh db-migrate
   ```

3. **Chạy tests trước khi commit**:

   ```bash
   ./scripts/dev.sh test
   ```

4. **Kết thúc ngày làm việc**:
   ```bash
   ./scripts/dev.sh stop
   ```

### 7. Useful Commands

```bash
# Tất cả lệnh có sẵn
./scripts/dev.sh help

# Xem tất cả containers
docker ps

# Vào database trực tiếp
docker-compose -f docker-compose.dev.yml exec db mysql -u root -p

# Backup database
docker-compose -f docker-compose.dev.yml exec db mysqldump -u root -p nihongo_ecom_development > backup.sql
```

## Production Deployment

Xem hướng dẫn deployment tại [DEPLOYMENT.md](DEPLOYMENT.md)
