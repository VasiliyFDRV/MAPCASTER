import QtQuick

QtObject {
    id: theme

    property color baseColor: "#2D2D2D"
    property color textPrimary: "#D0D0D0"
    property color textSecondary: "#909090"

    property color shadowDarkBase: "#151618"
    property color shadowLightBase: "#3B3C40"
    property color borderColor: Qt.rgba(1, 1, 1, 0.03)
    property int borderWidth: 1

    property real raisedRadius: 18
    property real raisedShadowOffset: 6
    property real raisedShadowRadius: 12
    property int raisedShadowSamples: 25
    property real raisedDarkAlpha: 0.96
    property real raisedLightAlpha: 0.60
    property color raisedShadowDarkColor: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, raisedDarkAlpha)
    property color raisedShadowLightColor: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, raisedLightAlpha)

    property real insetRadius: 20
    property real insetOffset: 6
    property real insetDarkRadius: 12
    property int insetDarkSamples: 31
    property real insetDarkAlpha: 0.86
    property real insetLightOffset: -6
    property real insetLightRadius: 10
    property int insetLightSamples: 25
    property real insetLightAlpha: raisedLightAlpha
    property color insetDarkColor: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, insetDarkAlpha)
    property color insetLightColor: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, insetLightAlpha)

    property real frameInsetOffset: 7
    property real frameInsetDarkRadius: 15
    property int frameInsetDarkSamples: 35
    property real frameInsetDarkAlpha: insetDarkAlpha
    property color frameInsetDarkColor: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, frameInsetDarkAlpha)
    property real frameInsetLightOffset: -7
    property real frameInsetLightRadius: 13
    property int frameInsetLightSamples: 29
    property real frameInsetLightAlpha: insetLightAlpha
    property color frameInsetLightColor: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, frameInsetLightAlpha)

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

    property real iconOuterDarkAlphaLarge: 0.96
    property real iconOuterDarkAlphaMedium: 0.90
    property real iconOuterDarkAlphaSmall: 0.84
    property real iconOuterLightAlphaLarge: 0.60
    property real iconOuterLightAlphaMedium: 0.52
    property real iconOuterLightAlphaSmall: 0.44

    property color iconOuterDarkColorLarge: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconOuterDarkAlphaLarge)
    property color iconOuterDarkColorMedium: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconOuterDarkAlphaMedium)
    property color iconOuterDarkColorSmall: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconOuterDarkAlphaSmall)
    property color iconOuterLightColorLarge: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconOuterLightAlphaLarge)
    property color iconOuterLightColorMedium: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconOuterLightAlphaMedium)
    property color iconOuterLightColorSmall: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconOuterLightAlphaSmall)

    property real iconInnerDarkAlphaLarge: 0.98
    property real iconInnerDarkAlphaMedium: 0.92
    property real iconInnerDarkAlphaSmall: 0.86
    property real iconInnerLightAlphaLarge: 0.58
    property real iconInnerLightAlphaMedium: 0.50
    property real iconInnerLightAlphaSmall: 0.42

    property color iconInnerDarkColorLarge: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconInnerDarkAlphaLarge)
    property color iconInnerDarkColorMedium: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconInnerDarkAlphaMedium)
    property color iconInnerDarkColorSmall: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconInnerDarkAlphaSmall)
    property color iconInnerLightColorLarge: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconInnerLightAlphaLarge)
    property color iconInnerLightColorMedium: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconInnerLightAlphaMedium)
    property color iconInnerLightColorSmall: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconInnerLightAlphaSmall)

    property int rowShadowSamples: 23
    property real rowShadowRadius: 10
    property real rowShadowOffset: 4
    property real rowShadowOffsetHover: 4.5
    property real rowShadowOffsetDrag: 5
    property real rowShadowRadiusDrag: 11
    property real rowDarkAlpha: 0.92
    property real rowLightAlpha: 0.60
    property real rowDarkAlphaDrag: 0.98
    property real rowLightAlphaDrag: 0.68
    property color rowShadowDarkColor: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, rowDarkAlpha)
    property color rowShadowDarkColorDrag: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, rowDarkAlphaDrag)
    property color rowShadowLightColor: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, rowLightAlpha)
    property color rowShadowLightColorDrag: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, rowLightAlphaDrag)
}
