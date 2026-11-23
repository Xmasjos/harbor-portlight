import QtQuick 2.0
import Sailfish.Silica 1.0
import "TextBlock.js" as TextMatcher

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
                 ? textBlock.renderInline(textBlock.block.type === "heading"
                                          ? TextMatcher.headingText(textBlock.block.source)
                                          : textBlock.block.source)
                 : "")
        textFormat: Text.RichText
        color: Theme.primaryColor
        wrapMode: Text.Wrap
        font.pixelSize: textBlock.block.type === "heading"
                        ? headingPixelSize(textBlock.block.level)
                        : Theme.fontSizeMedium
        font.bold: textBlock.block.type === "heading"

        function headingPixelSize(level) {
            if (level <= 1) return Theme.fontSizeHuge
            if (level === 2) return Theme.fontSizeExtraLarge
            if (level === 3) return Theme.fontSizeLarge
            if (level === 4) return Theme.fontSizeMedium
            if (level === 5) return Theme.fontSizeSmall
            return Theme.fontSizeTiny
        }
    }

    MouseArea {
        anchors.fill: displayLabel
        onClicked: textBlock.activated()
    }
}
