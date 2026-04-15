import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "neumo"

Window {
    id: root

    property var theme
    property Window parentWindow: null
    property string dialogTitle: "Выбор цвета"
    property string currentColor: "#FFFFFF"
    property string previewColor: "#FFFFFF"
    property string hexText: "#FFFFFF"
    property int pickerHue: 0
    property int pickerSaturation: 0
    property int pickerValue: 100
    property bool acceptInFlight: false

    signal colorAccepted(string color)
    signal canceled()

    transientParent: parentWindow
    modality: Qt.ApplicationModal
    flags: Qt.Dialog | Qt.WindowTitleHint | Qt.WindowCloseButtonHint
    visible: false
    title: dialogTitle
    width: parentWindow ? Math.max(360, Math.min(420, parentWindow.width - 24)) : 420
    height: 468
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    color: theme ? theme.baseColor : "#2D2D2D"
    x: parentWindow ? parentWindow.x + Math.round((parentWindow.width - width) / 2) : 120
    y: parentWindow ? parentWindow.y + Math.round((parentWindow.height - height) / 2) : 120

    function clampNumber(value, minValue, maxValue) {
        var number = Number(value)
        if (!isFinite(number)) {
            number = Number(minValue)
        }
        return Math.max(Number(minValue), Math.min(Number(maxValue), number))
    }
    function byteToHex(value) {
        var n = Math.max(0, Math.min(255, Math.round(Number(value) || 0)))
        var h = n.toString(16).toUpperCase()
        return h.length < 2 ? ("0" + h) : h
    }
    function rgbaToHex(r, g, b) {
        return "#" + byteToHex(r) + byteToHex(g) + byteToHex(b)
    }
    function parseColorInput(raw, fallbackColor) {
        var value = String(raw || "").trim()
        if (value.length <= 0 && fallbackColor !== undefined) {
            value = String(fallbackColor || "").trim()
        }
        var m = value.match(/^#([0-9a-fA-F]{3})$/)
        if (m) {
            var h3 = m[1]
            return {
                ok: true,
                r: parseInt(h3[0] + h3[0], 16),
                g: parseInt(h3[1] + h3[1], 16),
                b: parseInt(h3[2] + h3[2], 16),
                hex: "#" + (h3[0] + h3[0] + h3[1] + h3[1] + h3[2] + h3[2]).toUpperCase()
            }
        }
        m = value.match(/^#([0-9a-fA-F]{6})$/)
        if (m) {
            var h6 = m[1].toUpperCase()
            return {
                ok: true,
                r: parseInt(h6.slice(0, 2), 16),
                g: parseInt(h6.slice(2, 4), 16),
                b: parseInt(h6.slice(4, 6), 16),
                hex: "#" + h6
            }
        }
        m = value.match(/^#([0-9a-fA-F]{8})$/)
        if (m) {
            var h8 = m[1].toUpperCase()
            var rgb = h8.slice(2)
            return {
                ok: true,
                r: parseInt(rgb.slice(0, 2), 16),
                g: parseInt(rgb.slice(2, 4), 16),
                b: parseInt(rgb.slice(4, 6), 16),
                hex: "#" + rgb
            }
        }
        m = value.match(/^rgba?\(\s*([+-]?\d+(?:\.\d+)?)\s*,\s*([+-]?\d+(?:\.\d+)?)\s*,\s*([+-]?\d+(?:\.\d+)?)(?:\s*,\s*([+-]?\d*(?:\.\d+)?))?\s*\)$/i)
        if (m) {
            var rr = clampNumber(m[1], 0, 255)
            var gg = clampNumber(m[2], 0, 255)
            var bb = clampNumber(m[3], 0, 255)
            return {
                ok: true,
                r: Math.round(rr),
                g: Math.round(gg),
                b: Math.round(bb),
                hex: rgbaToHex(rr, gg, bb)
            }
        }
        if (fallbackColor !== undefined && String(value) !== String(fallbackColor)) {
            return parseColorInput(String(fallbackColor || "#FFFFFF"), "#FFFFFF")
        }
        return {
            ok: false,
            r: 255,
            g: 255,
            b: 255,
            hex: "#FFFFFF"
        }
    }
    function rgbToHsv(r, g, b) {
        var rn = clampNumber(r, 0, 255) / 255.0
        var gn = clampNumber(g, 0, 255) / 255.0
        var bn = clampNumber(b, 0, 255) / 255.0
        var maxc = Math.max(rn, gn, bn)
        var minc = Math.min(rn, gn, bn)
        var d = maxc - minc
        var h = 0
        if (d > 1e-6) {
            if (maxc === rn) {
                h = 60 * (((gn - bn) / d) % 6)
            } else if (maxc === gn) {
                h = 60 * (((bn - rn) / d) + 2)
            } else {
                h = 60 * (((rn - gn) / d) + 4)
            }
        }
        if (h < 0) {
            h += 360
        }
        var s = maxc <= 1e-6 ? 0 : (d / maxc)
        var v = maxc
        return {
            h: Math.round(clampNumber(h, 0, 360)),
            s: Math.round(clampNumber(s * 100, 0, 100)),
            v: Math.round(clampNumber(v * 100, 0, 100))
        }
    }
    function hsvToRgb(h, s, v) {
        var hh = clampNumber(h, 0, 360)
        var ss = clampNumber(s, 0, 100) / 100.0
        var vv = clampNumber(v, 0, 100) / 100.0
        if (ss <= 1e-6) {
            var g = Math.round(vv * 255)
            return { r: g, g: g, b: g }
        }
        if (hh >= 360) {
            hh = 0
        }
        var c = vv * ss
        var x = c * (1 - Math.abs(((hh / 60) % 2) - 1))
        var m = vv - c
        var rp = 0
        var gp = 0
        var bp = 0
        if (hh < 60) {
            rp = c; gp = x; bp = 0
        } else if (hh < 120) {
            rp = x; gp = c; bp = 0
        } else if (hh < 180) {
            rp = 0; gp = c; bp = x
        } else if (hh < 240) {
            rp = 0; gp = x; bp = c
        } else if (hh < 300) {
            rp = x; gp = 0; bp = c
        } else {
            rp = c; gp = 0; bp = x
        }
        return {
            r: Math.round((rp + m) * 255),
            g: Math.round((gp + m) * 255),
            b: Math.round((bp + m) * 255)
        }
    }
    function refreshPreviewColor(syncText) {
        var rgb = hsvToRgb(pickerHue, pickerSaturation, pickerValue)
        var hex = rgbaToHex(rgb.r, rgb.g, rgb.b)
        previewColor = hex
        if (syncText) {
            hexText = hex
            if (hexInput && !hexInput.activeFocus) {
                hexInput.text = hex
            }
        }
        repaintTracks()
    }
    function repaintTracks() {
        if (hueSliderControl) {
            hueSliderControl.requestTrackPaint()
        }
        if (saturationSliderControl) {
            saturationSliderControl.requestTrackPaint()
        }
        if (valueSliderControl) {
            valueSliderControl.requestTrackPaint()
        }
    }
    function setPickerFromColor(raw, fallbackColor) {
        var parsed = parseColorInput(raw, fallbackColor || "#FFFFFF")
        var hsv = rgbToHsv(parsed.r, parsed.g, parsed.b)
        pickerHue = hsv.h
        pickerSaturation = hsv.s
        pickerValue = hsv.v
        currentColor = parsed.hex
        hexText = parsed.hex
        previewColor = parsed.hex
        if (hexInput) {
            hexInput.text = parsed.hex
        }
        repaintTracks()
    }
    function applyTypedColor() {
        var parsed = parseColorInput(hexText, previewColor)
        var hsv = rgbToHsv(parsed.r, parsed.g, parsed.b)
        pickerHue = hsv.h
        pickerSaturation = hsv.s
        pickerValue = hsv.v
        hexText = parsed.hex
        previewColor = parsed.hex
        if (hexInput) {
            hexInput.text = parsed.hex
        }
        repaintTracks()
    }
    function openWith(rawColor, titleText, fallbackColor) {
        dialogTitle = String(titleText || "Выбор цвета")
        acceptInFlight = false
        setPickerFromColor(rawColor, fallbackColor || "#FFFFFF")
        visible = true
        raise()
        requestActivate()
    }

    onClosing: function(close) {
        if (!acceptInFlight) {
            canceled()
        }
        acceptInFlight = false
    }

    component EditorSectionLabel: Label {
        color: root.theme ? root.theme.textPrimary : "#D0D0D0"
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }
    component EditorFieldLabel: Label {
        color: root.theme ? root.theme.textSecondary : "#909090"
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
    component SliderNumberControl: RowLayout {
        id: control
        property real minValue: 0
        property real maxValue: 100
        property real step: 1
        property int decimals: 0
        property real value: 0
        property string trackMode: "neutral"
        property real trackHue: 0
        property real trackSaturation: 100
        property real trackValue: 100
        property color thumbAccentColor: Qt.rgba(1, 1, 1, 0.08)
        signal valueCommitted(real value)
        function requestTrackPaint() {
            sliderTrackFill.requestPaint()
        }
        Layout.fillWidth: true
        spacing: 8

        Slider {
            id: slider
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 10
            implicitHeight: 30
            from: control.minValue
            to: control.maxValue
            stepSize: control.step
            value: control.value
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0
            hoverEnabled: true

            onMoved: control.valueCommitted(value)
            onValueChanged: if (pressed) control.valueCommitted(value)

            background: Item {
                x: slider.leftPadding
                y: slider.topPadding + (slider.availableHeight - height) / 2
                width: slider.availableWidth
                height: 26

                NeumoInsetSurface {
                    id: sliderTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 12
                    theme: root.theme
                    radius: 6
                    fillColor: root.theme ? root.theme.fieldInlineFillColor : "#252525"
                    contentPadding: 0
                    insetDarkColor: root.theme
                        ? Qt.rgba(root.theme.shadowDarkBase.r, root.theme.shadowDarkBase.g, root.theme.shadowDarkBase.b, 0.92)
                        : "#D6151618"
                    insetLightColor: root.theme
                        ? Qt.rgba(root.theme.shadowLightBase.r, root.theme.shadowLightBase.g, root.theme.shadowLightBase.b, 0.44)
                        : "#553B3C40"
                }

                Canvas {
                    id: sliderTrackFill
                    anchors.left: sliderTrack.left
                    anchors.right: sliderTrack.right
                    anchors.verticalCenter: sliderTrack.verticalCenter
                    height: Math.max(4, sliderTrack.height - 4)
                    antialiasing: false

                    function trackColorAt(t) {
                        if (control.trackMode === "hsvHue") {
                            return root.hsvToRgb(t * 360.0, control.trackSaturation, control.trackValue)
                        }
                        if (control.trackMode === "hsvSaturation") {
                            return root.hsvToRgb(control.trackHue, t * 100.0, control.trackValue)
                        }
                        if (control.trackMode === "hsvValue") {
                            return root.hsvToRgb(control.trackHue, control.trackSaturation, t * 100.0)
                        }
                        var neutral = root.theme ? root.theme.textPrimary : Qt.rgba(0.94, 0.94, 0.94, 1.0)
                        return {
                            r: Math.round(neutral.r * 255),
                            g: Math.round(neutral.g * 255),
                            b: Math.round(neutral.b * 255)
                        }
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.clearRect(0, 0, width, height)
                        if (width <= 0 || height <= 0) {
                            return
                        }
                        if (control.trackMode === "neutral") {
                            return
                        }

                        var radius = height / 2
                        ctx.save()
                        ctx.beginPath()
                        ctx.moveTo(radius, 0)
                        ctx.lineTo(width - radius, 0)
                        ctx.arc(width - radius, radius, radius, -Math.PI / 2, Math.PI / 2, false)
                        ctx.lineTo(radius, height)
                        ctx.arc(radius, radius, radius, Math.PI / 2, -Math.PI / 2, false)
                        ctx.closePath()
                        ctx.clip()

                        var steps = Math.max(1, Math.round(width))
                        for (var i = 0; i < steps; ++i) {
                            var t = steps <= 1 ? 0 : (i / (steps - 1))
                            var rgb = trackColorAt(t)
                            ctx.fillStyle = "rgb(" + rgb.r + "," + rgb.g + "," + rgb.b + ")"
                            ctx.fillRect(i, 0, 1, height)
                        }

                        ctx.fillStyle = "rgba(255,255,255,0.08)"
                        ctx.fillRect(0, 0, width, height * 0.45)
                        ctx.restore()
                    }
                }

                Rectangle {
                    anchors.left: sliderTrackFill.left
                    anchors.verticalCenter: sliderTrackFill.verticalCenter
                    width: control.trackMode === "neutral"
                        ? Math.max(sliderTrackFill.height, Math.round(slider.visualPosition * sliderTrackFill.width))
                        : sliderTrackFill.width
                    height: sliderTrackFill.height
                    radius: sliderTrackFill.height / 2
                    color: control.trackMode === "neutral"
                        ? Qt.rgba(
                            root.theme ? root.theme.textPrimary.r : 0.94,
                            root.theme ? root.theme.textPrimary.g : 0.94,
                            root.theme ? root.theme.textPrimary.b : 0.94,
                            slider.pressed ? 0.22 : 0.14)
                        : Qt.rgba(1, 1, 1, slider.pressed ? 0.04 : 0.02)
                }

                Rectangle {
                    anchors.fill: sliderTrackFill
                    radius: sliderTrackFill.height / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.16)
                }
            }

            handle: Item {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + (slider.availableHeight - height) / 2
                width: 22
                height: 22

                NeumoRaisedSurface {
                    anchors.fill: parent
                    theme: root.theme
                    radius: width / 2
                    fillColor: root.theme ? root.theme.baseColor : "#2D2D2D"
                    shadowOffset: slider.pressed ? 2.1 : (slider.hovered ? 3.6 : 2.8)
                    shadowRadius: slider.pressed ? 4.6 : (slider.hovered ? 7.4 : 5.8)
                    shadowSamples: 17
                    shadowDarkColor: slider.hovered
                        ? (root.theme ? root.theme.raisedShadowDarkColorHover : "#FC151618")
                        : (root.theme ? root.theme.raisedShadowDarkColor : "#B8151618")
                    shadowLightColor: slider.hovered
                        ? (root.theme ? root.theme.raisedShadowLightColorHover : "#AD55565C")
                        : (root.theme ? root.theme.raisedShadowLightColor : "#703B3C40")
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: width / 2
                    color: control.thumbAccentColor
                    opacity: slider.hovered ? 1.0 : 0.92
                }
            }
        }

        NeumoStepperField {
            theme: root.theme
            from: control.minValue
            to: control.maxValue
            stepSize: control.step
            decimals: control.decimals
            value: control.value
            compactMode: true
            visualStyle: "launcherInline"
            Layout.minimumWidth: 70
            Layout.preferredWidth: 70
            Layout.maximumWidth: 70
            Layout.alignment: Qt.AlignVCenter
            onValueModified: control.valueCommitted(value)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        EditorSectionLabel {
            Layout.fillWidth: true
            text: root.dialogTitle
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            NeumoInsetSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                theme: root.theme
                radius: 14
                fillColor: root.theme ? root.theme.fieldInsetFillColor : "#252525"
                contentPadding: 6

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: root.currentColor
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.18)

                    Label {
                        anchors.centerIn: parent
                        text: "Текущий"
                        color: "#202020"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }

            NeumoInsetSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                theme: root.theme
                radius: 14
                fillColor: root.theme ? root.theme.fieldInsetFillColor : "#252525"
                contentPadding: 6

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: root.previewColor
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.18)

                    Label {
                        anchors.centerIn: parent
                        text: "Новый"
                        color: "#202020"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        EditorFieldLabel { text: "Тон" }
        SliderNumberControl {
            id: hueSliderControl
            minValue: 0
            maxValue: 360
            step: 1
            decimals: 0
            trackMode: "hsvHue"
            trackSaturation: root.pickerSaturation
            trackValue: root.pickerValue
            thumbAccentColor: root.previewColor
            value: root.pickerHue
            onValueCommitted: {
                root.pickerHue = Math.round(value)
                root.refreshPreviewColor(true)
            }
        }

        EditorFieldLabel { text: "Насыщенность" }
        SliderNumberControl {
            id: saturationSliderControl
            minValue: 0
            maxValue: 100
            step: 1
            decimals: 0
            trackMode: "hsvSaturation"
            trackHue: root.pickerHue
            trackValue: root.pickerValue
            thumbAccentColor: root.previewColor
            value: root.pickerSaturation
            onValueCommitted: {
                root.pickerSaturation = Math.round(value)
                root.refreshPreviewColor(true)
            }
        }

        EditorFieldLabel { text: "Яркость" }
        SliderNumberControl {
            id: valueSliderControl
            minValue: 0
            maxValue: 100
            step: 1
            decimals: 0
            trackMode: "hsvValue"
            trackHue: root.pickerHue
            trackSaturation: root.pickerSaturation
            thumbAccentColor: root.previewColor
            value: root.pickerValue
            onValueCommitted: {
                root.pickerValue = Math.round(value)
                root.refreshPreviewColor(true)
            }
        }

        EditorFieldLabel { text: "Код цвета (HEX / RGB(A))" }
        NeumoTextField {
            id: hexInput
            theme: root.theme
            visualStyle: "launcherInline"
            Layout.fillWidth: true
            text: root.hexText
            placeholderText: "#RRGGBB или rgb(255,255,255)"
            selectByMouse: true
            onTextEdited: root.hexText = text
            onEditingFinished: {
                root.hexText = text
                root.applyTypedColor()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            NeumoRaisedActionButton {
                Layout.fillWidth: true
                theme: root.theme
                compactMode: true
                text: "Отмена"
                onClicked: root.close()
            }

            NeumoRaisedActionButton {
                Layout.fillWidth: true
                theme: root.theme
                compactMode: true
                text: "Применить"
                onClicked: {
                    root.acceptInFlight = true
                    root.colorAccepted(root.previewColor)
                    root.close()
                }
            }
        }
    }
}
