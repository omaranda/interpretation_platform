from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional
from app.models.call import CallStatus

class CallBase(BaseModel):
    room_name: str
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None

class CallCreate(CallBase):
    pass

class CallResponse(CallBase):
    id: UUID
    agent_id: Optional[UUID] = None
    status: CallStatus
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    duration: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True

class CallUpdate(BaseModel):
    status: Optional[CallStatus] = None
    agent_id: Optional[UUID] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    duration: Optional[int] = None
