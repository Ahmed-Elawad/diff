({
    
    myAction : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: "PEO Getting Started"
            });
        })
        .catch(function(error) {
            console.log(error); 
        });
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i;
        
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            if (sParameterName[0] ==='c__RecordId') {
                component.set('v.recordId', sParameterName[1]);
                break;
            }
        }
        var device = $A.get("$Browser.formFactor");
        console.log('device: '+device);
        if(device == 'DESKTOP'){
            component.set('v.tabStyle', 'vertical');
        }
        else{
            component.set('v.tabStyle', 'overflow');
        }
        
        helper.helperFunctionAsPromise(component, helper.getUserAttributes, helper)
         .then($A.getCallback(function() {
             return helper.helperFunctionAsPromise(component, helper.getChecklistrecord, helper)
         }))
        .then(function(res) { return helper.buildPath(component, event, helper)})
        .then(function(res) { return helper.checkWhichFilesNeeded(component, event, helper)})
        .then(function(res) { return helper.loadFinished(component, event, helper)})
        .catch(function(res) {
            helper.loadFinished(component, event, helper);
            helper.handleError(component, event, helper);
        });
        
        component.set('v.indAttributesRefresh' , $A.getCallback(() => helper.refreshWCRelatedProperties(component, event, helper)));
        component.set('v.triggerAutoSave', $A.getCallback(() => helper.manageAutoSave(component, event, helper, true)))
    },  
    
    
   pendoAfter: function (component, event, helper){
       console.log('Inside pendo After');
       console.log('isCommunityUser:'+component.get('v.isCommunityUser'));
       var isCommunityUser = component.get('v.isCommunityUser'); 
       if(isCommunityUser){
           var uID = $A.get( "$SObjectType.CurrentUser.Id" );
           console.log ('JC running user ' + uID);  
           pendo.initialize({
               visitor: {
                   id:  uID
               },
               
               account: {
                   id: 'SFDCPEOEdge'
               }
           });
           console.log('pendo finished ');
       }
        
    }, 
        
    onPageReferenceChange: function(cmp, e, helpwe) {
        console.log('in page ref')
        var myPageRef = cmp.get("v.pageReference");
        var myId = myPageRef.state.c__RecordId;
        console.log(myId);
    },
    registerStep: function(component, event, helper) {
        console.log('in stepper');
    },    
    stepForward : function(component, event, helper) {
        helper.increaseStep(component, event);
    },
    
    stepBackward : function(component, event, helper) {
        helper.decreaseStep(component, event);
    },
    
    markDiscrepancy: function(cmp, e, helper) {
        console.log('got here')
        try {
            let formName = e.getParam('formName');
            let checklistId = e.getParam('checklistId');
            let type = e.getParam('type');
            let medChecklsitId = !!e.getParam('medicalChecklst') ? e.getParam('medicalChecklst') : null;
            helper.buildUrlForDiscrepancy(cmp, e, checklistId, formName, type, medChecklsitId);
            helper.navToDiscrepancy(cmp, e);
        } catch(e) {
            console.log('Error\n'+e);
        }
    },
    handleAutoSave: function(cmp, e, helper) {
        try {
            helper.manageAutoSave(cmp, e, helper);
        }catch (e) {
            console.error(e);
        }
    },
    scrollToTop: function(cmp, e, helper) {
        var target = cmp.find("housingDiv");
        var element = target.getElement();
        var rect = element.getBoundingClientRect();
        scrollTo({top: rect.top, behavior: "smooth"});
    },
    navToAddDocumentTab: function(cmp, e, helper){
        try {
            console.log('Inside sendCommunityFormsTabUpdate');
            let tabNavigateEVt = cmp.getEvent('communityFormsTabNavigate');
            tabNavigateEVt.setParam('direction', -1);
            tabNavigateEVt.fire();   
        }catch(e){
            console.error(e);
        }
    },
    handleTabNav: function(cmp, e, helper) {
        try {
            //debugger;
            let direction = e.getParam('direction');
            let skipToVerificationScreen = e.getParam('skipToVerificationScreen');
            let isCommUser = cmp.get("v.isCommunityUser");            
            let stepObjectList = cmp.get('v.allSteps');
            let currentStep = cmp.get('v.currStep');
            let completedTabs = cmp.get("v.completedSteps");
            let newTab = '', fldEvt;
            let checklist = cmp.get('v.PEOOnboardingChecklist');
            let medPrequal = cmp.get('v.isMedicalPrequal');
            let selectedStep = cmp.get('v.selectedStep');
            console.log(currentStep);
            
            // build the list of all the possible tabs
            let tablist = stepObjectList.reduce(function(s, o) {
                s.push(o.value);
                return s;
            }, []);
            if(tablist.includes('implementation')){
                if(selectedStep == 'implementation'){
                    cmp.set('v.progressIndicatorLength', stepObjectList.length);
                    cmp.set('v.showExternalTab', true);
                }
            }
            
            if (skipToVerificationScreen) {
                if (isCommUser) completedTabs = stepObjectList.slice(0,stepObjectList.indexOf('addDocs'));
                currentStep = 'addDocs';
            }
            
           // get the index of the next step. This will be the position of the current
            // step in the tab list plus whatever direction we need to go: left 1 or right 1  
            // ADDITION: use selected step to determine which type of navigation to do.
            // If the tab after currently selected tab comes before the next tab for the overall
            // stage of the deal(completed steps) then we need to assume they want to navigate to the next viewable tab.
            // In that case use the index of the selected tab and find the next tab
            let nextTabIndex;
            let usedSelectedStep;
            if (tablist.indexOf(selectedStep) + direction < tablist.indexOf(currentStep) + direction) {
                nextTabIndex = tablist.indexOf(selectedStep) + direction
                usedSelectedStep = true;
            } else {
                nextTabIndex = tablist.indexOf(currentStep) + direction;
            }
            
            if(selectedStep == 'confirmationNextSteps'){
                nextTabIndex = tablist.indexOf(selectedStep) + direction
                usedSelectedStep = true;
            }
            
            // if the next tab index is in range of the tablist
            // set the new tab value, set the current step for the form,
            // update the completed step value on the checklist, and finally
            // if the completed tabs does not include the tab we're navigating 
            // to add the incoming tab to the list of completed tabs   
            // console.log(`Next tab i: ${nextTabIndex}\nTablist length: ${tablist.length}`);
            if (nextTabIndex >= 0 && nextTabIndex < tablist.length){
                newTab = tablist[nextTabIndex];
                // only update the currecnt step if they are genuinly completing that section
                if (!usedSelectedStep) cmp.set('v.currStep', newTab);
                // save the completed_step value on the current instance of the checklist
                if(isCommUser && !usedSelectedStep){
                    cmp.set("v.PEOOnboardingChecklist.Completed_Step__c",currentStep);
                    // send the field value to the auto save handler so the completion of the
                    // previous tab is saved on the checklist
                    fldEvt = {
                        getParam: function(arg) {return this[arg];}
                    };
                    fldEvt.sendImmediete = false;
                    fldEvt.cancelAll = false;
                    fldEvt.accountId = cmp.get('v.parentAccountId');
                    fldEvt.accountName = cmp.get('v.Account.Name');
                    fldEvt.recordId = cmp.get('v.PEOOnboardingChecklist.Id');
                    fldEvt.fieldName = 'Completed_Step__c';
                    fldEvt.objectName = 'PEO_Onboarding_Checklist__c';
                    fldEvt.fieldValue = currentStep;
                    helper.manageAutoSave(cmp, fldEvt, helper);
                }
                
                cmp.set('v.selectedStep', newTab);
                if(!completedTabs.includes(currentStep)){
                    completedTabs.push(currentStep);
                    cmp.set('v.completedSteps', completedTabs);
                }
            } 
            // if the tab to nv to is the submit tab re-check the required docs logic    
            if(newTab == 'submit'){
                helper.checkWhichFilesNeeded(cmp, event);
            }
            
            if(cmp.get('v.currStep') != 'wc' && cmp.get('v.currStep') != 'addtlInfo') {
                cmp.set('v.CurrentTabId', '');
            }
            
            // send an auto save that should save everything that's been edited on the form
            helper.manageAutoSaveServerCall(cmp,event, helper, {sendImmediete: true});
            
            // if logged in as a portal user and they're completing one of the main
            // tabs trigger the notification logic to let the rep KNow they finished
            //console.log('JOURNEY TESTING: Tab notification attributes');
            //console.table({currentStep: currentStep, Medical_Pre_Qualifier_Status__c: checklist.Medical_Pre_Qualifier_Status__c})
            if(isCommUser && (currentStep == 'medical' || currentStep == 'wc' || currentStep == 'addtlInfo' || 
                              (currentStep=='acctUpdate' && checklist.Medical_Pre_Qualifier_Status__c == 'Approved'))){
                helper.sendCompleteNotification(cmp,event,helper,currentStep);
                console.log('sending complete notification: '+currentStep);
            }
        }catch (e) {
            console.error(e);
        }
    },
    changeStep: function(cmp, e, helper) {
        // get currentStep, newStep, and completed steps
        let newStep = e.getSource().get("v.value");
        let currentStep = cmp.get("v.currStep");
        var allCompletedSteps = cmp.get("v.completedSteps");
        helper._logProxyObJ(allCompletedSteps);
        
        // if it's a community user we don't want them to be able to click forward
        var isCommUser = cmp.get("v.isCommunityUser");
        var steps = cmp.get('v.allSteps');
        let newStepIsRightAfterCompletedStep;
        
        // iterate all the steps. 
        // set newStepIsRightAfterCompletedStep to true if the new step is right after the most
        // recent completed step found @ steps[i]:
        // ex: click Workers comp, completed = [acctUpdt, medical] => newStepIsRightAfterCompletedStep = true.
        for (let i = 0; i < steps.length; i++) {
          	if (allCompletedSteps.includes(steps[i].value) && (steps[i+1] && steps[i+1].value ==newStep)) {
                newStepIsRightAfterCompletedStep = true;
                break;
            }
        }
        
        // if logged in as an internal user allow any nav clicks
        // otherwise if the clicked step is already completed, or it's riht after the most recent completed step
        // or the new step is the step they're already vieweing
        // update the currently selected step.
        // INtended to allow a community user to navigate all the forms they've already completed & click into the one
        // they need to finish next
        if (!isCommUser ){
            cmp.set("v.selectedStep",newStep);
            // save all recent changes for autosave
            helper.manageAutoSaveServerCall(cmp,e, helper, {sendImmediete: true});
            //cmp.set("v.currStep",newStep);
        } else if (allCompletedSteps.includes(newStep) || newStepIsRightAfterCompletedStep || newStep == currentStep
                  || newStep=='addDocs' || newStep=='wc') {
            cmp.set("v.selectedStep",newStep);
            // save all recent changes for autosave
            helper.manageAutoSaveServerCall(cmp,e, helper, {sendImmediete: true});
        }
    }
})