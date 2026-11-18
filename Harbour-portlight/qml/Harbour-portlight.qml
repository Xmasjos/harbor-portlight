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

    ConfigurationGroup {
        id: persistedSettings
        path: "/apps/harbour-portlight"
        synchronous: true

        property string vaultPath: ""
        property bool autoSave: false
        property int saveDelay: 3000
        property bool showUnsupportedFiles: false
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
            pageStack.push(Qt.resolvedUrl("pages/NotePage.qml"), {
                notePath: path,
                noteContent: "",
                applicationWindow: app
            })
            app.activate()
        }
    }

    initialPage: Component { NotesPage { applicationWindow: app } }
    cover: Component {
        CoverPage {
            locationText: app.currentNote.length ? app.currentNote
                                                 : (app.currentFolder.length ? app.currentFolder : "Vault root")
            onCreateNoteRequested: app.createNoteFromCover()
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
}
