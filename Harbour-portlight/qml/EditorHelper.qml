import QtQuick 2.0
import Sailfish.Silica 1.0
import "components"

ApplicationWindow {
    id: helperWindow
    allowedOrientations: Orientation.All
    property bool completed: false

    initialPage: Page {
        id: editorPage

        Column {
            anchors.fill: parent

            PageHeader {
                id: pageHeader
                title: "Edit note"
            }

            WebNoteEditor {
                id: noteEditor
                width: parent.width
                height: parent.height - pageHeader.height - actions.height
                title: editorChannel.title
                text: editorChannel.content
                status: editorChannel.status
                onTextEdited: function(value) {
                    editorChannel.send("edit", { "text": value })
                }
                onTitleEdited: function(value) {
                    editorChannel.send("rename", { "title": value })
                }
            }

            Row {
                id: actions
                width: parent.width
                spacing: Theme.paddingMedium

                Button {
                    width: (parent.width - parent.spacing) / 2
                    text: "Save"
                    onClicked: editorChannel.send("save", { "text": noteEditor.text })
                }
                Button {
                    width: (parent.width - parent.spacing) / 2
                    text: "Cancel"
                    onClicked: {
                        helperWindow.completed = true
                        editorChannel.send("cancel", {})
                        Qt.quit()
                    }
                }
            }
        }
    }

    Component.onCompleted: editorChannel.send("ready", {})

    Connections {
        target: editorChannel
        onCommandReceived: function(type, data) {
            if (type === "close") {
                helperWindow.completed = true
                editorChannel.send("cancel", {})
                Qt.quit()
            } else if (type === "saveResult") {
                if (data.ok === true) {
                    helperWindow.completed = true
                    Qt.quit()
                }
            }
        }
    }

    onVisibleChanged: {
        if (!visible && !completed) {
            completed = true
            editorChannel.send("cancel", {})
        }
    }
}
