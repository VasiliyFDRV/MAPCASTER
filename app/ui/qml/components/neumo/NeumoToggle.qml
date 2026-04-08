import QtQuick

Item {
    id: toggleRoot

    property var theme
    property bool checked: false

    readonly property bool hovered: hitArea.containsMouse && toggleRoot.enabled
    readonly property bool pressed: hitArea.pressed && toggleRoot.enabled

    property color knobBaseColor: checked
        ? (theme ? theme.toggleKnobOnBaseColor : "#7A828F")
        : (theme ? theme.toggleKnobOffBaseColor : "#565A62")
    property color knobLightColor: checked
        ? (theme ? theme.toggleKnobOnLightColor : "#C4CCD9")
        : (theme ? theme.toggleKnobOffLightColor : "#7D838D")
    property color knobDarkColor: checked
        ? (theme ? theme.toggleKnobOnDarkColor : "#5A6372")
        : (theme ? theme.toggleKnobOffDarkColor : "#3E444E")
    property color knobBorderColor: checked
        ? (theme ? theme.toggleKnobOnBorderColor : "#C1C9D8")
        : (theme ? theme.toggleKnobOffBorderColor : "#6E7480")

    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    scale: hovered ? (theme ? theme.toggleHoverScale : 1.015) : 1.0

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
        fillColor: theme ? theme.fieldInsetFillColor : "#262626"
        contentPadding: 0
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border.width: 1
        border.color: checked
            ? (theme ? theme.toggleTrackCheckedBorderColor : "#6A6F78")
            : (theme ? theme.toggleTrackNeutralBorderColor : "#5F646D")
        opacity: 0.9

        Behavior on border.color {
            ColorAnimation { duration: 140 }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: height / 2
        color: theme ? theme.toggleTrackCheckedTintColor : "#8A909A"
        opacity: checked ? 0.13 : 0.0

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
        scale: toggleRoot.pressed ? (theme ? theme.togglePressScale : 0.97) : 1.0

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
            shadowOffset: 2.1
            shadowRadius: 4.8
            shadowSamples: 17
            shadowDarkColor: theme
                ? Qt.rgba(theme.shadowDarkBase.r, theme.shadowDarkBase.g, theme.shadowDarkBase.b, 0.55)
                : "#8C151618"
            shadowLightColor: theme
                ? Qt.rgba(theme.shadowLightBase.r, theme.shadowLightBase.g, theme.shadowLightBase.b, 0.26)
                : "#4255565C"
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
                diag.addColorStop(0.0, toCanvasColor(toggleRoot.knobLightColor, 0.98))
                diag.addColorStop(1.0, toCanvasColor(toggleRoot.knobDarkColor, 0.98))
                ctx.fillStyle = diag
                ctx.fillRect(0, 0, width, height)

                var gloss = ctx.createRadialGradient(width * 0.74, height * 0.26, 0, width * 0.74, height * 0.26, width * 0.72)
                gloss.addColorStop(0.0, toCanvasColor(Qt.rgba(1, 1, 1, 1), 0.22))
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
            opacity: 0.9
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
