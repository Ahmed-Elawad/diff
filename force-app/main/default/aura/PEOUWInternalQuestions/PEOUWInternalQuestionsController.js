({
    init : function(component, event, helper) {
         component.set("v.isLoading",true);	
         
       if(component.get("v.currentAccount") != null){	
            component.set("v.ActiveParentTab", component.get("v.currentAccount.Id") );	
       }
       if(component.get("v.currentAccount.Id") == component.get("v.ParentAccountId")){
        component.set("v.isParentAccount", true);
       
       }
       component.set("v.tabNameList", ['General Submission Information', 'Setup Information', 'Compliance', 'COBRA']);
       component.set('v.saveFunc' , $A.getCallback(() => helper.getSavePromise(component, event, helper)));

        helper.getImplementationChecklistData(component, event, helper);
        console.log('>>>on load :peoChecklist: '+JSON.stringify(component.get('v.peoChecklist')));
        
        if (component.get("v.peoChecklist.Platform__c") == 'Flex' && component.get("v.peoChecklist.Client_Add_on__c") == false) {
           component.set("v.flexvalue", true);
       }

    },
    keyCheck: function(component, event, helper) {
        if (event.which >= 48 && event.which <= 57) {
            return true;
        } else {
            event.preventDefault();
        }
    },
    handleCopyToChildren : function(component, event, helper){
       
       var isChecked = event.detail.checked;
       if(isChecked){
            var parentData = component.get("v.implementationChecklist");
            console.log('>>>>parentData::'+JSON.stringify(parentData));
            var appEvent = $A.get("e.c:PEOImpCopyToChildren");
            appEvent.setParams({"implementationChecklist":parentData});
            appEvent.fire();
       } 
    },
    handleCopyToChildrenEvent: function(component, event, helper){
        console.log('event handler>>>>',component.get("v.currentAccount")  );
      
        if(component.get("v.isParentAccount") == false && component.get("v.copyfromParent") ){
            component.set("v.mirrorParentInfo", true);
            console.log('parentImplChecklist else if');
            component.set('v.parentImplChecklist',event.getParam("implementationChecklist") );
            var impChecklistId =  component.get('v.implementationChecklist.Id');
           
            component.set('v.implementationChecklist',  event.getParam("implementationChecklist"));
            component.set('v.implementationChecklist.Id',impChecklistId) ;

            helper.prepareOwnerRecData(component, event, helper);
            helper.prepareOwnerDataWhoEarnMoreThan150K(component, event, helper);
            helper.prepareFamilyMemberRec(component, event, helper);
            helper.prepareMultiPicklistValues(component, event, helper);
            helper.preparePartnershipOwnerData(component, event, helper);
            helper.prepareOwner2Percentage(component, event, helper);
            helper.prepareOwnerDataWhoEarnMoreThan130K(component, event, helper);
            helper.saveImplementationQuestions(component, event, helper)
            
        }
     },
    
     handleCopyFromParent : function(component, event, helper){
        var parCheckListId = component.get('v.parentImplChecklist.Id');
        var impChecklistId =  component.get('v.implementationChecklist.Id');
        var impChecklistPC =  component.get('v.implementationChecklist.Prospect_Client__c');
        console.log('parCheckListId'+ '--'+parCheckListId+'----'+impChecklistId);  
        if(component.get("v.currentAccount.Id") == component.get("v.ParentAccountId")){
            component.set("v.isParentAccount", true);
           
        }else{
            component.set("v.isParentAccount", false);
        }
        console.log('component.get("v.currentAccount.Id") == component.get("v.ParentAccountId")'+component.get("v.currentAccount.Id")+'-----'+component.get("v.ParentAccountId")); 
        console.log('parCheckListId', JSON.stringify(component.get('v.parentImplChecklist')));
        //console.log(JSON.stringify(event.details));
        console.log(component.get("v.mirrorParentInfo")+'-----imid'+component.get('v.implementationChecklist.Id')+'----'+component.get("v.isParentAccount")+'-----'+component.get('v.currentAccount.Id'));
        if(component.get("v.mirrorParentInfo") &&  component.get("v.isParentAccount") == false){
            //Added by Srujan
            helper.copydataFromParentToChild(component, event, helper);
            helper.saveImplementationQuestions(component, event, helper); 
        }
     },
    handleTabChange: function(cmp, e, helper) {
        let tabName = e.getSource().get('v.Id');
        cmp.set('v.skipSave', false);
        helper.checkValidity(cmp, e, helper); 
        //SPA: US8:start
		helper.getImplementationChecklistData(cmp, e, helper);
        //SPA: US8:end
        
    },
   
    handleChange: function(component, event, helper) {
        try {
            if(component.get("v.isParentAccount") == true){
                var parentData = component.get("v.implementationChecklist");
                console.log('>>>>parentData::'+JSON.stringify(parentData));
                var appEvent = $A.get("e.c:PEOImpCopyToChildren");
                appEvent.setParams({"implementationChecklist":parentData});
                appEvent.fire();
            }
            console.log('fieldDetail:'+event.getSource());
            var fieldDetail = event.getSource();
            var fieldName = fieldDetail.getLocalId();
            var fieldVal = event.getParam("value");
            let fieldType = fieldDetail.get("v.type");
            
            if(fieldName == 'Names_individuals_who_are_officers__c'){
                let arr = fieldVal.split(',');
                if(arr.length > 10){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: 'Error',
                        message: 'You can not enter more than 10 names.',
                        type: 'ERROR'
                    });
                    toastEvent.fire();
                    arr.pop();
                    component.set('v.implementationChecklist.Names_individuals_who_are_officers__c',  arr.join(','));
                }
                return;
            }
            
            if(fieldName == 'Names_of_officers_of_company_earn_185K__c'){
                let arr = fieldVal.split(',');
                if(arr.length > 10){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: 'Error',
                        message: 'You can not enter more than 10 names.',
                        type: 'ERROR'
                    });
                    toastEvent.fire();
                    arr.pop();
                    component.set('v.implementationChecklist.Names_of_officers_of_company_earn_185K__c',  arr.join(','));
                }
                return;
            }
            
            if(fieldType != undefined && fieldType == 'text'){
                console.log('handleChange fieldType text');
                var timer = component.get('v.timeoutId');
                clearTimeout(timer);
                var timer = setTimeout(
                    $A.getCallback(function(){
                        component.set('v.timeoutId', null);
                        //debugger;
                        helper.runAutoSave(component, event, helper, event.getSource());
                    }), 300);
                
                component.set('v.timeoutId', timer);
            }
            else{
                //debugger;
                console.log('handleChange no delay for save send');
                helper.runAutoSave(component, event, helper, event.getSource());
            }
            helper.runAutoSave(component, event, helper, event.getSource());        
            
            if(fieldName =='Business_Entity_Type'){
                var busEntityType = component.get('v.businessEntityVal');
                if((busEntityType != null && busEntityType != '' && busEntityType != undefined) && busEntityType != fieldVal){
                    //debugger;
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: 'Warning!',
                        message: 'Changing the Business Entity type will clear associated fields on the Compliance tab.',
                        type: 'warning'
                    });
                    toastEvent.fire();
                }
                component.set("v.businessEntityVal", fieldVal);
                component.set('v.implementationChecklist.Business_Entity_Type__c', fieldVal );
                var businessEntityVal = fieldVal;		
                if(businessEntityVal == 'Partnership' || businessEntityVal == 'Limited Liability Partnership'
                   || businessEntityVal == 'Sole Proprietor'
                   || businessEntityVal == 'LLC taxed as a partnership' 
                   || businessEntityVal == 'LLC taxed as a sole proprietorship'){	
                    component.set('v.implementationChecklist.Is_the_Company_a_Partnership__c', 'Yes');	
                    component.set('v.isBusinessEntityTypePartner', true);
                    component.set('v.implementationChecklist.Own_5_of_the_company__c', '');	
                    component.set('v.implementationChecklist.Users_own_5_of_company__c', null);	
                    helper.prepareOwnerRecData(component, event, helper, component.get('v.implementationChecklist'));	
                    component.set('v.implementationChecklist.Own_2_of_the_company__c', '');	
                    component.set('v.implementationChecklist.Users_own_2_of_company__c', null);
                    helper.prepareOwner2Percentage(component, event, helper, component.get('v.implementationChecklist'));
                    component.set('v.implementationChecklist.Family_members_of_5_2_1_owners__c', '');	
                    component.set('v.implementationChecklist.Name_of_members_of_5_2_1_owners__c', null);
                    helper.prepareFamilyMemberRec(component, event, helper, component.get('v.implementationChecklist'));
                }	
                else{	
                    component.set('v.isBusinessEntityTypePartner', false);	                
                }
                //SFDC-22487
                var ownerRecs = component.get("v.ownerRecsPartnership");
                if(businessEntityVal=='Sole Proprietor' || businessEntityVal=='LLC taxed as a sole proprietorship'){
                    component.set('v.disableAddPartners', true);
                    if(ownerRecs.length>=2){       
                        console.log('Sole:' , ownerRecs);
                        ownerRecs.length=1;                    
                        let totalper=0;                      
                        if(ownerRecs[0].percentageOfOwner != '' 
                           && ownerRecs[0].percentageOfOwner != undefined)
                        {
                            totalper = parseFloat(ownerRecs[0].percentageOfOwner);
                        }
                        component.set("v.ownerRecsPartnership", ownerRecs );    
                        component.set("v.ownerRecsPartnershipTotal",totalper);
                    }
                }
                else
                {
                    component.set('v.disableAddPartners', false);	 
                }
                let ParDel;
                if(businessEntityVal == 'Partnership' || businessEntityVal == 'Limited Liability Partnership'               
                   || businessEntityVal == 'LLC taxed as a partnership' ){	   
                    ParDel=2;
                    if(ownerRecs.length <=1){
                        let ownerDetails = {nameOfOwner:"", percentageOfOwner:""};
                        ownerRecs.push(Object.assign({},ownerDetails));
                        component.set("v.ownerRecsPartnership", ownerRecs);
                    }
                } else{
                    ParDel=1;
                }      
                component.set('v.PartnersDelete', ParDel);    
                if(businessEntityVal=='S Corporation' || businessEntityVal=='LLC taxed as a S-Corp'){
                    component.set('v.scorpreadonly', true);  
                    //component.set('v.implementationChecklist.Family_members_of_5_2_1_owners__c', 'Yes');	                
                    component.set('v.implementationChecklist.Own_2_of_the_company__c', 'Yes');	
                    component.set('v.implementationChecklist.Own_5_of_the_company__c', '');	                
                    component.set('v.implementationChecklist.Users_own_5_of_company__c', null);
                    helper.prepareOwnerRecData(component, event, helper, component.get('v.implementationChecklist'));
                    component.set('v.implementationChecklist.Is_the_Company_a_Partnership__c', '');	                
                    component.set('v.implementationChecklist.Partner_user_of_company__c', null);
                    helper.preparePartnershipOwnerData(component, event, helper, component.get('v.implementationChecklist'));
                }
                else{
                    component.set('v.scorpreadonly', false);
                }
                if(businessEntityVal=='LLC taxed as a corporation' || businessEntityVal=='C Corporation'){
                    component.set('v.CCorpreadonly', true);  
                    component.set('v.implementationChecklist.Own_5_of_the_company__c', 'Yes');	
                    component.set('v.implementationChecklist.Own_2_of_the_company__c', '');	
                    component.set('v.implementationChecklist.Users_own_2_of_company__c', null);
                    helper.prepareOwner2Percentage(component, event, helper, component.get('v.implementationChecklist'));
                    component.set('v.implementationChecklist.Family_members_of_5_2_1_owners__c', '');	
                    component.set('v.implementationChecklist.Name_of_members_of_5_2_1_owners__c', null);
                    helper.prepareFamilyMemberRec(component, event, helper, component.get('v.implementationChecklist'));
                    component.set('v.implementationChecklist.Is_the_Company_a_Partnership__c', '');	
                    component.set('v.implementationChecklist.Partner_user_of_company__c', null);
                    helper.preparePartnershipOwnerData(component, event, helper, component.get('v.implementationChecklist'));
                } else{
                    component.set('v.CCorpreadonly', false);  
                }
            }
            console.log('isBusinessEntityTypePartner:'+component.get('v.isBusinessEntityTypePartner'));
            //SPA: US8:end
            
            if(fieldName == 'Payroll_Frequency__c'){
                var frequencyList = component.get('v.frequencyValues');
                if(frequencyList){
                    frequencyList = frequencyList.sort().join('; ');
                    component.set('v.implementationChecklist.PEO_Underwriting_Checklist__r.Payroll_Frequency__c',frequencyList);
                    if(frequencyList != undefined && frequencyList != null){
                        if(frequencyList.includes('52 - Weekly')){
                            component.set('v.showWeekly', true);
                        }else{
                            component.set('v.showWeekly', false);
                        }
                        if(frequencyList.includes('26 - Bi-Weekly')){
                            component.set('v.showBiWeekly', true);
                        }else{
                            component.set('v.showBiWeekly', false);
                        }
                        if(frequencyList.includes('24 - Semi-Monthly')){
                            component.set('v.showSemiMonthly', true);
                        }else{
                            component.set('v.showSemiMonthly', false);
                        }
                        if(frequencyList.includes('12 - Monthly')){
                            component.set('v.showMonthly', true);
                        }else{
                            component.set('v.showMonthly', false);
                        }
                    }
                }
                else{
                    component.set('v.implementationChecklist.PEO_Underwriting_Checklist__r.Payroll_Frequency__c','');
                    component.set('v.showWeekly', false);
                    component.set('v.showBiWeekly', false);
                    component.set('v.showSemiMonthly', false);
                    component.set('v.showMonthly', false);
                }
                
            }
            
            if(fieldName == 'Anticipated_First_Run_Date_Weekly__c'){
                var checkdate = component.get('v.implementationChecklist.Anticipated_First_Check_Date_Weekly__c');
                if(checkdate != null && checkdate != '' && checkdate != undefined){
                    if(fieldVal > checkdate){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Error',
                            message: 'The Anticipated First Run Date cannot be greater than the Anticipated First Check Date.',
                            duration:' 5000',
                            type: 'error',
                        });
                        toastEvent.fire();
                        component.set('v.implementationChecklist.Anticipated_First_Run_Date_Weekly__c', '');
                    }
                }
            }
            if(fieldName == 'Anticipated_First_Run_Date_BiWeekly__c'){
                var checkdate = component.get('v.implementationChecklist.Anticipated_First_Check_Date_BiWeekly__c');
                if(checkdate != null && checkdate != '' && checkdate != undefined){
                    if(fieldVal > checkdate){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Error',
                            message: 'The Anticipated First Run Date cannot be greater than the Anticipated First Check Date.',
                            duration:' 5000',
                            type: 'error',
                        });
                        toastEvent.fire();
                        component.set('v.implementationChecklist.Anticipated_First_Run_Date_BiWeekly__c', '');
                    }
                }
            }
            if(fieldName == 'Anticipated_First_Run_Date_SemiMonthly__c'){
                var checkdate = component.get('v.implementationChecklist.Anticipated_First_Check_Date_SemiMonth__c');
                if(checkdate != null && checkdate != '' && checkdate != undefined){
                    if(fieldVal > checkdate){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Error',
                            message: 'The Anticipated First Run Date cannot be greater than the Anticipated First Check Date.',
                            duration:' 5000',
                            type: 'error',
                        });
                        toastEvent.fire();
                        component.set('v.implementationChecklist.Anticipated_First_Run_Date_SemiMonthly__c', '');
                    }
                }
            }
            if(fieldName == 'Anticipated_First_Run_Date_Monthly__c'){
                var checkdate = component.get('v.implementationChecklist.Anticipated_First_Check_Date_Monthly__c');
                if(checkdate != null && checkdate != '' && checkdate != undefined){
                    if(fieldVal > checkdate){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Error',
                            message: 'The Anticipated First Run Date cannot be greater than the Anticipated First Check Date.',
                            duration:' 5000',
                            type: 'error',
                        });
                        toastEvent.fire();
                        component.set('v.implementationChecklist.Anticipated_First_Run_Date_Monthly__c', '');
                    }
                }
            }
            if(fieldName == 'Did_the_client_have_prior_wages__c' && fieldVal != 'Yes'){
                component.set('v.implementationChecklist.Year_To_Date_payments_to_be_applied__c', null );
            }
            if(fieldName == 'Offer_a_PEO_Flexible_Spending_Account__c' && fieldVal != 'Yes'){
                component.set('v.implementationChecklist.Health_Flexible_Spending_Account__c', null );
                component.set('v.implementationChecklist.Dependent_Care_Flexible_Spending_Account__c', null );
            }
            if(fieldName == 'Client_offer_a_Health_Savings_Account__c' && fieldVal != 'Yes'){
                component.set('v.implementationChecklist.Employer_Contribution_HSA_Individual__c', null );
                component.set('v.implementationChecklist.Employer_Contribution_HSA_Family__c', null );
            }
            if(fieldName == 'Require_multiple_client_codes__c' && fieldVal != 'Yes'){
                component.set('v.implementationChecklist.Reason_for_multiple_client_codes__c', null );
            }
            if( fieldName ==  'Any_officers_of_company_earn_185K__c' && fieldVal != 'Yes'){
                component.set('v.implementationChecklist.Names_of_officers_of_company_earn_185K__c', null );
            }
            /* if( fieldName ==  'Any_individuals_who_earned_130k__c' && fieldVal != 'Yes'){
            component.set('v.implementationChecklist.Name_of_people_who_earn_130K__c', null );
        }*/
            if( fieldName ==  'Any_individuals_who_are_officers__c' && fieldVal != 'Yes'){
                component.set('v.implementationChecklist.Names_individuals_who_are_officers__c', null );
                component.set('v.implementationChecklist.Any_officers_of_company_earn_185K__c',null);
                component.set('v.implementationChecklist.Names_of_officers_of_company_earn_185K__c',null);
                
            }
            
            if(fieldName == 'Approved_to_self_retain_ancillary_prods__c' && fieldVal != 'Yes'){
                var tempList = [];
                component.set("v.implementationChecklist.Requesting_to_self_retail_ancillary_prod__c",null);
                component.set("v.selfRetainProductsValue",tempList);
                component.set("v.implementationChecklist.Self_retain_ancillary_products__c",null);
                
            }
            if(fieldName == 'Requesting_to_self_retail_ancillary_prod__c' && fieldVal != 'Yes'){
                var tempList = [];
                component.set("v.selfRetainProductsValue",tempList);
                component.set("v.implementationChecklist.Self_retain_ancillary_products__c",null);
                
            }
            if(fieldName == 'Self_retain_ancillary_products__c'){
                var fieldValACI = fieldVal;
                if(fieldValACI != null && fieldValACI != undefined && fieldValACI != ''){
                    console.log('fieldValACI::not null:'+fieldValACI);
                    component.set("v.implementationChecklist.Self_retain_ancillary_products__c",fieldValACI);
                    console.log('Self_retain_ancillary_products__c::'+component.get("v.implementationChecklist.Self_retain_ancillary_products__c"));
                }
                else{
                    console.log('in else::'+fieldValACI);
                }
            } 
            
            if( fieldName == 'Paychex_FlexTime__c'){
                // console.log('>>>>checkbox:: '+component.find("Paychex_FlexTime__c").getElement().checked);
                console.log('>>>>checkbox:checked: '+component.get("v.implementationChecklist.Paychex_FlexTime__c"));
                if(component.get("v.implementationChecklist.Paychex_FlexTime__c") == true){
                    component.set("v.implementationChecklist.Paychex_Flex_Time_Essentials__c",false);
                }
            }
            if( fieldName == 'Paychex_Flex_Time_Essentials__c'){
                console.log('>>>>Paychex_Flex_Time_Essentials__c checkbox:checked: '+component.get("v.implementationChecklist.Paychex_Flex_Time_Essentials__c"));
                if(component.get("v.implementationChecklist.Paychex_Flex_Time_Essentials__c") == true){
                    component.set("v.implementationChecklist.Paychex_FlexTime__c",false);
                }
                
            }
            
            if( fieldName == 'Flex_Onboarding__c'){
                console.log('>>>>checkbox:checked: '+component.get("v.implementationChecklist.Flex_Onboarding__c"));
                if(component.get("v.implementationChecklist.Flex_Onboarding__c") == true){
                    component.set("v.implementationChecklist.MyStaffingPro__c",false);
                    component.set("v.disableMyStaffingPro", false);
                }else{
                    component.set("v.implementationChecklist.E_verify_setup__c",false);
                    component.set("v.implementationChecklist.Flex_Hiring__c",false);
                }
            }
            if( fieldName == 'MyStaffingPro__c'){
                console.log('>>>>MyStaffingPro__c checkbox:checked: '+component.get("v.implementationChecklist.MyStaffingPro__c"));
                if(component.get("v.implementationChecklist.MyStaffingPro__c") == true){
                    component.set("v.implementationChecklist.Flex_Onboarding__c",false);
                    component.set("v.implementationChecklist.E_verify_setup__c",false);
                    component.set("v.implementationChecklist.Flex_Hiring__c",false);
                    component.set("v.disableMyStaffingPro", true);
                }
                else{
                    component.set("v.disableMyStaffingPro", false);
                }
            }
            if( fieldName == 'Own_5_of_the_company__c'){
                if(fieldVal != 'Yes'){
                    var tempData = [];
                    component.set("v.ownerRecs",tempData);
                    component.set("v.implementationChecklist.Users_own_5_of_company__c",null);
                }else{
                    let ownerRecs = [];
                    let ownerDetails = {"nameOfOwner":"", "percentageOfOwner":""};
                    let ownerObj = Object.assign({},ownerDetails);
                    ownerRecs.push(ownerObj);
                    component.set("v.ownerRecs",ownerRecs);
                }
            }
            if( fieldName == 'Own_2_of_the_company__c'){
                if(fieldVal != 'Yes'){
                    var tempData = [];
                    component.set("v.ownerRecs2percent",tempData);
                    component.set("v.implementationChecklist.Users_own_2_of_company__c",null);
                }else{
                    let ownerRecs = [];
                    let ownerDetails = {"nameOfOwner":"", "percentageOfOwner":""};
                    let ownerObj = Object.assign({},ownerDetails);
                    ownerRecs.push(ownerObj);
                    component.set("v.ownerRecs2percent",ownerRecs);
                }
            }
            if( fieldName == 'Own_1_of_the_company_earn_150k__c'){
                if(fieldVal != 'Yes'){
                    var tempData = [];
                    component.set("v.ownerRecsEarn150K",tempData);
                    component.set("v.implementationChecklist.Users_own_1_of_company_earn_150k__c",null);
                }else{
                    let ownerRecs = [];
                    let ownerDetails = {"nameOfOwner":"", "percentageOfOwner":""};
                    let ownerObj = Object.assign({},ownerDetails);
                    ownerRecs.push(ownerObj);
                    component.set("v.ownerRecsEarn150K",ownerRecs);
                }
            }
            if( fieldName == 'Any_employee_earned_130K_in_prior_year__c'){
                if(fieldVal != 'Yes'){
                    var tempData = [];
                    component.set("v.ownerRecsEarn130K",tempData);
                    component.set("v.implementationChecklist.User_earned_130K_in_prior_year__c",null);
                }else{
                    let ownerRecs = [];
                    let ownerDetails = {"nameOfOwner":"", "percentageOfOwner":""};
                    let ownerObj = Object.assign({},ownerDetails);
                    ownerRecs.push(ownerObj);
                    component.set("v.ownerRecsEarn130K",ownerRecs);
                }
            }
            if( fieldName == 'Is_the_Company_a_Partnership__c'){
                if(fieldVal != 'Yes'){
                    var tempData = [];
                    component.set("v.ownerRecsPartnership",tempData);
                    component.set("v.implementationChecklist.Partner_user_of_company__c",null);
                }
                else{
                    let ownerRecs = [];
                    let ownerDetails = {"nameOfOwner":"", "percentageOfOwner":""};
                    let ownerObj = Object.assign({},ownerDetails);
                    ownerRecs.push(ownerObj);
                    component.set("v.ownerRecsPartnership",ownerRecs);
                }
            }
            if( fieldName == 'Family_members_of_5_2_1_owners__c'){
                if(fieldVal != 'Yes'){
                    var tempData = [];
                    component.set("v.familyMemberRecs",tempData);
                    component.set("v.implementationChecklist.Name_of_members_of_5_2_1_owners__c",null);
                }else{
                    let ownerRecs = [];
                    let ownerDetails = {"familyMember":"", "nameOfOwner":"", "percentageOfOwner":""};
                    let ownerObj = Object.assign({},ownerDetails);
                    ownerRecs.push(ownerObj);
                    component.set("v.familyMemberRecs",ownerRecs);
                }
            }
            if(fieldName == 'ACI_Options__c'){
                var fieldValACI = fieldVal;
                if(fieldValACI != null && fieldValACI != undefined && fieldValACI != ''){
                    console.log('fieldValACI::not null:'+fieldValACI);
                    component.set("v.implementationChecklist.ACI_Options__c",fieldValACI);
                    console.log('ACI_Options__c::'+component.get("v.implementationChecklist.ACI_Options__c"));
                }
                else{
                    console.log('in else::'+fieldValACI);
                }
            }  
            if(fieldName == 'Client_currently_offer_a_401k_plan__c' && fieldVal != 'Yes'){
                
                component.set("v.implementationChecklist.Is_it_a_Paychex_401k__c",null);
            }
            
            if( fieldName == 'Any_individuals_who_are_officers__c'){
                if(fieldVal != 'Yes'){
                    var tempData = [];
                    component.set("v.officersRecs",tempData);
                    //component.set("v.implementationChecklist.User_earned_130K_in_prior_year__c",null);
                }else{
                    let officersRecs = [];
                    let officerDetails = {"nameOfOwner":""};
                    let officerObj = Object.assign({},officerDetails);
                    officersRecs.push(officerObj);
                    component.set("v.officersRecs",officersRecs);
                }
            }
            
            if( fieldName == 'Any_officers_of_company_earn_185K__c'){
                if(fieldVal != 'Yes'){
                    var tempData = [];
                    component.set("v.officersRecs185k",tempData);
                    //component.set("v.implementationChecklist.User_earned_130K_in_prior_year__c",null);
                }else{
                    let officersRecs185k = [];
                    let officerDetails = {"nameOfOwner":""};
                    let officerObj = Object.assign({},officerDetails);
                    officersRecs185k.push(officerObj);
                    component.set("v.officersRecs185k",officersRecs185k);
                }
            }
            //JDA S08
        }catch(e) {
            console.log(`Err PEOUWInternalQuestionsController.handleChange ${e}`)
        }
    },
    
    handleCheckboxChange: function(cmp, event, helper){
        if(cmp.get('v.implementationChecklist.Business_Owner_Same_as_Primary_Contact__c')){
            cmp.set('v.implementationChecklist.Primary_Contact_Name__c', cmp.get('v.implementationChecklist.Business_Owner_Name__c'));
            cmp.set('v.implementationChecklist.Primary_Contact_Email_address__c', cmp.get('v.implementationChecklist.Business_Owner_Email_address__c'));
            cmp.set('v.implementationChecklist.Primary_Contact_Title__c', cmp.get('v.implementationChecklist.Business_Owner_Title__c'));
        }else{
            cmp.set('v.implementationChecklist.Primary_Contact_Name__c', '');
            cmp.set('v.implementationChecklist.Primary_Contact_Email_address__c', '');
            cmp.set('v.implementationChecklist.Primary_Contact_Title__c', '');
        }
    },
    handleCheckboxChangeAuthorized: function(cmp, event, helper){
        if(cmp.get('v.implementationChecklist.Same_as_Authorized_Officer__c')){
            cmp.set('v.implementationChecklist.Business_Owner_Name__c', cmp.get('v.implementationChecklist.Authorized_Officer_Name__c'));
            cmp.set('v.implementationChecklist.Business_Owner_Title__c', cmp.get('v.implementationChecklist.Authorized_Officer_Title__c'));
        }else{
            cmp.set('v.implementationChecklist.Business_Owner_Name__c', '');
            cmp.set('v.implementationChecklist.Business_Owner_Title__c', '');
        }
    },
    
    handleDateChangeWeekly: function(cmp, event, helper){
        var fieldVal = event.getParam("value");
        var formattedDate = helper.handleDateChange(cmp, event, helper, fieldVal);
        cmp.set('v.implementationChecklist.Anticipated_First_Run_Date_Weekly__c', formattedDate);
    },
    
    handleDateChangeBiWeekly: function(cmp, event, helper){
        var fieldVal = event.getParam("value");
        var formattedDate = helper.handleDateChange(cmp, event, helper, fieldVal);
        cmp.set('v.implementationChecklist.Anticipated_First_Run_Date_BiWeekly__c', formattedDate);
    },
    
    handleDateChangeSemiMonthly: function(cmp, event, helper){
        var fieldVal = event.getParam("value");
        var formattedDate = helper.handleDateChange(cmp, event, helper, fieldVal);
        cmp.set('v.implementationChecklist.Anticipated_First_Run_Date_SemiMonthly__c', formattedDate);
    },
    
    handleDateChangeMonthly: function(cmp, event, helper){
        var fieldVal = event.getParam("value");
        var formattedDate = helper.handleDateChange(cmp, event, helper, fieldVal);
        cmp.set('v.implementationChecklist.Anticipated_First_Run_Date_Monthly__c', formattedDate);
    },
    
    formatDate: function(date){
        var d = new Date(date),
            month = '' + (d.getMonth() + 1),
            day = '' + d.getDate(),
            year = d.getFullYear();
        
        if (month.length < 2) 
            month = '0' + month;
        if (day.length < 2) 
            day = '0' + day;
        
        return [year, month, day].join('-');
    },
    
    
    showPopup: function(component, event, helper){
        if(component.get('v.implementationChecklist.ACI__c')){
            component.set('v.showAdditionalFee', true);
        }else{
            component.set('v.showAdditionalFee', false);
            var tempList = [];
            component.set("v.ACIOptionsValue",tempList);
            component.set("v.implementationChecklist.ACI_Options__c",null);
        }
        
    },
    
    closePopup: function(component, event, helper){
        component.set('v.showAdditionalFee', false);
    },
    
    handleMemberChange: function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.getSource().get('v.name'));
        var ownerRecs = cmp.get("v.familyMemberRecs");
        let userInput = e.getSource().get('v.value');
        ownerRecs[ownerRecIndex].familyMember = userInput;
        cmp.set("v.familyMemberRecs",ownerRecs);
        var tempData = cmp.get("v.familyMemberRecs");
        console.log('>>>>>familyMemberRecs line 164::'+JSON.stringify(cmp.get("v.familyMemberRecs")));
        
        if(tempData != null){
            var strName = '';
            var finalStr = '';
            for(var i =0 ; i< tempData.length ;i++){
                if(tempData[i].nameOfOwner != undefined && tempData[i].familyMember  != undefined && tempData[i].percentageOfOwner != undefined && 
                   tempData[i].nameOfOwner != '' && tempData[i].familyMember  != '' && tempData[i].percentageOfOwner != ''){
                    strName = tempData[i].familyMember +'|' + tempData[i].nameOfOwner +'|' + tempData[i].percentageOfOwner ;
                    finalStr = strName +';'+finalStr ;
                }
            }
            console.log('>>>>>>finalStr:::'+finalStr);
            cmp.set("v.implementationChecklist.Name_of_members_of_5_2_1_owners__c",finalStr);
            if(cmp.get("v.isParentAccount") == true){
                var parentData = cmp.get("v.implementationChecklist");
                console.log('>>>>parentData::'+JSON.stringify(parentData));
                var appEvent = $A.get("e.c:PEOImpCopyToChildren");
                appEvent.setParams({"implementationChecklist":parentData});
                appEvent.fire();
            }
        }
        
        // Name_of_members_of_5_2_1_owners__c
    },        
    
    handleOwnerChange : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.getSource().get('v.name'));
        var whichOne = e.getSource().getLocalId();
        var ownerRecs;
        switch(whichOne){
            case 'ownerRecs':
                ownerRecs = cmp.get("v.ownerRecs");
                break;
            case 'ownerRecs':
                ownerRecs = cmp.get("v.ownerRecs");
                break;
            case 'ownerRecs2percent':
                ownerRecs = cmp.get("v.ownerRecs2percent");
                break;
            case 'ownerRecsPartnership':
                ownerRecs = cmp.get("v.ownerRecsPartnership");
                break;
            case 'ownerRecsEarn130K':
                ownerRecs = cmp.get("v.ownerRecsEarn130K");
                break;
            case 'ownerRecsEarn150K':
                ownerRecs = cmp.get("v.ownerRecsEarn150K");
                break;
            case 'familyMemberRecs':
                ownerRecs = cmp.get("v.familyMemberRecs");
                break;
            case 'officersRecs':
                ownerRecs = cmp.get("v.officersRecs");
                break;
            case 'officersRecs185k':
                ownerRecs = cmp.get("v.officersRecs185k");
                break;
        }
        
        let userInput = e.getSource().get('v.value');
        // ownerRecs[ownerRecIndex].familyMember = userInput;
        ownerRecs[ownerRecIndex].nameOfOwner = userInput;
        switch(whichOne){
            case 'ownerRecs':
                cmp.set("v.ownerRecs",ownerRecs);
                break;
            case 'ownerRecs2percent':
                cmp.set("v.ownerRecs2percent",ownerRecs);
                break;
            case 'ownerRecsEarn150K':
                cmp.set("v.ownerRecsEarn150K",ownerRecs);
                break;
            case 'ownerRecsEarn130K':
                cmp.set("v.ownerRecsEarn130K",ownerRecs);
                break;
            case 'ownerRecsPartnership':
                cmp.set("v.ownerRecsPartnership",ownerRecs);
                break;
            case 'familyMemberRecs':
                cmp.set("v.familyMemberRecs",ownerRecs);
                break;
            case 'officersRecs':
                cmp.set("v.officersRecs",ownerRecs);
                break;
            case 'officersRecs185k':
                cmp.set("v.officersRecs185k",ownerRecs);
                break;
        }
        
        console.log('>>>>>familyMemberRecs 213::  '+JSON.stringify(cmp.get("v.familyMemberRecs")));
        var tempData = cmp.get("v.familyMemberRecs");
        if(tempData != null){
            var strName = '';
            var finalStr = '';
            for(var i =0 ; i< tempData.length ;i++){
                if(tempData[i].nameOfOwner != undefined && tempData[i].familyMember  != undefined 
                   && tempData[i].percentageOfOwner != undefined && 
                   tempData[i].nameOfOwner != '' && tempData[i].familyMember  != '' 
                   && tempData[i].percentageOfOwner != ''){
                    strName = tempData[i].familyMember +'|'+ tempData[i].nameOfOwner +'|' + tempData[i].percentageOfOwner ;
                    finalStr = strName +';'+finalStr ;
                }
            }
            console.log('>>>>>>finalStr:::'+finalStr);
            cmp.set("v.implementationChecklist.Name_of_members_of_5_2_1_owners__c",finalStr);
        }
        var tempData150 = cmp.get("v.ownerRecsEarn150K");
        if(tempData150 != null){
            var strName150 = '';
            var finalStr150 = '';
            for(var i =0 ; i< tempData150.length ;i++){
                if(tempData150[i].nameOfOwner != undefined && tempData150[i].percentageOfOwner != undefined && 
                   tempData150[i].nameOfOwner != '' && tempData150[i].percentageOfOwner != ''){
                    strName150 = tempData150[i].nameOfOwner +'|'+tempData150[i].percentageOfOwner ;
                    finalStr150 = strName150 +';'+finalStr150 ;
                }
            }
            console.log('>>>>>>finalStr150 ownerRecsEarn150K:::'+finalStr150);
            cmp.set("v.implementationChecklist.Users_own_1_of_company_earn_150k__c",finalStr150);
        }
        var tempData130 = cmp.get("v.ownerRecsEarn130K");
        if(tempData130 != null){
            var strName150 = '';
            var finalStr150 = '';
            for(var i =0 ; i< tempData130.length ;i++){
                if(tempData130[i].nameOfOwner != undefined && tempData130[i].nameOfOwner != ''){
                    strName150 = tempData130[i].nameOfOwner;
                    finalStr150 = strName150 +';'+finalStr150 ;
                }
            }
            console.log('>>>>>>finalStr150 ownerRecsEarn130K:::'+finalStr150);
            cmp.set("v.implementationChecklist.User_earned_130K_in_prior_year__c",finalStr150);
        }
        var tempDataPartner = cmp.get("v.ownerRecsPartnership");
        if(tempDataPartner != null){
            var strName150 = '';
            var finalStr150 = '';
            for(var i =0 ; i< tempDataPartner.length ;i++){
                if(tempDataPartner[i].nameOfOwner != undefined && tempDataPartner[i].percentageOfOwner != undefined && 
                   tempDataPartner[i].nameOfOwner != '' && tempDataPartner[i].percentageOfOwner != ''){
                    strName150 = tempDataPartner[i].nameOfOwner +'|'+tempDataPartner[i].percentageOfOwner ;
                    finalStr150 = strName150 +';'+finalStr150 ;
                }
            }
            console.log('>>>>>>finalStr150 ownerRecsPartnership:::'+finalStr150);
            cmp.set("v.implementationChecklist.Partner_user_of_company__c",finalStr150);
        }
        var tempData5 = cmp.get("v.ownerRecs");
        if(tempData5 != null){
            var strName5 = '';
            var finalStr5 = '';
            for(var i =0 ; i< tempData5.length ;i++){
                if(tempData5[i].nameOfOwner != undefined && tempData5[i].percentageOfOwner != undefined && 
                   tempData5[i].nameOfOwner != '' && tempData5[i].percentageOfOwner != ''){
                    strName5 = tempData5[i].nameOfOwner +'|'+tempData5[i].percentageOfOwner ;
                    finalStr5 = strName5 +';'+finalStr5 ;
                }
                
            }
            console.log('>>>>>>finalStr5 ownerRecs:::'+finalStr5);
            cmp.set("v.implementationChecklist.Users_own_5_of_company__c",finalStr5);
        }
        var tempData2 = cmp.get("v.ownerRecs2percent");
        if(tempData2 != null){
            var strName2 = '';
            var finalStr2 = '';
            for(var i =0 ; i< tempData2.length ;i++){
                if(tempData2[i].nameOfOwner != undefined && tempData2[i].percentageOfOwner != undefined && 
                    tempData2[i].nameOfOwner != '' && tempData2[i].percentageOfOwner != ''){
                    strName5 = tempData2[i].nameOfOwner +'|'+tempData2[i].percentageOfOwner ;
                    finalStr5 = strName5 +';'+finalStr5 ;
                }
                
            }
            console.log('>>>>>>finalStr5 ownerRecs:::'+finalStr5);
            cmp.set("v.implementationChecklist.Users_own_2_of_company__c",finalStr5);
        }
        
        //s08
        var tempDataOfficer = cmp.get("v.officersRecs");
        if(tempDataOfficer != null){
            var strNameOfcr = '';
            var finalStrOfcr = '';
            for(var i =0 ; i< tempDataOfficer.length ;i++){
                if(tempDataOfficer[i].nameOfOwner != undefined && tempDataOfficer[i].nameOfOwner != ''){
                    //strName5 = tempData2[i].nameOfOwner +'|'+tempData2[i].percentageOfOwner ;
                    strNameOfcr = tempDataOfficer[i].nameOfOwner
                    finalStrOfcr = strNameOfcr +';'+finalStrOfcr ;
                }
                
            }
            console.log('>>>>>>finalStr5 tempDataOfficer:::'+finalStrOfcr);
            cmp.set("v.implementationChecklist.Names_individuals_who_are_officers__c",finalStrOfcr);
        }
        var tempDataOfficer185 = cmp.get("v.officersRecs185k");
        if(tempDataOfficer185 != null){
            var strNameOfcr185 = '';
            var finalStrOfcr185 = '';
            for(var i =0 ; i< tempDataOfficer185.length ;i++){
                if(tempDataOfficer185[i].nameOfOwner != undefined && tempDataOfficer185[i].nameOfOwner != ''){
                    //strName5 = tempData2[i].nameOfOwner +'|'+tempData2[i].percentageOfOwner ;
                    strNameOfcr185 = tempDataOfficer185[i].nameOfOwner
                    finalStrOfcr185 = strNameOfcr185 +';'+finalStrOfcr185 ;
                }
                
            }
            console.log('>>>>>>finalStrOfcr185 tempDataOfficer:::'+finalStrOfcr185);
            cmp.set("v.implementationChecklist.Names_of_officers_of_company_earn_185K__c",finalStrOfcr185);
        }
        //s08 
        if(cmp.get("v.isParentAccount") == true){
            var parentData = cmp.get("v.implementationChecklist");
            console.log('>>>>parentData::'+JSON.stringify(parentData));
            var appEvent = $A.get("e.c:PEOImpCopyToChildren");
            appEvent.setParams({"implementationChecklist":parentData});
            appEvent.fire();
        }
    },
    
    calculatePercentOwnership : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.getSource().get('v.name'));
        var whichOne = e.getSource().getLocalId();
        var ownerRecs;
        switch(whichOne){
            case 'ownerRecs':
                ownerRecs = cmp.get("v.ownerRecs");
                break;
            case 'ownerRecsEarn150K':
                ownerRecs = cmp.get("v.ownerRecsEarn150K");
                break;
                case 'ownerRecsEarn130K':
                ownerRecs = cmp.get("v.ownerRecsEarn130K");
                break;
                case 'ownerRecsPartnership':
                ownerRecs = cmp.get("v.ownerRecsPartnership");
                break;
                case 'ownerRecs2percent':
                ownerRecs = cmp.get("v.ownerRecs2percent");
                break;
            case 'familyMemberRecs':
                ownerRecs = cmp.get("v.familyMemberRecs");
                break;
        }
        let userInput = e.getSource().get('v.value');
        ownerRecs[ownerRecIndex].percentageOfOwner = userInput;
        switch(whichOne){
            case 'ownerRecs':
                cmp.set("v.ownerRecs",ownerRecs);
                break;
            case 'ownerRecs2percent':
                cmp.set("v.ownerRecs2percent",ownerRecs);
                break;
                case 'ownerRecsEarn150K':
                cmp.set("v.ownerRecsEarn150K",ownerRecs);
                break;
                /*case 'ownerRecsEarn130K':
                    cmp.set("v.ownerRecsEarn130K",ownerRecs);
                    break;*/
                    case 'ownerRecsPartnership':
                        cmp.set("v.ownerRecsPartnership",ownerRecs);
                        break;
            case 'familyMemberRecs':
                cmp.set("v.familyMemberRecs",ownerRecs);
                break;
        }
        console.log('>>>>>familyMemberRecs 257::  '+JSON.stringify(cmp.get("v.familyMemberRecs")));
        var tempData = cmp.get("v.familyMemberRecs");
        
        
        if(tempData != null){
            var strName = '';
            var finalStr = '';
            for(var i =0 ; i< tempData.length ;i++){
                if(tempData[i].nameOfOwner != undefined && tempData[i].familyMember  != undefined && tempData[i].percentageOfOwner != undefined &&
                   tempData[i].nameOfOwner != '' && tempData[i].familyMember  != '' && tempData[i].percentageOfOwner != ''){
                    strName = tempData[i].familyMember + '|' + tempData[i].nameOfOwner +'|'+tempData[i].percentageOfOwner ;
                    finalStr = strName +';'+finalStr ;
                }
            }
            console.log('>>>>>>finalStr:::'+finalStr);
            cmp.set("v.implementationChecklist.Name_of_members_of_5_2_1_owners__c",finalStr);
        }
        var tempData150 = cmp.get("v.ownerRecsEarn150K");
        if(tempData150 != null){
            var strName150 = '';
            var finalStr150 = '';
            for(var i =0 ; i< tempData150.length ;i++){
                if(tempData150[i].nameOfOwner != undefined && tempData150[i].percentageOfOwner != undefined &&
                   tempData150[i].nameOfOwner != '' && tempData150[i].percentageOfOwner != ''){
                    strName150 = tempData150[i].nameOfOwner +'|'+tempData150[i].percentageOfOwner ;
                    finalStr150 = strName150 +';'+finalStr150 ;
                }
            }
            console.log('>>>>>>finalStr150 ownerRecsEarn150K:::'+finalStr150);
            cmp.set("v.implementationChecklist.Users_own_1_of_company_earn_150k__c",finalStr150);
        }
        /*var tempData130 = cmp.get("v.ownerRecsEarn130K");
        if(tempData130 != null){
            var strName150 = '';
            var finalStr150 = '';
            for(var i =0 ; i< tempData130.length ;i++){
                if(tempData130[i].nameOfOwner != undefined && tempData130[i].percentageOfOwner != undefined &&
                   tempData130[i].nameOfOwner != '' && tempData130[i].percentageOfOwner != ''){
                    strName150 = tempData130[i].nameOfOwner +'|'+tempData130[i].percentageOfOwner ;
                    finalStr150 = strName150 +';'+finalStr150 ;
                }
            }
            console.log('>>>>>>finalStr150 ownerRecsEarn130K:::'+finalStr150);
            cmp.set("v.implementationChecklist.User_earned_130K_in_prior_year__c",finalStr150);
        }*/
        var tempDataPartner = cmp.get("v.ownerRecsPartnership");
        if(tempDataPartner != null){
            var strName150 = '';
            var finalStr150 = '';
            let totalper=0;
            for(var i =0 ; i< tempDataPartner.length ;i++){
                if(tempDataPartner[i].nameOfOwner != undefined && tempDataPartner[i].percentageOfOwner != undefined 
                   && tempDataPartner[i].nameOfOwner != '' && tempDataPartner[i].percentageOfOwner != ''){
                    strName150 = tempDataPartner[i].nameOfOwner +'|'+tempDataPartner[i].percentageOfOwner ;
                    finalStr150 = strName150 +';'+finalStr150 ;                    
                }
                if(tempDataPartner[i].percentageOfOwner != '' 
                   && tempDataPartner[i].percentageOfOwner != undefined)
                {
                    totalper = totalper + parseFloat(tempDataPartner[i].percentageOfOwner);
                }
            }
            //console.log('>>>>>>finalStr150 ownerRecsPartnership:::'+finalStr150);
            cmp.set("v.implementationChecklist.Partner_user_of_company__c",finalStr150);
            cmp.set("v.ownerRecsPartnershipTotal",totalper);
        }

        var tempData5 = cmp.get("v.ownerRecs");
        if(tempData5 != null){
            var strName5 = '';
            var finalStr5 = '';
            for(var i =0 ; i< tempData5.length ;i++){
                if(tempData5[i].nameOfOwner != undefined && tempData5[i].percentageOfOwner != undefined &&
                   tempData5[i].nameOfOwner != '' && tempData5[i].percentageOfOwner != ''){
                    strName5 = tempData5[i].nameOfOwner +'|'+tempData5[i].percentageOfOwner ;
                    finalStr5 = strName5 +';'+finalStr5 ;
                }
            }
            console.log('>>>>>>finalStr5 ownerRecs:::'+finalStr5);
            cmp.set("v.implementationChecklist.Users_own_5_of_company__c",finalStr5);
        }
        var tempData2 = cmp.get("v.ownerRecs2percent");
        if(tempData2 != null){
            var strName2 = '';
            var finalStr2 = '';
            for(var i =0 ; i< tempData2.length ;i++){
                if(tempData2[i].nameOfOwner != undefined && tempData2[i].percentageOfOwner != undefined &&
                    tempData2[i].nameOfOwner != '' && tempData2[i].percentageOfOwner != ''){
                        strName2 = tempData2[i].nameOfOwner +'|'+tempData2[i].percentageOfOwner ;
                    finalStr2 = strName2 +';'+finalStr2 ;
                }
            }
            console.log('>>>>>>finalStr2 ownerRecs:::'+finalStr2);
            cmp.set("v.implementationChecklist.Users_own_2_of_company__c",finalStr2);
        }
        if(cmp.get("v.isParentAccount") == true){
            var parentData = cmp.get("v.implementationChecklist");
            console.log('>>>>parentData::'+JSON.stringify(parentData));
            var appEvent = $A.get("e.c:PEOImpCopyToChildren");
            appEvent.setParams({"implementationChecklist":parentData});
            appEvent.fire();
        }
    },
    
    //s08
    removeNameRow : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.target.name);
        let ownerRecs = cmp.get("v.officersRecs");
        ownerRecs.splice(ownerRecIndex, 1);
        cmp.set("v.officersRecs",ownerRecs);
        var tempData5 = cmp.get("v.officersRecs");
        if(tempData5 != null){
            var strName5 = '';
            var finalStr5 = '';
            for(var i =0 ; i< tempData5.length ;i++){
                if(tempData5[i].nameOfOwner != undefined){
                    strName5 = tempData5[i].nameOfOwner;
                    finalStr5 = strName5 +';'+finalStr5 ;
                }
            }
            console.log('>>>>>>finalStr5 ownerRecs:::'+finalStr5);
            cmp.set("v.implementationChecklist.Names_individuals_who_are_officers__c",finalStr5);
        }
    },
    
    removeNameRow185K : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.target.name);
        let ownerRecs = cmp.get("v.officersRecs185k");
        ownerRecs.splice(ownerRecIndex, 1);
        cmp.set("v.officersRecs185k",ownerRecs);
        var tempData5 = cmp.get("v.officersRecs185k");
        if(tempData5 != null){
            var strName5 = '';
            var finalStr5 = '';
            for(var i =0 ; i< tempData5.length ;i++){
                if(tempData5[i].nameOfOwner != undefined){
                    strName5 = tempData5[i].nameOfOwner;
                    finalStr5 = strName5 +';'+finalStr5 ;
                }
            }
            console.log('>>>>>>finalStr5 ownerRecs:::'+finalStr5);
            cmp.set("v.implementationChecklist.Names_of_officers_of_company_earn_185K__c",finalStr5);
        }
    },
    //s08
    
    removeRow : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.target.name);
        let ownerRecs = cmp.get("v.ownerRecs");
        ownerRecs.splice(ownerRecIndex, 1);
        cmp.set("v.ownerRecs",ownerRecs);
        let button = cmp.find('ownerRecsButton');
        button.set('v.disabled',false);
        var tempData5 = cmp.get("v.ownerRecs");
        if(tempData5 != null){
            var strName5 = '';
            var finalStr5 = '';
            for(var i =0 ; i< tempData5.length ;i++){
                if(tempData5[i].nameOfOwner != undefined && tempData5[i].percentageOfOwner != undefined){
                    strName5 = tempData5[i].nameOfOwner +'|'+tempData5[i].percentageOfOwner ;
                    finalStr5 = strName5 +';'+finalStr5 ;
                }
            }
            console.log('>>>>>>finalStr5 ownerRecs:::'+finalStr5);
            cmp.set("v.implementationChecklist.Users_own_5_of_company__c",finalStr5);
        }
    },
    
    removeRow2percent : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.target.name);
        let ownerRecs = cmp.get("v.ownerRecs2percent");
        ownerRecs.splice(ownerRecIndex, 1);
        cmp.set("v.ownerRecs2percent",ownerRecs);
        let button = cmp.find('ownerRecs2percentButton');
        button.set('v.disabled',false);
        var tempData2 = cmp.get("v.ownerRecs2percent");
        if(tempData2 != null){
            var strName2 = '';
            var finalStr2 = '';
            for(var i =0 ; i< tempData2.length ;i++){
                if(tempData2[i].nameOfOwner != undefined && tempData2[i].percentageOfOwner != undefined){
                    strName2 = tempData2[i].nameOfOwner +'|'+tempData2[i].percentageOfOwner ;
                    finalStr2 = strName2 +';'+finalStr2 ;
                }
            }
            console.log('>>>>>>finalStr2 ownerRecs2percent:::'+finalStr2);
            cmp.set("v.implementationChecklist.Users_own_2_of_company__c",finalStr2);
        }
    },
    
    removeRow150K : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.target.name);
        let ownerRecs = cmp.get("v.ownerRecsEarn150K");
        ownerRecs.splice(ownerRecIndex, 1);
        cmp.set("v.ownerRecsEarn150K",ownerRecs);
        let button = cmp.find('ownerRecsEarn150KButton');
        button.set('v.disabled',false);
        var tempData150 = cmp.get("v.ownerRecsEarn150K");
        if(tempData150 != null){
            var strName150 = '';
            var finalStr150 = '';
            for(var i =0 ; i< tempData150.length ;i++){
                if(tempData150[i].nameOfOwner != undefined && tempData150[i].percentageOfOwner != undefined){
                    strName150 = tempData150[i].nameOfOwner +'|'+tempData150[i].percentageOfOwner ;
                    finalStr150 = strName150 +';'+finalStr150 ;
                }
            }
            console.log('>>>>>>finalStr150 ownerRecsEarn150K:::'+finalStr150);
            cmp.set("v.implementationChecklist.Users_own_1_of_company_earn_150k__c",finalStr150);
        }
    },
    removeRow130K : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.target.name);
        let ownerRecs = cmp.get("v.ownerRecsEarn130K");
        ownerRecs.splice(ownerRecIndex, 1);
        cmp.set("v.ownerRecsEarn130K",ownerRecs);
        let button = cmp.find('ownerRecsEarn130KButton');
        button.set('v.disabled',false);
        var tempData150 = cmp.get("v.ownerRecsEarn130K");
        if(tempData150 != null){
            var strName150 = '';
            var finalStr150 = '';
            for(var i =0 ; i< tempData150.length ;i++){
                if(tempData150[i].nameOfOwner != undefined){
                    strName150 = tempData150[i].nameOfOwner;
                    finalStr150 = strName150 +';'+finalStr150 ;
                }
            }
            console.log('>>>>>>finalStr150 ownerRecsEarn130K:::'+finalStr150);
            cmp.set("v.implementationChecklist.User_earned_130K_in_prior_year__c",finalStr150);
        }
    },
    removeRowPartnership : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.target.name);
        let totalper=0;
        let ownerRecs = cmp.get("v.ownerRecsPartnership");
        ownerRecs.splice(ownerRecIndex, 1);
        cmp.set("v.ownerRecsPartnership",ownerRecs);
        let button = cmp.find('ownerRecsPartnershipButton');
        button.set('v.disabled',false);
        var tempData150 = cmp.get("v.ownerRecsPartnership");
        if(tempData150 != null){
            var strName150 = '';
            var finalStr150 = '';
            for(var i =0 ; i< tempData150.length ;i++){
                if(tempData150[i].nameOfOwner != undefined && tempData150[i].percentageOfOwner != undefined){
                    strName150 = tempData150[i].nameOfOwner +'|'+tempData150[i].percentageOfOwner ;
                    finalStr150 = strName150 +';'+finalStr150 ;
                    
                }
                if(tempData150[i].percentageOfOwner!= '' 
                   && tempData150[i].percentageOfOwner != undefined)
                {
                    totalper+= parseFloat(tempData150[i].percentageOfOwner);
                }
            }
            //console.log('>>>>>>finalStr150 ownerRecsPartnership:::'+finalStr150);
            cmp.set("v.implementationChecklist.Partner_user_of_company__c",finalStr150);
            cmp.set("v.ownerRecsPartnershipTotal",totalper);
        }
    },
    
    removeRowFamilyMember : function(cmp, e, helper) {
        let ownerRecIndex = parseInt(e.target.name);
        let ownerRecs = cmp.get("v.familyMemberRecs");
        ownerRecs.splice(ownerRecIndex, 1);
        cmp.set("v.familyMemberRecs",ownerRecs);
        let button = cmp.find('familyMemberRecsButton');
        button.set('v.disabled',false);
        console.log('>>>>>familyMemberRecs 269::  '+JSON.stringify(cmp.get("v.familyMemberRecs")));
        var tempData = cmp.get("v.familyMemberRecs");
        
        if(tempData != null){
            var strName = '';
            var finalStr = '';
            for(var i =0 ; i< tempData.length ;i++){
                if(tempData[i].nameOfOwner != undefined && tempData[i].familyMember  != undefined && tempData[i].percentageOfOwner != undefined){
                    strName = tempData[i].nameOfOwner +'|' +tempData[i].familyMember +'|'+tempData[i].percentageOfOwner ;
                    finalStr = strName +';'+finalStr ;
                }
            }
            console.log('>>>>>>finalStr:::'+finalStr);
            cmp.set("v.implementationChecklist.Name_of_members_of_5_2_1_owners__c",finalStr);
        }
    },
    
    addNewOwner : function(cmp, e, helper) {
        var whichOne = e.getSource().getLocalId();
        var ownerRecs;
        switch(whichOne){
            case 'ownerRecsButton':
                ownerRecs = cmp.get("v.ownerRecs");
                break;
            case 'ownerRecs2percentButton':
                ownerRecs = cmp.get("v.ownerRecs2percent");
                break;
            case 'ownerRecsEarn150KButton':
                ownerRecs = cmp.get("v.ownerRecsEarn150K");
                break;
            case 'ownerRecsEarn130KButton':
                ownerRecs = cmp.get("v.ownerRecsEarn130K");
                break;
            case 'ownerRecsPartnershipButton':
                ownerRecs = cmp.get("v.ownerRecsPartnership");
                break;
            case 'familyMemberRecsButton':
                ownerRecs = cmp.get("v.familyMemberRecs");
                break;
        }
        if(ownerRecs.length == 10){
            var button = e.getSource();
            button.set('v.disabled',true);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: 'Error',
                message: 'Reached max rows',
                type: 'ERROR'
            });
            toastEvent.fire();
        }else{
            let ownerDetails = {nameOfOwner:"", percentageOfOwner:""};
            ownerRecs.push(Object.assign({},ownerDetails));
            switch(whichOne){
                case 'ownerRecsButton':
                    cmp.set("v.ownerRecs",ownerRecs);
                    break;
                case 'ownerRecs2percentButton':
                    cmp.set("v.ownerRecs2percent",ownerRecs);
                    break;
                case 'ownerRecsEarn150KButton':
                    cmp.set("v.ownerRecsEarn150K",ownerRecs);
                    break;
                case 'ownerRecsEarn130KButton':
                    cmp.set("v.ownerRecsEarn130K",ownerRecs);
                    break;
                case 'ownerRecsPartnershipButton':
                    cmp.set("v.ownerRecsPartnership",ownerRecs);
                    break;
                case 'familyMemberRecsButton':
                    cmp.set("v.familyMemberRecs",ownerRecs);
                    break;
            }
        }
        
    },
    
    //JDA S08
    
    addNewName : function(cmp, e, helper) {
        //debugger;
        var whichOne = e.getSource().getLocalId();
        var officersRecs;
        switch(whichOne){
            case 'officersRecs':
                officersRecs = cmp.get("v.officersRecs");
                break;
            case 'officersRecs185k':
                officersRecs = cmp.get("v.officersRecs185k");
                break;
        }
        let officerDetails = {nameOfOwner:""};
        officersRecs.push(Object.assign({},officerDetails));
        switch(whichOne){
            case 'officersRecs':
                cmp.set("v.officersRecs",officersRecs);
                break;
            case 'officersRecs185k':
                cmp.set("v.officersRecs185k",officersRecs);
                break;
        }
    },
    
    
    handleTabChange: function(component, event, helper) {
     
    
    },
    save: function(component, event, helper) {
        component.set("v.isLoading",true);
         helper.checkValidity(component, event, helper);
        
            window.setTimeout(
             $A.getCallback(function() {
                 helper.saveImplementationQuestions(component, event, helper); 
             }), 3000
                );
       // helper.saveImplementationQuestions(component, event, helper); 
      
    },
    handleNext: function(component, event, helper) {
        var tab = component.get("v.selectedTab");
        if(tab == 'General Submission Information'){
            helper.checkValidity(component, event, helper);
            window.setTimeout(
             $A.getCallback(function() {
                 helper.saveImplementationQuestions(component, event, helper); 
             }), 3000
         );
        
            component.set("v.selectedTab","Setup Information");
        } 
        else if(tab == 'Setup Information'){
            helper.checkValidity(component, event, helper);
             window.setTimeout(
             $A.getCallback(function() {
                 helper.saveImplementationQuestions(component, event, helper); 
             }), 3000
         );
        
            component.set("v.selectedTab","Compliance");
        }
            else if(tab == 'Compliance'){
                helper.checkValidity(component, event, helper);
                 window.setTimeout(
             $A.getCallback(function() {
                 helper.saveImplementationQuestions(component, event, helper); 
             }), 3000
         );
        
                component.set("v.selectedTab","COBRA");
            }
                else if(tab == 'COBRA'){
                    helper.checkValidity(component, event, helper);
                     window.setTimeout(
             $A.getCallback(function() {
                 helper.saveImplementationQuestions(component, event, helper); 
             }), 3000
         );
        
                    component.set("v.selectedTab","General Submission Information");
                }
        
    },
   
    finalize: function(component, event, helper) {
        // alert('finalize calling');
        console.log('>>>called finalize:peoChecklist: '+JSON.stringify(component.get('v.peoChecklist')));
        console.log('>>>peoChecklistcCS_CM_Contract_Status__c:: '+component.get('v.peoChecklist').CS_CM_Contract_Status__c);
        //if(component.get('v.peoChecklist') != null && component.get('v.peoChecklist') != undefined){
        if(component.get('v.peoChecklist').CS_CM_Contract_Status__c == undefined ||
           component.get('v.peoChecklist').CS_CM_Contract_Status__c != 'Approved'){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: 'Error',
                message: 'CS CM Contract Status needs to be Approved in order to finalize the questions!',
                type: 'ERROR'
            });
            toastEvent.fire();
        }
        else{
            console.log('>>>showCommunityUserInfo line 468 '+component.get('v.showCommunityUserInfo'));
            component.set('v.showCommunityUserInfo', true);
            console.log('>>>showCommunityUserInfo line 470 '+component.get('v.showCommunityUserInfo'));
        }             
    },
    
    getToggleButtonValue: function(component, event, helper) {
        var checkToggle = component.find("tglbtn").get("v.checked");
        if(checkToggle){
            component.set('v.buttonText', 'Send Notification');
        }else{
            component.set('v.buttonText', 'Confirm without notifying the client');
        }
    }
})