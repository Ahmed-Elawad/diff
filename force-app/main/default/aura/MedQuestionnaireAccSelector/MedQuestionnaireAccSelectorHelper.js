({
    getChecklistAndMedQuestionnaire : function(component, event) {
        component.set("v.contentLoaded", false);
        console.log('component.get("v.formNeedsSaving")='+component.get("v.formNeedsSaving"));
        if(component.get("v.formNeedsSaving")) {
           helper.sendAsyncQuestionnaireSave(sendAsyncQuestionnaireSave, event, this);
        }
        var selectedTabId = component.get("v.selectedTab");
        var parentAccountId = component.get("v.AccountList")[0].Id;
        console.log('selectedTabId='+selectedTabId+' parentAccountId='+parentAccountId);
        if(selectedTabId == null || selectedTabId == 'undefined') {
            selectedTabId = parentAccountId;
            component.set("v.selectedTab",parentAccountId);
        }
        console.log('selectedTabId='+selectedTabId+' parentAccountId='+parentAccountId);
        let user = component.get('v.User');
        let medicalQuestionnaire = component.get('v.parentQuestionnaire');
        let chk = component.get('v.currentPEOChecklist');
        let userIsInternal = user && user.Profile && user.Profile.Name !== 'Customer Community Login User Clone';
        if(selectedTabId == parentAccountId || selectedTabId == 'acknowledgement') {
            //if (userIsInternal && (medicalQuestionnaire.Acknowledged_By__c != undefined || medicalQuestionnaire.Client_Id_user_agreement_acknowledgment__c != undefined)) component.set('v.makeReadOnly', true);
            console.log("setting checklist and questionnaire to be the parents.");
            component.set("v.currentPEOChecklist", component.get("v.parentPEOChecklist"));
            console.log('parentCheckList: '+component.get("v.parentPEOChecklist.Id")+'currentPEOChecklist: '+component.get("v.currentPEOChecklist.Id"));
            console.log('MGF currentPEOChecklist.Id = '+component.get("v.currentPEOChecklist.Id"));
            console.log('MGF currentPEOChecklist.Number_of_Enrolled_Employees__c = '+component.get("v.currentPEOChecklist.Number_of_Enrolled_Employees__c"));
            component.set("v.currentQuestionnaire", component.get("v.parentQuestionnaire"));
            console.log('MGF currentQuestionnaire.Total_Number_of_Full_Time_Employees__c = '+component.get("v.currentQuestionnaire.Total_Number_of_Full_Time_Employees__c"));
            console.log('MGF currentQuestionnaire.Total_Number_of_Part_Time_Employees__c = '+component.get("v.currentQuestionnaire.Total_Number_of_Part_Time_Employees__c"));
            component.set("v.isParentRec", true);
            component.set("v.contentLoaded", true);
        }
        else {
            component.set("v.isParentRec", false);
            var getPEOChecklist = component.get("c.getPEOOnboardingChecklist");
            component.set("v.parentAccountId", parentAccountId);
            
            getPEOChecklist.setCallback(this, function(data) {
                if(data.getReturnValue() != null)
                {
                    component.set("v.currentPEOChecklist", data.getReturnValue());
                    console.log('currentPEOChecklist'+data.getReturnValue());
                    var getMedQuestionnaire = component.get("c.getMedicalQuestionnaireForm");
                    console.log('MGF currentPEOChecklist.Id = '+component.get("v.currentPEOChecklist.Id"));
                    console.log('MGF currentPEOChecklist.Number_of_Enrolled_Employees__c = '+component.get("v.currentPEOChecklist.Number_of_Enrolled_Employees__c"));
                    
                    getMedQuestionnaire.setParams({
                        'peoOnboardingChecklistId': data.getReturnValue().Id,
                        formName: 'MedQuestionnaireAccSelector.cmp'
                    });
                    
                    getMedQuestionnaire.setCallback(this, function(res) {
                        debugger;
                        if(data.getReturnValue() != null)
                        {
                            component.set("v.currentQuestionnaire", res.getReturnValue());
                            console.log('userIsInternal:'+userIsInternal);
                            //if (userIsInternal && (medicalQuestionnaire.Acknowledged_By__c != undefined || medicalQuestionnaire.Client_Id_user_agreement_acknowledgment__c != undefined)) component.set('v.makeReadOnly', true);
                            component.set("v.contentLoaded", true);
                            //console.log('currQuestionnaire'+res.getReturnValue());
                            console.log('MGF currentQuestionnaire.Total_Number_of_Full_Time_Employees__c = '+component.get("v.currentQuestionnaire.Total_Number_of_Full_Time_Employees__c"));
                            console.log('MGF currentQuestionnaire.Total_Number_of_Part_Time_Employees__c = '+component.get("v.currentQuestionnaire.Total_Number_of_Part_Time_Employees__c"));
                        }
                    });
                    $A.enqueueAction(getMedQuestionnaire);
                }
                else {
                    console.log("NO CHECKLIST FOUND");
                }
            });
            
            getPEOChecklist.setParams({
                'accountId': selectedTabId,
                formName: 'MedQuestionnaireAccSelector.cmp'
            });
            
            $A.enqueueAction(getPEOChecklist);
        }
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
    }
})