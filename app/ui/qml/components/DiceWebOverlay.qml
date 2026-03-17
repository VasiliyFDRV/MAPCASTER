import QtQuick
import QtWebEngine

Item {
    id: root
    anchors.fill: parent

    property bool active: false
    property bool pageReady: false
    property bool pendingRoll: false

    property int activeRequestId: 0
    property int activeExpectedCount: 0
    property var activeExpectedBySides: ({6: 0, 8: 0})
    property var activeValuesBySides: ({6: [], 8: []})

    signal d6ResultReady(int requestId, int value)
    signal d6BatchResultReady(int requestId, var values)
    signal standardBatchResultReady(int requestId, int sides, var values)

    function runD6Script(requestId) {
        var req = Number(requestId || activeRequestId || 0)
        web.runJavaScript("window.startRoll && window.startRoll(" + String(req) + ", 'd6', 1);")
    }

    function runD8Script(requestId) {
        var req = Number(requestId || activeRequestId || 0)
        web.runJavaScript("window.startRoll && window.startRoll(" + String(req) + ", 'd8', 1);")
    }

    function clearWebDiceNow() {
        if (pageReady) {
            web.runJavaScript("window.clearAllDice && window.clearAllDice();")
        }
    }

    function startBatchNow() {
        if (activeRequestId <= 0 || activeExpectedCount <= 0) {
            return
        }

        var c6 = Number(activeExpectedBySides[6] || 0)
        var c8 = Number(activeExpectedBySides[8] || 0)
        for (var i = 0; i < c6; i++) {
            runD6Script(activeRequestId)
        }
        for (var j = 0; j < c8; j++) {
            runD8Script(activeRequestId)
        }
        hideTimer.restart()
    }

    function triggerStandardBatch(requestId, d6Count, d8Count, appendMode) {
        var append = Boolean(appendMode)
        var req = Number(requestId || 0)
        var addD6 = Math.max(0, Number(d6Count || 0))
        var addD8 = Math.max(0, Number(d8Count || 0))
        var addTotal = addD6 + addD8
        if (req <= 0 || addTotal <= 0) {
            return
        }

        var sameActive = append && activeRequestId === req && activeExpectedCount > 0
        if (!sameActive) {
            clearWebDiceNow()
            activeRequestId = req
            activeExpectedCount = addTotal
            activeExpectedBySides = ({6: addD6, 8: addD8})
            activeValuesBySides = ({6: [], 8: []})
        } else {
            activeExpectedCount = Number(activeExpectedCount || 0) + addTotal
            activeExpectedBySides = ({
                6: Number(activeExpectedBySides[6] || 0) + addD6,
                8: Number(activeExpectedBySides[8] || 0) + addD8
            })
        }

        active = true
        web.visible = true
        web.opacity = 1.0
        hideTimer.restart()

        if (pageReady) {
            pendingRoll = false
            for (var i = 0; i < addD6; i++) {
                runD6Script(activeRequestId)
            }
            for (var j = 0; j < addD8; j++) {
                runD8Script(activeRequestId)
            }
        } else {
            pendingRoll = true
            web.reload()
        }
    }

    function triggerD6(requestId) {
        triggerStandardBatch(requestId, 1, 0, false)
    }

    function triggerD8(requestId, count, appendMode) {
        triggerStandardBatch(requestId, 0, Math.max(1, Number(count || 1)), appendMode)
    }

    function triggerD6Batch(requestId, count, appendMode) {
        triggerStandardBatch(requestId, Math.max(1, Number(count || 1)), 0, appendMode)
    }

    function clear() {
        clearWebDiceNow()
        active = false
        web.opacity = 0.0
        web.visible = false
        pendingRoll = false
        activeRequestId = 0
        activeExpectedCount = 0
        activeExpectedBySides = ({6: 0, 8: 0})
        activeValuesBySides = ({6: [], 8: []})
    }

    function finalizeBatch() {
        if (activeRequestId <= 0 || activeExpectedCount <= 0) {
            return
        }

        var reqId = activeRequestId
        var values6 = (activeValuesBySides[6] || []).slice(0)
        var values8 = (activeValuesBySides[8] || []).slice(0)

        if (values6.length > 0 && values6.length === 1) {
            d6ResultReady(reqId, Number(values6[0]))
        }
        if (values6.length > 0) {
            d6BatchResultReady(reqId, values6)
            standardBatchResultReady(reqId, 6, values6)
        }
        if (values8.length > 0) {
            standardBatchResultReady(reqId, 8, values8)
        }
        hideTimer.restart()
        activeExpectedCount = 0
        activeExpectedBySides = ({6: 0, 8: 0})
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
        if (reqId <= 0 || value <= 0 || (sides !== 6 && sides !== 8)) {
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
            6: (activeValuesBySides[6] || []).slice(0),
            8: (activeValuesBySides[8] || []).slice(0)
        })
        bySides[sides] = bySides[sides].concat([value])
        if (bySides[sides].length > expected) {
            bySides[sides] = bySides[sides].slice(0, expected)
        }
        activeValuesBySides = bySides

        var landedTotal = Number((activeValuesBySides[6] || []).length) + Number((activeValuesBySides[8] || []).length)
        if (landedTotal >= Number(activeExpectedCount || 0)) {
            finalizeBatch()
            return
        }
    }

    WebEngineView {
        id: web
        anchors.fill: parent
        visible: false
        opacity: 0.0
        backgroundColor: "transparent"
        url: Qt.resolvedUrl("../../web/dice_physics.html")
        enabled: false
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

    Timer {
        id: hideTimer
        interval: 6000
        repeat: false
        onTriggered: {}
    }
}
