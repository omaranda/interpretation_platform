#!/bin/bash

# Call Center Stack Management Script
# Usage: ./stack.sh [start|stop|restart|status|logs|build|clean]

set -e

PROJECT_NAME="callcenter"
DOCKER_COMPOSE_FILE="docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if docker and docker-compose are installed
check_dependencies() {
    if ! command -v docker &> /dev/null; then
        print_message "$RED" "Error: Docker is not installed"
        exit 1
    fi

    if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
        print_message "$RED" "Error: Docker Compose is not installed"
        exit 1
    fi
}

# Get docker compose command (supports both docker-compose and docker compose)
get_compose_cmd() {
    if command -v docker compose &> /dev/null; then
        echo "docker compose"
    else
        echo "docker-compose"
    fi
}

# Setup Jitsi directories and configuration
setup_jitsi() {
    print_message "$BLUE" "🎥 Setting up Jitsi Meet configuration..."

    # Create Jitsi directories
    mkdir -p jitsi-meet/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}

    # Check if Jitsi .env exists
    if [ ! -f jitsi-meet/.env ]; then
        print_message "$YELLOW" "⚠️  Jitsi .env file not found. It should already exist."
    fi

    # Set proper permissions
    chmod -R 777 jitsi-meet/

    print_message "$GREEN" "✓ Jitsi directories created successfully!"
}

# Start the stack
start() {
    print_message "$BLUE" "🚀 Starting Call Center stack..."

    # Check if .env file exists, if not create from .env.docker
    if [ ! -f .env ]; then
        print_message "$YELLOW" "⚠️  .env file not found. Creating from .env.docker..."
        cp .env.docker .env
        print_message "$GREEN" "✓ Created .env file. Please review and update as needed."
    fi

    # Setup Jitsi if needed
    if [ ! -d jitsi-meet/web ]; then
        setup_jitsi
    fi

    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE up -d

    print_message "$GREEN" "✓ Call Center stack started successfully!"
    echo ""
    print_message "$BLUE" "📍 Services available at:"
    echo "   - Frontend: http://localhost:3000"
    echo "   - Backend API: http://localhost:8000"
    echo "   - API Docs: http://localhost:8000/docs"
    echo "   - Database: localhost:5432"
    echo "   - Jitsi Meet: http://localhost:8443"
    echo ""
    print_message "$YELLOW" "💡 Run './stack.sh logs' to view logs"
    print_message "$YELLOW" "💡 Run './stack.sh status' to check services status"
}

# Stop the stack
stop() {
    print_message "$BLUE" "🛑 Stopping Call Center stack..."

    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE down

    print_message "$GREEN" "✓ Call Center stack stopped successfully!"
}

# Restart the stack
restart() {
    print_message "$BLUE" "🔄 Restarting Call Center stack..."
    stop
    sleep 2
    start
}

# Show status of all services
status() {
    print_message "$BLUE" "📊 Call Center stack status:"
    echo ""

    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE ps

    echo ""
    print_message "$BLUE" "🏥 Health checks:"

    # Check database
    if docker exec callcenter-postgres pg_isready -U callcenter &> /dev/null; then
        print_message "$GREEN" "✓ Database: Healthy"
    else
        print_message "$RED" "✗ Database: Unhealthy"
    fi

    # Check backend
    if curl -s http://localhost:8000/health &> /dev/null; then
        print_message "$GREEN" "✓ Backend: Healthy"
    else
        print_message "$RED" "✗ Backend: Unhealthy or not responding"
    fi

    # Check frontend
    if curl -s http://localhost:3000 &> /dev/null; then
        print_message "$GREEN" "✓ Frontend: Healthy"
    else
        print_message "$RED" "✗ Frontend: Unhealthy or not responding"
    fi

    # Check Jitsi
    if curl -s http://localhost:8443 &> /dev/null; then
        print_message "$GREEN" "✓ Jitsi Meet: Healthy"
    else
        print_message "$RED" "✗ Jitsi Meet: Unhealthy or not responding"
    fi
}

# Show logs
logs() {
    local service=$2

    COMPOSE_CMD=$(get_compose_cmd)

    if [ -z "$service" ]; then
        print_message "$BLUE" "📋 Showing logs for all services (press Ctrl+C to exit)..."
        $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE logs -f
    else
        case $service in
            db|database|postgres)
                print_message "$BLUE" "📋 Showing logs for database..."
                $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE logs -f postgres
                ;;
            backend|api)
                print_message "$BLUE" "📋 Showing logs for backend..."
                $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE logs -f backend
                ;;
            frontend|web)
                print_message "$BLUE" "📋 Showing logs for frontend..."
                $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE logs -f frontend
                ;;
            jitsi|jitsi-web)
                print_message "$BLUE" "📋 Showing logs for Jitsi web..."
                $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE logs -f jitsi-web
                ;;
            jitsi-prosody|prosody)
                print_message "$BLUE" "📋 Showing logs for Jitsi Prosody..."
                $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE logs -f jitsi-prosody
                ;;
            jitsi-jicofo|jicofo)
                print_message "$BLUE" "📋 Showing logs for Jitsi Jicofo..."
                $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE logs -f jitsi-jicofo
                ;;
            jitsi-jvb|jvb)
                print_message "$BLUE" "📋 Showing logs for Jitsi JVB..."
                $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE logs -f jitsi-jvb
                ;;
            *)
                print_message "$RED" "Error: Unknown service '$service'"
                print_message "$YELLOW" "Available services: database, backend, frontend, jitsi, prosody, jicofo, jvb"
                exit 1
                ;;
        esac
    fi
}

