.pragma library

.import "Strikethrough.js" as Strikethrough
.import "Emphasis.js" as Emphasis

function escapeHtml(value) {
    return value.replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;")
                .replace(/"/g, "&quot;")
                .replace(/'/g, "&#39;")
                .replace(/\n/g, "<br>")
}

function normalizeReferenceLabel(value) {
    return value.replace(/\s+/g, " ").trim().toLowerCase()
}

function collectReferenceDefinitions(documentSource) {
    var references = {}
    if (!documentSource) return references

    var pattern = /^ {0,3}\[([^\]]+)\]:\s*(?:<([^>\n]+)>|(\S+))(?:\s+(?:["'(]([^"'\n]*)["')]))?\s*$/gm
    var match
    while ((match = pattern.exec(documentSource))) {
        var label = normalizeReferenceLabel(match[1])
        references[label] = {
            destination: match[2] || match[3],
            title: match[4] || ""
        }
    }
    return references
}

function removeReferenceDefinitions(source) {
    return source.replace(/^ {0,3}\[([^\]]+)\]:[^\n]*(?:\n|$)/gm, "")
                 .replace(/^(?:<br>)?(?:\n|$)/, "")
}

function findClosing(source, start, openCharacter, closeCharacter) {
    var depth = 0
    for (var i = start; i < source.length; i++) {
        if (source.charAt(i) === "\\") {
            i++
            continue
        }
        if (source.charAt(i) === openCharacter) depth++
        else if (source.charAt(i) === closeCharacter) {
            if (depth === 0) return i
            depth--
        }
    }
    return -1
}

function parseInlineDestination(value) {
    value = value.trim()
    if (value.charAt(0) === "<") {
        var close = value.indexOf(">")
        if (close >= 0)
            return { destination: value.substring(1, close),
                     title: value.substring(close + 1).trim() }
    }

    var match = /^(\S+)(?:\s+(?:["'(](.*)["')]))?$/.exec(value)
    if (!match) return null
    return { destination: match[1], title: match[2] || "" }
}

function resolveDestination(destination, baseFolder) {
    if (!destination) return ""
    destination = destination.replace(/\\([()[\]{}])/g, "$1")

    if (/^(?:https?:|mailto:|tel:|file:|#)/i.test(destination))
        return destination

    if (!baseFolder) return destination
    var folder = baseFolder.replace(/\/+$/, "")
    var relative = destination.replace(/^\.?\//, "")
    var parts = (folder + "/" + relative).split("/")
    var normalized = []
    for (var i = 0; i < parts.length; i++) {
        if (!parts[i] || parts[i] === ".") continue
        if (parts[i] === "..") {
            if (normalized.length) normalized.pop()
        } else {
            normalized.push(parts[i])
        }
    }
    return "file://" + "/" + normalized.join("/")
}

function matchInlineLink(source, start, references, baseFolder) {
    var image = source.substr(start, 2) === "!["
    var prefixLength = image ? 2 : 1
    if (source.charAt(start) !== (image ? "!" : "["))
        return null
    if (image && source.substr(start + 1, 1) !== "[")
        return null

    var labelStart = start + prefixLength
    var labelClose = findClosing(source, labelStart, "[", "]")
    if (labelClose < 0) return null

    var label = source.substring(labelStart, labelClose)
    var destination = null
    var title = ""
    var cursor = labelClose + 1

    if (source.charAt(cursor) === "(") {
        var destinationClose = findClosing(source, cursor + 1, "(", ")")
        if (destinationClose < 0) return null
        var parsed = parseInlineDestination(source.substring(cursor + 1, destinationClose))
        if (!parsed) return null
        destination = parsed.destination
        title = parsed.title
        cursor = destinationClose + 1
    } else if (source.charAt(cursor) === "[") {
        var referenceClose = findClosing(source, cursor + 1, "[", "]")
        if (referenceClose < 0) return null
        var referenceLabel = source.substring(cursor + 1, referenceClose)
        if (!referenceLabel.length) referenceLabel = label
        var reference = references[normalizeReferenceLabel(referenceLabel)]
        if (!reference) return null
        destination = reference.destination
        title = reference.title
        cursor = referenceClose + 1
    } else {
        var shortcut = references[normalizeReferenceLabel(label)]
        if (!shortcut) return null
        destination = shortcut.destination
        title = shortcut.title
    }

    return {
        end: cursor,
        image: image,
        label: label,
        destination: resolveDestination(destination, baseFolder),
        title: title
    }
}

function render(source, documentSource, baseFolder) {
    var references = collectReferenceDefinitions(documentSource || source)
    source = removeReferenceDefinitions(source)
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
            var escaped = source.charAt(i + 1)
            if (/[\\`*_{}\[\]()#+\-.!|>~]/.test(escaped)) plain += escaped
            else plain += "\\" + escaped
            i += 2
            continue
        }

        if (character === "`") {
            var ticks = /^`+/.exec(source.substring(i))[0]
            var closeCode = source.indexOf(ticks, i + ticks.length)
            if (closeCode >= 0) {
                flushPlain()
                output += "<code>" + escapeHtml(source.substring(i + ticks.length, closeCode).replace(/\n/g, " ")) + "</code>"
                i = closeCode + ticks.length
                continue
            }
        }

        if (character === "<") {
            var rawTag = /^<\/?[A-Za-z][^>]*>|^<!--[\s\S]*?-->/.exec(source.substring(i))
            if (rawTag) {
                flushPlain()
                output += rawTag[0]
                i += rawTag[0].length
                continue
            }
        }

        var link = matchInlineLink(source, i, references, baseFolder)
        if (link) {
            flushPlain()
            if (link.image) {
                var alt = escapeHtml(link.label)
                var title = link.title ? ' title="' + escapeHtml(link.title) + '"' : ""
                output += '<img src="' + escapeHtml(link.destination)
                        + '" alt="' + alt + '"' + title
                        + ' style="max-width:100%;">'
            } else {
                var linkTitle = link.title ? ' title="' + escapeHtml(link.title) + '"' : ""
                output += '<a href="' + escapeHtml(link.destination) + '"' + linkTitle + '>'
                        + render(link.label, documentSource || source, baseFolder)
                        + "</a>"
            }
            i = link.end
            continue
        }

        var strike = Strikethrough.match(source, i)
        if (strike) {
            flushPlain()
            output += "<s>" + render(strike.text) + "</s>"
            i = strike.end
            continue
        }

        var emphasis = Emphasis.match(source, i)
        if (!emphasis) {
            plain += character
            i++
            continue
        }

        flushPlain()
        var rendered = render(emphasis.text)
        if (emphasis.length === 3)
            output += "<b><i>" + rendered + "</i></b>"
        else if (emphasis.length === 2)
            output += "<b>" + rendered + "</b>"
        else
            output += "<i>" + rendered + "</i>"
        i = emphasis.close + emphasis.length
    }

    flushPlain()
    return output
}
