({
    doInit : function(component, event, helper) {
        helper.updateComponent(component, event, helper);
        //EVENT SUBSCRIPTION
       // console.log('Setting Current Id');
       // var currentUserId =  $A.get("$SObjectType.CurrentUser.Id");
      //  onsole.log('Current Id is='+currentUserId);
     //   cmp.set("v.currentUserId", currentUserId);
        helper.subscribe(component, event, helper);
    },
    navigateToParent : function(component, event, helper) {
        helper.openParentRecord(component, event, helper);
    },
     displayRepeatScreen : function(component, event, helper) {
         component.set("v.displayScreen", 'displayRepeat');
    },
    displaySkipScreen : function(component, event, helper) {   
        component.set("v.displayScreen", 'displaySkipScreen');
    },
    displayCreateActivityScreen : function(component, event, helper) {  
        //select multiple refctcts 
        helper.setRefCtctEmailList(component,helper);
        component.set('v.refCtctEmailColumns', [
            { label: 'Name', fieldName: 'Name', type: 'text'},
            { label: 'Title', fieldName: 'Title', type: 'text'},
            { label: 'Email', fieldName: 'Email__c', type: 'email'}
           
        ]);
        // select 1 refctct 

        helper.setCreateActivityList(component,helper);
        helper.setCANamesList(component,helper);

        component.set("v.isCreateActivityOpen", true);

    },
    //Sets Component variable to the selected Referral Contact
    updateCAContact: function(component,event,helper){
        var selectedOptionValue = event.getParam("value");
        component.set("v.selectedCARefctctId",selectedOptionValue);
        console.log("selected a new Create Activity Referral Contact");
        var info = component.get("v.selectedCARefctctId");
        console.log("This is the selected Referral Contact's Id: "+ info);


        //component.set('v.')
    },
    displayCreateActivity : function(component, event, helper){
        component.set("v.showCreateActivity",true);
        //helper.getRefctctName(component,helper);
    },
    displayLogScreen : function(component, event, helper) {
        component.set("v.displayScreen", 'displayLogScreen');
        var isReferral = component.get("v.cadenceTouchpoint.CarRecord__r.IsReferralSource__c");
        //console.log("IsReferral : "+isReferral);
        //APR0159917--Start
        var cadenceId=component.get("v.cadenceTouchpoint.Cadence__c");//Outcome_Required__c
        var stepNumber=component.get("v.cadenceTouchpoint.Step_Number__c");
        console.log("IsReferral : "+isReferral)
        console.log("cadenceId : "+cadenceId+" stepNumber"+stepNumber);
        if(cadenceId!=null){
            console.log("Calling cadenceSteps");
            helper.cadenceSteps(component,helper,cadenceId,stepNumber);
        }
        //APR0159917--End
        if(isReferral){
            console.log('This should not show for Contact');
            component.set("v.showSelectContacts", true);
        }else{
            component.set("v.showSelectContacts", false);

        }
        component.set('v.refCtctEmailColumns', [
            { label: 'Name', fieldName: 'Name', type: 'text'},
            { label: 'Email', fieldName: 'Email__c', type: 'email'},
            { label: 'Phone', fieldName: 'Phone__c', type: 'phone'},
            { label: 'Mobile', fieldName: 'Mobile_Phone__c', type: 'phone'},
            { label: 'Title', fieldName: 'Title', type: 'text'}
            
            
           
        ]);
        helper.setRefCtctSelect(component,helper);

    },
    displayLogScreen2 : function(component,event,helper){
        component.set("v.showSelectContacts", false);
        var isReferral = component.get("v.cadenceTouchpoint.CarRecord__r.IsReferralSource__c");
        //APR0159917--Start
        var cadenceId=component.get("v.cadenceTouchpoint.Cadence__c");//Outcome_Required__c
        var stepNumber=component.get("v.cadenceTouchpoint.Step_Number__c");
        console.log("IsReferral : "+isReferral)
        console.log("cadenceId : "+cadenceId+" stepNumber"+stepNumber);
        if(cadenceId!=null){
            console.log("Calling cadenceSteps");
            helper.cadenceSteps(component,helper,cadenceId,stepNumber);
        }
        //APR0159917--End
    },
    displayRemoveScreen : function(component, event, helper) {
        component.set("v.displayScreen", 'displayRemoveFromCad');
    },
    displayEmail : function(component, event, helper) {
        var touchpoint = component.get("v.cadenceTouchpoint");
        component.set("v.emailRecipient", touchpoint.CarRecord__r.SignificantContactEmail__c);
        component.set("v.displayScreen", 'displayEmail');
        helper.setRefCtctEmailList(component);
        component.set('v.refCtctEmailColumns', [
            { label: 'Name', fieldName: 'Name', type: 'text'},
            { label: 'Title', fieldName: 'Title', type: 'text'},
            { label: 'Email', fieldName: 'Email__c', type: 'email'}
           
        ]);
        helper.getEmailContactIds(component,helper);


        //component.set("v.emailList",emailList)
    },
    displayContactScreen : function(component, event, helper) {
        //var actions = [
        //    { label: 'Make Significant', name: 'make_significant'}
        //];
        component.set('v.ctctTableColumns', [
            { label: 'Name', fieldName: 'Name', type: 'text'},
            { label: 'Title', fieldName: 'Title', type: 'text'},
            { label: 'Email', fieldName: 'Email', type: 'email'},
            { label: 'Do Not Email', fieldName: 'HasOptedOutOfEmail', type: 'boolean', cellAttributes: { alignment: 'center' }},
            { label: 'Email Bounced Reason', fieldName: 'EmailBouncedReason', type: 'text'},
            { label: 'Phone', fieldName: 'Phone', type: 'phone'},
            { label: 'Text Eligible', fieldName: 'TextEligible__c', type: 'boolean', cellAttributes: { alignment: 'center' }}
        ]);
        var touchpoint = component.get("v.cadenceTouchpoint");
        component.set("v.queryContactsOnly", true);
        helper.setInsightList(component, helper);
        component.set("v.displayScreen", 'displayContact');
    },
    displayInsightScreen : function(component, event, helper) {
        component.set("v.queryContactsOnly", false);
        helper.setInsightList(component, helper);
        component.set("v.displayScreen", 'displayInsights');
    },
    /*
    handleSuccess : function(component, event, helper) {
        var payload = event.getParams().response;
        //alert("payload="+JSON.stringify(payload));
        //alert("recId="+recId);
        var payloadStr = JSON.stringify(payload);
        var idPos = payloadStr.indexOf('"id":"');
        var idStr = payloadStr.substr(idPos+6,18);
        alert('idPos='+idPos+' lastPos='+lastPos+' idStr='+idStr);
        component.set("v.createMode", false);
        component.set('v.showSpinner', false);
    },
    */
    handleContactSuccess : function(component, event, helper) {
        var message="Contact Created";
        var record = event.getParam("response");
        var payload = event.getParams().response;
        //alert("payload="+JSON.stringify(payload));
        //alert("recId="+recId);
        var payloadStr = JSON.stringify(payload);
        var idPos = payloadStr.indexOf('"id":"');
        var idStr = payloadStr.substr(idPos+6,18);
        //alert('idPos='+idPos+' lastPos='+lastPos+' idStr='+idStr);

        var updateSigContact = component.get("v.updateSig");
        if (updateSigContact == true) {
            helper.updateRecToSignificant(component, event, idStr);
        }
        helper.displayToast('success','Confirmation!', message);
        component.set("v.createMode", false);
        component.set('v.showSpinner', false);
        helper.refreshTouchpoints(component, true, false);
    },
    handleContactSubmit: function(component, event, helper) {
        component.set('v.disabled', true);
        component.set('v.showSpinner', true);
    },
    cancelCreateScreen : function(component, event) {
        component.set("v.createMode", false);
    },
    displayCreateScreen : function(component, event) {
        component.set("v.createMode", true);
    },
    handleRefreshContact: function(component, event, helper) {
        helper.refreshContact(component,event,helper);
    },
    handleRefreshLead: function(component, event, helper) {
        helper.refreshLead(component,event,helper);
    },
    handleCtctRowAction: function(component, event, helper) {
        var action = event.getParam('action');
       var row = event.getParam('row');
       switch (action.name) {
          case 'make_significant':
             helper.updateSignificant(component, helper, row);
             break;
       }
    },
    updateContactSource : function(component, event, helper) {
        var makeSignificateValue = component.get("v.updateSig");
        component.set("v.contactSource", makeSignificateValue ? 'Cadence - Significant' : 'Cadence');
    },
    processOwnershipChange : function(component, event, helper) {
        helper.setTouchpointOwner(component, helper);
    },
    processOwnershipChangeAll : function(component, event, helper) {
        helper.setCadenceOwner(component, helper);
    },
    /*
    processFollowUp : function(component, event, helper) {
        helper.updateDueDate(component, helper);
    },
    */
    processCadRemoval : function(component, event, helper) {
        helper.cadenceRemoval(component, helper);
    },
    processSubmitReferral: function(component, event, helper) {
        helper.handleSubmitReferral(component, event, helper);
    },
    processCreateOpp : function(component, event, helper) {
        helper.createOpportunity(component, event, helper);       
    },
    processTouchpointSkip : function(component, event, helper) {
        helper.skipTouchpoint(component, helper);
    },
    processEmailRequest: function(component, event, helper) {
        helper.processEmail(component, helper);
    },
    processCancelRequest : function(component, event, helper) {
        component.set("v.displayScreen", 'displayDetails');
        component.set("v.selectedLabel", "Touchpoint");
        component.set("v.logStepValue","Complete Step");
        component.set("v.followUpDate",null);
        component.set("v.TouchpointUpdateNote",null);
    },
    updateRefCtctOptions : function(component,event,helper){
        helper.setRefCtctEmailList(component,helper);
    },
    handleEmailList: function(component,event,helper){
            // This will contain an array of the "value" attribute of the selected options
            var selectedOptionValue = event.getParam('selectedRows');
            console.log("Selected Contact Value before Set: "+JSON.stringify(selectedOptionValue));
            selectedOptionValue.forEach((refctct)=>{
                console.log(refctct.Contact__c);
                refctct = JSON.parse(JSON.stringify(refctct));
                console.log(refctct);
                return refctct.Contact__c;
            });
            console.log(selectedOptionValue);
            component.set("v.selectedRefctctEmails", selectedOptionValue);

            console.log("Selected Contact Value after Set: "+JSON.stringify(selectedOptionValue));
            var test = component.get("v.selectedRefctctEmails");
            console.log("What is in the component: "+JSON.stringify(test));
            helper.getEmailContactIds(component,helper);
            component.set("v.mirrorContactSelected",true);

            // var test2 = component.get("v.selectedMirrorContactIds");
            // console.log("the IDs: "+JSON.stringify(test2));
            
    },
    handleRefCtctSelect: function(component,event,helper){
        var selectedOptionValue = event.getParam('selectedRows');
        console.log("Selected Contact Value before Set: "+JSON.stringify(selectedOptionValue));
        selectedOptionValue.forEach((refctct)=>{
            console.log(refctct.Contact__c);
            refctct = JSON.parse(JSON.stringify(refctct));
            console.log(refctct);
            return refctct.Name;
        });
        console.log(selectedOptionValue);
        component.set("v.selectedRefctctNamesList", selectedOptionValue);

        console.log("Selected Contact Value after Set: "+JSON.stringify(selectedOptionValue));
        var test = component.get("v.selectedRefctctNamesList");
        console.log("What is in the component: "+JSON.stringify(test));
        helper.getReferralContactNames(component,helper);
        
        // helper.getEmailContactIds(component,helper);
        // var test2 = component.get("v.selectedMirrorContactIds");
        // console.log("the IDs: "+JSON.stringify(test2));
        
    },

    /*
    processTouchpointRequest: function(component, event, helper) {
        helper.processRequest(component, helper);
        component.set("v.displayScreen", "displayDetails");
    },
    */
    processContactUpdate : function(component, event, helper) {     
        helper.updateContact(component, helper);
    },
    processMakeMainRecSig : function(component, event, helper) {
        helper.handleMakeMainRecSig(component, helper);
    },
    processSaveNotes : function (component, event, helper){
        helper.updateCarNotes(component, helper);
        /*var a = component.get('c.doInit');
        $A.enqueueAction(a);*/
        //helper.updateComponent(component, event, helper);
        //component.set("v.displayScreen", 'displayDetails');
    }, 
    handleUploadFinished: function (component, event) {
        // This will contain the List of File uploaded data and status
        var uploadedFiles = event.getParam("files");
        alert("Files uploaded : " + uploadedFiles.length);
    },
    handleEmailPreview: function(component, event, helper) {
        helper.emailPreview(component,helper);
    },
    closeEmailPreview: function(component, event, helper) {
      // Set isEmailPreviewOpen attribute to false  
      component.set("v.isEmailPreviewOpen", false);
   },
   closeCreateActivityScreen: function(component,event,helper){
       //set isCreateActivityOpen attribute to false 
       component.set("v.isCreateActivityOpen",false);
       component.set("v.showCreateActivity",false);

   },
   closeCreateActivity: function(component,event,helper){
       component.set("v.showCreateActivity",false);
   },
   processLogStep: function(component, event, helper) {
      component.set("v.disableButton", true);
      helper.setCANamesList(component,helper);
      helper.completeLogStep(component, event, helper);
   },
   refreshRecord: function(component, event, helper) {
     helper.refreshTouchpoints(component, true, false);
   },

})