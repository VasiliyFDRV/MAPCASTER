from __future__ import annotations

from typing import Any

from PySide6.QtCore import QObject, Signal, Slot

from app.core.event_bus import EventBus
from app.services.dice_service import DiceService


class DiceController(QObject):
    rollCompleted = Signal("QVariantMap")

    def __init__(self, dice_service: DiceService, event_bus: EventBus) -> None:
        super().__init__()
        self._dice_service = dice_service
        self._event_bus = event_bus
        self._map_window_open = False
        self._request_seq = 0

        self._event_bus.subscribe("dice.roll_requested", self._on_roll_requested)
        self._event_bus.subscribe("dice.roll_completed", self._on_roll_completed)

    @Slot(bool)
    def set_map_window_open(self, is_open: bool) -> None:
        self._map_window_open = bool(is_open)

    @Slot(result=bool)
    def is_map_window_open(self) -> bool:
        return self._map_window_open

    def _next_request_id(self) -> int:
        self._request_seq += 1
        return self._request_seq

    @Slot(int, str, int)
    def request_roll_d20(self, count: int, mode: str, bonus: int) -> None:
        self._event_bus.publish(
            "dice.roll_requested",
            {
                "request_id": self._next_request_id(),
                "kind": "d20",
                "payload": {
                    "count": int(count),
                    "mode": str(mode),
                    "bonus": int(bonus),
                },
            },
        )

    @Slot(int, int, int, int, int, int)
    def request_roll_standard(
        self,
        d4: int,
        d6: int,
        d8: int,
        d10: int,
        d12: int,
        bonus: int,
    ) -> None:
        self._event_bus.publish(
            "dice.roll_requested",
            {
                "request_id": self._next_request_id(),
                "kind": "standard",
                "payload": {
                    "d4": int(d4),
                    "d6": int(d6),
                    "d8": int(d8),
                    "d10": int(d10),
                    "d12": int(d12),
                    "bonus": int(bonus),
                },
            },
        )

    @Slot()
    def request_roll_d100(self) -> None:
        self._event_bus.publish(
            "dice.roll_requested",
            {
                "request_id": self._next_request_id(),
                "kind": "d100",
                "payload": {},
            },
        )

    @Slot(int, str, int, int, int, int, int, int, int)
    def request_roll_all(
        self,
        d20_count: int,
        d20_mode: str,
        d20_bonus: int,
        d4: int,
        d6: int,
        d8: int,
        d10: int,
        d12: int,
        standard_bonus: int,
    ) -> None:
        self._event_bus.publish(
            "dice.roll_requested",
            {
                "request_id": self._next_request_id(),
                "kind": "all",
                "payload": {
                    "d20_count": int(d20_count),
                    "d20_mode": str(d20_mode),
                    "d20_bonus": int(d20_bonus),
                    "d4": int(d4),
                    "d6": int(d6),
                    "d8": int(d8),
                    "d10": int(d10),
                    "d12": int(d12),
                    "standard_bonus": int(standard_bonus),
                },
            },
        )

    # Backward-compatible direct methods (used by older QML revisions).
    @Slot(int, str, int, result="QVariantMap")
    def roll_d20(self, count: int, mode: str, bonus: int) -> dict[str, Any]:
        return self._dice_service.roll_d20(count, mode, bonus)

    @Slot(int, int, int, int, int, int, result="QVariantMap")
    def roll_standard(
        self,
        d4: int,
        d6: int,
        d8: int,
        d10: int,
        d12: int,
        bonus: int,
    ) -> dict[str, Any]:
        return self._dice_service.roll_standard(d4, d6, d8, d10, d12, bonus)

    @Slot(result="QVariantMap")
    def roll_d100(self) -> dict[str, Any]:
        return self._dice_service.roll_d100()

    @Slot(int, str, int, int, int, int, int, int, int, result="QVariantMap")
    def roll_all(
        self,
        d20_count: int,
        d20_mode: str,
        d20_bonus: int,
        d4: int,
        d6: int,
        d8: int,
        d10: int,
        d12: int,
        standard_bonus: int,
    ) -> dict[str, Any]:
        return self._dice_service.roll_all(
            d20_count,
            d20_mode,
            d20_bonus,
            d4,
            d6,
            d8,
            d10,
            d12,
            standard_bonus,
        )

    def _effective_count(self, count: int) -> int:
        return 1 if int(count) <= 0 else int(count)

    def _build_visual_dice_list(self, kind: str, req_payload: dict[str, Any]) -> list[int]:
        dice: list[int] = []
        if kind == "d20":
            count = self._effective_count(int(req_payload.get("count", 0)))
            mode = str(req_payload.get("mode", "normal"))
            multiplier = 2 if mode in {"advantage", "disadvantage"} else 1
            dice.extend([20] * (count * multiplier))
            return dice
        if kind == "standard":
            for sides_key, sides in (("d4", 4), ("d6", 6), ("d8", 8), ("d10", 10), ("d12", 12)):
                count = int(req_payload.get(sides_key, 0))
                if count > 0:
                    dice.extend([sides] * count)
            return dice
        if kind == "d100":
            # d100 visualized as two d10 dice (tens + ones)
            return [10, 10]
        if kind == "all":
            d20_count = int(req_payload.get("d20_count", 0))
            d20_mode = str(req_payload.get("d20_mode", "normal"))
            if d20_count > 0:
                multiplier = 2 if d20_mode in {"advantage", "disadvantage"} else 1
                dice.extend([20] * (d20_count * multiplier))
            for sides_key, sides in (("d4", 4), ("d6", 6), ("d8", 8), ("d10", 10), ("d12", 12)):
                count = int(req_payload.get(sides_key, 0))
                if count > 0:
                    dice.extend([sides] * count)
            return dice
        return dice

    def _on_roll_requested(self, event_name: str, payload: dict[str, Any]) -> None:
        kind = str(payload.get("kind", "")).strip()
        req_payload = payload.get("payload") or {}
        request_id = int(payload.get("request_id") or 0)

        requested_mode = self._dice_service.resolve_mode(self._map_window_open)
        completed_mode = requested_mode

        visual_dice = self._build_visual_dice_list(kind, req_payload)
        if len(visual_dice) > 0:
            self._event_bus.publish(
                "dice.visual_roll_requested",
                {
                    "request_id": request_id,
                    "kind": kind,
                    "dice": visual_dice,
                    "requested_mode": requested_mode,
                },
            )

        # Physics mode is planned next; current stage uses deterministic fallback to RNG.
        if requested_mode == "physics":
            completed_mode = "physics_fallback_random"

        result: dict[str, Any]
        if kind == "d20":
            result = self._dice_service.roll_d20(
                int(req_payload.get("count", 0)),
                str(req_payload.get("mode", "normal")),
                int(req_payload.get("bonus", 0)),
            )
        elif kind == "standard":
            result = self._dice_service.roll_standard(
                int(req_payload.get("d4", 0)),
                int(req_payload.get("d6", 0)),
                int(req_payload.get("d8", 0)),
                int(req_payload.get("d10", 0)),
                int(req_payload.get("d12", 0)),
                int(req_payload.get("bonus", 0)),
            )
        elif kind == "d100":
            result = self._dice_service.roll_d100()
        elif kind == "all":
            result = self._dice_service.roll_all(
                int(req_payload.get("d20_count", 0)),
                str(req_payload.get("d20_mode", "normal")),
                int(req_payload.get("d20_bonus", 0)),
                int(req_payload.get("d4", 0)),
                int(req_payload.get("d6", 0)),
                int(req_payload.get("d8", 0)),
                int(req_payload.get("d10", 0)),
                int(req_payload.get("d12", 0)),
                int(req_payload.get("standard_bonus", 0)),
            )
        else:
            return

        self._event_bus.publish(
            "dice.roll_completed",
            {
                "request_id": request_id,
                "kind": kind,
                "mode": completed_mode,
                "result": result,
            },
        )

    def _on_roll_completed(self, event_name: str, payload: dict[str, Any]) -> None:
        self.rollCompleted.emit(payload)
