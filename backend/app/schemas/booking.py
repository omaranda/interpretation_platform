from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from uuid import UUID

class BookingCreate(BaseModel):
    translator_id: UUID
    start_time: datetime
    duration_minutes: int  # 30 or 60
    language: str
    notes: Optional[str] = None

class BookingUpdate(BaseModel):
    status: Optional[str] = None
    notes: Optional[str] = None

class BookingResponse(BaseModel):
    id: UUID
    translator_id: UUID
    employee_id: UUID
    company_id: UUID
    start_time: datetime
    duration_minutes: int
    language: str
    status: str
    jitsi_room_name: Optional[str]
    notes: Optional[str]
    created_at: datetime

    # Nested user info
    translator_name: Optional[str] = None
    employee_name: Optional[str] = None
    company_name: Optional[str] = None

    class Config:
        from_attributes = True

class AvailableSlot(BaseModel):
    translator_id: UUID
    translator_name: str
    languages: list[str]
    available_times: list[datetime]
