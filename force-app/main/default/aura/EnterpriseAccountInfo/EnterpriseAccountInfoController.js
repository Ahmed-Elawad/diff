({
    doInit : function(component, event, helper) {
        var accountId = component.get("v.accountId");
        var parentAccount = component.get("v.parentAccount");
        var parentTracker = component.get("v.parentTracker");
        var tracker = component.get("v.tracker");
        var isParent = accountId == parentAccount.Id ? true : false;
        component.set("v.parentOnboardingRecord", parentTracker.Onboarding_Tool__c);
        component.set("v.onboardingRecord", tracker.Onboarding_Tool__c);
        component.set("v.isParent", isParent);  
        var opp = component.get("v.oppty");
        if (opp != null) {
           component.set("v.sstLeveraged",opp.LeverageSST__c);
        }
    },
    showSpinner : function(component, event, helper) {
        component.set("v.loadSpinner", true);
    },
    hideSST : function(component, event, helper) {
        component.set("v.showForm", false);
    },
    showSST : function(component, event, helper) {
        component.set("v.showForm", true);
    },
    handleTrackerLoad : function(component, event, helper) {
        var trackerLoaded = component.get("v.trackerLoading");
        if(!trackerLoaded){
            var recUi = event.getParam("recordUi");
            var trackerChildType = recUi.record.fields["ChildType__c"].value;
            var AcctValidated = recUi.record.fields["AcctValidated__c"].value;
            var fedisSSN = recUi.record.fields["FedIsSSN__c"].value;
            component.set("v.acctComplete", AcctValidated);
            component.set("v.fedIdIsSSN", fedisSSN);
            component.set("v.ChildType", trackerChildType);
            component.set("v.trackerLoaded", true);
        }
    },
    handleAccountParentLoad : function(component, event, helper) {
        var recUi = event.getParam("recordUi");
        component.set("v.legalStreetParent", recUi.record.fields["LegalAddress__Street__s"].value);
        component.set("v.legalStateParent", recUi.record.fields["LegalAddress__StateCode__s"].value);
        component.set("v.legalCityParent", recUi.record.fields["LegalAddress__City__s"].value);
        component.set("v.legalZipParent", recUi.record.fields["LegalAddress__PostalCode__s"].value);
        component.set("v.legalCountryParent", recUi.record.fields["LegalAddress__CountryCode__s"].value);       
    },

    handleAccountError : function(component, event, helper) {
        component.set("v.loadSpinner", false);
        //Get the error
        var error = event.getParams();
        console.log("Error : " + JSON.stringify(error));
        //Get the error message
        var errorMessage = event.getParam("message");
        console.log("Error Message : " + errorMessage);
    },
    handleAccountLoad : function(component, event, helper) {
        var acctLoaded = component.get("v.acctLoaded");
        if(!acctLoaded){
            helper.selectTab(component, event, helper);
            var recUi = event.getParam("recordUi");      
            component.set("v.billStreet", component.find("billStreetAddy").get("v.value"));
            component.set("v.billCity", component.find("billCityAddy").get("v.value"));
            component.set("v.billState", component.find("billStateAddy").get("v.value"));
            component.set("v.billZip", component.find("billZipAddy").get("v.value"));
            component.set("v.shipStreet", component.find("ShipStreetAddy").get("v.value"));
            component.set("v.shipCity", component.find("ShipCityAddy").get("v.value"));
            component.set("v.shipState", component.find("ShipStateAddy").get("v.value"));
            component.set("v.shipZip", component.find("ShipZipAddy").get("v.value"));
            var isParent = component.get("v.isParent");
            var ChildType = component.get("v.ChildType");
            if(isParent!=null){
                if(isParent || (ChildType!=null && ChildType!="Combo")){
                    component.set("v.legalStreet", recUi.record.fields["LegalAddress__Street__s"].value);
                    component.set("v.legalState", recUi.record.fields["LegalAddress__StateCode__s"].value);
                    component.set("v.legalCity", recUi.record.fields["LegalAddress__City__s"].value);
                    component.set("v.legalZip", recUi.record.fields["LegalAddress__PostalCode__s"].value);
                }
            }
            /*if(recUi.record.fields["LegalAddress__Street__s"]!=null){
                component.set("v.legalStreet", recUi.record.fields["LegalAddress__Street__s"].value);
                component.set("v.legalCity", recUi.record.fields["LegalAddress__City__s"].value);
                component.set("v.legalZip", recUi.record.fields["LegalAddress__PostalCode__s"].value);
            }*/
            //component.set("v.legalCountry", recUi.record.fields["LegalAddress__CountryCode__s"].value);
            var tracker = component.get("v.tracker");
            if(tracker!=null && tracker.UserErrorMessage__c !=null){
                component.set("v.registrationError", tracker.UserErrorMessage__c);           
            }else{
                component.set("v.registrationError", null);  
            }
            var acctValid  = true;
            var acctValidCurrentValue = component.get("v.acctComplete");
            var formFields = component.find("AcctFormField");
            var revalidationCalled = component.get("v.revalidationCalled");
            if(formFields!=null){
                formFields.forEach(function (field) {
                    if(field.get("v.fieldName") != null){
                        if($A.util.isEmpty(field.get("v.value"))){
                            //alert(field.get("v.fieldName"));
                            acctValid = false;
                        }
                    }
                });
                component.set("v.acctComplete", acctValid);
                if(acctValidCurrentValue != acctValid && !revalidationCalled){
                    component.find('TrackerForm').submit();
                    helper.reValidateForm(component);
                    component.set("v.revalidationCalled", true);
                }
            }
            component.set("v.loadSpinner", false);         
        }        
    },
    displaySucessMessage : function(component, event, helper) {
        var isMMSStandalone = component.get("v.isMMSStandalone");
        var isParent = component.get("v.isParent");
        var usingSST = component.get("v.sstLeveraged");
        //alert('in displaySucessMessage usingSST='+usingSST);
        var SSTValidationField = (usingSST ? component.find("SSTValidationField").get("v.value") : true);
        //alert('in displaySucessMessage usingSST='+usingSST+' SSTValidationField='+SSTValidationField);
        var messageType = SSTValidationField ? 'success' : 'warning';
        var messageMode = SSTValidationField ? 'dismissible' : 'sticky';
        var successMessage = SSTValidationField ? 'The updates have been saved successfully' 
        : 'The updates have been saved successfully!\nPlease Note: You must navigate to the Sales Submission Team Information Tab and complete that form to proceed.';
        //alert('in displaySucessMessage isParent='+isParent);
        if(isParent && usingSST){
            component.find('OpptyUpdateForm').submit();
        } else if(!isParent && !isMMSStandalone){
            component.find('ChildTrackerForm').submit();
        }
        component.set("v.loadSpinner", false);
        var showToast = $A.get("e.force:showToast"); 
        showToast.setParams({ 
            'title' : 'Confirmation', 
            'type' : messageType,
            'mode' : messageMode,
            'message' : successMessage
        }); 
        showToast.fire();
        helper.reValidateForm(component);
    },
    handleOpptyLoad : function(component, event, helper) {
        var opptyLoaded = component.get("v.opptyLoaded");
        if(!opptyLoaded){
            //alert("Opportunity loaded");
            component.set("v.opptyLoaded", true);
        }
    },
    handleAccountSubmit : function(component, event, helper) {
        helper.validateAcct(component, event, helper, false);
    },
    saveAndCloseAcct : function(component, event, helper) {
        helper.validateAcct(component, event, helper, true);
    },
    closeAcct : function(component, event, helper) {
        helper.closeAcct(component, event, helper);
    },
    makeLegalBill : function(component, event, helper) {
        component.set("v.legalStreet", component.find("billStreetAddy").get("v.value"));
        component.set("v.legalCity", component.find("billCityAddy").get("v.value"));
        component.set("v.legalState", component.find("billStateAddy").get("v.value"));
        component.set("v.legalZip", component.find("billZipAddy").get("v.value"));
        component.find("legalIsShipping").set("v.value", false);
    },
    makeLegalShip : function(component, event, helper) {
        component.set("v.legalStreet", component.find("ShipStreetAddy").get("v.value"));
        component.set("v.legalCity", component.find("ShipCityAddy").get("v.value"));
        component.set("v.legalState", component.find("ShipStateAddy").get("v.value"));
        component.set("v.legalZip", component.find("ShipZipAddy").get("v.value"));
        component.find("legalIsBilling").set("v.value", false);
    },
    ParentIsChildLegal : function(component, event, helper) {
        var legalState = component.find("ParentLegalState").get("v.value");
        component.set("v.legalStreet", component.find("ParentLegalStreet").get("v.value"));
        component.set("v.legalCity", component.find("ParentLegalCity").get("v.value"));
                if(legalState!=''){
            component.set("v.legalState", legalState);
        }
        component.set("v.legalZip", component.find("ParentLegalZip").get("v.value"));
    },
    ShipSameAsBilling : function(component, event, helper) {
        component.set("v.shipStreet", component.find("billStreetAddy").get("v.value"));
        component.set("v.shipCity", component.find("billCityAddy").get("v.value"));
        component.set("v.shipState", component.find("billStateAddy").get("v.value"));
        component.set("v.shipZip", component.find("billZipAddy").get("v.value"));
    },
    BillSameAsShipping : function(component, event, helper) {
        component.set("v.billStreet", component.find("ShipStreetAddy").get("v.value"));
        component.set("v.billCity", component.find("ShipCityAddy").get("v.value"));
        component.set("v.billState", component.find("ShipStateAddy").get("v.value"));
        component.set("v.billZip", component.find("ShipZipAddy").get("v.value"));
    },
    
    ParentIsChildBilling : function(component, event, helper) {
        component.set("v.billStreet", component.find("ParentBillingStreet").get("v.value"));
        component.set("v.billCity", component.find("ParentBillingCity").get("v.value"));
        component.set("v.billState", component.find("ParentBillingState").get("v.value"));
        component.set("v.billZip", component.find("ParentBillingZip").get("v.value"));
    },
    ParentIsChildShipping : function(component, event, helper) {
        component.set("v.shipStreet", component.find("ParentShippingStreet").get("v.value"));
        component.set("v.shipCity", component.find("ParentShippingCity").get("v.value"));
        component.set("v.shipState", component.find("ParentShippingState").get("v.value"));
        component.set("v.shipZip", component.find("ParentShippingZip").get("v.value"));
    },
})