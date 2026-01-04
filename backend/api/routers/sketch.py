from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Response
import shutil
import os
import uuid
from pathlib import Path
from modules.sketch import SketchModule
from modules.database import save_task
from api.routers.history import get_current_user

router = APIRouter()
sketch_module = SketchModule()

@router.post("/vectorize")
async def vectorize_sketch(file: UploadFile = File(...), userId: str = Depends(get_current_user)):
    try:
        # Read file to bytes
        content = await file.read()
        
        # Open as PIL Image
        from PIL import Image
        import io
        image = Image.open(io.BytesIO(content))
        
        # Convert to SVG (returns string)
        svg_content = sketch_module.image_to_svg(image)
        
        # Save to history
        if userId:
            # Save a snippet or just the fact that it was vectorized
            await save_task(userId, "sketch", file.filename, svg_content[:5000]) # Snippet for history
            
        # Return direct SVG content
        return Response(content=svg_content, media_type="image/svg+xml")
            
    except Exception as e:
        print(f"Sketch Error: {e}") # Debug log
        raise HTTPException(status_code=500, detail=f"Vectorization failed: {str(e)}")
