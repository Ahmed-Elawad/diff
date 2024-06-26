({
    getImplementationChecklistData : function(component, event, helper) {
        console.log("Inside getImplementationChecklistData");
        var getImplChecklist = component.get('c.getPEOImplementationChecklistResponse');
        var implChecklist = component.get('v.implChecklists');
        console.log("accId:"+component.get('v.currentAccount').Id);
        console.log("parentAccountId:"+component.get('v.ParentAccountId'));
        getImplChecklist.setParams({
            accId: component.get('v.currentAccount').Id,
            parentAccountId: component.get('v.ParentAccountId')
        });
        
        getImplChecklist.setCallback(this, function(res) {
            component.set("v.isLoading",false);
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError());
            }else{
                let data = res.getReturnValue();
                if(data != null){
                    if(data.implChecklist != undefined){
                        if(component.get("v.isParentAccount") == true){
                            var parentData = data.implChecklist;
                            console.log('>>>>parentData::'+JSON.stringify(parentData));
                            var appEvent = $A.get("e.c:PEOImpCopyToChildren");
                            appEvent.setParams({"implementationChecklist":parentData});
                            appEvent.fire();
                        }
                        if(data.implChecklist.Self_retain_ancillary_products__c != null &&
                           (data.implChecklist.Self_retain_ancillary_products__c == 'Life' ||
                            data.implChecklist.Self_retain_ancillary_products__c == 'STD' ||
                            data.implChecklist.Self_retain_ancillary_products__c == 'LTD' ||
                            data.implChecklist.Self_retain_ancillary_products__c == 'Voluntary Benefits')){
                            data.implChecklist.Self_retain_ancillary_products__c = 'MetLife Voluntary';
                        }
                        console.log('>>>>implChecklist Data::');
                        console.log(data.implChecklist);
                        component.set('v.implementationChecklist', data.implChecklist);
                        //SPA: US8:start
                        var businessEntityVal = component.get("v.implementationChecklist.Business_Entity_Type__c");	
                        component.set("v.businessEntityVal", component.get("v.implementationChecklist.Business_Entity_Type__c"));	
                        //alert('>>businessEntityVal: '+businessEntityVal);	
                        if(businessEntityVal == 'Partnership' || businessEntityVal == 'Limited Liability Partnership'
                           || businessEntityVal == 'Sole Proprietor' 
                           || businessEntityVal == 'LLC taxed as a partnership' 
                           || businessEntityVal == 'LLC taxed as a sole proprietorship'){	
                            component.set('v.isBusinessEntityTypePartner', true);	
                            component.set('v.implementationChecklist.Is_the_Company_a_Partnership__c', 'Yes');	
                        }	
                        else{	
                            component.set('v.isBusinessEntityTypePartner', false);	
                        }
                        if(businessEntityVal=='Sole Proprietor' 
                           || businessEntityVal=='LLC taxed as a sole proprietorship'){
                            component.set('v.disableAddPartners', true);
                        }
                        if(businessEntityVal == 'Partnership' || businessEntityVal == 'Limited Liability Partnership'               
                           || businessEntityVal == 'LLC taxed as a partnership' ){
                            component.set('v.PartnersDelete', 2);
                        }
                        if(businessEntityVal=='S Corporation' || businessEntityVal=='LLC taxed as a S-Corp'){
                            component.set('v.scorpreadonly', true);  
                            //component.set('v.implementationChecklist.Family_members_of_5_2_1_owners__c', 'Yes');	                
                            component.set('v.implementationChecklist.Own_2_of_the_company__c', 'Yes');	
                        }
                        if(businessEntityVal=='LLC taxed as a corporation' || businessEntityVal=='C Corporation'){
                            component.set('v.CCorpreadonly', true);  
                            component.set('v.implementationChecklist.Own_5_of_the_company__c', 'Yes');	 
                        }
                        //JDA_midnight
                        if(component.get("v.implementationChecklist.Business_Entity_Type__c") == 'S Corporation'){
                            component.set('v.isBusinessEntityTypeScorporation', true);
                        }else{
                            component.set('v.isBusinessEntityTypeScorporation', false);
                        }
                        //JDA_midnight
                        //SPA: US8:end
                        var payFrequency = data.implChecklist.PEO_Underwriting_Checklist__r.Payroll_Frequency__c;
                        var frequencies = (!$A.util.isUndefinedOrNull(payFrequency) ? payFrequency.split(';'):[]);
                        component.set('v.frequencyValues', frequencies);
                        if(payFrequency != undefined && payFrequency != null){
                            if(payFrequency.includes('52 - Weekly')){
                                component.set('v.showWeekly', true);
                            }
                            if(payFrequency.includes('26 - Bi-Weekly')){
                                component.set('v.showBiWeekly', true);
                            }
                            if(payFrequency.includes('24 - Semi-Monthly')){
                                component.set('v.showSemiMonthly', true);
                            }
                            if(payFrequency.includes('12 - Monthly')){
                                component.set('v.showMonthly', true);
                            }
                        }                        
                      
                    }
                    if(data.parentImplChklist != undefined){
                        //component.set('v.parentImplChecklist', data.parentImplChklist);
                    }
                }
                this.prepareOwnerRecData(component, event, helper, data.implChecklist);
                this.prepareOwnerDataWhoEarnMoreThan150K(component, event, helper, data.implChecklist);
                this.prepareFamilyMemberRec(component, event, helper, data.implChecklist);
                this.prepareMultiPicklistValues(component, event, helper, data.implChecklist);
                this.preparePartnershipOwnerData(component, event, helper, data.implChecklist);
                this.prepareOwner2Percentage(component, event, helper, data.implChecklist);
                this.prepareOwnerDataWhoEarnMoreThan130K(component, event, helper, data.implChecklist);
                this.prepareofficersRecs(component, event, helper, data.implChecklist);
                this.prepareofficersRecs185k(component, event, helper, data.implChecklist);
            }
        })
        $A.enqueueAction(getImplChecklist);
    },
    
    handleDateChange: function(cmp, event, helper, fieldVal){

        var dateVal = new Date(fieldVal);
        dateVal.setDate(dateVal.getDate() - 1);
        var tempdate = new Date(dateVal).toDateString("yyyy-MM-dd");
        var dateNew = new Date(tempdate);
        var year = dateNew.toLocaleString("default", { year: "numeric" });
        var month = dateNew.toLocaleString("default", { month: "2-digit" });
        var day = dateNew.toLocaleString("default", { day: "2-digit" });
        var formattedDate = year + "-" + month + "-" + day;
        console.log('>>.formattedDate:: '+formattedDate); 
        return formattedDate;
        //cmp.set('v.implementationChecklist.Anticipated_First_Run_Date_Weekly__c', formattedDate);
    },
    
    prepareOwnerRecData: function(component, event, helper, checklistData) {
        let ownerRecs = [];
        let ownerDetails = {"nameOfOwner":"", "percentageOfOwner":""};
        let percentageTotal = 0;
        //let checklistData = component.get("v.implementationChecklist");
        if(checklistData != null && checklistData.hasOwnProperty('Users_own_5_of_company__c') &&  checklistData.Users_own_5_of_company__c != null &&  checklistData.Users_own_5_of_company__c != 'undefined' && checklistData.Users_own_5_of_company__c != ''){
            let existingOwnershipData = checklistData.Users_own_5_of_company__c;
            let ownersDataAndPercentArr = existingOwnershipData.split(';');
            for(let cnt = 0; cnt < ownersDataAndPercentArr.length - 1; cnt++){
                let ownerNameAndPercentArr = ownersDataAndPercentArr[cnt].split('|');
                let ownerObj = Object.assign({},ownerDetails);
                ownerObj.nameOfOwner = ownerNameAndPercentArr[0];
                if(ownerNameAndPercentArr[1] != null && ownerNameAndPercentArr[1] != '' && ownerNameAndPercentArr[1] != 'undefined'){
                    ownerObj.percentageOfOwner = parseFloat(ownerNameAndPercentArr[1]);
                }
                ownerRecs.push(ownerObj);
            }
        }else{
            let ownerObj = Object.assign({},ownerDetails);
            ownerRecs.push(ownerObj);
        }
        component.set("v.ownerRecs",ownerRecs);
    },
    
    prepareOwnerDataWhoEarnMoreThan150K : function(component, event, helper, checklistData) {
        let ownerRecs = [];
        let ownerDetails = {"nameOfOwner":"", "percentageOfOwner":""};
        let percentageTotal = 0;
        //let checklistData = component.get("v.implementationChecklist");
        if(checklistData != null && checklistData.hasOwnProperty('Users_own_1_of_company_earn_150k__c') &&  checklistData.Users_own_1_of_company_earn_150k__c != null &&  checklistData.Users_own_1_of_company_earn_150k__c != 'undefined' && checklistData.Users_own_1_of_company_earn_150k__c != ''){
            let existingOwnershipData = checklistData.Users_own_1_of_company_earn_150k__c;
            let ownersDataAndPercentArr = existingOwnershipData.split(';');
            for(let cnt = 0; cnt < ownersDataAndPercentArr.length - 1; cnt++){
                let ownerNameAndPercentArr = ownersDataAndPercentArr[cnt].split('|');
                let ownerObj = Object.assign({},ownerDetails);
                ownerObj.nameOfOwner = ownerNameAndPercentArr[0];
                if(ownerNameAndPercentArr[1] != null && ownerNameAndPercentArr[1] != '' && ownerNameAndPercentArr[1] != 'undefined'){
                    ownerObj.percentageOfOwner = parseFloat(ownerNameAndPercentArr[1]);
                }
                ownerRecs.push(ownerObj);
            }
        }else{
            let ownerObj = Object.assign({},ownerDetails);
            ownerRecs.push(ownerObj);
        }
        component.set("v.ownerRecsEarn150K",ownerRecs);
    },
    prepareOwnerDataWhoEarnMoreThan130K : function(component, event, helper, checklistData) {
        let ownerRecs = [];
        let ownerDetails = {"nameOfOwner":""};
        let percentageTotal = 0;
        //let checklistData = component.get("v.implementationChecklist");
        if(checklistData != null && checklistData.hasOwnProperty('User_earned_130K_in_prior_year__c') &&  checklistData.User_earned_130K_in_prior_year__c != null &&  checklistData.User_earned_130K_in_prior_year__c != 'undefined' && checklistData.User_earned_130K_in_prior_year__c != ''){
            let existingOwnershipData = checklistData.User_earned_130K_in_prior_year__c;
            let ownersDataAndPercentArr = existingOwnershipData.split(';');
            for(let cnt = 0; cnt < ownersDataAndPercentArr.length - 1; cnt++){
                let ownerNameAndPercentArr = ownersDataAndPercentArr[cnt].split('|');
                let ownerObj = Object.assign({},ownerDetails);
                ownerObj.nameOfOwner = ownerNameAndPercentArr[0];
                /*if(ownerNameAndPercentArr[1] != null && ownerNameAndPercentArr[1] != '' && ownerNameAndPercentArr[1] != 'undefined'){
                    ownerObj.percentageOfOwner = parseFloat(ownerNameAndPercentArr[1]);
                }*/
                ownerRecs.push(ownerObj);
            }
        }else{
            let ownerObj = Object.assign({},ownerDetails);
            ownerRecs.push(ownerObj);
        }
        component.set("v.ownerRecsEarn130K",ownerRecs);
    },
    prepareOwner2Percentage : function(component, event, helper, checklistData) {
        let ownerRecs = [];
        let ownerDetails = {"nameOfOwner":"", "percentageOfOwner":""};
        let percentageTotal = 0;
        //let checklistData = component.get("v.implementationChecklist");
        if(checklistData != null && checklistData.hasOwnProperty('Users_own_2_of_company__c') &&  checklistData.Users_own_2_of_company__c != null &&  checklistData.Users_own_2_of_company__c != 'undefined' && checklistData.Users_own_2_of_company__c != ''){
            let existingOwnershipData = checklistData.Users_own_2_of_company__c;
            let ownersDataAndPercentArr = existingOwnershipData.split(';');
            for(let cnt = 0; cnt < ownersDataAndPercentArr.length - 1; cnt++){
                let ownerNameAndPercentArr = ownersDataAndPercentArr[cnt].split('|');
                let ownerObj = Object.assign({},ownerDetails);
                ownerObj.nameOfOwner = ownerNameAndPercentArr[0];
                if(ownerNameAndPercentArr[1] != null && ownerNameAndPercentArr[1] != '' && ownerNameAndPercentArr[1] != 'undefined'){
                    ownerObj.percentageOfOwner = parseFloat(ownerNameAndPercentArr[1]);
                }
                ownerRecs.push(ownerObj);
            }
        }else{
            let ownerObj = Object.assign({},ownerDetails);
            ownerRecs.push(ownerObj);
        }
        component.set("v.ownerRecs2percent",ownerRecs);
    },
    preparePartnershipOwnerData : function(component, event, helper, checklistData) {
        let ownerRecs = [];
        let ownerDetails = {"nameOfOwner":"", "percentageOfOwner":""};
        let percentageTotal = 0;
        //let checklistData = component.get("v.implementationChecklist");
        if(checklistData != null && checklistData.hasOwnProperty('Partner_user_of_company__c') 
           &&  checklistData.Partner_user_of_company__c != null 
           &&  checklistData.Partner_user_of_company__c != 'undefined' 
           && checklistData.Partner_user_of_company__c != ''){
            let existingOwnershipData = checklistData.Partner_user_of_company__c;
            let ownersDataAndPercentArr = existingOwnershipData.split(';');
            for(let cnt = 0; cnt < ownersDataAndPercentArr.length - 1; cnt++){
                let ownerNameAndPercentArr = ownersDataAndPercentArr[cnt].split('|');
                let ownerObj = Object.assign({},ownerDetails);
                ownerObj.nameOfOwner = ownerNameAndPercentArr[0];
                if(ownerNameAndPercentArr[1] != null && ownerNameAndPercentArr[1] != '' && ownerNameAndPercentArr[1] != 'undefined'){
                    ownerObj.percentageOfOwner = parseFloat(ownerNameAndPercentArr[1]);
                    percentageTotal += parseFloat(ownerNameAndPercentArr[1]);
                }
                ownerRecs.push(ownerObj);
            }
        }else{
            let ownerObj = Object.assign({},ownerDetails);
            ownerRecs.push(ownerObj);
        }
        let businessEntityVal = checklistData.Business_Entity_Type__c;
        if(ownerRecs.length<=1 && (businessEntityVal == 'Partnership' 
                                   || businessEntityVal == 'Limited Liability Partnership'               
                                   || businessEntityVal == 'LLC taxed as a partnership')){
            let AddntlOwner = {nameOfOwner:"", percentageOfOwner:""};
                         ownerRecs.push(Object.assign({},AddntlOwner));            
        }
        component.set("v.ownerRecsPartnership",ownerRecs);
        component.set("v.ownerRecsPartnershipTotal",percentageTotal);
    },
    
    prepareFamilyMemberRec: function(component, event, helper, checklistData) {
        let ownerRecs = [];
        let ownerDetails = {"familyMember":"", "nameOfOwner":"", "percentageOfOwner":""};
        let percentageTotal = 0;
        //let checklistData = component.get("v.implementationChecklist");
        if(checklistData != null && checklistData.hasOwnProperty('Name_of_members_of_5_2_1_owners__c') &&  checklistData.Name_of_members_of_5_2_1_owners__c != null &&  checklistData.Name_of_members_of_5_2_1_owners__c != 'undefined' && checklistData.Name_of_members_of_5_2_1_owners__c != ''){
            let existingOwnershipData = checklistData.Name_of_members_of_5_2_1_owners__c;
            let ownersDataAndPercentArr = existingOwnershipData.split(';');
            for(let cnt = 0; cnt < ownersDataAndPercentArr.length - 1; cnt++){
                let ownerNameAndPercentArr = ownersDataAndPercentArr[cnt].split('|');
                let ownerObj = Object.assign({},ownerDetails);
                //ownerObj.familyMember = ownerNameAndPercentArr[1];
                //ownerObj.nameOfOwner = ownerNameAndPercentArr[0];
                ownerObj.familyMember = ownerNameAndPercentArr[0];
                ownerObj.nameOfOwner = ownerNameAndPercentArr[1];
                if(ownerNameAndPercentArr[2] != null && ownerNameAndPercentArr[2] != '' && ownerNameAndPercentArr[2] != 'undefined'){
                    ownerObj.percentageOfOwner = parseFloat(ownerNameAndPercentArr[2]);
                }
                ownerRecs.push(ownerObj);
            }
        }else{
            let ownerObj = Object.assign({},ownerDetails);
            ownerRecs.push(ownerObj);
        }
        component.set("v.familyMemberRecs",ownerRecs);
    },
    
    //JDA S08
    prepareofficersRecs : function(component, event, helper, checklistData) {
        let ownerRecs = [];
        let ownerDetails = {"nameOfOwner":""};
        let percentageTotal = 0;
        if(checklistData != null && checklistData.hasOwnProperty('Names_individuals_who_are_officers__c') &&  checklistData.Names_individuals_who_are_officers__c != null &&  checklistData.Names_individuals_who_are_officers__c != 'undefined' && checklistData.Names_individuals_who_are_officers__c != ''){
            let existingOwnershipData = checklistData.Names_individuals_who_are_officers__c;
            let ownersDataAndPercentArr = existingOwnershipData.split(';');
            for(let cnt = 0; cnt < ownersDataAndPercentArr.length - 1; cnt++){
                let ownerNameAndPercentArr = ownersDataAndPercentArr[cnt];
                let ownerObj = Object.assign({},ownerDetails);
                ownerObj.nameOfOwner = ownerNameAndPercentArr;
                /*if(ownerNameAndPercentArr[1] != null && ownerNameAndPercentArr[1] != '' && ownerNameAndPercentArr[1] != 'undefined'){
				ownerObj.percentageOfOwner = parseFloat(ownerNameAndPercentArr[1]);
			}*/
                ownerRecs.push(ownerObj);
            }
        }else{
            let ownerObj = Object.assign({},ownerDetails);
            ownerRecs.push(ownerObj);
        }
        component.set("v.officersRecs",ownerRecs);
    },
    
    prepareofficersRecs185k : function(component, event, helper, checklistData) {
        let ownerRecs = [];
        let ownerDetails = {"nameOfOwner":""};
        let percentageTotal = 0;
        if(checklistData != null && checklistData.hasOwnProperty('Names_of_officers_of_company_earn_185K__c') &&  checklistData.Names_of_officers_of_company_earn_185K__c != null &&  checklistData.Names_of_officers_of_company_earn_185K__c != 'undefined' && checklistData.Names_of_officers_of_company_earn_185K__c != ''){
            let existingOwnershipData = checklistData.Names_of_officers_of_company_earn_185K__c;
            let ownersDataAndPercentArr = existingOwnershipData.split(';');
            for(let cnt = 0; cnt < ownersDataAndPercentArr.length - 1; cnt++){
                let ownerNameAndPercentArr = ownersDataAndPercentArr[cnt];
                let ownerObj = Object.assign({},ownerDetails);
                ownerObj.nameOfOwner = ownerNameAndPercentArr;
                /*if(ownerNameAndPercentArr[1] != null && ownerNameAndPercentArr[1] != '' && ownerNameAndPercentArr[1] != 'undefined'){
			ownerObj.percentageOfOwner = parseFloat(ownerNameAndPercentArr[1]);
		}*/
                ownerRecs.push(ownerObj);
            }
        }else{
            let ownerObj = Object.assign({},ownerDetails);
            ownerRecs.push(ownerObj);
        }
        component.set("v.officersRecs185k",ownerRecs);
    },
    //JDA S08
    
    copydataFromParentToChild: function(component, event, helper){
        var getParentImplChecklist = component.get('c.getParentPEOImplementationChecklist');
        getParentImplChecklist.setParams({
            chkListId : component.get("v.parentImplChecklist").Id
        });
        getParentImplChecklist.setCallback(this, function(res) {
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError());
            }else{
                let data = res.getReturnValue();
                this.copyData(component, event, helper, data);
                this.saveImplementationQuestions(component, event, helper); 
            }
        });
        $A.enqueueAction(getParentImplChecklist);
        
    },
    
    copyData: function(component, event, helper, parentChecklist){
        var checkList = component.get('v.implementationChecklist');
        checkList.Business_Entity_Type__c = parentChecklist.Business_Entity_Type__c;
        checkList.Authorized_Officer_Name__c = parentChecklist.Authorized_Officer_Name__c;
        checkList.Authorized_Officer_Title__c = parentChecklist.Authorized_Officer_Title__c;
        checkList.Require_multiple_client_codes__c = parentChecklist.Require_multiple_client_codes__c;
        checkList.Reason_for_multiple_client_codes__c = parentChecklist.Reason_for_multiple_client_codes__c;
        checkList.How_bank_acc_info_be_provided__c = parentChecklist.How_bank_acc_info_be_provided__c;
        checkList.LAST_FOUR_digits_of_their_Bank_Acc_No__c = parentChecklist.LAST_FOUR_digits_of_their_Bank_Acc_No__c;
        checkList.Same_as_Authorized_Officer__c = parentChecklist.Same_as_Authorized_Officer__c;
        checkList.Business_Owner_Name__c = parentChecklist.Business_Owner_Name__c;
        checkList.Business_Owner_Email_address__c = parentChecklist.Business_Owner_Email_address__c;
        checkList.Business_Owner_Title__c = parentChecklist.Business_Owner_Title__c;
        checkList.Business_Owner_Same_as_Primary_Contact__c = parentChecklist.Business_Owner_Same_as_Primary_Contact__c;
        checkList.Primary_Contact_Name__c = parentChecklist.Primary_Contact_Name__c;
        checkList.Primary_Contact_Email_address__c = parentChecklist.Primary_Contact_Email_address__c;
        checkList.Primary_Contact_Title__c = parentChecklist.Primary_Contact_Title__c;
        checkList.Period_Begin_Dates_Weekly__c = parentChecklist.Period_Begin_Dates_Weekly__c;
        checkList.Period_End_Dates_Weekly__c = parentChecklist.Period_End_Dates_Weekly__c;
        checkList.Anticipated_First_Check_Date_Weekly__c = parentChecklist.Anticipated_First_Check_Date_Weekly__c;
        checkList.Anticipated_First_Run_Date_Weekly__c = parentChecklist.Anticipated_First_Run_Date_Weekly__c;
        checkList.Period_Begin_Date_BiWeekly__c = parentChecklist.Period_Begin_Date_BiWeekly__c;
        checkList.Period_End_Date_BiWeekly__c = parentChecklist.Period_End_Date_BiWeekly__c;
        checkList.Anticipated_First_Check_Date_BiWeekly__c = parentChecklist.Anticipated_First_Check_Date_BiWeekly__c;
        checkList.Anticipated_First_Run_Date_BiWeekly__c = parentChecklist.Anticipated_First_Run_Date_BiWeekly__c;
        checkList.Period_Begin_Date_SemiMonthly__c = parentChecklist.Period_Begin_Date_SemiMonthly__c;
        checkList.Period_End_Date_SemiMonthly__c = parentChecklist.Period_End_Date_SemiMonthly__c;
        checkList.Anticipated_First_Check_Date_SemiMonth__c = parentChecklist.Anticipated_First_Check_Date_SemiMonth__c;
        checkList.Anticipated_First_Run_Date_SemiMonthly__c = parentChecklist.Anticipated_First_Run_Date_SemiMonthly__c;
        checkList.Period_Begin_Date_Monthly__c = parentChecklist.Period_Begin_Date_Monthly__c;
        checkList.Period_End_Date_Monthly__c = parentChecklist.Period_End_Date_Monthly__c;
        checkList.Anticipated_First_Check_Date_Monthly__c = parentChecklist.Anticipated_First_Check_Date_Monthly__c;
        checkList.Anticipated_First_Run_Date_Monthly__c = parentChecklist.Anticipated_First_Run_Date_Monthly__c;
        checkList.Pay_on_Demand__c = parentChecklist.Pay_on_Demand__c;
        checkList.Labor_Distribution__c = parentChecklist.Labor_Distribution__c;
        checkList.Job_Costing__c = parentChecklist.Job_Costing__c;
        checkList.General_Ledger__c = parentChecklist.General_Ledger__c;
        checkList.General_Ledger_Service__c = parentChecklist.General_Ledger_Service__c;
        checkList.Tax_Credit_Services__c = parentChecklist.Tax_Credit_Services__c;
        checkList.Timely_Tips__c = parentChecklist.Timely_Tips__c;
        checkList.Paychex_FlexTime__c = parentChecklist.Paychex_FlexTime__c;
        checkList.Paychex_Flex_Time_Essentials__c = parentChecklist.Paychex_Flex_Time_Essentials__c;
        checkList.Flex_Onboarding__c = parentChecklist.Flex_Onboarding__c;
        checkList.MyStaffingPro__c = parentChecklist.MyStaffingPro__c;
        checkList.E_verify_setup__c = parentChecklist.E_verify_setup__c;
        checkList.Flex_Hiring__c = parentChecklist.Flex_Hiring__c;
        checkList.ACI__c = parentChecklist.ACI__c;
        checkList.Client_currently_offer_a_401k_plan__c = parentChecklist.Client_currently_offer_a_401k_plan__c;
        checkList.Is_it_a_Paychex_401k__c = parentChecklist.Is_it_a_Paychex_401k__c;
        
        if(checkList.Business_Entity_Type__c == 'Partnership' || checkList.Business_Entity_Type__c == 'Limited Liability Partnership'
               || checkList.Business_Entity_Type__c == 'Sole Proprietor'
               || checkList.Business_Entity_Type__c == 'LLC taxed as a partnership' 
               || checkList.Business_Entity_Type__c == 'LLC taxed as a sole proprietorship'){
            component.set('v.isBusinessEntityTypePartner', true);
        }
        if(checkList.Business_Entity_Type__c =='LLC taxed as a corporation' || checkList.Business_Entity_Type__c =='C Corporation'){
            component.set('v.CCorpreadonly', true); 
        }
        if(checkList.Business_Entity_Type__c =='S Corporation' || checkList.Business_Entity_Type__c =='LLC taxed as a S-Corp'){
            component.set('v.scorpreadonly', true);
        }
        
        checkList.Own_5_of_the_company__c = parentChecklist.Own_5_of_the_company__c;
        checkList.Own_2_of_the_company__c = parentChecklist.Own_2_of_the_company__c;
        
        checkList.Own_1_of_the_company_earn_150k__c = parentChecklist.Own_1_of_the_company_earn_150k__c;
        checkList.Family_members_of_5_2_1_owners__c = parentChecklist.Family_members_of_5_2_1_owners__c;
        checkList.Is_the_Company_a_Partnership__c = parentChecklist.Is_the_Company_a_Partnership__c;
        checkList.Any_individuals_who_are_officers__c = parentChecklist.Any_individuals_who_are_officers__c;
        checkList.Names_individuals_who_are_officers__c = parentChecklist.Names_individuals_who_are_officers__c;
        checkList.Any_officers_of_company_earn_185K__c = parentChecklist.Any_officers_of_company_earn_185K__c;
        checkList.Names_of_officers_of_company_earn_185K__c = parentChecklist.Names_of_officers_of_company_earn_185K__c;
        checkList.Any_employee_earned_130K_in_prior_year__c = parentChecklist.Any_employee_earned_130K_in_prior_year__c;
        checkList.Have_any_COBRA_Participants__c = parentChecklist.Have_any_COBRA_Participants__c;
        
        helper.prepareOwnerRecData(component, event, helper, parentChecklist);
        checkList.Users_own_5_of_company__c = parentChecklist.Users_own_5_of_company__c;
        
        helper.prepareOwnerDataWhoEarnMoreThan150K(component, event, helper, parentChecklist);
        checkList.Users_own_1_of_company_earn_150k__c = parentChecklist.Users_own_1_of_company_earn_150k__c;
        
        helper.prepareFamilyMemberRec(component, event, helper, parentChecklist);
        checkList.Name_of_members_of_5_2_1_owners__c = parentChecklist.Name_of_members_of_5_2_1_owners__c;
        
        //helper.prepareMultiPicklistValues(component, event, helper, parentChecklist);
        
        helper.preparePartnershipOwnerData(component, event, helper, parentChecklist);
        checkList.Partner_user_of_company__c = parentChecklist.Partner_user_of_company__c;
        
        helper.prepareOwner2Percentage(component, event, helper, parentChecklist);
        checkList.Users_own_2_of_company__c = parentChecklist.Users_own_2_of_company__c;
        
        helper.prepareOwnerDataWhoEarnMoreThan130K(component, event, helper, parentChecklist);
        checkList.User_earned_130K_in_prior_year__c = parentChecklist.User_earned_130K_in_prior_year__c;
        
        component.set('v.implementationChecklist', checkList);
    },
    
    prepareMultiPicklistValues: function(component, event, helper, checklistData){
        //let checklistData = component.get("v.implementationChecklist");
        if(checklistData != null && checklistData.hasOwnProperty('Self_retain_ancillary_products__c') &&  checklistData.Self_retain_ancillary_products__c != null &&  checklistData.Self_retain_ancillary_products__c != 'undefined' && checklistData.Self_retain_ancillary_products__c != ''){
            var array = checklistData.Self_retain_ancillary_products__c.split(';');
            component.set('v.selfRetainProductsValue', array);            
        }
        if(checklistData != null && checklistData.hasOwnProperty('ACI_Options__c') &&  checklistData.ACI_Options__c != null &&  checklistData.ACI_Options__c != 'undefined' && checklistData.ACI_Options__c != ''){
            var array = checklistData.ACI_Options__c.split(';');
            component.set('v.ACIOptionsValue', array);            
        }
    },
    
    checkValidity : function(component, event, helper) {
        // alert('>>>check validity function');
        component.set("v.isLoading",true);
        console.log('>>>>checkValidity::');
        console.log('>>>>currentAccount::'+component.get("v.currentAccount.Id"));
        var impCheckList =  component.get("v.implementationChecklist");
        var ParentAccountId = component.get("v.ParentAccountId");
        var currentAccount = component.get("v.currentAccount.Id");
        var currentAccountData = component.get("v.currentAccount");
        var isBussScorp = component.get("v.isBusinessEntityTypeScorporation");
        var missingFields = [];
		var peoChecklist = component.get("v.peoChecklist");
		var CorporationType = component.get("v.implementationChecklist.Business_Entity_Type__c");
        if(currentAccount == ParentAccountId){
            console.log('for parent');
            console.log('impCheckListimpCheckListimpCheckListimpCheckList', impCheckList);
            
            console.log('impCheckListimpCheckListimpCheckListimpCheckList', JSON.stringify(impCheckList));
            console.log('impCheckList.Any_individuals_who_are_officers__c', impCheckList.Any_individuals_who_are_officers__c);
            console.log('impCheckList.Any_officers_of_company_earn_185K__c', impCheckList.Any_officers_of_company_earn_185K__c);
            console.log( impCheckList.Any_individuals_who_are_officers__c == 'No' || (impCheckList.Any_individuals_who_are_officers__c == 'Yes' && impCheckList.Any_officers_of_company_earn_185K__c));
            console.log('jda impCheckList.Any_individuals_who_are_officers__c  :'+impCheckList['Any_individuals_who_are_officers__c']);
            console.log('jda impCheckList.Any_individuals_who_are_officers__c  :'+impCheckList.Any_individuals_who_are_officers__c );
            var hasMissingFields = helper.checkForMissingFields(component, event, helper);
            console.log('checkValidity hasMissingFields:'+hasMissingFields);
            if(impCheckList.Business_Entity_Type__c 
               && impCheckList.Require_multiple_client_codes__c
               && impCheckList.How_bank_acc_info_be_provided__c
               && impCheckList.Did_the_client_have_prior_wages__c  
               && impCheckList.Business_Owner_Name__c 
               && impCheckList.Business_Owner_Email_address__c 
               && impCheckList.Business_Owner_Title__c 
               // && impCheckList.Same_as_Authorized_Officer__c 
               && impCheckList.Requested_Benefits_Effective_Date__c 
               //&& impCheckList.Business_Owner_Same_as_Primary_Contact__c 
               && impCheckList.Primary_Contact_Name__c 
               && impCheckList.Primary_Contact_Email_address__c 
               && impCheckList.Primary_Contact_Title__c 
               //&& impCheckList.Currently_offering_group_Dental__c 
               //&& impCheckList.Will_offer_Dental_through_PBS_PEO__c 
               && impCheckList.Approved_to_self_retain_ancillary_prods__c 
               // && impCheckList.Period_Begin_Dates_Weekly__c  
               // && impCheckList.Period_End_Dates_Weekly__c   
               && impCheckList.Client_currently_offer_a_401k_plan__c 
               // && impCheckList.Anticipated_First_Check_Date_Weekly__c 
               // && impCheckList.Anticipated_First_Run_Date_Weekly__c  
              /* && (impCheckList.Pay_on_Demand__c 
                   || impCheckList.Labor_Distribution__c 
                   || impCheckList.Job_Costing__c 
                   || impCheckList.General_Ledger__c 
                   || impCheckList.General_Ledger_Service__c 
                   || impCheckList.Tax_Credit_Services__c 
                   || impCheckList.Timely_Tips__c 
                   || impCheckList.Paychex_FlexTime__c 
                   || impCheckList.Paychex_Flex_Time_Essentials__c 
                   || impCheckList.ACI__c)  */
               && impCheckList.Offer_Employer_Shared_Responsibility__c 
               && impCheckList.Have_an_FSA_with_Paychex__c
               && impCheckList.Offer_a_PEO_Flexible_Spending_Account__c 
               && impCheckList.Will_client_offer_medical_through_PIA__c 
               && impCheckList.Client_offer_a_Health_Savings_Account__c 
               && impCheckList.Will_the_client_offer_Skylight_Paycard__c
               && impCheckList.Spanish_Employee_Onboarding_needed__c
               && (impCheckList.Own_1_of_the_company_earn_150k__c )
               // && impCheckList.Any_individuals_who_earned_130k__c 
               && ((CorporationType!= 'Sole Proprietor' && CorporationType!= 'Partnership'  && CorporationType!= 'LLC taxed as a partnership' && CorporationType!= 'LLC taxed as a sole proprietorship') 
                  
                   || ((CorporationType== 'Sole Proprietor'|| CorporationType== 'Partnership' 
                        || CorporationType== 'LLC taxed as a partnership' || CorporationType== 'LLC taxed as a sole proprietorship') 
                       && impCheckList.Is_the_Company_a_Partnership__c) )
               && impCheckList.Any_employee_earned_130K_in_prior_year__c 
               && impCheckList.Any_individuals_who_are_officers__c
               &&( impCheckList.Any_individuals_who_are_officers__c == 'No' || (impCheckList.Any_individuals_who_are_officers__c == 'Yes' && impCheckList.Any_officers_of_company_earn_185K__c))
               
               && impCheckList.Have_any_COBRA_Participants__c ){
                console.log('line 310');
                component.set("v.implementationChecklist.Ready_to_Finalize__c",true);
                component.set("v.isValid",true);
                
                /*if(currentAccountData.Date_of_Incorporation__c == '' || currentAccountData.Date_of_Incorporation__c == undefined){
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                }*/
               
                if(impCheckList.Did_the_client_have_prior_wages__c == 'Yes'
                   && !impCheckList.Year_To_Date_payments_to_be_applied__c){
                    console.log('line 338');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                }
                if(impCheckList.Offer_a_PEO_Flexible_Spending_Account__c == 'Yes'
                   && (!impCheckList.Health_Flexible_Spending_Account__c ||
                       !impCheckList.Dependent_Care_Flexible_Spending_Account__c)){
                    console.log('line 345');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                }
                if(impCheckList.Client_offer_a_Health_Savings_Account__c == 'Yes'){
                    if((impCheckList.Employer_Contribution_HSA_Individual__c == '' || impCheckList.Employer_Contribution_HSA_Individual__c == null 
                        || impCheckList.Employer_Contribution_HSA_Individual__c == undefined || impCheckList.Employer_Contribution_HSA_Individual__c == ' ')
                       && impCheckList.Employer_Contribution_HSA_Individual__c != 0 ){
                        console.log('>>>line 353 in if ');
                        component.set("v.isValid",false);
                        component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                    }
                    if((impCheckList.Employer_Contribution_HSA_Family__c == '' || impCheckList.Employer_Contribution_HSA_Family__c == null 
                        || impCheckList.Employer_Contribution_HSA_Family__c == undefined || impCheckList.Employer_Contribution_HSA_Family__c == ' ') 
                       && impCheckList.Employer_Contribution_HSA_Family__c != 0 ){
                        console.log('>>>line 360 in if ');
                        component.set("v.isValid",false);
                        component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                    }
                }
                
                
                console.log('>>>line 361 in helper:: '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                component.set("v.implementationChecklist.PEOUW_Msng_Sec__c",'');
                if(impCheckList.Client_currently_offer_a_401k_plan__c == 'Yes' 
                   && !impCheckList.Is_it_a_Paychex_401k__c){
                    console.log('line 378');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                }
                if(impCheckList.Approved_to_self_retain_ancillary_prods__c == 'Yes'){
                    if(!impCheckList.Requesting_to_self_retail_ancillary_prod__c){
                        component.set("v.isValid",false);  
                        component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                    }else if(impCheckList.Requesting_to_self_retail_ancillary_prod__c == 'Yes'){
                        if(!impCheckList.Self_retain_ancillary_products__c){
                            console.log('line 584');
                            component.set("v.isValid",false);  
                            component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                        }
                    }
                } 
                if(impCheckList.Require_multiple_client_codes__c == 'Yes' 
                   && !impCheckList.Reason_for_multiple_client_codes__c){
                    console.log('line 391');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                if(impCheckList.ACI__c == true 
                   && !impCheckList.ACI_Options__c){
                    console.log('line 397');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                if(impCheckList.Own_5_of_the_company__c == 'Yes' 
                   && !impCheckList.Users_own_5_of_company__c){
                    console.log('line 403');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                console.log('impCheckList.Users_own_1_of_company_earn_150k__c:'+impCheckList.Users_own_1_of_company_earn_150k__c);
                if(impCheckList.Own_1_of_the_company_earn_150k__c == 'Yes' 
                   && !impCheckList.Users_own_1_of_company_earn_150k__c){
                    console.log('line 409');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                    //missingFields.push('Users_own_1_of_company_earn_150k__c');
                }
                if(impCheckList.Any_employee_earned_130K_in_prior_year__c == 'Yes' 
                   && !impCheckList.User_earned_130K_in_prior_year__c){
                    console.log('line 415');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                console.log('line 419 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                 //console.log('line Corporation_Type__c '+component.get("v.currentAccount.Corporation_Type__c"));
                 console.log('line Is_the_Company_a_Partnership__c '+component.get("v.implementationChecklist.Is_the_Company_a_Partnership__c"));
                 console.log('line Partner_user_of_company__c '+component.get("v.implementationChecklist.Partner_user_of_company__c"));
                
                
                if((CorporationType== 'Sole Proprietor' || CorporationType == 'Partnership' 
                   ||CorporationType== 'Limited Liability Partnership')  
                   && impCheckList.Is_the_Company_a_Partnership__c == 'Yes' 
                   && !impCheckList.Partner_user_of_company__c){
                  //  alert('line 429 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                 
                    console.log('line 425'); 
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                 console.log('line 435 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
               if(CorporationType== 'S Corporation' && !impCheckList.Own_2_of_the_company__c){
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                 console.log('line 440 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                if(CorporationType== 'C Corporation' && impCheckList.Own_5_of_the_company__c == 'Yes' 
                   && !impCheckList.Users_own_5_of_company__c){
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                if(CorporationType== 'S Corporation' && impCheckList.Own_2_of_the_company__c == 'Yes' 
                   && !impCheckList.Users_own_2_of_company__c){
                    console.log('line 421');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                 console.log('line 447 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                if(CorporationType== 'S Corporation' && !impCheckList.Family_members_of_5_2_1_owners__c){
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                 console.log('line 452 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                if(CorporationType== 'S Corporation' && impCheckList.Family_members_of_5_2_1_owners__c == 'Yes' 
                   && !impCheckList.Name_of_members_of_5_2_1_owners__c){
                    console.log('line 431');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                 console.log('line 459 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
               
                if(impCheckList.Any_individuals_who_are_officers__c == 'Yes' 
                   && !impCheckList.Names_individuals_who_are_officers__c){
                    console.log('line 443');
                    component.set("v.isValid",false); 
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                }
                 console.log('line 471 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                if(impCheckList.Any_officers_of_company_earn_185K__c == 'Yes' 
                   && !impCheckList.Names_of_officers_of_company_earn_185K__c){
                    console.log('line 124');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                 console.log('line 479 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                if(component.get("v.showWeekly") == true){
                    if(!impCheckList.Period_Begin_Dates_Weekly__c || !impCheckList.Period_End_Dates_Weekly__c ||
                       !impCheckList.Anticipated_First_Check_Date_Weekly__c || !impCheckList.Anticipated_First_Run_Date_Weekly__c ){
                        console.log('line 130');
                        component.set("v.isValid",false);
                        component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                    }
                }
                 console.log('line 488 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                if(component.get("v.showBiWeekly") == true){
                    if(!impCheckList.Period_Begin_Date_BiWeekly__c || !impCheckList.Period_End_Date_BiWeekly__c ||
                       !impCheckList.Anticipated_First_Check_Date_BiWeekly__c || !impCheckList.Anticipated_First_Run_Date_BiWeekly__c ){
                        console.log('line 137');
                        component.set("v.isValid",false);
                        component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                    }
                }
                 console.log('line 497 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                if(component.get("v.showSemiMonthly") == true){
                    if(!impCheckList.Period_Begin_Date_SemiMonthly__c || !impCheckList.Period_End_Date_SemiMonthly__c ||
                       !impCheckList.Anticipated_First_Check_Date_SemiMonth__c || !impCheckList.Anticipated_First_Run_Date_SemiMonthly__c ){
                        console.log('line 144');
                        component.set("v.isValid",false);
                        component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                    }
                }
                 console.log('line 4506 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                if(component.get("v.showMonthly") == true){
                    if(!impCheckList.Period_Begin_Date_Monthly__c || !impCheckList.Period_End_Date_Monthly__c ||
                       !impCheckList.Anticipated_First_Check_Date_Monthly__c || !impCheckList.Anticipated_First_Run_Date_Monthly__c ){
                        console.log('line 151');
                        component.set("v.isValid",false);
                        component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                    }
                }
                 console.log('line 515 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
                if(!component.get("v.implementationChecklist.Ready_to_Finalize__c")){
                    console.log('Parent Inside if: Setting msng fields values');
                    console.log('missingSectionString:'+component.get('v.missingSectionString'));
                    if(component.get('v.missingSectionString') == undefined || component.get('v.missingSectionString') == null){
                        console.log('Inside if');
                        component.set("v.implementationChecklist.PEOUW_Msng_Sec__c",'');
                    }else{
                        console.log('Inside else');
                        component.set("v.implementationChecklist.PEOUW_Msng_Sec__c",component.get('v.missingSectionString'));
                    }
                }
            }
            else{
                component.set("v.isValid",false);
                component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                if(component.get('v.missingSectionString') == undefined || component.get('v.missingSectionString') == null){
                    component.set("v.implementationChecklist.PEOUW_Msng_Sec__c",'');
                }else{
                    component.set("v.implementationChecklist.PEOUW_Msng_Sec__c",component.get('v.missingSectionString'));
                }
                console.log('>>>is not Valid');
            }
            console.log('line 522');
             console.log('line 523 '+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
            // return  component.get("v.isValid");
            component.set("v.isLoading",false);
            // this.saveImplementationQuestions(component, event, helper);
            console.log('missingFields:'+missingFields);
        }
        /*********validation for child accounts***********/
        else if(currentAccount != ParentAccountId){
            component.set("v.isLoading",true);
            console.log('for child');
            console.log("501 impCheckList", JSON.stringify(impCheckList));
            var hasMissingFields = helper.checkForMissingFields(component, event, helper);
            console.log('Child checkValidity hasMissingFields:'+hasMissingFields);
            if(impCheckList.Require_multiple_client_codes__c 
               && impCheckList.How_bank_acc_info_be_provided__c &&
               impCheckList.Business_Owner_Name__c &&
               impCheckList.Business_Owner_Email_address__c && 
               impCheckList.Business_Owner_Title__c &&
              // impCheckList.Business_Owner_Same_as_Primary_Contact__c  
               impCheckList.Primary_Contact_Name__c &&
               impCheckList.Primary_Contact_Email_address__c &&
               impCheckList.Primary_Contact_Title__c && 
               //impCheckList.Period_Begin_Dates_Weekly__c && 
               //impCheckList.Period_End_Dates_Weekly__c && 
               impCheckList.Client_currently_offer_a_401k_plan__c && 
               //  impCheckList.Anticipated_First_Check_Date_Weekly__c && 
               /*//  impCheckList.Anticipated_First_Run_Date_Weekly__c && 
               (impCheckList.Pay_on_Demand__c || 
                impCheckList.Labor_Distribution__c || 
                impCheckList.Job_Costing__c 
                || impCheckList.General_Ledger__c 
                || impCheckList.General_Ledger_Service__c 
                || impCheckList.Tax_Credit_Services__c 
                || impCheckList.Timely_Tips__c 
                || impCheckList.Paychex_FlexTime__c 
                || impCheckList.Paychex_Flex_Time_Essentials__c 
                || impCheckList.ACI__c) */
               //    && impCheckList.Offer_Employer_Shared_Responsibility__c 
               //    && impCheckList.Have_an_FSA_with_Paychex__c 
               //    && impCheckList.Offer_a_PEO_Flexible_Spending_Account__c 
               //    && impCheckList.Will_client_offer_medical_through_PIA__c 
               //    && impCheckList.Client_offer_a_Health_Savings_Account__c 
               //    && impCheckList.Will_the_client_offer_Skylight_Paycard__c
               
                impCheckList.Own_1_of_the_company_earn_150k__c 
               
               && ((CorporationType!= 'Sole Proprietor' && CorporationType!= 'Partnership' && CorporationType!= 'Limited Liability Partnership') 
                  
                   || ((CorporationType== 'Sole Proprietor'|| CorporationType== 'Partnership'
                        || CorporationType== 'Limited Liability Partnership') 
                       && impCheckList.Is_the_Company_a_Partnership__c) )
               
              // &&(peoChecklist.Business_Entity_Type__c!= 'Sole Proprietor' 
                 // || (peoChecklist.Business_Entity_Type__c== 'Sole Proprietor' && impCheckList.Is_the_Company_a_Partnership__c) )
               && impCheckList.Any_employee_earned_130K_in_prior_year__c 
               && impCheckList.Have_any_COBRA_Participants__c ){
                console.log('line 202');
                component.set("v.isValid",true);
                component.set("v.implementationChecklist.Ready_to_Finalize__c",true);
                component.set("v.implementationChecklist.PEOUW_Msng_Sec__c",'');
               
                if(impCheckList.Require_multiple_client_codes__c == 'Yes' 
                   && !impCheckList.Reason_for_multiple_client_codes__c){
                    console.log('line 206');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                }
                if(impCheckList.Client_currently_offer_a_401k_plan__c == 'Yes' 
                   && !impCheckList.Is_it_a_Paychex_401k__c){
                    console.log('line 211');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                }
                if(impCheckList.Own_5_of_the_company__c == 'Yes' 
                   && !impCheckList.Users_own_5_of_company__c){
                    console.log('line 216');
                    component.set("v.isValid",false); 
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                }
                if(impCheckList.Own_1_of_the_company_earn_150k__c == 'Yes' 
                   && !impCheckList.Users_own_1_of_company_earn_150k__c){
                    console.log('line 221');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                if(impCheckList.Any_employee_earned_130K_in_prior_year__c == 'Yes' 
                   && !impCheckList.User_earned_130K_in_prior_year__c){
                    console.log('line 221');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                
                 if((CorporationType== 'Sole Proprietor' || CorporationType== 'Partnership'||CorporationType== 'Limited Liability Partnership')  
                   && impCheckList.Is_the_Company_a_Partnership__c == 'Yes' 
                   && !impCheckList.Partner_user_of_company__c){
                     
               
                    console.log('line 221');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                if(CorporationType== 'C Corporation' && impCheckList.Own_5_of_the_company__c == 'Yes' 
                   && !impCheckList.Users_own_5_of_company__c){
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                if(CorporationType== 'S Corporation' && !impCheckList.Own_2_of_the_company__c){
                    console.log('line 581');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                if(CorporationType== 'S Corporation' && impCheckList.Own_2_of_the_company__c == 'Yes' 
                   && !impCheckList.Users_own_2_of_company__c){
                    console.log('line 584');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                if(CorporationType== 'S Corporation' && !impCheckList.Family_members_of_5_2_1_owners__c){
                    console.log('line 591');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
                if( CorporationType== 'S Corporation' && impCheckList.Family_members_of_5_2_1_owners__c == 'Yes' 
                   && !impCheckList.Name_of_members_of_5_2_1_owners__c){
                    console.log('line 594');
                    component.set("v.isValid",false);
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false); 
                }
               
                if(impCheckList.Any_individuals_who_are_officers__c == 'Yes' 
                   && !impCheckList.Names_individuals_who_are_officers__c && !impCheckList.Any_officers_of_company_earn_185K__c){
                    console.log('line 231');
                    component.set("v.isValid",false); 
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                }
                if(impCheckList.Any_officers_of_company_earn_185K__c == 'Yes' 
                   && !impCheckList.Names_of_officers_of_company_earn_185K__c){
                    console.log('line 236');
                    component.set("v.isValid",false); 
                    component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                }
                if(component.get("v.showWeekly") == true){
                    if(!impCheckList.Period_Begin_Dates_Weekly__c || !impCheckList.Period_End_Dates_Weekly__c ||
                       !impCheckList.Anticipated_First_Check_Date_Weekly__c || !impCheckList.Anticipated_First_Run_Date_Weekly__c ){
                        console.log('line 242');
                        component.set("v.isValid",false);
                        component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                    }
                }
                if(component.get("v.showBiWeekly") == true){
                    if(!impCheckList.Period_Begin_Date_BiWeekly__c || !impCheckList.Period_End_Date_BiWeekly__c ||
                       !impCheckList.Anticipated_First_Check_Date_BiWeekly__c || !impCheckList.Anticipated_First_Run_Date_BiWeekly__c ){
                        console.log('line 249');
                        component.set("v.isValid",false);
                        component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                    }
                }
                if(component.get("v.showSemiMonthly") == true){
                    if(!impCheckList.Period_Begin_Date_SemiMonthly__c || !impCheckList.Period_End_Date_SemiMonthly__c ||
                       !impCheckList.Anticipated_First_Check_Date_SemiMonth__c || !impCheckList.Anticipated_First_Run_Date_SemiMonthly__c ){
                        console.log('line 256');
                        component.set("v.isValid",false);
                        component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                    }
                }
                if(component.get("v.showMonthly") == true){
                    if(!impCheckList.Period_Begin_Date_Monthly__c || !impCheckList.Period_End_Date_Monthly__c ||
                       !impCheckList.Anticipated_First_Check_Date_Monthly__c || !impCheckList.Anticipated_First_Run_Date_Monthly__c ){
                        console.log('line 263');
                        component.set("v.isValid",false);
                        component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                    }
                }
            }
            else{   
                console.log('Didnt meet the reqd conditions: Setting req finlz to False');
                component.set("v.implementationChecklist.Ready_to_Finalize__c",false);
                //   return  component.get("v.isValid");
            }
            if(!component.get("v.implementationChecklist.Ready_to_Finalize__c")){
                console.log('Inside if: Setting msng fields values');
                //component.set("v.implementationChecklist.PEOUW_Msng_Sec__c",component.get('v.missingSectionString'));
                console.log('missingSectionString:'+component.get('v.missingSectionString'));
                if(component.get('v.missingSectionString') == undefined || component.get('v.missingSectionString') == null){
                    console.log('Inside if');
                    component.set("v.implementationChecklist.PEOUW_Msng_Sec__c",'');
                }else{
                    console.log('Inside else');
                    component.set("v.implementationChecklist.PEOUW_Msng_Sec__c",component.get('v.missingSectionString'));
                }
            }
            //this.saveImplementationQuestions(component, event, helper);
            // return  component.get("v.isValid");
        }
            else{   
                console.log('line 273');
                //   return  component.get("v.isValid");
            }
        console.log('>>>>ready to finalize::'+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
        component.set("v.isLoading",false);
    },

    
    getSavePromise : function(component, event, helper){
        console.log('getSavePromise');
        console.log('tabname: ', component.get("v.tabName"));
        let flex = component.get("v.flexvalue");
        if(flex && component.get('v.peoChecklist').Current_Aff_with_Paychex_PEO_Oasis__c != 'Paychex PEO/Oasis PEO, Child Add-On'){
           component.set("v.implementationChecklist.Flex_Onboarding__c", true);
        }
        var tabname=component.get("v.tabName");
        let isvalid = helper.tabvalidation(component, event, helper, tabname);
        if(isvalid){
        	return new Promise(function(resolve, reject) {
            try{
                helper.checkValidity(component, event, helper);
                helper.triggerImmedieteAutoSaveOfRecords(component, event, helper);
                resolve(helper.saveImplementationQuestions(component, event, helper));
            }
            catch(e) {
                console.log(e);
                reject(false);
            }
        });
        }
        else{
            return new Promise(function(resolve, reject) {
                reject(false);
            });
        }
    },
    
    
  tabvalidation: function(component, event, helper,tabname){
        let isValid=true;
        if(tabname=='Compliance'){
            if(component.get('v.isBusinessEntityTypePartner')
               && component.get('v.implementationChecklist.Is_the_Company_a_Partnership__c')){
                let totalper=0;            
                let tempDataPartner=component.get('v.ownerRecsPartnership');
                for(var i =0 ; i< tempDataPartner.length ;i++){
                    if(tempDataPartner[i].nameOfOwner == undefined ||
                       tempDataPartner[i].percentageOfOwner == undefined 
                       || tempDataPartner[i].nameOfOwner == '' 
                       || tempDataPartner[i].percentageOfOwner == ''){
                        isValid=false;                    
                    }
                    else{
                        totalper = totalper + parseFloat(tempDataPartner[i].percentageOfOwner);
                    }               
                }
                if(isValid){
                    if(totalper!=100){
                        let dets = {ty: 'error', t: 'Error!', m:  'Percent is to equal 100%'};
                        console.log('percent should be 100%');
                        helper.showUserMsg(component, dets);
                        isValid=false;
                    }
                }
                else{
                    let dets = {ty: 'error', t: 'Error!', m:  'Name and Percentage entries are invalid for the ownership percentage'};
                    console.log('Missing partners info');
                    helper.showUserMsg(component, dets);
                }
            }
        }
        return isValid;
    },
    
    triggerImmedieteAutoSaveOfRecords: function(component, event, helper) {
         return new Promise(function(resolve, reject) {
            try {
                console.log('triggerImmedieteAutoSaveOfRecords.send')
                let recordsToIgnore = {};
                //let currentAccountBeingSaved = cmp.get('v.currentAccount');
                //let checklistBeingSaved = cmp.get('v.viewPEOChecklist');
           
                let autoSaveEvt = component.get('v.saveAction');
                autoSaveEvt(component, event, helper, true)
                .then(function(result) {
                    console.log('triggerImmedieteAutoSaveOfRecords.recieve');
                    resolve(result);
                })
                .catch(function(err) {
                    console.log('err:' + err);
                })
            } catch(e) {
                console.log('triggerImmedieteAutoSaveOfRecords err');
                console.log(e);
            }  
        })
    },
    
    saveImplementationQuestions: function(component, event, helper) {
         console.log('>>>save function '+component.get('v.currentAccount.Id'));
        console.log('>>>>ready to finalize in save::'+component.get("v.implementationChecklist.Ready_to_Finalize__c"));
        console.log('>>>>ready to finalize in save::'+JSON.stringify(component.get("v.implementationChecklist")));
        console.log('current Account', component.get('v.currentAccount.Id'));
        component.set("v.isLoading",true);
        var saveImplChecklist = component.get('c.savePEOImplementationChecklist');
        var implChecklist = component.get('v.implementationChecklist');
        /*implChecklist.PEO_Underwriting_Checklist__c = component.get('v.peoChecklist.Id');
        implChecklist.Prospect_Client__c = component.get('v.currentAccount.Id');
        var parentImpCheckListId =  component.get('v.parentImplChecklist.Id')
        if(parentImpCheckListId){
            //implChecklist.Parent_Implementation_Checklist__c = parentImpCheckListId;
        }*/
        console.log('implChecklistimplChecklistimplChecklist', JSON.stringify(implChecklist));
        var updateChecklist = true;
        saveImplChecklist.setParams({
            implChecklist: implChecklist,   
            updateDates : false,
            updateFinalizeDate : true
        });
        saveImplChecklist.setCallback(this, function(res) {
            
            console.log('>>>>>>>response saving:: '+JSON.stringify(res.getReturnValue()));
            if (res.getState() != 'SUCCESS') {
                console.log('>>>>>>>error in saving:: '+JSON.stringify(res.getError()));
            }else{
                let data = res.getReturnValue();
                var toastEvent = $A.get("e.force:showToast");
                if(data.isSuccessful){
                    component.set('v.implementationChecklist', data.implChecklist);
                    toastEvent.setParams({
                        title: 'Success',
                        message: 'Implementation Checklist saved successfully!',
                        type: 'SUCCESS'
                    });
                }else{
                    console.log('>>>>error res::'+res.getReturnValue());
                   	 	var errors = res.getReturnValue();
                               console.log(errors.ErrorMessage);             
                    toastEvent.setParams({
                        title: 'Error',
                        message: 'Failed to save Implementation Checklist!' + errors.ErrorMessage ,
                        type: 'ERROR'
                    });
                }
                toastEvent.fire();
            }
            
            window.setTimeout(
                $A.getCallback(function() {
                    component.set("v.isLoading",false);
                }), 3000
            );
        })
       $A.enqueueAction(saveImplChecklist);
    },
    
    checkValidPromise : function(component, event, helper){
        return new Promise(function(resolve, reject) {
            try{
                
                resolve(helper.checkValidity(component, event, helper));
            }
            catch(e) {
                console.log(e);
                reject(false);
            }
        });
    },
    
    runAutoSave: function(component, event, helper, field) {
        helper.checkValidPromise(component, event, helper)
        .then($A.getCallback(function() {
            let fieldName = field.get('v.name');
            let currAcc = component.get("v.currentAccount");
            let fieldAPIName, objectAPIName, fieldValue;
            
            if (fieldName) {
                let splitName =  fieldName.split('.');
                objectAPIName = splitName[0];
                fieldAPIName = splitName[1];
            }
            fieldValue = field.get('v.value');
            if(fieldValue && fieldValue.length){
                try {
                    
                    let recordId;
                    if (objectAPIName == 'Account') recordId = currAcc.Id;
                    if (objectAPIName == 'PEO_Implementation_Checklist__c') recordId = component.get('v.implementationChecklist.Id');
                    if (objectAPIName == 'PEO_Onboarding_Checklist__c') recordId = component.get('v.implementationChecklist.PEO_Underwriting_Checklist__c');
                    //recordId = component.get('v.implementationChecklist.Id');
                    console.log(field);
                    let autoSaveEvt = component.getEvent('autoSave');
                    autoSaveEvt.setParam('objectName', objectAPIName);
                    autoSaveEvt.setParam('accountName', currAcc.Name);
                    autoSaveEvt.setParam('accountId', currAcc.Id);
                    autoSaveEvt.setParam('sendImmediete', true);
                    autoSaveEvt.setParam('fieldName', fieldAPIName);
                    autoSaveEvt.setParam('fieldValue', fieldValue);
                    autoSaveEvt.setParam('recordId', recordId);
                    autoSaveEvt.fire();
                    let relatedFieldList = component.get('v.relatedFieldList');
                    relatedFieldList.push('PEOUW_Msng_Sec__c');
               
                
            } catch(e) {
                console.log('err occured:')
                console.log(e);
            }
        }
    }))
    },
    
    checkForMissingFields : function(component, event, helper){
        //Create custom labels for each tab and call here
        var implChk = component.get("v.implementationChecklist");
        var missingFields = [];
        console.log('Current Account:');
        console.log(component.get('v.currentAccount'));
        var missingSections = [];
        //= component.get('v.currentAccount.Name')+':';
        var sections = ['General Info','Setup Info ','Compliance ','Cobra '];
        var ParentAccountId = component.get("v.ParentAccountId");
        var currentAccount = component.get("v.currentAccount.Id");
        for(const section of sections){
            var sectionFields = [];
            var sectionFieldList= [];
            console.log('section:'+section);
            if(section == 'General Info'){
                sectionFieldList = $A.get("$Label.c.PEOUW_IMPL_GI").split(',')
                if(currentAccount != ParentAccountId){
                    //const index = sectionFieldList.indexOf('Select_Entity_Structure__c');
                    //sectionFieldList.splice(index, 1);
                    //console.log('child sectionFieldList values:'+sectionFieldList);
                }
                
            }
            else if(section == 'Setup Info '){
                if(currentAccount == ParentAccountId){
                    sectionFieldList = $A.get("$Label.c.PEOUW_IMPL_StpInfo_1").split(',');
                    var sectionFieldList2 = $A.get("$Label.c.PEOUW_IMPL_StpInfo_2").split(',');
                    for(const sfl2 of sectionFieldList2){
                        sectionFieldList.push(sfl2);
                    }
                }
                else{
                    sectionFieldList.push('Client_currently_offer_a_401k_plan__c');
                }
                
                //console.log('Setup Info sectionFieldList:'+sectionFieldList);
            }
            else if(section == 'Compliance ')sectionFieldList = $A.get("$Label.c.PEOUW_IMPL_Compliance").split(',')
            else if(section == 'Cobra ')sectionFieldList = $A.get("$Label.c.PEOUW_IMPL_Cobra").split(',')
            for (const splitField of sectionFieldList){
                //console.log('splitField:'+splitField);
                sectionFields.push(splitField);
            }
            //console.log('checkForMissingFields sectionFields:'+sectionFields);
            var relatedFldsMissing = helper.checkRelatedMissingFields(component, event, helper,section);
            console.log('related fields missing:'+relatedFldsMissing);
            if(!relatedFldsMissing){
                for (const field of sectionFields){
                    console.log(field+':'+implChk[field]);
                    if(implChk[field] == undefined || implChk[field] == null){
                        missingSections.push(section+" ");
                        break;
                    }
                }
            }
            else{
                missingSections.push(section+" ");
            }
        }
        if(missingSections.length >0){
            var missingSectionString = component.get('v.currentAccount.Name')+':'+" "+missingSections;
            component.set('v.missingSectionString',missingSectionString);
            console.log('missingSectionString:'+missingSectionString);
            return true;
        }
        console.log('Total validated fields:'+sectionFields.length);
        console.log('Missing fields:'+missingFields.length);
        console.log('missingSectionString:'+component.get('v.missingSectionString'));
        return false;
        
    },
    
   	showUserMsg: function(cmp, err) {
        console.log('Shpuld show msg')
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: err.t,
            message: err.m,
            type: err.ty
        });
        toastEvent.fire(); 
    },
    
    checkRelatedMissingFields : function(component, event, helper, section){
        console.log("checkRelatedMissingFields");
        var impCheckList =  component.get("v.implementationChecklist");
        var ParentAccountId = component.get("v.ParentAccountId");
        var currentAccount = component.get("v.currentAccount.Id");
        var accountInfo = component.get("v.currentAccount");
        var peoChecklist = component.get("v.peoChecklist");
        if(section == 'Setup Info '){
           // if(currentAccount == ParentAccountId){
           if(impCheckList.PEO_Underwriting_Checklist__r.Payroll_Frequency__c == '' || impCheckList.PEO_Underwriting_Checklist__r.Payroll_Frequency__c == undefined)return true;
                const payFrequency = {
                    showWeekly: ["Period_Begin_Dates_Weekly__c", "Period_End_Dates_Weekly__c", "Anticipated_First_Check_Date_Weekly__c", "Anticipated_First_Run_Date_Weekly__c"],
                    showBiWeekly: ["Period_Begin_Date_BiWeekly__c", "Period_End_Date_BiWeekly__c", "Anticipated_First_Check_Date_BiWeekly__c", "Anticipated_First_Run_Date_BiWeekly__c"],
                    showSemiMonthly: ["Period_Begin_Date_SemiMonthly__c", "Period_End_Date_SemiMonthly__c", "Anticipated_First_Check_Date_SemiMonth__c", "Anticipated_First_Run_Date_SemiMonthly__c"],
                    showMonthly: ["Period_Begin_Date_Monthly__c", "Period_End_Date_Monthly__c", "Anticipated_First_Check_Date_Monthly__c", "Anticipated_First_Run_Date_Monthly__c"],
                };
                const freqs = ["showWeekly","showBiWeekly","showSemiMonthly","showMonthly"];
                for (const sfreq of freqs){
                    if(component.get("v."+sfreq) == true){
                        console.log('sfreq:'+sfreq+'is True');
                        for (const splitFreq of payFrequency[sfreq]){
                            if(impCheckList[splitFreq] == undefined || impCheckList[splitFreq] == null){
                                return true;
                                break;
                            }
                        }
                    }
                }
            if(currentAccount == ParentAccountId){
                if(component.get("v.implementationChecklist.ACI__c") == true && !component.get("v.implementationChecklist.ACI_Options__c")){
                    return true;
                }
                if(impCheckList.Client_currently_offer_a_401k_plan__c == 'Yes' && !impCheckList.Is_it_a_Paychex_401k__c){
                    return true;
                }
                if(impCheckList.Client_offer_a_Health_Savings_Account__c == 'Yes'){
                    if((impCheckList.Employer_Contribution_HSA_Individual__c == '' || impCheckList.Employer_Contribution_HSA_Individual__c == null 
                        || impCheckList.Employer_Contribution_HSA_Individual__c == undefined || impCheckList.Employer_Contribution_HSA_Individual__c == ' ')
                       && impCheckList.Employer_Contribution_HSA_Individual__c != 0 ){
                        return true;
                    }
                    if((impCheckList.Employer_Contribution_HSA_Family__c == '' || impCheckList.Employer_Contribution_HSA_Family__c == null 
                        || impCheckList.Employer_Contribution_HSA_Family__c == undefined || impCheckList.Employer_Contribution_HSA_Family__c == ' ') 
                       && impCheckList.Employer_Contribution_HSA_Family__c != 0 ){
                        return true;
                    }
                }
                //Begin of changes Srujan
                if(impCheckList.Offer_a_PEO_Flexible_Spending_Account__c == 'Yes'){
                    if((impCheckList.Health_Flexible_Spending_Account__c == '' || impCheckList.Health_Flexible_Spending_Account__c == null 
                        || impCheckList.Health_Flexible_Spending_Account__c == undefined || impCheckList.Health_Flexible_Spending_Account__c == ' ')){
                        return true;
                    }
                    if((impCheckList.Dependent_Care_Flexible_Spending_Account__c == '' || impCheckList.Dependent_Care_Flexible_Spending_Account__c == null 
                        || impCheckList.Dependent_Care_Flexible_Spending_Account__c == undefined || impCheckList.Dependent_Care_Flexible_Spending_Account__c == ' ')){
                        return true;
                    }
                }
                //End of changes
                
                if(impCheckList.Approved_to_self_retain_ancillary_prods__c == 'Yes'){
                    if(!impCheckList.Requesting_to_self_retail_ancillary_prod__c){
                        return true;
                    }else if(impCheckList.Requesting_to_self_retail_ancillary_prod__c == 'Yes'){
                        if(!impCheckList.Self_retain_ancillary_products__c){
                            return true;
                        }
                    }
                }
            }
            else{
                if(impCheckList.Client_currently_offer_a_401k_plan__c == 'Yes' && !impCheckList.Is_it_a_Paychex_401k__c){
                    return true;
                }
            }
        }// End setup Info
        else if(section == 'General Info'){
            if(currentAccount == ParentAccountId){
                /*if(impCheckList.Select_Entity_Structure__c == 'Part Controlled/Part Common'){
                    if(!impCheckList.Controlled_Ownership_Section__c)return true;
                    if(!impCheckList.Common_Ownership_Section__c)return true;
                }*/
                //if(impCheckList.Select_Entity_Structure__c == 'Single Entity'){
                    if(!impCheckList.Authorized_Officer_Name__c || !impCheckList.Authorized_Officer_Title__c)return true;
                //}
                if(!impCheckList.Requested_Benefits_Effective_Date__c )return true; 
                if(impCheckList.Did_the_client_have_prior_wages__c == 'Yes'&& !impCheckList.Year_To_Date_payments_to_be_applied__c)return true;
            }
            if(impCheckList.Require_multiple_client_codes__c == 'Yes' && !impCheckList.Reason_for_multiple_client_codes__c)return true;
            /*if(accountInfo.Date_of_Incorporation__c == '' || accountInfo.Date_of_Incorporation__c == undefined)return true;*/
        }
            else if(section == 'Compliance '){
                const busEntTypes = ['Sole Proprietor','Partnership','Limited Liability Partnership'];
                var entityIncludes = busEntTypes.includes(component.get("v.implementationChecklist.Business_Entity_Type__c"));
                if(entityIncludes && !impCheckList.Is_the_Company_a_Partnership__c)return true; 
                if(impCheckList.Is_the_Company_a_Partnership__c == 'Yes' && !impCheckList.Partner_user_of_company__c)return true; 
                if(impCheckList.Own_5_of_the_company__c == 'Yes'  && !impCheckList.Users_own_5_of_company__c)return true; 
                if(component.get("v.implementationChecklist.Business_Entity_Type__c") == 'S Corporation'){
                    if(!impCheckList.Own_2_of_the_company__c)return true
                    else if(impCheckList.Own_2_of_the_company__c == 'Yes' && !impCheckList.Users_own_2_of_company__c)return true
                    else if(!impCheckList.Family_members_of_5_2_1_owners__c)return true
                    else if(impCheckList.Family_members_of_5_2_1_owners__c == 'Yes' && !impCheckList.Name_of_members_of_5_2_1_owners__c)return true;
                }
                if(component.get("v.implementationChecklist.Business_Entity_Type__c") == 'C Corporation'){
                    if(!impCheckList.Own_5_of_the_company__c)return true
                    else if(impCheckList.Own_5_of_the_company__c == 'Yes' && !impCheckList.Users_own_5_of_company__c)return true;
                }
                if(impCheckList.Own_1_of_the_company_earn_150k__c == 'Yes' && !impCheckList.Users_own_1_of_company_earn_150k__c)return true;
                if(impCheckList.Any_individuals_who_are_officers__c == 'Yes' && !impCheckList.Names_individuals_who_are_officers__c && !impCheckList.Any_officers_of_company_earn_185K__c)return true;
                if(impCheckList.Any_officers_of_company_earn_185K__c == 'Yes' && !impCheckList.Names_of_officers_of_company_earn_185K__c)return true;
                if(impCheckList.Any_employee_earned_130K_in_prior_year__c == 'Yes' && !impCheckList.User_earned_130K_in_prior_year__c)return true;
            }
        return false;
    },
    
    relatedFieldChanges: function(cmp, e, helper,objectAPINameToSave, relatedFieldListToSave) {
        try {
            console.log('relatedFieldListToSave:'+relatedFieldListToSave);
            console.log('objectAPINameToSave:'+objectAPINameToSave);
            let objectAPIName = '';
            let recordId;
            let Account = cmp.get('v.currentAccount');
            let fieldName,fieldValue;
            if(relatedFieldListToSave.length>0){
                relatedFieldListToSave.forEach(function (item, index) {
                    console.log(item, index);
                    fieldName = item;
                    fieldValue = cmp.get(`v.implementationChecklist.`+item);
                    recordId = cmp.get('v.implementationChecklist.Id');
                    console.log("fieldName:"+fieldName+"fieldValue:"+fieldValue);
                    objectAPIName = objectAPINameToSave;
                    let autoSaveEvt = cmp.getEvent('autoSave');
                    autoSaveEvt.setParam('objectName', objectAPIName);
                    autoSaveEvt.setParam('accountId', Account.Id);
                    autoSaveEvt.setParam('fieldName', fieldName);
                    autoSaveEvt.setParam('fieldValue', fieldValue);
                    autoSaveEvt.setParam('recordId', recordId);
                    autoSaveEvt.setParam('accountName', Account.Name);
                    autoSaveEvt.fire();
                });
            }
            
        } catch(e) {
            console.error('Error sendMultiFieldUpdate');
            console.error(e);
        }
    },
    
})