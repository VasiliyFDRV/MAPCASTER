import QtQuick
import QtQuick.Controls

FocusScope {
    id: root

    property var theme
    property real value: 0.0
    property real from: 0.0
    property real to: 9999.0
    property real stepSize: 1.0
    property int decimals: 2
    property bool compactMode: false
    property bool wheelAdjustEnabled: false
    property string visualStyle: "launcherInline" // launcherInline | default

    readonly property bool launcherInlineStyle: visualStyle === "launcherInline"
    readonly property bool inlineHovered: fieldHover.hovered || leftArea.containsMouse || rightArea.containsMouse || editor.hovered
    readonly property bool inlineInteractive: launcherInlineStyle && (inlineHovered || root.activeFocus)
    readonly property real inlineInsetDarkAlpha: Math.min(
        1.0,
        (root.theme && root.theme.insetDarkAlpha !== undefined ? root.theme.insetDarkAlpha : 0.86)
            + (root.inlineInteractive ? 0.20 : 0.0)
    )
    readonly property real inlineInsetLightAlpha: Math.min(
        1.0,
        (root.theme && root.theme.insetLightAlpha !== undefined ? root.theme.insetLightAlpha : 0.60)
            + (root.inlineInteractive ? 0.14 : 0.0)
    )

    property color surfaceColor: launcherInlineStyle
        ? (theme ? theme.fieldInlineFillColor : "#2D2D2D")
        : (theme ? theme.fieldInsetFillColor : "#262626")

    property color inlineOutlineColor: theme ? theme.fieldInlineFocusColor : "#8C8C8C"

    property color outlineColor: launcherInlineStyle
        ? (root.activeFocus
            ? inlineOutlineColor
            : (inlineHovered ? inlineOutlineColor : "transparent"))
        : (root.activeFocus
            ? (theme ? theme.fieldBorderFocusColor : "#ABABAB")
            : (inlineHovered
                ? (theme ? theme.fieldBorderHoverColor : "#626262")
                : (theme ? theme.fieldBorderColor : "#4D4D4D")))

    property real outlineWidth: launcherInlineStyle
        ? (root.activeFocus ? 0.65 : (inlineHovered ? 0.45 : 0.0))
        : 1

    property real outlineOpacity: launcherInlineStyle
        ? ((root.activeFocus ? 0.44 : (inlineHovered ? 0.24 : 0.0)) * (root.enabled ? 1.0 : 0.55))
        : (root.enabled ? 1.0 : 0.55)

    readonly property bool editFieldHovered: editor.hovered

    signal valueModified(real value)

    implicitWidth: compactMode ? 116 : 144
    implicitHeight: compactMode ? 38 : 42

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

    HoverHandler {
        id: fieldHover
    }

    NeumoInsetSurface {
        anchors.fill: parent
        theme: root.theme
        radius: compactMode ? 12 : 14
        fillColor: root.surfaceColor
        contentPadding: 0
        insetOffset: root.theme ? root.theme.insetOffset : 6
        insetDarkRadius: root.theme ? root.theme.insetDarkRadius : 9.5
        insetDarkColor: root.theme
            ? Qt.rgba(root.theme.shadowDarkBase.r, root.theme.shadowDarkBase.g, root.theme.shadowDarkBase.b, root.inlineInsetDarkAlpha)
            : "#CC151618"
        insetLightOffset: root.theme ? root.theme.insetLightOffset : -6
        insetLightRadius: root.theme ? root.theme.insetLightRadius : 7.5
        insetLightColor: root.theme
            ? Qt.rgba(root.theme.shadowLightBase.r, root.theme.shadowLightBase.g, root.theme.shadowLightBase.b, root.inlineInsetLightAlpha)
            : "#663B3C40"
    }

    Rectangle {
        anchors.fill: parent
        radius: compactMode ? 12 : 14
        color: "transparent"
        border.width: root.outlineWidth
        border.color: root.outlineColor
        opacity: root.outlineOpacity

        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    Item {
        id: body
        anchors.fill: parent
        anchors.leftMargin: compactMode ? 3 : 4
        anchors.rightMargin: compactMode ? 3 : 4
        anchors.topMargin: compactMode ? 4 : 5
        anchors.bottomMargin: compactMode ? 4 : 5

        readonly property int segmentWidth: compactMode ? 16 : 18

        Item {
            id: leftSegment
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: body.segmentWidth

            Rectangle {
                anchors.fill: parent
                radius: compactMode ? 7 : 8
                color: theme ? theme.baseColor : "#2D2D2D"
                opacity: leftArea.pressed ? 0.32 : (leftArea.containsMouse ? 0.22 : 0.0)

                Behavior on opacity {
                    NumberAnimation { duration: 90 }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "-"
                color: root.theme ? root.theme.textPrimary : "#D0D0D0"
                font.pixelSize: compactMode ? 13 : 15
                font.weight: Font.DemiBold
                opacity: root.enabled ? 1.0 : 0.45
            }

            MouseArea {
                id: leftArea
                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.stepBy(-1)
            }
        }

        Item {
            id: rightSegment
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: body.segmentWidth

            Rectangle {
                anchors.fill: parent
                radius: compactMode ? 7 : 8
                color: theme ? theme.baseColor : "#2D2D2D"
                opacity: rightArea.pressed ? 0.32 : (rightArea.containsMouse ? 0.22 : 0.0)

                Behavior on opacity {
                    NumberAnimation { duration: 90 }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "+"
                color: root.theme ? root.theme.textPrimary : "#D0D0D0"
                font.pixelSize: compactMode ? 12 : 14
                font.weight: Font.DemiBold
                opacity: root.enabled ? 1.0 : 0.45
            }

            MouseArea {
                id: rightArea
                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.stepBy(1)
            }
        }

        TextField {
            id: editor
            anchors.left: leftSegment.right
            anchors.right: rightSegment.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: compactMode ? 4 : 5
            anchors.rightMargin: compactMode ? 4 : 5
            color: root.theme ? root.theme.textPrimary : "#D0D0D0"
            selectedTextColor: root.theme ? root.theme.fieldSelectedTextColor : "#F4F4F6"
            selectionColor: root.theme ? root.theme.fieldSelectionColor : "#6C6C6C"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: compactMode ? 12 : 13
            hoverEnabled: true
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
    }

    WheelHandler {
        target: null
        enabled: root.enabled && root.wheelAdjustEnabled && (leftArea.containsMouse || rightArea.containsMouse || editor.activeFocus)
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
