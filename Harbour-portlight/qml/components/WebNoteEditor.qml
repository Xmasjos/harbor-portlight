import QtQuick 2.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0

Item {
    id: editor

    property string title
    property string text
    property bool editorLoaded: false

    signal textEdited(string text)

    function updateText() {
        if (editor.editorLoaded)
            webView.runJavaScript("window.setNoteText(" + JSON.stringify(editor.text) + ")")
    }

    onTextChanged: updateText()

    WebView {
        id: webView
        anchors.fill: parent
        url: Qt.resolvedUrl("../editor.html")

        onViewInitialized: {
            webView.addMessageListener("portlight:noteChanged")
            webView.loadFrameScript(Qt.resolvedUrl("../editor-frame.js"))
        }
        onLoadingChanged: {
            if (!loading) {
                editor.editorLoaded = true
                editor.updateText()
            }
        }
        onRecvAsyncMessage: function(message, data) {
            if (message === "portlight:noteChanged" && data && typeof data.text === "string")
                editor.textEdited(data.text)
        }
    }
}
