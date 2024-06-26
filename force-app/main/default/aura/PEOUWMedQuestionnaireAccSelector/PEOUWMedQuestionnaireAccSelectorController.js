({
    getChecklistAndQuestionnaire : function(component, event, helper) {
        let tabs = component.get('v.AccountList').reduce(function(s, a) {
            s.push(a.Id);
            return s;
        }, []);
        tabs.push('acknowledgement');
        component.set("v.tablist", tabs);
        helper.getChecklistAndMedQuestionnaire(component, event);
        component.set('v.chkRefreshFunc', $A.getCallback(() => helper.getChecklistAndMedQuestionnaire(component, event, helper)));
        /*let autoSaveEvt = component.getEvent('autoSave');
        autoSaveEvt.setParam('sendImmediete', true);
        autoSaveEvt.fire();*/
        helper.addTabNumbers(component, event, helper);
    }
})