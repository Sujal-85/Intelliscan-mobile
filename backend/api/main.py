print("Starting IntelliScan API Server...")
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import sys
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()


# Add backend root to sys.path to allow imports from modules
backend_root = Path(__file__).parent.parent
sys.path.append(str(backend_root))

print("Importing router: ocr...")
from api.routers import ocr
print("Importing router: speech...")
from api.routers import speech
print("Importing router: math_solver...")
from api.routers import math_solver
print("Importing router: auth...")
from api.routers import auth
print("Importing router: history...")
from api.routers import history
print("Importing router: guide...")
from api.routers import guide
print("Importing router: system...")
from api.routers import system
print("Importing router: referral...")
from api.routers import referral
print("Importing router: vault...")
from api.routers import vault
# print("Im

app = FastAPI(
    title="IntelliScan API",
    description="Backend API for Smart Handwritten Data Recognition",
    version="1.0.0"
)


# print("Importing router: sketch...")
# from api.routers import sketch
# print("Importing router: pdf_tools...")
# from api.routers import pdf_tools

print("Importing router: advanced...")
from api.routers import advanced


# app.include_router(system.router, prefix="/api/system", tags=["System"])
# app.include_router(system.router, prefix="/api/system", tags=["System"])

# CORS Configuration
# In production, we should set FRONTEND_URL environment variable
frontend_url = os.getenv("FRONTEND_URL", "http://localhost:5173")
origins = [
    frontend_url,
    "http://localhost:5173",
    "http://localhost:8080",
    "http://localhost:3000",
    "http://127.0.0.1:5173",
    "http://127.0.0.1:8080",
    "http://127.0.0.1:3000",
]

# Add Render default subdomains if applicable
render_url = os.getenv("RENDER_EXTERNAL_URL")
if render_url:
    origins.append(render_url)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Welcome to IntelliScan API", "status": "running"}

# Include Routers
app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
app.include_router(history.router, prefix="/api/history", tags=["History"])
app.include_router(ocr.router, prefix="/api/ocr", tags=["OCR"])
app.include_router(speech.router, prefix="/api/speech", tags=["Speech"])
app.include_router(math_solver.router, prefix="/api/math", tags=["Math"])
# app.include_router(sketch.router, prefix="/api/sketch", tags=["Sketch"])
# app.include_router(pdf_tools.router, prefix="/api/pdf", tags=["PDF"])
app.include_router(guide.router, prefix="/api/guide", tags=["Guide"])
app.include_router(advanced.router, prefix="/api/advanced", tags=["Advanced"])
app.include_router(system.router, prefix="/api/system", tags=["System"])
app.include_router(referral.router, prefix="/api/referral", tags=["Referral"])
app.include_router(vault.router, prefix="/api/vault", tags=["Vault"])
from api.routers import subscription
app.include_router(subscription.router, prefix="/api/subscription", tags=["Subscription"])

from modules.database import verify_connection

@app.on_event("startup")
async def startup_event():
    # We disable preloading on startup to save memory on limited environments (like Render Free Tier)
    # Models will be lazily loaded when first requested.
    print("Advanced models will be loaded lazily on first request.")
    print("Startup complete. application is ready to listen.")
    # Run DB check in background so it doesn't block startup
    import asyncio
    asyncio.create_task(verify_connection())

