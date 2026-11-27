import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    allowedOrientations: Orientation.All
    id: notePage
    property string notePath: ""
    property string noteContent: ""
    property string savedContent: noteContent
    property string saveStatus: ""
    property string editorStatus: noteContent === savedContent ? saveStatus
                                  : (applicationWindow.autoSave ? "Saving…" : "Unsaved changes")
    property string baselineContent: noteContent
    property bool externalChangeDetected: false
    property bool conflictDialogOpen: false
    property var applicationWindow
    property bool quickCapture: false
    property string editorMode: "preview"

    function noteFolder(path) {
        var slash = path.lastIndexOf("/")
        return slash < 0 ? "" : path.substring(0, slash)
    }

    function noteFileName(path) {
        var slash = path.lastIndexOf("/")
        return slash < 0 ? path : path.substring(slash + 1)
    }

    function renameNote(name) {
        var cleanName = name.trim()
        cleanName = cleanName.replace(/\.md$/i, "")
        if (!cleanName.length || cleanName === "." || cleanName === ".."
                || cleanName.indexOf("/") >= 0 || cleanName.indexOf("\\") >= 0
                || cleanName.indexOf("\u0000") >= 0
                || /[\u0000-\u001F]/.test(cleanName) || cleanName.length > 255) {
            if (sourceEditorLoader.item) sourceEditorLoader.item.resetTitle()
            if (previewEditorLoader.item) previewEditorLoader.item.resetTitle()
            return
        }
        var slash = notePage.notePath.lastIndexOf("/")
        var folder = slash < 0 ? "" : notePage.notePath.substring(0, slash + 1)
        var fileName = cleanName.substring(cleanName.lastIndexOf("/") + 1)
        if (!/\.[^./]+$/.test(fileName)) fileName += ".md"
        var destination = "" + folder + fileName // Prepend empty string to hint the editor
        if (destination === notePage.notePath) return
        var result = vault.moveNote(notePage.notePath, destination)
        if (result.ok) {
            notePage.notePath = result.path
            notePage.saveStatus = "Renamed"
        } else {
            notePage.saveStatus = "Rename failed: " + result.error
            if (sourceEditorLoader.item) sourceEditorLoader.item.resetTitle()
            if (previewEditorLoader.item) previewEditorLoader.item.resetTitle()
        }
    }

    function saveNote(automatic) {
        if (notePage.externalChangeDetected) {
            notePage.saveStatus = "Not saved: the note changed elsewhere"
            console.warn("[NotePage] Note save blocked by an external change")
            notePage.showConflictDialog()
            return
        }
        var disk = vault.readNote(notePage.notePath)
        if (!disk.ok || disk.content !== notePage.baselineContent) {
            notePage.externalChangeDetected = true
            notePage.saveStatus = "Not saved: the note changed elsewhere"
            console.warn("[NotePage] Note save blocked because the note changed outside the editor")
            notePage.showConflictDialog()
            return
        }
        var result = vault.writeNote(notePage.notePath, notePage.noteContent, notePage.baselineContent)
        if (result.ok) {
            notePage.savedContent = notePage.noteContent
            notePage.baselineContent = notePage.noteContent
            notePage.saveStatus = automatic ? "Saved automatically" : "Saved"
            console.debug("[NotePage] Note saved")
        } else if (result.conflict) {
            notePage.externalChangeDetected = true
            notePage.saveStatus = "Not saved: the note changed elsewhere"
            console.warn("[NotePage] Note save conflicted with an external change")
            notePage.showConflictDialog()
        } else {
            notePage.saveStatus = "Save failed: " + result.error
            console.warn("[NotePage] Note save failed:", result.error)
        }
    }

    function refreshBaseline() {
        var result = vault.readNote(notePage.notePath)
        if (result.ok) notePage.baselineContent = result.content
    }

    function reloadExternalNote() {
        var result = vault.readNote(notePage.notePath)
        if (!result.ok) {
            notePage.saveStatus = "Reload failed: " + result.error
            console.warn("[NotePage] Unable to reload note:", result.error)
            return
        }
        notePage.noteContent = result.content
        notePage.savedContent = result.content
        notePage.baselineContent = result.content
        notePage.externalChangeDetected = false
        notePage.saveStatus = "Reloaded newer version"
    }

    function saveCurrentAsCopy() {
        var fileName = notePage.notePath.substring(notePage.notePath.lastIndexOf("/") + 1)
        var slash = notePage.notePath.lastIndexOf("/")
        var folder = slash < 0 ? "" : notePage.notePath.substring(0, slash + 1)
        var base = fileName.replace(/\.md$/i, "")
        var created = notePage.applicationWindow.createNoteWithUniqueName(function(suffix) {
            return folder + base + " (copy" + (suffix ? " " + suffix : "") + ").md"
        }, function(path) { return vault.createNote(path, notePage.noteContent) })
        var destination = created.path
        var result = created.result
        if (result.ok) {
            notePage.saveStatus = "Current text saved as " + destination.substring(destination.lastIndexOf("/") + 1)
        } else {
            notePage.saveStatus = "Copy failed: " + result.error
        }
    }

    function showConflictDialog() {
        if (notePage.conflictDialogOpen) return
        pageStack.push(conflictDialog, { sourcePage: notePage })
    }

    onNoteContentChanged: {
        if (applicationWindow.autoSave && noteContent !== savedContent) autoSaveTimer.restart()
        else autoSaveTimer.stop()
    }

    onVisibleChanged: {
        if (visible && applicationWindow) {
            applicationWindow.currentNote = notePath
            applicationWindow.currentFolder = noteFolder(notePath)
        }
        if (visible) vault.watchNote(notePath)
        else vault.unwatchNote()
    }
    onNotePathChanged: {
        if (visible && applicationWindow) {
            applicationWindow.currentNote = notePath
            applicationWindow.currentFolder = noteFolder(notePath)
        }
        if (visible) vault.watchNote(notePath)
    }
    Component.onCompleted: {
        notePage.savedContent = notePage.noteContent
        refreshBaseline()
        if (visible) vault.watchNote(notePath)
    }
    Component.onDestruction: {
        vault.unwatchNote()
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
                text: "Use source editor"
                visible: notePage.editorMode !== "source"
                onClicked: notePage.editorMode = "source"
            }
            MenuItem {
                text: "Use preview editor"
                visible: notePage.editorMode !== "preview"
                onClicked: notePage.editorMode = "preview"
            }
            MenuItem {
                text: "Save"
                visible: notePage.noteContent !== notePage.savedContent
                onClicked: notePage.saveNote(false)
            }
            MenuLabel {
                text: (notePage.noteContent === notePage.savedContent ? "Saved · " : "")
                      + (notePage.noteFolder(notePage.notePath) || "Vault root")
            }
        }

        Column {
            id: column
            width: notePage.width
            spacing: Theme.paddingMedium
            Loader {
                id: sourceEditorLoader
                active: notePage.editorMode === "source"
                visible: active
                width: parent.width
                height: active
                        ? Math.max(notePage.height, item ? item.implicitContentHeight : notePage.height)
                        : 0
                sourceComponent: Component {
                    SourceNoteEditor {
                        width: notePage.width
                        title: notePage.noteFileName(notePage.notePath).replace(/\.md$/i, "")
                        text: notePage.noteContent
                        status: notePage.editorStatus
                        onTextEdited: function(value) { notePage.noteContent = value }
                        onTitleEdited: function(value) { notePage.renameNote(value) }
                    }
                }
            }
            Loader {
                id: previewEditorLoader
                active: notePage.editorMode === "preview"
                visible: active
                width: parent.width
                height: active
                        ? Math.max(notePage.height, item ? item.implicitContentHeight : notePage.height)
                        : 0
                sourceComponent: Component {
                    NotePreviewEditor {
                        width: notePage.width
                        title: notePage.noteFileName(notePage.notePath).replace(/\.md$/i, "")
                        text: notePage.noteContent
                        status: notePage.editorStatus
                        notePath: notePage.notePath
                        onTextEdited: function(value) { notePage.noteContent = value }
                        onTitleEdited: function(value) { notePage.renameNote(value) }
                        onLinkActivated: function(url) {
                            if (url.indexOf("file://") === 0 || /^https?:/i.test(url)
                                    || /^mailto:/i.test(url) || /^tel:/i.test(url))
                                Qt.openUrlExternally(url)
                        }
                    }
                }
            }
        }
        VerticalScrollDecorator {}
    }

    Timer {
        id: autoSaveTimer
        interval: notePage.applicationWindow.saveDelay
        repeat: false
        onTriggered: {
            if (notePage.applicationWindow.autoSave && notePage.noteContent !== notePage.savedContent) notePage.saveNote(true)
        }
    }

    Connections {
        target: notePage.applicationWindow
        onAutoSaveChanged: {
            if (notePage.applicationWindow.autoSave && notePage.noteContent !== notePage.savedContent) autoSaveTimer.restart()
            else autoSaveTimer.stop()
        }
        onSaveDelayChanged: {
            if (autoSaveTimer.running) autoSaveTimer.restart()
        }
    }

    Connections {
        target: vault
        onNoteChanged: function(relativePath) {
            if (relativePath !== notePage.notePath) return
            var result = vault.readNote(relativePath)
            if (!result.ok) {
                notePage.externalChangeDetected = true
                notePage.saveStatus = "Not saved: the note changed or was removed elsewhere"
            } else if (result.content === notePage.noteContent) {
                return
            } else if (result.content !== notePage.baselineContent) {
                notePage.externalChangeDetected = true
                notePage.saveStatus = "The note changed elsewhere"
            }
        }
    }

    Component {
        id: conflictDialog
        Dialog {
            property var sourcePage
            canAccept: false
            onOpened: sourcePage.conflictDialogOpen = true
            onDone: sourcePage.conflictDialogOpen = false

            Column {
                width: parent.width
                spacing: Theme.paddingLarge
                DialogHeader {
                    title: "Note changed elsewhere"
                }
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    wrapMode: Text.Wrap
                    text: "A newer version exists outside this app. Choose what to do before saving."
                    color: Theme.highlightColor
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Reload newer version"
                    onClicked: {
                        sourcePage.reloadExternalNote()
                        pageStack.pop()
                    }
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Save current text as copy"
                    onClicked: {
                        sourcePage.saveCurrentAsCopy()
                        pageStack.pop()
                    }
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Cancel"
                    onClicked: pageStack.pop()
                }
            }
        }
    }
}
