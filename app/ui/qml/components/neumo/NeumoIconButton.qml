import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

Item {
    id: iconRoot
    property var theme
    property string iconSource: ""
    property string glyph: ""
    property string toolTip: ""
    property int fontSize: 14
    property real buttonSize: Math.max(width, height)
    property bool largeButton: buttonSize >= (theme ? theme.iconLargeThreshold : 40)
    property bool mediumButton: buttonSize >= (theme ? theme.iconMediumThreshold : 30) && buttonSize < (theme ? theme.iconLargeThreshold : 40)
    property real outerOffset: largeButton ? (theme ? theme.iconOuterOffsetLarge : 6)
        : (mediumButton ? (theme ? theme.iconOuterOffsetMedium : 4) : (theme ? theme.iconOuterOffsetSmall : 2))
    property real outerRadius: largeButton ? (theme ? theme.iconOuterRadiusLarge : 12)
        : (mediumButton ? (theme ? theme.iconOuterRadiusMedium : 8.5) : (theme ? theme.iconOuterRadiusSmall : 4.5))
    property int outerSamples: largeButton ? (theme ? theme.iconOuterSamplesLarge : 25)
        : (mediumButton ? (theme ? theme.iconOuterSamplesMedium : 21) : (theme ? theme.iconOuterSamplesSmall : 15))
    property real innerOffset: largeButton ? (theme ? theme.iconInnerOffsetLarge : 3)
        : (mediumButton ? (theme ? theme.iconInnerOffsetMedium : 2) : (theme ? theme.iconInnerOffsetSmall : 1.2))
    property real innerRadius: largeButton ? (theme ? theme.iconInnerRadiusLarge : 7)
        : (mediumButton ? (theme ? theme.iconInnerRadiusMedium : 5) : (theme ? theme.iconInnerRadiusSmall : 3.2))
    property int innerSamples: largeButton ? (theme ? theme.iconInnerSamplesLarge : 21)
        : (mediumButton ? (theme ? theme.iconInnerSamplesMedium : 17) : (theme ? theme.iconInnerSamplesSmall : 11))
    property color outerDarkColor: largeButton ? (theme ? theme.iconOuterDarkColorLarge : "#B8151618")
        : (mediumButton ? (theme ? theme.iconOuterDarkColorMedium : "#99151618") : (theme ? theme.iconOuterDarkColorSmall : "#70151618"))
    property color outerLightColor: largeButton ? (theme ? theme.iconOuterLightColorLarge : "#A63B3C40")
        : (mediumButton ? (theme ? theme.iconOuterLightColorMedium : "#8A3B3C40") : (theme ? theme.iconOuterLightColorSmall : "#6A3B3C40"))
    property color innerDarkColor: largeButton ? (theme ? theme.iconInnerDarkColorLarge : "#D0151618")
        : (mediumButton ? (theme ? theme.iconInnerDarkColorMedium : "#A6151618") : (theme ? theme.iconInnerDarkColorSmall : "#7A151618"))
    property color innerLightColor: largeButton ? (theme ? theme.iconInnerLightColorLarge : "#7C3B3C40")
        : (mediumButton ? (theme ? theme.iconInnerLightColorMedium : "#5A3B3C40") : (theme ? theme.iconInnerLightColorSmall : "#423B3C40"))
    property color iconColor: theme ? theme.textPrimary : "#CFCFCF"
    property color iconDisabledColor: "#7A7A7A"
    property real tipX: 0
    property real tipY: 0
    signal clicked()
    width: 24
    height: 24

    function updateTipPosition() {
        if (!tipPopup.visible || !tipPopup.parent) {
            return
        }
        var p = iconRoot.mapToItem(tipPopup.parent, iconRoot.width / 2, 0)
        var xPos = Math.round(p.x - tipPopup.width / 2)
        var yPos = Math.round(p.y - tipPopup.height - 8)
        var maxX = Math.max(0, tipPopup.parent.width - tipPopup.width)
        var maxY = Math.max(0, tipPopup.parent.height - tipPopup.height)
        iconRoot.tipX = Math.max(0, Math.min(xPos, maxX))
        iconRoot.tipY = Math.max(0, Math.min(yPos, maxY))
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: largeButton ? 12 : (mediumButton ? 9 : 7)
        color: theme ? theme.baseColor : "#2D2D2D"
    }

    DropShadow {
        anchors.fill: bg
        source: bg
        transparentBorder: true
        horizontalOffset: iconRoot.outerOffset
        verticalOffset: iconRoot.outerOffset
        radius: iconRoot.outerRadius
        samples: iconRoot.outerSamples
        color: iconRoot.outerDarkColor
        visible: !hitArea.pressed
        z: -1
    }

    DropShadow {
        anchors.fill: bg
        source: bg
        transparentBorder: true
        horizontalOffset: -iconRoot.outerOffset
        verticalOffset: -iconRoot.outerOffset
        radius: iconRoot.outerRadius
        samples: iconRoot.outerSamples
        color: iconRoot.outerLightColor
        visible: !hitArea.pressed
        z: -2
    }

    InnerShadow {
        id: buttonInsetDark
        anchors.fill: bg
        source: bg
        horizontalOffset: iconRoot.innerOffset
        verticalOffset: iconRoot.innerOffset
        radius: iconRoot.innerRadius
        samples: iconRoot.innerSamples
        color: iconRoot.innerDarkColor
        visible: hitArea.pressed
    }

    InnerShadow {
        anchors.fill: bg
        source: buttonInsetDark
        horizontalOffset: -iconRoot.innerOffset
        verticalOffset: -iconRoot.innerOffset
        radius: Math.max(2, iconRoot.innerRadius - 1)
        samples: iconRoot.innerSamples
        color: iconRoot.innerLightColor
        visible: hitArea.pressed
    }

    Image {
        id: iconImage
        anchors.centerIn: parent
        width: Math.max(10, Math.min(18, parent.width - (largeButton ? 14 : 10)))
        height: width
        visible: iconRoot.iconSource.length > 0
        source: iconRoot.iconSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        sourceSize.width: Math.round(width * 2)
        sourceSize.height: Math.round(height * 2)
        opacity: 0.0
    }

    ColorOverlay {
        anchors.fill: iconImage
        source: iconImage
        visible: iconImage.visible
        color: iconRoot.enabled ? iconRoot.iconColor : iconRoot.iconDisabledColor
    }

    Text {
        anchors.centerIn: parent
        visible: (!iconImage.visible || iconImage.status !== Image.Ready) && iconRoot.glyph.length > 0
        text: iconRoot.glyph
        color: iconRoot.enabled ? iconRoot.iconColor : iconRoot.iconDisabledColor
        font.pixelSize: iconRoot.fontSize
        font.weight: Font.DemiBold
    }

    Popup {
        id: tipPopup
        parent: Overlay.overlay
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        visible: hitArea.containsMouse && iconRoot.toolTip.length > 0
        x: iconRoot.tipX
        y: iconRoot.tipY
        padding: 8

        onVisibleChanged: iconRoot.updateTipPosition()
        onWidthChanged: iconRoot.updateTipPosition()
        onHeightChanged: iconRoot.updateTipPosition()
        Connections {
            target: tipPopup.parent
            enabled: tipPopup.visible && target !== null
            function onWidthChanged() { iconRoot.updateTipPosition() }
            function onHeightChanged() { iconRoot.updateTipPosition() }
        }

        contentItem: Text {
            text: iconRoot.toolTip
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
        enabled: iconRoot.enabled
        hoverEnabled: true
        onPositionChanged: iconRoot.updateTipPosition()
        onEntered: iconRoot.updateTipPosition()
        onClicked: iconRoot.clicked()
    }
}
