import QtQuick
import QtQuick.Controls

CheckBox {
    id: control
    property var theme

    hoverEnabled: true
    spacing: 8

    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        x: control.leftPadding
        y: (control.height - height) / 2
        radius: 5
        color: control.checked
            ? (control.theme ? control.theme.checkIndicatorCheckedColor : "#6D6D6D")
            : (control.theme ? control.theme.checkIndicatorColor : "#252931")
        border.width: 1
        border.color: control.checked
            ? (control.theme ? control.theme.checkIndicatorBorderCheckedColor : "#C1C1C1")
            : (control.hovered
                ? (control.theme ? control.theme.checkIndicatorBorderHoverColor : "#7A7A7A")
                : (control.theme ? control.theme.checkIndicatorBorderColor : "#545454"))
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Rectangle {
            anchors.centerIn: parent
            width: 8
            height: 8
            radius: 3
            visible: control.checked
            color: control.theme ? control.theme.checkIndicatorMarkColor : "#F3F4F7"
        }
    }

    contentItem: Text {
        text: control.text
        color: control.theme ? control.theme.checkTextColor : "#909090"
        leftPadding: control.indicator.width + control.spacing + 4
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 12
    }
}
