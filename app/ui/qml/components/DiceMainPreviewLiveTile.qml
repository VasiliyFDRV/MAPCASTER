import QtQuick
import QtWebEngine

Item {
    id: root

    property string dieType: "d6"
    property var stylePayload: ({})
    property bool hovered: false
    property bool previewActive: true
    property real previewMargin: 0
    property real referenceSize: 96
    property url sourceUrl: Qt.resolvedUrl("../../web/dice_physics.html")

    property bool pageReady: false
    property bool hasEverRendered: false
    property string appliedSignature: ""

    function normalizedDieType() {
        return String(dieType || "d6").toLowerCase()
    }

    function currentPresentation() {
        return hovered ? "idle" : "static"
    }

    function sceneSignature() {
        return JSON.stringify({
            "kind": normalizedDieType(),
            "presentation": currentPresentation(),
            "payload": stylePayload || {}
        })
    }

    function applyScene(force) {
        if (!previewActive || !pageReady || !previewWeb) {
            return
        }
        var signature = sceneSignature()
        if (!force && signature === appliedSignature) {
            return
        }
        appliedSignature = signature
        var options = {
            "kind": normalizedDieType(),
            "payload": stylePayload || {},
            "presentation": currentPresentation()
        }
        var script = "(function(){"
        script += "if(window.applyMainPreviewScene){window.applyMainPreviewScene(" + JSON.stringify(options) + ");return true;}"
        script += "if(window.renderPreviewScene){window.renderPreviewScene({variant:'main',presentation:" + JSON.stringify(options.presentation) + ",payload:" + JSON.stringify(options.payload) + ",kind:" + JSON.stringify(options.kind) + "});return true;}"
        script += "return false;"
        script += "})();"
        previewWeb.runJavaScript(script, function(_) {
            root.hasEverRendered = true
        })
    }

    Item {
        id: viewportFrame
        anchors.fill: parent
        anchors.margins: root.previewMargin
        clip: true

        Item {
            id: viewportRoot
            anchors.centerIn: parent
            width: root.referenceSize
            height: root.referenceSize
            scale: Math.min(viewportFrame.width / width, viewportFrame.height / height)
            transformOrigin: Item.Center

            WebEngineView {
                id: previewWeb
                anchors.fill: parent
                visible: true
                enabled: false
                focus: false
                backgroundColor: "#00000000"
                url: root.sourceUrl
                opacity: root.hasEverRendered ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                }

                onLoadingChanged: function(req) {
                    if (req.status === WebEngineView.LoadFailedStatus) {
                        root.pageReady = false
                        return
                    }
                    if (req.status === WebEngineView.LoadSucceededStatus) {
                        root.pageReady = true
                        root.applyScene(true)
                    }
                }
            }
        }

        Item {
            id: loaderRoot
            anchors.centerIn: parent
            width: 26
            height: 10
            visible: !root.hasEverRendered

            Row {
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: 3

                    Rectangle {
                        required property int index
                        width: 6
                        height: 6
                        radius: 3
                        color: "#B8B8BA"
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
    }

    onDieTypeChanged: applyScene(true)
    onStylePayloadChanged: applyScene(true)
    onHoveredChanged: applyScene(false)
    onPreviewActiveChanged: {
        if (previewActive) {
            applyScene(true)
        }
    }
}
