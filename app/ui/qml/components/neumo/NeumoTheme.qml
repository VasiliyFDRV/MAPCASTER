import QtQuick

QtObject {
    id: theme

    property color baseColor: "#2D2D2D"
    property color textPrimary: "#D0D0D0"
    property color textSecondary: "#909090"


    property color dialogButtonTextColor: textPrimary
    property color dialogButtonAccentTextColor: "#F7F7F8"
    property color dialogButtonDisabledTextColor: "#8A8A8A"
    property color dialogButtonBorderColor: "#505050"
    property color dialogButtonAccentBorderColor: "#B4B4B4"
    property color dialogButtonTopColor: "#363636"
    property color dialogButtonTopHoverColor: "#3B3B3B"
    property color dialogButtonTopPressedColor: "#323232"
    property color dialogButtonBottomColor: "#2D2D2D"
    property color dialogButtonBottomHoverColor: "#323232"
    property color dialogButtonBottomPressedColor: "#292929"
    property color dialogButtonAccentTopColor: "#7D7D7D"
    property color dialogButtonAccentTopHoverColor: "#858585"
    property color dialogButtonAccentTopPressedColor: "#727272"
    property color dialogButtonAccentBottomColor: "#6E6E6E"
    property color dialogButtonAccentBottomHoverColor: "#747474"
    property color dialogButtonAccentBottomPressedColor: "#666666"
    property real dialogButtonHoverScale: 1.025
    property real dialogButtonPressScale: 0.97

    property color fieldBackgroundColor: "#232323"
    property color fieldInsetFillColor: "#26282C"
    property color fieldBorderColor: "#4D4D4D"
    property color fieldBorderHoverColor: "#626262"
    property color fieldBorderFocusColor: "#ABABAB"
    property color fieldSelectedTextColor: "#F4F4F6"
    property color fieldSelectionColor: "#6C6C6C"
    property color fieldPlaceholderColor: textSecondary

    property color mediaTilePreviewFillColor: "#202226"
    property color mediaTilePreviewStrokeColor: "#4E525A"
    property color mediaTileEmptyFillColor: "#1C1E22"
    property color mediaTileHintColor: textSecondary
    property color mediaTileValueTextColor: textPrimary

    property color utilityIconHoverFillColor: "#555555"
    property color utilityIconPressedFillColor: "#646464"
    property color utilityIconBorderColor: "#969696"

    property color toggleTrackColor: "#353535"
    property color toggleTrackCheckedColor: "#646464"
    property color toggleTrackBorderColor: "#5C5C5C"
    property color toggleTrackCheckedBorderColor: "#A8A8A8"
    property color toggleKnobColor: "#EAEAEA"
    property color toggleKnobBorderColor: "#B2B2B2"

    property color comboTextColor: textPrimary
    property color comboIndicatorColor: "#C6C6C6"
    property color comboBackgroundColor: fieldBackgroundColor
    property color comboBorderColor: "#4D4D4D"
    property color comboBorderHoverColor: "#707070"
    property color comboBorderFocusColor: "#A7A7A7"
    property color comboPopupColor: "#252525"
    property color comboPopupBorderColor: "#595959"
    property color comboDelegateTextColor: "#D1D1D1"
    property color comboDelegateHighlightTextColor: "#F4F5F7"
    property color comboDelegateHoverColor: "#3A3A3A"
    property color comboDelegateHighlightColor: "#545454"

    property color checkIndicatorColor: "#252931"
    property color checkIndicatorCheckedColor: "#6D6D6D"
    property color checkIndicatorBorderColor: "#545454"
    property color checkIndicatorBorderHoverColor: "#7A7A7A"
    property color checkIndicatorBorderCheckedColor: "#C1C1C1"
    property color checkIndicatorMarkColor: "#F3F4F7"
    property color checkTextColor: textSecondary

    property color ghostActionIconIdleColor: "#6D6D6D"
    property color ghostActionIconRowHoverColor: "#969696"
    property color ghostActionIconHoverColor: "#F2F2F2"
    property color ghostActionIconPressedColor: "#DADADA"
    property color ghostActionShadowColor: shadowDarkBase
    property real ghostActionShadowHoverAlpha: 0.18
    property real ghostActionShadowPressedAlpha: 0.10
    property real ghostActionShadowBlur: 6
    property real ghostActionPressScale: 0.92
    property real ghostActionPressYOffset: 1

    property color shadowDarkBase: "#151618"
    property color shadowLightBase: "#55565C"
    property color rimLightBase: baseColor
    property color borderColor: Qt.rgba(1, 1, 1, 0.03)
    property int borderWidth: 1

    property real raisedRadius: 18
    property real raisedShadowOffset: 6
    property real raisedShadowOffsetHover: 6.8
    property real raisedShadowRadius: 12
    property real raisedShadowRadiusHover: 13
    property int raisedShadowSamples: 25
    property real raisedDarkAlpha: 0.96
    property real raisedLightAlpha: 0.60
    property real raisedDarkAlphaHover: 1.0
    property real raisedLightAlphaHover: raisedLightAlpha
    property color raisedShadowDarkColor: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, raisedDarkAlpha)
    property color raisedShadowLightColor: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, raisedLightAlpha)
    property color raisedShadowDarkColorHover: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, raisedDarkAlphaHover)
    property color raisedShadowLightColorHover: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, raisedLightAlphaHover)

    property real insetRadius: 20
    property real insetOffset: 6
    property real insetDarkRadius: 9.5
    property int insetDarkSamples: 31
    property real insetDarkAlpha: 0.86
    property real insetLightOffset: -6
    property real insetLightRadius: 7.5
    property int insetLightSamples: 25
    property real insetLightAlpha: raisedLightAlpha
    property color insetDarkColor: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, insetDarkAlpha)
    property color insetLightColor: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, insetLightAlpha)
    property real insetRimLightAlpha: 0.0
    property color insetRimLightColor: Qt.rgba(rimLightBase.r, rimLightBase.g, rimLightBase.b, insetRimLightAlpha)

    property real frameInsetOffset: 7
    property real frameInsetDarkRadius: 12.5
    property int frameInsetDarkSamples: 35
    property real frameInsetDarkAlpha: insetDarkAlpha
    property color frameInsetDarkColor: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, frameInsetDarkAlpha)
    property real frameInsetLightOffset: -7
    property real frameInsetLightRadius: 10.0
    property int frameInsetLightSamples: 29
    property real frameInsetLightAlpha: insetLightAlpha
    property color frameInsetLightColor: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, frameInsetLightAlpha)
    property real frameInsetRimLightAlpha: 0.0
    property color frameInsetRimLightColor: Qt.rgba(rimLightBase.r, rimLightBase.g, rimLightBase.b, frameInsetRimLightAlpha)

    property real iconLargeThreshold: 40
    property real iconMediumThreshold: 30

    property real iconOuterOffsetLarge: 6
    property real iconOuterOffsetMedium: 4
    property real iconOuterOffsetSmall: 2
    property real iconOuterOffsetLargeHover: 6.8
    property real iconOuterOffsetMediumHover: 4.7
    property real iconOuterOffsetSmallHover: 2.6
    property real iconOuterRadiusLarge: 12
    property real iconOuterRadiusMedium: 8.5
    property real iconOuterRadiusSmall: 4.5
    property real iconOuterRadiusLargeHover: 13
    property real iconOuterRadiusMediumHover: 9.2
    property real iconOuterRadiusSmallHover: 5.1
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
    property real iconOuterDarkAlphaLargeHover: 1.0
    property real iconOuterDarkAlphaMediumHover: 0.98
    property real iconOuterDarkAlphaSmallHover: 0.94
    property real iconOuterLightAlphaLargeHover: iconOuterLightAlphaLarge
    property real iconOuterLightAlphaMediumHover: iconOuterLightAlphaMedium
    property real iconOuterLightAlphaSmallHover: iconOuterLightAlphaSmall

    property color iconOuterDarkColorLarge: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconOuterDarkAlphaLarge)
    property color iconOuterDarkColorMedium: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconOuterDarkAlphaMedium)
    property color iconOuterDarkColorSmall: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconOuterDarkAlphaSmall)
    property color iconOuterLightColorLarge: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconOuterLightAlphaLarge)
    property color iconOuterLightColorMedium: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconOuterLightAlphaMedium)
    property color iconOuterLightColorSmall: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconOuterLightAlphaSmall)
    property color iconOuterDarkColorLargeHover: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconOuterDarkAlphaLargeHover)
    property color iconOuterDarkColorMediumHover: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconOuterDarkAlphaMediumHover)
    property color iconOuterDarkColorSmallHover: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconOuterDarkAlphaSmallHover)
    property color iconOuterLightColorLargeHover: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconOuterLightAlphaLargeHover)
    property color iconOuterLightColorMediumHover: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconOuterLightAlphaMediumHover)
    property color iconOuterLightColorSmallHover: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconOuterLightAlphaSmallHover)

    property real iconInnerDarkAlphaLarge: 0.98
    property real iconInnerDarkAlphaMedium: 0.92
    property real iconInnerDarkAlphaSmall: 0.86
    property real iconInnerLightAlphaLarge: iconOuterLightAlphaLarge
    property real iconInnerLightAlphaMedium: iconOuterLightAlphaMedium
    property real iconInnerLightAlphaSmall: iconOuterLightAlphaSmall
    property real iconInnerRimLightAlphaLarge: 0.0
    property real iconInnerRimLightAlphaMedium: 0.0
    property real iconInnerRimLightAlphaSmall: 0.0

    property color iconInnerDarkColorLarge: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconInnerDarkAlphaLarge)
    property color iconInnerDarkColorMedium: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconInnerDarkAlphaMedium)
    property color iconInnerDarkColorSmall: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, iconInnerDarkAlphaSmall)
    property color iconInnerLightColorLarge: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconInnerLightAlphaLarge)
    property color iconInnerLightColorMedium: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconInnerLightAlphaMedium)
    property color iconInnerLightColorSmall: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, iconInnerLightAlphaSmall)
    property color iconInnerRimLightColorLarge: Qt.rgba(rimLightBase.r, rimLightBase.g, rimLightBase.b, iconInnerRimLightAlphaLarge)
    property color iconInnerRimLightColorMedium: Qt.rgba(rimLightBase.r, rimLightBase.g, rimLightBase.b, iconInnerRimLightAlphaMedium)
    property color iconInnerRimLightColorSmall: Qt.rgba(rimLightBase.r, rimLightBase.g, rimLightBase.b, iconInnerRimLightAlphaSmall)

    property int rowShadowSamples: 23
    property real rowShadowRadius: 10
    property real rowShadowRadiusHover: 11.4
    property real rowShadowOffset: 4.5
    property real rowShadowOffsetHover: 6.1
    property real rowShadowOffsetDrag: 5
    property real rowShadowRadiusDrag: 11
    property real rowDarkAlpha: 0.92
    property real rowLightAlpha: 0.60
    property real rowDarkAlphaHover: 1.0
    property real rowLightAlphaHover: 0.52
    property real rowDarkAlphaDrag: 0.98
    property real rowLightAlphaDrag: 0.68
    property color rowShadowDarkColor: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, rowDarkAlpha)
    property color rowShadowDarkColorHover: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, rowDarkAlphaHover)
    property color rowShadowDarkColorDrag: Qt.rgba(shadowDarkBase.r, shadowDarkBase.g, shadowDarkBase.b, rowDarkAlphaDrag)
    property color rowShadowLightColor: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, rowLightAlpha)
    property color rowShadowLightColorHover: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, rowLightAlphaHover)
    property color rowShadowLightColorDrag: Qt.rgba(shadowLightBase.r, shadowLightBase.g, shadowLightBase.b, rowLightAlphaDrag)
}
