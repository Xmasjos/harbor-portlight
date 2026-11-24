import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: textBlock

    property var block
    property var renderInline
    implicitHeight: displayLabel.implicitHeight

    signal activated()

    Label {
        id: displayLabel
        x: Theme.horizontalPageMargin
        width: textBlock.width - Theme.horizontalPageMargin * 2
        text: !textBlock.block.source.trim().length
              ? "Tap to add a paragraph"
              : (textBlock.renderInline
                 ? textBlock.renderInline(textBlock.block.source)
                 : "")
        textFormat: Text.RichText
        color: Theme.primaryColor
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeMedium
    }

    MouseArea {
        anchors.fill: displayLabel
        onClicked: textBlock.activated()
    }
}
