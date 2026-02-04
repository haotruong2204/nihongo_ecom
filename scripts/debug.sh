#!/bin/bash

# Debug script for development environment
# This script helps debug connection issues

set -e

COMPOSE_FILE="docker-compose.dev.yml"

show_help() {
    echo "🔍 Nihongo E-commerce Debug Helper"
    echo ""
    echo "Usage: ./scripts/debug.sh [command]"
    echo ""
    echo "Commands:"
    echo "  db-logs       - Show database container logs"
    echo "  app-logs      - Show application container logs"
    echo "  db-connect    - Test direct database connection"
    echo "  db-status     - Check database status"
    echo "  network       - Check network connectivity"
    echo "  env           - Show environment variables"
    echo "  rails-config  - Show Rails database config"
    echo "  containers    - Show running containers"
    echo "  db-shell      - Open MySQL shell"
    echo "  app-shell     - Open application shell"
    echo "  full-debug    - Run comprehensive debug"
    echo "  help          - Show this help"
    echo ""
}

check_containers() {
    echo "🐳 Checking container status..."
    docker-compose -f $COMPOSE_FILE ps
    echo ""
}

check_network() {
    echo "🌐 Checking network connectivity..."
    
    echo "Testing from app container to db container:"
    if docker-compose -f $COMPOSE_FILE exec web timeout 5 bash -c "</dev/tcp/db/3306" 2>/dev/null; then
        echo "✅ Port 3306 is reachable from app container"
    else
        echo "❌ Cannot reach port 3306 from app container"
    fi
    
    echo ""
    echo "Network information:"
    docker-compose -f $COMPOSE_FILE exec web cat /etc/hosts | grep -E "(db|mysql)"
    echo ""
    
    echo "DNS resolution test:"
    docker-compose -f $COMPOSE_FILE exec web nslookup db || echo "DNS resolution failed"
    echo ""
}

test_db_connection() {
    echo "🗄️ Testing database connection..."
    
    echo "1. Testing MySQL connection from app container:"
    # Try different MySQL clients
    if docker-compose -f $COMPOSE_FILE exec web which mysql >/dev/null 2>&1; then
        echo "Using mysql client..."
        docker-compose -f $COMPOSE_FILE exec web mysql -h db -u root -ppassword -e "SHOW DATABASES;" 2>&1 || echo "MySQL connection failed"
    elif docker-compose -f $COMPOSE_FILE exec web which mariadb >/dev/null 2>&1; then
        echo "Using mariadb client..."
        docker-compose -f $COMPOSE_FILE exec web mariadb -h db -u root -ppassword -e "SHOW DATABASES;" 2>&1 || echo "MariaDB connection failed"
    else
        echo "❌ No MySQL/MariaDB client found in container"
        echo "Available database-related commands:"
        docker-compose -f $COMPOSE_FILE exec web ls /usr/bin/ | grep -E "(mysql|maria)" || echo "None found"
        echo ""
        echo "Testing with netcat instead:"
        if docker-compose -f $COMPOSE_FILE exec web nc -z db 3306; then
            echo "✅ Port 3306 is reachable"
        else
            echo "❌ Port 3306 is not reachable"
        fi
    fi
    
    echo ""
    echo "2. Testing Rails database connection:"
    docker-compose -f $COMPOSE_FILE exec web bundle exec rails runner "
        begin
            result = ActiveRecord::Base.connection.execute('SELECT VERSION() as version')
            puts '✅ Rails DB connection successful!'
            puts 'MySQL Version: ' + result.first['version']
        rescue => e
            puts '❌ Rails DB connection failed:'
            puts e.class.name + ': ' + e.message
        end
    " 2>&1
}

show_env() {
    echo "🔧 Environment variables in app container:"
    docker-compose -f $COMPOSE_FILE exec web env | grep -E "(DATABASE|MYSQL|DB_|RAILS_ENV|RACK_ENV)" | sort
    echo ""
}

show_rails_config() {
    echo "⚙️ Rails database configuration:"
    docker-compose -f $COMPOSE_FILE exec web bundle exec rails runner "
        puts 'Active environment: ' + Rails.env
        puts 'Database config:'
        pp ActiveRecord::Base.connection_config
        puts ''
        puts 'Database URL from ENV:'
        puts ENV['DATABASE_URL'].inspect
    " 2>&1
}

full_debug() {
    echo "🔍 Running comprehensive debug..."
    echo "=================================="
    echo ""
    
    check_containers
    echo ""
    
    check_network
    echo ""
    
    show_env
    echo ""
    
    test_db_connection
    echo ""
    
    show_rails_config
    echo ""
    
    echo "🔍 Database container logs (last 20 lines):"
    docker-compose -f $COMPOSE_FILE logs --tail=20 db
    echo ""
    
    echo "🔍 Application container logs (last 20 lines):"
    docker-compose -f $COMPOSE_FILE logs --tail=20 web
}

case "$1" in
    "db-logs")
        echo "📋 Database container logs:"
        docker-compose -f $COMPOSE_FILE logs -f db
        ;;
    
    "app-logs")
        echo "📋 Application container logs:"
        docker-compose -f $COMPOSE_FILE logs -f web
        ;;
    
    "db-connect")
        test_db_connection
        ;;
    
    "db-status")
        echo "🗄️ Database status:"
        docker-compose -f $COMPOSE_FILE exec db mysql -u root -ppassword -e "
            SHOW PROCESSLIST;
            SHOW DATABASES;
            SELECT User, Host FROM mysql.user;
        " 2>&1
        ;;
    
    "network")
        check_network
        ;;
    
    "env")
        show_env
        ;;
    
    "rails-config")
        show_rails_config
        ;;
    
    "containers")
        check_containers
        ;;
    
    "db-shell")
        echo "🐚 Opening MySQL shell..."
        # Connect directly to the database container (not through app container)
        docker-compose -f $COMPOSE_FILE exec db mysql -u root -ppassword
        ;;
    
    "app-shell")
        echo "🐚 Opening application shell..."
        docker-compose -f $COMPOSE_FILE exec web bash
        ;;
    
    "full-debug")
        full_debug
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
