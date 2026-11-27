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

    function createNoteWithUniqueName(pathForSuffix, createNote) {
        var suffix = 0
        var path = pathForSuffix(suffix)
        var result = createNote(path)
        while (!result.ok && result.error === "A note with that name already exists" && suffix < 999) {
            suffix++
            path = pathForSuffix(suffix)
            result = createNote(path)
        }
        return { path: path, result: result }
    }

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
        var created = app.createNoteWithUniqueName(function(suffix) {
            return (folder.length ? folder + "/" : "") + base
                    + (suffix ? " " + suffix : "") + ".md"
        }, function(path) { return vault.createNote(path, "") })
        var path = created.path
        var result = created.result
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
        var created = app.createNoteWithUniqueName(function(suffix) {
            return base + "Untitled" + (suffix ? " " + suffix : "") + ".md"
        }, function(path) { return vault.createNote(path, "") })
        var path = created.path
        var result = created.result
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
