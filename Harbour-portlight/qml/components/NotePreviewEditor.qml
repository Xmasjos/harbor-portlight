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
            var line = value.substring(lineStart, contentEnd)
            var heading = /^ {0,3}(#{1,6})(?:[ \t]+|$)(.*)$/.exec(line)

            if (!line.trim().length) {
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
            } else {
                if (paragraphStart < 0) paragraphStart = lineStart
                paragraphEnd = contentEnd
            }

            if (newline < 0) break
            lineStart = newline + 1
        }

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
                property bool editing: notePreviewEditor.activeIndex === index
                width: contentColumn.width
                height: editing ? editArea.height : displayLabel.implicitHeight

                Label {
                    id: displayLabel
                    visible: !blockItem.editing
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
