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
    property var activeValues: []
    property int pendingD8Count: 0

    signal d6ResultReady(int requestId, int value)
    signal d6BatchResultReady(int requestId, var values)

    function runD6Script(requestId) {
        var req = Number(requestId || activeRequestId || 0)
        web.runJavaScript("window.startD6Roll && window.startD6Roll(" + String(req) + ");")
    }

    function runD8Script() {
        web.runJavaScript("window.startD6Roll && window.startD6Roll(0, 'd8');")
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
        activeValues = []
        pendingD8Count = 0
        for (var i = 0; i < activeExpectedCount; i++) {
            runD6Script(activeRequestId)
        }
        hideTimer.restart()
    }

    function triggerD6(requestId) {
        triggerD6Batch(requestId, 1, false)
    }

    function triggerD8(count) {
        var rolls = Math.max(1, Number(count || 1))
        active = true
        web.visible = true
        web.opacity = 1.0
        hideTimer.restart()

        if (!pageReady) {
            pendingD8Count = pendingD8Count + rolls
            web.reload()
            return
        }
        for (var i = 0; i < rolls; i++) {
            runD8Script()
        }
    }

    function triggerD6Batch(requestId, count, appendMode) {
        var append = Boolean(appendMode)
        var req = Number(requestId || 0)
        var addCount = Math.max(1, Number(count || 1))

        if (req <= 0) {
            return
        }

        var sameActive = append && activeRequestId === req && activeExpectedCount > 0
        if (!sameActive) {
            clearWebDiceNow()
            activeRequestId = req
            activeExpectedCount = addCount
            activeValues = []
        } else {
            activeExpectedCount = activeExpectedCount + addCount
        }

        active = true
        web.visible = true
        web.opacity = 1.0
        hideTimer.restart()

        if (pageReady) {
            pendingRoll = false
            for (var i = 0; i < addCount; i++) {
                runD6Script(activeRequestId)
            }
        } else {
            pendingRoll = true
            web.reload()
        }
    }

    function clear() {
        clearWebDiceNow()
        active = false
        web.opacity = 0.0
        web.visible = false
        pendingRoll = false
        activeRequestId = 0
        activeExpectedCount = 0
        activeValues = []
        pendingD8Count = 0
    }

    function finalizeBatch() {
        if (activeRequestId <= 0 || activeExpectedCount <= 0) {
            return
        }
        if (activeValues.length <= 0) {
            return
        }

        var resultValues = activeValues.slice(0)
        var reqId = activeRequestId
        if (resultValues.length === 1) {
            d6ResultReady(reqId, Number(resultValues[0]))
        }
        d6BatchResultReady(reqId, resultValues)
        hideTimer.restart()
    }

    function tryParseResultMessage(message) {
        var text = String(message || "")
        if (text.indexOf("[dice-result]") !== 0) {
            return
        }

        var reqMatch = /request=(\d+)/.exec(text)
        var valueMatch = /value=(\d+)/.exec(text)
        if (!reqMatch || !valueMatch) {
            return
        }

        var reqId = Number(reqMatch[1])
        var value = Number(valueMatch[1])
        if (reqId <= 0 || value <= 0) {
            return
        }

        if (reqId !== activeRequestId) {
            console.log("[dice-web] ignore stale result req=", reqId, "active=", activeRequestId)
            return
        }

        activeValues = activeValues.concat([value])
        if (activeValues.length >= activeExpectedCount) {
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
                if (root.pendingD8Count > 0) {
                    var d8Count = Number(root.pendingD8Count)
                    root.pendingD8Count = 0
                    for (var i = 0; i < d8Count; i++) {
                        root.runD8Script()
                    }
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
