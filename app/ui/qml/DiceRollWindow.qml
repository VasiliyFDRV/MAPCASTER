import QtQuick
import QtQuick.Window
import "components"
import "components/neumo"

Window {
    id: rollWindow
    objectName: "diceRollWindow"
    width: 920
    height: 640
    visible: true
    color: "#181A1E"
    title: "DnD Maps - Броски"

    property color textPrimary: "#EFEFF2"
    property color textSecondary: "#B0B0B0"
    property var neumoTheme: NeumoTheme {
        baseColor: "#2D2D2D"
        textPrimary: rollWindow.textPrimary
        textSecondary: rollWindow.textSecondary
    }

    Rectangle {
        anchors.fill: parent
        color: "#17191D"
    }

    DiceVisualHost {
        id: diceVisualHost
        anchors.fill: parent
        visualTarget: "roll_window"
        includeFallback2D: false
        overlayZ: 10
        fallbackOverlayZ: 9
    }
}
