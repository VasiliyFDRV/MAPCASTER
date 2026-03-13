import QtQuick
import QtWebEngine

Item {
    id: root
    anchors.fill: parent

    property bool active: false
    property bool pageReady: false
    property bool pendingRoll: false

    function runD6Script() {
        web.runJavaScript("window.startD6Roll && window.startD6Roll();")
    }

    function triggerD6() {
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


