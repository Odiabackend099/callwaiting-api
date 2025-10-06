#!/bin/bash

# Quick RunPod Deployment Script
# This script sets up auto-restart monitoring for CallWaiting.ai API

set -e

echo "🚀 Quick Deploy: CallWaiting.ai API with Auto-Restart"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Update system
print_status "Updating system..."
apt update -y

# Install git if not present
apt install -y git

# Clone repository
print_status "Cloning CallWaiting.ai API..."
if [ ! -d "/root/callwaiting-api" ]; then
    git clone https://github.com/Odiabackend099/callwaiting-api.git /root/callwaiting-api
else
    cd /root/callwaiting-api
    git pull
fi

cd /root/callwaiting-api

# Install Python dependencies
print_status "Installing dependencies..."
apt install -y python3 python3-pip python3-venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Make scripts executable
chmod +x auto-restart.sh
chmod +x runpod-deploy.sh

# Create log directory
mkdir -p /var/log
touch /var/log/callwaiting-api.log

# Install systemd service
print_status "Installing auto-restart service..."
cp runpod-systemd.service /etc/systemd/system/callwaiting-monitor.service
systemctl daemon-reload
systemctl enable callwaiting-monitor
systemctl start callwaiting-monitor

# Wait for service to start
sleep 5

# Check status
if systemctl is-active --quiet callwaiting-monitor; then
    print_success "Auto-restart monitor is running!"
else
    echo "❌ Failed to start monitor service"
    systemctl status callwaiting-monitor
    exit 1
fi

# Get public IP
PUBLIC_IP=$(curl -s https://ipv4.icanhazip.com/ || echo "Unable to get IP")

print_success "Deployment completed!"
echo ""
echo "🎉 CallWaiting.ai API is now running with auto-restart!"
echo ""
echo "📋 Management Commands:"
echo "  Status:  systemctl status callwaiting-monitor"
echo "  Logs:    journalctl -u callwaiting-monitor -f"
echo "  Restart: systemctl restart callwaiting-monitor"
echo "  Stop:    systemctl stop callwaiting-monitor"
echo ""
echo "🌐 API Endpoints:"
echo "  Health:  http://$PUBLIC_IP:8787/"
echo "  Twilio:  http://$PUBLIC_IP:8787/twilio/voice"
echo "  Test:    http://$PUBLIC_IP:8787/test/tts"
echo ""
echo "🔧 Twilio Configuration:"
echo "  Webhook URL: http://$PUBLIC_IP:8787/twilio/voice"
echo "  HTTP Method: POST"
echo ""
echo "📊 Auto-Restart Features:"
echo "  ✅ Auto-restarts on crashes"
echo "  ✅ Health monitoring every 30 seconds"
echo "  ✅ Maximum 10 restart attempts"
echo "  ✅ Auto-updates from GitHub"
echo "  ✅ Comprehensive logging"
echo ""
print_success "Ready for production use! 🚀"
