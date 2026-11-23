import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: ruleBlock

    implicitHeight: Theme.paddingLarge

    signal activated()

    Rectangle {
        x: Theme.horizontalPageMargin
        y: Theme.paddingMedium
        width: ruleBlock.width - Theme.horizontalPageMargin * 2
        height: 2
        color: Theme.secondaryHighlightColor

        MouseArea {
            anchors.fill: parent
            onClicked: ruleBlock.activated()
        }
    }
}
