from fastapi import APIRouter, HTTPException, Request, Depends
from modules.database import get_database
from modules.auth import decode_access_token
from typing import List
from datetime import datetime

router = APIRouter()

async def get_current_user(request: Request):
    # 1. Check for access_token cookie
    token = request.cookies.get("access_token")
    if token:
        payload = decode_access_token(token)
        if payload:
            return payload["sub"]
    
    # 2. Check for userId in form data (for Multipart requests)
    try:
        form = await request.form()
        if "userId" in form:
            return form["userId"]
    except Exception:
        pass
        
    # 3. Check for userId in JSON body (for JSON requests)
    try:
        body = await request.json()
        if isinstance(body, dict) and "userId" in body:
            return body["userId"]
    except Exception:
        pass
        
    return None

@router.get("/")
@router.get("/{uid}")
async def get_history(type: str = None, uid: str = None, auth_userId: str = Depends(get_current_user)):
    # Use uid from path if provided (direct fetch), otherwise fallback to authenticated user
    active_userId = uid or auth_userId
    
    if not active_userId:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    db = get_database()
    query = {"userId": active_userId}
    if type:
        query["taskType"] = {"$regex": type, "$options": "i"} # Case-insensitive partial match
        
    cursor = db.tasks.find(query).sort("timestamp", -1).limit(50)
    tasks = await cursor.to_list(length=50)
    
    # Clean up _id for JSON serialization
    for task in tasks:
        task["id"] = str(task["_id"])
        del task["_id"]
        
    return tasks

@router.delete("/{task_id}")
async def delete_task(task_id: str, userId: str = Depends(get_current_user)):
    if not userId:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    from bson import ObjectId
    db = get_database()
    try:
        result = await db.tasks.delete_one({"_id": ObjectId(task_id), "userId": userId})
        if result.deleted_count == 0:
            raise HTTPException(status_code=404, detail="Task not found")
        return {"message": "Task deleted"}
    except Exception:
         raise HTTPException(status_code=400, detail="Invalid ID")
