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
    property bool useHtmlEditor: false
    property string editorStartContent: ""
    property string editorStartSavedContent: ""

    function noteFolder(path) {
        var slash = path.lastIndexOf("/")
        return slash < 0 ? "" : path.substring(0, slash)
    }

    function noteFileName(path) {
        var slash = path.lastIndexOf("/")
        return slash < 0 ? path : path.substring(slash + 1)
    }

    function logWebEditorProcess(event) {
        console.debug("[NotePage] Web editor process " + event
                      + ": running=" + editorProcess.running)
    }

    function updateWebEditor() {
        if (editorProcess.running) {
            editorProcess.send("update", {
                "title": noteFileName(notePath).replace(/\.md$/i, ""),
                "content": noteContent,
                "status": editorStatus
            })
        }
    }

    function toggleHtmlEditor() {
        if (editorProcess.running) {
            editorProcess.send("close", {})
        } else {
            editorStartContent = noteContent
            editorStartSavedContent = savedContent
            if (editorProcess.start(noteFileName(notePath).replace(/\.md$/i, ""),
                                    noteContent, editorStatus)) {
                useHtmlEditor = true
                logWebEditorProcess("launch requested")
            } else {
                saveStatus = "Unable to start HTML editor"
            }
        }
    }

    function renameNote(name) {
        var cleanName = name.trim()
        cleanName = cleanName.replace(/\.md$/i, "")
        if (!cleanName.length || cleanName === "." || cleanName === ".."
                || cleanName.indexOf("/") >= 0 || cleanName.indexOf("\\") >= 0
                || cleanName.indexOf("\u0000") >= 0
                || /[\u0000-\u001F]/.test(cleanName) || cleanName.length > 255) {
            sourceEditor.resetTitle()
            updateWebEditor()
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
            sourceEditor.resetTitle()
            updateWebEditor()
        }
    }

    function saveNote(automatic) {
        if (notePage.externalChangeDetected) {
            notePage.saveStatus = "Not saved: the note changed elsewhere"
            console.warn("[NotePage] Note save blocked by an external change")
            notePage.showConflictDialog()
            return false
        }
        var disk = vault.readNote(notePage.notePath)
        if (!disk.ok || disk.content !== notePage.baselineContent) {
            notePage.externalChangeDetected = true
            notePage.saveStatus = "Not saved: the note changed elsewhere"
            console.warn("[NotePage] Note save blocked because the note changed outside the editor")
            notePage.showConflictDialog()
            return false
        }
        var result = vault.writeNote(notePage.notePath, notePage.noteContent, notePage.baselineContent)
        if (result.ok) {
            notePage.savedContent = notePage.noteContent
            notePage.baselineContent = notePage.noteContent
            notePage.saveStatus = automatic ? "Saved automatically" : "Saved"
            console.debug("[NotePage] Note saved")
            return true
        } else if (result.conflict) {
            notePage.externalChangeDetected = true
            notePage.saveStatus = "Not saved: the note changed elsewhere"
            console.warn("[NotePage] Note save conflicted with an external change")
            notePage.showConflictDialog()
        } else {
            notePage.saveStatus = "Save failed: " + result.error
            console.warn("[NotePage] Note save failed:", result.error)
        }
        return false
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
        var destination = folder + base + " (copy).md"
        var suffix = 1
        var result = vault.createNote(destination, notePage.noteContent)
        while (!result.ok && result.error === "A note with that name already exists" && suffix < 1000) {
            destination = folder + base + " (copy " + suffix + ").md"
            result = vault.createNote(destination, notePage.noteContent)
            suffix++
        }
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
        updateWebEditor()
    }
    onEditorStatusChanged: updateWebEditor()

    onVisibleChanged: {
        if (visible && applicationWindow) {
            applicationWindow.currentNote = notePath
            applicationWindow.currentFolder = noteFolder(notePath)
        }
        if (visible) vault.watchNote(notePath)
        else vault.unwatchNote()
        updateWebEditor()
    }
    onNotePathChanged: {
        if (visible && applicationWindow) {
            applicationWindow.currentNote = notePath
            applicationWindow.currentFolder = noteFolder(notePath)
        }
        if (visible) vault.watchNote(notePath)
        updateWebEditor()
    }
    Component.onCompleted: {
        notePage.savedContent = notePage.noteContent
        refreshBaseline()
        if (visible) vault.watchNote(notePath)
    }
    Component.onDestruction: {
        if (editorProcess.running) editorProcess.send("close", {})
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
                text: notePage.useHtmlEditor ? "Use source editor" : "Use HTML editor"
                onClicked: notePage.toggleHtmlEditor()
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
            SourceNoteEditor {
                id: sourceEditor
                visible: !notePage.useHtmlEditor
                width: parent.width
                height: Math.max(notePage.height, implicitContentHeight)
                title: notePage.noteFileName(notePage.notePath).replace(/\.md$/i, "")
                text: notePage.noteContent
                status: notePage.editorStatus
                onTextEdited: function(value) { notePage.noteContent = value }
                onTitleEdited: function(value) { notePage.renameNote(value) }
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
        target: editorProcess
        onMessageReceived: function(type, data) {
            if (type === "edit" && typeof data.text === "string") {
                notePage.noteContent = data.text
            } else if (type === "rename" && typeof data.title === "string") {
                notePage.renameNote(data.title)
            } else if (type === "save" && typeof data.text === "string") {
                notePage.noteContent = data.text
                var saved = notePage.saveNote(false)
                editorProcess.send("saveResult", {
                    "ok": saved,
                    "status": notePage.editorStatus
                })
                if (!saved) notePage.applicationWindow.activate()
            } else if (type === "cancel") {
                notePage.noteContent = notePage.savedContent === notePage.editorStartSavedContent
                        ? notePage.editorStartContent : notePage.savedContent
            }
        }
        onRunningChanged: {
            notePage.useHtmlEditor = editorProcess.running
            notePage.logWebEditorProcess(editorProcess.running ? "started" : "stopped")
            if (!editorProcess.running && notePage.applicationWindow)
                notePage.applicationWindow.activate()
        }
        onProcessError: function(error) {
            notePage.saveStatus = "HTML editor failed: " + error
            notePage.useHtmlEditor = false
            notePage.logWebEditorProcess("error: " + error)
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
