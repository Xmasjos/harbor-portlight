(function() {
    addEventListener("input", function(event) {
        var target = event.target;
        if (target && target.id === "note") {
            sendAsyncMessage("portlight:noteChanged", { text: target.value });
        }
    }, true);
})();
