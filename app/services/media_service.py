from __future__ import annotations

import shutil
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote, urlparse

from PySide6.QtGui import QGuiApplication


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif"}
VIDEO_EXTENSIONS = {".mp4", ".webm", ".mkv", ".avi", ".mov", ".wmv", ".m4v"}


class MediaService:
    def __init__(self, project_root: Path) -> None:
        self._project_root = project_root
        self._clipboard_dir = self._project_root / "app_data" / "clipboard"

    def stage_media_from_clipboard(self, target: str) -> str:
        clipboard = QGuiApplication.clipboard()
        mime = clipboard.mimeData()
        if mime is None:
            return ""

        if mime.hasUrls():
            urls = mime.urls()
            if urls:
                return self._path_from_url(urls[0].toString())

        if mime.hasText():
            value = self.normalize_media_input(mime.text())
            return self._path_from_url(value)

        if mime.hasImage():
            image = clipboard.image()
            if image.isNull():
                return ""
            self._clipboard_dir.mkdir(parents=True, exist_ok=True)
            filename = f"{self._safe_target_name(target)}_{self._timestamp()}.png"
            path = self._clipboard_dir / filename
            if not image.save(str(path), "PNG"):
                return ""
            return str(path)

        return ""

    def resolve_scene_media_value(self, scene_dir: Path, media_type: str, value: str, target: str) -> str:
        normalized_type = media_type.strip().lower()
        raw_value = self.normalize_media_input(value)
        if normalized_type == "color":
            return raw_value
        if not raw_value:
            return ""

        parsed_url = urlparse(raw_value)
        if parsed_url.scheme in {"http", "https"}:
            return raw_value

        source = Path(self._path_from_url(raw_value))
        if not source.exists():
            return raw_value

        # If media already points to a file inside this scene folder, keep it as-is.
        try:
            existing_relative = source.resolve().relative_to(scene_dir.resolve())
            return str(existing_relative)
        except ValueError:
            pass

        assets_dir = scene_dir / "assets"
        assets_dir.mkdir(parents=True, exist_ok=True)
        extension = source.suffix.lower()
        if extension == "":
            extension = ".bin"
        destination = assets_dir / f"{self._safe_target_name(target)}_{self._timestamp()}{extension}"
        shutil.copy2(source, destination)
        return str(destination.relative_to(scene_dir))

    def absolute_media_source(self, scene_dir: Path | None, value: str) -> str:
        candidate = self.normalize_media_input(value)
        if not candidate:
            return ""
        if candidate.startswith(("http://", "https://", "qrc:/")):
            return candidate
        if candidate.startswith("file://"):
            return self._path_from_url(candidate)

        path = Path(candidate)
        if path.is_absolute():
            return str(path)
        if scene_dir is not None:
            return str((scene_dir / path).resolve())
        return str((Path.cwd() / path).resolve())

    def infer_media_type(self, value: str, fallback: str = "color") -> str:
        source = Path(self._path_from_url(self.normalize_media_input(value)))
        extension = source.suffix.lower()
        if extension in IMAGE_EXTENSIONS:
            return "image"
        if extension in VIDEO_EXTENSIONS:
            return "video"
        return fallback

    def local_path_from_value(self, value: str) -> Path | None:
        candidate = self.normalize_media_input(value)
        if not candidate or candidate.startswith(("http://", "https://", "qrc:/")):
            return None
        return Path(self._path_from_url(candidate))

    def normalize_media_input(self, value: str) -> str:
        raw = str(value or "").replace("\x00", "").strip()
        if not raw:
            return ""
        if "\n" in raw or "\r" in raw:
            for line in raw.splitlines():
                cleaned = line.strip()
                if not cleaned or cleaned.startswith("#"):
                    continue
                raw = cleaned
                break
        return raw.strip()

    def _path_from_url(self, value: str) -> str:
        raw = self.normalize_media_input(value)
        if raw.startswith("file://"):
            parsed = urlparse(raw)
            if parsed.netloc:
                netloc = unquote(parsed.netloc)
                path = unquote(parsed.path or "")
                if len(netloc) == 2 and netloc[1] == ":":
                    return f"{netloc}{path}"
                return f"//{netloc}{path}"
            path = unquote(parsed.path)
            if len(path) >= 3 and path[0] == "/" and path[2] == ":":
                return path[1:]
            return path.lstrip("/")
        return raw

    def _timestamp(self) -> str:
        return datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S%f")

    def _safe_target_name(self, target: str) -> str:
        normalized = target.strip().lower()
        if normalized not in {"map", "background"}:
            return "media"
        return normalized
