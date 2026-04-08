import QtQuick

Item {
    id: toggleRoot

    property var theme
    property bool checked: false

    readonly property bool hovered: hitArea.containsMouse && toggleRoot.enabled
    readonly property bool pressed: hitArea.pressed && toggleRoot.enabled

    property color knobBaseColor: checked
        ? (theme ? theme.toggleKnobOnBaseColor : "#4A5260")
        : (theme ? theme.toggleKnobOffBaseColor : "#343941")
    property color knobLightColor: checked
        ? (theme ? theme.toggleKnobOnLightColor : "#687285")
        : (theme ? theme.toggleKnobOffLightColor : "#4B5160")
    property color knobDarkColor: checked
        ? (theme ? theme.toggleKnobOnDarkColor : "#38404D")
        : (theme ? theme.toggleKnobOffDarkColor : "#272C34")
    property color knobBorderColor: checked
        ? (theme ? theme.toggleKnobOnBorderColor : "#788399")
        : (theme ? theme.toggleKnobOffBorderColor : "#515968")

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

    Behavior on knobBorderColor {
        ColorAnimation { duration: 140 }
    }

    NeumoInsetSurface {
        anchors.fill: parent
        theme: toggleRoot.theme
        radius: height / 2
        fillColor: theme ? theme.toggleTrackColor : "#2D2D2D"
        contentPadding: 0
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: height / 2
        color: theme ? theme.toggleTrackCheckedTintColor : "#7B8492"
        opacity: checked ? 0.08 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 140 }
        }
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

                var diag = ctx.createLinearGradient(width, 0, 0, height)
                diag.addColorStop(0.0, toCanvasColor(toggleRoot.knobLightColor, 0.94))
                diag.addColorStop(1.0, toCanvasColor(toggleRoot.knobDarkColor, 0.94))
                ctx.fillStyle = diag
                ctx.fillRect(0, 0, width, height)

                var gloss = ctx.createRadialGradient(width * 0.72, height * 0.28, 0, width * 0.72, height * 0.28, width * 0.7)
                gloss.addColorStop(0.0, toCanvasColor(Qt.rgba(1, 1, 1, 1), 0.10))
                gloss.addColorStop(1.0, toCanvasColor(Qt.rgba(1, 1, 1, 0), 0.0))
                ctx.fillStyle = gloss
                ctx.fillRect(0, 0, width, height)
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: knobBorderColor
            opacity: 0.82
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
