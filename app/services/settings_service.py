from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from app.domain.defaults import build_default_settings


class SettingsService:
    def __init__(self, settings_path: Path, project_root: Path) -> None:
        self._settings_path = settings_path
        self._project_root = project_root

    def load(self) -> dict[str, Any]:
        defaults = build_default_settings(self._project_root)
        if not self._settings_path.exists():
            self._settings_path.parent.mkdir(parents=True, exist_ok=True)
            self.save(defaults)
            return defaults

        with self._settings_path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)

        return self._merge_dicts(defaults, data)

    def save(self, settings: dict[str, Any]) -> None:
        self._settings_path.parent.mkdir(parents=True, exist_ok=True)
        with self._settings_path.open("w", encoding="utf-8") as fh:
            json.dump(settings, fh, indent=2, ensure_ascii=False)

    def _merge_dicts(self, defaults: dict[str, Any], current: dict[str, Any]) -> dict[str, Any]:
        merged = dict(defaults)
        for key, value in current.items():
            if key in merged and isinstance(merged[key], dict) and isinstance(value, dict):
                merged[key] = self._merge_dicts(merged[key], value)
                continue
            merged[key] = value
        return merged
