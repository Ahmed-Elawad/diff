({
showToast : function(cmp, event, helper) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
        "title": "Workspace Tab Closed!",
        "type": "success",
        "message": "Maximum number of Workspace tabs reached! You may be able to view the closed tab in Recently Viewed List view or in history below"
    });
    toastEvent.fire();
}
})