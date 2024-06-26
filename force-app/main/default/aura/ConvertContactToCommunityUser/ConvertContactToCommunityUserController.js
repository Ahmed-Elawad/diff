({
    initialize: function(component, e, helper) {
        // get the contact record for the user
        // then assing field values from the returned record
        // throws warning and closes if fails to get contact
        // then check to see if there's a community user already:
        // blocks all fields from being edited if so
        // catch: grabs any returned error and displays the message for the user
        // helper.handleErr determines if the modal is closed or not   
        // Testing ERR NOTES: none as of now
        
        
        if (component.get('v.recordId') !== null) {
            helper.updateSpinnerState(component, e, helper);
            helper.helperFunctionAsPromise(component, e, helper, helper.methodZero)
            .then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.getUser)}))
            .then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.getPermissions)}))
            .then( $A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.getContactInfo)}))
            .then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.checkForAssociatedCommunityUser)}))
            .then($A.getCallback(function() { return helper.helperFunctionAsPromise(component, e, helper, helper.assignCreationValues)}))
            .then($A.getCallback(function() {return helper.helperFunctionAsPromise(component, e, helper, helper.getOppty)}))
            .then(function(res) {
                helper.helperFunctionAsPromise(component, e, helper, helper.updateViewToStep1);
                helper.helperFunctionAsPromise(component, e, helper, helper.updateSpinnerState);
            })
            .catch(err => helper.handleError(err));
        } else {
            let err = {
                m: 'Error initializing the component. Record not available. Contact admin for suppport.',
                t: 'Failure Initializing',
                ty:  'warning',
                broke: true
            };
            helper.handleError(err);
        }
    },
    checkCreateUser: function(component, e, helper) {
    	
        var createCommunityUser = component.get("v.createCommUser");
        if(createCommunityUser && createCommunityUser == 'Yes'){
            helper.checkPayxEmail(component,e,helper)
            //.then(res => helper.checkOpportunity(component,e,helper)) APR0129807 moved to initialization check to only if checklist doesn't exist
            .catch(err => helper.handleError(err));
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
            helper.handleError({
                t: 'User created',
                m: 'Portal user created. Registration email has been sent',
                ty: 'success',
                broke: true});
            helper.closeAction();
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
        
        var inactiveUser = cmp.get("v.hasInactiveUser");//has active user variable
        var reacNeeded = cmp.get("v.reactivationNeeded"); //reactivate community user field
        
        console.log('update view createCommunityUser'+createCommunityUser);
        if((!hasCommunityUser && !createCommunityUser) || (inactiveUser && !reacNeeded)){
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
        helper.helperFunctionAsPromise(cmp, e, helper, helper.methodZero)
        .then($A.getCallback(function(methodZeroResult){ return helper.helperFunctionAsPromise(cmp, e, helper, helper.validateAdditionalQuestionFields) }))
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
            helper.helperFunctionAsPromise(cmp, e, helper, helper.updateSpinnerState);
        })
        .catch(function(err) {
            console.log('ERROR:');
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
    updateMedicalSelection: function(cmp, e, h) {
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
        }
        console.log(cmp.get('v.medicalReq'))
    },
    setExperience: function(cmp, e) {
        let val = cmp.find('portalExperience').get('v.value');
        console.log('portal experience: ',cmp.find('portalExperience').get('v.value'));
        cmp.set('v.experience', val);
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
    }
})