import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "neumo"

Item {
    id: root

    property var theme
    property color bgBase: "#2D2D2D"
    property color textPrimary: "#D0D0D0"
    property color textSecondary: "#909090"
    property real explorerEdgeInset: 12

    readonly property bool scenesMode: appController.launcherAdventure.length > 0
    readonly property bool adventureInlineActive: !scenesMode && adventureInlineMode !== "none"
    readonly property bool sceneInlineActive: scenesMode && sceneInlineMode !== "none"
    readonly property bool inlineEditActive: adventureInlineActive || sceneInlineActive

    property string adventureInlineMode: "none"
    property string adventureInlineOriginalName: ""
    property string adventureInlineDraftName: ""
    property bool adventureInlinePendingFocus: false
    property var adventureInlineModel: []
    property string sceneInlineMode: "none"
    property string sceneInlineOriginalName: ""
    property string sceneInlineDraftName: ""
    property bool sceneInlinePendingFocus: false
    property var sceneInlineModel: []
    property var sceneInlineDraftPayload: ({})
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

    signal createSceneRequested()
    signal editSceneRequested(string sceneName)
    signal settingsRequested()
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
    Component.onCompleted: {
        refreshAdventureInlineModel()
        refreshSceneInlineModel()
    }

    onScenesModeChanged: {
        if (scenesMode) {
            cancelAdventureInlineEdit()
        } else {
            cancelSceneInlineEdit()
        }
    }

    Connections {
        target: appController
        function onLibraryChanged() {
            refreshAdventureInlineModel()
            refreshSceneInlineModel()
        }
    }
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
                        font.pixelSize: Math.max(28, Math.min(40, root.width * 0.06))
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Label {
                        text: root.scenesMode
                            ? "Список сцен текущего приключения"
                            : "Корневая папка приключений"
                        color: root.textSecondary
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    spacing: 14

                    NeumoIconButton {
                        theme: root.theme
                        width: 44
                        height: 44
                        enabled: !root.inlineEditActive
                        iconSource: Qt.resolvedUrl("../icons/dice.svg")
                        toolTip: "Дайсы"
                        onClicked: appController.request_open_dice()
                    }

                    NeumoIconButton {
                        theme: root.theme
                        width: 44
                        height: 44
                        enabled: !root.inlineEditActive
                        iconSource: Qt.resolvedUrl("../icons/settings.svg")
                        toolTip: "Настройки"
                        onClicked: root.settingsRequested()
                    }
                }
            }

            NeumoInsetSurface {
                theme: root.theme
                useFrameProfile: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 26
                fillColor: root.bgBase
                contentPadding: 20

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: root.explorerEdgeInset
                        Layout.rightMargin: root.explorerEdgeInset
                        spacing: 10

                        NeumoIconButton {
                            theme: root.theme
                            width: 30
                            height: 30
                            enabled: visible && !root.inlineEditActive
                            iconSource: Qt.resolvedUrl("../icons/back.svg")
                            toolTip: "Назад к приключениям"
                            visible: root.scenesMode
                            onClicked: appController.leave_launcher_adventure()
                        }

                        Label {
                            Layout.fillWidth: true
                            text: root.scenesMode ? appController.launcherAdventure : "Приключения"
                            color: "#E4E4E4"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        NeumoIconButton {
                            theme: root.theme
                            width: 30
                            height: 30
                            enabled: !root.inlineEditActive
                            glyph: "+"
                            fontSize: 20
                            toolTip: root.scenesMode ? "Добавить сцену" : "Добавить приключение"
                            onClicked: {
                                if (root.scenesMode) {
                                    root.createSceneRequested()
                                } else {
                                    root.beginCreateAdventureInline()
                                }
                            }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: explorerView

                            Timer {
                                interval: 16
                                repeat: true
                                running: root.listDragMode !== "none"
                                onTriggered: root.autoScrollDraggedList(explorerView)
                            }
                            property real rowShadowBleed: root.explorerEdgeInset
                            anchors.fill: parent
                            leftMargin: rowShadowBleed
                            rightMargin: rowShadowBleed
                            topMargin: rowShadowBleed
                            bottomMargin: rowShadowBleed
                            spacing: 12
                            cacheBuffer: Math.max(height * 3, 720)
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.scenesMode ? root.sceneInlineModel : root.adventureInlineModel
                            ScrollBar.vertical: NeumoScrollBar {}
                            ScrollBar.horizontal: NeumoScrollBar {}
                            displaced: Transition {
                                NumberAnimation { properties: "x,y"; duration: 170; easing.type: Easing.OutCubic }
                            }


                            delegate: Item {
                                id: explorerDelegate
                                property bool scenesMode: root.scenesMode
                                property bool isAdventureInline: !explorerDelegate.scenesMode && modelData && modelData.isInlineEditor
                                property bool isSceneInline: explorerDelegate.scenesMode && modelData && modelData.isInlineEditor
                                property bool isInlineEditor: explorerDelegate.isAdventureInline || explorerDelegate.isSceneInline
                                property string itemName: modelData && modelData.name ? modelData.name : ""
                                property real dragY: 0
                                property real dragDeltaY: 0
                                property string dragMode: explorerDelegate.scenesMode ? "scene" : "adventure"
                                property bool isDraggedDelegate: root.listDragMode === explorerDelegate.dragMode && root.listDragFromIndex === index
                                property bool usesSmoothListDrag: explorerDelegate.scenesMode || !explorerDelegate.isInlineEditor
                                property real slotDisplacement: explorerDelegate.usesSmoothListDrag
                                    ? root.listDisplacementForIndex(explorerDelegate.dragMode, index, explorerDelegate.height + explorerView.spacing)
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
                                    theme: root.theme
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
                                                enabled: !root.inlineEditActive
                                                onClicked: singleClickTimer.restart()
                                                onDoubleClicked: {
                                                    singleClickTimer.stop()
                                                    if (explorerDelegate.scenesMode) {
                                                        root.beginRenameSceneInline(explorerDelegate.itemName)
                                                    } else {
                                                        root.beginRenameAdventureInline(explorerDelegate.itemName)
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
                                                theme: root.theme
                                                width: 24
                                                height: 24
                                                visible: explorerDelegate.scenesMode
                                                enabled: !root.inlineEditActive
                                                rowHovered: rowButton.hovered
                                                iconSource: Qt.resolvedUrl("../icons/scene_edit.svg")
                                                toolTip: "Изменить сцену"
                                                onClicked: root.editSceneRequested(explorerDelegate.itemName)
                                            }

                                            NeumoGhostIconButton {
                                                theme: root.theme
                                                width: 24
                                                height: 24
                                                enabled: !root.inlineEditActive
                                                rowHovered: rowButton.hovered
                                                iconSource: Qt.resolvedUrl("../icons/clear.svg")
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
                                    theme: root.theme
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: 13
                                    fillColor: root.bgBase
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
                                            text: explorerDelegate.isSceneInline ? root.sceneInlineDraftName : root.adventureInlineDraftName
                                            color: root.textPrimary
                                            selectedTextColor: "#F4F4F6"
                                            selectionColor: "#6C6C6C"
                                            placeholderText: "Введите название"
                                            placeholderTextColor: root.textSecondary
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
                                                    root.sceneInlineDraftName = text
                                                } else {
                                                    root.adventureInlineDraftName = text
                                                }
                                            }
                                            onAccepted: {
                                                if (explorerDelegate.isSceneInline) {
                                                    root.commitSceneInlineEdit()
                                                } else {
                                                    root.commitAdventureInlineEdit()
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
                                                    root.cancelSceneInlineEdit()
                                                } else {
                                                    root.cancelAdventureInlineEdit()
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
                                    running: explorerDelegate.isInlineEditor && (explorerDelegate.isSceneInline ? root.sceneInlinePendingFocus : root.adventureInlinePendingFocus)
                                    repeat: false
                                    onTriggered: {
                                        if (explorerDelegate.isSceneInline) {
                                            root.sceneInlinePendingFocus = false
                                        } else {
                                            root.adventureInlinePendingFocus = false
                                        }
                                        inlineAdventureField.forceActiveFocus()
                                        inlineAdventureField.selectAll()
                                    }
                                }

                                DragHandler {
                                    id: dragHandler
                                    enabled: !root.inlineEditActive && !explorerDelegate.isInlineEditor
                                    target: null
                                    onActiveChanged: {
                                        if (active) {
                                            explorerDelegate.dragDeltaY = 0
                                            singleClickTimer.stop()
                                            root.beginListDrag(
                                                explorerDelegate.dragMode,
                                                explorerDelegate.itemName,
                                                index,
                                                explorerDelegate.height,
                                                explorerView.spacing,
                                                explorerView.count,
                                                explorerDelegate,
                                                explorerDragOverlay
                                            )
                                            root.updateListDrag(
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
                                        root.finishListDrag()
                                        explorerDelegate.dragY = 0
                                        explorerDelegate.dragDeltaY = 0
                                    }
                                    onTranslationChanged: {
                                        explorerDelegate.dragY = translation.y
                                        explorerDelegate.dragDeltaY = translation.y
                                        root.updateListDrag(
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
                                theme: root.theme
                                x: root.listDragVisualX
                                y: root.listDragVisualY
                                width: root.listDragVisualWidth
                                height: root.listDragVisualHeight > 0 ? root.listDragVisualHeight : 48
                                visible: root.listDragMode !== "none"
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
                                        text: root.listDragName
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
                                            theme: root.theme
                                            width: 24
                                            height: 24
                                            visible: root.scenesMode
                                            enabled: false
                                            rowHovered: true
                                            iconSource: Qt.resolvedUrl("../icons/scene_edit.svg")
                                        }

                                        NeumoGhostIconButton {
                                            theme: root.theme
                                            width: 24
                                            height: 24
                                            enabled: false
                                            rowHovered: true
                                            iconSource: Qt.resolvedUrl("../icons/clear.svg")
                                        }
                                    }
                                }
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: explorerView.count === 0
                            text: root.scenesMode
                                ? "В этом приключении пока нет сцен"
                                : "Приключений пока нет"
                            color: root.textSecondary
                            font.pixelSize: 14
                        }
                    }
                }
                }
            }
}