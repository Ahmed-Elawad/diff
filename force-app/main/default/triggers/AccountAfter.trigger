/* 
   Check the ShippingPostalCode field. If it's populated
   and changed, set the owner. If the shipping is null and the billing is not null, check that.
   Also call the trigger if the hold out flag was previously set and is not set anymore. 
   Check to see if the zip code changed on the record.
   If it did change, and the hold out flag is not set,
   check to see if there is a new owner. 
   
  History
  -------
  03/30/2009 Dan Carmen   Created
  09/21/2009 Dan Carmen   Added a change to the hold out as a condition for the trigger.
  12/02/2009 Dan Carmen   Changed to check profile name to use the insert part of the trigger.
  07/12/2010 Dan Carmen   If the record type changes, re-evaluate owner.
  02/07/2011 Dan Carmen   Clean up class and trigger.
  01/17/2012 Dan Carmen   Moved code from AccountCheckOwner. Added in check for start date for Sequencing.
  01/19/2012 Dan Carmen   Added HR Manager to Account Team
  08/20/2012 Carrie Marciano    added check for Do Not Call and Email Opt-Out
  12/06/2012 Cindy Freeman      added Use Zip Assignment Rules to force ZipCheckOwner to run
  04/21/2014 Cindy Freeman      Added check for DataFlux delta service    
  09/10/2014 Dan Carmen   Always trigger ownership for SFDC Data
  03/03/2015 Dan Carmen   Fix for using the Use_Zip_Assignment_Rules__c field
  03/11/2015 Justin Henderson Added back in FirstRunDate Entry point for field update
  04/18/2016 Jacob Hinds  Calling ReferenceHRGMethods to update Reference HRG records when HR Generalist on account changes.
  05/19/2016 Jacob Hinds  Call AccountChatterUpdate to post a chatter update if certain fields change.
  11/08/2016 Lynn Michels Add criteria to update Reference MPSC based on updates on the Account
  12/04/2016 Cindy Freeman  added checks for new Account Junction logic linking parent and child accounts
  01/03/2016 Josh Cartwright new code to send insert vs update action to datafluxDelta Service 
  01/20/2017 Dan Carmen   Add call to TriggerMethods
  01/25/2017 Josh Cartwright changes for Dataflux 
  03/09/2017 Jacob Hinds    Removing AccountChatterUpdate
  03/22/2017 Cindy Freeman  moved account Junction code to Junction trigger
  04/13/2017 Jermaine Stukes    Added new DNC logic
  03/13/2018 Cindy Freeman      Added check of Lost Client for Client Reference 
  02/13/2019 Dan Carmen       Added check for recursion
  01/08/2020 Dan Carmen        Increment API version, Move AccountJunction logic to Interface class
  05/10/2021 Jacob Hinds    Calling CommunityMethods after zip code update
  01/04/2022 Dan Carmen         Move logic from the AccountAfter trigger to ZipCheckOwner
  04/05/2023 Vinay          Added "MutualClientRelationMethods" call for Prospect-Client Mutual clients verification.
  06/02/2023 Dan Carmen         Removed call to MutualClientRelationMethods
  12/11/2023 Dan Carmen         Remove ReferenceMPSC direct calls
  03/15/2024 Dan Carmen         Remove Dataflux code

 */
