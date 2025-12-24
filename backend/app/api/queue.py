from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
import json

from app.db.session import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.call import Call, CallStatus
from app.models.queue import QueueItem

router = APIRouter(prefix="/queue", tags=["queue"])

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_text(json.dumps(message))
            except:
                pass

manager = ConnectionManager()

@router.get("")
async def get_queue(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    queue_items = db.query(QueueItem).order_by(
        QueueItem.priority.desc(),
        QueueItem.created_at
    ).all()
    return queue_items

@router.get("/metrics")
async def get_metrics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    total_calls = db.query(Call).count()
    active_calls = db.query(Call).filter(Call.status == CallStatus.ACTIVE).count()
    waiting_calls = db.query(Call).filter(Call.status == CallStatus.WAITING).count()

    avg_duration = db.query(func.avg(Call.duration)).filter(
        Call.duration.isnot(None)
    ).scalar() or 0

    return {
        "totalCalls": total_calls,
        "activeCalls": active_calls,
        "waitingCalls": waiting_calls,
        "averageWaitTime": 0,
        "averageCallDuration": int(avg_duration)
    }

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            # Echo back for now, can add more logic later
            await websocket.send_text(f"Message received: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)
