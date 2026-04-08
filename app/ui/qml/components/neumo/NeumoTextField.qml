import QtQuick
import QtQuick.Controls

TextField {
    id: control

    property var theme
    property string visualStyle: "default" // default | launcherInline
    property real cornerRadius: 12

    hoverEnabled: true

    readonly property bool launcherInlineStyle: visualStyle === "launcherInline"

    property color surfaceColor: launcherInlineStyle
        ? (control.theme ? control.theme.fieldInlineFillColor : "#2D2D2D")
        : (control.theme ? control.theme.fieldInsetFillColor : "#262626")

    property color outlineColor: launcherInlineStyle
        ? (control.activeFocus
            ? (control.theme ? control.theme.fieldInlineFocusColor : "#8C8C8C")
            : "transparent")
        : (control.activeFocus
            ? (control.theme ? control.theme.fieldBorderFocusColor : "#ABABAB")
            : (control.hovered
                ? (control.theme ? control.theme.fieldBorderHoverColor : "#626262")
                : (control.theme ? control.theme.fieldBorderColor : "#4D4D4D")))

    property real outlineWidth: launcherInlineStyle ? (control.activeFocus ? 1 : 0) : 1
    property real outlineOpacity: launcherInlineStyle ? 0.9 : (control.enabled ? 1.0 : 0.55)

    color: control.theme ? control.theme.textPrimary : "#D0D0D0"
    selectedTextColor: control.theme ? control.theme.fieldSelectedTextColor : "#F4F4F6"
    selectionColor: control.theme ? control.theme.fieldSelectionColor : "#6C6C6C"
    placeholderTextColor: control.theme ? control.theme.fieldPlaceholderColor : "#909090"

    padding: 0
    leftPadding: launcherInlineStyle ? 10 : 14
    rightPadding: launcherInlineStyle ? 10 : 14
    topPadding: launcherInlineStyle ? 10 : 11
    bottomPadding: launcherInlineStyle ? 10 : 11

    verticalAlignment: TextInput.AlignVCenter

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
            border.width: control.outlineWidth
            border.color: control.outlineColor
            opacity: control.outlineOpacity

            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }
    }
}
