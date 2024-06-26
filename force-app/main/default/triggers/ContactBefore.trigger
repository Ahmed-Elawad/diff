/**
 * Handle all of the "before" Contact operations.
   Migrated logic from ContactFormatPaychexEmps trigger.
   Verify LeadSource is valid from RJDB
 *
 * History
 * -------
 * 02/21/2012 Dan Carmen      Created
 * 06/12/2012 Cindy Freeman   Added logic to verify LeadSource from RJDB is in picklist
   02/01/2013 Dan Carmen      set record type on records created by relational junction
   09/26/2013 Dan Carmen      Changes for the employee records coming in via the integration
   09/30/2013 Dan Carmen      Pull out the employee logic into another class
 * 08/24/2014 Cindy Freeman   Added stuff for Contact Flopper
   02/16/2015 Dan Carmen      Changes for the NSS Call Disposition Field
   03/25/2015 Dan Carmen      Set Latest Campaign Date
   06/30/2015 Cindy Freeman   look for matching active user rcd missing HR person Id and fill it in
   08/04/2015 Dan Carmen      Move Sales Contact checkbox logic from workflow to the trigger. Log time between web lead coming and and dialed.
   01/28/2016 Dan Carmen      Added checkType method 
   05/02/2016 Dan Carmen      Ability to not trigger on the dialed checkbox
   09/29/2016 Dan Carmen      Move ownership to the before trigger. Moved some functionality to the ContactTriggerBeforeMethods class.
   09/30/2016 Jacob Hinds     Changed isLeadLoader to use method instead of variable.
   01/20/2017 Dan Carmen      Add call to TriggerMethods
   02/02/2017 Dan Carmen      Change order of calls
   05/04/2017 Jermaine Stukes Added DNC update
   05/11/2017 Dan Carmen      Add additional call to TriggerMethods
   07/20/2017 Dan Carmen      Remove Profiled code
   01/31/2018 Dan Carmen      Merge in UserUpdateFromContact logic
   09/07/2018 Jacob Hinds     Merging revised dnc code
   12/06/2018 Dan Carmen      Replace qbdialer__LastCallTime__c with LatestCallTime__c
   09/19/2019 Cindy Freeman   changed to use StringHelper to add to ProcessNotes__c
   09/27/2019 Dan Carmen      Add additional tracking info
   01/14/2021 Carrie Marciano INC2576959 fix to query for account related to contact so that we can check account DNC and EEO and ensure that if they are True that all related Contacts are also true
   04/16/2021 Dan Carmen      Remove call to CampaignMethods, changed email opt out to only happen on insert
   12/16/2022 Dan Carmen      Log if the Sales Contact changes to the process notes

 */
