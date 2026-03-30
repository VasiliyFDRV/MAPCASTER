import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine
Window {
    id: diceWindow
    objectName: "diceWindow"
    width: 400
    height: 640
    minimumWidth: 400
    minimumHeight: 640
    visible: true
    color: "#111111"
    title: "DnD Maps - Дайсы"

    TapHandler {
        id: windowTapClearDiceVisuals
        acceptedButtons: Qt.AllButtons
        onTapped: diceController.request_clear_dice_visuals()
    }
    property int resetToken: 0

    property int d20Count: 0
    property string d20Mode: "normal"
    property int d20Bonus: 0

    property int d4Count: 0
    property int d6Count: 0
    property int d8Count: 0
    property int d10Count: 0
    property int d12Count: 0
    property int standardBonus: 0

    property var d20Result: null
    property var standardResult: null
    property var d100Result: null
    property bool waitingStandardPhysicsResult: false
    property var pendingStandardFallbackResult: null

    property color textPrimary: "#EFEFF2"
    property color textSecondary: "#B0B0B0"
    property color panelColor: "#242424"
    property color panelBorder: "#4A4A4A"
    property var dieStyles: ({})
    property string dieEditorDieKey: "d6"
    property string pendingColorField: ""
    property string pendingColorTitle: "Выбор цвета"
    property var dieEditorWorking: ({
        "scalePercent": 100,
        "color": "#C9C9C9",
        "gradientEnabled": false,
        "gradientCenterColor": "#FFFFFF",
        "gradientSharpness": 50,
        "gradientOffset": 50,
        "fontColor": "#1F1F1F",
        "textStrokeColor": "#EEEEEE",
        "textGlowRadius": 100,
        "textGlowOpacity": 100,
        "edgeColor": "#D4D4D4",
        "edgeWidth": 0.0
    })
    property bool previewWebReady: false
    property int pickerHue: 0
    property int pickerSaturation: 0
    property int pickerValue: 100
    property string pickerHexText: "#FFFFFF"
    property string pickerPreviewColor: "#FFFFFF"
    property string pickerCurrentColor: "#FFFFFF"

    function effectiveCount(countValue) {
        return countValue > 0 ? countValue : 1
    }

    function resetState() {
        d20Count = 0
        d20Mode = "normal"
        d20Bonus = 0

        d4Count = 0
        d6Count = 0
        d8Count = 0
        d10Count = 0
        d12Count = 0
        standardBonus = 0

        clearResults()
    }

    function clearResults() {
        d20Result = null
        standardResult = null
        d100Result = null
        waitingStandardPhysicsResult = false
        pendingStandardFallbackResult = null
        physicsFallbackTimer.stop()
    }

    function canRollStandard() {
        return (d4Count + d6Count + d8Count + d10Count + d12Count) > 0
    }

    function canRollAll() {
        return (d20Count > 0) || canRollStandard()
    }

    function isPhysicsStandardRequest(d4, d6, d8, d10, d12) {
        return d4 === 0
            && (d6 + d8 + d10 + d12) > 0
    }

    function setD20Mode(newMode) {
        if (d20Mode === newMode) {
            d20Mode = "normal"
        } else {
            d20Mode = newMode
        }
    }


    function rollD20Only() {
        clearResults()
        diceController.request_roll_d20(effectiveCount(d20Count), d20Mode, d20Bonus)
    }

    function rollStandardOnly() {
        if (!canRollStandard()) {
            return
        }
        clearResults()
        waitingStandardPhysicsResult = isPhysicsStandardRequest(d4Count, d6Count, d8Count, d10Count, d12Count)
            && diceController.is_map_window_open()
        console.log("[dice-ui-debug] rollStandardOnly waiting=" + waitingStandardPhysicsResult
            + " d4=" + d4Count + " d6=" + d6Count + " d8=" + d8Count + " d10=" + d10Count + " d12=" + d12Count
            + " bonus=" + standardBonus)
        if (waitingStandardPhysicsResult) {
            physicsFallbackTimer.restart()
        }
        diceController.request_roll_standard(d4Count, d6Count, d8Count, d10Count, d12Count, standardBonus)
    }

    function rollSingleStandardDie(sides, configuredCount) {
        var c = effectiveCount(configuredCount)
        var d4 = 0
        var d6 = 0
        var d8 = 0
        var d10 = 0
        var d12 = 0
        if (sides === 4) d4 = c
        else if (sides === 6) d6 = c
        else if (sides === 8) d8 = c
        else if (sides === 10) d10 = c
        else if (sides === 12) d12 = c

        clearResults()
        waitingStandardPhysicsResult = isPhysicsStandardRequest(d4, d6, d8, d10, d12)
            && diceController.is_map_window_open()
        console.log("[dice-ui-debug] rollSingleStandardDie sides=" + sides + " configured=" + configuredCount
            + " effective=" + c + " waiting=" + waitingStandardPhysicsResult
            + " d4=" + d4 + " d6=" + d6 + " d8=" + d8 + " d10=" + d10 + " d12=" + d12 + " bonus=" + standardBonus)
        if (waitingStandardPhysicsResult) {
            physicsFallbackTimer.restart()
        }
        diceController.request_roll_standard(d4, d6, d8, d10, d12, standardBonus)
    }

    function rollD100Only() {
        clearResults()
        diceController.request_roll_d100()
    }

    function rollAll() {
        if (!canRollAll()) {
            return
        }
        clearResults()
        waitingStandardPhysicsResult = d20Count === 0
            && isPhysicsStandardRequest(d4Count, d6Count, d8Count, d10Count, d12Count)
            && diceController.is_map_window_open()
        console.log("[dice-ui-debug] rollAll waiting=" + waitingStandardPhysicsResult
            + " d20=" + d20Count + " mode=" + d20Mode + " d20Bonus=" + d20Bonus
            + " standard(d4/d6/d8/d10/d12)=" + d4Count + "/" + d6Count + "/" + d8Count + "/" + d10Count + "/" + d12Count
            + " stdBonus=" + standardBonus)
        if (waitingStandardPhysicsResult) {
            physicsFallbackTimer.restart()
        }
        diceController.request_roll_all(
            d20Count,
            d20Mode,
            d20Bonus,
            d4Count,
            d6Count,
            d8Count,
            d10Count,
            d12Count,
            standardBonus
        )
    }

    function handleRollCompleted(payload) {
        if (!payload || !payload.kind) {
            return
        }
        var resultTotal = payload.result && payload.result.total !== undefined ? payload.result.total : "-"
        var resultRaw = payload.result && payload.result.raw_total !== undefined ? payload.result.raw_total : "-"
        var firstRoll = (payload.result && payload.result.rolls && payload.result.rolls.length > 0)
            ? payload.result.rolls[0].value : "-"
        console.log("[dice-ui-debug] roll_completed kind=" + payload.kind
            + " request_id=" + (payload.request_id !== undefined ? payload.request_id : "-")
            + " mode=" + (payload.mode || "-")
            + " requested_mode=" + (payload.requested_mode || "-")
            + " waitingBefore=" + waitingStandardPhysicsResult
            + " total=" + resultTotal + " raw=" + resultRaw + " firstRoll=" + firstRoll)
        if (payload.kind === "d20") {
            d20Result = payload.result
        } else if (payload.kind === "standard") {
            var expectsPhysics = waitingStandardPhysicsResult
                || payload.mode === "physics_fallback_random"
                || payload.requested_mode === "physics"
            if (expectsPhysics) {
                if (payload.mode === "physics") {
                    waitingStandardPhysicsResult = false
                    pendingStandardFallbackResult = null
                    physicsFallbackTimer.stop()
                    standardResult = payload.result
                    console.log("[dice-ui-debug] accepted physics result total=" + (standardResult ? standardResult.total : "-"))
                } else if (payload.mode === "physics_fallback_random") {
                    waitingStandardPhysicsResult = false
                    pendingStandardFallbackResult = null
                    physicsFallbackTimer.stop()
                    standardResult = payload.result
                    console.log("[dice-ui-debug] accepted physics timeout fallback total=" + (standardResult ? standardResult.total : "-"))
                } else {
                    waitingStandardPhysicsResult = true
                    pendingStandardFallbackResult = payload.result
                    console.log("[dice-ui-debug] hold fallback result mode=" + (payload.mode || "-")
                        + " total=" + (pendingStandardFallbackResult ? pendingStandardFallbackResult.total : "-"))
                }
                return
            }
            standardResult = payload.result
        } else if (payload.kind === "d100") {
            d100Result = payload.result
        } else if (payload.kind === "all") {
            d20Result = payload.result ? payload.result.d20 : null
            if (waitingStandardPhysicsResult && payload.mode !== "physics") {
                pendingStandardFallbackResult = payload.result ? payload.result.standard : null
                console.log("[dice-ui-debug] hold all.standard fallback mode=" + (payload.mode || "-")
                    + " total=" + (pendingStandardFallbackResult ? pendingStandardFallbackResult.total : "-"))
                return
            }
            standardResult = payload.result ? payload.result.standard : null
        }
    }
    function d20CritColor(value) {
        var v = Number(value || 0)
        if (v === 20) return "#F3BF42"
        if (v === 1) return "#8F2532"
        return textPrimary
    }

    function d20PairDieColor(entry, which) {
        if (!entry || entry.type !== "pair") {
            return textPrimary
        }
        var first = Number(entry.first || 0)
        var second = Number(entry.second || 0)
        var picked = Number(entry.picked || 0)
        var value = which === "first" ? first : second
        if (value !== picked) {
            return textPrimary
        }
        return d20CritColor(value)
    }

    function d20SingleDieColor(entry) {
        if (!entry || entry.type !== "single") {
            return textPrimary
        }
        return d20CritColor(Number(entry.value || 0))
    }

    function cloneStyle(style) {
        var legacyGlow = Number(style && style.textShadowIntensity !== undefined ? style.textShadowIntensity : 100)
        var glowRadius = Number(style && style.textGlowRadius !== undefined ? style.textGlowRadius : legacyGlow)
        var glowOpacity = Number(style && style.textGlowOpacity !== undefined ? style.textGlowOpacity : legacyGlow)
        return {
            "scalePercent": Number(style && style.scalePercent !== undefined ? style.scalePercent : 100),
            "color": String(style && style.color ? style.color : "#C9C9C9"),
            "gradientEnabled": Boolean(style && style.gradientEnabled),
            "gradientCenterColor": String(style && style.gradientCenterColor ? style.gradientCenterColor : "#FFFFFF"),
            "gradientSharpness": Number(style && style.gradientSharpness !== undefined ? style.gradientSharpness : 50),
            "gradientOffset": Number(style && style.gradientOffset !== undefined ? style.gradientOffset : 50),
            "fontColor": String(style && style.fontColor ? style.fontColor : "#1F1F1F"),
            "textStrokeColor": String(style && style.textStrokeColor ? style.textStrokeColor : "#EEEEEE"),
            "textGlowRadius": Math.max(0, Math.min(200, glowRadius)),
            "textGlowOpacity": Math.max(0, Math.min(200, glowOpacity)),
            "edgeColor": String(style && style.edgeColor ? style.edgeColor : "#D4D4D4"),
            "edgeWidth": Number(style && style.edgeWidth !== undefined ? style.edgeWidth : 0.0)
        }
    }
    function ensureDieStyle(key) {
        var k = String(key)
        var bag = dieStyles || {}
        if (!bag[k]) {
            bag[k] = cloneStyle(null)
            dieStyles = Object.assign({}, bag)
        }
        return bag[k]
    }

    function styleForDie(key) {
        return cloneStyle(ensureDieStyle(key))
    }

    function updateEditorField(field, value) {
        var next = cloneStyle(dieEditorWorking)
        next[field] = value
        dieEditorWorking = next
    }

    function saveDieEditor() {
        var key = String(dieEditorDieKey)
        var bag = Object.assign({}, dieStyles || {})
        bag[key] = cloneStyle(dieEditorWorking)
        dieStyles = bag
        dieStylePopup.close()
    }

    function resetDieEditorToDefaults() {
        dieEditorWorking = cloneStyle(null)
    }

    function clampNumber(value, minValue, maxValue) {
        var n = Number(value)
        if (!isFinite(n)) {
            n = Number(minValue)
        }
        return Math.max(Number(minValue), Math.min(Number(maxValue), n))
    }

    function roundToDecimals(value, decimals) {
        var d = Math.max(0, Number(decimals || 0))
        var p = Math.pow(10, d)
        return Math.round(Number(value) * p) / p
    }

    function clampAndRound(textValue, minValue, maxValue, decimals, fallbackValue) {
        var parsed = Number(String(textValue || "").replace(",", "."))
        if (!isFinite(parsed)) {
            parsed = Number(fallbackValue)
        }
        var clamped = clampNumber(parsed, minValue, maxValue)
        return roundToDecimals(clamped, decimals)
    }

    function formatSliderValue(value, decimals) {
        var d = Math.max(0, Number(decimals || 0))
        var n = Number(value)
        if (!isFinite(n)) {
            n = 0
        }
        if (d <= 0) {
            return String(Math.round(n))
        }
        return Number(n).toFixed(d)
    }

    function byteToHex(value) {
        var n = Math.max(0, Math.min(255, Math.round(Number(value) || 0)))
        var h = n.toString(16).toUpperCase()
        return h.length < 2 ? ("0" + h) : h
    }

    function rgbaToHex(r, g, b) {
        return "#" + byteToHex(r) + byteToHex(g) + byteToHex(b)
    }

    function parseColorInput(raw, fallbackColor) {
        var value = String(raw || "").trim()
        if (value.length <= 0 && fallbackColor !== undefined) {
            value = String(fallbackColor || "").trim()
        }

        var m = value.match(/^#([0-9a-fA-F]{3})$/)
        if (m) {
            var h3 = m[1]
            return {
                ok: true,
                r: parseInt(h3[0] + h3[0], 16),
                g: parseInt(h3[1] + h3[1], 16),
                b: parseInt(h3[2] + h3[2], 16),
                hex: "#" + (h3[0] + h3[0] + h3[1] + h3[1] + h3[2] + h3[2]).toUpperCase()
            }
        }

        m = value.match(/^#([0-9a-fA-F]{6})$/)
        if (m) {
            var h6 = m[1].toUpperCase()
            return {
                ok: true,
                r: parseInt(h6.slice(0, 2), 16),
                g: parseInt(h6.slice(2, 4), 16),
                b: parseInt(h6.slice(4, 6), 16),
                hex: "#" + h6
            }
        }

        m = value.match(/^#([0-9a-fA-F]{8})$/)
        if (m) {
            var h8 = m[1].toUpperCase()
            var rgb = h8.slice(2)
            return {
                ok: true,
                r: parseInt(rgb.slice(0, 2), 16),
                g: parseInt(rgb.slice(2, 4), 16),
                b: parseInt(rgb.slice(4, 6), 16),
                hex: "#" + rgb
            }
        }

        m = value.match(/^rgba?\(\s*([+-]?\d+(?:\.\d+)?)\s*,\s*([+-]?\d+(?:\.\d+)?)\s*,\s*([+-]?\d+(?:\.\d+)?)(?:\s*,\s*([+-]?\d*(?:\.\d+)?))?\s*\)$/i)
        if (m) {
            var rr = clampNumber(m[1], 0, 255)
            var gg = clampNumber(m[2], 0, 255)
            var bb = clampNumber(m[3], 0, 255)
            return {
                ok: true,
                r: Math.round(rr),
                g: Math.round(gg),
                b: Math.round(bb),
                hex: rgbaToHex(rr, gg, bb)
            }
        }

        if (fallbackColor !== undefined && String(value) !== String(fallbackColor)) {
            return parseColorInput(String(fallbackColor || "#FFFFFF"), "#FFFFFF")
        }

        return {
            ok: false,
            r: 255,
            g: 255,
            b: 255,
            hex: "#FFFFFF"
        }
    }

    function normalizePickerColor(raw, fallback) {
        return parseColorInput(raw, fallback || "#FFFFFF").hex
    }

    function rgbToHsv(r, g, b) {
        var rn = clampNumber(r, 0, 255) / 255.0
        var gn = clampNumber(g, 0, 255) / 255.0
        var bn = clampNumber(b, 0, 255) / 255.0
        var maxc = Math.max(rn, gn, bn)
        var minc = Math.min(rn, gn, bn)
        var d = maxc - minc
        var h = 0
        if (d > 1e-6) {
            if (maxc === rn) {
                h = 60 * (((gn - bn) / d) % 6)
            } else if (maxc === gn) {
                h = 60 * (((bn - rn) / d) + 2)
            } else {
                h = 60 * (((rn - gn) / d) + 4)
            }
        }
        if (h < 0) {
            h += 360
        }
        var s = maxc <= 1e-6 ? 0 : (d / maxc)
        var v = maxc
        return {
            h: Math.round(clampNumber(h, 0, 360)),
            s: Math.round(clampNumber(s * 100, 0, 100)),
            v: Math.round(clampNumber(v * 100, 0, 100))
        }
    }

    function hsvToRgb(h, s, v) {
        var hh = clampNumber(h, 0, 360)
        var ss = clampNumber(s, 0, 100) / 100.0
        var vv = clampNumber(v, 0, 100) / 100.0
        if (ss <= 1e-6) {
            var g = Math.round(vv * 255)
            return { r: g, g: g, b: g }
        }
        if (hh >= 360) {
            hh = 0
        }
        var c = vv * ss
        var x = c * (1 - Math.abs(((hh / 60) % 2) - 1))
        var m = vv - c
        var rp = 0
        var gp = 0
        var bp = 0
        if (hh < 60) {
            rp = c; gp = x; bp = 0
        } else if (hh < 120) {
            rp = x; gp = c; bp = 0
        } else if (hh < 180) {
            rp = 0; gp = c; bp = x
        } else if (hh < 240) {
            rp = 0; gp = x; bp = c
        } else if (hh < 300) {
            rp = x; gp = 0; bp = c
        } else {
            rp = c; gp = 0; bp = x
        }
        return {
            r: Math.round((rp + m) * 255),
            g: Math.round((gp + m) * 255),
            b: Math.round((bp + m) * 255)
        }
    }

    function refreshPickerColorFromHSV(syncText) {
        var rgb = hsvToRgb(pickerHue, pickerSaturation, pickerValue)
        var hex = rgbaToHex(rgb.r, rgb.g, rgb.b)
        pickerPreviewColor = hex
        if (syncText) {
            pickerHexText = hex
            if (pickerHexInput && !pickerHexInput.activeFocus) {
                pickerHexInput.text = hex
            }
        }
    }

    function setPickerFromColor(raw, fallbackColor) {
        var parsed = parseColorInput(raw, fallbackColor || "#FFFFFF")
        var hsv = rgbToHsv(parsed.r, parsed.g, parsed.b)
        pickerHue = hsv.h
        pickerSaturation = hsv.s
        pickerValue = hsv.v
        pickerCurrentColor = parsed.hex
        pickerHexText = parsed.hex
        pickerPreviewColor = parsed.hex
        if (pickerHexInput) {
            pickerHexInput.text = parsed.hex
        }
    }

    function applyPickerTypedColor() {
        var parsed = parseColorInput(pickerHexText, pickerPreviewColor)
        var hsv = rgbToHsv(parsed.r, parsed.g, parsed.b)
        pickerHue = hsv.h
        pickerSaturation = hsv.s
        pickerValue = hsv.v
        pickerHexText = parsed.hex
        pickerPreviewColor = parsed.hex
        if (pickerHexInput) {
            pickerHexInput.text = parsed.hex
        }
    }

    function openDieColorDialog(field, titleText, fallbackColor) {
        pendingColorField = String(field || "")
        pendingColorTitle = String(titleText || "Выбор цвета")
        var current = dieEditorWorking && pendingColorField.length > 0 ? dieEditorWorking[pendingColorField] : null
        setPickerFromColor(current, fallbackColor || "#FFFFFF")
        colorPickerPopup.open()
    }


    function openDieEditor(key) {
        dieEditorDieKey = String(key)
        dieEditorWorking = styleForDie(dieEditorDieKey)
        dieStylePopup.open()
    }

    function pushPreviewStyle() {
        if (!dieStylePopup || !dieStylePopup.visible) {
            return
        }
        if (!previewWeb || !previewWeb.visible || !previewWebReady) {
            return
        }

        var stylePayload = {
            "scalePercent": Number(dieEditorWorking.scalePercent !== undefined ? dieEditorWorking.scalePercent : 100),
            "faceColor": String(dieEditorWorking.color || "#C9C9C9"),
            "gradientEnabled": Boolean(dieEditorWorking.gradientEnabled),
            "gradientCenterColor": String(dieEditorWorking.gradientCenterColor || "#FFFFFF"),
            "gradientSharpness": Math.max(0, Math.min(1, Number(dieEditorWorking.gradientSharpness || 50) / 100.0)),
            "gradientOffset": Math.max(0, Math.min(1, Number(dieEditorWorking.gradientOffset || 50) / 100.0)),
            "textColor": String(dieEditorWorking.fontColor || "#1F1F1F"),
            "textStrokeColor": String(dieEditorWorking.textStrokeColor || "#EEEEEE"),
            "textGlowRadius": Math.max(0, Math.min(2, Number(dieEditorWorking.textGlowRadius !== undefined ? dieEditorWorking.textGlowRadius : 100) / 100.0)),
            "textGlowOpacity": Math.max(0, Math.min(2, Number(dieEditorWorking.textGlowOpacity !== undefined ? dieEditorWorking.textGlowOpacity : 100) / 100.0)),
            "edgeColor": String(dieEditorWorking.edgeColor || "#D4D4D4"),
            "edgeWidth": Number(dieEditorWorking.edgeWidth !== undefined ? dieEditorWorking.edgeWidth : 0.0)
        }
        previewWeb.runJavaScript("window.setStyleOverrides && window.setStyleOverrides(" + JSON.stringify(stylePayload) + ");")
        previewWeb.runJavaScript("window.setPreviewDieKind && window.setPreviewDieKind('" + String(dieEditorDieKey || "d6") + "');")
    }

    function startPreviewRollNow() {
        if (!previewWeb || !previewWeb.visible || !previewWebReady) {
            return
        }
        previewWeb.runJavaScript("window.startPreviewRoll && window.startPreviewRoll();")
    }


    onResetTokenChanged: resetState()
    onDieEditorWorkingChanged: pushPreviewStyle()
    onDieEditorDieKeyChanged: {
        pushPreviewStyle()
        startPreviewRollNow()
    }
    Component.onCompleted: resetState()

    Connections {
        target: diceController
        function onRollCompleted(payload) {
            diceWindow.handleRollCompleted(payload)
        }
    }


    component AppPanel: Rectangle {
        radius: 12
        color: panelColor
        border.color: panelBorder
        border.width: 1
    }


    component AppButton: AbstractButton {
        id: control
        property bool accent: false
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        activeFocusOnTab: false
        implicitHeight: 36
        font.pixelSize: 13

        contentItem: Text {
            text: control.text
            color: control.enabled
                ? (control.accent ? "#F7F7F8" : textPrimary)
                : "#8A8A8A"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: control.font.pixelSize
            font.weight: control.accent ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 12
            border.width: 1
            border.color: control.accent ? "#B4B4B4" : "#505050"
            opacity: control.enabled ? 1.0 : 0.5
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: control.accent
                        ? (control.pressed ? "#727272" : (control.hovered ? "#858585" : "#7D7D7D"))
                        : (control.pressed ? "#323232" : (control.hovered ? "#3B3B3B" : "#363636"))
                }
                GradientStop {
                    position: 1
                    color: control.accent
                        ? (control.pressed ? "#666666" : (control.hovered ? "#747474" : "#6E6E6E"))
                        : (control.pressed ? "#292929" : (control.hovered ? "#323232" : "#2D2D2D"))
                }
            }
            scale: control.pressed ? 0.97 : (control.hovered ? 1.025 : 1.0)

            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }
        }
    }

    component ModeArrowButton: AbstractButton {
        id: control
        property string arrowText: "?"
        property color activeColor: "#3F7A4A"
        property bool active: false
        implicitWidth: 26
        implicitHeight: 20
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        activeFocusOnTab: false

        contentItem: Text {
            text: control.arrowText
            color: "#F0F0F0"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }

        background: Rectangle {
            radius: 7
            border.width: 1
            border.color: control.active ? "#C4C4C4" : "#5B5B5B"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: control.active
                        ? Qt.lighter(control.activeColor, control.pressed ? 0.92 : (control.hovered ? 1.03 : 1.0))
                        : (control.pressed ? "#353535" : (control.hovered ? "#3D3D3D" : "#333333"))
                }
                GradientStop {
                    position: 1
                    color: control.active
                        ? Qt.darker(control.activeColor, control.pressed ? 1.15 : 1.05)
                        : (control.pressed ? "#2C2C2C" : (control.hovered ? "#343434" : "#2A2A2A"))
                }
            }
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }
    }

    component NumberInput: SpinBox {
        id: control
        editable: true
        from: 0
        to: 20
        stepSize: 1
        value: 0
        focusPolicy: Qt.NoFocus

        validator: RegularExpressionValidator { regularExpression: /[+-]?\d*/ }

        textFromValue: function(value, locale) {
            return Number(value).toLocaleString(locale, 'f', 0)
        }

        valueFromText: function(text, locale) {
            var n = Number.fromLocaleString(locale, text)
            if (!isFinite(n)) {
                n = Number(text)
            }
            if (!isFinite(n)) {
                return control.from
            }
            return Math.round(n)
        }

        contentItem: TextInput {
            text: control.textFromValue(control.value, control.locale)
            color: "#EFEFF2"
            selectionColor: "#6A6A6A"
            selectedTextColor: "#FFFFFF"
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            font.pixelSize: 13
            validator: control.validator
            readOnly: !control.editable
            onEditingFinished: {
                var parsed = control.valueFromText(text, control.locale)
                if (!isFinite(parsed)) {
                    parsed = control.from
                }
                var bounded = Math.max(control.from, Math.min(control.to, parsed))
                control.value = Math.round(bounded)
                text = control.textFromValue(control.value, control.locale)
            }
        }

        background: Rectangle {
            radius: 8
            color: "#1F1F1F"
            border.width: 1
            border.color: "#4C4C4C"
        }

        up.indicator: Rectangle {
            implicitWidth: 22
            implicitHeight: 16
            color: control.up.pressed ? "#535353" : (control.up.hovered ? "#484848" : "#3A3A3A")
            border.color: "#5A5A5A"
            Text {
                anchors.centerIn: parent
                text: "▲"
                color: "#E5E5E5"
                font.pixelSize: 9
            }
        }

        down.indicator: Rectangle {
            implicitWidth: 22
            implicitHeight: 16
            color: control.down.pressed ? "#535353" : (control.down.hovered ? "#484848" : "#3A3A3A")
            border.color: "#5A5A5A"
            Text {
                anchors.centerIn: parent
                text: "▼"
                color: "#E5E5E5"
                font.pixelSize: 9
            }
        }
    }

    component SliderNumberControl: RowLayout {
        id: control
        property real minValue: 0
        property real maxValue: 100
        property real step: 1
        property int decimals: 0
        property real value: 0
        signal valueCommitted(real value)

        Layout.fillWidth: true
        spacing: 8

        Slider {
            id: slider
            Layout.fillWidth: true
            from: control.minValue
            to: control.maxValue
            stepSize: control.step
            value: control.value
            onMoved: control.valueCommitted(value)
            onValueChanged: if (pressed) control.valueCommitted(value)
        }

        TextField {
            id: valueInput
            Layout.preferredWidth: 62
            selectByMouse: true
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            validator: RegularExpressionValidator { regularExpression: /[+-]?\d*(?:\.\d*)?/ }
            text: formatSliderValue(control.value, control.decimals)

            onEditingFinished: {
                var v = clampAndRound(text, control.minValue, control.maxValue, control.decimals, control.value)
                control.valueCommitted(v)
                text = formatSliderValue(v, control.decimals)
            }
        }

        onValueChanged: {
            if (!valueInput.activeFocus) {
                valueInput.text = formatSliderValue(control.value, control.decimals)
            }
        }
    }
    component DieGlyph: Item {
        id: glyph
        property string dieType: "d6"
        property string label: "d6"
        property color lineColor: "#E5E5E5"
        property color fillColor: "transparent"
        property color textColor: "#EFEFF2"
        property string labelFontFamily: "Segoe UI"
        property int labelFontWeight: Font.DemiBold
        property int labelPixelSize: 12
        property real lineWidth: 1.4
        property real valueOpacity: 1.0

        Behavior on valueOpacity {
            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
        }

        implicitWidth: 40
        implicitHeight: 40

        Canvas {
            id: canvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.clearRect(0, 0, width, height)
                ctx.globalAlpha = glyph.valueOpacity
                ctx.lineWidth = glyph.lineWidth
                ctx.strokeStyle = glyph.lineColor
                ctx.fillStyle = glyph.fillColor

                var w = width
                var h = height
                var cx = w * 0.5
                var cy = h * 0.5
                var pad = 3

                function polygon(points) {
                    if (points.length === 0) {
                        return
                    }
                    ctx.beginPath()
                    ctx.moveTo(points[0].x, points[0].y)
                    for (var i = 1; i < points.length; i++) {
                        ctx.lineTo(points[i].x, points[i].y)
                    }
                    ctx.closePath()
                    if (glyph.fillColor !== "transparent") {
                        ctx.fill()
                    }
                    ctx.stroke()
                }

                function regularPolygon(sides, radius, rotation) {
                    var points = []
                    for (var i = 0; i < sides; i++) {
                        var a = rotation + (Math.PI * 2 * i / sides)
                        points.push({"x": cx + Math.cos(a) * radius, "y": cy + Math.sin(a) * radius})
                    }
                    polygon(points)
                }

                if (glyph.dieType === "d4") {
                    polygon([
                        {"x": cx, "y": pad},
                        {"x": w - pad, "y": h - pad},
                        {"x": pad, "y": h - pad}
                    ])
                } else if (glyph.dieType === "d6") {
                    polygon([
                        {"x": pad, "y": pad},
                        {"x": w - pad, "y": pad},
                        {"x": w - pad, "y": h - pad},
                        {"x": pad, "y": h - pad}
                    ])
                } else if (glyph.dieType === "d8") {
                    polygon([
                        {"x": cx, "y": pad},
                        {"x": w - pad, "y": cy},
                        {"x": cx, "y": h - pad},
                        {"x": pad, "y": cy}
                    ])
                } else if (glyph.dieType === "d10") {
                    regularPolygon(4, Math.min(w, h) * 0.45, -Math.PI / 2)
                } else if (glyph.dieType === "d12") {
                    regularPolygon(10, Math.min(w, h) * 0.45, -Math.PI / 2)
                } else if (glyph.dieType === "d20") {
                    regularPolygon(6, Math.min(w, h) * 0.45, -Math.PI / 2)
                } else if (glyph.dieType === "d100") {
                    var backPad = 6
                    ctx.beginPath()
                    ctx.moveTo(cx + 4, backPad)
                    ctx.lineTo(w - backPad + 4, cy)
                    ctx.lineTo(cx + 4, h - backPad)
                    ctx.lineTo(backPad + 4, cy)
                    ctx.closePath()
                    ctx.stroke()
                    polygon([
                        {"x": cx, "y": pad},
                        {"x": w - pad, "y": cy},
                        {"x": cx, "y": h - pad},
                        {"x": pad, "y": cy}
                    ])
                } else {
                    polygon([
                        {"x": pad, "y": pad},
                        {"x": w - pad, "y": pad},
                        {"x": w - pad, "y": h - pad},
                        {"x": pad, "y": h - pad}
                    ])
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: glyph.label
            color: glyph.textColor
            font.family: glyph.labelFontFamily
            font.pixelSize: glyph.labelPixelSize
            font.weight: glyph.labelFontWeight
            opacity: glyph.valueOpacity
        }

        onDieTypeChanged: canvas.requestPaint()
        onFillColorChanged: canvas.requestPaint()
        onLineColorChanged: canvas.requestPaint()
        onLineWidthChanged: canvas.requestPaint()
        onValueOpacityChanged: canvas.requestPaint()
        onWidthChanged: canvas.requestPaint()
        onHeightChanged: canvas.requestPaint()
        Component.onCompleted: canvas.requestPaint()
    }

    component CountStepper: RowLayout {
        id: stepper
        property int from: 0
        property int to: 20
        property int value: 0

        function clamp(v) {
            return Math.max(from, Math.min(to, v))
        }

        spacing: 4

        Rectangle {
            implicitWidth: 20
            implicitHeight: 20
            radius: 6
            color: leftHit.pressed ? "#4D4D4D" : (leftHit.containsMouse ? "#444444" : "#3A3A3A")
            border.width: 1
            border.color: leftHit.pressed ? "#767676" : "#595959"

            Text {
                anchors.centerIn: parent
                text: "◀"
                color: "#E7E7EA"
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: leftHit
                anchors.fill: parent
                hoverEnabled: true
                onClicked: stepper.value = stepper.clamp(stepper.value - 1)
            }
        }

        Rectangle {
            implicitWidth: 28
            implicitHeight: 20
            radius: 5
            color: "#1F1F1F"
            border.color: "#4C4C4C"
            border.width: 1

            TextInput {
                id: stepperInput
                anchors.fill: parent
                anchors.margins: 1
                text: String(stepper.value)
                color: "#EFEFF2"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 11
                validator: RegularExpressionValidator { regularExpression: /[+-]?\d*/ }
                selectByMouse: true

                onEditingFinished: {
                    var n = parseInt(text)
                    if (isNaN(n)) {
                        n = stepper.from
                    }
                    stepper.value = stepper.clamp(n)
                }
            }
        }

        Rectangle {
            implicitWidth: 20
            implicitHeight: 20
            radius: 6
            color: rightHit.pressed ? "#4D4D4D" : (rightHit.containsMouse ? "#444444" : "#3A3A3A")
            border.width: 1
            border.color: rightHit.pressed ? "#767676" : "#595959"

            Text {
                anchors.centerIn: parent
                text: "▶"
                color: "#E7E7EA"
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: rightHit
                anchors.fill: parent
                hoverEnabled: true
                onClicked: stepper.value = stepper.clamp(stepper.value + 1)
            }
        }

        onValueChanged: {
            if (stepperInput.text !== String(stepper.value)) {
                stepperInput.text = String(stepper.value)
            }
        }
    }

    component StandardDieRow: RowLayout {
        id: root
        property int sides: 6
        property string dieKey: "d" + String(sides)
        property alias countValue: qty.value

        Layout.fillWidth: true
        spacing: 8

        DieGlyph {
            dieType: root.dieKey
            label: root.dieKey
            implicitWidth: 38
            implicitHeight: 38
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.sides === 4) rollSingleStandardDie(4, d4Count)
                    else if (root.sides === 6) rollSingleStandardDie(6, d6Count)
                    else if (root.sides === 8) rollSingleStandardDie(8, d8Count)
                    else if (root.sides === 10) rollSingleStandardDie(10, d10Count)
                    else if (root.sides === 12) rollSingleStandardDie(12, d12Count)
                }
            }
        }

        Label {
            text: "\u041a\u043e\u043b\u0438\u0447\u0435\u0441\u0442\u0432\u043e:"
            color: textSecondary
            font.pixelSize: 11
        }

        CountStepper {
            id: qty
            from: 0
            to: 20
            value: 0
        }


        AppButton {
            text: "🖌"
            implicitWidth: 26
            implicitHeight: 22
            onClicked: openDieEditor(root.dieKey)
        }

        Item { Layout.fillWidth: true }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true


            ColumnLayout {
                width: Math.max(220, diceWindow.width - 32)
                spacing: 8

                AppPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: resultsColumn.implicitHeight + 14
                    color: "#0F0F10"
                    border.color: "#2D2D2D"

                    ColumnLayout {
                        id: resultsColumn
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 7

                        Label {
                            text: "Результаты"
                            color: textPrimary
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        Item {
                            id: resultsViewport
                            Layout.fillWidth: true
                            Layout.minimumHeight: 85
                            Layout.preferredHeight: Math.max(85, resultsRow.implicitHeight)
                            clip: true

                            Rectangle {
                                anchors.fill: parent
                                visible: !(d20Result && d20Result.active) && !(standardResult && standardResult.active) && !(d100Result && d100Result.active)
                                radius: 9
                                color: "#0C0C0D"
                                border.width: 1
                                border.color: "#373737"
                                Text {
                                    anchors.centerIn: parent
                                    text: waitingStandardPhysicsResult
                                        ? "\u041e\u0436\u0438\u0434\u0430\u043d\u0438\u0435 \u0440\u0435\u0437\u0443\u043b\u044c\u0442\u0430\u0442\u043e\u0432..."
                                        : "\u0411\u0440\u043e\u0441\u043a\u043e\u0432 \u043f\u043e\u043a\u0430 \u043d\u0435\u0442"
                                    color: textSecondary
                                    font.pixelSize: 12
                                }
                            }

                            RowLayout {
                                id: resultsRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                visible: (d20Result && d20Result.active) || (standardResult && standardResult.active) || (d100Result && d100Result.active)
                                spacing: 8

                                AppPanel {
                                    visible: d20Result && d20Result.active
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: d20ResCol.implicitHeight + 10
                                    clip: true

                                    ColumnLayout {
                                        id: d20ResCol
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        spacing: 3
                                        Label { text: String(d20Result ? d20Result.formula : "") + ":"; color: textSecondary; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                        Label { text: d20Result ? String(d20Result.total) : ""; color: (d20Result && d20Result.rolls && d20Result.rolls.length === 1 && d20Result.rolls[0].type === "single") ? d20CritColor(Number(d20Result.rolls[0].value || 0)) : textPrimary; font.pixelSize: 20; font.weight: Font.Bold }
                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 3
                                            Repeater {
                                                model: d20Result ? d20Result.rolls : []
                                                delegate: Item {
                                                    width: modelData.type === "pair" ? 56 : 28
                                                    height: 28
                                                    Row {
                                                        anchors.fill: parent
                                                        spacing: 2
                                                        DieGlyph {
                                                            dieType: "d20"
                                                            label: modelData.type === "pair" ? String(modelData.first) : String(modelData.value)
                                                            implicitWidth: 27
                                                            implicitHeight: 27
                                                            valueOpacity: modelData.type === "pair" && modelData.first !== modelData.picked ? 0.35 : 1.0
                                                            textColor: modelData.type === "pair" ? d20PairDieColor(modelData, "first") : d20SingleDieColor(modelData)
                                                            lineColor: modelData.type === "pair" ? d20PairDieColor(modelData, "first") : d20SingleDieColor(modelData)
                                                        }
                                                        DieGlyph {
                                                            visible: modelData.type === "pair"
                                                            dieType: "d20"
                                                            label: modelData.type === "pair" ? String(modelData.second) : ""
                                                            implicitWidth: 27
                                                            implicitHeight: 27
                                                            valueOpacity: modelData.type === "pair" && modelData.second !== modelData.picked ? 0.35 : 1.0
                                                            textColor: d20PairDieColor(modelData, "second")
                                                            lineColor: d20PairDieColor(modelData, "second")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                AppPanel {
                                    visible: standardResult && standardResult.active
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: stdResCol.implicitHeight + 10
                                    clip: true

                                    ColumnLayout {
                                        id: stdResCol
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        spacing: 3
                                        Label { text: String(standardResult ? standardResult.formula : "") + ":"; color: textSecondary; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                        Label { text: standardResult ? String(standardResult.total) : ""; color: textPrimary; font.pixelSize: 20; font.weight: Font.Bold }
                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 3
                                            Repeater {
                                                model: standardResult ? standardResult.rolls : []
                                                delegate: DieGlyph {
                                                    dieType: "d" + String(modelData.sides)
                                                    label: String(modelData.value)
                                                    implicitWidth: 26
                                                    implicitHeight: 26
                                                }
                                            }
                                        }
                                    }
                                }

                                AppPanel {
                                    visible: d100Result && d100Result.active
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: d100ResCol.implicitHeight + 10
                                    clip: true

                                    ColumnLayout {
                                        id: d100ResCol
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        spacing: 3
                                        DieGlyph {
                                            dieType: "d100"
                                            label: d100Result ? String(d100Result.total) : ""
                                            implicitWidth: 34
                                            implicitHeight: 34
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        Label {
                                            text: d100Result ? String(d100Result.total) : ""
                                            color: textPrimary
                                            font.pixelSize: 19
                                            font.weight: Font.Bold
                                            horizontalAlignment: Text.AlignHCenter
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                AppPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: d20Column.implicitHeight + 14

                    ColumnLayout {
                        id: d20Column
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            DieGlyph {
                                dieType: "d20"
                                label: "d20"
                                implicitWidth: 46
                                implicitHeight: 46
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rollD20Only()
                                }
                            }

                            ColumnLayout {
                                spacing: 4
                                ModeArrowButton {
                                    arrowText: "\u25B2"
                                    active: d20Mode === "advantage"
                                    activeColor: "#2F8B4B"
                                    onClicked: setD20Mode("advantage")
                                }
                                ModeArrowButton {
                                    arrowText: "\u25BC"
                                    active: d20Mode === "disadvantage"
                                    activeColor: "#A33C3C"
                                    onClicked: setD20Mode("disadvantage")
                                }
                            }

                            Label { text: "\u041a\u043e\u043b\u0438\u0447\u0435\u0441\u0442\u0432\u043e:"; color: textSecondary; font.pixelSize: 11 }
                            CountStepper {
                                from: 0
                                to: 20
                                value: d20Count
                                onValueChanged: d20Count = value
                            }


                            AppButton {
                                text: "🖌"
                                implicitWidth: 26
                                implicitHeight: 22
                                onClicked: openDieEditor("d20")
                            }

                            Label { text: "\u0411\u043e\u043d\u0443\u0441:"; color: textSecondary; font.pixelSize: 11 }
                            CountStepper {
                                from: -20
                                to: 20
                                value: d20Bonus
                                onValueChanged: d20Bonus = value
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                AppPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: standardColumn.implicitHeight + 14

                    ColumnLayout {
                        id: standardColumn
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        StandardDieRow { sides: 4; countValue: d4Count; onCountValueChanged: d4Count = countValue }
                        StandardDieRow { sides: 6; countValue: d6Count; onCountValueChanged: d6Count = countValue }
                        StandardDieRow { sides: 8; countValue: d8Count; onCountValueChanged: d8Count = countValue }
                        StandardDieRow { sides: 10; countValue: d10Count; onCountValueChanged: d10Count = countValue }
                        StandardDieRow { sides: 12; countValue: d12Count; onCountValueChanged: d12Count = countValue }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Label { text: "\u0411\u043e\u043d\u0443\u0441:"; color: textSecondary; font.pixelSize: 11 }
                            CountStepper {
                                from: -20
                                to: 20
                                value: standardBonus
                                onValueChanged: standardBonus = value
                            }
                            Item { Layout.fillWidth: true }
                        }

                        AppButton {
                            Layout.fillWidth: true
                            text: "\u0411\u0440\u043e\u0441\u0438\u0442\u044c D4-D12"
                            enabled: canRollStandard()
                            onClicked: rollStandardOnly()
                        }
                    }
                }

                AppPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        DieGlyph {
                            dieType: "d100"
                            label: "d100"
                            implicitWidth: 42
                            implicitHeight: 42
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rollD100Only()
                            }
                        }

                        AppButton {
                            Layout.fillWidth: true
                            text: "\u0411\u0440\u043e\u0441\u0438\u0442\u044c D100"
                            onClicked: rollD100Only()
                        }
                    }
                }
            }
        }

        AppButton {
            Layout.fillWidth: true
            text: "Бросить все"
            accent: true
            enabled: canRollAll()
            onClicked: rollAll()
        }
    }


    Timer {
        id: physicsFallbackTimer
        interval: 2300
        repeat: false
        onTriggered: {
            if (waitingStandardPhysicsResult && pendingStandardFallbackResult) {
                waitingStandardPhysicsResult = false
                standardResult = pendingStandardFallbackResult
                pendingStandardFallbackResult = null
                console.log("[dice-ui-debug] fallback timer committed result total=" + (standardResult ? standardResult.total : "-"))
            } else {
                console.log("[dice-ui-debug] fallback timer fired without pending result")
            }
        }
    }

    Popup {
        id: dieStylePopup
        modal: true
        focus: true
        width: Math.min(460, diceWindow.width - 24)
        height: Math.min(760, diceWindow.height - 24)
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        anchors.centerIn: Overlay.overlay
        padding: 0

        background: Rectangle {
            radius: 12
            color: "#1E1E1F"
            border.width: 1
            border.color: "#4D4D4D"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Label {
                Layout.fillWidth: true
                text: "Кастомизация " + dieEditorDieKey
                color: textPrimary
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                radius: 10
                color: "#121214"
                border.width: 1
                border.color: "#353535"
                clip: true

                Item {
                    id: previewStage
                    anchors.fill: parent

                    WebEngineView {
                        id: previewWeb
                        anchors.fill: parent
                        visible: dieStylePopup.visible
                        enabled: visible
                        backgroundColor: "#121214"
                        url: Qt.resolvedUrl("../web/dice_physics.html")
                        onLoadingChanged: function(req) {
                            if (req.status === WebEngineView.LoadFailedStatus) {
                                previewWebReady = false
                                return
                            }
                            if (req.status === WebEngineView.LoadSucceededStatus) {
                                previewWebReady = true
                                diceWindow.pushPreviewStyle()
                                diceWindow.startPreviewRollNow()
                            }
                        }
                        onVisibleChanged: {
                            if (visible) {
                                diceWindow.pushPreviewStyle()
                                diceWindow.startPreviewRollNow()
                            }
                        }
                        onJavaScriptConsoleMessage: function(level, message, lineNumber, sourceID) {
                            console.log("[dice-preview-web]", String(message), String(sourceID) + ":" + String(lineNumber))
                        }
                    }

                    Timer {
                        id: previewRollTimer
                        interval: 3200
                        repeat: true
                        running: false
                        onTriggered: diceWindow.startPreviewRollNow()
                    }
                }
            }
            Label { text: "Размер (50%..150%)"; color: textSecondary; font.pixelSize: 11 }
            SliderNumberControl {
                minValue: 50
                maxValue: 150
                step: 1
                decimals: 0
                value: Number(dieEditorWorking.scalePercent || 100)
                onValueCommitted: updateEditorField("scalePercent", Math.round(value))
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Label { text: "Цвет граней"; color: textSecondary; font.pixelSize: 11 }
                Rectangle {
                    implicitWidth: 40
                    implicitHeight: 20
                    radius: 6
                    color: dieEditorWorking.color
                    border.width: 1
                    border.color: "#666666"
                }
                AppButton {
                    text: "🎨"
                    implicitWidth: 32
                    implicitHeight: 24
                    onClicked: openDieColorDialog("color", "Выбор цвета граней", "#C9C9C9")
                }
                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Label { text: "Градиент"; color: textSecondary; font.pixelSize: 11 }
                Switch {
                    checked: Boolean(dieEditorWorking.gradientEnabled)
                    onToggled: updateEditorField("gradientEnabled", checked)
                }
                Item { Layout.fillWidth: true }
            }

            RowLayout {
                visible: Boolean(dieEditorWorking.gradientEnabled)
                Layout.fillWidth: true
                spacing: 8
                Label { text: "Цвет центра"; color: textSecondary; font.pixelSize: 11 }
                Rectangle {
                    implicitWidth: 40
                    implicitHeight: 20
                    radius: 6
                    color: dieEditorWorking.gradientCenterColor
                    border.width: 1
                    border.color: "#666666"
                }
                AppButton {
                    text: "🎨"
                    implicitWidth: 32
                    implicitHeight: 24
                    onClicked: openDieColorDialog("gradientCenterColor", "Выбор цвета центра градиента", "#FFFFFF")
                }
                Item { Layout.fillWidth: true }
            }
            Label {
                visible: Boolean(dieEditorWorking.gradientEnabled)
                text: "Резкость/плавность градиента"
                color: textSecondary
                font.pixelSize: 11
            }
            SliderNumberControl {
                visible: Boolean(dieEditorWorking.gradientEnabled)
                minValue: 0
                maxValue: 100
                step: 1
                decimals: 0
                value: Number(dieEditorWorking.gradientSharpness || 50)
                onValueCommitted: updateEditorField("gradientSharpness", Math.round(value))
            }

            Label {
                visible: Boolean(dieEditorWorking.gradientEnabled)
                text: "Смещение градиента"
                color: textSecondary
                font.pixelSize: 11
            }
            SliderNumberControl {
                visible: Boolean(dieEditorWorking.gradientEnabled)
                minValue: 0
                maxValue: 100
                step: 1
                decimals: 0
                value: Number(dieEditorWorking.gradientOffset || 50)
                onValueCommitted: updateEditorField("gradientOffset", Math.round(value))
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Label { text: "Цвет текста"; color: textSecondary; font.pixelSize: 11 }
                Rectangle {
                    implicitWidth: 40
                    implicitHeight: 20
                    radius: 6
                    color: dieEditorWorking.fontColor
                    border.width: 1
                    border.color: "#666666"
                }
                AppButton {
                    text: "🎨"
                    implicitWidth: 32
                    implicitHeight: 24
                    onClicked: openDieColorDialog("fontColor", "Выбор цвета шрифта", "#1F1F1F")
                }
                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Label { text: "Цвет свечения текста"; color: textSecondary; font.pixelSize: 11 }
                Rectangle {
                    implicitWidth: 40
                    implicitHeight: 20
                    radius: 6
                    color: dieEditorWorking.textStrokeColor
                    border.width: 1
                    border.color: "#666666"
                }
                AppButton {
                    text: "🎨"
                    implicitWidth: 32
                    implicitHeight: 24
                    onClicked: openDieColorDialog("textStrokeColor", "Выбор цвета свечения текста", "#EEEEEE")
                }
                Item { Layout.fillWidth: true }
            }
            Label { text: "Glow radius"; color: textSecondary; font.pixelSize: 11 }
            SliderNumberControl {
                minValue: 0
                maxValue: 200
                step: 1
                decimals: 0
                value: Number(dieEditorWorking.textGlowRadius !== undefined ? dieEditorWorking.textGlowRadius : 100)
                onValueCommitted: updateEditorField("textGlowRadius", Math.round(value))
            }
            Label { text: "Glow opacity"; color: textSecondary; font.pixelSize: 11 }
            SliderNumberControl {
                minValue: 0
                maxValue: 200
                step: 1
                decimals: 0
                value: Number(dieEditorWorking.textGlowOpacity !== undefined ? dieEditorWorking.textGlowOpacity : 100)
                onValueCommitted: updateEditorField("textGlowOpacity", Math.round(value))
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Label { text: "Цвет ребер"; color: textSecondary; font.pixelSize: 11 }
                Rectangle {
                    implicitWidth: 40
                    implicitHeight: 20
                    radius: 6
                    color: dieEditorWorking.edgeColor
                    border.width: 1
                    border.color: "#666666"
                }
                AppButton {
                    text: "🎨"
                    implicitWidth: 32
                    implicitHeight: 24
                    onClicked: openDieColorDialog("edgeColor", "Выбор цвета ребер", "#D4D4D4")
                }
                Item { Layout.fillWidth: true }
            }

            Label { text: "Толщина ребер"; color: textSecondary; font.pixelSize: 11 }
            SliderNumberControl {
                minValue: 0
                maxValue: 5
                step: 0.1
                decimals: 1
                value: Number(dieEditorWorking.edgeWidth !== undefined ? dieEditorWorking.edgeWidth : 0.0)
                onValueCommitted: updateEditorField("edgeWidth", roundToDecimals(value, 1))
            }
            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                AppButton { Layout.fillWidth: true; text: "Отмена"; onClicked: dieStylePopup.close() }
                AppButton { Layout.fillWidth: true; text: "По умолчанию"; onClicked: resetDieEditorToDefaults() }
                AppButton { Layout.fillWidth: true; text: "Сохранить"; accent: true; onClicked: saveDieEditor() }
            }
        }
    }
    Popup {
        id: colorPickerPopup
        modal: true
        focus: true
        width: Math.min(420, diceWindow.width - 24)
        height: 430
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        anchors.centerIn: Overlay.overlay
        padding: 0

        background: Rectangle {
            radius: 12
            color: "#1E1E1F"
            border.width: 1
            border.color: "#4D4D4D"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Label {
                Layout.fillWidth: true
                text: pendingColorTitle
                color: textPrimary
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 8
                    color: pickerCurrentColor
                    border.width: 1
                    border.color: "#666666"
                    Label {
                        anchors.centerIn: parent
                        text: "Текущий"
                        color: "#202020"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 8
                    color: pickerPreviewColor
                    border.width: 1
                    border.color: "#666666"
                    Label {
                        anchors.centerIn: parent
                        text: "Новый"
                        color: "#202020"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }

            Label { text: "Тон"; color: textSecondary; font.pixelSize: 11 }
            SliderNumberControl {
                minValue: 0
                maxValue: 360
                step: 1
                decimals: 0
                value: pickerHue
                onValueCommitted: {
                    pickerHue = Math.round(value)
                    refreshPickerColorFromHSV(true)
                }
            }

            Label { text: "Насыщенность"; color: textSecondary; font.pixelSize: 11 }
            SliderNumberControl {
                minValue: 0
                maxValue: 100
                step: 1
                decimals: 0
                value: pickerSaturation
                onValueCommitted: {
                    pickerSaturation = Math.round(value)
                    refreshPickerColorFromHSV(true)
                }
            }

            Label { text: "Яркость"; color: textSecondary; font.pixelSize: 11 }
            SliderNumberControl {
                minValue: 0
                maxValue: 100
                step: 1
                decimals: 0
                value: pickerValue
                onValueCommitted: {
                    pickerValue = Math.round(value)
                    refreshPickerColorFromHSV(true)
                }
            }

            Label { text: "Код цвета (HEX / RGB(A))"; color: textSecondary; font.pixelSize: 11 }
            TextField {
                id: pickerHexInput
                Layout.fillWidth: true
                text: pickerHexText
                placeholderText: "#RRGGBB или rgb(255,255,255)"
                selectByMouse: true
                onTextEdited: pickerHexText = text
                onEditingFinished: {
                    pickerHexText = text
                    applyPickerTypedColor()
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                AppButton {
                    Layout.fillWidth: true
                    text: "Отмена"
                    onClicked: colorPickerPopup.close()
                }
                AppButton {
                    Layout.fillWidth: true
                    text: "Применить"
                    accent: true
                    onClicked: {
                        if (pendingColorField && pendingColorField.length > 0) {
                            updateEditorField(pendingColorField, pickerPreviewColor)
                        }
                        colorPickerPopup.close()
                    }
                }
            }
        }
    }
}


