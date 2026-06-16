from fastapi import FastAPI

from app.routers import order

app = FastAPI(title="Foaps AI Service", version="1.0.0")

# Register routers — add new feature routers here as the service grows
app.include_router(order.router, prefix="/api/v1")
