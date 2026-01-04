import shutil
import os
import zipfile
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from typing import List
from modules.pdf_tools import PDFTools
from modules.gemini_client import GeminiClient
from modules.ilovepdf_service import ILovePDFService
from modules.database import save_task
from api.routers.history import get_current_user
import tempfile
import json
from fastapi import Depends

router = APIRouter()
pdf_tools = PDFTools()
gemini_client = GeminiClient()
ilovepdf_service = ILovePDFService()

def cleanup_file(path: str):
    try:
        if os.path.exists(path):
            os.remove(path)
    except Exception:
        pass

@router.post("/merge")
async def merge_pdfs(
    background_tasks: BackgroundTasks, 
    files: List[UploadFile] = File(...),
    use_api: bool = Form(False),
    userId: str = Depends(get_current_user)
):
    temp_dir = tempfile.mkdtemp()
    input_paths = []
    
    try:
        # Save uploaded files
        for file in files:
            path = os.path.join(temp_dir, file.filename)
            with open(path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            input_paths.append(path)
            
        output_path = os.path.join(temp_dir, "merged_output.pdf")
        
        if use_api:
            # iLovePDF Merge
            result_path = ilovepdf_service.process_task('merge', input_paths, temp_dir)
            # Rename if necessary or just use result_path
            output_path = result_path
        else:
            # Offline Merge
            pdf_tools.merge_pdfs(input_paths, output_path)
        
        if userId:
            await save_task(userId, "pdf_merge", f"{len(files)} files", "Success: merged.pdf")
            
        return FileResponse(
            output_path, 
            media_type="application/pdf", 
            filename="merged.pdf",
            background=background_tasks.add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        shutil.rmtree(temp_dir)
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/compress")
async def compress_pdf(
    background_tasks: BackgroundTasks, 
    file: UploadFile = File(...),
    use_api: bool = Form(False),
    userId: str = Depends(get_current_user)
):
    temp_dir = tempfile.mkdtemp()
    try:
        input_path = os.path.join(temp_dir, file.filename)
        with open(input_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        output_path = os.path.join(temp_dir, "compressed_output.pdf")
        
        if use_api:
            result_path = ilovepdf_service.process_task('compress', [input_path], temp_dir)
            output_path = result_path
        else:
            pdf_tools.compress_pdf(input_path, output_path)
        
        if userId:
            await save_task(userId, "pdf_compress", file.filename, "Success: compressed")
            
        return FileResponse(
            output_path, 
            media_type="application/pdf", 
            filename=f"compressed_{file.filename}",
            background=background_tasks.add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        shutil.rmtree(temp_dir)
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/image-to-pdf")
async def image_to_pdf(
    background_tasks: BackgroundTasks, 
    files: List[UploadFile] = File(...),
    userId: str = Depends(get_current_user)
):
    temp_dir = tempfile.mkdtemp()
    input_paths = []
    try:
        for file in files:
            path = os.path.join(temp_dir, file.filename)
            with open(path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            input_paths.append(path)
            
        output_path = os.path.join(temp_dir, "converted_images.pdf")
        pdf_tools.images_to_pdf(input_paths, output_path)
        
        if userId:
            await save_task(userId, "pdf_image_to_pdf", f"{len(files)} images", "Success: converted")
            
        return FileResponse(
            output_path, 
            media_type="application/pdf", 
            filename="images_converted.pdf",
            background=background_tasks.add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        shutil.rmtree(temp_dir)
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/split")
async def split_pdf(
    background_tasks: BackgroundTasks, 
    file: UploadFile = File(...),
    userId: str = Depends(get_current_user)
):
    temp_dir = tempfile.mkdtemp()
    try:
        input_path = os.path.join(temp_dir, file.filename)
        with open(input_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        split_dir = os.path.join(temp_dir, "split_pages")
        os.makedirs(split_dir)
        
        # Split
        pdf_tools.split_pdf(input_path, split_dir)
        
        # Zip the result
        zip_path = os.path.join(temp_dir, "split_files.zip")
        with zipfile.ZipFile(zip_path, 'w') as zipf:
            for root, dirs, files in os.walk(split_dir):
                for file in files:
                    zipf.write(os.path.join(root, file), file)
        
        if userId:
            await save_task(userId, "pdf_split", file.filename, "Success: split into pages")
            
        return FileResponse(
            zip_path,
            media_type="application/zip",
            filename="split_pages.zip",
            background=background_tasks.add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        shutil.rmtree(temp_dir)
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/protect")
async def protect_pdf(
    background_tasks: BackgroundTasks, 
    file: UploadFile = File(...), 
    password: str = Form(...),
    userId: str = Depends(get_current_user)
):
    temp_dir = tempfile.mkdtemp()
    try:
        input_path = os.path.join(temp_dir, file.filename)
        with open(input_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        output_path = os.path.join(temp_dir, f"protected_{file.filename}")
        pdf_tools.protect_pdf(input_path, password, output_path)
        
        if userId:
            await save_task(userId, "pdf_protect", file.filename, "Success: protected with password")
            
        return FileResponse(
            output_path, 
            media_type="application/pdf", 
            filename=f"protected_{file.filename}",
            background=background_tasks.add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        shutil.rmtree(temp_dir)
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/redact")
async def redact_pdf(
    background_tasks: BackgroundTasks, 
    file: UploadFile = File(...),
    userId: str = Depends(get_current_user)
):
    temp_dir = tempfile.mkdtemp()
    try:
        input_path = os.path.join(temp_dir, file.filename)
        with open(input_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # 1. Extract text
        text_content = pdf_tools.extract_text(input_path)
        
        # 2. Identify sensitive info with Gemini
        # It returns a JSON string like '["John", "email@example.com"]'
        sensitive_json = gemini_client.identify_sensitive_data(text_content)
        
        # Clean up JSON string if it has markdown code blocks
        if "```json" in sensitive_json:
            sensitive_json = sensitive_json.split("```json")[1].split("```")[0].strip()
        elif "```" in sensitive_json:
            sensitive_json = sensitive_json.split("```")[1].split("```")[0].strip()
            
        try:
            redactions = json.loads(sensitive_json)
        except:
            redactions = [] # Fallback
            print(f"Failed to parse redaction JSON: {sensitive_json}")
            
        output_path = os.path.join(temp_dir, f"redacted_{file.filename}")
        
        # 3. Apply redactions
        pdf_tools.redact_text(input_path, redactions, output_path)
        
        # Return file (UI can display success message)
        # We lose the 'counts' metadata here unless we send it as a header or multipart response. 
        # For now, just returning the file is easiest for "download".
        # To show counts, we might need a custom header.
        
        if userId:
            await save_task(userId, "pdf_redact", file.filename, f"Success: {len(redactions)} redactions applied")
            
        return FileResponse(
            output_path, 
            media_type="application/pdf", 
            filename=f"redacted_{file.filename}",
            headers={"X-Redaction-Count": str(len(redactions))},
            background=background_tasks.add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        shutil.rmtree(temp_dir)
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/convert")
async def convert_pdf(
    background_tasks: BackgroundTasks,
    files: List[UploadFile] = File(...),
    task: str = Form(...), # 'pdfword', 'pdfpps', 'pdfexcel', 'wordpdf', 'ppspdf', 'excelpdf', 'pdfjpg', 'jpgpdf', 'pdfpdfa'
    userId: str = Depends(get_current_user)
):
    """Generic conversion endpoint using iLovePDF API"""
    temp_dir = tempfile.mkdtemp()
    try:
        file = files[0]
        input_path = os.path.join(temp_dir, file.filename)
        with open(input_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        result_path = ilovepdf_service.process_task(task, [input_path], temp_dir)
        
        if not result_path or not os.path.exists(result_path):
            raise Exception("Conversion failed to produce a file")
            
        filename = os.path.basename(result_path)
        
        media_type = "application/pdf"
        if filename.endswith(".docx"): media_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        elif filename.endswith(".pptx"): media_type = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        elif filename.endswith(".xlsx"): media_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        elif filename.endswith(".jpg") or filename.endswith(".jpeg"): media_type = "image/jpeg"
        elif filename.endswith(".zip"): media_type = "application/zip"
            
        return FileResponse(
            result_path,
            media_type=media_type,
            filename=filename,
            background=background_tasks.add_task(shutil.rmtree, temp_dir)
        )
        
        if userId:
            await save_task(userId, f"pdf_{task}", file.filename, f"Success: converted to {filename.split('.')[-1]}")
            
        return response
    except Exception as e:
        shutil.rmtree(temp_dir)
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/unlock")
async def unlock_pdf(
    background_tasks: BackgroundTasks, 
    files: List[UploadFile] = File(...),
    password: str = Form(None),
    userId: str = Depends(get_current_user)
):
    temp_dir = tempfile.mkdtemp()
    try:
        file = files[0]
        input_path = os.path.join(temp_dir, file.filename)
        with open(input_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        result_path = ilovepdf_service.process_task('unlock', [input_path], temp_dir, password=password)
        
        if userId:
            await save_task(userId, "pdf_unlock", file.filename, "Success: unlocked")
            
        return FileResponse(
            result_path,
            media_type="application/pdf",
            filename=f"unlocked_{file.filename}",
            background=background_tasks.add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        shutil.rmtree(temp_dir)
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/rotate")
async def rotate_pdf(
    background_tasks: BackgroundTasks, 
    files: List[UploadFile] = File(...),
    rotate: int = Form(90), # 90, 180, 270
    userId: str = Depends(get_current_user)
):
    temp_dir = tempfile.mkdtemp()
    try:
        file = files[0]
        input_path = os.path.join(temp_dir, file.filename)
        with open(input_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        result_path = ilovepdf_service.process_task('rotate', [input_path], temp_dir, rotate=rotate)
        
        if userId:
            await save_task(userId, "pdf_rotate", file.filename, f"Success: rotated {rotate} degrees")
            
        return FileResponse(
            result_path,
            media_type="application/pdf",
            filename=f"rotated_{file.filename}",
            background=background_tasks.add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        shutil.rmtree(temp_dir)
        raise HTTPException(status_code=500, detail=str(e))
