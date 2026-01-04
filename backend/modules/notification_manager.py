import firebase_admin
from firebase_admin import credentials, messaging
import os
from dotenv import load_dotenv

load_dotenv()

class NotificationManager:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(NotificationManager, cls).__new__(cls)
            cls._instance._initialize()
        return cls._instance

    def _initialize(self):
        # Check if already initialized to avoid errors
        if not firebase_admin._apps:
            cred_path = os.getenv("FIREBASE_CREDENTIALS", "firebase_credentials.json")
            if os.path.exists(cred_path):
                try:
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)
                    print("Firebase Admin initialized successfully.")
                except Exception as e:
                    print(f"Failed to initialize Firebase Admin: {e}")
            else:
                print(f"Warning: Firebase credentials file not found at {cred_path}. Push notifications will not work.")
        else:
            print("Firebase Admin already initialized.")

    def send_push_notification(self, token: str, title: str, body: str, data: dict = None):
        if not token:
            print("No token provided for push notification.")
            return

        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data if data else {},
                token=token,
            )
            response = messaging.send(message)
            print(f"Successfully sent message: {response}")
            return response
        except Exception as e:
            print(f"Error sending push notification: {e}")
            return None

    def send_multicast_notification(self, tokens: list, title: str, body: str, data: dict = None):
        if not tokens:
            return
        
        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data if data else {},
                tokens=tokens,
            )
            response = messaging.send_multicast(message)
            print(f"Successfully sent multicast message: {response.success_count} success, {response.failure_count} failures")
            return response
        except Exception as e:
            print(f"Error sending multicast notification: {e}")
            return None
