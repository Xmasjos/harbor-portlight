import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: editor

    property string title
    property string text
    property alias implicitContentHeight: noteText.implicitHeight

    signal textEdited(string text)

    onTextChanged: {
        if (noteText.text !== text) noteText.text = text
    }

    TextArea {
        id: noteText
        width: editor.width
        height: editor.height
        text: editor.text
        placeholderText: "Markdown note"
        label: "Note"
        onTextChanged: {
            if (editor.text !== text) editor.textEdited(text)
        }
    }
}
