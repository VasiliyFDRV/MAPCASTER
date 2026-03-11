from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtQml import QQmlApplicationEngine, QQmlComponent

from app.core.app_controller import AppController
from app.core.event_bus import EventBus


class WindowManager:
    def __init__(self, qml_root: Path, app_controller: AppController, event_bus: EventBus) -> None:
        self._qml_root = qml_root
        self._event_bus = event_bus
        self._engine = QQmlApplicationEngine()
        self._engine.rootContext().setContextProperty("appController", app_controller)
        self._engine.rootContext().setContextProperty("eventBus", event_bus)
        self._windows: dict[str, object] = {}

        self._event_bus.subscribe("scene.open_requested", self._on_scene_open_requested)
        self._event_bus.subscribe("scene.saved", self._on_scene_saved)

    def create_windows(self) -> None:
        self._windows["launcher"] = self._create_window("LauncherWindow.qml")
        self._windows["map"] = self._create_window("MapWindow.qml")
        self._windows["background"] = self._create_window("BackgroundWindow.qml")

    def _create_window(self, qml_name: str) -> object:
        qml_path = self._qml_root / qml_name
        component = QQmlComponent(self._engine, QUrl.fromLocalFile(str(qml_path)))
        errors = component.errors()
        if errors:
            message = "\n".join(err.toString() for err in errors)
            raise RuntimeError(f"Failed to load {qml_name}:\n{message}")

        window = component.create(self._engine.rootContext())
        if window is None:
            raise RuntimeError(f"Failed to create window object for {qml_name}")

        if hasattr(window, "show"):
            window.show()
        return window

    def _on_scene_open_requested(self, event_name: str, payload: dict[str, object]) -> None:
        adventure = str(payload.get("adventure", "")).strip()
        scene = str(payload.get("scene", "")).strip()
        if not adventure or not scene:
            return
        self._set_window_title("launcher", f"DnD Maps - Лаунчер - {adventure}")
        self._set_window_title("map", f"DnD Maps - Карта - {adventure}/{scene}")
        self._set_window_title("background", f"DnD Maps - Фон - {adventure}/{scene}")

    def _on_scene_saved(self, event_name: str, payload: dict[str, object]) -> None:
        adventure = str(payload.get("adventure", "")).strip()
        scene = str(payload.get("scene", "")).strip()
        if not adventure or not scene:
            return
        self._set_window_title("map", f"DnD Maps - Карта - {adventure}/{scene} [сохранено]")

    def _set_window_title(self, key: str, title: str) -> None:
        window = self._windows.get(key)
        if window is None:
            return
        if hasattr(window, "setProperty"):
            try:
                window.setProperty("title", title)
            except RuntimeError:
                # Window was closed by user and underlying C++ object is already destroyed.
                self._windows[key] = None
