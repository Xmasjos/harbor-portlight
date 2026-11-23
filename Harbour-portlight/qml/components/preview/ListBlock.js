.pragma library

function matchList(line) {
    return /^([ \t]*)([-+*]|\d+[.)])[ \t]+(.*)$/.exec(line)
}
