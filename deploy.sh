#!/bin/bash

# WordExcel Deployment Script for Hostinger VPS
# This script automates the deployment process

set -e

echo "🚀 Starting WordExcel deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating from template..."
    if [ -f "env.example" ]; then
        cp env.example .env
        print_warning "Please edit .env file with your actual values before continuing."
        exit 1
    else
        print_error "env.example file not found. Please create .env file manually."
        exit 1
    fi
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Function to use docker-compose or docker compose
docker_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# Stop existing containers
print_status "Stopping existing containers..."
docker_compose_cmd down --remove-orphans || true

# Remove old images (optional, uncomment if you want to force rebuild)
# print_status "Removing old images..."
# docker system prune -f

# Build and start containers
print_status "Building and starting containers..."
docker_compose_cmd up --build -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 30

# Check if services are running
print_status "Checking service health..."

# Check backend health
if curl -f http://localhost:8000/health &> /dev/null; then
    print_success "Backend service is healthy"
else
    print_error "Backend service is not responding"
    docker_compose_cmd logs backend
    exit 1
fi

# Check frontend
if curl -f http://localhost:3000 &> /dev/null; then
    print_success "Frontend service is healthy"
else
    print_error "Frontend service is not responding"
    docker_compose_cmd logs frontend
    exit 1
fi

# Check nginx
if curl -f http://localhost &> /dev/null; then
    print_success "Nginx service is healthy"
else
    print_error "Nginx service is not responding"
    docker_compose_cmd logs nginx
    exit 1
fi

print_success "🎉 Deployment completed successfully!"
print_status "Your application is now running at:"
print_status "  - Main application: http://localhost"
print_status "  - Frontend (direct): http://localhost:3000"
print_status "  - Backend API: http://localhost:8000"
print_status "  - API Health check: http://localhost:8000/health"

print_status "To view logs: docker-compose logs -f [service_name]"
print_status "To stop: docker-compose down"
print_status "To restart: docker-compose restart [service_name]"

# Show running containers
print_status "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
