import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

AbstractButton {
    id: control
    property var theme
    property bool accent: false
    property real baseShadowOffset: 4.8
    property real baseShadowRadius: 10.6
    property real hoverShadowOffset: 5.6
    property real hoverShadowRadius: 11.8
    property real pressedShadowOffset: 4.0
    property real pressedShadowRadius: 8.8
    property int shadowSamples: 23

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

    background: Item {
        opacity: control.enabled ? 1.0 : 0.5

        Rectangle {
            id: face
            anchors.fill: parent
            radius: 12
            border.width: 1
            border.color: control.accent
                ? (control.theme ? control.theme.dialogButtonAccentBorderColor : "#B4B4B4")
                : (control.theme ? control.theme.dialogButtonBorderColor : "#505050")
            scale: control.down
                ? 0.985
                : (control.hovered ? (control.theme ? control.theme.dialogButtonHoverScale : 1.025) : 1.0)
            transformOrigin: Item.Center
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: control.accent
                        ? (control.hovered
                            ? (control.theme ? control.theme.dialogButtonAccentTopHoverColor : "#858585")
                            : (control.theme ? control.theme.dialogButtonAccentTopColor : "#7D7D7D"))
                        : (control.hovered
                            ? (control.theme ? control.theme.dialogButtonTopHoverColor : "#3B3B3B")
                            : (control.theme ? control.theme.dialogButtonTopColor : "#363636"))
                }
                GradientStop {
                    position: 1
                    color: control.accent
                        ? (control.hovered
                            ? (control.theme ? control.theme.dialogButtonAccentBottomHoverColor : "#747474")
                            : (control.theme ? control.theme.dialogButtonAccentBottomColor : "#6E6E6E"))
                        : (control.hovered
                            ? (control.theme ? control.theme.dialogButtonBottomHoverColor : "#323232")
                            : (control.theme ? control.theme.dialogButtonBottomColor : "#2D2D2D"))
                }
            }

            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }
        }

        DropShadow {
            anchors.fill: face
            source: face
            transparentBorder: true
            horizontalOffset: control.down
                ? control.pressedShadowOffset
                : (control.hovered ? control.hoverShadowOffset : control.baseShadowOffset)
            verticalOffset: control.down
                ? control.pressedShadowOffset
                : (control.hovered ? control.hoverShadowOffset : control.baseShadowOffset)
            radius: control.down
                ? control.pressedShadowRadius
                : (control.hovered ? control.hoverShadowRadius : control.baseShadowRadius)
            samples: control.shadowSamples
            color: control.hovered
                ? "#FC151618"
                : "#B8151618"
            z: -1
        }

        DropShadow {
            anchors.fill: face
            source: face
            transparentBorder: true
            horizontalOffset: control.down
                ? -control.pressedShadowOffset
                : -(control.hovered ? control.hoverShadowOffset : control.baseShadowOffset)
            verticalOffset: control.down
                ? -control.pressedShadowOffset
                : -(control.hovered ? control.hoverShadowOffset : control.baseShadowOffset)
            radius: control.down
                ? control.pressedShadowRadius
                : (control.hovered ? control.hoverShadowRadius : control.baseShadowRadius)
            samples: control.shadowSamples
            color: control.hovered
                ? "#AD55565C"
                : "#703B3C40"
            z: -2
        }

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }
}
