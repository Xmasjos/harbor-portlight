import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: tableBlock
    property var block
    property var renderInline
    property int rowHeight: Theme.itemSizeSmall
    implicitHeight: tableColumn.childrenRect.height
    signal activated()
    signal linkActivated(string url)
    Column {
        id: tableColumn
        x: Theme.horizontalPageMargin
        width: tableBlock.width - 2 * Theme.horizontalPageMargin
        Repeater {
            model: tableBlock.block ? tableBlock.block.rows : []
            delegate: Item {
                id: tableRow
                property var cells: modelData
                property int rowIndex: index
                width: tableColumn.width
                height: Math.max(tableBlock.rowHeight, cellRow.contentHeight)
                implicitHeight: height
                Row {
                    id: cellRow
                    property real contentHeight: tableBlock.rowHeight
                    width: parent.width
                    height: parent.height

                    function updateContentHeight() {
                        var tallest = tableBlock.rowHeight
                        for (var i = 0; i < cellRepeater.count; i++) {
                            var cell = cellRepeater.itemAt(i)
                            if (cell) tallest = Math.max(tallest, cell.implicitHeight)
                        }
                        contentHeight = tallest
                    }

                    Repeater {
                        id: cellRepeater
                        model: cells
                        delegate: Label {
                            width: cells.length ? cellRow.width / cells.length : 0
                            height: implicitHeight
                            text: tableBlock.renderInline ? tableBlock.renderInline(modelData) : modelData
                            textFormat: Text.RichText
                            color: tableRow.rowIndex === 0 ? Theme.primaryColor : Theme.secondaryColor
                            font.bold: tableRow.rowIndex === 0
                            wrapMode: Text.Wrap
                            verticalAlignment: Text.AlignVCenter
                            onLinkActivated: tableBlock.linkActivated(link)
                            onImplicitHeightChanged: cellRow.updateContentHeight()
                        }
                        onItemAdded: cellRow.updateContentHeight()
                    }
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.secondaryColor
                    opacity: 0.35
                }
                MouseArea { z: -1; anchors.fill: parent; onClicked: tableBlock.activated() }
            }
        }
    }
}
