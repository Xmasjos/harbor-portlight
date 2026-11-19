import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    allowedOrientations: Orientation.All
    id: notePage
    property string notePath: ""
    property string noteContent: ""
    property string savedContent: noteContent
    property string saveStatus: ""
    property var applicationWindow
    property bool quickCapture: false

    function noteFolder(path) {
        var slash = path.lastIndexOf("/")
        return slash < 0 ? "" : path.substring(0, slash)
    }

    function renameNote(name) {
        var cleanName = name.trim()
        if (!cleanName.length) {
            titleField.text = notePage.notePath.substring(notePage.notePath.lastIndexOf("/") + 1).replace(/\.md$/i, "")
            return
        }
        var slash = notePage.notePath.lastIndexOf("/")
        var folder = slash < 0 ? "" : notePage.notePath.substring(0, slash + 1)
        var fileName = cleanName.substring(cleanName.lastIndexOf("/") + 1)
        if (!/\.[^./]+$/.test(fileName)) fileName += ".md"
        var destination = folder + fileName
        if (destination === notePage.notePath) return
        var result = vault.moveNote(notePage.notePath, destination)
        if (result.ok) {
            notePage.notePath = result.path
            titleField.text = fileName.replace(/\.md$/i, "")
            notePage.saveStatus = "Renamed"
        } else {
            notePage.saveStatus = "Rename failed: " + result.error
            titleField.text = notePage.notePath.substring(notePage.notePath.lastIndexOf("/") + 1).replace(/\.md$/i, "")
        }
    }

    function saveNote(automatic) {
        var result = vault.writeNote(notePage.notePath, editor.text)
        if (result.ok) {
            notePage.savedContent = editor.text
            notePage.saveStatus = automatic ? "Saved automatically" : "Saved"
        } else {
            notePage.saveStatus = "Save failed: " + result.error
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
    Component.onDestruction: {
        if (quickCapture) {
            var stored = vault.readNote(notePath)
            if (stored.ok && !stored.content.trim().length) vault.deleteNote(notePath)
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: "Save"
                visible: editor.text !== notePage.savedContent
                onClicked: notePage.saveNote(false)
            }
            MenuLabel {
                text: (editor.text === notePage.savedContent ? "Saved · " : "")
                      + (notePage.noteFolder(notePage.notePath) || "Vault root")
            }
        }

        Column {
            id: column
            width: notePage.width
            spacing: Theme.paddingMedium
            PageHeader {
                id: pageHeader
                title: ""
                TextField {
                    id: titleField
                    parent: pageHeader.extraContent
                    y: Theme.paddingSmall
                    width: parent.width
                    text: notePage.notePath.substring(notePage.notePath.lastIndexOf("/") + 1).replace(/\.md$/i, "")
                    label: "Note name"
                    placeholderText: "Untitled"
                    EnterKey.onClicked: notePage.renameNote(text)
                    onFocusChanged: if (!focus) notePage.renameNote(text)
                }
            }
            TextArea {
                id: editor
                width: parent.width
                text: notePage.noteContent
                placeholderText: "Markdown note"
                label: "Note"
                height: Math.max(notePage.height - Theme.itemSizeLarge * 2, implicitHeight)
                onTextChanged: {
                    if (notePage.applicationWindow.autoSave && text !== notePage.savedContent) autoSaveTimer.restart()
                    else autoSaveTimer.stop()
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                text: editor.text === notePage.savedContent ? notePage.saveStatus
                                                        : (notePage.applicationWindow.autoSave ? "Saving…" : "Unsaved changes")
                color: Theme.secondaryColor
            }
        }
        VerticalScrollDecorator {}
    }

    Timer {
        id: autoSaveTimer
        interval: notePage.applicationWindow.saveDelay
        repeat: false
        onTriggered: {
            if (notePage.applicationWindow.autoSave && editor.text !== notePage.savedContent) notePage.saveNote(true)
        }
    }

    Connections {
        target: notePage.applicationWindow
        onAutoSaveChanged: {
            if (notePage.applicationWindow.autoSave && editor.text !== notePage.savedContent) autoSaveTimer.restart()
            else autoSaveTimer.stop()
        }
        onSaveDelayChanged: {
            if (autoSaveTimer.running) autoSaveTimer.restart()
        }
    }
}
