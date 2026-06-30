from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import chat, order

app = FastAPI(title="Foaps AI Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers — add new feature routers here as the service grows
app.include_router(order.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
