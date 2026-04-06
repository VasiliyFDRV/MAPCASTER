import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

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
    property color effectiveInsetRimLightColor: useFrameProfile
        ? (theme ? theme.frameInsetRimLightColor : insetLightColor)
        : (theme ? theme.insetRimLightColor : insetLightColor)
    property real lightRimBandSize: Math.max(18, Math.ceil(root.effectiveInsetLightRadius * 2 + Math.abs(root.effectiveInsetLightOffset) + (root.theme ? root.theme.borderWidth : 1) + 8))

    Rectangle {
        id: insetBase
        anchors.fill: parent
        radius: root.radius
        color: root.fillColor
        border.width: root.theme ? root.theme.borderWidth : 1
        border.color: root.theme ? root.theme.borderColor : Qt.rgba(1, 1, 1, 0.03)
    }

    InnerShadow {
        id: insetDark
        anchors.fill: insetBase
        source: insetBase
        horizontalOffset: root.effectiveInsetOffset
        verticalOffset: root.effectiveInsetOffset
        radius: root.effectiveInsetDarkRadius
        samples: root.effectiveInsetDarkSamples
        color: root.effectiveInsetDarkColor
    }

    InnerShadow {
        id: insetLight
        anchors.fill: insetBase
        source: insetDark
        horizontalOffset: root.effectiveInsetLightOffset
        verticalOffset: root.effectiveInsetLightOffset
        radius: root.effectiveInsetLightRadius
        samples: root.effectiveInsetLightSamples
        color: root.effectiveInsetLightColor
    }

    NeumoInnerRim {
        anchors.fill: insetBase
        sourceItem: insetBase
        horizontalOffset: root.effectiveInsetLightOffset
        verticalOffset: root.effectiveInsetLightOffset
        radius: root.effectiveInsetLightRadius
        samples: root.effectiveInsetLightSamples
        rimColor: root.effectiveInsetRimLightColor
        bandSize: root.lightRimBandSize
    }

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}