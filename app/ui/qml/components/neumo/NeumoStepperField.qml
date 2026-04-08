import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root

    property var theme
    property real value: 0.0
    property real from: 0.0
    property real to: 9999.0
    property real stepSize: 1.0
    property int decimals: 2

    signal valueModified(real value)

    implicitWidth: 154
    implicitHeight: 42

    function decimalsFactor() {
        return Math.pow(10, Math.max(0, decimals))
    }

    function clampValue(raw) {
        return Math.max(from, Math.min(to, raw))
    }

    function normalizedValue(raw) {
        var factor = decimalsFactor()
        return Math.round(clampValue(raw) * factor) / factor
    }

    function formatValue(raw) {
        return Number(normalizedValue(raw)).toFixed(Math.max(0, decimals))
    }

    function setCurrentValue(raw, emitSignal) {
        var next = normalizedValue(raw)
        var changed = Math.abs(next - value) > 0.000001
        value = next
        if (!editor.activeFocus || changed) {
            editor.text = formatValue(next)
        }
        if (emitSignal) {
            valueModified(next)
        }
    }

    function stepBy(direction) {
        setCurrentValue(value + (stepSize * direction), true)
    }

    function commitEditorValue() {
        var raw = String(editor.text || "").trim()
        if (raw.length === 0) {
            editor.text = formatValue(value)
            return
        }
        var parsed = Number(raw)
        if (!isFinite(parsed)) {
            editor.text = formatValue(value)
            return
        }
        setCurrentValue(parsed, true)
    }

    onValueChanged: {
        if (!editor.activeFocus) {
            editor.text = formatValue(value)
        }
    }

    Component.onCompleted: {
        editor.text = formatValue(value)
    }

    NeumoInsetSurface {
        anchors.fill: parent
        theme: root.theme
        radius: 14
        fillColor: theme ? theme.fieldInsetFillColor : "#262626"
        contentPadding: 0
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "transparent"
        border.width: 1
        border.color: root.activeFocus
            ? (theme ? theme.fieldBorderFocusColor : "#ABABAB")
            : (editor.hovered
                ? (theme ? theme.fieldBorderHoverColor : "#626262")
                : (theme ? theme.fieldBorderColor : "#4D4D4D"))
        opacity: root.enabled ? 1.0 : 0.55

        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 6

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            NeumoRaisedSurface {
                anchors.fill: parent
                theme: root.theme
                radius: 8
                fillColor: theme ? theme.baseColor : "#2D2D2D"
                shadowOffset: 2.0
                shadowRadius: 5.0
                shadowSamples: 17
                shadowDarkColor: theme
                    ? Qt.rgba(theme.shadowDarkBase.r, theme.shadowDarkBase.g, theme.shadowDarkBase.b, 0.55)
                    : "#8C151618"
                shadowLightColor: theme
                    ? Qt.rgba(theme.shadowLightBase.r, theme.shadowLightBase.g, theme.shadowLightBase.b, 0.24)
                    : "#3D55565C"
            }

            Text {
                anchors.centerIn: parent
                text: "-"
                color: root.theme ? root.theme.textPrimary : "#D0D0D0"
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.enabled
                onClicked: root.stepBy(-1)
            }
        }

        TextField {
            id: editor
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            color: root.theme ? root.theme.textPrimary : "#D0D0D0"
            selectedTextColor: root.theme ? root.theme.fieldSelectedTextColor : "#F4F4F6"
            selectionColor: root.theme ? root.theme.fieldSelectionColor : "#6C6C6C"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 13
            background: null
            padding: 0
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            validator: DoubleValidator {
                bottom: Math.min(root.from, root.to)
                top: Math.max(root.from, root.to)
                decimals: Math.max(0, root.decimals)
                notation: DoubleValidator.StandardNotation
            }
            onEditingFinished: root.commitEditorValue()
            Keys.onReturnPressed: function(event) {
                event.accepted = true
                root.commitEditorValue()
            }
            Keys.onEnterPressed: function(event) {
                event.accepted = true
                root.commitEditorValue()
            }
            Keys.onUpPressed: function(event) {
                event.accepted = true
                root.stepBy(1)
            }
            Keys.onDownPressed: function(event) {
                event.accepted = true
                root.stepBy(-1)
            }
        }

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            NeumoRaisedSurface {
                anchors.fill: parent
                theme: root.theme
                radius: 8
                fillColor: theme ? theme.baseColor : "#2D2D2D"
                shadowOffset: 2.0
                shadowRadius: 5.0
                shadowSamples: 17
                shadowDarkColor: theme
                    ? Qt.rgba(theme.shadowDarkBase.r, theme.shadowDarkBase.g, theme.shadowDarkBase.b, 0.55)
                    : "#8C151618"
                shadowLightColor: theme
                    ? Qt.rgba(theme.shadowLightBase.r, theme.shadowLightBase.g, theme.shadowLightBase.b, 0.24)
                    : "#3D55565C"
            }

            Text {
                anchors.centerIn: parent
                text: "+"
                color: root.theme ? root.theme.textPrimary : "#D0D0D0"
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.enabled
                onClicked: root.stepBy(1)
            }
        }
    }

    WheelHandler {
        target: null
        enabled: root.enabled
        onWheel: function(event) {
            if (event.angleDelta.y > 0) {
                root.stepBy(1)
            } else if (event.angleDelta.y < 0) {
                root.stepBy(-1)
            }
            event.accepted = true
        }
    }
}
