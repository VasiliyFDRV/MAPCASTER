import QtQuick

Item {
    id: toggleRoot

    property var theme
    property bool checked: false
    readonly property bool hovered: hitArea.containsMouse && toggleRoot.enabled
    readonly property bool pressed: hitArea.pressed && toggleRoot.enabled

    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight
    scale: hovered ? (theme ? theme.toggleHoverScale : 1.02) : 1.0

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    NeumoInsetSurface {
        id: trackSurface
        anchors.fill: parent
        theme: toggleRoot.theme
        radius: height / 2
        fillColor: theme ? theme.fieldInsetFillColor : "#262626"
        contentPadding: 0
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: toggleRoot.checked
            ? (theme ? theme.toggleTrackCheckedColor : "#646464")
            : (theme ? theme.toggleTrackColor : "#353535")
        opacity: toggleRoot.checked ? 0.34 : 0.14
        border.width: 1
        border.color: toggleRoot.checked
            ? (theme ? theme.toggleTrackCheckedBorderColor : "#A8A8A8")
            : (theme ? theme.toggleTrackBorderColor : "#5C5C5C")

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }
    }

    Item {
        id: knobWrap
        width: toggleRoot.height - 8
        height: width
        x: toggleRoot.checked ? toggleRoot.width - width - 4 : 4
        y: ((toggleRoot.height - height) / 2) + (toggleRoot.pressed ? (theme ? theme.togglePressYOffset : 1) : 0)
        scale: toggleRoot.pressed ? (theme ? theme.togglePressScale : 0.985) : 1.0

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
            fillColor: theme ? theme.toggleKnobColor : "#EAEAEA"
            shadowOffset: 2.2
            shadowRadius: 5.2
            shadowSamples: 17
            shadowDarkColor: theme
                ? Qt.rgba(theme.shadowDarkBase.r, theme.shadowDarkBase.g, theme.shadowDarkBase.b, 0.55)
                : "#8C151618"
            shadowLightColor: theme
                ? Qt.rgba(theme.shadowLightBase.r, theme.shadowLightBase.g, theme.shadowLightBase.b, 0.30)
                : "#4D55565C"
            contentPadding: 0
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: theme ? theme.toggleKnobBorderColor : "#B2B2B2"
            opacity: 0.95
        }
    }

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
