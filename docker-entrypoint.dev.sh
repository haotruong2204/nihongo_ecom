#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Function to wait for database
wait_for_database() {
  echo "=== DATABASE CONNECTION DEBUG ==="
  echo "DATABASE_URL: $DATABASE_URL"
  echo "DB Environment Variables:"
  env | grep -E "(DATABASE|MYSQL|DB_|RAILS_ENV)" | sort
  echo ""
  
  # Check if we can resolve the hostname 'db'
  echo "🔍 Checking hostname resolution..."
  if nslookup db > /dev/null 2>&1; then
    echo "✅ Hostname 'db' resolves successfully"
    echo "DB IP: $(nslookup db | grep -A1 "Name:" | tail -1 | awk '{print $2}')"
  else
    echo "❌ Cannot resolve hostname 'db'"
    echo "Available hosts:"
    cat /etc/hosts
    return 1
  fi
  
  # Check if port is open
  echo ""
  echo "🔍 Checking port connectivity..."
  if timeout 5 bash -c "</dev/tcp/db/3306" 2>/dev/null; then
    echo "✅ Port 3306 on 'db' is open"
  else
    echo "❌ Cannot connect to port 3306 on 'db'"
    echo "Network connectivity issues detected"
    return 1
  fi
  
  # Wait for MySQL service to be ready
  echo ""
  echo "🔍 Waiting for MySQL service..."
  for i in {1..30}; do
    if timeout 10 mysql -h db -u root -ppassword -e "SELECT 1;" &>/dev/null; then
      echo "✅ MySQL server is responding!"
      break
    fi
    
    echo "⏳ MySQL not ready yet (attempt $i/30)..."
    if [ $i -eq 5 ] || [ $i -eq 15 ] || [ $i -eq 25 ]; then
      echo "🔍 Debug info at attempt $i:"
      echo "  - Testing basic connectivity..."
      timeout 5 bash -c "echo > /dev/tcp/db/3306" && echo "    Port is open" || echo "    Port is closed"
      echo "  - Trying mysql connection with verbose error..."
      mysql -h db -u root -ppassword -e "SELECT 1;" 2>&1 | head -5
    fi
    
    sleep 2
    
    if [ $i -eq 30 ]; then
      echo "❌ MySQL server failed to become available after 60 seconds"
      echo ""
      echo "🔍 Final debug information:"
      echo "Network status:"
      netstat -an | grep 3306 || echo "No processes listening on port 3306"
      echo ""
      echo "MySQL connection attempt with full error:"
      mysql -h db -u root -ppassword -e "SELECT 1;" 2>&1
      return 1
    fi
  done
  
  # Test Rails database connection
  echo ""
  echo "🔍 Testing Rails database connection..."
  for i in {1..10}; do
    echo "Attempt $i: Testing Rails DB connection..."
    
    if bundle exec rails runner "
      begin
        ActiveRecord::Base.connection.execute('SELECT 1')
        puts '✅ Rails database connection successful!'
        exit 0
      rescue => e
        puts '❌ Rails DB connection failed:'
        puts e.class.name + ': ' + e.message
        puts 'Backtrace:'
        puts e.backtrace[0..3].join(\"\n\")
        exit 1
      end
    " 2>&1; then
      echo "✅ Rails database connection successful!"
      return 0
    fi
    
    echo "⏳ Rails DB connection failed, retrying in 3 seconds..."
    sleep 3
  done
  
  echo "❌ Rails failed to connect to database after multiple attempts"
  echo ""
  echo "🔍 Rails database configuration debug:"
  bundle exec rails runner "
    puts 'Database config:'
    puts ActiveRecord::Base.connection_config.inspect
  " 2>&1 || echo "Failed to get database config"
  
  return 1
}

# Wait for database
wait_for_database

# Install any new gems
bundle check || bundle install

# Setup database if it doesn't exist
echo "Checking database setup..."
if ! bundle exec rails runner "ActiveRecord::Base.connection.table_exists?('schema_migrations')" 2>/dev/null; then
  echo "Setting up database for the first time..."
  bundle exec rails db:create
  bundle exec rails db:migrate
  bundle exec rails db:seed
else
  echo "Running pending migrations..."
  bundle exec rails db:migrate
fi

echo "Starting Rails application..."

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
