import QtQuick
import QtQuick.Controls

Item {
    id: root
    property var theme
    property bool enabled: true
    property real radius: theme ? theme.insetRadius : 20
    property real contentPadding: 10
    property string toolTip: ""
    readonly property bool hovered: hitArea.containsMouse && root.enabled
    readonly property bool pressed: hitArea.pressed && root.enabled
    default property alias contentData: contentSlot.data
    signal clicked()

    implicitWidth: 120
    implicitHeight: 54

    NeumoInsetSurface {
        anchors.fill: parent
        theme: root.theme
        radius: root.radius
        fillColor: root.theme ? root.theme.baseColor : "#2D2D2D"
        insetDarkColor: root.theme
            ? Qt.rgba(root.theme.shadowDarkBase.r, root.theme.shadowDarkBase.g, root.theme.shadowDarkBase.b,
                Math.min(1.0, root.theme.insetDarkAlpha + (root.hovered ? 0.14 : 0.0)))
            : "#CC151618"
        insetLightColor: root.theme
            ? Qt.rgba(root.theme.shadowLightBase.r, root.theme.shadowLightBase.g, root.theme.shadowLightBase.b,
                Math.min(1.0, root.theme.insetLightAlpha + (root.hovered ? 0.08 : 0.0)))
            : "#663B3C40"
        scale: root.pressed ? 0.992 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
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
    }

    ToolTip.visible: hitArea.containsMouse && root.toolTip.length > 0
    ToolTip.delay: 250
    ToolTip.timeout: 3000
    ToolTip.text: root.toolTip
}
