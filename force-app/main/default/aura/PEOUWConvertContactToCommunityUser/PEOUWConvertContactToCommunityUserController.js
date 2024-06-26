({
    initialize: function(component, e, helper) {
        if (!component.get('v.recordId')) {
        	let err = {
                m: 'Error initializing the component. Record not available. Contact admin for suppport.',
                t: 'Failure Initializing',
                ty:  'warning',
                broke: true
            };
            return helper.handleError(err);
        }
        
        // Start the loading spinner loop. Throws a message every 10 seconds it isn't cleared
        helper.updateSpinnerState(component, e, helper);
        
        /*AE: initialization refactor: SFDC-23774
		helper.helperFunctionAsPromise(component, e, helper, helper.methodZero)
		.then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.getEnvironment)}))
		.then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.getUser)}))
		.then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.getPermissions)}))
		.then( $A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.getContactInfo)}))
		.then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.checkForAssociatedCommunityUser)}))
		.then($A.getCallback(function() { return helper.helperFunctionAsPromise(component, e, helper, helper.assignCreationValues)}))
		.then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.getOppty)}))
		.then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.getChecklistDocs)}))
		//.then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.getClientNumber)}))
		//Check if the user has QQ testing access
		.then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.checkQQSPATesterAccess)}))
		.then(function(res) {
			helper.helperFunctionAsPromise(component, e, helper, helper.updateViewToStep1); // do sync
			helper.helperFunctionAsPromise(component, e, helper, helper.updateSpinnerState); // do sync
		})
		.catch(err => helper.handleInitialError(err,component)); // break spinner once here
		*/
        
        helper.helperFunctionAsPromise(component, e, helper, helper.getInitializationAttributes)
        	.then($A.getCallback(() => helper.helperFunctionAsPromise(component, e, helper, helper.getInitializationRecord)))
        	.then($A.getCallback(() => {
                component.set('v.step', 1);
            	helper.updateSpinnerState(component, e, helper);
            }))
			.catch(err => {
                helper.handleError(err,component)
            })
        
        component.set('v.toastMode','dismissible'); // do sync
    },
    
    handleChildAccountsSelection:function(component, event, helper){
        var changeValue = event.getParam("value");
        if(changeValue == 'No'){
            component.set('v.showInfoMessage', false);
        }
    },
    
    handleFUPChange: function(component, e, helper){
        var checkList = component.get('v.existingChecklist');
        if(component.get('v.fullUnderwritingPathVal') == 'No'){
            if((checkList.Total_Number_of_Employees__c &&  checkList.Total_Number_of_Employees__c > 49) ||
               (checkList.Is_Your_Plan_Self_Funded_or_Level_Funded__c && checkList.Is_Your_Plan_Self_Funded_or_Level_Funded__c == 'Yes') || 
               (checkList.Currently_using_a_PEO__c && checkList.Currently_using_a_PEO__c == 'Yes') ||
               (checkList.Medical_Carriers_currently_in_use__c && checkList.Medical_Carriers_currently_in_use__c != 'None of These')){
                component.set('v.showInfo', true);
                component.set('v.fullUnderwritingPathVal', 'Yes');
            }
        }
    },
                
    okay: function(component, e, helper){
    	component.set('v.showInfo', false);
    },
    
    /*
    handlechangecladd: function(component, event, helper){
         var changeValue = event.getParam("value");     
        
        console.log('value', changeValue);
        if(changeValue=='Yes' ){
            		component.set('v.ClientAddOn', true);
                	component.set('v.fullUnderwritingPathVal', 'Yes');    
                    component.set('v.WhyareyouchoosingVal', 'Client Add-on');                    
                }
                else
                {
                	component.set('v.ClientAddOn', false);
                }
                    console.log(component.get('v.WhyareyouchoosingVal'));
                    console.log(component.get('v.ClientAddOn'));
        },
    */
    handleChange:function(component, e, helper){
        
        var checklists = component.get('v.existingChildAccChecklists');		
        var selectedAccs = e.getParam("value");		
        var str = ''		
        var noneVal;		
        if(selectedAccs.length > 0){		
            str = selectedAccs.join(';');		
        }		
        		
        var oldValues = component.get('v.childAccsOldValue');		
        		
        if(str.includes('None')){		
            if(oldValues.includes('None')){		
                selectedAccs.splice(selectedAccs.indexOf('None'), 1)		
                component.set('v.childAccountId', selectedAccs);		
            }else{		
                noneVal = ['None'];		
                //str = noneVal;		
                if(checklists != ''){		
                    component.set('v.unCheckChildAcc', true);		
                    component.set('v.message', 'Checking this box will delete all the Child Checklists and all associated data. please confirm deletion.');		
                }else{		
                    component.set('v.childAccountId', 'None');		
                }		
            }		
        }		
            		
        component.set('v.childAccsOldValue', component.get('v.childAccountId'));		
        		
        if(checklists != '' && !component.get('v.unCheckChildAcc')){		
            var chklistsAfterUnchecking = '';		
            var isUnchecked = false;		
            var buildChklist = '';		
            var arr = checklists.split(';');		
            for(let i=0; i<arr.length; i++){		
                if(!isUnchecked){		
                    isUnchecked = str.indexOf(arr[i]) == -1;		
                    if(isUnchecked){		
                        component.set('v.uncheckedChildAccId', arr[i]);		
                    }else{		
                        if(chklistsAfterUnchecking != ''){		
                            chklistsAfterUnchecking = chklistsAfterUnchecking + ';' + arr[i];		
                        }else{		
                            chklistsAfterUnchecking = arr[i];		
                        }		
                    }		
                }else{		
                    if(chklistsAfterUnchecking != ''){		
                        chklistsAfterUnchecking = chklistsAfterUnchecking + ';' + arr[i];		
                    }else{		
                        chklistsAfterUnchecking = arr[i];		
                    }		
                }		
            }		
            		
            if(isUnchecked){		
                component.set('v.unCheckChildAcc', true);		
                component.set('v.message', 'Unchecking this box will delete the Child Checklist and all associated data. please confirm deletion.');		
            }		
            component.set('v.existingChildAccChecklists', chklistsAfterUnchecking);		
        }		
    },	
	

    cancelModal: function(component, event, helper){		
        var childAccountId = component.get('v.childAccountId');		
        if(childAccountId.includes('None')){		
            var childAccsOldValue = component.get('v.childAccsOldValue');		
            childAccsOldValue.splice(childAccsOldValue.indexOf('None'), 1);		
            component.set('v.childAccountId', childAccsOldValue);		
        }else{		
            var existingChildAccChecklists = component.get('v.existingChildAccChecklists');		
            childAccountId = childAccountId + ';' + component.get('v.uncheckedChildAccId');		
            existingChildAccChecklists = existingChildAccChecklists + ';' + component.get('v.uncheckedChildAccId');		
            component.set('v.childAccountId', childAccountId);		
            component.set('v.childAccsOldValue', childAccountId);		
            component.set('v.existingChildAccChecklists', existingChildAccChecklists);		
        }		
        component.set('v.unCheckChildAcc', false);		
    },		
    		
    confirmModal: function(component, event, helper){		
        if(component.get('v.childAccountId').length == 0){		
            component.set('v.existingChildAccChecklists', '');		
        }		
        if(component.get('v.childAccountId').includes('None')){		
            component.set('v.childAccountId', 'None');		
            component.set('v.existingChildAccChecklists', '');		
            component.set('v.childAccsOldValue', component.get('v.childAccountId'));		
        }		
        component.set('v.unCheckChildAcc', false); 		
    },		
    		
    handleMedicalUnderwritingPathValChange: function(component, event, helper){		
        var val = component.get('v.medicalUnderwritingPathVal');		
        var medicalUwPath = component.get('v.medicalUwPath');		
        if(val == 'Yes'){		
            if(medicalUwPath == 'Gradient Pre-Qualifier'){		
                component.set('v.medicalUwPath', '');		
            }		
        }		
    },
    		
    	//JDA: Do we need this method?		
    handleIsMedicalUnderwritingPathValChange: function(component, event, helper){	
       /*  SFDC-22141
        var val = component.get('v.isMedicalRequestedVal');			
        if(val == 'Currently does not have Medical and not interested in Medical, do not quote'){		
            component.set('v.fullUnderwriting', true);		
            component.set('v.fullUnderwritingPathVal', 'Yes');	
            component.set('v.WhyareyouchoosingVal', 'Need support of NBSC');
        }	*/	
    },

    checkCreateUser: function(component, e, helper) {
    	
        var createCommunityUser = component.get("v.createCommUser");
        if(createCommunityUser){
            if(createCommunityUser == 'Yes'){
                component.set('v.welcomeEmailCheck','');
                helper.checkPayxEmail(component,e,helper)
                //.then(res => helper.checkOpportunity(component,e,helper)) APR0129807 moved to initialization check to only if checklist doesn't exist
                .catch(err => helper.handleError(err));
            }else{
                component.set('v.welcomeEmailCheck','No');
            }
        }
        else{
            component.set('v.disableContinue',false);
        }
    },
    
    createUser: function(component, e, helper) {
        // User info verification handled in updateView()
        // initiate user creation request
        // Throws error if creation fails
        // NOTES: Should i add a reroute to the verification screen again?
        // Should I add a limit for attemps per session?
        // Testing ERR NOTES: none as of now
        helper.loadSpinner(component);
        helper.createNewUser(component, e)
        .then(function(res){
            helper.loadSpinner(component);
            if(component.get("v.welcomeEmailCheck") == 'Yes'){
                helper.handleError({
                    t: 'User created',
                    m: 'User welcome email successfully scheduled for ' + $A.localizationService.formatDate(component.get("v.welcomeEmailDate"), "MMMM dd yyyy, hh:mm:ss a"),
                    ty: 'success',
                    broke: true});
            }else{
                helper.handleError({
                    t: 'User created',
                    m: 'Portal user created. Registration email has been sent',
                    ty: 'success',
                    broke: true});
            }
            
           // helper.closeAction();
           helper.closeModal(component, e, helper)
        }).catch(function(data) {
            helper.loadSpinner(component);
            helper.handleError(data)
        });
        console.log('user created');
    },
    callReactivateUser: function(component, e, helper) {
        helper.loadSpinner(component);
        helper.reactivateUser(component, e,helper)
        .then(function(res){
            helper.loadSpinner(component);
            helper.handleError({
                t: 'User created',
                m: 'Portal user reactivated. Welcome email has been sent',
                ty: 'success',
                broke: true});
            helper.closeAction();
        }).catch(function(data) {
            helper.loadSpinner(component);
            helper.handleError(data)
        });
        console.log('user reactivated');
	},
    updateView: function(cmp, e, helper) {
        // This checks for duplicate values before continuing to the account view screen
        // throws message to user if dups or blanks found 
        // then change the view to the questionnaire forms for teh rep to input values
        // Any errors are shown to the user by the handler: verification errs thrown by verifyFormDups() 
        //Do we need to do all the methods here? Usually, if a person checks no to creating a community user we only load in web component.
        //Possibly call "continue... 2" no matter what and only add in the reactivate user code if needed.
        //If reactivating a user, shouldn't the checklist already be created?
         
        console.log('updateView');
        var hasCommunityUser = cmp.get("v.communityUser"); //community user variable
        var createCommunityUser = cmp.get("v.createCommUser"); //create community user field
        var welcomeEmailCheck = cmp.get("v.welcomeEmailCheck");
        var welcomeEmailDate = cmp.get("v.welcomeEmailDate");
        var childAccountSelection = cmp.get("v.childAccountSelection");	
        var childAccountId = cmp.get("v.childAccountId");
        console.log($A.localizationService.formatDate(welcomeEmailDate, "MMMM dd yyyy, hh:mm:ss a"));
        var inactiveUser = cmp.get("v.hasInactiveUser");//has active user variable
        var reacNeeded = cmp.get("v.reactivationNeeded"); //reactivate community user field
        //var medicalUnderwritingPathVal = cmp.get('v.medicalUnderwritingPathVal');	
        var medicalRequestedVal = cmp.get('v.medicalRequestedVal');
        
        console.log('update view createCommunityUser'+createCommunityUser);
        if((!hasCommunityUser && !createCommunityUser) || (inactiveUser && !reacNeeded)){
            helper.handleError({t: 'Required Field Missing', m: 'Please fill out all required fields', ty: 'warning'});
            return;
        }
        /*if(!welcomeEmailCheck || (welcomeEmailCheck == 'Yes' && !welcomeEmailDate)){
            helper.handleError({t: 'Required Field Missing', m: 'Please fill out all required fields', ty: 'warning'});
            return;
        }*/
        if(createCommunityUser == 'Yes' && welcomeEmailCheck == 'Yes'){
            cmp.set('v.createUser', 'Confirm Invite');
        }
        if(childAccountSelection == undefined || (childAccountSelection == "No" && childAccountId.length == 0)){		
            helper.handleError({t: 'Required Field Missing', m: 'Please fill out all required fields', ty: 'warning'});		
            return;		
        }
        
        helper.updateSpinnerState(cmp, e, helper);
        if(createCommunityUser == 'Yes'){
            let uName = cmp.find('communityUsername');
            console.log('uName'+uName);
            if(uName && !uName.checkValidity()){
                console.log('Invalid username...');
                helper.updateSpinnerState(cmp, e, helper);
                helper.handleError({t: 'Invalid username format', m: 'Username must be in email format: example@example.com', ty: 'warning'});
                return;
            }
        }
        
        helper.helperFunctionAsPromise(cmp, e, helper, helper.validateAdditionalQuestionFields)
        .then($A.getCallback(function(validationResult){
            console.log('in validationResult');
            if(createCommunityUser == 'Yes'){
                console.log('in validationResult yes');
                return helper.helperFunctionAsPromise(cmp, e, helper, helper.validateUserCreationFields)
            }
            else return validationResult;
        }))
        .then($A.getCallback(function(res) { return  helper.helperFunctionAsPromise(cmp, e, helper, helper.updateContactAndAcctWQ) })) 
        .then($A.getCallback(function(res){ return  helper.helperFunctionAsPromise(cmp, e, helper, helper.createQuestionnaire) }))
        .then(function(res) {
            helper.helperFunctionAsPromise(cmp, e, helper, helper.updateView);
            // SPRINT 23 uat issue: loading spinner
            // helper.helperFunctionAsPromise(cmp, e, helper, helper.updateSpinnerState);
        })
        .catch(function(err) {
            console.log('ERROR:'+err);
            console.log(err)
            helper.helperFunctionAsPromise(cmp, e, helper, helper.updateSpinnerState);
            helper.handleError(err);
        });
    },
    closeModal: function(component, e, helper) {
        // simply forces the modal to close using the helper evnt
        // Testing ERR NOTES: none as of now
        
        helper.closeAction();
    },
    /*updateMedicalSelection: function(cmp, e, h) {
        // flips the flag attr on the modal to pass
        // flag attr passed into commforms cmp
        // NOTE: Need to add a check for this in the cmp incase user exists?
        // Check for existing questionnaire record? 
        // Testing ERR NOTES: none as of now
        
        let wantsMed = cmp.get('v.medicalRequestedVal');
        if(wantsMed && wantsMed == 'Yes'){
            cmp.set('v.medicalReq', true);
        }
        else if(wantsMed && wantsMed == 'No'){
            cmp.set('v.medicalReq', false);
            cmp.set('v.medicalUwPath','');
            cmp.set('v.medicalUnderwritingPathVal','');
            cmp.set('v.benEffectiveDate',null);
        }
        console.log(cmp.get('v.medicalReq'))
    },
    goToForms: function(cmp, e, helper) {
        helper.openForm(cmp, e);
    },
    handleBenefitDateUpdate: function(cmp, e, helper) {
        var field = e.getSource();
        field.setCustomValidity('') ;
        var chckvalididty = field.get("v.validity");
        console.log(chckvalididty.valid); // it gives false when 1st enter wrong format then i changed to correct format still shows
        if(!chckvalididty.valid){
            console.log("Setting custom validation message...");
            field.setCustomValidity('format must be mm/dd/yyyy');
        }else{
            let benefitDate = new Date(cmp.find('effectiveDate').get('v.value'));
            let todayDate = new Date();
            let monthStart = new Date(todayDate.getFullYear(),todayDate.getMonth(),1);
            
            if(monthStart>benefitDate) cmp.set('v.benefitDateError', true);
            else cmp.set('v.benefitDateError', false);
            field.setCustomValidity('') ;
        }
        field.reportValidity();
    },
    updateWCFastPassInput: function(cmp, e, helper) {
        if(cmp.get("v.WCUnderwritingVal") != 'Yes - WC to be reviewed') {
            cmp.set("v.WCFastPass", 'default');
            cmp.set("v.WCInTargetHazardGroup", 'default');
            cmp.set("v.WCPremiumUnderLimit", 'default');
            cmp.set("v.FastPass", false);
        }
        //console.log('cmp.get("v.WCFastPass") = ' + cmp.get("v.WCFastPass"));
        else if(cmp.get("v.WCFastPass") == 'Yes') {
            cmp.set("v.FastPass", true);
            if(cmp.get("v.WCInTargetHazardGroup") == 'No' || cmp.get("v.WCPremiumUnderLimit") == 'No') {
                cmp.set("v.WCFastPass", 'No');
                cmp.set("v.WCInTargetHazardGroup", 'default');
                cmp.set("v.WCPremiumUnderLimit", 'default');
                cmp.set("v.FastPass", false);
                
                let err = {
                    m: "The Prospect does not qualify for Worker's Comp FastPass.",
                    t: "Criteria Not Met.",
                    ty:  'warning',
                    broke: false
                };
                
                helper.handleError(err);
            }
        }
        else {
            cmp.set("v.FastPass", false);
        }
    },
                */
    navigateBack: function(component, e, helper) {
        //Clear the forms and navigate to first screen
        helper.clearForm(component, e, helper);
        helper.updateViewToStep1(component, e);
    },
    handleScroll: function(component, e, helper) {
        var elementList = document.getElementsByClassName("slds-modal__content");
        if (elementList.length) {
            let target = elementList[0];
            var rect = target.getBoundingClientRect();
            scrollTo({top: rect.top, behavior: "smooth"});
        }
    },
    openMultiIDParentTab: function(component, e, helper) {
        var workspaceAPI = component.find("navWorkspace");
        workspaceAPI.openTab({
            url:'/lightning/r/Account/'+ component.get("v.contactRec.Account.SalesParent__c") +'/view',
            focus:true
        }).then(function(response){
            workspaceAPI.getTabInfo({
                tabId:response
            }).then(function(tabInfo){
                console.log('Record ID for Prospect tab is: '+tabInfo.recordId);
            });
        }).catch(function(error){
            console.error('Error occured while navigation: '+error);
        });
    },
    closeAction: function(component, event, helper) {
        helper.closeAction(component, event, helper);
    },
    /*getToggleButtonValue:function(component,event,helper){
        var checkCmp = component.find("display_Benchmark_tab__c").get("v.checked");
        component.set("v.display_Benchmark_tab__c",checkCmp);
    },*/
	// Sprint 23 UAT issue 2: loading spinner
	finishLoadingCommunityForms: function(component, event, helper) {      
    	// when this method is called we need to ensure that the spinner is
    	// always closed. Set the waitingForResp flag to true so that the 
    	// helper.updateSpinnerState call always closes the spinner
    	//debugger;
        if (!component.get('v.waitingForResp')) component.set('v.waitingForResp', true)
        helper.updateSpinnerState(component, event, helper);                
    },
})