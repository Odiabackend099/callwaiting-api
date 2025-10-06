from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import FileResponse, PlainTextResponse
import httpx
import os
import uuid
import logging
from pathlib import Path
import tempfile

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# RunPod Configuration - Use local TTS service
TTS_URL = "http://localhost:8888/synthesize"  # Local TTS service
AUTH_TOKEN = "cw_demo_12345"
TEMP_DIR = Path("/tmp/callwaiting_audio")

# Ensure temp directory exists
TEMP_DIR.mkdir(exist_ok=True)

app = FastAPI(
    title="CallWaiting.ai API - RunPod",
    description="Bridge between Twilio and RunPod TTS Engine",
    version="1.0.0"
)

@app.get("/")
def home():
    """Health check endpoint"""
    return {
        "status": "CallWaiting.ai API active on RunPod",
        "tts_url": TTS_URL,
        "version": "1.0.0",
        "deployment": "runpod"
    }

@app.get("/health")
def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "tts_endpoint": TTS_URL,
        "temp_dir": str(TEMP_DIR),
        "temp_dir_exists": TEMP_DIR.exists(),
        "deployment": "runpod"
    }

@app.post("/twilio/voice")
async def twilio_voice(request: Request):
    """
    Main Twilio webhook endpoint
    Receives voice data from Twilio and returns TTS audio
    """
    try:
        # Parse form data from Twilio
        data = await request.form()
        text = data.get("SpeechResult", "Hello, thank you for calling ODIADEV.")
        voice = data.get("voice", "naija_female")  # Allow voice override
        
        logger.info(f"Received Twilio request: text='{text[:50]}...', voice='{voice}'")
        
        # Generate unique filename
        audio_filename = f"{uuid.uuid4()}.mp3"
        temp_file = TEMP_DIR / audio_filename
        
        # Call TTS API (local on RunPod)
        async with httpx.AsyncClient(timeout=60) as client:
            try:
                response = await client.post(
                    TTS_URL,
                    headers={"Authorization": f"Bearer {AUTH_TOKEN}"},
                    files={
                        "text": (None, text),
                        "voice_id": (None, voice)
                    },
                )
                response.raise_for_status()
                
                # Save audio file
                with open(temp_file, "wb") as f:
                    f.write(response.content)
                
                logger.info(f"TTS audio saved: {temp_file}")
                
            except httpx.HTTPError as e:
                logger.error(f"TTS API error: {e}")
                raise HTTPException(status_code=500, detail=f"TTS service error: {e}")
        
        # Generate TwiML response
        audio_url = request.url_for('serve_audio', filename=audio_filename)
        twiml = f"""<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Play>{audio_url}</Play>
</Response>"""
        
        return PlainTextResponse(twiml, media_type="text/xml")
        
    except Exception as e:
        logger.error(f"Error processing Twilio request: {e}")
        # Return error TwiML
        error_twiml = """<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say>Sorry, there was an error processing your request.</Say>
</Response>"""
        return PlainTextResponse(error_twiml, media_type="text/xml")

@app.get("/audio/{filename}")
async def serve_audio(filename: str):
    """
    Serve audio files to Twilio
    """
    try:
        file_path = TEMP_DIR / filename
        
        if not file_path.exists():
            logger.warning(f"Audio file not found: {filename}")
            raise HTTPException(status_code=404, detail="Audio file not found")
        
        # Clean up old files (older than 1 hour)
        cleanup_old_files()
        
        return FileResponse(
            file_path, 
            media_type="audio/mpeg",
            filename=filename
        )
        
    except Exception as e:
        logger.error(f"Error serving audio {filename}: {e}")
        raise HTTPException(status_code=500, detail="Error serving audio")

@app.post("/test/tts")
async def test_tts(text: str = "Hello, this is a test of the TTS system.", voice: str = "naija_female"):
    """
    Test endpoint to verify TTS functionality
    """
    try:
        temp_file = TEMP_DIR / f"test_{uuid.uuid4()}.mp3"
        
        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(
                TTS_URL,
                headers={"Authorization": f"Bearer {AUTH_TOKEN}"},
                files={
                    "text": (None, text),
                    "voice_id": (None, voice)
                },
            )
            response.raise_for_status()
            
            with open(temp_file, "wb") as f:
                f.write(response.content)
        
        return {
            "status": "success",
            "text": text,
            "voice": voice,
            "audio_file": str(temp_file),
            "file_size": temp_file.stat().st_size,
            "deployment": "runpod"
        }
        
    except Exception as e:
        logger.error(f"TTS test error: {e}")
        raise HTTPException(status_code=500, detail=f"TTS test failed: {e}")

def cleanup_old_files(max_age_hours: int = 1):
    """
    Clean up old audio files to prevent disk space issues
    """
    try:
        import time
        current_time = time.time()
        max_age_seconds = max_age_hours * 3600
        
        for file_path in TEMP_DIR.glob("*.mp3"):
            if current_time - file_path.stat().st_mtime > max_age_seconds:
                file_path.unlink()
                logger.info(f"Cleaned up old file: {file_path.name}")
                
    except Exception as e:
        logger.error(f"Error cleaning up files: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8787)
