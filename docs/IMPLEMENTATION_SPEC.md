# DnD MAPS - Уточненное ТЗ и план реализации

## 1) Продуктовая цель
Десктоп-приложение-помощник мастера DnD для удобной работы с картой сцены и отдельным фоновым экраном во время игры.

Приложение работает одновременно с тремя окнами:
- Launcher (управление приключениями и сценами).
- Map Window (карта + сетка + инструменты).
- Background Window (фон для игроков).

## 2) Подтвержденные решения
- Основа на Python: да.
- Платформа: только Windows.
- Хранилище по умолчанию: папка проекта, путь можно менять в настройках.
- Форматы в MVP: базовые (изображения/видео), расширение позже.
- Видео: всегда mute, autoplay, loop.
- Измерение расстояния: центр гекса -> центр гекса, с подсветкой начального и конечного гекса.
- Размер кистей: слайдер от 1/6 ft до 25 ft.
- Undo: только в текущей сцене, лимит 50 шагов.
- Сохранение: вручную кнопкой Save + автоматически при закрытии сцены/открытии новой.
- Recovery после аварийного закрытия: не требуется.
- Выделение клеток: несколько цветовых групп одновременно, наложение цветов допускается, у каждой группы свой контур.
- Скрытая панель инструментов: только слева, появляется при наведении в левую reveal-зону.
- Кнопка Back в карте: только undo.
- Горячие клавиши: нужны.
- Дефолтная сцена при старте: не пустая; источники карты/фона и параметры сетки задаются в настройках.
- Порядок сцен: настраиваемый в Launcher; Next/Previous в Map Window идут по этому порядку.

## 3) Технологический стек
- Python 3.12
- PySide6 (Qt6) + QML (Qt Quick Controls)
- Qt Multimedia (воспроизведение видео)
- NumPy (операции по маскам/слоям)
- Pillow (обработка изображений, при необходимости)
- JSON/orjson (настройки и метаданные сцен)
- PyInstaller (сборка .exe и ярлык запуска)

## 4) Архитектура
UI (QML) -> Application Services (Python) -> Domain Models -> Storage/Filesystem

Ключевые модули:
- `core`: bootstrap, event bus, window manager, app controller.
- `domain`: модели сцены, настройки сетки, дефолтные значения.
- `services`: settings, adventure/scene lifecycle, tools/undo.
- `storage`: файловый репозиторий и сериализация.
- `ui/qml`: 3 окна и компоненты интерфейса.

Map Window (целевая послойная схема):
1. Map media layer (image/video)
2. Hex grid layer
3. Draw layer (pen/fill/eraser)
4. Hex selection layer (группы + контуры)
5. Measure overlay
6. UI overlay (левая скрытая панель)

## 5) Формат данных (план)
- `app_data/settings.json`:
  - `adventures_root`
  - `default_scene.map` (color/image/video)
  - `default_scene.background` (color/image/video)
  - `default_scene.grid` (size/thickness/color/opacity)
  - `ui.left_panel_width`, `ui.left_reveal_zone`
  - hotkeys
- `adventures/<adventure>/adventure.json`:
  - название, метаданные, `scene_order`
- `adventures/<adventure>/<scene>/scene.json`:
  - map/bg media
  - grid settings
  - draw/selection data
  - scene metadata

## 6) План реализации
1. Каркас проекта, запуск 3 окон, event bus, settings load/save.  
2. Settings UI + default scene/default grid.  
3. CRUD приключений и сцен + файловая структура.  
4. Launcher UI: списки, создание/редактирование, импорт медиа (picker/drag&drop/paste).  
5. Переупорядочивание сцен и интеграция Next/Previous по `scene_order`.  
6. Переиспользование окон при смене сцены (без создания новых).  
7. Рендер карты + гекс-сетка.  
8. Инструменты рисования (cursor/pen/fill/eraser/clear).  
9. Hex selection groups + measure center-to-center.  
10. Левая скрытая панель, hotkeys, undo(50), Save button.  
11. Политика сохранения: ручное + при switch/close scene.  
12. Сборка .exe, ярлык, базовая документация.

## 7) Этап 1 (текущий)
Цель этапа:
- Подготовить рабочий каркас проекта.
- Запускать 3 окна сразу.
- Загрузить/сохранить настройки.
- Проложить event routing через EventBus.

Критерии готовности этапа:
- Приложение стартует без падений.
- Видны Launcher, Map и Background окна.
- Дефолтные цвета карты/фона берутся из `settings.json`.
- Кнопка Save в карте публикует событие и вызывает сохранение настроек.

## 8) Прогресс реализации
- Этап 1: выполнен.
- Этап 2: выполнен (добавлены настройки default scene/default grid и применение в окнах).
- Этап 3: выполнен (CRUD приключений/сцен, scene_order, базовый Launcher-менеджмент списков).
- Этап 4: выполнен (форма создания/редактирования сцены, импорт медиа в форме, загрузка сцены в map/background окна).
- Этап 5: выполнен (next/previous сцены по `scene_order` в Map Window, автосохранение при switch/close, dirty-state флаг сцены).
- Этап 6: выполнен (event-driven навигация сцены, Back=Undo команда в панели карты, синхронизация заголовков окон через WindowManager).
- Этап 7: выполнен (базовое рисование пером в Map Window, undo/back по штрихам, сохранение/восстановление `draw_strokes` в сцене).
- Этап 8: выполнен (базовый hex-select с сохранением групп, измерение центр->центр в футах, undo для пера и гексов).
- Stage 9: completed (basic Fill/Eraser, clear all visual layers, undo for pen/hex/fill).
