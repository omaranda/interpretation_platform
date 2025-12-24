from pydantic import BaseModel, EmailStr
from typing import Optional
from uuid import UUID

class CompanyCreate(BaseModel):
    name: str
    contact_email: EmailStr
    contact_phone: Optional[str] = None
    address: Optional[str] = None

class CompanyResponse(BaseModel):
    id: UUID
    name: str
    contact_email: str
    contact_phone: Optional[str]
    address: Optional[str]

    class Config:
        from_attributes = True

class EmployeeRegister(BaseModel):
    email: EmailStr
    name: str
    password: str
    company_id: UUID

class EmployeeResponse(BaseModel):
    id: UUID
    email: str
    name: str
    role: str
    company_id: Optional[UUID]
    company_name: Optional[str]

    class Config:
        from_attributes = True
