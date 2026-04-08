import QtQuick

Item {
    id: toggleRoot
    property var theme
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
        color: toggleRoot.checked
            ? (toggleRoot.theme ? toggleRoot.theme.toggleTrackCheckedColor : "#646464")
            : (toggleRoot.theme ? toggleRoot.theme.toggleTrackColor : "#353535")
        border.width: 1
        border.color: toggleRoot.checked
            ? (toggleRoot.theme ? toggleRoot.theme.toggleTrackCheckedBorderColor : "#A8A8A8")
            : (toggleRoot.theme ? toggleRoot.theme.toggleTrackBorderColor : "#5C5C5C")
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
        color: toggleRoot.theme ? toggleRoot.theme.toggleKnobColor : "#EAEAEA"
        border.width: 1
        border.color: toggleRoot.theme ? toggleRoot.theme.toggleKnobBorderColor : "#B2B2B2"
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
