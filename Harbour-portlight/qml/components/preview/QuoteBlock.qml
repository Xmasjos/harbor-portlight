import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: quoteBlock

    property var block
    property var renderInline
    implicitHeight: quoteColumn.implicitHeight

    signal activated()

    Column {
        id: quoteColumn
        x: Theme.horizontalPageMargin
        width: quoteBlock.width - Theme.horizontalPageMargin * 2

        Repeater {
            model: quoteBlock.block ? quoteBlock.block.items : []

            delegate: Item {
                id: quoteRow
                property var quoteItem: modelData
                width: quoteColumn.width
                height: quoteText.implicitHeight

                Rectangle {
                    x: (quoteRow.quoteItem.depth - 1) * Theme.paddingLarge
                    width: 3
                    height: quoteRow.height
                    color: Theme.highlightColor
                }

                Label {
                    id: quoteText
                    x: quoteRow.quoteItem.depth * Theme.paddingLarge
                    width: quoteRow.width - x
                    text: quoteBlock.renderInline
                          ? quoteBlock.renderInline(quoteRow.quoteItem.text) : ""
                    textFormat: Text.RichText
                    color: Theme.secondaryColor
                    wrapMode: Text.Wrap
                }

                MouseArea {
                    anchors.fill: quoteRow
                    onClicked: quoteBlock.activated()
                }
            }
        }
    }
}
