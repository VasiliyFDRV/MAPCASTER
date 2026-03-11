import QtQuick
import QtQuick.Controls
import QtMultimedia

FocusScope {
    id: root
    implicitHeight: 102
    implicitWidth: 260

    property string mediaType: "color"
    property string previewValue: ""
    property string previewSourceUrl: previewSource(previewValue)
    property color fallbackColor: "#2E2E2E"
    property string placeholderText: "Перетащите файл, Ctrl+V или двойной клик"
    property string effectiveType: inferTypeFromValue(previewValue, mediaType)
    property bool videoPreviewReady: false
    property bool videoPreviewPrimed: false

    signal dropValue(string value)
    signal pasteRequest()
    signal browseRequest()

    function previewSource(rawValue) {
        var value = String(rawValue || "").trim()
        if (value.length === 0) {
            return ""
        }
        if (value.indexOf("file://") === 0
                || value.indexOf("http://") === 0
                || value.indexOf("https://") === 0
                || value.indexOf("qrc:/") === 0) {
            return value
        }
        return "file:///" + value.replace(/\\/g, "/")
    }

    function inferTypeFromValue(rawValue, fallbackType) {
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

    function primeVideoPreview() {
        if (effectiveType !== "video" || previewSourceUrl.length === 0) {
            return
        }
        if (videoPreviewPrimed) {
            return
        }
        videoPreviewPrimed = true
        previewPlayer.play()
        pausePreviewTimer.restart()
    }

    Keys.onPressed: function(event) {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) {
            root.pasteRequest()
            event.accepted = true
        }
    }

    onPreviewSourceUrlChanged: {
        videoPreviewReady = false
        videoPreviewPrimed = false
        previewPlayer.stop()
    }

    onEffectiveTypeChanged: {
        videoPreviewReady = false
        videoPreviewPrimed = false
        if (effectiveType !== "video") {
            previewPlayer.stop()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#1E2027"
        border.width: 1
        border.color: root.activeFocus ? "#9FA7BA" : "#4C515D"

        Rectangle {
            id: previewFrame
            anchors.fill: parent
            anchors.margins: 6
            radius: 8
            clip: true
            color: "#14161B"
            border.width: 1
            border.color: "#3F444E"

            Rectangle {
                anchors.fill: parent
                visible: root.effectiveType === "color"
                color: String(root.previewValue || "").length > 0 ? root.previewValue : root.fallbackColor
            }

            Image {
                anchors.fill: parent
                visible: root.effectiveType === "image" && String(root.previewValue || "").length > 0
                fillMode: Image.PreserveAspectCrop
                source: visible ? root.previewSource(root.previewValue) : ""
                smooth: true
                asynchronous: true
                cache: false
            }

            Rectangle {
                anchors.fill: parent
                visible: root.effectiveType === "video" && String(root.previewValue || "").length > 0
                color: "#111318"

                VideoOutput {
                    id: previewVideoOutput
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectCrop
                    visible: root.videoPreviewReady
                }

                Text {
                    anchors.centerIn: parent
                    text: "VIDEO"
                    color: "#C8CCD7"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    visible: !root.videoPreviewReady
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: String(root.previewValue || "").length === 0
                color: "#171920"

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 20
                    text: root.placeholderText
                    color: "#8F94A1"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 24
                color: "#101218"
                opacity: 0.86
                visible: String(root.previewValue || "").length > 0

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    text: String(root.previewValue || "")
                    color: "#D6D9E1"
                    elide: Text.ElideMiddle
                    font.pixelSize: 11
                }
            }
        }

        DropArea {
            anchors.fill: parent
            onDropped: function(drop) {
                if (!drop || !drop.urls || drop.urls.length === 0) {
                    return
                }
                root.forceActiveFocus()
                root.dropValue(drop.urls[0].toString())
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.forceActiveFocus()
            onDoubleClicked: {
                root.forceActiveFocus()
                root.browseRequest()
            }
        }
    }

    MediaPlayer {
        id: previewPlayer
        source: root.effectiveType === "video" ? root.previewSourceUrl : ""
        autoPlay: false
        loops: 1
        videoOutput: previewVideoOutput

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
                root.primeVideoPreview()
            } else if (mediaStatus === MediaPlayer.InvalidMedia || mediaStatus === MediaPlayer.NoMedia) {
                root.videoPreviewReady = false
            }
        }

        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.PlayingState) {
                root.videoPreviewReady = true
            }
        }

        onErrorOccurred: function(error, errorString) {
            if (error !== MediaPlayer.NoError) {
                root.videoPreviewReady = false
                stop()
            }
        }
    }

    Timer {
        id: pausePreviewTimer
        interval: 140
        repeat: false
        onTriggered: {
            if (root.effectiveType !== "video") {
                return
            }
            previewPlayer.pause()
            previewPlayer.position = 0
            root.videoPreviewReady = true
        }
    }
}
