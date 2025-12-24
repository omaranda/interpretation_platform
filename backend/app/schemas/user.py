from pydantic import BaseModel, EmailStr
from uuid import UUID
from typing import Optional, List
from app.models.user import UserRole

class UserBase(BaseModel):
    email: EmailStr
    name: str
    role: UserRole

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: UUID
    languages: Optional[List[str]] = None
    hourly_rate: Optional[str] = None
    is_available: Optional[bool] = True
    company_id: Optional[UUID] = None

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class LoginRequest(BaseModel):
    email: EmailStr
    password: str
