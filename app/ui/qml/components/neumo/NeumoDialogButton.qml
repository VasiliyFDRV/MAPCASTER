import QtQuick
import QtQuick.Controls

AbstractButton {
    id: control
    property var theme
    property bool accent: false

    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    activeFocusOnTab: false
    implicitHeight: 36
    font.pixelSize: 13

    contentItem: Text {
        text: control.text
        color: control.enabled
            ? (control.accent
                ? (control.theme ? control.theme.dialogButtonAccentTextColor : "#F7F7F8")
                : (control.theme ? control.theme.dialogButtonTextColor : "#D0D0D0"))
            : (control.theme ? control.theme.dialogButtonDisabledTextColor : "#8A8A8A")
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: control.font.pixelSize
        font.weight: control.accent ? Font.DemiBold : Font.Medium
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: 12
        border.width: 1
        border.color: control.accent
            ? (control.theme ? control.theme.dialogButtonAccentBorderColor : "#B4B4B4")
            : (control.theme ? control.theme.dialogButtonBorderColor : "#505050")
        opacity: control.enabled ? 1.0 : 0.5
        gradient: Gradient {
            GradientStop {
                position: 0
                color: control.accent
                    ? (control.down
                        ? (control.theme ? control.theme.dialogButtonAccentTopPressedColor : "#727272")
                        : (control.hovered
                            ? (control.theme ? control.theme.dialogButtonAccentTopHoverColor : "#858585")
                            : (control.theme ? control.theme.dialogButtonAccentTopColor : "#7D7D7D")))
                    : (control.down
                        ? (control.theme ? control.theme.dialogButtonTopPressedColor : "#323232")
                        : (control.hovered
                            ? (control.theme ? control.theme.dialogButtonTopHoverColor : "#3B3B3B")
                            : (control.theme ? control.theme.dialogButtonTopColor : "#363636")))
            }
            GradientStop {
                position: 1
                color: control.accent
                    ? (control.down
                        ? (control.theme ? control.theme.dialogButtonAccentBottomPressedColor : "#666666")
                        : (control.hovered
                            ? (control.theme ? control.theme.dialogButtonAccentBottomHoverColor : "#747474")
                            : (control.theme ? control.theme.dialogButtonAccentBottomColor : "#6E6E6E")))
                    : (control.down
                        ? (control.theme ? control.theme.dialogButtonBottomPressedColor : "#292929")
                        : (control.hovered
                            ? (control.theme ? control.theme.dialogButtonBottomHoverColor : "#323232")
                            : (control.theme ? control.theme.dialogButtonBottomColor : "#2D2D2D")))
            }
        }
        scale: control.down
            ? (control.theme ? control.theme.dialogButtonPressScale : 0.97)
            : (control.hovered ? (control.theme ? control.theme.dialogButtonHoverScale : 1.025) : 1.0)

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }
    }
}
