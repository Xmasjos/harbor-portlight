(function() {
    addEventListener("input", function(event) {
        const target = event.target;
        if (target && target.id === "note") {
            sendAsyncMessage("portlight:noteChanged", { text: target.value });
        }
    }, true);

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
