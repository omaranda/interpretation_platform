from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from uuid import UUID

from app.db.session import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.call import Call, CallStatus
from app.schemas.call import CallCreate, CallResponse, CallUpdate

router = APIRouter(prefix="/calls", tags=["calls"])

@router.get("/active", response_model=List[CallResponse])
async def get_active_calls(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    calls = db.query(Call).filter(
        Call.status.in_([CallStatus.WAITING, CallStatus.RINGING, CallStatus.ACTIVE])
    ).all()
    return calls

@router.post("/start", response_model=CallResponse)
async def start_call(
    call_data: CallCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    call = Call(
        room_name=call_data.room_name,
        customer_name=call_data.customer_name,
        customer_phone=call_data.customer_phone,
        status=CallStatus.WAITING,
    )
    db.add(call)
    db.commit()
    db.refresh(call)
    return call

@router.post("/end", response_model=CallResponse)
async def end_call(
    call_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    call = db.query(Call).filter(Call.id == call_id).first()
    if not call:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Call not found"
        )

    if call.status == CallStatus.ENDED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Call already ended"
        )

    call.status = CallStatus.ENDED
    call.end_time = datetime.utcnow()

    if call.start_time:
        duration = (call.end_time - call.start_time).total_seconds()
        call.duration = int(duration)

    db.commit()
    db.refresh(call)
    return call

@router.put("/{call_id}", response_model=CallResponse)
async def update_call(
    call_id: UUID,
    call_update: CallUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    call = db.query(Call).filter(Call.id == call_id).first()
    if not call:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Call not found"
        )

    for field, value in call_update.dict(exclude_unset=True).items():
        setattr(call, field, value)

    db.commit()
    db.refresh(call)
    return call

@router.get("/history", response_model=List[CallResponse])
async def get_call_history(
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    calls = db.query(Call).filter(
        Call.status == CallStatus.ENDED
    ).order_by(Call.end_time.desc()).limit(limit).all()
    return calls
