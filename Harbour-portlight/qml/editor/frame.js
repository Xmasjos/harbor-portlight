(function() {
    let keydownKey = null;
    let keydownText = null;
    let pendingInputType = null;

    function isEditorContent(target) {
        return target && target.classList
            && target.classList.contains("cm-content");
    }

    addEventListener("keydown", function(event) {
        pendingInputType = null;
        keydownKey = null;
        keydownText = null;
        if (!event.isTrusted || !isEditorContent(event.target)
                || (event.key !== "Enter" && event.key !== "Backspace"))
            return;

        keydownKey = event.key;
        keydownText = event.target.getAttribute("data-portlight-text");
    }, true);

    addEventListener("keydown", function(event) {
        if (!event.isTrusted || !isEditorContent(event.target)
                || event.key !== keydownKey)
            return;

        const text = event.target.getAttribute("data-portlight-text");
        if (event.defaultPrevented && typeof text === "string"
                && text !== keydownText) {
            pendingInputType = event.key === "Enter"
                ? "insertParagraph" : "deleteContentBackward";
            sendAsyncMessage("portlight:noteChanged", { text: text });
        }

        keydownKey = null;
        keydownText = null;
    }, false);

    addEventListener("beforeinput", function(event) {
        const inputType = event.inputType;
        if (!pendingInputType)
            return;

        const expectedInputType = pendingInputType;
        pendingInputType = null;
        if (event.isTrusted && event.cancelable
                && (inputType === expectedInputType
                    || (expectedInputType === "insertParagraph"
                        && inputType === "insertLineBreak")))
            event.preventDefault();
    }, true);

    addEventListener("keyup", function(event) {
        if (isEditorContent(event.target)
                && (event.key === "Enter" || event.key === "Backspace"))
            pendingInputType = null;
    }, false);

    addEventListener("input", function(event) {
        const target = event.target;
        if (!event.isTrusted || !target || !target.classList
                || !target.classList.contains("cm-content"))
            return;

        const text = target.getAttribute("data-portlight-text");
        if (typeof text === "string")
            sendAsyncMessage("portlight:noteChanged", { text: text });
    }, false);

    function sendTitleChange(target) {
        if (target && target.id === "note-title") {
            sendAsyncMessage("portlight:titleChanged", { title: target.value });
        }
    }

    addEventListener("change", function(event) {
        sendTitleChange(event.target);
    }, true);

    addEventListener("keydown", function(event) {
        if (event.target && event.target.id === "note-title"
                && event.key === "Enter") {
            event.preventDefault();
            event.target.blur();
            sendTitleChange(event.target);
        }
    }, true);
})();
