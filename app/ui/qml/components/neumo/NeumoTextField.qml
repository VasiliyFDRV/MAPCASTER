import QtQuick
import QtQuick.Controls

TextField {
    id: control

    property var theme
    property string visualStyle: "default" // default | launcherInline
    property real cornerRadius: 12

    hoverEnabled: true

    readonly property bool launcherInlineStyle: visualStyle === "launcherInline"
    readonly property bool inlineInteractive: launcherInlineStyle && (control.hovered || control.activeFocus)
    readonly property real inlineInsetDarkAlpha: Math.min(
        1.0,
        (control.theme && control.theme.insetDarkAlpha !== undefined ? control.theme.insetDarkAlpha : 0.86)
            + (control.inlineInteractive ? 0.18 : 0.0)
    )
    readonly property real inlineInsetLightAlpha: Math.min(
        1.0,
        (control.theme && control.theme.insetLightAlpha !== undefined ? control.theme.insetLightAlpha : 0.60)
            + (control.inlineInteractive ? 0.12 : 0.0)
    )

    property color surfaceColor: launcherInlineStyle
        ? (control.theme ? control.theme.fieldInlineFillColor : "#2D2D2D")
        : (control.theme ? control.theme.fieldInsetFillColor : "#262626")

    property color inlineOutlineColor: control.theme ? control.theme.fieldInlineFocusColor : "#8C8C8C"

    property color outlineColor: launcherInlineStyle
        ? (control.activeFocus
            ? control.inlineOutlineColor
            : (control.hovered ? control.inlineOutlineColor : "transparent"))
        : (control.activeFocus
            ? (control.theme ? control.theme.fieldBorderFocusColor : "#ABABAB")
            : (control.hovered
                ? (control.theme ? control.theme.fieldBorderHoverColor : "#626262")
                : (control.theme ? control.theme.fieldBorderColor : "#4D4D4D")))

    property real outlineWidth: launcherInlineStyle
        ? (control.activeFocus ? 0.65 : (control.hovered ? 0.45 : 0.0))
        : 1

    property real outlineOpacity: launcherInlineStyle
        ? ((control.activeFocus ? 0.44 : (control.hovered ? 0.24 : 0.0)) * (control.enabled ? 1.0 : 0.55))
        : (control.enabled ? 1.0 : 0.55)

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
            insetOffset: control.theme ? control.theme.insetOffset : 6
            insetDarkRadius: control.theme ? control.theme.insetDarkRadius : 9.5
            insetDarkColor: control.theme
                ? Qt.rgba(control.theme.shadowDarkBase.r, control.theme.shadowDarkBase.g, control.theme.shadowDarkBase.b, control.inlineInsetDarkAlpha)
                : "#CC151618"
            insetLightOffset: control.theme ? control.theme.insetLightOffset : -6
            insetLightRadius: control.theme ? control.theme.insetLightRadius : 7.5
            insetLightColor: control.theme
                ? Qt.rgba(control.theme.shadowLightBase.r, control.theme.shadowLightBase.g, control.theme.shadowLightBase.b, control.inlineInsetLightAlpha)
                : "#663B3C40"
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
