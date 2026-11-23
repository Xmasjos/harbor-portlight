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
        var listStart = -1
        var listEnd = -1
        var listItems = []
        var quoteStart = -1
        var quoteEnd = -1
        var quoteItems = []
        var lineStart = 0

        function flushList() {
            if (listStart < 0) return
            parsed.push({
                start: listStart,
                end: listEnd,
                source: value.substring(listStart, listEnd),
                type: "list",
                items: listItems
            })
            listStart = -1
            listEnd = -1
            listItems = []
        }

        function flushQuote() {
            if (quoteStart < 0) return
            parsed.push({
                start: quoteStart,
                end: quoteEnd,
                source: value.substring(quoteStart, quoteEnd),
                type: "blockquote",
                items: quoteItems
            })
            quoteStart = -1
            quoteEnd = -1
            quoteItems = []
        }

        while (lineStart <= value.length) {
            var newline = value.indexOf("\n", lineStart)
            var lineEnd = newline < 0 ? value.length : newline
            var contentEnd = lineEnd
            if (contentEnd > lineStart && value.charAt(contentEnd - 1) === "\r") contentEnd--
            var line = value.substring(lineStart, contentEnd)
            var heading = /^ {0,3}(#{1,6})(?:[ \t]+|$)(.*)$/.exec(line)
            var list = /^([ \t]*)([-+*]|\d+[.)])[ \t]+(.*)$/.exec(line)
            var quote = /^ {0,3}((?:>[ \t]?)+)(.*)$/.exec(line)

            if (!line.trim().length) {
                flushList()
                flushQuote()
                if (paragraphStart >= 0) {
                    parsed.push({
                        start: paragraphStart,
                        end: paragraphEnd,
                        source: value.substring(paragraphStart, paragraphEnd),
                        type: "paragraph"
                    })
                    paragraphStart = -1
                }
            } else if (heading) {
                flushList()
                flushQuote()
                if (paragraphStart >= 0) {
                    parsed.push({
                        start: paragraphStart,
                        end: paragraphEnd,
                        source: value.substring(paragraphStart, paragraphEnd),
                        type: "paragraph"
                    })
                    paragraphStart = -1
                }
                parsed.push({
                    start: lineStart,
                    end: contentEnd,
                    source: line,
                    type: "heading",
                    level: heading[1].length
                })
            } else if (quote) {
                flushList()
                if (paragraphStart >= 0) {
                    parsed.push({
                        start: paragraphStart,
                        end: paragraphEnd,
                        source: value.substring(paragraphStart, paragraphEnd),
                        type: "paragraph"
                    })
                    paragraphStart = -1
                }
                var depth = (quote[1].match(/>/g) || []).length
                if (quoteStart < 0) quoteStart = lineStart
                quoteEnd = contentEnd
                quoteItems.push({ text: quote[2], depth: depth })
            } else if (list) {
                flushQuote()
                if (paragraphStart >= 0) {
                    parsed.push({
                        start: paragraphStart,
                        end: paragraphEnd,
                        source: value.substring(paragraphStart, paragraphEnd),
                        type: "paragraph"
                    })
                    paragraphStart = -1
                }
                var indentation = list[1].replace(/\t/g, "    ").length
                var task = /^\[([ xX])\][ \t]*(.*)$/.exec(list[3])
                if (listStart < 0) listStart = lineStart
                listEnd = contentEnd
                listItems.push({
                    start: lineStart,
                    end: contentEnd,
                    indent: Math.floor(indentation / 2),
                    type: "list",
                    marker: list[2],
                    ordered: /^\d+[.)]$/.test(list[2]),
                    taskState: task ? task[1].toLowerCase() : null,
                    text: task ? task[2] : list[3]
                })
            } else {
                flushList()
                flushQuote()
                if (paragraphStart < 0) paragraphStart = lineStart
                paragraphEnd = contentEnd
            }

            if (newline < 0) break
            lineStart = newline + 1
        }

        flushList()
        flushQuote()
        if (paragraphStart >= 0) {
            parsed.push({
                start: paragraphStart,
                end: paragraphEnd,
                source: value.substring(paragraphStart, paragraphEnd),
                type: "paragraph"
            })
        }

        if (!parsed.length)
            parsed.push({ start: 0, end: value.length, source: value, type: "paragraph" })
        return parsed
    }

    function headingText(source) {
        var match = /^ {0,3}(#{1,6})(?:[ \t]+|$)(.*)$/.exec(source)
        if (!match) return source
        return match[2].replace(/[ \t]+#+[ \t]*$/, "")
    }

    function headingPixelSize(level) {
        if (level <= 1) return Theme.fontSizeHuge
        if (level === 2) return Theme.fontSizeExtraLarge
        if (level === 3) return Theme.fontSizeLarge
        if (level === 4) return Theme.fontSizeMedium
        if (level === 5) return Theme.fontSizeSmall
        return Theme.fontSizeTiny
    }

    function listMarker(block, itemIndex) {
        var item = block.items[itemIndex]
        if (!item.ordered) return "-"
        var counter = 0
        for (var i = 0; i <= itemIndex; i++) {
            var previous = block.items[i]
            if (previous.indent !== item.indent) continue
            counter = previous.ordered ? counter + 1 : 0
        }
        return counter + "."
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
        blocks = parseBlocks(sourceText)
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
                property int blockIndex: index
                property bool editing: notePreviewEditor.activeIndex === index
                width: contentColumn.width
                height: editing ? editArea.height
                                : (block.type === "list"
                                   ? listColumn.implicitHeight
                                   : (block.type === "blockquote"
                                      ? quoteColumn.implicitHeight
                                      : displayLabel.implicitHeight))

                Label {
                    id: displayLabel
                    visible: !blockItem.editing
                             && blockItem.block.type !== "list"
                             && blockItem.block.type !== "blockquote"
                    x: Theme.horizontalPageMargin
                    width: blockItem.width - Theme.horizontalPageMargin * 2
                    text: blockItem.block.source.trim().length
                          ? (blockItem.block.type === "heading"
                             ? notePreviewEditor.renderInline(
                                   notePreviewEditor.headingText(blockItem.block.source))
                             : notePreviewEditor.renderInline(blockItem.block.source))
                          : "Tap to add a paragraph"
                    textFormat: Text.RichText
                    color: Theme.primaryColor
                    wrapMode: Text.Wrap
                    font.pixelSize: blockItem.block.type === "heading"
                                    ? notePreviewEditor.headingPixelSize(blockItem.block.level)
                                    : Theme.fontSizeMedium
                    font.bold: blockItem.block.type === "heading"
                }

                MouseArea {
                    anchors.fill: displayLabel
                    visible: displayLabel.visible
                    onClicked: notePreviewEditor.activate(blockItem.block)
                }

                Column {
                    id: listColumn
                    visible: !blockItem.editing && blockItem.block.type === "list"
                    x: Theme.horizontalPageMargin
                    width: blockItem.width - Theme.horizontalPageMargin * 2

                    Repeater {
                        model: blockItem.block.type === "list" ? blockItem.block.items : []

                        delegate: Item {
                            id: listRow
                            property var listItem: modelData
                            property int itemIndex: index
                            property real markerSize: Theme.fontSizeLarge
                            width: listColumn.width
                            height: Math.max(markerSize, rowText.implicitHeight)

                            Item {
                                x: listRow.listItem.indent * Theme.paddingLarge
                                width: listRow.markerSize
                                height: listRow.height

                                Label {
                                    anchors.fill: parent
                                    visible: listRow.listItem.taskState === null
                                    text: notePreviewEditor.listMarker(blockItem.block, index)
                                    color: Theme.primaryColor
                                    font.pixelSize: Theme.fontSizeMedium
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    visible: listRow.listItem.taskState !== null
                                    width: listRow.markerSize - 4
                                    height: width
                                    color: "transparent"
                                    border.color: Theme.primaryColor
                                    border.width: 2
                                    radius: 3

                                    Label {
                                        anchors.centerIn: parent
                                        visible: listRow.listItem.taskState === "x"
                                        text: "✓"
                                        color: Theme.primaryColor
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: notePreviewEditor.toggleTask(
                                                       blockItem.blockIndex,
                                                       listRow.itemIndex)
                                    }
                                }
                            }

                            Label {
                                id: rowText
                                x: listRow.listItem.indent * Theme.paddingLarge
                                   + listRow.markerSize + Theme.paddingSmall
                                width: listRow.width - x
                                text: listRow.listItem.taskState === "x"
                                      ? "<s>" + notePreviewEditor.renderInline(
                                            listRow.listItem.text) + "</s>"
                                      : notePreviewEditor.renderInline(listRow.listItem.text)
                                textFormat: Text.RichText
                                color: Theme.primaryColor
                                wrapMode: Text.Wrap
                            }

                            MouseArea {
                                anchors.fill: rowText
                                onClicked: notePreviewEditor.activate(blockItem.block)
                            }
                        }
                    }
                }

                Column {
                    id: quoteColumn
                    visible: !blockItem.editing
                             && blockItem.block.type === "blockquote"
                    x: Theme.horizontalPageMargin
                    width: blockItem.width - Theme.horizontalPageMargin * 2

                    Repeater {
                        model: blockItem.block.type === "blockquote"
                               ? blockItem.block.items : []

                        delegate: Item {
                            id: quoteRow
                            property var quoteItem: modelData
                            width: quoteColumn.width
                            height: quoteText.implicitHeight

                            Rectangle {
                                x: (quoteRow.quoteItem.depth - 1) * Theme.paddingLarge
                                width: 3
                                height: quoteRow.height
                                color: Theme.highlightColor
                            }

                            Label {
                                id: quoteText
                                x: quoteRow.quoteItem.depth * Theme.paddingLarge
                                width: quoteRow.width - x
                                text: notePreviewEditor.renderInline(quoteRow.quoteItem.text)
                                textFormat: Text.RichText
                                color: Theme.secondaryColor
                                wrapMode: Text.Wrap
                            }

                            MouseArea {
                                anchors.fill: quoteRow
                                onClicked: notePreviewEditor.activate(blockItem.block)
                            }
                        }
                    }
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
