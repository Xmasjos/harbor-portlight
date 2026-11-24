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

function render(source) {
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