# Build images
build() {
    print_message "$BLUE" "🔨 Building Docker images..."

    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE build --no-cache

    print_message "$GREEN" "✓ Images built successfully!"
}

# Clean up everything (including volumes)
clean() {
    print_message "$YELLOW" "⚠️  This will remove all containers, volumes, and data!"
    read -p "Are you sure? (yes/no): " -r
    echo

    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        print_message "$BLUE" "🧹 Cleaning up..."

        COMPOSE_CMD=$(get_compose_cmd)
        $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE down -v --remove-orphans

        print_message "$GREEN" "✓ Cleanup completed!"
    else
        print_message "$YELLOW" "Cleanup cancelled."
    fi
}

# Execute command in a service
exec_service() {
    local service=$2
    shift 2
    local cmd="$@"

    COMPOSE_CMD=$(get_compose_cmd)

    case $service in
        db|database|postgres)
            $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE exec postgres $cmd
            ;;
        backend|api)
            $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE exec backend $cmd
            ;;
        frontend|web)
            $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE exec frontend $cmd
            ;;
        jitsi|jitsi-web)
            $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE exec jitsi-web $cmd
            ;;
        jitsi-prosody|prosody)
            $COMPOSE_CMD -f $DOCKER_COMPOSE_FILE exec jitsi-prosody $cmd
            ;;
        *)
            print_message "$RED" "Error: Unknown service '$service'"
            exit 1
            ;;
    esac
}

# Database backup
backup_db() {
    print_message "$BLUE" "💾 Creating database backup..."

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="backups/callcenter_${TIMESTAMP}.sql"

    mkdir -p backups
    docker exec callcenter-postgres pg_dump -U callcenter callcenter > $BACKUP_FILE

    print_message "$GREEN" "✓ Database backed up to: $BACKUP_FILE"
}

# Database restore
restore_db() {
    local backup_file=$2

    if [ -z "$backup_file" ]; then
        print_message "$RED" "Error: Please specify backup file"
        print_message "$YELLOW" "Usage: ./stack.sh restore <backup_file>"
        exit 1
    fi

    if [ ! -f "$backup_file" ]; then
        print_message "$RED" "Error: Backup file not found: $backup_file"
        exit 1
    fi

    print_message "$YELLOW" "⚠️  This will restore the database from: $backup_file"
    read -p "Are you sure? (yes/no): " -r
    echo

    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        print_message "$BLUE" "📥 Restoring database..."
        docker exec -i callcenter-postgres psql -U callcenter callcenter < $backup_file
        print_message "$GREEN" "✓ Database restored successfully!"
    else
        print_message "$YELLOW" "Restore cancelled."
    fi
}

# Show help
show_help() {
    echo "Call Center Stack Management"
    echo ""
    echo "Usage: ./stack.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  start              Start all services"
    echo "  stop               Stop all services"
    echo "  restart            Restart all services"
    echo "  status             Show status of all services"
    echo "  logs [service]     Show logs (all or specific service)"
    echo "  build              Build Docker images"
    echo "  clean              Remove all containers and volumes"
    echo "  exec <service> <command>  Execute command in service"
    echo "  backup             Backup database"
    echo "  restore <file>     Restore database from backup"
    echo "  help               Show this help message"
    echo ""
    echo "Services: database, backend, frontend, jitsi, prosody, jicofo, jvb"
    echo ""
    echo "Examples:"
    echo "  ./stack.sh start"
    echo "  ./stack.sh logs backend"
    echo "  ./stack.sh logs jitsi"
    echo "  ./stack.sh exec backend bash"
    echo "  ./stack.sh backup"
    echo "  ./stack.sh restore backups/callcenter_20231215_120000.sql"
    echo ""
    echo "Jitsi Meet is available at: http://localhost:8443"
}

# Main script
main() {
    check_dependencies

    local command=${1:-help}

    case $command in
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        status)
            status
            ;;
        logs)
            logs "$@"
            ;;
        build)
            build
            ;;
        clean)
            clean
            ;;
        exec)
            exec_service "$@"
            ;;
        backup)
            backup_db
            ;;
        restore)
            restore_db "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_message "$RED" "Error: Unknown command '$command'"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
