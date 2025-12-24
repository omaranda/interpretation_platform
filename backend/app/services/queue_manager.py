from sqlalchemy.orm import Session
from uuid import UUID
from datetime import datetime

from app.models.call import Call, CallStatus
from app.models.queue import QueueItem
from app.models.user import User, UserRole

class QueueManager:
    def __init__(self, db: Session):
        self.db = db

    def add_to_queue(self, call_id: UUID, priority: int = 0) -> QueueItem:
        """Add a call to the queue"""
        max_position = self.db.query(QueueItem).count()

        queue_item = QueueItem(
            call_id=call_id,
            position=max_position + 1,
            priority=priority
        )
        self.db.add(queue_item)
        self.db.commit()
        self.db.refresh(queue_item)
        return queue_item

    def remove_from_queue(self, call_id: UUID):
        """Remove a call from the queue"""
        queue_item = self.db.query(QueueItem).filter(
            QueueItem.call_id == call_id
        ).first()

        if queue_item:
            position = queue_item.position
            self.db.delete(queue_item)

            # Update positions of remaining items
            self.db.query(QueueItem).filter(
                QueueItem.position > position
            ).update({"position": QueueItem.position - 1})

            self.db.commit()

    def get_next_call(self) -> Call | None:
        """Get the next call in the queue based on priority and position"""
        queue_item = self.db.query(QueueItem).order_by(
            QueueItem.priority.desc(),
            QueueItem.created_at
        ).first()

        if queue_item:
            call = self.db.query(Call).filter(Call.id == queue_item.call_id).first()
            return call

        return None

    def assign_call_to_agent(self, call_id: UUID, agent_id: UUID) -> Call:
        """Assign a call to an available agent"""
        call = self.db.query(Call).filter(Call.id == call_id).first()

        if not call:
            raise ValueError("Call not found")

        call.agent_id = agent_id
        call.status = CallStatus.RINGING
        call.start_time = datetime.utcnow()

        self.remove_from_queue(call_id)

        self.db.commit()
        self.db.refresh(call)
        return call

    def get_available_agents(self) -> list[User]:
        """Get list of agents that are not currently on a call"""
        busy_agent_ids = self.db.query(Call.agent_id).filter(
            Call.status.in_([CallStatus.ACTIVE, CallStatus.RINGING])
        ).distinct()

        available_agents = self.db.query(User).filter(
            User.role == UserRole.AGENT,
            ~User.id.in_(busy_agent_ids)
        ).all()

        return available_agents

    def auto_assign_calls(self):
        """Automatically assign waiting calls to available agents"""
        available_agents = self.get_available_agents()

        for agent in available_agents:
            next_call = self.get_next_call()
            if next_call:
                self.assign_call_to_agent(next_call.id, agent.id)
