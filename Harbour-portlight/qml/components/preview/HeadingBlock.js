.pragma library

function matchHeading(line) {
    return /^ {0,3}(#{1,6})(?:[ \t]+|$)(.*)$/.exec(line)
}

function headingText(source) {
    var match = matchHeading(source)
    if (!match) return source
    return match[2].replace(/[ \t]+#+[ \t]*$/, "")
}
