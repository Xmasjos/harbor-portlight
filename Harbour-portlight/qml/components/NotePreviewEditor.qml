import QtQuick 2.0
import Sailfish.Silica 1.0
import "preview"
import "preview/Parser.js" as Parser

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

    function toggleTask(blockIndex, itemIndex) {
        if (blockIndex < 0 || blockIndex >= blocks.length) return
        var block = blocks[blockIndex]
        if (itemIndex < 0 || itemIndex >= block.items.length) return

        var item = block.items[itemIndex]
        var line = sourceText.substring(item.start, item.end)
        var taskLine = line.replace(/^([ \t]*(?:[-+*]|\d+[.)])[ \t]+\[)([ xX])(\][ \t]*)/,
                                     function(match, prefix, state, suffix) {
                                         return prefix + (state.toLowerCase() === "x" ? " " : "x") + suffix
                                     })
        if (taskLine === line) return

        sourceText = sourceText.substring(0, item.start)
                   + taskLine
                   + sourceText.substring(item.end)
        blocks = Parser.parseBlocks(sourceText)
        textEdited(sourceText)
    }

    function escapeHtml(value) {
        return value.replace(/&/g, "&amp;")
                    .replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;")
                    .replace(/"/g, "&quot;")
                    .replace(/'/g, "&#39;")
                    .replace(/\n/g, "<br>")
    }

    function renderInline(source) {
        var output = ""
        var plain = ""
        var i = 0

        function flushPlain() {
            if (!plain.length) return
            output += escapeHtml(plain)
            plain = ""
        }

        while (i < source.length) {
            var character = source.charAt(i)

            if (character === "\\" && i + 1 < source.length) {
                plain += source.charAt(i + 1)
                i += 2
                continue
            }

            if (character === "~" && source.substr(i, 2) === "~~") {
                var strikeClose = source.indexOf("~~", i + 2)
                if (strikeClose >= i + 2) {
                    var strikeText = source.substring(i + 2, strikeClose)
                    if (strikeText.length) {
                        flushPlain()
                        output += "<s>" + notePreviewEditor.renderInline(strikeText) + "</s>"
                        i = strikeClose + 2
                        continue
                    }
                }
            }

            if (character !== "*" && character !== "_") {
                plain += character
                i++
                continue
            }

            var markerLength = 1
            if (source.substr(i, 3) === character + character + character)
                markerLength = 3
            else if (source.substr(i, 2) === character + character)
                markerLength = 2

            var markerText = markerLength === 3
                           ? "***" : (markerLength === 2 ? "**" : "*")
            if (character === "_")
                markerText = markerLength === 3
                           ? "___" : (markerLength === 2 ? "__" : "_")

            var close = source.indexOf(markerText, i + markerLength)
            if (close < 0) {
                plain += character
                i++
                continue
            }

            var inner = source.substring(i + markerLength, close)
            if (!inner.length) {
                plain += character
                i++
                continue
            }

            if (markerLength === 1 && character === "_"
                    && ((i > 0 && /\w/.test(source.charAt(i - 1)))
                        || (close + 1 < source.length
                            && /\w/.test(source.charAt(close + 1)))))
                inner = null

            if (inner === null) {
                plain += character
                i++
                continue
            }

            flushPlain()
            var rendered = notePreviewEditor.renderInline(inner)
            if (markerLength === 3)
                output += "<b><i>" + rendered + "</i></b>"
            else if (markerLength === 2)
                output += "<b>" + rendered + "</b>"
            else
                output += "<i>" + rendered + "</i>"
            i = close + markerLength
        }

        flushPlain()
        return output
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
        blocks = Parser.parseBlocks(sourceText)
    }

    onTextChanged: {
        if (text !== sourceText) {
            sourceText = text
            activeIndex = -1
            activeBlockEnd = -1
            blocks = Parser.parseBlocks(text)
        }
    }

    onTitleChanged: resetTitle()
    Component.onCompleted: {
        sourceText = text
        blocks = Parser.parseBlocks(text)
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
                property int blockIndex: index
                property bool editing: notePreviewEditor.activeIndex === index
                width: contentColumn.width
                height: editing ? editArea.height
                                : (block.type === "horizontal-rule"
                                   ? ruleBlock.implicitHeight
                                   : (block.type === "list"
                                      ? listBlock.implicitHeight
                                      : (block.type === "blockquote"
                                         ? quoteBlock.implicitHeight
                                         : textBlock.implicitHeight)))

                TextBlock {
                    id: textBlock
                    visible: !blockItem.editing
                             && blockItem.block.type !== "list"
                             && blockItem.block.type !== "blockquote"
                             && blockItem.block.type !== "horizontal-rule"
                    width: blockItem.width
                    block: blockItem.block
                    renderInline: notePreviewEditor.renderInline
                    onActivated: notePreviewEditor.activate(blockItem.block)
                }

                RuleBlock {
                    id: ruleBlock
                    visible: !blockItem.editing
                             && blockItem.block.type === "horizontal-rule"
                    width: blockItem.width
                    onActivated: notePreviewEditor.activate(blockItem.block)
                }

                ListBlock {
                    id: listBlock
                    visible: !blockItem.editing && blockItem.block.type === "list"
                    width: blockItem.width
                    block: blockItem.block
                    renderInline: notePreviewEditor.renderInline
                    onActivated: notePreviewEditor.activate(blockItem.block)
                    onTaskToggled: notePreviewEditor.toggleTask(blockItem.blockIndex, itemIndex)
                }

                QuoteBlock {
                    id: quoteBlock
                    visible: !blockItem.editing && blockItem.block.type === "blockquote"
                    width: blockItem.width
                    block: blockItem.block
                    renderInline: notePreviewEditor.renderInline
                    onActivated: notePreviewEditor.activate(blockItem.block)
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
