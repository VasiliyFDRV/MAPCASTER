import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtMultimedia

Window {
    id: backgroundWindow
    width: 1280
    height: 720
    visible: true
    color: "#111215"
    title: "DnD Maps - Р¤РѕРЅ"

    function toggleFullscreenMode() {
        visibility = visibility === Window.FullScreen ? Window.Windowed : Window.FullScreen
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#1A1C21" }
            GradientStop { position: 1.0; color: "#0F1014" }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: opacity > 0
        opacity: appController.activeBackgroundEnabled && appController.activeBackgroundMediaType === "color" ? 1.0 : 0.0
        color: appController.activeBackgroundFillColor
        Behavior on opacity {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }
    }

    Image {
        id: backgroundImageLayer
        anchors.fill: parent
        visible: opacity > 0
        opacity: appController.activeBackgroundEnabled && appController.activeBackgroundMediaType === "image" ? 1.0 : 0.0
        source: appController.activeBackgroundEnabled && appController.activeBackgroundMediaType === "image" ? appController.activeBackgroundMediaSource : ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        Behavior on opacity {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }
    }

    MediaPlayer {
        id: backgroundPlayer
        source: appController.activeBackgroundEnabled && appController.activeBackgroundMediaType === "video" ? appController.activeBackgroundMediaSource : ""
        loops: appController.activeBackgroundMediaLoop ? MediaPlayer.Infinite : 1
        autoPlay: appController.activeBackgroundEnabled && appController.activeBackgroundMediaAutoplay && appController.activeBackgroundMediaType === "video"
        videoOutput: backgroundVideoLayer
        // Avoid attaching audio pipeline while muted to reduce noisy ffmpeg audio warnings.
        audioOutput: appController.activeBackgroundMediaMute ? null : backgroundAudioOutput
        onErrorOccurred: function(error, errorString) {
            if (error !== MediaPlayer.NoError) {
                stop()
                console.warn("РћС€РёР±РєР° С„РѕРЅРѕРІРѕРіРѕ РІРёРґРµРѕ:", errorString)
            }
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia) {
                stop()
            }
        }
    }

    AudioOutput {
        id: backgroundAudioOutput
        muted: false
        volume: 1.0
    }

    VideoOutput {
        id: backgroundVideoLayer
        anchors.fill: parent
        visible: opacity > 0
        opacity: appController.activeBackgroundEnabled && appController.activeBackgroundMediaType === "video" ? 1.0 : 0.0
        fillMode: VideoOutput.PreserveAspectCrop
        Behavior on opacity {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#4B4F58"
        border.width: 1
        opacity: 0.45
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.1
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 0.75; color: "#00000000" }
            GradientStop { position: 1.0; color: "#77000000" }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onDoubleClicked: {
            if (mouse.button === Qt.LeftButton) {
                backgroundWindow.toggleFullscreenMode()
            }
        }
    }

    Label {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 14
        anchors.topMargin: 10
        color: "#DADCE2"
        text: appController.currentScene.length > 0 ? ("РЎС†РµРЅР°: " + appController.currentScene) : "РЎС†РµРЅР°: РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ"
        font.pixelSize: 13
        opacity: 0.72
    }

    Connections {
        target: appController
        function onSceneViewChanged() {
            if (appController.activeBackgroundEnabled && appController.activeBackgroundMediaType === "video"
                    && appController.activeBackgroundMediaAutoplay
                    && backgroundPlayer.source
                    && backgroundPlayer.source.toString().length > 0) {
                backgroundPlayer.play()
            } else {
                backgroundPlayer.stop()
            }
        }
    }
}
