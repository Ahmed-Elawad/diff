({
    setupFields: function(cmp, e, helper) {
        cmp.set('v.saveFunc' , $A.getCallback(() => helper.saveForm(cmp, e, helper)));
        
        var submissionStatus = cmp.get('v.PEOChecklist.Peo_WC_formStatus__c');
        console.log('WC PEOChecklist:');
        console.log(cmp.get('v.PEOChecklist'));
        console.log('WC Submission status:'+submissionStatus);
        if(submissionStatus === 'Complete'){
            cmp.set('v.formSubmitted', true);
        }
        
        console.log(cmp.get('v.PEOChecklist'));
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
            else cmp.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.')
        } 
        helper.getFieldInfoForAcc(cmp, e);
        helper.prepareAddressRecData(cmp, e);
        helper.prepareShiftRecData(cmp, e);
    },
    changeSubFieldView: function(cmp, evt, helper) {
        try {
            if (!cmp.get('v.answersChanged')) cmp.set('v.answersChanged', true);
            let field = evt.getSource();
            let fieldName = field.get('v.name');
            let fieldValue = field.get('v.value');
            let fieldType = field.get("v.type");
            if(fieldName=='number_of_volunteers__c' && fieldValue.length>9){
                cmp.set('v.PEOChecklist.number_of_volunteers__c',fieldValue.substring(0,9));
            }
            if(fieldName=='number_of_seasonal_wrkrs__c' && fieldValue.length>9){
                cmp.set('v.PEOChecklist.number_of_seasonal_wrkrs__c',fieldValue.substring(0,9));
            }
            if(fieldName=='Maximum_height_applicants_work_from__c' && fieldValue.length>9){
                cmp.set('v.PEOChecklist.Maximum_height_applicants_work_from__c',fieldValue.substring(0,9));
            }
            if(fieldName=='How_many_subcontractors__c' && fieldValue.length>9){
                cmp.set('v.PEOChecklist.How_many_subcontractors__c',fieldValue.substring(0,9));
            }
            
            helper.updateChildView(cmp, evt, helper);
            //helper.sendAutoSaveEvent(cmp, evt, helper);
            //Providing delay for text fields
            if(fieldType != undefined && fieldType == 'text'){
                console.log('changeSubFieldView fieldType text');
                var timer = cmp.get('v.timeoutId');
                clearTimeout(timer);
                
                var timer = setTimeout(
                    $A.getCallback(function() {
                        try {
                            helper.sendAutoSaveEvent(cmp, evt, helper);
                            cmp.set('v.timeoutId', null);
                        }catch(err) {
                            console.log(`Err PEOUWWorkersCompQuestionnaireController.sendAutoSaveEvent: ${err}`);
                        }
                    }), 300);
                cmp.set('v.timeoutId', timer);
            }
            else{
                console.log('handleChange no delay for save send');
                helper.sendAutoSaveEvent(cmp, evt, helper);
            }
        }catch(err) {
            console.log(`Err PEOUWWorkersCompQuestionnaireController.changeSubFieldView: ${err}`);            
        }
    },
    saveForm: function(component, event, helper) {
        helper.saveForm(component, event, helper);
    },
    openTab: function(cmp, e, helper) {
        console.log('in controller')
        helper.triggerEvt(cmp, e);
    },
    
    handleAddressChange : function(cmp, e, helper) {
        let addressRecIndex = parseInt(e.getSource().get('v.name'));
        console.log('addressRecIndex'+addressRecIndex);
        let addressRecs = cmp.get("v.addressRecs");
        console.log('addressRecs'+addressRecs);
        let userInput = e.getSource().get('v.value');
        console.log('addressRecs'+addressRecs);
        addressRecs[addressRecIndex].address = userInput;
        cmp.set("v.userInput",userInput);
        helper.sendAddressAutoSave(cmp, e, helper);
    },
    
    handleManagerChange : function(cmp, e, helper) {
        let managerRecIndex = parseInt(e.getSource().get('v.name'));
        let multiShiftRecs = cmp.get("v.multiShiftRecs");
        let userInput = e.getSource().get('v.value');
        multiShiftRecs[managerRecIndex].manager = userInput;
        cmp.set("v.userInput",userInput);
        helper.sendManagerInfoAutoSave(cmp, e, helper);
    },
    
    handleCountChange : function(cmp, e, helper) {
        let addressRecIndex = parseInt(e.getSource().get('v.name'));
        let addressRecs = cmp.get("v.addressRecs");
        let userInput = e.getSource().get('v.value');
        addressRecs[addressRecIndex].numberOfemployees = userInput;
        cmp.set("v.addressRecs",addressRecs);
        helper.sendAddressAutoSave(cmp, e, helper);
    },
    
    handleShiftCountChange : function(cmp, e, helper) {
        let multiShiftRecIndex = parseInt(e.getSource().get('v.name'));
        console.log('multiShiftRecIndex'+multiShiftRecIndex);
        let multiShiftRecs = cmp.get("v.multiShiftRecs");
        console.log('multiShiftRecs'+multiShiftRecs);
        let userInput = e.getSource().get('v.value');
        multiShiftRecs[multiShiftRecIndex].numberOfemployees = userInput;
        cmp.set("v.userInput",userInput);
        helper.sendShiftCountAutoSave(cmp, e, helper);
    },
    
    removeRow : function(cmp, e, helper) {
        let addressRecIndex = parseInt(e.target.name);
        let addressRecs = cmp.get("v.addressRecs");
        addressRecs.splice(addressRecIndex, 1);
        cmp.set("v.addressRecs",addressRecs);
        helper.sendAddressAutoSave(cmp, e, helper);
    },
    
    removeShiftRow : function(cmp, e, helper) {
        let multiShiftRecIndex = parseInt(e.target.name);
        let multiShiftRecs = cmp.get("v.multiShiftRecs");
        multiShiftRecs.splice(multiShiftRecIndex, 1);
        cmp.set("v.multiShiftRecs",multiShiftRecs);
        helper.sendManagerInfoAutoSave(cmp, e, helper);
    },
    
    addNewLocInfo : function(cmp, e, helper) {
        let addressRecs = cmp.get("v.addressRecs");
        let addDetails = {address:"", numberOfemployees:""};
        addressRecs.push(Object.assign({},addDetails));
        cmp.set("v.addressRecs",addressRecs);
    },
    
    addNewShiftInfo : function(cmp, e, helper) {
        let multiShiftRecs = cmp.get("v.multiShiftRecs");
        let addDetails = {numberOfemployees:"", manager:""};
        multiShiftRecs.push(Object.assign({},addDetails));
        cmp.set("v.multiShiftRecs",multiShiftRecs);
    },
})