import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "components"

Window {
    id: launcherWindow
    width: 450
    height: 370
    minimumWidth: 450
    minimumHeight: 370
    visible: true
    color: "#2D2D2D"
    title: "DnD Maps - Лаунчер"

    onClosing: function(close) {
        close.accepted = true
        appController.request_app_exit()
    }
    property int selectedAdventureIndex: -1
    property int selectedSceneIndex: -1
    property string pendingFileTarget: "map"
    property string pendingColorTarget: "map"
    property string sceneDialogModeCode: "create"
    property bool sceneMapEnabled: true
    property bool sceneBgEnabled: true
    property string sceneMapTypeValue: "color"
    property string sceneBgTypeValue: "color"
    property string sceneMapValueText: "#000000"
    property string sceneBgValueText: "#000000"
    property color bgBase: "#28292C"
    property color bgDeep: "#28292C"
    property color bgCard: "#28292C"
    property color bgCardSoft: "#2C2D30"
    property color lineColor: "#3B3C40"
    property color textPrimary: "#E8E8E8"
    property color textSecondary: "#8A8A8A"
    property color accentColor: "#B6B6B6"
    property color accentStrong: "#9C9C9C"
    property string adventureDialogMode: "create"
    property string adventureOriginalName: ""

    function detectMediaTypeFromValue(rawValue, fallbackType) {
        var value = String(rawValue || "").trim().toLowerCase()
        if (value.length === 0) {
            return fallbackType || "color"
        }
        var clean = value.split("?")[0].split("#")[0]
        if (clean.match(/\.(png|jpg|jpeg|webp|bmp|gif)$/)) {
            return "image"
        }
        if (clean.match(/\.(mp4|webm|mkv|avi|mov|wmv|m4v)$/)) {
            return "video"
        }
        return fallbackType || "color"
    }

    function normalizeColorValue(raw) {
        var value = String(raw || "").trim()
        if (value.length === 0) {
            return "#000000"
        }
        if (value.length === 9 && value[0] === "#") {
            return "#" + value.slice(3)
        }
        return value
    }

    function applyDraftToDialog(draft) {
        if (!draft || !draft.map || !draft.background || !draft.grid) {
            return
        }
        sceneDialogModeCode = draft.mode === "edit" ? "edit" : "create"
        sceneDialogMode.text = sceneDialogModeCode === "edit" ? "Редактирование сцены" : "Создание сцены"
        sceneNameField.text = draft.name || ""
        sceneOriginalName.text = draft.original_name || ""
        sceneNameField.enabled = true

        sceneMapEnabled = draft.map.enabled === undefined ? true : Boolean(draft.map.enabled)
        sceneMapTypeValue = draft.map.type || detectMediaTypeFromValue(draft.map.value || "", "color")
        sceneMapValueText = normalizeColorValue(draft.map.value || "#000000")

        sceneBgEnabled = draft.background.enabled === undefined ? true : Boolean(draft.background.enabled)
        sceneBgTypeValue = draft.background.type || detectMediaTypeFromValue(draft.background.value || "", "color")
        sceneBgValueText = normalizeColorValue(draft.background.value || "#000000")

        sceneGridSize.text = Number(draft.grid.cell_size_ft || 5).toFixed(2)
        sceneGridThickness.text = Number(draft.grid.line_thickness_px || 1.5).toFixed(2)
        sceneGridOpacity.text = Number(draft.grid.opacity || 0.45).toFixed(2)
        sceneGridColor.text = draft.grid.color || "#9D9D9D"
    }

    function openCreateSceneDialog() {
        if (appController.currentAdventure.length === 0) {
            return
        }
        applyDraftToDialog(appController.build_new_scene_draft())
        sceneDialog.open()
    }

    function openEditSceneDialog() {
        if (launcherWindow.selectedSceneIndex < 0) {
            return
        }
        var item = appController.scenesModel[launcherWindow.selectedSceneIndex]
        if (!item) {
            return
        }
        applyDraftToDialog(appController.load_scene_draft(item.name))
        sceneDialog.open()
    }

    function openCreateAdventureDialog() {
        adventureDialogMode = "create"
        adventureOriginalName = ""
        adventureNameField.text = ""
        adventureDialogTitle.text = "Новое приключение"
        adventureDialog.open()
    }

    function openEditAdventureDialog(index) {
        var item = appController.adventuresModel[index]
        if (!item) {
            return
        }
        adventureDialogMode = "edit"
        adventureOriginalName = item.name
        adventureNameField.text = item.name
        adventureDialogTitle.text = "Переименование приключения"
        adventureDialog.open()
    }

    function moveSceneTo(sceneName, targetIndex) {
        var scenes = appController.scenesModel
        if (!scenes || scenes.length === 0) {
            return
        }
        var fromIndex = -1
        for (var i = 0; i < scenes.length; i++) {
            if (scenes[i].name === sceneName) {
                fromIndex = i
                break
            }
        }
        if (fromIndex < 0) {
            return
        }
        var boundedTarget = Math.max(0, Math.min(scenes.length - 1, targetIndex))
        while (fromIndex < boundedTarget) {
            appController.move_scene(sceneName, 1)
            fromIndex += 1
        }
        while (fromIndex > boundedTarget) {
            appController.move_scene(sceneName, -1)
            fromIndex -= 1
        }
        launcherWindow.selectedSceneIndex = boundedTarget
    }

    function assignDroppedPath(drop, textField) {
        if (!drop || !drop.urls || drop.urls.length === 0) {
            return
        }
        textField.text = drop.urls[0].toString()
    }

    function collectDialogDraft() {
        var mapValue = sceneMapEnabled ? sceneMapValueText : "#000000"
        var bgValue = sceneBgEnabled ? sceneBgValueText : "#000000"
        var mapType = sceneMapEnabled ? detectMediaTypeFromValue(mapValue, sceneMapTypeValue || "color") : "color"
        var bgType = sceneBgEnabled ? detectMediaTypeFromValue(bgValue, sceneBgTypeValue || "color") : "color"
        return {
            "mode": sceneDialogModeCode,
            "name": sceneNameField.text,
            "original_name": sceneOriginalName.text,
            "map": {
                "enabled": sceneMapEnabled,
                "type": mapType,
                "value": mapValue,
                "autoplay": true,
                "loop": true,
                "mute": true
            },
            "background": {
                "enabled": sceneBgEnabled,
                "type": bgType,
                "value": bgValue,
                "autoplay": true,
                "loop": true,
                "mute": true
            },
            "grid": {
                "cell_size_ft": Number(sceneGridSize.text),
                "line_thickness_px": Number(sceneGridThickness.text),
                "opacity": Number(sceneGridOpacity.text),
                "color": sceneGridColor.text
            }
        }
    }
    component AppButton: AbstractButton {
        id: control
        property bool accent: false
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        activeFocusOnTab: false
        implicitHeight: 36
        font.pixelSize: 13

        contentItem: Text {
            text: control.text
            color: control.enabled
                ? (control.accent ? "#F7F7F8" : launcherWindow.textPrimary)
                : "#8A8A8A"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: control.font.pixelSize
            font.weight: control.accent ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 12
            border.width: 1
            border.color: control.accent ? "#B4B4B4" : "#505050"
            opacity: control.enabled ? 1.0 : 0.5
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: control.accent
                        ? (control.down ? "#727272" : (control.hovered ? "#858585" : "#7D7D7D"))
                        : (control.down ? "#323232" : (control.hovered ? "#3B3B3B" : "#363636"))
                }
                GradientStop {
                    position: 1
                    color: control.accent
                        ? (control.down ? "#666666" : (control.hovered ? "#747474" : "#6E6E6E"))
                        : (control.down ? "#292929" : (control.hovered ? "#323232" : "#2D2D2D"))
                }
            }
            scale: control.down ? 0.97 : (control.hovered ? 1.025 : 1.0)

            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }
        }
    }

    component AppTextField: TextField {
        id: control
        color: launcherWindow.textPrimary
        selectedTextColor: "#F4F4F6"
        selectionColor: "#6C6C6C"
        placeholderTextColor: "#909090"
        padding: 10

        background: Rectangle {
            radius: 11
            color: "#232323"
            border.width: 1
            border.color: control.activeFocus ? "#ABABAB" : (control.hovered ? "#626262" : "#4D4D4D")
            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }
        }
    }
    component IconButton: Item {
        id: iconRoot
        property string iconSource: ""
        property string glyph: ""
        property string toolTip: ""
        property int fontSize: 14
        property real buttonSize: Math.max(width, height)
        property bool largeButton: buttonSize >= 40
        property bool mediumButton: buttonSize >= 30 && buttonSize < 40
        property real outerOffset: largeButton ? 6 : (mediumButton ? 4 : 2)
        property real outerRadius: largeButton ? 12 : (mediumButton ? 8.5 : 4.5)
        property int outerSamples: largeButton ? 25 : (mediumButton ? 21 : 15)
        property real innerOffset: largeButton ? 3 : (mediumButton ? 2 : 1.2)
        property real innerRadius: largeButton ? 7 : (mediumButton ? 5 : 3.2)
        property int innerSamples: largeButton ? 21 : (mediumButton ? 17 : 11)
        property color outerDarkColor: largeButton ? "#B8151618" : (mediumButton ? "#99151618" : "#70151618")
        property color outerLightColor: largeButton ? "#8A3B3C40" : (mediumButton ? "#703B3C40" : "#523B3C40")
        property color innerDarkColor: largeButton ? "#C0151618" : (mediumButton ? "#A6151618" : "#7A151618")
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
            color: hitArea.pressed ? "#252629" : (hitArea.containsMouse ? "#2C2D30" : "#28292C")

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: hitArea.pressed ? 0 : iconRoot.outerOffset
                verticalOffset: hitArea.pressed ? 0 : iconRoot.outerOffset
                radius: iconRoot.outerRadius
                samples: iconRoot.outerSamples
                color: iconRoot.outerDarkColor
            }
        }

        DropShadow {
            anchors.fill: bg
            source: bg
            horizontalOffset: hitArea.pressed ? 0 : -iconRoot.outerOffset
            verticalOffset: hitArea.pressed ? 0 : -iconRoot.outerOffset
            radius: iconRoot.outerRadius
            samples: iconRoot.outerSamples
            color: iconRoot.outerLightColor
            visible: !hitArea.pressed
            z: -1
        }

        InnerShadow {
            anchors.fill: bg
            source: bg
            horizontalOffset: iconRoot.innerOffset
            verticalOffset: iconRoot.innerOffset
            radius: iconRoot.innerRadius
            samples: iconRoot.innerSamples
            color: iconRoot.innerDarkColor
            visible: hitArea.pressed
        }

        Image {
            anchors.centerIn: parent
            width: Math.min(18, parent.width - 10)
            height: width
            visible: iconRoot.iconSource.length > 0
            source: iconRoot.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: iconRoot.enabled ? 0.9 : 0.45
        }

        Text {
            anchors.centerIn: parent
            visible: iconRoot.iconSource.length === 0 && iconRoot.glyph.length > 0
            text: iconRoot.glyph
            color: "#8A8A8A"
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
    component NeumoPanel: Item {
        id: panel
        property string title: ""
        property real titleSize: 18
        property bool addEnabled: true
        signal addClicked()
        default property alias contentData: contentContainer.data
        clip: false

        Rectangle {
            id: panelBase
            anchors.fill: parent
            radius: 20
            color: "#28292C"
        }

        InnerShadow {
            id: insetDark
            anchors.fill: panelBase
            source: panelBase
            horizontalOffset: 6
            verticalOffset: 6
            radius: 12
            samples: 31
            color: "#CC151618"
        }

        InnerShadow {
            anchors.fill: panelBase
            source: insetDark
            horizontalOffset: -6
            verticalOffset: -6
            radius: 10
            samples: 25
            color: "#663B3C40"
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: panel.title
                    color: "#E8E8E8"
                    font.pixelSize: panel.titleSize
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                IconButton {
                    width: 30
                    height: 30
                    glyph: "+"
                    fontSize: 20
                    enabled: panel.addEnabled
                    opacity: enabled ? 1.0 : 0.45
                    onClicked: panel.addClicked()
                }
            }

            Item {
                id: contentContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
    component NeumoRowCard: Item {
        id: rowCard
        property string title: ""
        property bool active: false
        property bool hovered: false
        default property alias contentData: contentWrap.data

        Rectangle {
            id: rowBase
            anchors.fill: parent
            radius: 12
            color: rowCard.hovered ? "#2C2D30" : "#28292C"
            border.color: rowCard.active ? "#40FFFFFF" : "transparent"
            border.width: rowCard.active ? 1 : 0

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 3.5
                verticalOffset: 3.5
                radius: 7
                samples: 19
                color: "#B0151618"
            }
        }

        DropShadow {
            anchors.fill: rowBase
            anchors.margins: -10
            source: rowBase
            transparentBorder: true
            horizontalOffset: -3.5
            verticalOffset: -3.5
            radius: 7
            samples: 19
            color: "#663B3C40"
            z: -1
        }

        Item {
            id: contentWrap
            anchors.fill: parent
        }
    }
    Rectangle {
        anchors.fill: parent
        color: launcherWindow.bgBase

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 24

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: "Лаунчер DnD Maps"
                        color: "#E8E8E8"
                        font.pixelSize: Math.max(28, Math.min(40, launcherWindow.width * 0.06))
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Label {
                        text: "Приключения, сцены и настройки по умолчанию"
                        color: "#8A8A8A"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    spacing: 14
                    IconButton {
                        width: 44
                        height: 44
                        iconSource: "icons/dice.svg"
                        toolTip: "Дайсы"
                        onClicked: appController.request_open_dice()
                    }
                    IconButton {
                        width: 44
                        height: 44
                        iconSource: "icons/settings.svg"
                        toolTip: "Настройки"
                        onClicked: settingsDrawer.open()
                    }
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 22

                NeumoPanel {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    title: "Приключения"
                    onAddClicked: launcherWindow.openCreateAdventureDialog()

                    ListView {
                        id: adventuresView
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        property real shadowBleedX: 12
                        property real shadowBleedY: 8
                        property real rowHeight: 48
                        topMargin: shadowBleedY
                        bottomMargin: shadowBleedY
                        model: appController.adventuresModel
                        currentIndex: launcherWindow.selectedAdventureIndex
                        ScrollBar.vertical: AppScrollBar {}
                        ScrollBar.horizontal: AppScrollBar {}

                        delegate: Item {
                            id: adventureDelegate
                            x: adventuresView.shadowBleedX
                            width: Math.max(0, adventuresView.width - adventuresView.shadowBleedX * 2)
                            height: adventuresView.rowHeight + adventuresView.shadowBleedY * 2
                            property bool hovered: hoverHandler.hovered

                            NeumoRowCard {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                y: adventuresView.shadowBleedY
                                height: adventuresView.rowHeight
                                active: ListView.isCurrentItem
                                hovered: adventureDelegate.hovered

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: ListView.isCurrentItem ? "#FFFFFF" : "#B8B8B8"
                                        font.pixelSize: 14
                                        font.weight: ListView.isCurrentItem ? Font.DemiBold : Font.Medium
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 5
                                        visible: true

                                        IconButton {
                                            width: 24
                                            height: 24
                                            iconSource: "icons/scene_edit.svg"
                                            toolTip: "Переименовать"
                                            onClicked: launcherWindow.openEditAdventureDialog(index)
                                        }
                                        IconButton {
                                            width: 24
                                            height: 24
                                            iconSource: "icons/clear.svg"
                                            toolTip: "Удалить"
                                            onClicked: {
                                                appController.delete_adventure(modelData.name)
                                                launcherWindow.selectedAdventureIndex = -1
                                                launcherWindow.selectedSceneIndex = -1
                                            }
                                        }
                                    }
                                }
                            }

                            HoverHandler { id: hoverHandler }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: {
                                    launcherWindow.selectedAdventureIndex = index
                                    launcherWindow.selectedSceneIndex = -1
                                    appController.select_adventure(modelData.name)
                                }
                            }
                        }
                    }
                }

                NeumoPanel {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    title: appController.currentAdventure ? ("Сцены: " + appController.currentAdventure) : "Сцены"
                    addEnabled: appController.currentAdventure.length > 0
                    onAddClicked: launcherWindow.openCreateSceneDialog()

                    ListView {
                        id: scenesView
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        property real shadowBleedX: 12
                        property real shadowBleedY: 8
                        property real rowHeight: 48
                        topMargin: shadowBleedY
                        bottomMargin: shadowBleedY
                        model: appController.scenesModel
                        currentIndex: launcherWindow.selectedSceneIndex
                        ScrollBar.vertical: AppScrollBar {}
                        ScrollBar.horizontal: AppScrollBar {}

                        delegate: Item {
                            id: sceneDelegate
                            x: scenesView.shadowBleedX
                            width: Math.max(0, scenesView.width - scenesView.shadowBleedX * 2)
                            height: scenesView.rowHeight + scenesView.shadowBleedY * 2
                            property bool hovered: hoverHandler.hovered
                            property real dragY: 0
                            property real dragDeltaY: 0

                            Translate {
                                id: dragTranslate
                                y: sceneDelegate.dragY
                            }
                            transform: [dragTranslate]
                            z: dragHandler.active ? 20 : 1

                            NeumoRowCard {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                y: scenesView.shadowBleedY
                                height: scenesView.rowHeight
                                active: ListView.isCurrentItem
                                hovered: sceneDelegate.hovered

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: ListView.isCurrentItem ? "#FFFFFF" : "#B8B8B8"
                                        font.pixelSize: 14
                                        font.weight: ListView.isCurrentItem ? Font.DemiBold : Font.Medium
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 5
                                        visible: true

                                        IconButton {
                                            width: 24
                                            height: 24
                                            iconSource: "icons/scene_edit.svg"
                                            toolTip: "Изменить сцену"
                                            onClicked: {
                                                launcherWindow.selectedSceneIndex = index
                                                launcherWindow.openEditSceneDialog()
                                            }
                                        }
                                        IconButton {
                                            width: 24
                                            height: 24
                                            iconSource: "icons/clear.svg"
                                            toolTip: "Удалить сцену"
                                            onClicked: {
                                                appController.delete_scene(modelData.name)
                                                launcherWindow.selectedSceneIndex = -1
                                            }
                                        }
                                    }
                                }
                            }

                            HoverHandler { id: hoverHandler }

                            DragHandler {
                                id: dragHandler
                                target: null
                                onActiveChanged: {
                                    if (active) {
                                        launcherWindow.selectedSceneIndex = index
                                        sceneDelegate.dragDeltaY = 0
                                        return
                                    }
                                    var rowExtent = sceneDelegate.height + scenesView.spacing
                                    var centerY = sceneDelegate.y + sceneDelegate.dragDeltaY + (sceneDelegate.height / 2)
                                    var rawIndex = Math.floor(centerY / Math.max(1, rowExtent))
                                    var toIndex = Math.max(0, Math.min(appController.scenesModel.length - 1, rawIndex))
                                    if (toIndex !== index) {
                                        launcherWindow.moveSceneTo(modelData.name, toIndex)
                                    }
                                    sceneDelegate.dragY = 0
                                    sceneDelegate.dragDeltaY = 0
                                }
                                onTranslationChanged: {
                                    sceneDelegate.dragY = translation.y
                                    sceneDelegate.dragDeltaY = translation.y
                                }
                            }

                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: launcherWindow.selectedSceneIndex = index
                                onDoubleTapped: {
                                    launcherWindow.selectedSceneIndex = index
                                    var item = appController.scenesModel[index]
                                    if (item) {
                                        appController.open_scene(item.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: appController.refresh_library()

    Connections {
        target: appController
        function onLibraryChanged() {
            var adventuresCount = appController.adventuresModel.length
            var targetAdventure = appController.currentAdventure
            var targetIndex = -1
            for (var i = 0; i < adventuresCount; i++) {
                if (appController.adventuresModel[i].name === targetAdventure) {
                    targetIndex = i
                    break
                }
            }
            launcherWindow.selectedAdventureIndex = targetIndex
            var scenesCount = appController.scenesModel.length
            if (launcherWindow.selectedSceneIndex >= scenesCount) {
                launcherWindow.selectedSceneIndex = scenesCount > 0 ? scenesCount - 1 : -1
            }
        }
    }

    Dialog {
        id: sceneDialog
        modal: true
        x: Math.round((launcherWindow.width - width) / 2)
        y: 16
        width: Math.min(launcherWindow.width - 32, 960)
        height: Math.min(launcherWindow.height - 32, 960)
        standardButtons: Dialog.NoButton
        closePolicy: Popup.CloseOnEscape
        opacity: 1.0

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 170; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 130; easing.type: Easing.InCubic }
        }

        background: Rectangle {
            color: "#262626"
            border.color: "#626262"
            border.width: 1
            radius: 12
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#2E2E2E" }
                GradientStop { position: 1.0; color: "#252525" }
            }
        }

        contentItem: ScrollView {
            id: sceneDialogScroll
            clip: true
            padding: 12
            ScrollBar.vertical: AppScrollBar {}
            ScrollBar.horizontal: AppScrollBar {}
            ColumnLayout {
                id: sceneDialogContent
                width: sceneDialogScroll.availableWidth
                spacing: 10

                Label {
                    id: sceneDialogMode
                    text: "Создание сцены"
                    color: launcherWindow.textPrimary
                    font.pixelSize: 22
                    Layout.fillWidth: true
                }

                AppTextField {
                    id: sceneNameField
                    placeholderText: "Название сцены"
                    Layout.fillWidth: true
                }
                AppTextField {
                    id: sceneOriginalName
                    visible: false
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#4C4C4C" }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Label { text: "Карта"; color: launcherWindow.textPrimary; Layout.fillWidth: true }
                    AppToggle {
                        id: sceneMapEnabledSwitch
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumWidth: implicitWidth
                        Layout.maximumHeight: implicitHeight
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        checked: sceneMapEnabled
                        onToggled: function(next) { sceneMapEnabled = next }
                    }
                }
                RowLayout {
                    visible: sceneMapEnabled
                    Layout.fillWidth: true
                    spacing: 8
                    MediaDropTile {
                        id: sceneMapDrop
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredHeight: 92
                        mediaType: sceneMapTypeValue
                        previewValue: sceneMapValueText
                        fallbackColor: "#000000"
                        placeholderText: "Клик / Ctrl+V / Перетащить / Двойной клик"
                        onDropValue: function(value) {
                            sceneMapValueText = value
                            sceneMapTypeValue = detectMediaTypeFromValue(value, "color")
                        }
                        onPasteRequest: {
                            var pastedMap = appController.paste_media_value("map")
                            if (pastedMap && pastedMap.length > 0) {
                                sceneMapValueText = pastedMap
                                sceneMapTypeValue = detectMediaTypeFromValue(pastedMap, "color")
                            }
                        }
                        onBrowseRequest: {
                            launcherWindow.pendingFileTarget = "map"
                            mediaFileDialog.open()
                        }
                    }
                    IconButton {
                        width: 30
                        height: 30
                        enabled: sceneMapEnabled
                        opacity: enabled ? 1.0 : 0.4
                        iconSource: "icons/palette.svg"
                        toolTip: "Выбрать цвет карты"
                        onClicked: {
                            launcherWindow.pendingColorTarget = "map"
                            colorPickerDialog.selectedColor = sceneMapValueText
                            colorPickerDialog.open()
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#4C4C4C" }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Label { text: "Фон"; color: launcherWindow.textPrimary; Layout.fillWidth: true }
                    AppToggle {
                        id: sceneBgEnabledSwitch
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumWidth: implicitWidth
                        Layout.maximumHeight: implicitHeight
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        checked: sceneBgEnabled
                        onToggled: function(next) { sceneBgEnabled = next }
                    }
                }
                RowLayout {
                    visible: sceneBgEnabled
                    Layout.fillWidth: true
                    spacing: 8
                    MediaDropTile {
                        id: sceneBgDrop
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredHeight: 92
                        mediaType: sceneBgTypeValue
                        previewValue: sceneBgValueText
                        fallbackColor: "#000000"
                        placeholderText: "Клик / Ctrl+V / Перетащить / Двойной клик"
                        onDropValue: function(value) {
                            sceneBgValueText = value
                            sceneBgTypeValue = detectMediaTypeFromValue(value, "color")
                        }
                        onPasteRequest: {
                            var pastedBg = appController.paste_media_value("background")
                            if (pastedBg && pastedBg.length > 0) {
                                sceneBgValueText = pastedBg
                                sceneBgTypeValue = detectMediaTypeFromValue(pastedBg, "color")
                            }
                        }
                        onBrowseRequest: {
                            launcherWindow.pendingFileTarget = "background"
                            mediaFileDialog.open()
                        }
                    }
                    IconButton {
                        width: 30
                        height: 30
                        enabled: sceneBgEnabled
                        opacity: enabled ? 1.0 : 0.4
                        iconSource: "icons/palette.svg"
                        toolTip: "Выбрать цвет фона"
                        onClicked: {
                            launcherWindow.pendingColorTarget = "background"
                            colorPickerDialog.selectedColor = sceneBgValueText
                            colorPickerDialog.open()
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#4C4C4C" }

                Label { text: "Гекс-сетка"; color: launcherWindow.textPrimary }
                Label { text: "Размер клетки (ft)"; color: launcherWindow.textSecondary }
                AppTextField { id: sceneGridSize; Layout.fillWidth: true; text: "5.00" }
                Label { text: "Толщина линии (px)"; color: launcherWindow.textSecondary }
                AppTextField { id: sceneGridThickness; Layout.fillWidth: true; text: "1.50" }
                Label { text: "Прозрачность (0..1)"; color: launcherWindow.textSecondary }
                AppTextField { id: sceneGridOpacity; Layout.fillWidth: true; text: "0.45" }
                Label { text: "Цвет сетки"; color: launcherWindow.textSecondary }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    AppTextField { id: sceneGridColor; Layout.fillWidth: true; text: "#9D9D9D" }
                    IconButton {
                        width: 30
                        height: 30
                        iconSource: "icons/palette.svg"
                        toolTip: "Выбрать цвет сетки"
                        onClicked: {
                            launcherWindow.pendingColorTarget = "grid"
                            colorPickerDialog.selectedColor = sceneGridColor.text
                            colorPickerDialog.open()
                        }
                    }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 6 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    AppButton {
                        text: "Отмена"
                        Layout.fillWidth: true
                        onClicked: sceneDialog.close()
                    }
                    AppButton {
                        text: "Сохранить"
                        accent: true
                        Layout.fillWidth: true
                        onClicked: {
                            var ok = appController.save_scene_draft(launcherWindow.collectDialogDraft())
                            if (ok) {
                                sceneDialog.close()
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 4 }
            }
        }
    }

    Dialog {
        id: adventureDialog
        modal: true
        x: (launcherWindow.width - width) / 2
        y: 120
        width: Math.min(launcherWindow.width - 48, 440)
        standardButtons: Dialog.NoButton
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color: "#262626"
            border.color: "#626262"
            border.width: 1
            radius: 12
        }

        contentItem: ColumnLayout {
            spacing: 10

            Label {
                id: adventureDialogTitle
                text: "Новое приключение"
                color: launcherWindow.textPrimary
                font.pixelSize: 20
                Layout.fillWidth: true
            }

            AppTextField {
                id: adventureNameField
                Layout.fillWidth: true
                placeholderText: "Название приключения"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                AppButton {
                    text: "Отмена"
                    Layout.fillWidth: true
                    onClicked: adventureDialog.close()
                }
                AppButton {
                    text: "Сохранить"
                    accent: true
                    Layout.fillWidth: true
                    onClicked: {
                        if (adventureDialogMode === "edit") {
                            appController.rename_adventure(adventureOriginalName, adventureNameField.text)
                        } else {
                            appController.create_adventure(adventureNameField.text)
                        }
                        adventureDialog.close()
                    }
                }
            }
        }
    }

    FileDialog {
        id: mediaFileDialog
        title: "Выберите медиафайл"
        fileMode: FileDialog.OpenFile
        nameFilters: [
            "Медиафайлы (*.png *.jpg *.jpeg *.webp *.bmp *.gif *.mp4 *.webm *.mkv *.avi *.mov *.wmv *.m4v)",
            "Все файлы (*.*)"
        ]
        onAccepted: {
            var selected = selectedFile.toString()
            if (launcherWindow.pendingFileTarget === "background") {
                sceneBgValueText = selected
                sceneBgTypeValue = detectMediaTypeFromValue(selected, "color")
            } else {
                sceneMapValueText = selected
                sceneMapTypeValue = detectMediaTypeFromValue(selected, "color")
            }
        }
    }

    component AppToggle: Item {
        id: toggleRoot
        property bool checked: false
        signal toggled(bool checked)
        implicitWidth: 38
        implicitHeight: 20
        width: implicitWidth
        height: implicitHeight

        Rectangle {
            id: track
            anchors.fill: parent
            radius: height / 2
            color: toggleRoot.checked ? "#646464" : "#353535"
            border.width: 1
            border.color: toggleRoot.checked ? "#A8A8A8" : "#5C5C5C"
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }

        Rectangle {
            id: knob
            width: 14
            height: 14
            radius: 7
            y: (toggleRoot.height - height) / 2
            x: toggleRoot.checked ? (toggleRoot.width - width - 3) : 3
            color: "#EAEAEA"
            border.width: 1
            border.color: "#B2B2B2"
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                toggleRoot.checked = !toggleRoot.checked
                toggleRoot.toggled(toggleRoot.checked)
            }
        }
    }

    ColorDialog {
        id: colorPickerDialog
        title: "Выбор цвета"
        onAccepted: {
            var value = normalizeColorValue(selectedColor)
            if (launcherWindow.pendingColorTarget === "background") {
                sceneBgValueText = value
                sceneBgTypeValue = "color"
            } else if (launcherWindow.pendingColorTarget === "grid") {
                sceneGridColor.text = value
            } else {
                sceneMapValueText = value
                sceneMapTypeValue = "color"
            }
        }
    }

    component AppScrollBar: ScrollBar {
        id: control
        policy: ScrollBar.AlwaysOff
        active: false
        visible: false
        hoverEnabled: false
        implicitWidth: 0
        implicitHeight: 0

        contentItem: Rectangle {
            implicitWidth: 0
            implicitHeight: 0
            opacity: 0.0
            color: "transparent"
        }

        background: Rectangle {
            implicitWidth: 0
            implicitHeight: 0
            opacity: 0.0
            color: "transparent"
            border.width: 0
        }
    }

    component AppComboBox: ComboBox {
        id: control
        implicitHeight: 36
        font.pixelSize: 13
        leftPadding: 10
        rightPadding: 28

        contentItem: Text {
            text: control.displayText
            color: launcherWindow.textPrimary
            verticalAlignment: Text.AlignVCenter
            leftPadding: 2
            elide: Text.ElideRight
            font.pixelSize: control.font.pixelSize
        }

        indicator: Canvas {
            x: control.width - width - 10
            y: (control.height - height) / 2
            width: 10
            height: 6
            contextType: "2d"
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.moveTo(0, 0)
                ctx.lineTo(width, 0)
                ctx.lineTo(width / 2, height)
                ctx.closePath()
                ctx.fillStyle = "#C6C6C6"
                ctx.fill()
            }
        }

        background: Rectangle {
            radius: 10
            color: "#232323"
            border.width: 1
            border.color: control.activeFocus ? "#A7A7A7" : (control.hovered ? "#707070" : "#4D4D4D")
            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }
        }

        delegate: ItemDelegate {
            width: control.width - 8
            height: 32
            hoverEnabled: true
            contentItem: Text {
                text: control.textAt(index)
                color: highlighted ? "#F4F5F7" : "#D1D1D1"
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font.pixelSize: 13
            }
            highlighted: control.highlightedIndex === index
            background: Rectangle {
                radius: 8
                color: parent.highlighted ? "#545454" : (parent.hovered ? "#3A3A3A" : "transparent")
            }
        }

        popup: Popup {
            y: control.height + 6
            width: control.width
            padding: 4
            implicitHeight: Math.min(contentItem.implicitHeight + 8, 220)
            background: Rectangle {
                radius: 10
                color: "#252525"
                border.width: 1
                border.color: "#595959"
            }
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: control.popup.visible ? control.delegateModel : null
                currentIndex: control.highlightedIndex
                ScrollBar.vertical: AppScrollBar {}
                ScrollBar.horizontal: AppScrollBar {}
            }
        }
    }

    component AppCheckBox: CheckBox {
        id: control
        hoverEnabled: true
        spacing: 8

        indicator: Rectangle {
            implicitWidth: 18
            implicitHeight: 18
            x: control.leftPadding
            y: (control.height - height) / 2
            radius: 5
            color: control.checked ? "#6D6D6D" : "#252931"
            border.width: 1
            border.color: control.checked ? "#C1C1C1" : (control.hovered ? "#7A7A7A" : "#545454")
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 3
                visible: control.checked
                color: "#F3F4F7"
            }
        }

        contentItem: Text {
            text: control.text
            color: launcherWindow.textSecondary
            leftPadding: control.indicator.width + control.spacing + 4
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 12
        }
    }

    Drawer {
        id: settingsDrawer
        width: Math.min(460, Math.max(360, launcherWindow.width * 0.45))
        height: launcherWindow.height
        edge: Qt.RightEdge
        modal: false
        interactive: true
        opacity: 1.0

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 130; easing.type: Easing.InCubic }
        }

        background: Rectangle {
            color: "#1F1F1F"
            border.color: "#606060"
            border.width: 1
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#252525" }
                GradientStop { position: 1.0; color: "#1C1C1C" }
            }
        }

        ScrollView {
            id: settingsScroll
            anchors.fill: parent
            clip: true
            padding: 12
            ScrollBar.vertical: AppScrollBar {}
            ScrollBar.horizontal: AppScrollBar {}

            ColumnLayout {
                width: settingsScroll.availableWidth
                spacing: 10

                Label {
                    text: "Настройки приложения"
                    color: launcherWindow.textPrimary
                    font.pixelSize: 22
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#4C4C4C"
                }

                Label { text: "Корневая папка приключений"; color: launcherWindow.textPrimary }
                AppTextField {
                    id: adventuresRootField
                    text: appController.adventuresRoot
                    placeholderText: "Путь к папке приключений"
                    Layout.fillWidth: true
                }
                AppButton {
                    text: "Применить путь"
                    accent: true
                    onClicked: appController.update_adventures_root(adventuresRootField.text)
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#4C4C4C"
                }

                Label {
                    text: "Раздел в переработке"
                    color: launcherWindow.textPrimary
                    font.pixelSize: 16
                    Layout.fillWidth: true
                }
                Label {
                    text: "Параметры сцены по умолчанию временно скрыты."
                    color: launcherWindow.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#4C4C4C"
                }

                Label { text: "Левая панель"; color: launcherWindow.textPrimary }
                Label { text: "Ширина панели (px)"; color: launcherWindow.textSecondary }
                AppTextField {
                    id: panelWidthField
                    text: String(appController.leftPanelWidth)
                    Layout.fillWidth: true
                }
                Label { text: "Зона появления (px)"; color: launcherWindow.textSecondary }
                AppTextField {
                    id: revealZoneField
                    text: String(appController.leftRevealZone)
                    Layout.fillWidth: true
                }
                AppButton {
                    text: "Применить панель"
                    onClicked: appController.update_panel(Number(panelWidthField.text), Number(revealZoneField.text))
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                }

                RowLayout {
                    Layout.fillWidth: true
                    AppButton {
                        text: "Сохранить настройки"
                        accent: true
                        Layout.fillWidth: true
                        onClicked: appController.persist_settings()
                    }
                    AppButton {
                        text: "Закрыть"
                        Layout.fillWidth: true
                        onClicked: settingsDrawer.close()
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 12
                }
            }
        }
    }
}
