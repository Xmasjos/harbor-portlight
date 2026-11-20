import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import "../components"

Page {
    allowedOrientations: Orientation.All
    id: vaultBrowserPage
    property var applicationWindow
    property Component vaultBrowserPageComponent
    property string currentFolder: ""
    property string scanStatus: "Loading vault…"
    property string searchQuery: ""
    property bool searchActive: searchQuery.trim().length >= 2
    property bool searchLoading: false
    property bool refreshPending: true
    property string folderTitle: currentFolder.length
            ? currentFolder.slice(currentFolder.lastIndexOf("/") + 1)
            : "Obsidian notes"
    signal clearSearchRequested()

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
            console.warn("[VaultBrowserPage] Unable to list vault entries:", result.error)
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
                applicationWindow: vaultBrowserPage.applicationWindow
            })
        } else {
            scanStatus = result.error
            console.warn("[VaultBrowserPage] Unable to open note:", result.error)
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
                applicationWindow: vaultBrowserPage.applicationWindow
            })
        } else {
            scanStatus = result.error
            console.warn("[VaultBrowserPage] Unable to create note:", result.error)
        }
    }

    function parentFolder(path) {
        var slash = path.lastIndexOf("/")
        return slash < 0 ? "" : path.substring(0, slash)
    }

    function clearSearch() {
        clearSearchRequested()
        searchQuery = ""
        searchTimer.stop()
    }

    function askPath(title, initialText, placeholder, callback, destination, destinationType, properties) {
        properties = properties || ({})
        properties.applicationWindow = vaultBrowserPage.applicationWindow
        pageStack.push(pathDialog, {
            dialogTitle: title,
            initialText: initialText,
            pathPlaceholder: placeholder,
            acceptCallback: callback,
            sourcePage: vaultBrowserPage,
            destinationType: destinationType,
            acceptDestination: destination,
            acceptDestinationProperties: properties,
            acceptDestinationAction: PageStackAction.Replace,
            acceptDestinationReplaceTarget: vaultBrowserPage
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

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: height

        PullDownMenu {
            MenuItem {
                text: "Settings"
                onClicked: pageStack.push(settingsPage, {
                    applicationWindow: vaultBrowserPage.applicationWindow
                })
            }
            MenuItem {
                text: applicationWindow.showUnsupportedFiles ? "Hide unsupported files" : "Show unsupported files"
                onClicked: {
                    applicationWindow.showUnsupportedFiles = !applicationWindow.showUnsupportedFiles
                    if (!vaultBrowserPage.searchActive) vaultBrowserPage.refreshFolder(true)
                }
            }
            MenuItem {
                text: "Create folder"
                onClicked: vaultBrowserPage.askPath("New folder", "", "Folder name or vault path", function(name, dialog) {
                    var path = vaultBrowserPage.currentFolder.length ? vaultBrowserPage.currentFolder + "/" + name : name
                    var result = vault.createFolder(path)
                    if (result.ok) dialog.acceptDestinationInstance.refreshFolder()
                    else dialog.returnToSource(result.error)
                }, vaultBrowserPageComponent, "folder", { currentFolder: vaultBrowserPage.currentFolder })
            }
            MenuItem {
                text: "Create note"
                onClicked: vaultBrowserPage.createUntitledNote()
            }
        }

        Column {
            id: mainColumn
            width: parent.width
            height: parent.height

            Column {
                id: browserHeader
                width: parent.width
                height: implicitHeight
                PageHeader {
                    title: vaultBrowserPage.folderTitle
                    description: vaultBrowserPage.currentFolder.length ? vaultBrowserPage.currentFolder : "Vault root"
                }
                SearchField {
                    id: searchField
                    width: parent.width
                    placeholderText: "Search notes"
                    onTextChanged: {
                        vaultBrowserPage.searchQuery = text
                        vaultBrowserPage.searchLoading = vaultBrowserPage.searchActive
                        searchTimer.restart()
                    }
                    rightItem: Row {
                        width: implicitWidth
                        spacing: Theme.paddingSmall
                        BusyIndicator {
                            anchors.verticalCenter: clearSearchButton.verticalCenter
                            size: BusyIndicatorSize.Small
                            width: Theme.iconSizeSmall
                            height: Theme.iconSizeSmall
                            running: vaultBrowserPage.searchLoading
                            visible: running
                        }
                        IconButton {
                            id: clearSearchButton
                            icon.source: "image://theme/icon-m-clear"
                            enabled: searchField.text.length > 0
                            opacity: enabled ? 1.0 : 0.0
                            Behavior on opacity { FadeAnimation {} }
                            onClicked: searchField.text = ""
                        }
                    }
                }
                Connections {
                    target: vaultBrowserPage
                    onClearSearchRequested: searchField.text = ""
                }
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    text: vaultBrowserPage.scanStatus
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
                }
            }

            SilicaListView {
                id: listView
                width: parent.width
                height: parent.height - browserHeader.height
                clip: true
                model: notesModel
                delegate: VaultEntryDelegate {
                    entry: ({ type: type, name: name, path: path, excerpt: excerpt, hasItems: hasItems })
                    width: listView.width
                    searchActive: vaultBrowserPage.searchActive
                    iconName: vaultBrowserPage.iconForEntry(entry)
                    renameCallback: function(entry) {
                        var sourcePath = entry.path
                        var isFolder = entry.type === "folder"
                        vaultBrowserPage.askPath(isFolder ? "Rename folder" : "Rename note", sourcePath,
                                     "Name and extension", function(path, dialog) {
                            var result = isFolder ? vault.moveFolder(sourcePath, path)
                                                  : vault.moveNote(sourcePath, path)
                            if (result.ok) dialog.acceptDestinationInstance.refreshFolder()
                            else dialog.returnToSource(result.error)
                        }, vaultBrowserPageComponent, "destination",
                        { currentFolder: vaultBrowserPage.parentFolder(sourcePath) })
                    }
                    copyCallback: function(entry) {
                        var sourcePath = entry.path
                        var isFolder = entry.type === "folder"
                        var defaultPath = isFolder ? sourcePath + " copy"
                                                    : sourcePath.replace(/\.md$/i, " copy.md")
                        vaultBrowserPage.askPath(isFolder ? "Copy folder to" : "Copy note to", defaultPath,
                                     "Destination path", function(path, dialog) {
                            var result = isFolder ? vault.copyFolder(sourcePath, path)
                                                  : vault.copyNote(sourcePath, path)
                            if (result.ok) dialog.acceptDestinationInstance.refreshFolder()
                            else dialog.returnToSource(result.error)
                        }, vaultBrowserPageComponent, "destination",
                        { currentFolder: vaultBrowserPage.parentFolder(defaultPath) })
                    }
                    moveCallback: function(entry) {
                        pageStack.push(moveFolderPicker, {
                            sourcePath: entry.path,
                            isFolder: entry.type === "folder"
                        })
                    }
                    deleteCallback: function(entry) {
                        if (entry.type !== "folder") {
                            vaultBrowserPage.deleteNote(entry.path)
                        } else {
                            var result = vault.deleteFolder(entry.path)
                            if (result.ok) vaultBrowserPage.refreshFolder()
                            else vaultBrowserPage.scanStatus = result.error
                        }
                    }
                    activateCallback: function(entry) {
                        if (entry.type === "folder") {
                            pageStack.animatorPush(vaultBrowserPageComponent, {
                                currentFolder: entry.path,
                                applicationWindow: vaultBrowserPage.applicationWindow
                            })
                        } else if (entry.type === "image") {
                            vaultBrowserPage.openImage(entry.path)
                        } else if (entry.type === "note") {
                            vaultBrowserPage.openNote(entry.path)
                        } else {
                            vaultBrowserPage.scanStatus = "Unsupported file type"
                        }
                    }
                }
                VerticalScrollDecorator {}
            }
        }
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
            if (vaultBrowserPage.status !== PageStatus.Active) {
                vaultBrowserPage.refreshPending = true
                vaultBrowserPage.searchLoading = false
                return
            }
            if (!vaultBrowserPage.searchActive) {
                vaultBrowserPage.searchLoading = false
                vaultBrowserPage.refreshFolder(true)
                return
            }

            var query = vaultBrowserPage.searchQuery.trim()
            var result = vault.searchNotes(query)
            vaultBrowserPage.searchLoading = false
            if (!result.ok) {
                vaultBrowserPage.refreshPending = false
                vaultBrowserPage.updateNotes([], true)
                scanStatus = result.error
                console.warn("[VaultBrowserPage] Note search failed:", result.error)
                return
            }
            var matches = result.matches
            vaultBrowserPage.refreshPending = false
            for (var i = 0; i < matches.length; i++)
                matches[i].excerpt = matches[i].excerpt || ""
            vaultBrowserPage.updateNotes(matches, true)
            scanStatus = matches.length
                    ? matches.length + " matches across vault"
                    : "No matching notes"
            console.debug("[VaultBrowserPage] Note search completed; matches:", matches.length)
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
        id: moveFolderPicker
        FolderPickerDialog {
            property string sourcePath: ""
            property bool isFolder: false
            title: isFolder ? "Move folder to" : "Move note to"
            path: vault.vaultPath

            onAccepted: {
                var root = vault.vaultPath
                var selected = selectedPath.replace(/\/$/, "")
                var destinationFolder
                if (selected === root) {
                    destinationFolder = ""
                } else if (selected.indexOf(root + "/") === 0) {
                    destinationFolder = selected.substring(root.length + 1)
                } else {
                    vaultBrowserPage.scanStatus = "Choose a folder inside the configured vault"
                    return
                }

                var name = sourcePath.substring(sourcePath.lastIndexOf("/") + 1)
                var destination = destinationFolder.length
                        ? destinationFolder + "/" + name : name
                var result = isFolder ? vault.moveFolder(sourcePath, destination)
                                      : vault.moveNote(sourcePath, destination)
                if (result.ok) {
                    vaultBrowserPage.clearSearch()
                    vaultBrowserPage.currentFolder = destinationFolder
                    vaultBrowserPage.refreshFolder(true)
                } else {
                    vaultBrowserPage.scanStatus = result.error
                }
            }
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
            vaultBrowserPage.currentFolder = ""
            vaultBrowserPage.clearSearch()
            vaultBrowserPage.refreshPending = true
            if (vaultBrowserPage.visible && applicationWindow.configurationReady) vaultBrowserPage.enterPage()
        }
        onFolderChanged: {
            if (!applicationWindow.configurationReady) return
            if (vaultBrowserPage.searchActive) {
                if (vaultBrowserPage.status === PageStatus.Active) {
                    vaultBrowserPage.searchLoading = true
                    searchTimer.restart()
                }
                else vaultBrowserPage.refreshPending = true
            } else {
                vaultBrowserPage.refreshPending = true
                if (vaultBrowserPage.status === PageStatus.Active) refreshTimer.restart()
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
            if (!vaultBrowserPage.visible || !vaultBrowserPage.refreshPending) return
            if (vaultBrowserPage.searchActive) {
                vaultBrowserPage.searchLoading = true
                searchTimer.restart()
            } else {
                vaultBrowserPage.refreshFolder(true)
            }
        }
    }

    Connections {
        target: vaultBrowserPage.applicationWindow
        onConfigurationReadyChanged: if (applicationWindow.configurationReady && vaultBrowserPage.visible) vaultBrowserPage.enterPage()
        onShowUnsupportedFilesChanged: {
            if (vaultBrowserPage.visible && !vaultBrowserPage.searchActive) vaultBrowserPage.refreshFolder(true)
        }
    }
}
