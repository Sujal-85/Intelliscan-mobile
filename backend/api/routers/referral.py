from fastapi import APIRouter, HTTPException, Depends, Request
from modules.database import get_database
from modules.auth import decode_access_token
from pydantic import BaseModel
import uuid
import random
import string
from datetime import datetime

router = APIRouter()

class ClaimCodeRequest(BaseModel):
    code: str

def generate_referral_code():
    # Generate 6 char random code
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

async def get_current_user_id(request: Request):
    token = request.cookies.get("access_token")
    if token:
        payload = decode_access_token(token)
        if payload:
            return payload["sub"]
            
    # Fallback to query param (for mobile GET) or body (manual check needed, but query is easier for global helper)
    user_id = request.query_params.get("userId")
    if user_id:
        return user_id
        
    raise HTTPException(status_code=401, detail="Not authenticated")

@router.get("/info")
async def get_referral_info(request: Request):
    user_id = await get_current_user_id(request)
    db = get_database()
    
    user = await db.users.find_one({"userId": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Generate code if not exists
    if "referralCode" not in user:
        code = generate_referral_code()
        # Ensure uniqueness (simple retry logic)
        while await db.users.find_one({"referralCode": code}):
            code = generate_referral_code()
            
        await db.users.update_one(
            {"userId": user_id},
            {"$set": {"referralCode": code, "referralPoints": user.get("referralPoints", 0), "referralsCount": 0}}
        )
        # Refresh user object
        user = await db.users.find_one({"userId": user_id})
        
    return {
        "referralCode": user.get("referralCode"),
        "points": user.get("referralPoints", 0),
        "referralsCount": user.get("referralsCount", 0)
    }

@router.post("/claim")
async def claim_referral_code(request: Request, body: ClaimCodeRequest):
    user_id = await get_current_user_id(request)
    db = get_database()
    
    user = await db.users.find_one({"userId": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Validation
    if user.get("referredBy"):
        raise HTTPException(status_code=400, detail="You have already claimed a referral code")
        
    target_code = body.code.upper()
    
    if user.get("referralCode") == target_code:
        raise HTTPException(status_code=400, detail="Cannot claim your own code")
        
    referrer = await db.users.find_one({"referralCode": target_code})
    if not referrer:
        raise HTTPException(status_code=404, detail="Invalid referral code")
        
    # Award points
    POINTS_REFERRER = 100
    POINTS_REFEREE = 50
    
    # 1. Update Current User (Referee)
    await db.users.update_one(
        {"userId": user_id},
        {
            "$set": {
                "referredBy": referrer["userId"],
                "referralPoints": user.get("referralPoints", 0) + POINTS_REFEREE
            }
        }
    )
    
    # 2. Update Referrer
    await db.users.update_one(
        {"userId": referrer["userId"]},
        {
            "$inc": {
                "referralPoints": POINTS_REFERRER,
                "referralsCount": 1
            }
        }
    )
    
    return {
        "message": "Referral claimed successfully!",
        "pointsAwarded": POINTS_REFEREE,
        "newBalance": user.get("referralPoints", 0) + POINTS_REFEREE
    }
