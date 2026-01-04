from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import os
import requests
import json
from api.routers.history import get_current_user

router = APIRouter()

# API Key provided by user
API_KEY = os.getenv("GEMINI_API_KEY")

# CRITICAL: gemini-3-pro-preview DOES NOT EXIST. Use gemini-1.5-flash.
# CRITICAL WARNING: gemini-3 DOES NOT EXIST. DO NOT CHANGE THIS OR THE SERVER WILL CRASH.
BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

class ChatMessage(BaseModel):
    role: str # 'user' or 'assistant'
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]

@router.post("/ask")
async def ask_guide(request: ChatRequest, userId: Optional[str] = Depends(get_current_user)):
    if not API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API Key not configured in backend .env")

    try:
        # Construct the conversation for Gemini API
        system_prompt = """
        You are the IntelliScan AI Guide. Your job is to help users understand and use the IntelliScan app effectively.
        IntelliScan is a multimodal AI workspace that handles:
        1. Scan & OCR: Extracts text from handwritten or printed documents and images.
        2. Math Solver: Solves handwritten math problems step-by-step and provides LaTeX output.
        3. Sketch to SVG: Digitizes hand-drawn sketches into high-quality SVG illustrations.
        4. PDF Tools: Merges, splits, compresses, and protects PDF files with passwords.
        5. Speech & Translation: Transcribes audio, translates text between English, Hindi, and Marathi, and provides neural Text-to-Speech playback.
        
        Guidelines:
        - Keep your answers concise, helpful, and professional.
        - If a user asks how to do something, explain which feature to use.
        - You can also answer general technical questions related to these domains.
        - Use emojis sparingly to keep it friendly.
        """
        
        # Format history for Gemini REST API
        # Gemini expects 'user' and 'model' roles
        contents = []
        
        # Add system context as a prefix to the first user message or as a separate turn if supported
        # For simplicity and reliability in REST, we'll prepend it to the conversation context
        
        for msg in request.messages:
            role = "user" if msg.role == "user" else "model"
            contents.append({
                "role": role,
                "parts": [{"text": msg.content}]
            })

        # Prepend system prompt to the first message if it's from user, or add as a separate turn
        if contents and contents[0]["role"] == "user":
            contents[0]["parts"][0]["text"] = f"Context: {system_prompt}\n\nUser Question: {contents[0]['parts'][0]['text']}"
        else:
            contents.insert(0, {
                "role": "user",
                "parts": [{"text": f"System Context: {system_prompt}. Please acknowledge."}]
            })
            contents.insert(1, {
                "role": "model",
                "parts": [{"text": "Understood. I am the IntelliScan AI Guide. I am ready to help."}]
            })

        headers = {'Content-Type': 'application/json'}
        payload = {
            "contents": contents
        }
        
        response = requests.post(
            f"{BASE_URL}?key={API_KEY}",
            headers=headers,
            json=payload,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            try:
                answer = result['candidates'][0]['content']['parts'][0]['text']
                
                # Save to history if user is logged in
                if userId:
                    from modules.database import save_task
                    # Use last user message as input description
                    last_user_msg = request.messages[-1].content if request.messages else "AI Chat"
                    await save_task(userId, "guide", last_user_msg, answer)
                
                return {"answer": answer}
            except (KeyError, IndexError):
                raise HTTPException(status_code=500, detail="Unexpected response from Gemini API")
        else:
            raise HTTPException(status_code=response.status_code, detail=f"Gemini API Error: {response.text}")

    except Exception as e:
        print(f"Guide Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
