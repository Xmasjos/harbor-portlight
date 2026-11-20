import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0

Page {
    allowedOrientations: Orientation.All
    id: notePage
    property string notePath: ""
    property string noteContent: ""
    property string savedContent: noteContent
    property string saveStatus: ""
    property string baselineContent: noteContent
    property bool externalChangeDetected: false
    property bool conflictDialogOpen: false
    property var applicationWindow
    property bool quickCapture: false
    property bool useHtmlEditor: false

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
        var destination = "" + folder + fileName // Prepend empty string to hint the editor
        if (destination === notePath) return
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
        notePage.updateEditorText()
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

    function updateEditorText() {
        if (sourceEditor.text !== noteContent) sourceEditor.text = noteContent
        if (editorLoaded) {
            webEditor.runJavaScript("window.setNoteText(" + JSON.stringify(noteContent) + ")")
        }
    }

    property bool editorLoaded: false

    onNoteContentChanged: {
        if (sourceEditor.text !== noteContent) sourceEditor.text = noteContent
        if (applicationWindow.autoSave && noteContent !== savedContent) autoSaveTimer.restart()
        else autoSaveTimer.stop()
    }
    onUseHtmlEditorChanged: {
        if (useHtmlEditor) updateEditorText()
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
                text: notePage.useHtmlEditor ? "Use source editor" : "Use HTML editor"
                onClicked: notePage.useHtmlEditor = !notePage.useHtmlEditor
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
                id: sourceEditor
                visible: !notePage.useHtmlEditor
                width: parent.width
                text: notePage.noteContent
                placeholderText: "Markdown note"
                label: "Note"
                height: Math.max(notePage.height - Theme.itemSizeLarge * 2, implicitHeight)
                onTextChanged: {
                    if (notePage.noteContent !== text) notePage.noteContent = text
                }
            }
            WebView {
                id: webEditor
                visible: notePage.useHtmlEditor
                width: parent.width
                height: Math.max(notePage.height - Theme.itemSizeLarge * 2, Theme.itemSizeLarge)
                url: Qt.resolvedUrl("../editor.html")

                onViewInitialized: {
                    webEditor.addMessageListener("portlight:noteChanged")
                    webEditor.loadFrameScript(Qt.resolvedUrl("../editor-frame.js"))
                }
                onLoadingChanged: {
                    if (!loading) {
                        notePage.editorLoaded = true
                        notePage.updateEditorText()
                    }
                }
                onRecvAsyncMessage: function(message, data) {
                    if (message === "portlight:noteChanged" && data && typeof data.text === "string")
                        notePage.noteContent = data.text
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                text: notePage.noteContent === notePage.savedContent ? notePage.saveStatus
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
