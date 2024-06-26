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
        
        //helper.gatherStartingInformation(component, event, helper);
        
        helper.helperFunctionAsPromise(component, helper.getAccountInfo, helper)
        .then($A.getCallback(function() {
            console.log('got acc info')
            return helper.helperFunctionAsPromise(component, helper.getChildChecklists, helper)
        }))
        .then($A.getCallback(function() {
            console.log('got checklist')
            return helper.helperFunctionAsPromise(component, helper.getIndustryNames, helper)
        }))
        .then($A.getCallback(function() {
            console.log('got inds')
            return helper.helperFunctionAsPromise(component, helper.getSysPermissions, helper)
        }))
        .then($A.getCallback(function() {
            console.log('got permission')
            return helper.helperFunctionAsPromise(component, helper.getRunningUser, helper)
        }))
        .then($A.getCallback(function() {
            console.log('got user')
            return helper.helperFunctionAsPromise(component, helper.getCommUser, helper)
        }))
        .then($A.getCallback(function() {
            console.log('got opp')
            return helper.helperFunctionAsPromise(component, helper.getChecklist, helper)
        }))
        .then($A.getCallback(function() {
            console.log('got chk')
            return helper.helperFunctionAsPromise(component, helper.getMedicalQuestionnaire, helper)
        }))
        .then($A.getCallback(function() {
            console.log('got med')
            return helper.helperFunctionAsPromise(component, helper.covidQuestionnaireIsNeeded, helper)
        }))
        .then(function(res) { return helper.buildPath(component, event, helper)})
        .then(function(res) { return helper.checkWhichFilesNeeded(component, event, helper)})
        .then(function(res) { return helper.loadFinished(component, event, helper)})
        .catch(function(res) {
            helper.loadFinished(component, event, helper);
            helper.handleError(component, event, helper);
        });
        
        /*helper.getAccountInfo(component, event, helper)
        .then(res =>  helper.getChildChecklists(component, event, helper))
        .then(res =>  helper.getIndustryNames(component, event, helper))
        .then(res =>  helper.getSysPermissions(component, event, helper))
        .then(res =>  helper.getRunningUser(component, event, helper))
        .then(res =>  helper.getCommUser(component, event, helper))
        .then(res =>  helper.getChecklist(component, event, helper))
        .then(res =>  helper.getMedicalQuestionnaire(component, event, helper))
        .then(res =>  helper.covidQuestionnaireIsNeeded(component, event, helper))
        .then(res =>  helper.buildPath(component, event, helper))
        .then(res =>  helper.checkWhichFilesNeeded(component, event, helper))
        .then(res =>  helper.loadFinished(component, event, helper))
        .catch(err => helper.handleError(err));*/
        component.set('v.indAttributesRefresh' , $A.getCallback(() => helper.refreshWCRelatedProperties(component, event, helper)));
    },
    onPageReferenceChange: function(cmp, e, helpwe) {
        console.log('in page ref')
        var myPageRef = cmp.get("v.pageReference");
        var myId = myPageRef.state.c__RecordId;
        console.log(myId)
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
    //THIS IS NOT CALLED ANYMORE, MOVED FUNCTIONALITY TO HANDLE TAB NAV
    /*
    updatePEOChecklist : function(component, event, helper) {
        helper.updateComponentViewWidth(component, event);
        helper.manageAutoSaveServerCall(component,event, helper, {sendImmediete: true});
        component.set('v.fileUploadSelectedAccId', component.get('v.parentAccountId'));
    },*/
    //I don't think this is used anymore
    /*saveForm : function(component, event, helper) {
        console.log("tab id = " + component.get("v.selectedTab"));
        console.log("formToSave = " + component.get("v.formToSave"));
        component.set('v.fileUploadSelectedAccId', component.get('v.parentAccountId'));
        
        if(component.get("v.formToSave") != "CommGeneralInfo" && component.get("v.formToSave") != "uploadFiles")
        {
            try {
                component.find(component.get("v.formToSave")).saveRecordEditForm();
            }
            catch(err) {
                alert('Form answers may not have been saved properly. Please refresh the page and try again.');
            }
            
        }
        
        
        var element = document.getElementById("housingDiv");
        if(element != null && !element.classList.contains("slds-container_large")) {
            element.classList.remove("maxWidth");
            element.classList.add("slds-container_large");
        }
        
        component.set("v.formToSave", component.get("v.selectedTab"));
        console.log("formToSave = " + component.get("v.formToSave"));
    },*/
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
    handleTabNav: function(cmp, e, helper) {
        try {
            console.log('Tab nav triggered');
            let isCommUser = cmp.get("v.isCommunityUser");
            let direction = e.getParam('direction');
            let stepObjectList = cmp.get('v.allSteps');
            let currentStep = cmp.get('v.currStep');
            console.log('currStep: '+ currentStep);
            let completedTabs = cmp.get("v.completedSteps");
            let newTab = '', fldEvt;
            let checklist = cmp.get('v.PEOOnboardingChecklist');
            let medPrequal = cmp.get('v.isMedicalPrequal');
            let selectedStep = cmp.get('v.selectedStep');
            
            // build the list of all the possible tabs
            let tablist = stepObjectList.reduce(function(s, o) {
                s.push(o.value);
                return s;
            }, []);
            
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
                    console.log('Updating completed step...')
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
                if(!completedTabs.includes(newTab)){
                    completedTabs.push(newTab);
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
            if(isCommUser && ((currentStep == 'medical' && medPrequal) || currentStep == 'wc' || currentStep == 'addtlInfo' || (currentStep=='acctUpdate' && checklist.Medical_Pre_Qualifier_Status__c == 'Approved'))){
                helper.sendCompleteNotification(cmp,event,helper,currentStep);
                console.log('sending complete notification: '+currentStep);
            }
        }catch (e) {
            console.error(e);
        }
    },
    changeStep: function(cmp, e, helper) {
        let newStep = e.getSource().get("v.value");
        let currentStep = cmp.get("v.currStep");
        var allCompletedSteps = cmp.get("v.completedSteps");
        var isCommUser = cmp.get("v.isCommunityUser");
        var steps = cmp.get('v.allSteps');
        let newStepIsRightAfterCompletedStep;
        
        for (let i = 0; i < steps.length; i++) {
          	// if the next step is the new step and the completed steps contains the curent step
          	// set flag to true
          	if (allCompletedSteps.includes(steps[i].value) && (steps[i+1] && steps[i+1].value ==newStep)) {
                newStepIsRightAfterCompletedStep = true;
                break;
            }
        }
        
        // if(allCompletedSteps.includes(newStep) || newStep == currentStep || !isCommUser){
        // if loggged in as a rep just update the tab
        // otherwise if lofgged in as a portal user only update the tab when the step is completed already
        // // always update the current step if there's a change
        console.log(allCompletedSteps.includes(newStep))
        console.log('newStep: ' +newStep)
        console.log('currentStep: '+currentStep)
        if (!isCommUser ){
            console.log('Not comm user')
            cmp.set("v.selectedStep",newStep);
            //cmp.set("v.currStep",newStep);
        } else if (allCompletedSteps.includes(newStep) || newStepIsRightAfterCompletedStep || newStep == currentStep) {
            console.log('nav as comm user')
            cmp.set("v.selectedStep",newStep);
            //cmp.set("v.currStep",newStep);
        }
        /*else{
            console.log('cannot go forward');
            //cmp.set("v.selectedStep",currentStep);
            //cmp.set("v.currStep",currentStep);
        }*/
        
        // what is this for??
        /*if(newStep != 'wc' && newStep != 'addtlInfo') {
            cmp.set('v.CurrentTabId', '');
        }*/
    }
})