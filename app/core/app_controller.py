from __future__ import annotations

import copy
from datetime import datetime, timezone
import json
import math
from pathlib import Path
from typing import Any

from PySide6.QtCore import QObject, Property, Signal, Slot

from app.core.event_bus import EventBus
from app.services.adventure_service import AdventureService
from app.services.media_service import MediaService
from app.services.settings_service import SettingsService


class AppController(QObject):
    settings_changed = Signal()
    settingsChanged = Signal()
    status_changed = Signal()
    library_changed = Signal()
    libraryChanged = Signal()
    scene_view_changed = Signal()
    sceneViewChanged = Signal()

    def __init__(
        self,
        settings_service: SettingsService,
        event_bus: EventBus,
        adventure_service: AdventureService,
        media_service: MediaService,
    ) -> None:
        super().__init__()
        self._settings_service = settings_service
        self._event_bus = event_bus
        self._adventure_service = adventure_service
        self._media_service = media_service
        self._settings = self._settings_service.load()
        self._status_message = "Готово"

        self._adventures: list[str] = []
        self._scenes: list[str] = []
        self._current_adventure = ""

        self._active_scene_name = ""
        self._active_scene_adventure = ""
        self._active_scene_data: dict[str, Any] | None = None
        self._active_scene_dir: Path | None = None
        self._scene_dirty = False
        self._undo_stack: list[dict[str, Any]] = []
        self._visual_revision = 0
        self._default_runtime_scene = self._build_default_runtime_scene()

        self._adventure_service.set_root(Path(self.adventuresRoot))
        self.refresh_library()
        self._event_bus.subscribe("*", self._on_event)

    @Property(str, notify=settings_changed)
    def mapFillColor(self) -> str:
        if self.mapMediaType == "color":
            return str(self._settings["default_scene"]["map"].get("value", "#2E2E2E"))
        return "#2E2E2E"

    @Property(str, notify=settings_changed)
    def mapMediaType(self) -> str:
        return str(self._settings["default_scene"]["map"].get("type", "color"))

    @Property(str, notify=settings_changed)
    def mapMediaValue(self) -> str:
        return str(self._settings["default_scene"]["map"].get("value", "#2E2E2E"))

    @Property(str, notify=settings_changed)
    def mapMediaSource(self) -> str:
        return self._to_local_file_url(self.mapMediaValue)

    @Property(bool, notify=settings_changed)
    def mapMediaAutoplay(self) -> bool:
        return bool(self._settings["default_scene"]["map"].get("autoplay", True))

    @Property(bool, notify=settings_changed)
    def mapMediaLoop(self) -> bool:
        return bool(self._settings["default_scene"]["map"].get("loop", True))

    @Property(bool, notify=settings_changed)
    def mapMediaMute(self) -> bool:
        return bool(self._settings["default_scene"]["map"].get("mute", True))

    @Property(str, notify=settings_changed)
    def backgroundFillColor(self) -> str:
        if self.backgroundMediaType == "color":
            return str(self._settings["default_scene"]["background"].get("value", "#1F1F1F"))
        return "#1F1F1F"

    @Property(str, notify=settings_changed)
    def backgroundMediaType(self) -> str:
        return str(self._settings["default_scene"]["background"].get("type", "color"))

    @Property(str, notify=settings_changed)
    def backgroundMediaValue(self) -> str:
        return str(self._settings["default_scene"]["background"].get("value", "#1F1F1F"))

    @Property(str, notify=settings_changed)
    def backgroundMediaSource(self) -> str:
        return self._to_local_file_url(self.backgroundMediaValue)

    @Property(bool, notify=settings_changed)
    def backgroundMediaAutoplay(self) -> bool:
        return bool(self._settings["default_scene"]["background"].get("autoplay", True))

    @Property(bool, notify=settings_changed)
    def backgroundMediaLoop(self) -> bool:
        return bool(self._settings["default_scene"]["background"].get("loop", True))

    @Property(bool, notify=settings_changed)
    def backgroundMediaMute(self) -> bool:
        return bool(self._settings["default_scene"]["background"].get("mute", True))

    @Property(float, notify=settings_changed)
    def gridCellSizeFt(self) -> float:
        return float(self._settings["default_scene"]["grid"].get("cell_size_ft", 5.0))

    @Property(float, notify=settings_changed)
    def gridLineThicknessPx(self) -> float:
        return float(self._settings["default_scene"]["grid"].get("line_thickness_px", 1.5))

    @Property(float, notify=settings_changed)
    def gridOpacity(self) -> float:
        return float(self._settings["default_scene"]["grid"].get("opacity", 0.45))

    @Property(str, notify=settings_changed)
    def gridColor(self) -> str:
        return str(self._settings["default_scene"]["grid"].get("color", "#9DA6B0"))

    @Property(str, notify=scene_view_changed)
    def activeMapMediaType(self) -> str:
        return str(self._scene_source()["map"].get("type", "color"))

    @Property(str, notify=scene_view_changed)
    def activeMapFillColor(self) -> str:
        if self.activeMapMediaType == "color":
            return str(self._scene_source()["map"].get("value", "#2E2E2E"))
        return "#2E2E2E"

    @Property(str, notify=scene_view_changed)
    def activeMapMediaSource(self) -> str:
        media = self._scene_source()["map"]
        return self._to_local_file_url(
            self._media_service.absolute_media_source(
                self._active_scene_dir,
                str(media.get("value", "")),
            )
        )

    @Property(bool, notify=scene_view_changed)
    def activeMapMediaAutoplay(self) -> bool:
        return bool(self._scene_source()["map"].get("autoplay", True))

    @Property(bool, notify=scene_view_changed)
    def activeMapMediaLoop(self) -> bool:
        return bool(self._scene_source()["map"].get("loop", True))

    @Property(bool, notify=scene_view_changed)
    def activeMapMediaMute(self) -> bool:
        return bool(self._scene_source()["map"].get("mute", True))

    @Property(str, notify=scene_view_changed)
    def activeBackgroundMediaType(self) -> str:
        return str(self._scene_source()["background"].get("type", "color"))

    @Property(str, notify=scene_view_changed)
    def activeBackgroundFillColor(self) -> str:
        if self.activeBackgroundMediaType == "color":
            return str(self._scene_source()["background"].get("value", "#1F1F1F"))
        return "#1F1F1F"

    @Property(str, notify=scene_view_changed)
    def activeBackgroundMediaSource(self) -> str:
        media = self._scene_source()["background"]
        return self._to_local_file_url(
            self._media_service.absolute_media_source(
                self._active_scene_dir,
                str(media.get("value", "")),
            )
        )

    @Property(bool, notify=scene_view_changed)
    def activeBackgroundMediaAutoplay(self) -> bool:
        return bool(self._scene_source()["background"].get("autoplay", True))

    @Property(bool, notify=scene_view_changed)
    def activeBackgroundMediaLoop(self) -> bool:
        return bool(self._scene_source()["background"].get("loop", True))

    @Property(bool, notify=scene_view_changed)
    def activeBackgroundMediaMute(self) -> bool:
        return bool(self._scene_source()["background"].get("mute", True))

    @Property(float, notify=scene_view_changed)
    def activeGridCellSizeFt(self) -> float:
        return float(self._scene_source()["grid"].get("cell_size_ft", 5.0))

    @Property(float, notify=scene_view_changed)
    def activeGridLineThicknessPx(self) -> float:
        return float(self._scene_source()["grid"].get("line_thickness_px", 1.5))

    @Property(float, notify=scene_view_changed)
    def activeGridOpacity(self) -> float:
        return float(self._scene_source()["grid"].get("opacity", 0.45))

    @Property(str, notify=scene_view_changed)
    def activeGridColor(self) -> str:
        return str(self._scene_source()["grid"].get("color", "#9DA6B0"))

    @Property(str, notify=settings_changed)
    def adventuresRoot(self) -> str:
        return str(self._settings.get("adventures_root", ""))

    @Property(int, notify=settings_changed)
    def leftPanelWidth(self) -> int:
        return int(self._settings["ui"].get("left_panel_width", 260))

    @Property(int, notify=settings_changed)
    def leftRevealZone(self) -> int:
        return int(self._settings["ui"].get("left_reveal_zone", 300))

    @Property("QVariantMap", notify=settings_changed)
    def diceStyles(self) -> dict[str, Any]:
        return copy.deepcopy(self._dice_styles_ref())
    @Property(str, notify=status_changed)
    def statusMessage(self) -> str:
        return self._status_message

    @Property("QVariantList", notify=library_changed)
    def adventuresModel(self) -> list[dict[str, str]]:
        return [{"name": name} for name in self._adventures]

    @Property("QVariantList", notify=library_changed)
    def scenesModel(self) -> list[dict[str, str]]:
        return [{"name": name} for name in self._scenes]

    @Property(str, notify=library_changed)
    def currentAdventure(self) -> str:
        return self._current_adventure

    @Property(str, notify=scene_view_changed)
    def currentScene(self) -> str:
        return self._active_scene_name

    @Property(bool, notify=scene_view_changed)
    def activeSceneDirty(self) -> bool:
        return self._scene_dirty

    @Property(bool, notify=scene_view_changed)
    def canOpenPreviousScene(self) -> bool:
        position = self._active_scene_position()
        return position > 0

    @Property(bool, notify=scene_view_changed)
    def canOpenNextScene(self) -> bool:
        order = self._active_scene_order()
        position = self._active_scene_position()
        return position >= 0 and position < len(order) - 1

    @Property(bool, notify=scene_view_changed)
    def canUndoSceneAction(self) -> bool:
        return len(self._undo_stack) > 0

    @Property(str, notify=scene_view_changed)
    def activeDrawStrokesJson(self) -> str:
        return json.dumps(self._draw_strokes_ref(), ensure_ascii=False)

    @Property(str, notify=scene_view_changed)
    def activeHexGroupsJson(self) -> str:
        return json.dumps(self._hex_groups_ref(), ensure_ascii=False)

    @Property(str, notify=scene_view_changed)
    def activeFillLayersJson(self) -> str:
        return json.dumps(self._fill_layers_ref(), ensure_ascii=False)

    @Property(str, notify=scene_view_changed)
    def activeEraseStrokesJson(self) -> str:
        return json.dumps(self._erase_strokes_ref(), ensure_ascii=False)

    @Property(int, notify=scene_view_changed)
    def visualRevision(self) -> int:
        return int(self._visual_revision)

    @Slot()
    def request_manual_save(self) -> None:
        self._event_bus.publish("scene.save_requested", {"source": "map_window"})

    @Slot()
    def request_open_dice(self) -> None:
        self._event_bus.publish("dice.open_requested", {"source": "launcher_window"})

    @Slot()
    def request_next_scene(self) -> None:
        self._event_bus.publish("scene.navigate_next_requested", {"source": "map_window"})

    @Slot()
    def request_previous_scene(self) -> None:
        self._event_bus.publish("scene.navigate_previous_requested", {"source": "map_window"})

    @Slot()
    def request_undo(self) -> None:
        self._event_bus.publish("scene.undo_requested", {"source": "map_window"})

    @Slot()
    def request_back(self) -> None:
        # Product decision: Back is mapped to undo in map window.
        self._event_bus.publish("scene.back_requested", {"source": "map_window"})

    @Slot()
    def request_app_exit(self) -> None:
        self._event_bus.publish("app.exit_requested", {"source": "launcher_window"})

    @Slot()
    def mark_scene_dirty(self) -> None:
        if self._active_scene_data is None:
            return
        if not self._scene_dirty:
            self._scene_dirty = True
            self._emit_scene_view_changed()

    @Slot(str, str, float, float)
    def add_draw_stroke(self, points_json: str, color: str, size_ft: float, opacity: float) -> None:
        try:
            points_raw = json.loads(points_json)
        except json.JSONDecodeError:
            return
        if not isinstance(points_raw, list):
            return
        points: list[dict[str, float]] = []
        for point in points_raw:
            if not isinstance(point, dict):
                continue
            x = self._safe_float(point.get("x"), 0.0)
            y = self._safe_float(point.get("y"), 0.0)
            points.append({"x": x, "y": y})
        if len(points) < 2:
            return

        stroke = {
            "op_id": self._next_visual_operation_id(),
            "color": color.strip() or "#F4D35E",
            "size_ft": max(1.0 / 6.0, self._safe_float(size_ft, 5.0)),
            "opacity": min(1.0, max(0.05, self._safe_float(opacity, 1.0))),
            "points": points,
        }
        self._draw_strokes_ref().append(stroke)
        self._mark_scene_dirty_if_active()
        self._push_undo_action({"type": "add_stroke"})
        self._emit_scene_view_changed()

    @Slot()
    def clear_draw_strokes(self) -> None:
        strokes = self._draw_strokes_ref()
        if not strokes:
            return
        snapshot = copy.deepcopy(strokes)
        strokes.clear()
        self._mark_scene_dirty_if_active()
        self._push_undo_action({"type": "clear_strokes", "strokes": snapshot})
        self._emit_scene_view_changed()

    @Slot(str, str, float, float)
    def add_hex_group(
        self,
        cells_json: str,
        color: str,
        fill_opacity: float,
        outline_opacity: float,
    ) -> None:
        try:
            cells_raw = json.loads(cells_json)
        except json.JSONDecodeError:
            return
        if not isinstance(cells_raw, list):
            return

        unique: dict[str, dict[str, int]] = {}
        for cell in cells_raw:
            if not isinstance(cell, dict):
                continue
            q = self._safe_int(cell.get("q"), 0)
            r = self._safe_int(cell.get("r"), 0)
            unique[f"{q},{r}"] = {"q": q, "r": r}
        if not unique:
            return

        snapshot = self._snapshot_visual_state()
        group = {
            "op_id": self._next_visual_operation_id(),
            "color": color.strip() or "#58C4DD",
            "fill_opacity": min(1.0, max(0.05, self._safe_float(fill_opacity, 0.35))),
            "outline_opacity": min(1.0, max(0.05, self._safe_float(outline_opacity, 0.8))),
            "cells": list(unique.values()),
        }
        self._replace_hex_cells(group)
        self._mark_scene_dirty_if_active()
        self._push_undo_action({"type": "snapshot", "state": snapshot})
        self._emit_scene_view_changed()

    @Slot()
    def clear_hex_groups(self) -> None:
        groups = self._hex_groups_ref()
        if not groups:
            return
        snapshot = copy.deepcopy(groups)
        groups.clear()
        self._mark_scene_dirty_if_active()
        self._push_undo_action({"type": "clear_hex_groups", "groups": snapshot})
        self._emit_scene_view_changed()

    @Slot(str, float, str)
    @Slot(str, float, str, str)
    def add_fill_layer(
        self,
        color: str,
        opacity: float,
        mode: str = "screen",
        points_json: str = "[]",
    ) -> None:
        normalized_mode = mode.strip().lower() or "screen"
        if normalized_mode not in {"screen", "polygon", "mask"}:
            normalized_mode = "screen"
        layer = {
            "op_id": self._next_visual_operation_id(),
            "color": color.strip() or "#263238",
            "opacity": min(1.0, max(0.05, self._safe_float(opacity, 0.35))),
            "mode": normalized_mode,
        }
        if normalized_mode == "polygon":
            polygon = self._parse_polygon_points(points_json)
            if len(polygon) < 3:
                normalized_mode = "screen"
                layer["mode"] = "screen"
            else:
                layer["points"] = polygon
        elif normalized_mode == "mask":
            mask_payload = self._parse_mask_payload(points_json)
            if not mask_payload:
                normalized_mode = "screen"
                layer["mode"] = "screen"
            else:
                layer.update(mask_payload)
        self._fill_layers_ref().append(layer)
        self._mark_scene_dirty_if_active()
        self._push_undo_action({"type": "add_fill_layer"})
        self._emit_scene_view_changed()

    @Slot()
    def clear_fill_layers(self) -> None:
        layers = self._fill_layers_ref()
        if not layers:
            return
        snapshot = copy.deepcopy(layers)
        layers.clear()
        self._mark_scene_dirty_if_active()
        self._push_undo_action({"type": "clear_fill_layers", "layers": snapshot})
        self._emit_scene_view_changed()

    @Slot()
    def clear_all_visual_layers(self) -> None:
        if (
            not self._draw_strokes_ref()
            and not self._hex_groups_ref()
            and not self._fill_layers_ref()
            and not self._erase_strokes_ref()
        ):
            return
        snapshot = self._snapshot_visual_state()
        self._draw_strokes_ref().clear()
        self._hex_groups_ref().clear()
        self._fill_layers_ref().clear()
        self._erase_strokes_ref().clear()
        self._mark_scene_dirty_if_active()
        self._push_undo_action({"type": "snapshot", "state": snapshot})
        self._emit_scene_view_changed()

    @Slot(str, float, float)
    def erase_with_path(self, points_json: str, radius_px: float, softness: float) -> None:
        try:
            raw = json.loads(points_json)
        except json.JSONDecodeError:
            return
        if not isinstance(raw, list) or not raw:
            return

        path: list[dict[str, float]] = []
        for point in raw:
            if not isinstance(point, dict):
                continue
            path.append(
                {
                    "x": self._safe_float(point.get("x"), 0.0),
                    "y": self._safe_float(point.get("y"), 0.0),
                }
            )
        if not path:
            return

        radius_value = max(1.0, self._safe_float(radius_px, 12.0))
        snapshot = self._snapshot_visual_state()

        stroke = {
            "op_id": self._next_visual_operation_id(),
            "points": path,
            "radius_px": radius_value,
            "softness": min(1.0, max(0.0, self._safe_float(softness, 0.5))),
        }
        self._erase_strokes_ref().append(stroke)
        softness_value = min(1.0, max(0.0, self._safe_float(softness, 0.5)))
        hex_radius = max(1.0, radius_value * (1.0 - softness_value))
        self._erase_hex_cells_by_path(path, hex_radius)
        self._mark_scene_dirty_if_active()
        self._push_undo_action({"type": "snapshot", "state": snapshot})
        self._emit_scene_view_changed()

    @Slot()
    def refresh_library(self) -> None:
        self._adventures = self._adventure_service.list_adventures()
        if self._current_adventure not in self._adventures:
            self._current_adventure = self._adventures[0] if self._adventures else ""
        self._refresh_scenes()
        self._emit_library_changed()

    @Slot(str)
    def select_adventure(self, name: str) -> None:
        selected = name.strip()
        if not selected:
            return
        if selected not in self._adventures:
            self._set_status(f"Приключение '{selected}' не найдено.")
            return
        self._current_adventure = selected
        self._refresh_scenes()
        self._emit_library_changed()

    @Slot(str)
    def create_adventure(self, name: str) -> None:
        try:
            created = self._adventure_service.create_adventure(name)
        except ValueError as exc:
            self._set_status(str(exc))
            return
        self._adventures = self._adventure_service.list_adventures()
        self._current_adventure = created
        self._refresh_scenes()
        self._set_status(f"Приключение '{created}' создано.")
        self._emit_library_changed()

    @Slot(str)
    def delete_adventure(self, name: str) -> None:
        try:
            self._adventure_service.delete_adventure(name)
        except ValueError as exc:
            self._set_status(str(exc))
            return

        deleted = name.strip()
        self._adventures = self._adventure_service.list_adventures()
        if deleted == self._current_adventure:
            self._current_adventure = self._adventures[0] if self._adventures else ""
            self._refresh_scenes()
        if deleted == self._active_scene_adventure:
            self._clear_active_scene()
        self._set_status(f"Приключение '{deleted}' удалено.")
        self._emit_library_changed()


    @Slot(str, str)
    def rename_adventure(self, name: str, new_name: str) -> None:
        old_name = name.strip()
        try:
            renamed = self._adventure_service.rename_adventure(old_name, new_name)
        except ValueError as exc:
            self._set_status(str(exc))
            return
        self._adventures = self._adventure_service.list_adventures()
        if self._current_adventure == old_name:
            self._current_adventure = renamed
            self._refresh_scenes()
        if self._active_scene_adventure == old_name:
            self._active_scene_adventure = renamed
        self._set_status(f"Приключение '{old_name}' переименовано в '{renamed}'.")
        self._emit_library_changed()

    @Slot(str)
    def create_scene(self, scene_name: str) -> None:
        if not self._current_adventure:
            self._set_status("Сначала выберите приключение.")
            return
        try:
            created = self._adventure_service.create_scene(
                self._current_adventure,
                scene_name,
                self._settings["default_scene"],
            )
        except ValueError as exc:
            self._set_status(str(exc))
            return
        self._refresh_scenes()
        self._set_status(f"Сцена '{created}' создана.")
        self._emit_library_changed()

    @Slot(str)
    def delete_scene(self, scene_name: str) -> None:
        if not self._current_adventure:
            self._set_status("Сначала выберите приключение.")
            return
        try:
            self._adventure_service.delete_scene(self._current_adventure, scene_name)
        except ValueError as exc:
            self._set_status(str(exc))
            return
        if (
            self._active_scene_adventure == self._current_adventure
            and self._active_scene_name == scene_name.strip()
        ):
            self._clear_active_scene()
        deleted = scene_name.strip()
        self._refresh_scenes()
        self._set_status(f"Сцена '{deleted}' удалена.")
        self._emit_library_changed()

    @Slot(str, int)
    def move_scene(self, scene_name: str, direction: int) -> None:
        if not self._current_adventure:
            self._set_status("Сначала выберите приключение.")
            return
        try:
            self._adventure_service.move_scene(
                self._current_adventure,
                scene_name,
                self._safe_int(direction, 0),
            )
        except ValueError as exc:
            self._set_status(str(exc))
            return
        self._refresh_scenes()
        self._emit_library_changed()

    @Slot(str)
    def open_scene(self, scene_name: str) -> None:
        if not self._current_adventure:
            self._set_status("Сначала выберите приключение.")
            return
        selected = scene_name.strip()
        if selected not in self._scenes:
            self._set_status(f"Сцена '{selected}' не найдена.")
            return
        try:
            self._open_scene_internal(self._current_adventure, selected)
        except ValueError as exc:
            self._set_status(str(exc))

    @Slot()
    def open_next_scene(self) -> None:
        order = self._active_scene_order()
        position = self._active_scene_position()
        if position < 0 or position >= len(order) - 1:
            return
        try:
            self._open_scene_internal(self._active_scene_adventure, order[position + 1])
        except ValueError as exc:
            self._set_status(str(exc))

    @Slot()
    def open_previous_scene(self) -> None:
        order = self._active_scene_order()
        position = self._active_scene_position()
        if position <= 0:
            return
        try:
            self._open_scene_internal(self._active_scene_adventure, order[position - 1])
        except ValueError as exc:
            self._set_status(str(exc))

    @Slot(result="QVariantMap")
    def build_new_scene_draft(self) -> dict[str, Any]:
        default_scene = self._settings["default_scene"]
        return {
            "mode": "create",
            "name": "",
            "original_name": "",
            "map": dict(default_scene["map"]),
            "background": dict(default_scene["background"]),
            "grid": dict(default_scene["grid"]),
        }

    @Slot(str, result="QVariantMap")
    def load_scene_draft(self, scene_name: str) -> dict[str, Any]:
        if not self._current_adventure:
            self._set_status("Сначала выберите приключение.")
            return {}
        selected = scene_name.strip()
        if not selected:
            return {}
        try:
            scene_data = self._adventure_service.load_scene(self._current_adventure, selected)
            scene_dir = self._adventure_service.scene_path(self._current_adventure, selected)
        except ValueError as exc:
            self._set_status(str(exc))
            return {}

        draft = {
            "mode": "edit",
            "name": selected,
            "original_name": selected,
            "map": self._draft_media(scene_dir, scene_data.get("map", {}), "map"),
            "background": self._draft_media(scene_dir, scene_data.get("background", {}), "background"),
            "grid": self._normalize_grid(scene_data.get("grid", {}), self._settings["default_scene"]["grid"]),
        }
        return draft

    @Slot(str, result=str)
    def paste_media_value(self, target: str) -> str:
        value = self._media_service.stage_media_from_clipboard(target)
        if not value:
            self._set_status("В буфере нет пути, URL или изображения.")
        return value

    @Slot("QVariantMap", result=bool)
    def save_scene_draft(self, draft: dict[str, Any]) -> bool:
        if not self._current_adventure:
            self._set_status("Select an adventure first.")
            return False

        mode = str(draft.get("mode", "create")).strip().lower()
        scene_name = str(draft.get("name", "")).strip()
        original_name = str(draft.get("original_name", scene_name)).strip()
        if not scene_name:
            self._set_status("Scene name cannot be empty.")
            return False

        payload = self._normalize_scene_payload(draft)
        renamed_active_scene = False
        try:
            if mode == "create":
                target_name = self._adventure_service.create_scene(
                    self._current_adventure,
                    scene_name,
                    payload,
                )
            else:
                if not original_name:
                    self._set_status("Cannot determine original scene name.")
                    return False
                target_name = original_name
                if scene_name != original_name:
                    # On Windows the active scene directory may be locked by media playback.
                    if (
                        self._active_scene_adventure == self._current_adventure
                        and self._active_scene_name == original_name
                    ):
                        self._save_active_scene_if_needed(force=True)
                        self._clear_active_scene()
                        renamed_active_scene = True
                    target_name = self._adventure_service.rename_scene(
                        self._current_adventure,
                        original_name,
                        scene_name,
                    )

            scene_dir = self._adventure_service.scene_path(self._current_adventure, target_name)
            existing = self._adventure_service.load_scene(self._current_adventure, target_name)
            validation_error = self._validate_scene_media_payload(scene_dir, payload)
            if validation_error:
                if renamed_active_scene and original_name:
                    try:
                        self._open_scene_internal(self._current_adventure, original_name)
                    except ValueError:
                        pass
                self._set_status(validation_error)
                return False
            final_payload = self._prepare_scene_payload_for_storage(scene_dir, payload, existing)
            self._adventure_service.save_scene(self._current_adventure, target_name, final_payload)
        except (ValueError, OSError) as exc:
            if renamed_active_scene and original_name:
                try:
                    self._open_scene_internal(self._current_adventure, original_name)
                except ValueError:
                    pass
            self._set_status(str(exc))
            return False

        self._refresh_scenes()
        self._emit_library_changed()
        self._set_status(f"Scene '{target_name}' saved.")

        if (
            self._active_scene_adventure == self._current_adventure
            and self._active_scene_name in {original_name, target_name}
        ):
            try:
                self.open_scene(target_name)
            except Exception as exc:
                self._set_status(str(exc))
                return False
        return True

    @Slot(str)
    def update_adventures_root(self, value: str) -> None:
        root = value.strip()
        if not root:
            self._set_status("Путь к приключениям не может быть пустым.")
            return
        self._save_active_scene_if_needed(force=True)
        self._settings["adventures_root"] = root
        self._adventure_service.set_root(Path(root))
        self._clear_active_scene()
        self.refresh_library()
        self._emit_settings_changed()

    @Slot(str, str, str)
    def update_media(self, target: str, media_type: str, value: str) -> None:
        key = self._target_key(target)
        if key is None:
            return
        media = self._settings["default_scene"][key]
        normalized_type = media_type.strip().lower()
        if normalized_type not in {"color", "image", "video"}:
            normalized_type = "color"
        media["type"] = normalized_type
        media["value"] = value.strip()
        self._emit_settings_changed()
        if self._active_scene_data is None:
            self._default_runtime_scene[key] = dict(media)
            self._emit_scene_view_changed()

    @Slot(str, bool, bool, bool)
    def update_playback(self, target: str, autoplay: bool, loop: bool, mute: bool) -> None:
        key = self._target_key(target)
        if key is None:
            return
        media = self._settings["default_scene"][key]
        media["autoplay"] = bool(autoplay)
        media["loop"] = bool(loop)
        media["mute"] = bool(mute)
        self._emit_settings_changed()
        if self._active_scene_data is None:
            self._default_runtime_scene[key] = dict(media)
            self._emit_scene_view_changed()

    @Slot(float, float, float, str)
    def update_grid(self, cell_size_ft: float, line_thickness_px: float, opacity: float, color: str) -> None:
        grid = self._settings["default_scene"]["grid"]
        grid["cell_size_ft"] = max(0.1, self._safe_float(cell_size_ft, 5.0))
        grid["line_thickness_px"] = min(10.0, max(0.2, self._safe_float(line_thickness_px, 1.5)))
        grid["opacity"] = min(1.0, max(0.0, self._safe_float(opacity, 0.45)))
        grid["color"] = color.strip() or "#9DA6B0"
        self._emit_settings_changed()
        if self._active_scene_data is None:
            self._default_runtime_scene["grid"] = dict(grid)
            self._emit_scene_view_changed()

    @Slot(int, int)
    def update_panel(self, panel_width: int, reveal_zone: int) -> None:
        width = max(160, self._safe_int(panel_width, 260))
        reveal = max(width + 20, self._safe_int(reveal_zone, width + 40))
        self._settings["ui"]["left_panel_width"] = width
        self._settings["ui"]["left_reveal_zone"] = reveal
        self._emit_settings_changed()

    @Slot(str, "QVariantMap")
    def update_dice_style(self, die_key: str, style: dict[str, Any]) -> None:
        key = str(die_key or "").strip().lower()
        if key not in {"d4", "d6", "d8", "d10", "d12", "d20", "d100"}:
            return

        incoming = dict(style or {})
        styles = self._dice_styles_ref()
        styles[key] = copy.deepcopy(incoming)
        self._settings_service.save(self._settings)
        self._emit_settings_changed()
    @Slot()
    def persist_settings(self) -> None:
        self._settings_service.save(self._settings)
        self._set_status("Настройки сохранены")

    @Slot()
    def shutdown(self) -> None:
        self._save_active_scene_if_needed(force=True)
        self._settings_service.save(self._settings)

    def _on_event(self, event_name: str, payload: dict[str, Any]) -> None:
        if event_name == "scene.save_requested":
            if self._save_active_scene_if_needed(force=True):
                self._set_status(f"Сцена '{self._active_scene_name}' сохранена.")
                return
            now = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d %H:%M:%S")
            self._set_status(f"Ручное сохранение запрошено в {now}")
            return

        if event_name == "scene.navigate_next_requested":
            self.open_next_scene()
            return

        if event_name == "scene.navigate_previous_requested":
            self.open_previous_scene()
            return

        if event_name in {"scene.undo_requested", "scene.back_requested"}:
            if self._undo_last_scene_action():
                self._set_status("Отмена выполнена.")
            else:
                self._set_status("Нечего отменять.")

    def _save_active_scene_if_needed(self, force: bool = False) -> bool:
        if (
            not self._active_scene_name
            or not self._active_scene_adventure
            or self._active_scene_data is None
        ):
            return False
        if not force and not self._scene_dirty:
            return False
        try:
            self._adventure_service.save_scene(
                self._active_scene_adventure,
                self._active_scene_name,
                self._active_scene_data,
            )
        except ValueError:
            return False
        self._scene_dirty = False
        self._event_bus.publish(
            "scene.saved",
            {"adventure": self._active_scene_adventure, "scene": self._active_scene_name},
        )
        self._emit_scene_view_changed()
        return True

    def _scene_source(self) -> dict[str, Any]:
        if self._active_scene_data is not None:
            return self._active_scene_data
        return self._default_runtime_scene

    def _draw_strokes_ref(self) -> list[dict[str, Any]]:
        source = self._scene_source()
        strokes = source.get("draw_strokes")
        if not isinstance(strokes, list):
            source["draw_strokes"] = []
            strokes = source["draw_strokes"]
        return strokes

    def _hex_groups_ref(self) -> list[dict[str, Any]]:
        source = self._scene_source()
        groups = source.get("hex_groups")
        if not isinstance(groups, list):
            source["hex_groups"] = []
            groups = source["hex_groups"]
        return groups

    def _fill_layers_ref(self) -> list[dict[str, Any]]:
        source = self._scene_source()
        layers = source.get("fill_layers")
        if not isinstance(layers, list):
            source["fill_layers"] = []
            layers = source["fill_layers"]
        return layers

    def _erase_strokes_ref(self) -> list[dict[str, Any]]:
        source = self._scene_source()
        strokes = source.get("erase_strokes")
        if not isinstance(strokes, list):
            source["erase_strokes"] = []
            strokes = source["erase_strokes"]
        return strokes

    def _next_visual_operation_id(self) -> int:
        source = self._scene_source()
        next_id = self._safe_int(source.get("next_visual_op_id"), 1)
        if next_id < 1:
            next_id = 1
        source["next_visual_op_id"] = next_id + 1
        return next_id

    def _ensure_visual_operation_ids(self, scene_data: dict[str, Any]) -> None:
        collections: list[tuple[str, list[dict[str, Any]]]] = []
        for key in ["draw_strokes", "hex_groups", "fill_layers", "erase_strokes"]:
            raw = scene_data.get(key)
            items = raw if isinstance(raw, list) else []
            collections.append((key, items))

        max_seen = 0
        for _, items in collections:
            for item in items:
                if not isinstance(item, dict):
                    continue
                op_id = self._safe_int(item.get("op_id"), 0)
                if op_id < 1:
                    continue
                item["op_id"] = op_id
                if op_id > max_seen:
                    max_seen = op_id

        next_id = self._safe_int(scene_data.get("next_visual_op_id"), 1)
        if next_id < 1:
            next_id = 1
        next_id = max(next_id, max_seen + 1)

        for _, items in collections:
            for item in items:
                if not isinstance(item, dict):
                    continue
                op_id = self._safe_int(item.get("op_id"), 0)
                if op_id >= 1:
                    continue
                item["op_id"] = next_id
                next_id += 1

        scene_data["next_visual_op_id"] = next_id

    def _snapshot_visual_state(self) -> dict[str, Any]:
        return {
            "draw_strokes": copy.deepcopy(self._draw_strokes_ref()),
            "hex_groups": copy.deepcopy(self._hex_groups_ref()),
            "fill_layers": copy.deepcopy(self._fill_layers_ref()),
            "erase_strokes": copy.deepcopy(self._erase_strokes_ref()),
            "next_visual_op_id": self._safe_int(self._scene_source().get("next_visual_op_id"), 1),
        }

    def _restore_visual_state(self, state: dict[str, Any]) -> None:
        source = self._scene_source()
        source["draw_strokes"] = copy.deepcopy(state.get("draw_strokes", []))
        source["hex_groups"] = copy.deepcopy(state.get("hex_groups", []))
        source["fill_layers"] = copy.deepcopy(state.get("fill_layers", []))
        source["erase_strokes"] = copy.deepcopy(state.get("erase_strokes", []))
        source["next_visual_op_id"] = self._safe_int(state.get("next_visual_op_id"), 1)
        self._ensure_visual_operation_ids(source)

    def _push_undo_action(self, action: dict[str, Any]) -> None:
        self._undo_stack.append(action)
        max_steps = int(self._settings.get("undo", {}).get("max_steps", 50))
        if max_steps < 1:
            max_steps = 1
        if len(self._undo_stack) > max_steps:
            self._undo_stack = self._undo_stack[-max_steps:]

    def _mark_scene_dirty_if_active(self) -> None:
        if self._active_scene_data is None:
            return
        self._scene_dirty = True

    def _undo_last_scene_action(self) -> bool:
        if not self._undo_stack:
            return False
        action = self._undo_stack.pop()
        action_type = str(action.get("type", ""))

        if action_type == "add_stroke":
            strokes = self._draw_strokes_ref()
            if strokes:
                strokes.pop()
        elif action_type == "clear_strokes":
            restored = action.get("strokes", [])
            if isinstance(restored, list):
                self._scene_source()["draw_strokes"] = copy.deepcopy(restored)
        elif action_type == "add_hex_group":
            groups = self._hex_groups_ref()
            if groups:
                groups.pop()
        elif action_type == "clear_hex_groups":
            restored_groups = action.get("groups", [])
            if isinstance(restored_groups, list):
                self._scene_source()["hex_groups"] = copy.deepcopy(restored_groups)
        elif action_type == "add_fill_layer":
            layers = self._fill_layers_ref()
            if layers:
                layers.pop()
        elif action_type == "clear_fill_layers":
            restored_layers = action.get("layers", [])
            if isinstance(restored_layers, list):
                self._scene_source()["fill_layers"] = copy.deepcopy(restored_layers)
        elif action_type == "add_erase_stroke":
            strokes = self._erase_strokes_ref()
            if strokes:
                strokes.pop()
        elif action_type == "snapshot":
            state = action.get("state", {})
            if not isinstance(state, dict):
                return False
            self._restore_visual_state(state)
        else:
            return False

        self._mark_scene_dirty_if_active()
        self._emit_scene_view_changed()
        return True

    def _stroke_touches_path(
        self,
        stroke: dict[str, Any],
        path: list[dict[str, float]],
        radius: float,
    ) -> bool:
        points = stroke.get("points", [])
        if not isinstance(points, list) or not points:
            return False
        radius_sq = radius * radius
        for point in points:
            if not isinstance(point, dict):
                continue
            px = self._safe_float(point.get("x"), 0.0)
            py = self._safe_float(point.get("y"), 0.0)
            for sample in path:
                dx = px - sample["x"]
                dy = py - sample["y"]
                if dx * dx + dy * dy <= radius_sq:
                    return True
        return False

    def _cell_touches_path(
        self,
        q: int,
        r: int,
        path: list[dict[str, float]],
        radius: float,
    ) -> bool:
        center = self._axial_to_center(q, r)
        radius_sq = radius * radius
        for sample in path:
            dx = center["x"] - sample["x"]
            dy = center["y"] - sample["y"]
            if dx * dx + dy * dy <= radius_sq:
                return True
        return False

    def _erase_hex_cells_by_path(
        self,
        path: list[dict[str, float]],
        radius: float,
    ) -> bool:
        groups = self._hex_groups_ref()
        if not groups:
            return False

        changed = False
        updated_groups: list[dict[str, Any]] = []
        for group in groups:
            if not isinstance(group, dict):
                continue
            raw_cells = group.get("cells", [])
            if not isinstance(raw_cells, list) or not raw_cells:
                continue

            kept_cells: list[dict[str, int]] = []
            for cell in raw_cells:
                if not isinstance(cell, dict):
                    continue
                q = self._safe_int(cell.get("q"), 0)
                r = self._safe_int(cell.get("r"), 0)
                if self._cell_touches_path(q, r, path, radius):
                    changed = True
                    continue
                kept_cells.append({"q": q, "r": r})

            if kept_cells:
                if len(kept_cells) != len(raw_cells):
                    changed = True
                    group_copy = dict(group)
                    group_copy["cells"] = kept_cells
                    updated_groups.append(group_copy)
                else:
                    updated_groups.append(group)
            elif raw_cells:
                changed = True

        if changed:
            source = self._scene_source()
            source["hex_groups"] = updated_groups
        return changed

    def _replace_hex_cells(self, group: dict[str, Any]) -> None:
        groups = self._hex_groups_ref()
        replacement_cells_raw = group.get("cells", [])
        if not isinstance(replacement_cells_raw, list) or not replacement_cells_raw:
            return

        replacement_lookup: dict[str, bool] = {}
        replacement_cells: list[dict[str, int]] = []
        for cell in replacement_cells_raw:
            if not isinstance(cell, dict):
                continue
            q = self._safe_int(cell.get("q"), 0)
            r = self._safe_int(cell.get("r"), 0)
            key = f"{q},{r}"
            if key in replacement_lookup:
                continue
            replacement_lookup[key] = True
            replacement_cells.append({"q": q, "r": r})

        if not replacement_cells:
            return

        updated_groups: list[dict[str, Any]] = []
        for existing in groups:
            if not isinstance(existing, dict):
                continue
            raw_cells = existing.get("cells", [])
            if not isinstance(raw_cells, list) or not raw_cells:
                continue

            kept_cells: list[dict[str, int]] = []
            for cell in raw_cells:
                if not isinstance(cell, dict):
                    continue
                q = self._safe_int(cell.get("q"), 0)
                r = self._safe_int(cell.get("r"), 0)
                if f"{q},{r}" in replacement_lookup:
                    continue
                kept_cells.append({"q": q, "r": r})

            if kept_cells:
                group_copy = dict(existing)
                group_copy["cells"] = kept_cells
                updated_groups.append(group_copy)

        group_copy = dict(group)
        group_copy["cells"] = replacement_cells
        updated_groups.append(group_copy)
        self._scene_source()["hex_groups"] = updated_groups

    def _fill_layer_touches_path(
        self,
        layer: dict[str, Any],
        path: list[dict[str, float]],
        radius: float,
    ) -> bool:
        mode = str(layer.get("mode", "screen")).strip().lower()
        if mode == "mask":
            return self._mask_touches_path(layer, path, radius)
        if mode != "polygon":
            return bool(path)

        raw_points = layer.get("points", [])
        if not isinstance(raw_points, list) or len(raw_points) < 3:
            return bool(path)

        polygon: list[dict[str, float]] = []
        for point in raw_points:
            if not isinstance(point, dict):
                continue
            polygon.append(
                {
                    "x": self._safe_float(point.get("x"), 0.0),
                    "y": self._safe_float(point.get("y"), 0.0),
                }
            )
        if len(polygon) < 3:
            return bool(path)

        for sample in path:
            sx = sample["x"]
            sy = sample["y"]
            if self._point_inside_polygon(sx, sy, polygon):
                return True
            if self._distance_to_polygon_edges(sx, sy, polygon) <= radius:
                return True
        return False

    def _mask_touches_path(
        self,
        layer: dict[str, Any],
        path: list[dict[str, float]],
        radius: float,
    ) -> bool:
        runs_raw = layer.get("runs", [])
        if not isinstance(runs_raw, list) or not runs_raw:
            return bool(path)

        cell_px = max(1.0, self._safe_float(layer.get("cell_px"), 6.0))
        rows: dict[int, list[tuple[int, int]]] = {}
        for run in runs_raw:
            if not isinstance(run, dict):
                continue
            row = self._safe_int(run.get("y"), -1)
            x0 = self._safe_int(run.get("x0"), -1)
            x1 = self._safe_int(run.get("x1"), -1)
            if row < 0 or x0 < 0 or x1 < x0:
                continue
            rows.setdefault(row, []).append((x0, x1))

        if not rows:
            return bool(path)

        for sample in path:
            sx = self._safe_float(sample.get("x"), 0.0)
            sy = self._safe_float(sample.get("y"), 0.0)
            row_min = math.floor((sy - radius) / cell_px)
            row_max = math.floor((sy + radius) / cell_px)
            for row in range(row_min, row_max + 1):
                segments = rows.get(row)
                if not segments:
                    continue
                rect_top = row * cell_px
                rect_bottom = (row + 1) * cell_px
                for x0, x1 in segments:
                    rect_left = x0 * cell_px
                    rect_right = (x1 + 1) * cell_px
                    if self._distance_point_to_rect(
                        sx,
                        sy,
                        rect_left,
                        rect_top,
                        rect_right,
                        rect_bottom,
                    ) <= radius:
                        return True
        return False

    def _parse_polygon_points(self, points_json: str) -> list[dict[str, float]]:
        try:
            raw = json.loads(points_json)
        except json.JSONDecodeError:
            return []
        if not isinstance(raw, list):
            return []

        points: list[dict[str, float]] = []
        for point in raw:
            if not isinstance(point, dict):
                continue
            points.append(
                {
                    "x": self._safe_float(point.get("x"), 0.0),
                    "y": self._safe_float(point.get("y"), 0.0),
                }
            )
        return points

    def _parse_mask_payload(self, points_json: str) -> dict[str, Any] | None:
        try:
            raw = json.loads(points_json)
        except json.JSONDecodeError:
            return None
        if not isinstance(raw, dict):
            return None

        cell_px = max(1.0, self._safe_float(raw.get("cell_px"), 6.0))
        runs_raw = raw.get("runs", [])
        if not isinstance(runs_raw, list):
            return None

        runs: list[dict[str, int]] = []
        for run in runs_raw:
            if not isinstance(run, dict):
                continue
            row = self._safe_int(run.get("y"), -1)
            x0 = self._safe_int(run.get("x0"), -1)
            x1 = self._safe_int(run.get("x1"), -1)
            if row < 0 or x0 < 0 or x1 < x0:
                continue
            runs.append({"y": row, "x0": x0, "x1": x1})
            if len(runs) >= 50000:
                break

        if not runs:
            return None
        return {"cell_px": cell_px, "runs": runs}

    def _point_inside_polygon(
        self,
        x: float,
        y: float,
        polygon: list[dict[str, float]],
    ) -> bool:
        if len(polygon) < 3:
            return False
        inside = False
        j = len(polygon) - 1
        for i in range(len(polygon)):
            xi = polygon[i]["x"]
            yi = polygon[i]["y"]
            xj = polygon[j]["x"]
            yj = polygon[j]["y"]

            intersects = (yi > y) != (yj > y)
            if intersects:
                denominator = yj - yi
                if denominator == 0:
                    denominator = 1e-9
                hit_x = (xj - xi) * (y - yi) / denominator + xi
                if x < hit_x:
                    inside = not inside
            j = i
        return inside

    def _distance_to_polygon_edges(
        self,
        x: float,
        y: float,
        polygon: list[dict[str, float]],
    ) -> float:
        if len(polygon) < 2:
            return float("inf")
        distance = float("inf")
        for idx in range(len(polygon)):
            start = polygon[idx]
            end = polygon[(idx + 1) % len(polygon)]
            segment_distance = self._distance_point_to_segment(
                x,
                y,
                start["x"],
                start["y"],
                end["x"],
                end["y"],
            )
            distance = min(distance, segment_distance)
        return distance

    def _distance_point_to_segment(
        self,
        px: float,
        py: float,
        ax: float,
        ay: float,
        bx: float,
        by: float,
    ) -> float:
        dx = bx - ax
        dy = by - ay
        if dx == 0 and dy == 0:
            return math.hypot(px - ax, py - ay)

        t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)
        t = min(1.0, max(0.0, t))
        cx = ax + t * dx
        cy = ay + t * dy
        return math.hypot(px - cx, py - cy)

    def _distance_point_to_rect(
        self,
        px: float,
        py: float,
        left: float,
        top: float,
        right: float,
        bottom: float,
    ) -> float:
        clamped_x = min(max(px, left), right)
        clamped_y = min(max(py, top), bottom)
        return math.hypot(px - clamped_x, py - clamped_y)

    def _axial_to_center(self, q: int, r: int) -> dict[str, float]:
        radius = max(8.0, self.activeGridCellSizeFt * 6.0)
        hex_width = math.sqrt(3.0) * radius
        row_step = 1.5 * radius
        row = int(r)
        col = int(q) + math.floor((row - (row & 1)) / 2)
        x_offset = (hex_width / 2.0) if (row & 1) else 0.0
        return {
            "x": -hex_width + col * hex_width + x_offset,
            "y": -radius + row * row_step,
        }

    def _target_key(self, target: str) -> str | None:
        normalized = target.strip().lower()
        if normalized in {"map", "background"}:
            return normalized
        return None

    def _to_local_file_url(self, value: str) -> str:
        candidate = value.strip()
        if not candidate:
            return ""
        if candidate.startswith(("file://", "http://", "https://", "qrc:/")):
            return candidate
        path = Path(candidate)
        if not path.is_absolute():
            path = Path.cwd() / path
        return path.resolve().as_uri()

    def _refresh_scenes(self) -> None:
        if not self._current_adventure:
            self._scenes = []
            return
        self._scenes = self._adventure_service.list_scenes(self._current_adventure)

    def _open_scene_internal(self, adventure_name: str, scene_name: str) -> None:
        if self._active_scene_name:
            switching = (
                self._active_scene_adventure != adventure_name
                or self._active_scene_name != scene_name
            )
            if switching and self._save_active_scene_if_needed():
                self._set_status(
                    f"Сцена '{self._active_scene_adventure}/{self._active_scene_name}' автосохранена."
                )

        scene_data = self._adventure_service.load_scene(adventure_name, scene_name)
        if not isinstance(scene_data.get("draw_strokes"), list):
            scene_data["draw_strokes"] = []
        if not isinstance(scene_data.get("hex_groups"), list):
            scene_data["hex_groups"] = []
        if not isinstance(scene_data.get("fill_layers"), list):
            scene_data["fill_layers"] = []
        if not isinstance(scene_data.get("erase_strokes"), list):
            scene_data["erase_strokes"] = []
        self._ensure_visual_operation_ids(scene_data)
        self._active_scene_adventure = adventure_name
        self._active_scene_name = scene_name
        self._active_scene_data = scene_data
        self._active_scene_dir = self._adventure_service.scene_path(adventure_name, scene_name)
        self._scene_dirty = False
        self._undo_stack = []

        self._current_adventure = adventure_name
        self._refresh_scenes()
        self._emit_library_changed()
        self._emit_scene_view_changed()

        self._event_bus.publish(
            "scene.open_requested",
            {"adventure": adventure_name, "scene": scene_name},
        )
        self._set_status(f"Открыта сцена: {adventure_name}/{scene_name}")

    def _active_scene_order(self) -> list[str]:
        if not self._active_scene_adventure:
            return []
        try:
            return self._adventure_service.list_scenes(self._active_scene_adventure)
        except ValueError:
            return []

    def _active_scene_position(self) -> int:
        if not self._active_scene_name:
            return -1
        order = self._active_scene_order()
        if self._active_scene_name not in order:
            return -1
        return order.index(self._active_scene_name)

    def _clear_active_scene(self) -> None:
        self._active_scene_name = ""
        self._active_scene_adventure = ""
        self._active_scene_data = None
        self._active_scene_dir = None
        self._scene_dirty = False
        self._undo_stack = []
        self._emit_scene_view_changed()

    def _draft_media(self, scene_dir: Path, media: dict[str, Any], target: str) -> dict[str, Any]:
        defaults = self._settings["default_scene"][target]
        normalized = self._normalize_media(media, defaults)
        if normalized["type"] != "color":
            normalized["value"] = self._media_service.absolute_media_source(scene_dir, normalized["value"])
        return normalized

    def _normalize_scene_payload(self, draft: dict[str, Any]) -> dict[str, Any]:
        defaults = self._settings["default_scene"]
        map_media = self._normalize_media(draft.get("map", {}), defaults["map"])
        bg_media = self._normalize_media(draft.get("background", {}), defaults["background"])
        grid = self._normalize_grid(draft.get("grid", {}), defaults["grid"])
        return {"map": map_media, "background": bg_media, "grid": grid}

    def _normalize_media(self, media: dict[str, Any], defaults: dict[str, Any]) -> dict[str, Any]:
        enabled = bool(media.get("enabled", defaults.get("enabled", True)))
        raw_type = str(media.get("type", defaults.get("type", "color"))).strip().lower()
        if raw_type not in {"color", "image", "video"}:
            raw_type = self._media_service.infer_media_type(str(media.get("value", "")), fallback="color")
        value = str(media.get("value", defaults.get("value", ""))).strip()
        if raw_type == "color" and not value:
            value = str(defaults.get("value", "#2E2E2E"))
        return {
            "enabled": enabled,
            "type": raw_type,
            "value": value,
            "autoplay": bool(media.get("autoplay", defaults.get("autoplay", True))),
            "loop": bool(media.get("loop", defaults.get("loop", True))),
            "mute": bool(media.get("mute", defaults.get("mute", True))),
        }

    def _normalize_grid(self, grid: dict[str, Any], defaults: dict[str, Any]) -> dict[str, Any]:
        return {
            "cell_size_ft": max(
                0.1,
                self._safe_float(grid.get("cell_size_ft", defaults.get("cell_size_ft", 5.0)), 5.0),
            ),
            "line_thickness_px": min(
                10.0,
                max(
                    0.2,
                    self._safe_float(grid.get("line_thickness_px", defaults.get("line_thickness_px", 1.5)), 1.5),
                ),
            ),
            "opacity": min(
                1.0,
                max(0.0, self._safe_float(grid.get("opacity", defaults.get("opacity", 0.45)), 0.45)),
            ),
            "color": str(grid.get("color", defaults.get("color", "#9DA6B0"))).strip() or "#9DA6B0",
        }

    def _prepare_scene_payload_for_storage(
        self,
        scene_dir: Path,
        payload: dict[str, Any],
        existing: dict[str, Any],
    ) -> dict[str, Any]:
        map_media = dict(payload["map"])
        bg_media = dict(payload["background"])

        map_media["value"] = self._media_service.resolve_scene_media_value(
            scene_dir,
            map_media["type"],
            map_media["value"],
            "map",
        )
        bg_media["value"] = self._media_service.resolve_scene_media_value(
            scene_dir,
            bg_media["type"],
            bg_media["value"],
            "background",
        )
        result = {
            key: value
            for key, value in existing.items()
            if key not in {"name", "map", "background", "grid", "updated_at"}
        }
        result["name"] = existing.get("name", scene_dir.name)
        result["map"] = map_media
        result["background"] = bg_media
        result["grid"] = dict(payload["grid"])
        result["created_at"] = existing.get("created_at") or datetime.now(timezone.utc).isoformat()
        return result

    def _validate_scene_media_payload(self, scene_dir: Path, payload: dict[str, Any]) -> str:
        for key, label in (("map", "карты"), ("background", "фона")):
            media = payload.get(key, {})
            if not isinstance(media, dict):
                continue
            error = self._validate_media_entry(scene_dir, media, label)
            if error:
                return error
        return ""

    def _validate_media_entry(
        self,
        scene_dir: Path,
        media: dict[str, Any],
        label: str,
    ) -> str:
        media_type = str(media.get("type", "color")).strip().lower()
        if not bool(media.get("enabled", True)):
            return ""
        value = str(media.get("value", "")).strip()
        if media_type == "color":
            return ""
        if not value:
            return f"Не указан файл для {label}."

        absolute = self._media_service.absolute_media_source(scene_dir, value)
        local_path = self._media_service.local_path_from_value(absolute)
        if local_path is None:
            return ""
        if not local_path.exists() or not local_path.is_file():
            return f"Файл для {label} не найден: {value}"

        detected = self._media_service.infer_media_type(str(local_path), fallback="")
        if media_type == "video" and detected != "video":
            return f"Для {label} выбран файл неподдерживаемого видеоформата."
        if media_type == "image" and detected != "image":
            return f"Для {label} выбран файл неподдерживаемого формата изображения."
        return ""
    def _dice_styles_ref(self) -> dict[str, Any]:
        styles = self._settings.get("dice_styles")
        if not isinstance(styles, dict):
            styles = {}
            self._settings["dice_styles"] = styles
        return styles

    def _build_default_runtime_scene(self) -> dict[str, Any]:
        defaults = self._settings["default_scene"]
        return {
            "map": dict(defaults["map"]),
            "background": dict(defaults["background"]),
            "grid": dict(defaults["grid"]),
            "draw_strokes": [],
            "hex_groups": [],
            "fill_layers": [],
            "erase_strokes": [],
            "next_visual_op_id": 1,
        }

    def _emit_settings_changed(self) -> None:
        self.settings_changed.emit()
        self.settingsChanged.emit()

    def _emit_library_changed(self) -> None:
        self.library_changed.emit()
        self.libraryChanged.emit()
        self._emit_scene_view_changed()

    def _emit_scene_view_changed(self) -> None:
        self._visual_revision += 1
        self.scene_view_changed.emit()
        self.sceneViewChanged.emit()

    def _set_status(self, message: str) -> None:
        self._status_message = message
        self.status_changed.emit()

    def _safe_float(self, value: Any, fallback: float) -> float:
        try:
            parsed = float(value)
        except (TypeError, ValueError):
            return fallback
        if math.isnan(parsed) or math.isinf(parsed):
            return fallback
        return parsed

    def _safe_int(self, value: Any, fallback: int) -> int:
        try:
            parsed = int(value)
        except (TypeError, ValueError):
            return fallback
        return parsed

