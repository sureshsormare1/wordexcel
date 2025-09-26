# WordExcel Docker Deployment Guide

This guide will help you deploy the WordExcel application on a Hostinger VPS using Docker.

## Prerequisites

- Hostinger VPS with Ubuntu/Debian
- Root or sudo access
- Domain name (optional, for SSL)
- OpenAI API key

## Quick Start

1. **Clone the repository to your VPS:**
   ```bash
   git clone <your-repo-url>
   cd wordexcel
   ```

2. **Set up environment variables:**
   ```bash
   cp env.example .env
   nano .env  # Edit with your actual values
   ```

3. **Run the deployment script:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

## Detailed Setup Instructions

### 1. Server Preparation

#### Install Docker
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

#### Configure Firewall
```bash
# Allow HTTP and HTTPS
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 22  # SSH
sudo ufw enable
```

### 2. Application Configuration

#### Environment Variables
Edit the `.env` file with your configuration:

```bash
# Required: OpenAI API Key
OPENAI_API_KEY=sk-your-actual-openai-api-key

# Optional: Domain configuration (for SSL)
DOMAIN=yourdomain.com
SSL_EMAIL=your-email@domain.com
```

### 3. Deployment Options

#### Option A: HTTP Only (Development/Testing)
```bash
# Use the default docker-compose.yml
docker-compose up -d
```

#### Option B: HTTPS with SSL (Production)
1. **Update Nginx configuration:**
   ```bash
   # Edit nginx/nginx.conf
   # Uncomment the HTTPS server block
   # Update server_name with your domain
   ```

2. **Set up SSL certificates:**
   ```bash
   # Install Certbot
   sudo apt install certbot python3-certbot-nginx

   # Get SSL certificate
   sudo certbot --nginx -d yourdomain.com
   ```

3. **Deploy with SSL:**
   ```bash
   docker-compose up -d
   ```

### 4. Service Management

#### Start Services
```bash
docker-compose up -d
```

#### Stop Services
```bash
docker-compose down
```

#### Restart Services
```bash
docker-compose restart [service_name]
```

#### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f nginx
```

#### Update Application
```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose up --build -d
```

### 5. Monitoring and Maintenance

#### Health Checks
- Backend: `http://your-server/api/health`
- Frontend: `http://your-server`

#### System Resources
```bash
# Check container status
docker ps

# Check resource usage
docker stats

# Check disk usage
docker system df
```

#### Backup Important Data
```bash
# Backup uploads and temp directories
tar -czf backup-$(date +%Y%m%d).tar.gz python/uploads python/temp

# Backup environment configuration
cp .env .env.backup
```

### 6. Troubleshooting

#### Common Issues

**Port Already in Use:**
```bash
# Check what's using the port
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Stop conflicting services
sudo systemctl stop apache2  # or nginx if installed separately
```

**Container Won't Start:**
```bash
# Check logs
docker-compose logs [service_name]

# Check container status
docker ps -a

# Restart specific service
docker-compose restart [service_name]
```

**SSL Certificate Issues:**
```bash
# Renew certificates
sudo certbot renew

# Test certificate renewal
sudo certbot renew --dry-run
```

**Out of Disk Space:**
```bash
# Clean up Docker
docker system prune -a

# Remove unused volumes
docker volume prune
```

### 7. Performance Optimization

#### For Production Use:

1. **Increase file upload limits** (if needed):
   ```bash
   # Edit nginx/nginx.conf
   client_max_body_size 500M;  # Adjust as needed
   ```

2. **Configure log rotation:**
   ```bash
   # Add to /etc/logrotate.d/docker-containers
   /var/lib/docker/containers/*/*.log {
       rotate 7
       daily
       compress
       size=1M
       missingok
       delaycompress
       copytruncate
   }
   ```

3. **Set up monitoring:**
   ```bash
   # Install monitoring tools
   sudo apt install htop iotop nethogs
   ```

### 8. Security Considerations

- Change default passwords
- Keep Docker and system updated
- Use SSL certificates for production
- Configure proper firewall rules
- Regular security updates
- Monitor logs for suspicious activity

### 9. Scaling (Future)

For high-traffic scenarios, consider:
- Load balancer setup
- Multiple backend instances
- Database optimization
- CDN for static assets
- Container orchestration (Kubernetes)

## Support

If you encounter issues:
1. Check the logs: `docker-compose logs -f`
2. Verify environment variables in `.env`
3. Ensure all ports are available
4. Check system resources (CPU, RAM, disk)

## URLs After Deployment

- **Main Application**: `http://your-server-ip` or `https://yourdomain.com`
- **API Health Check**: `http://your-server-ip/api/health`
- **Direct Frontend**: `http://your-server-ip:3000` (for debugging)
- **Direct Backend**: `http://your-server-ip:8000` (for debugging)

Remember to replace `your-server-ip` with your actual server IP address or domain name.
