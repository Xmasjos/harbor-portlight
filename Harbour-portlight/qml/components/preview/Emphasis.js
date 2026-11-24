.pragma library

function match(source, start) {
    var character = source.charAt(start)
    if (character !== "*" && character !== "_") return null

    var markerLength = 1
    if (source.substr(start, 3) === character + character + character)
        markerLength = 3
    else if (source.substr(start, 2) === character + character)
        markerLength = 2

    var marker = markerLength === 3
               ? (character === "*" ? "***" : "___")
               : (markerLength === 2
                  ? (character === "*" ? "**" : "__")
                  : character)
    var close = source.indexOf(marker, start + markerLength)
    if (close < 0) return null

    var text = source.substring(start + markerLength, close)
    if (!text.length) return null

    if (markerLength === 1 && character === "_"
            && ((start > 0 && /\w/.test(source.charAt(start - 1)))
                || (close + 1 < source.length
                    && /\w/.test(source.charAt(close + 1)))))
        return null

    return {
        close: close,
        length: markerLength,
        text: text
    }
}
