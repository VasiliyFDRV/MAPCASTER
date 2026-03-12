from __future__ import annotations

from typing import Any

from PySide6.QtCore import QObject, Slot

from app.services.dice_service import DiceService


class DiceController(QObject):
    def __init__(self, dice_service: DiceService) -> None:
        super().__init__()
        self._dice_service = dice_service

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
