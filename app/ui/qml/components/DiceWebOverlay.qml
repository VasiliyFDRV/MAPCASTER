import QtQuick
import QtWebEngine

Item {
    id: root
    anchors.fill: parent

    property bool active: false
    property bool pageReady: false
    property bool pendingRoll: false
    property var styleBag: ({})

    property int activeRequestId: 0
    property int activeExpectedCount: 0
    property var standardSides: [4, 6, 8, 10, 12]
    property var activeExpectedBySides: ({4: 0, 6: 0, 8: 0, 10: 0, 12: 0})
    property var activeValuesBySides: ({4: [], 6: [], 8: [], 10: [], 12: []})
    property int d20ActiveRequestId: 0
    property int d20ExpectedCount: 0
    property var d20Values: []
    property string d20ActiveMode: "normal"
    property int d100ActiveRequestId: 0
    property int d100TensValue: -1
    property int d100OnesValue: -1
    property bool d100TensReady: false
    property bool d100OnesReady: false

    signal d6ResultReady(int requestId, int value)
    signal d6BatchResultReady(int requestId, var values)
    signal standardBatchResultReady(int requestId, int sides, var values)
    signal d20BatchResultReady(int requestId, var values)
    signal d100ResultReady(int requestId, int tensValue, int onesValue)

    function clampNumber(value, minValue, maxValue) {
        var n = Number(value)
        if (!isFinite(n)) {
            n = Number(minValue)
        }
        return Math.max(Number(minValue), Math.min(Number(maxValue), n))
    }

    function setStyleBag(bag) {
        styleBag = bag && typeof bag === "object" ? bag : ({})
    }

    function styleKeyForKind(kind) {
        var k = String(kind || "d6").toLowerCase()
        if (k === "d10t") {
            return "d100"
        }
        if (k === "d4" || k === "d6" || k === "d8" || k === "d10" || k === "d12" || k === "d20" || k === "d100") {
            return k
        }
        return "d6"
    }

    function stylePayloadForKind(kind) {
        var bag = styleBag || ({})
        var key = styleKeyForKind(kind)
        var style = bag[key]
        if (!style && key === "d100") {
            style = bag["d10"]
        }

        var legacyGlow = Number(style && style.textShadowIntensity !== undefined ? style.textShadowIntensity : 100)
        var glowRadius = Number(style && style.textGlowRadius !== undefined ? style.textGlowRadius : legacyGlow)
        var glowOpacity = Number(style && style.textGlowOpacity !== undefined ? style.textGlowOpacity : legacyGlow)

        return {
            "scalePercent": clampNumber(Number(style && style.scalePercent !== undefined ? style.scalePercent : 100), 50, 150),
            "faceColor": String(style && style.color ? style.color : "#C9C9C9"),
            "gradientEnabled": Boolean(style && style.gradientEnabled),
            "gradientCenterColor": String(style && style.gradientCenterColor ? style.gradientCenterColor : "#FFFFFF"),
            "gradientSharpness": clampNumber(Number(style && style.gradientSharpness !== undefined ? style.gradientSharpness : 50) / 100.0, 0, 1),
            "gradientOffset": clampNumber(Number(style && style.gradientOffset !== undefined ? style.gradientOffset : 50) / 100.0, 0, 1),
            "textColor": String(style && style.fontColor ? style.fontColor : "#1F1F1F"),
            "textStrokeColor": String(style && style.textStrokeColor ? style.textStrokeColor : "#EEEEEE"),
            "textGlowRadius": clampNumber(glowRadius / 100.0, 0, 2),
            "textGlowOpacity": clampNumber(glowOpacity / 100.0, 0, 2),
            "edgeColor": String(style && style.edgeColor ? style.edgeColor : "#D4D4D4"),
            "edgeWidth": clampNumber(Number(style && style.edgeWidth !== undefined ? style.edgeWidth : 0.0), 0, 5)
        }
    }

    function runRollScript(requestId, kind, count, styleKindOverride) {
        var req = Number(requestId || 0)
        var modelKind = String(kind || "d6")
        var rollCount = Math.max(1, Number(count || 1))
        var styleKeyKind = styleKindOverride !== undefined && styleKindOverride !== null ? styleKindOverride : modelKind
        var stylePayload = stylePayloadForKind(styleKeyKind)
        var script = "(function(){"
            + "if (window.setStyleOverrides) { window.setStyleOverrides(" + JSON.stringify(stylePayload) + "); }"
            + "if (window.startRoll) { window.startRoll(" + String(req) + ", " + JSON.stringify(modelKind) + ", " + String(rollCount) + "); }"
            + "})();"
        web.runJavaScript(script)
    }

    function runStandardScript(requestId, sides) {
        var req = Number(requestId || activeRequestId || 0)
        var s = Number(sides || 6)
        var kind = "d" + String(s)
        runRollScript(req, kind, 1)
    }

    function clearWebDiceNow() {
        if (pageReady) {
            web.runJavaScript("window.clearAllDice && window.clearAllDice();")
        }
    }

    function buildCountMap(d4Count, d6Count, d8Count, d10Count, d12Count) {
        return ({
            4: Math.max(0, Number(d4Count || 0)),
            6: Math.max(0, Number(d6Count || 0)),
            8: Math.max(0, Number(d8Count || 0)),
            10: Math.max(0, Number(d10Count || 0)),
            12: Math.max(0, Number(d12Count || 0))
        })
    }

    function sideCountTotal(counts) {
        var total = 0
        for (var i = 0; i < standardSides.length; i++) {
            var s = Number(standardSides[i])
            total += Number(counts[s] || 0)
        }
        return Number(total)
    }

    function startBatchNow() {
        var started = false

        if (d100ActiveRequestId > 0 && (!d100TensReady || !d100OnesReady)) {
            runRollScript(d100ActiveRequestId, "d10t", 1, "d100")
            runRollScript(d100ActiveRequestId, "d10", 1, "d100")
            started = true
        }

        if (d20ActiveRequestId > 0 && d20ExpectedCount > 0) {
            web.runJavaScript("window.setD20RequestMeta && window.setD20RequestMeta(" + String(d20ActiveRequestId) + ", '" + String(d20ActiveMode || 'normal') + "');")
            for (var k = 0; k < d20ExpectedCount; k++) {
                runStandardScript(d20ActiveRequestId, 20)
            }
            started = true
        }

        if (activeRequestId > 0 && activeExpectedCount > 0) {
            for (var i = 0; i < standardSides.length; i++) {
                var s = Number(standardSides[i])
                var cnt = Number(activeExpectedBySides[s] || 0)
                for (var j = 0; j < cnt; j++) {
                    runStandardScript(activeRequestId, s)
                }
            }
            started = true
        }

        if (started) {
            hideTimer.restart()
        }
    }

    function triggerStandardBatch(requestId, d4Count, d6Count, d8Count, d10Count, d12Count, appendMode) {
        var append = Boolean(appendMode)
        var req = Number(requestId || 0)
        d100ActiveRequestId = 0
        d100TensValue = -1
        d100OnesValue = -1
        d100TensReady = false
        d100OnesReady = false
        var addBySides = buildCountMap(d4Count, d6Count, d8Count, d10Count, d12Count)
        var addTotal = sideCountTotal(addBySides)
        if (req <= 0 || addTotal <= 0) {
            return
        }

        var sameActive = append && activeRequestId === req && activeExpectedCount > 0
        if (!sameActive) {
            if (d20ExpectedCount <= 0 && d100ActiveRequestId <= 0) {
                clearWebDiceNow()
            }
            activeRequestId = req
            activeExpectedCount = addTotal
            activeExpectedBySides = addBySides
            activeValuesBySides = ({4: [], 6: [], 8: [], 10: [], 12: []})
        } else {
            var mergedExpected = ({4: 0, 6: 0, 8: 0, 10: 0, 12: 0})
            for (var i = 0; i < standardSides.length; i++) {
                var s = Number(standardSides[i])
                mergedExpected[s] = Number(activeExpectedBySides[s] || 0) + Number(addBySides[s] || 0)
            }
            activeExpectedBySides = mergedExpected
            activeExpectedCount = Number(activeExpectedCount || 0) + addTotal
        }

        active = true
        web.opacity = 1.0
        hideTimer.restart()

        if (pageReady) {
            pendingRoll = false
            for (var i2 = 0; i2 < standardSides.length; i2++) {
                var s2 = Number(standardSides[i2])
                var cnt2 = Number(addBySides[s2] || 0)
                for (var j2 = 0; j2 < cnt2; j2++) {
                    runStandardScript(activeRequestId, s2)
                }
            }
        } else {
            pendingRoll = true
            web.reload()
        }
    }

    function triggerD6(requestId) {
        triggerStandardBatch(requestId, 0, 1, 0, 0, 0, false)
    }

    function triggerD8(requestId, count, appendMode) {
        triggerStandardBatch(requestId, 0, 0, Math.max(1, Number(count || 1)), 0, 0, appendMode)
    }

    function triggerD6Batch(requestId, count, appendMode) {
        triggerStandardBatch(requestId, 0, Math.max(1, Number(count || 1)), 0, 0, 0, appendMode)
    }

    function triggerD20Batch(requestId, count, appendMode, modeName) {
        var append = Boolean(appendMode)
        var req = Number(requestId || 0)
        var cnt = Math.max(0, Number(count || 0))
        var mode = String(modeName || "normal")
        if (mode !== "advantage" && mode !== "disadvantage") {
            mode = "normal"
        }
        if (req <= 0 || cnt <= 0) {
            return
        }

        d100ActiveRequestId = 0
        d100TensValue = -1
        d100OnesValue = -1
        d100TensReady = false
        d100OnesReady = false

        var sameActive = append && d20ActiveRequestId === req && d20ExpectedCount > 0
        if (!sameActive) {
            if (activeExpectedCount <= 0 && d100ActiveRequestId <= 0) {
                clearWebDiceNow()
            }
            d20ActiveRequestId = req
            d20ExpectedCount = cnt
            d20Values = []
            d20ActiveMode = mode
        } else {
            d20ExpectedCount = Number(d20ExpectedCount || 0) + cnt
        }

        active = true
        web.opacity = 1.0
        hideTimer.restart()

        if (pageReady) {
            pendingRoll = false
            web.runJavaScript("window.setD20RequestMeta && window.setD20RequestMeta(" + String(req) + ", '" + String(mode) + "');")
            for (var i = 0; i < cnt; i++) {
                runStandardScript(req, 20)
            }
        } else {
            pendingRoll = true
            web.reload()
        }
    }

    function triggerD100(requestId) {
        var req = Number(requestId || 0)
        if (req <= 0) {
            return
        }

        clearWebDiceNow()
        activeRequestId = 0
        activeExpectedCount = 0
        activeExpectedBySides = ({4: 0, 6: 0, 8: 0, 10: 0, 12: 0})
        activeValuesBySides = ({4: [], 6: [], 8: [], 10: [], 12: []})
        d20ActiveRequestId = 0
        d20ExpectedCount = 0
        d20Values = []

        d100ActiveRequestId = req
        d100TensValue = -1
        d100OnesValue = -1
        d100TensReady = false
        d100OnesReady = false

        active = true
        web.opacity = 1.0
        hideTimer.restart()

        if (pageReady) {
            pendingRoll = false
            runRollScript(req, "d10t", 1, "d100")
            runRollScript(req, "d10", 1, "d100")
        } else {
            pendingRoll = true
            web.reload()
        }
    }

    function clear() {
        clearWebDiceNow()
        active = false
        web.opacity = 0.0
        pendingRoll = false
        activeRequestId = 0
        activeExpectedCount = 0
        activeExpectedBySides = ({4: 0, 6: 0, 8: 0, 10: 0, 12: 0})
        activeValuesBySides = ({4: [], 6: [], 8: [], 10: [], 12: []})
        d20ActiveRequestId = 0
        d20ExpectedCount = 0
        d20Values = []
        d20ActiveMode = "normal"
        d100ActiveRequestId = 0
        d100TensValue = -1
        d100OnesValue = -1
        d100TensReady = false
        d100OnesReady = false
    }

    function finalizeBatch() {
        if (activeRequestId <= 0 || activeExpectedCount <= 0) {
            return
        }

        var reqId = activeRequestId
        var values6 = (activeValuesBySides[6] || []).slice(0)
        if (values6.length > 0 && values6.length === 1) {
            d6ResultReady(reqId, Number(values6[0]))
        }
        if (values6.length > 0) {
            d6BatchResultReady(reqId, values6)
        }

        for (var i = 0; i < standardSides.length; i++) {
            var s = Number(standardSides[i])
            var values = (activeValuesBySides[s] || []).slice(0)
            if (values.length > 0) {
                standardBatchResultReady(reqId, s, values)
            }
        }

        hideTimer.restart()
        activeExpectedCount = 0
        activeExpectedBySides = ({4: 0, 6: 0, 8: 0, 10: 0, 12: 0})
    }

    function tryParseResultMessage(message) {
        var text = String(message || "")
        if (text.indexOf("[dice-result]") !== 0) {
            return
        }

        var reqMatch = /request=(\d+)/.exec(text)
        var sidesMatch = /sides=(\d+)/.exec(text)
        var valueMatch = /value=(\d+)/.exec(text)
        if (!reqMatch || !valueMatch) {
            return
        }

        var reqId = Number(reqMatch[1])
        var sides = sidesMatch ? Number(sidesMatch[1]) : 6
        var value = Number(valueMatch[1])
        if (reqId <= 0) {
            return
        }
        var allowZeroTens = reqId === d100ActiveRequestId && sides === 100 && value === 0
        if (value <= 0 && !allowZeroTens) {
            return
        }

        if (reqId === d100ActiveRequestId) {
            if (sides === 100) {
                d100TensValue = Math.max(0, Math.min(90, Number(value || 0)))
                d100TensReady = true
            } else if (sides === 10) {
                var ones = Number(value || 0) % 10
                if (ones < 0) ones += 10
                d100OnesValue = Math.max(0, Math.min(9, ones))
                d100OnesReady = true
            } else {
                return
            }

            if (d100TensReady && d100OnesReady) {
                d100ResultReady(d100ActiveRequestId, d100TensValue, d100OnesValue)
                d100ActiveRequestId = 0
                d100TensValue = -1
                d100OnesValue = -1
                d100TensReady = false
                d100OnesReady = false
                hideTimer.restart()
            }
            return
        }

        if (sides === 20) {
            if (reqId !== d20ActiveRequestId) {
                console.log("[dice-web] ignore stale d20 result req=", reqId, "active=", d20ActiveRequestId)
                return
            }
            var d20List = (d20Values || []).slice(0)
            d20List = d20List.concat([Math.max(1, Math.min(20, value))])
            if (d20List.length > d20ExpectedCount) {
                d20List = d20List.slice(0, d20ExpectedCount)
            }
            d20Values = d20List
            if (d20Values.length >= d20ExpectedCount) {
                d20BatchResultReady(d20ActiveRequestId, d20Values.slice(0))
                d20ActiveRequestId = 0
                d20ExpectedCount = 0
                d20Values = []
                hideTimer.restart()
            }
            return
        }

        var isStandardSide = standardSides.indexOf(sides) >= 0
        if (!isStandardSide) {
            return
        }

        if (reqId !== activeRequestId) {
            console.log("[dice-web] ignore stale result req=", reqId, "active=", activeRequestId)
            return
        }

        var expected = Number(activeExpectedBySides[sides] || 0)
        if (expected <= 0) {
            return
        }

        var bySides = ({
            4: (activeValuesBySides[4] || []).slice(0),
            6: (activeValuesBySides[6] || []).slice(0),
            8: (activeValuesBySides[8] || []).slice(0),
            10: (activeValuesBySides[10] || []).slice(0),
            12: (activeValuesBySides[12] || []).slice(0)
        })
        bySides[sides] = bySides[sides].concat([value])
        if (bySides[sides].length > expected) {
            bySides[sides] = bySides[sides].slice(0, expected)
        }
        activeValuesBySides = bySides

        var landedTotal = 0
        for (var i = 0; i < standardSides.length; i++) {
            landedTotal += Number((activeValuesBySides[Number(standardSides[i])] || []).length)
        }
        if (landedTotal >= Number(activeExpectedCount || 0)) {
            finalizeBatch()
            return
        }
    }

    WebEngineView {
        id: web
        anchors.fill: parent
        visible: true
        opacity: 0.0
        backgroundColor: "transparent"
        url: Qt.resolvedUrl("../../web/dice_physics.html")
        enabled: true
        focus: false
        z: 1

        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        onJavaScriptConsoleMessage: function(level, message, lineNumber, sourceID) {
            root.tryParseResultMessage(message)
            console.log("[dice-web-js]", String(message), String(sourceID) + ":" + String(lineNumber))
        }

        onLoadingChanged: function(req) {
            if (req.status === WebEngineView.LoadFailedStatus) {
                root.pageReady = false
                console.log("[dice-web] load failed", req.errorString)
                return
            }
            if (req.status === WebEngineView.LoadSucceededStatus) {
                root.pageReady = true
                if (root.pendingRoll) {
                    root.pendingRoll = false
                    root.startBatchNow()
                }
            }
        }
    }

    Component.onCompleted: {
        web.reload()
    }

    Timer {
        id: hideTimer
        interval: 6000
        repeat: false
        onTriggered: {}
    }
}