trigger AccountAfter on Account (after insert, after update) {
   System.debug('AccountAfter.SKIP_TRIGGERS = '+ZipCheckOwner.SKIP_TRIGGERS);
   if (ZipCheckOwner.SKIP_TRIGGERS || AccountMethods.ACCOUNT_AFTER_TRIGGER_EXECUTING) {
      return;
   }

   AccountMethods.ACCOUNT_AFTER_TRIGGER_EXECUTING = true;
   //get account for contacts with Do_Not_Call__c selected
   Set<Id> DNCAccount = new Set<Id>();
   //get account for contacts with Email_Opt_Out__c selected
   Set<Id> EmailAccount = new Set<Id>();
   // set of accounts tat went Lost to check for Client References
   Set<Id> lostAcctSet = new Set<Id>();
   // product of interest changes - have to reevaluate ownership (if it already exists)
   List<Id> acctIdsProdChanged = new List<Id>();
   List<Id> firstRunDateAcctIds = new List <Id>();
   List<string> acctEmailUpdatedList = new List<string>();   
   UserHelper.setRunningUserAttributes();
   Boolean isLeadLoader = UserHelper.runningUserIsLeadLoader;
   Boolean ruBeginsSysAdmin = UserHelper.isSystemAdmin(userHelper.getRunningUser());
    
   Map<Id,Id> hrgUpdate = new Map<Id,Id>();
   
  TriggerMethods.checkBeforeLoop('AccountAfter', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
   
   for (Account acct: Trigger.new) {
      System.debug('AccountAfter acct.Name='+acct.Name);
      Account olda = (Trigger.isUpdate ? Trigger.oldMap.get(acct.id) : null);
      
      TriggerMethods.checkInLoop('AccountAfter', acct, olda, Trigger.IsBefore, Trigger.IsAfter);
      
      // check account Do Not Call and Email Opt out flags if checked and not previously checked or insert add to set 
      if (acct.Do_Not_Call__c && (olda == null || !olda.Do_Not_Call__c)) {
         DNCAccount.add(acct.Id);
      }
      if (acct.Email_Opt_Out__c && (olda == null || !olda.Email_Opt_Out__c)) {
         EmailAccount.add(acct.Id);
      }
      
      AccountMethods.accountAfterChecks(acct,olda);
      
      if (Trigger.isUpdate) {
            
         if(acct.HR_Generalist__c != null && acct.HR_Generalist__c != olda.HR_Generalist__c){
            hrgUpdate.put(acct.HR_Generalist__c, acct.Id);
         }
                       
                    
         if (!isLeadLoader && olda != null && String.isNotBlank(acct.Products__c) && olda.Products__c != acct.Products__c) {
            // if products do change, evaluate the NSS Team to see if it changed
            acctIdsProdChanged.add(acct.Id);
         }

         if (acct.EvaluateSignificant__c) {
            AccountMethods.accountIdsToCheckSignificantSet.add(acct.Id);
         }
          
         if (ruBeginsSysAdmin && acct.First_Run_Date__c != oldA.First_Run_Date__c) {
             firstRunDateAcctIds.add(acct.Id);
         }
         if (acct.Email_Opt_Out__c && (olda.Email__c != acct.Email__c)) {
            acctEmailUpdatedList.add(acct.Email__c);
         }
         if (acct.Type == 'Lost Client' && acct.Type != olda.Type)
         {    lostAcctSet.add(acct.Id); }
      } 
   } // for (Account
   
   TriggerMethods.checkOutsideLoop('AccountAfter', Trigger.isBefore, Trigger.isAfter);

   //post chatter messages that got created
   if(!Test.IsRunningTest()){
      ChatterMentionPost.postBatchFeedElements();
   }
   
   //update ref hrg
   if(!hrgUpdate.IsEmpty()){
      ReferenceHRGMethods.ownerSync(hrgUpdate);
   }
    
   //call method to update Payroll run date
   if (!firstRunDateAcctIds.isEmpty()) {
      FirstRunDateUpdate.updatePayrollRunDate(firstRunDateAcctIds);
   }
   
   // call ContactRestrictionsfromAccount class
   if (!DNCAccount.isEmpty()||!EmailAccount.isEmpty()) {
      ContactRestrictionsfromAccount.getContacts(DNCAccount,EmailAccount);
   }
   
   if(Trigger.isUpdate){
        CommunityMethods.handleAcctsAfter(Trigger.New,Trigger.oldMap);
    }
   
   AccountMethods.checkForAccountAfterMethods();
   
   if (!acctIdsProdChanged.isEmpty()) {
      ProspectOwnershipMethods.evaluateAccountNSSTeam(acctIdsProdChanged);
   }

    if (!lostAcctSet.isEmpty())
    {   ClientReferencesSelectedMethods.referenceWentLost(lostAcctSet); }
    
   AccountMethods.ACCOUNT_AFTER_TRIGGER_EXECUTING = false;
    
} // trigger AccountAfter