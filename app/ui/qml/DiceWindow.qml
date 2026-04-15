import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine
import "components"
import "components/DicePreviewUtils.js" as DicePreviewUtils
import "components/neumo"
Window {
    id: diceWindow
    objectName: "diceWindow"
    width: 340
    height: 670
    visible: true
    color: neumoTheme ? neumoTheme.baseColor : "#2D2D2D"
    title: "DnD Maps - Дайсы"
    TapHandler {
        id: windowTapClearDiceVisuals
        acceptedButtons: Qt.AllButtons
        onTapped: diceController.request_clear_dice_visuals()
    }
    HoverHandler {
        id: windowHoverTracker
        enabled: !diceWindow.useLiveMainDicePreview
        onPointChanged: {
            var hoveredTile = diceWindow.mainPreviewTileAt(point.position.x, point.position.y)
            if (hoveredTile) {
                if (diceWindow.mainPreviewHoverTile !== hoveredTile) {
                    diceWindow.activateMainPreviewHover(hoveredTile)
                } else {
                    diceWindow.syncMainPreviewHoverGeometry()
                }
            } else if (diceWindow.mainPreviewHoverTile) {
                diceWindow.deactivateMainPreviewHover(diceWindow.mainPreviewHoverTile)
            }
        }
        onHoveredChanged: {
            if (!hovered && diceWindow.mainPreviewHoverTile) {
                diceWindow.deactivateMainPreviewHover(diceWindow.mainPreviewHoverTile)
            }
        }
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
    property int rollVisibilityMode: 1
    property var d20Result: null
    property var standardResult: null
    property var d100Result: null
    property bool waitingStandardPhysicsResult: false
    property var pendingStandardFallbackResult: null
    property color textPrimary: "#EFEFF2"
    property color textSecondary: "#B0B0B0"
    property color panelColor: "#242424"
    property color panelBorder: "#4A4A4A"
    property var neumoTheme: NeumoTheme {
        baseColor: "#2D2D2D"
        textPrimary: diceWindow.textPrimary
        textSecondary: diceWindow.textSecondary
    }
    readonly property bool narrowLayout: width < 500
    readonly property int sectionGutter: narrowLayout ? 6 : 8
    readonly property int sectionSpacing: narrowLayout ? 10 : 12
    readonly property int cardRadius: narrowLayout ? 16 : 18
    readonly property int cardPadding: narrowLayout ? 10 : 12
    readonly property int editorFrameRadius: 28
    readonly property int editorFramePadding: 18
    readonly property int editorSectionOuterGutter: narrowLayout ? 6 : 9
    readonly property int resultsCardPadding: narrowLayout ? 14 : 16
    readonly property real cardShadowOffset: narrowLayout ? 3.5 : 4.4
    readonly property real cardShadowRadius: narrowLayout ? 8.0 : 9.4
    readonly property int cardShadowSamples: 23
    readonly property int innerCardRadius: 12
    readonly property int innerCardPadding: 6
    readonly property real innerShadowOffset: 2.4
    readonly property real innerShadowRadius: 5.6
    readonly property int innerShadowSamples: 17
    readonly property color innerShadowDarkColor: Qt.rgba(neumoTheme.shadowDarkBase.r, neumoTheme.shadowDarkBase.g, neumoTheme.shadowDarkBase.b, 0.55)
    readonly property color innerShadowLightColor: Qt.rgba(neumoTheme.shadowLightBase.r, neumoTheme.shadowLightBase.g, neumoTheme.shadowLightBase.b, 0.22)
    readonly property int standardLabelWidth: narrowLayout ? 78 : 86
    readonly property int standardStepperWidth: narrowLayout ? 90 : 102
    readonly property int d20LabelWidth: standardLabelWidth
    readonly property int d20StepperWidth: narrowLayout ? 90 : 102
    readonly property int ghostIconSize: 26
    readonly property int actionButtonHeight: narrowLayout ? 48 : 52
    readonly property int standardPreviewSize: narrowLayout ? 40 : 42
    readonly property int d100ActionWidth: standardPreviewSize + ghostIconSize + 28
    readonly property color resultsFillColor: Qt.rgba(30 / 255, 30 / 255, 30 / 255, 1.0)
    readonly property color resultsInsetDarkColor: {
        if (!neumoTheme) {
            return Qt.rgba(0, 0, 0, 0.9)
        }
        var deltaR = neumoTheme.baseColor.r - neumoTheme.shadowDarkBase.r
        var deltaG = neumoTheme.baseColor.g - neumoTheme.shadowDarkBase.g
        var deltaB = neumoTheme.baseColor.b - neumoTheme.shadowDarkBase.b
        var r = Math.max(0, resultsFillColor.r - deltaR)
        var g = Math.max(0, resultsFillColor.g - deltaG)
        var b = Math.max(0, resultsFillColor.b - deltaB)
        return Qt.rgba(r, g, b, neumoTheme.insetDarkAlpha / 1.2)
    }
    readonly property color resultsInsetLightColor: {
        if (!neumoTheme) {
            return Qt.rgba(59 / 255, 60 / 255, 64 / 255, 0.4)
        }
        return Qt.rgba(
            neumoTheme.shadowLightBase.r,
            neumoTheme.shadowLightBase.g,
            neumoTheme.shadowLightBase.b,
            neumoTheme.insetLightAlpha / 1.6)
    }
    property var dieStyles: ({})
    property var dieStyleTemplates: ({"user": [], "damage": []})
    property var damageTemplateIconNames: ([
        "weapon.svg",
        "fire.svg",
        "sound.svg",
        "radiant.svg",
        "necrotic.svg",
        "psychic.svg",
        "force.svg",
        "cold.svg",
        "acid.svg",
        "poison.svg"
    ])
    property string damageTemplateIconsBaseUrl: Qt.resolvedUrl("../../../app_data/icons/")
    property var templateSnapshotCache: ({})
    property var templateSnapshotQueue: ([])
    property bool templateSnapshotBusy: false
    property bool templateSnapshotWebReady: false
    property var templateSnapshotCurrentTask: null
    property bool useLiveMainDicePreview: true
    property bool mainPreviewHoverWebReady: false
    property var mainPreviewHoverTile: null
    property string mainPreviewHoverDieType: ""
    property real mainPreviewHoverX: -1000
    property real mainPreviewHoverY: -1000
    property real mainPreviewHoverWidth: 1
    property real mainPreviewHoverHeight: 1
    property var mainPreviewTiles: []
    property int mainPreviewPoseVersion: 22
    readonly property real mainPreviewReferenceSize: 96
    readonly property var mainPreviewDieTypes: (["d4", "d6", "d8", "d10", "d12", "d100", "d20"])
    property var damageTemplateLabels: ([
        "Оружие",
        "Огонь",
        "Звук",
        "Излучение",
        "Некротический",
        "Психический",
        "Силовое поле",
        "Холод",
        "Кислота",
        "Яд"
    ])
    property string templateContextRow: "user"
    property int templateContextIndex: -1
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
    property string diceViewMode: "main"
    readonly property bool styleEditorActive: diceViewMode === "styleEditor"
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

    function cycleRollVisibilityMode() {
        rollVisibilityMode = (rollVisibilityMode + 1) % 3
    }

    function rollVisibilityIconSource() {
        if (rollVisibilityMode === 0) {
            return Qt.resolvedUrl("icons/eye_closed.svg")
        }
        if (rollVisibilityMode === 1) {
            return Qt.resolvedUrl("icons/eye_open.svg")
        }
        return Qt.resolvedUrl("icons/window_mode.svg")
    }

    function rollVisibilityToolTipText() {
        if (rollVisibilityMode === 0) {
            return "Закрытый бросок"
        }
        if (rollVisibilityMode === 1) {
            return "Открытый бросок"
        }
        return "Бросок в отдельном окне"
    }

    function metricWidth(metric) {
        return Math.ceil(metric ? (metric.advanceWidth || 0) : 0)
    }

    function resultGlyphUnitWidths(cardType, result) {
        var widths = []
        if (!result || !result.rolls || result.rolls.length <= 0) {
            return widths
        }
        for (var i = 0; i < result.rolls.length; ++i) {
            if (cardType === "d20") {
                widths.push(result.rolls[i].type === "pair" ? 56 : 28)
            } else if (cardType === "standard") {
                widths.push(26)
            }
        }
        return widths
    }

    function resultVisualItemCount(cardType, result) {
        return resultGlyphUnitWidths(cardType, result).length
    }

    function resultGlyphSpacing(cardType) {
        return 3
    }

    function resultCardMinWidth(cardType) {
        if (cardType === "standard") {
            return d20ResultMinWidth()
        }
        if (cardType === "d20") {
            return narrowLayout ? 46 : 50
        }
        return narrowLayout ? 78 : 86
    }

    function resultCardChromeWidth(cardType) {
        return innerCardPadding * 2 + 4
    }

    function resultCardTextWidth(cardType) {
        if (cardType === "d20") {
            return Math.max(metricWidth(d20FormulaMetrics), metricWidth(d20TotalMetrics))
        }
        if (cardType === "standard") {
            return Math.max(metricWidth(standardFormulaMetrics), metricWidth(standardTotalMetrics))
        }
        return 0
    }

    function resultGlyphRowWidth(cardType, itemsPerRow, result) {
        var unitWidths = resultGlyphUnitWidths(cardType, result)
        if (unitWidths.length <= 0) {
            return 0
        }
        var perRow = Math.max(1, itemsPerRow)
        var spacing = resultGlyphSpacing(cardType)
        var maxWidth = 0
        for (var start = 0; start < unitWidths.length; start += perRow) {
            var rowWidth = 0
            var end = Math.min(start + perRow, unitWidths.length)
            for (var i = start; i < end; ++i) {
                if (i > start) {
                    rowWidth += spacing
                }
                rowWidth += unitWidths[i]
            }
            maxWidth = Math.max(maxWidth, rowWidth)
        }
        return maxWidth
    }

    function resultCardMinWidthForRows(cardType, result, rowCount) {
        var visualItemCount = resultVisualItemCount(cardType, result)
        var targetRows = Math.max(1, rowCount)
        var itemsPerRow = visualItemCount > 0 ? Math.ceil(visualItemCount / targetRows) : 1
        var glyphWidth = resultGlyphRowWidth(cardType, itemsPerRow, result)
        var contentWidth = Math.max(resultCardTextWidth(cardType), glyphWidth)
        return Math.max(resultCardMinWidth(cardType), contentWidth + resultCardChromeWidth(cardType))
    }

    function d20ResultMinWidth() {
        return narrowLayout ? 46 : 50
    }

    function standardResultMinWidth() {
        return d20ResultMinWidth()
    }

    function d100ResultCardWidth() {
        return narrowLayout ? 78 : 86
    }

    function resultCardWidths() {
        var d20Active = d20Result && d20Result.active
        var standardActive = standardResult && standardResult.active
        var d100Active = d100Result && d100Result.active
        var activeCount = 0
        if (d20Active) {
            activeCount += 1
        }
        if (standardActive) {
            activeCount += 1
        }
        if (d100Active) {
            activeCount += 1
        }

        var widths = {
            d20: d20Active ? resultCardMinWidthForRows("d20", d20Result, 1) : 0,
            standard: standardActive ? resultCardMinWidthForRows("standard", standardResult, 1) : 0,
            d100: d100Active ? d100ResultCardWidth() : 0
        }

        var availableWidth = resultsViewport ? resultsViewport.width : 0
        if (availableWidth <= 0) {
            return widths
        }

        var spacingWidth = Math.max(0, activeCount - 1) * resultsRow.spacing
        var flexibleAvailableWidth = availableWidth - spacingWidth - widths.d100
        var flexibleCards = []
        if (d20Active) {
            flexibleCards.push({ key: "d20", result: d20Result })
        }
        if (standardActive) {
            flexibleCards.push({ key: "standard", result: standardResult })
        }

        if (flexibleCards.length <= 0) {
            return widths
        }

        if (flexibleCards.length === 1) {
            var singleCard = flexibleCards[0]
            widths[singleCard.key] = Math.max(resultCardMinWidthForRows(singleCard.key, singleCard.result, 1), flexibleAvailableWidth)
            return widths
        }

        var maxGlyphRows = 1
        for (var cardIndex = 0; cardIndex < flexibleCards.length; ++cardIndex) {
            maxGlyphRows = Math.max(maxGlyphRows, resultVisualItemCount(flexibleCards[cardIndex].key, flexibleCards[cardIndex].result))
        }

        var targetRows = maxGlyphRows
        for (var rowCount = 1; rowCount <= maxGlyphRows; ++rowCount) {
            var requiredWidth = 0
            for (var widthIndex = 0; widthIndex < flexibleCards.length; ++widthIndex) {
                var card = flexibleCards[widthIndex]
                requiredWidth += resultCardMinWidthForRows(card.key, card.result, rowCount)
            }
            if (requiredWidth <= flexibleAvailableWidth) {
                targetRows = rowCount
                break
            }
        }

        var flexibleBaseWidth = 0
        for (var baseIndex = 0; baseIndex < flexibleCards.length; ++baseIndex) {
            var baseCard = flexibleCards[baseIndex]
            widths[baseCard.key] = resultCardMinWidthForRows(baseCard.key, baseCard.result, targetRows)
            flexibleBaseWidth += widths[baseCard.key]
        }

        if (flexibleAvailableWidth > flexibleBaseWidth && flexibleBaseWidth > 0) {
            var extraWidth = flexibleAvailableWidth - flexibleBaseWidth
            var distributedWidth = 0
            for (var growIndex = 0; growIndex < flexibleCards.length; ++growIndex) {
                var growCard = flexibleCards[growIndex]
                if (growIndex === flexibleCards.length - 1) {
                    widths[growCard.key] += extraWidth - distributedWidth
                } else {
                    var growShare = Math.round(extraWidth * (widths[growCard.key] / flexibleBaseWidth))
                    widths[growCard.key] += growShare
                    distributedWidth += growShare
                }
            }
        }

        return widths
    }

    function d20ResultCardWidth() {
        return resultCardWidths().d20
    }

    function standardResultCardWidth() {
        return resultCardWidths().standard
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
        var hasD20 = d20Count > 0
        var hasStandard = canRollStandard()
        clearResults()
        waitingStandardPhysicsResult = hasStandard
            && isPhysicsStandardRequest(d4Count, d6Count, d8Count, d10Count, d12Count)
            && diceController.is_map_window_open()
        console.log("[dice-ui-debug] rollAll split requests=" + (hasD20 || hasStandard)
            + " d20=" + d20Count + " mode=" + d20Mode + " d20Bonus=" + d20Bonus
            + " standard(d4/d6/d8/d10/d12)=" + d4Count + "/" + d6Count + "/" + d8Count + "/" + d10Count + "/" + d12Count
            + " stdBonus=" + standardBonus + " waitingStandard=" + waitingStandardPhysicsResult)
        if (waitingStandardPhysicsResult) {
            physicsFallbackTimer.restart()
        }
        if (hasD20) {
            diceController.request_roll_d20(effectiveCount(d20Count), d20Mode, d20Bonus)
        }
        if (hasStandard) {
            diceController.request_roll_standard(d4Count, d6Count, d8Count, d10Count, d12Count, standardBonus)
        }
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
        return DicePreviewUtils.cloneStyle(style)
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
    function loadDieStylesFromSettings() {
        var source = {}
        if (typeof appController !== "undefined" && appController && appController.diceStyles) {
            source = appController.diceStyles
        }
        var keys = ["d4", "d6", "d8", "d10", "d12", "d20", "d100"]
        var bag = {}
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i]
            bag[key] = cloneStyle(source && source[key] ? source[key] : null)
        }
        dieStyles = bag
    }
    function defaultDamageTemplateStyles() {
        return [
            { "scalePercent": 100, "color": "#C8C8C8", "gradientEnabled": true, "gradientCenterColor": "#F3F3F3", "gradientSharpness": 58, "gradientOffset": 50, "fontColor": "#1F2228", "textStrokeColor": "#F0F3FA", "textGlowRadius": 90, "textGlowOpacity": 85, "edgeColor": "#7A7E86", "edgeWidth": 1.2 },
            { "scalePercent": 100, "color": "#D35A28", "gradientEnabled": true, "gradientCenterColor": "#FFD08C", "gradientSharpness": 64, "gradientOffset": 52, "fontColor": "#2A140C", "textStrokeColor": "#FFE3A8", "textGlowRadius": 110, "textGlowOpacity": 105, "edgeColor": "#7A2315", "edgeWidth": 1.4 },
            { "scalePercent": 100, "color": "#5F6CE0", "gradientEnabled": true, "gradientCenterColor": "#C7D0FF", "gradientSharpness": 56, "gradientOffset": 50, "fontColor": "#151933", "textStrokeColor": "#D9E2FF", "textGlowRadius": 108, "textGlowOpacity": 96, "edgeColor": "#2E356E", "edgeWidth": 1.2 },
            { "scalePercent": 100, "color": "#E4CE63", "gradientEnabled": true, "gradientCenterColor": "#FFF7BE", "gradientSharpness": 62, "gradientOffset": 48, "fontColor": "#2A240F", "textStrokeColor": "#FFF4B0", "textGlowRadius": 116, "textGlowOpacity": 108, "edgeColor": "#8B7422", "edgeWidth": 1.3 },
            { "scalePercent": 100, "color": "#5C4A6A", "gradientEnabled": true, "gradientCenterColor": "#A296B8", "gradientSharpness": 60, "gradientOffset": 53, "fontColor": "#F0EAF8", "textStrokeColor": "#2B1F36", "textGlowRadius": 92, "textGlowOpacity": 78, "edgeColor": "#2D2236", "edgeWidth": 1.3 },
            { "scalePercent": 100, "color": "#8A5FD6", "gradientEnabled": true, "gradientCenterColor": "#E1CCFF", "gradientSharpness": 57, "gradientOffset": 50, "fontColor": "#26173A", "textStrokeColor": "#F0E3FF", "textGlowRadius": 122, "textGlowOpacity": 110, "edgeColor": "#4B2F7B", "edgeWidth": 1.2 },
            { "scalePercent": 100, "color": "#4D8DF0", "gradientEnabled": true, "gradientCenterColor": "#D8EBFF", "gradientSharpness": 58, "gradientOffset": 50, "fontColor": "#12243D", "textStrokeColor": "#E4F1FF", "textGlowRadius": 114, "textGlowOpacity": 102, "edgeColor": "#224D83", "edgeWidth": 1.3 },
            { "scalePercent": 100, "color": "#8CCEF1", "gradientEnabled": true, "gradientCenterColor": "#E8F9FF", "gradientSharpness": 54, "gradientOffset": 48, "fontColor": "#163147", "textStrokeColor": "#F6FDFF", "textGlowRadius": 126, "textGlowOpacity": 116, "edgeColor": "#FFFFFF", "edgeWidth": 1.6 },
            { "scalePercent": 100, "color": "#6FAF2C", "gradientEnabled": true, "gradientCenterColor": "#D8FF8A", "gradientSharpness": 63, "gradientOffset": 53, "fontColor": "#1A2D0D", "textStrokeColor": "#EDFFC8", "textGlowRadius": 118, "textGlowOpacity": 104, "edgeColor": "#2D5F15", "edgeWidth": 1.3 },
            { "scalePercent": 100, "color": "#4A7A44", "gradientEnabled": true, "gradientCenterColor": "#98D08E", "gradientSharpness": 58, "gradientOffset": 52, "fontColor": "#102012", "textStrokeColor": "#D0F0C8", "textGlowRadius": 104, "textGlowOpacity": 94, "edgeColor": "#20391F", "edgeWidth": 1.2 }
        ]
    }
    function cloneTemplateBag(payload) {
        var source = payload && typeof payload === "object" ? payload : {}
        var sourceUser = source.user && source.user.length ? source.user : []
        var sourceDamage = source.damage && source.damage.length ? source.damage : []
        var defaultDamage = defaultDamageTemplateStyles()
        var user = []
        var damage = []
        for (var i = 0; i < 10; i++) {
            var u = i < sourceUser.length ? sourceUser[i] : null
            if (u && typeof u === "object") {
                user.push(cloneStyle(u))
            } else {
                user.push(null)
            }
            var d = i < sourceDamage.length ? sourceDamage[i] : defaultDamage[i]
            if (d && typeof d === "object") {
                damage.push(cloneStyle(d))
            } else {
                damage.push(cloneStyle(defaultDamage[i]))
            }
        }
        return {"user": user, "damage": damage}
    }
    function loadDieStyleTemplatesFromSettings() {
        var source = {}
        if (typeof appController !== "undefined" && appController && appController.diceStyleTemplates) {
            source = appController.diceStyleTemplates
        }
        dieStyleTemplates = cloneTemplateBag(source)
    }
    function persistDieStyleTemplates() {
        if (typeof appController !== "undefined" && appController && appController.update_dice_style_templates) {
            appController.update_dice_style_templates(cloneTemplateBag(dieStyleTemplates))
        }
    }
    function templateSlotList(rowKey) {
        var bag = cloneTemplateBag(dieStyleTemplates)
        return rowKey === "damage" ? bag.damage : bag.user
    }
    function templateStyle(rowKey, index) {
        var list = templateSlotList(rowKey)
        if (index < 0 || index >= list.length) {
            return null
        }
        var item = list[index]
        if (!item || typeof item !== "object") {
            return null
        }
        return item
    }
    function hasTemplateStyle(rowKey, index) {
        return templateStyle(rowKey, index) !== null
    }
    function applyTemplateSlot(rowKey, index) {
        var style = templateStyle(rowKey, index)
        if (!style) {
            return
        }
        dieEditorWorking = cloneStyle(style)
    }
    function saveCurrentStyleToTemplateQueue() {
        var next = cloneTemplateBag(dieStyleTemplates)
        for (var i = 9; i > 0; i--) {
            next.user[i] = next.user[i - 1] ? cloneStyle(next.user[i - 1]) : null
        }
        next.user[0] = cloneStyle(dieEditorWorking)
        dieStyleTemplates = next
        persistDieStyleTemplates()
        refreshTemplateSnapshots("user", true)
    }
    function openTemplateContextMenu(rowKey, index, x, y) {
        if (!hasTemplateStyle(rowKey, index)) {
            return
        }
        templateContextRow = String(rowKey || "user")
        templateContextIndex = Number(index)
        templateSlotContextMenu.popup(x, y)
    }
    function overwriteTemplateContextSlot() {
        if (templateContextIndex < 0 || !hasTemplateStyle(templateContextRow, templateContextIndex)) {
            return
        }
        var next = cloneTemplateBag(dieStyleTemplates)
        var row = templateContextRow === "damage" ? "damage" : "user"
        next[row][templateContextIndex] = cloneStyle(dieEditorWorking)
        dieStyleTemplates = next
        persistDieStyleTemplates()
        enqueueTemplateSnapshot(row, templateContextIndex, true)
    }
    function deleteTemplateContextSlot() {
        if (templateContextRow !== "user" || templateContextIndex < 0) {
            return
        }
        if (!hasTemplateStyle("user", templateContextIndex)) {
            return
        }
        var next = cloneTemplateBag(dieStyleTemplates)
        for (var i = templateContextIndex; i < 9; i++) {
            next.user[i] = next.user[i + 1] ? cloneStyle(next.user[i + 1]) : null
        }
        next.user[9] = null
        dieStyleTemplates = next
        persistDieStyleTemplates()
        refreshTemplateSnapshots("user", true)
    }
    function previewLabelForDieType(dieType) {
        var key = String(dieType || "d6").toLowerCase()
        if (key === "d100") return "00"
        if (key === "d20") return "20"
        if (key === "d12") return "12"
        if (key === "d10") return "10"
        if (key === "d8") return "8"
        if (key === "d6") return "6"
        if (key === "d4") return "4"
        return "6"
    }
    function templateSlotSizeForWidth(availableWidth) {
        var gap = 8
        var width = Math.max(0, Number(availableWidth || 0))
        if (width <= 0) {
            return 32
        }
        var s = Math.floor((width - gap * 4) / 5)
        return Math.max(32, s)
    }
    function previewKindForDieType(dieType) {
        var key = String(dieType || "d6").toLowerCase()
        return key === "d100" ? "d10t" : key
    }
    function styleToWebPayload(styleObj) {
        return DicePreviewUtils.styleToWebPayload(styleObj)
    }
    function styleToTemplateSnapshotPayload(styleObj) {
        return DicePreviewUtils.styleToTemplateSnapshotPayload(styleObj)
    }
    function styleToMainPreviewPayload(styleObj, dieType) {
        return DicePreviewUtils.styleToMainPreviewPayload(styleObj, dieType)
    }
    function resolveMainPreviewSpec(dieType, styleOverride) {
        var style = styleOverride && typeof styleOverride === "object" ? cloneStyle(styleOverride) : styleForDie(dieType)
        return DicePreviewUtils.resolveMainPreviewSpec(dieType, style)
    }
    function mainPreviewSnapshotKey(dieType, styleObj) {
        return DicePreviewUtils.buildMainPreviewSnapshotKey(dieType, styleObj, mainPreviewPoseVersion)
    }
    function mainPreviewSnapshotSource(dieType) {
        return diceMainPreviewCache ? diceMainPreviewCache.snapshotSourceForDie(dieType) : ""
    }
    function refreshMainPreviewSnapshots(forceRender) {
        if (!diceMainPreviewCache) {
            return
        }
        if (forceRender) {
            diceMainPreviewCache.prewarmAll()
            return
        }
        for (var i = 0; i < mainPreviewDieTypes.length; ++i) {
            diceMainPreviewCache.ensureSnapshotForDie(mainPreviewDieTypes[i])
        }
    }
    function runPreviewScene(webView, renderVariant, presentation, kind, payload, startRoll) {
        if (!webView) {
            return
        }
        var script = "(function(){"
        script += "if(window.setPreviewRenderVariant){window.setPreviewRenderVariant(" + JSON.stringify(String(renderVariant || "default")) + ");}"
        script += "if(window.setPreviewPresentationMode){window.setPreviewPresentationMode(" + JSON.stringify(String(presentation || "roll")) + ");}"
        script += "if(window.setStyleOverrides){window.setStyleOverrides(" + JSON.stringify(payload || {}) + ");}"
        script += "if(window.setPreviewDieKind){window.setPreviewDieKind(" + JSON.stringify(String(kind || "d6")) + ");}"
        if (startRoll) {
            script += "if(window.startPreviewRoll){window.startPreviewRoll();}"
        }
        script += "})();"
        webView.runJavaScript(script)
    }
    function isPointerInsideTile(tile, sceneX, sceneY) {
        if (!tile || !diceWindow.contentItem) {
            return false
        }
        var p = diceWindow.contentItem.mapToItem(tile, sceneX, sceneY)
        return p.x >= 0 && p.y >= 0 && p.x <= tile.width && p.y <= tile.height
    }
    function registerMainPreviewTile(tile) {
        if (!tile || !tile.useInset) {
            return
        }
        var next = []
        var found = false
        for (var i = 0; i < mainPreviewTiles.length; ++i) {
            var current = mainPreviewTiles[i]
            if (!current) {
                continue
            }
            if (current === tile) {
                found = true
            }
            next.push(current)
        }
        if (!found) {
            next.push(tile)
        }
        mainPreviewTiles = next
    }
    function unregisterMainPreviewTile(tile) {
        if (!tile) {
            return
        }
        var next = []
        for (var i = 0; i < mainPreviewTiles.length; ++i) {
            var current = mainPreviewTiles[i]
            if (current && current !== tile) {
                next.push(current)
            }
        }
        mainPreviewTiles = next
        if (mainPreviewHoverTile === tile) {
            deactivateMainPreviewHover(tile)
        }
    }
    function mainPreviewTileAt(sceneX, sceneY) {
        for (var i = mainPreviewTiles.length - 1; i >= 0; --i) {
            var tile = mainPreviewTiles[i]
            if (tile && tile.visible && tile.enabled && isPointerInsideTile(tile, sceneX, sceneY)) {
                return tile
            }
        }
        return null
    }
    function syncMainPreviewHoverGeometry() {
        if (!mainPreviewHoverTile || !mainPreviewOverlayHost) {
            return
        }
        var margin = Number(mainPreviewHoverTile.previewMargin || 0)
        var p = mainPreviewHoverTile.mapToItem(mainPreviewOverlayHost, margin, margin)
        mainPreviewHoverX = p.x
        mainPreviewHoverY = p.y
        mainPreviewHoverWidth = Math.max(1, mainPreviewHoverTile.width - margin * 2)
        mainPreviewHoverHeight = Math.max(1, mainPreviewHoverTile.height - margin * 2)
    }
    function startMainPreviewHoverNow() {
        if (!mainPreviewHoverTile || !mainPreviewHoverWebReady || !mainPreviewHoverWeb) {
            return
        }
        syncMainPreviewHoverGeometry()
        var spec = resolveMainPreviewSpec(mainPreviewHoverDieType)
        runPreviewScene(mainPreviewHoverWeb, "main", "idle", mainPreviewHoverDieType, spec.payload, true)
    }
    function activateMainPreviewHover(tile) {
        if (!tile || !tile.enabled) {
            return
        }
        mainPreviewHoverTile = tile
        mainPreviewHoverDieType = String(tile.dieType || "d6")
        syncMainPreviewHoverGeometry()
        startMainPreviewHoverNow()
    }
    function deactivateMainPreviewHover(tile) {
        if (tile && mainPreviewHoverTile !== tile) {
            return
        }
        if (mainPreviewHoverWeb) {
            mainPreviewHoverWeb.runJavaScript("window.clearAllDice && window.clearAllDice();")
        }
        mainPreviewHoverTile = null
        mainPreviewHoverDieType = ""
        mainPreviewHoverX = -1000
        mainPreviewHoverY = -1000
    }
    function templateStyleHash(styleObj) {
        var s = cloneStyle(styleObj)
        return [
            Number(s.scalePercent || 100).toFixed(3),
            String(s.color || "#C9C9C9"),
            s.gradientEnabled ? "1" : "0",
            String(s.gradientCenterColor || "#FFFFFF"),
            Number(s.gradientSharpness || 50).toFixed(3),
            Number(s.gradientOffset || 50).toFixed(3),
            String(s.fontColor || "#1F1F1F"),
            String(s.textStrokeColor || "#EEEEEE"),
            Number(s.textGlowRadius !== undefined ? s.textGlowRadius : 100).toFixed(3),
            Number(s.textGlowOpacity !== undefined ? s.textGlowOpacity : 100).toFixed(3),
            String(s.edgeColor || "#D4D4D4"),
            Number(s.edgeWidth !== undefined ? s.edgeWidth : 0.0).toFixed(3)
        ].join("|")
    }
    function templateSnapshotKey(dieType, rowKey, index, styleObj) {
        return String(dieType || "d6") + "::" + String(rowKey || "user") + "::" + Number(index) + "::" + templateStyleHash(styleObj)
    }
    function templateSnapshotSource(rowKey, index) {
        var style = templateStyle(rowKey, index)
        if (!style) {
            return ""
        }
        var key = templateSnapshotKey(dieEditorDieKey, rowKey, index, style)
        var cache = templateSnapshotCache || {}
        return cache[key] ? String(cache[key]) : ""
    }
    function resolveDamageIconSource(index) {
        var i = Number(index)
        if (!isFinite(i) || i < 0 || i >= damageTemplateIconNames.length) {
            return ""
        }
        var base = String(damageTemplateIconsBaseUrl || "")
        if (base.length <= 0) {
            return ""
        }
        if (base[base.length - 1] !== "/") {
            base += "/"
        }
        return base + encodeURIComponent(String(damageTemplateIconNames[i]))
    }
    function enqueueTemplateSnapshot(rowKey, index, forceRender) {
        var style = templateStyle(rowKey, index)
        if (!style) {
            return
        }
        var key = templateSnapshotKey(dieEditorDieKey, rowKey, index, style)
        var cache = templateSnapshotCache || {}
        if (!forceRender && cache[key]) {
            return
        }
        if (templateSnapshotBusy && templateSnapshotCurrentTask && templateSnapshotCurrentTask.key === key) {
            return
        }
        var q = templateSnapshotQueue ? templateSnapshotQueue.slice(0) : []
        for (var i = 0; i < q.length; i++) {
            if (q[i] && q[i].key === key) {
                return
            }
        }
        q.push({
            "key": key,
            "rowKey": String(rowKey),
            "index": Number(index),
            "dieType": String(dieEditorDieKey || "d6"),
            "previewKind": previewKindForDieType(dieEditorDieKey),
            "payload": styleToTemplateSnapshotPayload(style)
        })
        templateSnapshotQueue = q
        processTemplateSnapshotQueue()
    }
    function refreshTemplateSnapshots(rowKey, forceRender) {
        var row = String(rowKey || "")
        if (row !== "user" && row !== "damage") {
            return
        }
        for (var i = 0; i < 10; i++) {
            enqueueTemplateSnapshot(row, i, Boolean(forceRender))
        }
    }
    function refreshAllTemplateSnapshots(forceRender) {
        refreshTemplateSnapshots("user", forceRender)
        refreshTemplateSnapshots("damage", forceRender)
    }
    function clearTemplateSnapshotQueue() {
        templateSnapshotQueue = []
        templateSnapshotBusy = false
        templateSnapshotCurrentTask = null
        templateSnapshotCaptureTimer.stop()
    }
    function processTemplateSnapshotQueue() {
        if (!styleEditorActive) {
            return
        }
        if (!templateSnapshotWebReady || templateSnapshotBusy) {
            return
        }
        var q = templateSnapshotQueue ? templateSnapshotQueue.slice(0) : []
        if (q.length <= 0) {
            return
        }
        var task = q.shift()
        templateSnapshotQueue = q
        templateSnapshotCurrentTask = task
        templateSnapshotBusy = true
        if (!templateSnapshotWeb) {
            templateSnapshotBusy = false
            templateSnapshotCurrentTask = null
            return
        }
        runPreviewScene(templateSnapshotWeb, "default", "static", task.previewKind, task.payload, true)
        templateSnapshotCaptureTimer.restart()
    }
    function handleTemplateSnapshotCaptured(result) {
        var task = templateSnapshotCurrentTask
        if (task && result && result.url) {
            var cache = Object.assign({}, templateSnapshotCache || {})
            cache[task.key] = result.url
            templateSnapshotCache = cache
        }
        templateSnapshotBusy = false
        templateSnapshotCurrentTask = null
        processTemplateSnapshotQueue()
    }
    function captureTemplateSnapshotCurrentTask() {
        if (!templateSnapshotBusy || !templateSnapshotCurrentTask || !templateSnapshotWeb) {
            return
        }
        templateSnapshotWeb.grabToImage(function(result) {
            diceWindow.handleTemplateSnapshotCaptured(result)
        })
    }
    function updateEditorField(field, value) {
        var next = cloneStyle(dieEditorWorking)
        next[field] = value
        dieEditorWorking = next
    }
    function saveDieEditor() {
        var key = String(dieEditorDieKey)
        var savedStyle = cloneStyle(dieEditorWorking)
        var bag = Object.assign({}, dieStyles || {})
        bag[key] = savedStyle
        dieStyles = bag
        if (diceMainPreviewCache) {
            diceMainPreviewCache.invalidateDie(key)
        }
        if (typeof appController !== "undefined" && appController && appController.update_dice_style) {
            appController.update_dice_style(key, savedStyle)
        }
        if (mainPreviewHoverTile && mainPreviewHoverDieType === key) {
            startMainPreviewHoverNow()
        }
        if (colorPickerPopup.visible) {
            colorPickerPopup.close()
        }
        diceViewMode = "main"
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
        diceViewMode = "styleEditor"
    }
    function closeDieEditor() {
        if (colorPickerPopup.visible) {
            colorPickerPopup.close()
        }
        diceViewMode = "main"
    }
    function pushPreviewStyle() {
        if (!styleEditorActive) {
            return
        }
        if (!previewWeb || !previewWeb.visible || !previewWebReady) {
            return
        }
        var stylePayload = styleToWebPayload(dieEditorWorking)
        var previewKind = previewKindForDieType(dieEditorDieKey)
        runPreviewScene(previewWeb, "default", "roll", previewKind, stylePayload, false)
    }
    function startPreviewRollNow() {
        if (!previewWeb || !previewWeb.visible || !previewWebReady) {
            return
        }
        var previewKind = previewKindForDieType(dieEditorDieKey)
        runPreviewScene(previewWeb, "default", "roll", previewKind, styleToWebPayload(dieEditorWorking), true)
    }
    onResetTokenChanged: resetState()
    onDieEditorWorkingChanged: pushPreviewStyle()
    onDieEditorDieKeyChanged: {
        pushPreviewStyle()
        startPreviewRollNow()
        if (styleEditorActive) {
            refreshAllTemplateSnapshots(true)
        }
    }
    onStyleEditorActiveChanged: {
        if (styleEditorActive) {
            pushPreviewStyle()
            startPreviewRollNow()
            refreshAllTemplateSnapshots(false)
            processTemplateSnapshotQueue()
            return
        }
        clearTemplateSnapshotQueue()
        templateSlotContextMenu.close()
        if (colorPickerPopup.visible) {
            colorPickerPopup.close()
        }
    }
    Component.onCompleted: {
        resetState()
        loadDieStylesFromSettings()
        loadDieStyleTemplatesFromSettings()
        if (!useLiveMainDicePreview && diceMainPreviewCache) {
            diceMainPreviewCache.prewarmAll()
        }
    }
    Connections {
        target: appController
        function onSettingsChanged() {
            if (!styleEditorActive) {
                loadDieStylesFromSettings()
                loadDieStyleTemplatesFromSettings()
                if (!useLiveMainDicePreview && diceMainPreviewCache) {
                    diceMainPreviewCache.prewarmAll()
                }
            }
        }
    }
    Connections {
        target: diceController
        function onRollCompleted(payload) {
            diceWindow.handleRollCompleted(payload)
        }
    }
    DiceMainPreviewCacheManager {
        id: diceMainPreviewCache
        dieStyles: diceWindow.dieStyles
        dieTypes: diceWindow.mainPreviewDieTypes
        poseVersion: diceWindow.mainPreviewPoseVersion
        cacheDirUrl: Qt.resolvedUrl("../../../app_data/cache/dice_main_preview/")
        renderingEnabled: false
        prewarmEnabled: false
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
            Layout.minimumWidth: 0
            Layout.preferredWidth: 10
            implicitHeight: 30
            from: control.minValue
            to: control.maxValue
            stepSize: control.step
            value: control.value
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0
            hoverEnabled: true

            onMoved: control.valueCommitted(value)
            onValueChanged: if (pressed) control.valueCommitted(value)

            background: Item {
                x: slider.leftPadding
                y: slider.topPadding + (slider.availableHeight - height) / 2
                width: slider.availableWidth
                height: 26

                NeumoInsetSurface {
                    id: sliderTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 12
                    theme: neumoTheme
                    radius: 6
                    fillColor: neumoTheme ? neumoTheme.fieldInlineFillColor : "#252525"
                    contentPadding: 0
                    insetDarkColor: neumoTheme
                        ? Qt.rgba(neumoTheme.shadowDarkBase.r, neumoTheme.shadowDarkBase.g, neumoTheme.shadowDarkBase.b, 0.92)
                        : "#D6151618"
                    insetLightColor: neumoTheme
                        ? Qt.rgba(neumoTheme.shadowLightBase.r, neumoTheme.shadowLightBase.g, neumoTheme.shadowLightBase.b, 0.44)
                        : "#553B3C40"
                }

                Rectangle {
                    anchors.left: sliderTrack.left
                    anchors.verticalCenter: sliderTrack.verticalCenter
                    width: Math.max(height, slider.visualPosition * sliderTrack.width)
                    height: Math.max(4, sliderTrack.height - 4)
                    radius: height / 2
                    color: Qt.rgba(
                        neumoTheme ? neumoTheme.textPrimary.r : 0.94,
                        neumoTheme ? neumoTheme.textPrimary.g : 0.94,
                        neumoTheme ? neumoTheme.textPrimary.b : 0.94,
                        slider.pressed ? 0.22 : 0.14)
                }
            }

            handle: Item {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + (slider.availableHeight - height) / 2
                width: 22
                height: 22

                NeumoRaisedSurface {
                    anchors.fill: parent
                    theme: neumoTheme
                    radius: width / 2
                    fillColor: neumoTheme ? neumoTheme.baseColor : "#2D2D2D"
                    shadowOffset: slider.pressed ? 2.1 : (slider.hovered ? 3.6 : 2.8)
                    shadowRadius: slider.pressed ? 4.6 : (slider.hovered ? 7.4 : 5.8)
                    shadowSamples: 17
                    shadowDarkColor: slider.hovered
                        ? (neumoTheme ? neumoTheme.raisedShadowDarkColorHover : "#FC151618")
                        : (neumoTheme ? neumoTheme.raisedShadowDarkColor : "#B8151618")
                    shadowLightColor: slider.hovered
                        ? (neumoTheme ? neumoTheme.raisedShadowLightColorHover : "#AD55565C")
                        : (neumoTheme ? neumoTheme.raisedShadowLightColor : "#703B3C40")
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: width / 2
                    color: Qt.rgba(1, 1, 1, slider.hovered ? 0.12 : 0.08)
                }
            }
        }

        NeumoStepperField {
            theme: neumoTheme
            from: control.minValue
            to: control.maxValue
            stepSize: control.step
            decimals: control.decimals
            value: control.value
            compactMode: true
            visualStyle: "launcherInline"
            Layout.minimumWidth: 70
            Layout.preferredWidth: 70
            Layout.maximumWidth: 70
            Layout.alignment: Qt.AlignVCenter
            onValueModified: control.valueCommitted(value)
        }
    }
    component EditorSectionLabel: Label {
        color: textPrimary
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }
    component EditorFieldLabel: Label {
        color: textSecondary
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
    component ColorFieldButton: NeumoRaisedActionButton {
        id: button
        property color swatchColor: "#FFFFFF"
        property string labelText: ""
        compactMode: true
        radius: 12
        contentPadding: 4
        implicitWidth: 108
        implicitHeight: 34

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 7
                color: button.swatchColor
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.18)
            }

            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: button.labelText.length > 0 ? button.labelText : String(button.swatchColor).toUpperCase()
                color: textPrimary
                font.pixelSize: 11
                font.weight: Font.Medium
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
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
    component TemplateStylePreview: Item {
        id: preview
        property string dieType: "d6"
        property var styleData: ({})
        property string labelText: diceWindow.previewLabelForDieType(dieType)
        Canvas {
            id: templateCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.clearRect(0, 0, width, height)
                var w = width
                var h = height
                var cx = w * 0.5
                var cy = h * 0.5
                var pad = Math.max(2, Math.round(Math.min(w, h) * 0.08))
                var style = preview.styleData || {}
                var faceColor = String(style.color || "#C9C9C9")
                var centerColor = String(style.gradientCenterColor || "#FFFFFF")
                var gradientEnabled = Boolean(style.gradientEnabled)
                var sharpness = Math.max(0, Math.min(100, Number(style.gradientSharpness !== undefined ? style.gradientSharpness : 50)))
                var offset = Math.max(0, Math.min(100, Number(style.gradientOffset !== undefined ? style.gradientOffset : 50)))
                var textColor = String(style.fontColor || "#1F1F1F")
                var glowColor = String(style.textStrokeColor || "#EEEEEE")
                var glowRadius = Math.max(0, Math.min(200, Number(style.textGlowRadius !== undefined ? style.textGlowRadius : 100)))
                var glowOpacity = Math.max(0, Math.min(200, Number(style.textGlowOpacity !== undefined ? style.textGlowOpacity : 100)))
                var edgeColor = String(style.edgeColor || "#D4D4D4")
                var edgeWidth = Math.max(0, Math.min(5, Number(style.edgeWidth !== undefined ? style.edgeWidth : 0)))
                function hexToRgb(hex) {
                    var s = String(hex || "").trim()
                    var m3 = /^#([0-9a-fA-F]{3})$/.exec(s)
                    if (m3) {
                        return {
                            r: parseInt(m3[1][0] + m3[1][0], 16),
                            g: parseInt(m3[1][1] + m3[1][1], 16),
                            b: parseInt(m3[1][2] + m3[1][2], 16)
                        }
                    }
                    var m6 = /^#([0-9a-fA-F]{6})$/.exec(s)
                    if (m6) {
                        return {
                            r: parseInt(m6[1].slice(0, 2), 16),
                            g: parseInt(m6[1].slice(2, 4), 16),
                            b: parseInt(m6[1].slice(4, 6), 16)
                        }
                    }
                    return { r: 255, g: 255, b: 255 }
                }
                function rgba(hex, alpha) {
                    var rgb = hexToRgb(hex)
                    var a = Math.max(0, Math.min(1, Number(alpha || 0)))
                    return "rgba(" + rgb.r + "," + rgb.g + "," + rgb.b + "," + a.toFixed(3) + ")"
                }
                function shapePoints(kind) {
                    var t = String(kind || "d6").toLowerCase()
                    if (t === "d4") {
                        return [{x: cx, y: pad}, {x: w - pad, y: h - pad}, {x: pad, y: h - pad}]
                    }
                    if (t === "d6") {
                        return [{x: pad, y: pad}, {x: w - pad, y: pad}, {x: w - pad, y: h - pad}, {x: pad, y: h - pad}]
                    }
                    if (t === "d8") {
                        return [{x: cx, y: pad}, {x: w - pad, y: cy}, {x: cx, y: h - pad}, {x: pad, y: cy}]
                    }
                    if (t === "d10" || t === "d100") {
                        return [{x: cx, y: pad}, {x: w - pad, y: cy}, {x: cx, y: h - pad}, {x: pad, y: cy}]
                    }
                    if (t === "d12") {
                        var p12 = []
                        var r12 = Math.min(w, h) * 0.43
                        for (var i = 0; i < 10; i++) {
                            var a12 = -Math.PI / 2 + (Math.PI * 2 * i / 10)
                            p12.push({x: cx + Math.cos(a12) * r12, y: cy + Math.sin(a12) * r12})
                        }
                        return p12
                    }
                    if (t === "d20") {
                        var p20 = []
                        var r20 = Math.min(w, h) * 0.43
                        for (var j = 0; j < 6; j++) {
                            var a20 = -Math.PI / 2 + (Math.PI * 2 * j / 6)
                            p20.push({x: cx + Math.cos(a20) * r20, y: cy + Math.sin(a20) * r20})
                        }
                        return p20
                    }
                    return [{x: pad, y: pad}, {x: w - pad, y: pad}, {x: w - pad, y: h - pad}, {x: pad, y: h - pad}]
                }
                function drawPolygon(points) {
                    if (!points || points.length === 0) {
                        return
                    }
                    ctx.beginPath()
                    ctx.moveTo(points[0].x, points[0].y)
                    for (var i = 1; i < points.length; i++) {
                        ctx.lineTo(points[i].x, points[i].y)
                    }
                    ctx.closePath()
                    if (gradientEnabled) {
                        var rad = Math.max(6, Math.min(w, h) * (0.26 + offset * 0.0048))
                        var grd = ctx.createRadialGradient(cx, cy, 0, cx, cy, rad)
                        var stop = Math.max(0.05, Math.min(0.95, 0.20 + (100 - sharpness) * 0.0055))
                        grd.addColorStop(0, centerColor)
                        grd.addColorStop(stop, centerColor)
                        grd.addColorStop(1, faceColor)
                        ctx.fillStyle = grd
                    } else {
                        ctx.fillStyle = faceColor
                    }
                    ctx.fill()
                    if (edgeWidth > 0.01) {
                        ctx.lineWidth = Math.max(0.6, edgeWidth * 0.85)
                        ctx.strokeStyle = edgeColor
                        ctx.stroke()
                    }
                }
                if (String(preview.dieType || "") === "d100") {
                    var backPad = Math.max(3, pad + 1)
                    ctx.beginPath()
                    ctx.moveTo(cx + 2, backPad)
                    ctx.lineTo(w - backPad + 2, cy)
                    ctx.lineTo(cx + 2, h - backPad)
                    ctx.lineTo(backPad + 2, cy)
                    ctx.closePath()
                    ctx.lineWidth = Math.max(0.6, edgeWidth * 0.7)
                    ctx.strokeStyle = edgeColor
                    ctx.stroke()
                }
                drawPolygon(shapePoints(preview.dieType))
                var glowA = Math.max(0, Math.min(1, glowOpacity / 200.0))
                var blur = Math.max(0, glowRadius / 200.0 * 7.5)
                ctx.save()
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.font = "600 " + Math.max(8, Math.round(Math.min(w, h) * 0.34)) + "px Segoe UI"
                if (glowA > 0.001) {
                    ctx.shadowColor = rgba(glowColor, Math.min(0.95, 0.25 + glowA * 0.55))
                    ctx.shadowBlur = blur
                }
                ctx.fillStyle = textColor
                ctx.fillText(String(preview.labelText || ""), cx, cy)
                if (glowA > 0.18) {
                    ctx.shadowBlur = 0
                    ctx.lineWidth = Math.max(0.35, glowRadius / 200.0 * 1.1)
                    ctx.strokeStyle = rgba(glowColor, Math.min(1, glowA * 0.55))
                    ctx.strokeText(String(preview.labelText || ""), cx, cy)
                }
                ctx.restore()
            }
        }
        onDieTypeChanged: templateCanvas.requestPaint()
        onStyleDataChanged: templateCanvas.requestPaint()
        onLabelTextChanged: templateCanvas.requestPaint()
        onWidthChanged: templateCanvas.requestPaint()
        onHeightChanged: templateCanvas.requestPaint()
        Component.onCompleted: templateCanvas.requestPaint()
    }
    component DicePreviewLoader: Item {
        id: loaderRoot
        property color dotColor: Qt.rgba(0.88, 0.88, 0.9, 0.78)
        property real dotSize: Math.max(4, Math.round(Math.min(width, height) * 0.12))
        implicitWidth: 28
        implicitHeight: 12
        Row {
            anchors.centerIn: parent
            spacing: loaderRoot.dotSize * 0.55
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    width: loaderRoot.dotSize
                    height: loaderRoot.dotSize
                    radius: width / 2
                    color: loaderRoot.dotColor
                    opacity: 0.2
                    scale: 0.82
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: loaderRoot.visible
                        PauseAnimation { duration: index * 120 }
                        NumberAnimation { to: 0.8; duration: 360; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.2; duration: 360; easing.type: Easing.InOutSine }
                        PauseAnimation { duration: Math.max(0, 240 - index * 120) }
                    }
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: loaderRoot.visible
                        PauseAnimation { duration: index * 120 }
                        NumberAnimation { to: 1.0; duration: 360; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.82; duration: 360; easing.type: Easing.InOutSine }
                        PauseAnimation { duration: Math.max(0, 240 - index * 120) }
                    }
                }
            }
        }
    }
    component DiePreviewTile: Item {
        id: tile
        property string dieType: "d6"
        property int tileSize: 46
        property bool useInset: true
        readonly property int previewMargin: tile.useInset ? 0 : 4
        readonly property string snapshotSource: diceWindow.mainPreviewSnapshotSource(tile.dieType)
        readonly property var livePreviewPayload: diceWindow.styleToMainPreviewPayload(diceWindow.styleForDie(tile.dieType), tile.dieType)
        signal clicked()
        implicitWidth: tile.tileSize
        implicitHeight: tile.tileSize
        HoverHandler {
            id: tileHover
        }
        NeumoInsetSurface {
            id: tileInset
            anchors.fill: parent
            visible: tile.useInset
            theme: neumoTheme
            radius: diceWindow.narrowLayout ? 12 : 14
            contentPadding: 6
            fillColor: neumoTheme.baseColor
            insetDarkColor: neumoTheme
                ? Qt.rgba(neumoTheme.shadowDarkBase.r, neumoTheme.shadowDarkBase.g, neumoTheme.shadowDarkBase.b,
                    Math.min(1.0, neumoTheme.insetDarkAlpha + (tileHover.hovered ? 0.18 : 0.0)))
                : "#CC151618"
            insetLightColor: neumoTheme
                ? Qt.rgba(neumoTheme.shadowLightBase.r, neumoTheme.shadowLightBase.g, neumoTheme.shadowLightBase.b,
                    Math.min(1.0, neumoTheme.insetLightAlpha + (tileHover.hovered ? 0.12 : 0.0)))
                : "#663B3C40"
        }
        Item {
            id: tileFlat
            anchors.fill: parent
            visible: !tile.useInset
        }
        DiceMainPreviewLiveTile {
            id: mainPreviewLiveTile
            anchors.fill: tileInset
            anchors.margins: tile.previewMargin
            visible: tile.useInset && diceWindow.useLiveMainDicePreview
            dieType: tile.dieType
            stylePayload: tile.livePreviewPayload
            hovered: tileHover.hovered && tile.enabled
            previewActive: visible
            previewMargin: 0
            referenceSize: diceWindow.mainPreviewReferenceSize
            opacity: tile.enabled ? 1.0 : 0.55
            scale: tilePress.pressed ? 0.96 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
            }
        }
        Image {
            id: mainPreviewImage
            anchors.fill: tileInset
            anchors.margins: tile.previewMargin
            visible: tile.useInset
                && !diceWindow.useLiveMainDicePreview
                && status === Image.Ready
                && (!diceWindow.mainPreviewHoverTile || diceWindow.mainPreviewHoverTile !== tile || !diceWindow.mainPreviewHoverWebReady)
            source: tile.snapshotSource
            asynchronous: true
            cache: false
            smooth: true
            mipmap: true
            fillMode: Image.PreserveAspectFit
            opacity: tile.enabled ? 1.0 : 0.55
            scale: tilePress.pressed ? 0.96 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
            }
        }
        DicePreviewLoader {
            anchors.fill: tileInset
            anchors.margins: tile.previewMargin
            visible: tile.useInset
                && !diceWindow.useLiveMainDicePreview
                && (!diceWindow.mainPreviewHoverTile || diceWindow.mainPreviewHoverTile !== tile || !diceWindow.mainPreviewHoverWebReady)
                && mainPreviewImage.status !== Image.Ready
            opacity: tile.enabled ? 1.0 : 0.55
            scale: tilePress.pressed ? 0.96 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
            }
        }
        TemplateStylePreview {
            anchors.fill: tileFlat
            anchors.margins: 4
            visible: !tile.useInset
            dieType: tile.dieType
            styleData: diceWindow.styleForDie(tile.dieType)
            labelText: diceWindow.previewLabelForDieType(tile.dieType)
            opacity: tile.enabled ? 1.0 : 0.55
            scale: tilePress.pressed ? 0.96 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
            }
        }
        MouseArea {
            id: tilePress
            anchors.fill: parent
            hoverEnabled: true
            enabled: tile.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
        Component.onCompleted: {
            if (tile.useInset && !diceWindow.useLiveMainDicePreview) {
                diceWindow.registerMainPreviewTile(tile)
            }
            if (tile.useInset && !diceWindow.useLiveMainDicePreview && diceMainPreviewCache) {
                diceMainPreviewCache.ensureSnapshotForDie(tile.dieType)
            }
        }
        Component.onDestruction: {
            if (tile.useInset && !diceWindow.useLiveMainDicePreview) {
                diceWindow.unregisterMainPreviewTile(tile)
            }
        }
        onDieTypeChanged: {
            if (tile.useInset && !diceWindow.useLiveMainDicePreview) {
                diceWindow.registerMainPreviewTile(tile)
            }
            if (tile.useInset && !diceWindow.useLiveMainDicePreview && diceMainPreviewCache) {
                diceMainPreviewCache.ensureSnapshotForDie(tile.dieType)
            }
        }
        onXChanged: if (!diceWindow.useLiveMainDicePreview && diceWindow.mainPreviewHoverTile === tile) diceWindow.syncMainPreviewHoverGeometry()
        onYChanged: if (!diceWindow.useLiveMainDicePreview && diceWindow.mainPreviewHoverTile === tile) diceWindow.syncMainPreviewHoverGeometry()
        onWidthChanged: if (!diceWindow.useLiveMainDicePreview && diceWindow.mainPreviewHoverTile === tile) diceWindow.syncMainPreviewHoverGeometry()
        onHeightChanged: if (!diceWindow.useLiveMainDicePreview && diceWindow.mainPreviewHoverTile === tile) diceWindow.syncMainPreviewHoverGeometry()
    }
    component TemplateSlotButton: Item {
        id: slot
        property string rowKey: "user"
        property int slotIndex: 0
        property int slotSize: 34
        property var slotStyle: null
        property string snapshotSource: diceWindow.templateSnapshotSource(slot.rowKey, slot.slotIndex)
        property string damageIconSource: slot.rowKey === "damage" ? diceWindow.resolveDamageIconSource(slot.slotIndex) : ""
        property string damageTooltipText: {
            if (slot.rowKey !== "damage") {
                return ""
            }
            if (slot.slotIndex < 0 || slot.slotIndex >= diceWindow.damageTemplateLabels.length) {
                return ""
            }
            var label = String(diceWindow.damageTemplateLabels[slot.slotIndex] || "")
            if (label.length <= 0) {
                return ""
            }
            return "\u0428\u0430\u0431\u043b\u043e\u043d \u0443\u0440\u043e\u043d\u0430: " + label.toLowerCase()
        }
        implicitWidth: slotSize
        implicitHeight: slotSize
        NeumoInsetSurface {
            anchors.fill: parent
            theme: neumoTheme
            radius: Math.max(6, slot.slotSize * 0.18)
            fillColor: slot.slotStyle ? diceWindow.resultsFillColor : Qt.rgba(22 / 255, 23 / 255, 25 / 255, 1.0)
            insetDarkColor: slot.slotStyle ? diceWindow.resultsInsetDarkColor : Qt.rgba(neumoTheme.shadowDarkBase.r, neumoTheme.shadowDarkBase.g, neumoTheme.shadowDarkBase.b, 0.92)
            insetLightColor: slot.slotStyle ? diceWindow.resultsInsetLightColor : Qt.rgba(neumoTheme.shadowLightBase.r, neumoTheme.shadowLightBase.g, neumoTheme.shadowLightBase.b, 0.18)
            contentPadding: 0
        }
        Rectangle {
            anchors.fill: parent
            radius: Math.max(6, slot.slotSize * 0.18)
            color: "transparent"
            border.width: slotHoverArea.containsMouse ? 1 : 0
            border.color: Qt.rgba(1, 1, 1, 0.18)
            opacity: slotHoverArea.containsMouse ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
        }
        TemplateStylePreview {
            anchors.centerIn: parent
            width: Math.max(22, slot.slotSize - 10)
            height: Math.max(22, slot.slotSize - 10)
            visible: !!slot.slotStyle && (!slot.snapshotSource || slot.snapshotSource.length <= 0)
            dieType: diceWindow.dieEditorDieKey
            styleData: slot.slotStyle || ({})
            labelText: diceWindow.previewLabelForDieType(diceWindow.dieEditorDieKey)
        }
        Image {
            anchors.centerIn: parent
            width: Math.max(22, slot.slotSize - 10)
            height: Math.max(22, slot.slotSize - 10)
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            cache: false
            source: slot.snapshotSource
            visible: !!slot.slotStyle && slot.snapshotSource.length > 0 && status === Image.Ready
        }
        NeumoRaisedSurface {
            id: damageIconFrame
            width: Math.max(12, damageIcon.width + 4)
            height: width
            theme: neumoTheme
            radius: Math.max(4, width * 0.18)
            x: parent.width - width - 3
            y: parent.height - height - 3
            fillColor: neumoTheme.baseColor
            shadowOffset: 2.0
            shadowRadius: 4.8
            shadowSamples: 15
            visible: damageIcon.visible
            z: 3
        }
        Image {
            id: damageIcon
            width: Math.max(9, Math.round(slot.slotSize * 0.27))
            height: width
            anchors.centerIn: damageIconFrame
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            source: slot.damageIconSource
            visible: slot.rowKey === "damage" && slot.damageIconSource.length > 0 && status === Image.Ready
            z: 4
        }
        MouseArea {
            id: slotHoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    if (slot.slotStyle) {
                        diceWindow.applyTemplateSlot(slot.rowKey, slot.slotIndex)
                    }
                    return
                }
                if (mouse.button === Qt.RightButton && slot.slotStyle) {
                    var p = slot.mapToItem(diceWindow.contentItem, mouse.x, mouse.y)
                    diceWindow.openTemplateContextMenu(slot.rowKey, slot.slotIndex, p.x, p.y)
                }
            }
        }
        ToolTip.visible: slotHoverArea.containsMouse && slot.damageTooltipText.length > 0
        ToolTip.delay: 250
        ToolTip.timeout: 3000
        ToolTip.text: slot.damageTooltipText
    }
    component StandardDieRow: RowLayout {
        id: root
        property int sides: 6
        property string dieKey: "d" + String(sides)
        property alias countValue: qty.value
        Layout.fillWidth: true
        spacing: 10
        HoverHandler {
            id: rowHover
        }
        DiePreviewTile {
            dieType: root.dieKey
            tileSize: diceWindow.standardPreviewSize
            Layout.alignment: Qt.AlignVCenter
            onClicked: {
                if (root.sides === 4) rollSingleStandardDie(4, d4Count)
                else if (root.sides === 6) rollSingleStandardDie(6, d6Count)
                else if (root.sides === 8) rollSingleStandardDie(8, d8Count)
                else if (root.sides === 10) rollSingleStandardDie(10, d10Count)
                else if (root.sides === 12) rollSingleStandardDie(12, d12Count)
            }
        }
        Label {
            text: "Количество:"
            color: textSecondary
            font.pixelSize: 12
            Layout.preferredWidth: diceWindow.standardLabelWidth
            Layout.alignment: Qt.AlignVCenter
        }
        NeumoStepperField {
            id: qty
            theme: neumoTheme
            from: 0
            to: 20
            stepSize: 1
            decimals: 0
            value: 0
            compactMode: true
            visualStyle: "launcherInline"
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
        }
        NeumoGhostIconButton {
            theme: neumoTheme
            rowHovered: rowHover.hovered
            width: diceWindow.ghostIconSize
            height: diceWindow.ghostIconSize
            iconSource: Qt.resolvedUrl("icons/brush.svg")
            toolTip: "Редактировать стиль"
            Layout.alignment: Qt.AlignVCenter
            onClicked: openDieEditor(root.dieKey)
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 0
        visible: !diceWindow.styleEditorActive
        Flickable {
            id: diceScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            contentWidth: width
            contentHeight: diceContent.implicitHeight
            interactive: contentHeight > height
            onContentYChanged: diceWindow.syncMainPreviewHoverGeometry()
            ScrollBar.vertical: NeumoScrollBar {}
            ScrollBar.horizontal: NeumoScrollBar {}
            ColumnLayout {
                    id: diceContent
                    width: diceScroll.width
                    spacing: diceWindow.sectionSpacing
                    NeumoInsetSurface {
                        id: resultsCard
                        theme: neumoTheme
                        Layout.fillWidth: true
                        Layout.leftMargin: diceWindow.sectionGutter
                        Layout.rightMargin: diceWindow.sectionGutter
                        radius: diceWindow.cardRadius
                        fillColor: diceWindow.resultsFillColor
                        insetDarkColor: diceWindow.resultsInsetDarkColor
                        insetLightColor: diceWindow.resultsInsetLightColor
                        contentPadding: diceWindow.resultsCardPadding
                        implicitHeight: resultsContent.implicitHeight + contentPadding * 2
                        ColumnLayout {
                            id: resultsContent
                            width: parent.width
                            spacing: 8
                            Label {
                                text: "Результаты"
                                color: textPrimary
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                            Item {
                                id: resultsViewport
                                Layout.fillWidth: true
                                Layout.minimumHeight: 96
                                Layout.preferredHeight: Math.max(96, resultsRow.implicitHeight + 12)
                                clip: true
                                Item {
                                    anchors.fill: parent
                                    TextMetrics {
                                        id: d20FormulaMetrics
                                        font.pixelSize: 10
                                        text: String(d20Result ? d20Result.formula : "") + ":"
                                    }
                                    TextMetrics {
                                        id: d20TotalMetrics
                                        font.pixelSize: 20
                                        font.weight: Font.Bold
                                        text: d20Result ? String(d20Result.total) : ""
                                    }
                                    TextMetrics {
                                        id: standardFormulaMetrics
                                        font.pixelSize: 10
                                        text: String(standardResult ? standardResult.formula : "") + ":"
                                    }
                                    TextMetrics {
                                        id: standardTotalMetrics
                                        font.pixelSize: 20
                                        font.weight: Font.Bold
                                        text: standardResult ? String(standardResult.total) : ""
                                    }
                                    Label {
                                        anchors.centerIn: parent
                                        visible: !(d20Result && d20Result.active) && !(standardResult && standardResult.active) && !(d100Result && d100Result.active)
                                        text: waitingStandardPhysicsResult
                                            ? "Ожидание результатов..."
                                            : "Бросков пока нет"
                                        color: textSecondary
                                        font.pixelSize: 12
                                    }
                                    RowLayout {
                                        id: resultsRow
                                        anchors.fill: parent
                                        visible: (d20Result && d20Result.active) || (standardResult && standardResult.active) || (d100Result && d100Result.active)
                                        spacing: 8
                                        Rectangle {
                                            visible: d20Result && d20Result.active
                                            Layout.minimumWidth: diceWindow.d20ResultCardWidth()
                                            Layout.preferredWidth: diceWindow.d20ResultCardWidth()
                                            Layout.maximumWidth: diceWindow.d20ResultCardWidth()
                                            radius: diceWindow.innerCardRadius
                                            color: "transparent"
                                            border.width: 2
                                            border.color: textPrimary
                                            implicitHeight: d20ResCol.implicitHeight + diceWindow.innerCardPadding * 2
                                            clip: true
                                            ColumnLayout {
                                                id: d20ResCol
                                                anchors.fill: parent
                                                anchors.margins: diceWindow.innerCardPadding
                                                spacing: 4
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
                                        Rectangle {
                                            visible: standardResult && standardResult.active
                                            Layout.minimumWidth: diceWindow.standardResultCardWidth()
                                            Layout.preferredWidth: diceWindow.standardResultCardWidth()
                                            Layout.maximumWidth: diceWindow.standardResultCardWidth()
                                            radius: diceWindow.innerCardRadius
                                            color: "transparent"
                                            border.width: 2
                                            border.color: textPrimary
                                            implicitHeight: stdResCol.implicitHeight + diceWindow.innerCardPadding * 2
                                            clip: true
                                            ColumnLayout {
                                                id: stdResCol
                                                anchors.fill: parent
                                                anchors.margins: diceWindow.innerCardPadding
                                                spacing: 4
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
                                        Rectangle {
                                            visible: d100Result && d100Result.active
                                            Layout.minimumWidth: diceWindow.d100ResultCardWidth()
                                            Layout.preferredWidth: diceWindow.d100ResultCardWidth()
                                            Layout.maximumWidth: diceWindow.d100ResultCardWidth()
                                            radius: diceWindow.innerCardRadius
                                            color: "transparent"
                                            border.width: 2
                                            border.color: textPrimary
                                            implicitHeight: d100ResCol.implicitHeight + diceWindow.innerCardPadding * 2
                                            clip: true
                                            ColumnLayout {
                                                id: d100ResCol
                                                anchors.fill: parent
                                                anchors.margins: diceWindow.innerCardPadding
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
                    }
                    NeumoRaisedSurface {
                        id: d20Card
                        theme: neumoTheme
                        Layout.fillWidth: true
                        Layout.leftMargin: diceWindow.sectionGutter
                        Layout.rightMargin: diceWindow.sectionGutter
                        radius: diceWindow.cardRadius
                        fillColor: neumoTheme.baseColor
                        shadowOffset: diceWindow.cardShadowOffset
                        shadowRadius: diceWindow.cardShadowRadius
                        shadowSamples: diceWindow.cardShadowSamples
                        contentPadding: diceWindow.cardPadding
                        implicitHeight: d20Content.implicitHeight + contentPadding * 2
                        ColumnLayout {
                            id: d20Content
                            width: parent.width
                            spacing: 10
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                DiePreviewTile {
                                    dieType: "d20"
                                    tileSize: diceWindow.standardPreviewSize
                                    Layout.alignment: Qt.AlignVCenter
                                    onClicked: rollD20Only()
                                }
                                ColumnLayout {
                                    spacing: 4
                                    Layout.alignment: Qt.AlignVCenter
                                    NeumoIconButton {
                                        theme: neumoTheme
                                        width: 24
                                        height: 24
                                        glyph: "▲"
                                        fontSize: 10
                                        iconIdleColor: d20Mode === "advantage" ? "#2F8B4B" : (neumoTheme ? neumoTheme.textSecondary : "#909090")
                                        iconHoverColor: d20Mode === "advantage" ? "#2F8B4B" : (neumoTheme ? neumoTheme.textPrimary : "#D0D0D0")
                                        idleSurfaceOpacity: d20Mode === "advantage" ? 1.0 : 0.9
                                        onClicked: setD20Mode("advantage")
                                    }
                                    NeumoIconButton {
                                        theme: neumoTheme
                                        width: 24
                                        height: 24
                                        glyph: "▼"
                                        fontSize: 10
                                        iconIdleColor: d20Mode === "disadvantage" ? "#A33C3C" : (neumoTheme ? neumoTheme.textSecondary : "#909090")
                                        iconHoverColor: d20Mode === "disadvantage" ? "#A33C3C" : (neumoTheme ? neumoTheme.textPrimary : "#D0D0D0")
                                        idleSurfaceOpacity: d20Mode === "disadvantage" ? 1.0 : 0.9
                                        onClicked: setD20Mode("disadvantage")
                                    }
                                }
                                ColumnLayout {
                                    id: d20Fields
                                    Layout.fillWidth: true
                                    spacing: 8
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10
                                        Label {
                                            text: "Количество:"
                                            color: textSecondary
                                            font.pixelSize: 12
                                            Layout.preferredWidth: diceWindow.d20LabelWidth
                                            horizontalAlignment: Text.AlignLeft
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                        NeumoStepperField {
                                            theme: neumoTheme
                                            from: 0
                                            to: 20
                                            stepSize: 1
                                            decimals: 0
                                            value: d20Count
                                            compactMode: true
                                            visualStyle: "launcherInline"
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 0
                                            Layout.alignment: Qt.AlignVCenter
                                            onValueModified: d20Count = Math.round(value)
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10
                                        Label {
                                            text: "Бонус:"
                                            color: textSecondary
                                            font.pixelSize: 12
                                            Layout.preferredWidth: diceWindow.d20LabelWidth
                                            horizontalAlignment: Text.AlignLeft
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                        NeumoStepperField {
                                            theme: neumoTheme
                                            from: -20
                                            to: 20
                                            stepSize: 1
                                            decimals: 0
                                            value: d20Bonus
                                            compactMode: true
                                            visualStyle: "launcherInline"
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 0
                                            Layout.alignment: Qt.AlignVCenter
                                            onValueModified: d20Bonus = Math.round(value)
                                        }
                                    }
                                }
                                NeumoGhostIconButton {
                                    theme: neumoTheme
                                    rowHovered: d20RowHover.hovered
                                    width: diceWindow.ghostIconSize
                                    height: diceWindow.ghostIconSize
                                    iconSource: Qt.resolvedUrl("icons/brush.svg")
                                    toolTip: "Редактировать стиль"
                                    Layout.alignment: Qt.AlignVCenter
                                    onClicked: openDieEditor("d20")
                                }
                                HoverHandler { id: d20RowHover }
                            }
                        }
                    }
                    NeumoRaisedSurface {
                        id: standardCard
                        theme: neumoTheme
                        Layout.fillWidth: true
                        Layout.leftMargin: diceWindow.sectionGutter
                        Layout.rightMargin: diceWindow.sectionGutter
                        radius: diceWindow.cardRadius
                        fillColor: neumoTheme.baseColor
                        shadowOffset: diceWindow.cardShadowOffset
                        shadowRadius: diceWindow.cardShadowRadius
                        shadowSamples: diceWindow.cardShadowSamples
                        contentPadding: diceWindow.cardPadding
                        implicitHeight: standardContent.implicitHeight + contentPadding * 2
                        ColumnLayout {
                            id: standardContent
                            width: parent.width
                            spacing: 8
                            StandardDieRow { sides: 4; countValue: d4Count; onCountValueChanged: d4Count = Math.round(countValue) }
                            StandardDieRow { sides: 6; countValue: d6Count; onCountValueChanged: d6Count = Math.round(countValue) }
                            StandardDieRow { sides: 8; countValue: d8Count; onCountValueChanged: d8Count = Math.round(countValue) }
                            StandardDieRow { sides: 10; countValue: d10Count; onCountValueChanged: d10Count = Math.round(countValue) }
                            StandardDieRow { sides: 12; countValue: d12Count; onCountValueChanged: d12Count = Math.round(countValue) }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Item {
                                    Layout.preferredWidth: diceWindow.standardPreviewSize
                                    Layout.preferredHeight: 1
                                }
                                Label {
                                    text: "Бонус:"
                                    color: textSecondary
                                    font.pixelSize: 12
                                    Layout.preferredWidth: diceWindow.standardLabelWidth
                                    horizontalAlignment: Text.AlignLeft
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                NeumoStepperField {
                                    theme: neumoTheme
                                    from: -20
                                    to: 20
                                    stepSize: 1
                                    decimals: 0
                                    value: standardBonus
                                    compactMode: true
                                    visualStyle: "launcherInline"
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.alignment: Qt.AlignVCenter
                                    onValueModified: standardBonus = Math.round(value)
                                }
                                Item {
                                    Layout.preferredWidth: diceWindow.ghostIconSize
                                    Layout.preferredHeight: 1
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: diceWindow.sectionGutter
                        Layout.rightMargin: diceWindow.sectionGutter
                        spacing: 10

                        NeumoRaisedActionButton {
                            id: d100ActionTile
                            theme: neumoTheme
                            toolTip: "Бросить d100"
                            compactMode: true
                            contentPadding: diceWindow.cardPadding
                            baseShadowOffset: diceWindow.cardShadowOffset
                            baseShadowRadius: diceWindow.cardShadowRadius
                            hoverShadowOffset: diceWindow.cardShadowOffset + 0.35
                            hoverShadowRadius: diceWindow.cardShadowRadius + 0.8
                            pressedShadowOffset: Math.max(2.8, diceWindow.cardShadowOffset - 0.35)
                            pressedShadowRadius: Math.max(6.8, diceWindow.cardShadowRadius - 0.8)
                            Layout.preferredWidth: diceWindow.d100ActionWidth
                            Layout.minimumWidth: diceWindow.d100ActionWidth
                            Layout.maximumWidth: diceWindow.d100ActionWidth
                            Layout.preferredHeight: diceWindow.actionButtonHeight + 4
                            onClicked: rollD100Only()
                            Item {
                                anchors.fill: parent

                                DiePreviewTile {
                                    dieType: "d100"
                                    tileSize: diceWindow.standardPreviewSize
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: rollD100Only()
                                }

                                NeumoGhostIconButton {
                                    theme: neumoTheme
                                    rowHovered: d100ActionTile.hovered
                                    width: diceWindow.ghostIconSize
                                    height: diceWindow.ghostIconSize
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    iconSource: Qt.resolvedUrl("icons/brush.svg")
                                    toolTip: "Редактировать стиль"
                                    onClicked: openDieEditor("d100")
                                }
                            }
                        }

                        NeumoRaisedActionButton {
                            theme: neumoTheme
                            toolTip: "Бросить все"
                            text: "Бросить все"
                            enabled: canRollAll()
                            compactMode: true
                            baseShadowOffset: diceWindow.cardShadowOffset
                            baseShadowRadius: diceWindow.cardShadowRadius
                            hoverShadowOffset: diceWindow.cardShadowOffset + 0.35
                            hoverShadowRadius: diceWindow.cardShadowRadius + 0.8
                            pressedShadowOffset: Math.max(2.8, diceWindow.cardShadowOffset - 0.35)
                            pressedShadowRadius: Math.max(6.8, diceWindow.cardShadowRadius - 0.8)
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredHeight: diceWindow.actionButtonHeight + 4
                            onClicked: rollAll()
                        }

                        NeumoRaisedActionButton {
                            theme: neumoTheme
                            toolTip: rollVisibilityToolTipText()
                            compactMode: true
                            contentPadding: 0
                            baseShadowOffset: diceWindow.cardShadowOffset
                            baseShadowRadius: diceWindow.cardShadowRadius
                            hoverShadowOffset: diceWindow.cardShadowOffset + 0.35
                            hoverShadowRadius: diceWindow.cardShadowRadius + 0.8
                            pressedShadowOffset: Math.max(2.8, diceWindow.cardShadowOffset - 0.35)
                            pressedShadowRadius: Math.max(6.8, diceWindow.cardShadowRadius - 0.8)
                            Layout.preferredWidth: diceWindow.actionButtonHeight + 4
                            Layout.minimumWidth: diceWindow.actionButtonHeight + 4
                            Layout.maximumWidth: diceWindow.actionButtonHeight + 4
                            Layout.preferredHeight: diceWindow.actionButtonHeight + 4
                            onClicked: cycleRollVisibilityMode()

                            Image {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: rollVisibilityIconSource()
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: diceWindow.sectionSpacing
                    }
                }
            }
    }
    Item {
        id: styleEditorScreen
        anchors.fill: parent
        visible: diceWindow.styleEditorActive

        NeumoInsetSurface {
            anchors.fill: parent
            anchors.margins: 16
            theme: neumoTheme
            useFrameProfile: true
            radius: diceWindow.editorFrameRadius
            fillColor: neumoTheme.baseColor
            contentPadding: diceWindow.editorFramePadding

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: diceWindow.editorSectionOuterGutter
                    Layout.rightMargin: diceWindow.editorSectionOuterGutter
                    Layout.topMargin: diceWindow.narrowLayout ? 8 : 10
                    spacing: 10

                    NeumoIconButton {
                        theme: neumoTheme
                        width: 30
                        height: 30
                        iconSource: Qt.resolvedUrl("icons/back.svg")
                        toolTip: "Назад"
                        onClicked: closeDieEditor()
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Кастомизация " + dieEditorDieKey
                        color: textPrimary
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                NeumoInsetSurface {
                    Layout.fillWidth: true
                    Layout.leftMargin: diceWindow.editorSectionOuterGutter
                    Layout.rightMargin: diceWindow.editorSectionOuterGutter
                    Layout.preferredHeight: diceWindow.narrowLayout ? 154 : 176
                    theme: neumoTheme
                    radius: diceWindow.innerCardRadius + 2
                    fillColor: diceWindow.resultsFillColor
                    insetDarkColor: diceWindow.resultsInsetDarkColor
                    insetLightColor: diceWindow.resultsInsetLightColor
                    contentPadding: 0

                    Item {
                        anchors.fill: parent
                        clip: true

                        WebEngineView {
                            id: previewWeb
                            anchors.fill: parent
                            visible: diceWindow.styleEditorActive
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

                        DicePreviewLoader {
                            anchors.fill: parent
                            visible: !previewWebReady
                        }
                    }
                }

                Timer {
                    id: previewRollTimer
                    interval: 3200
                    repeat: true
                    running: diceWindow.styleEditorActive && previewWebReady
                    onTriggered: diceWindow.startPreviewRollNow()
                }

                ScrollView {
                    id: styleEditorScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    Layout.leftMargin: diceWindow.editorSectionOuterGutter
                    Layout.rightMargin: diceWindow.editorSectionOuterGutter
                    clip: true
                    ScrollBar.vertical: NeumoScrollBar {}
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        id: styleEditorContent
                        width: styleEditorScroll.availableWidth > 0 ? styleEditorScroll.availableWidth : styleEditorScroll.width
                        spacing: 8

                        EditorSectionLabel { text: "Грани" }
                        EditorFieldLabel { text: "Размер (50%..150%)" }
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
                            spacing: 10
                            EditorFieldLabel {
                                Layout.fillWidth: true
                                text: "Цвет граней"
                            }
                            ColorFieldButton {
                                theme: neumoTheme
                                swatchColor: dieEditorWorking.color
                                labelText: String(dieEditorWorking.color || "#C9C9C9").toUpperCase()
                                onClicked: openDieColorDialog("color", "Выбор цвета граней", "#C9C9C9")
                            }
                        }

                        Item { Layout.fillWidth: true; Layout.preferredHeight: 2 }
                        EditorSectionLabel { text: "Градиент" }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            EditorFieldLabel {
                                Layout.fillWidth: true
                                text: "Включить градиент"
                            }
                            NeumoToggle {
                                theme: neumoTheme
                                checked: Boolean(dieEditorWorking.gradientEnabled)
                                onToggled: updateEditorField("gradientEnabled", checked)
                            }
                        }
                        RowLayout {
                            visible: Boolean(dieEditorWorking.gradientEnabled)
                            Layout.fillWidth: true
                            spacing: 10
                            EditorFieldLabel {
                                Layout.fillWidth: true
                                text: "Цвет центра"
                            }
                            ColorFieldButton {
                                theme: neumoTheme
                                swatchColor: dieEditorWorking.gradientCenterColor
                                labelText: String(dieEditorWorking.gradientCenterColor || "#FFFFFF").toUpperCase()
                                onClicked: openDieColorDialog("gradientCenterColor", "Выбор цвета центра градиента", "#FFFFFF")
                            }
                        }
                        EditorFieldLabel {
                            visible: Boolean(dieEditorWorking.gradientEnabled)
                            text: "Резкость/плавность градиента"
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
                        EditorFieldLabel {
                            visible: Boolean(dieEditorWorking.gradientEnabled)
                            text: "Смещение градиента"
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

                        Item { Layout.fillWidth: true; Layout.preferredHeight: 2 }
                        EditorSectionLabel { text: "Текст" }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            EditorFieldLabel {
                                Layout.fillWidth: true
                                text: "Цвет текста"
                            }
                            ColorFieldButton {
                                theme: neumoTheme
                                swatchColor: dieEditorWorking.fontColor
                                labelText: String(dieEditorWorking.fontColor || "#1F1F1F").toUpperCase()
                                onClicked: openDieColorDialog("fontColor", "Выбор цвета шрифта", "#1F1F1F")
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            EditorFieldLabel {
                                Layout.fillWidth: true
                                text: "Цвет свечения текста"
                            }
                            ColorFieldButton {
                                theme: neumoTheme
                                swatchColor: dieEditorWorking.textStrokeColor
                                labelText: String(dieEditorWorking.textStrokeColor || "#EEEEEE").toUpperCase()
                                onClicked: openDieColorDialog("textStrokeColor", "Выбор цвета свечения текста", "#EEEEEE")
                            }
                        }

                        Item { Layout.fillWidth: true; Layout.preferredHeight: 2 }
                        EditorSectionLabel { text: "Свечение" }
                        EditorFieldLabel { text: "Радиус свечения" }
                        SliderNumberControl {
                            minValue: 0
                            maxValue: 200
                            step: 1
                            decimals: 0
                            value: Number(dieEditorWorking.textGlowRadius !== undefined ? dieEditorWorking.textGlowRadius : 100)
                            onValueCommitted: updateEditorField("textGlowRadius", Math.round(value))
                        }
                        EditorFieldLabel { text: "Интенсивность свечения" }
                        SliderNumberControl {
                            minValue: 0
                            maxValue: 200
                            step: 1
                            decimals: 0
                            value: Number(dieEditorWorking.textGlowOpacity !== undefined ? dieEditorWorking.textGlowOpacity : 100)
                            onValueCommitted: updateEditorField("textGlowOpacity", Math.round(value))
                        }

                        Item { Layout.fillWidth: true; Layout.preferredHeight: 2 }
                        EditorSectionLabel { text: "Ребра" }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            EditorFieldLabel {
                                Layout.fillWidth: true
                                text: "Цвет ребер"
                            }
                            ColorFieldButton {
                                theme: neumoTheme
                                swatchColor: dieEditorWorking.edgeColor
                                labelText: String(dieEditorWorking.edgeColor || "#D4D4D4").toUpperCase()
                                onClicked: openDieColorDialog("edgeColor", "Выбор цвета ребер", "#D4D4D4")
                            }
                        }
                        EditorFieldLabel { text: "Толщина ребер" }
                        SliderNumberControl {
                            minValue: 0
                            maxValue: 5
                            step: 0.1
                            decimals: 1
                            value: Number(dieEditorWorking.edgeWidth !== undefined ? dieEditorWorking.edgeWidth : 0.0)
                            onValueCommitted: updateEditorField("edgeWidth", roundToDecimals(value, 1))
                        }

                        Item { Layout.fillWidth: true; Layout.preferredHeight: 2 }
                        EditorSectionLabel { text: "Шаблоны" }
                        EditorFieldLabel { text: "Пользовательские" }
                        GridLayout {
                            id: userTemplateGrid
                            Layout.fillWidth: true
                            Layout.preferredHeight: (slotSize * 2) + rowSpacing
                            columns: 5
                            columnSpacing: 8
                            rowSpacing: 8
                            property int slotSize: diceWindow.templateSlotSizeForWidth(styleEditorContent.width)

                            Repeater {
                                model: 10
                                delegate: TemplateSlotButton {
                                    rowKey: "user"
                                    slotIndex: index
                                    slotSize: userTemplateGrid.slotSize
                                    slotStyle: diceWindow.templateStyle("user", index)
                                    Layout.minimumWidth: 0
                                    Layout.minimumHeight: 0
                                    Layout.preferredWidth: userTemplateGrid.slotSize
                                    Layout.preferredHeight: userTemplateGrid.slotSize
                                    Layout.maximumWidth: userTemplateGrid.slotSize
                                    Layout.maximumHeight: userTemplateGrid.slotSize
                                }
                            }
                        }
                        EditorFieldLabel { text: "Типы урона" }
                        GridLayout {
                            id: damageTemplateGrid
                            Layout.fillWidth: true
                            Layout.preferredHeight: (slotSize * 2) + rowSpacing
                            columns: 5
                            columnSpacing: 8
                            rowSpacing: 8
                            property int slotSize: diceWindow.templateSlotSizeForWidth(styleEditorContent.width)

                            Repeater {
                                model: 10
                                delegate: TemplateSlotButton {
                                    rowKey: "damage"
                                    slotIndex: index
                                    slotSize: damageTemplateGrid.slotSize
                                    slotStyle: diceWindow.templateStyle("damage", index)
                                    Layout.minimumWidth: 0
                                    Layout.minimumHeight: 0
                                    Layout.preferredWidth: damageTemplateGrid.slotSize
                                    Layout.preferredHeight: damageTemplateGrid.slotSize
                                    Layout.maximumWidth: damageTemplateGrid.slotSize
                                    Layout.maximumHeight: damageTemplateGrid.slotSize
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: diceWindow.editorSectionOuterGutter
                    Layout.rightMargin: diceWindow.editorSectionOuterGutter
                    spacing: 10

                    NeumoIconButton {
                        theme: neumoTheme
                        width: 30
                        height: 30
                        iconSource: Qt.resolvedUrl("icons/undo.svg")
                        toolTip: "По умолчанию"
                        onClicked: resetDieEditorToDefaults()
                    }

                    NeumoRaisedActionButton {
                        theme: neumoTheme
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredHeight: diceWindow.actionButtonHeight
                        text: "Сохранить"
                        compactMode: true
                        onClicked: saveDieEditor()
                    }

                    NeumoIconButton {
                        theme: neumoTheme
                        width: 30
                        height: 30
                        iconSource: Qt.resolvedUrl("icons/save.svg")
                        toolTip: "Сохранить стиль"
                        onClicked: saveCurrentStyleToTemplateQueue()
                    }
                }
            }
        }
    }
    WebEngineView {
        id: templateSnapshotWeb
        x: -10000
        y: -10000
        width: 148
        height: 148
        visible: diceWindow.styleEditorActive
        enabled: visible
        backgroundColor: "#121214"
        url: Qt.resolvedUrl("../web/dice_physics.html")
        onLoadingChanged: function(req) {
            if (req.status === WebEngineView.LoadFailedStatus) {
                templateSnapshotWebReady = false
                return
            }
            if (req.status === WebEngineView.LoadSucceededStatus) {
                templateSnapshotWebReady = true
                diceWindow.processTemplateSnapshotQueue()
            }
        }
    }
    Timer {
        id: templateSnapshotCaptureTimer
        interval: 180
        repeat: false
        onTriggered: diceWindow.captureTemplateSnapshotCurrentTask()
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
    Item {
        id: mainPreviewOverlayHost
        anchors.fill: parent
        z: 20
        visible: !diceWindow.useLiveMainDicePreview
        enabled: false
        onWidthChanged: diceWindow.syncMainPreviewHoverGeometry()
        onHeightChanged: diceWindow.syncMainPreviewHoverGeometry()
        Rectangle {
            id: mainPreviewHoverFrame
            visible: !diceWindow.useLiveMainDicePreview && !!diceWindow.mainPreviewHoverTile && diceWindow.mainPreviewHoverWebReady
            enabled: false
            x: diceWindow.mainPreviewHoverX
            y: diceWindow.mainPreviewHoverY
            width: diceWindow.mainPreviewHoverWidth
            height: diceWindow.mainPreviewHoverHeight
            radius: Math.max(8, Math.round(Math.min(width, height) * 0.18))
            color: "transparent"
            clip: true
            Item {
                anchors.centerIn: parent
                width: diceWindow.mainPreviewReferenceSize
                height: diceWindow.mainPreviewReferenceSize
                scale: Math.min(mainPreviewHoverFrame.width / width, mainPreviewHoverFrame.height / height)
                transformOrigin: Item.Center
                enabled: false
                WebEngineView {
                    id: mainPreviewHoverWeb
                    anchors.fill: parent
                    visible: true
                    enabled: false
                    backgroundColor: "#00000000"
                    url: Qt.resolvedUrl("../web/dice_physics.html")
                    onLoadingChanged: function(req) {
                        if (req.status === WebEngineView.LoadFailedStatus) {
                            mainPreviewHoverWebReady = false
                            return
                        }
                        if (req.status === WebEngineView.LoadSucceededStatus) {
                            mainPreviewHoverWebReady = true
                            diceWindow.startMainPreviewHoverNow()
                        }
                    }
                }
            }
        }
    }
    Menu {
        id: templateSlotContextMenu
        MenuItem {
            text: "Перезаписать ячейку"
            enabled: templateContextIndex >= 0
            onTriggered: overwriteTemplateContextSlot()
        }
        MenuItem {
            text: "Удалить шаблон"
            enabled: templateContextRow === "user" && templateContextIndex >= 0
            onTriggered: deleteTemplateContextSlot()
        }
    }
    Popup {
        id: colorPickerPopup
        modal: true
        focus: true
        width: Math.min(420, diceWindow.width - 24)
        height: 468
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        anchors.centerIn: Overlay.overlay
        padding: 0
        background: Item {
            NeumoRaisedSurface {
                anchors.fill: parent
                theme: neumoTheme
                radius: diceWindow.cardRadius
                fillColor: neumoTheme.baseColor
                shadowOffset: diceWindow.cardShadowOffset
                shadowRadius: diceWindow.cardShadowRadius
                shadowSamples: diceWindow.cardShadowSamples
            }
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            EditorSectionLabel {
                Layout.fillWidth: true
                text: pendingColorTitle
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                NeumoInsetSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    theme: neumoTheme
                    radius: 14
                    fillColor: neumoTheme.fieldInsetFillColor
                    contentPadding: 6

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: pickerCurrentColor
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.18)

                        Label {
                            anchors.centerIn: parent
                            text: "Текущий"
                            color: "#202020"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }
                }

                NeumoInsetSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    theme: neumoTheme
                    radius: 14
                    fillColor: neumoTheme.fieldInsetFillColor
                    contentPadding: 6

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: pickerPreviewColor
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.18)

                        Label {
                            anchors.centerIn: parent
                            text: "Новый"
                            color: "#202020"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            EditorFieldLabel { text: "Тон" }
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

            EditorFieldLabel { text: "Насыщенность" }
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

            EditorFieldLabel { text: "Яркость" }
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

            EditorFieldLabel { text: "Код цвета (HEX / RGB(A))" }
            NeumoTextField {
                id: pickerHexInput
                theme: neumoTheme
                visualStyle: "launcherInline"
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

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                NeumoRaisedActionButton {
                    Layout.fillWidth: true
                    theme: neumoTheme
                    compactMode: true
                    text: "Отмена"
                    onClicked: colorPickerPopup.close()
                }

                NeumoRaisedActionButton {
                    Layout.fillWidth: true
                    theme: neumoTheme
                    compactMode: true
                    text: "Применить"
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


