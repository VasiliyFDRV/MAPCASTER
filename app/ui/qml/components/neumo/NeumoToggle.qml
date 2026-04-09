import QtQuick

Item {
    id: toggleRoot

    property var theme
    property bool checked: false

    readonly property bool hovered: hitArea.containsMouse && toggleRoot.enabled
    readonly property bool pressed: hitArea.pressed && toggleRoot.enabled
    readonly property real trackInsetDarkAlpha: Math.min(
        1.0,
        (theme && theme.insetDarkAlpha !== undefined ? theme.insetDarkAlpha : 0.86)
            + (pressed ? 0.14 : (hovered ? 0.24 : 0.0))
    )
    readonly property real trackInsetLightAlpha: Math.min(
        1.0,
        (theme && theme.insetLightAlpha !== undefined ? theme.insetLightAlpha : 0.60)
            + (pressed ? 0.10 : (hovered ? 0.18 : 0.0))
    )

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

    scale: 1.0

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
        insetOffset: theme ? theme.insetOffset : 6
        insetDarkRadius: theme ? theme.insetDarkRadius : 9.5
        insetDarkColor: theme
            ? Qt.rgba(theme.shadowDarkBase.r, theme.shadowDarkBase.g, theme.shadowDarkBase.b, toggleRoot.trackInsetDarkAlpha)
            : "#CC151618"
        insetLightOffset: theme ? theme.insetLightOffset : -6
        insetLightRadius: theme ? theme.insetLightRadius : 7.5
        insetLightColor: theme
            ? Qt.rgba(theme.shadowLightBase.r, theme.shadowLightBase.g, theme.shadowLightBase.b, toggleRoot.trackInsetLightAlpha)
            : "#663B3C40"
    }

    Item {
        id: knobWrap
        width: toggleRoot.height - 8
        height: width
        x: toggleRoot.checked ? toggleRoot.width - width - 4 : 4
        y: ((toggleRoot.height - height) / 2) + (toggleRoot.pressed ? ((theme && theme.togglePressYOffset !== undefined) ? theme.togglePressYOffset : 1) : 0)
        scale: toggleRoot.pressed ? ((theme && theme.togglePressScale !== undefined) ? theme.togglePressScale : 0.975) : 1.0

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
            shadowOffset: toggleRoot.pressed
                ? ((theme && theme.toggleKnobShadowOffsetPressed !== undefined) ? theme.toggleKnobShadowOffsetPressed : 2.1)
                : (toggleRoot.hovered
                    ? ((theme && theme.toggleKnobShadowOffsetHover !== undefined) ? theme.toggleKnobShadowOffsetHover : 3.6)
                    : ((theme && theme.toggleKnobShadowOffset !== undefined) ? theme.toggleKnobShadowOffset : 2.6))
            shadowRadius: toggleRoot.pressed
                ? ((theme && theme.toggleKnobShadowRadiusPressed !== undefined) ? theme.toggleKnobShadowRadiusPressed : 4.6)
                : (toggleRoot.hovered
                    ? ((theme && theme.toggleKnobShadowRadiusHover !== undefined) ? theme.toggleKnobShadowRadiusHover : 7.4)
                    : ((theme && theme.toggleKnobShadowRadius !== undefined) ? theme.toggleKnobShadowRadius : 5.8))
            shadowSamples: 17
            shadowDarkColor: theme
                ? Qt.rgba(
                    theme.shadowDarkBase.r,
                    theme.shadowDarkBase.g,
                    theme.shadowDarkBase.b,
                    toggleRoot.pressed
                        ? ((theme && theme.toggleKnobShadowDarkAlphaPressed !== undefined) ? theme.toggleKnobShadowDarkAlphaPressed : 0.54)
                        : (toggleRoot.hovered
                            ? ((theme && theme.toggleKnobShadowDarkAlphaHover !== undefined) ? theme.toggleKnobShadowDarkAlphaHover : 0.78)
                            : ((theme && theme.toggleKnobShadowDarkAlpha !== undefined) ? theme.toggleKnobShadowDarkAlpha : 0.62)))
                : "#80151618"
            shadowLightColor: theme
                ? Qt.rgba(
                    theme.shadowLightBase.r,
                    theme.shadowLightBase.g,
                    theme.shadowLightBase.b,
                    (theme && theme.toggleKnobShadowLightAlpha !== undefined) ? theme.toggleKnobShadowLightAlpha : 0.28)
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
                var alphaMul = toggleRoot.hovered
                    ? ((toggleRoot.theme && toggleRoot.theme.toggleKnobGradientAlphaHover !== undefined) ? toggleRoot.theme.toggleKnobGradientAlphaHover : 1.08)
                    : ((toggleRoot.theme && toggleRoot.theme.toggleKnobGradientAlpha !== undefined) ? toggleRoot.theme.toggleKnobGradientAlpha : 0.98)
                diag.addColorStop(0.0, toCanvasColor(toggleRoot.knobLightColor, alphaMul))
                diag.addColorStop(1.0, toCanvasColor(toggleRoot.knobDarkColor, alphaMul))
                ctx.fillStyle = diag
                ctx.fillRect(0, 0, width, height)

                var gloss = ctx.createRadialGradient(width * 0.28, height * 0.22, 0, width * 0.28, height * 0.22, width * 0.72)
                gloss.addColorStop(0.0, toCanvasColor(Qt.rgba(1, 1, 1, 1), toggleRoot.hovered ? 0.12 : 0.08))
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
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggleRoot.checked = !toggleRoot.checked
            toggleRoot.toggled(toggleRoot.checked)
        }
    }
}
