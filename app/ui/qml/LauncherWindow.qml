import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window
import "components"

Window {
    id: launcherWindow
    width: 620
    height: 820
    visible: true
    color: "#0F1218"
    title: "DnD Maps - Лаунчер"
    property int selectedAdventureIndex: -1
    property int selectedSceneIndex: -1
    property string pendingFileTarget: "map"
    property string sceneDialogModeCode: "create"
    property color bgBase: "#17181B"
    property color bgDeep: "#1C1D22"
    property color bgCard: "#26282F"
    property color bgCardSoft: "#2E3139"
    property color lineColor: "#4A4E58"
    property color textPrimary: "#EFEFF2"
    property color textSecondary: "#ABADB5"
    property color accentColor: "#8E939F"
    property color accentStrong: "#777C87"
    property string adventureDialogMode: "create"
    property string adventureOriginalName: ""

    function mediaIndex(mediaType) {
        if (mediaType === "image") {
            return 1
        }
        if (mediaType === "video") {
            return 2
        }
        return 0
    }

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

    function applyDetectedMediaType(value, comboBox) {
        if (!comboBox) {
            return
        }
        var detected = detectMediaTypeFromValue(value, comboBox.currentText || "color")
        comboBox.currentIndex = mediaIndex(detected)
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

        sceneMapType.currentIndex = mediaIndex(draft.map.type || "color")
        sceneMapValue.text = draft.map.value || ""
        sceneMapAutoplay.checked = draft.map.autoplay
        sceneMapLoop.checked = draft.map.loop
        sceneMapMute.checked = draft.map.mute

        sceneBgType.currentIndex = mediaIndex(draft.background.type || "color")
        sceneBgValue.text = draft.background.value || ""
        sceneBgAutoplay.checked = draft.background.autoplay
        sceneBgLoop.checked = draft.background.loop
        sceneBgMute.checked = draft.background.mute

        sceneGridSize.text = Number(draft.grid.cell_size_ft || 5).toFixed(2)
        sceneGridThickness.text = Number(draft.grid.line_thickness_px || 1.5).toFixed(2)
        sceneGridOpacity.text = Number(draft.grid.opacity || 0.45).toFixed(2)
        sceneGridColor.text = draft.grid.color || "#9DA6B0"
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
        return {
            "mode": sceneDialogModeCode,
            "name": sceneNameField.text,
            "original_name": sceneOriginalName.text,
            "map": {
                "type": sceneMapType.currentText,
                "value": sceneMapValue.text,
                "autoplay": sceneMapAutoplay.checked,
                "loop": sceneMapLoop.checked,
                "mute": sceneMapMute.checked
            },
            "background": {
                "type": sceneBgType.currentText,
                "value": sceneBgValue.text,
                "autoplay": sceneBgAutoplay.checked,
                "loop": sceneBgLoop.checked,
                "mute": sceneBgMute.checked
            },
            "grid": {
                "cell_size_ft": Number(sceneGridSize.text),
                "line_thickness_px": Number(sceneGridThickness.text),
                "opacity": Number(sceneGridOpacity.text),
                "color": sceneGridColor.text
            }
        }
    }

    component AppButton: Button {
        id: control
        property bool accent: false
        hoverEnabled: true
        implicitHeight: 36
        font.pixelSize: 13

        contentItem: Text {
            text: control.text
            color: control.enabled
                ? (control.accent ? "#F7F7F8" : launcherWindow.textPrimary)
                : "#8A8E97"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: control.font.pixelSize
            font.weight: control.accent ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 12
            border.width: 1
            border.color: control.accent ? "#B4BAC6" : "#505663"
            opacity: control.enabled ? 1.0 : 0.5
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: control.accent
                        ? (control.down ? "#727987" : (control.hovered ? "#858D9C" : "#7D8492"))
                        : (control.down ? "#323740" : (control.hovered ? "#3B414C" : "#363B45"))
                }
                GradientStop {
                    position: 1
                    color: control.accent
                        ? (control.down ? "#666E7D" : (control.hovered ? "#747D8C" : "#6E7685"))
                        : (control.down ? "#292E36" : (control.hovered ? "#323741" : "#2D323B"))
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
        selectionColor: "#6C717D"
        placeholderTextColor: "#8F919A"
        padding: 10

        background: Rectangle {
            radius: 11
            color: "#23262E"
            border.width: 1
            border.color: control.activeFocus ? "#ABB1BE" : (control.hovered ? "#626977" : "#4D515C")
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
        signal clicked()
        width: 24
        height: 24

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: hitArea.pressed ? "#646A77" : (hitArea.containsMouse ? "#555B67" : "transparent")
            border.width: hitArea.containsMouse ? 1 : 0
            border.color: "#969CAA"
            Behavior on color { ColorAnimation { duration: 90 } }
        }

        Image {
            anchors.centerIn: parent
            width: 14
            height: 14
            visible: iconRoot.iconSource.length > 0
            source: iconRoot.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }

        Text {
            anchors.centerIn: parent
            visible: iconRoot.iconSource.length === 0 && iconRoot.glyph.length > 0
            text: iconRoot.glyph
            color: "#E8EAF0"
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }

        ToolTip.visible: hitArea.containsMouse && toolTip.length > 0
        ToolTip.text: toolTip
        ToolTip.delay: 350

        MouseArea {
            id: hitArea
            anchors.fill: parent
            enabled: iconRoot.enabled
            hoverEnabled: true
            onClicked: iconRoot.clicked()
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: launcherWindow.bgDeep }
            GradientStop { position: 0.6; color: launcherWindow.bgBase }
            GradientStop { position: 1.0; color: "#121316" }
        }

        Rectangle {
            id: orbTop
            width: 420
            height: 420
            radius: 210
            x: -140
            y: -170
            color: "#4A4D54"
            opacity: 0.18

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: -90; duration: 4200; easing.type: Easing.InOutSine }
                NumberAnimation { to: -140; duration: 4200; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: -130; duration: 3600; easing.type: Easing.InOutSine }
                NumberAnimation { to: -170; duration: 3600; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            id: orbBottom
            width: 480
            height: 480
            radius: 240
            x: launcherWindow.width - width + 130
            y: launcherWindow.height - height + 180
            color: "#5A5E67"
            opacity: 0.14

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: launcherWindow.width - width + 80; duration: 4800; easing.type: Easing.InOutSine }
                NumberAnimation { to: launcherWindow.width - width + 130; duration: 4800; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: launcherWindow.height - height + 130; duration: 5000; easing.type: Easing.InOutSine }
                NumberAnimation { to: launcherWindow.height - height + 180; duration: 5000; easing.type: Easing.InOutSine }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Лаунчер DnD Maps"
                        color: launcherWindow.textPrimary
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }
                    Label {
                        text: "Приключения, сцены и настройки по умолчанию"
                        color: launcherWindow.textSecondary
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                }

                AppButton {
                    text: "Настройки"
                    accent: true
                    onClicked: settingsDrawer.open()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: "#23262E"
                border.color: "#606572"
                border.width: 1
                implicitHeight: statusLabel.implicitHeight + 12
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "#2B2F38" }
                    GradientStop { position: 1.0; color: "#22262E" }
                }

                Rectangle {
                    width: 4
                    radius: 2
                    color: "#A8AEBB"
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    opacity: 0.9
                }

                Label {
                    id: statusLabel
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    text: appController.statusMessage
                    color: "#D2D4DB"
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: launcherWindow.bgCard
                border.color: launcherWindow.lineColor
                border.width: 1
                opacity: 0.98

                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: launcherWindow.bgCardSoft }
                    GradientStop { position: 1.0; color: launcherWindow.bgCard }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: parent.width * 0.42
                        color: "#22252D"
                        radius: 12
                        border.color: "#4F535D"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Label {
                                text: "Приключения"
                                color: launcherWindow.textPrimary
                                font.pixelSize: 18
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Item { Layout.fillWidth: true }
                                IconButton {
                                    glyph: "+"
                                    toolTip: "Создать приключение"
                                    onClicked: launcherWindow.openCreateAdventureDialog()
                                }
                            }

                            ListView {
                                id: adventuresView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 4
                                boundsBehavior: Flickable.StopAtBounds
                                model: appController.adventuresModel
                                currentIndex: launcherWindow.selectedAdventureIndex
                                ScrollBar.vertical: AppScrollBar {}
                                delegate: Item {
                                    id: adventureDelegate
                                    width: adventuresView.width
                                    height: 38
                                    property bool hovered: hoverHandler.hovered

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 9
                                        color: ListView.isCurrentItem
                                            ? "#4A4D55"
                                            : (adventureDelegate.hovered ? "#373A42" : "transparent")
                                        border.width: ListView.isCurrentItem ? 1 : 0
                                        border.color: "#A7A9B1"
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            color: ListView.isCurrentItem ? "#F2F2F4" : "#CFD1D8"
                                            font.pixelSize: 14
                                            font.weight: ListView.isCurrentItem ? Font.DemiBold : Font.Normal
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Item {
                                            Layout.preferredWidth: 54
                                            Layout.fillHeight: true
                                            visible: adventureDelegate.hovered || ListView.isCurrentItem

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                IconButton {
                                                    iconSource: "icons/scene_edit.svg"
                                                    toolTip: "Переименовать"
                                                    onClicked: launcherWindow.openEditAdventureDialog(index)
                                                }
                                                IconButton {
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

                            AppTextField {
                                id: newAdventureField
                                visible: false
                                Layout.fillWidth: true
                                placeholderText: "Название нового приключения"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: false
                                AppButton {
                                    text: "Создать"
                                    accent: true
                                    Layout.fillWidth: true
                                    onClicked: {
                                        appController.create_adventure(newAdventureField.text)
                                        newAdventureField.text = ""
                                        launcherWindow.selectedAdventureIndex = -1
                                    }
                                }
                                AppButton {
                                    text: "Удалить"
                                    Layout.fillWidth: true
                                    enabled: launcherWindow.selectedAdventureIndex >= 0
                                    onClicked: {
                                        var item = appController.adventuresModel[launcherWindow.selectedAdventureIndex]
                                        if (item) {
                                            appController.delete_adventure(item.name)
                                            launcherWindow.selectedAdventureIndex = -1
                                            launcherWindow.selectedSceneIndex = -1
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        color: "#22252D"
                        radius: 12
                        border.color: "#4F535D"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Label {
                                text: appController.currentAdventure ? ("Сцены: " + appController.currentAdventure) : "Сцены"
                                color: launcherWindow.textPrimary
                                font.pixelSize: 18
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Item { Layout.fillWidth: true }
                                IconButton {
                                    glyph: "+"
                                    toolTip: "Создать сцену"
                                    enabled: appController.currentAdventure.length > 0
                                    opacity: enabled ? 1.0 : 0.45
                                    onClicked: launcherWindow.openCreateSceneDialog()
                                }
                            }

                            ListView {
                                id: scenesView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 4
                                boundsBehavior: Flickable.StopAtBounds
                                model: appController.scenesModel
                                currentIndex: launcherWindow.selectedSceneIndex
                                ScrollBar.vertical: AppScrollBar {}
                                delegate: Item {
                                    id: sceneDelegate
                                    width: scenesView.width
                                    height: 38
                                    property bool hovered: hoverHandler.hovered
                                    property real dragY: 0
                                    property real dragDeltaY: 0

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 9
                                        color: ListView.isCurrentItem
                                            ? "#535660"
                                            : (sceneDelegate.hovered ? "#3B3E47" : "transparent")
                                        border.width: ListView.isCurrentItem ? 1 : 0
                                        border.color: "#B8BAC2"
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Translate {
                                        id: dragTranslate
                                        y: sceneDelegate.dragY
                                    }
                                    transform: [dragTranslate]
                                    z: dragHandler.active ? 20 : 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            color: ListView.isCurrentItem ? "#F2F2F4" : "#CFD1D8"
                                            font.pixelSize: 14
                                            font.weight: ListView.isCurrentItem ? Font.DemiBold : Font.Normal
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Item {
                                            Layout.preferredWidth: 54
                                            Layout.fillHeight: true
                                            visible: sceneDelegate.hovered || ListView.isCurrentItem

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                IconButton {
                                                    iconSource: "icons/scene_edit.svg"
                                                    toolTip: "Изменить сцену"
                                                    onClicked: {
                                                        launcherWindow.selectedSceneIndex = index
                                                        launcherWindow.openEditSceneDialog()
                                                    }
                                                }
                                                IconButton {
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
                                            // Compute target index from visual center of dragged row.
                                            // This is more stable than indexAt/mapToItem with translated delegates.
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

                            RowLayout {
                                Layout.fillWidth: true
                                visible: false
                                AppButton {
                                    text: "Новая"
                                    accent: true
                                    Layout.fillWidth: true
                                    enabled: appController.currentAdventure.length > 0
                                    onClicked: launcherWindow.openCreateSceneDialog()
                                }
                                AppButton {
                                    text: "Изменить"
                                    Layout.fillWidth: true
                                    enabled: launcherWindow.selectedSceneIndex >= 0
                                    onClicked: launcherWindow.openEditSceneDialog()
                                }
                                AppButton {
                                    text: "Удалить"
                                    Layout.fillWidth: true
                                    enabled: launcherWindow.selectedSceneIndex >= 0
                                    onClicked: {
                                        var item = appController.scenesModel[launcherWindow.selectedSceneIndex]
                                        if (item) {
                                            appController.delete_scene(item.name)
                                            launcherWindow.selectedSceneIndex = -1
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: false
                                AppButton {
                                    text: "Вверх"
                                    Layout.fillWidth: true
                                    enabled: launcherWindow.selectedSceneIndex > 0
                                    onClicked: {
                                        var item = appController.scenesModel[launcherWindow.selectedSceneIndex]
                                        if (item) {
                                            appController.move_scene(item.name, -1)
                                            launcherWindow.selectedSceneIndex = Math.max(0, launcherWindow.selectedSceneIndex - 1)
                                        }
                                    }
                                }
                                AppButton {
                                    text: "Вниз"
                                    Layout.fillWidth: true
                                    enabled: launcherWindow.selectedSceneIndex >= 0 && launcherWindow.selectedSceneIndex < appController.scenesModel.length - 1
                                    onClicked: {
                                        var item = appController.scenesModel[launcherWindow.selectedSceneIndex]
                                        if (item) {
                                            appController.move_scene(item.name, 1)
                                            launcherWindow.selectedSceneIndex = Math.min(appController.scenesModel.length - 1, launcherWindow.selectedSceneIndex + 1)
                                        }
                                    }
                                }
                                AppButton {
                                    text: "Открыть"
                                    accent: true
                                    Layout.fillWidth: true
                                    enabled: launcherWindow.selectedSceneIndex >= 0
                                    onClicked: {
                                        var item = appController.scenesModel[launcherWindow.selectedSceneIndex]
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
        x: (launcherWindow.width - width) / 2
        y: 40
        width: Math.min(launcherWindow.width - 40, 560)
        height: Math.min(launcherWindow.height - 80, 700)
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
            color: "#262830"
            border.color: "#626876"
            border.width: 1
            radius: 12
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#2E323C" }
                GradientStop { position: 1.0; color: "#252932" }
            }
        }

        contentItem: ScrollView {
            clip: true
            ScrollBar.vertical: AppScrollBar {}
            ColumnLayout {
                width: sceneDialog.width - 32
                x: 12
                y: 12
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

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#4C505A" }

                Label { text: "Медиа карты"; color: launcherWindow.textPrimary }
                AppComboBox {
                    id: sceneMapType
                    model: ["color", "image", "video"]
                    Layout.fillWidth: true
                }
                MediaDropTile {
                    id: sceneMapDrop
                    Layout.fillWidth: true
                    mediaType: sceneMapType.currentText
                    previewValue: sceneMapValue.text
                    fallbackColor: "#2E2E2E"
                    placeholderText: "Кликните, Ctrl+V, перетащите или двойной клик"
                    onDropValue: function(value) {
                        sceneMapValue.text = value
                        launcherWindow.applyDetectedMediaType(value, sceneMapType)
                    }
                    onPasteRequest: {
                        var pastedMap = appController.paste_media_value("map")
                        sceneMapValue.text = pastedMap
                        launcherWindow.applyDetectedMediaType(pastedMap, sceneMapType)
                    }
                    onBrowseRequest: {
                        launcherWindow.pendingFileTarget = "map"
                        mediaFileDialog.open()
                    }
                }

                AppTextField {
                    id: sceneMapValue
                    Layout.fillWidth: true
                    placeholderText: sceneMapType.currentText === "color" ? "#2E2E2E" : "Путь / URL"
                }
                RowLayout {
                    Layout.fillWidth: true
                    AppCheckBox { id: sceneMapAutoplay; text: "Авто"; checked: true }
                    AppCheckBox { id: sceneMapLoop; text: "Цикл"; checked: true }
                    AppCheckBox { id: sceneMapMute; text: "Без звука"; checked: true }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#4C505A" }

                Label { text: "Медиа фона"; color: launcherWindow.textPrimary }
                AppComboBox {
                    id: sceneBgType
                    model: ["color", "image", "video"]
                    Layout.fillWidth: true
                }
                MediaDropTile {
                    id: sceneBgDrop
                    Layout.fillWidth: true
                    mediaType: sceneBgType.currentText
                    previewValue: sceneBgValue.text
                    fallbackColor: "#1F1F1F"
                    placeholderText: "Кликните, Ctrl+V, перетащите или двойной клик"
                    onDropValue: function(value) {
                        sceneBgValue.text = value
                        launcherWindow.applyDetectedMediaType(value, sceneBgType)
                    }
                    onPasteRequest: {
                        var pastedBg = appController.paste_media_value("background")
                        sceneBgValue.text = pastedBg
                        launcherWindow.applyDetectedMediaType(pastedBg, sceneBgType)
                    }
                    onBrowseRequest: {
                        launcherWindow.pendingFileTarget = "background"
                        mediaFileDialog.open()
                    }
                }

                AppTextField {
                    id: sceneBgValue
                    Layout.fillWidth: true
                    placeholderText: sceneBgType.currentText === "color" ? "#1F1F1F" : "Путь / URL"
                }
                RowLayout {
                    Layout.fillWidth: true
                    AppCheckBox { id: sceneBgAutoplay; text: "Авто"; checked: true }
                    AppCheckBox { id: sceneBgLoop; text: "Цикл"; checked: true }
                    AppCheckBox { id: sceneBgMute; text: "Без звука"; checked: true }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#4C505A" }

                Label { text: "Гекс-сетка"; color: launcherWindow.textPrimary }
                Label { text: "Размер клетки (ft)"; color: launcherWindow.textSecondary }
                AppTextField { id: sceneGridSize; Layout.fillWidth: true; text: "5.00" }
                Label { text: "Толщина линии (px)"; color: launcherWindow.textSecondary }
                AppTextField { id: sceneGridThickness; Layout.fillWidth: true; text: "1.50" }
                Label { text: "Прозрачность (0..1)"; color: launcherWindow.textSecondary }
                AppTextField { id: sceneGridOpacity; Layout.fillWidth: true; text: "0.45" }
                Label { text: "Цвет сетки"; color: launcherWindow.textSecondary }
                AppTextField { id: sceneGridColor; Layout.fillWidth: true; text: "#9DA6B0" }

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
            color: "#262830"
            border.color: "#626876"
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
                sceneBgValue.text = selected
                launcherWindow.applyDetectedMediaType(selected, sceneBgType)
            } else {
                sceneMapValue.text = selected
                launcherWindow.applyDetectedMediaType(selected, sceneMapType)
            }
        }
    }

    component AppScrollBar: ScrollBar {
        id: control
        policy: ScrollBar.AsNeeded
        active: hovered || pressed || visualSize < 1.0
        hoverEnabled: true
        implicitWidth: 10

        contentItem: Rectangle {
            implicitWidth: 6
            radius: 3
            color: control.pressed
                ? "#AEB4C2"
                : (control.hovered ? "#979EAD" : "#747B89")
            opacity: control.active ? 0.95 : 0.65
            Behavior on color { ColorAnimation { duration: 110 } }
            Behavior on opacity { NumberAnimation { duration: 110 } }
        }

        background: Rectangle {
            implicitWidth: 10
            radius: 5
            color: "#20232B"
            border.width: 1
            border.color: "#3F4552"
            opacity: control.active ? 0.9 : 0.55
            Behavior on opacity { NumberAnimation { duration: 110 } }
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
                ctx.fillStyle = "#C6CAD4"
                ctx.fill()
            }
        }

        background: Rectangle {
            radius: 10
            color: "#23262E"
            border.width: 1
            border.color: control.activeFocus ? "#A7ABB6" : (control.hovered ? "#707681" : "#4D515C")
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
                color: highlighted ? "#F4F5F7" : "#D1D4DC"
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font.pixelSize: 13
            }
            highlighted: control.highlightedIndex === index
            background: Rectangle {
                radius: 8
                color: parent.highlighted ? "#545A66" : (parent.hovered ? "#3A3F49" : "transparent")
            }
        }

        popup: Popup {
            y: control.height + 6
            width: control.width
            padding: 4
            implicitHeight: Math.min(contentItem.implicitHeight + 8, 220)
            background: Rectangle {
                radius: 10
                color: "#252933"
                border.width: 1
                border.color: "#59606C"
            }
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: control.popup.visible ? control.delegateModel : null
                currentIndex: control.highlightedIndex
                ScrollBar.vertical: AppScrollBar {}
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
            color: control.checked ? "#6D7482" : "#252931"
            border.width: 1
            border.color: control.checked ? "#C1C6D1" : (control.hovered ? "#7A8190" : "#545B68")
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
        width: 430
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
            color: "#1F2128"
            border.color: "#606675"
            border.width: 1
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#252A34" }
                GradientStop { position: 1.0; color: "#1C2028" }
            }
        }

        ScrollView {
            anchors.fill: parent
            clip: true
            ScrollBar.vertical: AppScrollBar {}

            ColumnLayout {
                width: settingsDrawer.width - 24
                x: 12
                y: 12
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
                    color: "#4C505A"
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
                    color: "#4C505A"
                }

                Label { text: "Карта по умолчанию"; color: launcherWindow.textPrimary }
                AppComboBox {
                    id: mapTypeCombo
                    model: ["color", "image", "video"]
                    currentIndex: launcherWindow.mediaIndex(appController.mapMediaType)
                    Layout.fillWidth: true
                }
                AppTextField {
                    id: mapValueField
                    text: appController.mapMediaValue
                    placeholderText: mapTypeCombo.currentText === "color" ? "#2E2E2E" : "Путь или URL"
                    Layout.fillWidth: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    AppCheckBox { id: mapAutoplay; text: "Авто"; checked: appController.mapMediaAutoplay }
                    AppCheckBox { id: mapLoop; text: "Цикл"; checked: appController.mapMediaLoop }
                    AppCheckBox { id: mapMute; text: "Без звука"; checked: appController.mapMediaMute }
                }
                AppButton {
                    text: "Применить карту"
                    accent: true
                    onClicked: {
                        appController.update_media("map", mapTypeCombo.currentText, mapValueField.text)
                        appController.update_playback("map", mapAutoplay.checked, mapLoop.checked, mapMute.checked)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#4C505A"
                }

                Label { text: "Фон по умолчанию"; color: launcherWindow.textPrimary }
                AppComboBox {
                    id: bgTypeCombo
                    model: ["color", "image", "video"]
                    currentIndex: launcherWindow.mediaIndex(appController.backgroundMediaType)
                    Layout.fillWidth: true
                }
                AppTextField {
                    id: bgValueField
                    text: appController.backgroundMediaValue
                    placeholderText: bgTypeCombo.currentText === "color" ? "#1F1F1F" : "Путь или URL"
                    Layout.fillWidth: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    AppCheckBox { id: bgAutoplay; text: "Авто"; checked: appController.backgroundMediaAutoplay }
                    AppCheckBox { id: bgLoop; text: "Цикл"; checked: appController.backgroundMediaLoop }
                    AppCheckBox { id: bgMute; text: "Без звука"; checked: appController.backgroundMediaMute }
                }
                AppButton {
                    text: "Применить фон"
                    accent: true
                    onClicked: {
                        appController.update_media("background", bgTypeCombo.currentText, bgValueField.text)
                        appController.update_playback("background", bgAutoplay.checked, bgLoop.checked, bgMute.checked)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#4C505A"
                }

                Label { text: "Сетка по умолчанию"; color: launcherWindow.textPrimary }
                Label { text: "Размер клетки (ft)"; color: launcherWindow.textSecondary }
                AppTextField {
                    id: cellSizeField
                    text: Number(appController.gridCellSizeFt).toFixed(2)
                    Layout.fillWidth: true
                }
                Label { text: "Толщина линии (px)"; color: launcherWindow.textSecondary }
                AppTextField {
                    id: lineThicknessField
                    text: Number(appController.gridLineThicknessPx).toFixed(2)
                    Layout.fillWidth: true
                }
                Label { text: "Прозрачность сетки (0..1)"; color: launcherWindow.textSecondary }
                AppTextField {
                    id: opacityField
                    text: Number(appController.gridOpacity).toFixed(2)
                    Layout.fillWidth: true
                }
                Label { text: "Цвет сетки"; color: launcherWindow.textSecondary }
                AppTextField {
                    id: gridColorField
                    text: appController.gridColor
                    Layout.fillWidth: true
                }
                AppButton {
                    text: "Применить сетку"
                    accent: true
                    onClicked: appController.update_grid(
                                   Number(cellSizeField.text),
                                   Number(lineThicknessField.text),
                                   Number(opacityField.text),
                                   gridColorField.text)
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#4C505A"
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
