from __future__ import annotations

import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication

from app.core.app_controller import AppController
from app.core.event_bus import EventBus
from app.core.dice_controller import DiceController
from app.core.window_manager import WindowManager
from app.services.adventure_service import AdventureService
from app.services.dice_service import DiceService
from app.services.media_service import MediaService
from app.services.settings_service import SettingsService
from app.storage.filesystem_repo import FilesystemRepository


def _resolve_runtime_paths() -> tuple[Path, Path]:
    """Return (resource_root, data_root)."""
    if getattr(sys, "frozen", False):
        resource_root = Path(getattr(sys, "_MEIPASS", Path(sys.executable).resolve().parent))
        data_root = Path(sys.executable).resolve().parent
        return resource_root, data_root

    project_root = Path(__file__).resolve().parent.parent
    return project_root, project_root


def run() -> int:
    app = QGuiApplication([])
    resource_root, data_root = _resolve_runtime_paths()
    settings_path = data_root / "app_data" / "settings.json"

    event_bus = EventBus()
    settings_service = SettingsService(settings_path=settings_path, project_root=data_root)
    settings = settings_service.load()
    repository = FilesystemRepository(adventures_root=Path(settings["adventures_root"]))
    adventure_service = AdventureService(repository=repository)
    media_service = MediaService(project_root=data_root)
    dice_service = DiceService()
    dice_controller = DiceController(dice_service=dice_service)

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
