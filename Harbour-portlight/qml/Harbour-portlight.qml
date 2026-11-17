import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "cover"

ApplicationWindow {
    id: app
    property string currentFolder: ""
    property string currentNote: ""

    function createNoteFromCover() {
        var base = currentFolder.length ? currentFolder + "/" : ""
        var path = base + "New note.md"
        var suffix = 2
        var result = vault.createNote(path, "")
        while (!result.ok && suffix < 1000) {
            if (result.error !== "A note with that name already exists") break
            path = base + "New note " + suffix + ".md"
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
}
