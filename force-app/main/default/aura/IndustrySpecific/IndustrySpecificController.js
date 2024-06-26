({
    doInit : function(component, event, helper){
        let isCommUser = component.get('v.communityUser');
        if (isCommUser) component.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, visit the Need Help section on our homepage, so we can promptly address the issue.');
        else component.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.')
        
        helper.getIndustrySpecific(component,event)
        .then(bool => helper.setupFormView(component, event))
        .catch(err => helper.handleErr(component, err))  
        console.log(component.get('v.parentTabs'));
        console.log(component.get('v.activeParent'));
        helper.fetchNaicsFromAcc(component, event, helper);
        component.set('v.saveFunc', $A.getCallback(() => helper.save(component, event, helper)));
    },
    handleChange : function(component, event, helper){
        helper.sendAutoSave(component,event, helper); 
    },
    saveRec : function(component, event, helper){
        helper.save(component, event, helper);
        /*
        var buttonLabel = event.getSource().get("v.label");
        component.set('v.buttonLabel',buttonLabel);
        if(buttonLabel != 'Save and Finish Later'){
            component.set('v.industryStruct.industryRec.Peo_IndSpecific_formStatus__c','Complete');
        }
        var rec = component.get('v.IndustrySpecific');
        rec.PEO_Underwriting_Checklist__c = component.get('v.PEOChecklist').Id;
        rec.RecordTypeId= component.get('v.IndustryTypeId');
        component.set("v.IndustrySpecific",rec);
        helper.saveIndustrySpecific(component,event);*/
    }
})