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
        self._pending_physics_standard_d8: dict[int, dict[str, Any]] = {}
        self._recent_standard_d6_requests: dict[int, dict[str, Any]] = {}
        self._physics_fallback_timers: dict[int, QTimer] = {}
        self._active_standard_d6_batch: dict[str, Any] | None = None

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

    def _start_physics_fallback_timer(self, request_id: int, req_payload: dict[str, Any], sides: int = 6) -> None:
        req_id = int(request_id)
        if req_id <= 0:
            return
        self._cancel_physics_fallback_timer(req_id)

        timer = QTimer(self)
        timer.setSingleShot(True)

        def _on_timeout() -> None:
            if int(sides) == 8:
                pending = self._pending_physics_standard_d8.pop(req_id, None)
            else:
                pending = self._pending_physics_standard_d6.pop(req_id, None)
            self._physics_fallback_timers.pop(req_id, None)
            if pending is None:
                timer.deleteLater()
                return

            if int(sides) == 6:
                self._recent_standard_d6_requests.pop(req_id, None)
                batch = self._active_standard_d6_batch
                if batch and int(batch.get("request_id", 0)) == req_id:
                    self._active_standard_d6_batch = None

            fallback_count = max(1, int(pending.get("expected_count", pending.get(f"d{int(sides)}", 1))))
            bonus = int(pending.get("bonus", 0))
            if int(sides) == 8:
                fallback = self._dice_service.roll_standard(0, 0, fallback_count, 0, 0, bonus)
            else:
                fallback = self._dice_service.roll_standard(0, fallback_count, 0, 0, 0, bonus)
            self._debug(
                f"physics-timeout fallback request_id={req_id} sides={int(sides)} total={fallback.get('total')} raw={fallback.get('raw_total')}"
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
        fallback_count = max(1, int(req_payload.get(f"d{int(sides)}", 1)))
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

        pending = self._pending_physics_standard_d6.get(req_id)
        if not pending:
            self._debug(f"submit_physics_d6_batch_result request_id={req_id} has no pending batch")
            return

        expected = max(1, int(pending.get("expected_count", pending.get("d6", 1))))
        current_values = list(pending.get("values", []))
        current_values.extend(parsed_values)
        if len(current_values) > expected:
            current_values = current_values[:expected]

        pending["values"] = current_values
        pending["expected_count"] = expected
        pending["d6"] = expected

        batch = self._active_standard_d6_batch
        if batch and int(batch.get("request_id", 0)) == req_id:
            batch["landed_count"] = len(current_values)

        self._debug(
            f"submit_physics_d6_batch_result request_id={req_id} expected={expected} landed={len(current_values)} "
            f"values={current_values} bonus={int(pending.get('bonus', 0))}"
        )

        if len(current_values) < expected:
            return

        self._cancel_physics_fallback_timer(req_id)
        self._pending_physics_standard_d6.pop(req_id, None)
        self._recent_standard_d6_requests.pop(req_id, None)

        req_payload = {
            "d6": expected,
            "bonus": int(pending.get("bonus", 0)),
        }
        result = self._build_standard_d6_only_result(current_values, req_payload)

        if batch and int(batch.get("request_id", 0)) == req_id:
            self._active_standard_d6_batch = None

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
    @Slot(int, int, "QVariantList")
    def submit_physics_standard_batch_result(self, request_id: int, sides: int, values: list[Any]) -> None:
        s = int(sides)
        if s == 6:
            self.submit_physics_d6_batch_result(request_id, values)
            return
        if s != 8:
            self._debug(f"submit_physics_standard_batch_result unsupported sides={s}")
            return

        req_id = int(request_id)
        if req_id <= 0:
            self._debug(f"submit_physics_standard_batch_result ignored invalid request_id={request_id}")
            return

        parsed_values: list[int] = []
        for item in (values or []):
            try:
                v = int(item)
            except (TypeError, ValueError):
                continue
            if v > 0:
                parsed_values.append(max(1, min(8, v)))

        if len(parsed_values) <= 0:
            self._debug(f"submit_physics_standard_batch_result request_id={req_id} sides=8 got empty values")
            return

        pending = self._pending_physics_standard_d8.get(req_id)
        if not pending:
            self._debug(f"submit_physics_standard_batch_result request_id={req_id} sides=8 has no pending batch")
            return

        expected = max(1, int(pending.get("expected_count", pending.get("d8", 1))))
        current_values = list(pending.get("values", []))
        current_values.extend(parsed_values)
        if len(current_values) > expected:
            current_values = current_values[:expected]

        pending["values"] = current_values
        pending["expected_count"] = expected
        pending["d8"] = expected

        self._debug(
            f"submit_physics_standard_batch_result request_id={req_id} sides=8 expected={expected} landed={len(current_values)} values={current_values} bonus={int(pending.get('bonus', 0))}"
        )

        if len(current_values) < expected:
            return

        self._cancel_physics_fallback_timer(req_id)
        self._pending_physics_standard_d8.pop(req_id, None)

        result = self._build_standard_single_type_result(current_values, 8, int(pending.get("bonus", 0)))
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

    @Slot(result=bool)
    def request_clear_dice_visuals(self) -> bool:
        batch = self._active_standard_d6_batch
        if batch and int(batch.get("expected_count", 0)) > int(batch.get("landed_count", 0)):
            self._debug(
                f"clear visuals ignored request_id={int(batch.get('request_id', 0))} "
                f"landed={int(batch.get('landed_count', 0))}/{int(batch.get('expected_count', 0))}"
            )
            return False
        self._event_bus.publish("dice.visual.clear_requested", {"source": "ui_interaction"})
        return True
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

    def _is_physics_standard_d8_only(
        self,
        kind: str,
        req_payload: dict[str, Any],
        visual_dice: list[int],
    ) -> bool:
        if kind != "standard":
            return False
        if len(visual_dice) <= 0:
            return False
        if any(int(s) != 8 for s in visual_dice):
            return False
        return (
            int(req_payload.get("d4", 0)) == 0
            and int(req_payload.get("d6", 0)) == 0
            and int(req_payload.get("d8", 0)) > 0
            and int(req_payload.get("d10", 0)) == 0
            and int(req_payload.get("d12", 0)) == 0
        )

    def _register_or_extend_pending_d6(self, request_id: int, add_count: int, bonus: int) -> dict[str, Any]:
        req_id = int(request_id)
        count = max(1, int(add_count))
        b = max(-20, min(20, int(bonus)))

        pending = self._pending_physics_standard_d6.get(req_id)
        if pending is None:
            pending = {
                "d6": count,
                "expected_count": count,
                "values": [],
                "bonus": b,
            }
        else:
            expected = max(1, int(pending.get("expected_count", pending.get("d6", 1))))
            expected += count
            pending["d6"] = expected
            pending["expected_count"] = expected
            pending["bonus"] = int(pending.get("bonus", b))

        self._pending_physics_standard_d6[req_id] = pending
        self._recent_standard_d6_requests[req_id] = {"d6": int(pending.get("d6", 1)), "bonus": int(pending.get("bonus", b))}
        self._start_physics_fallback_timer(req_id, {"d6": int(pending.get("d6", 1)), "bonus": int(pending.get("bonus", b))}, sides=6)
        return pending

    def _register_pending_d8(self, request_id: int, count: int, bonus: int) -> dict[str, Any]:
        req_id = int(request_id)
        c = max(1, int(count))
        b = max(-20, min(20, int(bonus)))
        pending = {
            "d8": c,
            "expected_count": c,
            "values": [],
            "bonus": b,
        }
        self._pending_physics_standard_d8[req_id] = pending
        self._start_physics_fallback_timer(req_id, {"d8": c, "bonus": b}, sides=8)
        return pending

    def _build_standard_single_type_result(self, values: list[int], sides: int, bonus: int) -> dict[str, Any]:
        s = max(2, int(sides))
        clean_values = [max(1, min(s, int(v))) for v in values if int(v) > 0]
        if len(clean_values) <= 0:
            clean_values = [1]

        b = max(-20, min(20, int(bonus)))
        raw_total = sum(clean_values)
        total = raw_total + b

        count = len(clean_values)
        formula = f"d{s}" if count == 1 else f"{count}d{s}"
        if b > 0:
            formula += f" + {b}"
        elif b < 0:
            formula += f" - {abs(b)}"

        return {
            "active": True,
            "kind": "standard",
            "formula": formula,
            "total": total,
            "bonus": b,
            "rolls": [{"sides": s, "value": int(v)} for v in clean_values],
            "raw_total": raw_total,
        }

    def _build_standard_d6_only_result(self, values: list[int], req_payload: dict[str, Any]) -> dict[str, Any]:
        return self._build_standard_single_type_result(values, 6, int(req_payload.get("bonus", 0)))

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

        if kind == "standard" and request_id > 0:
            d4 = int(req_payload.get("d4", 0))
            d6 = int(req_payload.get("d6", 0))
            d8 = int(req_payload.get("d8", 0))
            d10 = int(req_payload.get("d10", 0))
            d12 = int(req_payload.get("d12", 0))
            bonus = int(req_payload.get("bonus", 0))
            is_d6_only = d4 == 0 and d6 > 0 and d8 == 0 and d10 == 0 and d12 == 0

            if is_d6_only:
                d6_count = self._effective_count(d6)
                batch = self._active_standard_d6_batch
                append = False
                master_request_id = request_id

                if batch and int(batch.get("expected_count", 0)) > int(batch.get("landed_count", 0)):
                    master_request_id = int(batch.get("request_id", request_id))
                    batch["expected_count"] = int(batch.get("expected_count", 0)) + d6_count
                    append = True
                else:
                    self._active_standard_d6_batch = {
                        "request_id": request_id,
                        "expected_count": d6_count,
                        "landed_count": 0,
                        "bonus": max(-20, min(20, bonus)),
                    }

                pending = self._register_or_extend_pending_d6(master_request_id, d6_count, int(self._active_standard_d6_batch.get("bonus", bonus)) if self._active_standard_d6_batch else bonus)
                self._debug(
                    f"d6 interactive batch request_id={master_request_id} append={append} "
                    f"expected={int(pending.get('expected_count', 0))}"
                )
                self._event_bus.publish(
                    "dice.visual_roll_requested",
                    {
                        "request_id": master_request_id,
                        "kind": "standard",
                        "dice": [6] * d6_count,
                        "requested_mode": "physics",
                        "append": append,
                    },
                )
                return

            is_d8_only = d4 == 0 and d6 == 0 and d8 > 0 and d10 == 0 and d12 == 0
            if is_d8_only:
                d8_count = self._effective_count(d8)
                pending = self._register_pending_d8(request_id, d8_count, bonus)
                self._debug(
                    f"d8 physics request_id={request_id} expected={int(pending.get('expected_count', 0))}"
                )
                self._event_bus.publish(
                    "dice.visual_roll_requested",
                    {
                        "request_id": request_id,
                        "kind": "standard",
                        "dice": [8] * d8_count,
                        "requested_mode": "physics",
                        "append": False,
                    },
                )
                return

        visual_dice = self._build_visual_dice_list(kind, req_payload)
        if len(visual_dice) > 0:
            self._event_bus.publish(
                "dice.visual_roll_requested",
                {
                    "request_id": request_id,
                    "kind": kind,
                    "dice": visual_dice,
                    "requested_mode": requested_mode,
                    "append": False,
                },
            )

        is_standard_d6_only = self._is_physics_standard_d6_only(kind, req_payload, visual_dice)
        is_standard_d8_only = self._is_physics_standard_d8_only(kind, req_payload, visual_dice)
        self._debug(
            f"visual request_id={request_id} kind={kind} dice={visual_dice} d6_only={is_standard_d6_only}"
        )
        if is_standard_d6_only and request_id > 0:
            self._recent_standard_d6_requests[request_id] = dict(req_payload)
            if len(self._recent_standard_d6_requests) > 256:
                oldest_request_id = min(self._recent_standard_d6_requests.keys())
                self._recent_standard_d6_requests.pop(oldest_request_id, None)

        if is_standard_d6_only and request_id > 0:
            self._pending_physics_standard_d6[request_id] = {
                "d6": max(1, int(req_payload.get("d6", 1))),
                "expected_count": max(1, int(req_payload.get("d6", 1))),
                "values": [],
                "bonus": int(req_payload.get("bonus", 0)),
            }
            self._start_physics_fallback_timer(request_id, req_payload, sides=6)
            self._debug(f"pending physics d6-only request_id={request_id} (requested_mode={requested_mode})")
            return

        if is_standard_d8_only and request_id > 0:
            self._pending_physics_standard_d8[request_id] = {
                "d8": max(1, int(req_payload.get("d8", 1))),
                "expected_count": max(1, int(req_payload.get("d8", 1))),
                "values": [],
                "bonus": int(req_payload.get("bonus", 0)),
            }
            self._start_physics_fallback_timer(request_id, req_payload, sides=8)
            self._debug(f"pending physics d8-only request_id={request_id} (requested_mode={requested_mode})")
            return

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

