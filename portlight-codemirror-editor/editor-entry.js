import { basicSetup, EditorView } from "codemirror";
import { markdown } from "@codemirror/lang-markdown";

var applyingText = false;
var lineEndings = [];
var defaultLineEnding = "\n";
var noteText = document.getElementById("note");

var theme = EditorView.theme({
    "&": {
        height: "100%",
        backgroundColor: "transparent",
        color: "#fff"
    },
    ".cm-content": {
        padding: "16px",
        fontFamily: "sans-serif",
        fontSize: "18px",
        lineHeight: "1.4",
        caretColor: "#fff"
    },
    ".cm-line": {
        padding: "0"
    },
    ".cm-scroller": {
        overflow: "auto",
        fontFamily: "sans-serif"
    },
    ".cm-gutters": {
        backgroundColor: "transparent",
        border: "0",
        color: "#777"
    },
    "&.cm-focused": {
        outline: "0"
    },
    ".cm-selectionBackground, &.cm-focused .cm-selectionBackground": {
        backgroundColor: "#354e66"
    }
}, { dark: true });

var view = new EditorView({
    doc: "",
    parent: noteText,
    extensions: [
        basicSetup,
        markdown(),
        EditorView.lineWrapping,
        theme,
        EditorView.updateListener.of(function(update) {
            if (update.docChanged && !applyingText) {
                var lines = update.state.doc.toString().split("\n");
                var restored = lines.map(function(line, index) {
                    return line + (index < lines.length - 1
                        ? (lineEndings[index] || defaultLineEnding)
                        : "");
                }).join("");
                view.contentDOM.setAttribute("data-portlight-text", restored);
            }
        })
    ]
});

window.setNoteText = function(text) {
    if (typeof text !== "string")
        return;

    lineEndings = text.match(/\r\n|\r|\n/g) || [];
    defaultLineEnding = lineEndings[0] || "\n";
    view.contentDOM.setAttribute("data-portlight-text", text);

    var normalized = text.replace(/\r\n|\r/g, "\n");
    if (view.state.doc.toString() === normalized)
        return;

    applyingText = true;
    view.dispatch({
        changes: { from: 0, to: view.state.doc.length, insert: normalized }
    });
    applyingText = false;
};
