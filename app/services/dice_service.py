from __future__ import annotations

import random
from typing import Any


class DiceService:
    """Pure dice rolling logic isolated from UI and windows."""

    @staticmethod
    def _clamp_int(value: int, min_value: int, max_value: int) -> int:
        return max(min_value, min(max_value, int(value)))

    @staticmethod
    def _bonus_suffix(bonus: int) -> str:
        if bonus > 0:
            return f" + {bonus}"
        if bonus < 0:
            return f" - {abs(bonus)}"
        return ""

    def roll_d20(self, count: int, mode: str, bonus: int) -> dict[str, Any]:
        count = self._clamp_int(count, 0, 20)
        bonus = self._clamp_int(bonus, -20, 20)
        mode = mode if mode in {"normal", "advantage", "disadvantage"} else "normal"

        if count <= 0:
            return {
                "active": False,
                "kind": "d20",
                "formula": "",
                "total": 0,
                "bonus": bonus,
                "rolls": [],
                "mode": mode,
            }

        rolls: list[dict[str, Any]] = []
        total_raw = 0
        for _ in range(count):
            if mode == "normal":
                value = random.randint(1, 20)
                total_raw += value
                rolls.append({"type": "single", "value": value})
            else:
                first = random.randint(1, 20)
                second = random.randint(1, 20)
                if mode == "advantage":
                    picked = max(first, second)
                else:
                    picked = min(first, second)
                total_raw += picked
                rolls.append(
                    {
                        "type": "pair",
                        "first": first,
                        "second": second,
                        "picked": picked,
                    }
                )

        if count == 1:
            base = "d20"
        else:
            base = f"{count}d20"
        if mode == "advantage":
            base += "(преимущество)"
        elif mode == "disadvantage":
            base += "(помеха)"

        return {
            "active": True,
            "kind": "d20",
            "formula": f"{base}{self._bonus_suffix(bonus)}",
            "total": total_raw + bonus,
            "bonus": bonus,
            "rolls": rolls,
            "mode": mode,
            "raw_total": total_raw,
        }

    def roll_standard(
        self,
        d4: int,
        d6: int,
        d8: int,
        d10: int,
        d12: int,
        bonus: int,
    ) -> dict[str, Any]:
        counts = {
            4: self._clamp_int(d4, 0, 20),
            6: self._clamp_int(d6, 0, 20),
            8: self._clamp_int(d8, 0, 20),
            10: self._clamp_int(d10, 0, 20),
            12: self._clamp_int(d12, 0, 20),
        }
        bonus = self._clamp_int(bonus, -20, 20)

        if sum(counts.values()) <= 0:
            return {
                "active": False,
                "kind": "standard",
                "formula": "",
                "total": 0,
                "bonus": bonus,
                "rolls": [],
            }

        terms: list[str] = []
        rolls: list[dict[str, int]] = []
        total_raw = 0
        for sides in (4, 6, 8, 10, 12):
            count = counts[sides]
            if count <= 0:
                continue
            if count == 1:
                terms.append(f"d{sides}")
            else:
                terms.append(f"{count}d{sides}")
            for _ in range(count):
                value = random.randint(1, sides)
                total_raw += value
                rolls.append({"sides": sides, "value": value})

        formula = " + ".join(terms)
        if bonus > 0:
            formula += f" + {bonus}"
        elif bonus < 0:
            formula += f" - {abs(bonus)}"

        return {
            "active": True,
            "kind": "standard",
            "formula": formula,
            "total": total_raw + bonus,
            "bonus": bonus,
            "rolls": rolls,
            "raw_total": total_raw,
        }

    def roll_d100(self) -> dict[str, Any]:
        value = random.randint(1, 100)
        return {
            "active": True,
            "kind": "d100",
            "formula": "d100",
            "total": value,
            "roll": value,
        }

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
        return {
            "d20": self.roll_d20(d20_count, d20_mode, d20_bonus),
            "standard": self.roll_standard(d4, d6, d8, d10, d12, standard_bonus),
        }
