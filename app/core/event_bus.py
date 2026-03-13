from __future__ import annotations

from collections import defaultdict
from collections.abc import Callable
from typing import Any

from PySide6.QtCore import QObject, Signal


EventHandler = Callable[[str, dict[str, Any]], None]


class EventBus(QObject):
    """Simple in-process event bus for app-wide signals."""

    eventEmitted = Signal(str, "QVariantMap")
    # Backward-compatible alias for existing QML handlers/code paths.
    event_emitted = Signal(str, "QVariantMap")

    def __init__(self) -> None:
        super().__init__()
        self._handlers: dict[str, list[EventHandler]] = defaultdict(list)

    def publish(self, event_name: str, payload: dict[str, Any] | None = None) -> None:
        data = payload or {}
        self.eventEmitted.emit(event_name, data)
        self.event_emitted.emit(event_name, data)
        for handler in self._handlers[event_name]:
            handler(event_name, data)
        for handler in self._handlers["*"]:
            handler(event_name, data)

    def subscribe(self, event_name: str, handler: EventHandler) -> None:
        if handler not in self._handlers[event_name]:
            self._handlers[event_name].append(handler)

    def unsubscribe(self, event_name: str, handler: EventHandler) -> None:
        if handler in self._handlers[event_name]:
            self._handlers[event_name].remove(handler)
