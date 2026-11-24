import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: listBlock

    property var block
    property var renderInline
    implicitHeight: listColumn.implicitHeight

    signal activated()
    signal taskToggled(int itemIndex)
    signal linkActivated(string url)

    function marker(itemIndex) {
        var item = block.items[itemIndex]
        if (!item.ordered) return "-"
        var counter = 0
        for (var i = 0; i <= itemIndex; i++) {
            var previous = block.items[i]
            if (previous.indent !== item.indent) continue
            counter = previous.ordered ? counter + 1 : 0
        }
        return counter + "."
    }

    Column {
        id: listColumn
        x: Theme.horizontalPageMargin
        width: listBlock.width - Theme.horizontalPageMargin * 2

        Repeater {
            model: listBlock.block ? listBlock.block.items : []

            delegate: Item {
                id: listRow
                property var listItem: modelData
                property int itemIndex: index
                property real markerSize: Theme.fontSizeLarge
                property bool checklist: listItem.taskState !== null
                width: listColumn.width
                height: checklist ? checklistItem.implicitHeight
                                  : Math.max(markerSize, rowText.implicitHeight)

                Item {
                    x: listRow.listItem.indent * Theme.paddingLarge
                    width: listRow.markerSize
                    height: listRow.height
                    visible: !listRow.checklist

                    Label {
                        anchors.fill: parent
                        text: listBlock.marker(listRow.itemIndex)
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Label {
                    id: rowText
                    visible: !listRow.checklist
                    x: listRow.listItem.indent * Theme.paddingLarge
                       + listRow.markerSize + Theme.paddingSmall
                    width: listRow.width - x
                    text: listBlock.renderInline
                          ? listBlock.renderInline(listRow.listItem.text) : ""
                    textFormat: Text.RichText
                    color: Theme.primaryColor
                    wrapMode: Text.Wrap
                    onLinkActivated: listBlock.linkActivated(link)
                }

                MouseArea {
                    anchors.fill: rowText
                    visible: rowText.visible
                    onClicked: listBlock.activated()
                }

                ChecklistItem {
                    id: checklistItem
                    visible: listRow.checklist
                    x: listRow.listItem.indent * Theme.paddingLarge
                    width: listRow.width - x
                    itemText: listRow.listItem.text
                    checked: listRow.listItem.taskState === "x"
                    renderInline: listBlock.renderInline
                    onToggled: listBlock.taskToggled(listRow.itemIndex)
                    onActivated: listBlock.activated()
                    onLinkActivated: listBlock.linkActivated(url)
                }
            }
        }
    }
}
