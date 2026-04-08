import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
Item {
    id: root
    property var theme
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
        scale: hitArea.pressed ? (root.theme ? root.theme.ghostActionPressScale : 0.92) : 1.0
        y: hitArea.pressed ? (root.theme ? root.theme.ghostActionPressYOffset : 1) : 0
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
                mipmap: false
                sourceSize.width: Math.round(width * 2)
                sourceSize.height: Math.round(height * 2)
                opacity: 0.0
            }
            ColorOverlay {
                anchors.fill: shadowIconImage
                source: shadowIconImage
                visible: shadowIconImage.visible
                color: root.theme ? root.theme.ghostActionShadowColor : '#151618'
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
            anchors.verticalCenterOffset: root.theme ? root.theme.ghostActionPressYOffset : 1
            width: shadowSourceItem.width + ((root.theme ? root.theme.ghostActionShadowBlur : 6) * 2)
            height: shadowSourceItem.height + ((root.theme ? root.theme.ghostActionShadowBlur : 6) * 2)
            source: shadowSource
            radius: root.theme ? root.theme.ghostActionShadowBlur : 6
            transparentBorder: true
            opacity: hitArea.pressed
                ? (root.theme ? root.theme.ghostActionShadowPressedAlpha : 0.10)
                : (root.hovered ? (root.theme ? root.theme.ghostActionShadowHoverAlpha : 0.18) : 0.0)
            visible: opacity > 0.001 && shadowIconImage.visible
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
            mipmap: false
            sourceSize.width: Math.round(width * 2)
            sourceSize.height: Math.round(height * 2)
            opacity: 0.0
        }
        ColorOverlay {
            anchors.fill: iconImage
            source: iconImage
            visible: iconImage.visible
            color: hitArea.pressed
                ? (root.theme ? root.theme.ghostActionIconPressedColor : '#DADADA')
                : (root.hovered
                    ? (root.theme ? root.theme.ghostActionIconHoverColor : '#F2F2F2')
                    : (root.rowHovered
                        ? (root.theme ? root.theme.ghostActionIconRowHoverColor : '#969696')
                        : (root.theme ? root.theme.ghostActionIconIdleColor : '#6D6D6D')))
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
            color: '#E6E6E6'
            font.pixelSize: 12
        }
        background: Rectangle {
            radius: 8
            color: '#2B2B2B'
            border.width: 1
            border.color: '#5E5E5E'
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

