# DnD MAPS (Stage 9)

Каркас приложения с тремя окнами:
- Launcher
- Map
- Background

Реализовано на этапе 8:
- запуск 3 окон при старте;
- базовая загрузка/сохранение настроек (`app_data/settings.json`);
- EventBus для маршрутизации событий;
- кнопка ручного сохранения в карте (через событие `scene.save_requested`);
- панель настроек в Launcher (default map/background/grid + root path);
- применение default map/background (color/image/video) в окнах карты и фона;
- базовый рендер hex grid в окне карты по параметрам из настроек;
- файловый CRUD приключений/сцен и хранение `scene_order` в `adventure.json`;
- Launcher: списки приключений/сцен, создание, удаление, перемещение сцен вверх/вниз.
- форма создания/редактирования сцены (Dialog) с параметрами map/background/grid;
- импорт map/background в форме через file picker, drag&drop и paste;
- загрузка сцены в окна карты/фона без создания новых окон (`open_scene`);
- сохранение `scene.json` из формы с копированием локальных медиа в папку сцены.
- переключение `Prev/Next` в окне карты по `scene_order`;
- горячие клавиши `PageUp/PageDown` для навигации и `Ctrl+S` для ручного сохранения сцены;
- автосохранение открытой сцены при переключении на другую сцену и при закрытии приложения.
- навигация в карте переведена на event bus (`request_next_scene/request_previous_scene`);
- добавлена кнопка `Back` (по ТЗ = undo) и `Ctrl+Z` как команда undo;
- WindowManager синхронизирует заголовки окон на `scene.open_requested` и `scene.saved`.
- базовый runtime-слой рисования пером в окне карты;
- undo/back реально откатывают последние штрихи пера;
- ручка сохраняется в данных сцены (`draw_strokes`) и восстанавливается при открытии сцены.
- добавлен базовый инструмент выбора гексов с сохранением групп (`hex_groups`);
- добавлен инструмент измерения центр->центр с подсветкой старт/финиш гекса и отображением дистанции в футах;
- undo/back теперь откатывают действия пера и групп гексов в рамках текущей сцены.

## Запуск

1. Установить зависимости:
```powershell
python -m pip install -e .
```

2. Запустить:
```powershell
python -m app.main
```

## EXE Deployment (Windows)

- Build script: build_exe.bat
- Portable ZIP script: build_portable_zip.bat
- Detailed guide: docs/DEPLOY_EXE.md
