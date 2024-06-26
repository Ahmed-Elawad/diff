({
    doInit : function(component, event, helper) {
        
    },
    changeContactEmail : function(component, event, helper) {
        
        var myList = component.get('v.ContactList');
        var recordedId = component.find("contactIdSelect").get("v.value");
        /*component.set("v.contactId", undefined);
        component.set("v.email", undefined);*/
        component.set("v.contactId", null);
        component.set("v.email", null);
        component.set("v.phone", null);
        component.set("v.phoneVerified", false);
        component.set("v.emailVerified", false);
        component.set("v.contactSelected", false);
        for (var i=0; i < myList.length; i++) {
            if(myList[i].Id == recordedId){
                component.set("v.contactId", myList[i].Id);
                component.set("v.email", myList[i].Email);
                component.set("v.phone", myList[i].MobilePhone);
                component.set("v.accountId", myList[i].AccountId);
                component.set("v.contactSelected", true);
            }
        }


        
       /* var action = component.get('c.getPrimaryQuote');
        console.log('component.get("v.recId")',component.get("v.recId"));
        action.setParams(
            {
                "recordId":component.get("v.recId")
            })
        action.setCallback(this, function(response){           
            var name = response.getState();
            if (name === "SUCCESS") {
                component.set("v.containsFile", response.getReturnValue());
                if(response.getReturnValue() == false){
                    component.set("v.buttonDisabled", true);
                }
                console.log(response.getReturnValue());
            }
        });
        $A.enqueueAction(action);*/
    },

    handleChange: function (component, event) {
        var changeValue = event.getParam("value");
        component.set("v.quoteOption", changeValue);
        component.set("v.quoteName", null);
        component.set("v.certificateName", null);
        component.set("v.quoteId", null);
        component.set("v.certificateId", null);
        component.set("v.matchingAttachments", false);
    },
    updateQuoteId: function (component, event,helper) {
        var quoteId = event.getSource().get("v.value");
        
        component.set("v.quoteId", quoteId);
        if(quoteId.startsWith("069")){
            var action = component.get('c.retrieveFile');
            action.setParams(
                {
                    "fileId":quoteId
                })            
            action.setCallback(this, function(response){           
                var name = response.getState();
                var retrievedFile = response.getReturnValue();
                if (name === "SUCCESS") {
                    
                    component.set("v.file", retrievedFile);
                    var objFileReader = new FileReader();
                    objFileReader.onload = $A.getCallback(function() {
                        var fileContents = objFileReader.result;
                        var base64 = 'base64,';
                        var dataStart = fileContents.indexOf(base64) + base64.length;
                        alert(dataStart);
                        component.set("v.dataStart", dataStart);
                        component.set("v.base64", base64);
                        component.set("v.fileContents", fileContents.substring(dataStart));
                        fileContents = fileContents.substring(dataStart);
                    });
                    
                    objFileReader.readAsDataURL(retrievedFile);
                }
                /*component.set("v.loadSpinner", false);
                component.set("v.displayNext", true);*/
            });
            $A.enqueueAction(action);
            helper.uploadCertProcess(component, event);
        }
        /*var action = component.get('c.updateUploadedAttId');
        action.setParams(
            {
                "tracker":component.get("v.csoTrackingRec"),
                "attType":"quote",
                "attId":quoteId
            })
        $A.enqueueAction(action);  
        component.set("v.quoteId", quoteId);
        helper.validateForm(component, helper);*/
    },
    updateCertId: function (component, event,helper) {
        var certId = event.getSource().get("v.value");
        var action = component.get('c.updateUploadedAttId');
        action.setParams(
            {
                "tracker":component.get("v.csoTrackingRec"),
                "attType":"certificate",
                "attId":certId
            })
        
        $A.enqueueAction(action);
        component.set("v.certificateId", certId);
        helper.validateForm(component, helper);
    },
    updateContactEmail : function(component, event, helper) {
        var conEmail = component.get("v.email");
        var conPhone = component.get("v.phone");

        if((conEmail == null || conEmail == '') || (conPhone == null || conPhone == '')){
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({ 
                'title' : 'Please update contact with a valid Email and Mobile Phone', 
                'type' : 'warning',
                'message' : 'test'
            });
            
            showToast.fire();
        }else{
            component.set("v.loadSpinner", true);
            var action = component.get('c.updateContact');
            action.setParams(
                {
                    "recordId":component.get("v.contactId"),
                    "email":component.get("v.email"),
                    "mobile":component.get("v.phone")
                })
            action.setCallback(this, function(response){           
                var name = response.getState();
                component.set("v.loadSpinner", false);
                component.set("v.displayNext", true);
                /*if (name === "SUCCESS") {
                //component.set("v.showContact", false);
                //component.set("v.ContactList", response.getReturnValue());
                console.log(response.getReturnValue());
                var a = component.get('c.getOpportunityData');
                $A.enqueueAction(a);
            }*/
        });
            $A.enqueueAction(action);
        }
    },
    getOpportunityData : function(component, event, helper) {
        /*console.log('Fetch Opp Data');
        var action = component.get('c.getOpportunity');
        action.setParams(
            {
                "recordId":component.get("v.recId")
            })
        action.setCallback(this, function(response){           
            var name = response.getState();
            if (name === "SUCCESS") {
                
                component.set("v.showContact", false);
                component.set("v.opportunityObj", response.getReturnValue());
                console.log('Opp->',response.getReturnValue());
            }
        });*/
        component.set("v.showContact", false);
        console.log('Here');
        console.log('component.get("v.accountId")',component.get("v.accountId"));
        var action2 = component.get('c.getAccountData');
        action2.setParams(
            {
                "recordId":component.get("v.accountId")
            })
        action2.setCallback(this, function(response){      
            console.log('response'+response);
            var name = response.getState();
            component.set("v.loadSpinner",false);
            if (name === "SUCCESS") {
                var accObj = response.getReturnValue();
                var address = (accObj.ShippingStreet!=undefined?accObj.ShippingStreet:'') + ' '+(accObj.ShippingCity!=undefined?accObj.ShippingCity:'') + ' ' +  (accObj.ShippingState!=undefined?accObj.ShippingState:'') + ' ' + (accObj.ShippingPostalCode!=undefined?accObj.ShippingPostalCode:'') + ' ' +  (accObj.ShippingCountry!=undefined?accObj.ShippingPostalCode:'');
                if(accObj.LegalAddress__Street__s!=null && accObj.LegalAddress__City__s!=null && accObj.LegalAddress__StateCode__s!=null && accObj.LegalAddress__PostalCode__s!=null){
                    var legalAddress = accObj.LegalAddress__Street__s + ', '+accObj.LegalAddress__City__s + ', ' +  accObj.LegalAddress__StateCode__s + ', ' + accObj.LegalAddress__PostalCode__s;
                    component.set("v.legalAddressConcat", legalAddress);
                    component.set("v.hasLegalAddress", true);
                }else{
                    component.set("v.hasLegalAddress", false);
                }
                
                console.log("response.getReturnValue()",response.getReturnValue());
                component.set("v.shippingAddress", address);
                component.set("v.AccountObj", response.getReturnValue());
            }
        });
        //$A.enqueueAction(action);
        $A.enqueueAction(action2);
        //component.set("v.loadSpinner", false);
    },
    removeQuote : function(component, event, helper)  {
        component.set("v.quoteName", null);
    },
    removeCert : function(component, event, helper)  {
        component.set("v.certificateName", null);
        
    },
    handleFilesChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        } 
        component.set("v.quoteName", fileName);
        helper.uploadHelper(component, event);
    },
    handleCertChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        } 
        component.set("v.certificateName", fileName);
        helper.uploadCertHelper(component, event);
    },
    saveAttachmentFiles: function(component, event, helper) {
        helper.uploadProcess(component, event);
        //helper.uploadCertProcess(component, event);
    },
    handleQuoteUploadFinished : function(component, event, helper) {
        var quoteFileList = event.getParam("files");
        var quoteFile = quoteFileList[0];
        //var action = component.get('c.updateUploadedAttId');
        var objFileReader = new FileReader();
        
        objFileReader.onload = function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
            var fileContentSubstring = fileContents.substring(dataStart);

            helper.uploadProcess(component, quoteFile,fileContentSubstring);
        }

        objFileReader.readAsDataURL(quoteFile); 
        /*quoteFile.forEach(file => {
            component.set("v.quoteId", file.documentId);
            component.set("v.quoteUploadName", file.name);
            oneFile = file;
        });
            action.setParams({
            "tracker":component.get("v.csoTrackingRec"),
            "attType":"quote",
            "attId":component.get("v.quoteId")
        })
        $A.enqueueAction(action);
        */
    },   
    handleCertUploadFinished : function(component, event, helper)  {
        var certFile = event.getParam("files");
        var action = component.get('c.updateUploadedAttId');
        certFile.forEach(file => {
            component.set("v.certificateId", file.documentId);
            component.set("v.certUploadName", file.name);
        
        });
            action.setParams({
            "tracker":component.get("v.csoTrackingRec"),
            "attType":"certificate",
            "attId":component.get("v.certificateId")
        })

        $A.enqueueAction(action);
        helper.validateForm(component, helper);
    },
    saveLegalAddress : function(component, event, helper) {
        //component.set("v.hasLegalAddress", true);
    },
    updateNextButton : function(component, event, helper) {
        component.set("v.displayNext", false);
    },
    updateAddressDisplay : function(component, event, helper) {
        var action = component.get('c.getOpportunityData');
        action.setCallback(this, function(response){           
            var name = response.getState();
            if (name === "SUCCESS") {
                $A.enqueueAction(a); 
                component.set("v.legalIsShip", false);
                component.set("v.hasLegalAddress", true);
                component.set("v.loadSpinner", false);
            }
        });
        $A.enqueueAction(action); 
    },
    updateLegal : function(component, event, helper) {
        component.set("v.hasLegalAddress", false);
    },
    updateFedId : function(component, event, helper) {
        component.set("v.loadSpinner", true);
        var fedIdValue = component.find("fedId").get("v.value");
        if(fedIdValue!=null){
            var action = component.get('c.updateAccount');
            
            action.setParams(
                {
                    "recordId":component.get("v.accountId"),
                    "fedId":fedIdValue
                })
            action.setCallback(this, function(response){           
                component.set("v.loadSpinner", false);
                console.log('response->'+response);
               var res = response.getReturnValue();
               if (res.statusCode != 200) {
                    var showToast = $A.get("e.force:showToast");
                    showToast.setParams({ 
                        'mode' : 'sticky',
                        'title' : 'Confirmation', 
                        'type' : 'error',
                        'message' : 'An unexpected error has occurred.\n Details: '+res.message
                    });
                   showToast.fire();
 
               }
            });
            $A.enqueueAction(action);
        }
        //helper.checkValidationFields(component, event, helper);
    },
    updateLegalAddress : function(component, event, helper) {
        //component.set("v.loadSpinner", true);
       var setLegalToShippingAddress = component.get("v.legalIsShip"); 
        var shipStreet = component.get("v.AccountObj.ShippingStreet");
        var shipCity = component.get("v.AccountObj.ShippingCity"); 
        var shipState = component.get("v.AccountObj.ShippingState"); 
        var shipStateUpper = shipState.toUpperCase();
        var shipZip = component.get("v.AccountObj.ShippingPostalCode"); 
        //var a = component.get('c.getOpportunityData');
 
        if(setLegalToShippingAddress){
            component.find("legalStreet").set("v.value", shipStreet);
            component.find("legalCity").set("v.value", shipCity);
            component.find("legalState").set("v.value", shipStateUpper);
            component.find("legalZip").set("v.value", shipZip);
            component.find("legalCountry").set("v.value", 'US');

            //var action = component.get('c.setLegalToShipping');
        /*action.setParams(
            {
                "acct":component.get("v.AccountObj")
            })
        action.setCallback(this, function(response){           
            var name = response.getState();
            if (name === "SUCCESS") {
            //$A.enqueueAction(a); 
            component.set("v.legalIsShip", false);
            component.set("v.hasLegalAddress", true);
            component.set("v.loadSpinner", false);
            }
        });
            $A.enqueueAction(action); */
        }
    },
    nextOpportunity : function(component, event, helper) {
        //component.set("v.showContact", false);
        
        var email = component.get("v.email");
        var emailVerified = component.get("v.emailVerified");
        var phone = component.get("v.phone");
        var phoneVerified = component.get("v.phoneVerified");
        var a = component.get('c.getOpportunityData');

        if(email==null || phone==null || !emailVerified || !phoneVerified){
            component.set("v.showVerificationMessage", true);
        }else{
            component.set("v.loadSpinner", true);
            component.set("v.showVerificationMessage", false);
            $A.enqueueAction(a);
        }
    },
    saveAddressAndOpp : function(component, event, helper) {
        component.set("v.loadSpinner", true);
        var legalShow = component.find("legalAddress").get("v.value");
        
        var action = component.get('c.updateOppAndAccount');
        action.setParams(
            {
                "recordId":component.get("v.accountId"),
                "oppObject":component.get("v.opportunityObj"),
                "street":component.get("v.legalAddress")+' '+component.get("v.street2"),
                "city":component.get("v.city"),
                "postalCode":component.get("v.postalCode"),
                "country":component.get("v.country"),
                "state":component.get("v.state"),
                "updateAccount" : legalShow
            })
        action.setCallback(this, function(response){           
            var name = response.getState();
            component.set("v.loadSpinner", false);
            if (name === "SUCCESS") {
                component.set("v.showAccount", true);
                component.set("v.showFinalPage", true);
                console.log('response->',response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    createNewContact : function(component, event, helper) {
        console.log('Here');
        component.set("v.showNewContact", true);
    },
    onCancel : function(component, event, helper) {
        console.log('Here');
        component.set("v.showNewContact", false);
    },
    saveNewLegalAddress : function(component, event, helper) {
        component.set("v.loadSpinner", true);
    },
    saveNewContact : function(component, event, helper) {
        component.set("v.loadSpinner", true);
    },
    updateContactList : function(component, event, helper) {
        component.set("v.loadSpinner", false);
        
        var action = component.get('c.getContact');
        action.setParams(
            {
                "recordId":component.get("v.recId")
            })
        action.setCallback(this, function(response){   
            var name = response.getState();
            if (name === "SUCCESS") {
                component.set("v.ContactList", response.getReturnValue());
                console.log(response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        component.set("v.contactSelected", false);
        component.set("v.showNewContact", false);
        /*var a = component.get('c.getOpportunityData');
        $A.enqueueAction(a);*/
    },
   
    showLegalAddress : function(component, event, helper) {
        var legalShow = component.find("legalAddressSelect").get("v.value");
        if(legalShow == 'Enter New Address'){
            component.set("v.showLegalAddress", true);
        }
        else{
            component.set("v.showLegalAddress", false);
            component.set("v.showFinalPage", true);
        }
    },
    showFinalPage : function(component, event, helper) {
        component.set("v.showFinalPage", true);
    },
    showSSNPage : function(component, event, helper) {
        var fedIsSSN = component.get("v.fedIdIsSSN");
        if(fedIsSSN){
            component.find("ssn").set("v.value","");
        }
        else{
        }
    },
    checkValidationFields : function(component, event, helper) {
         helper.validateForm(component, helper);
    },
  
    displayContact : function(component, event, helper) {
        component.set("v.showContact", true);
    },
    startExtraction : function(component, event, helper) {
        flow.startFlow("Extraction_Request_Flow");
    },
    processCancelRequest : function(component, event, helper) {
        component.find("legalAddressSelect").set("v.value", "PleaseSelect");
        component.set("v.showLegalAddress", false);
    },
    submitForm : function(component, event, helper) {
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var oppObject = component.get("v.opportunityObj");
        
        if(userId == oppObject.OwnerId || userId == oppObject.Owner.ManagerId){
        component.set("v.loadSpinner", true);
        var action = component.get('c.sendCSOData');
        action.setParams(
            {
                "oppObject":component.get("v.opportunityObj"),
                "csoRec":component.get("v.csoTrackingRec"),
                "isSSN":component.get("v.fedIdIsSSN"),
                "dataExtraction":component.find("dataExtraction").get("v.value"),
                "contactId":component.get("v.contactId"),
                "quoteId":component.get("v.quoteId"),
                "certId":component.get("v.certificateId"),
            })
        action.setCallback(this, function(response){           
            var name = response.getState();
            component.set("v.loadSpinner", false);
            if (name === "SUCCESS") {
                //component.set("v.ContactList", response.getReturnValue());
                console.log(response.getReturnValue());
                var res = response.getReturnValue();
                var showToast = $A.get("e.force:showToast");
                 if(res.statusCode == 200){
                    var showDataExtractMessage = component.get("v.showDataExtractMessage"); 
                    var successMessage = 'The EZ Onboarding Registration form has been successfully submitted.';
                    var displayMessage = showDataExtractMessage ? successMessage+'\nPlease Remember to submit Data Extraction Form.' : successMessage;
                     showToast.setParams({ 
                        'title' : 'Confirmation', 
                        'type' : 'success',
                        'message' : displayMessage
                    });
                }
                else{
                    showToast.setParams({ 
                        'title' : 'Confirmation', 
                        'type' : 'error',
                        'message' : 'An unexpected error has occurred.\n Details: '+res.message
                    });
                }
                showToast.fire();
                
                
            }
            /*var compEvent = component.getEvent("EZOnboardingEvent");
                compEvent.setParams({
                    "showProgress" : true 
                });
                compEvent.fire();*/
            var parentComponent = component.get("v.parent");                         
            parentComponent.ezParentMethod()            
        });
        $A.enqueueAction(action);
        }
        else{
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({ 
                'title' : 'Unauthorized Access', 
                'type' : 'error',
                'message' : 'You don\'t have access to submit this opportunity.'
            });
            showToast.fire();
        }
    },
    closeModal : function(component){
        component.set("v.loadSpinner", true);
        var updateOppty = component.get("v.updateOppty"); 
        var oppty = component.get("v.opportunityObj");
        var multiClient = component.get("v.isMulti");  
        var nonEnglish = component.get("v.needsNonEngPpwrk");  
        var returningLC = component.get("v.isReturning");  
        //if(updateOppty){
            var action = component.get('c.updateOpp');
            action.setParams(
                {
                    "updateOppty":oppty,
                    "isMulti":multiClient,
                    "returningLost":returningLC,
                    "NonEnglishPpwrk":nonEnglish
                })
            action.setCallback(this, function(response){  
                component.set("v.loadSpinner", false);
                console.log('response->'+response);
                var cmpEvent = component.getEvent("closeForm");
                cmpEvent.fire();
            });
            $A.enqueueAction(action);
        //}

    },
})