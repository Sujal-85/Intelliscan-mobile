from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from modules.database import get_database
from typing import Optional
from datetime import datetime
import uuid

router = APIRouter()

class FeedbackCreate(BaseModel):
    userId: Optional[str] = None
    rating: int = Field(..., ge=1, le=5)
    category: str
    message: str
    email: Optional[str] = None

@router.post("/feedback")
async def submit_feedback(feedback: FeedbackCreate):
    db = get_database()
    
    feedback_entry = {
        "id": str(uuid.uuid4()),
        "userId": feedback.userId,
        "rating": feedback.rating,
        "category": feedback.category,
        "message": feedback.message,
        "email": feedback.email,
        "createdAt": datetime.utcnow()
    }
    
    await db.feedback.insert_one(feedback_entry)
    return {"message": "Feedback submitted successfully", "id": feedback_entry["id"]}

@router.get("/community")
async def get_community_link():
    # In a real app, this could be fetched from DB config
    return {
        "discord": "https://discord.gg/3yeMGkmY", # Example
        "telegram": "https://t.me/intelliscan",
    }
