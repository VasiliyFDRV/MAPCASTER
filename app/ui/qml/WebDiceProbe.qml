import QtQuick
import QtQuick.Window
import QtWebEngine

Window {
    id: root
    width: 960
    height: 640
    visible: true
    color: "#0f1116"
    title: "MAPCASTER Web Dice Probe"

    WebEngineView {
        id: web
        anchors.fill: parent
        url: Qt.resolvedUrl("../web/dice_web_probe.html")
        onLoadingChanged: function(req) {
            if (req.status === WebEngineView.LoadFailedStatus) {
                console.log("[web-dice-probe] load failed", req.errorString)
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 10
        color: "#00000099"
        radius: 6
        width: 420
        height: 34
        z: 2

        Text {
            anchors.centerIn: parent
            color: "#E6EAF2"
            font.pixelSize: 13
            text: "Если куб и тень двигаются: WebEngine-рендер работает"
        }
    }
}
