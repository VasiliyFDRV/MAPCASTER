import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "neumo"

FocusScope {
    id: root
    clip: true

    implicitHeight: compactMode ? 154 : 222
    implicitWidth: 280

    property var theme
    property bool compactMode: false
    property string mediaType: "color"
    property string previewValue: ""
    property string previewSourceUrl: previewSource(previewValue)
    property color fallbackColor: "#2A2A2A"
    property string placeholderText: "\u041f\u0435\u0440\u0435\u0442\u0430\u0449\u0438\u0442\u0435 \u0444\u0430\u0439\u043b, Ctrl+V \u0438\u043b\u0438 \u0434\u0432\u043e\u0439\u043d\u043e\u0439 \u043a\u043b\u0438\u043a"
    property string valuePlaceholderText: mediaType === "color" ? "#2E2E2E" : "\u041f\u0443\u0442\u044c \u0438\u043b\u0438 URL"
    property string helperText: "Ctrl+V, drag and drop, double click"
    property string effectiveType: inferTypeFromValue(previewValue, mediaType)
    property bool videoPreviewReady: false
    property bool videoPreviewPrimed: false

    signal dropValue(string value)
    signal pasteRequest()
    signal browseRequest()
    signal valueEdited(string value)
    signal colorRequest()

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
        if (effectiveType !== "video" || previewSourceUrl.length === 0 || videoPreviewPrimed) {
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
        if (!valueField.activeFocus) {
            valueField.text = String(previewValue || "")
        }
    }

    onEffectiveTypeChanged: {
        videoPreviewReady = false
        videoPreviewPrimed = false
        if (effectiveType !== "video") {
            previewPlayer.stop()
        }
    }

    onPreviewValueChanged: {
        if (!valueField.activeFocus) {
            valueField.text = String(previewValue || "")
        }
    }

    NeumoInsetSurface {
        anchors.fill: parent
        theme: root.theme
        radius: compactMode ? 16 : 18
        fillColor: theme ? theme.baseColor : "#2D2D2D"
        contentPadding: compactMode ? 9 : 12

        ColumnLayout {
            anchors.fill: parent
            spacing: compactMode ? 7 : 10

            NeumoRaisedSurface {
                id: previewTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: compactMode ? 80 : 136
                Layout.preferredHeight: compactMode ? 88 : 150
                theme: root.theme
                radius: compactMode ? 14 : 16
                fillColor: theme ? theme.baseColor : "#2D2D2D"
                shadowOffset: compactMode ? 2.6 : 4.4
                shadowRadius: compactMode ? 5.8 : 9.4
                shadowSamples: 21

                Rectangle {
                    anchors.fill: parent
                    radius: compactMode ? 14 : 16
                    clip: true
                    color: theme ? theme.mediaTilePreviewFillColor : "#1E1F22"
                    border.width: 1
                    border.color: theme ? theme.mediaTilePreviewStrokeColor : "#41444B"

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
                        color: theme ? theme.mediaTilePreviewFillColor : "#1E1F22"

                        VideoOutput {
                            id: previewVideoOutput
                            anchors.fill: parent
                            fillMode: VideoOutput.PreserveAspectCrop
                            visible: root.videoPreviewReady
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "VIDEO"
                            color: root.theme ? root.theme.mediaTileValueTextColor : "#D0D0D0"
                            font.pixelSize: compactMode ? 12 : 14
                            font.weight: Font.DemiBold
                            visible: !root.videoPreviewReady
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: String(root.previewValue || "").length === 0
                        color: theme ? theme.mediaTileEmptyFillColor : "#1A1B1E"

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            text: root.placeholderText
                            color: root.theme ? root.theme.mediaTileHintColor : "#909090"
                            font.pixelSize: compactMode ? 11 : 12
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
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
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: compactMode ? 6 : 8

                NeumoTextField {
                    id: valueField
                    theme: root.theme
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: String(root.previewValue || "")
                    placeholderText: root.valuePlaceholderText
                    onEditingFinished: root.valueEdited(text)
                    onAccepted: root.valueEdited(text)
                }

                NeumoUtilityIconButton {
                    theme: root.theme
                    width: compactMode ? 28 : 30
                    height: compactMode ? 28 : 30
                    iconSource: Qt.resolvedUrl("../icons/palette.svg")
                    toolTip: "\u0412\u044b\u0431\u0440\u0430\u0442\u044c \u0446\u0432\u0435\u0442"
                    onClicked: root.colorRequest()
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.helperText.length > 0
                text: root.helperText
                color: root.theme ? root.theme.mediaTileHintColor : "#909090"
                font.pixelSize: compactMode ? 10 : 11
                wrapMode: Text.WordWrap
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

        onErrorOccurred: function(error) {
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
