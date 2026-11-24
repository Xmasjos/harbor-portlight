import QtQuick 2.0
import Sailfish.Silica 1.0
import "HeadingBlock.js" as HeadingMatcher

Item {
    id: headingBlock

    property var block
    property var renderInline
    implicitHeight: headingLabel.implicitHeight

    signal activated()
    signal linkActivated(string url)

    Label {
        id: headingLabel
        x: Theme.horizontalPageMargin
        width: headingBlock.width - Theme.horizontalPageMargin * 2
        text: headingBlock.renderInline
              ? headingBlock.renderInline(HeadingMatcher.headingText(headingBlock.block.source))
              : ""
        textFormat: Text.RichText
        color: Theme.primaryColor
        wrapMode: Text.Wrap
        font.pixelSize: headingPixelSize(headingBlock.block.level)
        font.bold: true
        onLinkActivated: headingBlock.linkActivated(link)

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
        anchors.fill: headingLabel
        onClicked: headingBlock.activated()
    }
}
