import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    property string currentFolder: ""
    property string scanStatus: "Loading vault…"
    property string searchQuery: ""
    property string folderTitle: currentFolder.length
            ? currentFolder.slice(currentFolder.lastIndexOf("/") + 1)
            : "Obsidian notes"

    ListModel {
        id: notesModel
    }

    function updateNotes(entries) {
        for (var i = notesModel.count - 1; i >= 0; i--) {
            var found = -1
            for (var j = 0; j < entries.length; j++) {
                if (notesModel.get(i).path === entries[j].path) {
                    found = j
                    break
                }
            }
            if (found < 0) notesModel.remove(i)
        }

        for (var target = 0; target < entries.length; target++) {
            var row = -1
            for (var current = target; current < notesModel.count; current++) {
                if (notesModel.get(current).path === entries[target].path) {
                    row = current
                    break
                }
            }
            if (row < 0) notesModel.insert(target, entries[target])
            else {
                if (row !== target) notesModel.move(row, target, 1)
                var entry = entries[target]
                for (var key in entry) {
                    if (notesModel.get(target)[key] !== entry[key])
                        notesModel.setProperty(target, key, entry[key])
                }
            }
        }
    }

    function refreshFolder() {
        var result = vault.listVaultEntries(currentFolder)
        if (!result.ok) {
            updateNotes([])
            scanStatus = result.error
            return
        }

        var entries = []
        for (var i = 0; i < result.entries.length; i++) {
            var entry = result.entries[i]
            entry.excerpt = entry.excerpt || ""
            entries.push(entry)
        }
        updateNotes(entries)
        scanStatus = result.entries.length + " items"
    }

    function openNote(path) {
        var result = vault.readNote(path)
        if (result.ok) {
            pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                notePath: path,
                noteContent: result.content
            })
        } else {
            scanStatus = result.error
        }
    }

    function parentFolder(path) {
        var slash = path.lastIndexOf("/")
        return slash < 0 ? "" : path.substring(0, slash)
    }

    function askPath(title, initialText, placeholder, callback, destination, destinationType, properties) {
        pageStack.push(pathDialog, {
            dialogTitle: title,
            initialText: initialText,
            pathPlaceholder: placeholder,
            acceptCallback: callback,
            sourcePage: page,
            destinationType: destinationType,
            acceptDestination: destination,
            acceptDestinationProperties: properties,
            acceptDestinationAction: PageStackAction.Replace,
            acceptDestinationReplaceTarget: page
        })
    }

    function notePath(name) {
        var fileName = name.substring(name.lastIndexOf("/") + 1)
        var dot = fileName.lastIndexOf(".")
        if (dot <= 0 || dot === fileName.length - 1) name += ".md"
        return currentFolder.length ? currentFolder + "/" + name : name
    }

    function deleteNote(path) {
        var result = vault.deleteNote(path)
        if (result.ok) refreshFolder()
        else scanStatus = result.error
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: notesModel
        PullDownMenu {
            MenuItem {
                text: "Create folder"
                onClicked: page.askPath("New folder", "", "Folder name or vault path", function(name, dialog) {
                    var path = page.currentFolder.length ? page.currentFolder + "/" + name : name
                    var result = vault.createFolder(path)
                    if (result.ok) dialog.acceptDestinationInstance.refreshFolder()
                    else dialog.returnToSource(result.error)
                }, Qt.resolvedUrl("NotesPage.qml"), "folder", { currentFolder: page.currentFolder })
            }
            MenuItem {
                text: "Create note"
                onClicked: page.askPath("New note", "", "Note name or vault path", function(name, dialog) {
                    var path = page.notePath(name)
                    var result = vault.createNote(path, "")
                    if (!result.ok) dialog.returnToSource(result.error)
                }, Qt.resolvedUrl("NotePage.qml"), "note",
                { notePath: page.notePath(""), noteContent: "" })
            }
        }
        header: Column {
            width: listView.width
            PageHeader {
                title: page.folderTitle
                description: page.currentFolder.length ? page.currentFolder : "Vault root"
            }
            SearchField {
                width: parent.width
                placeholderText: "Search notes"
                onTextChanged: {
                    page.searchQuery = text
                    searchTimer.restart()
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: page.scanStatus
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                truncationMode: TruncationMode.Fade
            }
        }
        delegate: ListItem {
            id: noteDelegate
            property var entry: ({ type: type, name: name, path: path, excerpt: excerpt })
            width: listView.width
            contentHeight: resultColumn.height + 2 * Theme.paddingMedium
            menu: ContextMenu {
                MenuItem {
                    text: "Rename"
                    onClicked: {
                        var sourcePath = noteDelegate.entry.path
                        var isFolder = noteDelegate.entry.type === "folder"
                        page.askPath(isFolder ? "Rename folder" : "Rename note", sourcePath,
                                     "Name and extension", function(path, dialog) {
                            var result = isFolder ? vault.moveFolder(sourcePath, path)
                                                  : vault.moveNote(sourcePath, path)
                            if (result.ok) dialog.acceptDestinationInstance.refreshFolder()
                            else dialog.returnToSource(result.error)
                        }, Qt.resolvedUrl("NotesPage.qml"), "destination",
                        { currentFolder: page.parentFolder(sourcePath) })
                    }
                }
                MenuItem {
                    text: "Copy"
                    onClicked: {
                        var sourcePath = noteDelegate.entry.path
                        var isFolder = noteDelegate.entry.type === "folder"
                        var defaultPath = isFolder ? sourcePath + " copy"
                                                    : sourcePath.replace(/\.md$/i, " copy.md")
                        page.askPath(isFolder ? "Copy folder to" : "Copy note to", defaultPath,
                                     "Destination path", function(path, dialog) {
                            var result = isFolder ? vault.copyFolder(sourcePath, path)
                                                  : vault.copyNote(sourcePath, path)
                            if (result.ok) dialog.acceptDestinationInstance.refreshFolder()
                            else dialog.returnToSource(result.error)
                        }, Qt.resolvedUrl("NotesPage.qml"), "destination",
                        { currentFolder: page.parentFolder(defaultPath) })
                    }
                }
                MenuItem {
                    text: "Move"
                    onClicked: {
                        var sourcePath = noteDelegate.entry.path
                        var isFolder = noteDelegate.entry.type === "folder"
                        page.askPath(isFolder ? "Move folder to" : "Move note to", sourcePath,
                                     "Destination path", function(path, dialog) {
                            var result = isFolder ? vault.moveFolder(sourcePath, path)
                                                  : vault.moveNote(sourcePath, path)
                            if (result.ok) dialog.acceptDestinationInstance.refreshFolder()
                            else dialog.returnToSource(result.error)
                        }, Qt.resolvedUrl("NotesPage.qml"), "destination",
                        { currentFolder: page.parentFolder(sourcePath) })
                    }
                }
                MenuItem {
                    text: "Delete"
                    onClicked: {
                        var sourcePath = noteDelegate.entry.path
                        var isFolder = noteDelegate.entry.type === "folder"
                        noteDelegate.remorseDelete(function() {
                            if (!isFolder) {
                                page.deleteNote(sourcePath)
                                return
                            }
                            var result = vault.deleteFolder(sourcePath)
                            if (result.ok) page.refreshFolder()
                            else page.scanStatus = result.error
                        })
                    }
                }
            }

            Column {
                id: resultColumn
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: type === "folder" ? name + "/"
                          : page.searchQuery.trim().length ? path : name
                    truncationMode: TruncationMode.Fade
                    color: noteDelegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    text: excerpt || ""
                    visible: text.length > 0
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    truncationMode: TruncationMode.Fade
                }
            }

            onClicked: {
                if (type === "folder") {
                    pageStack.animatorPush(Qt.resolvedUrl("NotesPage.qml"), {
                        currentFolder: path
                    })
                } else {
                    openNote(path)
                }
            }
        }
        VerticalScrollDecorator {}
    }

    Timer {
        id: searchTimer
        interval: 300
        onTriggered: {
            var query = page.searchQuery.trim()
            if (!query.length) {
                page.refreshFolder()
                return
            }

            var result = vault.searchNotes(query)
            if (!result.ok) {
                page.updateNotes([])
                scanStatus = result.error
                return
            }
            var matches = result.matches
            for (var i = 0; i < matches.length; i++)
                matches[i].excerpt = matches[i].excerpt || ""
            page.updateNotes(matches)
            scanStatus = result.matches.length
                    ? result.matches.length + " matches across vault"
                    : "No matching notes"
        }
    }

    Component {
        id: pathDialog
        Dialog {
            id: inputDialog
            property string dialogTitle: ""
            property string initialText: ""
            property string pathPlaceholder: ""
            property var acceptCallback
            property var sourcePage
            property string destinationType: ""
            property alias enteredText: nameField.text
            canAccept: enteredText.trim().length > 0

            function updateDestination() {
                var destinationPage = acceptDestinationInstance
                var value = enteredText.trim()
                if (!destinationPage || !value.length) return
                if (destinationType === "note") {
                    destinationPage.notePath = sourcePage.notePath(value)
                } else if (destinationType === "folder") {
                    destinationPage.currentFolder = sourcePage.currentFolder.length
                            ? sourcePage.currentFolder + "/" + value : value
                } else if (destinationType === "destination") {
                    destinationPage.currentFolder = sourcePage.parentFolder(value)
                }
            }

            function returnToSource(error) {
                sourcePage.scanStatus = error
                acceptDestination = sourcePage
                acceptDestinationAction = PageStackAction.Pop
            }

            onAccepted: {
                var value = enteredText.trim()
                if (value.length) acceptCallback(value, inputDialog)
            }
            onOpened: updateDestination()

            Column {
                width: parent.width
                DialogHeader { title: inputDialog.dialogTitle }
                TextField {
                    id: nameField
                    width: parent.width
                    text: inputDialog.initialText
                    placeholderText: inputDialog.pathPlaceholder
                    onTextChanged: inputDialog.updateDestination()
                    EnterKey.onClicked: inputDialog.accept()
                }
            }

            Component.onCompleted: nameField.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        refreshFolder()
        if (visible) vault.watchFolder(currentFolder)
    }
    onVisibleChanged: {
        if (visible) vault.watchFolder(currentFolder)
    }

    Connections {
        target: vault
        onFolderChanged: {
            if (page.searchQuery.trim().length) searchTimer.restart()
            else page.refreshFolder()
        }
    }
}
