import QtQuick
import QtQuick.Effects

Item {
    id: root
    property var theme
    property real radius: theme ? theme.raisedRadius : 18
    property color fillColor: theme ? theme.baseColor : "#2D2D2D"
    property real shadowOffset: theme ? theme.raisedShadowOffset : 6
    property real shadowRadius: theme ? theme.raisedShadowRadius : 12
    property int shadowSamples: theme ? theme.raisedShadowSamples : 25
    property color shadowDarkColor: theme ? theme.raisedShadowDarkColor : "#B8151618"
    property color shadowLightColor: theme ? theme.raisedShadowLightColor : "#703B3C40"
    property real contentPadding: 0
    default property alias contentData: contentItem.data
    clip: false

    Rectangle {
        id: base
        anchors.fill: parent
        radius: root.radius
        color: root.fillColor
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: root.shadowOffset
            verticalOffset: root.shadowOffset
            radius: root.shadowRadius
            samples: root.shadowSamples
            color: root.shadowDarkColor
        }
    }

    DropShadow {
        anchors.fill: base
        source: base
        transparentBorder: true
        horizontalOffset: -root.shadowOffset
        verticalOffset: -root.shadowOffset
        radius: root.shadowRadius
        samples: root.shadowSamples
        color: root.shadowLightColor
        z: -1
    }

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}
