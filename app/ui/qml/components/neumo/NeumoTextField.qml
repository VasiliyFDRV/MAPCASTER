import QtQuick
import QtQuick.Controls

TextField {
    id: control
    property var theme

    color: control.theme ? control.theme.textPrimary : "#D0D0D0"
    selectedTextColor: control.theme ? control.theme.fieldSelectedTextColor : "#F4F4F6"
    selectionColor: control.theme ? control.theme.fieldSelectionColor : "#6C6C6C"
    placeholderTextColor: control.theme ? control.theme.fieldPlaceholderColor : "#909090"
    padding: 10

    background: Rectangle {
        radius: 11
        color: control.theme ? control.theme.fieldBackgroundColor : "#232323"
        border.width: 1
        border.color: control.activeFocus
            ? (control.theme ? control.theme.fieldBorderFocusColor : "#ABABAB")
            : (control.hovered
                ? (control.theme ? control.theme.fieldBorderHoverColor : "#626262")
                : (control.theme ? control.theme.fieldBorderColor : "#4D4D4D"))
        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }
    }
}
