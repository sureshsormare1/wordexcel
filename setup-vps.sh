#!/bin/bash

# VPS Setup Script for WordExcel Application
# Run this script on a fresh Ubuntu/Debian VPS

set -e

echo "🚀 Setting up VPS for WordExcel deployment..."

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

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    print_error "This script needs to be run as root or with sudo privileges"
    exit 1
fi

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
print_status "Installing essential packages..."
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_success "Docker installed successfully"
else
    print_success "Docker is already installed"
fi

# Install Docker Compose
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_success "Docker Compose is already installed"
fi

# Install Nginx (for SSL certificate management)
print_status "Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo apt install -y nginx
    sudo systemctl stop nginx  # Stop it as we'll use Docker nginx
    sudo systemctl disable nginx
    print_success "Nginx installed (disabled for Docker use)"
else
    print_success "Nginx is already installed"
fi

# Install Certbot for SSL
print_status "Installing Certbot..."
if ! command -v certbot &> /dev/null; then
    sudo apt install -y certbot python3-certbot-nginx
    print_success "Certbot installed successfully"
else
    print_success "Certbot is already installed"
fi

# Configure firewall
print_status "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
print_success "Firewall configured"

# Create application directory
print_status "Creating application directory..."
APP_DIR="/opt/wordexcel"
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR
print_success "Application directory created at $APP_DIR"

# Install Node.js (for potential debugging)
print_status "Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_success "Node.js installed successfully"
else
    print_success "Node.js is already installed"
fi

# Install Python (usually pre-installed)
print_status "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    sudo apt install -y python3 python3-pip
    print_success "Python3 installed successfully"
else
    print_success "Python3 is already installed"
fi

# Create swap file if not exists (recommended for small VPS)
print_status "Checking swap configuration..."
if ! swapon --show | grep -q "/swapfile"; then
    print_status "Creating swap file (1GB)..."
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    print_success "Swap file created"
else
    print_success "Swap is already configured"
fi

# Configure log rotation for Docker
print_status "Configuring Docker log rotation..."
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Restart Docker to apply log configuration
sudo systemctl restart docker

# Create logrotate configuration for application logs
sudo tee /etc/logrotate.d/wordexcel > /dev/null <<EOF
/opt/wordexcel/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    create 644 $USER $USER
}
EOF

print_success "Log rotation configured"

# Display system information
print_status "System Information:"
echo "  - OS: $(lsb_release -d | cut -f2)"
echo "  - Kernel: $(uname -r)"
echo "  - Docker: $(docker --version)"
echo "  - Docker Compose: $(docker-compose --version 2>/dev/null || docker compose version)"
echo "  - Available Memory: $(free -h | awk '/^Mem:/ {print $7}')"
echo "  - Available Disk: $(df -h / | awk 'NR==2 {print $4}')"

print_success "🎉 VPS setup completed successfully!"
print_status "Next steps:"
echo "  1. Clone your application repository to $APP_DIR"
echo "  2. Configure your .env file with API keys"
echo "  3. Run the deployment script"
echo ""
print_warning "Note: You may need to log out and back in for Docker group membership to take effect"
print_status "Or run: newgrp docker"
