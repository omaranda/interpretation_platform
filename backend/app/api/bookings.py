from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timedelta
import uuid

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.booking import Booking, BookingStatus
from app.schemas.booking import BookingCreate, BookingUpdate, BookingResponse

router = APIRouter(prefix="/bookings", tags=["bookings"])

@router.post("/", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
async def create_booking(
    booking_data: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new booking for translation service"""
    # Verify translator exists and is available
    translator = db.query(User).filter(
        User.id == booking_data.translator_id,
        User.role == UserRole.TRANSLATOR
    ).first()

    if not translator:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Translator not found"
        )

    if not translator.is_available:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Translator is not available"
        )

    # Verify language is supported by translator
    if booking_data.language not in translator.languages:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Translator does not support {booking_data.language}"
        )

    # Verify duration
    if booking_data.duration_minutes not in [30, 60]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Duration must be either 30 or 60 minutes"
        )

    # Check for conflicting bookings
    end_time = booking_data.start_time + timedelta(minutes=booking_data.duration_minutes)
    conflicting_booking = db.query(Booking).filter(
        Booking.translator_id == booking_data.translator_id,
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.PENDING]),
        Booking.start_time < end_time,
        Booking.start_time >= booking_data.start_time
    ).first()

    if conflicting_booking:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Translator already has a booking at this time"
        )

    # Generate Jitsi room name
    jitsi_room = f"translation-{uuid.uuid4().hex[:12]}"

    # Create booking
    booking = Booking(
        translator_id=booking_data.translator_id,
        employee_id=current_user.id,
        company_id=current_user.company_id,
        start_time=booking_data.start_time,
        duration_minutes=booking_data.duration_minutes,
        language=booking_data.language,
        jitsi_room_name=jitsi_room,
        notes=booking_data.notes,
        status=BookingStatus.CONFIRMED
    )

    db.add(booking)
    db.commit()
    db.refresh(booking)

    return booking

@router.get("/", response_model=List[BookingResponse])
async def get_bookings(
    start_date: datetime = None,
    end_date: datetime = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get bookings for current user (translator or employee)"""
    query = db.query(Booking)

    # Filter based on user role
    if current_user.role == UserRole.TRANSLATOR:
        query = query.filter(Booking.translator_id == current_user.id)
    elif current_user.role in [UserRole.EMPLOYEE, UserRole.COMPANY_ADMIN]:
        if current_user.role == UserRole.EMPLOYEE:
            query = query.filter(Booking.employee_id == current_user.id)
        else:
            query = query.filter(Booking.company_id == current_user.company_id)
    elif current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view bookings"
        )

    # Filter by date range
    if start_date:
        query = query.filter(Booking.start_time >= start_date)
    if end_date:
        query = query.filter(Booking.start_time <= end_date)

    bookings = query.order_by(Booking.start_time).all()
    return bookings

@router.get("/{booking_id}", response_model=BookingResponse)
async def get_booking(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get specific booking details"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()

    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )

    # Check authorization
    is_authorized = (
        booking.translator_id == current_user.id or
        booking.employee_id == current_user.id or
        (current_user.company_id and booking.company_id == current_user.company_id) or
        current_user.role == UserRole.ADMIN
    )

    if not is_authorized:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this booking"
        )

    return booking

@router.put("/{booking_id}", response_model=BookingResponse)
async def update_booking(
    booking_id: str,
    update_data: BookingUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update booking status or notes"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()

    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )

    # Check authorization
    is_authorized = (
        booking.translator_id == current_user.id or
        booking.employee_id == current_user.id or
        current_user.role == UserRole.ADMIN
    )

    if not is_authorized:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this booking"
        )

    # Update fields
    if update_data.status:
        booking.status = update_data.status
    if update_data.notes is not None:
        booking.notes = update_data.notes

    db.commit()
    db.refresh(booking)

    return booking

@router.delete("/{booking_id}")
async def cancel_booking(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Cancel a booking"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()

    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )

    # Check authorization
    is_authorized = (
        booking.employee_id == current_user.id or
        current_user.role == UserRole.ADMIN
    )

    if not is_authorized:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to cancel this booking"
        )

    booking.status = BookingStatus.CANCELLED
    db.commit()

    return {"message": "Booking cancelled successfully"}
