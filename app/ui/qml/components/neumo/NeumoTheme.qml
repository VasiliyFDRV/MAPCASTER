import QtQuick

QtObject {
    id: theme

    property color baseColor: "#2D2D2D"
    property color textPrimary: "#D0D0D0"
    property color textSecondary: "#909090"

    property real raisedRadius: 18
    property real raisedShadowOffset: 6
    property real raisedShadowRadius: 12
    property int raisedShadowSamples: 25
    property color raisedShadowDarkColor: "#B8151618"
    property color raisedShadowLightColor: "#703B3C40"

    property real insetRadius: 20
    property real insetOffset: 6
    property real insetDarkRadius: 12
    property int insetDarkSamples: 31
    property color insetDarkColor: "#CC151618"
    property real insetLightOffset: -6
    property real insetLightRadius: 10
    property int insetLightSamples: 25
    property color insetLightColor: "#663B3C40"

    property real iconLargeThreshold: 40
    property real iconMediumThreshold: 30

    property real iconOuterOffsetLarge: 6
    property real iconOuterOffsetMedium: 4
    property real iconOuterOffsetSmall: 2
    property real iconOuterRadiusLarge: 12
    property real iconOuterRadiusMedium: 8.5
    property real iconOuterRadiusSmall: 4.5
    property int iconOuterSamplesLarge: 25
    property int iconOuterSamplesMedium: 21
    property int iconOuterSamplesSmall: 15

    property real iconInnerOffsetLarge: 3
    property real iconInnerOffsetMedium: 2
    property real iconInnerOffsetSmall: 1.2
    property real iconInnerRadiusLarge: 7
    property real iconInnerRadiusMedium: 5
    property real iconInnerRadiusSmall: 3.2
    property int iconInnerSamplesLarge: 21
    property int iconInnerSamplesMedium: 17
    property int iconInnerSamplesSmall: 11

    property color iconOuterDarkColorLarge: "#B8151618"
    property color iconOuterDarkColorMedium: "#99151618"
    property color iconOuterDarkColorSmall: "#70151618"
    property color iconOuterLightColorLarge: "#A63B3C40"
    property color iconOuterLightColorMedium: "#8A3B3C40"
    property color iconOuterLightColorSmall: "#6A3B3C40"

    property color iconInnerDarkColorLarge: "#D0151618"
    property color iconInnerDarkColorMedium: "#A6151618"
    property color iconInnerDarkColorSmall: "#7A151618"
    property color iconInnerLightColorLarge: "#7C3B3C40"
    property color iconInnerLightColorMedium: "#5A3B3C40"
    property color iconInnerLightColorSmall: "#423B3C40"

    property int rowShadowSamples: 23
    property real rowShadowRadius: 10
    property real rowShadowOffset: 4
    property real rowShadowOffsetHover: 4.5
    property real rowShadowOffsetDrag: 5
    property real rowShadowRadiusDrag: 11
    property color rowShadowDarkColor: "#9E151618"
    property color rowShadowDarkColorDrag: "#BC151618"
    property color rowShadowLightColor: "#643B3C40"
    property color rowShadowLightColorDrag: "#7C3B3C40"
}
