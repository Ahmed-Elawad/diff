({
    // gather the running user
    // set the user on the component
    getUser: function(cmp, e) {
        console.log('getUser');
        return new Promise(function(resolve, reject) {
            let getUser = cmp.get('c.getRunningUser');
            
            getUser.setCallback(this, function(res) {
                if (res.getState() != 'SUCCESS' || !res.getReturnValue()) {
                    console.log('err getUser');
                    console.log(res.getError());
                    return reject({
                        t: 'Error',
                        m: 'We’re sorry, your request can’t be completed right now. Please try again. For support, visit the Need Help section on our homepage, so we can promptly address the issue.',
                        ty: 'Error',
                        b: true,
                        err: res.getError()
                    });
                }
                console.log('ret getUser');
                cmp.set('v.userProfile', res.getReturnValue().Profile.Name);
                cmp.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, visit the Need Help section on our homepage, so we can promptly address the issue.');
                resolve(res.getReturnValue());
            });
            
            $A.enqueueAction(getUser);
        });
    },
    // gather the accounts
    // set the parent as the parent account
    // set the children ass the accounts
    getAccounts: function(cmp, e, user) {
        console.log('getAccounts');
        return new Promise(function(resolve, reject) {
            let getAccs = cmp.get('c.getAccountInformation');
            
            getAccs.setParams({
                'startingId': cmp.get("v.recordId"),
                formName: 'peoOnboardingSummaryAccSelect.cmp'
            });
            
            getAccs.setCallback(this, function(res) {
                if (res.getState() !== 'SUCCESS' || !res.getReturnValue()) {
                    // handle an account error
                    return reject({
                        t: 'Error',
                        m: cmp.get('v.errMsg'),
                        ty: 'Error',
                        b: true,
                       err: res.getError()
                    });
                }
                
                let accountList = res.getReturnValue();
                let parentAccount = accountList[0];
                cmp.set('v.allAccounts', accountList);
                console.log(' ret getAccounts');
                resolve(parentAccount);
            });
            
            $A.enqueueAction(getAccs);
        })
    },
    
    checkCovid: function(cmp, e, parentAccount) { 
        console.log('checkCovid');
        return new Promise(function(resolve, reject) {
            if(cmp.get("v.covidQuestionnaireNeeded") == null || cmp.get("v.covidQuestionnaireNeeded") == '' || cmp.get("v.covidQuestionnaireNeeded") == 'undefined') {
                var covidQuestionnaireNeeded = cmp.get("c.needCovidQuestionnaire");
                covidQuestionnaireNeeded.setParams({
                    'parentAccount': parentAccount
                });
                
                covidQuestionnaireNeeded.setCallback(this, function(data) {
                    if (data.getState() !== 'SUCCESS') {
                        // handle an account error
                        console.log('err checkCovid');
                        console.log(res.getError());
                        return reject({
                            t: 'Error',
                            m: cmp.get('v.errMsg'),
                            ty: 'Error',
                            b: true,
                            err: data.getError()
                        });
                    }
                    
                    var covidQuestionnaire = data.getReturnValue();
                    cmp.set("v.covidQuestionnaireNeeded", covidQuestionnaire);
                    console.log('ret checkCovid');
                    resolve(parentAccount.Id);
                });
                
                $A.enqueueAction(covidQuestionnaireNeeded);
            }
            else {
                resolve(parentAccount.Id);
            }
        })
    },
    
    // gather the checklist for the parent account
    // on error lock screen or show meesage
    // set the checklist on the cmp
    getChecklist: function(cmp, e, accId) {
        console.log('getChecklist');
        return new Promise(function(resolve, reject) {   
           // debugger;
            let getChecklist = cmp.get('c.getPEOOnboardingChecklist');
            getChecklist.setParams({accountId: accId,
                                    formName: 'peoOnboardingSummaryAccSelect.cmp'
                                   });
            
            getChecklist.setCallback(this, function(res) {
                if (res.getState() !== 'SUCCESS' || !res.getReturnValue()) {
                    console.log('err getChecklist');
                    console.log(res.getError())
                    // handle an account error
                    return reject({
                        t: 'Questionnaire Error',
                        m: cmp.get('v.errMsg'),
                        ty: 'Error',
                        b: true
                    });
                }
                cmp.set('v.peoFullChecklist', res.getReturnValue());
                cmp.set('v.portalExperience', cmp.get('v.peoFullChecklist.Experience__c'));
                cmp.set('v.WCFastPassChosen', cmp.get('v.peoFullChecklist.Workers_Comp_FastPass__c'));
                console.log('ret getChecklist');
                resolve(res.getReturnValue());
            })
            
            $A.enqueueAction(getChecklist);
        });
    },
    // parse the data and show a message 
    // update the cmp as needed for fail cases or refreshing
    handleErr: function(cmp, e, data) {
        if ( !cmp.set('v.loaded')) {
            this.switchLoadState(cmp, e);
        }
        var toastEvent = $A.get("e.force:showToast");
    	toastEvent.setParams({
        	title: data.t,
            message: data.m,
			type: data.ty
    	});
    	toastEvent.fire();
        if (data.b) cmp.set('v.error', true);
    },
    // updates the spinner and handles the timmer for spinning
    switchLoadState: function(cmp, e) {
        //debugger;
        cmp.set('v.loaded', !cmp.get('v.loaded'));
        // set the spinner view to the oposite of what it is now
        // Continously update the spinner for 5 seconds
        let updateLoading = function(cmp, stillLoading) {
            if (cmp.get('v.progressRate') < 100 && stillLoading) {
                let newval = cmp.get('v.progressRate');
                newval+=10;
                cmp.set('v.progressRate', newval);
                window.setTimeout(
                    $A.getCallback(updateLoading.bind(this, cmp, cmp.get('v.waitingForResp'))),
				1000);
            } else if (stillLoading) {
                cmp.set('v.progressRate', 0);
                window.setTimeout(
                    $A.getCallback(updateLoading.bind(this, cmp, cmp.get('v.waitingForResp'))),
				1000);
            } else {
                clearTimeout(updateLoading);
            }
        }
        
        let showSpinner = cmp.get("v.waitingForResp");
        
        cmp.set("v.waitingForResp", !showSpinner);
        
        if (!showSpinner) {
            updateLoading(cmp, true);
        } else {
            cmp.set('v.progressRate', 0);
        }
        return;
    },
    getMedical: function(cmp, e, peoChecklist) {
        console.log('getMedical');
        // only get the checklist if needed
        return new Promise(function(resolve, reject){
            let peoChecklist = cmp.get('v.peoFullChecklist');
            if (peoChecklist.Medical_Benefits_Underwriting_Requested__c != 'Yes') {
                resolve(true);
            } else {
                let getMedical = cmp.get('c.getMedicalQuestionnaireForm');
                getMedical.setParams({
                    peoOnboardingChecklistId: peoChecklist.Id,
                    formName: 'PeoONboardingSummaryAccSelect.cmp'
                });
                getMedical.setCallback(this, function(res) {
                    if (res.getState() !== 'SUCCESS' || !res.getReturnValue()) {
                        console.log('err getMedical');
                        console.log(res.getError());
                        // handle an account error
                        return reject({
                            t: 'Questionnaire Error',
                            m: cmp.get('v.errMsg'),
                            ty: 'Error',
                            b: true
                        });
                    }
                    cmp.set('v.medicalChecklist', res.getReturnValue());
                    console.log('ret getMedical');
                    resolve(true);
                })
                
                $A.enqueueAction(getMedical);
            }
        })
    }
})