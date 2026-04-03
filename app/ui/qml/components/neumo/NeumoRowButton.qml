import QtQuick
import QtQuick.Effects

Item {
    id: rowButton
    property var theme
    property bool dragging: false
    property bool hovered: hoverHandler.hovered
    default property alias contentData: contentWrap.data

    NeumoRaisedSurface {
        id: rowSurface
        anchors.fill: parent
        theme: rowButton.theme
        radius: 13
        fillColor: rowButton.theme ? rowButton.theme.baseColor : "#2D2D2D"
        shadowOffset: rowButton.dragging
            ? (rowButton.theme ? rowButton.theme.rowShadowOffsetDrag : 5)
            : (rowButton.hovered ? (rowButton.theme ? rowButton.theme.rowShadowOffsetHover : 4.5) : (rowButton.theme ? rowButton.theme.rowShadowOffset : 4))
        shadowRadius: rowButton.dragging
            ? (rowButton.theme ? rowButton.theme.rowShadowRadiusDrag : 11)
            : (rowButton.theme ? rowButton.theme.rowShadowRadius : 10)
        shadowSamples: rowButton.theme ? rowButton.theme.rowShadowSamples : 23
        shadowDarkColor: rowButton.dragging
            ? (rowButton.theme ? rowButton.theme.rowShadowDarkColorDrag : "#BC151618")
            : (rowButton.theme ? rowButton.theme.rowShadowDarkColor : "#9E151618")
        shadowLightColor: rowButton.dragging
            ? (rowButton.theme ? rowButton.theme.rowShadowLightColorDrag : "#7C3B3C40")
            : (rowButton.theme ? rowButton.theme.rowShadowLightColor : "#643B3C40")
    }

    Item {
        id: contentWrap
        parent: rowSurface
        anchors.fill: rowSurface
    }

    HoverHandler { id: hoverHandler }
}
