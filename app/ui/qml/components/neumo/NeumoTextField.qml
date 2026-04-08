import QtQuick
import QtQuick.Controls

TextField {
    id: control

    property var theme
    property real cornerRadius: 12
    property color surfaceColor: control.theme ? control.theme.fieldInsetFillColor : "#262626"
    property color outlineColor: control.activeFocus
        ? (control.theme ? control.theme.fieldBorderFocusColor : "#ABABAB")
        : (control.hovered
            ? (control.theme ? control.theme.fieldBorderHoverColor : "#626262")
            : (control.theme ? control.theme.fieldBorderColor : "#4D4D4D"))

    color: control.theme ? control.theme.textPrimary : "#D0D0D0"
    selectedTextColor: control.theme ? control.theme.fieldSelectedTextColor : "#F4F4F6"
    selectionColor: control.theme ? control.theme.fieldSelectionColor : "#6C6C6C"
    placeholderTextColor: control.theme ? control.theme.fieldPlaceholderColor : "#909090"
    padding: 0
    leftPadding: 14
    rightPadding: 14
    topPadding: 11
    bottomPadding: 11

    background: Item {
        implicitWidth: 180
        implicitHeight: 42

        NeumoInsetSurface {
            anchors.fill: parent
            theme: control.theme
            radius: control.cornerRadius
            fillColor: control.surfaceColor
            contentPadding: 0
        }

        Rectangle {
            anchors.fill: parent
            radius: control.cornerRadius
            color: "transparent"
            border.width: 1
            border.color: control.outlineColor
            opacity: control.enabled ? 1.0 : 0.55

            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }
    }
}
