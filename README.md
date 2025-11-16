# OpenStreetLifting - Production Deployment

Infrastructure as Code for deploying OpenStreetLifting API with Traefik reverse proxy.

## Overview

This configuration deploys a production-ready instance of the OpenStreetLifting backend API with:

- **PostgreSQL 18** - Primary database with persistent storage
- **Actix-web Backend** - High-performance REST API
- **Traefik Integration** - Automatic HTTPS with Let's Encrypt
- **Docker Compose** - Orchestration and service management

## Prerequisites

### Required

- Docker Engine 20.10+
- Docker Compose 2.0+
- Traefik reverse proxy running with `traefik_public` network
- Domain name with DNS configured (default: `api.openstreetlifting.org`)

### Traefik Network Setup

If Traefik is not yet configured, create the external network:

```bash
docker network create traefik_public
```

Ensure Traefik is configured with:
- Let's Encrypt certificate resolver named `letsencrypt`
- Entrypoints: `web` (80), `websecure` (443)

## Quick Deployment

```bash
# 1. Clone repository
git clone <repository-url>
cd openstreetlifting_iac

# 2. Configure environment
cp .env.example .env
nano .env  # Edit with production values

# 3. Deploy
docker-compose up -d

# 4. Verify deployment
docker-compose ps
docker-compose logs -f backend
```

Access your API at `https://api.openstreetlifting.org`

## Configuration

### Required Environment Variables

Edit `.env` with production values:

```bash
# Database credentials (⚠️ CHANGE IN PRODUCTION)
DB_USER=appuser
DB_PASSWORD=<strong-random-password>
DB_NAME=appdb

# API authentication (⚠️ REQUIRED)
# Generate with: openssl rand -hex 32
API_KEYS=<secure-api-key-1>,<secure-api-key-2>
```

### Security Checklist

- [ ] Change `DB_PASSWORD` to a strong random password
- [ ] Generate secure `API_KEYS` (use `openssl rand -hex 32`)
- [ ] Verify DNS points to your server
- [ ] Review Traefik configuration for HTTPS
- [ ] Consider restricting database port exposure (comment out `ports` in docker-compose)
- [ ] Set up automated backups for PostgreSQL data
- [ ] Configure firewall rules

### Optional Configuration

```bash
# Database port (default: 5432)
DB_PORT=5432

# Application metadata
APP_NAME=openstreetlifting

# Server settings (usually no need to change)
HOST=0.0.0.0
PORT=8080
```

## Management

### Service Control

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart specific service
docker-compose restart backend

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### Database Management

#### Backups

```bash
# Create backup
docker-compose exec postgres pg_dump -U appuser appdb > backups/backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
docker-compose exec -T postgres psql -U appuser appdb < backups/backup_20240101_120000.sql
```

#### Access Database

```bash
# Interactive psql session
docker-compose exec postgres psql -U appuser -d appdb

# Run SQL query
docker-compose exec postgres psql -U appuser -d appdb -c "SELECT COUNT(*) FROM competitions;"
```

### Updates

```bash
# Pull latest image
docker-compose pull backend

# Restart with new image
docker-compose up -d backend

# View logs
docker-compose logs -f backend
```

## Monitoring

### Health Checks

```bash
# Check API health
curl https://api.openstreetlifting.org/health

# Check database health
docker-compose exec postgres pg_isready -U appuser

# View resource usage
docker stats openstreetlifting_web_api openstreetlifting_postgres
```

### Logs

```bash
# All logs
docker-compose logs -f

# Backend only
docker-compose logs -f backend

# Last 100 lines
docker-compose logs --tail=100 backend

# Since specific time
docker-compose logs --since 2024-01-01T12:00:00 backend
```

## Troubleshooting

### Service won't start

```bash
# Check logs for errors
docker-compose logs backend

# Verify Traefik network exists
docker network ls | grep traefik_public

# Verify environment variables
docker-compose config
```

### HTTPS/Certificate issues

```bash
# Check Traefik logs
docker logs traefik

# Verify DNS resolution
dig api.openstreetlifting.org

# Check certificate status in Traefik dashboard
```

### Database connection errors

```bash
# Verify PostgreSQL is healthy
docker-compose ps postgres

# Check database logs
docker-compose logs postgres

# Test connection manually
docker-compose exec backend nc -zv postgres 5432
```

### High resource usage

```bash
# Check resource consumption
docker stats

# Optimize PostgreSQL
# Edit postgresql.conf in volume or use custom config
docker-compose exec postgres psql -U appuser -c "SHOW shared_buffers;"
```

## Architecture

```
┌─────────────────┐
│   Internet      │
└────────┬────────┘
         │
┌────────▼────────┐
│    Traefik      │  (HTTPS, Let's Encrypt)
└────────┬────────┘
         │
┌────────▼────────┐
│    Backend      │  (Actix-web on :8080)
└────────┬────────┘
         │
┌────────▼────────┐
│   PostgreSQL    │  (Port :5432)
└─────────────────┘
```

## Data Persistence

Volumes:
- `postgres_data` - Database files (persistent across restarts)
- `./backups` - Database backup directory (bind mount)

To reset all data:
```bash
docker-compose down -v  # ⚠️ WARNING: Destroys all data
```

## Security Best Practices

1. **Secrets Management**: Consider using Docker secrets or external vault
2. **Database Access**: Remove external port exposure if not needed
3. **API Keys**: Rotate regularly, use one key per client
4. **Backups**: Automate daily backups and test restoration
5. **Monitoring**: Set up alerts for service failures
6. **Updates**: Keep Docker images updated
7. **Firewall**: Restrict access to ports 80/443 only

## Support

For issues or questions:
- Check logs: `docker-compose logs`
- Review [Backend Documentation](../openstreetlifting_backend/README.md)
- Open an issue on GitHub

## License

[Add your license here]
