.pragma library

.import "HeadingBlock.js" as HeadingBlock
.import "ListBlock.js" as ListBlock
.import "QuoteBlock.js" as QuoteBlock
.import "RuleBlock.js" as RuleBlock
.import "ChecklistItem.js" as ChecklistItem

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
        var heading = HeadingBlock.matchHeading(line)
        var horizontalRule = RuleBlock.matchHorizontalRule(line)
        var list = ListBlock.matchList(line)
        var quote = QuoteBlock.matchQuote(line)

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
        } else if (horizontalRule) {
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
                type: "horizontal-rule"
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
            var task = ChecklistItem.matchTask(list[3])
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
