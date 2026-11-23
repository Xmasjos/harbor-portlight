import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: listBlock

    property var block
    property var renderInline
    implicitHeight: listColumn.implicitHeight

    signal activated()
    signal taskToggled(int itemIndex)

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
                width: listColumn.width
                height: Math.max(markerSize, rowText.implicitHeight)

                Item {
                    x: listRow.listItem.indent * Theme.paddingLarge
                    width: listRow.markerSize
                    height: listRow.height

                    Label {
                        anchors.fill: parent
                        visible: listRow.listItem.taskState === null
                        text: listBlock.marker(listRow.itemIndex)
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        visible: listRow.listItem.taskState !== null
                        width: listRow.markerSize - 4
                        height: width
                        color: "transparent"
                        border.color: Theme.primaryColor
                        border.width: 2
                        radius: 3

                        Label {
                            anchors.centerIn: parent
                            visible: listRow.listItem.taskState === "x"
                            text: "✓"
                            color: Theme.primaryColor
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: listBlock.taskToggled(listRow.itemIndex)
                        }
                    }
                }

                Label {
                    id: rowText
                    x: listRow.listItem.indent * Theme.paddingLarge
                       + listRow.markerSize + Theme.paddingSmall
                    width: listRow.width - x
                    text: listBlock.renderInline
                          ? (listRow.listItem.taskState === "x"
                             ? "<s>" + listBlock.renderInline(listRow.listItem.text) + "</s>"
                             : listBlock.renderInline(listRow.listItem.text))
                          : ""
                    textFormat: Text.RichText
                    color: Theme.primaryColor
                    wrapMode: Text.Wrap
                }

                MouseArea {
                    anchors.fill: rowText
                    onClicked: listBlock.activated()
                }
            }
        }
    }
}
