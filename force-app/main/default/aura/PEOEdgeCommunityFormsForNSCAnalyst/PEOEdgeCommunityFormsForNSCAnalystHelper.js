({
	displayMsg: function(title, msg, type, duration) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: msg,
            type: type
        });
        toastEvent.fire();
    },
})