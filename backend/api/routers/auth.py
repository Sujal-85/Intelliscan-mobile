from fastapi import APIRouter, HTTPException, Depends, Response, Request
from pydantic import BaseModel, EmailStr
from modules.database import get_database
from modules.auth import get_password_hash, verify_password, create_access_token, decode_access_token
from datetime import datetime, timedelta
import json
import uuid
import os

router = APIRouter()

class UserSignup(BaseModel):
    email: EmailStr
    password: str
    fullName: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserGoogleLogin(BaseModel):
    token: str
    email: EmailStr
    fullName: str
    avatar: str = None

class UpdateAvatar(BaseModel):
    userId: str = None
    avatar: str  # Base64 encoded image

class UpdateProfileInfo(BaseModel):
    userId: str = None
    fullName: str
    phone: str = None
    bio: str = None
    location: str = None


@router.post("/signup")
async def signup(user: UserSignup):
    db = get_database()
    # Check if user exists
    existing_user = await db.users.find_one({"email": user.email})
    if existing_user:
        raise HTTPException(status_code=400, detail="User already registered")
    
    user_dict = {
        "userId": str(uuid.uuid4()),
        "email": user.email,
        "password": get_password_hash(user.password),
        "fullName": user.fullName,
        "createdAt": datetime.utcnow(),
        "credits": 100,
        "plan": "starter", # or "free_trial"
        "planStartDate": datetime.utcnow(),
        "subscriptionEndDate": datetime.utcnow() + timedelta(days=14),
        "isPro": False
    }
    await db.users.insert_one(user_dict)
    return {"message": "User created successfully"}

