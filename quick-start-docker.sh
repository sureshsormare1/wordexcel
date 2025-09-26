#!/bin/bash

# Quick Start Script for Local Docker Development
# This script helps you quickly test the Docker setup locally

set -e

echo "🚀 Quick Start - WordExcel Docker Setup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating from template..."
    if [ -f "env.example" ]; then
        cp env.example .env
        print_warning "Please edit .env file with your OpenAI API key:"
        print_status "  nano .env"
        print_status "  # Add your OPENAI_API_KEY=sk-your-key-here"
        echo ""
        read -p "Press Enter after you've updated the .env file..."
    else
        print_error "env.example file not found. Please create .env file manually."
        exit 1
    fi
fi

# Function to use docker-compose or docker compose
docker_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# Stop any existing containers
print_status "Stopping any existing containers..."
docker_compose_cmd down --remove-orphans 2>/dev/null || true

# Build and start services
print_status "Building and starting services (this may take a few minutes)..."
docker_compose_cmd up --build -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 10

# Function to wait for service
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1

    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" >/dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start within expected time"
    return 1
}

# Check services
echo ""
print_status "Checking service health..."

# Check backend
if wait_for_service "http://localhost:8000/health" "Backend API"; then
    print_success "✅ Backend service is healthy"
else
    print_error "❌ Backend service failed to start"
    print_status "Backend logs:"
    docker_compose_cmd logs --tail=20 backend
    exit 1
fi

# Check frontend
if wait_for_service "http://localhost:3000" "Frontend"; then
    print_success "✅ Frontend service is healthy"
else
    print_error "❌ Frontend service failed to start"
    print_status "Frontend logs:"
    docker_compose_cmd logs --tail=20 frontend
    exit 1
fi

# Check nginx
if wait_for_service "http://localhost" "Nginx Proxy"; then
    print_success "✅ Nginx proxy is healthy"
else
    print_error "❌ Nginx proxy failed to start"
    print_status "Nginx logs:"
    docker_compose_cmd logs --tail=20 nginx
    exit 1
fi

echo ""
print_success "🎉 All services are running successfully!"
echo ""
print_status "📋 Service URLs:"
print_status "  🌐 Main Application: http://localhost"
print_status "  🖥️  Frontend (direct): http://localhost:3000"
print_status "  🔧 Backend API: http://localhost:8000"
print_status "  ❤️  Health Check: http://localhost:8000/health"
echo ""
print_status "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=wordexcel"
echo ""
print_status "🔍 Useful Commands:"
print_status "  📜 View all logs: docker-compose logs -f"
print_status "  📜 View specific service logs: docker-compose logs -f [backend|frontend|nginx]"
print_status "  🔄 Restart service: docker-compose restart [service_name]"
print_status "  🛑 Stop all services: docker-compose down"
print_status "  🔧 Rebuild and restart: docker-compose up --build -d"
echo ""
print_warning "💡 Tips:"
print_status "  - Upload some Word documents to test the functionality"
print_status "  - Check the browser console for any frontend errors"
print_status "  - Monitor logs if you encounter any issues"
echo ""

# Open browser (optional)
if command -v xdg-open &> /dev/null; then
    read -p "Would you like to open the application in your browser? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xdg-open http://localhost
    fi
elif command -v open &> /dev/null; then
    read -p "Would you like to open the application in your browser? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open http://localhost
    fi
fi

print_success "Happy coding! 🚀"
