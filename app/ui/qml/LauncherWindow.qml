import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window
import "components"
import "components/MediaValueUtils.js" as MediaValueUtils
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

    property string pendingFileTarget: "map"
    property string pendingColorTarget: "map"
    property bool sceneEditorVisible: false
    property int sceneEditorOpenToken: 0
    property var sceneEditorInitialDraft: ({})
    property color bgBase: "#2D2D2D"
    property var neumoTheme: NeumoTheme { baseColor: bgBase; textPrimary: textPrimary; textSecondary: textSecondary }
    property color textPrimary: "#D0D0D0"
    property color textSecondary: "#909090"
    property real explorerEdgeInset: 12
    property int mainPreviewPoseVersion: 16

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

    Rectangle {
        anchors.fill: parent
        color: launcherWindow.bgBase

        DiceMainPreviewCacheManager {
            id: launcherDiceMainPreviewCache
            dieStyles: appController && appController.diceStyles ? appController.diceStyles : ({})
            poseVersion: launcherWindow.mainPreviewPoseVersion
            cacheDirUrl: Qt.resolvedUrl("../../../app_data/cache/dice_main_preview/")
            renderingEnabled: true
            prewarmEnabled: true
        }

        LauncherLibrarySurface {
            anchors.fill: parent
            visible: !launcherWindow.sceneEditorVisible
            theme: neumoTheme
            bgBase: launcherWindow.bgBase
            textPrimary: launcherWindow.textPrimary
            textSecondary: launcherWindow.textSecondary
            explorerEdgeInset: launcherWindow.explorerEdgeInset
            onCreateSceneRequested: launcherWindow.openCreateSceneDialog()
            onEditSceneRequested: function(sceneName) {
                launcherWindow.openEditSceneDialog(sceneName)
            }
            onSettingsRequested: settingsDrawer.open()
        }

        Item {
            anchors.fill: parent
            visible: launcherWindow.sceneEditorVisible

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 0

                NeumoInsetSurface {
                    theme: neumoTheme
                    useFrameProfile: true
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 28
                    fillColor: launcherWindow.bgBase
                    contentPadding: 18

                    SceneEditorSurface {
                        id: sceneEditorSurface
                        anchors.fill: parent
                        theme: neumoTheme
                        initialDraft: launcherWindow.sceneEditorInitialDraft
                        openToken: launcherWindow.sceneEditorOpenToken
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
    }

    Component.onCompleted: {
        appController.refresh_library()
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
            var value = MediaValueUtils.normalizeColorValue(selectedColor, "#000000")
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
