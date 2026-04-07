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
    property real outerOffset: largeButton
        ? (iconRoot.hovered ? (theme ? theme.iconOuterOffsetLargeHover : 6.8) : (theme ? theme.iconOuterOffsetLarge : 6))
        : (mediumButton
            ? (iconRoot.hovered ? (theme ? theme.iconOuterOffsetMediumHover : 4.7) : (theme ? theme.iconOuterOffsetMedium : 4))
            : (iconRoot.hovered ? (theme ? theme.iconOuterOffsetSmallHover : 2.6) : (theme ? theme.iconOuterOffsetSmall : 2)))
    property real outerRadius: largeButton
        ? (iconRoot.hovered ? (theme ? theme.iconOuterRadiusLargeHover : 13) : (theme ? theme.iconOuterRadiusLarge : 12))
        : (mediumButton
            ? (iconRoot.hovered ? (theme ? theme.iconOuterRadiusMediumHover : 9.2) : (theme ? theme.iconOuterRadiusMedium : 8.5))
            : (iconRoot.hovered ? (theme ? theme.iconOuterRadiusSmallHover : 5.1) : (theme ? theme.iconOuterRadiusSmall : 4.5)))
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
    property color outerDarkColorHover: largeButton ? (theme ? theme.iconOuterDarkColorLargeHover : "#FC151618")
        : (mediumButton ? (theme ? theme.iconOuterDarkColorMediumHover : "#F0151618") : (theme ? theme.iconOuterDarkColorSmallHover : "#E0151618"))
    property color outerLightColorHover: largeButton ? (theme ? theme.iconOuterLightColorLargeHover : "#AD55565C")
        : (mediumButton ? (theme ? theme.iconOuterLightColorMediumHover : "#9955565C") : (theme ? theme.iconOuterLightColorSmallHover : "#8555565C"))
    property color innerDarkColor: largeButton ? (theme ? theme.iconInnerDarkColorLarge : "#D0151618")
        : (mediumButton ? (theme ? theme.iconInnerDarkColorMedium : "#A6151618") : (theme ? theme.iconInnerDarkColorSmall : "#7A151618"))
    property color innerLightColor: largeButton ? (theme ? theme.iconInnerLightColorLarge : "#7C3B3C40")
        : (mediumButton ? (theme ? theme.iconInnerLightColorMedium : "#5A3B3C40") : (theme ? theme.iconInnerLightColorSmall : "#423B3C40"))
    property color iconColor: theme ? theme.textPrimary : "#CFCFCF"
    property color iconDisabledColor: "#7A7A7A"
    property real tipX: 0
    property real tipY: 0
    property bool hovered: hitArea.containsMouse && iconRoot.enabled && !hitArea.pressed
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

    Item {
        id: visualRoot
        anchors.fill: parent
        scale: iconRoot.hovered ? 1.045 : 1.0
        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: largeButton ? 12 : (mediumButton ? 9 : 7)
            color: theme ? theme.baseColor : "#2D2D2D"
            border.width: theme ? theme.borderWidth : 1
            border.color: theme ? theme.borderColor : Qt.rgba(1, 1, 1, 0.03)
        }

        DropShadow {
            anchors.fill: bg
            source: bg
            transparentBorder: true
            horizontalOffset: iconRoot.outerOffset
            verticalOffset: iconRoot.outerOffset
            radius: iconRoot.outerRadius
            samples: iconRoot.outerSamples
            color: iconRoot.hovered ? iconRoot.outerDarkColorHover : iconRoot.outerDarkColor
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
            color: iconRoot.hovered ? iconRoot.outerLightColorHover : iconRoot.outerLightColor
            visible: !hitArea.pressed
            z: -2
        }

        NeumoInsetBevel {
            anchors.fill: bg
            radius: bg.radius
            darkColor: iconRoot.innerDarkColor
            lightColor: iconRoot.innerLightColor
            darkOffset: iconRoot.innerOffset
            lightOffset: -iconRoot.innerOffset
            darkRadius: iconRoot.innerRadius
            lightRadius: iconRoot.innerRadius
            active: hitArea.pressed
        }

        Item {
            id: iconVisual
            anchors.centerIn: parent
            width: Math.max(10, Math.min(18, parent.width - (largeButton ? 14 : 10)))
            height: width
        }

        Image {
            id: iconImage
            anchors.centerIn: iconVisual
            width: iconVisual.width
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
            anchors.centerIn: iconVisual
            visible: (!iconImage.visible || iconImage.status !== Image.Ready) && iconRoot.glyph.length > 0
            text: iconRoot.glyph
            color: iconRoot.enabled ? iconRoot.iconColor : iconRoot.iconDisabledColor
            font.pixelSize: iconRoot.fontSize
            font.weight: Font.DemiBold
        }
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
