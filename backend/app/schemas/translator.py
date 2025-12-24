from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime
from uuid import UUID

class TranslatorRegister(BaseModel):
    email: EmailStr
    name: str
    password: str
    languages: List[str]  # ["SPANISH", "FRENCH", "GERMAN"]
    hourly_rate: Optional[str] = None

class TranslatorResponse(BaseModel):
    id: UUID
    email: str
    name: str
    languages: List[str]
    is_available: bool
    hourly_rate: Optional[str]

    class Config:
        from_attributes = True

class TranslatorAvailability(BaseModel):
    translator_id: UUID
    is_available: bool

class TranslatorUpdate(BaseModel):
    name: Optional[str] = None
    languages: Optional[List[str]] = None
    is_available: Optional[bool] = None
    hourly_rate: Optional[str] = None
