import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "neumo"
import "MediaValueUtils.js" as MediaValueUtils

FocusScope {
    id: root

    property var theme
    property string modeCode: "create"
    property var initialDraft: ({})
    property int openToken: 0

    property string sceneName: ""
    property string originalName: ""
    property bool mapEnabled: true
    property bool backgroundEnabled: false
    property bool gridEnabled: true
    property string mapType: "color"
    property string backgroundType: "color"
    property string mapValue: "#2E2E2E"
    property string backgroundValue: "#1F1F1F"
    property real gridCellSize: 8.0
    property real gridLineThickness: 1.0
    property real gridOpacity: 0.45
    property string gridColor: "#000000"
    property string initialFingerprint: ""

    readonly property string modeTitle: modeCode === "edit"
        ? "\u0420\u0435\u0434\u0430\u043a\u0442\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435 \u0441\u0446\u0435\u043d\u044b"
        : "\u0421\u043e\u0437\u0434\u0430\u043d\u0438\u0435 \u0441\u0446\u0435\u043d\u044b"
    readonly property string saveButtonText: modeCode === "edit"
        ? "\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c"
        : "\u0421\u043e\u0437\u0434\u0430\u0442\u044c"
    readonly property string currentDraftFingerprint: JSON.stringify(root.currentDraft())
    readonly property bool dirty: currentDraftFingerprint !== initialFingerprint
    readonly property bool narrowLayout: width < 360
    readonly property int sectionRadius: narrowLayout ? 18 : 20
    readonly property int sectionPadding: narrowLayout ? 12 : 15
    readonly property int sectionSpacing: narrowLayout ? 10 : 13
    readonly property int sectionOuterGutter: narrowLayout ? 6 : 9
    readonly property int headerTitleSize: narrowLayout ? 20 : 22
    readonly property string gridSizeLabel: "\u0420\u0430\u0437\u043c\u0435\u0440 \u043a\u043b\u0435\u0442\u043a\u0438"
    readonly property string gridLineThicknessLabel: "\u0422\u043e\u043b\u0449\u0438\u043d\u0430 \u043b\u0438\u043d\u0438\u0438"
    readonly property string gridOpacityLabel: "\u041f\u0440\u043e\u0437\u0440\u0430\u0447\u043d\u043e\u0441\u0442\u044c \u0441\u0435\u0442\u043a\u0438"
    readonly property int compactGridLabelWidth: narrowLayout ? 132 : 0

    signal backRequested(bool dirty)
    signal saveRequested(var draft)
    signal browseRequested(string target)
    signal colorRequested(string target, string currentValue)
    signal pasteRequested(string target)

    function pointerOverEditableControl() {
        return sceneNameField.hovered
            || gridColorField.hovered
            || mapMediaTile.inputFieldHovered
            || backgroundMediaTile.inputFieldHovered
            || gridCellWideField.editFieldHovered
            || gridLineWideField.editFieldHovered
            || gridOpacityWideField.editFieldHovered
            || gridCellCompactField.editFieldHovered
            || gridLineCompactField.editFieldHovered
            || gridOpacityCompactField.editFieldHovered
    }

    function clearEditorFocus() {
        focusSink.forceActiveFocus(Qt.MouseFocusReason)
    }

    function applyMediaValue(target, value, explicitType) {
        var nextValue = String(value || "").trim()
        var nextType = explicitType || MediaValueUtils.detectMediaTypeFromValue(nextValue, "color")
        if (target === "background") {
            backgroundValue = nextType === "color" ? MediaValueUtils.normalizeColorValue(nextValue, "#1F1F1F") : nextValue
            backgroundType = nextType
        } else {
            mapValue = nextType === "color" ? MediaValueUtils.normalizeColorValue(nextValue, "#2E2E2E") : nextValue
            mapType = nextType
        }
    }

    function loadDraft(draft) {
        var payload = draft || {}
        var draftMap = payload.map || {}
        var draftBackground = payload.background || {}
        var draftGrid = payload.grid || {}

        modeCode = payload.mode === "edit" ? "edit" : "create"
        sceneName = String(payload.name || "")
        originalName = String(payload.original_name || "")
        mapEnabled = draftMap.enabled === undefined ? true : Boolean(draftMap.enabled)
        backgroundEnabled = draftBackground.enabled === undefined ? true : Boolean(draftBackground.enabled)
        gridEnabled = draftGrid.enabled === undefined ? true : Boolean(draftGrid.enabled)
        mapType = String(draftMap.type || MediaValueUtils.detectMediaTypeFromValue(draftMap.value || "", "color"))
        backgroundType = String(draftBackground.type || MediaValueUtils.detectMediaTypeFromValue(draftBackground.value || "", "color"))
        mapValue = mapType === "color" ? MediaValueUtils.normalizeColorValue(draftMap.value || "#2E2E2E", "#2E2E2E") : String(draftMap.value || "")
        backgroundValue = backgroundType === "color" ? MediaValueUtils.normalizeColorValue(draftBackground.value || "#1F1F1F", "#1F1F1F") : String(draftBackground.value || "")
        gridCellSize = Number(draftGrid.cell_size_ft === undefined ? 8.0 : draftGrid.cell_size_ft)
        gridLineThickness = Number(draftGrid.line_thickness_px === undefined ? 1.0 : draftGrid.line_thickness_px)
        gridOpacity = Number(draftGrid.opacity === undefined ? 0.45 : draftGrid.opacity)
        gridColor = MediaValueUtils.normalizeColorValue(draftGrid.color || "#000000", "#000000")
        sceneNameField.text = sceneName
        gridColorField.text = gridColor
        initialFingerprint = currentDraftFingerprint
    }

    function currentDraft() {
        return {
            "mode": modeCode,
            "name": String(sceneName || "").trim(),
            "original_name": String(originalName || "").trim(),
            "map": {
                "enabled": mapEnabled,
                "type": mapType,
                "value": mapType === "color" ? MediaValueUtils.normalizeColorValue(mapValue, "#2E2E2E") : String(mapValue || "").trim(),
                "autoplay": true,
                "loop": true,
                "mute": true
            },
            "background": {
                "enabled": backgroundEnabled,
                "type": backgroundType,
                "value": backgroundType === "color" ? MediaValueUtils.normalizeColorValue(backgroundValue, "#1F1F1F") : String(backgroundValue || "").trim(),
                "autoplay": true,
                "loop": true,
                "mute": true
            },
            "grid": {
                "enabled": gridEnabled,
                "cell_size_ft": Number(gridCellSize.toFixed(2)),
                "line_thickness_px": Number(gridLineThickness.toFixed(2)),
                "opacity": Number(gridOpacity.toFixed(2)),
                "color": MediaValueUtils.normalizeColorValue(gridColor, "#000000")
            }
        }
    }

    function currentFingerprint() {
        return currentDraftFingerprint
    }

    function applyFileSelection(target, value) {
        applyMediaValue(target, value, null)
    }

    function applyPastedValue(target, value) {
        applyMediaValue(target, value, null)
    }

    function applyColorSelection(target, value) {
        var normalized = MediaValueUtils.normalizeColorValue(value, target === "background" ? "#1F1F1F" : "#2E2E2E")
        if (target === "grid") {
            gridColor = normalized
            gridColorField.text = normalized
            return
        }
        applyMediaValue(target, normalized, "color")
    }

    onOpenTokenChanged: loadDraft(initialDraft)
    Component.onCompleted: loadDraft(initialDraft)

    Item {
        id: focusSink
        width: 1
        height: 1
        opacity: 0
        anchors.left: parent.left
        anchors.top: parent.top
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        propagateComposedEvents: true
        preventStealing: false
        z: 1000
        onPressed: function(mouse) {
            if (!root.pointerOverEditableControl()) {
                root.clearEditorFocus()
            }
            mouse.accepted = false
        }
    }

    Flickable {
        id: editorScroll
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: editorContent.implicitHeight
        interactive: contentHeight > height
        ScrollBar.vertical: NeumoScrollBar {}
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        ColumnLayout {
            id: editorContent
            width: editorScroll.width
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: root.sectionOuterGutter
                Layout.rightMargin: root.sectionOuterGutter
                Layout.topMargin: root.narrowLayout ? 8 : 10
                spacing: 10

                Item {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 44
                    Layout.alignment: Qt.AlignVCenter

                    NeumoIconButton {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        theme: root.theme
                        width: 30
                        height: 30
                        iconSource: Qt.resolvedUrl("../icons/back.svg")
                        toolTip: "\u041d\u0430\u0437\u0430\u0434"
                        onClicked: {
                            root.clearEditorFocus()
                            root.backRequested(root.dirty)
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.modeTitle
                    color: root.theme ? root.theme.textPrimary : "#D0D0D0"
                    font.pixelSize: root.headerTitleSize
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

                Label {
                    text: "\u041d\u0430\u0437\u0432\u0430\u043d\u0438\u0435 \u0441\u0446\u0435\u043d\u044b"
                    color: root.theme ? root.theme.textSecondary : "#909090"
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    Layout.leftMargin: root.sectionOuterGutter
                    Layout.rightMargin: root.sectionOuterGutter
                }

                NeumoTextField {
                    id: sceneNameField
                    theme: root.theme
                    visualStyle: "launcherInline"
                    Layout.fillWidth: true
                    Layout.leftMargin: root.sectionOuterGutter
                    Layout.rightMargin: root.sectionOuterGutter
                    placeholderText: "\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u043d\u0430\u0437\u0432\u0430\u043d\u0438\u0435"
                    text: root.sceneName
                    onTextChanged: root.sceneName = text
                }

                NeumoRaisedSurface {
                    id: mapSection
                    theme: root.theme
                    Layout.fillWidth: true
                    Layout.leftMargin: root.sectionOuterGutter
                    Layout.rightMargin: root.sectionOuterGutter
                    Layout.topMargin: 2
                    Layout.preferredHeight: implicitHeight
                    implicitHeight: mapSectionContent.implicitHeight + contentPadding * 2
                    radius: root.sectionRadius
                    fillColor: root.theme ? root.theme.baseColor : "#2D2D2D"
                    shadowOffset: root.narrowLayout ? 3.5 : 4.4
                    shadowRadius: root.narrowLayout ? 8.0 : 9.4
                    shadowSamples: 23
                    contentPadding: root.sectionPadding

                    ColumnLayout {
                        id: mapSectionContent
                        width: parent.width
                        spacing: root.sectionSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Label {
                                Layout.fillWidth: true
                                text: "\u041a\u0430\u0440\u0442\u0430"
                                color: root.theme ? root.theme.textPrimary : "#D0D0D0"
                                font.pixelSize: root.narrowLayout ? 16 : 18
                                font.weight: Font.DemiBold
                            }

                            NeumoToggle {
                                theme: root.theme
                                checked: root.mapEnabled
                                onToggled: function(next) {
                                    root.clearEditorFocus()
                                    root.mapEnabled = next
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: root.mapEnabled
                            enabled: root.mapEnabled
                            spacing: root.sectionSpacing

                            MediaDropTile {
                                id: mapMediaTile
                                theme: root.theme
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                Layout.leftMargin: root.narrowLayout ? 4 : 8
                                Layout.rightMargin: root.narrowLayout ? 4 : 8
                                Layout.topMargin: root.narrowLayout ? 6 : 4
                                compactMode: true
                                mediaType: root.mapType
                                previewValue: root.mapValue
                                fallbackColor: "#2E2E2E"
                                placeholderText: "\u041a\u0430\u0440\u0442\u0430: \u0444\u0430\u0439\u043b, \u0432\u0438\u0434\u0435\u043e \u0438\u043b\u0438 \u0446\u0432\u0435\u0442"
                                helperText: ""
                                onDropValue: function(value) { root.applyMediaValue("map", value, null) }
                                onPasteRequest: root.pasteRequested("map")
                                onBrowseRequest: {
                                    root.clearEditorFocus()
                                    root.browseRequested("map")
                                }
                                onValueEdited: function(value) { root.applyMediaValue("map", value, null) }
                                onColorRequest: {
                                    root.clearEditorFocus()
                                    root.colorRequested("map", root.mapValue)
                                }
                            }

                            NeumoRaisedSurface {
                                id: gridSection
                                theme: root.theme
                                Layout.fillWidth: true
                                Layout.leftMargin: root.narrowLayout ? 4 : 8
                                Layout.rightMargin: root.narrowLayout ? 4 : 8
                                Layout.topMargin: root.narrowLayout ? 2 : 4
                                Layout.preferredHeight: implicitHeight
                                implicitHeight: gridSectionContent.implicitHeight + contentPadding * 2
                                radius: root.narrowLayout ? 15 : 16
                                fillColor: root.theme ? root.theme.baseColor : "#2D2D2D"
                                shadowOffset: root.narrowLayout ? 2.2 : 2.8
                                shadowRadius: root.narrowLayout ? 6.0 : 7.2
                                shadowSamples: 21
                                contentPadding: root.sectionPadding

                                ColumnLayout {
                                    id: gridSectionContent
                                    width: parent.width
                                    spacing: root.narrowLayout ? 7 : 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Label {
                                            Layout.fillWidth: true
                                            text: "\u0421\u0435\u0442\u043a\u0430"
                                            color: root.theme ? root.theme.textPrimary : "#D0D0D0"
                                            font.pixelSize: root.narrowLayout ? 14 : 16
                                            font.weight: Font.DemiBold
                                        }

                                        NeumoToggle {
                                            theme: root.theme
                                            checked: root.gridEnabled
                                            enabled: root.mapEnabled
                                            onToggled: function(next) {
                                                root.clearEditorFocus()
                                                root.gridEnabled = next
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        visible: root.gridEnabled
                                        enabled: root.gridEnabled && root.mapEnabled
                                        spacing: 8

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            visible: !root.narrowLayout
                                            spacing: 8

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Label {
                                                    Layout.fillWidth: true
                                                    text: root.gridSizeLabel
                                                    color: root.theme ? root.theme.textSecondary : "#909090"
                                                    font.pixelSize: 11
                                                    wrapMode: Text.WordWrap
                                                    horizontalAlignment: Text.AlignHCenter
                                                }

                                                Label {
                                                    Layout.fillWidth: true
                                                    text: root.gridLineThicknessLabel
                                                    color: root.theme ? root.theme.textSecondary : "#909090"
                                                    font.pixelSize: 11
                                                    wrapMode: Text.WordWrap
                                                    horizontalAlignment: Text.AlignHCenter
                                                }

                                                Label {
                                                    Layout.fillWidth: true
                                                    text: root.gridOpacityLabel
                                                    color: root.theme ? root.theme.textSecondary : "#909090"
                                                    font.pixelSize: 11
                                                    wrapMode: Text.WordWrap
                                                    horizontalAlignment: Text.AlignHCenter
                                                }
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                NeumoStepperField {
                                                    id: gridCellWideField
                                                    theme: root.theme
                                                    Layout.fillWidth: true
                                                    Layout.minimumWidth: 0
                                                    value: root.gridCellSize
                                                    from: 0.1
                                                    to: 100.0
                                                    stepSize: 0.25
                                                    decimals: 2
                                                    onValueModified: function(value) { root.gridCellSize = value }
                                                }

                                                NeumoStepperField {
                                                    id: gridLineWideField
                                                    theme: root.theme
                                                    Layout.fillWidth: true
                                                    Layout.minimumWidth: 0
                                                    value: root.gridLineThickness
                                                    from: 0.2
                                                    to: 10.0
                                                    stepSize: 0.1
                                                    decimals: 2
                                                    onValueModified: function(value) { root.gridLineThickness = value }
                                                }

                                                NeumoStepperField {
                                                    id: gridOpacityWideField
                                                    theme: root.theme
                                                    Layout.fillWidth: true
                                                    Layout.minimumWidth: 0
                                                    value: root.gridOpacity
                                                    from: 0.0
                                                    to: 1.0
                                                    stepSize: 0.05
                                                    decimals: 2
                                                    onValueModified: function(value) { root.gridOpacity = value }
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            visible: root.narrowLayout
                                            spacing: 8

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Label {
                                                    Layout.preferredWidth: root.compactGridLabelWidth
                                                    text: root.gridSizeLabel
                                                    color: root.theme ? root.theme.textSecondary : "#909090"
                                                    font.pixelSize: 12
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                NeumoStepperField {
                                                    id: gridCellCompactField
                                                    theme: root.theme
                                                    Layout.fillWidth: true
                                                    Layout.minimumWidth: 0
                                                    compactMode: true
                                                    value: root.gridCellSize
                                                    from: 0.1
                                                    to: 100.0
                                                    stepSize: 0.25
                                                    decimals: 2
                                                    onValueModified: function(value) { root.gridCellSize = value }
                                                }
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Label {
                                                    Layout.preferredWidth: root.compactGridLabelWidth
                                                    text: root.gridLineThicknessLabel
                                                    color: root.theme ? root.theme.textSecondary : "#909090"
                                                    font.pixelSize: 12
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                NeumoStepperField {
                                                    id: gridLineCompactField
                                                    theme: root.theme
                                                    Layout.fillWidth: true
                                                    Layout.minimumWidth: 0
                                                    compactMode: true
                                                    value: root.gridLineThickness
                                                    from: 0.2
                                                    to: 10.0
                                                    stepSize: 0.1
                                                    decimals: 2
                                                    onValueModified: function(value) { root.gridLineThickness = value }
                                                }
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Label {
                                                    Layout.preferredWidth: root.compactGridLabelWidth
                                                    text: root.gridOpacityLabel
                                                    color: root.theme ? root.theme.textSecondary : "#909090"
                                                    font.pixelSize: 12
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                NeumoStepperField {
                                                    id: gridOpacityCompactField
                                                    theme: root.theme
                                                    Layout.fillWidth: true
                                                    Layout.minimumWidth: 0
                                                    compactMode: true
                                                    value: root.gridOpacity
                                                    from: 0.0
                                                    to: 1.0
                                                    stepSize: 0.05
                                                    decimals: 2
                                                    onValueModified: function(value) { root.gridOpacity = value }
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Label {
                                                text: "\u0426\u0432\u0435\u0442 \u0441\u0435\u0442\u043a\u0438"
                                                color: root.theme ? root.theme.textSecondary : "#909090"
                                                font.pixelSize: 12
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                NeumoTextField {
                                                    id: gridColorField
                                                    theme: root.theme
                                                    visualStyle: "launcherInline"
                                                    Layout.fillWidth: true
                                                    Layout.minimumWidth: 0
                                                    text: root.gridColor
                                                    placeholderText: "#000000"
                                                    onTextChanged: root.gridColor = text
                                                }

                                                NeumoUtilityIconButton {
                                                    theme: root.theme
                                                    width: 28
                                                    height: 28
                                                    iconSource: Qt.resolvedUrl("../icons/palette.svg")
                                                    toolTip: "\u0412\u044b\u0431\u0440\u0430\u0442\u044c \u0446\u0432\u0435\u0442 \u0441\u0435\u0442\u043a\u0438"
                                                    onClicked: {
                                                        root.clearEditorFocus()
                                                        root.colorRequested("grid", root.gridColor)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                NeumoRaisedSurface {
                    id: backgroundSection
                    theme: root.theme
                    Layout.fillWidth: true
                    Layout.leftMargin: root.sectionOuterGutter
                    Layout.rightMargin: root.sectionOuterGutter
                    Layout.topMargin: root.narrowLayout ? 4 : 6
                    Layout.preferredHeight: implicitHeight
                    implicitHeight: backgroundSectionContent.implicitHeight + contentPadding * 2
                    radius: root.sectionRadius
                    fillColor: root.theme ? root.theme.baseColor : "#2D2D2D"
                    shadowOffset: root.narrowLayout ? 3.5 : 4.4
                    shadowRadius: root.narrowLayout ? 8.0 : 9.4
                    shadowSamples: 23
                    contentPadding: root.sectionPadding

                    ColumnLayout {
                        id: backgroundSectionContent
                        width: parent.width
                        spacing: root.sectionSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Label {
                                Layout.fillWidth: true
                                text: "\u0424\u043e\u043d"
                                color: root.theme ? root.theme.textPrimary : "#D0D0D0"
                                font.pixelSize: root.narrowLayout ? 16 : 18
                                font.weight: Font.DemiBold
                            }

                            NeumoToggle {
                                theme: root.theme
                                checked: root.backgroundEnabled
                                onToggled: function(next) {
                                    root.clearEditorFocus()
                                    root.backgroundEnabled = next
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: root.backgroundEnabled
                            enabled: root.backgroundEnabled
                            spacing: root.sectionSpacing

                            MediaDropTile {
                                id: backgroundMediaTile
                                theme: root.theme
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                Layout.leftMargin: root.narrowLayout ? 4 : 8
                                Layout.rightMargin: root.narrowLayout ? 4 : 8
                                Layout.topMargin: root.narrowLayout ? 6 : 4
                                compactMode: true
                                mediaType: root.backgroundType
                                previewValue: root.backgroundValue
                                fallbackColor: "#1F1F1F"
                                placeholderText: "\u0424\u043e\u043d: \u0444\u0430\u0439\u043b, \u0432\u0438\u0434\u0435\u043e \u0438\u043b\u0438 \u0446\u0432\u0435\u0442"
                                helperText: ""
                                onDropValue: function(value) { root.applyMediaValue("background", value, null) }
                                onPasteRequest: root.pasteRequested("background")
                                onBrowseRequest: {
                                    root.clearEditorFocus()
                                    root.browseRequested("background")
                                }
                                onValueEdited: function(value) { root.applyMediaValue("background", value, null) }
                                onColorRequest: {
                                    root.clearEditorFocus()
                                    root.colorRequested("background", root.backgroundValue)
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.leftMargin: root.sectionOuterGutter
                    Layout.rightMargin: root.sectionOuterGutter
                    Layout.topMargin: 8
                    implicitHeight: 68

                    NeumoRaisedSurface {
                        anchors.fill: parent
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        theme: root.theme
                        radius: 16
                        fillColor: root.theme ? root.theme.baseColor : "#2D2D2D"
                        shadowOffset: root.narrowLayout ? 5.0 : 5.4
                        shadowRadius: root.narrowLayout ? 10.8 : 11.2
                        shadowSamples: 23

                        Label {
                            anchors.centerIn: parent
                            text: root.saveButtonText
                            color: root.theme ? root.theme.textPrimary : "#D0D0D0"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.clearEditorFocus()
                                root.saveRequested(root.currentDraft())
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                }
            }
        }
    }
