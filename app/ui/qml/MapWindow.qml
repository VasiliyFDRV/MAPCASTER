import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window
import QtMultimedia
import "components"

Window {
    id: mapWindow
    width: 1280
    height: 720
    visible: true
    color: "#111316"
    title: "DnD Maps - РљР°СЂС‚Р°"

    property bool panelExpanded: false
    property real panelHandleWidth: 22
    property real panelBodyWidth: 72
    property real panelRevealZoneWidth: 62
    property real viewScale: 1.0
    property real viewOffsetX: 0.0
    property real viewOffsetY: 0.0
    property bool panningView: false
    property real panStartX: 0.0
    property real panStartY: 0.0
    property real panStartOffsetX: 0.0
    property real panStartOffsetY: 0.0
    property real hexRadiusPx: Math.max(8, appController.activeGridCellSizeFt * 6)
    property color uiTextPrimary: "#ECECEF"
    property color uiTextSecondary: "#A9AAB2"
    property color uiPanel: "#23252B"
    property color uiPanelSoft: "#2B2E36"
    property color uiPanelLine: "#464B56"
    property string currentTool: "cursor"
    property bool pointerInsideMap: false
    property bool pointerOverPanelUi: false
    property real pointerX: 0
    property real pointerY: 0
    property real pointerWorldX: 0
    property real pointerWorldY: 0
    property var cursorRipples: []
    property color penColor: "#F4D35E"
    property real penSizeFt: 5.0
    property real penOpacity: 1.0
    property var strokes: []
    property var closedFillPolygons: []
    property var currentStrokePoints: []
    property var pendingCommittedStroke: null
    property var eraseStrokes: []
    property var presetColors: [
        "#FFFFFF",
        "#000000",
        "#E53935",
        "#FB8C00",
        "#FDD835",
        "#43A047",
        "#1E88E5",
        "#8E24AA",
        "#00ACC1",
        "#6D4C41"
    ]
    property color fillColor: "#263238"
    property real fillOpacity: 0.35
    property var fillLayers: []
    property color hexColor: "#58C4DD"
    property real hexFillOpacity: 0.35
    property real hexOutlineOpacity: 0.8
    property var hexGroups: []
    property var currentHexCells: ({})
    property real eraserSizeFt: 8.0
    property real eraserSoftness: 0.5
    property var currentEraserPath: []
    property var currentEraserCursor: null
    property bool eraserCommitPending: false
    property bool eraserAwaitingStaticPaint: false
    property int eraserAwaitRevision: -1
    property bool renderTraceEnabled: true
    property bool measureActive: false
    property var measureStart: null
    property var measureEnd: null
    property real measureDistanceFt: 0
    property real lastToolClickAtMs: 0
    property string lastToolClickTool: ""
    property string lastSceneIdentity: ""
    property string lastStrokesRaw: ""
    property string lastHexRaw: ""
    property string lastFillRaw: ""
    property string lastEraseRaw: ""
    property string sceneEditPendingFileTarget: "map"
    property bool toolHintVisible: false
    property string toolHintText: ""
    property real toolHintX: 12
    property real toolHintY: 12
    property var toolHintOwner: null


    function shouldUseD6PhysicsVisual(payload) {
        if (!payload || payload.kind !== "standard") {
            return false
        }
        if (!payload.dice || payload.dice.length !== 1) {
            return false
        }
        return Number(payload.dice[0]) === 6
    }


    function useCustomCursor(toolName) {
        return toolName === "cursor"
            || toolName === "pen"
            || toolName === "eraser"
            || toolName === "hex_select"
            || toolName === "fill"
            || toolName === "measure"
    }

    function shouldUseArrowCursor() {
        if (pointerOverPanelUi) {
            return true
        }
        return currentTool !== "pan_zoom" && !useCustomCursor(currentTool)
    }

    function shouldShowPanelPeek() {
        return panelExpanded
            || pointerOverPanelUi
            || (pointerInsideMap && pointerX <= panelRevealZoneWidth)
    }

    function canToggleFullscreenByDoubleClick(toolName) {
        return false
    }

    function toggleFullscreenMode() {
        visibility = visibility === Window.FullScreen ? Window.Windowed : Window.FullScreen
    }

    function sceneIdentity() {
        return String(appController.currentAdventure || "") + "::" + String(appController.currentScene || "")
    }

    function penBrushSizePx() {
        return Math.max(1, (penSizeFt / 5.0) * hexRadiusPx)
    }

    function eraserBrushRadiusPx() {
        return Math.max(1, (eraserSizeFt / 5.0) * hexRadiusPx)
    }

    function eraserCoreRadiusPx() {
        var outer = eraserBrushRadiusPx()
        var softness = Math.min(1.0, Math.max(0.0, eraserSoftness))
        return Math.max(1.0, outer * (1.0 - softness))
    }

    function appendStrokePoint(worldPoint, forceAppend) {
        if (!worldPoint) {
            return false
        }
        if (currentStrokePoints.length === 0) {
            currentStrokePoints.push({"x": worldPoint.x, "y": worldPoint.y})
            return true
        }
        var last = currentStrokePoints[currentStrokePoints.length - 1]
        var dx = Number(worldPoint.x) - Number(last.x)
        var dy = Number(worldPoint.y) - Number(last.y)
        var distance = Math.sqrt(dx * dx + dy * dy)
        var minStep = Math.max(0.75, penBrushSizePx() * 0.22)
        if (!forceAppend && distance < minStep) {
            return false
        }
        if (distance < 1e-6) {
            return false
        }
        var added = false
        if (distance <= minStep) {
            currentStrokePoints.push({"x": worldPoint.x, "y": worldPoint.y})
            return true
        }
        var segments = Math.max(1, Math.floor(distance / minStep))
        for (var s = 1; s <= segments; s++) {
            var t = s / segments
            currentStrokePoints.push({
                "x": Number(last.x) + dx * t,
                "y": Number(last.y) + dy * t
            })
            added = true
        }
        var tail = currentStrokePoints[currentStrokePoints.length - 1]
        if (forceAppend
                && (Math.abs(Number(worldPoint.x) - Number(tail.x)) > 1e-4
                    || Math.abs(Number(worldPoint.y) - Number(tail.y)) > 1e-4)) {
            currentStrokePoints.push({"x": worldPoint.x, "y": worldPoint.y})
            added = true
        }
        return added
    }

    function appendEraserPoint(worldPoint, forceAppend) {
        if (!worldPoint) {
            return false
        }
        if (currentEraserPath.length === 0) {
            currentEraserPath.push({"x": worldPoint.x, "y": worldPoint.y})
            return true
        }
        var last = currentEraserPath[currentEraserPath.length - 1]
        var dx = Number(worldPoint.x) - Number(last.x)
        var dy = Number(worldPoint.y) - Number(last.y)
        var distance = Math.sqrt(dx * dx + dy * dy)
        if (!forceAppend) {
            var minStep = Math.max(0.9, eraserBrushRadiusPx() * 0.22)
            if (distance < minStep) {
                return false
            }
        }
        currentEraserPath.push({"x": worldPoint.x, "y": worldPoint.y})
        return true
    }

    function mapToWorldPoint(screenX, screenY) {
        var scale = Math.max(0.0001, viewScale)
        return {
            "x": (screenX - viewOffsetX) / scale,
            "y": (screenY - viewOffsetY) / scale
        }
    }

    function worldToScreenPoint(worldX, worldY) {
        return {
            "x": worldX * viewScale + viewOffsetX,
            "y": worldY * viewScale + viewOffsetY
        }
    }

    function requestFullMapRepaint() {
        gridOverlay.requestPaint()
        fillOverlay.requestPaint()
        drawStaticCache.requestPaint()
        drawOverlay.requestPaint()
        hexOverlay.requestPaint()
        measureOverlay.requestPaint()
        cursorOverlay.requestPaint()
    }

    function traceRender(tag) {
        if (!renderTraceEnabled) {
            return
        }
        var ts = Date.now()
        console.log(
            "[render]",
            ts,
            tag,
            "rev=" + Number(appController.visualRevision),
            "commit=" + eraserCommitPending,
            "awaitPaint=" + eraserAwaitingStaticPaint,
            "awaitRev=" + eraserAwaitRevision,
            "path=" + currentEraserPath.length,
            "cursor=" + (currentEraserCursor ? "1" : "0")
        )
    }

    function clearAllVisualLayersLocal() {
        currentStrokePoints = []
        pendingCommittedStroke = null
        eraserCommitPending = false
        eraserAwaitingStaticPaint = false
        eraserAwaitRevision = -1
        currentEraserPath = []
        currentEraserCursor = null
        strokes = []
        eraseStrokes = []
        fillLayers = []
        hexGroups = []
        currentHexCells = ({})
        closedFillPolygons = []
        lastStrokesRaw = "__force_refresh__"
        lastEraseRaw = "__force_refresh__"
        lastFillRaw = "__force_refresh__"
        lastHexRaw = "__force_refresh__"
        requestFullMapRepaint()
    }

    function zoomAt(screenX, screenY, steps) {
        if (steps === 0) {
            return
        }
        var previousScale = Math.max(0.0001, viewScale)
        var nextScale = previousScale * Math.pow(1.14, steps)
        nextScale = Math.max(0.25, Math.min(4.0, nextScale))
        if (Math.abs(nextScale - previousScale) < 1e-6) {
            return
        }
        var world = mapToWorldPoint(screenX, screenY)
        viewScale = nextScale
        viewOffsetX = screenX - world.x * nextScale
        viewOffsetY = screenY - world.y * nextScale
        requestFullMapRepaint()
    }

    function resetMapView() {
        viewScale = 1.0
        viewOffsetX = 0.0
        viewOffsetY = 0.0
        requestFullMapRepaint()
    }

    function detectMediaTypeFromValue(rawValue, fallbackType) {
        var value = String(rawValue || "").trim().toLowerCase()
        if (value.length === 0) {
            return fallbackType || "color"
        }
        var clean = value.split("?")[0].split("#")[0]
        if (clean.match(/\.(png|jpg|jpeg|webp|bmp|gif)$/)) {
            return "image"
        }
        if (clean.match(/\.(mp4|webm|mkv|avi|mov|wmv|m4v)$/)) {
            return "video"
        }
        return fallbackType || "color"
    }

    function applyDetectedMediaType(value, comboBox) {
        if (!comboBox) {
            return
        }
        var detected = detectMediaTypeFromValue(value, comboBox.currentText || "color")
        if (detected === "image") {
            comboBox.currentIndex = 1
        } else if (detected === "video") {
            comboBox.currentIndex = 2
        } else {
            comboBox.currentIndex = 0
        }
    }

    function drawHex(ctx, cx, cy, radius) {
        ctx.beginPath()
        for (var i = 0; i < 6; i++) {
            var angle = (Math.PI / 180.0) * (60 * i - 30)
            var px = cx + radius * Math.cos(angle)
            var py = cy + radius * Math.sin(angle)
            if (i === 0) {
                ctx.moveTo(px, py)
            } else {
                ctx.lineTo(px, py)
            }
        }
        ctx.closePath()
        ctx.stroke()
    }

    function drawStroke(ctx, stroke) {
        if (!stroke || !stroke.points || stroke.points.length < 2) {
            return
        }
        var points = stroke.points
        var sizeFt = stroke.size_ft !== undefined ? Number(stroke.size_ft) : 5.0
        var sizePx = Math.max(1, (sizeFt / 5.0) * hexRadiusPx)
        ctx.strokeStyle = stroke.color || "#F4D35E"
        ctx.globalAlpha = stroke.opacity !== undefined ? Number(stroke.opacity) : 1.0
        ctx.lineWidth = sizePx
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.beginPath()
        ctx.moveTo(points[0].x, points[0].y)
        for (var i = 1; i < points.length; i++) {
            ctx.lineTo(points[i].x, points[i].y)
        }
        ctx.stroke()
        ctx.globalAlpha = 1.0
    }

    function isStrokeClosed(stroke) {
        if (!stroke || !stroke.points || stroke.points.length < 3) {
            return false
        }
        var first = stroke.points[0]
        var last = stroke.points[stroke.points.length - 1]
        var dx = Number(first.x) - Number(last.x)
        var dy = Number(first.y) - Number(last.y)
        var brushFt = stroke.size_ft !== undefined ? Number(stroke.size_ft) : 5.0
        var brushPx = Math.max(1, (brushFt / 5.0) * hexRadiusPx)
        var closureThreshold = Math.max(6, brushPx * 1.5)
        return Math.sqrt(dx * dx + dy * dy) <= closureThreshold
    }

    function strokeToPolygon(stroke) {
        if (!stroke || !stroke.points) {
            return []
        }
        var polygon = []
        for (var i = 0; i < stroke.points.length; i++) {
            var point = stroke.points[i]
            polygon.push({"x": Number(point.x), "y": Number(point.y)})
        }
        return polygon
    }

    function polygonAreaAbs(polygon) {
        if (!polygon || polygon.length < 3) {
            return 0
        }
        var sum = 0
        for (var i = 0; i < polygon.length; i++) {
            var a = polygon[i]
            var b = polygon[(i + 1) % polygon.length]
            sum += Number(a.x) * Number(b.y) - Number(b.x) * Number(a.y)
        }
        return Math.abs(sum) / 2.0
    }

    function distancePointToSegment(px, py, ax, ay, bx, by) {
        var dx = bx - ax
        var dy = by - ay
        if (dx === 0 && dy === 0) {
            var sx = px - ax
            var sy = py - ay
            return Math.sqrt(sx * sx + sy * sy)
        }
        var t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)
        if (t < 0) {
            t = 0
        } else if (t > 1) {
            t = 1
        }
        var cx = ax + t * dx
        var cy = ay + t * dy
        var rx = px - cx
        var ry = py - cy
        return Math.sqrt(rx * rx + ry * ry)
    }

    function distanceToPolygonEdges(x, y, polygon) {
        if (!polygon || polygon.length < 2) {
            return Number.POSITIVE_INFINITY
        }
        var minDistance = Number.POSITIVE_INFINITY
        for (var i = 0; i < polygon.length; i++) {
            var a = polygon[i]
            var b = polygon[(i + 1) % polygon.length]
            var distance = distancePointToSegment(
                x,
                y,
                Number(a.x),
                Number(a.y),
                Number(b.x),
                Number(b.y)
            )
            if (distance < minDistance) {
                minDistance = distance
            }
        }
        return minDistance
    }

    function buildClosedFillPolygons() {
        var result = []
        for (var i = 0; i < strokes.length; i++) {
            var stroke = strokes[i]
            if (!isStrokeClosed(stroke)) {
                continue
            }
            var polygon = strokeToPolygon(stroke)
            if (polygon.length < 3) {
                continue
            }
            result.push({
                "points": polygon,
                "area": polygonAreaAbs(polygon),
                "strokeIndex": i
            })
        }
        closedFillPolygons = result
    }

    function pointInPolygon(x, y, polygon) {
        if (!polygon || polygon.length < 3) {
            return false
        }
        var inside = false
        var j = polygon.length - 1
        for (var i = 0; i < polygon.length; i++) {
            var xi = Number(polygon[i].x)
            var yi = Number(polygon[i].y)
            var xj = Number(polygon[j].x)
            var yj = Number(polygon[j].y)
            var intersects = (yi > y) !== (yj > y)
            if (intersects) {
                var denominator = yj - yi
                if (denominator === 0) {
                    denominator = 1e-9
                }
                var hitX = (xj - xi) * (y - yi) / denominator + xi
                if (x < hitX) {
                    inside = !inside
                }
            }
            j = i
        }
        return inside
    }

    function findFillPolygonAtPoint(x, y) {
        var bestPolygon = []
        var bestArea = Number.POSITIVE_INFINITY
        var bestStrokeIndex = -1
        var edgeThreshold = Math.max(4, penBrushSizePx() * 0.6)

        for (var i = 0; i < closedFillPolygons.length; i++) {
            var candidate = closedFillPolygons[i]
            if (!candidate || !candidate.points || candidate.points.length < 3) {
                continue
            }
            var polygon = candidate.points
            var inside = pointInPolygon(x, y, polygon)
            var onEdge = distanceToPolygonEdges(x, y, polygon) <= edgeThreshold
            if (!inside && !onEdge) {
                continue
            }
            var area = Number(candidate.area)
            var strokeIndex = Number(candidate.strokeIndex)
            if (area < bestArea || (area === bestArea && strokeIndex > bestStrokeIndex)) {
                bestArea = area
                bestStrokeIndex = strokeIndex
                bestPolygon = polygon
            }
        }
        return bestPolygon
    }

    function markBlockedDisk(blocked, gridWidth, gridHeight, cellPx, cx, cy, radiusPx) {
        var minX = Math.max(0, Math.floor((cx - radiusPx) / cellPx))
        var maxX = Math.min(gridWidth - 1, Math.floor((cx + radiusPx) / cellPx))
        var minY = Math.max(0, Math.floor((cy - radiusPx) / cellPx))
        var maxY = Math.min(gridHeight - 1, Math.floor((cy + radiusPx) / cellPx))
        var radiusSq = radiusPx * radiusPx
        for (var gy = minY; gy <= maxY; gy++) {
            var centerY = gy * cellPx + cellPx / 2.0
            for (var gx = minX; gx <= maxX; gx++) {
                var centerX = gx * cellPx + cellPx / 2.0
                var dx = centerX - cx
                var dy = centerY - cy
                if (dx * dx + dy * dy <= radiusSq) {
                    blocked[gy * gridWidth + gx] = 1
                }
            }
        }
    }

    function clearBlockedDisk(blocked, gridWidth, gridHeight, cellPx, cx, cy, radiusPx) {
        var minX = Math.max(0, Math.floor((cx - radiusPx) / cellPx))
        var maxX = Math.min(gridWidth - 1, Math.floor((cx + radiusPx) / cellPx))
        var minY = Math.max(0, Math.floor((cy - radiusPx) / cellPx))
        var maxY = Math.min(gridHeight - 1, Math.floor((cy + radiusPx) / cellPx))
        var radiusSq = radiusPx * radiusPx
        for (var gy = minY; gy <= maxY; gy++) {
            var centerY = gy * cellPx + cellPx / 2.0
            for (var gx = minX; gx <= maxX; gx++) {
                var centerX = gx * cellPx + cellPx / 2.0
                var dx = centerX - cx
                var dy = centerY - cy
                if (dx * dx + dy * dy <= radiusSq) {
                    blocked[gy * gridWidth + gx] = 0
                }
            }
        }
    }

    function rasterizeStrokeToBlockedGrid(stroke, blocked, gridWidth, gridHeight, cellPx) {
        if (!stroke || !stroke.points || stroke.points.length === 0) {
            return
        }
        var sizeFt = stroke.size_ft !== undefined ? Number(stroke.size_ft) : 5.0
        var strokeRadiusPx = Math.max(1, (sizeFt / 5.0) * hexRadiusPx) / 2.0 + 1.5
        var points = stroke.points
        for (var i = 0; i < points.length - 1; i++) {
            var a = points[i]
            var b = points[i + 1]
            var ax = Number(a.x)
            var ay = Number(a.y)
            var bx = Number(b.x)
            var by = Number(b.y)
            var dx = bx - ax
            var dy = by - ay
            var segmentLength = Math.sqrt(dx * dx + dy * dy)
            var steps = Math.max(1, Math.ceil(segmentLength / Math.max(1, cellPx * 0.7)))
            for (var s = 0; s <= steps; s++) {
                var t = s / steps
                var sx = ax + dx * t
                var sy = ay + dy * t
                markBlockedDisk(blocked, gridWidth, gridHeight, cellPx, sx, sy, strokeRadiusPx)
            }
        }
        var first = points[0]
        markBlockedDisk(
            blocked,
            gridWidth,
            gridHeight,
            cellPx,
            Number(first.x),
            Number(first.y),
            strokeRadiusPx
        )
    }

    function rasterizeEraserStrokeToBlockedGrid(stroke, blocked, gridWidth, gridHeight, cellPx) {
        if (!stroke || !stroke.points || stroke.points.length === 0) {
            return
        }
        var radiusPx = Math.max(1, Number(stroke.radius_px !== undefined ? stroke.radius_px : 10))
        var points = stroke.points
        for (var i = 0; i < points.length - 1; i++) {
            var a = points[i]
            var b = points[i + 1]
            var ax = Number(a.x)
            var ay = Number(a.y)
            var bx = Number(b.x)
            var by = Number(b.y)
            var dx = bx - ax
            var dy = by - ay
            var segmentLength = Math.sqrt(dx * dx + dy * dy)
            var steps = Math.max(1, Math.ceil(segmentLength / Math.max(1, cellPx * 0.7)))
            for (var s = 0; s <= steps; s++) {
                var t = s / steps
                var sx = ax + dx * t
                var sy = ay + dy * t
                clearBlockedDisk(blocked, gridWidth, gridHeight, cellPx, sx, sy, radiusPx)
            }
        }
        var first = points[0]
        clearBlockedDisk(
            blocked,
            gridWidth,
            gridHeight,
            cellPx,
            Number(first.x),
            Number(first.y),
            radiusPx
        )
    }

    function findNearestUnblockedSeed(blocked, gridWidth, gridHeight, seedX, seedY) {
        function isFree(x, y) {
            return x >= 0
                && y >= 0
                && x < gridWidth
                && y < gridHeight
                && blocked[y * gridWidth + x] === 0
        }

        if (isFree(seedX, seedY)) {
            return {"x": seedX, "y": seedY}
        }

        var maxDistance = 10
        for (var d = 1; d <= maxDistance; d++) {
            for (var dy = -d; dy <= d; dy++) {
                for (var dx = -d; dx <= d; dx++) {
                    if (Math.max(Math.abs(dx), Math.abs(dy)) !== d) {
                        continue
                    }
                    var nx = seedX + dx
                    var ny = seedY + dy
                    if (isFree(nx, ny)) {
                        return {"x": nx, "y": ny}
                    }
                }
            }
        }
        return null
    }

    function buildMaskFillAtPoint(x, y) {
        if (strokes.length === 0) {
            return null
        }

        var cellPx = Math.max(4, Math.min(10, Math.round(hexRadiusPx / 5.0)))
        var gridWidth = Math.max(1, Math.ceil(width / cellPx))
        var gridHeight = Math.max(1, Math.ceil(height / cellPx))
        var gridCount = gridWidth * gridHeight
        if (gridCount > 260000) {
            return null
        }

        var blocked = new Uint8Array(gridCount)
        var drawIndex = 0
        var eraseIndex = 0
        while (drawIndex < strokes.length || eraseIndex < eraseStrokes.length) {
            var nextDrawOp = drawIndex < strokes.length
                ? normalizeOpId(strokes[drawIndex] ? strokes[drawIndex].op_id : null, drawIndex + 1)
                : Number.MAX_SAFE_INTEGER
            var nextEraseOp = eraseIndex < eraseStrokes.length
                ? normalizeOpId(eraseStrokes[eraseIndex] ? eraseStrokes[eraseIndex].op_id : null, eraseIndex + 1)
                : Number.MAX_SAFE_INTEGER
            if (nextDrawOp <= nextEraseOp) {
                rasterizeStrokeToBlockedGrid(strokes[drawIndex], blocked, gridWidth, gridHeight, cellPx)
                drawIndex += 1
            } else {
                rasterizeEraserStrokeToBlockedGrid(eraseStrokes[eraseIndex], blocked, gridWidth, gridHeight, cellPx)
                eraseIndex += 1
            }
        }

        var seedX = Math.floor(x / cellPx)
        var seedY = Math.floor(y / cellPx)
        var seed = findNearestUnblockedSeed(blocked, gridWidth, gridHeight, seedX, seedY)
        if (!seed) {
            return null
        }

        var visited = new Uint8Array(gridCount)
        var queueX = []
        var queueY = []
        var head = 0
        var touchesBorder = false

        queueX.push(seed.x)
        queueY.push(seed.y)
        visited[seed.y * gridWidth + seed.x] = 1

        while (head < queueX.length) {
            var cx = queueX[head]
            var cy = queueY[head]
            head += 1

            if (cx === 0 || cy === 0 || cx === gridWidth - 1 || cy === gridHeight - 1) {
                touchesBorder = true
            }

            var neighbors = [
                {"x": cx + 1, "y": cy},
                {"x": cx - 1, "y": cy},
                {"x": cx, "y": cy + 1},
                {"x": cx, "y": cy - 1}
            ]
            for (var n = 0; n < neighbors.length; n++) {
                var nx = neighbors[n].x
                var ny = neighbors[n].y
                if (nx < 0 || ny < 0 || nx >= gridWidth || ny >= gridHeight) {
                    continue
                }
                var idx = ny * gridWidth + nx
                if (visited[idx] !== 0 || blocked[idx] !== 0) {
                    continue
                }
                visited[idx] = 1
                queueX.push(nx)
                queueY.push(ny)
            }
        }

        if (touchesBorder) {
            return null
        }

        var runs = []
        for (var gy = 0; gy < gridHeight; gy++) {
            var gx = 0
            while (gx < gridWidth) {
                var index = gy * gridWidth + gx
                if (visited[index] === 0) {
                    gx += 1
                    continue
                }
                var startX = gx
                while (gx + 1 < gridWidth && visited[gy * gridWidth + gx + 1] !== 0) {
                    gx += 1
                }
                runs.push({"y": gy, "x0": startX, "x1": gx})
                gx += 1
            }
        }

        if (runs.length === 0) {
            return null
        }
        return {
            "cell_px": cellPx,
            "runs": runs
        }
    }

    function addCursorRipple(x, y) {
        var now = Date.now()
        var first = {
            "x": x,
            "y": y,
            "start": now,
            "duration": 360,
            "maxRadius": Math.max(18, hexRadiusPx * 0.9)
        }
        var second = {
            "x": x,
            "y": y,
            "start": now + 80,
            "duration": 360,
            "maxRadius": Math.max(24, hexRadiusPx * 1.25)
        }
        cursorRipples = cursorRipples.concat([first, second])
        cursorAnimationTimer.restart()
        cursorOverlay.requestPaint()
    }

    function refreshCursorRipples() {
        var now = Date.now()
        var active = []
        for (var i = 0; i < cursorRipples.length; i++) {
            var ripple = cursorRipples[i]
            var progress = (now - Number(ripple.start)) / Number(ripple.duration)
            if (progress < 1.0) {
                active.push(ripple)
            }
        }
        cursorRipples = active
    }

    function cellKey(q, r) {
        return String(q) + "," + String(r)
    }

    function axialToCenter(q, r) {
        var radius = hexRadiusPx
        var hexWidth = Math.sqrt(3) * radius
        var rowStep = 1.5 * radius
        var row = r
        var col = q + Math.floor((row - (row & 1)) / 2)
        var xOffset = (row & 1) ? (hexWidth / 2.0) : 0
        return {
            "x": -hexWidth + col * hexWidth + xOffset,
            "y": -radius + row * rowStep
        }
    }

    function pointToCell(x, y) {
        var radius = hexRadiusPx
        var hexWidth = Math.sqrt(3) * radius
        var rowStep = 1.5 * radius
        var row = Math.round((y + radius) / rowStep)
        var xOffset = (row & 1) ? (hexWidth / 2.0) : 0
        var col = Math.round((x - xOffset + hexWidth) / hexWidth)
        var q = col - Math.floor((row - (row & 1)) / 2)
        var center = axialToCenter(q, row)
        return {"q": q, "r": row, "x": center.x, "y": center.y}
    }

    function hexDistance(a, b) {
        if (!a || !b) {
            return 0
        }
        var dq = a.q - b.q
        var dr = a.r - b.r
        var ds = (-a.q - a.r) - (-b.q - b.r)
        return (Math.abs(dq) + Math.abs(dr) + Math.abs(ds)) / 2.0
    }

    function pathTouchesCell(pathPoints, q, r, radiusPx) {
        if (!pathPoints || pathPoints.length === 0) {
            return false
        }
        var center = axialToCenter(q, r)
        var radiusSq = radiusPx * radiusPx
        for (var i = 0; i < pathPoints.length; i++) {
            var sample = pathPoints[i]
            var dx = center.x - Number(sample.x)
            var dy = center.y - Number(sample.y)
            if (dx * dx + dy * dy <= radiusSq) {
                return true
            }
        }
        return false
    }

    function removeHexCellsLocallyByPath(pathPoints, radiusPx) {
        if (!pathPoints || pathPoints.length === 0 || !hexGroups || hexGroups.length === 0) {
            return
        }
        var changed = false
        var updatedGroups = []
        for (var g = 0; g < hexGroups.length; g++) {
            var group = hexGroups[g]
            if (!group || !group.cells || group.cells.length === 0) {
                continue
            }
            var keptCells = []
            for (var c = 0; c < group.cells.length; c++) {
                var cell = group.cells[c]
                if (!cell) {
                    continue
                }
                var q = Number(cell.q)
                var r = Number(cell.r)
                if (pathTouchesCell(pathPoints, q, r, radiusPx)) {
                    changed = true
                } else {
                    keptCells.push(cell)
                }
            }
            if (keptCells.length > 0) {
                if (keptCells.length !== group.cells.length) {
                    changed = true
                    updatedGroups.push({
                        "op_id": group.op_id,
                        "color": group.color,
                        "fill_opacity": group.fill_opacity,
                        "outline_opacity": group.outline_opacity,
                        "cells": keptCells
                    })
                } else {
                    updatedGroups.push(group)
                }
            } else if (group.cells.length > 0) {
                changed = true
            }
        }
        if (changed) {
            hexGroups = updatedGroups
            hexOverlay.requestPaint()
        }
    }

    function drawSingleHex(ctx, q, r, fillColor, fillAlpha, strokeColor, strokeAlpha) {
        var center = axialToCenter(q, r)
        ctx.beginPath()
        for (var i = 0; i < 6; i++) {
            var angle = (Math.PI / 180.0) * (60 * i - 30)
            var px = center.x + hexRadiusPx * Math.cos(angle)
            var py = center.y + hexRadiusPx * Math.sin(angle)
            if (i === 0) {
                ctx.moveTo(px, py)
            } else {
                ctx.lineTo(px, py)
            }
        }
        ctx.closePath()
        if (fillColor) {
            ctx.globalAlpha = fillAlpha
            ctx.fillStyle = fillColor
            ctx.fill()
        }
        if (strokeColor) {
            ctx.globalAlpha = strokeAlpha
            ctx.strokeStyle = strokeColor
            ctx.lineWidth = 2
            ctx.stroke()
        }
        ctx.globalAlpha = 1.0
    }

    function hexVertices(cx, cy, radius) {
        var vertices = []
        for (var i = 0; i < 6; i++) {
            var angle = (Math.PI / 180.0) * (60 * i - 30)
            vertices.push({
                "x": cx + radius * Math.cos(angle),
                "y": cy + radius * Math.sin(angle)
            })
        }
        return vertices
    }

    function buildCellLookup(cells) {
        var lookup = ({})
        if (!cells) {
            return lookup
        }
        for (var i = 0; i < cells.length; i++) {
            var cell = cells[i]
            if (!cell) {
                continue
            }
            lookup[cellKey(Number(cell.q), Number(cell.r))] = true
        }
        return lookup
    }

    function drawHexGroup(ctx, group) {
        if (!group || !group.cells || group.cells.length === 0) {
            return
        }

        var fillColorValue = group.color || "#58C4DD"
        var fillAlpha = group.fill_opacity !== undefined ? Number(group.fill_opacity) : 0.35
        var outlineAlpha = group.outline_opacity !== undefined ? Number(group.outline_opacity) : 0.8
        for (var i = 0; i < group.cells.length; i++) {
            var cell = group.cells[i]
            drawSingleHex(
                ctx,
                Number(cell.q),
                Number(cell.r),
                fillColorValue,
                fillAlpha,
                fillColorValue,
                outlineAlpha
            )
        }
    }

    function resolvedHexCells() {
        var resolved = []
        var cellIndexByKey = ({})
        for (var g = 0; g < hexGroups.length; g++) {
            var group = hexGroups[g]
            if (!group || !group.cells || group.cells.length === 0) {
                continue
            }
            for (var c = 0; c < group.cells.length; c++) {
                var cell = group.cells[c]
                if (!cell) {
                    continue
                }
                var q = Number(cell.q)
                var r = Number(cell.r)
                var key = cellKey(q, r)
                var resolvedCell = {
                    "q": q,
                    "r": r,
                    "color": group.color || "#58C4DD",
                    "fill_opacity": group.fill_opacity !== undefined ? Number(group.fill_opacity) : 0.35,
                    "outline_opacity": group.outline_opacity !== undefined ? Number(group.outline_opacity) : 0.8
                }
                if (cellIndexByKey[key] !== undefined) {
                    resolved[cellIndexByKey[key]] = resolvedCell
                } else {
                    cellIndexByKey[key] = resolved.length
                    resolved.push(resolvedCell)
                }
            }
        }
        return resolved
    }

    function refreshHexGroupsFromController() {
        var raw = appController.activeHexGroupsJson
        if (raw === lastHexRaw) {
            return
        }
        lastHexRaw = raw
        if (!raw || raw.length === 0) {
            hexGroups = []
        } else {
            try {
                hexGroups = JSON.parse(raw)
            } catch (err) {
                hexGroups = []
            }
        }
        hexOverlay.requestPaint()
    }

    function refreshFillLayersFromController() {
        var raw = appController.activeFillLayersJson
        if (raw === lastFillRaw) {
            return
        }
        lastFillRaw = raw
        if (!raw || raw.length === 0) {
            fillLayers = []
        } else {
            try {
                fillLayers = JSON.parse(raw)
            } catch (err) {
                fillLayers = []
            }
        }
        fillOverlay.requestPaint()
    }

    function refreshEraseStrokesFromController() {
        var raw = appController.activeEraseStrokesJson
        if (raw === lastEraseRaw) {
            return
        }
        lastEraseRaw = raw
        if (!raw || raw.length === 0) {
            eraseStrokes = []
        } else {
            try {
                eraseStrokes = JSON.parse(raw)
            } catch (err) {
                eraseStrokes = []
            }
        }
        hexOverlay.requestPaint()
        fillOverlay.requestPaint()
        drawStaticCache.requestPaint()
        drawOverlay.requestPaint()
    }

    function refreshStrokesFromController() {
        var raw = appController.activeDrawStrokesJson
        if (raw === lastStrokesRaw) {
            return
        }
        lastStrokesRaw = raw
        if (!raw || raw.length === 0) {
            strokes = []
        } else {
            try {
                strokes = JSON.parse(raw)
            } catch (err) {
                strokes = []
            }
        }
        buildClosedFillPolygons()
        drawStaticCache.requestPaint()
        drawOverlay.requestPaint()
    }

    function stampSoftEraser(ctx, x, y, radiusPx, softnessValue) {
        var outer = Math.max(1.0, radiusPx)
        var softness = Math.min(1.0, Math.max(0.0, softnessValue))
        var inner = outer * (1.0 - softness)
        var gradient = ctx.createRadialGradient(x, y, inner, x, y, outer)
        gradient.addColorStop(0.0, "rgba(0,0,0,1)")
        gradient.addColorStop(1.0, "rgba(0,0,0,0)")
        ctx.fillStyle = gradient
        ctx.beginPath()
        ctx.arc(x, y, outer, 0, Math.PI * 2.0)
        ctx.fill()
    }

    function normalizeOpId(rawValue, fallbackValue) {
        var parsed = Number(rawValue)
        if (!isFinite(parsed) || parsed < 1) {
            return fallbackValue
        }
        return Math.floor(parsed)
    }

    function applySingleEraserStroke(ctx, stroke) {
        if (!stroke || !stroke.points || stroke.points.length === 0) {
            return
        }
        var radiusPx = Number(stroke.radius_px !== undefined ? stroke.radius_px : 10)
        var softnessValue = Number(stroke.softness !== undefined ? stroke.softness : 0.5)
        var points = stroke.points
        for (var p = 0; p < points.length - 1; p++) {
            var a = points[p]
            var b = points[p + 1]
            var ax = Number(a.x)
            var ay = Number(a.y)
            var bx = Number(b.x)
            var by = Number(b.y)
            var dx = bx - ax
            var dy = by - ay
            var length = Math.sqrt(dx * dx + dy * dy)
            var step = Math.max(1.4, radiusPx * 0.75)
            var samples = Math.max(1, Math.ceil(length / step))
            for (var s = 0; s <= samples; s++) {
                var t = s / samples
                stampSoftEraser(
                    ctx,
                    ax + dx * t,
                    ay + dy * t,
                    radiusPx,
                    softnessValue
                )
            }
        }
        var first = points[0]
        stampSoftEraser(ctx, Number(first.x), Number(first.y), radiusPx, softnessValue)
    }

    function applyEraserEvent(ctx, stroke) {
        ctx.save()
        ctx.globalCompositeOperation = "destination-out"
        applySingleEraserStroke(ctx, stroke)
        ctx.restore()
    }

    function drawFillLayerContent(ctx, layer) {
        if (!layer) {
            return
        }
        ctx.globalAlpha = layer.opacity !== undefined ? Number(layer.opacity) : 0.35
        ctx.fillStyle = layer.color || "#263238"
        if (layer.mode === "polygon" && layer.points && layer.points.length >= 3) {
            ctx.beginPath()
            ctx.moveTo(Number(layer.points[0].x), Number(layer.points[0].y))
            for (var j = 1; j < layer.points.length; j++) {
                ctx.lineTo(Number(layer.points[j].x), Number(layer.points[j].y))
            }
            ctx.closePath()
            ctx.fill()
        } else if (layer.mode === "mask" && layer.runs && layer.runs.length > 0) {
            var maskCellPx = Math.max(1, Number(layer.cell_px !== undefined ? layer.cell_px : 6))
            for (var r = 0; r < layer.runs.length; r++) {
                var run = layer.runs[r]
                var y = Number(run.y)
                var x0 = Number(run.x0)
                var x1 = Number(run.x1)
                var rectX = x0 * maskCellPx
                var rectY = y * maskCellPx
                var rectW = (x1 - x0 + 1) * maskCellPx
                ctx.fillRect(rectX, rectY, rectW, maskCellPx)
            }
        } else {
            ctx.fillRect(0, 0, width, height)
        }
        ctx.globalAlpha = 1.0
    }

    function renderLayerWithEraserTimeline(ctx, objects, drawObjectFn) {
        var objectIndex = 0
        var eraseIndex = 0
        while (objectIndex < objects.length || eraseIndex < eraseStrokes.length) {
            var nextObjectOp = objectIndex < objects.length
                ? normalizeOpId(objects[objectIndex] ? objects[objectIndex].op_id : null, objectIndex + 1)
                : Number.MAX_SAFE_INTEGER
            var nextEraseOp = eraseIndex < eraseStrokes.length
                ? normalizeOpId(eraseStrokes[eraseIndex] ? eraseStrokes[eraseIndex].op_id : null, eraseIndex + 1)
                : Number.MAX_SAFE_INTEGER

            if (nextObjectOp <= nextEraseOp) {
                drawObjectFn(ctx, objects[objectIndex])
                objectIndex += 1
            } else {
                applyEraserEvent(ctx, eraseStrokes[eraseIndex])
                eraseIndex += 1
            }
        }
    }

    function applyLiveEraserMask(ctx) {
        if (currentTool !== "eraser" || currentEraserPath.length === 0) {
            if (!currentEraserCursor) {
                return
            }
        }
        var points = currentEraserPath.slice()
        if (currentEraserCursor) {
            points.push({"x": currentEraserCursor.x, "y": currentEraserCursor.y})
        }
        if (points.length === 0) {
            return
        }
        applyEraserEvent(ctx, {
            "points": points,
            "radius_px": eraserBrushRadiusPx(),
            "softness": eraserSoftness
        })
    }

    function closeToolSettings() {
        penSettingsPopup.close()
        fillSettingsPopup.close()
        eraserSettingsPopup.close()
        hexSettingsPopup.close()
        cursorSettingsPopup.close()
        measureSettingsPopup.close()
        panSettingsPopup.close()
        sceneEditPopup.close()
    }

    function handleToolButtonClick(toolName, popup, sourceButton) {
        var now = Date.now()
        var isDoubleClick = lastToolClickTool === toolName && (now - lastToolClickAtMs) <= 500
        lastToolClickTool = toolName
        lastToolClickAtMs = now
        currentTool = toolName
        if (isDoubleClick && popup) {
            Qt.callLater(function() {
                openToolSettings(popup, sourceButton)
            })
        } else {
            closeToolSettings()
        }
    }

    function openToolSettings(popup, sourceButton) {
        if (!popup) {
            return
        }
        closeToolSettings()
        var popupAnchorY = 12
        if (sourceButton) {
            var mapped = sourceButton.mapToItem(leftPanel, 0, 0)
            popupAnchorY = leftPanel.y + mapped.y
        }
        var popupHeight = popup.height > 0
            ? popup.height
            : (popup.implicitHeight > 0 ? popup.implicitHeight : 220)
        var maxY = Math.max(8, mapWindow.height - popupHeight - 8)
        popup.x = Math.max(8, leftPanel.x + leftPanel.width + 8)
        popup.y = Math.max(8, Math.min(maxY, popupAnchorY))
        popup.open()
    }

    function openSceneEditor(sourceButton) {
        if (!appController.currentScene || appController.currentScene.length === 0) {
            return
        }
        var draft = appController.load_scene_draft(appController.currentScene)
        if (!draft || !draft.map || !draft.background || !draft.grid) {
            return
        }
        sceneEditName.text = draft.name || appController.currentScene
        sceneEditOriginalName.text = draft.original_name || appController.currentScene
        sceneEditMapType.currentIndex = draft.map.type === "image" ? 1 : (draft.map.type === "video" ? 2 : 0)
        sceneEditMapValue.text = draft.map.value || ""
        sceneEditMapAutoplay.checked = !!draft.map.autoplay
        sceneEditMapLoop.checked = !!draft.map.loop
        sceneEditMapMute.checked = !!draft.map.mute

        sceneEditBgType.currentIndex = draft.background.type === "image"
            ? 1
            : (draft.background.type === "video" ? 2 : 0)
        sceneEditBgValue.text = draft.background.value || ""
        sceneEditBgAutoplay.checked = !!draft.background.autoplay
        sceneEditBgLoop.checked = !!draft.background.loop
        sceneEditBgMute.checked = !!draft.background.mute

        sceneEditGridSize.text = Number(draft.grid.cell_size_ft || 5).toFixed(2)
        sceneEditGridThickness.text = Number(draft.grid.line_thickness_px || 1.5).toFixed(2)
        sceneEditGridOpacity.text = Number(draft.grid.opacity || 0.45).toFixed(2)
        sceneEditGridColor.text = draft.grid.color || "#9DA6B0"
        openToolSettings(sceneEditPopup, sourceButton)
    }

    function collectSceneEditorDraft() {
        return {
            "mode": "edit",
            "name": sceneEditName.text,
            "original_name": sceneEditOriginalName.text,
            "map": {
                "type": sceneEditMapType.currentText,
                "value": sceneEditMapValue.text,
                "autoplay": sceneEditMapAutoplay.checked,
                "loop": sceneEditMapLoop.checked,
                "mute": sceneEditMapMute.checked
            },
            "background": {
                "type": sceneEditBgType.currentText,
                "value": sceneEditBgValue.text,
                "autoplay": sceneEditBgAutoplay.checked,
                "loop": sceneEditBgLoop.checked,
                "mute": sceneEditBgMute.checked
            },
            "grid": {
                "cell_size_ft": Number(sceneEditGridSize.text),
                "line_thickness_px": Number(sceneEditGridThickness.text),
                "opacity": Number(sceneEditGridOpacity.text),
                "color": sceneEditGridColor.text
            }
        }
    }

    function applySceneEditorDraft() {
        var ok = appController.save_scene_draft(collectSceneEditorDraft())
        if (ok) {
            sceneEditPopup.close()
        }
    }

    component ToolButton: AbstractButton {
        id: control
        property bool accent: false
        property bool highlighted: false
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        activeFocusOnTab: false
        implicitHeight: 32
        font.pixelSize: 13

        contentItem: Text {
            text: control.text
            color: control.enabled
                ? ((control.accent || control.highlighted) ? "#FCFCFD" : mapWindow.uiTextPrimary)
                : "#7E818B"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: control.font.pixelSize
            font.weight: control.accent ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
        }

        background: Rectangle {
            property bool activeState: control.accent || control.highlighted
            radius: 9
            border.width: 1
            border.color: (control.accent || control.highlighted) ? "#B8BBC3" : "#4B4F58"
            opacity: control.enabled ? 1.0 : 0.5
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: (control.accent || control.highlighted)
                        ? (control.down ? "#686D79" : "#7A808D")
                        : (control.down ? "#2C2F37" : "#353943")
                }
                GradientStop {
                    position: 1
                    color: (control.accent || control.highlighted)
                        ? (control.down ? "#5E6370" : "#737985")
                        : (control.down ? "#252830" : "#2F333D")
                }
            }
            scale: control.down ? 0.98 : (control.hovered ? 1.015 : 1.0)
            Behavior on scale {
                NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
            }
        }
    }

    component ToolField: TextField {
        id: control
        color: mapWindow.uiTextPrimary
        selectedTextColor: "#F6F6F7"
        selectionColor: "#636875"
        placeholderTextColor: "#8A8D97"
        padding: 8
        background: Rectangle {
            radius: 9
            color: "#1E2128"
            border.width: 1
            border.color: control.activeFocus ? "#A4A8B3" : "#4A4E59"
            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }
        }
    }

    component IconSquareButton: AbstractButton {
        id: control
        property string iconText: ""
        property url iconSource: ""
        property bool selectedState: false
        property string hintText: ""
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        activeFocusOnTab: false
        implicitWidth: 52
        implicitHeight: 52

        function syncToolHint() {
            if (control.hovered && control.hintText.length > 0) {
                var mapped = control.mapToItem(mapWindow.contentItem, control.width + 12, Math.round((control.height - 26) / 2))
                mapWindow.toolHintText = control.hintText
                mapWindow.toolHintX = Math.max(8, mapped.x)
                mapWindow.toolHintY = Math.max(8, mapped.y)
                mapWindow.toolHintVisible = true
                mapWindow.toolHintOwner = control
            } else if (mapWindow.toolHintOwner === control) {
                mapWindow.toolHintVisible = false
                mapWindow.toolHintOwner = null
            }
        }

        contentItem: Item {
            Image {
                anchors.centerIn: parent
                width: 22
                height: 22
                source: control.iconSource
                fillMode: Image.PreserveAspectFit
                visible: control.iconSource.toString().length > 0
                smooth: true
                mipmap: true
                opacity: control.enabled ? 1.0 : 0.5
            }
            Text {
                anchors.centerIn: parent
                visible: control.iconSource.toString().length === 0
                text: control.iconText
                color: !control.enabled ? "#7E818B" : "#ECEEF2"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: "Segoe UI Symbol"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

        }

        background: Rectangle {
            radius: 12
            border.width: 1
            border.color: control.selectedState ? "#A8B3CB" : "#515563"
            color: control.selectedState
                ? (control.down ? "#4C5668" : "#5C687E")
                : (control.down ? "#2A2E35" : (control.hovered ? "#343A45" : "#2A2D35"))
            opacity: control.enabled ? 1.0 : 0.45
            scale: control.down ? 0.94 : (control.hovered ? 1.05 : (control.selectedState ? 1.02 : 1.0))
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        onHoveredChanged: syncToolHint()
        onXChanged: syncToolHint()
        onYChanged: syncToolHint()
        onVisibleChanged: syncToolHint()
        onHintTextChanged: syncToolHint()
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }

    Rectangle {
        width: 420
        height: 420
        radius: 210
        x: -120
        y: -170
        color: "#4D515B"
        opacity: 0.13
        visible: false
    }

    Rectangle {
        width: 460
        height: 460
        radius: 230
        x: mapWindow.width - width + 120
        y: mapWindow.height - height + 160
        color: "#40444F"
        opacity: 0.09
        visible: false
    }

    Rectangle {
        id: mapColorLayer
        anchors.fill: parent
        visible: appController.activeMapMediaType === "color"
        color: appController.activeMapFillColor
        transform: [
            Scale {
                origin.x: 0
                origin.y: 0
                xScale: viewScale
                yScale: viewScale
            },
            Translate {
                x: viewOffsetX
                y: viewOffsetY
            }
        ]
    }

    Image {
        id: mapImageLayer
        anchors.fill: parent
        visible: appController.activeMapMediaType === "image"
        source: appController.activeMapMediaType === "image" ? appController.activeMapMediaSource : ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        transform: [
            Scale {
                origin.x: 0
                origin.y: 0
                xScale: viewScale
                yScale: viewScale
            },
            Translate {
                x: viewOffsetX
                y: viewOffsetY
            }
        ]
    }

    MediaPlayer {
        id: mapPlayer
        source: appController.activeMapMediaType === "video" ? appController.activeMapMediaSource : ""
        loops: appController.activeMapMediaLoop ? MediaPlayer.Infinite : 1
        autoPlay: appController.activeMapMediaAutoplay && appController.activeMapMediaType === "video"
        videoOutput: mapVideoLayer
        // Avoid attaching audio pipeline while muted to reduce noisy ffmpeg audio warnings.
        audioOutput: appController.activeMapMediaMute ? null : mapAudioOutput
        onErrorOccurred: function(error, errorString) {
            if (error !== MediaPlayer.NoError) {
                stop()
                console.warn("РћС€РёР±РєР° РІРёРґРµРѕ РєР°СЂС‚С‹:", errorString)
            }
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia) {
                stop()
            }
        }
    }

    AudioOutput {
        id: mapAudioOutput
        muted: false
        volume: 1.0
    }

    VideoOutput {
        id: mapVideoLayer
        anchors.fill: parent
        visible: appController.activeMapMediaType === "video"
        fillMode: VideoOutput.PreserveAspectCrop
        transform: [
            Scale {
                origin.x: 0
                origin.y: 0
                xScale: viewScale
                yScale: viewScale
            },
            Translate {
                x: viewOffsetX
                y: viewOffsetY
            }
        ]
    }

    Canvas {
        id: gridOverlay
        anchors.fill: parent
        opacity: appController.activeGridOpacity

        onPaint: {
            if (eraserCommitPending || eraserAwaitingStaticPaint) {
                traceRender("drawStaticCache.onPaint")
            }
            var ctx = getContext("2d")
            ctx.setTransform(1, 0, 0, 1, 0, 0)
            ctx.clearRect(0, 0, width, height)
            ctx.setTransform(viewScale, 0, 0, viewScale, viewOffsetX, viewOffsetY)
            ctx.strokeStyle = appController.activeGridColor
            ctx.lineWidth = appController.activeGridLineThicknessPx

            var radius = hexRadiusPx
            var hexWidth = Math.sqrt(3) * radius
            var rowStep = 1.5 * radius
            var rowIndex = 0

            for (var y = -radius; y < height + radius; y += rowStep) {
                var xOffset = (rowIndex % 2) * (hexWidth / 2.0)
                for (var x = -hexWidth; x < width + hexWidth; x += hexWidth) {
                    drawHex(ctx, x + xOffset, y, radius)
                }
                rowIndex += 1
            }
        }
    }

    Canvas {
        id: fillOverlay
        anchors.fill: parent
        z: 2
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Immediate

        onPaint: {
            var ctx = getContext("2d")
            ctx.setTransform(1, 0, 0, 1, 0, 0)
            ctx.clearRect(0, 0, width, height)
            ctx.setTransform(viewScale, 0, 0, viewScale, viewOffsetX, viewOffsetY)
            renderLayerWithEraserTimeline(ctx, fillLayers, function(context, layer) {
                drawFillLayerContent(context, layer)
            })
            applyLiveEraserMask(ctx)
            ctx.globalAlpha = 1.0
        }
    }

    Canvas {
        id: drawStaticCache
        anchors.fill: parent
        z: 3
        visible: !(currentTool === "eraser"
                   && (eraserCommitPending
                       || eraserAwaitingStaticPaint
                       || currentEraserPath.length > 0
                       || currentEraserCursor))
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Threaded

        onPaint: {
            var ctx = getContext("2d")
            ctx.setTransform(1, 0, 0, 1, 0, 0)
            ctx.clearRect(0, 0, width, height)
            ctx.setTransform(viewScale, 0, 0, viewScale, viewOffsetX, viewOffsetY)
            renderLayerWithEraserTimeline(ctx, strokes, function(context, stroke) {
                drawStroke(context, stroke)
            })
        }

        onPainted: {
            if (eraserCommitPending || eraserAwaitingStaticPaint) {
                traceRender("drawStaticCache.onPainted")
            }
            if (pendingCommittedStroke) {
                pendingCommittedStroke = null
                drawOverlay.requestPaint()
            }
            if (eraserAwaitingStaticPaint) {
                eraserAwaitingStaticPaint = false
                currentEraserPath = []
                currentEraserCursor = null
                eraserAwaitRevision = -1
                drawOverlay.requestPaint()
            }
        }

    }

    Canvas {
        id: drawOverlay
        anchors.fill: parent
        z: 4
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Immediate

        onPaint: {
            var ctx = getContext("2d")
            ctx.setTransform(1, 0, 0, 1, 0, 0)
            ctx.clearRect(0, 0, width, height)
            ctx.setTransform(viewScale, 0, 0, viewScale, viewOffsetX, viewOffsetY)
            var erasingNow = currentTool === "eraser"
                && (eraserCommitPending
                    || eraserAwaitingStaticPaint
                    || currentEraserPath.length > 0
                    || currentEraserCursor)
            if (erasingNow) {
                traceRender("drawOverlay.onPaint")
            }
            if (erasingNow) {
                renderLayerWithEraserTimeline(ctx, strokes, function(context, stroke) {
                    drawStroke(context, stroke)
                })
            }
            if (currentStrokePoints.length > 1) {
                drawStroke(ctx, {
                    "color": penColor,
                    "size_ft": penSizeFt,
                    "opacity": penOpacity,
                    "points": currentStrokePoints
                })
            }
            if (pendingCommittedStroke) {
                drawStroke(ctx, pendingCommittedStroke)
            }
            applyLiveEraserMask(ctx)
        }
    }

    Canvas {
        id: hexOverlay
        anchors.fill: parent
        z: 1
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Threaded

        onPaint: {
            var ctx = getContext("2d")
            ctx.setTransform(1, 0, 0, 1, 0, 0)
            ctx.clearRect(0, 0, width, height)
            ctx.setTransform(viewScale, 0, 0, viewScale, viewOffsetX, viewOffsetY)
            var resolvedCells = resolvedHexCells()
            for (var i = 0; i < resolvedCells.length; i++) {
                var cell = resolvedCells[i]
                drawSingleHex(
                    ctx,
                    Number(cell.q),
                    Number(cell.r),
                    String(cell.color),
                    Number(cell.fill_opacity),
                    String(cell.color),
                    Number(cell.outline_opacity)
                )
            }

            var keys = Object.keys(currentHexCells)
            for (var k = 0; k < keys.length; k++) {
                var key = keys[k]
                var live = currentHexCells[key]
                drawSingleHex(ctx, live.q, live.r, String(hexColor), 0.2, String(hexColor), 0.95)
            }
        }
    }

    Canvas {
        id: measureOverlay
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.setTransform(1, 0, 0, 1, 0, 0)
            ctx.clearRect(0, 0, width, height)
            if (!measureActive || !measureStart || !measureEnd) {
                return
            }
            ctx.setTransform(viewScale, 0, 0, viewScale, viewOffsetX, viewOffsetY)
            drawSingleHex(ctx, measureStart.q, measureStart.r, "#E9D66B", 0.3, "#E9D66B", 0.95)
            drawSingleHex(ctx, measureEnd.q, measureEnd.r, "#E9D66B", 0.3, "#E9D66B", 0.95)

            ctx.beginPath()
            ctx.moveTo(measureStart.x, measureStart.y)
            ctx.lineTo(measureEnd.x, measureEnd.y)
            ctx.strokeStyle = "#F5E87B"
            ctx.lineWidth = 2
            ctx.stroke()

            ctx.setTransform(1, 0, 0, 1, 0, 0)
            var midpoint = worldToScreenPoint(
                (measureStart.x + measureEnd.x) / 2.0,
                (measureStart.y + measureEnd.y) / 2.0
            )
            var labelX = midpoint.x
            var labelY = midpoint.y - 8
            ctx.fillStyle = "#111"
            ctx.globalAlpha = 0.75
            ctx.fillRect(labelX - 34, labelY - 14, 68, 22)
            ctx.globalAlpha = 1.0
            ctx.fillStyle = "#F5E87B"
            ctx.font = "12px sans-serif"
            ctx.fillText(Math.round(measureDistanceFt) + " ft", labelX - 18, labelY + 1)
        }
    }

    MouseArea {
        id: interactionArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: currentTool === "pan_zoom"
            ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
            : (shouldUseArrowCursor() ? Qt.ArrowCursor : Qt.BlankCursor)

        onWheel: function(wheel) {
            if (currentTool !== "pan_zoom") {
                return
            }
            var steps = wheel.angleDelta.y / 120.0
            if (steps === 0) {
                return
            }
            zoomAt(wheel.x, wheel.y, steps)
            wheel.accepted = true
        }

        onDoubleClicked: {
            if (mouse.button !== Qt.LeftButton) {
                return
            }
            if (!canToggleFullscreenByDoubleClick(currentTool)) {
                return
            }
            toggleFullscreenMode()
        }

        onPressed: {
            if (mouse.button !== Qt.LeftButton) {
                return
            }
            if (!panelExpanded && pointerX <= panelRevealZoneWidth) {
            }
            toolHintVisible = false
            toolHintOwner = null
            pointerX = mouse.x
            pointerY = mouse.y
            var worldPoint = mapToWorldPoint(mouse.x, mouse.y)
            pointerWorldX = worldPoint.x
            pointerWorldY = worldPoint.y
            cursorOverlay.requestPaint()

            if (currentTool === "pan_zoom") {
                panningView = true
                panStartX = mouse.x
                panStartY = mouse.y
                panStartOffsetX = viewOffsetX
                panStartOffsetY = viewOffsetY
                return
            }
            if (currentTool === "cursor") {
                addCursorRipple(mouse.x, mouse.y)
                return
            }
            if (currentTool === "pen") {
                currentStrokePoints = []
                appendStrokePoint(worldPoint, true)
                drawOverlay.requestPaint()
                return
            }
            if (currentTool === "fill") {
                var polygon = findFillPolygonAtPoint(worldPoint.x, worldPoint.y)
                if (polygon && polygon.length >= 3) {
                    appController.add_fill_layer(
                        String(fillColor),
                        fillOpacity,
                        "polygon",
                        JSON.stringify(polygon)
                    )
                } else {
                    var maskData = buildMaskFillAtPoint(worldPoint.x, worldPoint.y)
                    if (maskData && maskData.runs && maskData.runs.length > 0) {
                        appController.add_fill_layer(
                            String(fillColor),
                            fillOpacity,
                            "mask",
                            JSON.stringify(maskData)
                        )
                    } else {
                        appController.add_fill_layer(String(fillColor), fillOpacity, "screen", "[]")
                    }
                }
                return
            }
            if (currentTool === "eraser") {
                eraserCommitPending = false
                eraserAwaitingStaticPaint = false
                eraserAwaitRevision = -1
                currentEraserPath = []
                currentEraserCursor = {"x": worldPoint.x, "y": worldPoint.y}
                if (appendEraserPoint(worldPoint, true)) {
                    removeHexCellsLocallyByPath(currentEraserPath, eraserCoreRadiusPx())
                    drawOverlay.requestPaint()
                    fillOverlay.requestPaint()
                    hexOverlay.requestPaint()
                }
                return
            }
            if (currentTool === "hex_select") {
                var startCell = pointToCell(worldPoint.x, worldPoint.y)
                currentHexCells = ({})
                currentHexCells[cellKey(startCell.q, startCell.r)] = {"q": startCell.q, "r": startCell.r}
                hexOverlay.requestPaint()
                return
            }
            if (currentTool === "measure") {
                measureStart = pointToCell(worldPoint.x, worldPoint.y)
                measureEnd = measureStart
                measureDistanceFt = 0
                measureActive = true
                measureOverlay.requestPaint()
                return
            }
        }

        onPositionChanged: function(mouse) {
            pointerX = mouse.x
            pointerY = mouse.y
            var worldPoint = mapToWorldPoint(mouse.x, mouse.y)
            pointerWorldX = worldPoint.x
            pointerWorldY = worldPoint.y
            if (!panelExpanded) {
            }
            cursorOverlay.requestPaint()
            if (pressed && currentTool === "pan_zoom" && panningView) {
                viewOffsetX = panStartOffsetX + (mouse.x - panStartX)
                viewOffsetY = panStartOffsetY + (mouse.y - panStartY)
                requestFullMapRepaint()
            } else if (pressed && currentTool === "pen") {
                if (appendStrokePoint(worldPoint, false)) {
                    drawOverlay.requestPaint()
                }
            } else if (pressed && currentTool === "eraser") {
                currentEraserCursor = {"x": worldPoint.x, "y": worldPoint.y}
                var added = appendEraserPoint(worldPoint, false)
                if (added) {
                    var pathSegment = []
                    if (currentEraserPath.length > 1) {
                        pathSegment.push(currentEraserPath[currentEraserPath.length - 2])
                    }
                    pathSegment.push(currentEraserPath[currentEraserPath.length - 1])
                    removeHexCellsLocallyByPath(pathSegment, eraserCoreRadiusPx())
                }
                drawOverlay.requestPaint()
                if (fillLayers.length > 0) {
                    fillOverlay.requestPaint()
                }
                hexOverlay.requestPaint()
            } else if (pressed && currentTool === "hex_select") {
                var cell = pointToCell(worldPoint.x, worldPoint.y)
                currentHexCells[cellKey(cell.q, cell.r)] = {"q": cell.q, "r": cell.r}
                hexOverlay.requestPaint()
            } else if (pressed && currentTool === "measure" && measureActive) {
                measureEnd = pointToCell(worldPoint.x, worldPoint.y)
                measureDistanceFt = hexDistance(measureStart, measureEnd) * 5.0
                measureOverlay.requestPaint()
            }
        }

        onReleased: {
            if (currentTool === "pan_zoom") {
                panningView = false
            }
            if (currentTool === "pen" && currentStrokePoints.length > 0) {
                var releasePoint = mapToWorldPoint(mouse.x, mouse.y)
                appendStrokePoint(releasePoint, true)
                if (currentStrokePoints.length === 1) {
                    currentStrokePoints.push({
                        "x": currentStrokePoints[0].x,
                        "y": currentStrokePoints[0].y
                    })
                }
                var committedPoints = currentStrokePoints.slice(0)
                pendingCommittedStroke = {
                    "color": String(penColor),
                    "size_ft": penSizeFt,
                    "opacity": penOpacity,
                    "points": committedPoints
                }
                strokes = strokes.concat([pendingCommittedStroke])
                buildClosedFillPolygons()
                drawStaticCache.requestPaint()
                appController.add_draw_stroke(
                    JSON.stringify(committedPoints),
                    String(penColor),
                    penSizeFt,
                    penOpacity
                )
                currentStrokePoints = []
            }
            if (currentTool === "eraser" && currentEraserPath.length > 0) {
                appendEraserPoint(mapToWorldPoint(mouse.x, mouse.y), true)
                eraserCommitPending = true
                eraserAwaitRevision = Number(appController.visualRevision) + 1
                traceRender("eraser.onReleased.commit")
                var eraserRadiusPx = Math.max(1, (eraserSizeFt / 5.0) * hexRadiusPx)
                appController.erase_with_path(
                    JSON.stringify(currentEraserPath),
                    eraserRadiusPx,
                    eraserSoftness
                )
            }
            if (currentTool === "hex_select") {
                var keys = Object.keys(currentHexCells)
                if (keys.length > 0) {
                    var cells = []
                    for (var i = 0; i < keys.length; i++) {
                        cells.push(currentHexCells[keys[i]])
                    }
                    appController.add_hex_group(
                        JSON.stringify(cells),
                        String(hexColor),
                        hexFillOpacity,
                        hexOutlineOpacity
                    )
                }
                currentHexCells = ({})
                hexOverlay.requestPaint()
            }
            if (currentTool === "measure") {
                measureActive = false
                measureStart = null
                measureEnd = null
                measureDistanceFt = 0
                measureOverlay.requestPaint()
            }
            currentStrokePoints = []
            if (!eraserCommitPending) {
                currentEraserPath = []
                currentEraserCursor = null
            }
            drawOverlay.requestPaint()
            fillOverlay.requestPaint()
            hexOverlay.requestPaint()
        }

        onEntered: {
            pointerInsideMap = true
            var worldPoint = mapToWorldPoint(pointerX, pointerY)
            pointerWorldX = worldPoint.x
            pointerWorldY = worldPoint.y
            if (!panelExpanded && pointerX <= panelRevealZoneWidth) {
            }
            cursorOverlay.requestPaint()
        }

        onExited: {
            pointerInsideMap = false
            if (!panelExpanded) {
            }
            cursorOverlay.requestPaint()
        }
    }

    Canvas {
        id: cursorOverlay
        anchors.fill: parent
        z: 9

        onPaint: {
            var ctx = getContext("2d")
            ctx.setTransform(1, 0, 0, 1, 0, 0)
            ctx.clearRect(0, 0, width, height)

            var now = Date.now()
            for (var i = 0; i < cursorRipples.length; i++) {
                var ripple = cursorRipples[i]
                var progress = (now - Number(ripple.start)) / Number(ripple.duration)
                if (progress < 0 || progress > 1) {
                    continue
                }
                var radius = 4 + Number(ripple.maxRadius) * progress
                var alpha = (1.0 - progress) * 0.9
                ctx.beginPath()
                ctx.arc(Number(ripple.x), Number(ripple.y), radius, 0, Math.PI * 2.0)
                ctx.lineWidth = Math.max(1.0, 2.2 - progress)
                ctx.strokeStyle = "#F4D35E"
                ctx.globalAlpha = alpha
                ctx.stroke()
            }

            if (currentTool === "cursor" && pointerInsideMap) {
                ctx.beginPath()
                ctx.arc(pointerX, pointerY, 4.0, 0, Math.PI * 2.0)
                ctx.fillStyle = "#F4D35E"
                ctx.globalAlpha = 0.98
                ctx.fill()
            }
            if (currentTool === "pen" && pointerInsideMap) {
                var penRadius = (penBrushSizePx() * viewScale) / 2.0
                ctx.beginPath()
                ctx.arc(pointerX, pointerY, penRadius, 0, Math.PI * 2.0)
                ctx.fillStyle = String(penColor)
                ctx.globalAlpha = Math.min(0.55, Math.max(0.12, penOpacity * 0.45))
                ctx.fill()
                ctx.lineWidth = 1.2
                ctx.strokeStyle = String(penColor)
                ctx.globalAlpha = Math.min(1.0, Math.max(0.35, penOpacity))
                ctx.stroke()
            }
            if (currentTool === "eraser" && pointerInsideMap) {
                var outerRadius = eraserBrushRadiusPx() * viewScale
                var innerRadius = outerRadius * (1.0 - eraserSoftness)
                ctx.setLineDash([6, 4])
                ctx.beginPath()
                ctx.arc(pointerX, pointerY, outerRadius, 0, Math.PI * 2.0)
                ctx.strokeStyle = "#F5F7FA"
                ctx.lineWidth = 1.4
                ctx.globalAlpha = 0.92
                ctx.stroke()
                ctx.setLineDash([])

                ctx.beginPath()
                ctx.arc(pointerX, pointerY, Math.max(0.5, innerRadius), 0, Math.PI * 2.0)
                ctx.fillStyle = "#F5F7FA"
                ctx.globalAlpha = 0.2
                ctx.fill()
                ctx.lineWidth = 1.0
                ctx.strokeStyle = "#F5F7FA"
                ctx.globalAlpha = 0.85
                ctx.stroke()
            }
            if (currentTool === "hex_select" && pointerInsideMap) {
                var previewCell = pointToCell(pointerWorldX, pointerWorldY)
                ctx.save()
                ctx.setTransform(viewScale, 0, 0, viewScale, viewOffsetX, viewOffsetY)
                drawSingleHex(
                    ctx,
                    previewCell.q,
                    previewCell.r,
                    String(hexColor),
                    0.22,
                    String(hexColor),
                    0.98
                )
                ctx.restore()
                ctx.beginPath()
                ctx.arc(pointerX, pointerY, 3.4, 0, Math.PI * 2.0)
                ctx.fillStyle = "#F2F2F2"
                ctx.globalAlpha = 0.95
                ctx.fill()
            }
            if (currentTool === "fill" && pointerInsideMap) {
                var previewPolygon = findFillPolygonAtPoint(pointerWorldX, pointerWorldY)
                if (previewPolygon.length >= 3) {
                    ctx.save()
                    ctx.setTransform(viewScale, 0, 0, viewScale, viewOffsetX, viewOffsetY)
                    ctx.beginPath()
                    ctx.moveTo(Number(previewPolygon[0].x), Number(previewPolygon[0].y))
                    for (var p = 1; p < previewPolygon.length; p++) {
                        ctx.lineTo(Number(previewPolygon[p].x), Number(previewPolygon[p].y))
                    }
                    ctx.closePath()
                    ctx.fillStyle = String(fillColor)
                    ctx.globalAlpha = 0.12
                    ctx.fill()
                    ctx.setLineDash([5, 4])
                    ctx.lineWidth = 1.2
                    ctx.strokeStyle = String(fillColor)
                    ctx.globalAlpha = 0.8
                    ctx.stroke()
                    ctx.setLineDash([])
                    ctx.restore()
                }
                ctx.beginPath()
                ctx.arc(pointerX, pointerY, 4.0, 0, Math.PI * 2.0)
                ctx.fillStyle = String(fillColor)
                ctx.globalAlpha = 0.95
                ctx.fill()
            }
            if (currentTool === "measure" && pointerInsideMap && !measureActive) {
                var hoverCell = pointToCell(pointerWorldX, pointerWorldY)
                ctx.save()
                ctx.setTransform(viewScale, 0, 0, viewScale, viewOffsetX, viewOffsetY)
                drawSingleHex(ctx, hoverCell.q, hoverCell.r, "#E9D66B", 0.15, "#E9D66B", 0.95)
                ctx.restore()
            }

            ctx.globalAlpha = 1.0
        }
    }

    Timer {
        id: cursorAnimationTimer
        interval: 16
        repeat: true
        running: false
        onTriggered: {
            refreshCursorRipples()
            cursorOverlay.requestPaint()
            if (cursorRipples.length === 0) {
                stop()
            }
        }
    }

    component SettingsPopup: Popup {
        id: control
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape
        padding: 12
        opacity: 0.0
        scale: 0.96

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 120 }
                NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 140; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 100 }
                NumberAnimation { property: "scale"; from: 1.0; to: 0.97; duration: 100; easing.type: Easing.InCubic }
            }
        }

        background: Rectangle {
            radius: 12
            border.color: "#505666"
            border.width: 1
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#2E323C" }
                GradientStop { position: 1.0; color: "#252932" }
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: 13
                color: "transparent"
                border.width: 1
                border.color: "#111318"
                opacity: 0.55
            }
        }
    }

    SettingsPopup {
        id: penSettingsPopup
        x: Math.max(8, leftPanel.x + leftPanel.width + 8)
        y: 96
        width: 240
        contentItem: ColumnLayout {
            spacing: 8
            Label { text: "РџРµСЂРѕ"; color: mapWindow.uiTextPrimary; font.pixelSize: 14 }
            Label { text: "Р¦РІРµС‚"; color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
            RowLayout {
                spacing: 4
                Repeater {
                    model: presetColors
                    delegate: Rectangle {
                        width: 18
                        height: 18
                        radius: 4
                        color: modelData
                        border.width: String(penColor).toLowerCase() === String(modelData).toLowerCase() ? 2 : 1
                        border.color: "#E7E7EB"
                        MouseArea {
                            anchors.fill: parent
                            onClicked: penColor = modelData
                        }
                    }
                }
            }
            ToolField {
                Layout.fillWidth: true
                text: String(penColor)
                placeholderText: "#FFFFFF"
                onEditingFinished: penColor = text
            }
            Label { text: "Р Р°Р·РјРµСЂ (ft): " + Number(penSizeFt).toFixed(2); color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
            Slider {
                Layout.fillWidth: true
                from: 1.0 / 6.0
                to: 25.0
                value: penSizeFt
                onMoved: penSizeFt = value
            }
            Label { text: "РџСЂРѕР·СЂР°С‡РЅРѕСЃС‚СЊ: " + Number(penOpacity).toFixed(2); color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
            Slider {
                Layout.fillWidth: true
                from: 0.05
                to: 1.0
                value: penOpacity
                onMoved: penOpacity = value
            }
        }
    }

    SettingsPopup {
        id: fillSettingsPopup
        x: Math.max(8, leftPanel.x + leftPanel.width + 8)
        y: 180
        width: 240
        contentItem: ColumnLayout {
            spacing: 8
            Label { text: "Р—Р°Р»РёРІРєР°"; color: mapWindow.uiTextPrimary; font.pixelSize: 14 }
            Label { text: "Р¦РІРµС‚"; color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
            RowLayout {
                spacing: 4
                Repeater {
                    model: presetColors
                    delegate: Rectangle {
                        width: 18
                        height: 18
                        radius: 4
                        color: modelData
                        border.width: String(fillColor).toLowerCase() === String(modelData).toLowerCase() ? 2 : 1
                        border.color: "#E7E7EB"
                        MouseArea {
                            anchors.fill: parent
                            onClicked: fillColor = modelData
                        }
                    }
                }
            }
            ToolField {
                Layout.fillWidth: true
                text: String(fillColor)
                placeholderText: "#FFFFFF"
                onEditingFinished: fillColor = text
            }
            Label { text: "РџСЂРѕР·СЂР°С‡РЅРѕСЃС‚СЊ: " + Number(fillOpacity).toFixed(2); color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
            Slider {
                Layout.fillWidth: true
                from: 0.05
                to: 1.0
                value: fillOpacity
                onMoved: fillOpacity = value
            }
        }
    }

    SettingsPopup {
        id: eraserSettingsPopup
        x: Math.max(8, leftPanel.x + leftPanel.width + 8)
        y: 264
        width: 240
        contentItem: ColumnLayout {
            spacing: 8
            Label { text: "Р›Р°СЃС‚РёРє"; color: mapWindow.uiTextPrimary; font.pixelSize: 14 }
            Label { text: "Р Р°Р·РјРµСЂ (ft): " + Number(eraserSizeFt).toFixed(2); color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
            Slider {
                Layout.fillWidth: true
                from: 1.0 / 6.0
                to: 25.0
                value: eraserSizeFt
                onMoved: eraserSizeFt = value
            }
            Label { text: "РњСЏРіРєРѕСЃС‚СЊ: " + Number(eraserSoftness).toFixed(2); color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
            Slider {
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: eraserSoftness
                onMoved: eraserSoftness = value
            }
        }
    }

    SettingsPopup {
        id: hexSettingsPopup
        x: Math.max(8, leftPanel.x + leftPanel.width + 8)
        y: 348
        width: 240
        contentItem: ColumnLayout {
            spacing: 8
            Label { text: "Р’С‹РґРµР»РµРЅРёРµ РіРµРєСЃРѕРІ"; color: mapWindow.uiTextPrimary; font.pixelSize: 14 }
            Label { text: "Р¦РІРµС‚"; color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
            RowLayout {
                spacing: 4
                Repeater {
                    model: presetColors
                    delegate: Rectangle {
                        width: 18
                        height: 18
                        radius: 4
                        color: modelData
                        border.width: String(hexColor).toLowerCase() === String(modelData).toLowerCase() ? 2 : 1
                        border.color: "#E7E7EB"
                        MouseArea {
                            anchors.fill: parent
                            onClicked: hexColor = modelData
                        }
                    }
                }
            }
            ToolField {
                Layout.fillWidth: true
                text: String(hexColor)
                placeholderText: "#FFFFFF"
                onEditingFinished: hexColor = text
            }
            Label { text: "РџСЂРѕР·СЂР°С‡РЅРѕСЃС‚СЊ Р·Р°Р»РёРІРєРё: " + Number(hexFillOpacity).toFixed(2); color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
            Slider {
                Layout.fillWidth: true
                from: 0.05
                to: 1.0
                value: hexFillOpacity
                onMoved: hexFillOpacity = value
            }
            Label { text: "РџСЂРѕР·СЂР°С‡РЅРѕСЃС‚СЊ РєРѕРЅС‚СѓСЂР°: " + Number(hexOutlineOpacity).toFixed(2); color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
            Slider {
                Layout.fillWidth: true
                from: 0.05
                to: 1.0
                value: hexOutlineOpacity
                onMoved: hexOutlineOpacity = value
            }
        }
    }

    SettingsPopup {
        id: cursorSettingsPopup
        x: Math.max(8, leftPanel.x + leftPanel.width + 8)
        y: 80
        width: 200
        contentItem: Label {
            text: "Р”Р»СЏ РєСѓСЂСЃРѕСЂР° РЅРµС‚ РЅР°СЃС‚СЂРѕРµРє."
            color: mapWindow.uiTextPrimary
            wrapMode: Text.WordWrap
        }
    }

    SettingsPopup {
        id: measureSettingsPopup
        x: Math.max(8, leftPanel.x + leftPanel.width + 8)
        y: 432
        width: 220
        contentItem: Label {
            text: "РњР°СЃС€С‚Р°Р± С„РёРєСЃРёСЂРѕРІР°РЅ: 1 РіРµРєСЃ = 5 ft."
            color: mapWindow.uiTextPrimary
            wrapMode: Text.WordWrap
        }
    }

    SettingsPopup {
        id: panSettingsPopup
        x: Math.max(8, leftPanel.x + leftPanel.width + 8)
        y: 516
        width: 220
        contentItem: ColumnLayout {
            spacing: 8
            Label {
                text: "РќР°РІРёРіР°С†РёСЏ РєР°СЂС‚С‹"
                color: mapWindow.uiTextPrimary
                font.pixelSize: 14
            }
            Label {
                text: "РљРѕР»РµСЃРѕ РјС‹С€Рё вЂ” РјР°СЃС€С‚Р°Р±, Р›РљРњ вЂ” РїРµСЂРµРјРµС‰РµРЅРёРµ."
                color: mapWindow.uiTextSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            ToolButton {
                text: "РЎР±СЂРѕСЃРёС‚СЊ РІРёРґ"
                accent: true
                Layout.fillWidth: true
                onClicked: resetMapView()
            }
        }
    }

    SettingsPopup {
        id: sceneEditPopup
        x: Math.max(8, leftPanel.x + leftPanel.width + 8)
        y: 70
        width: 420
        height: Math.min(mapWindow.height - 40, 670)
        contentItem: ScrollView {
            clip: true
            ColumnLayout {
                width: sceneEditPopup.width - 26
                spacing: 8

                Label {
                    text: "Р РµРґР°РєС‚РёСЂРѕРІР°РЅРёРµ СЃС†РµРЅС‹"
                    color: mapWindow.uiTextPrimary
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                ToolField {
                    id: sceneEditName
                    Layout.fillWidth: true
                    placeholderText: "РќР°Р·РІР°РЅРёРµ СЃС†РµРЅС‹"
                }
                ToolField {
                    id: sceneEditOriginalName
                    visible: false
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#4C515C" }
                Label { text: "РљР°СЂС‚Р°"; color: mapWindow.uiTextPrimary; font.pixelSize: 14 }
                ComboBox {
                    id: sceneEditMapType
                    model: ["color", "image", "video"]
                    Layout.fillWidth: true
                }
                MediaDropTile {
                    Layout.fillWidth: true
                    mediaType: sceneEditMapType.currentText
                    previewValue: sceneEditMapValue.text
                    fallbackColor: "#2E2E2E"
                    placeholderText: "РџРµСЂРµС‚Р°С‰РёС‚Рµ С„Р°Р№Р», Ctrl+V РёР»Рё РґРІРѕР№РЅРѕР№ РєР»РёРє"
                    onDropValue: function(value) {
                        sceneEditMapValue.text = value
                        applyDetectedMediaType(value, sceneEditMapType)
                    }
                    onPasteRequest: {
                        var pastedMap = appController.paste_media_value("map")
                        sceneEditMapValue.text = pastedMap
                        applyDetectedMediaType(pastedMap, sceneEditMapType)
                    }
                    onBrowseRequest: {
                        sceneEditPendingFileTarget = "map"
                        sceneEditFileDialog.open()
                    }
                }
                ToolField {
                    id: sceneEditMapValue
                    Layout.fillWidth: true
                    placeholderText: sceneEditMapType.currentText === "color" ? "#2E2E2E" : "РџСѓС‚СЊ / URL"
                }
                RowLayout {
                    Layout.fillWidth: true
                    CheckBox { id: sceneEditMapAutoplay; text: "РђРІС‚Рѕ"; checked: true }
                    CheckBox { id: sceneEditMapLoop; text: "Р¦РёРєР»"; checked: true }
                    CheckBox { id: sceneEditMapMute; text: "Р‘РµР· Р·РІСѓРєР°"; checked: true }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#4C515C" }
                Label { text: "Р¤РѕРЅ"; color: mapWindow.uiTextPrimary; font.pixelSize: 14 }
                ComboBox {
                    id: sceneEditBgType
                    model: ["color", "image", "video"]
                    Layout.fillWidth: true
                }
                MediaDropTile {
                    Layout.fillWidth: true
                    mediaType: sceneEditBgType.currentText
                    previewValue: sceneEditBgValue.text
                    fallbackColor: "#1F1F1F"
                    placeholderText: "РџРµСЂРµС‚Р°С‰РёС‚Рµ С„Р°Р№Р», Ctrl+V РёР»Рё РґРІРѕР№РЅРѕР№ РєР»РёРє"
                    onDropValue: function(value) {
                        sceneEditBgValue.text = value
                        applyDetectedMediaType(value, sceneEditBgType)
                    }
                    onPasteRequest: {
                        var pastedBg = appController.paste_media_value("background")
                        sceneEditBgValue.text = pastedBg
                        applyDetectedMediaType(pastedBg, sceneEditBgType)
                    }
                    onBrowseRequest: {
                        sceneEditPendingFileTarget = "background"
                        sceneEditFileDialog.open()
                    }
                }
                ToolField {
                    id: sceneEditBgValue
                    Layout.fillWidth: true
                    placeholderText: sceneEditBgType.currentText === "color" ? "#1F1F1F" : "РџСѓС‚СЊ / URL"
                }
                RowLayout {
                    Layout.fillWidth: true
                    CheckBox { id: sceneEditBgAutoplay; text: "РђРІС‚Рѕ"; checked: true }
                    CheckBox { id: sceneEditBgLoop; text: "Р¦РёРєР»"; checked: true }
                    CheckBox { id: sceneEditBgMute; text: "Р‘РµР· Р·РІСѓРєР°"; checked: true }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#4C515C" }
                Label { text: "РЎРµС‚РєР°"; color: mapWindow.uiTextPrimary; font.pixelSize: 14 }
                Label { text: "Р Р°Р·РјРµСЂ РєР»РµС‚РєРё (ft)"; color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
                ToolField { id: sceneEditGridSize; Layout.fillWidth: true; text: "5.00" }
                Label { text: "РўРѕР»С‰РёРЅР° Р»РёРЅРёРё (px)"; color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
                ToolField { id: sceneEditGridThickness; Layout.fillWidth: true; text: "1.50" }
                Label { text: "РџСЂРѕР·СЂР°С‡РЅРѕСЃС‚СЊ (0..1)"; color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
                ToolField { id: sceneEditGridOpacity; Layout.fillWidth: true; text: "0.45" }
                Label { text: "Р¦РІРµС‚"; color: mapWindow.uiTextSecondary; font.pixelSize: 12 }
                ToolField { id: sceneEditGridColor; Layout.fillWidth: true; text: "#9DA6B0" }

                RowLayout {
                    Layout.fillWidth: true
                    ToolButton {
                        text: "РћС‚РјРµРЅР°"
                        Layout.fillWidth: true
                        onClicked: sceneEditPopup.close()
                    }
                    ToolButton {
                        text: "РЎРѕС…СЂР°РЅРёС‚СЊ"
                        accent: true
                        Layout.fillWidth: true
                        onClicked: applySceneEditorDraft()
                    }
                }
            }
        }
    }

    FileDialog {
        id: sceneEditFileDialog
        title: "Р’С‹Р±РµСЂРёС‚Рµ РјРµРґРёР°С„Р°Р№Р»"
        fileMode: FileDialog.OpenFile
        nameFilters: [
            "РњРµРґРёР°С„Р°Р№Р»С‹ (*.png *.jpg *.jpeg *.webp *.bmp *.gif *.mp4 *.webm *.mkv *.avi *.mov *.wmv *.m4v)",
            "Р’СЃРµ С„Р°Р№Р»С‹ (*.*)"
        ]
        onAccepted: {
            var selected = selectedFile.toString()
            if (sceneEditPendingFileTarget === "background") {
                sceneEditBgValue.text = selected
                applyDetectedMediaType(selected, sceneEditBgType)
            } else {
                sceneEditMapValue.text = selected
                applyDetectedMediaType(selected, sceneEditMapType)
            }
        }
    }

    Rectangle {
        id: leftPanel
        z: 20
        width: panelBodyWidth + panelHandleWidth + 10
        height: parent.height
        color: mapWindow.uiPanel
        border.color: mapWindow.uiPanelLine
        border.width: 1
        x: panelExpanded
            ? 0
            : (shouldShowPanelPeek() ? -(width - panelHandleWidth) : -width)
        opacity: 0.98
        clip: true

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: mapWindow.uiPanelSoft }
            GradientStop { position: 1.0; color: mapWindow.uiPanel }
        }

        Behavior on x {
            NumberAnimation {
                duration: 210
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: panelPeekEdge
            width: panelHandleWidth
            height: 220
            radius: 14
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            visible: panelExpanded || shouldShowPanelPeek()
            opacity: 1.0

            Column {
                anchors.centerIn: parent
                spacing: 8
                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: "#E8E8E8"
                        opacity: 0.9
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panelExpanded = !panelExpanded
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.ArrowCursor
            z: 0
            onEntered: {
                pointerOverPanelUi = true
            }
            onExited: {
                pointerOverPanelUi = false
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            anchors.rightMargin: panelHandleWidth + 6
            spacing: 8

            IconSquareButton {
                id: cursorToolButton
                Layout.alignment: Qt.AlignHCenter
                iconSource: "icons/cursor.svg"
                selectedState: currentTool === "cursor"
                hintText: "РљСѓСЂСЃРѕСЂ. Р”РІРѕР№РЅРѕР№ РєР»РёРє Р›РљРњ вЂ” РЅР°СЃС‚СЂРѕР№РєРё."
                onClicked: handleToolButtonClick("cursor", cursorSettingsPopup, cursorToolButton)
            }

            IconSquareButton {
                id: penToolButton
                Layout.alignment: Qt.AlignHCenter
                iconSource: "icons/pen.svg"
                selectedState: currentTool === "pen"
                hintText: "РџРµСЂРѕ. Р”РІРѕР№РЅРѕР№ РєР»РёРє Р›РљРњ вЂ” РЅР°СЃС‚СЂРѕР№РєРё."
                onClicked: handleToolButtonClick("pen", penSettingsPopup, penToolButton)
            }

            IconSquareButton {
                id: fillToolButton
                Layout.alignment: Qt.AlignHCenter
                iconSource: "icons/fill.svg"
                selectedState: currentTool === "fill"
                hintText: "Р—Р°Р»РёРІРєР°. Р”РІРѕР№РЅРѕР№ РєР»РёРє Р›РљРњ вЂ” РЅР°СЃС‚СЂРѕР№РєРё."
                onClicked: handleToolButtonClick("fill", fillSettingsPopup, fillToolButton)
            }

            IconSquareButton {
                id: eraserToolButton
                Layout.alignment: Qt.AlignHCenter
                iconSource: "icons/eraser.svg"
                selectedState: currentTool === "eraser"
                hintText: "Р›Р°СЃС‚РёРє. Р”РІРѕР№РЅРѕР№ РєР»РёРє Р›РљРњ вЂ” РЅР°СЃС‚СЂРѕР№РєРё."
                onClicked: handleToolButtonClick("eraser", eraserSettingsPopup, eraserToolButton)
            }

            IconSquareButton {
                id: hexToolButton
                Layout.alignment: Qt.AlignHCenter
                iconSource: "icons/hex.svg"
                selectedState: currentTool === "hex_select"
                hintText: "Р’С‹Р±РѕСЂ РіРµРєСЃРѕРІ. Р”РІРѕР№РЅРѕР№ РєР»РёРє Р›РљРњ вЂ” РЅР°СЃС‚СЂРѕР№РєРё."
                onClicked: handleToolButtonClick("hex_select", hexSettingsPopup, hexToolButton)
            }

            IconSquareButton {
                id: measureToolButton
                Layout.alignment: Qt.AlignHCenter
                iconSource: "icons/measure.svg"
                selectedState: currentTool === "measure"
                hintText: "РР·РјРµСЂРµРЅРёРµ. Р”РІРѕР№РЅРѕР№ РєР»РёРє Р›РљРњ вЂ” РЅР°СЃС‚СЂРѕР№РєРё."
                onClicked: handleToolButtonClick("measure", measureSettingsPopup, measureToolButton)
            }

            IconSquareButton {
                id: panToolButton
                Layout.alignment: Qt.AlignHCenter
                iconSource: "icons/pan.svg"
                selectedState: currentTool === "pan_zoom"
                hintText: "РќР°РІРёРіР°С†РёСЏ РєР°СЂС‚С‹. Р”РІРѕР№РЅРѕР№ РєР»РёРє Р›РљРњ вЂ” РЅР°СЃС‚СЂРѕР№РєРё."
                onClicked: handleToolButtonClick("pan_zoom", panSettingsPopup, panToolButton)
            }

            IconSquareButton {
                id: fullscreenToolButton
                Layout.alignment: Qt.AlignHCenter
                iconSource: "icons/fullscreen.svg"
                hintText: "РџРѕР»РЅРѕСЌРєСЂР°РЅРЅС‹Р№ СЂРµР¶РёРј."
                onClicked: toggleFullscreenMode()
            }

            IconSquareButton {
                id: sceneEditToolButton
                Layout.alignment: Qt.AlignHCenter
                iconSource: "icons/scene_edit.svg"
                hintText: "Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ СЃС†РµРЅСѓ."
                onClicked: openSceneEditor(sceneEditToolButton)
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 22
                height: 1
                color: "#4A4E59"
                opacity: 0.8
            }

            Item { Layout.fillHeight: true }

            IconSquareButton {
                iconSource: "icons/undo.svg"
                Layout.alignment: Qt.AlignHCenter
                enabled: appController.canUndoSceneAction
                hintText: "РћС‚РјРµРЅРёС‚СЊ РїРѕСЃР»РµРґРЅРµРµ РґРµР№СЃС‚РІРёРµ."
                onClicked: appController.request_undo()
            }

            IconSquareButton {
                iconSource: "icons/clear.svg"
                Layout.alignment: Qt.AlignHCenter
                hintText: "РћС‡РёСЃС‚РёС‚СЊ РІСЃРµ СЃР»РѕРё."
                onClicked: {
                    clearAllVisualLayersLocal()
                    appController.clear_all_visual_layers()
                }
            }

            IconSquareButton {
                iconSource: "icons/save.svg"
                Layout.alignment: Qt.AlignHCenter
                hintText: "РЎРѕС…СЂР°РЅРёС‚СЊ СЃС†РµРЅСѓ."
                onClicked: appController.request_manual_save()
            }

            IconSquareButton {
                iconSource: "icons/back.svg"
                Layout.alignment: Qt.AlignHCenter
                hintText: "РќР°Р·Р°Рґ РІ Р»Р°СѓРЅС‡РµСЂ."
                onClicked: appController.request_back()
            }
        }
    }


    DiceWebOverlay {
        id: diceWebOverlay
        z: 230
        anchors.fill: parent
    }

    MapDiceOverlay {
        id: mapDiceOverlay
        z: 229
        anchors.fill: parent
    }

    Rectangle {
        id: toolHintBubble
        z: 240
        visible: toolHintVisible && toolHintText.length > 0
        x: Math.max(8, Math.min(mapWindow.width - width - 8, toolHintX))
        y: Math.max(8, Math.min(mapWindow.height - height - 8, toolHintY))
        radius: 10
        color: "#242932"
        border.width: 1
        border.color: "#596173"
        opacity: 0.985
        implicitWidth: Math.min(320, toolHintLabel.implicitWidth + 20)
        implicitHeight: toolHintLabel.implicitHeight + 12
        width: implicitWidth
        height: implicitHeight

        Text {
            id: toolHintLabel
            anchors.fill: parent
            anchors.margins: 8
            text: toolHintText
            color: uiTextPrimary
            wrapMode: Text.WordWrap
            font.pixelSize: 12
        }
    }

    Connections {
        target: appController
        function onSceneViewChanged() {
            var nextSceneIdentity = sceneIdentity()
            var sceneChanged = nextSceneIdentity !== lastSceneIdentity
            lastSceneIdentity = nextSceneIdentity
            if (eraserCommitPending || eraserAwaitingStaticPaint) {
                traceRender("sceneViewChanged.start")
            }
            refreshFillLayersFromController()
            refreshEraseStrokesFromController()
            refreshStrokesFromController()
            refreshHexGroupsFromController()
            if (eraserCommitPending
                    && eraserAwaitRevision >= 0
                    && Number(appController.visualRevision) >= eraserAwaitRevision) {
                eraserCommitPending = false
                eraserAwaitingStaticPaint = true
                eraserAwaitRevision = -1
                traceRender("sceneViewChanged.toAwaitPaint")
                drawStaticCache.requestPaint()
                drawOverlay.requestPaint()
            }
            if (sceneChanged) {
                resetMapView()
                panningView = false
                currentHexCells = ({})
                currentEraserPath = []
                measureActive = false
                measureStart = null
                measureEnd = null
                measureDistanceFt = 0
                cursorRipples = []
            }
            currentStrokePoints = []
            measureOverlay.requestPaint()
            gridOverlay.requestPaint()
            cursorOverlay.requestPaint()
            if (appController.activeMapMediaType === "video"
                    && appController.activeMapMediaAutoplay
                    && mapPlayer.source
                    && mapPlayer.source.toString().length > 0) {
                mapPlayer.play()
            } else {
                mapPlayer.stop()
            }
        }
    }

    Connections {
        target: appController
        function onSettingsChanged() {
            requestFullMapRepaint()
        }
    }


    Connections {
        target: eventBus
        function handleBusEvent(eventName, payload) {
            if (eventName !== "dice.visual_roll_requested") {
                return
            }
            if (!payload || !payload.dice) {
                return
            }
            if (mapWindow.shouldUseD6PhysicsVisual(payload)) {
                console.log("[dice-visual] map -> 3d d6", payload.dice.length)
                diceWebOverlay.triggerD6()
            } else {
                console.log("[dice-visual] map -> 2d", payload.dice.length)
                mapDiceOverlay.trigger2D(payload.dice)
            }
        }
        function onEventEmitted(eventName, payload) {
            handleBusEvent(eventName, payload)
        }
        function onEvent_emitted(eventName, payload) {
            handleBusEvent(eventName, payload)
        }
    }

    Shortcut { sequence: "PageDown"; onActivated: appController.request_next_scene() }
    Shortcut { sequence: "PageUp"; onActivated: appController.request_previous_scene() }
    Shortcut { sequence: "Ctrl+S"; onActivated: appController.request_manual_save() }
    Shortcut { sequence: "Ctrl+Z"; onActivated: appController.request_undo() }

    onWidthChanged: requestFullMapRepaint()
    onHeightChanged: requestFullMapRepaint()
    onCurrentToolChanged: {
        if (currentTool !== "pan_zoom") {
            panningView = false
        }
        if (currentTool !== "eraser") {
            eraserCommitPending = false
            eraserAwaitingStaticPaint = false
            eraserAwaitRevision = -1
            currentEraserPath = []
            currentEraserCursor = null
        }
        if (currentTool !== "pen") {
            currentStrokePoints = []
            pendingCommittedStroke = null
        }
        toolHintVisible = false
        toolHintOwner = null
        cursorOverlay.requestPaint()
    }
    onPointerOverPanelUiChanged: cursorOverlay.requestPaint()
    onPanelExpandedChanged: {
        if (!panelExpanded) {
            closeToolSettings()
            toolHintVisible = false
            toolHintOwner = null
        }
    }
    onPenColorChanged: cursorOverlay.requestPaint()
    onPenSizeFtChanged: cursorOverlay.requestPaint()
    onPenOpacityChanged: cursorOverlay.requestPaint()
    onFillColorChanged: cursorOverlay.requestPaint()
    onEraserSizeFtChanged: cursorOverlay.requestPaint()
    onEraserSoftnessChanged: cursorOverlay.requestPaint()
    onHexColorChanged: cursorOverlay.requestPaint()
    Component.onCompleted: {
        lastSceneIdentity = sceneIdentity()
        refreshFillLayersFromController()
        refreshEraseStrokesFromController()
        refreshStrokesFromController()
        refreshHexGroupsFromController()
    }
}


