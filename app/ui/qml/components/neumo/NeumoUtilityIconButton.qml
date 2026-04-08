import QtQuick
import QtQuick.Controls

Item {
    id: root
    property var theme
    property string iconSource: ""
    property string glyph: ""
    property string toolTip: ""
    property real tipX: 0
    property real tipY: 0
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

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: hitArea.pressed
            ? (root.theme ? root.theme.utilityIconPressedFillColor : "#646464")
            : (hitArea.containsMouse ? (root.theme ? root.theme.utilityIconHoverFillColor : "#555555") : "transparent")
        border.width: hitArea.containsMouse ? 1 : 0
        border.color: root.theme ? root.theme.utilityIconBorderColor : "#969696"
        Behavior on color { ColorAnimation { duration: 90 } }
    }

    Image {
        anchors.centerIn: parent
        width: 14
        height: 14
        visible: root.iconSource.length > 0
        source: root.iconSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    Text {
        anchors.centerIn: parent
        visible: root.iconSource.length === 0 && root.glyph.length > 0
        text: root.glyph
        color: root.theme ? root.theme.textPrimary : "#E8E8E8"
        font.pixelSize: 16
        font.weight: Font.DemiBold
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
