import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import "pages"
import "cover"

ApplicationWindow {
    id: app
    allowedOrientations: Orientation.All
    property string currentFolder: ""
    property string currentNote: ""
    property bool configurationReady: false
    property alias vaultPath: persistedSettings.vaultPath
    property alias autoSave: persistedSettings.autoSave
    property alias saveDelay: persistedSettings.saveDelay
    property alias showUnsupportedFiles: persistedSettings.showUnsupportedFiles
    property alias quickNoteFolder: persistedSettings.quickNoteFolder

    ConfigurationGroup {
        id: persistedSettings
        path: "/apps/harbour-portlight"
        synchronous: true

        property string vaultPath: ""
        property bool autoSave: false
        property int saveDelay: 3000
        property bool showUnsupportedFiles: false
        property string quickNoteFolder: "quick-notes"
    }

    function openQuickCapture() {
        var folder = quickNoteFolder
        var folderResult = vault.listVaultEntries(folder)
        if (!folderResult.ok && folder.length) {
            var createFolderResult = vault.createFolder(folder)
            if (createFolderResult.ok) folderResult = vault.listVaultEntries(folder)
        }
        if (!folderResult.ok) {
            pageStack.push(quickCaptureErrorPage, {
                applicationWindow: app,
                statusText: "Quick note folder is unavailable. Choose an accessible folder in Settings."
            })
            return
        }
        var now = new Date()
        function twoDigits(value) { return value < 10 ? "0" + value : value }
        var base = "Quick note " + now.getFullYear() + "-" + twoDigits(now.getMonth() + 1)
                + "-" + twoDigits(now.getDate()) + " " + twoDigits(now.getHours())
                + "-" + twoDigits(now.getMinutes()) + "-" + twoDigits(now.getSeconds())
        var path = (folder.length ? folder + "/" : "") + base + ".md"
        var result = vault.createNote(path, "")
        var suffix = 1
        while (!result.ok && result.error === "A note with that name already exists" && suffix < 1000) {
            path = (folder.length ? folder + "/" : "") + base + " " + suffix + ".md"
            result = vault.createNote(path, "")
            suffix++
        }
        if (!result.ok) {
            pageStack.push(quickCaptureErrorPage, {
                applicationWindow: app,
                statusText: "Unable to create quick note: " + result.error
            })
            return
        }
        pageStack.push(notePage, {
            notePath: path,
            noteContent: "",
            applicationWindow: app,
            quickCapture: true
        })
        app.activate()
    }

    function createNoteFromCover() {
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
            currentNote = path
            pageStack.push(notePage, {
                notePath: path,
                noteContent: "",
                applicationWindow: app
            })
            app.activate()
        }
    }

    initialPage: vaultBrowserPageFactory
    cover: Component {
        CoverPage {
            locationText: app.currentNote.length ? app.currentNote
                                                 : (app.currentFolder.length ? app.currentFolder : "Vault root")
            onCreateNoteRequested: app.createNoteFromCover()
            onQuickCaptureRequested: app.openQuickCapture()
        }
    }

    Component.onCompleted: {
        if (persistedSettings.vaultPath.length) {
            if (vault.setVaultPath(persistedSettings.vaultPath))
                persistedSettings.vaultPath = vault.vaultPath
        } else {
            persistedSettings.vaultPath = vault.vaultPath
        }

        app.configurationReady = true
    }

    Component {
        id: quickCaptureErrorPage
        QuickCaptureErrorPage {}
    }

    Component {
        id: notePage
        NotePage {}
    }

    Component {
        id: vaultBrowserPageFactory
        VaultBrowserPage {
            applicationWindow: app
            vaultBrowserPageComponent: vaultBrowserPageFactory
        }
    }
}
