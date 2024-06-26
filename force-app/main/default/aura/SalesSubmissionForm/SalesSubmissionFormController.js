({
    doInit : function(component, event, helper) {
        component.set("v.loading", true);
    },
    updateDisplay : function(component, event, helper) {
        helper.updateDisplay(component, event, helper);
    },
    handleSSTError: function(component, event, helper) {
        component.set("v.loadSpinner", false);
    },
    saveSST : function(component, event, helper) {
        helper.validateSST(component, event, helper, false);
    },
    saveAndCloseSST : function(component, event, helper) {
        helper.validateSST(component, event, helper, true);
    },
    closeSST : function(component, event, helper) {
        helper.closeSST(component, event, helper);
    },
    displaySucessMessage : function(component, event, helper) {
        component.set("v.loadSpinner", false);
        var showToast = $A.get("e.force:showToast"); 
        showToast.setParams({ 
            'title' : 'Confirmation', 
            'type' : 'success',
            'message' : 'The Sales Submission Team Form information has been saved'
        }); 
        showToast.fire();
        helper.reValidateForm(component);
    },
    handleTrackerLoad : function(component, event, helper) {
        var trackerLoaded = component.get("v.trackerLoaded");
        if(!trackerLoaded){
            var recUi = event.getParam("recordUi");
            component.set("v.sstValid", recUi.record.fields["SSTValidated__c"].value);
            component.set("v.trackerLoaded", true);
            component.set("v.loading", true);
        }
    },
    handleOnboardLoad : function(component, event, helper) {        
        var onboardingLoaded = component.get("v.onboardingLoaded");
        if(!onboardingLoaded){
            helper.initialize(component, event, helper);
            var recUi = event.getParam("recordUi");
            var aoId = recUi.record.fields["Authorize_Officer__c"].value;
            if(component.get("v.authOfficerId") ==null && aoId!=null && !component.get("v.updateAO")){
                component.set("v.authOfficerId", aoId);
            }
			var RelationWithAddAccount = recUi.record.fields["RelationWithAddAccount__c"].value;
            if(component.get("v.relationWithAddAccount") ==null && RelationWithAddAccount!=null){
                component.set("v.relationWithAddAccount", RelationWithAddAccount);
            }
            var RelatedAccountId = recUi.record.fields["RelatedAccountId__c"].value;
            if(component.get("v.relatedAccountId") ==null && RelatedAccountId!=null){
                component.set("v.relatedAccountId", RelatedAccountId);
            }
            if(recUi.record.fields["Precheck_Client__c"]!=null){
                var preCheck = recUi.record.fields["Precheck_Client__c"].value;
                if(component.get("v.preCheck") ==null && preCheck!=null){
                    component.set("v.preCheck", preCheck);
                }
            }
            var payContactId = recUi.record.fields["PayrollContact__c"].value;
            if(component.get("v.payContactId") ==null && payContactId!=null && !component.get("v.updatePC")){
                component.set("v.payContactId", payContactId);
            }
            var requires1099 = recUi.record.fields["Does_Company_Need_1099s__c"].value;
            if(component.get("v.need1099") ==null && requires1099!=null){
                component.set("v.need1099", requires1099);
            }
            var DeliverIsLegalAddy = recUi.record.fields["IrsIsDelivery__c"].value;
            if(component.get("v.deliveryIsLegal") ==null && DeliverIsLegalAddy!=null){
                component.set("v.deliveryIsLegal", DeliverIsLegalAddy);
            }
            var preAssignedNumber = recUi.record.fields["PreAssignedClientNum__c"].value;
            if(component.get("v.needPreassignedNumber") ==null && preAssignedNumber!=null){
                component.set("v.needPreassignedNumber", preAssignedNumber);
            }
            var runDate = recUi.record.fields["Run_Date__c"].value;
            if(component.get("v.runDate") ==null && runDate!=null){
                component.set("v.runDate", runDate);
            }
            var checkDate = recUi.record.fields["First_Check_Date__c"].value;
            if(component.get("v.checkDate") ==null && checkDate!=null){
                component.set("v.checkDate", checkDate);
            }
            var endDate = recUi.record.fields["PeriodEndDate__c"].value;
            if(component.get("v.endDate") ==null && endDate!=null){
                component.set("v.endDate", endDate);
            }
            var busStructure = recUi.record.fields["Business_Structure__c"].value;
            if(component.get("v.businessStructure") ==null && busStructure!=null){
                component.set("v.businessStructure", busStructure);
            }
            var relationManager = recUi.record.fields["RelationshipManager__c"].value;
            if(component.get("v.relationshipManager") ==null && relationManager!=null){
                component.set("v.relationshipManager", relationManager);
            }
            var IgnoreRelationshipManager = recUi.record.fields["IgnoreRelationshipManager__c"].value;
            if(component.get("v.ignoreRelationManager") != IgnoreRelationshipManager){
                component.set("v.ignoreRelationManager", IgnoreRelationshipManager);
            }
            var newBusiness = recUi.record.fields["Newly_Established_Business__c"].value;
            if(component.get("v.newlyEstablished") ==null && newBusiness!=null){
                component.set("v.newlyEstablished", newBusiness);
            }
            var priorWages = recUi.record.fields["PriorWagesLoaded__c"].value;
            if(component.get("v.priorWagesLoaded") ==null && priorWages!=null){
                component.set("v.priorWagesLoaded", priorWages);
            }
            var empsToLoad = recUi.record.fields["EmpsToLoad__c"].value;
            if(component.get("v.empsToLoad") ==null && empsToLoad!=null){
                component.set("v.empsToLoad", empsToLoad);
            }
            var states = recUi.record.fields["StateProcessedIn__c"].value;
            if(component.get("v.statesProcessedIn") ==null && states!=null){
                component.set("v.statesProcessedIn", states);
            }
            var num1099 = recUi.record.fields["NumOf1099s__c"].value;
            if(component.get("v.num1099") ==null && num1099!=null){
                component.set("v.num1099", num1099);
            }
            var irsAddy = recUi.record.fields["Irs_Address__c"].value;
            if(component.get("v.deliveryAddy") ==null && irsAddy!=null){
                component.set("v.deliveryAddy", irsAddy);
            }
            if(component.get("v.hasESR")){
                if(recUi.record.fields["ESR_educationInstitution__c"]!=null){
                    component.set("v.ESR_educationInstitution", recUi.record.fields["ESR_educationInstitution__c"].value);
                    component.set("v.ESR_PriorMedRenewalDate", recUi.record.fields["ESR_PriorMedRenewalDate__c"].value);
                    component.set("v.ESR_selfInsuredPlan", recUi.record.fields["ESR_selfInsuredPlan__c"].value);
                    component.set("v.ESR_UnionEmps", recUi.record.fields["ESR_UnionEmps__c"].value);
                }
            }
            if(component.get("v.hasFlexTime")){
                if(recUi.record.fields["NumFlexId__c"]!=null){
                    component.set("v.Flextime_Date", recUi.record.fields["Flextime_Date__c"].value);
                    component.set("v.Flextime_NumFlexId", recUi.record.fields["NumFlexId__c"].value);
                    component.set("v.Flextime_Anticipated_Start_Date", recUi.record.fields["Anticipated_Start_Date__c"].value);
                    component.set("v.Flextime_Timeclock", recUi.record.fields["Flextime_Timeclock__c"].value);
                    component.set("v.Flextime_TAA", recUi.record.fields["Flextime_TAA__c"].value);
                }
            }
            if(component.get("v.hasBenAdmin")){
                if(recUi.record.fields["Broker_Contact__c"]!=null){
                    component.set("v.benAdmin_Broker_Contact", recUi.record.fields["Broker_Contact__c"].value);
                    component.set("v.benAdmin_Broker_Paying_Benefits_Admin_Fees", recUi.record.fields["Broker_Paying_Benefits_Admin_Fees__c"].value);
                    component.set("v.benAdmin_Open_Enrollment_Date", recUi.record.fields["Open_Enrollment_Date__c"].value);
                    component.set("v.benAdmin_Delivery_Date", recUi.record.fields["Delivery_Date__c"].value);
                    component.set("v.benAdmin_EDI_Connection", recUi.record.fields["EDI_Connection__c"].value);
                    component.set("v.benAdmin_Carrier_Name", recUi.record.fields["Carrier_Name__c"].value);
                    component.set("v.benAdmin_Carrier_Contact", recUi.record.fields["Carrier_Contact__c"].value);
                    component.set("v.benAdmin_Group_Number", recUi.record.fields["Group_Number__c"].value);
                }
            }
            
            var sstValidCurrentValue = component.get("v.sstValid");
            var formFields = component.find("sstFormField");
            var sstValid = true;
            var ignoreRelationshipManager = component.get("v.ignoreRelationManager");
            var revalidationCalled = component.get("v.revalidationCalled");
            
            formFields.forEach(function (field) {
                if(field.get("v.fieldName") != null){
                    var currentFieldName = field.get("v.fieldName");
                    if(currentFieldName != "RelationshipManager__c" || !ignoreRelationshipManager){
                        if($A.util.isEmpty(field.get("v.value"))){
                            //alert(field.get("v.fieldName"));
                            sstValid = false;
                        }
                    }
                }
            });
            component.set("v.sstValid", sstValid);
            if(sstValidCurrentValue != sstValid && !revalidationCalled){
                component.find('TrackerForm').submit();
                helper.reValidateForm(component);
                component.set("v.revalidationCalled", true);
            }
        }
    },
    clearPC : function(component, event, helper) {
        component.set("v.updatePC", true);
        component.set("v.payContactId", null);
        //component.set("v.updatePC", false);
    },
    clearAO : function(component, event, helper) {
        component.set("v.updateAO", true);
        component.set("v.authOfficerId",null);
        //component.set("v.updateAO", false);
    },
    displayNewPC : function(component, event, helper) {
        component.set("v.displayUpdateScreen", true);
        component.set("v.displayPayrollContactScreen", true);
    },
    displayNewAO : function(component, event, helper) {
        component.set("v.displayUpdateScreen", true);
        component.set("v.displayAuthOfficerScreen", true);
    },
    populateParentPayContact : function(component, event, helper) {
        var populateParentPayContact = component.get("v.populateParentPC");
        if(populateParentPayContact){
            component.set("v.payContactId", component.find("payContactParent").get("v.value"));
        }else{
            component.set("v.payContactId", null);
        }   
    },
    populateParentAO : function(component, event, helper) {
        var populateParentAO = component.get("v.populateParentAO");
        if(populateParentAO){
            component.set("v.authOfficerId", component.find("authOfficerParent").get("v.value"));
        }else{
            component.set("v.authOfficerId", null);
        }            
    },

    populateParentPayroll : function(component, event, helper) {
        var populateParentPayContact = component.get("v.populateParentPC");
        component.set("v.businessStructure", component.find("businessStructureParent").get("v.value"));
        component.set("v.runDate", component.find("runDateParent").get("v.value"));
        component.set("v.checkDate", component.find("checkDateParent").get("v.value"));
        component.set("v.endDate", component.find("endDateParent").get("v.value"));
        component.set("v.relationshipManager", component.find("relationshipManagerParent").get("v.value"));
        component.set("v.newlyEstablished", component.find("newlyEstablishedParent").get("v.value"));
        component.set("v.priorWagesLoaded", component.find("priorWagesLoadedParent").get("v.value"));
        component.set("v.empsToLoad", component.find("empsToLoadParent").get("v.value"));
        component.set("v.statesProcessedIn", component.find("statesProcessedInParent").get("v.value"));
        component.set("v.num1099", component.find("1099requiredParent").get("v.value"));
        component.set("v.PriceLock", component.find("3yearPriceLockParent").get("v.value"));
        component.set("v.deliveryAddy", component.find("deliveryAddyParent").get("v.value"));
        component.set("v.preAssignedId", component.find("preAssignedIdParent").get("v.value"));
        component.set("v.needPreassignedNumber", component.find("PreAssignedClientNumParent").get("v.value"));
        component.set("v.need1099", component.find("1099requiredParent").get("v.value"));
        component.set("v.deliveryIsLegal", component.find("isDeliveryLegalParent").get("v.value"));
        component.set("v.relationWithAddAccount", component.find("relationWithAddAccountParent").get("v.value"));
        component.set("v.relatedAccountId", component.find("relatedAccountIdParent").get("v.value"));
    },
    populateParentESR : function(component, event, helper) {
        var populateParentESR = component.get("v.populateParentESR");
        if(populateParentESR){
            component.set("v.ESR_educationInstitution", component.find("ESR_educationInstitutionParent").get("v.value"));
            component.set("v.ESR_PriorMedRenewalDate", component.find("ESR_PriorMedRenewalDateParent").get("v.value"));
            component.set("v.ESR_selfInsuredPlan", component.find("ESR_selfInsuredPlanParent").get("v.value"));
            component.set("v.ESR_UnionEmps", component.find("ESR_UnionEmpsParent").get("v.value"));
        }
    },
    populateParentFlex : function(component, event, helper) {
        var populateParentFlexTime = component.get("v.populateParentFlexTime");
        if(populateParentFlexTime){
            component.set("v.Flextime_Date", component.find("Flextime_DateParent").get("v.value"));
            component.set("v.Flextime_NumFlexId", component.find("NumFlexIdParent").get("v.value"));
            component.set("v.Flextime_Anticipated_Start_Date", component.find("Anticipated_Start_DateParent").get("v.value"));
            component.set("v.Flextime_Timeclock", component.find("Flextime_TimeclockParent").get("v.value"));
            component.set("v.Flextime_TAA", component.find("Flextime_TAAParent").get("v.value"));
            component.set("v.preCheck", component.find("Precheck_ClientParent").get("v.value"));
        }
    },
    populateParentBenAdmin : function(component, event, helper) {
        var populateParentBenAdmin = component.get("v.populateParentBenAdmin");
        if(populateParentBenAdmin){
            component.set("v.benAdmin_Broker_Contact", component.find("benAdmin_Broker_ContactParent").get("v.value"));
            component.set("v.benAdmin_Broker_Paying_Benefits_Admin_Fees", component.find("benAdmin_Broker_Paying_Benefits_Admin_FeesParent").get("v.value"));
            component.set("v.benAdmin_Open_Enrollment_Date", component.find("benAdmin_Open_Enrollment_DateParent").get("v.value"));
            component.set("v.benAdmin_Delivery_Date", component.find("benAdmin_Delivery_DateParent").get("v.value"));
            component.set("v.benAdmin_EDI_Connection", component.find("benAdmin_EDI_ConnectionParent").get("v.value"));
            component.set("v.benAdmin_Carrier_Name", component.find("benAdmin_Carrier_NameParent").get("v.value"));
            component.set("v.benAdmin_Carrier_Contact", component.find("benAdmin_Carrier_ContactParent").get("v.value"));
            component.set("v.benAdmin_Group_Number", component.find("benAdmin_Group_NumberParent").get("v.value"));
        }
    },
    displayUpdateAO : function(component, event, helper) {
        component.set("v.displayAuthOfficerScreen", true);
        component.set("v.displayUpdateScreen", true);
    },
    displayUpdatePC : function(component, event, helper) {
        component.set("v.displayPayrollContactScreen", true);
        component.set("v.displayUpdateScreen", true);
    },
    updateAuthOfficer : function(component, event, helper) {
        var updatedRecord = event.getParam("response");
        component.set("v.authOfficerId", updatedRecord.id);
        component.set("v.displayAuthOfficerScreen", false);
        //component.find('SSTForm').submit();
        component.set("v.loadSpinner", false);
        helper.updateDisplay(component, event, helper);
        
    },
    updatePC : function(component, event, helper) {
        var updatedRecord = event.getParam("response");
        component.set("v.payContactId", updatedRecord.id);
        component.set("v.displayPayrollContactScreen", false);
        //component.find('SSTForm').submit();
        component.set("v.loadSpinner", false);
        helper.updateDisplay(component, event, helper);
        
    },
    handlePCSubmit : function(component, event, helper) {
        component.set("v.loadSpinner", true);
        event.preventDefault();
        var fields = event.getParam('fields');
        component.find('PayrollContactForm').submit(fields);
    },
    handleAOSubmit : function(component, event, helper) {
        component.set("v.loadSpinner", true);
        event.preventDefault();
        var fields = event.getParam('fields');
        component.find('AuthorizedOfficerForm').submit(fields);
    },
})