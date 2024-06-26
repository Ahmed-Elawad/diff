({
    doInit: function(component, event, helper) {
        helper.getAccountWrapper(component, event, helper);
        helper.insightsPilot(component, event, helper);
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            var acct = component.get("v.account");
            console.dir(acct.Do_Not_Prospect_Reason__c);
            console.dir(acct.Do_Not_Call__c);
            console.dir(acct.Do_Not_Call_Flag__c);
            console.dir(acct.Email_Opt_Out__c);
            console.dir(acct.Email_Opt_Out_Flag__c);
        } else if(eventParams.changeType === "CHANGED") {
            // record is changed 
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
            console.log("error");
            console.log(component.get("v.recordError"));
        }
    }   
})