import os
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
DATABASE_NAME = "intelliscan"

client = None
db = None

def get_database():
    global client, db
    if client is None:
        print(f"Connecting to MongoDB at {MONGO_URI}...")
        try:
            client = AsyncIOMotorClient(
                MONGO_URI,
                serverSelectionTimeoutMS=5000 # 5 second timeout
            )
            db = client[DATABASE_NAME]
            # No await here since get_database is sync, 
            # but we can trigger a ping in a background or first request.
            print("MongoDB client initialized.")
        except Exception as e:
            print(f"Error connecting to MongoDB: {e}")
            client = None
            db = None
    return db

async def verify_connection():
    db = get_database()
    if db is not None:
        try:
            # The ismaster command is cheap and does not require auth.
            await db.command("ismaster")
            print("MongoDB connection verified successfully.")
            return True
        except Exception as e:
            print(f"MongoDB connection verification failed: {e}")
            return False
    return False

async def close_database_connection():
    global client
    if client:
        client.close()
        client = None

async def save_task(userId: str, taskType: str, inputData: str, outputData: str):
    db = get_database()
    task = {
        "userId": userId,
        "taskType": taskType,
        "inputData": inputData,
        "result": outputData,
        "timestamp": datetime.utcnow()
    }
    await db.tasks.insert_one(task)
    
    # Send Push Notification
    try:
        from modules.notification_manager import NotificationManager
        notification_manager = NotificationManager()
        
        user = await db.users.find_one({"userId": userId})
        if user and "fcmToken" in user:
            notification_manager.send_push_notification(
                token=user["fcmToken"],
                title=f"Task Completed: {taskType}",
                body=f"Your task '{taskType}' has been processed successfully.",
                data={"taskId": str(task["_id"]), "taskType": taskType}
            )
    except Exception as e:
        print(f"Failed to trigger notification: {e}")

async def set_security_question(userId: str, questionId: str, answerHash: str):
    db = get_database()
    await db.users.update_one(
        {"userId": userId},
        {"$set": {"securityQuestionId": questionId, "securityAnswerHash": answerHash}},
        upsert=True
    )

async def get_security_question(userId: str):
    db = get_database()
    user = await db.users.find_one({"userId": userId})
    if user and "securityQuestionId" in user:
        return user["securityQuestionId"]
    return None

async def verify_security_answer(userId: str, answerHash: str):
    db = get_database()
    user = await db.users.find_one({"userId": userId})
    if user and "securityAnswerHash" in user:
        return user["securityAnswerHash"] == answerHash
    return False
