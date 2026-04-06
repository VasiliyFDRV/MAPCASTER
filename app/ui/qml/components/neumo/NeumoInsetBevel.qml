import QtQuick

Item {
    id: root
    property real radius: 20
    property real borderWidth: 1
    property color darkColor: "transparent"
    property color lightColor: "transparent"
    property real darkBand: 14
    property real lightBand: 14

    function rgbaString(color, alphaScale) {
        var scaledAlpha = Math.max(0, Math.min(1, color.a * alphaScale))
        return "rgba("
            + Math.round(color.r * 255) + ","
            + Math.round(color.g * 255) + ","
            + Math.round(color.b * 255) + ","
            + scaledAlpha.toFixed(4) + ")"
    }

    function roundedRectPath(ctx, x, y, w, h, r) {
        var clampedRadius = Math.max(0, Math.min(r, Math.min(w, h) / 2))
        ctx.beginPath()
        ctx.moveTo(x + clampedRadius, y)
        ctx.lineTo(x + w - clampedRadius, y)
        ctx.quadraticCurveTo(x + w, y, x + w, y + clampedRadius)
        ctx.lineTo(x + w, y + h - clampedRadius)
        ctx.quadraticCurveTo(x + w, y + h, x + w - clampedRadius, y + h)
        ctx.lineTo(x + clampedRadius, y + h)
        ctx.quadraticCurveTo(x, y + h, x, y + h - clampedRadius)
        ctx.lineTo(x, y + clampedRadius)
        ctx.quadraticCurveTo(x, y, x + clampedRadius, y)
        ctx.closePath()
    }

    Canvas {
        id: bevelCanvas
        anchors.fill: parent
        renderTarget: Canvas.Image
        contextType: "2d"

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            if (width <= 0 || height <= 0) {
                return
            }

            var inset = Math.max(0, root.borderWidth)
            var x0 = inset
            var y0 = inset
            var w = Math.max(0, width - inset * 2)
            var h = Math.max(0, height - inset * 2)
            if (w <= 0 || h <= 0) {
                return
            }

            var clipRadius = Math.max(0, root.radius - inset)
            var darkBand = Math.max(1, Math.min(root.darkBand, Math.min(w, h)))
            var lightBand = Math.max(1, Math.min(root.lightBand, Math.min(w, h)))
            var tlRadius = Math.min(Math.max(darkBand, clipRadius), Math.min(w, h))
            var brRadius = Math.min(Math.max(lightBand, clipRadius), Math.min(w, h))

            ctx.save()
            root.roundedRectPath(ctx, x0, y0, w, h, clipRadius)
            ctx.clip()

            var topGradient = ctx.createLinearGradient(0, y0, 0, y0 + darkBand)
            topGradient.addColorStop(0.0, root.rgbaString(root.darkColor, 1.0))
            topGradient.addColorStop(0.45, root.rgbaString(root.darkColor, 0.72))
            topGradient.addColorStop(1.0, root.rgbaString(root.darkColor, 0.0))
            ctx.fillStyle = topGradient
            ctx.fillRect(x0, y0, w, darkBand)

            var leftGradient = ctx.createLinearGradient(x0, 0, x0 + darkBand, 0)
            leftGradient.addColorStop(0.0, root.rgbaString(root.darkColor, 1.0))
            leftGradient.addColorStop(0.45, root.rgbaString(root.darkColor, 0.72))
            leftGradient.addColorStop(1.0, root.rgbaString(root.darkColor, 0.0))
            ctx.fillStyle = leftGradient
            ctx.fillRect(x0, y0, darkBand, h)

            var tlGradient = ctx.createRadialGradient(x0, y0, 0, x0, y0, tlRadius)
            tlGradient.addColorStop(0.0, root.rgbaString(root.darkColor, 1.0))
            tlGradient.addColorStop(0.55, root.rgbaString(root.darkColor, 0.76))
            tlGradient.addColorStop(1.0, root.rgbaString(root.darkColor, 0.0))
            ctx.fillStyle = tlGradient
            ctx.fillRect(x0, y0, tlRadius, tlRadius)

            var bottomGradient = ctx.createLinearGradient(0, y0 + h - lightBand, 0, y0 + h)
            bottomGradient.addColorStop(0.0, root.rgbaString(root.lightColor, 0.0))
            bottomGradient.addColorStop(0.55, root.rgbaString(root.lightColor, 0.74))
            bottomGradient.addColorStop(1.0, root.rgbaString(root.lightColor, 1.0))
            ctx.fillStyle = bottomGradient
            ctx.fillRect(x0, y0 + h - lightBand, w, lightBand)

            var rightGradient = ctx.createLinearGradient(x0 + w - lightBand, 0, x0 + w, 0)
            rightGradient.addColorStop(0.0, root.rgbaString(root.lightColor, 0.0))
            rightGradient.addColorStop(0.55, root.rgbaString(root.lightColor, 0.74))
            rightGradient.addColorStop(1.0, root.rgbaString(root.lightColor, 1.0))
            ctx.fillStyle = rightGradient
            ctx.fillRect(x0 + w - lightBand, y0, lightBand, h)

            var brGradient = ctx.createRadialGradient(x0 + w, y0 + h, 0, x0 + w, y0 + h, brRadius)
            brGradient.addColorStop(0.0, root.rgbaString(root.lightColor, 1.0))
            brGradient.addColorStop(0.55, root.rgbaString(root.lightColor, 0.80))
            brGradient.addColorStop(1.0, root.rgbaString(root.lightColor, 0.0))
            ctx.fillStyle = brGradient
            ctx.fillRect(x0 + w - brRadius, y0 + h - brRadius, brRadius, brRadius)

            ctx.restore()
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }

    onRadiusChanged: bevelCanvas.requestPaint()
    onBorderWidthChanged: bevelCanvas.requestPaint()
    onDarkColorChanged: bevelCanvas.requestPaint()
    onLightColorChanged: bevelCanvas.requestPaint()
    onDarkBandChanged: bevelCanvas.requestPaint()
    onLightBandChanged: bevelCanvas.requestPaint()
}