from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
from fastapi.responses import FileResponse
from pydantic import BaseModel
import io
import os
from modules.speech_language import LanguageToolkit
from modules.database import save_task
from api.routers.history import get_current_user


router = APIRouter()
toolkit = LanguageToolkit()

@router.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...), userId: str = Depends(get_current_user)):
    try:
        content = await file.read()
        text = toolkit.transcribe_audio(content)
        
        # Auto-refine if it's a decent length
        if len(text) > 5:
             # This is actually already called in speech_language.py in the refined version, 
             # but we can keep it here or ensure it's not redundant.
             pass
             
        # Save to history
        if userId:
            await save_task(userId, "transcription", file.filename, text)
            
        return {"text": text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/voices")
async def get_voices():
    # Prioritize Neural Voices
    voices = await toolkit.get_neural_voices()
    if not voices:
       # Fallback to system voices
       voices = toolkit.get_voices()
    return {"voices": voices}

class TTSRequest(BaseModel):
    text: str
    voice_id: str = "en-US-ChristopherNeural" # Default valid neural voice

@router.post("/tts")
async def text_to_speech(request: TTSRequest):
    try:
        # Use Neural TTS
        output_file = await toolkit.text_to_speech_neural(request.text, voice_id=request.voice_id)
        
        if not output_file:
             # Fallback to legacy
             output_file = toolkit.text_to_speech(request.text, voice_id=request.voice_id)

        if output_file and os.path.exists(output_file):
            # Edge TTS is mp3, fallback is wav
            media_type = "audio/mpeg" if output_file.endswith(".mp3") else "audio/wav"
            filename = "speech.mp3" if output_file.endswith(".mp3") else "speech.wav"
            return FileResponse(output_file, media_type=media_type, filename=filename)
            
        return {"error": "TTS failed"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class TranslateRequest(BaseModel):
    text: str
    target_lang: str = "hi"

@router.post("/translate")
async def translate_text(request: TranslateRequest, userId: str = Depends(get_current_user)):
    try:
        # Default source is auto/en
        translated = toolkit.translate_text(request.text, to_code=request.target_lang)
        
        # Save to history
        if userId:
            await save_task(userId, "translation", request.text[:100], translated)
            
        return {"translated_text": translated}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
