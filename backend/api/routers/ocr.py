from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Request, Depends
from fastapi.responses import JSONResponse
from PIL import Image
import io
import shutil
import os

from modules.ocr import OCRModule
from modules.database import save_task
from api.routers.history import get_current_user

router = APIRouter()
ocr_module = OCRModule()

@router.post("/extract")
async def extract_text(
    file: UploadFile = File(...), 
    mode: str = Form("standard"),
    use_ai_correction: bool = Form(True),
    userId: str = Depends(get_current_user)
):
    try:
        # Read image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        text = ""
        if mode == "high_accuracy":
            text = ocr_module.perform_high_accuracy_ocr(image)
        else:
            text = ocr_module.perform_ocr(image)
            
        if use_ai_correction:
            # Note: ocr_module already calls Gemini in the refined version, 
            # but we can call it again or ensure it's handled.
            # In the previous steps I integrated Gemini into ocr_module directly.
            pass
            
        # Save to history if logged in
        if userId:
            await save_task(userId, "ocr", file.filename, text)
            
        return {"text": text, "mode": mode}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
