from sqlalchemy import Column, String, Enum as SQLEnum, DateTime, Integer, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
import enum
from datetime import datetime

from app.db.session import Base

class BookingStatus(str, enum.Enum):
    PENDING = "PENDING"
    CONFIRMED = "CONFIRMED"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"

class BookingDuration(str, enum.Enum):
    THIRTY_MINUTES = "30"
    ONE_HOUR = "60"

class Booking(Base):
    __tablename__ = "bookings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Foreign keys
    translator_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=False)
    employee_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=False)
    company_id = Column(UUID(as_uuid=True), ForeignKey('companies.id'), nullable=False)

    # Booking details
    start_time = Column(DateTime, nullable=False)
    duration_minutes = Column(Integer, nullable=False)  # 30 or 60
    language = Column(String, nullable=False)

    # Status
    status = Column(SQLEnum(BookingStatus), nullable=False, default=BookingStatus.PENDING)

    # Meeting details
    jitsi_room_name = Column(String, nullable=True)
    notes = Column(Text, nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    translator = relationship("User", foreign_keys=[translator_id], back_populates="translator_bookings")
    employee = relationship("User", foreign_keys=[employee_id], back_populates="employee_bookings")
    company = relationship("Company")
