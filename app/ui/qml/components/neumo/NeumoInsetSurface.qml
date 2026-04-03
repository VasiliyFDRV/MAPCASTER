import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property var theme
    property real radius: theme ? theme.insetRadius : 20
    property color fillColor: theme ? theme.baseColor : "#2D2D2D"
    property real insetOffset: theme ? theme.insetOffset : 6
    property real insetDarkRadius: theme ? theme.insetDarkRadius : 12
    property int insetDarkSamples: theme ? theme.insetDarkSamples : 31
    property color insetDarkColor: theme ? theme.insetDarkColor : "#CC151618"
    property real insetLightOffset: theme ? theme.insetLightOffset : -6
    property real insetLightRadius: theme ? theme.insetLightRadius : 10
    property int insetLightSamples: theme ? theme.insetLightSamples : 25
    property color insetLightColor: theme ? theme.insetLightColor : "#663B3C40"
    property real contentPadding: 0
    default property alias contentData: contentItem.data

    Rectangle {
        id: insetBase
        anchors.fill: parent
        radius: root.radius
        color: root.fillColor
    }

    InnerShadow {
        id: insetDark
        anchors.fill: insetBase
        source: insetBase
        horizontalOffset: root.insetOffset
        verticalOffset: root.insetOffset
        radius: root.insetDarkRadius
        samples: root.insetDarkSamples
        color: root.insetDarkColor
    }

    InnerShadow {
        anchors.fill: insetBase
        source: insetDark
        horizontalOffset: root.insetLightOffset
        verticalOffset: root.insetLightOffset
        radius: root.insetLightRadius
        samples: root.insetLightSamples
        color: root.insetLightColor
    }

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}
