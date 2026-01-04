from datetime import datetime, timedelta
from typing import Optional
from modules.database import get_database
from fastapi import HTTPException
import razorpay
import os
import hmac
import hashlib

# Initialize Razorpay Client
RAZORPAY_KEY_ID = os.getenv("RAZORPAY_KEY_ID", "rzp_test_YOUR_KEY_ID")
RAZORPAY_KEY_SECRET = os.getenv("RAZORPAY_KEY_SECRET", "YOUR_KEY_SECRET")

client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))

class SubscriptionManager:
    COST_MAP = {
        "basic": 10,
        "advanced": 20
    }
    
    PLANS = {
        "starter": {"credits": 100, "price": 0},
        "pro": {"credits": 3000, "price": 79900}, # in paise
        "premium": {"credits": 5000, "price": 99900} # in paise
    }

    @staticmethod
    async def get_user_subscription_status(user_id: str):
        db = get_database()
        user = await db.users.find_one({"userId": user_id})
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Lazy Init for Legacy Users
        if "plan" not in user:
            plan_start = datetime.utcnow()
            sub_end = plan_start + timedelta(days=14)
            await db.users.update_one(
                {"userId": user_id},
                {
                    "$set": {
                        "plan": "starter",
                        "credits": 100,
                        "planStartDate": plan_start,
                        "subscriptionEndDate": sub_end,
                        "isPro": False
                    }
                }
            )
            # Update local obj
            user["plan"] = "starter"
            user["credits"] = 100
            user["subscriptionEndDate"] = sub_end
        
        now = datetime.utcnow()
        expiry = user.get("subscriptionEndDate")
        
        is_expired = False
        if expiry and expiry < now:
            is_expired = True
            
        return {
            "plan": user.get("plan", "starter"),
            "credits": user.get("credits", 0),
            "isPro": user.get("isPro", False),
            "subscriptionEndDate": expiry,
            "isExpired": is_expired
        }

    @staticmethod
    async def deduct_credits(user_id: str, service_type: str = "basic") -> bool:
        """
        Deduct credits for a service.
        service_type: 'basic' or 'advanced' (defaults to basic cost of 10 if unknown)
        Returns True if successful, raises HTTPException if failed.
        """
        cost = SubscriptionManager.COST_MAP.get(service_type, 10)
        
        db = get_database()
        user = await db.users.find_one({"userId": user_id})
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        current_credits = user.get("credits", 0)
        
        # Check expiry
        expiry = user.get("subscriptionEndDate")
        if expiry and expiry < datetime.utcnow():
             raise HTTPException(status_code=403, detail="Subscription expired. Please upgrade.")

        if current_credits < cost:
            raise HTTPException(status_code=403, detail="Insufficient credits. Please upgrade.")

        # Atomic update
        result = await db.users.update_one(
            {"userId": user_id, "credits": {"$gte": cost}},
            {"$inc": {"credits": -cost}}
        )

        if result.modified_count == 0:
             # Double check if it was race condition or actual lack of credits
             raise HTTPException(status_code=403, detail="Insufficient credits.")
        
        return True

    @staticmethod
    async def create_order(amount_paise: int, currency: str = "INR"):
        try:
            data = { "amount": amount_paise, "currency": currency }
            payment = client.order.create(data=data)
            return payment
        except Exception as e:
            print(f"Razorpay Order Creation Failed: {e}")
            raise HTTPException(status_code=500, detail="Payment initiation failed")

    @staticmethod
    async def verify_payment(payment_id: str, order_id: str, signature: str):
        try:
            # Razorpay verification
            params_dict = {
                'razorpay_order_id': order_id,
                'razorpay_payment_id': payment_id,
                'razorpay_signature': signature
            }
            client.utility.verify_payment_signature(params_dict)
            return True
        except razorpay.errors.SignatureVerificationError:
            return False
        except Exception as e:
            print(f"Payment Verification Error: {e}")
            return False

    @staticmethod
    async def upgrade_user_plan(user_id: str, plan_name: str):
        db = get_database()
        
        plan_details = SubscriptionManager.PLANS.get(plan_name)
        if not plan_details:
             raise HTTPException(status_code=400, detail="Invalid plan")
             
        new_credits = plan_details["credits"]
        duration_days = 30 # Default monthly
        
        subscription_end_date = datetime.utcnow() + timedelta(days=duration_days)
        
        await db.users.update_one(
            {"userId": user_id},
            {
                "$set": {
                    "plan": plan_name,
                    "credits": new_credits, # Configuring to set/reset credits. Could also be $inc if we want to add. User says "with 3000 credits", implies a set amount per month.
                    "subscriptionEndDate": subscription_end_date,
                    "isPro": True,
                    "updatedAt": datetime.utcnow()
                }
            }
        )
