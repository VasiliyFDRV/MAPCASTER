from __future__ import annotations

from pathlib import Path
from typing import Any


def build_default_settings(project_root: Path) -> dict[str, Any]:
    adventures_root = project_root / "adventures"
    return {
        "adventures_root": str(adventures_root),
        "default_scene": {
            "map": {
                "type": "color",
                "value": "#2E2E2E",
                "autoplay": True,
                "loop": True,
                "mute": True,
            },
            "background": {
                "type": "color",
                "value": "#1F1F1F",
                "autoplay": True,
                "loop": True,
                "mute": True,
            },
            "grid": {
                "cell_size_ft": 5.0,
                "line_thickness_px": 1.5,
                "opacity": 0.45,
                "color": "#9DA6B0",
            },
        },
        "ui": {
            "left_panel_width": 260,
            "left_reveal_zone": 300,
        },
        "tools": {
            "brush_size_ft_min": 1.0 / 6.0,
            "brush_size_ft_max": 25.0,
        },
        "undo": {
            "max_steps": 50,
        },
        "hotkeys": {
            "pen": "P",
            "eraser": "E",
            "fill": "F",
            "hex_select": "H",
            "measure": "M",
            "undo": "Ctrl+Z",
            "fullscreen": "F11",
            "next_scene": "PageDown",
            "previous_scene": "PageUp",
            "save_scene": "Ctrl+S",
        },
        "dice_styles": {},
    }
