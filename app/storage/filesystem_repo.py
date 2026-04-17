from __future__ import annotations

import copy
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from app.storage.serializers import read_json, write_json


INVALID_NAME_CHARS = re.compile(r'[<>:"/\\|?*]')


class FilesystemRepository:
    def __init__(self, adventures_root: Path) -> None:
        self._adventures_root = adventures_root
        self._adventure_order_file = '.launcher_order.json'

    @property
    def adventures_root(self) -> Path:
        return self._adventures_root

    def set_root(self, root: Path) -> None:
        self._adventures_root = root

    def ensure_root(self) -> None:
        self._adventures_root.mkdir(parents=True, exist_ok=True)

    def list_adventures(self) -> list[str]:
        self.ensure_root()
        adventures: list[tuple[datetime, str]] = []
        for entry in self._adventures_root.iterdir():
            if not entry.is_dir():
                continue
            payload = read_json(entry / "adventure.json", default={})
            created_raw = str(payload.get("created_at", "")).strip()
            created_at = datetime.min.replace(tzinfo=timezone.utc)
            if created_raw:
                try:
                    created_at = datetime.fromisoformat(created_raw.replace("Z", "+00:00"))
                    if created_at.tzinfo is None:
                        created_at = created_at.replace(tzinfo=timezone.utc)
                except ValueError:
                    created_at = datetime.min.replace(tzinfo=timezone.utc)
            adventures.append((created_at, entry.name))
        adventures.sort(key=lambda item: (item[0], item[1].lower()), reverse=True)
        discovered = [name for _, name in adventures]
        order = self._normalized_adventure_order(discovered)
        self._save_adventure_order(order)
        return order

    def create_adventure(self, name: str) -> str:
        safe_name = self._sanitize_name(name)
        path = self._adventures_root / safe_name
        if path.exists():
            raise ValueError(f"Приключение '{safe_name}' уже существует.")

        path.mkdir(parents=True, exist_ok=False)
        payload = {
            "name": safe_name,
            "scene_order": [],
            "created_at": self._now_iso(),
            "updated_at": self._now_iso(),
        }
        write_json(path / "adventure.json", payload)
        self._prepend_adventure_order(safe_name)
        return safe_name

    def delete_adventure(self, name: str) -> None:
        safe_name = self._sanitize_name(name)
        path = self._adventures_root / safe_name
        if not path.exists():
            raise ValueError(f"Приключение '{safe_name}' не существует.")
        shutil.rmtree(path)
        self._remove_from_adventure_order(safe_name)

    def rename_adventure(self, name: str, new_name: str) -> str:
        old_name = self._sanitize_name(name)
        target_name = self._sanitize_name(new_name)
        if old_name == target_name:
            return old_name
        order_before_rename = self.list_adventures()
        old_path = self._adventures_root / old_name
        new_path = self._adventures_root / target_name
        if not old_path.exists():
            raise ValueError(f"Adventure '{old_name}' does not exist.")
        if new_path.exists():
            raise ValueError(f"Adventure '{target_name}' already exists.")
        try:
            old_path.rename(new_path)
        except PermissionError as exc:
            raise ValueError(
                "Cannot rename adventure folder because files are in use. "
                "Close related scenes and try again."
            ) from exc
        except OSError as exc:
            raise ValueError(f"Failed to rename adventure '{old_name}' to '{target_name}': {exc}") from exc
        payload = read_json(new_path / "adventure.json", default={"name": target_name, "scene_order": []})
        payload["name"] = target_name
        write_json(new_path / "adventure.json", payload)
        order = [target_name if item == old_name else item for item in order_before_rename]
        self._save_adventure_order(order)
        return target_name

    def move_adventure(self, name: str, target_index: int) -> None:
        safe_name = self._sanitize_name(name)
        order = self.list_adventures()
        if safe_name not in order:
            raise ValueError(f"Adventure '{safe_name}' not found.")
        bounded_index = max(0, min(len(order) - 1, int(target_index)))
        current_index = order.index(safe_name)
        if current_index == bounded_index:
            return
        order.pop(current_index)
        order.insert(bounded_index, safe_name)
        self._save_adventure_order(order)

    def list_scenes(self, adventure_name: str) -> list[str]:
        adventure_path = self._adventure_path(adventure_name)
        data = self.load_adventure(adventure_name)
        disk_scenes = sorted(
            entry.name
            for entry in adventure_path.iterdir()
            if entry.is_dir()
        )

        ordered = [scene for scene in data["scene_order"] if scene in disk_scenes]
        extra = [scene for scene in disk_scenes if scene not in ordered]
        return ordered + extra

    def create_scene(self, adventure_name: str, scene_name: str, default_scene: dict[str, Any]) -> str:
        safe_adventure = self._sanitize_name(adventure_name)
        safe_scene = self._sanitize_name(scene_name)

        scene_path = self._scene_path(safe_adventure, safe_scene, must_exist=False)
        if scene_path.exists():
            raise ValueError(f"Сцена '{safe_scene}' уже существует.")

        scene_path.mkdir(parents=True, exist_ok=False)
        scene_payload = {
            "name": safe_scene,
            "map": copy.deepcopy(default_scene["map"]),
            "background": copy.deepcopy(default_scene["background"]),
            "grid": copy.deepcopy(default_scene["grid"]),
            "draw_strokes": copy.deepcopy(default_scene.get("draw_strokes", [])),
            "hex_groups": copy.deepcopy(default_scene.get("hex_groups", [])),
            "fill_layers": copy.deepcopy(default_scene.get("fill_layers", [])),
            "erase_strokes": copy.deepcopy(default_scene.get("erase_strokes", [])),
            "next_visual_op_id": max(1, int(default_scene.get("next_visual_op_id", 1))),
            "created_at": self._now_iso(),
            "updated_at": self._now_iso(),
        }
        write_json(scene_path / "scene.json", scene_payload)
        self._append_scene_order(safe_adventure, safe_scene)
        return safe_scene

    def rename_scene(self, adventure_name: str, scene_name: str, new_scene_name: str) -> str:
        safe_adventure = self._sanitize_name(adventure_name)
        old_name = self._sanitize_name(scene_name)
        new_name = self._sanitize_name(new_scene_name)
        if old_name == new_name:
            return old_name

        stored_order = list(self.load_adventure(safe_adventure).get("scene_order", []))
        old_path = self._scene_path(safe_adventure, old_name)
        new_path = self._scene_path(safe_adventure, new_name, must_exist=False)
        if new_path.exists():
            raise ValueError(f"Сцена '{new_name}' уже существует.")
        try:
            old_path.rename(new_path)
        except PermissionError as exc:
            raise ValueError(
                "Cannot rename scene folder because files are in use. "
                "Close the scene in map/background windows and try again."
            ) from exc
        except OSError as exc:
            raise ValueError(f"Failed to rename scene '{old_name}' to '{new_name}': {exc}") from exc

        scene_payload = read_json(new_path / "scene.json", default={"name": new_name})
        scene_payload["name"] = new_name
        write_json(new_path / "scene.json", scene_payload)

        if old_name in stored_order:
            order = [new_name if item == old_name else item for item in stored_order]
        else:
            order = [item for item in self.list_scenes(safe_adventure) if item != new_name]
            order.append(new_name)
        self.set_scene_order(safe_adventure, order)
        return new_name

    def delete_scene(self, adventure_name: str, scene_name: str) -> None:
        safe_adventure = self._sanitize_name(adventure_name)
        safe_scene = self._sanitize_name(scene_name)
        scene_path = self._scene_path(safe_adventure, safe_scene)
        if not scene_path.exists():
            raise ValueError(f"Сцена '{safe_scene}' не существует.")
        shutil.rmtree(scene_path)
        self._remove_from_scene_order(safe_adventure, safe_scene)

    def move_scene(self, adventure_name: str, scene_name: str, direction: int) -> None:
        safe_adventure = self._sanitize_name(adventure_name)
        safe_scene = self._sanitize_name(scene_name)

        order = self.list_scenes(safe_adventure)
        if safe_scene not in order:
            raise ValueError(f"Сцена '{safe_scene}' не найдена в приключении '{safe_adventure}'.")

        old_idx = order.index(safe_scene)
        new_idx = old_idx + direction
        if new_idx < 0 or new_idx >= len(order):
            return

        order[old_idx], order[new_idx] = order[new_idx], order[old_idx]
        self.set_scene_order(safe_adventure, order)

    def load_adventure(self, name: str) -> dict[str, Any]:
        safe_name = self._sanitize_name(name)
        path = self._adventure_path(safe_name) / "adventure.json"
        payload = read_json(path, default={"name": safe_name, "scene_order": []})
        if "name" not in payload:
            payload["name"] = safe_name
        if "scene_order" not in payload or not isinstance(payload["scene_order"], list):
            payload["scene_order"] = []
        return payload

    def save_adventure(self, name: str, payload: dict[str, Any]) -> None:
        safe_name = self._sanitize_name(name)
        data = dict(payload)
        data["name"] = safe_name
        data["updated_at"] = self._now_iso()
        write_json(self._adventure_path(safe_name) / "adventure.json", data)

    def set_scene_order(self, adventure_name: str, order: list[str]) -> None:
        safe_adventure = self._sanitize_name(adventure_name)
        data = self.load_adventure(safe_adventure)
        data["scene_order"] = [self._sanitize_name(scene) for scene in order]
        self.save_adventure(safe_adventure, data)

    def load_scene(self, adventure_name: str, scene_name: str) -> dict[str, Any]:
        safe_adventure = self._sanitize_name(adventure_name)
        safe_scene = self._sanitize_name(scene_name)
        scene_path = self._scene_path(safe_adventure, safe_scene) / "scene.json"
        payload = read_json(scene_path, default={"name": safe_scene})
        payload["name"] = safe_scene
        if "draw_strokes" not in payload or not isinstance(payload["draw_strokes"], list):
            payload["draw_strokes"] = []
        if "hex_groups" not in payload or not isinstance(payload["hex_groups"], list):
            payload["hex_groups"] = []
        if "fill_layers" not in payload or not isinstance(payload["fill_layers"], list):
            payload["fill_layers"] = []
        if "erase_strokes" not in payload or not isinstance(payload["erase_strokes"], list):
            payload["erase_strokes"] = []
        try:
            payload["next_visual_op_id"] = max(1, int(payload.get("next_visual_op_id", 1)))
        except (TypeError, ValueError):
            payload["next_visual_op_id"] = 1
        return payload

    def save_scene(self, adventure_name: str, scene_name: str, payload: dict[str, Any]) -> None:
        safe_adventure = self._sanitize_name(adventure_name)
        safe_scene = self._sanitize_name(scene_name)
        data = dict(payload)
        data["name"] = safe_scene
        data["updated_at"] = self._now_iso()
        write_json(self._scene_path(safe_adventure, safe_scene) / "scene.json", data)

    def scene_path(self, adventure_name: str, scene_name: str) -> Path:
        safe_adventure = self._sanitize_name(adventure_name)
        safe_scene = self._sanitize_name(scene_name)
        return self._scene_path(safe_adventure, safe_scene)

    def _append_scene_order(self, adventure_name: str, scene_name: str) -> None:
        data = self.load_adventure(adventure_name)
        if scene_name in data["scene_order"]:
            data["scene_order"] = [item for item in data["scene_order"] if item != scene_name]
        data["scene_order"].insert(0, scene_name)
        self.save_adventure(adventure_name, data)

    def _remove_from_scene_order(self, adventure_name: str, scene_name: str) -> None:
        data = self.load_adventure(adventure_name)
        data["scene_order"] = [item for item in data["scene_order"] if item != scene_name]
        self.save_adventure(adventure_name, data)

    def _adventure_order_path(self) -> Path:
        return self._adventures_root / self._adventure_order_file

    def _load_adventure_order(self) -> list[str]:
        payload = read_json(self._adventure_order_path(), default={"adventure_order": []})
        raw_order = payload.get("adventure_order", [])
        if not isinstance(raw_order, list):
            return []
        normalized: list[str] = []
        for item in raw_order:
            if not isinstance(item, str):
                continue
            name = item.strip()
            if name and name not in normalized:
                normalized.append(name)
        return normalized

    def _save_adventure_order(self, order: list[str]) -> None:
        normalized: list[str] = []
        for item in order:
            if not isinstance(item, str):
                continue
            name = item.strip()
            if name and name not in normalized:
                normalized.append(name)
        write_json(self._adventure_order_path(), {"adventure_order": normalized})

    def _normalized_adventure_order(self, discovered: list[str]) -> list[str]:
        known = set(discovered)
        stored = [item for item in self._load_adventure_order() if item in known]
        missing = [item for item in discovered if item not in stored]
        return stored + missing

    def _prepend_adventure_order(self, adventure_name: str) -> None:
        order = self.list_adventures()
        order = [item for item in order if item != adventure_name]
        order.insert(0, adventure_name)
        self._save_adventure_order(order)

    def _remove_from_adventure_order(self, adventure_name: str) -> None:
        order = [item for item in self.list_adventures() if item != adventure_name]
        self._save_adventure_order(order)

    def _adventure_path(self, name: str) -> Path:
        self.ensure_root()
        path = self._adventures_root / self._sanitize_name(name)
        if not path.exists():
            raise ValueError(f"Приключение '{name}' не существует.")
        return path

    def _scene_path(self, adventure_name: str, scene_name: str, must_exist: bool = True) -> Path:
        adventure_path = self._adventure_path(adventure_name)
        scene_path = adventure_path / self._sanitize_name(scene_name)
        if must_exist and not scene_path.exists():
            raise ValueError(f"Сцена '{scene_name}' не существует.")
        return scene_path

    def _sanitize_name(self, name: str) -> str:
        cleaned = INVALID_NAME_CHARS.sub("_", name.strip())
        if not cleaned:
            raise ValueError("Имя не может быть пустым.")
        if cleaned in {".", ".."}:
            raise ValueError("Некорректное имя.")
        return cleaned

    def _now_iso(self) -> str:
        return datetime.now(timezone.utc).isoformat()


