from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel
from modules.auth import decode_access_token
from modules.subscription_manager import SubscriptionManager

router = APIRouter()

class DeductCreditsRequest(BaseModel):
    serviceType: str

class CreateOrderRequest(BaseModel):
    planName: str

class VerifyPaymentRequest(BaseModel):
    razorpay_payment_id: str
    razorpay_order_id: str
    razorpay_signature: str
    planName: str

async def get_current_user(request: Request):
    token = request.cookies.get("access_token")
    if not token:
        # Check header just in case mobile sends it there
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header.split(" ")[1]
        
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid session")
    return payload["sub"]

@router.get("/status")
async def get_subscription_status(user_id: str = Depends(get_current_user)):
    return await SubscriptionManager.get_user_subscription_status(user_id)

@router.post("/deduct")
async def deduct_credits(data: DeductCreditsRequest, user_id: str = Depends(get_current_user)):
    success = await SubscriptionManager.deduct_credits(user_id, data.serviceType)
    return {"success": success, "message": "Credits deducted"}

@router.post("/create-order")
async def create_order(data: CreateOrderRequest, user_id: str = Depends(get_current_user)):
    plan = SubscriptionManager.PLANS.get(data.planName)
    if not plan:
        raise HTTPException(status_code=400, detail="Invalid plan")
    
    order = await SubscriptionManager.create_order(plan["price"])
    return order

@router.post("/verify-payment")
async def verify_payment(data: VerifyPaymentRequest, user_id: str = Depends(get_current_user)):
    is_valid = await SubscriptionManager.verify_payment(
        data.razorpay_payment_id,
        data.razorpay_order_id,
        data.razorpay_signature
    )
    
    if not is_valid:
        raise HTTPException(status_code=400, detail="Invalid payment signature")
    
    await SubscriptionManager.upgrade_user_plan(user_id, data.planName)
    return {"success": True, "message": "Plan upgraded successfully"}
