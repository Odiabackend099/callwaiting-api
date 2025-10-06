# 🚀 Deployment Guide

## Quick Deploy Commands

After creating your GitHub repository, run these commands:

```bash
# Add remote origin (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/callwaiting-api.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## 🌐 Deploy to VPS/Cloud

### Option 1: Deploy to any VPS
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/callwaiting-api.git
cd callwaiting-api

# Run setup
chmod +x setup.sh
./setup.sh

# Start server
./start_server.sh
```

### Option 2: Deploy to Railway
1. Connect your GitHub repo to Railway
2. Railway will auto-detect Python and install dependencies
3. Set environment variables if needed
4. Deploy!

### Option 3: Deploy to Render
1. Connect your GitHub repo to Render
2. Choose "Web Service"
3. Build command: `pip install -r requirements.txt`
4. Start command: `uvicorn server:app --host 0.0.0.0 --port $PORT`

### Option 4: Deploy to Heroku
```bash
# Install Heroku CLI
# Create Procfile
echo "web: uvicorn server:app --host 0.0.0.0 --port \$PORT" > Procfile

# Deploy
heroku create your-app-name
git push heroku main
```

## 🔧 Environment Variables

Set these in your deployment platform:

- `TTS_URL`: Your RunPod TTS endpoint
- `AUTH_TOKEN`: Your TTS authentication token
- `PORT`: Server port (usually set by platform)

## 📱 Twilio Configuration

Once deployed, set your webhook URL in Twilio:
- **Voice Webhook URL**: `https://your-deployed-app.com/twilio/voice`
- **HTTP Method**: POST

## 🧪 Testing Deployment

```bash
# Health check
curl https://your-deployed-app.com/

# TTS test
curl -X POST "https://your-deployed-app.com/test/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from deployed API!", "voice": "naija_female"}'
```
