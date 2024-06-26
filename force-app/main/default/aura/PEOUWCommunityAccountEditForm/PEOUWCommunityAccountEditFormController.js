({
    clearout : function(cmp, e, helper){
        var evtId = e.getSource().getLocalId();
        let relatedFieldList = cmp.get('v.relatedFieldList');
        if(evtId==='isDental'){
            if(cmp.get("v.viewPEOChecklist.Has_current_dental_carrier__c")=='No'){ 
                cmp.set("v.viewPEOChecklist.Interested_in_dental__c",'');
                cmp.set("v.viewPEOChecklist.Who_is_your_Current_Dental_Carrier__c",'');
                relatedFieldList.push('Has_current_dental_carrier__c','Interested_in_dental__c','Who_is_your_Current_Dental_Carrier__c');
            }
        }
        else if(evtId==='isVision'){
            if(cmp.get("v.viewPEOChecklist.has_current_Vision_Carrier__c")=='No'){
                cmp.set("v.viewPEOChecklist.interested_in_Vision__c",'');
                cmp.set("v.viewPEOChecklist.Who_is_your_Current_Vision_Carrier__c",'');
                relatedFieldList.push('interested_in_Vision__c','Who_is_your_Current_Vision_Carrier__c');
            }
        }
            else if(evtId==='isMedical'){
                if(cmp.get("v.viewPEOChecklist.Current_Medical_Coverage_Provided__c")=='No'){
                    cmp.set("v.viewPEOChecklist.Number_of_Enrolled_Employees__c",'');
                    relatedFieldList.push('Number_of_Enrolled_Employees__c');
                }
            }
        helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
        let field = e.getSource();
        helper.runAutoSave(cmp, e, helper, field);     },
    
    okay: function(component, e, helper){
        component.set('v.showMsg', false);	
    },
    
    handleLongTextChange: function(cmp, e, helper) {
        var timer = cmp.get('v.timeoutId');
        clearTimeout(timer);
        var timer = setTimeout(
            $A.getCallback(function(){
                cmp.set('v.timeoutId', null);
                helper.handleChange(cmp, e, helper);
            }),
            300);
        cmp.set('v.timeoutId', timer);
    },
    
    handleSelect: function (cmp, event, helper) {
        let finValidation = helper.finFieldValidation(cmp, event, helper);
        if(!finValidation){
            cmp.set('v.selectedTab','About Your Business');
            cmp.set("v.errorText", "Please enter a valid Federal Identification Number.");
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: 'Error',
                message: 'Please enter valid data and provide value for required fields',
                type: 'error'
            });
            toastEvent.fire(); 
        }else{
            cmp.set("v.errorText",'');
        }
    },
    
    handleChange: function(cmp, e, helper) {
        // should update the object storing the reference values to contain the vlaue from the current field
        // set the boolean to indicate a change occuered to true
        
        let field = e.getSource();
        console.log('handleChange field type:'+field.get("v.type"));
        console.log('handleChange field name:'+field.get("v.name"));
        let fieldType = field.get("v.type");
        let fieldName = field.get("v.name");
        let fields;
        //sfdc:25032- Apply debouncing
        //Check if field type is text and add delay
        //else do the regular handle change // && fieldName != 'Account.Federal_ID_Number__c'
        if(fieldType != undefined && fieldType == 'text' && fieldName != 'Account.Federal_ID_Number__c'){
            console.log('handleChange fieldType text');
            var timer = cmp.get('v.timeoutId');
            clearTimeout(timer);
            
            var timer = setTimeout(
                $A.getCallback(function() {
                    helper.handleChange(cmp, e, helper);
                    cmp.set('v.timeoutId', null);
                })
                , 300);
            cmp.set('v.timeoutId', timer);
        }
        else{
            console.log('handleChange no delay for save send');
            helper.handleChange(cmp, e, helper);
        }
    },
    
    //this method determines if backspace is pressed or not
    keyCheck : function(component, event, helper){
        if (event.which == 8)component.set('v.onBackspacePress',true)
        else component.set('v.onBackspacePress',false);
    },
    
    setViewedChecklist: function(cmp, e, helper) {
        console.log('****SETVIEWEDCHECKLIST****');
        cmp.set('v.saveFunc' , $A.getCallback(() => helper.save(cmp, e, helper)));
        var curUser = cmp.get('v.currentRunningUser');
        let Opty = cmp.get('v.Opportunity');
        console.log('Opty:', Opty);
        if(!cmp.get("v.communityUser") && (curUser.Sales_Org__c == 'PAS' || curUser.Sales_Org__c == 'PEO' || curUser.Profile.Name.includes('System Admin'))) {
            cmp.set('v.stateRequired', true);
        }
        
        let isCommUser = cmp.get('v.communityUser');
        let msg;
        if (isCommUser) msg = 'We’re sorry, your request can’t be completed right now. Please try again. For support, visit the Need Help section on our homepage, so we can promptly address the issue.';
        else msg = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.';
        cmp.set('v.errorMsg', msg);
        
        helper.fetchPickListVal(cmp);
        var tabs = ['About Your Business', 'Additional Details'];
        let checklist = cmp.get("v.PEOChecklist");
        if(checklist.Client_Add_on__c && cmp.get('v.allAccts').length == 1){
            cmp.set('v.clientAddOn', true);
        }
        console.log('clientAddOn: ' , cmp.get('v.clientAddOn') );
        console.log('allAccts: ' , cmp.get('v.allAccts') );
        
         var headquater = checklist.Headquarter_State__c;
        console.log('headquater ::: '+headquater);
        if ((headquater == 'HI') || (headquater == 'MI') || (headquater == 'NH')) {
            cmp.set('v.headquaterValue', true);
            const helpText = 'HI MI and NH require a PEO client to be on the WC master policy. If the risk does not meet WC UW Guidelines and WC is not approved, then this group will not be allowed on the PEO. If you have questions, please refer to your DSM.';
            cmp.set('v.headquaterHelpText', helpText);
        }
        else{
            cmp.set('v.headquaterValue', false);
        }
        
        var mostEmpSate = checklist.state_with_most_employees__c;
        console.log('mostEmpSate ::: '+mostEmpSate);
        if ((mostEmpSate == 'HI') || (mostEmpSate == 'MI') || (mostEmpSate == 'NH')) {
            cmp.set('v.mostEmp', true);
            const helpText = 'HI MI and NH require a PEO client to be on the WC master policy. If the risk does not meet WC UW Guidelines and WC is not approved, then this group will not be allowed on the PEO. If you have questions, please refer to your DSM.';
            cmp.set('v.headquaterHelpText', helpText);
        }
        else {
            cmp.set('v.mostEmp', false);
        }
        
        if (cmp.get('v.firstStep') == 0) {
            console.log('firststep' ,cmp.get('v.firstStep'));
            console.log(checklist);
            cmp.set("v.viewPEOChecklist", checklist);
            var frequencies = (!$A.util.isUndefinedOrNull(checklist.Payroll_Frequency__c) ? checklist.Payroll_Frequency__c.split(';'):[]);
            cmp.set('v.frequencyValues', frequencies);
            if(checklist.Medical_Benefits_Underwriting_Requested__c == 'Yes' ||  cmp.get("v.medicalWasRequested")) {
                cmp.set("v.viewMedicalQuestionnaire", cmp.get("v.medicalQuestionnaire"));
            }
            
            helper.prepareOwnerRecData(cmp, e);
        }else{
            helper.getChecklist(cmp, e);
        }
        
        if(checklist.Is_Medical_Underwriting_Requested__c == 'Currently have Medical, please quote' || checklist.Is_Medical_Underwriting_Requested__c == 'Currently does not have Medical, please quote'){
            console.log('setting optionalMedical');
            cmp.set('v.optionalMedical', true);
        }
        if(checklist.Is_Medical_Underwriting_Requested__c == 'Currently have Medical, please quote'){
            console.log('setting haveMedical');
            cmp.set('v.haveMedical', true);
        }
        if(checklist.Current_Aff_with_Paychex_PEO_Oasis__c == 'None'){
            console.log('setting noAffiliation');
            cmp.set('v.noAffiliation', true);
        }
        var acc = cmp.get('v.currentAccount');
        console.log('Account: ' , acc);
        if(acc.isParent__c || (!acc.isParent__c && acc.SalesParent__c == undefined)){
            cmp.set('v.isParent', true);
            cmp.set('v.isChild', false);
        }else{
            cmp.set('v.isParent', false);
            cmp.set('v.isChild', true);
        }
        console.log('isParent: ' ,cmp.get('v.isParent'));
        
        //Benchmark
        if($A.get("$Label.c.PEOUWCustomBenchmarkView") == 'true'){
            helper.checkPermissions(cmp, e, helper);
        }
        
        cmp.set('v.tabList',tabs);
        var options = [{label:'Board Owned',value:'Board Owned'},{label:'C-Corporation',value:'C-Corporation'}
                       ,{label:'Church Organization',value:'Church Organization'},{label:'Government',value:'Government'} 
                       ,{label:'Individual/Sole Proprietor',value:'Individual/Sole Proprietor'},{label:'Joint Venture',value:'Joint Venture'} 
                       ,{label:'Limited Partnership',value:'Limited Partnership'},{label:'Not For Profit',value:'Not For Profit'} 
                       ,{label:'Other',value:'Other'},{label:'Partnership',value:'Partnership'} 
                       ,{label:'Personal Service Corporation',value:'Personal Service Corporation'},{label:'Professional Corporation',value:'Professional Corporation'} 
                       ,{label:'S-Corporation',value:'S-Corporation'},{label:'Tax Exempt',value:'Tax Exempt'}
                       ,{label:'Trust',value:'Trust'} 
                      ];
        //cmp.set('v.EntityTypeOptions',options);
        cmp.set('v.initialNaicsCode',cmp.get('v.currentAccount.NAICS_Code__c'));
        helper.setParentTablistForButtons(cmp, e, helper);
        helper.addTabNumbers(cmp, e, helper);
        //helper.validateAllTabs(cmp, e, helper);
        //cmp.set('v.init', true);
        console.log('method end');
        
    },
    handleOwnerChange : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.getSource().get('v.name'));
        let ownerRecs = cmp.get("v.ownerRecs");
        let userInput = e.getSource().get('v.value');
        ownerRecs[ownerRecIndex].nameOfOwner = userInput;
        cmp.set("v.ownerRecs",ownerRecs);
        helper.sendOwnerAutoSave(cmp, e, helper);
    },
    
    calculatePercentOwnership : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.getSource().get('v.name'));
        let ownerRecs = cmp.get("v.ownerRecs");
        let userInput = e.getSource().get('v.value');
        ownerRecs[ownerRecIndex].percentOfOwner = userInput;
        cmp.set("v.ownerRecs",ownerRecs);
        helper.calcPercentOwnership(cmp, e, helper);
        helper.sendOwnerAutoSave(cmp, e, helper);
    },
    
    removeRow : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.target.name);
        let ownerRecs = cmp.get("v.ownerRecs");
        ownerRecs.splice(ownerRecIndex, 1);
        cmp.set("v.ownerRecs",ownerRecs);
        helper.calcPercentOwnership(cmp, e, helper);
        helper.sendOwnerAutoSave(cmp, e, helper);
    },
    
    addNewOwner : function(cmp, e, helper) {
        let ownerRecs = cmp.get("v.ownerRecs");
        let ownerDetails = {nameOfOwner:"", percentOfOwner:""};
        ownerRecs.push(Object.assign({},ownerDetails));
        cmp.set("v.ownerRecs",ownerRecs);
    },
    
    save: function(cmp, e, helper) {
        var params = e.getParam('arguments');
        let finValidation = helper.finFieldValidation(cmp, e, helper);
        if(!finValidation){
            cmp.set('v.selectedTab','About Your Business');
            cmp.set("v.errorText", "Please enter a valid Federal Identification Number.");
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: 'Error',
                message: 'Please enter valid data and provide value for required fields',
                type: 'error'
            });
            toastEvent.fire(); 
        }else{
            helper.save(cmp, e, helper, params.buttonClicked, params.skipValidate);
        }
    },
    setLabel: function(cmp, e, helper) {
        //cmp.set('v.init', false);
        console.log('setLabel');
        cmp.set('v.activeLabel', cmp.get('v.selectedTab'));
        //cmp.set('v.init', true);
    },
    
    naicsChange: function(cmp, e, helper) {
        //debugger;
        try {
            //let field = e.getSource();
            let fieldName = 'NAICS_Code__c';
            let fieldValue = cmp.get('v.currentAccount.NAICS_Code__c');
            let objectAPIName = 'Account';
            //let Account = cmp.get('v.parentAccount');
            let Account = cmp.get('v.currentAccount');
            console.log('CommAccEdit sendAutoSave fieldValue:'+fieldValue+' fieldName:'+fieldName);
            console.log('CommAccEdit sendAutoSave objectAPIName:'+objectAPIName);
            if ((fieldValue && fieldValue.length == 6) || fieldValue == '') {
                let recordId = Account.Id;
                let autoSaveEvt = cmp.getEvent('autoSave');
                autoSaveEvt.setParam('objectName', objectAPIName);
                autoSaveEvt.setParam('accountId', Account.Id);
                autoSaveEvt.setParam('fieldName', fieldName);
                autoSaveEvt.setParam('fieldValue', fieldValue);
                autoSaveEvt.setParam('recordId', recordId);
                autoSaveEvt.setParam('accountName', Account.Name);
                autoSaveEvt.fire();
                helper.addTabNumbers(cmp, e, helper);
            }
            if(fieldValue == ''){
                console.log('naicsChange: Set Naics descr to blank');
                cmp.set('v.currentAccount.NAICS_Description__c','');
            }
        } catch(e) {
            console.error('Error sendAutoSave');
            console.error(e);
        }
    },
    
    updateBenchMarkPos: function(cmp, e, helper) {
        //update the tab pos for benchmark
        console.log('updateBenchMarkPos');
        if(cmp.get('v.benchMarkPos') == 'BenchMarkAvgWages'){
            cmp.set('v.selectedTab',cmp.get('v.benchMarkPos'));
        }
    },
    
    updateNaicsDescr: function(cmp, e, helper) {
        try {
            let fieldName = 'NAICS_Description__c';
            let fieldValue = cmp.get('v.currentAccount.NAICS_Description__c');
            let objectAPIName = 'Account';
            let Account = cmp.get('v.currentAccount');
            if ((fieldValue && fieldValue.length)|| fieldValue == '') {
                console.log('updateNaicsDescr: Trigger NaicsDescr autosave');
                let recordId = Account.Id;
                let autoSaveEvt = cmp.getEvent('autoSave');
                autoSaveEvt.setParam('objectName', objectAPIName);
                autoSaveEvt.setParam('accountId', Account.Id);
                autoSaveEvt.setParam('fieldName', fieldName);
                autoSaveEvt.setParam('fieldValue', fieldValue);
                autoSaveEvt.setParam('recordId', recordId);
                autoSaveEvt.setParam('accountName', Account.Name);
                autoSaveEvt.fire();
            }
        } catch(e) {
            console.error('Error sendAutoSave');
            console.error(e);
        }
    },
})