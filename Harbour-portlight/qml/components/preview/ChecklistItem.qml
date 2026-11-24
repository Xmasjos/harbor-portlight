import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: checklistItem

    property string itemText
    property bool checked
    property var renderInline
    property real markerSize: Theme.fontSizeLarge
    implicitHeight: Math.max(markerSize, itemLabel.implicitHeight)
    height: implicitHeight

    signal toggled()
    signal activated()
    signal linkActivated(string url)

    Rectangle {
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: checklistItem.markerSize - 4
        height: width
        color: "transparent"
        border.color: Theme.primaryColor
        border.width: 2
        radius: 3

        Label {
            anchors.centerIn: parent
            visible: checklistItem.checked
            text: "✓"
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: checklistItem.toggled()
        }
    }

    Label {
        id: itemLabel
        x: checklistItem.markerSize + Theme.paddingSmall
        width: checklistItem.width - x
        text: checklistItem.renderInline
              ? (checklistItem.checked
                 ? "<s>" + checklistItem.renderInline(checklistItem.itemText) + "</s>"
                 : checklistItem.renderInline(checklistItem.itemText))
              : ""
        textFormat: Text.RichText
        color: Theme.primaryColor
        wrapMode: Text.Wrap
        onLinkActivated: checklistItem.linkActivated(link)
    }

    MouseArea {
        anchors.fill: itemLabel
        onClicked: checklistItem.activated()
    }
}
