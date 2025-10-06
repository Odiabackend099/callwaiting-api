# CallWaiting.ai API Server

Bridge between Twilio Voice and RunPod TTS Engine for real-time voice synthesis.

## 🚀 Quick Start

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Run the Server
```bash
uvicorn server:app --host 0.0.0.0 --port 8787
```

### 3. Test Locally
Visit: http://localhost:8787
You should see: `{"status": "CallWaiting.ai API active"}`

## 🔧 Configuration

### Environment Variables (Optional)
- `TTS_URL`: Your RunPod TTS endpoint (default: `https://ud38nvz31mzxtr-8888.proxy.runpod.net/synthesize`)
- `AUTH_TOKEN`: Authentication token for TTS API (default: `cw_demo_12345`)
- `PORT`: Server port (default: `8787`)

### TTS Configuration
- **Voice Options**: `naija_female`, `naija_male`, etc.
- **Audio Format**: MP3
- **Timeout**: 60 seconds

## 📡 API Endpoints

### Health Check
- `GET /` - Basic status
- `GET /health` - Detailed health check

### Twilio Integration
- `POST /twilio/voice` - Main webhook for Twilio voice calls
- `GET /audio/{filename}` - Serve generated audio files

### Testing
- `POST /test/tts` - Test TTS functionality directly

## 🌐 Deployment Options

### Option 1: Local + ngrok (Recommended for Testing)
```bash
# Terminal 1: Start the server
uvicorn server:app --host 0.0.0.0 --port 8787

# Terminal 2: Expose with ngrok
ngrok http 8787
```

Copy the ngrok URL (e.g., `https://abcd1234.ngrok.io`) and set it in Twilio:
- **Voice Webhook URL**: `https://abcd1234.ngrok.io/twilio/voice`

### Option 2: VPS Deployment
```bash
# On your VPS
git clone <your-repo>
cd callwaiting-api
pip install -r requirements.txt
uvicorn server:app --host 0.0.0.0 --port 8787
```

### Option 3: Docker (Optional)
```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8787
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8787"]
```

## 🔄 Twilio Setup

1. **Get a Twilio Phone Number**
2. **Configure Webhook**:
   - Voice Webhook URL: `https://your-domain.com/twilio/voice`
   - HTTP Method: POST
3. **Test**: Call your Twilio number and speak

## 🧪 Testing

### Test TTS Directly
```bash
curl -X POST "http://localhost:8787/test/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, this is a test!", "voice": "naija_female"}'
```

### Test Twilio Webhook
```bash
curl -X POST "http://localhost:8787/twilio/voice" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "SpeechResult=Hello from Twilio&voice=naija_female"
```

## 📊 Monitoring

- **Logs**: Check console output for request/response logs
- **Health**: Visit `/health` endpoint for system status
- **Audio Files**: Stored in `/tmp/callwaiting_audio/` (auto-cleaned after 1 hour)

## 🛠️ Troubleshooting

### Common Issues

1. **TTS API Timeout**
   - Check RunPod endpoint is accessible
   - Verify authentication token
   - Check network connectivity

2. **Audio Not Playing**
   - Verify audio file is generated
   - Check TwiML response format
   - Test audio URL directly

3. **ngrok Issues**
   - Ensure ngrok is running
   - Check firewall settings
   - Verify port 8787 is accessible

### Debug Mode
```bash
# Run with debug logging
uvicorn server:app --host 0.0.0.0 --port 8787 --log-level debug
```

## 🔒 Security Notes

- Change default `AUTH_TOKEN` in production
- Use HTTPS in production (ngrok provides this)
- Consider rate limiting for production use
- Clean up temporary audio files regularly

## 📈 Performance

- **Latency**: ~2-5 seconds for TTS generation
- **Concurrent Calls**: Limited by RunPod TTS capacity
- **Storage**: Audio files auto-cleanup after 1 hour
- **Memory**: Minimal footprint (~50MB)

## 🆘 Support

For issues:
1. Check logs in console
2. Test TTS endpoint directly
3. Verify Twilio webhook configuration
4. Check RunPod TTS service status
