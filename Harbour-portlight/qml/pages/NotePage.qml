import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    property string notePath: ""
    property string noteContent: ""
    property string savedContent: noteContent
    property string saveStatus: ""
    property var applicationWindow

    function noteFolder(path) {
        var slash = path.lastIndexOf("/")
        return slash < 0 ? "" : path.substring(0, slash)
    }

    onVisibleChanged: {
        if (visible && applicationWindow) {
            applicationWindow.currentNote = notePath
            applicationWindow.currentFolder = noteFolder(notePath)
        }
    }
    onNotePathChanged: {
        if (visible && applicationWindow) {
            applicationWindow.currentNote = notePath
            applicationWindow.currentFolder = noteFolder(notePath)
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: "Save"
                onClicked: {
                    var result = vault.writeNote(page.notePath, editor.text)
                    if (result.ok) {
                        page.savedContent = editor.text
                        page.saveStatus = "Saved"
                    } else {
                        page.saveStatus = "Save failed: " + result.error
                    }
                }
            }
        }

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingMedium
            PageHeader { title: page.notePath }
            TextArea {
                id: editor
                width: parent.width
                text: page.noteContent
                placeholderText: "Markdown note"
                label: "Note"
                height: Math.max(page.height - Theme.itemSizeLarge * 2, implicitHeight)
            }
            Label {
                x: Theme.horizontalPageMargin
                text: editor.text === page.savedContent ? page.saveStatus : "Unsaved changes"
                color: Theme.secondaryColor
            }
        }
        VerticalScrollDecorator {}
    }
}
