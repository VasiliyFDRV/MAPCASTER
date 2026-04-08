import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "components"
import "components/neumo"

Window {
    id: launcherWindow
    width: 420
    height: 400
    visible: true
    color: "#2D2D2D"
    title: "DnD Maps - Лаунчер"

    onClosing: function(close) {
        close.accepted = true
        appController.request_app_exit()
    }
    property bool scenesMode: appController.launcherAdventure.length > 0
    property string pendingFileTarget: "map"
    property string pendingColorTarget: "map"
    property bool sceneEditorVisible: false
    property int sceneEditorOpenToken: 0
    property var sceneEditorInitialDraft: ({})
    property color bgBase: "#2D2D2D"
    property color bgDeep: "#2D2D2D"
    property color bgCard: "#2D2D2D"
    property color bgCardSoft: "#2D2D2D"
    property var neumoTheme: NeumoTheme { baseColor: bgBase; textPrimary: textPrimary; textSecondary: textSecondary }
    property color lineColor: "#3B3C40"
    property color textPrimary: "#D0D0D0"
    property color textSecondary: "#909090"
    property color accentColor: "#B6B6B6"
    property color accentStrong: "#9C9C9C"
    property string adventureDialogMode: "create"
    property real explorerEdgeInset: 12
    property string adventureOriginalName: ""
    property string adventureInlineMode: "none"
    property string adventureInlineOriginalName: ""
    property string adventureInlineDraftName: ""
    property bool adventureInlinePendingFocus: false
    property var adventureInlineModel: []
    property bool adventureInlineActive: !scenesMode && adventureInlineMode !== "none"
    property string sceneInlineMode: "none"
    property string sceneInlineOriginalName: ""
    property string sceneInlineDraftName: ""
    property bool sceneInlinePendingFocus: false
    property var sceneInlineModel: []
    property var sceneInlineDraftPayload: ({})
    property bool sceneInlineActive: scenesMode && sceneInlineMode !== "none"
    property bool inlineEditActive: adventureInlineActive || sceneInlineActive || sceneEditorVisible
    property string listDragMode: "none"
    property string listDragName: ""
    property int listDragFromIndex: -1
    property int listDragToIndex: -1
    property real listDragScrollCompensation: 0
    property real listDragItemHeight: 0
    property real listDragPointerDelta: 0
    property real listDragSpacing: 0
    property int listDragItemCount: 0
    property real listDragVisibleCenterY: 0
    property real listDragAutoScrollThreshold: 52
    property real listDragAutoScrollBaseStep: 5.5
    property real listDragVisualStartX: 0
    property real listDragVisualStartY: 0
    property real listDragVisualX: 0
    property real listDragVisualY: 0
    property real listDragVisualWidth: 0
    property real listDragVisualHeight: 0


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

    function openSceneEditor(draft) {
        if (!draft || !draft.map || !draft.background || !draft.grid) {
            return
        }
        sceneEditorInitialDraft = JSON.parse(JSON.stringify(draft))
        sceneEditorOpenToken += 1
        sceneEditorVisible = true
    }

    function closeSceneEditor() {
        sceneEditorVisible = false
        sceneEditorInitialDraft = ({})
    }

    function requestCloseSceneEditor(forceClose) {
        if (!sceneEditorVisible) {
            return
        }
        if (forceClose || !sceneEditorSurface.dirty) {
            closeSceneEditor()
            return
        }
        sceneEditorDiscardDialog.open()
    }

    function openCreateSceneDialog() {
        if (appController.launcherAdventure.length === 0) {
            return
        }
        openSceneEditor(appController.build_new_scene_draft())
    }

    function openEditSceneDialog(sceneName) {
        if (!sceneName || appController.launcherAdventure.length === 0) {
            return
        }
        openSceneEditor(appController.load_scene_draft_for_adventure(appController.launcherAdventure, sceneName))
    }
    function refreshSceneInlineModel() {
        var items = []
        var source = appController.scenesModel || []
        for (var i = 0; i < source.length; i++) {
            var scene = source[i]
            var name = scene && scene.name ? scene.name : ""
            if (sceneInlineMode === "rename" && name === sceneInlineOriginalName) {
                items.push({
                    "name": name,
                    "isInlineEditor": true,
                    "inlineMode": "rename"
                })
            } else {
                items.push({
                    "name": name,
                    "isInlineEditor": false,
                    "inlineMode": "none"
                })
            }
        }
        sceneInlineModel = items
    }

    function beginRenameSceneInline(sceneName) {
        if (!sceneName || appController.launcherAdventure.length === 0) {
            return
        }
        var draft = appController.load_scene_draft_for_adventure(appController.launcherAdventure, sceneName)
        if (!draft || !draft.name) {
            return
        }
        sceneInlineMode = "rename"
        sceneInlineOriginalName = sceneName
        sceneInlineDraftName = sceneName
        sceneInlineDraftPayload = JSON.parse(JSON.stringify(draft))
        sceneInlinePendingFocus = true
        refreshSceneInlineModel()
    }

    function cancelSceneInlineEdit() {
        if (sceneInlineMode === "none") {
            return
        }
        sceneInlineMode = "none"
        sceneInlineOriginalName = ""
        sceneInlineDraftName = ""
        sceneInlineDraftPayload = ({})
        sceneInlinePendingFocus = false
        refreshSceneInlineModel()
    }

    function commitSceneInlineEdit() {
        if (sceneInlineMode === "none") {
            return
        }
        var trimmedName = String(sceneInlineDraftName || "").trim()
        if (trimmedName === sceneInlineOriginalName) {
            cancelSceneInlineEdit()
            return
        }
        var draft = JSON.parse(JSON.stringify(sceneInlineDraftPayload || {}))
        draft.name = trimmedName
        draft.original_name = sceneInlineOriginalName
        draft.mode = "edit"
        appController.save_scene_draft_for_adventure(appController.launcherAdventure, draft)
        var renamed = false
        var oldStillExists = false
        var renamedScenes = appController.scenesModel || []
        for (var i = 0; i < renamedScenes.length; i++) {
            if (!renamedScenes[i]) {
                continue
            }
            if (renamedScenes[i].name === trimmedName) {
                renamed = true
            }
            if (renamedScenes[i].name === sceneInlineOriginalName) {
                oldStillExists = true
            }
        }
        if (renamed && !oldStillExists) {
            sceneInlineMode = "none"
            sceneInlineOriginalName = ""
            sceneInlineDraftName = ""
            sceneInlineDraftPayload = ({})
            sceneInlinePendingFocus = false
        } else {
            sceneInlineDraftName = trimmedName
            sceneInlinePendingFocus = true
        }
        refreshSceneInlineModel()
    }

    function refreshAdventureInlineModel() {
        var items = []
        var source = appController.adventuresModel || []
        for (var i = 0; i < source.length; i++) {
            var adventure = source[i]
            var name = adventure && adventure.name ? adventure.name : ""
            if (adventureInlineMode === "rename" && name === adventureInlineOriginalName) {
                items.push({
                    "name": name,
                    "isInlineEditor": true,
                    "inlineMode": "rename"
                })
            } else {
                items.push({
                    "name": name,
                    "isInlineEditor": false,
                    "inlineMode": "none"
                })
            }
        }
        if (adventureInlineMode === "create") {
            items.unshift({
                "name": "",
                "isInlineEditor": true,
                "inlineMode": "create"
            })
        }
        adventureInlineModel = items
    }

    function beginCreateAdventureInline() {
        adventureInlineMode = "create"
        adventureInlineOriginalName = ""
        adventureInlineDraftName = ""
        adventureInlinePendingFocus = true
        refreshAdventureInlineModel()
    }

    function beginRenameAdventureInline(adventureName) {
        if (!adventureName) {
            return
        }
        adventureInlineMode = "rename"
        adventureInlineOriginalName = adventureName
        adventureInlineDraftName = adventureName
        adventureInlinePendingFocus = true
        refreshAdventureInlineModel()
    }

    function cancelAdventureInlineEdit() {
        if (adventureInlineMode === "none") {
            return
        }
        adventureInlineMode = "none"
        adventureInlineOriginalName = ""
        adventureInlineDraftName = ""
        adventureInlinePendingFocus = false
        refreshAdventureInlineModel()
    }

    function commitAdventureInlineEdit() {
        if (adventureInlineMode === "none") {
            return
        }
        var trimmedName = String(adventureInlineDraftName || "").trim()
        if (adventureInlineMode === "rename" && trimmedName === adventureInlineOriginalName) {
            cancelAdventureInlineEdit()
            return
        }
        if (adventureInlineMode === "create") {
            appController.create_adventure(trimmedName)
            var created = false
            var adventures = appController.adventuresModel || []
            for (var i = 0; i < adventures.length; i++) {
                if (adventures[i] && adventures[i].name === trimmedName) {
                    created = true
                    break
                }
            }
            if (created) {
                adventureInlineMode = "none"
                adventureInlineOriginalName = ""
                adventureInlineDraftName = ""
                adventureInlinePendingFocus = false
            } else {
                adventureInlineDraftName = trimmedName
                adventureInlinePendingFocus = true
            }
            refreshAdventureInlineModel()
            return
        }
        appController.rename_adventure(adventureInlineOriginalName, trimmedName)
        var renamed = false
        var oldStillExists = false
        var renamedAdventures = appController.adventuresModel || []
        for (var j = 0; j < renamedAdventures.length; j++) {
            if (!renamedAdventures[j]) {
                continue
            }
            if (renamedAdventures[j].name === trimmedName) {
                renamed = true
            }
            if (renamedAdventures[j].name === adventureInlineOriginalName) {
                oldStillExists = true
            }
        }
        if (renamed && !oldStillExists) {
            adventureInlineMode = "none"
            adventureInlineOriginalName = ""
            adventureInlineDraftName = ""
            adventureInlinePendingFocus = false
        } else {
            adventureInlineDraftName = trimmedName
            adventureInlinePendingFocus = true
        }
        refreshAdventureInlineModel()
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
    }

    function moveAdventureTo(adventureName, targetIndex) {
        var adventures = appController.adventuresModel
        if (!adventures || adventures.length === 0) {
            return
        }
        var fromIndex = -1
        for (var i = 0; i < adventures.length; i++) {
            if (adventures[i].name === adventureName) {
                fromIndex = i
                break
            }
        }
        if (fromIndex < 0) {
            return
        }
        var boundedTarget = Math.max(0, Math.min(adventures.length - 1, targetIndex))
        if (boundedTarget === fromIndex) {
            return
        }
        appController.move_adventure(adventureName, boundedTarget)
    }

    function beginListDrag(mode, itemName, fromIndex, itemHeight, spacing, itemCount, delegateItem, overlayItem) {
        listDragMode = mode
        listDragName = itemName
        listDragFromIndex = fromIndex
        listDragToIndex = fromIndex
        listDragScrollCompensation = 0
        listDragItemHeight = itemHeight
        listDragPointerDelta = 0
        listDragSpacing = spacing
        listDragItemCount = itemCount
        var mapped = delegateItem && overlayItem ? delegateItem.mapToItem(overlayItem, 0, 0) : Qt.point(0, 0)
        listDragVisualStartX = mapped.x
        listDragVisualStartY = mapped.y
        listDragVisualX = mapped.x
        listDragVisualY = mapped.y
        listDragVisualWidth = delegateItem ? delegateItem.width : 0
        listDragVisualHeight = delegateItem ? delegateItem.height : itemHeight
        listDragVisibleCenterY = mapped.y + (itemHeight / 2)
    }

    function updateListDrag(mode, fromIndex, dragDeltaY, itemHeight, spacing, itemCount, contentY) {
        if (listDragMode !== mode) {
            return
        }
        listDragItemHeight = itemHeight
        listDragPointerDelta = dragDeltaY
        listDragSpacing = spacing
        listDragItemCount = itemCount
        var rowExtent = itemHeight + spacing
        var shiftedCenter = fromIndex * rowExtent + dragDeltaY + listDragScrollCompensation + (itemHeight / 2)
        var rawIndex = Math.floor((shiftedCenter + Math.max(0, spacing / 2)) / Math.max(1, rowExtent))
        listDragToIndex = Math.max(0, Math.min(itemCount - 1, rawIndex))
        listDragVisibleCenterY = shiftedCenter - contentY
        listDragVisualY = listDragVisualStartY + dragDeltaY
    }

    function listDisplacementForIndex(mode, itemIndex, rowExtent) {
        if (listDragMode !== mode || listDragFromIndex < 0 || listDragToIndex < 0) {
            return 0
        }
        if (itemIndex === listDragFromIndex) {
            return 0
        }
        if (listDragToIndex > listDragFromIndex && itemIndex > listDragFromIndex && itemIndex <= listDragToIndex) {
            return -rowExtent
        }
        if (listDragToIndex < listDragFromIndex && itemIndex >= listDragToIndex && itemIndex < listDragFromIndex) {
            return rowExtent
        }
        return 0
    }

    function autoScrollDraggedList(view) {
        if (!view || listDragMode === "none") {
            return
        }
        var maxContentY = Math.max(0, view.contentHeight - view.height)
        if (maxContentY <= 0) {
            return
        }
        var threshold = Math.min(listDragAutoScrollThreshold, Math.max(24, view.height * 0.22))
        var nextContentY = view.contentY
        if (listDragVisibleCenterY < threshold) {
            var upRatio = 1 - Math.max(0, listDragVisibleCenterY) / threshold
            nextContentY -= listDragAutoScrollBaseStep * (0.45 + upRatio * 1.25)
        } else if (listDragVisibleCenterY > view.height - threshold) {
            var downDistance = view.height - listDragVisibleCenterY
            var downRatio = 1 - Math.max(0, downDistance) / threshold
            nextContentY += listDragAutoScrollBaseStep * (0.45 + downRatio * 1.25)
        }
        nextContentY = Math.max(0, Math.min(maxContentY, nextContentY))
        var delta = nextContentY - view.contentY
        if (Math.abs(delta) < 0.01) {
            return
        }
        view.contentY = nextContentY
        listDragScrollCompensation += delta
        updateListDrag(listDragMode, listDragFromIndex, listDragPointerDelta, listDragItemHeight, listDragSpacing, listDragItemCount, view.contentY)
    }

    function finishListDrag() {
        var dragMode = listDragMode
        var draggedName = listDragName
        var fromIndex = listDragFromIndex
        var toIndex = listDragToIndex
        listDragMode = "none"
        listDragName = ""
        listDragFromIndex = -1
        listDragToIndex = -1
        listDragScrollCompensation = 0
        listDragItemHeight = 0
        listDragPointerDelta = 0
        listDragSpacing = 0
        listDragItemCount = 0
        listDragVisibleCenterY = 0
        listDragVisualStartX = 0
        listDragVisualStartY = 0
        listDragVisualX = 0
        listDragVisualY = 0
        listDragVisualWidth = 0
        listDragVisualHeight = 0
        if (!draggedName || fromIndex < 0 || toIndex < 0 || toIndex === fromIndex) {
            return
        }
        if (dragMode === "scene") {
            moveSceneTo(draggedName, toIndex)
        } else if (dragMode === "adventure") {
            moveAdventureTo(draggedName, toIndex)
        }
    }

    function assignDroppedPath(drop, textField) {
        if (!drop || !drop.urls || drop.urls.length === 0) {
            return
        }
        textField.text = drop.urls[0].toString()
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
                        text: launcherWindow.scenesMode
                            ? "Список сцен текущего приключения"
                            : "Корневая папка приключений"
                        color: launcherWindow.textSecondary
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    spacing: 14

                    NeumoIconButton {
                        theme: neumoTheme
                        width: 44
                        height: 44
                        enabled: !launcherWindow.inlineEditActive
                        iconSource: Qt.resolvedUrl("icons/dice.svg")
                        toolTip: "Дайсы"
                        onClicked: appController.request_open_dice()
                    }

                    NeumoIconButton {
                        theme: neumoTheme
                        width: 44
                        height: 44
                        enabled: !launcherWindow.inlineEditActive
                        iconSource: Qt.resolvedUrl("icons/settings.svg")
                        toolTip: "Настройки"
                        onClicked: settingsDrawer.open()
                    }
                }
            }

            NeumoInsetSurface {
                theme: neumoTheme
                useFrameProfile: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 26
                fillColor: launcherWindow.bgBase
                contentPadding: 20

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16

                    RowLayout {
                        visible: !launcherWindow.sceneEditorVisible
                        Layout.fillWidth: true
                        Layout.leftMargin: launcherWindow.explorerEdgeInset
                        Layout.rightMargin: launcherWindow.explorerEdgeInset
                        spacing: 10

                        NeumoIconButton {
                            theme: neumoTheme
                            width: 30
                            height: 30
                            enabled: visible && !launcherWindow.inlineEditActive
                            iconSource: Qt.resolvedUrl("icons/back.svg")
                            toolTip: "Назад к приключениям"
                            visible: launcherWindow.scenesMode
                            onClicked: appController.leave_launcher_adventure()
                        }

                        Label {
                            Layout.fillWidth: true
                            text: launcherWindow.scenesMode ? appController.launcherAdventure : "Приключения"
                            color: "#E4E4E4"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        NeumoIconButton {
                            theme: neumoTheme
                            width: 30
                            height: 30
                            enabled: !launcherWindow.inlineEditActive
                            glyph: "+"
                            fontSize: 20
                            toolTip: launcherWindow.scenesMode ? "Добавить сцену" : "Добавить приключение"
                            onClicked: {
                                if (launcherWindow.scenesMode) {
                                    launcherWindow.openCreateSceneDialog()
                                } else {
                                    launcherWindow.beginCreateAdventureInline()
                                }
                            }
                        }
                    }
                    Item {
                        visible: !launcherWindow.sceneEditorVisible
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: explorerView

                            Timer {
                                interval: 16
                                repeat: true
                                running: launcherWindow.listDragMode !== "none"
                                onTriggered: launcherWindow.autoScrollDraggedList(explorerView)
                            }
                            property real rowShadowBleed: launcherWindow.explorerEdgeInset
                            anchors.fill: parent
                            leftMargin: rowShadowBleed
                            rightMargin: rowShadowBleed
                            topMargin: rowShadowBleed
                            bottomMargin: rowShadowBleed
                            spacing: 12
                            cacheBuffer: Math.max(height * 3, 720)
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: launcherWindow.scenesMode ? launcherWindow.sceneInlineModel : launcherWindow.adventureInlineModel
                            ScrollBar.vertical: NeumoScrollBar {}
                            ScrollBar.horizontal: NeumoScrollBar {}
                            displaced: Transition {
                                NumberAnimation { properties: "x,y"; duration: 170; easing.type: Easing.OutCubic }
                            }


                            delegate: Item {
                                id: explorerDelegate
                                property bool scenesMode: launcherWindow.scenesMode
                                property bool isAdventureInline: !explorerDelegate.scenesMode && modelData && modelData.isInlineEditor
                                property bool isSceneInline: explorerDelegate.scenesMode && modelData && modelData.isInlineEditor
                                property bool isInlineEditor: explorerDelegate.isAdventureInline || explorerDelegate.isSceneInline
                                property string itemName: modelData && modelData.name ? modelData.name : ""
                                property real dragY: 0
                                property real dragDeltaY: 0
                                property string dragMode: explorerDelegate.scenesMode ? "scene" : "adventure"
                                property bool isDraggedDelegate: launcherWindow.listDragMode === explorerDelegate.dragMode && launcherWindow.listDragFromIndex === index
                                property bool usesSmoothListDrag: explorerDelegate.scenesMode || !explorerDelegate.isInlineEditor
                                property real slotDisplacement: explorerDelegate.usesSmoothListDrag
                                    ? launcherWindow.listDisplacementForIndex(explorerDelegate.dragMode, index, explorerDelegate.height + explorerView.spacing)
                                    : 0
                                x: explorerView.leftMargin
                                width: explorerView.width - explorerView.leftMargin - explorerView.rightMargin
                                height: 48
                                z: dragHandler.active ? 20 : 1

                                Behavior on slotDisplacement {
                                    NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
                                }

                                Translate {
                                    id: dragTranslate
                                    y: explorerDelegate.isDraggedDelegate ? 0 : explorerDelegate.slotDisplacement
                                }
                                transform: [dragTranslate]

                                NeumoRowButton {
                                    theme: neumoTheme
                                    id: rowButton
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    dragging: dragHandler.active && !explorerDelegate.isDraggedDelegate
                                    visible: !explorerDelegate.isInlineEditor && !explorerDelegate.isDraggedDelegate

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 15
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true

                                            Label {
                                                anchors.fill: parent
                                                text: explorerDelegate.itemName
                                                color: "#C9C9C9"
                                                font.pixelSize: 14
                                                font.weight: Font.Medium
                                                elide: Text.ElideRight
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                acceptedButtons: Qt.LeftButton
                                                enabled: !launcherWindow.inlineEditActive
                                                onClicked: singleClickTimer.restart()
                                                onDoubleClicked: {
                                                    singleClickTimer.stop()
                                                    if (explorerDelegate.scenesMode) {
                                                        launcherWindow.beginRenameSceneInline(explorerDelegate.itemName)
                                                    } else {
                                                        launcherWindow.beginRenameAdventureInline(explorerDelegate.itemName)
                                                    }
                                                }
                                            }

                                            Timer {
                                                id: singleClickTimer
                                                interval: 180
                                                repeat: false
                                                onTriggered: {
                                                    if (explorerDelegate.scenesMode) {
                                                        appController.open_scene(explorerDelegate.itemName)
                                                    } else {
                                                        appController.enter_launcher_adventure(explorerDelegate.itemName)
                                                    }
                                                }
                                            }
                                        }

                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 5

                                            NeumoGhostIconButton {
                                                theme: neumoTheme
                                                width: 24
                                                height: 24
                                                visible: explorerDelegate.scenesMode
                                                enabled: !launcherWindow.inlineEditActive
                                                rowHovered: rowButton.hovered
                                                iconSource: Qt.resolvedUrl("icons/scene_edit.svg")
                                                toolTip: "Изменить сцену"
                                                onClicked: launcherWindow.openEditSceneDialog(explorerDelegate.itemName)
                                            }

                                            NeumoGhostIconButton {
                                                theme: neumoTheme
                                                width: 24
                                                height: 24
                                                enabled: !launcherWindow.inlineEditActive
                                                rowHovered: rowButton.hovered
                                                iconSource: Qt.resolvedUrl("icons/clear.svg")
                                                toolTip: explorerDelegate.scenesMode ? "Удалить сцену" : "Удалить приключение"
                                                onClicked: {
                                                    if (explorerDelegate.scenesMode) {
                                                        appController.delete_scene(explorerDelegate.itemName)
                                                    } else {
                                                        appController.delete_adventure(explorerDelegate.itemName)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                NeumoInsetSurface {
                                    theme: neumoTheme
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: 13
                                    fillColor: launcherWindow.bgBase
                                    contentPadding: 0
                                    visible: explorerDelegate.isInlineEditor

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 15
                                        anchors.rightMargin: 15
                                        spacing: 8

                                        TextField {
                                            id: inlineAdventureField
                                            Layout.fillWidth: true
                                            text: explorerDelegate.isSceneInline ? launcherWindow.sceneInlineDraftName : launcherWindow.adventureInlineDraftName
                                            color: launcherWindow.textPrimary
                                            selectedTextColor: "#F4F4F6"
                                            selectionColor: "#6C6C6C"
                                            placeholderText: "Введите название"
                                            placeholderTextColor: launcherWindow.textSecondary
                                            padding: 0
                                            leftPadding: 0
                                            rightPadding: 0
                                            topPadding: 0
                                            bottomPadding: 0
                                            background: null
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                            onTextChanged: {
                                                if (explorerDelegate.isSceneInline) {
                                                    launcherWindow.sceneInlineDraftName = text
                                                } else {
                                                    launcherWindow.adventureInlineDraftName = text
                                                }
                                            }
                                            onAccepted: {
                                                if (explorerDelegate.isSceneInline) {
                                                    launcherWindow.commitSceneInlineEdit()
                                                } else {
                                                    launcherWindow.commitAdventureInlineEdit()
                                                }
                                            }
                                            onActiveFocusChanged: {
                                                if (!activeFocus && explorerDelegate.isInlineEditor) {
                                                    inlineFocusRestoreTimer.restart()
                                                }
                                            }
                                            Keys.onEscapePressed: function(event) {
                                                event.accepted = true
                                                if (explorerDelegate.isSceneInline) {
                                                    launcherWindow.cancelSceneInlineEdit()
                                                } else {
                                                    launcherWindow.cancelAdventureInlineEdit()
                                                }
                                            }

                                            Timer {
                                                id: inlineFocusRestoreTimer
                                                interval: 0
                                                repeat: false
                                                onTriggered: {
                                                    if (explorerDelegate.isInlineEditor) {
                                                        inlineAdventureField.forceActiveFocus()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Timer {
                                    id: inlineFocusTimer
                                    interval: 0
                                    running: explorerDelegate.isInlineEditor && (explorerDelegate.isSceneInline ? launcherWindow.sceneInlinePendingFocus : launcherWindow.adventureInlinePendingFocus)
                                    repeat: false
                                    onTriggered: {
                                        if (explorerDelegate.isSceneInline) {
                                            launcherWindow.sceneInlinePendingFocus = false
                                        } else {
                                            launcherWindow.adventureInlinePendingFocus = false
                                        }
                                        inlineAdventureField.forceActiveFocus()
                                        inlineAdventureField.selectAll()
                                    }
                                }

                                DragHandler {
                                    id: dragHandler
                                    enabled: !launcherWindow.inlineEditActive && !explorerDelegate.isInlineEditor
                                    target: null
                                    onActiveChanged: {
                                        if (active) {
                                            explorerDelegate.dragDeltaY = 0
                                            singleClickTimer.stop()
                                            launcherWindow.beginListDrag(
                                                explorerDelegate.dragMode,
                                                explorerDelegate.itemName,
                                                index,
                                                explorerDelegate.height,
                                                explorerView.spacing,
                                                explorerView.count,
                                                explorerDelegate,
                                                explorerDragOverlay
                                            )
                                            launcherWindow.updateListDrag(
                                                explorerDelegate.dragMode,
                                                index,
                                                0,
                                                explorerDelegate.height,
                                                explorerView.spacing,
                                                explorerView.count,
                                                explorerView.contentY
                                            )
                                            return
                                        }
                                        launcherWindow.finishListDrag()
                                        explorerDelegate.dragY = 0
                                        explorerDelegate.dragDeltaY = 0
                                    }
                                    onTranslationChanged: {
                                        explorerDelegate.dragY = translation.y
                                        explorerDelegate.dragDeltaY = translation.y
                                        launcherWindow.updateListDrag(
                                            explorerDelegate.dragMode,
                                            index,
                                            translation.y,
                                            explorerDelegate.height,
                                            explorerView.spacing,
                                            explorerView.count,
                                            explorerView.contentY
                                        )
                                    }
                                }
                            }
                        }

                        Item {
                            id: explorerDragOverlay
                            anchors.fill: parent
                            z: 50

                            NeumoRowButton {
                                id: dragRowProxy
                                theme: neumoTheme
                                x: launcherWindow.listDragVisualX
                                y: launcherWindow.listDragVisualY
                                width: launcherWindow.listDragVisualWidth
                                height: launcherWindow.listDragVisualHeight > 0 ? launcherWindow.listDragVisualHeight : 48
                                visible: launcherWindow.listDragMode !== "none"
                                dragging: true
                                enabled: false

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Label {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: launcherWindow.listDragName
                                        color: "#C9C9C9"
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 5

                                        NeumoGhostIconButton {
                                            theme: neumoTheme
                                            width: 24
                                            height: 24
                                            visible: launcherWindow.scenesMode
                                            enabled: false
                                            rowHovered: true
                                            iconSource: Qt.resolvedUrl("icons/scene_edit.svg")
                                        }

                                        NeumoGhostIconButton {
                                            theme: neumoTheme
                                            width: 24
                                            height: 24
                                            enabled: false
                                            rowHovered: true
                                            iconSource: Qt.resolvedUrl("icons/clear.svg")
                                        }
                                    }
                                }
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: explorerView.count === 0
                            text: launcherWindow.scenesMode
                                ? "В этом приключении пока нет сцен"
                                : "Приключений пока нет"
                            color: launcherWindow.textSecondary
                            font.pixelSize: 14
                        }
                    }
                }

                SceneEditorSurface {
                    id: sceneEditorSurface
                    visible: launcherWindow.sceneEditorVisible
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    theme: neumoTheme
                    initialDraft: launcherWindow.sceneEditorInitialDraft
                    openToken: launcherWindow.sceneEditorOpenToken
                    statusMessage: appController.statusMessage
                    onBackRequested: function(dirty) {
                        launcherWindow.requestCloseSceneEditor(!dirty)
                    }
                    onSaveRequested: function(draft) {
                        var ok = appController.save_scene_draft_for_adventure(appController.launcherAdventure, draft)
                        if (ok) {
                            launcherWindow.closeSceneEditor()
                        }
                    }
                    onBrowseRequested: function(target) {
                        launcherWindow.pendingFileTarget = target
                        mediaFileDialog.open()
                    }
                    onColorRequested: function(target, currentValue) {
                        launcherWindow.pendingColorTarget = target
                        colorPickerDialog.selectedColor = currentValue
                        colorPickerDialog.open()
                    }
                    onPasteRequested: function(target) {
                        var pastedValue = appController.paste_media_value(target)
                        if (pastedValue && pastedValue.length > 0) {
                            sceneEditorSurface.applyPastedValue(target, pastedValue)
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        appController.refresh_library()
        refreshAdventureInlineModel()
        refreshSceneInlineModel()
    }

    onScenesModeChanged: {
        if (scenesMode) {
            cancelAdventureInlineEdit()
        } else {
            cancelSceneInlineEdit()
            closeSceneEditor()
        }
    }

    Connections {
        target: appController
        function onLibraryChanged() {
            refreshAdventureInlineModel()
            refreshSceneInlineModel()
        }
    }

    Dialog {
        id: sceneEditorDiscardDialog
        modal: true
        x: Math.round((launcherWindow.width - width) / 2)
        y: Math.round((launcherWindow.height - height) / 2)
        width: 360
        standardButtons: Dialog.NoButton
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            radius: 18
            color: "#262626"
            border.width: 1
            border.color: "#5C5C5C"
        }

        contentItem: ColumnLayout {
            spacing: 12

            Label {
                text: "\u0415\u0441\u0442\u044c \u043d\u0435\u0441\u043e\u0445\u0440\u0430\u043d\u0435\u043d\u043d\u044b\u0435 \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u044f"
                color: launcherWindow.textPrimary
                font.pixelSize: 18
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Label {
                text: "\u0417\u0430\u043a\u0440\u044b\u0442\u044c \u0440\u0435\u0434\u0430\u043a\u0442\u043e\u0440 \u0438 \u043f\u043e\u0442\u0435\u0440\u044f\u0442\u044c \u0432\u0432\u0435\u0434\u0435\u043d\u043d\u044b\u0435 \u043f\u0440\u0430\u0432\u043a\u0438?"
                color: launcherWindow.textSecondary
                font.pixelSize: 13
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                NeumoDialogButton {
                    theme: neumoTheme
                    text: "\u0412\u0435\u0440\u043d\u0443\u0442\u044c\u0441\u044f"
                    Layout.fillWidth: true
                    onClicked: sceneEditorDiscardDialog.close()
                }

                NeumoDialogButton {
                    theme: neumoTheme
                    text: "\u0417\u0430\u043a\u0440\u044b\u0442\u044c \u0431\u0435\u0437 \u0441\u043e\u0445\u0440\u0430\u043d\u0435\u043d\u0438\u044f"
                    accent: true
                    Layout.fillWidth: true
                    onClicked: {
                        sceneEditorDiscardDialog.close()
                        launcherWindow.closeSceneEditor()
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
            if (launcherWindow.sceneEditorVisible) {
                sceneEditorSurface.applyFileSelection(launcherWindow.pendingFileTarget, selected)
            }
        }
    }

    ColorDialog {
        id: colorPickerDialog
        title: "Выбор цвета"
        onAccepted: {
            var value = normalizeColorValue(selectedColor)
            if (launcherWindow.sceneEditorVisible) {
                sceneEditorSurface.applyColorSelection(launcherWindow.pendingColorTarget, value)
            }
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
            ScrollBar.vertical: NeumoScrollBar {}
            ScrollBar.horizontal: NeumoScrollBar {}

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
                NeumoTextField {
                    theme: neumoTheme
                    id: adventuresRootField
                    text: appController.adventuresRoot
                    placeholderText: "Путь к папке приключений"
                    Layout.fillWidth: true
                }
                NeumoDialogButton {
                    theme: neumoTheme
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
                NeumoTextField {
                    theme: neumoTheme
                    id: panelWidthField
                    text: String(appController.leftPanelWidth)
                    Layout.fillWidth: true
                }
                Label { text: "Зона появления (px)"; color: launcherWindow.textSecondary }
                NeumoTextField {
                    theme: neumoTheme
                    id: revealZoneField
                    text: String(appController.leftRevealZone)
                    Layout.fillWidth: true
                }
                NeumoDialogButton {
                    theme: neumoTheme
                    text: "Применить панель"
                    onClicked: appController.update_panel(Number(panelWidthField.text), Number(revealZoneField.text))
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                }

                RowLayout {
                    Layout.fillWidth: true
                    NeumoDialogButton {
                        theme: neumoTheme
                        text: "Сохранить настройки"
                        accent: true
                        Layout.fillWidth: true
                        onClicked: appController.persist_settings()
                    }
                    NeumoDialogButton {
                        theme: neumoTheme
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