@router.post("/login")
async def login(response: Response, user: UserLogin):
    db = get_database()
    db_user = await db.users.find_one({"email": user.email})
    if not db_user or not verify_password(user.password, db_user["password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    token = create_access_token({"sub": db_user["userId"], "email": db_user["email"]})
    
    # User data for frontend hydration (non-sensitive)
    user_data = {
        "userId": db_user["userId"],
        "email": db_user["email"],
        "fullName": db_user.get("fullName"),
        "avatar": db_user.get("avatar")
    }
    import json
    user_data_str = json.dumps(user_data)

    # Production cookie settings
    is_prod = os.getenv("RENDER") is not None or os.getenv("NODE_ENV") == "production"
    
    # Set HTTP-only cookie for auth
    response.set_cookie(
        key="access_token",
        value=token,
        httponly=True,
        max_age=3600 * 24 * 7, # 1 week
        samesite="none" if is_prod else "lax",
        secure=is_prod,
    )


    # Set readable cookie for user data
    response.set_cookie(
        key="user_data",
        value=user_data_str,
        httponly=False,
        max_age=3600 * 24 * 7,
        samesite="none" if is_prod else "lax",
        secure=is_prod
    )
    
    return {
        "user": user_data
    }

class SyncRequest(BaseModel):
    email: EmailStr
    fullName: str
    avatar: str = None
    firebaseId: str

@router.post("/sync")
async def sync_user(response: Response, data: SyncRequest):
    db = get_database()
    print(f"DEBUG: Syncing user {data.email}")
    
    db_user = await db.users.find_one({"email": data.email})
    
    if not db_user:
        print(f"DEBUG: Creating new Synced user: {data.email}")
        db_user = {
            "userId": str(uuid.uuid4()),
            "email": data.email,
            "fullName": data.fullName,
            "avatar": data.avatar,
            "firebaseId": data.firebaseId,
            "provider": "firebase_sync",
            "createdAt": datetime.utcnow(),
            "credits": 100,
            "plan": "starter",
            "planStartDate": datetime.utcnow(),
            "subscriptionEndDate": datetime.utcnow() + timedelta(days=14),
            "isPro": False
        }
        await db.users.insert_one(db_user)
    else:
        # Update details if needed
        # Check if existing user has credits initialized
        if db_user.get("credits") is None:
             print(f"DEBUG: Initializing credits for existing user {data.email}")
             await db.users.update_one(
                 {"email": data.email},
                 {
                     "$set": {
                         "credits": 100, 
                         "plan": "starter",
                         "isPro": False,
                         "subscriptionEndDate": datetime.utcnow() + timedelta(days=14)
                     }
                 }
             )
             # Refresh local dict
             db_user["credits"] = 100
             db_user["plan"] = "starter"
         
        # Also ensure avatar/fullName are up to date from Firebase if provided
        update_fields = {}
        if data.fullName and data.fullName != db_user.get("fullName"):
            update_fields["fullName"] = data.fullName
        if data.avatar and data.avatar != db_user.get("avatar"):
            update_fields["avatar"] = data.avatar
            
        if update_fields:
            await db.users.update_one({"email": data.email}, {"$set": update_fields})
            db_user.update(update_fields)
    
    token = create_access_token({"sub": db_user["userId"], "email": db_user["email"]})
    
    user_data = {
        "userId": db_user["userId"],
        "email": db_user["email"],
        "fullName": db_user.get("fullName"),
        "avatar": db_user.get("avatar")
    }
    
    return {
        "access_token": token,
        "user": user_data
    }

@router.post("/google")
async def google_login(response: Response, user: UserGoogleLogin):
    db = get_database()
    print(f"DEBUG: Processing Google Login for {user.email}")
    
    db_user = await db.users.find_one({"email": user.email})
    
    if not db_user:
        print(f"DEBUG: Creating new Google user: {user.email}")
        db_user = {
            "userId": str(uuid.uuid4()),
            "email": user.email,
            "fullName": user.fullName,
            "avatar": user.avatar,
            "provider": "google",
            "createdAt": datetime.utcnow(),
            "credits": 100,
            "plan": "starter",
            "planStartDate": datetime.utcnow(),
            "subscriptionEndDate": datetime.utcnow() + timedelta(days=14),
            "isPro": False
        }
        await db.users.insert_one(db_user)
    else:
        print(f"DEBUG: Existing Google user found: {user.email}")
        await db.users.update_one(
            {"email": user.email},
            {"$set": {"fullName": user.fullName, "avatar": user.avatar, "lastLogin": datetime.utcnow()}}
        )
    
    token = create_access_token({"sub": db_user["userId"], "email": db_user["email"]})
    print(f"DEBUG: Created token for {db_user['userId']}")
    
    user_data = {
        "userId": db_user["userId"],
        "email": db_user["email"],
        "fullName": db_user.get("fullName"),
        "avatar": db_user.get("avatar")
    }
    user_data_str = json.dumps(user_data)

    # Production cookie settings
    is_prod = os.getenv("RENDER") is not None or os.getenv("NODE_ENV") == "production"

    response.set_cookie(
        key="access_token",
        value=token,
        httponly=True,
        max_age=3600 * 24 * 7,
        samesite="none" if is_prod else "lax",
        secure=is_prod
    )

    response.set_cookie(
        key="user_data",
        value=user_data_str,
        httponly=False,
        max_age=3600 * 24 * 7,
        samesite="none" if is_prod else "lax",
        secure=is_prod
    )
    
    return {
        "user": user_data
    }

@router.post("/logout")
async def logout(response: Response):
    print("DEBUG: Processing Logout")
    response.delete_cookie("access_token")
    response.delete_cookie("user_data")
    return {"message": "Logged out"}

@router.get("/me")
async def get_me(request: Request):
    token = request.cookies.get("access_token")
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid session")
    
    db = get_database()
    db_user = await db.users.find_one({"userId": payload["sub"]})
    if not db_user:
        raise HTTPException(status_code=401, detail="User not found")
    
    return {
        "userId": db_user["userId"],
        "email": db_user["email"],
        "fullName": db_user.get("fullName"),
        "avatar": db_user.get("avatar")
    }

@router.post("/update-avatar")
async def update_avatar(request: Request, data: UpdateAvatar):
    token = request.cookies.get("access_token")
    user_id = None

    if token:
        payload = decode_access_token(token)
        if payload:
            user_id = payload["sub"]

    # Fallback to body userId (for mobile)
    if not user_id and data.userId:
        user_id = data.userId
    
    from modules.storage import upload_image
    
    if not user_id:
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    # Upload to Cloudinary
    avatar_url = upload_image(data.avatar)
    if not avatar_url:
         raise HTTPException(status_code=500, detail="Failed to upload image")

    db = get_database()
    result = await db.users.update_one(
        {"userId": user_id},
        {"$set": {"avatar": avatar_url, "updatedAt": datetime.utcnow()}}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {"message": "Avatar updated successfully", "avatar": avatar_url}

@router.put("/update-info")
async def update_profile_info(request: Request, data: UpdateProfileInfo):
    token = request.cookies.get("access_token")
    user_id = None

    if token:
        payload = decode_access_token(token)
        if payload:
            user_id = payload["sub"]
    
    # Fallback to body userId (for mobile)
    if not user_id and data.userId:
        user_id = data.userId

    if not user_id:
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    db = get_database()
    
    update_data = {
        "fullName": data.fullName,
        "updatedAt": datetime.utcnow()
    }
    if data.phone:
        update_data["phone"] = data.phone
    if data.bio:
        update_data["bio"] = data.bio
    if data.location:
        update_data["location"] = data.location
        
    result = await db.users.update_one(
        {"userId": user_id},
        {"$set": update_data}
    )
    
    if result.matched_count == 0:
        # If no user found to update (modified might be 0 if fields are same, match is critical)
        raise HTTPException(status_code=404, detail="User not found")
            
    return {"message": "Profile updated successfully", "user": update_data}


class UpdateFCMToken(BaseModel):
    userId: str
    token: str

@router.post("/update-fcm-token")
async def update_fcm_token(data: UpdateFCMToken):
    db = get_database()
    result = await db.users.update_one(
        {"userId": data.userId},
        {"$set": {"fcmToken": data.token, "updatedAt": datetime.utcnow()}}
    )
@router.delete("/delete")
async def delete_account(response: Response, request: Request):
    token = request.cookies.get("access_token")
    if not token:
        # Try header
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header.split(" ")[1]
            
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid session")
        
    user_id = payload["sub"]
    db = get_database()
    
    # Delete user data
    res = await db.users.delete_one({"userId": user_id})
    
    if res.deleted_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Clear cookies
    response.delete_cookie("access_token")
    response.delete_cookie("user_data")
    
    return {"message": "Account deleted successfully"}
