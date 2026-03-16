import QtQuick
import QtWebEngine

Item {
    id: root
    anchors.fill: parent

    property bool active: false
    property bool pageReady: false
    property bool pendingRoll: false
    property int pendingRequestId: 0

    signal d6ResultReady(int requestId, int value)

    function runD6Script() {
        var req = Number(pendingRequestId || 0)
        web.runJavaScript("window.startD6Roll && window.startD6Roll(" + String(req) + ");")
    }

    function triggerD6(requestId) {
        pendingRequestId = Number(requestId || 0)
        active = true
        web.visible = true
        web.opacity = 1.0
        hideTimer.restart()

        if (pageReady) {
            runD6Script()
            pendingRoll = false
        } else {
            pendingRoll = true
            web.reload()
        }
    }

    function clear() {
        active = false
        web.opacity = 0.0
        web.visible = false
        pendingRoll = false
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
        d6ResultReady(reqId, value)
    }

    WebEngineView {
        id: web
        anchors.fill: parent
        visible: false
        opacity: 0.0
        backgroundColor: "transparent"
        url: Qt.resolvedUrl("../../web/dice_physics.html")
        enabled: root.active
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
                    root.runD6Script()
                    root.pendingRoll = false
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 4500
        repeat: false
        onTriggered: root.clear()
    }
}
