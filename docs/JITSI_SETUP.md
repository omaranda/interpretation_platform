# Jitsi Meet Docker Integration

## Overview

Jitsi Meet has been successfully integrated into the Call Center platform. It consists of 4 Docker containers working together to provide video conferencing capabilities.

## Architecture

### Services

1. **jitsi-web** - Web interface (Port 8443)
   - Serves the Jitsi Meet web application
   - Nginx-based frontend
   - Accessible at: http://localhost:8443

2. **jitsi-prosody** - XMPP Server
   - Handles signaling and room management
   - Internal service (not exposed)

3. **jitsi-jicofo** - Conference Focus
   - Manages media sessions
   - Coordinates between participants
   - Internal service (not exposed)

4. **jitsi-jvb** - Video Bridge
   - Handles actual media routing
   - UDP port 10000 for media
   - TCP port 4443 for fallback

## Configuration

### Directory Structure

```
jitsi-meet/
├── .env                          # Main configuration file
├── web/                          # Web interface config
├── transcripts/                  # Meeting transcripts
├── prosody/
│   ├── config/                   # Prosody XMPP config
│   └── prosody-plugins-custom/   # Custom plugins
├── jicofo/                       # Jicofo config
├── jvb/                          # JVB config
├── jigasi/                       # SIP gateway (optional)
└── jibri/                        # Recording service (optional)
```

### Key Configuration Settings

Located in `jitsi-meet/.env`:

```bash
# Security
ENABLE_AUTH=0              # No authentication required
ENABLE_GUESTS=1            # Guests can join

# Domains
XMPP_DOMAIN=meet.jitsi
PUBLIC_URL=http://localhost:8443

# Features
ENABLE_RECORDING=0         # Recording disabled
ENABLE_TRANSCRIPTIONS=0    # Transcriptions disabled
ENABLE_WELCOME_PAGE=1      # Show welcome page

# Network
DISABLE_HTTPS=1            # HTTP only (for local development)
```

## Usage

### Starting Jitsi

```bash
# Start all services (including Jitsi)
./stack.sh start

# Or start only Jitsi services
docker-compose up -d jitsi-prosody jitsi-jicofo jitsi-jvb jitsi-web
```

### Stopping Jitsi

```bash
# Stop all services
./stack.sh stop

# Or stop only Jitsi services
docker-compose stop jitsi-web jitsi-prosody jitsi-jicofo jitsi-jvb
```

### Viewing Logs

```bash
# View all Jitsi logs
./stack.sh logs jitsi

# View specific component logs
./stack.sh logs prosody
./stack.sh logs jicofo
./stack.sh logs jvb
```

### Checking Status

```bash
# Check all services including Jitsi
./stack.sh status
```

## Frontend Integration

The frontend has been configured to use the local Jitsi instance:

```typescript
// In frontend environment
NEXT_PUBLIC_JITSI_DOMAIN=localhost:8443
```

## Creating a Video Call

### Using the Web Interface

1. Open http://localhost:8443
2. Enter a room name
3. Click "Go" or press Enter
4. Allow camera/microphone permissions
5. Share the room URL with participants

### Using the Frontend Component

The JitsiCall component in the frontend (`frontend/src/components/JitsiCall.tsx`) integrates with the local Jitsi server:

```typescript
<JitsiCall
  roomName="your-room-name"
  displayName="User Name"
  onReadyToClose={() => {}}
/>
```

## Ports

- **8443** - Jitsi web interface (HTTP)
- **8444** - Jitsi HTTPS (not used in development)
- **10000/UDP** - Media streaming (JVB)
- **4443/TCP** - Fallback media port (JVB)

## Network Configuration

All Jitsi services are connected to the `callcenter-network` Docker network, allowing them to communicate with each other and with other services (backend, frontend).

## Troubleshooting

### Jitsi web not starting

```bash
# Check logs
docker logs callcenter-jitsi-web

# Remove config and restart
docker-compose stop jitsi-web
rm -rf jitsi-meet/web/*
docker-compose start jitsi-web
```

### Can't connect to video call

1. Check that all 4 Jitsi containers are running:
   ```bash
   docker-compose ps | grep jitsi
   ```

2. Verify UDP port 10000 is accessible:
   ```bash
   sudo netstat -tulpn | grep 10000
   ```

3. Check firewall settings allow UDP/10000

### Media not working

- Ensure browser has camera/microphone permissions
- Check that UDP port 10000 is not blocked
- Try using TCP fallback (port 4443)

## Advanced Features (Disabled by Default)

### Recording (Jibri)

To enable recording:
1. Set `ENABLE_RECORDING=1` in `jitsi-meet/.env`
2. Uncomment Jibri service in `docker-compose.yml`
3. Restart services

### Authentication

To enable authentication:
1. Set `ENABLE_AUTH=1` in `jitsi-meet/.env`
2. Set `ENABLE_GUESTS=0` for no guest access
3. Create users via Prosody

### SIP Gateway (Jigasi)

To enable SIP calling:
1. Configure SIP credentials in `jitsi-meet/.env`
2. Uncomment Jigasi service in `docker-compose.yml`
3. Restart services

## Security Notes

⚠️ **Development Configuration** ⚠️

This setup is configured for local development:
- HTTPS is disabled
- Authentication is disabled
- All services are accessible without credentials

For production deployment:
- Enable HTTPS with valid certificates
- Enable authentication
- Configure firewall rules
- Use strong passwords for all services
- Consider using Jitsi's JWT authentication

## Resources

- Official Jitsi Docker Setup: https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker
- Jitsi Meet Handbook: https://jitsi.github.io/handbook/
- Docker Images: https://hub.docker.com/u/jitsi

## Maintenance

### Updating Jitsi

To update to the latest stable version:

```bash
# Stop services
./stack.sh stop

# Pull latest images
docker-compose pull jitsi-web jitsi-prosody jitsi-jicofo jitsi-jvb

# Restart services
./stack.sh start
```

### Cleaning Up

To completely remove Jitsi and start fresh:

```bash
# Stop and remove containers
docker-compose stop jitsi-web jitsi-prosody jitsi-jicofo jitsi-jvb
docker-compose rm -f jitsi-web jitsi-prosody jitsi-jicofo jitsi-jvb

# Remove configuration
rm -rf jitsi-meet/{web,prosody,jicofo,jvb}/*

# Start fresh
./stack.sh start
```
