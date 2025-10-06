#!/bin/bash

# CallWaiting.ai API Auto-Restart Script
# This script ensures your API is always running on RunPod

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Configuration
API_DIR="/root/callwaiting-api"
API_PORT=8787
LOG_FILE="/var/log/callwaiting-api.log"
PID_FILE="/var/run/callwaiting-api.pid"
MAX_RESTARTS=10
RESTART_COUNT=0

# Function to check if API is running
check_api() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            # Check if it's actually responding
            if curl -s -f "http://localhost:$API_PORT/" > /dev/null 2>&1; then
                return 0
            else
                print_warning "API process exists but not responding"
                return 1
            fi
        else
            print_warning "Stale PID file found"
            rm -f "$PID_FILE"
            return 1
        fi
    else
        return 1
    fi
}

# Function to start the API
start_api() {
    print_status "Starting CallWaiting.ai API..."
    
    cd "$API_DIR"
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Start the API in background
    nohup uvicorn server-runpod:app --host 0.0.0.0 --port $API_PORT > "$LOG_FILE" 2>&1 &
    API_PID=$!
    
    # Save PID
    echo $API_PID > "$PID_FILE"
    
    # Wait a moment for startup
    sleep 5
    
    # Check if it started successfully
    if check_api; then
        print_success "API started successfully (PID: $API_PID)"
        return 0
    else
        print_error "Failed to start API"
        return 1
    fi
}

# Function to stop the API
stop_api() {
    print_status "Stopping CallWaiting.ai API..."
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            kill "$PID"
            sleep 3
            
            # Force kill if still running
            if ps -p "$PID" > /dev/null 2>&1; then
                kill -9 "$PID"
                print_warning "Force killed API process"
            fi
        fi
        rm -f "$PID_FILE"
    fi
    
    print_success "API stopped"
}

# Function to restart the API
restart_api() {
    print_status "Restarting CallWaiting.ai API..."
    stop_api
    sleep 2
    start_api
}

# Function to check API health
health_check() {
    if curl -s -f "http://localhost:$API_PORT/health" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to update from GitHub
update_from_github() {
    print_status "Updating from GitHub..."
    
    cd "$API_DIR"
    
    # Pull latest changes
    git pull origin main
    
    # Restart to apply changes
    restart_api
    
    print_success "Updated and restarted"
}

# Main monitoring loop
monitor_loop() {
    print_status "Starting CallWaiting.ai API monitor..."
    print_status "API Directory: $API_DIR"
    print_status "API Port: $API_PORT"
    print_status "Log File: $LOG_FILE"
    
    # Ensure API directory exists
    if [ ! -d "$API_DIR" ]; then
        print_error "API directory not found: $API_DIR"
        print_status "Cloning repository..."
        git clone https://github.com/Odiabackend099/callwaiting-api.git "$API_DIR"
        cd "$API_DIR"
        chmod +x runpod-deploy.sh
        ./runpod-deploy.sh
    fi
    
    # Start API if not running
    if ! check_api; then
        start_api
    fi
    
    # Main monitoring loop
    while true; do
        if ! check_api; then
            RESTART_COUNT=$((RESTART_COUNT + 1))
            
            if [ $RESTART_COUNT -gt $MAX_RESTARTS ]; then
                print_error "Maximum restart attempts reached ($MAX_RESTARTS)"
                print_error "Please check the logs: $LOG_FILE"
                exit 1
            fi
            
            print_warning "API not running, restarting... (attempt $RESTART_COUNT/$MAX_RESTARTS)"
            start_api
            
            if [ $? -eq 0 ]; then
                RESTART_COUNT=0  # Reset counter on successful restart
            fi
        else
            # Reset restart counter on successful check
            RESTART_COUNT=0
            
            # Optional: Health check every 5 minutes
            if ! health_check; then
                print_warning "Health check failed, restarting API..."
                restart_api
            fi
        fi
        
        # Wait before next check
        sleep 30
    done
}

# Handle signals
cleanup() {
    print_status "Received shutdown signal, stopping API..."
    stop_api
    exit 0
}

trap cleanup SIGTERM SIGINT

# Main script logic
case "${1:-monitor}" in
    "start")
        start_api
        ;;
    "stop")
        stop_api
        ;;
    "restart")
        restart_api
        ;;
    "status")
        if check_api; then
            print_success "API is running"
            PID=$(cat "$PID_FILE")
            echo "PID: $PID"
            echo "Port: $API_PORT"
            echo "Log: $LOG_FILE"
        else
            print_error "API is not running"
        fi
        ;;
    "update")
        update_from_github
        ;;
    "monitor")
        monitor_loop
        ;;
    "logs")
        tail -f "$LOG_FILE"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|update|monitor|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the API"
        echo "  stop    - Stop the API"
        echo "  restart - Restart the API"
        echo "  status  - Check API status"
        echo "  update  - Update from GitHub and restart"
        echo "  monitor - Start monitoring loop (default)"
        echo "  logs    - Show live logs"
        exit 1
        ;;
esac
