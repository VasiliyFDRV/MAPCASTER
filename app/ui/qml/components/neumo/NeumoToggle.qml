import QtQuick

Item {
    id: toggleRoot

    property var theme
    property bool checked: false

    readonly property bool hovered: hitArea.containsMouse && toggleRoot.enabled
    readonly property bool pressed: hitArea.pressed && toggleRoot.enabled

    property color knobBaseColor: checked
        ? (theme ? theme.toggleKnobOnBaseColor : "#55565C")
        : (theme ? theme.toggleKnobOffBaseColor : "#2D2D2D")
    property color knobLightColor: checked
        ? (theme ? theme.toggleKnobOnLightColor : "#D0D0D0")
        : (theme ? theme.toggleKnobOffLightColor : "#55565C")
    property color knobDarkColor: checked
        ? (theme ? theme.toggleKnobOnDarkColor : "#2D2D2D")
        : (theme ? theme.toggleKnobOffDarkColor : "#151618")

    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    scale: hovered ? (theme ? theme.toggleHoverScale : 1.01) : 1.0

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Behavior on knobBaseColor {
        ColorAnimation { duration: 140 }
    }

    Behavior on knobLightColor {
        ColorAnimation { duration: 140 }
    }

    Behavior on knobDarkColor {
        ColorAnimation { duration: 140 }
    }

    NeumoInsetSurface {
        anchors.fill: parent
        theme: toggleRoot.theme
        radius: height / 2
        fillColor: theme ? theme.toggleTrackColor : "#2D2D2D"
        contentPadding: 0
    }

    Item {
        id: knobWrap
        width: toggleRoot.height - 8
        height: width
        x: toggleRoot.checked ? toggleRoot.width - width - 4 : 4
        y: ((toggleRoot.height - height) / 2) + (toggleRoot.pressed ? (theme ? theme.togglePressYOffset : 1) : 0)
        scale: toggleRoot.pressed ? (theme ? theme.togglePressScale : 0.975) : 1.0

        Behavior on x {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
        }

        NeumoRaisedSurface {
            anchors.fill: parent
            theme: toggleRoot.theme
            radius: width / 2
            fillColor: knobBaseColor
            shadowOffset: 2.0
            shadowRadius: 4.4
            shadowSamples: 17
            shadowDarkColor: theme
                ? Qt.rgba(theme.shadowDarkBase.r, theme.shadowDarkBase.g, theme.shadowDarkBase.b, 0.50)
                : "#80151618"
            shadowLightColor: theme
                ? Qt.rgba(theme.shadowLightBase.r, theme.shadowLightBase.g, theme.shadowLightBase.b, 0.20)
                : "#3355565C"
            contentPadding: 0
        }

        Canvas {
            id: knobGradient
            anchors.fill: parent
            antialiasing: true

            function toCanvasColor(c, alphaMul) {
                var a = Math.max(0, Math.min(1, c.a * alphaMul))
                return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")"
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                ctx.beginPath()
                ctx.arc(width / 2, height / 2, Math.max(0, Math.min(width, height) / 2 - 1), 0, Math.PI * 2)
                ctx.closePath()
                ctx.clip()

                var diag = ctx.createLinearGradient(0, 0, width, height)
                diag.addColorStop(0.0, toCanvasColor(toggleRoot.knobLightColor, 0.94))
                diag.addColorStop(1.0, toCanvasColor(toggleRoot.knobDarkColor, 0.94))
                ctx.fillStyle = diag
                ctx.fillRect(0, 0, width, height)

                var gloss = ctx.createRadialGradient(width * 0.28, height * 0.22, 0, width * 0.28, height * 0.22, width * 0.72)
                gloss.addColorStop(0.0, toCanvasColor(Qt.rgba(1, 1, 1, 1), 0.08))
                gloss.addColorStop(1.0, toCanvasColor(Qt.rgba(1, 1, 1, 0), 0.0))
                ctx.fillStyle = gloss
                ctx.fillRect(0, 0, width, height)
            }
        }
    }

    onKnobLightColorChanged: knobGradient.requestPaint()
    onKnobDarkColorChanged: knobGradient.requestPaint()
    Component.onCompleted: knobGradient.requestPaint()

    MouseArea {
        id: hitArea
        anchors.fill: parent
        enabled: toggleRoot.enabled
        hoverEnabled: true
        onClicked: {
            toggleRoot.checked = !toggleRoot.checked
            toggleRoot.toggled(toggleRoot.checked)
        }
    }
}
