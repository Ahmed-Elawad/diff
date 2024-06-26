/**
 * Handle all of the "after" Contact operations.
   Migrated logic from ContactCheckOwner trigger.
   Migrated logic from ContactCheckEmail trigger
 *
 * History
 * -------
 * 02/21/2012 Dan Carmen        Created
 * 06/8/2012  Carrie Marciano   Added DoNotCall and EmailOptOut check
 * 12/06/2012 Cindy Freeman     Added Use Zip Assignment Rules to force ZipCheckOwner to be run
 * 04/10/2014 Cindy Freeman     Added check for DataFlux delta service
 * 05/20/2015 Carrie Marciano   Added check for Sensitivity BeneTrac - to change the Do Not Call flag on account records to yellow when contact has this checked
 * 06/04/2015 Carrie Marciano   Added check for Sensitivity Icon - to change the Do Not Call flag on account records to yellow when contact has this checked
 * 09/16/2015 Cindy Freeman      if contact's Account Id changes due to merge process, send to code to pull down new Account's DNC and EOO flags
   09/20/2016 Dan Carmen        Ability to trigger a change based on field sensitivity update.
   01/04/2017 Josh Cartwright   added dataflux change to the trigger, removed code to put into the datafluxDeltaService class 
   01/20/2017 Dan Carmen        Add call to TriggerMethods
   04/13/2017 Jermaine Stukes   Added new DNC logic
   05/11/2017 Dan Carmen      Add additional call to TriggerMethods
   01/31/2018 Dan Carmen        Merge in UserUpdateFromContact logic
   09/07/2018 Jacob Hinds        Merging revised dnc code
   11/29/2018 Cindy Freeman      be sure to call code to add Contacts to campaign
   12/31/2018 Dan Carmen         Move DNC code to DNCHelper
   10/24/2019 Dan Carmen        Move all LatestCampaign__c code to CampaignMethods
   03/17/2024 Dan Carmen        Move dataflux logic to DataFluxDeltaService

 */
 
trigger ContactAfter on Contact (after insert, after update) {
   System.debug('ContactAfter ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING='+ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING);
   // to prevent recursion in the trigger.
   if (ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING) {
      return;
   }
   ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;

   Boolean isLeadLoader = UserHelper.isLeadLoader(UserInfo.getName());
   Boolean isSfdcData = UserHelper.isSfdcData(UserInfo.getName());
   Boolean isRelJunc = UserHelper.isRelationalJunction(UserInfo.getName());
   
   // get the user information
   Boolean checkOwner = (Trigger.isInsert && ZipCheckOwner.checkOnInsert());

   //get account for contacts with Do_Not_Call__c  OR Sensitivity_BeneTrac__c OR Sensitivity_Icon__c selected 
   Set<Id> DNCAccountContactRestrictions = new Set<Id>();
   
   //get account for contacts with Email_Opt_Out__c selected
   Set<Id> EmailAccountContactRestrictions = new Set<Id>();
    
    //three lists to check against dnc depending on if phone,email or both changed
    List<Id> contactDNCList = new List<Id>();
    List<Id> contactEOOList = new List<Id>();
    List<Id> contactDNCEOOList = new List<Id>();
    //DNC Update List
    List<Id> contactUpdatedPhoneList = new List <Id>();
    List<Id> contactUpdatedEmailList = new List <Id>();
   //List<String> contactEmailList = new List<String>();
   
   // product of interest changes - have to reevaluate ownership (if it already exists)
   List<Id> ctctIdsProdChanged = new List<Id>();

   // the set of ids to handle the ownedBy field.
   Set<Id> ownedByCtctIdSet = new Set<Id>();
   Set<Id> ownedByAcctIdSet = new Set<Id>();

   // set of account ids for contacts that were moved to different account
   Set<Id> acctIdSet = new Set<Id>();
   
   //Map<Id,Id> contactCampaignIdMap = new Map<Id,Id>();
   
   TriggerMethods.checkBeforeLoop('ContactAfter', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);

   for (Contact rec : Trigger.new) {
      Contact oldC = (Trigger.isInsert ? null : (Contact)Trigger.oldMap.get(rec.id));
      
      TriggerMethods.checkInLoop('ContactAfter', rec, oldC, Trigger.IsBefore, Trigger.IsAfter);

      // we don't want employees going into here. 
      if (rec.AccountId != null && rec.HR_Person_Id__c == null) {
         SensitivityHelper.checkAfterTrigger(rec, oldC);
         ReferralScoreMethods.checkTriggerAfter(rec, oldC);

         // insert has to be called from the after trigger because we need to have the id
         if (isLeadLoader && Trigger.isInsert && String.isNotBlank(rec.OwnedBy__c)) {
            ownedByCtctIdSet.add(rec.Id);
            ownedByAcctIdSet.add(rec.AccountId);
         }

         if (Trigger.isInsert) {

            if (rec.DoNotCall || rec.Sensitivity_BeneTrac__c || rec.Sensitivity_Icon__c){
               DNCAccountContactRestrictions.add(rec.AccountId);
            }
            //if(rec.Email!=Null)
            //   {contactUpdatedEmailList.add(rec.Id);}
            if (rec.HasOptedOutOfEmail){
               EmailAccountContactRestrictions.add(rec.AccountId);
            }
         } else if (Trigger.isUpdate) {
         
            if ((rec.DoNotCall && rec.DoNotCall != oldc.DoNotCall) || (rec.Sensitivity_BeneTrac__c && rec.Sensitivity_BeneTrac__c != oldc.Sensitivity_BeneTrac__c) || (rec.Sensitivity_Icon__c && rec.Sensitivity_Icon__c != oldc.Sensitivity_Icon__c)){
               DNCAccountContactRestrictions.add(rec.AccountId);
            }
            if (rec.HasOptedOutOfEmail && rec.HasOptedOutOfEmail != oldc.HasOptedOutOfEmail){
               EmailAccountContactRestrictions.add(rec.AccountId);
            }
            if (oldC != null && oldC.Products__c != rec.Products__c) {
               // if the owner doesn't change but the products do change, evaluate the NSS Team to see if it changed
               ctctIdsProdChanged.add(rec.Id);
            }          
            if (rec.AccountID != oldC.AccountId)
            {  acctIdSet.add(rec.AccountID);   }
         
         } // if (Trigger
      } // if (rec.AccountId != null && rec.HR_Person_Id__c != null

   } // for (Contact rec

   System.debug('ContactAfter after record loop');

   TriggerMethods.checkOutsideLoop('ContactAfter', Trigger.isBefore, Trigger.isAfter);

   if (!DNCAccountContactRestrictions.isEmpty()||!EmailAccountContactRestrictions.isEmpty()) {
      AccountCheckContactRestrictions.checkContacts(DNCAccountContactRestrictions,EmailAccountContactRestrictions);
   }

   if (!ctctIdsProdChanged.isEmpty()) {
      ProspectOwnershipMethods.evaluateContactNSSTeam(ctctIdsProdChanged);
   }
   
   if (!ownedByCtctIdSet.isEmpty()) {
      ContactMethods.checkOwnedBy(ownedByCtctIdSet, ownedByAcctIdSet);
   }

   if (!acctIdSet.isEmpty())
   {    ContactRestrictionsfromAccount.mergedContacts(acctIdSet);   }
   
   AccountMethods.checkSignificantContact();
   
   SensitivityHelper.checkAfterActions();
   
   ReferralScoreMethods.processCtctTriggerAfter();

   ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = false;

} // trigger ContactAfter