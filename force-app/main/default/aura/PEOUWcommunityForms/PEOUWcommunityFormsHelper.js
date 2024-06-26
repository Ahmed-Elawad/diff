({
    helperFunctionAsPromise : function(component, helperFunction, helper) {
        return new Promise($A.getCallback(function(resolve, reject) {
            helperFunction(component, resolve, reject, helper);
        }));
    },
    getIndustryNames: function(component, resolve, reject, helper){
        console.log('getIndustryNames');
        //return new Promise(function(resolve, reject) {
        var naicsCodes = [];
        var parentNAICSCode = component.get('v.Account').NAICS_Code__c;
        var accountArray = component.get('v.Accounts');
        naicsCodes.push(parentNAICSCode);
        if(parentNAICSCode != null && parentNAICSCode != '' && parentNAICSCode != 'undefined') {
            for(var i = 0; i < accountArray.length; i++) {
                if(accountArray[i].NAICS_Code__c != parentNAICSCode) {
                    naicsCodes.push(accountArray[i].NAICS_Code__c);
                }
            }
        }
        var getIndustryNames = component.get('c.getIndustryNames');
        
        getIndustryNames.setParams({
            naicsCodes : naicsCodes
        });
        
        getIndustryNames.setCallback(this, function(res){
            var state = res.getState(); 
            var data = res.getReturnValue();
            if (state != 'SUCCESS' || !data) {
                console.log(data.getError())
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            else {
                for(var i = 0; i < data.length; i++) {
                    console.log('Industry Found: ' + data[i]);
                }
                if(data.length > 0) {
                    component.set('v.industries', data);
                    component.set('v.noMatchingQuestions', false);
                    component.set('v.noIndustryFound', false);
                } else {
                    component.set('v.noMatchingQuestions', true);
                    component.set('v.noIndustryFound', true);
                    
                }
            }
            console.log(data);
            component.set('v.loadingSpin', false);
            resolve(true);	
        });
        
        $A.enqueueAction(getIndustryNames);
        //})
    },
    
    covidQuestionnaireIsNeeded: function(component, resolve, reject, helper) {
        
        //return new Promise(function(resolve, reject) {
        //var covidQuestionnaireNeeded = component.get("c.needCovidQuestionnaire");
        
        covidQuestionnaireNeeded.setParams({
            'parentAccount': component.get("v.Account"),
            formName: 'CommunityForms.cmp'
        });
        
        covidQuestionnaireNeeded.setCallback(this, function(data) {
            if (data.getState() != 'SUCCESS') {
                console.log(data.getError())
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            else {
                var covidQuestionsNeeded = data.getReturnValue();
               // component.set("v.covidQuestionsNeeded", covidQuestionsNeeded);
                resolve(true);
            }
        });
        
        $A.enqueueAction(covidQuestionnaireNeeded);
        //})
    },
        
    buildPath: function(component, event, helper) {
        console.log('Building Path...');
        //this is where we define all of the tabs along the path
        let stepObjectList = [];
        let checklist = component.get('v.PEOOnboardingChecklist');
        if (!checklist) checklist = {};
        if(checklist.Medical_Benefits_Underwriting_Requested__c == 'Yes' && component.get('v.isMedicalPrequal')){
         //US41  stepObjectList.push({ label: 'Medical', value: 'medical', title:'Medical' });
            if(checklist.Medical_Pre_Qualifier_Status__c == 'Approved' || checklist.Medical_Pre_Qualifier_Status__c == 'Declined'){
                stepObjectList.push({ label: 'Company Information', value: 'acctUpdate', title:'Company Information' });
                if (checklist.Submit_to_Workers_Comp_Underwriting__c != 'Yes - WC to be excluded') 
                    stepObjectList.push({ label: "Workers' Compensation", value: "wc", title:"Workers' Compensation" });
                //stepObjectList.push({ label: "Additional Information", value: "addtlInfo", title:"Additional Information" });
                stepObjectList.push({ label: "Add Documents", value: "addDocs", title:"Add Documents" });
                if (component.get('v.runningUser') && component.get('v.runningUser.Profile.Name') == 'Customer Community Login User Clone') {
                    stepObjectList.push({ label: 'Confirmation & Next Steps', value: "confirmationNextSteps", title:"Confirmation & Next Steps" });
                }

            }
        }
        else{
            stepObjectList.push({ label: 'Company Information', value: 'acctUpdate', title:'Company Information' });
            //JDA:SPA code update for WC QQ-start
            //if (checklist.Submit_to_Workers_Comp_Underwriting__c != 'Yes - WC to be excluded') stepObjectList.push({ label: "Workers' Compensation", value: "wc", title:"Workers' Compensation" });
            //var isQuickQuote = checklist.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && checklist.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp';
            var isQuickQuoteMed = checklist.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical';
            var isQuickQuoteWC = checklist.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp';
            if (!isQuickQuoteWC) 
                stepObjectList.push({ label: "Workers' Compensation", value: "wc", title:"Workers' Compensation" });
            //JDA:SPA code update for WC QQ-end
            //stepObjectList.push({ label: "Additional Information", value: "addtlInfo", title:"Additional Information" });
            stepObjectList.push({ label: "Add Documents", value: "addDocs", title:"Add Documents" });
            if (component.get('v.runningUser') && component.get('v.runningUser.Profile.Name') == 'Customer Community Login User Clone') {
                stepObjectList.push({ label: "Confirmation & Next Steps", value: "confirmationNextSteps", title:"Confirmation & Next Steps" });
            }
        }
        if (component.get('v.runningUser') && component.get('v.runningUser.Profile.Name') != 'Customer Community Login User Clone') {
            stepObjectList.push({ label: "Summary", value: "summary", title:"Summary" });
            if(checklist.Medical_Pre_Qualifier_Status__c != 'Approved'){
                stepObjectList.push({ label: "Submit", value: "submit", title:"Submit" });
            }
        }

        if(!component.get('v.isCommunityUser') && checklist.Platform__c == 'Flex'){
            stepObjectList.push({ label: "Implementation Questions", value: "implementation", title:"Implementation Questions" });
        }
        
        component.set('v.allSteps', stepObjectList);

        //resume functionality. need to take the current step from the checklist, add all previous steps to completed list and set the active tab
        //to the one after the completed tab.  If there are no completed steps, start from the first tab
        let tablist = [];
        //put all the tabs into a list to check progress against
        for(let i=0;i<stepObjectList.length;i++){
            var step = stepObjectList[i];
            tablist.push(step.value);
        }
        let currentStep = '';
        
        if(checklist && !$A.util.isUndefinedOrNull(checklist.Completed_Step__c)){
            console.log('Setting current step for form: '+checklist.Completed_Step__c)
            let completedStep = checklist.Completed_Step__c;
            
            //put all the tabs before and including the completed step marked on the checklist
            let completedTabs = component.get("v.completedSteps");
            for(let i=0;i<=tablist.indexOf(completedStep);i++){
                if(!completedTabs.includes(tablist[i])){
                    completedTabs.push(tablist[i]);
                }
            }
            //set the active tab to be the next tab after the completed step
            let nextTab = tablist.indexOf(completedStep) + 1;
            if (nextTab > tablist.length - 1) currentStep = tablist[nextTab - 1];
            else currentStep = tablist[nextTab];
            component.set('v.currStep', currentStep);
            component.set('v.selectedStep', tablist[nextTab] ? tablist[nextTab] : tablist[nextTab-1]);
            component.set('v.completedSteps', completedTabs);
            
            if(currentStep == 'submit'){
                helper.checkWhichFilesNeeded(component, event);
            }
        }else{
            currentStep = tablist[0];
            component.set('v.currStep', currentStep);
            component.set('v.selectedStep', tablist[0]);
        }
    },
    
    validateCompanyInfoFields: function(component, event,helper, checkList){
        var accs = component.get('v.Accounts');
        var commUser = component.get('v.isCommunityUser');
        var clientAddOn = false;
        var noAffiliation = false;
        var haveMedical = false;
        var optionalMedical = false;
        var parentAcc;
        if(checkList.Current_Aff_with_Paychex_PEO_Oasis__c == 'None'){
            noAffiliation = true;
        }
        if(checkList.Is_Medical_Underwriting_Requested__c == 'Currently have Medical, please quote'){
            haveMedical = true;
        }
        if(checkList.Is_Medical_Underwriting_Requested__c == 'Currently have Medical, please quote' || checkList.Is_Medical_Underwriting_Requested__c == 'Currently does not have Medical, please quote'){
            optionalMedical = true;
        }
        if(!commUser){
            accs.forEach((acc) => {
                if(acc.Name == '' || acc.Name == null || acc.Name == undefined ||
                (checkList.Platform__c == 'Oasis' && (acc.DBA__c == '' || acc.DBA__c == null || acc.DBA__c == undefined)) ||
                acc.Federal_ID_Number__c == '' || acc.Federal_ID_Number__c == null || acc.Federal_ID_Number__c == undefined ||
                acc.Phone == '' || acc.Phone == null || acc.Phone == undefined ||
                acc.ShippingStreet == '' || acc.ShippingStreet == null || acc.ShippingStreet == undefined ||
                acc.ShippingCity == '' || acc.ShippingCity == null || acc.ShippingCity == undefined ||
                acc.ShippingState == '' || acc.ShippingState == null || acc.ShippingState == undefined ||
                acc.ShippingPostalCode == '' || acc.ShippingPostalCode == null || acc.ShippingPostalCode == undefined) {
                	if(checkList.Prospect_Client__c == acc.Id){
                		component.set('v.isCompanyInfoAYBFilledParent', false);
            		}else{
                        component.set('v.isCompanyInfoAYBFilledChild', false); 
                    }
                	//component.set('v.isCompanyInfoAYBFilled', false);
            	}else{
    				if(checkList.Prospect_Client__c == acc.Id){
                		component.set('v.isCompanyInfoAYBFilledParent', true);
            		}else{
                        component.set('v.isCompanyInfoAYBFilledChild', true); 
                    }
                    
                	///if(component.get('v.isCompanyInfoAYBFilledParent')){
                		//component.set('v.isCompanyInfoAYBFilled', true);
            		//}
 					//if(component.get('v.isCompanyInfoAYBFilledChild')){
    				//	component.set('v.isCompanyInfoAYBFilledChild', true);
					//}
                }
        		if(checkList.Prospect_Client__c == acc.Id){
            		parentAcc = acc;
        		}
            });
            if(checkList.Client_Add_on__c && accs.length == 1){
                clientAddOn = true;
            }
            if((checkList.Total_Number_of_Employees__c == undefined || checkList.Total_Number_of_Employees__c == null || checkList.Total_Number_of_Employees__c == '') ||
               (noAffiliation && ((checkList.Currently_using_a_PEO__c == undefined || checkList.Currently_using_a_PEO__c == null || checkList.Currently_using_a_PEO__c == '') || (checkList.Currently_using_a_PEO__c == 'Yes' && (checkList.Current_PEO_Provider__c == undefined || checkList.Current_PEO_Provider__c == '' || checkList.Current_PEO_Provider__c == null)) || (checkList.Currently_using_a_PEO__c == 'No' && (checkList.Previous_Paychex_PEO_Oasis_HROI_client__c == undefined || checkList.Previous_Paychex_PEO_Oasis_HROI_client__c == '' || checkList.Previous_Paychex_PEO_Oasis_HROI_client__c == null)))) ||
               (haveMedical && (checkList.Medical_Carriers_currently_in_use__c == undefined || checkList.Medical_Carriers_currently_in_use__c == '' || checkList.Medical_Carriers_currently_in_use__c == null || checkList.Is_Your_Plan_Self_Funded_or_Level_Funded__c == undefined || checkList.Is_Your_Plan_Self_Funded_or_Level_Funded__c == '' || checkList.Is_Your_Plan_Self_Funded_or_Level_Funded__c == null || checkList.medical_coverage_renewal_date__c == undefined || checkList.medical_coverage_renewal_date__c == '' || checkList.medical_coverage_renewal_date__c == null)) ||
               (optionalMedical && (checkList.Benefit_Effective_Date__c == undefined || checkList.Benefit_Effective_Date__c == '' || checkList.Benefit_Effective_Date__c == null || checkList.Headquarter_State__c == undefined || checkList.Headquarter_State__c == '' || checkList.Headquarter_State__c == null)) ||
               (checkList.state_with_most_employees__c == undefined || checkList.state_with_most_employees__c == '' || checkList.state_with_most_employees__c == null) ||
               (parentAcc.NAICS_Code__c == undefined || parentAcc.NAICS_Code__c == '' || parentAcc.NAICS_Code__c == null) || 
               (checkList.description_principle_product_business__c == undefined || checkList.description_principle_product_business__c == '' || checkList.description_principle_product_business__c == null) ||
               (parentAcc.Website == undefined || parentAcc.Website == '' || parentAcc.Website == null ) ||
               (checkList.had_wrkrs_comp_claim_past_3_yrs__c == undefined || checkList.had_wrkrs_comp_claim_past_3_yrs__c == '' || checkList.had_wrkrs_comp_claim_past_3_yrs__c == null) ||
               ((accs.length > 1 || clientAddOn) && (checkList.Ownership_Structure__c == undefined || checkList.Ownership_Structure__c == '' || checkList.Ownership_Structure__c == null))){
                component.set('v.isCompanyInfoADFilled', false);
            }else{
                componen.set('v.isCompanyInfoADFilled', true);
            }
            
            
        }else{
            component.set('v.isCompanyInfoAYBFilled', true);
            component.set('v.isCompanyInfoADFilled', true);
        }
    },
    
    loadFinished : function(component, event,helper) {
        component.set("v.contentLoaded", true);
        let finishLoadingEvent = component.getEvent('FinishLoadingCommunityForms');
        finishLoadingEvent.setParams({
            finishedLoading: true
        }); // this needs to go to the page after the submit screen
        finishLoadingEvent.fire();   
    },
    
    increaseStep : function(component, event) {
        var step = component.get("v.Step");
        step = step + 1;
        component.set("v.Step", step);
    },
    
    decreaseStep : function(component, event) {
        var step = component.get("v.Step");
        step = step - 1;
        component.set("v.Step", step);
    },
    
    checkWhichFilesNeeded : function(component, event) {
        console.log('checkWhichFilesNeeded');
        if(component.get("v.requestedMedical")  === true )component.set("v.misMedReqd", true);
        //Parent checklist validations happen here for upload files
        var chldChklst = component.get("v.PEOOnboardingChecklist");
        if(chldChklst.CensusRequired__c === true)component.set('v.censusRequired', true)
        else component.set('v.censusRequired', false)
        if(chldChklst.Claims_Report_required__c === true)component.set('v.claimsReportRequired', true)
        else component.set('v.claimsReportRequired', false)
        if(chldChklst.Health_Insurance_Renewal_required__c === true)component.set('v.hlthInsRenwReqd', true)
        else component.set('v.hlthInsRenwReqd', false)
        if(chldChklst.Health_Insurance_Summary_required__c === true)component.set('v.hlthInsSummReqd', true)
        else component.set('v.hlthInsSummReqd', false)
        if(chldChklst.Health_Invoice_required__c === true)component.set('v.hlthInvReqd', true)
        else component.set('v.hlthInvReqd', false)
        if(chldChklst.Loss_Runs_required__c === true)component.set('v.lossRunsReqd', true)
        else component.set('v.lossRunsReqd', false)
        if(chldChklst.Payroll_Register_Required__c === true)component.set('v.payrollRegReqd', true)
        else component.set('v.payrollRegReqd', false)
        if(chldChklst.SUI_Required__c === true)component.set('v.suiReqd', true)
        else component.set('v.suiReqd', false)
        if(chldChklst.WC_Declarations_Required__c === true)component.set('v.wcDecReqd', true)
        else component.set('v.wcDecReqd', false)
        if(chldChklst.WC_RatesAndPricing_Required__c === true)component.set('v.wcRtNPrcReqd', true)
        else component.set('v.wcRtNPrcReqd', false)
            },
    
    // This takes in all accounts and updates the attributes on the component
    // that control if the user is able to edit any of the fields or upload
    // files based on some status values on the Parent account
    setUWStatusLock: function(component, allAccounts, uwChecklist,helper) {
        //US36
        
      	 let CSCMStatusLockCodes = ['Prospect'];        
        let MedUWStatusLockCodes = ['More Info Needed', 'Full Underwriting Required','Abandoned'];        
        let WCUWStatusLockCodes =['More Info Needed', 'Full Underwriting Required'] ;
        
        var lockEdit = false;
        var lockMed = false;
        var lockWC = false;
        var lockMsg = '';
        var lockMessageMed = '';
        var lockMessageWc = '';
        
        if (!$A.util.isUndefinedOrNull(uwChecklist.CS_CM_Contract_Status__c) 
            	&& !CSCMStatusLockCodes.includes(uwChecklist.CS_CM_Contract_Status__c)) {            
             lockEdit = true;
        }
        if  (!$A.util.isUndefinedOrNull(uwChecklist.CS_CM_Medical_UW_Status__c) 
                && !MedUWStatusLockCodes.includes(uwChecklist.CS_CM_Medical_UW_Status__c)) {
            lockMed = true;
        }        
        if (!$A.util.isUndefinedOrNull(uwChecklist.CS_CM_WC_UW_Status__c) 
                && !WCUWStatusLockCodes.includes(uwChecklist.CS_CM_WC_UW_Status__c)) {
            lockWC = true;
        }
        if( (uwChecklist.Medical_Quick_Quote_Eligibility__c	=='Full Underwriting Required' 
             	|| uwChecklist.Workers_Comp_Quick_Quote_Eligibility__c=='Full Underwriting Required')
           		&& component.get('v.isCommunityUser')){ 
                lockMsg =  'Your information has been reviewed — we only need a few more details to customize Paychex HR PEO to your business. Your sales partner will get in touch to go over how to provide the additional information, documents, and/or forms. Thank you for considering Paychex for your HR and insurance needs.';
          }
        
        /*
        else if(lockEdit && !component.get('v.isCommunityUser')){
           
            if(lockEdit){
                lockMsg = 'This Prospect-Client has been submitted to underwriting and is under review';            
            }           
        }*/
         //US36
        component.set('v.lockEditing', lockEdit);
        component.set('v.lockMedicalEditing', lockMed);
        component.set('v.lockWCEditing', lockWC);
        
        component.set('v.lockMessage', lockMsg);       
        component.set('v.lockMessageMed', lockMessageMed);
        component.set('v.lockMessageWC', lockMessageWc);
    },
        
    // The entry point for all auto save operations from the controller
    // First check to see if we need to immedietly auto save the records.
    // if so, send a call to the manageAutoSaveServerCall method which will handle
    // removing the records that are already being saved, and saving what's left.
    // Then check to see if we need to cancel an autosave operation. If so, trigger the 
    // manageAutoSaveServerCall which will also handle canceling. Bail out of method if
    // first or second condition is true.
    // Finally start to parse the params and send the call to addFieldValueToStore
    // which manages reseting the timer and updating the auto save storage
    manageAutoSave: function(cmp, e, helper, now) {
        return new Promise(function(resolve, reject) {
            // IF we need to cancel the operation send the call to manageAutoSaveServerCall
            // and return from the method
             let sendImmedieteSave = now ? now : e.getParam('sendImmediete');
            if (sendImmedieteSave) {
                console.log('manageAutoSave.sendImmedieteSave')
                cmp.set('v.sessionChangesUnsaved', false);
                helper.manageAutoSaveServerCall(cmp, e, helper, {sendImmediete: true})
                .then(function(res) {
                    return resolve(res);
                })
                .catch(function(err){
                    console.log('manageAutoSave.err')
                    console.log(err)
                });
            }
            
            // IF we need to cancel the operation send the call to manageAutoSaveServerCall
            // and return from the method
            let cancel = e.getParam('cancelAll');
            if (cancel) {
                return helper.manageAutoSaveServerCall(cmp, e, helper, {clear: true});
                
            }
            
            // get the stored values
            // parse the event to get values we need
            let accountId = e.getParam('accountId');
            let accountName = e.getParam('accountName'); 
            let recordId =  e.getParam('recordId');
            let fieldAPIName = e.getParam('fieldName');
            let objectName = e.getParam('objectName');
            let fieldValue = e.getParam('fieldValue');
            
            // get the map containing multiple records to add to the auto save if it exists
            let multiFieldMap = e.getParam('objectToFieldsMap');
            
            // loops the map of multiple records to save. If one doesn't exist we won't
            // enter this logic
            // Get all the params from the object including the record fields
            // for each field send a request to add it to the storage
            for (let objectName in multiFieldMap) {
                let objectMap = multiFieldMap[objectName];
                let accountName = objectMap.accountName;
                let recordId = objectMap.recordId;
                console.log('saving recordId'+recordId);
                let fieldList = objectMap.fields;
                
                // loop over the fields and add them to the storage
                for (let fieldAPIName in fieldList) {
                    let fieldSaveParams = {
                        fieldAPIName: fieldAPIName,
                        objectAPIName: objectName,
                        FieldValue: fieldList[fieldAPIName],
                        recordId: recordId,
                        accountName: accountName
                    };
                    return helper.addFieldValueToStore(cmp, e, helper, fieldSaveParams);
                }
            }
            
            // only send the save request for a field if we have all the parameters we need
            if (accountName && recordId && fieldAPIName && objectName) {
                let fieldParams = {
                    fieldAPIName: fieldAPIName,
                    objectAPIName: objectName,
                    FieldValue: fieldValue,
                    AccountID: accountId,
                    recordId: recordId,
                    accountName: accountName
                };
                
                return helper.addFieldValueToStore(cmp, e, helper, fieldParams);   
            } else {
                console.log(`Null value provided for auto save registering: accountName = ${accountName} \n recordId = ${recordId} \n fieldAPIName = ${fieldAPIName} \n objectName = ${objectName}`)
            }
        });
    },
        
        
    // adds individual field values to the auto save storage
    // @Params: 
    // fieldVals: map with values relevent to the new add
    // first match/create on the account to get the object: {accId: {account, checklist, ...}, accId2: {...}}
    // then update the value for the passed in field API name on that map
    // finally reset the timer to reset the auto save timer
    addFieldValueToStore: function(cmp, e, helper, fieldVals){
        console.log('addFieldValueToStore...');
        let foundMAtch;
        // store could be blank or could have values: 
        let store = cmp.get('v.RecordsToSave');
        let accountRecordsMap;
        let recordMap;
        if (!store) store = {};
        
        // search for a matching account using the account ID passed in and in the storage
        for (let accName in store) {
            if (accName == fieldVals.accountName) {
                accountRecordsMap = store[accName];
                foundMAtch = true;
                break;
            }
        }
        
        // if an account match is not found
        // create a new instance of the object for the account
        if (!accountRecordsMap) {
            helper.createAccountMapInStore(store, fieldVals.accountName);
            accountRecordsMap = store[fieldVals.accountName];
            //createRecordMapInAccountMap(store[fieldVals.AccountID], fieldVals.recordId, fieldVals.objectAPIName);
            // store should be like {accName: {Account: {recordId: xxxxxxxxxx}}}
        }
        
        // find the matching record on the mapping
        recordMap = accountRecordsMap[fieldVals.objectAPIName]; 
        
        // if record is not found
        // create an instance of it on the map
        if (!recordMap) {
            recordMap = helper.createRecordMapInAccountMap(accountRecordsMap, fieldVals.recordId, fieldVals.objectAPIName);
        } 
        
        // change the createRecordMapInAccountMap to return the last index if rec it's inserting
        // into an array. Save two lines
        if (Array.isArray(recordMap)) {
            recordMap = recordMap[recordMap.length - 1];
        }
        
        recordMap[fieldVals.fieldAPIName] = fieldVals.FieldValue;    
        
        // set the new values on the component
        cmp.set('v.RecordsToSave', store);
        var sendImmediete = e.getParam('sendImmediete');
        var reset = !sendImmediete;
        let p = {reset: reset, clear: false,sendImmediete : sendImmediete, records: store};
        
        // Reset timer to initiate save 
       return helper.manageAutoSaveServerCall(cmp, e, helper, p);   
    },
    // Manages the queued calls to the server to save records.
    // Params contains arguments used for funtionality
    // clear: if true clears all instances of queued saves. Triggered for manual saves
    // reset: if true clears all insteances of queued saves and sends new save request for 2.5 mins
    manageAutoSaveServerCall: function(cmp, e, helper, params) {
        console.log('manageAuroSaveSerercall....');
        return new Promise(function(resolve, reject) {
           let records = cmp.get('v.RecordsToSave');
            
            // if reset
            if (params.reset) {
                console.log('inside reset');

                // clear all instances of the apex calls
                // create new instance using the sendAutoSave method 
                if (cmp.get('v.autoSaveFunction')) clearTimeout(cmp.get('v.autoSaveFunction'));
                cmp.get("v.autoSave")
                console.log('858');
                var inputTimer = setTimeout($A.getCallback(() => helper.sendAutoSave(cmp, e, helper, params.records)), 60000);
                console.log('860');
                cmp.set("v.autoSaveFunction", inputTimer);
                return resolve(true);
            }
            
            // if clearing timer
            // remove all async calls and restore the RecordsToSave to a blank obj
            if (params.clear) {
                return resolve(helper.resetAutoSaveToDefault(cmp, e, helper));
            }
            
            // If need to remove then save
            // send the call to remove the records if the params object 
            // contains any(it should), then send the request to save immedietly
            if (params.sendImmediete) {
                console.log('manageAutoSaveServerCall.sendImmediete.send')
                return helper.sendAutoSave(cmp, e, helper, records)
                .then(function(res) {
                    helper.resetAutoSaveToDefault(cmp, e, helper);
                    return resolve(res);
                })
                .catch(function(err) {
                    console.log(`manageAutoSaveServerCall.err: ${err.message}`)
                    return reject(false);
                });
            }
        })
    },
    // send the auto save request
    // Surfaces UI message for auto save in progress
    // recieves the storage as params. Sends the auto save apex call for each
    // object type(maybe do a generics kind of thing?)
    sendAutoSave: function(cmp, e, helper, records) {
        console.log('sendAutoSave...')
        return new Promise(function(resolve, reject) {
            try {
                let autoSaveAction = cmp.get('c.handleAutoSaveRecords');
                // list map is just a storage for the list of records to be saved
                let listMap = {
                    Account: [],
                    PEO_Onboarding_Checklist__c: [],
                    PEO_Onboarding_Medical_Questionnaire__c: [],
                    WC_Questionnaire_Industry_Specific__c: [],
                    Opportunity: [],
                    Policy_Period__c: [],
                    PEO_Implementation_Checklist__c : []
               };
                // loop over the records passed into the method
                for (let accountName in records) {
                    // get the map of records to be saved: {Account: {}, PEO_MedicalQuestionnaire: {}}
                    let recordTypeMap = records[accountName];
                    // iterate the map of records
                    // if the record is an array iterate that array and add each record to its
                    // respective listMap storage place. Otherwise just add the record to it's respective
                    // listMap storage place.
                    for (let recordType in recordTypeMap) {
                        if (Array.isArray(recordTypeMap[recordType])) {
                            let recordArray = recordTypeMap[recordType];
                            recordArray.forEach(rec => listMap[recordType].push(rec));
                        } else {
                            listMap[recordType].push(recordTypeMap[recordType]);
                        }
                    }
                }
                
                // add the lists of records to be saved to the server action and send the action
                autoSaveAction.setParams({
                    accounts: listMap.Account,
                    checklists: listMap.PEO_Onboarding_Checklist__c,
                    medicalForms: listMap.PEO_Onboarding_Medical_Questionnaire__c,
                    policyPeriodForms: listMap.Policy_Period__c,
                    industryForms: listMap.WC_Questionnaire_Industry_Specific__c,
                    lstPEOImpchk : listMap.PEO_Implementation_Checklist__c,
                    formName: 'CommunityForms.cmp'
                });
                
                //console.log('like 1032 executed PEOUWCommunityFormsHelper');
                // the auto save shouldn't alter much on the form since it's a background process.
                // Maybe a small UI message or something to indicate success or failure.
                // Add something to turn auto save off if fatal error?
                autoSaveAction.setCallback(this, function(res) {
                    //console.log('like 1037 executed PEOUWCommunityFormsHelper'+res.getReturnValue());
                    if (res.getState() != 'SUCCESS') {
                        console.log('error saving')
                        console.log(res.getError())
                        return resolve(false);
                    }
                    //debugger;
                    return resolve(res.getReturnValue());
                });
                $A.enqueueAction(autoSaveAction);
            }catch(e) {
                let t = 'Error',
                    m = `Auto Save Error please try again or provide these details to your Administrator: ERROR sendAutoSave: ${e.message}`,
                    ty = 'Error';
                return reject({t: t, m: m, ty: ty});
            }
        })
    },
    // used when an account does not have a map value in storage
    // creates generic map with accId as key and empty map as value
    createAccountMapInStore: function(store, accName) {
        store[accName] = {};
        return store;
    }, 
    // add a new instance of the record to be saved into the storage. 
    // Expect to be passed in the map of records either blank or not: {Account: {}} and expect
    // to create a new instance on the map for the record and OBJ name:
    // before: {Account: {Id: xxxxxx}}, After: {Account: {Id: xxxxxx}, Policy_Period__c: [{Id: xxxx}]}
    // NOTE: some records have a many to one rerlationship with a parent. These will be stored as an array of
    // records shown with policy periods
    createRecordMapInAccountMap: function(accountRecordStore, recordId, objName) {
        if (objName == 'Policy_Period__c') {
            accountRecordStore[objName] = [{Id: recordId}];
            return accountRecordStore[objName][0];
        }
        
        accountRecordStore[objName] = {Id: recordId}; 
        return accountRecordStore[objName];
    },
    // clear the auto save storage and timed autoSave function call 
    resetAutoSaveToDefault: function(cmp, e, helper) {
        cmp.set('v.RecordsToSave', {});
        return clearTimeout(cmp.get("v.autoSaveFunction"));
    },
    
    sendCompleteNotification: function(component, event, helper,currentStep){
        var sendEmail = component.get('c.sendCompleteEmail');
        let obChecklist = component.get('v.PEOOnboardingChecklist')
        let allAccounts = component.get('v.Accounts');
        var acctName;
        if(allAccounts){
            acctName = allAccounts[0].Name;
        }
        console.log('sendCompleteNotification acctName'+acctName);
        if(obChecklist && acctName && currentStep){
            console.log('triggering notif')
            sendEmail.setParams({
                checklist : obChecklist,
                accountName : acctName,
                currStep : currentStep
            });
            sendEmail.setCallback(this, function(res){
                var state = res.getState(); 
                var data = res.getReturnValue();
                if (state != 'SUCCESS' || !data) {
                    console.log('email send error')
                }
                else {
                    console.log('email send success');
                }
            });
            $A.enqueueAction(sendEmail);
        }
        else{
            console.log('something is missing');
        }
        
    },
    handleError: function(data) {
        console.log(data)
        var event = $A.get("e.force:showToast");
        event.setParams({
            title: data.t,
            message: data.m,
            type: data.ty
        });
        event.fire();
        
        if (data.broke) $A.get("e.force:closeQuickAction").fire();
    },
    refreshWCRelatedProperties: function(cmp, e, helper) {
        try{
            console.log('IN refresh call');
            helper.helperFunctionAsPromise(cmp, helper.getIndustryNames, helper)
            .then($A.getCallback(function() {
                return helper.helperFunctionAsPromise(cmp, helper.covidQuestionnaireIsNeeded, helper)
            }))
            .then(res => console.log('Success: '+res))
            .catch(err => console.log(err));
        }catch(e) {
            console.log('refresh err');
            console.log(err);
        }
    },
    // log procy obj
    _logProxyObJ: function(obj) {
        for (let i in obj) {
            console.log(i + ': '+ obj[i]);
    	}
    },
    
    //JDA
    pendoAfter: function (component, event, helper){
       console.log('Inside pendo After');
       console.log('isCommunityUser:'+component.get('v.isCommunityUser'));
       var isCommunityUser = component.get('v.isCommunityUser'); 
       if(isCommunityUser){
           var uID = $A.get( "$SObjectType.CurrentUser.Id" );
           console.log ('JC running user ' + uID);  
           pendo.initialize({
               visitor: {
                   id:  uID
               },
               
               account: {
                   id: 'SFDCPEOEdge'
               }
           });
           console.log('pendo finished ');
       }
        
    }, 
        
        getUserAttributes: function(component, resolve, reject, helper) {
            // get sys permissions
            // get running user
            // get comm user
            let getAttributeAction = component.get('c.getCommunityFormsUserAttributes');
            getAttributeAction.setParams({
                startingId: component.get("v.recordId"),
                formName: 'CommunityForms.cmp'
            });
            
            getAttributeAction.setCallback(this, function(resp) {
                if (resp.getState() != 'SUCCESS') {
                    let t = 'Error',
                        m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                        ty = 'Error';
                    return reject({t: t, m: m, ty: ty});
                }
                
                let {hasAccess, runningUser, communityUser} = resp.getReturnValue();
                // get sys permission
                component.set("v.hasAccess", hasAccess ? true : false);
                
                // get running user
                component.set("v.runningUser", runningUser);
                
                // get comm user
                if(runningUser && runningUser.Profile.Name.includes("Community"))
                {
                    component.set('v.isCommunityUser', true);
                }
                component.set("v.communityUser", communityUser);
                return resolve(true);
            });
            
            $A.enqueueAction(getAttributeAction);
        },
            getChecklistrecord: function(component, resolve, reject, helper) {
                let getRecordsAction = component.get('c.getCommunityFormRecords');
                getRecordsAction.setParams({
                    formName: 'CommunityForms.cmp', 
                    startingId: component.get("v.recordId")
                });
                    
                getRecordsAction.setCallback(this, function(resp) {
                    if (resp.getState() != 'SUCCESS') {
                        console.log(resp.getError())
                        let t = 'Error',
                            m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                            ty = 'Error';
                        return reject({t: t, m: m, ty: ty});
                    }
                    let {oppty, 
                        isEmailSent, 
                        peoOnboardingChecklist, 
                        childChecklists, 
                        allAccounts,
                        industryNames} = resp.getReturnValue();
                    
                    // getAccountInfo
                    if(allAccounts != null) {
                        component.set("v.Account", allAccounts[0]);
                        component.set("v.parentAccountId", allAccounts[0].Id);
                        component.set("v.Accounts", allAccounts);
                    } 
                    else {
                        let t = 'Error',
                            m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                            ty = 'Error';
                        return reject({t: t, m: m, ty: ty});
                    }

					// getChildChecklists                    
                    component.set('v.childAccsChecklist', childChecklists);

					// getIndustryNames     
					if (industryNames && industryNames.length) {
                        for(var i = 0; i < industryNames.length; i++) {
                            console.log('Industry Found: ' + industryNames[i]);
                        }
                        component.set('v.industries', industryNames);
                        component.set('v.noMatchingQuestions', false);
                        component.set('v.noIndustryFound', false);
                    } else {
                        component.set('v.noMatchingQuestions', true);
                        component.set('v.noIndustryFound', true);    
                    }
                   
                    // get checklist
                    if (peoOnboardingChecklist) {
                        console.log('getChecklist successful');
                        component.set("v.PEOOnboardingChecklist", peoOnboardingChecklist);
                        
                        // set all the attributes to lock edit or upload access based on status fields
                        helper.setUWStatusLock(component, component.get("v.Accounts"), peoOnboardingChecklist, helper);
                        
                        var ownerObjects = component.get('v.peoOnbCheckOwners');
                        if(peoOnboardingChecklist.List_of_Owners__c != null && peoOnboardingChecklist.List_of_Owners__c != undefined)
                        {
                            var ownerAndPercentList = peoOnboardingChecklist.List_of_Owners__c.split(';');
                            if(ownerAndPercentList.length > 0)
                            {
                                for(var index = 0; index < ownerAndPercentList.length; index++)
                                {
                                    var ownerInfo = ownerAndPercentList[index].split(',');
                                    var ownerName = "";
                                    var ownerPercent = "";
                                    
                                    if(ownerInfo[0] != null && ownerInfo[0] != 'undefined')
                                    {
                                        ownerName = ownerInfo[0];
                                    }
                                    if(ownerInfo[1] != null && ownerInfo[1] != 'undefined')
                                    {
                                        ownerPercent = ownerInfo[1];
                                    }
                                    var ownerData = {nameOfOwner:ownerName, percentOfOwner:ownerPercent};
                                    ownerObjects.push(ownerData);	
                                }
                                //console.log('ownerObjects='+ownerObjects);
                                component.set("v.peoOnbCheckOwners", ownerObjects);
                            }
                        }
                        else
                        {
                            var ownerObjects = component.get('v.peoOnbCheckOwners');
                            var ownerData = {nameOfOwner:"", percentOfOwner:""};
                            ownerObjects.push(ownerData);
                            //console.log('ownerObjects='+ownerObjects);
                            component.set("v.peoOnbCheckOwners", ownerObjects);
                        }
                        
                        if(peoOnboardingChecklist.Workers_Comp_FastPass__c == 'Yes') {
                            component.set('v.WCFastPass', true);
                        }
                        
                        if(peoOnboardingChecklist.Medical_Underwriting_Path__c == 'Gradient Pre-Qualifier'){
                            component.set('v.isMedicalPrequal', true);
                        }
                    } 
                    
                    // getImplementationQuestionTabVisibility
                    component.set("v.showExternalTab", isEmailSent ? true : false);
                    
                    // getOppty
                    component.set('v.Opportunity', oppty);
                    component.set('v.loadingSpin', false);
                    return resolve(true);
                });
                
                
                $A.enqueueAction(getRecordsAction);
            }
})