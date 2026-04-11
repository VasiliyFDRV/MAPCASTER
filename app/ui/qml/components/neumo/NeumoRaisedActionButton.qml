import QtQuick
import QtQuick.Controls

Item {
    id: root
    property var theme
    property string text: ""
    property bool enabled: true
    property bool compactMode: false
    property real radius: 16
    property real contentPadding: 10
    property string toolTip: ""
    default property alias contentData: contentSlot.data
    signal clicked()

    implicitHeight: compactMode ? 48 : 52
    implicitWidth: 140

    readonly property bool hovered: hitArea.containsMouse && root.enabled
    readonly property bool pressed: hitArea.pressed && root.enabled
    readonly property real baseShadowOffset: compactMode ? 5.0 : 5.4
    readonly property real baseShadowRadius: compactMode ? 10.8 : 11.2
    readonly property real hoverShadowOffset: compactMode ? 5.7 : 6.2
    readonly property real hoverShadowRadius: compactMode ? 12.0 : 12.6
    readonly property real pressedShadowOffset: compactMode ? 4.2 : 4.5
    readonly property real pressedShadowRadius: compactMode ? 9.8 : 10.2

    NeumoRaisedSurface {
        anchors.fill: parent
        theme: root.theme
        radius: root.radius
        fillColor: root.theme ? root.theme.baseColor : "#2D2D2D"
        shadowOffset: root.pressed
            ? root.pressedShadowOffset
            : (root.hovered ? root.hoverShadowOffset : root.baseShadowOffset)
        shadowRadius: root.pressed
            ? root.pressedShadowRadius
            : (root.hovered ? root.hoverShadowRadius : root.baseShadowRadius)
        shadowSamples: 23
        shadowDarkColor: root.hovered
            ? (root.theme ? root.theme.raisedShadowDarkColorHover : "#FC151618")
            : (root.theme ? root.theme.raisedShadowDarkColor : "#B8151618")
        shadowLightColor: root.hovered
            ? (root.theme ? root.theme.raisedShadowLightColorHover : "#AD55565C")
            : (root.theme ? root.theme.raisedShadowLightColor : "#703B3C40")
        scale: root.pressed ? 0.985 : (root.hovered ? 1.012 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }
        Behavior on shadowOffset {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
        Behavior on shadowRadius {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        MouseArea {
            id: hitArea
            anchors.fill: parent
            enabled: root.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }

        Item {
            id: contentSlot
            anchors.fill: parent
            anchors.margins: root.contentPadding
        }

        Label {
            anchors.centerIn: parent
            visible: root.text.length > 0 && contentSlot.children.length === 0
            text: root.text
            color: root.theme ? root.theme.textPrimary : "#D0D0D0"
            opacity: root.enabled ? 1.0 : 0.45
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }

    ToolTip.visible: hitArea.containsMouse && root.toolTip.length > 0
    ToolTip.delay: 250
    ToolTip.timeout: 3000
    ToolTip.text: root.toolTip
}
