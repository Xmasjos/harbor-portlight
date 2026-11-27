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
    var fence = null
    var lineStart = 0

    function normalizeTableRow(row) {
        return row.trim().replace(/^\\(?=\|)/, "").replace(/\\\s*$/, "")
    }

    function splitTableRow(row) {
        row = row.trim()
        row = normalizeTableRow(row)
        if (row.charAt(0) === "|") row = row.substring(1)
        if (row.charAt(row.length - 1) === "|") row = row.substring(0, row.length - 1)
        return row.split("|").map(function (cell) { return cell.trim() })
    }

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

        if (fence) {
            var closeFence = new RegExp("^ {0,3}" + fence.marker.charAt(0) + "{" + fence.marker.length + ",}\\s*$")
            if (closeFence.test(line)) {
                fence.end = contentEnd
                fence.source = value.substring(fence.start, contentEnd)
                fence.code = value.substring(fence.codeStart, lineStart).replace(/\n$/, "")
                parsed.push(fence)
                fence = null
            }
            if (newline < 0) break
            lineStart = newline + 1
            continue
        }

        var codeFence = /^ {0,3}(`{3,}|~{3,})(.*)$/.exec(line)
        var tableHeader = line.indexOf("|") >= 0 && lineStart < value.length
                ? /^\|?\s*:?-{3,}:?\s*(?:\|\s*:?-{3,}:?\s*)+\|?$/.exec(normalizeTableRow(value.substring(newline + 1, value.indexOf("\n", newline + 1) < 0 ? value.length : value.indexOf("\n", newline + 1)).replace(/\r$/, "")))
                : null

        if (codeFence) {
            flushList()
            flushQuote()
            if (paragraphStart >= 0) {
                parsed.push({ start: paragraphStart, end: paragraphEnd,
                    source: value.substring(paragraphStart, paragraphEnd), type: "paragraph" })
                paragraphStart = -1
            }
            fence = { start: lineStart, marker: codeFence[1], codeStart: newline < 0 ? lineEnd : newline + 1,
                      end: contentEnd, source: line, code: "", language: codeFence[2].trim(),
                      type: "code" }
        } else if (tableHeader && newline >= 0) {
            flushList(); flushQuote()
            if (paragraphStart >= 0) {
                parsed.push({ start: paragraphStart, end: paragraphEnd,
                    source: value.substring(paragraphStart, paragraphEnd), type: "paragraph" })
                paragraphStart = -1
            }
            var tableLines = [line]
            var tableEnd = value.indexOf("\n", newline + 1)
            if (tableEnd < 0) tableEnd = value.length
            var rowStart = value.indexOf("\n", newline + 1) + 1
            while (rowStart <= value.length) {
                var rowEnd = value.indexOf("\n", rowStart)
                if (rowEnd < 0) rowEnd = value.length
                var row = value.substring(rowStart, rowEnd).replace(/\r$/, "")
                if (!row.trim() || row.indexOf("|") < 0) break
                tableLines.push(row)
                tableEnd = rowEnd
                if (rowEnd === value.length) break
                rowStart = rowEnd + 1
            }
            var delimiter = normalizeTableRow(value.substring(newline + 1,
                    value.indexOf("\n", newline + 1) < 0 ? value.length : value.indexOf("\n", newline + 1)).replace(/\r$/, ""))
            parsed.push({ start: lineStart, end: tableEnd, source: value.substring(lineStart, tableEnd),
                type: "table", rows: tableLines.map(splitTableRow),
                align: delimiter.split("|").map(function (c) { return c.indexOf(":") === 0 && c.lastIndexOf(":") === c.length - 1 ? "center" : (c.indexOf(":") === 0 ? "left" : (c.lastIndexOf(":") === c.length - 1 ? "right" : "left")) }) })
            if (tableEnd === value.length) break
            lineStart = tableEnd + 1
            continue
        } else if (!line.trim().length) {
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
    if (fence) {
        fence.end = value.length
        fence.source = value.substring(fence.start)
        fence.code = value.substring(fence.codeStart)
        parsed.push(fence)
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
