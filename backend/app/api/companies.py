from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.security import get_password_hash, get_current_user
from app.db.session import get_db
from app.models.user import User, UserRole, Company
from app.schemas.company import (
    CompanyCreate,
    CompanyResponse,
    EmployeeRegister,
    EmployeeResponse
)

router = APIRouter(prefix="/companies", tags=["companies"])

@router.post("/", response_model=CompanyResponse, status_code=status.HTTP_201_CREATED)
async def create_company(
    company_data: CompanyCreate,
    db: Session = Depends(get_db)
):
    """Create a new company"""
    # Check if company already exists
    existing_company = db.query(Company).filter(
        Company.contact_email == company_data.contact_email
    ).first()

    if existing_company:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Company with this email already exists",
        )

    company = Company(
        name=company_data.name,
        contact_email=company_data.contact_email,
        contact_phone=company_data.contact_phone,
        address=company_data.address
    )

    db.add(company)
    db.commit()
    db.refresh(company)

    return company

@router.get("/", response_model=List[CompanyResponse])
async def get_companies(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all companies (admin only)"""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can view all companies"
        )

    companies = db.query(Company).all()
    return companies

@router.get("/{company_id}", response_model=CompanyResponse)
async def get_company(
    company_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get company details"""
    company = db.query(Company).filter(Company.id == company_id).first()

    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )

    # Check authorization
    is_authorized = (
        current_user.company_id == company.id or
        current_user.role == UserRole.ADMIN
    )

    if not is_authorized:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this company"
        )

    return company

@router.post("/employees/register", response_model=EmployeeResponse, status_code=status.HTTP_201_CREATED)
async def register_employee(
    employee_data: EmployeeRegister,
    db: Session = Depends(get_db)
):
    """Register a new employee"""
    # Check if user already exists
    existing_user = db.query(User).filter(User.email == employee_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    # Verify company exists
    company = db.query(Company).filter(Company.id == employee_data.company_id).first()
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found",
        )

    # Create employee
    employee = User(
        email=employee_data.email,
        name=employee_data.name,
        hashed_password=get_password_hash(employee_data.password),
        role=UserRole.EMPLOYEE,
        company_id=employee_data.company_id
    )

    db.add(employee)
    db.commit()
    db.refresh(employee)

    return employee

@router.get("/{company_id}/employees", response_model=List[EmployeeResponse])
async def get_company_employees(
    company_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all employees of a company"""
    # Check authorization
    is_authorized = (
        str(current_user.company_id) == company_id or
        current_user.role == UserRole.ADMIN
    )

    if not is_authorized:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this company's employees"
        )

    employees = db.query(User).filter(
        User.company_id == company_id,
        User.role.in_([UserRole.EMPLOYEE, UserRole.COMPANY_ADMIN])
    ).all()

    return employees
