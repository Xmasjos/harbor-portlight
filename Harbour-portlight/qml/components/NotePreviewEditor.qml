import QtQuick 2.0
import Sailfish.Silica 1.0
import "preview"
import "preview/Parser.js" as Parser
import "preview/ListBlock.js" as ListMatcher
import "preview/ChecklistItem.js" as ChecklistMatcher
import "preview/InlineMarkdown.js" as InlineMarkdown

Item {
    id: notePreviewEditor

    property string title
    property string text
    property string status
    property string notePath
    property var blocks: []
    property string sourceText: ""
    property int activeIndex: -1
    property int activeBlockEnd: -1
    property real implicitContentHeight: titleField.implicitHeight + contentColumn.implicitHeight
                                         + statusLabel.implicitHeight

    signal textEdited(string text)
    signal titleEdited(string title)
    signal linkActivated(string url)

    function resetTitle() {
        titleField.text = notePreviewEditor.title
    }

    function noteFolder(path) {
        var slash = path.lastIndexOf("/")
        return slash < 0 ? "" : path.substring(0, slash)
    }

    function renderPreviewInline(source) {
        return InlineMarkdown.render(source, sourceText, noteFolder(notePath), function(path) {
            return vault.imageUrl(path)
        })
    }

    function insertedNewlinePosition(previous, current, cursor) {
        var prefixLength = 0
        while (prefixLength < previous.length && prefixLength < current.length
               && previous.charAt(prefixLength) === current.charAt(prefixLength))
            prefixLength++

        var suffixLength = 0
        while (suffixLength < previous.length - prefixLength
               && suffixLength < current.length - prefixLength
               && previous.charAt(previous.length - suffixLength - 1)
                  === current.charAt(current.length - suffixLength - 1))
            suffixLength++

        var oldChangedText = previous.substring(prefixLength, previous.length - suffixLength)
        var changedText = current.substring(prefixLength, current.length - suffixLength)
        var newlineOffset = changedText.indexOf("\n")
        if (newlineOffset < 0 || oldChangedText.indexOf("\n") >= 0) return -1

        var position = cursor - 1
        return current.charAt(position) === "\n" ? position : prefixLength + newlineOffset
    }

    function listContinuation(line) {
        var list = ListMatcher.matchList(line)
        if (!list) return null

        var marker = list[2]
        var number = /^(\d+)([.)])$/.exec(marker)
        if (number) marker = (parseInt(number[1], 10) + 1) + number[2]
        var task = ChecklistMatcher.matchTask(list[3])
        return list[1] + marker + " " + (task ? "[ ] " : "")
    }

    function toggleTask(blockIndex, itemIndex) {
        if (blockIndex < 0 || blockIndex >= blocks.length) return
        var block = blocks[blockIndex]
        if (itemIndex < 0 || itemIndex >= block.items.length) return

        var item = block.items[itemIndex]
        var line = sourceText.substring(item.start, item.end)
        var taskLine = ChecklistMatcher.toggleLine(line)
        if (taskLine === line) return

        sourceText = sourceText.substring(0, item.start)
                   + taskLine
                   + sourceText.substring(item.end)
        blocks = Parser.parseBlocks(sourceText)
        textEdited(sourceText)
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
                property var blockViews: ({
                    paragraph: textBlock,
                    heading: headingBlock,
                    "horizontal-rule": ruleBlock,
                    code: codeBlockView,
                    table: tableBlockView,
                    list: listBlock,
                    blockquote: quoteBlock
                })
                width: contentColumn.width
                implicitHeight: editing ? editArea.height : blockViews[block.type].implicitHeight
                height: implicitHeight

                TextBlock {
                    id: textBlock
                    visible: !blockItem.editing && blockItem.block.type === "paragraph"
                    width: blockItem.width
                    block: blockItem.block
                    renderInline: notePreviewEditor.renderPreviewInline
                    onActivated: notePreviewEditor.activate(blockItem.block)
                    onLinkActivated: notePreviewEditor.linkActivated(url)
                }

                HeadingBlock {
                    id: headingBlock
                    visible: !blockItem.editing && blockItem.block.type === "heading"
                    width: blockItem.width
                    block: blockItem.block
                    renderInline: notePreviewEditor.renderPreviewInline
                    onActivated: notePreviewEditor.activate(blockItem.block)
                    onLinkActivated: notePreviewEditor.linkActivated(url)
                }

                RuleBlock {
                    id: ruleBlock
                    visible: !blockItem.editing
                             && blockItem.block.type === "horizontal-rule"
                    width: blockItem.width
                    onActivated: notePreviewEditor.activate(blockItem.block)
                }

                CodeBlock {
                    id: codeBlockView
                    visible: !blockItem.editing && blockItem.block.type === "code"
                    width: blockItem.width
                    block: blockItem.block
                    onActivated: notePreviewEditor.activate(blockItem.block)
                }

                TableBlock {
                    id: tableBlockView
                    visible: !blockItem.editing && blockItem.block.type === "table"
                    width: blockItem.width
                    block: blockItem.block
                    renderInline: notePreviewEditor.renderPreviewInline
                    onActivated: notePreviewEditor.activate(blockItem.block)
                    onLinkActivated: notePreviewEditor.linkActivated(url)
                }

                ListBlock {
                    id: listBlock
                    visible: !blockItem.editing && blockItem.block.type === "list"
                    width: blockItem.width
                    block: blockItem.block
                    renderInline: notePreviewEditor.renderPreviewInline
                    onActivated: notePreviewEditor.activate(blockItem.block)
                    onTaskToggled: notePreviewEditor.toggleTask(blockItem.blockIndex, itemIndex)
                    onLinkActivated: notePreviewEditor.linkActivated(url)
                }

                QuoteBlock {
                    id: quoteBlock
                    visible: !blockItem.editing && blockItem.block.type === "blockquote"
                    width: blockItem.width
                    block: blockItem.block
                    renderInline: notePreviewEditor.renderPreviewInline
                    onActivated: notePreviewEditor.activate(blockItem.block)
                    onLinkActivated: notePreviewEditor.linkActivated(url)
                }

                TextArea {
                    id: editArea
                    property string previousText: ""
                    property bool expandingTaskItem: false
                    visible: blockItem.editing
                    width: blockItem.width
                    height: visible ? Math.max(Theme.itemSizeMedium, implicitHeight) : 0
                    text: blockItem.block.source
                    placeholderText: "Markdown source"
                    label: "Paragraph source"
                    onVisibleChanged: {
                        if (visible) {
                            previousText = text
                            forceActiveFocus()
                        }
                    }
                    onTextChanged: {
                        if (!blockItem.editing || expandingTaskItem) return

                        var newlinePosition = notePreviewEditor.insertedNewlinePosition(
                                    previousText, text, cursorPosition)
                        if (newlinePosition >= 0) {
                            var lineStart = text.lastIndexOf("\n", newlinePosition - 1) + 1
                            var continuation = notePreviewEditor.listContinuation(
                                        text.substring(lineStart, newlinePosition))
                            if (continuation !== null) {
                                var insertPosition = newlinePosition + 1
                                var updatedText = text.substring(0, insertPosition) + continuation
                                                + text.substring(insertPosition)
                                expandingTaskItem = true
                                text = updatedText
                                cursorPosition = insertPosition + continuation.length
                                expandingTaskItem = false
                            }
                        }

                        previousText = text
                        if (blockItem.block.source !== text)
                            notePreviewEditor.updateBlock(index, text)
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
