({
    updateComponent : function(component, event, helper) {  
       
        component.set("v.selectedLabel", "Touchpoint");
        var touchpointToView = component.get("v.cadenceTouchpoint");
        var touchpointType = touchpointToView.Cadence_Touchpoint_Step__r.Touchpoint_Type__c;
        var cadActivity = touchpointToView.CarRecord__r.Activity_Log__c;
        component.set("v.createOppBtnLabel",touchpointToView.Cadence__r.CreateOppLabel__c);
        var referralSource = component.get("v.cadenceTouchpoint.CarRecord__r.IsReferralSource__c");
        if(referralSource){
            component.set("v.accountContactLabel","Referral Account/Referral Contact Detail");
        }else{
            component.set("v.accountContactLabel"," Account/Contact Detail");
        }
        var buttonLabel = component.get("v.cadenceTouchpoint.TouchpointObject__c");
        console.log("touchpoint object in question: "+buttonLabel);
        if(buttonLabel=="Referral_Account__c"){
            component.set("v.goToButtonLabel","Referral Account");
        }else{
            component.set("v.goToButtonLabel",buttonLabel);
        }
        var test3 = component.get("v.accountContactLabel");
        console.log("TEST LABEL: "+JSON.stringify(test3));
        component.set("v.ownedByQueue", touchpointToView.OwnedByQueue__c);
        component.set("v.ownerStaysQueue", touchpointToView.Cadence__r.OwnedByQueue__c);
        var isThisTelemarketing = touchpointToView.Cadence__r.IsTelemarketing__c;
        component.set("v.isTelemarketing", touchpointToView.Cadence__r.IsTelemarketing__c);
        component.set("v.recordContact", touchpointToView.CarRecord__r.ContactId__r);
        component.set("v.recordLead", touchpointToView.CarRecord__r.LeadId__r);
        component.set("v.recordReferralAccount", touchpointToView.CarRecord__r.ReferralAccount__r);
        if (touchpointToView.CarRecord__r.ContactId__r != null) {
           component.set("v.recordIsSignificant", touchpointToView.CarRecord__r.ContactId__r.SignificantContact__c);
           component.set("v.missingSignificant", false);
           //component.set("v.consentToText", touchpointToView.CarRecord__r.AccountId__r.SignificantContact__r.Consent_To_Text__c);
        } else if (touchpointToView.CarRecord__r.LeadId__r != null) {
           component.set("v.recordIsSignificant", touchpointToView.CarRecord__r.LeadId__r.SignificantLead__c);
           component.set("v.missingSignificant", false);
        } else if (touchpointToView.CarRecord__r.IsReferralSource__c) {
            component.set("v.missingSignificant", true);
        }else {
            var errorMessage = 'Please Note: The '+touchpointToView.Cadence__r.CreateOppLabel__c+' button is disabled. Please select a Significant Contact to enable.';
            component.set("v.missingSignificant", true);
            component.set("v.noSignificantErrorMessage", errorMessage);
        }
        var ctct = component.get("v.recordContact");
        //alert("isTelemarketing="+component.get("v.isTelemarketing")+" Contact: "+ctct.Name);
        component.set("v.cadenceActivity", cadActivity);
        component.set("v.displayEmail", false);
        component.set("v.displayTpNotes", false);
        component.set("v.displayDetails", true);
        component.set("v.emailExtra", touchpointToView.EmailExtraText__c);
        if (isThisTelemarketing) {
           component.set('v.activityTableColumns', [
            { label: 'Subject', fieldName:'Link' , type:'url',typeAttributes: { label: { fieldName: 'subject' }, target: '_self'} },
            { label: 'Activity Date', fieldName: 'activityDate', type: 'date-local', typeAttributes: {
                    year: '2-digit',
                    month: 'numeric',
                    day: 'numeric'}},
            { label: 'Contact Name', fieldName: 'contactName', type: 'text'},
            { label: 'Activity Type', fieldName: 'activityType', type: 'text'},
            { label: 'Owner Name', fieldName: 'ownerName', type: 'text'},
            { label: 'Phone Dialed', fieldName: 'phone', type: 'phone'},
            { label: 'Recording URL', fieldName: 'recordingUrl', type: 'url', typeAttributes: {
                tooltip: 'Play the recording', label: 'Play Recording'
               }}
          ]);
        } else {
           component.set('v.activityTableColumns', [
            { label: 'Subject', fieldName:'Link' , type:'url',typeAttributes: { label: { fieldName: 'subject' }, target: '_self'} },
            { label: 'Activity Date', fieldName: 'activityDate', type: 'date-local', typeAttributes: {
                    year: '2-digit',
                    month: 'numeric',
                    day: 'numeric'}},
            { label: 'Contact Name', fieldName: 'contactName', type: 'text'},
            { label: 'Activity Type', fieldName: 'activityType', type: 'text'},
            { label: 'Owner Name', fieldName: 'ownerName', type: 'text'}
          ]);
        }
        helper.setCadenceSteps(component);
        helper.setActivitiesList(component);
        helper.setActivitiesList2(component);
        //helper.setCurrentUserId(component, event, helper);
        if(touchpointToView.TouchpointObject__c != 'Lead'){
            
            component.set('v.oppTableColumns', [
               //{ label: 'Name', fieldName: 'oppName', type: 'text'},
               { label: 'Name', fieldName:'Link' , type:'url',typeAttributes: { label: { fieldName: 'oppName' }, target: '_self'} },

               { label: 'Status', fieldName: 'status', type: 'text'},
               { label: 'Owner Name', fieldName: 'owner', type: 'text'},
               { label: 'Run Effective Date', fieldName: 'closeDate', type: 'date-local', typeAttributes: {
                    year: '2-digit',
                    month: 'numeric',
                day: 'numeric'}}
           ]);

            component.set('v.prodTableColumns', [
               { label: 'Name', fieldName: 'assetName', type: 'text'},
               { label: 'Start Date', fieldName: 'startDate', type: 'date-local', typeAttributes: {
                    year: '2-digit',
                    month: 'numeric',
                    day: 'numeric'}},
               { label: 'End Date', fieldName: 'endDate', type: 'date-local', typeAttributes: {
                    year: '2-digit',
                    month: 'numeric',
                    day: 'numeric'}},
               { label: 'Lost Reason', fieldName: 'lostReason', type: 'text'}
           ]);

            helper.setOpptyList(component);
            helper.setProdList(component);
            component.set("v.touchpointIsAccount",true);
            component.set("v.touchpointIsLead",false);
            component.set("v.recordBeingViewed", "Account");
        } else {
            component.set("v.touchpointIsAccount",false);
            component.set("v.touchpointIsLead",true);
            component.set("v.recordBeingViewed", "Lead");
        }
        if(touchpointToView.TouchpointObject__c != 'Lead' && touchpointToView.CarRecord__r.ReferralAccount__r!=null){
            component.set("v.touchpointIsRefAccount",true);
        }
        if(touchpointToView.TouchpointObject__c != null){
            component.set("v.touchpointIcon", 'standard:'+touchpointToView.TouchpointObject__c.toLowerCase());
        }
        helper.checkEmailOptions(component, helper, touchpointToView, touchpointType);
        helper.setRemovalReasonList(component);
        helper.setStepOptions(component, event, helper);
        //helper.setInsightList(component);
       	const empApi = component.find('empApi');
        component.set("v.displayScreen", 'displayDetails');
        var secondaryUser = touchpointToView.CarRecord__r.Secondary_User__c;
        var carOwner = touchpointToView.CarRecord__r.Cadence_Owner__c;
        var notAllowRemoveCad = touchpointToView.Cadence__r.NotAllow_Secondary_user_to_close_Cadence__c;
        if(secondaryUser != null &&  touchpointToView.OwnerId == secondaryUser){
         component.set("v.isSecondaryUser", true);    
         component.set("v.notAllowCadRemove", notAllowRemoveCad);
        }
    },
    subscribe : function(component, event, helper){
       var currentTouchpoint = component.get("v.cadenceTouchpoint");
        const empApi = component.find('empApi');
        const channel = component.get('v.channel');
        const replayId = -1;
        const callback = function (message) {
            console.log('Event Received : ' + JSON.stringify(message));
            var updatedTouchpoint = message.data.payload.TouchpointId__c;
            if(currentTouchpoint.Id == updatedTouchpoint){
                /*helper.displayToast('success','Confirmation!',"The Touchpoint has been updated");
                // component.set("v.cadenceTouchpoint", null);
                var cmpEvent = component.getEvent("updateTouchpointList");
                cmpEvent.setParams({"currentTouchPoint" : currentTouchpoint,
                                   "updateTouchpoint" : false});
                cmpEvent.fire();*/
                helper.refreshTouchpoints(component, false, true);
            }
        };
        const saveSubscription = function (subscription) {
            console.log('Subscription request sent to: ', subscription.channel);
            component.set('v.subscription', subscription);
        };
        empApi.subscribe(channel, replayId, $A.getCallback(callback)).then(saveSubscription);
      },
    setActivitiesList : function(component) {
        // clear out the values
        component.set("v.touchpointParentInfo",null);
        component.set("v.openActivityList",null);
        component.set("v.activityHistoryList",null);
        component.set("v.latestActivity",null);
        var currentTouchpoint = component.get("v.cadenceTouchpoint");  
        var action = component.get("c.generateParentData");
        action.setParams({"touchpoint": currentTouchpoint});
        action.setCallback(this, function(response) {
            var touchpointAcct = response.getReturnValue();
            var state = response.getState();
            //alert('touchpointAcct='+touchpointAcct);
            if (state === "SUCCESS") {
                if(touchpointAcct != null){
                    component.set("v.touchpointParentInfo", touchpointAcct);
                    if(touchpointAcct.OpenActivities !=null){
                        component.set("v.openActivityList", touchpointAcct.OpenActivities);
                    }
                    if(touchpointAcct.ActivityHistories !=null && touchpointAcct.ActivityHistories.length > 0){
                        component.set("v.latestActivity", touchpointAcct.ActivityHistories[0]);
                        component.set("v.activityHistoryList", touchpointAcct.ActivityHistories);
                    }
                }
            }});
        $A.enqueueAction(action);
    },
    setActivitiesList2 : function(component) {
        // clear out the values
        component.set("v.allActivityList",null);
        var currentTouchpoint = component.get("v.cadenceTouchpoint");  
        var action = component.get("c.getActivity");
        action.setParams({"touchpoint": currentTouchpoint});
        action.setCallback(this, function(response) {
            var activityResponse = response.getReturnValue();
            var state = response.getState();
            //alert('touchpointAcct='+touchpointAcct);
            if (state === "SUCCESS") {
                if(activityResponse != null){
                    // console.log(activityResponse);
                    var tempActivityResponse = activityResponse;
                    tempActivityResponse.map((rec)=>{
                        if(rec.tsk!= null){
                            rec.Link = '/'+rec.tsk.Id;
                        }else{
                            rec.Link = '';

                        }
                        return rec;
                    });
                    console.log(tempActivityResponse);
                    //component.set("v.allActivityList", activityResponse);
                    component.set("v.allActivityList", tempActivityResponse);
                }
                // console.log(activityResponse);
            }});
        $A.enqueueAction(action);
    },
    setInsightList: function(component, helper){
        var currentTouchpoint = component.get("v.cadenceTouchpoint"); 
        var queryContactsOnly = component.get("v.queryContactsOnly"); 
        var action = component.get("c.getInsightList");
        action.setParams({"touchpoint": currentTouchpoint,
                          "onlyQueryContacts": queryContactsOnly});
        action.setCallback(this, function(response) {
            var insightWrapper = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                var contactList = insightWrapper.contactList != null ? insightWrapper.contactList : insightWrapper.leadList;
                component.set("v.touchpointContactList", contactList);
                component.set('v.ctctTableData', contactList);
                if(insightWrapper.insightsList != null){
                    component.set("v.emailInsightData", insightWrapper.insightsList);
                    //Set Insight table
                    component.set('v.emailInsightTableColumns', [
                        { label: 'Sender', fieldName: 'fromName', type: 'text'},
                        { label: 'Contact Name', fieldName: 'contactName', type: 'text'},
                        { label: 'Contact Email', fieldName: 'emailAddress', type: 'text'},
                        { label: 'Email Template Name', fieldName: 'templateName', type: 'text'},
                        { label: 'Subject', fieldName: 'subject', type: 'text'},
                        { label: 'Date Sent', fieldName: 'dateSent', type: 'date', 
                         typeAttributes:{
                             year: "numeric",
                             month: "long",
                             day: "2-digit"
                         }},
                        { label: 'Opened?', fieldName: 'opened', type: 'boolean', cellAttributes: { alignment: 'center' }},
                        { label: 'Last Open Date', fieldName: 'lastOpenDate', type: 'date',   
                         typeAttributes:{
                             year: "numeric",
                             month: "long",
                             day: "2-digit"
                         }},
                        { label: '# Times Opened', fieldName: 'timesOpened', type: 'number'}
                    ]);
                }
            }});
        $A.enqueueAction(action);
    },
    setTouchpointOwner : function(component, helper) {
        var currentTouchpoint = component.get("v.cadenceTouchpoint");          
        var action = component.get("c.updateOwner");
        action.setParams({"touchpoint": currentTouchpoint,
                          "updateAll": false});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.displayToast('success','Confirmation!','The touchpoint owner has been updated');
                helper.refreshTouchpoints(component, false, false);
            }});
        $A.enqueueAction(action);
    },
    setCadenceOwner : function(component, helper) {
        var currentTouchpoint = component.get("v.cadenceTouchpoint");          
        var action = component.get("c.updateOwner");
        action.setParams({"touchpoint": currentTouchpoint,
                          "updateAll": true});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.displayToast('success','Confirmation!','The cadence owner has been updated');
                helper.refreshTouchpoints(component, false, false);
            }});
        $A.enqueueAction(action);
    },
    
    
    setOpptyList : function(component) {
        var currentTouchpoint = component.get("v.cadenceTouchpoint");          
        var action = component.get("c.generateOpptyList");
        action.setParams({"touchpoint": currentTouchpoint});
        action.setCallback(this, function(response) {
            var opptyList = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                var tempOpptyList = opptyList;
                console.log("Before tempList: "+JSON.stringify(tempOpptyList));
                tempOpptyList.map((rec)=>{
                    if(rec.opp!= null){
                        rec.Link = '/'+rec.opp.Id;
                    }else{
                        rec.Link = '';
                    }
                    return rec;
                });
                console.log("temp opptyList:"+JSON.stringify(tempOpptyList));
                component.set("v.opportunityList", opptyList);
            }});
        $A.enqueueAction(action);
    },
    refreshContact: function(component, event, helper) {
        var ctct = component.get("v.recordContact");
        var action = component.get("c.queryContact");
        action.setParams({"p_ctctId": ctct.Id});
        action.setCallback(this, function(response) {
            var updatedCtct = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.recordIsSignificant", updatedCtct.SignificantContact__c);
                component.set("v.recordContact", updatedCtct);
            }});
        $A.enqueueAction(action);
    },
    refreshLead: function(component, event, helper) {
        var ld = component.get("v.recordLead");
        var action = component.get("c.queryLead");
        action.setParams({"p_leadId": ld.Id});
        action.setCallback(this, function(response) {
            var updatedLead = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.recordIsSignificant", updatedLead.SignificantLead__c);
                component.set("v.recordLead", updatedLead);
            }});
        $A.enqueueAction(action);
    },
    setProdList : function(component) {
        var currentTouchpoint = component.get("v.cadenceTouchpoint");          
        var action = component.get("c.getAssets");
        action.setParams({"touchpoint": currentTouchpoint});
        action.setCallback(this, function(response) {
            var prodList = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.productList", prodList);
            }
            //console.log(response);
        });
        $A.enqueueAction(action);
    },
    setRefCtctEmailList: function(component){
        console.log('Set Referral Contact is running');
        var currentTouchpoint = component.get("v.cadenceTouchpoint");    
        // console.log("the current touchpoint Id: "+currentTouchpoint.ReferralAccount__c);  
        // console.log("type of Touchpoint ID: "+typeof(currentTouchpoint.ReferralAccount__c));    
        var action = component.get("c.getRefCtctEmailList");//add a method in workqueuecontroller with method from TouchPointExtension
        action.setParams({"refActId": currentTouchpoint.ReferralAccount__c});
        // console.log('RefActID: '+ currentTouchpoint.ReferralAccount__c+" refActId type: "+typeof(currentTouchpoint.ReferralAccount__c));
        action.setCallback(this,function(response){
            var refctctEmailList = response.getReturnValue();
           
            //console.log("pre-selected Id List"+JSON.stringify(preselectedIds));

            var state = response.getState();
            if(state=== "SUCCESS"){
                var preselectedIds = [];
                var preselectedRefCtctIds =[];
                refctctEmailList.forEach((rec)=>{
                    preselectedIds.push(rec.Contact__c);
                    preselectedRefCtctIds.push(rec.Id);
                });
               
                console.log('Set Referral Contact was successful');
                component.set("v.referralContactEmailOptions",refctctEmailList);
                component.set("v.preselectedContacts",preselectedIds);
                component.set("v.preselectedRefContacts",preselectedRefCtctIds);
                
                var test = component.get("v.preselectedContacts");
                var test2 = component.get("v.preselectedRefContacts");
                console.log("whats in the comonent Pre-selected Contacts: "+ test);
                console.log("whats in the comonent Pre-selected Referral Contacts: "+ test2);
                //console.log('refctctEmailList: '+refctctEmailList);
                var info =  component.get("v.referralContactEmailOptions");
                console.log("whats in  referralContactEmailOptions"+JSON.stringify(info));
               
            }
            if(state ==='ERROR'){
                var errors = JSON.stringify(response.getError());
                console.log(errors);

            }
        });
        $A.enqueueAction(action);
    },
    setCANamesList: function(component){
        console.log('Set Referral Contact is running');
        var currentTouchpoint = component.get("v.cadenceTouchpoint");    
        // console.log("the current touchpoint Id: "+currentTouchpoint.ReferralAccount__c);  
        // console.log("type of Touchpoint ID: "+typeof(currentTouchpoint.ReferralAccount__c));    
        var action = component.get("c.getReferralContactswithAcctId");//add a method in workqueuecontroller with method from TouchPointExtension
        action.setParams({"refActId": currentTouchpoint.ReferralAccount__c});
        // console.log('RefActID: '+ currentTouchpoint.ReferralAccount__c+" refActId type: "+typeof(currentTouchpoint.ReferralAccount__c));
        action.setCallback(this,function(response){
            var refctcts = response.getReturnValue();
            var state = response.getState();
            

            if(state=== "SUCCESS"){
                console.log('Set Create Activity was successful');
                var refctcts2 = JSON.parse(JSON.stringify(refctcts));
                var refctctNames = '';
                refctcts2.forEach((refctct,i)=>{
                    
                    if(i!=refctcts2.length-1){
                        refctctNames += refctct.Name+", ";
                    }else {
                        refctctNames += refctct.Name;

                    }
                    
                });
                console.log("referral Contact Names : "+refctctNames);
                 component.set("v.CANamesList",refctctNames);
                //console.log('refctctEmailList: '+refctctEmailList);
                var info =  component.get("v.CANamesList");
                console.log("whats in  CANamesList: "+info);
            }
            if(state ==='ERROR'){
                var errors = JSON.stringify(response.getError());
                console.log(errors);

            }
        });
        $A.enqueueAction(action);
    },
    setCreateActivityList: function(component){
        var currentTouchpoint = component.get("v.cadenceTouchpoint");   
        var action = component.get("c.getCAContactNames"); 
        action.setParams({"refActId": currentTouchpoint.ReferralAccount__c});
        // console.log('RefActID: '+ currentTouchpoint.ReferralAccount__c+" refActId type: "+typeof(currentTouchpoint.ReferralAccount__c));
        action.setCallback(this,function(response){
            var CAOptions = response.getReturnValue();
            var state = response.getState();
            if(state=== "SUCCESS"){
                console.log('Set Create Activity Options was successful');
                component.set("v.createActivityOptions",CAOptions);
                //console.log('refctctEmailList: '+refctctEmailList);
                var info =  component.get("v.CAOptions");
                console.log("whats in  CAOptions"+JSON.stringify(info));
            }
            if(state ==='ERROR'){
                var errors = JSON.stringify(response.getError());
                console.log(errors);

            }
        });
        $A.enqueueAction(action);
         

    },
    getRefctctName : function(component){
    var refctctId = component.get("v.selectedCARefctctId");   
    var action = component.get("c.getReferralContact"); 
    action.setParams({"refctctId": refctctId});
    action.setCallback(this,function(response){
        var selectedRefctct = response.getReturnValue();
        var state = response.getState();
        if(state=== "SUCCESS"){
            console.log('Get Referral Contact info was successful');
            component.set("v.selectedCARefctct",selectedRefctct);
            //console.log('refctctEmailList: '+refctctEmailList);
            var info =  component.get("v.selectedCARefctct");
            console.log("whats in  selectedCARefctct"+JSON.stringify(info));
        }
        if(state ==='ERROR'){
            var errors = JSON.stringify(response.getError());
            console.log(errors);

        }
    });
    $A.enqueueAction(action);

    },
    getEmailContactIds : function(component){
        var selectedRefCtcts = component.get("v.selectedRefctctEmails");    

        var action = component.get("c.getEmailContactList");
        action.setParams({"refctcts": selectedRefCtcts});

        action.setCallback(this,function(response){
            var contactEmailIds = response.getReturnValue();
            var state = response.getState();
            if(state=== "SUCCESS"){
                console.log('Get Contact Ids was successful');
                component.set("v.selectedMirrorContactIds",contactEmailIds);
                var contactList = component.get("v.selectedMirrorContactIds");
                console.log('The true Id List after set: '+JSON.stringify(contactList));
                //console.log('refctctEmailList: '+refctctEmailList);
            }
            if(state ==='ERROR'){
                var errors = JSON.stringify(response.getError());
                console.log(errors);

            }
        });
        $A.enqueueAction(action);


    },
    setRemovalReasonList : function(component){
        var currentTouchpoint = component.get("v.cadenceTouchpoint");          
        var action = component.get("c.generateCloseReasonList");
        action.setParams({"touchpoint": currentTouchpoint});
        action.setCallback(this, function(response) {
            var reasonList = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.closeReasons", reasonList);
            }});
        $A.enqueueAction(action);
    },
    setCurrentUserId : function(component, event, helper){        
        var action = component.get("c.getCurrentUserId");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.currentUserId", response.getReturnValue());               
            }});
        $A.enqueueAction(action);
        var currentUserId = component.get("v.currentUserId"); 
    },
    setCadenceSteps : function(component) {
        var currentTouchpoint = component.get("v.cadenceTouchpoint");          
        var action = component.get("c.generateStepList");
        action.setParams({"CadId": currentTouchpoint.Cadence__c});
        action.setCallback(this, function(response) {
            var stepList = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.cadStepList", stepList);
                component.set("v.StepCount", stepList.length);
            }});
        $A.enqueueAction(action);
    },
    updateCarNotes : function(component, helper) {
        var action = component.get("c.updateCar");
        action.setParams({"touchpoint": component.get("v.cadenceTouchpoint"),
                          "notes": component.get("v.SalesNotes")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.refreshTouchpoints(component, true, false);
                component.set("v.SalesNotes", null);
                helper.displayToast('success','Confirmation!','Notes successfully saved.');
            }});
        $A.enqueueAction(action);
    },
    handleSubmitReferral: function(component, event, helper) {
        var currentTouchpoint = component.get("v.cadenceTouchpoint");
        var paramId = null;
        var paramStart = null;
        if (currentTouchpoint.CarRecord__r.ContactId__c != null) {
            paramId = currentTouchpoint.CarRecord__r.ContactId__c;
            paramStart = 'Contact';
        } else if (currentTouchpoint.CarRecord__r.AccountId__c != null) {
            paramId = currentTouchpoint.CarRecord__r.AccountId__c;
            paramStart = 'Account';
        } else if (currentTouchpoint.CarRecord__r.LeadId__c != null) {
            paramId = currentTouchpoint.CarRecord__r.LeadId__c;
            paramStart = 'Lead';
        }
        var urlTPParam ='TouchpointId='+currentTouchpoint.Id;
        var vfPage = '/apex/Referral?Id='+paramId+'&startedFrom='+paramStart+'&'+urlTPParam;         
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({"url": vfPage});
        urlEvent.fire();
        $A.get('e.force:refreshView').fire();  
    },
    createOpportunity : function(component, event, helper) {
        var currentTouchpoint = component.get("v.cadenceTouchpoint");
        var vfPage;
        if(currentTouchpoint.Cadence__r.FormToCall__c == 'Referral') {
            var funcType = currentTouchpoint.Cadence__r.Cadence_Type__c;
            // this is so if we use Oasis SDR or NSS Inbound or such
            if (funcType.startsWith('Oasis')) {
               funcType = 'Oasis';
            } else if (funcType.startsWith('NSS')) {
               funcType = 'NSS';
            }
            
            var paramId = null;
            var paramStart = null;
            if (currentTouchpoint.CarRecord__r.ContactId__c != null) {
                paramId = currentTouchpoint.CarRecord__r.ContactId__c;
                paramStart = 'Contact';
            } else if (currentTouchpoint.CarRecord__r.AccountId__c != null) {
                paramId = currentTouchpoint.CarRecord__r.AccountId__c;
                paramStart = 'Account';
            } else if (currentTouchpoint.CarRecord__r.LeadId__c != null) {
                paramId = currentTouchpoint.CarRecord__r.LeadId__c;
                paramStart = 'Lead';
            }
            // maybe if paramId == null -> show an error
            //var urlSigContactParam = currentTouchpoint.TouchpointObject__c == 'Lead' ? currentTouchpoint.CarRecord__r.SignificantLead__c : currentTouchpoint.CarRecord__r.SignificantContact__c;
            
            //var urlStartedFromParam = currentTouchpoint.TouchpointObject__c == 'Lead' ? 'Lead' : 'Contact';
            //var parentObject = currentTouchpoint.TouchpointObject__c;
            //vfPage = '/apex/Referral?Id='+urlSigContactParam+'&startedFrom='+urlStartedFromParam+'&functionType=NSS';         
            var urlTPParam ='TouchpointId='+currentTouchpoint.Id;
            vfPage = '/apex/Referral?Id='+paramId+'&startedFrom='+paramStart+'&functionType='+funcType+'&'+urlTPParam;         
        }
        else{
            //var urlSalesProgramParam = 'salesProgram='+currentTouchpoint.Sales_Program__c;
            var urlSigContactParam = currentTouchpoint.TouchpointObject__c == 'Lead' ? 'leadId='+currentTouchpoint.CarRecord__r.LeadId__c : 'contactId='+currentTouchpoint.CarRecord__r.ContactId__c;
            var urlTouchpointRecordParam ='touchPointId='+currentTouchpoint.Id;
            //vfPage = '/apex/CreateOppAndMeetingLightning?'+ urlSigContactParam+'&'+urlTouchpointRecordParam+'&'+urlSalesProgramParam;
            vfPage = '/apex/CreateOppAndMeetingLightning?'+ urlSigContactParam+'&'+urlTouchpointRecordParam;
        }
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({"url": vfPage});
        urlEvent.fire();
        $A.get('e.force:refreshView').fire();  
        
    },
    processEmail : function(component, helper) {
        component.set('v.showSpinner', true);
        var templateId = component.get("v.emailTemplateId"); 
        var templateName = component.get("v.emailTemplate");
        var selectedTemplate = component.get("v.selectedEmailTemplate");
        if (selectedTemplate != null) {
           var options = component.get("v.emailTemplateOptions");
            for (var cnt=0; cnt<options.length; cnt++) {
                var option = options[cnt];
                if (option.value == selectedTemplate){
                   templateId = option.value;
                   templateName = option.label;
                   break;
                }
            } // for (var option : options)
        }
        var isRefCtct = component.get("v.cadenceTouchpoint.CarRecord__r.IsReferralSource__c");
        component.set("v.selectedTemplateName", templateName);
        var selectedIds = component.get("v.selectedMirrorContactIds");
        var preselectedIds = component.get("v.preselectedContacts");
        var updatedSelectedList = component.get("v.mirrorContactSelected");
        console.log('vv ss rr', selectedIds); 

        if(isRefCtct){
            var action = component.get("c.sendMailWithTargetIds");
            if(selectedIds.length==0 &&updatedSelectedList == false){
                action.setParams({"targetIds": preselectedIds,
                "emailTemplateId": templateId,
                 "emailExtra": component.get("v.emailExtra"),
                 "touchpoint": component.get("v.cadenceTouchpoint")
                });
            }else{
                action.setParams({"targetIds": selectedIds,
                "emailTemplateId": templateId,
                 "emailExtra": component.get("v.emailExtra"),
                 "touchpoint": component.get("v.cadenceTouchpoint")
                });
            }
            

            action.setCallback(this, function(response) {
                //store state of response
                var emailSent = response.getReturnValue();
                if (emailSent == 'Success') {
                    helper.displayToast('success','Confirmation!','The email has been sucessfully sent and the Touchpoint has been closed.');
                    component.set("v.displayEmailButton",false);
                    helper.refreshTouchpoints(component, false, false);
                } else {
                    //helper.displayToast('error','Error!','There was an error trying to send the email! If this is for an email template a contact or lead for the email address might not have been found.');
                    helper.displayToast('error','Error!',emailSent);
                    component.set('v.showSpinner', false);
                }
            });
            $A.enqueueAction(action);
        }else{
            var action = component.get("c.sendMailMethod");
        action.setParams({"mMail": component.get("v.emailRecipient"),
                        "mSubject": component.get("v.emailSubject"),
                         "mbody": component.get("v.emailBody"),
                         "emailTemplateId": templateId,
                         "emailTemplateName": templateName,
                          "emailExtra": component.get("v.emailExtra"),
                          "touchpoint": component.get("v.cadenceTouchpoint")
                         });
        action.setCallback(this, function(response) {
            //store state of response
            var emailSent = response.getReturnValue();
            if (emailSent == 'Success') {
                helper.displayToast('success','Confirmation!','The email has been sucessfully sent and the Touchpoint has been closed.');
                component.set("v.displayEmailButton",false);
                helper.refreshTouchpoints(component, false, false);
            } else {
                //helper.displayToast('error','Error!','There was an error trying to send the email! If this is for an email template a contact or lead for the email address might not have been found.');
                helper.displayToast('error','Error!',emailSent);
                component.set('v.showSpinner', false);
            }
        });
        $A.enqueueAction(action);

        }
        
    },
    emailPreview : function(component, helper) {
        component.set('v.showSpinner', true);
        var templateId = component.get("v.emailTemplateId"); 
        var templateName = component.get("v.emailTemplate");
        var selectedTemplate = component.get("v.selectedEmailTemplate");
        if (selectedTemplate != null) {
           var options = component.get("v.emailTemplateOptions");
           //alert('options='+options);
            for (var cnt=0; cnt<options.length; cnt++) {
                var option = options[cnt];
                //alert('selectedTemplate='+selectedTemplate+' option='+option);
                if (option.value == selectedTemplate){
                   //alert('found match!');
                   templateId = option.value;
                   templateName = option.label;
                   break;
                }
            } // for (var option : options)
        }
        //alert('templateId='+templateId+' templateName='+templateName);
        component.set("v.selectedTemplateName", templateName);
        var isRefCtct = component.get("v.cadenceTouchpoint.CarRecord__r.IsReferralSource__c");

        if(isRefCtct){
            var action = component.get("c.previewEmailWithTargetId");
            var selectedIds = component.get("v.selectedMirrorContactIds");
            var preselectedIds = component.get("v.preselectedContacts");
            if(selectedIds.length==0){
                console.log('using Pre-selected Ids');
                var targetIds = preselectedIds;
            }else{
                console.log("the user has selected something and using that selection");
                var targetIds = selectedIds;
            }

            console.log("***Selected/Preselected Mirrored Contact Id's: "+JSON.stringify(targetIds[0])+"***");

        action.setParams({"targetId": targetIds[0],
                         "emailTemplateId": templateId,
                          "emailExtra": component.get("v.emailExtra"),
                          "touchpoint": component.get("v.cadenceTouchpoint")
                         });
        action.setCallback(this, function(response) {
           component.set('v.showSpinner', false);
            //store state of response
            var emailBody = response.getReturnValue();
            component.set("v.emailPreviewBody",emailBody);
            component.set("v.isEmailPreviewOpen", true);
        });
        $A.enqueueAction(action);
        }else{
            var action = component.get("c.previewEmail");
        action.setParams({"mMail": component.get("v.emailRecipient"),
                         "emailTemplateId": templateId,
                          "emailExtra": component.get("v.emailExtra"),
                          "touchpoint": component.get("v.cadenceTouchpoint")
                         });
        action.setCallback(this, function(response) {
           component.set('v.showSpinner', false);
            //store state of response
            var emailBody = response.getReturnValue();
            component.set("v.emailPreviewBody",emailBody);
            component.set("v.isEmailPreviewOpen", true);
        });
        $A.enqueueAction(action);
        }
       
    },
    updateSignificant : function(component, helper, row) {
        var currentTouchpoint = component.get("v.cadenceTouchpoint");  
        var action = component.get("c.apexUpdateSignificant");
        action.setParams({"touchpoint" : currentTouchpoint,
                          "significantObject" : row});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.displayToast('success','Confirmation!','Contact has been updated.');
                helper.refreshTouchpoints(component, true, false);
            }});
        $A.enqueueAction(action);
    },
    // updates a new contact to be the main contact on the CAR record.
    updateRecToSignificant : function(component, event, recIdToSetAsSig) {
        component.set('v.showSpinner', true);
        var currentTouchpoint = component.get("v.cadenceTouchpoint");
        var action = component.get("c.apexUpdateSignificant");
        action.setParams({"touchpoint" : currentTouchpoint,
                          "recordIdStr" : recIdToSetAsSig});
                action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //helper.displayToast('success','Confirmation!','Contact has been updated.');
                component.set("v.displaySkipScreen", false);
                component.set("v.displayDetails", true);
            }});
        $A.enqueueAction(action);
        component.set('v.showSpinner', false);
    },
    handleMakeMainRecSig : function(component, helper) {
        component.set('v.showSpinner', true);
        var currentTouchpoint = component.get("v.cadenceTouchpoint");  
        var recId = currentTouchpoint.CarRecord__r.ContactId__c != null ?  currentTouchpoint.CarRecord__r.ContactId__c :  currentTouchpoint.CarRecord__r.LeadId__c;
        var action = component.get("c.apexUpdateSignificant");
        action.setParams({"touchpoint" : currentTouchpoint,
                          "recordIdStr" : recId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.displayToast('success','Confirmation!','Significant Contact has been updated.');
                helper.refreshTouchpoints(component, true, false);
                component.set("v.cadenceTouchpoint", currentTouchpoint);
                
            }});
        $A.enqueueAction(action);

    },
    // updates a contact to be the main contact on the CAR record.
    updateContact : function(component, helper) {
        component.set('v.showSpinner', true);
        var updateSigContact = component.get("v.updateSig");
        var currentTouchpoint = component.get("v.cadenceTouchpoint");  
        var newContact = component.find("contact_List").get('v.value');
        //alert('updateContact updateSigContact='+updateSigContact+' newContact='+newContact);
        var action;
        console.log('updateSigContact: '+updateSigContact);
        if (updateSigContact) {
           action = component.get("c.apexUpdateSignificant");
           action.setParams({"touchpoint" : currentTouchpoint,
                          "recordIdStr" : newContact});
        } else {
           action = component.get("c.updateSigContact");
           action.setParams({"touchpoint" : currentTouchpoint,
                          "conToUpdate" : newContact});
        }
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.displayToast('success','Confirmation!','Contact has been updated.');
                helper.refreshTouchpoints(component, true, false);
                //component.set("v.cadenceTouchpoint", currentTouchpoint);
                
            }});
        $A.enqueueAction(action);
    },
    openParentRecord : function(component, helper) {
        var currentTouchpoint = component.get("v.cadenceTouchpoint");  
        var objectId = currentTouchpoint.CarRecord__r.CadenceObject__c;
        
        if (objectId != null && objectId.startsWith('003')) {
            objectId = currentTouchpoint.CarRecord__r.ContactId__c;
        }
        var parentId = '/'+objectId;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({"url": parentId});
        urlEvent.fire();
    },
    skipTouchpoint : function(component, helper) {
        var action = component.get("c.skipThisTouchpoint");
        action.setParams({"touchpoint": component.get("v.cadenceTouchpoint"),
                          "skipReason": component.get("v.skipReason")});
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.displayToast('success','Confirmation!','This touchpoint has been skipped.  Details added to Cadence History tab.');
                helper.refreshTouchpoints(component, false, false);
            }
        });
        $A.enqueueAction(action);
    },
    createActivity : function(component, helper, description) {
        var currentTouchpoint = component.get("v.cadenceTouchpoint");          
        var action = component.get("c.createTouchpointActivity");
        action.setParams({"touchpoint": currentTouchpoint,
                          "Descript": description});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                
            }});
        $A.enqueueAction(action);
        
    },
    getReferralContactNames: function(component,helper){
        component.set("v.selectedRefctctNames",'');

        var NamesList = component.get("v.selectedRefctctNamesList");
        console.log("Names List:"+JSON.stringify(NamesList));
                var refctctNames = '';
                NamesList.forEach((rec,i)=>{
                    
                    if(i!=NamesList.length-1){
                        refctctNames += rec.Name+", ";
                    }else {
                        refctctNames += rec.Name;

                    }
                    
                });
                console.log("ref contact names: "+refctctNames);
                component.set("v.selectedRefctctNames",refctctNames);
                var info = component.get("v.selectedRefctctNames");
                console.log("selectedRefctctNames in component: "+JSON.stringify(info));
    },
        //************Utility Methods************//
    refreshTouchpoints : function(component, updateCurrentTp, displayToast){
        var fromParent = component.get("v.navigatedFromParent");
        var touchpointToView = component.get("v.cadenceTouchpoint");
        if(fromParent){
            var cmpEvent = component.getEvent("updateTouchpoint");
           // cmpEvent.setParams({"refreshTouchpoint" : true });
            cmpEvent.fire();
        }
        else{
            component.set("v.cadenceTouchpoint", null);
            component.set('v.showSpinner', false);
            var cmpEvent = component.getEvent("updateTouchpointList");
                cmpEvent.setParams({"currentTouchPoint" : touchpointToView,
                                    "updateTouchpoint" : updateCurrentTp,
                                    "displayUpdateToast" : displayToast});

            cmpEvent.fire();
        }
    },
    displayToast : function(toastType, title, message){
        var showToast = $A.get("e.force:showToast"); 
        showToast.setParams({ 
      
            'title' : title, 
            'type' : toastType,
            'message' : message
        }); 
        showToast.fire();
    },
    toggleSpinner: function(component, trueOrFalse) {
        var spinner = component.find("spinner");
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : trueOrFalse });
        evt.fire();
    }, 
    checkEmailOptions: function(component, helper, touchpoint, touchpointType) {
        component.set("v.displayEmailButton", false);
        if(touchpoint.CarRecord__r.SignificantContactDNE__c && !touchpoint.CarRecord__r.Ignore_DNE__c ){
           component.set("v.cannotEmailContact", true);
        }
        if(touchpointType == "Email" || touchpointType == "Email Contact") {
           component.set("v.displayEmailButton", true);
           component.set("v.emailTemplate", null);
    console.log('vv touchpoint',touchpoint.Id );
           component.set("v.hasTemplateOptions",false);
           var templateNames = (touchpoint.Cadence_Touchpoint_Step__r.EmailTemplateNames__c != null ? touchpoint.Cadence_Touchpoint_Step__r.EmailTemplateNames__c.split(",") : null);
           if (templateNames != null) {
              var templateIds = (touchpoint.Cadence_Touchpoint_Step__r.EmailTemplateIds__c != null ? touchpoint.Cadence_Touchpoint_Step__r.EmailTemplateIds__c.split(",") : null);
              if (templateIds.length == 1) {
                 component.set("v.hasTemplateOptions",true);
                 component.set("v.emailTemplate", templateNames[0]);
                 component.set("v.emailTemplateId", templateIds[0]);
              } else if (templateIds.length > 1) {
                 component.set("v.hasTemplateOptions",true);
                 var options = [];
                 for (var cnt=0; cnt<templateIds.length; cnt++) {
                    options.push({ value: templateIds[cnt], label: templateNames[cnt] });			
                 }
                 component.set("v.selectedEmailTemplate", options[0].value);
                 component.set("v.emailTemplateOptions", options);
              }
           }
        }

    },
   setStepOptions: function(component, event, helper) {
      var touchpoint = component.get("v.cadenceTouchpoint");
       touchpoint.Cadence_Touchpoint_Step__r.Allow_Repeat__c
      
      var options = [];
      options.push({ value: "Complete Step", label: "Complete Step" });
      if (touchpoint.Cadence_Touchpoint_Step__r.Allow_Repeat__c) {
         options.push({ value: "Repeat Step", label: "Log Step and Repeat" });
      }
      options.push({ value: "Complete and Remove", label: "Complete Step and Remove From Cadence" });
      component.set("v.logStepValue","Complete Step");
      component.set("v.logStepOptions", options);
   },
   completeLogStep: function(component, event, helper) {
      var cadenceTp = component.get("v.cadenceTouchpoint");
      // save the changes
      
      var action = component.get("c.logStep");
      action.setParams({"touchpoint": component.get("v.cadenceTouchpoint")
                        ,"logType": component.get("v.logStepValue")
                         ,"repNote": component.get("v.TouchpointUpdateNote")
                         ,"dueDate": component.get("v.followUpDate")
                         ,"repeatReason": component.get("v.repeatReason")
                         ,"closeReason": component.get("v.RemovalReason")
                         ,"attendees": component.get("v.selectedRefctctNames")
                         });
       
       action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                var logType = component.get("v.logStepValue");
                var msg = (logType == 'Complete Step' ? 'Touchpoint Step Completed.' 
                                   : (logType == 'Repeat Step' ? 'The touchpoint due date has been updated'
                                      : (logType == 'Complete and Remove' ? 'Touchpoint Step Completed and Removed From the Cadence' : 'Success')));
                helper.displayToast('success','Confirmation!',msg);
                helper.refreshTouchpoints(component, false, false);
                component.set("v.followUpDate", null);
                component.set("v.repeatReason", null);
            }
        });
        $A.enqueueAction(action);
   },
   setRefCtctSelect: function(component,event,helper){
    var action = component.get("c.getReferralContactswithAcctId");
    action.setParams({"refActId": component.get("v.cadenceTouchpoint.CarRecord__r.ReferralAccount__c")});
    action.setCallback(this, function(response) {
        //store state of response
        console.log("made it into set ref select");
        var state = response.getState();
        var refctcts = response.getReturnValue();

        if (state === "SUCCESS") {
            console.log("SET REF SELECT WORKING");
            component.set("v.referralContactOptions",refctcts);
        }else{
            console.log(state);
        }
        
   });
   $A.enqueueAction(action);

},

    /*
    processRequest : function(component, helper) {
        component.set('v.showSpinner', true);
        var action = component.get("c.processTouchpoint");
        var touchpointUpdate = component.get("v.TouchpointUpdateNote");
        var cadenceTp = component.get("v.cadenceTouchpoint");
        action.setParams({"touchpoint": component.get("v.cadenceTouchpoint")
                         ,"repNote": touchpointUpdate});
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.displayToast('success','Confirmation!','Touchpoint Step Completed.');
                helper.refreshTouchpoints(component, false);
            }
        });
        $A.enqueueAction(action);
    },
    updateDueDate : function(component, helper) {
        var followUpReason = component.get("v.repeatReason");
        var action = component.get("c.updateDD");
        var cadenceTp = component.get("v.cadenceTouchpoint");
        action.setParams({"touchpoint": cadenceTp,
                          "dueDate": component.get("v.followUpDate"),
                          "reason": component.get("v.repeatReason")});
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.displayToast('success','Confirmation!','The touchpoint due date has been updated');
                if(cadenceTp.Cadence_Touchpoint_Step__r.Generate_Activity__c){
                    helper.createActivity(component, helper, followUpReason);
                }
                helper.refreshTouchpoints(component, false);
                component.set("v.SalesNotes", null);
                component.set("v.followUpDate", null);
                component.set("v.repeatReason", null);
            }
        });
        $A.enqueueAction(action);
    },
    */
    cadenceRemoval : function(component, helper) {
        var currentTouchpoint = component.get("v.cadenceTouchpoint");
        var parentObjectName = currentTouchpoint.Parent_ObjectName__c;
        var parentObject = currentTouchpoint.TouchpointObject__c;
        var action = component.get("c.removeFromCadence");
        action.setParams({"touchpoint": currentTouchpoint,
                          "closeReason": component.get("v.RemovalReason")});
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.displayToast('success','Confirmation!','The '+parentObject+' \"'+parentObjectName+'\" has been removed from the cadence process');
                helper.refreshTouchpoints(component, false, false);
            }
        });
        $A.enqueueAction(action);
    },
                   
    //APR0159917--Start
    cadenceSteps:function(component,helper,cadenceId,stepNumber){
        //console.log("I am inside cadenceSteps"+cadenceId+stepNumber);
        var action = component.get("c.isLastStep");
        var onLastStep=false;
        action.setParams({"cadenceId":cadenceId,"stepNumber":stepNumber});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state==="SUCCESS"){
                console.log('MA Success'+response.getReturnValue());
                if(response.getReturnValue()){
                    console.log("MA Check1"+onLastStep);
                    onLastStep=true;
                    //component.set("isLastStep",response.getReturnValue());
                    //console.log("MA Check2"+onLastStep);
                }
                //console.log("MA Check3"+onLastStep);
                component.set("v.isLastStep",onLastStep);
            }
            else{
                console.log('MA if not Success');
            }
        });
        $A.enqueueAction(action);
    }//APR0159917--End
                    
})