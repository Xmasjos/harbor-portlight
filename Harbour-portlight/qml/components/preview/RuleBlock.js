.pragma library

function matchHorizontalRule(line) {
    return /^ {0,3}(?:-{3,}|_{3,}|\*{3,})[ \t]*$/.test(line)
}
