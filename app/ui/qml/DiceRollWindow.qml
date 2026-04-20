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
    readonly property real cardRadius: 18
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
        var deltaR = neumoTheme.shadowLightBase.r - neumoTheme.baseColor.r
        var deltaG = neumoTheme.shadowLightBase.g - neumoTheme.baseColor.g
        var deltaB = neumoTheme.shadowLightBase.b - neumoTheme.baseColor.b
        var r = Math.min(1, resultsFillColor.r + deltaR)
        var g = Math.min(1, resultsFillColor.g + deltaG)
        var b = Math.min(1, resultsFillColor.b + deltaB)
        return Qt.rgba(r, g, b, neumoTheme.insetLightAlpha / 1.5)
    }

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
        radius: cardRadius
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
