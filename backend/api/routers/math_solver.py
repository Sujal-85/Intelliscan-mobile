from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from PIL import Image
import io
from modules.math_ocr import MathOCRModule
from modules.database import save_task
from api.routers.history import get_current_user

router = APIRouter()
math_module = MathOCRModule()

@router.post("/solve")
async def solve_math(file: UploadFile = File(...), userId: str = Depends(get_current_user)):
    try:
        content = await file.read()
        image = Image.open(io.BytesIO(content))
        latex_result = math_module.perform_math_ocr(image)
        
        # Save to history if logged in
        if userId:
            await save_task(userId, "math", file.filename, latex_result)
            
        return {
            "latex": latex_result,
            # latex_result now contains the solution if AI enhancement is enabled in MathOCRModule
            "solution": "Solution is integrated in the LaTeX/Output"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
