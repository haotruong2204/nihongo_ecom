#!/bin/bash

# Local Development Script
# This script helps you run the application locally for development

set -e

echo "🔧 Setting up local development environment..."

# Check if Docker is installed and running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📄 Creating .env file from example..."
    cat > .env << 'EOF'
# Database
DATABASE_URL=mysql2://root:password@db:3306/nihongo_ecom_development

# Redis
REDIS_URL=redis://redis:6379

# Rails
RAILS_ENV=development
RACK_ENV=development

# Add your other environment variables here
RAILS_MASTER_KEY=your_master_key_here
EOF
    echo "✅ Created .env file. Please update it with your actual values."
fi

# Build and start services
echo "🐳 Building and starting Docker services..."
docker-compose -f docker-compose.dev.yml up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 15

# Check if database needs setup
echo "🗄️ Setting up database if needed..."
docker-compose -f docker-compose.dev.yml exec web bundle exec rails db:prepare
docker-compose -f docker-compose.dev.yml exec web bundle exec rails db:seed

echo "✅ Development environment is ready!"
echo ""
echo "🌐 Your application is running at: http://localhost:3000"
echo "🗄️ MySQL is available at: localhost:3310"
echo "🔴 Redis is available at: localhost:6379"
echo ""
echo "📝 Useful commands:"
echo "   docker-compose -f docker-compose.dev.yml logs -f web    # View application logs"
echo "   docker-compose -f docker-compose.dev.yml exec web bash  # Access application container"
echo "   docker-compose -f docker-compose.dev.yml down           # Stop all services"
echo "   docker-compose -f docker-compose.dev.yml restart web    # Restart web service"
