import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    id: entryDelegate
    property var entry
    property bool searchActive: false
    property string iconName: ""
    property var renameCallback
    property var copyCallback
    property var moveCallback
    property var deleteCallback
    property var activateCallback

    contentHeight: resultColumn.height + 2 * Theme.paddingMedium

    menu: ContextMenu {
        MenuItem {
            text: "Rename"
            onClicked: entryDelegate.renameCallback(entryDelegate.entry)
        }
        MenuItem {
            text: "Copy"
            onClicked: entryDelegate.copyCallback(entryDelegate.entry)
        }
        MenuItem {
            text: "Move"
            onClicked: entryDelegate.moveCallback(entryDelegate.entry)
        }
        MenuItem {
            text: "Delete"
            onClicked: {
                var entry = entryDelegate.entry
                entryDelegate.remorseDelete(function() {
                    entryDelegate.deleteCallback(entry)
                })
            }
        }
    }

    Column {
        id: resultColumn
        x: Theme.horizontalPageMargin + itemIcon.width + Theme.paddingMedium
        width: parent.width - x - Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        Label {
            width: parent.width
            text: entryDelegate.searchActive ? entryDelegate.entry.path : entryDelegate.entry.name
            truncationMode: TruncationMode.Fade
            color: entryDelegate.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
        Label {
            width: parent.width
            text: entryDelegate.entry.excerpt || ""
            visible: text.length > 0
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            truncationMode: TruncationMode.Fade
        }
    }

    Image {
        id: itemIcon
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.iconSizeMedium
        height: Theme.iconSizeMedium
        source: "image://theme/" + entryDelegate.iconName
                + "?" + (entryDelegate.highlighted ? Theme.highlightColor : Theme.primaryColor)
    }

    onClicked: entryDelegate.activateCallback(entryDelegate.entry)
}
