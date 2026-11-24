.pragma library

function matchTask(source) {
    return /^\[([ xX])\][ \t]*(.*)$/.exec(source)
}

function toggleLine(line) {
    return line.replace(/^([ \t]*(?:[-+*]|\d+[.)])[ \t]+\[)([ xX])(\][ \t]*)/,
                       function(match, prefix, state, suffix) {
                           return prefix + (state.toLowerCase() === "x" ? " " : "x") + suffix
                       })
}
