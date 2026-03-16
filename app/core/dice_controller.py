from __future__ import annotations

from typing import Any

from PySide6.QtCore import QObject, Signal, Slot, QTimer

from app.core.event_bus import EventBus
from app.services.dice_service import DiceService


class DiceController(QObject):
    rollCompleted = Signal("QVariantMap")

    def _debug(self, message: str) -> None:
        print(f"[dice-controller-debug] {message}")

    def __init__(self, dice_service: DiceService, event_bus: EventBus) -> None:
        super().__init__()
        self._dice_service = dice_service
        self._event_bus = event_bus
        self._map_window_open = False
        self._request_seq = 0
        self._pending_physics_standard_d6: dict[int, dict[str, Any]] = {}
        self._recent_standard_d6_requests: dict[int, dict[str, Any]] = {}
        self._physics_fallback_timers: dict[int, QTimer] = {}

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

    def _cancel_physics_fallback_timer(self, request_id: int) -> None:
        timer = self._physics_fallback_timers.pop(int(request_id), None)
        if timer is not None:
            timer.stop()
            timer.deleteLater()

    def _start_physics_fallback_timer(self, request_id: int, req_payload: dict[str, Any]) -> None:
        req_id = int(request_id)
        if req_id <= 0:
            return
        self._cancel_physics_fallback_timer(req_id)

        timer = QTimer(self)
        timer.setSingleShot(True)

        def _on_timeout() -> None:
            pending = self._pending_physics_standard_d6.pop(req_id, None)
            self._physics_fallback_timers.pop(req_id, None)
            if pending is None:
                timer.deleteLater()
                return

            self._recent_standard_d6_requests.pop(req_id, None)
            fallback_count = max(1, int(pending.get("d6", 1)))
            fallback = self._dice_service.roll_standard(0, fallback_count, 0, 0, 0, int(pending.get("bonus", 0)))
            self._debug(
                f"physics-timeout fallback request_id={req_id} total={fallback.get('total')} raw={fallback.get('raw_total')}"
            )
            self._event_bus.publish(
                "dice.roll_completed",
                {
                    "request_id": req_id,
                    "kind": "standard",
                    "mode": "physics_fallback_random",
                    "requested_mode": "physics",
                    "result": fallback,
                },
            )
            timer.deleteLater()

        timer.timeout.connect(_on_timeout)
        self._physics_fallback_timers[req_id] = timer
        fallback_count = max(1, int(req_payload.get("d6", 1)))
        timer.start(min(12000, 2500 + fallback_count * 1600))

    @Slot(int, "QVariantList")
    def submit_physics_d6_batch_result(self, request_id: int, values: list[Any]) -> None:
        req_id = int(request_id)
        if req_id <= 0:
            self._debug(f"submit_physics_d6_batch_result ignored invalid request_id={request_id}")
            return

        parsed_values: list[int] = []
        for item in (values or []):
            try:
                v = int(item)
            except (TypeError, ValueError):
                continue
            if v > 0:
                parsed_values.append(max(1, min(6, v)))

        if len(parsed_values) <= 0:
            self._debug(f"submit_physics_d6_batch_result request_id={req_id} got empty values")
            return

        self._cancel_physics_fallback_timer(req_id)
        pending = self._pending_physics_standard_d6.pop(req_id, None)
        recent = self._recent_standard_d6_requests.pop(req_id, None)
        source_payload = pending or recent
        if not source_payload:
            self._debug(f"submit_physics_d6_batch_result request_id={req_id} has no source payload")
            return

        expected = max(1, int(source_payload.get("d6", 1)))
        if len(parsed_values) > expected:
            parsed_values = parsed_values[:expected]

        self._debug(
            f"submit_physics_d6_batch_result request_id={req_id} expected={expected} got={len(parsed_values)} values={parsed_values} "
            f"bonus={int(source_payload.get('bonus', 0))}"
        )

        result = self._build_standard_d6_only_result(parsed_values, source_payload)
        self._event_bus.publish(
            "dice.roll_completed",
            {
                "request_id": req_id,
                "kind": "standard",
                "mode": "physics",
                "requested_mode": "physics",
                "result": result,
            },
        )

    @Slot(int, int)
    def submit_physics_d6_result(self, request_id: int, value: int) -> None:
        self.submit_physics_d6_batch_result(request_id, [int(value)])

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

    def _is_physics_standard_d6_only(
        self,
        kind: str,
        req_payload: dict[str, Any],
        visual_dice: list[int],
    ) -> bool:
        if kind != "standard":
            return False
        if len(visual_dice) <= 0:
            return False
        if any(int(s) != 6 for s in visual_dice):
            return False
        return (
            int(req_payload.get("d4", 0)) == 0
            and int(req_payload.get("d6", 0)) > 0
            and int(req_payload.get("d8", 0)) == 0
            and int(req_payload.get("d10", 0)) == 0
            and int(req_payload.get("d12", 0)) == 0
        )

    def _build_standard_d6_only_result(self, values: list[int], req_payload: dict[str, Any]) -> dict[str, Any]:
        clean_values = [max(1, min(6, int(v))) for v in values if int(v) > 0]
        if len(clean_values) <= 0:
            clean_values = [1]

        bonus = max(-20, min(20, int(req_payload.get("bonus", 0))))
        raw_total = sum(clean_values)
        total = raw_total + bonus

        count = len(clean_values)
        formula = "d6" if count == 1 else f"{count}d6"
        if bonus > 0:
            formula += f" + {bonus}"
        elif bonus < 0:
            formula += f" - {abs(bonus)}"

        return {
            "active": True,
            "kind": "standard",
            "formula": formula,
            "total": total,
            "bonus": bonus,
            "rolls": [{"sides": 6, "value": int(v)} for v in clean_values],
            "raw_total": raw_total,
        }

    def _build_standard_single_d6_result(self, value: int, req_payload: dict[str, Any]) -> dict[str, Any]:
        return self._build_standard_d6_only_result([int(value)], req_payload)

    def _on_roll_requested(self, event_name: str, payload: dict[str, Any]) -> None:
        kind = str(payload.get("kind", "")).strip()
        req_payload = payload.get("payload") or {}
        request_id = int(payload.get("request_id") or 0)

        requested_mode = self._dice_service.resolve_mode(self._map_window_open)
        self._debug(
            f"roll_requested kind={kind} request_id={request_id} requested_mode={requested_mode} payload={req_payload}"
        )
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

        is_standard_d6_only = self._is_physics_standard_d6_only(kind, req_payload, visual_dice)
        self._debug(
            f"visual request_id={request_id} kind={kind} dice={visual_dice} d6_only={is_standard_d6_only}"
        )
        if is_standard_d6_only and request_id > 0:
            self._recent_standard_d6_requests[request_id] = dict(req_payload)
            if len(self._recent_standard_d6_requests) > 256:
                oldest_request_id = min(self._recent_standard_d6_requests.keys())
                self._recent_standard_d6_requests.pop(oldest_request_id, None)

        if requested_mode == "physics" and is_standard_d6_only and request_id > 0:
            # Await physics for d6-only batches while map physics is active.
            self._pending_physics_standard_d6[request_id] = dict(req_payload)
            self._start_physics_fallback_timer(request_id, req_payload)
            self._debug(f"pending physics d6-only request_id={request_id} (requested_mode={requested_mode})")
            return

        if requested_mode == "physics":
            # Other physics paths still use deterministic fallback to RNG.
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

        self._debug(
            f"publish roll_completed request_id={request_id} kind={kind} mode={completed_mode} "
            f"total={result.get('total') if isinstance(result, dict) else '-'}"
        )
        self._event_bus.publish(
            "dice.roll_completed",
            {
                "request_id": request_id,
                "kind": kind,
                "mode": completed_mode,
                "requested_mode": requested_mode,
                "result": result,
            },
        )

    def _on_roll_completed(self, event_name: str, payload: dict[str, Any]) -> None:
        self._debug(
            f"on_roll_completed event request_id={payload.get('request_id')} kind={payload.get('kind')} "
            f"mode={payload.get('mode')}"
        )
        self.rollCompleted.emit(payload)
