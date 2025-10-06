#!/bin/bash

# RunPod Deployment Script for CallWaiting.ai API
# This script sets up the API server on RunPod

set -e  # Exit on any error

echo "🚀 Deploying CallWaiting.ai API to RunPod..."

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

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install Python and pip if not present
print_status "Installing Python dependencies..."
apt install -y python3 python3-pip python3-venv

# Clone repository
print_status "Cloning CallWaiting.ai API repository..."
if [ ! -d "callwaiting-api" ]; then
    git clone https://github.com/Odiabackend099/callwaiting-api.git
    print_success "Repository cloned"
else
    print_warning "Repository already exists, updating..."
    cd callwaiting-api
    git pull
    cd ..
fi

cd callwaiting-api

# Create virtual environment
print_status "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
print_status "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
print_success "Dependencies installed"

# Create temp directory
print_status "Creating temporary audio directory..."
mkdir -p /tmp/callwaiting_audio
chmod 777 /tmp/callwaiting_audio
print_success "Temp directory created"

# Create systemd service
print_status "Creating systemd service..."
cat > /etc/systemd/system/callwaiting-api.service << 'EOF'
[Unit]
Description=CallWaiting.ai API Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/callwaiting-api
Environment=PATH=/root/callwaiting-api/venv/bin
ExecStart=/root/callwaiting-api/venv/bin/uvicorn server-runpod:app --host 0.0.0.0 --port 8787
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
print_status "Starting CallWaiting.ai API service..."
systemctl daemon-reload
systemctl enable callwaiting-api
systemctl start callwaiting-api

# Wait a moment for service to start
sleep 5

# Check service status
if systemctl is-active --quiet callwaiting-api; then
    print_success "CallWaiting.ai API service is running!"
else
    print_error "Failed to start CallWaiting.ai API service"
    systemctl status callwaiting-api
    exit 1
fi

# Test the API
print_status "Testing API endpoints..."
sleep 3

# Test health endpoint
if curl -s http://localhost:8787/ | grep -q "CallWaiting.ai API active"; then
    print_success "Health endpoint working"
else
    print_warning "Health endpoint test failed"
fi

# Get RunPod public IP
PUBLIC_IP=$(curl -s https://ipv4.icanhazip.com/ || echo "Unable to get public IP")
print_status "RunPod Public IP: $PUBLIC_IP"

# Create startup script
cat > start-api.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting CallWaiting.ai API on RunPod..."
systemctl start callwaiting-api
systemctl status callwaiting-api
EOF

chmod +x start-api.sh

# Create stop script
cat > stop-api.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping CallWaiting.ai API..."
systemctl stop callwaiting-api
EOF

chmod +x stop-api.sh

# Create status script
cat > status-api.sh << 'EOF'
#!/bin/bash
echo "📊 CallWaiting.ai API Status:"
systemctl status callwaiting-api --no-pager
echo ""
echo "🌐 API Endpoints:"
echo "Health: http://$(curl -s https://ipv4.icanhazip.com/):8787/"
echo "Twilio: http://$(curl -s https://ipv4.icanhazip.com/):8787/twilio/voice"
echo "Test: http://$(curl -s https://ipv4.icanhazip.com/):8787/test/tts"
EOF

chmod +x status-api.sh

print_success "Deployment completed!"
echo ""
echo "🎉 CallWaiting.ai API is now running on RunPod!"
echo ""
echo "📋 Management Commands:"
echo "  Start:   ./start-api.sh"
echo "  Stop:    ./stop-api.sh"
echo "  Status:  ./status-api.sh"
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
print_success "Ready for Twilio integration! 🚀"
