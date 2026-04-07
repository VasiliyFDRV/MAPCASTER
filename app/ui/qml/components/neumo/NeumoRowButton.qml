import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

Item {
    id: rowButton
    property var theme
    property bool dragging: false
    property bool hovered: hoverHandler.hovered
    default property alias contentData: contentWrap.data

    Item {
        id: surfaceRoot
        anchors.fill: parent
        scale: rowButton.hovered && !rowButton.dragging ? 1.01 : 1.0
        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 13
            color: rowButton.theme ? rowButton.theme.baseColor : "#2D2D2D"
            border.width: rowButton.theme ? rowButton.theme.borderWidth : 1
            border.color: rowButton.theme ? rowButton.theme.borderColor : Qt.rgba(1, 1, 1, 0.03)
            antialiasing: true
        }

        DropShadow {
            anchors.fill: bg
            source: bg
            transparentBorder: true
            horizontalOffset: rowButton.dragging
                ? (rowButton.theme ? rowButton.theme.rowShadowOffsetDrag : 5)
                : (rowButton.hovered ? (rowButton.theme ? rowButton.theme.rowShadowOffsetHover : 6.1) : (rowButton.theme ? rowButton.theme.rowShadowOffset : 4.5))
            verticalOffset: rowButton.dragging
                ? (rowButton.theme ? rowButton.theme.rowShadowOffsetDrag : 5)
                : (rowButton.hovered ? (rowButton.theme ? rowButton.theme.rowShadowOffsetHover : 6.1) : (rowButton.theme ? rowButton.theme.rowShadowOffset : 4.5))
            radius: rowButton.dragging
                ? (rowButton.theme ? rowButton.theme.rowShadowRadiusDrag : 11)
                : (rowButton.hovered ? (rowButton.theme ? rowButton.theme.rowShadowRadiusHover : 11.4) : (rowButton.theme ? rowButton.theme.rowShadowRadius : 10))
            samples: rowButton.theme ? rowButton.theme.rowShadowSamples : 23
            color: rowButton.dragging
                ? (rowButton.theme ? rowButton.theme.rowShadowDarkColorDrag : "#BC151618")
                : (rowButton.hovered
                    ? (rowButton.theme ? rowButton.theme.rowShadowDarkColorHover : "#FA151618")
                    : (rowButton.theme ? rowButton.theme.rowShadowDarkColor : "#EB151618"))
            visible: true
            z: -1
        }

        DropShadow {
            anchors.fill: bg
            source: bg
            transparentBorder: true
            horizontalOffset: -(rowButton.dragging
                ? (rowButton.theme ? rowButton.theme.rowShadowOffsetDrag : 5)
                : (rowButton.hovered ? (rowButton.theme ? rowButton.theme.rowShadowOffsetHover : 6.1) : (rowButton.theme ? rowButton.theme.rowShadowOffset : 4.5)))
            verticalOffset: -(rowButton.dragging
                ? (rowButton.theme ? rowButton.theme.rowShadowOffsetDrag : 5)
                : (rowButton.hovered ? (rowButton.theme ? rowButton.theme.rowShadowOffsetHover : 6.1) : (rowButton.theme ? rowButton.theme.rowShadowOffset : 4.5)))
            radius: rowButton.dragging
                ? (rowButton.theme ? rowButton.theme.rowShadowRadiusDrag : 11)
                : (rowButton.hovered ? (rowButton.theme ? rowButton.theme.rowShadowRadiusHover : 11.4) : (rowButton.theme ? rowButton.theme.rowShadowRadius : 10))
            samples: rowButton.theme ? rowButton.theme.rowShadowSamples : 23
            color: rowButton.dragging
                ? (rowButton.theme ? rowButton.theme.rowShadowLightColorDrag : "#7C3B3C40")
                : (rowButton.hovered
                    ? (rowButton.theme ? rowButton.theme.rowShadowLightColorHover : "#8555565C")
                    : (rowButton.theme ? rowButton.theme.rowShadowLightColor : "#9955565C"))
            visible: true
            z: -2
        }
    }

    Item {
        id: contentWrap
        anchors.fill: parent
    }

    HoverHandler { id: hoverHandler }
}
