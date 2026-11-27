import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: codeBlock
    property var block
    implicitHeight: codeLabel.implicitHeight + Theme.paddingMedium
    signal activated()
    Rectangle {
        anchors.fill: codeLabel
        anchors.margins: -Theme.paddingSmall
        color: Theme.rgba(Theme.secondaryColor, 0.12)
        radius: Theme.paddingSmall
    }
    Label {
        id: codeLabel
        x: Theme.horizontalPageMargin
        width: codeBlock.width - 2 * Theme.horizontalPageMargin
        text: codeBlock.block && codeBlock.block.type === "code"
              && typeof codeBlock.block.code === "string" ? codeBlock.block.code : ""
        color: Theme.primaryColor
        wrapMode: Text.WrapAnywhere
        font.family: "monospace"
    }
    MouseArea { anchors.fill: codeLabel; onClicked: codeBlock.activated() }
}
