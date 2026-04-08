import QtQuick
import QtQuick.Controls

ComboBox {
    id: control
    property var theme

    implicitHeight: 36
    font.pixelSize: 13
    leftPadding: 10
    rightPadding: 28

    contentItem: Text {
        text: control.displayText
        color: control.theme ? control.theme.comboTextColor : "#D0D0D0"
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
            ctx.fillStyle = control.theme ? control.theme.comboIndicatorColor : "#C6C6C6"
            ctx.fill()
        }
    }

    background: Rectangle {
        radius: 10
        color: control.theme ? control.theme.comboBackgroundColor : "#232323"
        border.width: 1
        border.color: control.activeFocus
            ? (control.theme ? control.theme.comboBorderFocusColor : "#A7A7A7")
            : (control.hovered
                ? (control.theme ? control.theme.comboBorderHoverColor : "#707070")
                : (control.theme ? control.theme.comboBorderColor : "#4D4D4D"))
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
            color: highlighted
                ? (control.theme ? control.theme.comboDelegateHighlightTextColor : "#F4F5F7")
                : (control.theme ? control.theme.comboDelegateTextColor : "#D1D1D1")
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            font.pixelSize: 13
        }
        highlighted: control.highlightedIndex === index
        background: Rectangle {
            radius: 8
            color: parent.highlighted
                ? (control.theme ? control.theme.comboDelegateHighlightColor : "#545454")
                : (parent.hovered ? (control.theme ? control.theme.comboDelegateHoverColor : "#3A3A3A") : "transparent")
        }
    }

    popup: Popup {
        y: control.height + 6
        width: control.width
        padding: 4
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 220)
        background: Rectangle {
            radius: 10
            color: control.theme ? control.theme.comboPopupColor : "#252525"
            border.width: 1
            border.color: control.theme ? control.theme.comboPopupBorderColor : "#595959"
        }
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollBar.vertical: NeumoScrollBar {}
        }
    }
}
