import QtQuick

Item {
    id: root
    property var theme
    property bool useFrameProfile: false
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

    property real effectiveInsetOffset: useFrameProfile
        ? (theme ? theme.frameInsetOffset : insetOffset)
        : insetOffset
    property real effectiveInsetDarkRadius: useFrameProfile
        ? (theme ? theme.frameInsetDarkRadius : insetDarkRadius)
        : insetDarkRadius
    property int effectiveInsetDarkSamples: useFrameProfile
        ? (theme ? theme.frameInsetDarkSamples : insetDarkSamples)
        : insetDarkSamples
    property color effectiveInsetDarkColor: useFrameProfile
        ? (theme ? theme.frameInsetDarkColor : insetDarkColor)
        : insetDarkColor
    property real effectiveInsetLightOffset: useFrameProfile
        ? (theme ? theme.frameInsetLightOffset : insetLightOffset)
        : insetLightOffset
    property real effectiveInsetLightRadius: useFrameProfile
        ? (theme ? theme.frameInsetLightRadius : insetLightRadius)
        : insetLightRadius
    property int effectiveInsetLightSamples: useFrameProfile
        ? (theme ? theme.frameInsetLightSamples : insetLightSamples)
        : insetLightSamples
    property color effectiveInsetLightColor: useFrameProfile
        ? (theme ? theme.frameInsetLightColor : insetLightColor)
        : insetLightColor
    property real darkBand: Math.max(5, Math.ceil(Math.abs(root.effectiveInsetOffset) + root.effectiveInsetDarkRadius * 0.75 + (root.theme ? root.theme.borderWidth : 1) + 1))
    property real lightBand: Math.max(5, Math.ceil(Math.abs(root.effectiveInsetLightOffset) + root.effectiveInsetLightRadius * 0.75 + (root.theme ? root.theme.borderWidth : 1) + 1))

    Rectangle {
        id: insetBase
        anchors.fill: parent
        radius: root.radius
        color: root.fillColor
        border.width: root.theme ? root.theme.borderWidth : 1
        border.color: root.theme ? root.theme.borderColor : Qt.rgba(1, 1, 1, 0.03)
    }

    NeumoInsetBevel {
        anchors.fill: insetBase
        radius: root.radius
        borderWidth: root.theme ? root.theme.borderWidth : 1
        darkColor: root.effectiveInsetDarkColor
        lightColor: root.effectiveInsetLightColor
        darkBand: root.darkBand
        lightBand: root.lightBand
    }

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}