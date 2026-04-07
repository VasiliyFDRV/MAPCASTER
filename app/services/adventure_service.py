from __future__ import annotations

import copy
from pathlib import Path
from typing import Any

from app.storage.filesystem_repo import FilesystemRepository


class AdventureService:
    def __init__(self, repository: FilesystemRepository) -> None:
        self._repository = repository

    @property
    def adventures_root(self) -> Path:
        return self._repository.adventures_root

    def set_root(self, root: Path) -> None:
        self._repository.set_root(root)
        self._repository.ensure_root()

    def list_adventures(self) -> list[str]:
        return self._repository.list_adventures()

    def create_adventure(self, name: str) -> str:
        return self._repository.create_adventure(name)

    def delete_adventure(self, name: str) -> None:
        self._repository.delete_adventure(name)

    def rename_adventure(self, name: str, new_name: str) -> str:
        return self._repository.rename_adventure(name, new_name)

    def move_adventure(self, name: str, target_index: int) -> None:
        self._repository.move_adventure(name, target_index)

    def list_scenes(self, adventure_name: str) -> list[str]:
        return self._repository.list_scenes(adventure_name)

    def create_scene(self, adventure_name: str, scene_name: str, default_scene: dict[str, Any]) -> str:
        payload = copy.deepcopy(default_scene)
        return self._repository.create_scene(adventure_name, scene_name, payload)

    def rename_scene(self, adventure_name: str, scene_name: str, new_scene_name: str) -> str:
        return self._repository.rename_scene(adventure_name, scene_name, new_scene_name)

    def delete_scene(self, adventure_name: str, scene_name: str) -> None:
        self._repository.delete_scene(adventure_name, scene_name)

    def move_scene(self, adventure_name: str, scene_name: str, direction: int) -> None:
        self._repository.move_scene(adventure_name, scene_name, direction)

    def load_scene(self, adventure_name: str, scene_name: str) -> dict[str, Any]:
        return self._repository.load_scene(adventure_name, scene_name)

    def save_scene(self, adventure_name: str, scene_name: str, payload: dict[str, Any]) -> None:
        self._repository.save_scene(adventure_name, scene_name, payload)

    def scene_path(self, adventure_name: str, scene_name: str) -> Path:
        return self._repository.scene_path(adventure_name, scene_name)
