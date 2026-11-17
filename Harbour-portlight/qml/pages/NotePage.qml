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

    function saveNote(automatic) {
        var result = vault.writeNote(page.notePath, editor.text)
        if (result.ok) {
            page.savedContent = editor.text
            page.saveStatus = automatic ? "Saved automatically" : "Saved"
        } else {
            page.saveStatus = "Save failed: " + result.error
        }
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
                visible: editor.text !== page.savedContent
                onClicked: page.saveNote(false)
            }
            MenuLabel {
                text: "Saved"
                visible: editor.text === page.savedContent
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
                onTextChanged: {
                    if (vault.autoSave && text !== page.savedContent) autoSaveTimer.restart()
                    else autoSaveTimer.stop()
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                text: editor.text === page.savedContent ? page.saveStatus
                                                        : (vault.autoSave ? "Saving…" : "Unsaved changes")
                color: Theme.secondaryColor
            }
        }
        VerticalScrollDecorator {}
    }

    Timer {
        id: autoSaveTimer
        interval: vault.saveDelay
        repeat: false
        onTriggered: {
            if (vault.autoSave && editor.text !== page.savedContent) page.saveNote(true)
        }
    }

    Connections {
        target: vault
        onAutoSaveChanged: {
            if (vault.autoSave && editor.text !== page.savedContent) autoSaveTimer.restart()
            else autoSaveTimer.stop()
        }
        onSaveDelayChanged: {
            if (autoSaveTimer.running) autoSaveTimer.restart()
        }
    }
}
