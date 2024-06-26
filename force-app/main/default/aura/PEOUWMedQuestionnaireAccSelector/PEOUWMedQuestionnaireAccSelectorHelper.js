({
    getChecklistAndMedQuestionnaire : function(component, event) {
        component.set("v.contentLoaded", false);
        
        // send async form save request if the form needs savin
        if(component.get("v.formNeedsSaving")) {
           helper.sendAsyncQuestionnaireSave(sendAsyncQuestionnaireSave, event, this);
        }
        
        // get the activated tab ID
        var selectedTabId = component.get("v.selectedTab");
        var parentAccountId = component.get("v.AccountList")[0].Id;
        // if the tab id is undefined set the active tab to the parent tab
        // id by default
        if(selectedTabId == null || selectedTabId == 'undefined') {
            selectedTabId = parentAccountId;
            component.set("v.selectedTab",parentAccountId);
        }
        // get some properties from the component
        console.log('selectedTabId='+selectedTabId+' parentAccountId='+parentAccountId);
        let user = component.get('v.User');
        let medicalQuestionnaire = component.get('v.parentQuestionnaire');
        let chk = component.get('v.currentPEOChecklist');
        let userIsInternal = user && user.Profile && user.Profile.Name !== 'Customer Community Login User Clone';
        // if opening the parent activatingParentAccountTab will be true
        let activatingParentAccountTab = (selectedTabId == parentAccountId || selectedTabId == 'acknowledgement');
        // if opening the acknowledgement tab need to set acknowledgement values and parent questionnaire values
        if(selectedTabId == 'acknowledgement') {
            if (userIsInternal && (medicalQuestionnaire.Acknowledged_By__c != undefined || medicalQuestionnaire.Client_Id_user_agreement_acknowledgment__c != undefined)){
                component.set('v.makeReadOnly', true);
                component.set('v.uploadReadOnly',false);
            } 
            /*component.set("v.currentPEOChecklist", component.get("v.parentPEOChecklist"));
            component.set("v.currentQuestionnaire", component.get("v.parentQuestionnaire"));
            component.set("v.isParentRec", true);
            component.set("v.contentLoaded", true);*/
        }
        //else {
        // set account flags for tabs
        if (!activatingParentAccountTab) {
            component.set("v.isParentRec", false);
            component.set("v.parentAccountId", parentAccountId);
        } else {
            component.set("v.isParentRec", true);
        }
        // get save event
        var getPEOChecklist = component.get("c.getPEOOnboardingChecklist");
        
        // set callback to update current checklist on tab and then get and 
        // update medical questionnaire on tab
        getPEOChecklist.setCallback(this, function(data) {
            // if the response isn't empty set the checklist on the tab then
            // get the medical questionnaire for this account
            if(data.getReturnValue() != null)
            {
                component.set("v.currentPEOChecklist", data.getReturnValue());
                if (activatingParentAccountTab) component.set("v.parentPEOChecklist", data.getReturnValue());
                
                var getMedQuestionnaire = component.get("c.getMedicalQuestionnaireForm");
                getMedQuestionnaire.setParams({
                    'peoOnboardingChecklistId': data.getReturnValue().Id,
                    formName: 'MedQuestionnaireAccSelector.cmp'
                });
                
                getMedQuestionnaire.setCallback(this, function(res) {
                    
                    if(data.getReturnValue() != null)
                    {
                        component.set("v.currentQuestionnaire", res.getReturnValue());
                        if (activatingParentAccountTab) component.set("v.currentQuestionnaire", res.getReturnValue());
                        if (userIsInternal && (medicalQuestionnaire.Acknowledged_By__c != undefined || medicalQuestionnaire.Client_Id_user_agreement_acknowledgment__c != undefined)) component.set('v.makeReadOnly', true);
                        component.set("v.contentLoaded", true);
                    }
                });
                $A.enqueueAction(getMedQuestionnaire);
            }
            else {
                console.log("NO CHECKLIST FOUND");
            }
        });
        let accountToSelect = (selectedTabId != 'acknowledgement' ? selectedTabId : parentAccountId);
        console.log('accountIdToSelect'+accountToSelect);
        getPEOChecklist.setParams({
            'accountId': accountToSelect,
            formName: 'MedQuestionnaireAccSelector.cmp'
        });
        
        $A.enqueueAction(getPEOChecklist);
        //}
    },
    sendAsyncQuestionnaireSave: function(component, e, helper) {
        var saveRec = component.get('c.saveMedicalQuestionnaire');
        
        saveRec.setParams({
            rec: component.get("v.currentQuestionnaire"),
            formName: 'MedQuestionnaireAccSelector.cmp'
        });
        
        saveRec.setCallback(this, function(res) {	
            if (res.getState() !== 'SUCCESS') {	
                console.Error(res.getError())	
            } else {
                component.set("v.formNeedsSaving", false);
            }
            
        });
        
        $A.enqueueAction(saveRec);
    },
    
    addTabNumbers: function(component, event, helper) {
        console.log('AccountListSize:'+component.get('v.AccountList').length);
        var tabNames = [];
        var initTabNum = component.get('v.AccountList').length;
        tabNames.push('AckLabel');
        if(tabNames.length>0){
            tabNames.forEach(function (item, index) {
                initTabNum++;
                console.log(item, index);
                component.set(`v.`+item, initTabNum+'.'+component.get(`v.`+item));
            });
        }
    }
})