trigger ContactBefore on Contact (before insert, before update) {
   UserHelper.setRunningUserAttributes();
   Boolean isRJDBuser = UserHelper.runningUserIsRelationalJunction;
   Boolean isLeadLoader = UserHelper.isLeadLoader(UserInfo.getName());
   Boolean isIsdcApi = UserHelper.runningUserIsIsdcApi;
   
   if (isLeadLoader) {
      // mark records so we know their incoming attributes
      for (Contact ctct : Trigger.new) {
         String msg = 'ContactBefore OwnedBy='+ctct.OwnedBy__c+' webLead='+ctct.Weblead__c+' TrigExecuting='+ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING;
         StringHelper.addToProcessNotes(ctct,msg);
      }
   } // if (isLeadLoader

    System.debug('ContactBefore ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING='+ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING);
    if (ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING) {
        return;
    }
    // to prevent recursion?
    ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
    
    // Ids of records that have been called so we can flag other records with same phone number 
    Set<Id> idsDialedSet = new Set<Id>();
    
    // if the Dialed__c field is set, check if anything needs to be done.
    // this should only be done on update - should already exist
    Contact[] checkDialed = new Contact[]{};
        
    // if the call disposition is changed to a not blank value
    // again, should only be done on an update
    Contact[] checkCallDisposition = new Contact[]{};
    // if the last call date changes
    Contact[] lastCallDateChanged = new Contact[]{};
    // the latest campaign changed
    Contact[] latestCampaignChanged = new Contact[]{};
    Set<Id> latestCampaignIdSet = new Set<Id>();
    // collect the ids so we don't have to loop through them again inside the trigger to collect them
    Set<Id> contactFieldTriggerAcctIdSet = new Set<Id>();
    Set<Id> contactFieldTriggerUserIdSet = new Set<Id>();
    // check the owned by field on the contacts
    Contact[] checkOwnedByContacts = new Contact[]{};
        
    TriggerMethods.checkBeforeLoop('ContactBefore', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
    
    if (Trigger.isUpdate) {
        CheckDataGovernance.checkData(Trigger.new,Trigger.oldMap);//As per the Data Goverance doc

    }
    
    Set<Id> newCAccountIds = new Set<Id>();
    for (Contact newC : Trigger.New) {       
        if (newC.AccountId != null) {
            newCAccountIds.add(newC.AccountId);
        }
    }
    
    // only do this on insert of a contact
    Map<Id, Account> newCAccountsMap = (!DNCHelper.DNC_CHECKED ? new Map<Id, Account>([select Id, Do_Not_Call__c, Email_Opt_Out__c from Account where Id in :newCAccountIds]) : new Map<Id,Account>());
    // so we only retrieve once during a transaction
    DNCHelper.DNC_CHECKED = true;
    
    for (Contact newC : Trigger.New) {       
        Boolean okayToContinue = (newC.Id == null || !AccountMethods.callDispositionHandledSet.contains(newC.Id));
        Contact oldC = (Trigger.isUpdate ? Trigger.oldMap.get(newC.id) : null);
              
        TriggerMethods.checkInLoop('ContactBefore', newC, oldC, Trigger.IsBefore, Trigger.IsAfter);

        system.debug('Contact Before okayToContinue: '+okayToContinue);
        if (okayToContinue && newC.AccountId != null && String.IsBlank(newC.HR_Person_Id__c)) {
                     
            //SRRTransitionHelper.checkBeforeActions(newC,oldC);      
            ContactTriggerBeforeMethods.checkBeforeActions(newC,oldC);
            ReferralScoreMethods.checkTriggerBefore(newC, oldC);
            Account acct = (newC.AccountId != null && newCAccountsMap.containsKey(newC.AccountId) ? newCAccountsMap.get(newC.AccountId) : null);
            system.debug('Contact Before newCAccountsMap.get(newC.AccountId).Do_Not_Call__c: '+(acct != null ? acct.Do_Not_Call__c : false));
            if(acct != null && acct.Do_Not_Call__c){
                newC.DoNotCall = true;
            }
            system.debug('Contact Before newC.DoNotCall: '+newC.DoNotCall);
            if(acct != null && acct.Email_Opt_Out__c){
                newC.HasOptedOutOfEmail = true;
            }
            
            ContactCheckType.checkType(newC,oldC);
            
            if (Trigger.isUpdate && (newC.Dialed__c || (!isIsdcApi && Label.PO_DateCheck == 'Y' && newC.LatestCallTime__c != null && newC.LatestCallTime__c != oldC.LatestCallTime__c))){
                // 8/5/2015 log that the record was dialed if necessary
                NSSMethods.checkWebLeadDialed(newC,oldC);
                
                Boolean dialedTimeOkay = Utilities.checkDialedTimeOkay(newC.DialedLastUsed__c);
                // if it was dialed recently do not let the checkbox be set again
                if (!dialedTimeOkay && newC.Dialed__c) {
                    newC.Dialed__c = false;
                }
                
                // clear out call disposition if within the time period and is the same as the previous value
                if (!dialedTimeOkay && String.isNotBlank(newC.NSSCallDisposition__c) && newC.NSSCallDisposition__c == newC.LastNSSCallDisposition__c) {
                    newC.NSSCallDisposition__c = null;
                }
            } // if (newL.Dialed__c || String.isNotBlank(newL.NSSCallDisposition__c
            
            // check if the last call date changed - we want to update the account if it does
            if (newC.LatestCallTime__c != null && (Trigger.isInsert || (Trigger.isUpdate && newC.LatestCallTime__c != oldC.LatestCallTime__c))) {
                lastCallDateChanged.add(newC);
                contactFieldTriggerAcctIdSet.add(newC.AccountId);
            }
            
            if (newC.LatestCampaign__c != null && (Trigger.isInsert || (Trigger.isUpdate && newC.LatestCampaign__c != oldC.LatestCampaign__c))) {
                latestCampaignChanged.add(newC);
                latestCampaignIdSet.add(newC.LatestCampaign__c);
                contactFieldTriggerAcctIdSet.add(newC.AccountId);
                newC.LatestCampaignDate__c = Datetime.now();
            }
            
            
            ContactMethods.contactBeforeChecks(newC,oldC);
            ZipCheckOwner.doWeCheckCtctOwner(newC,oldC);
            
            if (String.isNotBlank(newC.OwnedBy__c)) {
                // if not the lead loader just clear out the field?
                if (!isLeadLoader) {
                    newC.OwnedBy__c = null;
                } else {
                    // 8/5/2015 put the start date on incoming web leads
                    NSSMethods.checkWebLeadStart(newC,oldC);
                    if (Trigger.isUpdate) {
                        // process the update from the before trigger - have to do the insert from the after trigger because the id won't exist yet.
                        checkOwnedByContacts.add(newC);
                    }
                }
            } // if (String.isNotBlank
            
            AccountMethods.checkForSignificanceRecalc(newC,oldC);
            if (Trigger.isUpdate){
                // see if any of the pertinent fields changed on the contact.
                ContactMethods.checkForContactChange(newC,oldC);
                // if Dialed__c switches to true
                if (newC.Dialed__c && newC.AccountId != null){
                    System.debug('ContactBefore Dialed__c is set for '+newC.Id);
                    checkDialed.add(newC);
                    // reset the flag
                    //newC.Dialed__c = false;
                    //newC.DialedLastUsed__c = DateTime.now();
                    //newc.NSSOwnership__c = null;
                    
                    // save Id to look for and flag other records with same phone number
                    idsDialedSet.add(newC.Id); 
                    
                } // if Dialed && newA
                
                // if the call disposition changes
                if (String.isNotBlank(newC.NSSCallDisposition__c) && newC.NSSCallDisposition__c != oldC.NSSCallDisposition__c){  
                    checkCallDisposition.add(newC);
                    contactFieldTriggerAcctIdSet.add(newC.AccountId);
                    if (String.IsNotBlank(newC.DialedUserId__c)) {
                        contactFieldTriggerUserIdSet.add((Id)newC.DialedUserId__c);
                    }
                } // if (String.isNotBlank
                if(newC.Phone==null && newC.MobilePhone==null && newC.OtherPhone==null && (acct != null && acct.Do_Not_Call__c==false) && (newC.DoNotCall || newC.Consent_to_Text__c)){
                  newC.DoNotCall = false;
                  newC.Consent_to_Text__c = false;
                  //newC.ProcessNotes__c = newC.ProcessNotes__c+'\n'+system.now()+' Clearing Do Not Call/Text Opt In because there were no phone numbers on the record';
                  String newNotes = 'Clearing Do Not Call/Text Opt In, no phone numbers';
                  StringHelper.addToProcessNotes(newC, newNotes);
                  system.debug('ContactBefore newC.Phone==null then newC.DoNotCall set to false: '+newC.DoNotCall);
                }
                if(newC.Email==null && newC.HasOptedOutOfEmail && (acct != null && acct.Email_Opt_Out__c==false)){
                  newC.HasOptedOutOfEmail = false;
                  //newC.ProcessNotes__c = newC.ProcessNotes__c+'\n'+system.now()+' Clearing Email Opt Out because there was no email address on the record';
                  String newNotes = 'Clearing Email Opt Out, no email address';
                  StringHelper.addToProcessNotes(newC, newNotes);
                }
                
            } // if (Trigger.isUpdate
            
        } // if (okayToContinue
        if (oldC != null && newC.Sales_Contact__c != oldC.Sales_Contact__c) {
            StringHelper.addToProcessNotes(newC, 'Sales_Contact__c changed to '+newC.Sales_Contact__c+' in ContactBefore by '+UserInfo.getUserId());
        }
    } // for (Contact
    
    TriggerMethods.checkOutsideLoop('ContactBefore', Trigger.isBefore, Trigger.isAfter);
    
    // 2/1/18 DC - removed this logic and put inside the ContactFormatPaychexEmps class
    //ContactFormatPaychexEmps.checkUserLookups();
    
    //SRRTransitionHelper.processBeforeActions();
    
    ZipCheckOwner.checkProcessCtctOwnersBefore();
    
    ReferralScoreMethods.processCtctTriggerBefore();
    
    if (!LeadMethods.DISABLE_DIAL_CHECKBOX && !checkDialed.isEmpty()) 
    {
        ContactMethods.checkDialed(checkDialed);
    } // if (!checkDialed
    
    if (!contactFieldTriggerAcctIdSet.isEmpty()) {
        ContactMethods.handleContactFields(checkCallDisposition,lastCallDateChanged, latestCampaignChanged, latestCampaignIdSet
                                           ,contactFieldTriggerAcctIdSet,contactFieldTriggerUserIdSet );
    } // if (!checkCallDisposition
    
    if (!checkOwnedByContacts.isEmpty()) {
        ContactMethods.checkOwnedBy(checkOwnedByContacts);
    }
    
    if (!idsDialedSet.isEmpty())
    {  User runningUser = UserHelper.getRunningUser();    
     NSSMethods.checkDuplicatePhone(idsDialedSet, runningUser.id);
    }
    
    // reset flags on dialed contacts
    for (Contact ctct : checkDialed) {
        ctct.Dialed__c = false;
        ctct.DialedUserId__c = null;
        ctct.DialedLastUsed__c = DateTime.now();
        ctct.NSSOwnership__c = null;
    }
    
    if (Trigger.isUpdate) {
        ContactMethods.checkForContactChangeSave();
    }
    
    /* for SSO
if (!ctctEmailMap.isEmpty())
{  ContactFormatPaychexEmps.pushCtctHRpersonID(ctctEmailMap);  }
*/
    ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = false;
    
} // trigger ContactBefore