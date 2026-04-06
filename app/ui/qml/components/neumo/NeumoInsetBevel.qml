import QtQuick

Item {
    id: root
    property real radius: 20
    property color darkColor: "#CC151618"
    property color lightColor: "#663B3C40"
    property real darkOffset: 6
    property real lightOffset: -6
    property real darkRadius: 12
    property real lightRadius: 10
    property bool active: true

    readonly property real darkBand: Math.max(1.0, darkRadius + Math.abs(darkOffset))
    readonly property real lightBand: Math.max(1.0, lightRadius + Math.abs(lightOffset))
    readonly property real darkCornerExtent: Math.max(radius, darkBand * 1.55)
    readonly property real lightCornerExtent: Math.max(radius, lightBand * 1.55)
    readonly property bool darkOnTopLeft: darkOffset >= 0
    readonly property bool lightOnBottomRight: lightOffset <= 0

    visible: active && (darkColor.a > 0 || lightColor.a > 0)

    Canvas {
        id: canvas
        anchors.fill: parent
        visible: root.visible
        renderTarget: Canvas.Image

        function requestRepaint() {
            requestPaint()
        }

        function roundedRectPath(ctx, x, y, w, h, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + w - r, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + r)
            ctx.lineTo(x + w, y + h - r)
            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
            ctx.lineTo(x + r, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - r)
            ctx.lineTo(x, y + r)
            ctx.quadraticCurveTo(x, y, x + r, y)
            ctx.closePath()
        }

        function rgbaString(color, alphaScale) {
            var scale = alphaScale === undefined ? 1.0 : alphaScale
            return "rgba(" + Math.round(color.r * 255) + "," + Math.round(color.g * 255) + "," + Math.round(color.b * 255) + "," + (color.a * scale).toFixed(4) + ")"
        }

        onPaint: {
            var ctx = getContext("2d")
            var w = Math.max(1, Math.round(width))
            var h = Math.max(1, Math.round(height))
            var radius = Math.min(root.radius, Math.min(w, h) * 0.5)
            ctx.reset()
            ctx.clearRect(0, 0, w, h)

            if (!root.active || (root.darkColor.a <= 0 && root.lightColor.a <= 0)) {
                return
            }

            var darkBand = Math.min(root.darkBand, Math.min(w, h))
            var lightBand = Math.min(root.lightBand, Math.min(w, h))
            var darkCorner = Math.min(root.darkCornerExtent, Math.min(w, h))
            var lightCorner = Math.min(root.lightCornerExtent, Math.min(w, h))

            ctx.save()
            roundedRectPath(ctx, 0, 0, w, h, radius)
            ctx.clip()

            if (root.darkColor.a > 0) {
                var darkBandOuter = rgbaString(root.darkColor, 1.0)
                var darkBandMid = rgbaString(root.darkColor, 0.42)
                var darkTransparent = rgbaString(root.darkColor, 0.0)
                var darkCornerMid = rgbaString(root.darkColor, 0.55)

                if (root.darkOnTopLeft) {
                    var top = ctx.createLinearGradient(0, 0, 0, darkBand)
                    top.addColorStop(0.0, darkBandOuter)
                    top.addColorStop(0.55, darkBandMid)
                    top.addColorStop(1.0, darkTransparent)
                    ctx.fillStyle = top
                    ctx.fillRect(0, 0, w, darkBand)

                    var left = ctx.createLinearGradient(0, 0, darkBand, 0)
                    left.addColorStop(0.0, darkBandOuter)
                    left.addColorStop(0.55, darkBandMid)
                    left.addColorStop(1.0, darkTransparent)
                    ctx.fillStyle = left
                    ctx.fillRect(0, 0, darkBand, h)

                    var topLeft = ctx.createRadialGradient(0, 0, 0, 0, 0, darkCorner)
                    topLeft.addColorStop(0.0, darkBandOuter)
                    topLeft.addColorStop(0.55, darkCornerMid)
                    topLeft.addColorStop(1.0, darkTransparent)
                    ctx.fillStyle = topLeft
                    ctx.fillRect(0, 0, darkCorner, darkCorner)
                } else {
                    var bottomDark = ctx.createLinearGradient(0, h, 0, h - darkBand)
                    bottomDark.addColorStop(0.0, darkBandOuter)
                    bottomDark.addColorStop(0.55, darkBandMid)
                    bottomDark.addColorStop(1.0, darkTransparent)
                    ctx.fillStyle = bottomDark
                    ctx.fillRect(0, h - darkBand, w, darkBand)

                    var rightDark = ctx.createLinearGradient(w, 0, w - darkBand, 0)
                    rightDark.addColorStop(0.0, darkBandOuter)
                    rightDark.addColorStop(0.55, darkBandMid)
                    rightDark.addColorStop(1.0, darkTransparent)
                    ctx.fillStyle = rightDark
                    ctx.fillRect(w - darkBand, 0, darkBand, h)

                    var bottomRightDark = ctx.createRadialGradient(w, h, 0, w, h, darkCorner)
                    bottomRightDark.addColorStop(0.0, darkBandOuter)
                    bottomRightDark.addColorStop(0.55, darkCornerMid)
                    bottomRightDark.addColorStop(1.0, darkTransparent)
                    ctx.fillStyle = bottomRightDark
                    ctx.fillRect(w - darkCorner, h - darkCorner, darkCorner, darkCorner)
                }
            }

            if (root.lightColor.a > 0) {
                var lightBandOuter = rgbaString(root.lightColor, 1.0)
                var lightBandMid = rgbaString(root.lightColor, 0.42)
                var lightTransparent = rgbaString(root.lightColor, 0.0)
                var lightCornerMid = rgbaString(root.lightColor, 0.55)

                if (root.lightOnBottomRight) {
                    var bottom = ctx.createLinearGradient(0, h, 0, h - lightBand)
                    bottom.addColorStop(0.0, lightBandOuter)
                    bottom.addColorStop(0.55, lightBandMid)
                    bottom.addColorStop(1.0, lightTransparent)
                    ctx.fillStyle = bottom
                    ctx.fillRect(0, h - lightBand, w, lightBand)

                    var right = ctx.createLinearGradient(w, 0, w - lightBand, 0)
                    right.addColorStop(0.0, lightBandOuter)
                    right.addColorStop(0.55, lightBandMid)
                    right.addColorStop(1.0, lightTransparent)
                    ctx.fillStyle = right
                    ctx.fillRect(w - lightBand, 0, lightBand, h)

                    var bottomRight = ctx.createRadialGradient(w, h, 0, w, h, lightCorner)
                    bottomRight.addColorStop(0.0, lightBandOuter)
                    bottomRight.addColorStop(0.55, lightCornerMid)
                    bottomRight.addColorStop(1.0, lightTransparent)
                    ctx.fillStyle = bottomRight
                    ctx.fillRect(w - lightCorner, h - lightCorner, lightCorner, lightCorner)
                } else {
                    var topLight = ctx.createLinearGradient(0, 0, 0, lightBand)
                    topLight.addColorStop(0.0, lightBandOuter)
                    topLight.addColorStop(0.55, lightBandMid)
                    topLight.addColorStop(1.0, lightTransparent)
                    ctx.fillStyle = topLight
                    ctx.fillRect(0, 0, w, lightBand)

                    var leftLight = ctx.createLinearGradient(0, 0, lightBand, 0)
                    leftLight.addColorStop(0.0, lightBandOuter)
                    leftLight.addColorStop(0.55, lightBandMid)
                    leftLight.addColorStop(1.0, lightTransparent)
                    ctx.fillStyle = leftLight
                    ctx.fillRect(0, 0, lightBand, h)

                    var topLeftLight = ctx.createRadialGradient(0, 0, 0, 0, 0, lightCorner)
                    topLeftLight.addColorStop(0.0, lightBandOuter)
                    topLeftLight.addColorStop(0.55, lightCornerMid)
                    topLeftLight.addColorStop(1.0, lightTransparent)
                    ctx.fillStyle = topLeftLight
                    ctx.fillRect(0, 0, lightCorner, lightCorner)
                }
            }

            ctx.restore()
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }

    onRadiusChanged: canvas.requestRepaint()
    onDarkColorChanged: canvas.requestRepaint()
    onLightColorChanged: canvas.requestRepaint()
    onDarkOffsetChanged: canvas.requestRepaint()
    onLightOffsetChanged: canvas.requestRepaint()
    onDarkRadiusChanged: canvas.requestRepaint()
    onLightRadiusChanged: canvas.requestRepaint()
    onActiveChanged: canvas.requestRepaint()
}