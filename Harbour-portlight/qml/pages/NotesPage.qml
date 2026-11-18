import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    allowedOrientations: Orientation.All
    id: notesPage
    property var applicationWindow
    property Component notesPageComponent
    property string currentFolder: ""
    property string scanStatus: "Loading vault…"
    property string searchQuery: ""
    property bool refreshPending: true
    property string folderTitle: currentFolder.length
            ? currentFolder.slice(currentFolder.lastIndexOf("/") + 1)
            : "Obsidian notes"

    ListModel {
        id: notesModel
    }

    function updateNotes(entries, resetPosition) {
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
        if (resetPosition) positionResetTimer.restart()
    }

    function refreshFolder(resetPosition) {
        var result = vault.listVaultEntries(currentFolder)
        refreshPending = false
        if (!result.ok) {
            updateNotes([], resetPosition)
            scanStatus = result.error
            return
        }

        var entries = []
        for (var i = 0; i < result.entries.length; i++) {
            var entry = result.entries[i]
            if (entry.type === "unsupported" && !applicationWindow.showUnsupportedFiles) continue
            entry.excerpt = entry.excerpt || ""
            entries.push(entry)
        }
        updateNotes(entries, resetPosition)
        scanStatus = entries.length + " items"
    }

    function openNote(path) {
        var result = vault.readNote(path)
        if (result.ok) {
            pageStack.push(notePage, {
                notePath: path,
                noteContent: result.content,
                applicationWindow: notesPage.applicationWindow
            })
        } else {
            scanStatus = result.error
        }
    }

    function openImage(path) {
        var source = vault.imageUrl(path)
        if (!source.length) {
            scanStatus = "Unable to open image"
            return
        }
        pageStack.push(imagePage, {
            imagePath: path,
            imageSource: source
        })
    }

    function createUntitledNote() {
        var base = currentFolder.length ? currentFolder + "/" : ""
        var path = base + "Untitled.md"
        var suffix = 1
        var result = vault.createNote(path, "")
        while (!result.ok && suffix < 1000) {
            if (result.error !== "A note with that name already exists") break
            path = base + "Untitled " + suffix + ".md"
            result = vault.createNote(path, "")
            suffix++
        }
        if (result.ok) {
            pageStack.push(notePage, {
                notePath: path,
                noteContent: "",
                applicationWindow: notesPage.applicationWindow
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
        properties = properties || ({})
        properties.applicationWindow = notesPage.applicationWindow
        pageStack.push(pathDialog, {
            dialogTitle: title,
            initialText: initialText,
            pathPlaceholder: placeholder,
            acceptCallback: callback,
            sourcePage: notesPage,
            destinationType: destinationType,
            acceptDestination: destination,
            acceptDestinationProperties: properties,
            acceptDestinationAction: PageStackAction.Replace,
            acceptDestinationReplaceTarget: notesPage
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

    function iconForEntry(entry) {
        if (entry.type === "folder") return entry.hasItems ? "icon-m-file-folder" : "icon-m-folder"
        var extension = entry.name.substring(entry.name.lastIndexOf(".") + 1).toLowerCase()
        if (extension === "md" || extension === "markdown") return "icon-m-file-note"
        if (["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "heic", "tif", "tiff"].indexOf(extension) >= 0)
            return "icon-m-file-image"
        if (extension === "pdf") return "icon-m-file-pdf"
        if (["doc", "docx", "odt", "rtf"].indexOf(extension) >= 0) return "icon-m-file-formatted"
        if (["ppt", "pptx", "odp", "key"].indexOf(extension) >= 0) return "icon-m-file-presentation"
        if (["xls", "xlsx", "ods", "csv"].indexOf(extension) >= 0) return "icon-m-file-spreadsheet"
        if (["zip", "gz", "bz2", "xz", "7z", "rar", "tar"].indexOf(extension) >= 0)
            return "icon-m-file-compressed"
        if (["mp3", "wav", "ogg", "flac", "m4a", "aac"].indexOf(extension) >= 0)
            return "icon-m-file-audio"
        if (["mp4", "mkv", "avi", "mov", "webm", "m4v"].indexOf(extension) >= 0)
            return "icon-m-file-video"
        return entry.type === "note" ? "icon-m-file-document" : "icon-m-file-other"
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: notesModel
        PullDownMenu {
            MenuItem {
                text: "Settings"
                onClicked: pageStack.push(settingsPage, {
                    applicationWindow: notesPage.applicationWindow
                })
            }
            MenuItem {
                text: applicationWindow.showUnsupportedFiles ? "Hide unsupported files" : "Show unsupported files"
                onClicked: {
                    applicationWindow.showUnsupportedFiles = !applicationWindow.showUnsupportedFiles
                    if (!notesPage.searchQuery.trim().length) notesPage.refreshFolder(true)
                }
            }
            MenuItem {
                text: "Create folder"
                onClicked: notesPage.askPath("New folder", "", "Folder name or vault path", function(name, dialog) {
                    var path = notesPage.currentFolder.length ? notesPage.currentFolder + "/" + name : name
                    var result = vault.createFolder(path)
                    if (result.ok) dialog.acceptDestinationInstance.refreshFolder()
                    else dialog.returnToSource(result.error)
                }, notesPageComponent, "folder", { currentFolder: notesPage.currentFolder })
            }
            MenuItem {
                text: "Create note"
                onClicked: notesPage.createUntitledNote()
            }
        }
        header: Column {
            width: listView.width
            PageHeader {
                title: notesPage.folderTitle
                description: notesPage.currentFolder.length ? notesPage.currentFolder : "Vault root"
            }
            SearchField {
                id: searchField
                width: parent.width
                placeholderText: "Search notes"
                onTextChanged: {
                    notesPage.searchQuery = text
                    searchTimer.restart()
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: notesPage.scanStatus
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                truncationMode: TruncationMode.Fade
            }
        }
        delegate: ListItem {
            id: noteDelegate
            property var entry: ({ type: type, name: name, path: path, excerpt: excerpt, hasItems: hasItems })
            width: listView.width
            contentHeight: resultColumn.height + 2 * Theme.paddingMedium
            menu: ContextMenu {
                MenuItem {
                    text: "Rename"
                    onClicked: {
                        var sourcePath = noteDelegate.entry.path
                        var isFolder = noteDelegate.entry.type === "folder"
                        notesPage.askPath(isFolder ? "Rename folder" : "Rename note", sourcePath,
                                     "Name and extension", function(path, dialog) {
                            var result = isFolder ? vault.moveFolder(sourcePath, path)
                                                  : vault.moveNote(sourcePath, path)
                            if (result.ok) dialog.acceptDestinationInstance.refreshFolder()
                            else dialog.returnToSource(result.error)
                        }, notesPageComponent, "destination",
                        { currentFolder: notesPage.parentFolder(sourcePath) })
                    }
                }
                MenuItem {
                    text: "Copy"
                    onClicked: {
                        var sourcePath = noteDelegate.entry.path
                        var isFolder = noteDelegate.entry.type === "folder"
                        var defaultPath = isFolder ? sourcePath + " copy"
                                                    : sourcePath.replace(/\.md$/i, " copy.md")
                        notesPage.askPath(isFolder ? "Copy folder to" : "Copy note to", defaultPath,
                                     "Destination path", function(path, dialog) {
                            var result = isFolder ? vault.copyFolder(sourcePath, path)
                                                  : vault.copyNote(sourcePath, path)
                            if (result.ok) dialog.acceptDestinationInstance.refreshFolder()
                            else dialog.returnToSource(result.error)
                        }, notesPageComponent, "destination",
                        { currentFolder: notesPage.parentFolder(defaultPath) })
                    }
                }
                MenuItem {
                    text: "Move"
                    onClicked: {
                        var sourcePath = noteDelegate.entry.path
                        var isFolder = noteDelegate.entry.type === "folder"
                        notesPage.askPath(isFolder ? "Move folder to" : "Move note to", sourcePath,
                                     "Destination path", function(path, dialog) {
                            var result = isFolder ? vault.moveFolder(sourcePath, path)
                                                  : vault.moveNote(sourcePath, path)
                            if (result.ok) dialog.acceptDestinationInstance.refreshFolder()
                            else dialog.returnToSource(result.error)
                        }, notesPageComponent, "destination",
                        { currentFolder: notesPage.parentFolder(sourcePath) })
                    }
                }
                MenuItem {
                    text: "Delete"
                    onClicked: {
                        var sourcePath = noteDelegate.entry.path
                        var isFolder = noteDelegate.entry.type === "folder"
                        noteDelegate.remorseDelete(function() {
                            if (!isFolder) {
                                notesPage.deleteNote(sourcePath)
                                return
                            }
                            var result = vault.deleteFolder(sourcePath)
                            if (result.ok) notesPage.refreshFolder()
                            else notesPage.scanStatus = result.error
                        })
                    }
                }
            }

            Column {
                id: resultColumn
                x: Theme.horizontalPageMargin + itemIcon.width + Theme.paddingMedium
                width: parent.width - x - Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: notesPage.searchQuery.trim().length ? path : name
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

            Image {
                id: itemIcon
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.iconSizeMedium
                height: Theme.iconSizeMedium
                source: "image://theme/" + notesPage.iconForEntry(noteDelegate.entry)
                        + "?" + (noteDelegate.highlighted ? Theme.highlightColor : Theme.primaryColor)
            }

            onClicked: {
                if (type === "folder") {
                    pageStack.animatorPush(notesPageComponent, {
                        currentFolder: path,
                        applicationWindow: notesPage.applicationWindow
                    })
                } else if (type === "image") {
                    openImage(path)
                } else if (type === "note") {
                    openNote(path)
                } else {
                    notesPage.scanStatus = "Unsupported file type"
                }
            }
        }
        VerticalScrollDecorator {}
    }

    Timer {
        id: positionResetTimer
        interval: 1
        onTriggered: listView.positionViewAtBeginning()
    }

    Timer {
        id: searchTimer
        interval: 300
        onTriggered: {
            if (notesPage.status !== PageStatus.Active) {
                notesPage.refreshPending = true
                return
            }
            var query = notesPage.searchQuery.trim()
            if (!query.length) {
                notesPage.refreshFolder(true)
                return
            }

            var result = vault.searchNotes(query)
            if (!result.ok) {
                notesPage.refreshPending = false
                notesPage.updateNotes([], true)
                scanStatus = result.error
                return
            }
            var matches = result.matches
            notesPage.refreshPending = false
            for (var i = 0; i < matches.length; i++)
                matches[i].excerpt = matches[i].excerpt || ""
            notesPage.updateNotes(matches, true)
            scanStatus = result.matches.length
                    ? result.matches.length + " matches across vault"
                    : "No matching notes"
        }
    }

    Component {
        id: notePage
        NotePage {}
    }

    Component {
        id: imagePage
        ImagePage {}
    }

    Component {
        id: settingsPage
        SettingsPage {}
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

    function enterPage() {
        if (!applicationWindow || !applicationWindow.configurationReady) return
        applicationWindow.currentFolder = currentFolder
        applicationWindow.currentNote = ""
        vault.watchFolder(currentFolder)
        if (refreshPending) refreshTimer.restart()
    }

    Component.onCompleted: {
        if (visible) enterPage()
    }
    onVisibleChanged: {
        if (visible) enterPage()
    }

    onCurrentFolderChanged: {
        if (applicationWindow && visible) applicationWindow.currentFolder = currentFolder
    }

    Connections {
        target: vault
        onVaultPathChanged: {
            notesPage.currentFolder = ""
            searchField.text = ""
            notesPage.refreshPending = true
            if (notesPage.visible && applicationWindow.configurationReady) notesPage.enterPage()
        }
        onFolderChanged: {
            if (!applicationWindow.configurationReady) return
            if (notesPage.searchQuery.trim().length) {
                if (notesPage.status === PageStatus.Active) searchTimer.restart()
                else notesPage.refreshPending = true
            } else {
                notesPage.refreshPending = true
                if (notesPage.status === PageStatus.Active) refreshTimer.restart()
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active && refreshPending) refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 1
        onTriggered: {
            if (notesPage.status !== PageStatus.Active || !notesPage.refreshPending) return
            if (notesPage.searchQuery.trim().length) searchTimer.restart()
            else notesPage.refreshFolder(true)
        }
    }

    Connections {
        target: notesPage.applicationWindow
        onConfigurationReadyChanged: if (applicationWindow.configurationReady && notesPage.visible) notesPage.enterPage()
        onShowUnsupportedFilesChanged: {
            if (notesPage.visible && !notesPage.searchQuery.trim().length) notesPage.refreshFolder(true)
        }
    }
}
