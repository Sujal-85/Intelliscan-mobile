from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException
from typing import List
from modules import storage
import shutil
import tempfile
import os

router = APIRouter()

@router.post("/upload")
async def upload_vault_file(
    file: UploadFile = File(...), 
    userId: str = Form(...)
):
    try:
        # Create a temp file to store the upload
        with tempfile.NamedTemporaryFile(delete=False) as temp:
            shutil.copyfileobj(file.file, temp)
            temp_path = temp.name
        
        # Upload to Cloudinary under users/{userId}/vault
        folder = f"users/{userId}/vault"
        result = storage.upload_file(temp_path, folder=folder)
        
        # Cleanup temp file
        os.unlink(temp_path)
        
        if result:
            return {"success": True, "file": result}
        else:
            raise HTTPException(status_code=500, detail="Upload to storage failed")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/list/{userId}")
async def list_vault_files(userId: str):
    folder_prefix = f"users/{userId}/vault/"
    
    # Cloudinary resources list usually requires separate calls for 'image', 'raw', 'video'
    # For encrypted files, we mostly care about 'raw' or 'auto' treated as raw.
    # We will try fetching 'raw' resources.
    files_raw = storage.list_files(prefix=folder_prefix)
    
    # Map to simpler structure
    mapped_files = []
    for f in files_raw:
        mapped_files.append({
            "public_id": f['public_id'],
            "url": f['secure_url'],
            "created_at": f['created_at'],
            "bytes": f['bytes'],
            "format": f.get('format', 'enc')
        })
        
    return {"success": True, "files": mapped_files}

@router.delete("/delete")
async def delete_vault_file(public_id: str = Form(...)):
    # Verify owner? (Ideally check user token vs public_id structure)
    # For now, just delete.
    success = storage.delete_file(public_id, resource_type="raw")

    
    if not success:
        raise HTTPException(status_code=500, detail="Delete failed")
        
    return {"success": True}


# Security Question Endpoints

from modules import database
from pydantic import BaseModel

class SecurityQuestionSetRequest(BaseModel):
    userId: str
    questionId: str
    answerHash: str

class SecurityAnswerVerifyRequest(BaseModel):
    userId: str
    answerHash: str

@router.post("/set-security-question")
async def set_security_question(request: SecurityQuestionSetRequest):
    try:
        await database.set_security_question(
            request.userId, 
            request.questionId, 
            request.answerHash
        )
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/get-security-question/{userId}")
async def get_security_question(userId: str):
    try:
        questionId = await database.get_security_question(userId)
        if questionId:
            return {"success": True, "questionId": questionId}
        else:
            return {"success": False, "detail": "No security question set"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/verify-security-answer")
async def verify_security_answer(request: SecurityAnswerVerifyRequest):
    try:
        isValid = await database.verify_security_answer(request.userId, request.answerHash)
        return {"success": True, "isValid": isValid}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
