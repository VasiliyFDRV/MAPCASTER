import QtQuick
import QtQuick.Window
import "components"
import "components/neumo"

Window {
    id: rollWindow
    objectName: "diceRollWindow"
    width: 350
    height: 350
    visible: true
    color: resultsFillColor
    title: "DnD Maps - Броски"

    property color textPrimary: "#EFEFF2"
    property color textSecondary: "#B0B0B0"
    readonly property color resultsFillColor: Qt.rgba(30 / 255, 30 / 255, 30 / 255, 1.0)
    readonly property color resultsInsetDarkColor: Qt.rgba(12 / 255, 13 / 255, 15 / 255, 0.92)
    readonly property color resultsInsetLightColor: Qt.rgba(88 / 255, 90 / 255, 96 / 255, 0.18)

    property var neumoTheme: NeumoTheme {
        baseColor: "#2D2D2D"
        textPrimary: rollWindow.textPrimary
        textSecondary: rollWindow.textSecondary
    }

    Rectangle {
        anchors.fill: parent
        color: resultsFillColor
    }

    NeumoInsetSurface {
        anchors.fill: parent
        anchors.margins: 12
        theme: neumoTheme
        useFrameProfile: true
        radius: 20
        fillColor: resultsFillColor
        insetDarkColor: resultsInsetDarkColor
        insetLightColor: resultsInsetLightColor
        contentPadding: 0

        DiceVisualHost {
            id: diceVisualHost
            anchors.fill: parent
            visualTarget: "roll_window"
            includeFallback2D: false
            overlayZ: 10
            fallbackOverlayZ: 9
        }
    }
}
