# Quick Start Guide

Get the Call Center Platform running in under 5 minutes!

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running

## Steps

### 1. Clone and Navigate

```bash
cd interpretation_platform
```

### 2. Start Everything

```bash
./stack.sh start
```

This will:
- Start PostgreSQL database
- Start FastAPI backend
- Start Next.js frontend
- Create sample users and data

### 3. Access the Application

Open your browser and go to:

**http://localhost:3000**

### 4. Login

Use these test credentials:

```
Email: agent1@example.com
Password: password123
```

### 5. Start Making Calls

1. Click "Start Test Call" button
2. Allow camera/microphone permissions
3. You'll join a Jitsi video call
4. To test with another user, open a new incognito window and join with a different account

## Test Users

| Email | Password | Role |
|-------|----------|------|
| agent1@example.com | password123 | Agent |
| agent2@example.com | password123 | Agent |
| supervisor@example.com | password123 | Supervisor |
| admin@example.com | password123 | Admin |

## Useful Commands

```bash
# View all logs
./stack.sh logs

# View backend logs only
./stack.sh logs backend

# Check status
./stack.sh status

# Stop everything
./stack.sh stop

# Restart everything
./stack.sh restart
```

## API Documentation

Once running, visit:

**http://localhost:8000/docs**

This shows interactive API documentation powered by FastAPI.

## Troubleshooting

### Port Already in Use

If you see "port already in use" errors:

```bash
# Check what's using the port
lsof -i :3000  # Frontend
lsof -i :8000  # Backend
lsof -i :5432  # Database

# Kill the process or stop the service
```

### Services Won't Start

```bash
# Check logs for errors
./stack.sh logs

# Rebuild everything
./stack.sh clean
./stack.sh build
./stack.sh start
```

### Database Connection Failed

```bash
# Make sure database is healthy
./stack.sh status

# Restart database
docker compose restart postgres
```

## Next Steps

- **Customize UI**: Update components in `frontend/src/components/`
- **Add Features**: Extend API endpoints in `backend/app/api/`
- **Configure Jitsi**: Use self-hosted Jitsi by updating `NEXT_PUBLIC_JITSI_DOMAIN`
- **Deploy**: See [DOCKER.md](DOCKER.md) for production deployment guide

## Support

- Full README: [README.md](README.md)
- Docker Guide: [DOCKER.md](DOCKER.md)
- Architecture: [CLAUDE.md](CLAUDE.md)

## Stopping the Application

```bash
./stack.sh stop
```

This stops all containers but keeps your data. To remove everything including data:

```bash
./stack.sh clean
```

---

**Ready to build your call center!** 🚀
