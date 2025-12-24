# Docker Deployment Guide

This guide covers deploying the Call Center Platform using Docker.

## Architecture

The application consists of three Docker containers:

1. **postgres** - PostgreSQL 15 database
2. **backend** - FastAPI application (Python)
3. **frontend** - Next.js application (Node.js)

All containers communicate over a dedicated Docker network (`callcenter-network`).

## Quick Start

```bash
# Start the entire stack
./stack.sh start

# Check status
./stack.sh status

# View logs
./stack.sh logs
```

## Stack Management

### Starting Services

```bash
# Start all services
./stack.sh start

# Services will start in order:
# 1. PostgreSQL (with health check)
# 2. Backend (waits for database)
# 3. Frontend (waits for backend)
```

### Stopping Services

```bash
# Stop all services (keeps data)
./stack.sh stop

# Stop and remove everything including volumes
./stack.sh clean
```

### Viewing Logs

```bash
# All services
./stack.sh logs

# Specific service
./stack.sh logs backend
./stack.sh logs frontend
./stack.sh logs database

# Follow logs in real-time
./stack.sh logs backend  # Press Ctrl+C to exit
```

### Checking Status

```bash
./stack.sh status
```

This shows:
- Container status
- Health check status for each service
- Port mappings

### Restarting Services

```bash
# Restart all services
./stack.sh restart

# Restart specific service
docker compose restart backend
docker compose restart frontend
docker compose restart postgres
```

## Database Management

### Backup Database

```bash
./stack.sh backup
```

Backups are saved to `backups/callcenter_YYYYMMDD_HHMMSS.sql`

### Restore Database

```bash
./stack.sh restore backups/callcenter_20231215_120000.sql
```

### Access Database

```bash
# Using psql
./stack.sh exec database psql -U callcenter

# Or using docker directly
docker exec -it callcenter-postgres psql -U callcenter
```

## Executing Commands

### Backend Shell

```bash
# Access bash in backend container
./stack.sh exec backend bash

# Run Python commands
./stack.sh exec backend python -c "print('Hello')"

# Run database migrations (if using Alembic)
./stack.sh exec backend alembic upgrade head
```

### Frontend Shell

```bash
# Access shell in frontend container
./stack.sh exec frontend sh

# Check Next.js version
./stack.sh exec frontend node -v
```

## Building Images

### Build All Images

```bash
./stack.sh build
```

### Build Specific Service

```bash
docker compose build backend
docker compose build frontend
```

### Build with No Cache

```bash
docker compose build --no-cache backend
```

## Environment Variables

Environment variables are managed in `.env` file (created from `.env.docker`).

### Important Variables

```bash
# Security
SECRET_KEY=your-secret-key-change-this

# Database
POSTGRES_USER=callcenter
POSTGRES_PASSWORD=callcenter123
POSTGRES_DB=callcenter

# API URL (for frontend)
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_JITSI_DOMAIN=meet.jit.si
```

### Update Environment Variables

1. Edit `.env` file
2. Restart services: `./stack.sh restart`

## Volumes

### Database Volume

Database data is persisted in a Docker volume:

```bash
# List volumes
docker volume ls | grep callcenter

# Inspect volume
docker volume inspect interpretation_platform_postgres_data

# Remove volume (CAUTION: deletes all data)
docker volume rm interpretation_platform_postgres_data
```

## Networking

### Network Details

```bash
# Inspect network
docker network inspect callcenter-network

# List containers on network
docker network inspect callcenter-network --format '{{range .Containers}}{{.Name}} {{end}}'
```

### Container Communication

Containers communicate using service names:
- Backend connects to database: `postgresql://callcenter:callcenter123@postgres:5432/callcenter`
- Frontend connects to backend: `http://backend:8000`

### Port Mappings

- Frontend: `3000:3000`
- Backend: `8000:8000`
- Database: `5432:5432`

## Health Checks

All services have health checks configured:

### Database Health Check
- Command: `pg_isready -U callcenter`
- Interval: 10s
- Timeout: 5s
- Retries: 5

### Backend Health Check
- Endpoint: `http://localhost:8000/health`
- Interval: 30s
- Timeout: 10s
- Start period: 40s

### Frontend Health Check
- Port check: `http://localhost:3000`
- Interval: 30s
- Timeout: 10s

## Troubleshooting

### Services Won't Start

```bash
# Check logs
./stack.sh logs

# Check specific service
./stack.sh logs backend

# Rebuild images
./stack.sh build
./stack.sh restart
```

### Database Connection Issues

```bash
# Check database is running
./stack.sh status

# Check database logs
./stack.sh logs database

# Test connection
./stack.sh exec backend python -c "from app.db.session import engine; engine.connect()"
```

### Port Already in Use

```bash
# Find process using port 3000
lsof -i :3000

# Find process using port 8000
lsof -i :8000

# Kill process or change port in docker-compose.yml
```

### Reset Everything

```bash
# Stop and remove all containers and volumes
./stack.sh clean

# Rebuild and start
./stack.sh build
./stack.sh start
```

## Production Deployment

### Security Checklist

1. **Change default credentials**
   ```bash
   # Update in .env
   SECRET_KEY=<generate-strong-random-key>
   POSTGRES_PASSWORD=<strong-password>
   ```

2. **Use production database**
   - Use managed PostgreSQL (AWS RDS, Google Cloud SQL, etc.)
   - Or secure self-hosted PostgreSQL

3. **Enable HTTPS**
   - Use reverse proxy (Nginx, Traefik)
   - Configure SSL certificates

4. **Update CORS settings**
   - Edit `backend/app/main.py`
   - Set specific origins instead of `*`

5. **Environment-specific configs**
   - Create `.env.production`
   - Use secrets management (AWS Secrets Manager, etc.)

### Resource Limits

Add resource limits to `docker-compose.yml`:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### Monitoring

```bash
# View resource usage
docker stats

# View specific container
docker stats callcenter-backend
```

## Advanced Usage

### Scale Services

```bash
# Scale backend (requires load balancer)
docker compose up -d --scale backend=3
```

### Update Single Service

```bash
# Pull latest code
git pull

# Rebuild and update backend only
docker compose up -d --build backend
```

### Export/Import Database

```bash
# Export
docker exec callcenter-postgres pg_dump -U callcenter callcenter > backup.sql

# Import
docker exec -i callcenter-postgres psql -U callcenter callcenter < backup.sql
```

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and deploy
        run: |
          ./stack.sh stop
          git pull
          ./stack.sh build
          ./stack.sh start
```
