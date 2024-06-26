({
    handleBlur: function(cmp, e, helper) {
        console.log("Inside handleBlur");
        var field = e.getSource();
        field.setCustomValidity('') ;
        var chckvalididty = field.get("v.validity");
        console.log(chckvalididty.valid); // it gives false when 1st enter wrong format then i changed to correct format still shows
        if(!chckvalididty.valid){
            console.log("Setting custom validation message...");
            field.setCustomValidity('format must be mm/dd/yyyy');
        }else{
            field.setCustomValidity('') ;
        }
        field.reportValidity();
    },
    
    answerChanged: function(cmp, e, helper) {
        console.log('MGF answerChanged');
        let fieldName = e.getSource().get("v.name");	
        let questionnaire = cmp.get('v.questionnaire');
        let chk = cmp.get('v.peoChecklist');
        console.log('field changed:'+fieldName);
        let relatedFieldList = cmp.get('v.relatedFieldList');
        if(fieldName == 'Total_Number_of_Full_Time_Employees__c'){
            //console.log('Full time emp field validation');
            helper.changeRelatedFieldAccess(cmp, e, helper);
        }
        else if (fieldName == 'PEO_Onboarding_Checklist__c.Current_Medical_Coverage_Provided__c' && e.getSource().get('v.value') == 'Yes') {
            //sfdc-13211 
            questionnaire.group_medical_offered_past_two_years__c = '';
            questionnaire.Past_Medical_Carrier__c = "";
            questionnaire.Effective_date__c = "";
            questionnaire.Termination_date__c = "";
            questionnaire.Reason_for_termination__c = "";
            relatedFieldList.push('group_medical_offered_past_two_years__c','Past_Medical_Carrier__c','Effective_date__c','Termination_date__c','Reason_for_termination__c');
            cmp.set('v.questionnaire', questionnaire);
            helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Medical_Questionnaire__c',relatedFieldList);
        }
            else if (fieldName == 'PEO_Onboarding_Checklist__c.Current_Medical_Coverage_Provided__c' && e.getSource().get('v.value') == 'No') {
                //sfdc-13211 
                questionnaire.Current_PEO_Carrier_if_applicable__c = '';
                questionnaire.Renewal_date__c = "";
                questionnaire.Rate_change_on_last_renewal__c = "";
                questionnaire.Years_with_current_carrier__c = "";
                relatedFieldList.push('Current_PEO_Carrier_if_applicable__c','Renewal_date__c','Rate_change_on_last_renewal__c','Years_with_current_carrier__c');
                cmp.set('v.questionnaire', questionnaire);
                helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Medical_Questionnaire__c',relatedFieldList);
            }
                else if (fieldName == 'Renewal_date__c' && chk) {
                    chk.medical_coverage_renewal_date__c = questionnaire.Renewal_date__c;
                    cmp.set('v.peoChecklist', chk);
                    console.log("chk:"+cmp.get('v.peoChecklist'));
                    console.log(cmp.get('v.peoChecklist'));
                    relatedFieldList.push('medical_coverage_renewal_date__c');
                    helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
                } 
                    else if (fieldName == 'Is_your_current_plan_self_funded__c' && chk) {
                        //jc INC3010076  chk.Has_Self_or_Level_Funded_Plan__c = questionnaire.Has_Self_or_Level_Funded_Plan__c;
                        chk.Has_Self_or_Level_Funded_Plan__c = questionnaire.Is_your_current_plan_self_funded__c;  
                        cmp.set('v.peoChecklist', chk);
                        relatedFieldList.push('Has_Self_or_Level_Funded_Plan__c');
                        helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
                    }
                        else if (fieldName == 'Current_PEO_Carrier_if_applicable__c' && chk) {
                            chk.medical_coverage_carrier__c = questionnaire.Current_PEO_Carrier_if_applicable__c;
                            cmp.set('v.peoChecklist', chk);
                            relatedFieldList.push('medical_coverage_carrier__c');
                            helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
                        }
                            else if (fieldName == 'group_medical_offered_past_two_years__c' && e.getSource().get('v.value') == 'No'){
                                questionnaire.Past_Medical_Carrier__c = "";
                                questionnaire.Effective_date__c = "";
                                questionnaire.Termination_date__c = "";
                                questionnaire.Reason_for_termination__c = "";
                                relatedFieldList.push('Past_Medical_Carrier__c','Past_Medical_Carrier__c','Effective_date__c','Termination_date__c','Reason_for_termination__c');
                                cmp.set('v.questionnaire', questionnaire);
                                helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Medical_Questionnaire__c',relatedFieldList);
                            }
        
        helper.sendAutoSave(cmp, e, helper);
        //helper.answerHasChanged(cmp, e);
        if(cmp.get("v.aknSelected") == true){
            helper.displayMsg('Please Re-Acknowledge', 'Due to changes to the form(s), you must click the acknowledgement box again.', 'error', 10000);
        }
        helper.AKNUpdateAutoSave(cmp, e, helper,true);
	},
	getRecord: function(cmp, e, helper) {
        //if ((cmp.get('v.isParentAccount') && cmp.get('v.tabName') == 'medicalGeneralInfo')||(cmp.get('v.acknowledgementNeeded')) cmp.set('v.skipSave', true);
        //JDA
        if(!cmp.get('v.uploadReadOnly') && cmp.get('v.contractReadOnly')){
            console.log('JDA if:');
            cmp.set('v.uploadReadOnly',true);
        }
        else if(!cmp.get('v.contractReadOnly')){
            console.log('JDA else if:');
            cmp.set('v.uploadReadOnly',false);
        }
        else{
            console.log('JDA else:');
            cmp.set('v.uploadReadOnly',cmp.get('v.uploadReadOnly') && cmp.get('v.readOnly') );
        }
        cmp.set('v.saveFunc' , $A.getCallback(() => helper.saveForm(cmp, e, helper)));
        console.log(cmp.get('v.skipSave'))
        var submissionStatus = cmp.get('v.questionnaire.Peo_Medical_formStatus__c');
        //console.log('submissionStatus:'+submissionStatus);
        if(submissionStatus === 'Complete'){
            cmp.set('v.formSubmitted', true);
        }
        if (cmp.get('v.user')) {
            let user = cmp.get('v.user');
            let prfName = user.Profile.Name;
            let isAnalyst = prfName == 'HRS Regional Sales Admin SB';
            let isNsc = prfName == 'HRS PEO Centric Sales - SB';
            let isDSM = prfName == 'HRS Sales Manager - SB';
            let isAdmin = prfName == 'System Administrator' || prfName == 'System Administrator - TAF';
            if (isAnalyst || isNsc || isDSM || isAdmin) {
                cmp.set('v.allowDiscLog', true);
            }
            if (prfName =='Customer Community Login User Clone') cmp.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, visit the Need Help section on our homepage, so we can promptly address the issue.');
            else cmp.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.');
        } 
        if(cmp.get('v.isParentAccount') && !cmp.get('v.acknowledgementNeeded')){
           cmp.set('v.tabNameList', ['medicalGeneralInfo','medicalInfo','upload']); 
        } 
        else if(!cmp.get('v.acknowledgementNeeded')){
           cmp.set('v.tabNameList', ['medicalGeneralInfo']);
        }
            
        console.log('MGF calling helper.setup');
        helper.setup(cmp, e);
        //Benchmark
        if($A.get("$Label.c.PEOUWCustomBenchmarkView") == 'true'){
            helper.checkPermissions(cmp, e, helper);
        }
        helper.addTabNumbers(cmp, e, helper);
	},
    changeSubFieldView: function(cmp, e, helper){
        if(cmp.get("v.aknSelected") == true){
            helper.displayMsg('Please Re-Acknowledge', 'Due to changes to the form(s), you must click the acknowledgement box again.', 'error', 10000);
        }
        helper.AKNUpdateAutoSave(cmp, e, helper,true);
        helper.sendAutoSave(cmp, e, helper);
        helper.subFieldUpdate(cmp, e);
        
    },
    saveForm: function(cmp, e, helper) {
        helper.cancelAutoSaveEvents(cmp,e,helper);
        helper.saveForm(cmp, e);
    },
    handleAkn: function(cmp, e, helper) {
    	helper.checkAkn(cmp, e,helper);
	},
    handleNext: function(cmp, e, helper){
        if(cmp.get('v.tabName')==='medicalInfo'){
            cmp.set('v.tabName','medicalGeneralInfo');
            cmp.set('v.actionName','Next');
        }
        else if(cmp.get('v.tabName')==='medicalGeneralInfo') {
            cmp.set('v.tabName','medicalInfo');
            cmp.set('v.actionName','Prev');
        }
    },
    openTab: function(cmp, e, helper) {
        helper.triggerEvt(cmp, e);
    },
    visitedMedInfoTab: function(cmp, e, helper) {
        if(cmp.get("v.medInfoTabLoaded") == false) {
            cmp.set("v.medInfoTabLoaded", true);
        }
    },
    handleTabChange: function(cmp, e, helper) {
        let tabName = e.getSource().get('v.Id');
        if (tabName && tabName == 'medicalInfo') cmp.set("v.medInfoTabLoaded", true);
        let cmpActiveTab;
        
        // Update the active tab label. This is used by the title header
        if (cmp.get('v.tabName') == 'medicalGeneralInfo') cmpActiveTab = 'General Information';
        else if (cmp.get('v.tabName') == 'upload') cmpActiveTab =  'Medical Documents';
        else cmpActiveTab = 'Medical Information';
        cmp.set('v.activeLabel', cmpActiveTab);
        
        // dissalow the save func from triggering if we're not on the second tab
        // if the current tab is a parent and we're on the med gen info tab
        // set save func to undefined. Otherwise set save func to the actual call
        /*if (cmp.get('v.isParentAccount') && cmp.get('v.tabName') == 'medicalGeneralInfo') cmp.set('v.skipSave', true);
        else cmp.set('v.skipSave', false);*/
        cmp.set('v.skipSave', false);
        console.log(cmp.get('v.tabName'));;
        console.log(cmp.get('v.isParentAccount'));
        console.log(cmp.get('v.skipSave'));
    },
    
    updateBenchMarkPos: function(cmp, e, helper) {
        //update the tab pos for benchmark
        console.log('updateBenchMarkPos');
        console.log('benchMarkPosMed:'+cmp.get('v.benchMarkPosMed'));
        if(cmp.get('v.benchMarkPosMed') == 'BenchMarkMedPart'){
            cmp.set('v.tabName',cmp.get('v.benchMarkPosMed'));
        }
    },
})