({
    setUpComponent : function(component, helper) {
        console.log('setUpComponent');

        var action = component.get('c.getOppPathInfo'); 
        action.setParams(
            {
                "recordId":component.get("v.recordId")
            })
        action.setCallback(this, function(response) {           
            var name = response.getState();
            if (name === "SUCCESS") {
                var wrap = response.getReturnValue();
                var oppStageOkay = (wrap.oppStageIsWon || wrap.oppStageIsSold);
                //var ezRequirements =  wrap.signedQuoteRequired ? (wrap.) : (wrap.oppStageIsWon || wrap.oppStageIsSold);
                var ezRequirements = oppStageOkay && (!wrap.signedQuoteRequired || wrap.docusignComplete);
                component.set("v.csoTracking", wrap.tracker);
                component.set("v.csoOpportunity", wrap.opp);
                component.set("v.opptyId", wrap.tracker.Opportunity__c);
                component.set("v.opptyOwnerId", wrap.tracker.Opportunity__r.OwnerId);
                component.set("v.acctId", wrap.tracker.AccountId__c);
                component.set("v.currentUserId", wrap.currentUserId);
                component.set("v.ContactList", wrap.ctcts);
                component.set("v.hideAttachmentFields", wrap.signedQuoteRequired);
                component.set("v.showEZButton", ezRequirements);
                component.set("v.oppStageIsWon", wrap.oppStageIsWon);
                component.set("v.docusignComplete", wrap.docusignComplete);
                component.set("v.hasPrimaryQuote", wrap.hasPrimaryQuote);
                component.set("v.onboardingComplete", (wrap.tracker.SubmitCompleted__c != null));
                component.set("v.showException", (wrap.tracker.ExceptionAllowed__c 
                                                      && (wrap.currentUserId == wrap.tracker.Opportunity__r.OwnerId || wrap.currentUserId == wrap.tracker.Opportunity__r.Owner.ManagerId)));
                component.set("v.isPrimaryOpp", wrap.isPrimaryOpp);
                component.set("v.packageName",wrap.packageName);
                component.set("v.packageProducts",wrap.otherProducts);
                component.set("v.errorMsg","");

                //component.set("v.notPrimaryMsg", "This is not the primary Opportunity. Easy Setup is being worked on "+wrap.tracker.Opportunity__r.Name);
                component.set("v.notPrimaryMsg", "This is not the primary opportunity, "+wrap.tracker.Opportunity__r.Name+" appears to be primary. Review all other opportunities to ensure this is the most current and close any others out. If unable to correct, please submit a Sales Help Request to the Easy Setup Sales Help team.")
                if (wrap.ezComplete == false) {
                   if (wrap.docusignComplete == true && wrap.oppStageIsWon == false) {
                      component.set("v.nextStepMsg1","Next Step: Ensure your opportunity status = Verbal Commit to proceed with Easy Setup");
                   } else if (wrap.hasPrimaryQuote == true && wrap.docusignComplete == false && wrap.oppStageIsWon == true) {
                      component.set("v.nextStepMsg1","Next Step: Once the prospect has agreed to move forward, please send the quote for signature to proceed with client registration");
                   } else if (wrap.hasPrimaryQuote == true && wrap.docusignComplete == false && wrap.oppStageIsWon == false) {
                      component.set("v.nextStepMsg1","Next Step: Once the prospect has agreed to move forward, please send the quote for signature and set your opportunity status = Verbal Commit to proceed with Easy Setup");
                   }
                }
                var hasCsoException = ((!wrap.tracker.Account_Eligible__c && (wrap.tracker.AccountKnockout__c || wrap.tracker.InitialValidationDetail__c != null || wrap.tracker.CsoException__c))
                                       || (wrap.tracker.UserValidationDetail__c != null)
                                       || (!wrap.tracker.Opportunity_Eligible__c && (wrap.tracker.OpportunityEligibilityDetail__c != null || wrap.tracker.ProductKnockout__c)));
                component.set("v.hasCsoException", hasCsoException);
                if (wrap.tracker.ExceptionNeedApproval__c) {
                   if (wrap.tracker.ExceptionStatus__c=='Pending') {
                       component.set("v.exceptionMessage","An exception was submitted and is currently under leadership review.");
                       // don't show the button while the exception is pending.
                       component.set("v.showException",false);
                   } else if (wrap.tracker.ExceptionStatus__c != null) {
                       component.set("v.exceptionMessage","Your exception was "+wrap.tracker.ExceptionStatus__c+" with the reason: "+wrap.tracker.ExceptionAcceptRejectDescipt__c);
                   }
                } // if (wrap.tracker.ExceptionNeedApproval__c

                var ownerOkay = (wrap.currentUserId == wrap.tracker.Opportunity__r.OwnerId || wrap.currentUserId == wrap.tracker.Opportunity__r.Owner.ManagerId);
                var ctctOkay = (wrap.tracker.RegistrationStarted__c && wrap.tracker.FirstStepsCompleted__c == null && wrap.tracker.Contact__c != null && wrap.tracker.Contact__r.FlexUEID__c != null);
                var canResend = ((wrap.tracker.RegistrationStarted__c && wrap.tracker.FirstStepsCompleted__c == null && wrap.tracker.Contact__c != null && wrap.tracker.Contact__r.FlexUEID__c != null) 
                				&& (wrap.currentUserId == wrap.tracker.Opportunity__r.OwnerId || wrap.currentUserId == wrap.tracker.Opportunity__r.Owner.ManagerId));
                component.set("v.showResendUser", canResend);
                component.set("v.primaryQuoteName",wrap.primaryQuoteName);
                component.set("v.showCSO", (wrap.tracker.IsOppCso__c || !wrap.tracker.IsOppEnterprise__c));
                
                // if registration error
                // else
                if (wrap.tracker.IsOppEnterprise__c == true && wrap.tracker.HasSubscriptionQuote__c) {
                   // is there any subscription quote on this Opportunity?
                   component.set("v.showEnterprise", wrap.tracker.HasSubscriptionQuote__c);
                    
                   var quoteOptions = [];
                   quoteOptions.push({ value: 'Select A Quote', label: 'Select A Quote'});
                   for (var cnt=0; cnt<wrap.otherQuotes.length; cnt++) {
                      quoteOptions.push({ value: wrap.otherQuotes[cnt].quoteId, label: wrap.otherQuotes[cnt].quoteName });			
                   }
                   // only give the quote option if they haven't gotten to the won stage
                   component.set("v.hasOtherQuotes",(!wrap.oppStageIsWon && quoteOptions.length>1));
                   component.set("v.quoteOptions",quoteOptions);

                   var cpqSubmitted = (wrap.subscriptionCreated || wrap.tracker.CPQSubStatusCode__c == '200');
                   //var cpqFailed = (!wrap.tracker.CPQProcessing__c && wrap.tracker.CPQSubStatusCode__c != null && wrap.tracker.CPQSubStatusCode__c != '200');
                   if (!cpqSubmitted && wrap.tracker.UserErrorMessage__c != null) {
                       component.set("v.errorMsg",wrap.tracker.UserErrorMessage__c);
                   }
                   /*
                   if (wrap.tracker.RegistrationStatusCode__c != null && wrap.tracker.RegistrationStatusCode__c != '200') {
                       component.set("v.errorMsg","Registration Error: "+wrap.tracker.RegistrationDetail__c);
                   } else if (wrap.tracker.OSSKeysStatusCode__c != null && wrap.tracker.OSSKeysStatusCode__c != '200') {
                       component.set("v.errorMsg","OSS Keys Error: "+wrap.tracker.OSSKeysDetail__c);
                   } else if (!wrap.tracker.CPQProcessing__c && wrap.tracker.CPQKeysStatusCode__c != null && wrap.tracker.CPQKeysStatusCode__c != '200') {
                       component.set("v.errorMsg","CPQ Subscription: "+wrap.tracker.CPQKeysDetail__c);
                   } else if (!wrap.tracker.CPQProcessing__c && wrap.tracker.CPQSubStatusCode__c != null && wrap.tracker.CPQSubStatusCode__c != '200') {
                       component.set("v.errorMsg","CPQ Subscription: "+wrap.tracker.CPQSubDetail__c);
                   }
                   */
                   // if this is not in the won stage
                   var notWon = (!wrap.oppStageIsWon && !wrap.oppStageIsSold && !wrap.oppStageIsSoldSubmitted);
                   component.set("v.modifyQuote", (!cpqSubmitted));
                   // is the primary quote subscription?
                   component.set("v.eligibleForNewBill", wrap.oppIsNewBill);
                   var childErrors = (wrap.tracker.ChildErrors__c != null);
                   var nextStep = null;
                   var registrationStarted = wrap.tracker.RegistrationStarted__c;
                   if (registrationStarted && !childErrors) {
                      component.set("v.entHeaderSuccess","Client Record Created Successfully");
                   } else if (registrationStarted && childErrors) {
                      component.set("v.entHeaderSuccess","Error Registering Child Ids");
                      component.set("v.errorMsg",wrap.tracker.ChildErrors__c);
                      registrationStarted = false;
                   }
                   if (wrap.alwaysShowNewClientBtn) {
                      component.set("v.showNewClientButton",true);
                   }
                   component.set("v.showQuotes",true);
                   if (!wrap.quoteIsNewBill && !wrap.oppStageIsWon && !registrationStarted && !cpqSubmitted) {
                      nextStep = 'Either link up a new quote or this will be billed in legacy billing.';
                   } else if (wrap.quoteIsNewBill && !wrap.oppStageIsWon && !registrationStarted && !cpqSubmitted) {
                      component.set("v.entHeaderSuccess","Eligible for New Client Setup Process ");
                      nextStep = 'When appropriate, move opportunity to Verbal Commit status to proceed';
                   } else if (wrap.quoteIsNewBill && wrap.tracker.RegistrationProcessing__c) {
                      nextStep = 'Registration is processing...';
                   } else if (wrap.quoteIsNewBill && wrap.tracker.CPQProcessing__c) {
                      nextStep = 'Sending Subscription to billing...';
                   } else if (wrap.quoteIsNewBill && wrap.oppStageIsSoldSubmitted && registrationStarted && !cpqSubmitted) {
                      nextStep = 'Problem sending to billing! '+wrap.tracker.CPQSubDetail__c;
                   //} else if (wrap.quoteIsNewBill && wrap.oppStageIsSoldSubmitted && registrationStarted && cpqSubmitted) {
                   } else if (wrap.quoteIsNewBill && registrationStarted && cpqSubmitted) {
                      component.set("v.entHeaderSuccess","Quote Information Sent to Billing Successfully ");
                   } else if (wrap.quoteIsNewBill && wrap.oppStageIsSold && registrationStarted && !cpqSubmitted) {
                      nextStep = 'Complete PACO submission. When opportunity moves to Sold - Submitted, quote information will be sent to billing';
                      component.set("v.modifyQuote",true);
                   } else if (wrap.quoteIsNewBill && wrap.oppStageIsWon && !registrationStarted && !cpqSubmitted) {
                      nextStep = 'Set up the new client using the Setup New Client button.  This will create the client record to be used by all of Paychex';
                      component.set("v.entHeaderSuccess","Eligible for New Client Setup Process ");
                      component.set("v.showNewClientButton",true);
                      // we don't want to show those options at this stage
                      component.set("v.hasOtherQuotes",false);
                      component.set("v.showVerifyProdMsg",true);
                   } else if (wrap.quoteIsNewBill && wrap.oppStageIsWon && registrationStarted && !cpqSubmitted) {
                      component.set("v.showQuotes",true);
                      component.set("v.modifyQuote",true);
                      nextStep = 'Move the Opportunity to Sold to continue setup of the client';

                   } // if 
                        
                   component.set("v.ossNextStep",nextStep);
                }
                
                //helper.checkPackageName(component,wrap.packageName);

            }
        });
        $A.enqueueAction(action);
    },
    checkForErrors : function(component, helper, wrap) {
        
    },
    removeExceptionHelper : function(component, helper) {
        var action = component.get('c.removeException'); 
        var csoRec = component.get("v.csoTracking");
        action.setParams(
            {
                "cso":csoRec
            })
        action.setCallback(this, function(response){           
            var name = response.getState();
            if (name === "SUCCESS") {
                var showToast = $A.get("e.force:showToast"); 
                showToast.setParams({ 
                    'title' : 'Confirmation', 
                    'type' : 'success',
                    'message' : 'The CSO exception has been cleared.'
                }); 
                showToast.fire();
                window.location.reload();
            }
        });
        $A.enqueueAction(action);
    },
    handleResendUserReg: function(component, event, helper) {
        var csoRec = component.get("v.csoTracking");
        var oppId = csoRec.Opportunity__c;
        var ctctId = csoRec.Contact__c;
        var vfPage = '/apex/FlexNewClientOnboarding?Id='+ctctId+'&oppId='+oppId;         
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({"url": vfPage});
        urlEvent.fire();
        $A.get('e.force:refreshView').fire();  
    },
   /*
    checkPackageName: function(component, packageName) {
       if (packageName == "Express Payroll Processing" || packageName == "Paychex Flex Select") {
          component.set("v.productBundle",packageName);
          component.set("v.productBundleShow",true);
       } else {
          component.set("v.productBundleShow",false);
       }

    }, */
    changePrimaryQuote: function(component, event, helper) {
       var csoRec = component.get("v.csoTracking");
       var quoteId = component.get("v.selectedQuote");
       if (quoteId == 'Select A Quote') {
                var showToast = $A.get("e.force:showToast"); 
                showToast.setParams({ 
                    'title' : 'Select a Quote', 
                    'type' : 'error',
                    'message' : 'Please select a Quote to change!'
                }); 
                showToast.fire();
          return;
       } 
       var action = component.get('c.setPrimaryQuote'); 
       var tracker = component.get("v.csoTracking");
       component.set('v.showSpinner', true);
          
       action.setParams({
                "trackerId":tracker.Id,
                "oppId":tracker.Opportunity__c,
                "quoteId":quoteId
            })
        action.setCallback(this, function(response){           
            component.set('v.showSpinner', false);
            var name = response.getState();
            if (name === "SUCCESS") {
               $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
       
    },
})