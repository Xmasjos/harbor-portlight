import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    property string locationText: "Vault root"
    signal createNoteRequested()

    Label {
        anchors.centerIn: parent
        width: parent.width - 2 * Theme.horizontalPageMargin
        x: Theme.horizontalPageMargin
        horizontalAlignment: Text.AlignHCenter
        text: locationText
        maximumLineCount: 3
        wrapMode: Text.Wrap
        truncationMode: TruncationMode.Fade
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: createNoteRequested()
        }
    }
}
