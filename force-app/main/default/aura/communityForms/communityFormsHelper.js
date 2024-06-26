({
    /*
     * History:
     * ------------------------------------------------------
     * 12/17/2021 Ahmed Elawad	Added refreshWCRelatedProperties for inc INC2871415 & fixed bug for 
     */
    /*gatherStartingInformation : function(component, event, helper) {
        
        var getAcct = component.get("c.getAccountInformation");
        var getPermission = component.get("c.getSystemPermission");
        var getChildAccsChecklists = component.get("c.getPEOOnboardingChecklistsData"); //Added by Bharat
        var getUser = component.get("c.getRunningUser");
        var getPEOChecklist = component.get("c.getPEOOnboardingChecklist");
        var covidQuestionnaireNeeded = component.get("c.needCovidQuestionnaire");
        let getMedical = component.get('c.getMedicalQuestionnaireForm');
        //let getIndsutryDetails = component.get('c.getIndustryDetails');
        //console.log(`Record ID: ${component.get('v.recordId')}`);
        getAcct.setCallback(this, function(data) {
            getPermission.setCallback(this, function(data) {
                component.set("v.hasAccess", data.getReturnValue());
            });
            // set the account on the parent container 
            // if there are children set the children on the parent
            let allAccounts = data.getReturnValue();
            
            // parent account is at allAccounts[0] on the array. Set that as Account attr
            // if the parent account status is not prospect set accountStatusNotProspect true
            if(allAccounts != null)
            {
                component.set("v.Account", allAccounts[0]);
                component.set("v.parentAccountId", allAccounts[0].Id);
                component.set("v.Accounts", allAccounts);
                //fetch industy name for conditional display of industry specific tab
                helper.getIndustryNames(component, event, helper);
                getUser.setCallback(this, function(data) {
                    
                    component.set("v.runningUser", data.getReturnValue());
                    if(data.getReturnValue().Profile.Name.includes("Community"))
                    {
                        component.set('v.isCommunityUser', true);
                    }
                    var getCommunityUser = component.get("c.getCommunityUser");
                    
                    getCommunityUser.setCallback(this, function(data) {
                        console.log('Inside getCommunityUser callback');
                        if (data.getState() === 'SUCCESS') {
                            component.set("v.communityUser", data.getReturnValue());
                        }
                        console.log('component.get("v.communityUser")='+component.get("v.communityUser") + ' component.get("v.chosenExperience")='+component.get("v.chosenExperience"));
                        
                    });
                    getCommunityUser.setParams({
                        'startingId': component.get("v.recordId"),
                        formName: 'CommunityForms.cmp'
                    });
                    
                    $A.enqueueAction(getCommunityUser);
                    console.log('Inside getCommunityUser component.get("v.Account.Id") = '+component.get("v.Account.Id"));
                    
                });
                
                getPEOChecklist.setCallback(this, function(data) {
                    console.log('Checklist returned peo');
                    console.log(data.getReturnValue());
                    if(data.getReturnValue() != null)
                    {
                        var checklist = data.getReturnValue();
                        component.set("v.PEOOnboardingChecklist", checklist);
                        
                        // set all the attributes to lock edit or upload access based on status fields
                        this.setUWStatusLock(component, component.get("v.Accounts"), checklist,this);
                        var ownerObjects = component.get('v.peoOnbCheckOwners');
                        if(checklist.List_of_Owners__c != null && data.getReturnValue().List_of_Owners__c != undefined)
                        {
                            var ownerAndPercentList = checklist.List_of_Owners__c.split(';');
                            if(ownerAndPercentList.length > 0)
                            {
                                for(var index = 0; index < ownerAndPercentList.length; index++)
                                {
                                    var ownerInfo = ownerAndPercentList[index].split(',');
                                    var ownerName = "";
                                    var ownerPercent = "";
                                    
                                    if(ownerInfo[0] != null && ownerInfo[0] != 'undefined')
                                    {
                                        ownerName = ownerInfo[0];
                                        console.log('ownerName='+ownerName);
                                    }
                                    if(ownerInfo[1] != null && ownerInfo[1] != 'undefined')
                                    {
                                        ownerPercent = ownerInfo[1];
                                        console.log('ownerPercent='+ownerPercent);
                                    }
                                    var ownerData = {nameOfOwner:ownerName, percentOfOwner:ownerPercent};
                                    ownerObjects.push(ownerData);	
                                }
                                console.log('ownerObjects='+ownerObjects);
                                component.set("v.peoOnbCheckOwners", ownerObjects);
                            }
                        }
                        else
                        {
                            var ownerObjects = component.get('v.peoOnbCheckOwners');
                            var ownerData = {nameOfOwner:"", percentOfOwner:""};
                            ownerObjects.push(ownerData);
                            console.log('ownerObjects='+ownerObjects);
                            component.set("v.peoOnbCheckOwners", ownerObjects);
                        }
                        if(checklist.Workers_Comp_FastPass__c == 'Yes') {
                            component.set('v.WCFastPass', true);
                        }
                        if(checklist.Medical_Underwriting_Path__c == 'Gradient Pre-Qualifier'){
                            component.set('v.isMedicalPrequal', true);
                        }
                    }
                    
                    this.buildPath(component, event, helper);
                    component.set("v.contentLoaded", true);
                    
                    // if the checklist indicates the client requested medical
                    // retirieve the form and set the values on the component 
                    if (checklist && checklist.Medical_Benefits_Underwriting_Requested__c == 'Yes') {
                        component.set('v.requestedMedical', true);
                        getMedical.setParams({
                            peoOnboardingChecklistId: component.get('v.PEOOnboardingChecklist.Id'),
                            formName: 'CommunityForms.cmp'
                        });
                        getMedical.setCallback(this, function(res){
                            let data = res.getReturnValue();
                            console.log('medicalQuestionnaire: ');
                            console.log(data);
                            component.set('v.medicalQuestionnaire', data);
                            helper.buildPath(component, event, helper);
                            helper.checkWhichFilesNeeded(component, event);
                        });
                        $A.enqueueAction(getMedical);
                    } else {
                        helper.buildPath(component, event, helper);
                        helper.checkWhichFilesNeeded(component, event);
                    }
                    console.log('Inside getPEOChecklist component.get("v.Account.Id") = '+component.get("v.Account.Id"));
                });
                
                getPEOChecklist.setParams({
                    'accountId': component.get("v.Account.Id"),
                    'oppId': component.get("v.parentAccountOpportunity.Id"),
                    formName: 'CommunityForms.cmp'
                });
                
                covidQuestionnaireNeeded.setParams({
                    'parentAccount': component.get("v.Account"),
                    formName: 'CommunityForms.cmp'
                });
                
                covidQuestionnaireNeeded.setCallback(this, function(data) {
                    var covidQuestionsNeeded = data.getReturnValue();
                    console.log('MGF covidQuestionnaireNeeded.setCallback covidQuestionsNeeded='+covidQuestionsNeeded);
                    component.set("v.covidQuestionsNeeded", covidQuestionsNeeded);
                });
                
                //Added by Bharat- Start of Change
                if(allAccounts.length > 1){
                    let childAccs = allAccounts.slice(1,allAccounts.length);
                    getChildAccsChecklists.setCallback(this, function(data){
                        if(data.getState() === 'SUCCESS'){
                            component.set('v.childAccsChecklist', data.getReturnValue());
                        }
                    });
                    getChildAccsChecklists.setParams({
                        'accList':childAccs,
                        formName: 'CommunityForms.cmp'
                    });
                    $A.enqueueAction(getChildAccsChecklists);
                }  //Added by Bharat - End of Change
                
                $A.enqueueAction(getPermission);
                $A.enqueueAction(getUser);
                $A.enqueueAction(getPEOChecklist);
                $A.enqueueAction(covidQuestionnaireNeeded);
            }
        });
        console.log('component.get("v.recordId")='+component.get("v.recordId"));
        getAcct.setParams({
            'startingId': component.get("v.recordId"),
            formName: 'CommunityForms.cmp'
        });
        
        $A.enqueueAction(getAcct);
    },*/
    
    helperFunctionAsPromise : function(component, helperFunction, helper) {
        return new Promise($A.getCallback(function(resolve, reject) {
            helperFunction(component, resolve, reject, helper);
        }));
    },
    
    getAccountInfo: function(component, resolve, reject, helper) {
        var getAcct = component.get("c.getAccountInformation");
        console.log(component.get("v.recordId"))
        getAcct.setParams({
            'startingId': component.get("v.recordId"),
            formName: 'CommunityForms.cmp'
        });
        
        getAcct.setCallback(this, function(data) {
            // set the account on the parent container 
            // if there are children set the children on the parent
            let allAccounts = data.getReturnValue();
            if (data.getState() != 'SUCCESS') {
                console.log(data.getError())
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            
            // parent account is at allAccounts[0] on the array. Set that as Account attr
            // if the parent account status is not prospect set accountStatusNotProspect true
            if(allAccounts != null)
            {
                component.set("v.Account", allAccounts[0]);
                component.set("v.parentAccountId", allAccounts[0].Id);
                component.set("v.Accounts", allAccounts);
                return resolve(true);
            }
            else {
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                console.log('no accts ret')
                reject({t: t, m: m, ty: ty});
            }
        });
        
        $A.enqueueAction(getAcct);
    },
    
    getChildChecklists: function(component, resolve, reject, helper) {
        component.set("v.contentLoaded", false);
        
        var allAccounts = component.get('v.Accounts');
        if(allAccounts.length > 1) {
            var getChildAccsChecklists = component.get("c.getPEOOnboardingChecklistsData"); //Added by Bharat
            let childAccs = allAccounts.slice(1,allAccounts.length);
            
            getChildAccsChecklists.setParams({
                'accList':childAccs,
                formName: 'CommunityForms.cmp'
            });
            
            getChildAccsChecklists.setCallback(this, function(data){
                if (data.getState() != 'SUCCESS') {
                    console.log(data.getError())
                    let t = 'Error',
                        m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                        ty = 'Error';
                    
                    reject({t: t, m: m, ty: ty});
                }
                else {
                    component.set('v.childAccsChecklist', data.getReturnValue());
                    resolve(true);
                }
            });
            
            $A.enqueueAction(getChildAccsChecklists);
        }
        else {
            resolve(true);
        }
    },
    
    getIndustryNames: function(component, resolve, reject, helper){
        
        //return new Promise(function(resolve, reject) {
        var naicsCodes = [];
        var parentNAICSCode = component.get('v.Account').NAICS_Code__c;
        var accountArray = component.get('v.Accounts');
        naicsCodes.push(parentNAICSCode);
        if(parentNAICSCode != null && parentNAICSCode != '' && parentNAICSCode != 'undefined') {
            for(var i = 0; i < accountArray.length; i++) {
                if(accountArray[i].NAICS_Code__c != parentNAICSCode) {
                    naicsCodes.push(accountArray[i].NAICS_Code__c);
                }
            }
        }
        var getIndustryNames = component.get('c.getIndustryNames');
        
        getIndustryNames.setParams({
            naicsCodes : naicsCodes
        });
        
        getIndustryNames.setCallback(this, function(res){
            var state = res.getState(); 
            var data = res.getReturnValue();
            if (state != 'SUCCESS' || !data) {
                console.log(data.getError())
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            else {
                for(var i = 0; i < data.length; i++) {
                    //console.log('Industry Found: ' + data[i]);
                }
                if(data.length > 0) {
                    component.set('v.industries', data);
                    component.set('v.noMatchingQuestions', false);
                    component.set('v.noIndustryFound', false);
                } else {
                    component.set('v.noMatchingQuestions', true);
                    component.set('v.noIndustryFound', true);
                    
                }
            }
            console.log(data);
            component.set('v.loadingSpin', false);
            resolve(true);	
        });
        
        $A.enqueueAction(getIndustryNames);
        //})
    },
    
    getSysPermissions: function(component, resolve, reject, helper) {
        
        //return new Promise(function(resolve, reject) {
        var getPermission = component.get("c.getSystemPermission");
        
        getPermission.setCallback(this, function(data) {
            if (data.getState() != 'SUCCESS') {
                console.log(data.getError())
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            else {
                console.log('permis issue in comforms')
                component.set("v.hasAccess", data.getReturnValue());
                resolve(true);
            }
        });
        
        $A.enqueueAction(getPermission);
        //})
    },
    
    getRunningUser: function(component, resolve, reject, helper) {
        
        //return new Promise(function(resolve, reject) {
        var getUser = component.get("c.getRunningUser");
        
        getUser.setCallback(this, function(data) {
            if (data.getState() != 'SUCCESS') {
                console.log(data.getError())
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            else {
                component.set("v.runningUser", data.getReturnValue());
                if(data.getReturnValue().Profile.Name.includes("Community"))
                {
                    component.set('v.isCommunityUser', true);
                }
                
                resolve(true);
            }
        });
        
        $A.enqueueAction(getUser);
        //})
    },
    
    getCommUser: function(component, resolve, reject, helper) {
        
        //return new Promise(function(resolve, reject) {
        var getCommunityUser = component.get("c.getCommunityUser");
        
        getCommunityUser.setParams({
            'startingId': component.get("v.recordId"),
            formName: 'CommunityForms.cmp'
        });
        
        getCommunityUser.setCallback(this, function(data) {
            if (data.getState() != 'SUCCESS') {
                console.log(data.getError())
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            else {
                component.set("v.communityUser", data.getReturnValue());
                //console.log('component.get("v.communityUser")='+component.get("v.communityUser") + ' component.get("v.chosenExperience")='+component.get("v.chosenExperience"));
                resolve(true);
            }
        });
        
        $A.enqueueAction(getCommunityUser);
        //})
    },
    getChecklist: function(component, resolve, reject, helper) {
        
        //return new Promise(function(resolve, reject) {
        var getPEOChecklist = component.get("c.getPEOOnboardingChecklist");
        
        getPEOChecklist.setParams({
            'accountId': component.get("v.Account.Id"),
            formName: 'CommunityForms.cmp'
        });
        
        getPEOChecklist.setCallback(this, function(data) {
            if (data.getState() != 'SUCCESS' || !data.getReturnValue()) {
                console.log(data.getError())
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            else {
                
                //console.log(data.getReturnValue());
                var checklist = data.getReturnValue();
                component.set("v.PEOOnboardingChecklist", checklist);
                
                // set all the attributes to lock edit or upload access based on status fields
                helper.setUWStatusLock(component, component.get("v.Accounts"), checklist,helper);
                
                var ownerObjects = component.get('v.peoOnbCheckOwners');
                if(checklist.List_of_Owners__c != null && data.getReturnValue().List_of_Owners__c != undefined)
                {
                    var ownerAndPercentList = checklist.List_of_Owners__c.split(';');
                    if(ownerAndPercentList.length > 0)
                    {
                        for(var index = 0; index < ownerAndPercentList.length; index++)
                        {
                            var ownerInfo = ownerAndPercentList[index].split(',');
                            var ownerName = "";
                            var ownerPercent = "";
                            
                            if(ownerInfo[0] != null && ownerInfo[0] != 'undefined')
                            {
                                ownerName = ownerInfo[0];
                            }
                            if(ownerInfo[1] != null && ownerInfo[1] != 'undefined')
                            {
                                ownerPercent = ownerInfo[1];
                            }
                            var ownerData = {nameOfOwner:ownerName, percentOfOwner:ownerPercent};
                            ownerObjects.push(ownerData);	
                        }
                        //console.log('ownerObjects='+ownerObjects);
                        component.set("v.peoOnbCheckOwners", ownerObjects);
                    }
                }
                else
                {
                    var ownerObjects = component.get('v.peoOnbCheckOwners');
                    var ownerData = {nameOfOwner:"", percentOfOwner:""};
                    ownerObjects.push(ownerData);
                    //console.log('ownerObjects='+ownerObjects);
                    component.set("v.peoOnbCheckOwners", ownerObjects);
                }
                
                if(checklist.Workers_Comp_FastPass__c == 'Yes') {
                    component.set('v.WCFastPass', true);
                }
                
                if(checklist.Medical_Underwriting_Path__c == 'Gradient Pre-Qualifier'){
                    component.set('v.isMedicalPrequal', true);
                }
            }
            //this.buildPath(component, event, helper);
            //component.set("v.contentLoaded", true);
            resolve(true);
        });
        
        $A.enqueueAction(getPEOChecklist);
        //})
    },
    
    getMedicalQuestionnaire: function(component, resolve, reject, helper) {
        //return new Promise(function(resolve, reject) {
        var checklist = component.get("v.PEOOnboardingChecklist");
        
        if (checklist && checklist.Medical_Benefits_Underwriting_Requested__c == 'Yes') { 
            let getMedical = component.get('c.getMedicalQuestionnaireForm');
            component.set('v.requestedMedical', true);
            
            getMedical.setParams({
                peoOnboardingChecklistId: component.get('v.PEOOnboardingChecklist.Id'),
                formName: 'CommunityForms.cmp'
            });
            
            getMedical.setCallback(this, function(res){
                if (res.getState() != 'SUCCESS' || !res.getReturnValue()) {
                    console.log(res.getReturnValue().getError())
                    let t = 'Error',
                        m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                        ty = 'Error';
                    reject({t: t, m: m, ty: ty});
                }
                else {
                    let data = res.getReturnValue();
                    //console.log(data);
                    component.set('v.medicalQuestionnaire', data);
                    //helper.buildPath(component, event, helper);
                    //helper.checkWhichFilesNeeded(component, event);
                    resolve(true);
                }
            });
            
            $A.enqueueAction(getMedical);
        }
        else {
            //helper.buildPath(component, event, helper);
            //helper.checkWhichFilesNeeded(component, event);
            resolve(true);
        }
        //})
    },
    
    covidQuestionnaireIsNeeded: function(component, resolve, reject, helper) {
        
        //return new Promise(function(resolve, reject) {
        var covidQuestionnaireNeeded = component.get("c.needCovidQuestionnaire");
        
        covidQuestionnaireNeeded.setParams({
            'parentAccount': component.get("v.Account"),
            formName: 'CommunityForms.cmp'
        });
        
        covidQuestionnaireNeeded.setCallback(this, function(data) {
            if (data.getState() != 'SUCCESS') {
                console.log(data.getError())
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            else {
                var covidQuestionsNeeded = data.getReturnValue();
                component.set("v.covidQuestionsNeeded", covidQuestionsNeeded);
                resolve(true);
            }
        });
        
        $A.enqueueAction(covidQuestionnaireNeeded);
        //})
    },
    
    buildPath: function(component, event, helper) {
        console.log('Building Path...');
        //this is where we define all of the tabs along the path.  We'll need to add criteria to add each tab based on journey or otherwise in this method
        let stepObjectList = [];
        let checklist = component.get('v.PEOOnboardingChecklist');
        let medical = component.get('v.medicalQuestionnaire');
        
        if(checklist.Medical_Benefits_Underwriting_Requested__c == 'Yes' && component.get('v.isMedicalPrequal')){
            stepObjectList.push({ label: 'Medical', value: 'medical' });
            if(checklist.Medical_Pre_Qualifier_Status__c == 'Approved' || checklist.Medical_Pre_Qualifier_Status__c == 'Declined'){
                stepObjectList.push({ label: 'Company Information', value: 'acctUpdate' });
                if (checklist.Submit_to_Workers_Comp_Underwriting__c != 'Yes - WC to be excluded') stepObjectList.push({ label: "Workers' Compensation", value: "wc" });
                stepObjectList.push({ label: "Additional Information", value: "addtlInfo" });
            }
        }
        else{
            stepObjectList.push({ label: 'Company Information', value: 'acctUpdate' });
            if(checklist.Medical_Benefits_Underwriting_Requested__c == 'Yes'){
                stepObjectList.push({ label: 'Medical', value: 'medical' });
            }
            if (checklist.Submit_to_Workers_Comp_Underwriting__c != 'Yes - WC to be excluded') stepObjectList.push({ label: "Workers' Compensation", value: "wc" });
            stepObjectList.push({ label: "Additional Information", value: "addtlInfo" });
        }
        if (component.get('v.runningUser') && component.get('v.runningUser.Profile.Name') != 'Customer Community Login User Clone') {
            if(checklist.Medical_Pre_Qualifier_Status__c != 'Approved'){
                stepObjectList.push({ label: "Submit", value: "submit" });
            }
            stepObjectList.push({ label: "Summary", value: "summary" });
        }
        else{
            stepObjectList.push({ label: "Complete", value: "submit" });
        }
        component.set('v.allSteps', stepObjectList);
        console.log('All steps');
        console.log(stepObjectList);
        //resume functionality. need to take the current step from the checklist, add all previous steps to completed list and set the active tab
        //to the one after the completed tab.  If there are no completed steps, start from the first tab
        let tablist = [];
        //put all the tabs into a list to check progress against
        for(let i=0;i<stepObjectList.length;i++){
            var step = stepObjectList[i];
            tablist.push(step.value);
        }
        let currentStep = '';
        
        if(checklist && !$A.util.isUndefinedOrNull(checklist.Completed_Step__c)){
            console.log('Setting current step for form: '+checklist.Completed_Step__c)
            let completedStep = checklist.Completed_Step__c;
            
            //put all the tabs before and including the completed step marked on the checklist
            let completedTabs = component.get("v.completedSteps");
            console.log('completedSteps');
            console.log(completedTabs);
            for(let i=0;i<=tablist.indexOf(completedStep);i++){
                if(!completedTabs.includes(tablist[i])){
                    completedTabs.push(tablist[i]);
                }
            }
            //set the active tab to be the next tab after the completed step
            let nextTab = tablist.indexOf(completedStep) + 1;
            if (nextTab > tablist.length - 1) currentStep = tablist[nextTab - 1];
            else currentStep = tablist[nextTab];
            component.set('v.currStep', currentStep);
            component.set('v.selectedStep', tablist[nextTab] ? tablist[nextTab] : tablist[nextTab-1]);
            component.set('v.completedSteps', completedTabs);
            
            if(currentStep == 'submit'){
                helper.checkWhichFilesNeeded(component, event);
            }
            console.log('Setting current step from tab list');
            console.log('currentStep: ' + currentStep);
            console.log('From tab list');
            console.log(tablist)
        }else{
            console.log('no completed step found on checklist. Setting pos to tablist 0');
            console.log(tablist);
            currentStep = tablist[0];
            component.set('v.currStep', currentStep);
            component.set('v.selectedStep', tablist[0]);
        }
    },
    
    loadFinished : function(component, event,helper) {
        component.set("v.contentLoaded", true);
    },
    
    increaseStep : function(component, event) {
        var step = component.get("v.Step");
        step = step + 1;
        component.set("v.Step", step);
    },
    
    decreaseStep : function(component, event) {
        var step = component.get("v.Step");
        step = step - 1;
        component.set("v.Step", step);
    },
    
    checkWhichFilesNeeded : function(component, event) {
        if(component.get("v.requestedMedical")  === true )component.set("v.misMedReqd", true);
        //Parent checklist validations happen here for upload files
        var chldChklst = component.get("v.PEOOnboardingChecklist");
        if(chldChklst.CensusRequired__c === true)component.set('v.censusRequired', true)
        else component.set('v.censusRequired', false)
        if(chldChklst.Claims_Report_required__c === true)component.set('v.claimsReportRequired', true)
        else component.set('v.claimsReportRequired', false)
        if(chldChklst.Health_Insurance_Renewal_required__c === true)component.set('v.hlthInsRenwReqd', true)
        else component.set('v.hlthInsRenwReqd', false)
        if(chldChklst.Health_Insurance_Summary_required__c === true)component.set('v.hlthInsSummReqd', true)
        else component.set('v.hlthInsSummReqd', false)
        if(chldChklst.Health_Invoice_required__c === true)component.set('v.hlthInvReqd', true)
        else component.set('v.hlthInvReqd', false)
        if(chldChklst.Loss_Runs_required__c === true)component.set('v.lossRunsReqd', true)
        else component.set('v.lossRunsReqd', false)
        if(chldChklst.Payroll_Register_Required__c === true)component.set('v.payrollRegReqd', true)
        else component.set('v.payrollRegReqd', false)
        if(chldChklst.SUI_Required__c === true)component.set('v.suiReqd', true)
        else component.set('v.suiReqd', false)
        if(chldChklst.WC_Declarations_Required__c === true)component.set('v.wcDecReqd', true)
        else component.set('v.wcDecReqd', false)
        if(chldChklst.WC_RatesAndPricing_Required__c === true)component.set('v.wcRtNPrcReqd', true)
        else component.set('v.wcRtNPrcReqd', false)
            },
    
    medicalQuestionnaireCallback: function(res) {
        
    },
    // This takes in all accounts and updates the attributes on the component
    // that control if the user is able to edit any of the fields or upload
    // files based on some status values on the Parent account
    setUWStatusLock: function(component, allAccounts, uwChecklist,helper) {
        let CSCMStatusLockCodes = {
            Underwriting: true,
            Approved: true,
            ContractPending: true,
            PendingActivation: true,
            Client: true,
            PendingTermination: true, 
            Terminated: true,
            UnderContract: true
        };
        let MedUWStatusLockCodes = {
            'Pre-Med Approved': true,
            'Pre-Med Declined': true,
            'Approved for PEO Medical': true,
            'Approved to Self-Retain': true,
            'In-Progress': true,
            'InProgress': true,
            'Approved for PEO Medical': true,
            'Approved to Self-Retain': true,
            'In-Progress': true,
        };
        let WCUWStatusLockCodes = {
            'WC inProgress': true,
            'In-Progress': true,
            'WC Approved for PEO Master': true,
            'Approved for PEO Master': true,
            'WC Approved to Self Retain': true,
            'Approved to Self Retain': true,
            'Approved for PIA': true
        };
        
        var lockEdit = false;
        var lockMed = false;
        var lockWC = false;
        var lockMsg = '';
        if(!$A.util.isUndefinedOrNull(allAccounts[0].CSCMContractStatus__c) && 
           (allAccounts[0].CSCMContractStatus__c !== 'Prospect')){
            component.set('v.disableFilesUpload', true);
            console.log('disabling File Upload');
        }
        
        if (!$A.util.isUndefinedOrNull(allAccounts[0].CSCMContractStatus__c) &&
            CSCMStatusLockCodes[allAccounts[0].CSCMContractStatus__c]) {
            lockEdit = true;
            console.log('locking edit from account contract status');
        }
        // set the medical form to lock on the proper status
        if (!$A.util.isUndefinedOrNull(uwChecklist.CS_CM_Med_UW_Accept_Date__c) || (!$A.util.isUndefinedOrNull(uwChecklist.CS_CM_Medical_UW_Status__c) &&
                                                                                    MedUWStatusLockCodes[uwChecklist.CS_CM_Medical_UW_Status__c])) {
            lockMed = true;
            console.log('locking medical from med status');
        }
        
        if (!$A.util.isUndefinedOrNull(uwChecklist.CS_CM_WC_UW_Accept_Date__c) || (!$A.util.isUndefinedOrNull(uwChecklist.CS_CM_WC_UW_Status__c) &&
                                                                                   MedUWStatusLockCodes[uwChecklist.CS_CM_WC_UW_Status__c])) {
            lockWC = true;
            console.log('locking wc from wc status');
        }
        
        if((lockEdit || lockMed || lockWC) && component.get('v.isCommunityUser')){
            lockMsg =  'Thank you for your business! Your documents have been submitted and are under review.  Please reach out to your PEO Consultant if any additional changes are needed.';
        }
        else if((lockEdit || lockMed || lockWC) && !component.get('v.isCommunityUser')){
            lockMsg = 'This Prospect-Client has been submitted to underwriting and is under review';
        }
        component.set('v.lockEditing', lockEdit);
        component.set('v.lockMedicalEditing', lockMed);
        component.set('v.lockWCEditing', lockWC);
        component.set('v.lockMessage', lockMsg);
    },
    updateComponentViewWidth: function(component, event) {
        if(component.get('v.selectedTab') == "medicalQuestionnaire" || component.get('v.selectedTab') == "uploadFiles"|| component.get('v.selectedTab') == "summary" )
        {
            var element = document.getElementById("housingDiv");
            if (element) {
                element.classList.remove("slds-container_large");
                element.classList.add("maxWidth");   
            }
            
            if(component.get('v.selectedTab') == "uploadFiles")
            {
                this.checkWhichFilesNeeded(component, event);
            }
            if(component.get('v.selectedTab') == "medicalQuestionnaire") {
                component.set("v.medQuestionnaireSelectedAccId", component.get("v.Account.Id"));
            }
            
        }
        else {
            var element = document.getElementById("housingDiv");
            if(element && !element.classList.contains("slds-container_large")) {
                element.classList.remove("maxWidth");
                element.classList.add("slds-container_large");
            }
        }
    },
    // The entry point for all auto save operations from the controller
    // First check to see if we need to immedietly auto save the records.
    // if so, send a call to the manageAutoSaveServerCall method which will handle
    // removing the records that are already being saved, and saving what's left.
    // Then check to see if we need to cancel an autosave operation. If so, trigger the 
    // manageAutoSaveServerCall which will also handle canceling. Bail out of method if
    // first or second condition is true.
    // Finally start to parse the params and send the call to addFieldValueToStore
    // which manages reseting the timer and updating the auto save storage
    manageAutoSave: function(cmp, e, helper) {
        // IF we need to cancel the operation send the call to manageAutoSaveServerCall
        // and return from the method
        let sendImmedieteSave = e.getParam('sendImmediete');
        if (sendImmedieteSave) {
            helper.manageAutoSaveServerCall(cmp, event, helper, {removeThenSave: true});
            return;
        }
        
        // IF we need to cancel the operation send the call to manageAutoSaveServerCall
        // and return from the method
        let cancel = e.getParam('cancelAll');
        if (cancel) {
            helper.manageAutoSaveServerCall(cmp, event, helper, {clear: true});
            return;
        }
        
        // get the stored values
        // clear any auto save syncs that are already in queue to minimize multiple requests
        // parse the event to get values we need
        let accountId = e.getParam('accountId');
        let accountName = e.getParam('accountName'); 
        let recordId =  e.getParam('recordId');
        let fieldAPIName = e.getParam('fieldName');
        let objectName = e.getParam('objectName');
        let fieldValue = e.getParam('fieldValue');
        
        // get the map containing multiple records to add to the auto save if it exists
        let multiFieldMap = e.getParam('objectToFieldsMap');
        
        // loops the map of multiple records to save. If one doesn't exist we won't
        // enter this logic
        // Get all the params from the object including the record fields
        // for each field send a request to add it to the storage
        for (let objectName in multiFieldMap) {
            let objectMap = multiFieldMap[objectName];
            let accountName = objectMap.accountName;
            let recordId = objectMap.recordId;
            let fieldList = objectMap.fields;
            
            // loop over the fields and add them to the storage
            for (let fieldAPIName in fieldList) {
                let fieldSaveParams = {
                    fieldAPIName: fieldAPIName,
                    objectAPIName: objectName,
                    FieldValue: fieldList[fieldAPIName],
                    recordId: recordId,
                    accountName: accountName
                };
                helper.addFieldValueToStore(cmp, e, helper, fieldSaveParams);
            }
        }
        
        // only send the save request for a field if we have all the parameters we need
        if (accountName && recordId && fieldAPIName && objectName) {
            let fieldParams = {
                fieldAPIName: fieldAPIName,
                objectAPIName: objectName,
                FieldValue: fieldValue,
                AccountID: accountId,
                recordId: recordId,
                accountName: accountName
            };
            // console.log('manageAutoSave');
            // console.table(fieldVals);
            helper.addFieldValueToStore(cmp, e, helper, fieldParams);   
        } else {
            console.log('Null value provided for auto save registering:')
            console.log('accountName: '+accountName);
            console.log('recordId: ' + recordId);
            console.log('fieldAPIName: ' + fieldAPIName);
            console.log('objectName: ' + objectName);
        }
    },
    // adds individual field values to the auto save storage
    // @Params: 
    // fieldVals: map with values relevent to the new add
    // first match/create on the account to get the object: {accId: {account, checklist, ...}, accId2: {...}}
    // then update the value for the passed in field API name on that map
    // finally reset the timer to reset the auto save timer
    addFieldValueToStore: function(cmp, e, helper, fieldVals){
        let foundMAtch;
        // store could be blank or could have values: 
        let store = cmp.get('v.RecordsToSave');
        let accountRecordsMap;
        let recordMap;
        if (!store) store = {};
        
        // search for a matching account using the account ID passed in and in the storage
        for (let accName in store) {
            if (accName == fieldVals.accountName) {
                accountRecordsMap = store[accName];
                foundMAtch = true;
                break;
            }
        }
        
        // if an account match is not found
        // create a new instance of the object for the account
        if (!accountRecordsMap) {
            helper.createAccountMapInStore(store, fieldVals.accountName);
            accountRecordsMap = store[fieldVals.accountName];
            //createRecordMapInAccountMap(store[fieldVals.AccountID], fieldVals.recordId, fieldVals.objectAPIName);
            // store should be like {accName: {Account: {recordId: xxxxxxxxxx}}}
        }
        
        // find the matching record on the mapping
        recordMap = accountRecordsMap[fieldVals.objectAPIName]; 
        
        // if record is not found
        // create an instance of it on the map
        if (!recordMap) {
            recordMap = helper.createRecordMapInAccountMap(accountRecordsMap, fieldVals.recordId, fieldVals.objectAPIName);
        } 
        
        // change the createRecordMapInAccountMap to return the last index if rec it's inserting
        // into an array. Save two lines
        if (Array.isArray(recordMap)) {
            recordMap = recordMap[recordMap.length - 1];
        }
        
        recordMap[fieldVals.fieldAPIName] = fieldVals.FieldValue;    
        
        // set the new values on the component
        cmp.set('v.RecordsToSave', store);
        
        let p = {reset: true, clear: false, records: store};
        // Reset timer to initiate save
        helper.manageAutoSaveServerCall(cmp, e, helper, p);   
    },
    // Manages the queued calls to the server to save records.
    // Params contains arguments used for funtionality
    // clear: if true clears all instances of queued saves. Triggered for manual saves
    // reset: if true clears all insteances of queued saves and sends new save request for 2.5 mins
    manageAutoSaveServerCall: function(cmp, e, helper, params) {
        // if reset
        if (params.reset) {
            // clear all instances of the apex calls
            // create new instance using the sendAutoSave method 
            if (cmp.get('v.autoSaveFunction')) clearTimeout(cmp.get('v.autoSaveFunction'));
            cmp.get("v.autoSave")
            var inputTimer = setTimeout($A.getCallback(() => helper.sendAutoSave(cmp, e, helper, params.records)), 60000);
            cmp.set("v.autoSaveFunction", inputTimer);
        }
        
        // if clearing timer
        // remove all async calls and restore the RecordsToSave to a blank obj
        if (params.clear) {
            helper.resetAutoSaveToDefault(cmp, e, helper);
        }
        
        // If need to remove then save
        // send the call to remove the records if the params object 
        // contains any(it should), then send the request to save immedietly
        if (params.sendImmediete) {
            let records = cmp.get('v.RecordsToSave');
            helper.sendAutoSave(cmp, e, helper, records);
            helper.resetAutoSaveToDefault(cmp, e, helper);
        }
        
        // immidietly send the auto save
        // then reset to defuelt
        if (params.sendImmediete) {
            let records = cmp.get('v.RecordsToSave');
            helper.sendAutoSave(cmp, e, helper, records);
            helper.resetAutoSaveToDefault(cmp, e, helper);
        }
    },
    // send the auto save request
    // Surfaces UI message for auto save in progress
    // recieves the storage as params. Sends the auto save apex call for each
    // object type(maybe do a generics kind of thing?)
    sendAutoSave: function(cmp, e, helper, records) {
        try {
            let autoSaveAction = cmp.get('c.handleAutoSaveRecords');
            // list map is just a storage for the list of records to be saved
            let listMap = {
                Account: [],
                PEO_Onboarding_Checklist__c: [],
                PEO_Onboarding_Medical_Questionnaire__c: [],
                WC_Questionnaire_Industry_Specific__c: [],
                Opportunity: [],
                Policy_Period__c: []
            };
            
            // loop over the records passed into the method
            for (let accountName in records) {
                // get the map of records to be saved: {Account: {}, PEO_MedicalQuestionnaire: {}}
                let recordTypeMap = records[accountName];
                // iterate the map of records
                // if the record is an array iterate that array and add each record to its
                // respective listMap storage place. Otherwise just add the record to it's respective
                // listMap storage place.
                for (let recordType in recordTypeMap) {
                    if (Array.isArray(recordTypeMap[recordType])) {
                        let recordArray = recordTypeMap[recordType];
                        recordArray.forEach(rec => listMap[recordType].push(rec));
                    } else {
                        listMap[recordType].push(recordTypeMap[recordType]);
                    }
                }
            }
            
            // add the lists of records to be saved to the server action and send the action
            autoSaveAction.setParams({
                accounts: listMap.Account,
                checklists: listMap.PEO_Onboarding_Checklist__c,
                medicalForms: listMap.PEO_Onboarding_Medical_Questionnaire__c,
                policyPeriodForms: listMap.Policy_Period__c,
                industryForms: listMap.WC_Questionnaire_Industry_Specific__c,
                formName: 'CommunityForms.cmp'
            });
            
            // the auto save shouldn't alter much on the form since it's a background process.
            // Maybe a small UI message or something to indicate success or failure.
            // Add something to turn auto save off if fetal error?
            autoSaveAction.setCallback(this, function(res) {
                console.log('Auto save return values:');
                console.table(res.getState(), res.getError(), res.getReturnValue())
            });
            $A.enqueueAction(autoSaveAction);
        }catch(e) {
            console.log('Form Error auto saving');
            console.log(e);
        }
    },
    // used when an account does not have a map value in storage
    // creates generic map with accId as key and empty map as value
    createAccountMapInStore: function(store, accName) {
        store[accName] = {};
        return store;
    }, 
    // add a new instance of the record to be saved into the storage. 
    // Expect to be passed in the map of records either blank or not: {Account: {}} and expect
    // to create a new instance on the map for the record and OBJ name:
    // before: {Account: {Id: xxxxxx}}, After: {Account: {Id: xxxxxx}, Policy_Period__c: [{Id: xxxx}]}
    createRecordMapInAccountMap: function(accountRecordStore, recordId, objName) {
        if (objName == 'Policy_Period__c') {
            accountRecordStore[objName] = [{Id: recordId}];
            return accountRecordStore[objName][0];
        }
        
        accountRecordStore[objName] = {Id: recordId}; 
        return accountRecordStore[objName];
    },
    // clear the auto save storage and timed autoSave function call 
    resetAutoSaveToDefault: function(cmp, e, helper) {
        cmp.set('v.RecordsToSave', {});
        clearTimeout(cmp.get("v.autoSaveFunction"));
    },
    
    /*getIndustryNames: function(component, event, helper){
        var naicsCodes = [];
        var parentNAICSCode = component.get('v.Account').NAICS_Code__c;
        var accountArray = component.get('v.Accounts');
        naicsCodes.push(parentNAICSCode);
        if(parentNAICSCode != null && parentNAICSCode != '' && parentNAICSCode != 'undefined') {
            for(var i = 0; i < accountArray.length; i++) {
                if(accountArray[i].NAICS_Code__c != parentNAICSCode) {
                    naicsCodes.push(accountArray[i].NAICS_Code__c);
                }
            }
        }
        var getIndustryNames = component.get('c.getIndustryNames');
        getIndustryNames.setParams({
            naicsCodes : naicsCodes
        });
        getIndustryNames.setCallback(this, function(res){
            var state = res.getState(); 
            var data = res.getReturnValue();
            if (state != 'SUCCESS' || !data) {
                console.log('ERRORRRRR')
            }
            else {
                for(var i = 0; i < data.length; i++) {
                    console.log('Industry Found: ' + data[i]);
                }
                if(data.length > 0) {
                    component.set('v.industries', data);
                    component.set('v.noMatchingQuestions', false);
                    component.set('v.noIndustryFound', false);
                } else {
                    component.set('v.noMatchingQuestions', true);
                    component.set('v.noIndustryFound', true);
                    
                }
            }
            component.set('v.loadingSpin', false);
        });
        $A.enqueueAction(getIndustryNames);
    },*/
    sendCompleteNotification: function(component, event, helper,currentStep){
        var sendEmail = component.get('c.sendCompleteEmail');
        let obChecklist = component.get('v.PEOOnboardingChecklist')
        let allAccounts = component.get('v.Accounts');
        var acctName;
        if(allAccounts){
            acctName = allAccounts[0].Name;
        }
        console.log('sendCompleteNotification acctName'+acctName);
        if(obChecklist && acctName && currentStep){
            console.log('triggering notif')
            sendEmail.setParams({
                checklist : obChecklist,
                accountName : acctName,
                currStep : currentStep
            });
            sendEmail.setCallback(this, function(res){
                var state = res.getState(); 
                var data = res.getReturnValue();
                if (state != 'SUCCESS' || !data) {
                    console.log('email send error')
                }
                else {
                    console.log('email send success');
                }
            });
            $A.enqueueAction(sendEmail);
        }
        else{
            console.log('something is missing');
        }
        
    },
    handleError: function(data) {
        console.log(data)
        console.log(data.t);
        console.log(data.m)
        var event = $A.get("e.force:showToast");
        event.setParams({
            title: data.t,
            message: data.m,
            type: data.ty
        });
        event.fire();
        
        if (data.broke) $A.get("e.force:closeQuickAction").fire();
    },
    refreshWCRelatedProperties: function(cmp, e, helper) {
        try{
            console.log('IN refresh call');
            helper.helperFunctionAsPromise(cmp, helper.getIndustryNames, helper)
            .then($A.getCallback(function() {
                return helper.helperFunctionAsPromise(cmp, helper.covidQuestionnaireIsNeeded, helper)
            }))
            .then(res => console.log('Success: '+res))
            .catch(err => console.log(err));
        }catch(e) {
            console.log('refresh err');
            console.log(err);
        }
    },
})