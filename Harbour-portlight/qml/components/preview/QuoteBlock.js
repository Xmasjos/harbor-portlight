.pragma library

function matchQuote(line) {
    return /^ {0,3}((?:>[ \t]?)+)(.*)$/.exec(line)
}
