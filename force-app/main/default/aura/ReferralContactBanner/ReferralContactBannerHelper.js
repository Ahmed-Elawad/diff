({
    getReferralContactWrapper: function(component, event, helper) {
        var action = component.get("c.getReferralContactWrapperById");
        var referralContactId = component.get("v.referralContactId");

        action.setParams({
            referralContactId: referralContactId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') {
                var referralContactWrapper = response.getReturnValue();
                console.dir(referralContactWrapper);
                component.set("v.referralContactWrapper", referralContactWrapper);

                let refCndt = referralContactWrapper.refConData;
                let ppUd = referralContactWrapper.pPUDData;
                console.log('ref cn dt==='+JSON.stringify(refCndt));
                if(refCndt.isComUserFound || not(empty(ppUd))){
                    component.set("v.isCommunityUser",true);
                    component.set("v.commUser",refCndt.user);
                    /*if($A.util.isEmpty(refCndt.user.LastLoginDate)){//logged in user
                        component.set("v.enrolledUser",true);
                    }else{//enrolled user
                        component.set("v.loggedInUser",true);
                    }*/
                    if($A.util.isEmpty(refCndt.user.Community_User_First_Login__c)){//logged in user
                        component.set("v.enrolledUser",true);
                    }else{//enrolled user
                        component.set("v.loggedInUser",true);
                    }
                    console.log('Referral contact data:');
                    console.log(referralContactWrapper.ReferralContact);
                    /*if(referralContactWrapper.ReferralContact.CPA_Program_status__c != 'undefined' && referralContactWrapper.ReferralContact.CPA_Program_status__c != null){
                        if(referralContactWrapper.ReferralContact.CPA_Program_status__c == 'Unenrolled/no longer in Program'){
                            component.set("v.displayRefContChicklet",false);
                        }
                        else{
                            component.set("v.displayRefContChicklet",true);
                        }
                        //console.log('displayRefContChicklet:'+displayRefContChicklet);
                    }*/
                    var pPUDDataEvent;
                    var CPAPrgStatus;
                    console.log('Partner portal user details:');
                    console.log(ppUd);
                    try{
                        if(ppUd != 'undefined' && referralContactWrapper.pPUDData.event__c != 'undefined' ){
                            pPUDDataEvent = referralContactWrapper.pPUDData.event__c;
                        }
                    }
                    catch(e){
                        console.log('PPUD Undefined:'+e);
                        component.set("v.displayRefContChicklet",false);
                    }
                    
                    if(referralContactWrapper.ReferralContact.CPA_Program_status__c != 'undefined'){
                        CPAPrgStatus = referralContactWrapper.ReferralContact.CPA_Program_status__c;
                    }
                    console.log('Partner portal event:'+pPUDDataEvent);
                    console.log('CPA_Program_status__c:'+CPAPrgStatus);
                    if(CPAPrgStatus != 'undefined' && CPAPrgStatus != null){
                        console.log('CPA_Program_status__c:'+CPAPrgStatus+' value exist');
                        if(CPAPrgStatus == 'Invited' || CPAPrgStatus == 'Enrolled'){
                            component.set("v.displayRefContChicklet",true);
                        }
                    }
                    else if(pPUDDataEvent != 'undefined' && pPUDDataEvent != null){
                        console.log('Partner portal event:'+pPUDDataEvent+' value exist');
                        if(pPUDDataEvent == 'Invited' || pPUDDataEvent == 'Enrolled'){
                            component.set("v.displayRefContChicklet",true);
                        }
                    }
                        else{
                            component.set("v.displayRefContChicklet",false);
                        }
                }else{
                    component.set("v.isCommunityUser",false);
                }

                helper.populateEngagedDetails(component, referralContactWrapper.ReferralContact)
            } else {
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    },


    populateEngagedDetails: function(component, referralContact) {
        var engagedTextList = [];
        if(referralContact.CPA_Relationship_Manager__c) {
            engagedTextList.push("ABDM Engaged");
        }
        if(referralContact.ARM_owner__c) {
            engagedTextList.push("ARM Engaged");
        }
        if(referralContact.CAS_Engaged__c) {
            engagedTextList.push("CAS Engaged");
        }
        if(referralContact.Independent_Agent_Relationship_Manager__c) {
            engagedTextList.push("IA Relationship Manager");
        }

        component.set("v.engagementTextDisplayList", engagedTextList);
    },
    checkAccessPerm : function(component, event, helper){
        var action2 = component.get("c.hasCustomPermission");
        action2.setCallback(this, function(response){
            console.log('hasPermission in ref contactsss'+response.getReturnValue());
            component.set("v.hasPermission", response.getReturnValue())
        });
        $A.enqueueAction(action2);
    }
})