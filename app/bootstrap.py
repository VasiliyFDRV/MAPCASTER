from __future__ import annotations

import os
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickWindow, QSGRendererInterface
from PySide6.QtQml import QQmlApplicationEngine

from app.core.app_controller import AppController
from app.core.event_bus import EventBus
from app.core.dice_controller import DiceController
from app.core.window_manager import WindowManager
from app.services.adventure_service import AdventureService
from app.services.dice_service import DiceService
from app.services.media_service import MediaService
from app.services.settings_service import SettingsService
from app.storage.filesystem_repo import FilesystemRepository


def _run_3d_probe(resource_root: Path) -> int:
    app = QGuiApplication([])
    probe_path = resource_root / "app" / "ui" / "qml" / "ThreeDProbe.qml"
    engine = QQmlApplicationEngine()
    engine.load(QUrl.fromLocalFile(str(probe_path)))
    if not engine.rootObjects():
        print(f"[3d-probe] failed to load: {probe_path}")
        return 1
    api = QQuickWindow.graphicsApi()
    print(f"[3d-probe] requestedApi={os.getenv('MAPCASTER_GFX_API','opengl')} actualApi={api}")
    return app.exec()


def _run_web_dice_probe(resource_root: Path) -> int:
    app = QGuiApplication([])
    probe_path = resource_root / "app" / "ui" / "qml" / "WebDiceProbe.qml"
    engine = QQmlApplicationEngine()
    engine.load(QUrl.fromLocalFile(str(probe_path)))
    if not engine.rootObjects():
        print(f"[web-dice-probe] failed to load: {probe_path}")
        return 1
    print("[web-dice-probe] started")
    return app.exec()


def _resolve_runtime_paths() -> tuple[Path, Path]:
    """Return (resource_root, data_root)."""
    if getattr(sys, "frozen", False):
        resource_root = Path(getattr(sys, "_MEIPASS", Path(sys.executable).resolve().parent))
        data_root = Path(sys.executable).resolve().parent
        return resource_root, data_root

    project_root = Path(__file__).resolve().parent.parent
    return project_root, project_root


def run() -> int:
    api_name = os.getenv("MAPCASTER_GFX_API", "opengl").strip().lower()
    api_map = {
        "opengl": QSGRendererInterface.GraphicsApi.OpenGL,
        "d3d11": QSGRendererInterface.GraphicsApi.Direct3D11,
        "d3d12": QSGRendererInterface.GraphicsApi.Direct3D12,
        "software": QSGRendererInterface.GraphicsApi.Software,
    }
    chosen_api = api_map.get(api_name, QSGRendererInterface.GraphicsApi.OpenGL)
    QQuickWindow.setGraphicsApi(chosen_api)
    resource_root, data_root = _resolve_runtime_paths()

    if os.getenv("MAPCASTER_3D_PROBE", "0") == "1":
        return _run_3d_probe(resource_root)
    if os.getenv("MAPCASTER_WEB_DICE_PROBE", "0") == "1":
        return _run_web_dice_probe(resource_root)

    app = QGuiApplication([])
    print(f"[bootstrap] requestedApi={api_name} actualApi={QQuickWindow.graphicsApi()}")
    settings_path = data_root / "app_data" / "settings.json"

    event_bus = EventBus()
    settings_service = SettingsService(settings_path=settings_path, project_root=data_root)
    settings = settings_service.load()
    repository = FilesystemRepository(adventures_root=Path(settings["adventures_root"]))
    adventure_service = AdventureService(repository=repository)
    media_service = MediaService(project_root=data_root)
    dice_service = DiceService()
    dice_controller = DiceController(dice_service=dice_service, event_bus=event_bus)

    controller = AppController(
        settings_service=settings_service,
        event_bus=event_bus,
        adventure_service=adventure_service,
        media_service=media_service,
    )

    window_manager = WindowManager(
        qml_root=resource_root / "app" / "ui" / "qml",
        app_controller=controller,
        dice_controller=dice_controller,
        event_bus=event_bus,
    )
    window_manager.create_windows()

    app.aboutToQuit.connect(controller.shutdown)
    return app.exec()
