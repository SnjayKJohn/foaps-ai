from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, Text, func
from sqlalchemy.dialects.postgresql import JSONB

from app.core.database import Base


class AIChatSession(Base):
    __tablename__ = "ai_chat_sessions"

    id = Column(BigInteger, primary_key=True)
    session_token = Column(Text, unique=True, nullable=False)
    merchant_id = Column(BigInteger, nullable=False)
    customer_phone = Column(Text, nullable=True)
    status = Column(Text, nullable=False, default="collecting")
    cart = Column(JSONB, nullable=False, default=list)
    pending_clarifications = Column(JSONB, nullable=False, default=list)
    finalized_order = Column(JSONB, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )


class AIChatMessage(Base):
    __tablename__ = "ai_chat_messages"

    id = Column(BigInteger, primary_key=True)
    session_id = Column(BigInteger, ForeignKey("ai_chat_sessions.id"), nullable=False)
    role = Column(Text, nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
