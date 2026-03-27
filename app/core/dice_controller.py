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
        self._pending_physics_standard: dict[int, dict[str, Any]] = {}
        self._pending_physics_d20: dict[int, dict[str, Any]] = {}
        self._pending_physics_d100: dict[int, dict[str, Any]] = {}
        self._physics_fallback_timers: dict[int, QTimer] = {}
        self._physics_d20_fallback_timers: dict[int, QTimer] = {}
        self._physics_d100_fallback_timers: dict[int, QTimer] = {}
        self._active_standard_physics_batch: dict[str, Any] | None = None
        self._active_d20_physics_batch: dict[str, Any] | None = None

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

    def _start_physics_fallback_timer(self, request_id: int, expected_total: int) -> None:
        req_id = int(request_id)
        if req_id <= 0:
            return
        self._cancel_physics_fallback_timer(req_id)

        timer = QTimer(self)
        timer.setSingleShot(True)

        def _on_timeout() -> None:
            pending = self._pending_physics_standard.pop(req_id, None)
            self._physics_fallback_timers.pop(req_id, None)
            if pending is None:
                timer.deleteLater()
                return

            batch = self._active_standard_physics_batch
            if batch and int(batch.get("request_id", 0)) == req_id:
                self._active_standard_physics_batch = None

            expected_by_sides = pending.get("expected_by_sides") or {}
            d4_count = max(0, int(expected_by_sides.get(4, 0)))
            d6_count = max(0, int(expected_by_sides.get(6, 0)))
            d8_count = max(0, int(expected_by_sides.get(8, 0)))
            d10_count = max(0, int(expected_by_sides.get(10, 0)))
            d12_count = max(0, int(expected_by_sides.get(12, 0)))
            bonus = int(pending.get("bonus", 0))
            fallback = self._dice_service.roll_standard(d4_count, d6_count, d8_count, d10_count, d12_count, bonus)
            self._debug(
                f"physics-timeout fallback request_id={req_id} d4={d4_count} d6={d6_count} d8={d8_count} d10={d10_count} d12={d12_count} total={fallback.get('total')} raw={fallback.get('raw_total')}"
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
        timer.start(min(14000, 2600 + max(1, int(expected_total)) * 1400))

    def _cancel_d100_fallback_timer(self, request_id: int) -> None:
        timer = self._physics_d100_fallback_timers.pop(int(request_id), None)
        if timer is not None:
            timer.stop()
            timer.deleteLater()

    def _cancel_d20_fallback_timer(self, request_id: int) -> None:
        timer = self._physics_d20_fallback_timers.pop(int(request_id), None)
        if timer is not None:
            timer.stop()
            timer.deleteLater()

    def _start_physics_d20_fallback_timer(self, request_id: int, expected_total: int) -> None:
        req_id = int(request_id)
        if req_id <= 0:
            return
        self._cancel_d20_fallback_timer(req_id)

        timer = QTimer(self)
        timer.setSingleShot(True)

        def _on_timeout() -> None:
            pending = self._pending_physics_d20.pop(req_id, None)
            self._physics_d20_fallback_timers.pop(req_id, None)
            if pending is None:
                timer.deleteLater()
                return

            fallback = self._dice_service.roll_d20(
                int(pending.get("count", 0)),
                str(pending.get("mode", "normal")),
                int(pending.get("bonus", 0)),
            )
            self._debug(
                f"physics-timeout fallback d20 request_id={req_id} total={fallback.get('total')} raw={fallback.get('raw_total')}"
            )
            self._event_bus.publish(
                "dice.roll_completed",
                {
                    "request_id": req_id,
                    "kind": "d20",
                    "mode": "physics_fallback_random",
                    "requested_mode": "physics",
                    "result": fallback,
                },
            )
            timer.deleteLater()

        timer.timeout.connect(_on_timeout)
        self._physics_d20_fallback_timers[req_id] = timer
        timer.start(min(14000, 2400 + max(1, int(expected_total)) * 1200))

    def _start_physics_d100_fallback_timer(self, request_id: int) -> None:
        req_id = int(request_id)
        if req_id <= 0:
            return
        self._cancel_d100_fallback_timer(req_id)

        timer = QTimer(self)
        timer.setSingleShot(True)

        def _on_timeout() -> None:
            pending = self._pending_physics_d100.pop(req_id, None)
            self._physics_d100_fallback_timers.pop(req_id, None)
            if pending is None:
                timer.deleteLater()
                return

            fallback = self._dice_service.roll_d100()
            self._debug(
                f"physics-timeout fallback d100 request_id={req_id} total={fallback.get('total')}"
            )
            self._event_bus.publish(
                "dice.roll_completed",
                {
                    "request_id": req_id,
                    "kind": "d100",
                    "mode": "physics_fallback_random",
                    "requested_mode": "physics",
                    "result": fallback,
                },
            )
            timer.deleteLater()

        timer.timeout.connect(_on_timeout)
        self._physics_d100_fallback_timers[req_id] = timer
        timer.start(9000)

    def _cancel_all_pending_standard_physics(self, reason: str) -> None:
        pending_ids = list(self._pending_physics_standard.keys())
        if len(pending_ids) <= 0 and self._active_standard_physics_batch is None:
            return
        for req_id in pending_ids:
            self._cancel_physics_fallback_timer(int(req_id))
        self._pending_physics_standard.clear()
        self._active_standard_physics_batch = None
        self._debug(f"cancel pending standard physics reason={reason} requests={pending_ids}")

    def _cancel_all_pending_d100_physics(self, reason: str) -> None:
        pending_ids = list(self._pending_physics_d100.keys())
        if len(pending_ids) <= 0:
            return
        for req_id in pending_ids:
            self._cancel_d100_fallback_timer(int(req_id))
        self._pending_physics_d100.clear()
        self._debug(f"cancel pending d100 physics reason={reason} requests={pending_ids}")

    def _cancel_all_pending_d20_physics(self, reason: str) -> None:
        pending_ids = list(self._pending_physics_d20.keys())
        if len(pending_ids) <= 0 and self._active_d20_physics_batch is None:
            return
        for req_id in pending_ids:
            self._cancel_d20_fallback_timer(int(req_id))
        self._pending_physics_d20.clear()
        self._active_d20_physics_batch = None
        self._debug(f"cancel pending d20 physics reason={reason} requests={pending_ids}")

    def _is_supported_standard_physics_request(
        self,
        kind: str,
        req_payload: dict[str, Any],
        visual_dice: list[int],
    ) -> bool:
        if kind != "standard" or len(visual_dice) <= 0:
            return False
        return all(int(sides) in {4, 6, 8, 10, 12} for sides in visual_dice)

    def _register_or_extend_standard_physics_batch(
        self,
        request_id: int,
        d4_count: int,
        d6_count: int,
        d8_count: int,
        d10_count: int,
        d12_count: int,
        bonus: int,
    ) -> tuple[int, bool, dict[str, Any]]:
        c4 = max(0, int(d4_count))
        c6 = max(0, int(d6_count))
        c8 = max(0, int(d8_count))
        c10 = max(0, int(d10_count))
        c12 = max(0, int(d12_count))
        b = max(-20, min(20, int(bonus)))
        batch = self._active_standard_physics_batch

        if (
            batch
            and int(batch.get("expected_total", 0)) > int(batch.get("landed_total", 0))
            and int(batch.get("bonus", b)) == b
        ):
            master_request_id = int(batch.get("request_id", request_id))
            batch["expected_total"] = int(batch.get("expected_total", 0)) + c4 + c6 + c8 + c10 + c12
            expected_by_sides = dict(batch.get("expected_by_sides") or {})
            expected_by_sides[4] = int(expected_by_sides.get(4, 0)) + c4
            expected_by_sides[6] = int(expected_by_sides.get(6, 0)) + c6
            expected_by_sides[8] = int(expected_by_sides.get(8, 0)) + c8
            expected_by_sides[10] = int(expected_by_sides.get(10, 0)) + c10
            expected_by_sides[12] = int(expected_by_sides.get(12, 0)) + c12
            batch["expected_by_sides"] = expected_by_sides
            append = True
        else:
            master_request_id = int(request_id)
            batch = {
                "request_id": master_request_id,
                "expected_total": c4 + c6 + c8 + c10 + c12,
                "landed_total": 0,
                "expected_by_sides": {4: c4, 6: c6, 8: c8, 10: c10, 12: c12},
                "bonus": b,
            }
            self._active_standard_physics_batch = batch
            append = False

        pending = self._pending_physics_standard.get(master_request_id)
        if pending is None:
            pending = {
                "expected_by_sides": {4: 0, 6: 0, 8: 0, 10: 0, 12: 0},
                "values_by_sides": {4: [], 6: [], 8: [], 10: [], 12: []},
                "expected_total": 0,
                "bonus": b,
            }
        expected_by_sides = dict(pending.get("expected_by_sides") or {})
        expected_by_sides[4] = int(expected_by_sides.get(4, 0)) + c4
        expected_by_sides[6] = int(expected_by_sides.get(6, 0)) + c6
        expected_by_sides[8] = int(expected_by_sides.get(8, 0)) + c8
        expected_by_sides[10] = int(expected_by_sides.get(10, 0)) + c10
        expected_by_sides[12] = int(expected_by_sides.get(12, 0)) + c12
        pending["expected_by_sides"] = expected_by_sides
        pending["expected_total"] = (
            int(expected_by_sides.get(4, 0))
            + int(expected_by_sides.get(6, 0))
            + int(expected_by_sides.get(8, 0))
            + int(expected_by_sides.get(10, 0))
            + int(expected_by_sides.get(12, 0))
        )
        pending["bonus"] = b
        pending.setdefault("values_by_sides", {4: [], 6: [], 8: [], 10: [], 12: []})

        self._pending_physics_standard[master_request_id] = pending
        self._start_physics_fallback_timer(master_request_id, int(pending.get("expected_total", 1)))
        return master_request_id, append, pending


    def _register_or_extend_d20_physics_batch(
        self,
        request_id: int,
        count: int,
        mode: str,
        bonus: int,
    ) -> tuple[int, bool, dict[str, Any]]:
        c = max(1, int(count))
        m = str(mode)
        if m not in {"normal", "advantage", "disadvantage"}:
            m = "normal"
        b = max(-20, min(20, int(bonus)))
        multiplier = 2 if m in {"advantage", "disadvantage"} else 1
        add_expected = c * multiplier

        batch = self._active_d20_physics_batch
        if batch and int(batch.get("expected_total", 0)) > int(batch.get("landed_total", 0)):
            master_request_id = int(batch.get("request_id", request_id))
            batch_mode = str(batch.get("mode", m))
            batch_multiplier = 2 if batch_mode in {"advantage", "disadvantage"} else 1
            add_expected = c * batch_multiplier
            batch["count"] = int(batch.get("count", 0)) + c
            batch["expected_total"] = int(batch.get("expected_total", 0)) + add_expected
            append = True
            m = batch_mode
            b = int(batch.get("bonus", b))
        else:
            master_request_id = int(request_id)
            batch = {
                "request_id": master_request_id,
                "count": c,
                "mode": m,
                "bonus": b,
                "expected_total": add_expected,
                "landed_total": 0,
            }
            self._active_d20_physics_batch = batch
            append = False

        pending = self._pending_physics_d20.get(master_request_id)
        if pending is None:
            pending = {
                "request_id": master_request_id,
                "count": 0,
                "mode": m,
                "bonus": b,
                "expected_total": 0,
                "values": [],
            }
        pending["count"] = int(pending.get("count", 0)) + c
        pending["mode"] = m
        pending["bonus"] = b
        pending["expected_total"] = int(pending.get("expected_total", 0)) + add_expected
        pending.setdefault("values", [])

        self._pending_physics_d20[master_request_id] = pending
        self._start_physics_d20_fallback_timer(master_request_id, int(pending.get("expected_total", 1)))
        return master_request_id, append, pending
    def _build_standard_mixed_result(self, values_by_sides: dict[int, list[int]], bonus: int) -> dict[str, Any]:
        b = max(-20, min(20, int(bonus)))
        rolls: list[dict[str, int]] = []
        formula_parts: list[str] = []

        for sides in (4, 6, 8, 10, 12):
            values = [int(v) for v in (values_by_sides.get(sides) or []) if int(v) > 0]
            if len(values) <= 0:
                continue
            formula_parts.append(f"d{sides}" if len(values) == 1 else f"{len(values)}d{sides}")
            for value in values:
                rolls.append({"sides": int(sides), "value": int(value)})

        if len(rolls) <= 0:
            rolls = [{"sides": 6, "value": 1}]
            formula_parts = ["d6"]

        raw_total = sum(int(roll["value"]) for roll in rolls)
        total = raw_total + b
        formula = " + ".join(formula_parts)
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
            "rolls": rolls,
            "raw_total": raw_total,
        }

    def _try_finalize_standard_physics_batch(self, request_id: int) -> None:
        req_id = int(request_id)
        pending = self._pending_physics_standard.get(req_id)
        if not pending:
            return

        expected_by_sides = pending.get("expected_by_sides") or {}
        values_by_sides = pending.get("values_by_sides") or {}
        expected_total = int(pending.get("expected_total", 0))
        landed_total = len(values_by_sides.get(4) or []) + len(values_by_sides.get(6) or []) + len(values_by_sides.get(8) or []) + len(values_by_sides.get(10) or []) + len(values_by_sides.get(12) or [])

        batch = self._active_standard_physics_batch
        if batch and int(batch.get("request_id", 0)) == req_id:
            batch["landed_total"] = landed_total

        self._debug(
            f"physics-batch progress request_id={req_id} landed={landed_total}/{expected_total} "
            f"d4={len(values_by_sides.get(4) or [])}/{int(expected_by_sides.get(4, 0))} "
            f"d6={len(values_by_sides.get(6) or [])}/{int(expected_by_sides.get(6, 0))} "
            f"d8={len(values_by_sides.get(8) or [])}/{int(expected_by_sides.get(8, 0))} "
            f"d10={len(values_by_sides.get(10) or [])}/{int(expected_by_sides.get(10, 0))} "
            f"d12={len(values_by_sides.get(12) or [])}/{int(expected_by_sides.get(12, 0))}"
        )

        if landed_total < expected_total:
            return

        self._cancel_physics_fallback_timer(req_id)
        self._pending_physics_standard.pop(req_id, None)
        if batch and int(batch.get("request_id", 0)) == req_id:
            self._active_standard_physics_batch = None

        result = self._build_standard_mixed_result(
            {
                4: [int(v) for v in (values_by_sides.get(4) or [])],
                6: [int(v) for v in (values_by_sides.get(6) or [])],
                8: [int(v) for v in (values_by_sides.get(8) or [])],
                10: [int(v) for v in (values_by_sides.get(10) or [])],
                12: [int(v) for v in (values_by_sides.get(12) or [])],
            },
            int(pending.get("bonus", 0)),
        )
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

    def _build_d20_physics_result(
        self,
        values: list[int],
        count: int,
        mode: str,
        bonus: int,
    ) -> dict[str, Any]:
        c = max(0, int(count))
        b = max(-20, min(20, int(bonus)))
        m = str(mode)
        if m not in {"normal", "advantage", "disadvantage"}:
            m = "normal"

        rolls: list[dict[str, Any]] = []
        raw_total = 0
        idx = 0
        if m == "normal":
            for _ in range(c):
                if idx >= len(values):
                    break
                value = int(values[idx])
                idx += 1
                raw_total += value
                rolls.append({"type": "single", "value": value})
        else:
            for _ in range(c):
                if idx + 1 >= len(values):
                    break
                first = int(values[idx])
                second = int(values[idx + 1])
                idx += 2
                picked = max(first, second) if m == "advantage" else min(first, second)
                raw_total += picked
                rolls.append(
                    {
                        "type": "pair",
                        "first": first,
                        "second": second,
                        "picked": picked,
                    }
                )

        base = "d20" if c == 1 else f"{c}d20"
        if m == "advantage":
            base += "(advantage)"
        elif m == "disadvantage":
            base += "(disadvantage)"
        if b > 0:
            base += f" + {b}"
        elif b < 0:
            base += f" - {abs(b)}"

        return {
            "active": c > 0,
            "kind": "d20",
            "formula": base if c > 0 else "",
            "total": raw_total + b if c > 0 else 0,
            "bonus": b,
            "rolls": rolls,
            "mode": m,
            "raw_total": raw_total,
        }

    def _try_finalize_d20_physics_batch(self, request_id: int) -> None:
        req_id = int(request_id)
        pending = self._pending_physics_d20.get(req_id)
        if not pending:
            return

        expected = max(0, int(pending.get("expected_total", 0)))
        values = [int(v) for v in (pending.get("values") or [])]
        landed = len(values)

        batch = self._active_d20_physics_batch
        if batch and int(batch.get("request_id", 0)) == req_id:
            batch["landed_total"] = landed

        self._debug(f"d20-physics progress request_id={req_id} landed={landed}/{expected}")
        if landed < expected:
            return

        self._cancel_d20_fallback_timer(req_id)
        self._pending_physics_d20.pop(req_id, None)
        batch = self._active_d20_physics_batch
        if batch and int(batch.get("request_id", 0)) == req_id:
            self._active_d20_physics_batch = None

        result = self._build_d20_physics_result(
            values,
            int(pending.get("count", 0)),
            str(pending.get("mode", "normal")),
            int(pending.get("bonus", 0)),
        )
        self._event_bus.publish(
            "dice.roll_completed",
            {
                "request_id": req_id,
                "kind": "d20",
                "mode": "physics",
                "requested_mode": "physics",
                "result": result,
            },
        )

    @Slot(int, "QVariantList")
    def submit_physics_d6_batch_result(self, request_id: int, values: list[Any]) -> None:
        self.submit_physics_standard_batch_result(request_id, 6, values)

    @Slot(int, int, "QVariantList")
    def submit_physics_standard_batch_result(self, request_id: int, sides: int, values: list[Any]) -> None:
        req_id = int(request_id)
        s = int(sides)
        if req_id <= 0:
            self._debug(f"submit_physics_standard_batch_result ignored invalid request_id={request_id}")
            return
        if s not in {4, 6, 8, 10, 12}:
            self._debug(f"submit_physics_standard_batch_result unsupported sides={s}")
            return

        parsed_values: list[int] = []
        max_side = 12 if s == 12 else (10 if s == 10 else (8 if s == 8 else (6 if s == 6 else 4)))
        for item in (values or []):
            try:
                value = int(item)
            except (TypeError, ValueError):
                continue
            if value > 0:
                parsed_values.append(max(1, min(max_side, value)))

        if len(parsed_values) <= 0:
            self._debug(f"submit_physics_standard_batch_result request_id={req_id} sides={s} got empty values")
            return

        pending = self._pending_physics_standard.get(req_id)
        if not pending:
            self._debug(f"submit_physics_standard_batch_result request_id={req_id} sides={s} has no pending batch")
            return

        expected_by_sides = dict(pending.get("expected_by_sides") or {})
        values_by_sides = dict(pending.get("values_by_sides") or {})
        expected = max(0, int(expected_by_sides.get(s, 0)))
        current_values = list(values_by_sides.get(s) or [])
        current_values.extend(parsed_values)
        if len(current_values) > expected:
            current_values = current_values[:expected]
        values_by_sides[s] = current_values
        pending["values_by_sides"] = values_by_sides

        self._debug(
            f"submit_physics_standard_batch_result request_id={req_id} sides={s} expected={expected} landed={len(current_values)} values={current_values}"
        )

        self._try_finalize_standard_physics_batch(req_id)

    @Slot(int, "QVariantList")
    def submit_physics_d20_batch_result(self, request_id: int, values: list[Any]) -> None:
        req_id = int(request_id)
        if req_id <= 0:
            self._debug(f"submit_physics_d20_batch_result ignored invalid request_id={request_id}")
            return

        pending = self._pending_physics_d20.get(req_id)
        if not pending:
            self._debug(f"submit_physics_d20_batch_result request_id={req_id} has no pending d20")
            return

        parsed_values: list[int] = []
        for item in (values or []):
            try:
                value = int(item)
            except (TypeError, ValueError):
                continue
            if value > 0:
                parsed_values.append(max(1, min(20, value)))

        if len(parsed_values) <= 0:
            self._debug(f"submit_physics_d20_batch_result request_id={req_id} got empty values")
            return

        expected = max(0, int(pending.get("expected_total", 0)))
        current_values = list(pending.get("values") or [])
        current_values.extend(parsed_values)
        if len(current_values) > expected:
            current_values = current_values[:expected]
        pending["values"] = current_values
        self._debug(
            f"submit_physics_d20_batch_result request_id={req_id} expected={expected} landed={len(current_values)} values={current_values}"
        )
        self._try_finalize_d20_physics_batch(req_id)

    @Slot(int, int)
    def submit_physics_d6_result(self, request_id: int, value: int) -> None:
        self.submit_physics_standard_batch_result(request_id, 6, [int(value)])

    @Slot(int, int, int)
    def submit_physics_d100_result(self, request_id: int, tens_value: int, ones_value: int) -> None:
        req_id = int(request_id)
        if req_id <= 0:
            self._debug(f"submit_physics_d100_result ignored invalid request_id={request_id}")
            return

        pending = self._pending_physics_d100.get(req_id)
        if not pending:
            self._debug(f"submit_physics_d100_result request_id={req_id} has no pending d100")
            return

        tens = max(0, min(90, int(tens_value)))
        ones = max(0, min(9, int(ones_value)))
        if tens % 10 != 0:
            tens = int(round(tens / 10.0) * 10)
            tens = max(0, min(90, tens))

        self._cancel_d100_fallback_timer(req_id)
        self._pending_physics_d100.pop(req_id, None)

        total = 100 if (tens == 0 and ones == 0) else (tens + ones)
        result = {
            "active": True,
            "kind": "d100",
            "formula": "d100",
            "total": int(total),
            "roll": int(total),
            "tens": int(tens),
            "ones": int(ones),
        }
        self._debug(
            f"submit_physics_d100_result request_id={req_id} tens={tens} ones={ones} total={total}"
        )
        self._event_bus.publish(
            "dice.roll_completed",
            {
                "request_id": req_id,
                "kind": "d100",
                "mode": "physics",
                "requested_mode": "physics",
                "result": result,
            },
        )

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
        batch = self._active_standard_physics_batch
        if batch and int(batch.get("expected_total", 0)) > int(batch.get("landed_total", 0)):
            self._debug(
                f"clear visuals ignored request_id={int(batch.get('request_id', 0))} "
                f"landed={int(batch.get('landed_total', 0))}/{int(batch.get('expected_total', 0))}"
            )
            return False
        if len(self._pending_physics_d100) > 0:
            self._debug("clear visuals ignored while d100 physics roll is pending")
            return False
        if len(self._pending_physics_d20) > 0:
            self._debug("clear visuals ignored while d20 physics roll is pending")
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
        self._debug(
            f"roll_requested kind={kind} request_id={request_id} requested_mode={requested_mode} payload={req_payload}"
        )
        completed_mode = requested_mode

        # d100 remains exclusive. d20 and standard can run/append independently.
        if kind == "d100":
            self._cancel_all_pending_standard_physics("new_d100_request")
            self._cancel_all_pending_d20_physics("new_d100_request")
        elif kind == "d20":
            self._cancel_all_pending_d100_physics("new_d20_request")
        elif kind == "standard":
            self._cancel_all_pending_d100_physics("new_standard_request")
        else:
            self._cancel_all_pending_d100_physics(f"new_{kind or 'unknown'}_request")
            self._cancel_all_pending_d20_physics(f"new_{kind or 'unknown'}_request")

        visual_dice = self._build_visual_dice_list(kind, req_payload)

        if kind == "d100" and request_id > 0:
            self._pending_physics_d100[request_id] = {"request_id": request_id}
            self._start_physics_d100_fallback_timer(request_id)
            self._debug(f"d100 physics request_id={request_id} awaiting tens+ones")
            self._event_bus.publish(
                "dice.visual_roll_requested",
                {
                    "request_id": request_id,
                    "kind": "d100",
                    "dice": [10, 10],
                    "requested_mode": requested_mode,
                    "append": False,
                },
            )
            return

        if kind == "d20" and request_id > 0:
            count = self._effective_count(int(req_payload.get("count", 0)))
            mode = str(req_payload.get("mode", "normal"))
            bonus = max(-20, min(20, int(req_payload.get("bonus", 0))))
            master_request_id, append, pending = self._register_or_extend_d20_physics_batch(
                request_id,
                count,
                mode,
                bonus,
            )
            multiplier = 2 if str(pending.get("mode", "normal")) in {"advantage", "disadvantage"} else 1
            add_total = count * multiplier
            self._debug(
                f"d20 physics batch request_id={master_request_id} append={append} "
                f"count={int(pending.get('count', 0))} mode={str(pending.get('mode', 'normal'))} "
                f"expected_total={int(pending.get('expected_total', 0))} add={add_total}"
            )
            self._event_bus.publish(
                "dice.visual_roll_requested",
                {
                    "request_id": master_request_id,
                    "kind": "d20",
                    "dice": [20] * add_total,
                    "requested_mode": requested_mode,
                    "append": append,
                },
            )
            return

        if kind == "standard" and request_id > 0:
            d4_count = max(0, int(req_payload.get("d4", 0)))
            d6_count = max(0, int(req_payload.get("d6", 0)))
            d8_count = max(0, int(req_payload.get("d8", 0)))
            d10_count = max(0, int(req_payload.get("d10", 0)))
            d12_count = max(0, int(req_payload.get("d12", 0)))
            bonus = int(req_payload.get("bonus", 0))
            if self._is_supported_standard_physics_request(kind, req_payload, visual_dice) and (d4_count + d6_count + d8_count + d10_count + d12_count) > 0:
                master_request_id, append, pending = self._register_or_extend_standard_physics_batch(
                    request_id,
                    d4_count,
                    d6_count,
                    d8_count,
                    d10_count,
                    d12_count,
                    bonus,
                )
                self._debug(
                    f"standard physics batch request_id={master_request_id} append={append} "
                    f"expected_total={int(pending.get('expected_total', 0))} "
                    f"d4={int((pending.get('expected_by_sides') or {}).get(4, 0))} "
                    f"d6={int((pending.get('expected_by_sides') or {}).get(6, 0))} "
                    f"d8={int((pending.get('expected_by_sides') or {}).get(8, 0))} "
                    f"d10={int((pending.get('expected_by_sides') or {}).get(10, 0))} "
                    f"d12={int((pending.get('expected_by_sides') or {}).get(12, 0))}"
                )
                self._event_bus.publish(
                    "dice.visual_roll_requested",
                    {
                        "request_id": master_request_id,
                        "kind": "standard",
                        "dice": [4] * d4_count + [6] * d6_count + [8] * d8_count + [10] * d10_count + [12] * d12_count,
                        "requested_mode": requested_mode,
                        "append": append,
                    },
                )
                return

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

        if requested_mode == "physics" and kind not in {"standard", "d100", "d20"}:
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


























