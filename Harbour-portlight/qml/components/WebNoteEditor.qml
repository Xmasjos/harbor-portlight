import QtQuick 2.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0

Item {
    id: editor

    property string title
    property string text
    property string status
    property bool editorLoaded: false
    property bool handlingEditorText: false

    signal textEdited(string text)
    signal titleEdited(string title)

    Component.onCompleted: console.debug("[WebNoteEditor] component created")
    Component.onDestruction: console.debug("[WebNoteEditor] component destroyed")

    function updateText() {
        if (editor.editorLoaded) {
            console.debug("[WebNoteEditor] sync-to-page length=" + editor.text.length)
            webView.runJavaScript("window.setNoteText(" + JSON.stringify(editor.text) + ")")
        }
    }

    function updateTitle() {
        if (editor.editorLoaded)
            webView.runJavaScript("window.setNoteTitle(" + JSON.stringify(editor.title) + ")")
    }

    function updateStatus() {
        if (editor.editorLoaded)
            webView.runJavaScript("window.setNoteStatus(" + JSON.stringify(editor.status) + ")")
    }

    onTextChanged: {
        if (handlingEditorText)
            console.debug("[WebNoteEditor] suppress-echo length=" + editor.text.length)
        else
            updateText()
    }
    onTitleChanged: updateTitle()
    onStatusChanged: updateStatus()

    WebView {
        id: webView
        anchors.fill: parent
        url: Qt.resolvedUrl("../editor/index.html")

        onViewInitialized: {
            console.debug("[WebNoteEditor] WebView initialized")
            webView.addMessageListener("portlight:noteChanged")
            webView.addMessageListener("portlight:titleChanged")
            webView.loadFrameScript(Qt.resolvedUrl("../editor/frame.js"))
        }
        onLoadingChanged: {
            console.debug("[WebNoteEditor] WebView loading changed: loading=" + loading)
            if (!loading) {
                editor.editorLoaded = true
                editor.updateText()
                editor.updateTitle()
                editor.updateStatus()
            }
        }
        Component.onDestruction: console.debug("[WebNoteEditor] WebView component destroyed")
        onRecvAsyncMessage: function(message, data) {
            if (message === "portlight:noteChanged" && data
                    && typeof data.text === "string") {
                console.debug("[WebNoteEditor] noteChanged length=" + data.text.length)
                editor.handlingEditorText = true
                editor.textEdited(data.text)
                editor.handlingEditorText = false
            } else if (message === "portlight:titleChanged" && data
                       && typeof data.title === "string") {
                var title = data.title.trim()
                if (title.length > 0 && title.length <= 255
                        && title.indexOf("/") < 0 && title.indexOf("\\") < 0
                        && title.indexOf("\u0000") < 0
                        && title !== "." && title !== "..")
                    editor.titleEdited(title)
            }
        }
    }
}
