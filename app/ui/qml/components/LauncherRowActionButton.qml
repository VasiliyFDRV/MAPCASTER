import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property string iconSource: ""
    property string toolTip: ""
    property bool rowHovered: false
    property real tipX: 0
    property real tipY: 0
    readonly property bool hovered: hitArea.containsMouse && root.enabled && !hitArea.pressed
    signal clicked()
    width: 24
    height: 24

    function updateTipPosition() {
        if (!tipPopup.visible || !tipPopup.parent) {
            return
        }
        var p = root.mapToItem(tipPopup.parent, root.width / 2, 0)
        var xPos = Math.round(p.x - tipPopup.width / 2)
        var yPos = Math.round(p.y - tipPopup.height - 8)
        var maxX = Math.max(0, tipPopup.parent.width - tipPopup.width)
        var maxY = Math.max(0, tipPopup.parent.height - tipPopup.height)
        root.tipX = Math.max(0, Math.min(xPos, maxX))
        root.tipY = Math.max(0, Math.min(yPos, maxY))
    }

    Item {
        id: motionRoot
        anchors.fill: parent
        scale: hitArea.pressed ? 0.88 : (root.hovered ? 1.06 : 1.0)
        y: hitArea.pressed ? 1 : 0

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
        }

        Item {
            id: shadowSourceItem
            anchors.centerIn: parent
            width: 14
            height: 14
            visible: false

            Image {
                id: shadowIconImage
                anchors.fill: parent
                visible: root.iconSource.length > 0
                source: root.iconSource
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                opacity: 0.0
            }

            ColorOverlay {
                anchors.fill: shadowIconImage
                source: shadowIconImage
                visible: shadowIconImage.visible
                color: "#060606"
            }
        }

        ShaderEffectSource {
            id: shadowSource
            sourceItem: shadowSourceItem
            hideSource: true
            live: true
            visible: false
        }

        FastBlur {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            width: 22
            height: 22
            source: shadowSource
            radius: 12
            transparentBorder: true
            opacity: root.hovered ? 0.46 : 0.0
            visible: opacity > 0.001

            Behavior on opacity {
                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
            }
        }

        Image {
            id: iconImage
            anchors.centerIn: parent
            width: 14
            height: 14
            visible: root.iconSource.length > 0
            source: root.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: 0.0
        }

        ColorOverlay {
            anchors.fill: iconImage
            source: iconImage
            visible: iconImage.visible
            color: hitArea.pressed
                ? "#DADADA"
                : (root.hovered ? "#F2F2F2" : (root.rowHovered ? "#969696" : "#6D6D6D"))

            Behavior on color {
                ColorAnimation { duration: 130 }
            }
        }
    }

    Popup {
        id: tipPopup
        parent: Overlay.overlay
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        visible: hitArea.containsMouse && root.toolTip.length > 0
        x: root.tipX
        y: root.tipY
        padding: 8

        onVisibleChanged: root.updateTipPosition()
        onWidthChanged: root.updateTipPosition()
        onHeightChanged: root.updateTipPosition()

        Connections {
            target: tipPopup.parent
            enabled: tipPopup.visible && target !== null

            function onWidthChanged() { root.updateTipPosition() }
            function onHeightChanged() { root.updateTipPosition() }
        }

        contentItem: Text {
            text: root.toolTip
            color: "#E6E6E6"
            font.pixelSize: 12
        }

        background: Rectangle {
            radius: 8
            color: "#2B2B2B"
            border.width: 1
            border.color: "#5E5E5E"
        }
    }

    MouseArea {
        id: hitArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        onPositionChanged: root.updateTipPosition()
        onEntered: root.updateTipPosition()
        onClicked: root.clicked()
    }
}
