.pragma library

function match(source, start) {
    if (source.substr(start, 2) !== "~~") return null
    var close = source.indexOf("~~", start + 2)
    if (close <= start + 2) return null
    return {
        end: close + 2,
        text: source.substring(start + 2, close)
    }
}
