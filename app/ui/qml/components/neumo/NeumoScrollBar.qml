import QtQuick
import QtQuick.Controls

ScrollBar {
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
