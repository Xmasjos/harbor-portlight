import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: notePreviewEditor

    property string title
    property string text
    property string status
    property var blocks: []
    property string sourceText: ""
    property int activeIndex: -1
    property int activeBlockEnd: -1
    property real implicitContentHeight: titleField.implicitHeight + contentColumn.implicitHeight
                                         + statusLabel.implicitHeight

    signal textEdited(string text)
    signal titleEdited(string title)

    function resetTitle() {
        titleField.text = notePreviewEditor.title
    }

    function parseBlocks(value) {
        var parsed = []
        var paragraphStart = -1
        var paragraphEnd = -1
        var lineStart = 0

        while (lineStart <= value.length) {
            var newline = value.indexOf("\n", lineStart)
            var lineEnd = newline < 0 ? value.length : newline
            var contentEnd = lineEnd
            if (contentEnd > lineStart && value.charAt(contentEnd - 1) === "\r") contentEnd--

            if (value.substring(lineStart, contentEnd).trim().length) {
                if (paragraphStart < 0) paragraphStart = lineStart
                paragraphEnd = contentEnd
            } else if (paragraphStart >= 0) {
                var paragraph = value.substring(paragraphStart, paragraphEnd)
                parsed.push({ start: paragraphStart, end: paragraphEnd, source: paragraph })
                paragraphStart = -1
            }

            if (newline < 0) break
            lineStart = newline + 1
        }

        if (paragraphStart >= 0) {
            parsed.push({
                start: paragraphStart,
                end: paragraphEnd,
                source: value.substring(paragraphStart, paragraphEnd)
            })
        }

        if (!parsed.length) parsed.push({ start: 0, end: value.length, source: value })
        return parsed
    }

    function activate(targetBlock) {
        var targetStart = targetBlock.start
        if (activeIndex >= 0) {
            var currentBlock = blocks[activeIndex]
            if (targetStart >= currentBlock.end)
                targetStart += activeBlockEnd - currentBlock.end
            finishEditing()
        }

        for (var i = 0; i < blocks.length; i++) {
            if (targetStart >= blocks[i].start && targetStart <= blocks[i].end) {
                activeIndex = i
                activeBlockEnd = blocks[i].end
                return
            }
        }
    }

    function updateBlock(index, value) {
        var block = blocks[index]
        sourceText = sourceText.substring(0, block.start) + value + sourceText.substring(activeBlockEnd)
        activeBlockEnd = block.start + value.length
        textEdited(sourceText)
    }

    function finishEditing() {
        if (activeIndex < 0) return
        activeIndex = -1
        activeBlockEnd = -1
        blocks = parseBlocks(sourceText)
    }

    onTextChanged: {
        if (text !== sourceText) {
            sourceText = text
            activeIndex = -1
            activeBlockEnd = -1
            blocks = parseBlocks(text)
        }
    }

    onTitleChanged: resetTitle()
    Component.onCompleted: {
        sourceText = text
        blocks = parseBlocks(text)
    }

    TextField {
        id: titleField
        width: notePreviewEditor.width
        text: notePreviewEditor.title
        label: "Note name"
        placeholderText: "Untitled"
        EnterKey.onClicked: notePreviewEditor.titleEdited(text)
        onActiveFocusChanged: if (!activeFocus) notePreviewEditor.titleEdited(text)
    }

    Column {
        id: contentColumn
        y: titleField.height
        width: notePreviewEditor.width
        spacing: Theme.paddingMedium

        Repeater {
            model: notePreviewEditor.blocks

            delegate: Item {
                id: blockItem
                property var block: modelData
                property bool editing: notePreviewEditor.activeIndex === index
                width: contentColumn.width
                height: editing ? editArea.height : displayLabel.implicitHeight

                Label {
                    id: displayLabel
                    visible: !blockItem.editing
                    x: Theme.horizontalPageMargin
                    width: blockItem.width - Theme.horizontalPageMargin * 2
                    text: blockItem.block.source.trim().length
                          ? blockItem.block.source : "Tap to add a paragraph"
                    textFormat: Text.PlainText
                    color: Theme.primaryColor
                    wrapMode: Text.Wrap
                }

                MouseArea {
                    anchors.fill: displayLabel
                    onClicked: notePreviewEditor.activate(blockItem.block)
                }

                TextArea {
                    id: editArea
                    visible: blockItem.editing
                    width: blockItem.width
                    height: visible ? Math.max(Theme.itemSizeMedium, implicitHeight) : 0
                    text: blockItem.block.source
                    placeholderText: "Markdown source"
                    label: "Paragraph source"
                    onVisibleChanged: if (visible) forceActiveFocus()
                    onTextChanged: {
                        if (blockItem.editing && blockItem.block.source !== text) {
                            notePreviewEditor.updateBlock(index, text)
                        }
                    }
                    onActiveFocusChanged: {
                        if (!activeFocus && blockItem.editing)
                            notePreviewEditor.finishEditing()
                    }
                }
            }
        }
    }

    Label {
        id: statusLabel
        x: Theme.horizontalPageMargin
        y: contentColumn.y + contentColumn.height
        width: notePreviewEditor.width - Theme.horizontalPageMargin * 2
        text: notePreviewEditor.status
        color: Theme.secondaryColor
        wrapMode: Text.Wrap
    }
}
