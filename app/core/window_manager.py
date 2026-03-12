from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, QQmlComponent

from app.core.app_controller import AppController
from app.core.event_bus import EventBus
from app.core.dice_controller import DiceController


class WindowManager:
    def __init__(
        self,
        qml_root: Path,
        app_controller: AppController,
        dice_controller: DiceController,
        event_bus: EventBus,
    ) -> None:
        self._qml_root = qml_root
        self._event_bus = event_bus
        self._engine = QQmlApplicationEngine()
        self._engine.quit.connect(self._on_engine_quit)
        self._engine.rootContext().setContextProperty("appController", app_controller)
        self._engine.rootContext().setContextProperty("diceController", dice_controller)
        self._engine.rootContext().setContextProperty("eventBus", event_bus)
        self._windows: dict[str, object | None] = {}
        self._launcher_closing_connected = False
        self._shutdown_in_progress = False

        self._event_bus.subscribe("scene.open_requested", self._on_scene_open_requested)
        self._event_bus.subscribe("scene.saved", self._on_scene_saved)
        self._event_bus.subscribe("dice.open_requested", self._on_dice_open_requested)
        self._event_bus.subscribe("app.exit_requested", self._on_app_exit_requested)

    def create_windows(self) -> None:
        # Launcher starts immediately; map/background are created lazily on first scene open.
        self._windows["launcher"] = self._create_window("LauncherWindow.qml")
        launcher = self._windows["launcher"]
        if launcher is not None and hasattr(launcher, "closing") and not self._launcher_closing_connected:
            launcher.closing.connect(self._on_launcher_closing)
            self._launcher_closing_connected = True
        if launcher is not None and hasattr(launcher, "visibleChanged"):
            launcher.visibleChanged.connect(self._on_launcher_visible_changed)
        if launcher is not None and hasattr(launcher, "destroyed"):
            launcher.destroyed.connect(self._on_launcher_destroyed)

        self._windows["map"] = None
        self._windows["background"] = None
        self._windows["dice"] = None

    def _ensure_window(self, key: str) -> None:
        if key == "map":
            qml_name = "MapWindow.qml"
        elif key == "background":
            qml_name = "BackgroundWindow.qml"
        elif key == "launcher":
            qml_name = "LauncherWindow.qml"
        elif key == "dice":
            qml_name = "DiceWindow.qml"
        else:
            return
        if self._windows.get(key) is None:
            self._windows[key] = self._create_window(qml_name)

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


    def _is_window_alive(self, window: object | None) -> bool:
        if window is None:
            return False
        try:
            if hasattr(window, "isVisible"):
                window.isVisible()
            return True
        except RuntimeError:
            return False

    def _open_or_recreate_window(self, key: str) -> object | None:
        window = self._windows.get(key)
        if not self._is_window_alive(window):
            self._windows[key] = None
            self._ensure_window(key)
            window = self._windows.get(key)
            if not self._is_window_alive(window):
                return None
        return window

    def _activate_window(self, window: object) -> None:
        if hasattr(window, "show"):
            window.show()
        if hasattr(window, "raise_"):
            window.raise_()
        if hasattr(window, "requestActivate"):
            window.requestActivate()

    def _on_engine_quit(self) -> None:
        app = QGuiApplication.instance()
        if app is not None:
            app.quit()

    def _on_launcher_closing(self, close_event: object) -> None:
        # User closed launcher window -> terminate full application.
        self._on_app_exit_requested("app.exit_requested", {})

    def _on_launcher_destroyed(self, _obj: object = None) -> None:
        self._on_app_exit_requested("app.exit_requested", {})

    def _on_launcher_visible_changed(self) -> None:
        launcher = self._windows.get("launcher")
        if launcher is None or not hasattr(launcher, "isVisible"):
            return
        try:
            if not bool(launcher.isVisible()):
                self._on_app_exit_requested("app.exit_requested", {})
        except RuntimeError:
            # Underlying object is already gone; continue with shutdown path.
            self._on_app_exit_requested("app.exit_requested", {})

    def _on_scene_open_requested(self, event_name: str, payload: dict[str, object]) -> None:
        adventure = str(payload.get("adventure", "")).strip()
        scene = str(payload.get("scene", "")).strip()
        if not adventure or not scene:
            return
        self._ensure_window("map")
        self._ensure_window("background")
        self._set_window_title("launcher", f"DnD Maps - Лаунчер - {adventure}")
        self._set_window_title("map", f"DnD Maps - Карта - {adventure}/{scene}")
        self._set_window_title("background", f"DnD Maps - Фон - {adventure}/{scene}")

    def _on_scene_saved(self, event_name: str, payload: dict[str, object]) -> None:
        adventure = str(payload.get("adventure", "")).strip()
        scene = str(payload.get("scene", "")).strip()
        if not adventure or not scene:
            return
        self._set_window_title("map", f"DnD Maps - Карта - {adventure}/{scene} [сохранено]")

    def _on_dice_open_requested(self, event_name: str, payload: dict[str, object]) -> None:
        window = self._open_or_recreate_window("dice")
        if window is None:
            return

        try:
            if hasattr(window, "setProperty") and hasattr(window, "property"):
                current = int(window.property("resetToken") or 0)
                window.setProperty("resetToken", current + 1)
            self._activate_window(window)
        except RuntimeError:
            self._windows["dice"] = None
            window = self._open_or_recreate_window("dice")
            if window is None:
                return
            try:
                self._activate_window(window)
            except RuntimeError:
                self._windows["dice"] = None

    def _on_app_exit_requested(self, event_name: str, payload: dict[str, object]) -> None:
        if self._shutdown_in_progress:
            return
        self._shutdown_in_progress = True

        for key in ("map", "background", "dice", "launcher"):
            window = self._windows.get(key)
            if window is None:
                continue
            if hasattr(window, "close"):
                try:
                    window.close()
                except RuntimeError:
                    pass
            self._windows[key] = None

        app = QGuiApplication.instance()
        if app is not None:
            app.quit()

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
