import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: diceWindow
    objectName: "diceWindow"
    width: 400
    height: 640
    minimumWidth: 400
    minimumHeight: 640
    visible: true
    color: "#111111"
    title: "DnD Maps - Дайсы"

    property int resetToken: 0

    property int d20Count: 0
    property string d20Mode: "normal"
    property int d20Bonus: 0

    property int d4Count: 0
    property int d6Count: 0
    property int d8Count: 0
    property int d10Count: 0
    property int d12Count: 0
    property int standardBonus: 0

    property var d20Result: null
    property var standardResult: null
    property var d100Result: null

    property color textPrimary: "#EFEFF2"
    property color textSecondary: "#B0B0B0"
    property color panelColor: "#242424"
    property color panelBorder: "#4A4A4A"

    function effectiveCount(countValue) {
        return countValue > 0 ? countValue : 1
    }

    function resetState() {
        d20Count = 0
        d20Mode = "normal"
        d20Bonus = 0

        d4Count = 0
        d6Count = 0
        d8Count = 0
        d10Count = 0
        d12Count = 0
        standardBonus = 0

        clearResults()
    }

    function clearResults() {
        d20Result = null
        standardResult = null
        d100Result = null
    }

    function canRollStandard() {
        return (d4Count + d6Count + d8Count + d10Count + d12Count) > 0
    }

    function canRollAll() {
        return (d20Count > 0) || canRollStandard()
    }

    function setD20Mode(newMode) {
        if (d20Mode === newMode) {
            d20Mode = "normal"
        } else {
            d20Mode = newMode
        }
    }

    function rollD20Only() {
        clearResults()
        d20Result = diceController.roll_d20(effectiveCount(d20Count), d20Mode, d20Bonus)
    }

    function rollStandardOnly() {
        if (!canRollStandard()) {
            return
        }
        clearResults()
        standardResult = diceController.roll_standard(d4Count, d6Count, d8Count, d10Count, d12Count, standardBonus)
    }

    function rollSingleStandardDie(sides, configuredCount) {
        var c = effectiveCount(configuredCount)
        var d4 = 0
        var d6 = 0
        var d8 = 0
        var d10 = 0
        var d12 = 0
        if (sides === 4) d4 = c
        else if (sides === 6) d6 = c
        else if (sides === 8) d8 = c
        else if (sides === 10) d10 = c
        else if (sides === 12) d12 = c

        clearResults()
        standardResult = diceController.roll_standard(d4, d6, d8, d10, d12, standardBonus)
    }

    function rollD100Only() {
        clearResults()
        d100Result = diceController.roll_d100()
    }

    function rollAll() {
        if (!canRollAll()) {
            return
        }
        clearResults()
        var combined = diceController.roll_all(
            d20Count,
            d20Mode,
            d20Bonus,
            d4Count,
            d6Count,
            d8Count,
            d10Count,
            d12Count,
            standardBonus
        )
        d20Result = combined.d20
        standardResult = combined.standard
    }

    onResetTokenChanged: resetState()
    Component.onCompleted: resetState()

    component AppPanel: Rectangle {
        radius: 12
        color: panelColor
        border.color: panelBorder
        border.width: 1
    }

    component AppButton: Button {
        id: control
        property bool accent: false
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        activeFocusOnTab: false
        implicitHeight: 34

        contentItem: Text {
            text: control.text
            color: control.enabled ? "#F4F4F6" : "#8A8A8A"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 13
            font.weight: control.accent ? Font.DemiBold : Font.Medium
        }

        background: Rectangle {
            radius: 10
            border.width: 1
            border.color: control.accent ? "#A9A9A9" : "#555555"
            color: control.accent
                ? (control.down ? "#606060" : (control.hovered ? "#6E6E6E" : "#676767"))
                : (control.down ? "#2D2D2D" : (control.hovered ? "#363636" : "#313131"))
            opacity: control.enabled ? 1.0 : 0.45
        }
    }

    component ModeArrowButton: Button {
        id: control
        property string arrowText: "▲"
        property color activeColor: "#3F7A4A"
        property bool active: false
        implicitWidth: 26
        implicitHeight: 20
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        activeFocusOnTab: false

        text: ""

        contentItem: Text {
            text: control.arrowText
            color: "#F0F0F0"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        background: Rectangle {
            radius: 6
            border.width: 1
            border.color: control.active ? "#BBBBBB" : "#5B5B5B"
            color: control.active
                ? control.activeColor
                : (control.down ? "#3D3D3D" : (control.hovered ? "#363636" : "#2E2E2E"))
        }
    }

    component NumberInput: SpinBox {
        id: control
        editable: true
        from: 0
        to: 20
        stepSize: 1
        value: 0
        focusPolicy: Qt.NoFocus

        validator: IntValidator { bottom: control.from; top: control.to }

        textFromValue: function(value, locale) {
            return Number(value).toLocaleString(locale, 'f', 0)
        }

        valueFromText: function(text, locale) {
            var n = Number.fromLocaleString(locale, text)
            if (!isFinite(n)) {
                return control.from
            }
            return Math.round(n)
        }

        contentItem: TextInput {
            text: control.textFromValue(control.value, control.locale)
            color: "#EFEFF2"
            selectionColor: "#6A6A6A"
            selectedTextColor: "#FFFFFF"
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            font.pixelSize: 13
            validator: control.validator
            readOnly: !control.editable
            onTextEdited: {
                if (text.length === 0 || text === "-" || text === "+") {
                    return
                }
                var parsed = control.valueFromText(text, control.locale)
                if (!isFinite(parsed)) {
                    return
                }
                var bounded = Math.max(control.from, Math.min(control.to, parsed))
                if (control.value !== bounded) {
                    control.value = bounded
                }
            }
            onEditingFinished: control.value = control.valueFromText(text, control.locale)
        }

        background: Rectangle {
            radius: 8
            color: "#1F1F1F"
            border.width: 1
            border.color: "#4C4C4C"
        }

        up.indicator: Rectangle {
            implicitWidth: 22
            implicitHeight: 16
            color: control.up.pressed ? "#535353" : (control.up.hovered ? "#484848" : "#3A3A3A")
            border.color: "#5A5A5A"
            Text {
                anchors.centerIn: parent
                text: "▲"
                color: "#E5E5E5"
                font.pixelSize: 9
            }
        }

        down.indicator: Rectangle {
            implicitWidth: 22
            implicitHeight: 16
            color: control.down.pressed ? "#535353" : (control.down.hovered ? "#484848" : "#3A3A3A")
            border.color: "#5A5A5A"
            Text {
                anchors.centerIn: parent
                text: "▼"
                color: "#E5E5E5"
                font.pixelSize: 9
            }
        }
    }

    component DieGlyph: Item {
        id: glyph
        property string dieType: "d6"
        property string label: "d6"
        property color lineColor: "#E5E5E5"
        property color fillColor: "transparent"
        property color textColor: "#EFEFF2"
        property real lineWidth: 1.4
        property real valueOpacity: 1.0

        implicitWidth: 40
        implicitHeight: 40

        Canvas {
            id: canvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.clearRect(0, 0, width, height)
                ctx.globalAlpha = glyph.valueOpacity
                ctx.lineWidth = glyph.lineWidth
                ctx.strokeStyle = glyph.lineColor
                ctx.fillStyle = glyph.fillColor

                var w = width
                var h = height
                var cx = w * 0.5
                var cy = h * 0.5
                var pad = 3

                function polygon(points) {
                    if (points.length === 0) {
                        return
                    }
                    ctx.beginPath()
                    ctx.moveTo(points[0].x, points[0].y)
                    for (var i = 1; i < points.length; i++) {
                        ctx.lineTo(points[i].x, points[i].y)
                    }
                    ctx.closePath()
                    if (glyph.fillColor !== "transparent") {
                        ctx.fill()
                    }
                    ctx.stroke()
                }

                function regularPolygon(sides, radius, rotation) {
                    var points = []
                    for (var i = 0; i < sides; i++) {
                        var a = rotation + (Math.PI * 2 * i / sides)
                        points.push({"x": cx + Math.cos(a) * radius, "y": cy + Math.sin(a) * radius})
                    }
                    polygon(points)
                }

                if (glyph.dieType === "d4") {
                    polygon([
                        {"x": cx, "y": pad},
                        {"x": w - pad, "y": h - pad},
                        {"x": pad, "y": h - pad}
                    ])
                } else if (glyph.dieType === "d6") {
                    polygon([
                        {"x": pad, "y": pad},
                        {"x": w - pad, "y": pad},
                        {"x": w - pad, "y": h - pad},
                        {"x": pad, "y": h - pad}
                    ])
                } else if (glyph.dieType === "d8") {
                    polygon([
                        {"x": cx, "y": pad},
                        {"x": w - pad, "y": cy},
                        {"x": cx, "y": h - pad},
                        {"x": pad, "y": cy}
                    ])
                } else if (glyph.dieType === "d10") {
                    regularPolygon(4, Math.min(w, h) * 0.45, -Math.PI / 2)
                } else if (glyph.dieType === "d12") {
                    regularPolygon(10, Math.min(w, h) * 0.45, -Math.PI / 2)
                } else if (glyph.dieType === "d20") {
                    regularPolygon(6, Math.min(w, h) * 0.45, -Math.PI / 2)
                } else if (glyph.dieType === "d100") {
                    var backPad = 6
                    ctx.beginPath()
                    ctx.moveTo(cx + 4, backPad)
                    ctx.lineTo(w - backPad + 4, cy)
                    ctx.lineTo(cx + 4, h - backPad)
                    ctx.lineTo(backPad + 4, cy)
                    ctx.closePath()
                    ctx.stroke()
                    polygon([
                        {"x": cx, "y": pad},
                        {"x": w - pad, "y": cy},
                        {"x": cx, "y": h - pad},
                        {"x": pad, "y": cy}
                    ])
                } else {
                    polygon([
                        {"x": pad, "y": pad},
                        {"x": w - pad, "y": pad},
                        {"x": w - pad, "y": h - pad},
                        {"x": pad, "y": h - pad}
                    ])
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: glyph.label
            color: glyph.textColor
            font.pixelSize: 12
            font.weight: Font.DemiBold
            opacity: glyph.valueOpacity
        }

        onDieTypeChanged: canvas.requestPaint()
        onFillColorChanged: canvas.requestPaint()
        onLineColorChanged: canvas.requestPaint()
        onLineWidthChanged: canvas.requestPaint()
        onWidthChanged: canvas.requestPaint()
        onHeightChanged: canvas.requestPaint()
        Component.onCompleted: canvas.requestPaint()
    }

    component CountStepper: RowLayout {
        id: stepper
        property int from: 0
        property int to: 20
        property int value: 0

        function clamp(v) {
            return Math.max(from, Math.min(to, v))
        }

        spacing: 4

        Button {
            implicitWidth: 20
            implicitHeight: 20
            text: "\u25C0"
            focusPolicy: Qt.NoFocus
            onClicked: stepper.value = stepper.clamp(stepper.value - 1)
            contentItem: Text {
                text: parent.text
                color: "#E7E7EA"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 9
            }
            background: Rectangle {
                radius: 5
                color: parent.down ? "#4A4A4A" : (parent.hovered ? "#3F3F3F" : "#353535")
                border.color: "#5A5A5A"
                border.width: 1
            }
        }

        Rectangle {
            implicitWidth: 28
            implicitHeight: 20
            radius: 5
            color: "#1F1F1F"
            border.color: "#4C4C4C"
            border.width: 1

            TextInput {
                id: stepperInput
                anchors.fill: parent
                anchors.margins: 1
                text: String(stepper.value)
                color: "#EFEFF2"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 11
                validator: IntValidator { bottom: stepper.from; top: stepper.to }
                selectByMouse: true

                onEditingFinished: {
                    var n = parseInt(text)
                    if (isNaN(n)) {
                        n = stepper.from
                    }
                    stepper.value = stepper.clamp(n)
                }
            }
        }

        Button {
            implicitWidth: 20
            implicitHeight: 20
            text: "\u25B6"
            focusPolicy: Qt.NoFocus
            onClicked: stepper.value = stepper.clamp(stepper.value + 1)
            contentItem: Text {
                text: parent.text
                color: "#E7E7EA"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 9
            }
            background: Rectangle {
                radius: 5
                color: parent.down ? "#4A4A4A" : (parent.hovered ? "#3F3F3F" : "#353535")
                border.color: "#5A5A5A"
                border.width: 1
            }
        }

        onValueChanged: {
            if (stepperInput.text !== String(stepper.value)) {
                stepperInput.text = String(stepper.value)
            }
        }
    }

    component StandardDieRow: RowLayout {
        id: root
        property int sides: 6
        property alias countValue: qty.value

        Layout.fillWidth: true
        spacing: 8

        DieGlyph {
            dieType: "d" + String(root.sides)
            label: "d" + String(root.sides)
            implicitWidth: 38
            implicitHeight: 38
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.sides === 4) rollSingleStandardDie(4, d4Count)
                    else if (root.sides === 6) rollSingleStandardDie(6, d6Count)
                    else if (root.sides === 8) rollSingleStandardDie(8, d8Count)
                    else if (root.sides === 10) rollSingleStandardDie(10, d10Count)
                    else if (root.sides === 12) rollSingleStandardDie(12, d12Count)
                }
            }
        }

        Label {
            text: "\u041a\u043e\u043b\u0438\u0447\u0435\u0441\u0442\u0432\u043e:"
            color: textSecondary
            font.pixelSize: 11
        }

        CountStepper {
            id: qty
            from: 0
            to: 20
            value: 0
        }

        Item { Layout.fillWidth: true }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: Math.max(220, diceWindow.width - 32)
                spacing: 8

                AppPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: resultsColumn.implicitHeight + 14
                    color: "#0F0F10"
                    border.color: "#2D2D2D"

                    ColumnLayout {
                        id: resultsColumn
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 7

                        Label {
                            text: "Результаты"
                            color: textPrimary
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        Item {
                            id: resultsViewport
                            Layout.fillWidth: true
                            Layout.minimumHeight: 85
                            Layout.preferredHeight: Math.max(85, resultsRow.implicitHeight)
                            clip: true

                            Rectangle {
                                anchors.fill: parent
                                visible: !(d20Result && d20Result.active) && !(standardResult && standardResult.active) && !(d100Result && d100Result.active)
                                radius: 9
                                color: "#0C0C0D"
                                border.width: 1
                                border.color: "#373737"
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u0411\u0440\u043e\u0441\u043a\u043e\u0432 \u043f\u043e\u043a\u0430 \u043d\u0435\u0442"
                                    color: textSecondary
                                    font.pixelSize: 12
                                }
                            }

                            RowLayout {
                                id: resultsRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                visible: (d20Result && d20Result.active) || (standardResult && standardResult.active) || (d100Result && d100Result.active)
                                spacing: 8

                                AppPanel {
                                    visible: d20Result && d20Result.active
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: d20ResCol.implicitHeight + 10
                                    clip: true

                                    ColumnLayout {
                                        id: d20ResCol
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        spacing: 3
                                        Label { text: String(d20Result ? d20Result.formula : "") + ":"; color: textSecondary; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                        Label { text: d20Result ? String(d20Result.total) : ""; color: textPrimary; font.pixelSize: 20; font.weight: Font.Bold }
                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 3
                                            Repeater {
                                                model: d20Result ? d20Result.rolls : []
                                                delegate: Item {
                                                    width: modelData.type === "pair" ? 56 : 28
                                                    height: 28
                                                    Row {
                                                        anchors.fill: parent
                                                        spacing: 2
                                                        DieGlyph {
                                                            dieType: "d20"
                                                            label: modelData.type === "pair" ? String(modelData.first) : String(modelData.value)
                                                            implicitWidth: 27
                                                            implicitHeight: 27
                                                            valueOpacity: modelData.type === "pair" && modelData.first !== modelData.picked ? 0.35 : 1.0
                                                        }
                                                        DieGlyph {
                                                            visible: modelData.type === "pair"
                                                            dieType: "d20"
                                                            label: modelData.type === "pair" ? String(modelData.second) : ""
                                                            implicitWidth: 27
                                                            implicitHeight: 27
                                                            valueOpacity: modelData.type === "pair" && modelData.second !== modelData.picked ? 0.35 : 1.0
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                AppPanel {
                                    visible: standardResult && standardResult.active
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: stdResCol.implicitHeight + 10
                                    clip: true

                                    ColumnLayout {
                                        id: stdResCol
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        spacing: 3
                                        Label { text: String(standardResult ? standardResult.formula : "") + ":"; color: textSecondary; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                        Label { text: standardResult ? String(standardResult.total) : ""; color: textPrimary; font.pixelSize: 20; font.weight: Font.Bold }
                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 3
                                            Repeater {
                                                model: standardResult ? standardResult.rolls : []
                                                delegate: DieGlyph {
                                                    dieType: "d" + String(modelData.sides)
                                                    label: String(modelData.value)
                                                    implicitWidth: 26
                                                    implicitHeight: 26
                                                }
                                            }
                                        }
                                    }
                                }

                                AppPanel {
                                    visible: d100Result && d100Result.active
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: d100ResCol.implicitHeight + 10
                                    clip: true

                                    ColumnLayout {
                                        id: d100ResCol
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        spacing: 3
                                        DieGlyph {
                                            dieType: "d100"
                                            label: d100Result ? String(d100Result.total) : ""
                                            implicitWidth: 34
                                            implicitHeight: 34
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        Label {
                                            text: d100Result ? String(d100Result.total) : ""
                                            color: textPrimary
                                            font.pixelSize: 19
                                            font.weight: Font.Bold
                                            horizontalAlignment: Text.AlignHCenter
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                AppPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: d20Column.implicitHeight + 14

                    ColumnLayout {
                        id: d20Column
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            DieGlyph {
                                dieType: "d20"
                                label: "d20"
                                implicitWidth: 46
                                implicitHeight: 46
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rollD20Only()
                                }
                            }

                            ColumnLayout {
                                spacing: 4
                                ModeArrowButton {
                                    arrowText: "\u25B2"
                                    active: d20Mode === "advantage"
                                    activeColor: "#2F8B4B"
                                    onClicked: setD20Mode("advantage")
                                }
                                ModeArrowButton {
                                    arrowText: "\u25BC"
                                    active: d20Mode === "disadvantage"
                                    activeColor: "#A33C3C"
                                    onClicked: setD20Mode("disadvantage")
                                }
                            }

                            Label { text: "\u041a\u043e\u043b\u0438\u0447\u0435\u0441\u0442\u0432\u043e:"; color: textSecondary; font.pixelSize: 11 }
                            CountStepper {
                                from: 0
                                to: 20
                                value: d20Count
                                onValueChanged: d20Count = value
                            }

                            Label { text: "\u0411\u043e\u043d\u0443\u0441:"; color: textSecondary; font.pixelSize: 11 }
                            CountStepper {
                                from: -20
                                to: 20
                                value: d20Bonus
                                onValueChanged: d20Bonus = value
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                AppPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: standardColumn.implicitHeight + 14

                    ColumnLayout {
                        id: standardColumn
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        StandardDieRow { sides: 4; countValue: d4Count; onCountValueChanged: d4Count = countValue }
                        StandardDieRow { sides: 6; countValue: d6Count; onCountValueChanged: d6Count = countValue }
                        StandardDieRow { sides: 8; countValue: d8Count; onCountValueChanged: d8Count = countValue }
                        StandardDieRow { sides: 10; countValue: d10Count; onCountValueChanged: d10Count = countValue }
                        StandardDieRow { sides: 12; countValue: d12Count; onCountValueChanged: d12Count = countValue }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Label { text: "\u0411\u043e\u043d\u0443\u0441:"; color: textSecondary; font.pixelSize: 11 }
                            CountStepper {
                                from: -20
                                to: 20
                                value: standardBonus
                                onValueChanged: standardBonus = value
                            }
                            Item { Layout.fillWidth: true }
                        }

                        AppButton {
                            Layout.fillWidth: true
                            text: "\u0411\u0440\u043e\u0441\u0438\u0442\u044c D4-D12"
                            enabled: canRollStandard()
                            onClicked: rollStandardOnly()
                        }
                    }
                }

                AppPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        DieGlyph {
                            dieType: "d100"
                            label: "d100"
                            implicitWidth: 42
                            implicitHeight: 42
                        }

                        AppButton {
                            Layout.fillWidth: true
                            text: "\u0411\u0440\u043e\u0441\u0438\u0442\u044c D100"
                            onClicked: rollD100Only()
                        }
                    }
                }
            }
        }

        AppButton {
            Layout.fillWidth: true
            text: "Бросить все"
            accent: true
            enabled: canRollAll()
            onClicked: rollAll()
        }
    }
}
