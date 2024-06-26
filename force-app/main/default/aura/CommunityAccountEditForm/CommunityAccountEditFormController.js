({
    clearout : function(cmp, e, helper){
        var evtId = e.getSource().getLocalId();
        if(evtId==='isDental'){
            if(cmp.get("v.viewPEOChecklist.Has_current_dental_carrier__c")=='No'){ 
                cmp.set("v.viewPEOChecklist.Interested_in_dental__c",'');
                cmp.set("v.viewPEOChecklist.Who_is_your_Current_Dental_Carrier__c",'');
            }
        }
        else if(evtId==='isVision'){
            if(cmp.get("v.viewPEOChecklist.has_current_Vision_Carrier__c")=='No'){
                cmp.set("v.viewPEOChecklist.interested_in_Vision__c",'');
                cmp.set("v.viewPEOChecklist.Who_is_your_Current_Vision_Carrier__c",'');
            }
        }
            else if(evtId==='isMedical'){
                if(cmp.get("v.viewPEOChecklist.Current_Medical_Coverage_Provided__c")=='No')
                    cmp.set("v.viewPEOChecklist.Number_of_Enrolled_Employees__c",'');
            }
        
        let field = e.getSource();
        helper.runAutoSave(cmp, e, helper, field); 
    },
    handleChange: function(cmp, e, helper) {
        // should update the object storing the reference values to contain the vlaue from the current field
        // set the boolean to indicate a change occuered to true
        
        let field = e.getSource();
        let fields = cmp.find('editFormField');
        if (!cmp.get('v.valChange')) cmp.set('v.valChange', true);
        
        var frequencyList = cmp.get('v.frequencyValues');
        if(frequencyList){
            frequencyList = frequencyList.sort().join('; ');
            cmp.set('v.viewPEOChecklist.Payroll_Frequency__c',frequencyList);
        }
        else{
            cmp.set('v.viewPEOChecklist.Payroll_Frequency__c','');
        }
        
        helper.validateFields(cmp, e, fields);
        
        if(field.get("v.type") == 'Date' || field.get("v.type") == 'date') {
            field.setCustomValidity('') ;
            let chckvalididty = field.get("v.validity");
            
            if(!chckvalididty.valid) field.setCustomValidity('format must be mm/dd/yyyy');
            else field.setCustomValidity('');
            
            field.reportValidity();
        }
        helper.runAutoSave(cmp, e, helper, field); 
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
        if(!cmp.get("v.communityUser") && (curUser.Sales_Org__c == 'PAS' || curUser.Sales_Org__c == 'PEO' || curUser.Profile.Name.includes('System Admin'))) {
            cmp.set('v.stateRequired', true);
        }
        
        let isCommUser = cmp.get('v.communityUser');
        let msg;
        if (isCommUser) msg = 'We’re sorry, your request can’t be completed right now. Please try again. For support, visit the Need Help section on our homepage, so we can promptly address the issue.';
        else msg = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.';
        cmp.set('v.errorMsg', msg);
        
        helper.fetchPickListVal(cmp);
        var tabs = ['Basic Information', 'About Your Business'];
        let checklist = cmp.get("v.PEOChecklist");
        if (cmp.get('v.firstStep') == 0) {
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

        if(checklist.Medical_Pre_Qualifier_Status__c=='Approved' && (checklist.Health_Insurance_Summary_required__c || checklist.Health_Invoice_required__c ||checklist.Claims_Report_required__c || checklist.Health_Insurance_Renewal_required__c)){
            tabs.push('Upload');
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
        cmp.set('v.EntityTypeOptions',options);
        cmp.set('v.initialNaicsCode',cmp.get('v.currentAccount.NAICS_Code__c'));
        helper.setParentTablistForButtons(cmp, e, helper);
        helper.addTabNumbers(cmp, e, helper);
        ////Initial methods start
        /*helper.fetchPickListVal2(cmp, cmp.get("v.picklistFieldsMap"))
        .then(res => helper.initializationChecks(cmp, e, helper))
        .catch(err => helper.showUserMsg(cmp, err)); */
        //////Initial set of methods: end
        
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
        helper.save(cmp, e, helper);
    },
    setLabel: function(cmp, e, helper) {
        cmp.set('v.activeLabel', cmp.get('v.selectedTab'));
    }
})