#!/bin/bash

# CallWaiting.ai API Setup Script
# This script sets up the complete environment for the TTS-Twilio bridge

set -e  # Exit on any error

echo "🚀 Setting up CallWaiting.ai API Server..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if Python 3 is installed
print_status "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
print_success "Python $PYTHON_VERSION found"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    print_error "pip3 is not installed. Please install pip first."
    exit 1
fi

# Create virtual environment
print_status "Creating virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_warning "Virtual environment already exists"
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
print_status "Installing dependencies..."
pip install -r requirements.txt
print_success "Dependencies installed"

# Create temp directory
print_status "Creating temporary audio directory..."
mkdir -p /tmp/callwaiting_audio
print_success "Temp directory created"

# Test TTS endpoint connectivity
print_status "Testing TTS endpoint connectivity..."
TTS_URL="https://ud38nvz31mzxtr-8888.proxy.runpod.net/synthesize"
if curl -s --head "$TTS_URL" | head -n 1 | grep -q "200 OK"; then
    print_success "TTS endpoint is accessible"
else
    print_warning "TTS endpoint may not be accessible. Please check your RunPod instance."
fi

# Create startup script
print_status "Creating startup script..."
cat > start_server.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting CallWaiting.ai API Server..."
source venv/bin/activate
uvicorn server:app --host 0.0.0.0 --port 8787 --reload
EOF

chmod +x start_server.sh
print_success "Startup script created"

# Create ngrok setup script
print_status "Creating ngrok setup script..."
cat > start_with_ngrok.sh << 'EOF'
#!/bin/bash
echo "🌐 Starting server with ngrok tunnel..."

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok is not installed. Please install ngrok first:"
    echo "   brew install ngrok/ngrok/ngrok  # macOS"
    echo "   or download from https://ngrok.com/download"
    exit 1
fi

# Start server in background
echo "🚀 Starting API server..."
source venv/bin/activate
uvicorn server:app --host 0.0.0.0 --port 8787 &
SERVER_PID=$!

# Wait a moment for server to start
sleep 3

# Start ngrok tunnel
echo "🌐 Starting ngrok tunnel..."
ngrok http 8787

# Cleanup on exit
trap "kill $SERVER_PID" EXIT
EOF

chmod +x start_with_ngrok.sh
print_success "ngrok setup script created"

# Create test script
print_status "Creating test script..."
cat > test_api.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing CallWaiting.ai API..."

# Test health endpoint
echo "Testing health endpoint..."
curl -s http://localhost:8787/ | jq '.' || echo "Health check failed"

# Test TTS endpoint
echo "Testing TTS endpoint..."
curl -X POST "http://localhost:8787/test/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, this is a test of the TTS system!", "voice": "naija_female"}' \
  | jq '.' || echo "TTS test failed"

echo "✅ API tests completed"
EOF

chmod +x test_api.sh
print_success "Test script created"

# Final instructions
echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Start the server:"
echo "   ./start_server.sh"
echo ""
echo "2. Or start with ngrok tunnel:"
echo "   ./start_with_ngrok.sh"
echo ""
echo "3. Test the API:"
echo "   ./test_api.sh"
echo ""
echo "4. Configure Twilio webhook:"
echo "   URL: https://your-ngrok-url.ngrok.io/twilio/voice"
echo ""
echo "📖 For detailed instructions, see README.md"
echo ""
print_success "CallWaiting.ai API is ready to deploy! 🚀"
