#!/bin/bash

# Development Helper Commands
# Quick commands for common development tasks

set -e

COMPOSE_FILE="docker-compose.dev.yml"

show_help() {
    echo "🚀 Nihongo E-commerce Development Helper"
    echo ""
    echo "Usage: ./scripts/dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start       - Start all services"
    echo "  stop        - Stop all services"
    echo "  restart     - Restart all services"
    echo "  build       - Rebuild all services"
    echo "  logs        - Show application logs"
    echo "  logs-db     - Show database logs"
    echo "  logs-redis  - Show Redis logs"
    echo "  shell       - Access application shell"
    echo "  console     - Open Rails console"
    echo "  db-reset    - Reset database (destructive!)"
    echo "  db-migrate  - Run database migrations"
    echo "  db-seed     - Seed database"
    echo "  test        - Run test suite"
    echo "  clean       - Clean up containers and volumes"
    echo "  status      - Show services status"
    echo "  help        - Show this help"
    echo ""
}

case "$1" in
    "start")
        echo "🚀 Starting development environment..."
        docker-compose -f $COMPOSE_FILE up -d
        echo "✅ Development environment started!"
        echo "🌐 Application: http://localhost:3000"
        ;;
    
    "stop")
        echo "🛑 Stopping development environment..."
        docker-compose -f $COMPOSE_FILE down
        echo "✅ Development environment stopped!"
        ;;
    
    "restart")
        echo "🔄 Restarting development environment..."
        docker-compose -f $COMPOSE_FILE restart
        echo "✅ Development environment restarted!"
        ;;
    
    "build")
        echo "🔨 Building development environment..."
        docker-compose -f $COMPOSE_FILE build --no-cache
        echo "✅ Build completed!"
        ;;
    
    "logs")
        echo "📋 Showing application logs..."
        docker-compose -f $COMPOSE_FILE logs -f web
        ;;
    
    "logs-db")
        echo "📋 Showing database logs..."
        docker-compose -f $COMPOSE_FILE logs -f db
        ;;
    
    "logs-redis")
        echo "📋 Showing Redis logs..."
        docker-compose -f $COMPOSE_FILE logs -f redis
        ;;
    
    "shell")
        echo "🐚 Opening application shell..."
        docker-compose -f $COMPOSE_FILE exec web bash
        ;;
    
    "console")
        echo "🛠️ Opening Rails console..."
        docker-compose -f $COMPOSE_FILE exec web bundle exec rails console
        ;;
    
    "db-reset")
        echo "⚠️  This will destroy all data in the database!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🗄️ Resetting database..."
            docker-compose -f $COMPOSE_FILE exec web bundle exec rails db:drop db:create db:migrate db:seed
            echo "✅ Database reset completed!"
        else
            echo "❌ Database reset cancelled."
        fi
        ;;
    
    "db-migrate")
        echo "🗄️ Running database migrations..."
        docker-compose -f $COMPOSE_FILE exec web bundle exec rails db:migrate
        echo "✅ Migrations completed!"
        ;;
    
    "db-seed")
        echo "🌱 Seeding database..."
        docker-compose -f $COMPOSE_FILE exec web bundle exec rails db:seed
        echo "✅ Database seeded!"
        ;;
    
    "test")
        echo "🧪 Running test suite..."
        docker-compose -f $COMPOSE_FILE exec web bundle exec rspec
        ;;
    
    "clean")
        echo "🧹 Cleaning up containers and volumes..."
        docker-compose -f $COMPOSE_FILE down -v --remove-orphans
        docker system prune -f
        echo "✅ Cleanup completed!"
        ;;
    
    "status")
        echo "📊 Services status:"
        docker-compose -f $COMPOSE_FILE ps
        ;;
    
    "help"|"")
        show_help
        ;;
    
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
