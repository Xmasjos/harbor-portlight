import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: editor

    property string title
    property string text
    property string status
    property real implicitContentHeight: titleField.implicitHeight + noteText.implicitHeight
                                         + statusLabel.implicitHeight

    signal textEdited(string text)
    signal titleEdited(string title)

    function resetTitle() {
        titleField.text = editor.title
    }

    onTextChanged: {
        if (noteText.text !== text) noteText.text = text
    }
    onTitleChanged: resetTitle()

    TextField {
        id: titleField
        width: editor.width
        text: editor.title
        label: "Note name"
        placeholderText: "Untitled"
        EnterKey.onClicked: editor.titleEdited(text)
        onActiveFocusChanged: if (!activeFocus) editor.titleEdited(text)
    }

    TextArea {
        id: noteText
        y: titleField.height
        width: editor.width
        height: Math.max(0, editor.height - titleField.height - statusLabel.implicitHeight)
        text: editor.text
        placeholderText: "Markdown note"
        label: "Note"
        onTextChanged: {
            if (editor.text !== text) editor.textEdited(text)
        }
    }

    Label {
        id: statusLabel
        x: Theme.horizontalPageMargin
        y: noteText.y + noteText.height
        width: editor.width - Theme.horizontalPageMargin * 2
        text: editor.status
        color: Theme.secondaryColor
        wrapMode: Text.Wrap
    }
}
