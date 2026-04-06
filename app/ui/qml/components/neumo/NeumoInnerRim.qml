import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property var sourceItem
    property real horizontalOffset: -6
    property real verticalOffset: -6
    property real radius: 10
    property int samples: 25
        property color rimColor: "transparent"
    property real bandSize: 18
    property real bandMidAlpha: 0.72
    property real cornerMidAlpha: 0.82
    property real cornerPeakAlpha: 1.0
    property bool active: true

    InnerShadow {
        id: rimSource
        anchors.fill: parent
        source: root.sourceItem
        horizontalOffset: root.horizontalOffset
        verticalOffset: root.verticalOffset
        radius: root.radius
        samples: root.samples
        color: root.rimColor
        visible: false
    }

    Canvas {
        id: rimMask
        anchors.fill: parent
        visible: false
        renderTarget: Canvas.Image

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            var band = Math.max(0, Math.min(root.bandSize, Math.min(width, height)))
            if (band <= 0) {
                return
            }

            var bottomGradient = ctx.createLinearGradient(0, height - band, 0, height)
            bottomGradient.addColorStop(0.0, "rgba(255,255,255,0)")
            bottomGradient.addColorStop(0.55, "rgba(255,255,255," + root.bandMidAlpha.toFixed(3) + ")")
            bottomGradient.addColorStop(1.0, "rgba(255,255,255,1)")
            ctx.fillStyle = bottomGradient
            ctx.fillRect(0, height - band, width, band)

            var rightGradient = ctx.createLinearGradient(width - band, 0, width, 0)
            rightGradient.addColorStop(0.0, "rgba(255,255,255,0)")
            rightGradient.addColorStop(0.55, "rgba(255,255,255," + root.bandMidAlpha.toFixed(3) + ")")
            rightGradient.addColorStop(1.0, "rgba(255,255,255,1)")
            ctx.fillStyle = rightGradient
            ctx.fillRect(width - band, 0, band, height)

            var cornerGradient = ctx.createRadialGradient(width, height, 0, width, height, band)
            cornerGradient.addColorStop(0.0, "rgba(255,255,255," + root.cornerPeakAlpha.toFixed(3) + ")")
            cornerGradient.addColorStop(0.6, "rgba(255,255,255," + root.cornerMidAlpha.toFixed(3) + ")")
            cornerGradient.addColorStop(1.0, "rgba(255,255,255,0)")
            ctx.fillStyle = cornerGradient
            ctx.beginPath()
            ctx.moveTo(width, height)
            ctx.lineTo(width - band, height)
            ctx.arc(width, height, band, Math.PI, Math.PI * 1.5, false)
            ctx.closePath()
            ctx.fill()
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }

    OpacityMask {
        anchors.fill: parent
        source: rimSource
        maskSource: rimMask
        cached: true
        visible: root.active && root.rimColor.a > 0
    }
}

