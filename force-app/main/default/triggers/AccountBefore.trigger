/* 
   A trigger to handle before update/insert operations.

Running these tests should get test coverage for this trigger if not doing a full deploy:
AccountBeforeTest,AccountCheckFldsTest,AccountCheckHoldOutTest,AccountCheckShippingAddressTest,AccountHelperTest,AccountMethodsTest

  History
  -------
  07/27/2011 Dan Carmen   Created
  11/26/2013 Dan Carmen   Added logic for NSS Dialing
  02/16/2015 Dan Carmen   Changes for the NSS Call Disposition Field
  03/11/2015 Dan Carmen   Provide updates to the significant contact
  02/15/2016 Dan Carmen   Make sure the Dialed__c checkbox is set if the last call time changes.
  03/10/2016 Jacob Hinds  Added in call to check Account Type if Account is being updated by SFDC Data.
  05/02/2016 Dan Carmen   Ability to not trigger on the dialed checkbox
  05/02/2016 Jacob Hinds  Adding in Evaluate Type field to manually recheck type
  08/16/2016 Cindy Freeman  Added code for new Parent - Child functionality
  12/4/2016  Jacob Hinds  Adding in Profiled Evaluation
  12/15/2016 Jacob Hinds  Fix insert entry point for Profiled
  01/13/2016 Jacob Hinds  Add entry point for Profiled when any of the profiling fields change.
  01/20/2017 Dan Carmen   Add call to TriggerMethods
  01/24/2017 CIndy Freeman  tweak to asset and employee calc to handle null values
  01/27/2017 Cindy Freeman  put try catch around asset employee calc to catch null pointers
  02/08/2017 Cindy Freeman  modifed to only update assets and employees if values really change
  03/21/2017 Cindy Freeman  moved account junction stuff to junction trigger
  06/08/2017 Dan Carmen    Added extra call to TriggerMethods
  07/20/2017 Dan Carmen    Remove Profiled code
  09/29/2017 Dan Carmen    Fix for the Paychex_Payroll_Specialist__c field - trigger was treating it as a string.
  01/08/2017 Jacob Hinds   Removing checkcalldisposition
  12/06/2018 Dan Carmen       Replace qbdialer__LastCallTime__c with LatestCallTime__c
  02/13/2019 Dan Carmen       Added check for recursion
  01/08/2020 Dan Carmen        Increment API version, Move AccountJunction logic to Interface class
  18/05/2022 Jaipal          Calling method: AccountMethods.SendLostNotificationCSSR(OldA,newA);(isUpdate)
  01/10/2024 Dan Carmen      Added a field to Skip the Paychex triggers on the account
  03/06/2024 Susmitha Somavarapu Commented the code for don't let the paychex payroll specialist field changed by SFDC data if the MMS AS field is populated(INC3636379)


 */
trigger AccountBefore on Account (before update, before insert) {
   if (Trigger.new != null && !Trigger.new.isEmpty() && ((Account)Trigger.new[0]).SkipTriggers__c) {
      System.debug('AccountBefore setting SKIP_TRIGGERS based on SkipTriggers__c=true on an Account record');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      for (Account acct : Trigger.new) {
         acct.SkipTriggers__c=false;
      }
   }

   if (ZipCheckOwner.SKIP_TRIGGERS || AccountMethods.ACCOUNT_BEFORE_TRIGGER_EXECUTING) {
      return;
   }
   
   AccountMethods.ACCOUNT_BEFORE_TRIGGER_EXECUTING = true;

   // if the Dialed__c field is set, check if anything needs to be done.
   // this should only be done on update - should already exist
   Account[] checkDialed = new Account[]{};
   // if the call disposition is changed to a not blank value
   // again, should only be done on an update
   Account[] checkCallDisposition = new Account[]{};
   Account[] lastCallDateChanged = new Account[]{};
   Set<Id> significantContactIdSet = new Set<Id>();
   Set<Id> accountMethodsAcctIdSet = new Set<Id>();
   Set<Id> accountMethodsUserIdSet = new Set<Id>();
   
   // if a hosted client, check the ownership
   Account[] hostedAccounts = new Account[]{};
   
   /** Ids of records that have been called so we can flag other records with same phone number */
   Set<Id> idsDialedSet = new Set<Id>();
   
   UserHelper.setRunningUserAttributes();
   
   
   List<Account> acctTypeList = new List<Account>();
       
   //Boolean isSfdcData = UserHelper.isSfdcData(UserInfo.getName());
   //Boolean isLeadLoader = UserHelper.isLeadLoader(UserInfo.getName());

   TriggerMethods.checkBeforeLoop('AccountBefore', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
 
   if (Trigger.isUpdate) {
      CheckDataGovernance.checkData(Trigger.new, Trigger.oldMap);//As per the Data Goverance doc
   }
   
   for (Account newA : Trigger.new) {
      Account oldA = (Trigger.isUpdate ? Trigger.oldMap.get(newa.id) : null);
      System.debug('**CMF ** calling AcctJuncMeth.checkBeforeAccount');      
      //AccountJunctionMethods.checkBeforeAccount(newA, oldA, Trigger.isInsert, Trigger.isDelete);            
        if(Trigger.isUpdate && oldA.CSCMContractStatus__c != newA.CSCMContractStatus__c){
        acctTypeList.add(newA);
    }
    Boolean okayToContinue = (newA.Id == null || !AccountMethods.callDispositionHandledSet.contains(newA.Id));
    if (okayToContinue) {
      
         TriggerMethods.checkInLoop('AccountBefore', newA, oldA, Trigger.IsBefore, Trigger.IsAfter);
         //check if integration is making the update
          if(UserHelper.isSfdcData(UserInfo.getName()) && newA.Bis_ID__c!=null){
            if(Trigger.isInsert){
                newA.Evaluate_Type__c=true;
            }
            else if(Trigger.isUpdate && ((oldA.Client_Status__c!= newA.Client_Status__c) || (oldA.Lost_Date__c != newA.Lost_Date__c) ||
                                            (oldA.HR_Generalist__c != newA.HR_Generalist__c) || (oldA.HR_Manager__c != newA.HR_Manager__c) ||
                                                (oldA.Payroll_Branch_Nbr__c != newA.Payroll_Branch_Nbr__c))){
                newA.Evaluate_Type__c=true;
            }
          }
          if(newA.Evaluate_Type__c){
            newA.Evaluate_Type__c = false;
            acctTypeList.add(newA);
          }

         //ZipCheckOwner.accountBeforeActions(newA,oldA);
         
         // make sure only goes in once during a trigger invocation
         if (newA.Hosted_Client__c && (Trigger.IsInsert || (Trigger.IsUpdate && !HostedAccountContact.hostedCheckedIds.contains(newA.Id)))) {
            hostedAccounts.add(newA);
         }
      
         // check if the last call date changed - we want to update the significant contact
         if (newA.LatestCallTime__c != null && Trigger.isUpdate && newA.LatestCallTime__c != oldA.LatestCallTime__c) {
            if (newA.Id != null) {
               accountMethodsAcctIdSet.add(newA.Id);
               lastCallDateChanged.add(newA);
               if (newA.SignificantContact__c != null) {
                  significantContactIdSet.add(newA.SignificantContact__c);
               }
            } // if (newA.Id != null
            
            // if the call date changed, that should have been a dial if the user isn't ISDC
            if (!newA.Dialed__c && Label.PO_DateCheck == 'Y' &&!UserHelper.runningUserIsIsdcApi ) {
               newA.Dialed__c = true;
            }
         } // if (newA.LatestCallTime__c

         AccountMethods.accountBeforeChecks(newA,oldA);
      
         if (Trigger.isUpdate) {
         
            // if Dialed__c switches to true
            if (newA.Dialed__c && !oldA.Dialed__c) {
               checkDialed.add(newA);
               // reset the flag
               //newA.Dialed__c = false;
               //newA.DialedLastUsed__c = DateTime.now();
            
               // save Id to look for and flag other records with same phone number            
               idsDialedSet.add(newA.Id);   
            } // if newA
         
            // if the call disposition changes
            if (String.isNotBlank(newA.NSSCallDisposition__c) 
                    && !AccountMethods.callDispositionHandledSet.contains(newA.Id) 
                    && newA.NSSCallDisposition__c != oldA.NSSCallDisposition__c) {
               checkCallDisposition.add(newA);
               accountMethodsAcctIdSet.add(newA.Id);
               if (newA.SignificantContact__c != null) {
                  significantContactIdSet.add(newA.SignificantContact__c);
               }
               if (String.IsNotBlank(newA.DialedUserId__c)) {
                  accountMethodsUserIdSet.add((Id)newA.DialedUserId__c);
               }
            } // if (String.isNotBlank
            // don't let the paychex payroll specialist change by SFDC data if the MMS AS is populated
          /*  if (UserHelper.isSfdcData(UserInfo.getName()) && newA.Paychex_Payroll_Specialist__c != oldA.Paychex_Payroll_Specialist__c) {
               if (oldA.Paychex_Payroll_Specialist__c == null && newA.MMS_AS__c != null) {
                  newA.Paychex_Payroll_Specialist__c = oldA.Paychex_Payroll_Specialist__c;
               }
            } */ 
             //To notify lost client for users: APR0132594 - FY23 Create a new CSSR Mid-Market role in 20-49 segment
             AccountMethods.SendLostNotificationCSSR(OldA,newA);
         
         } // if (Trigger.isUpdate
    } // if (okayToContinue
   } // for (Account newA

   TriggerMethods.checkOutsideLoop('AccountBefore', Trigger.isBefore, Trigger.isAfter);

   AccountMethods.processBeforeActions();
   
   if(!acctTypeList.isEmpty()){
      AccountMethods.setAccountType(acctTypeList,false);
   }
   if (!hostedAccounts.isEmpty()) {
      HostedAccountContact.checkHostedOwner(hostedAccounts,(Trigger.isUpdate && !ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING));
   }
   if (!LeadMethods.DISABLE_DIAL_CHECKBOX && !checkDialed.isEmpty()) {
      AccountMethods.checkDialed(checkDialed);
   } // if (!checkDialed

   if (!accountMethodsAcctIdSet.isEmpty()) {
      AccountMethods.checkCallDisposition(checkCallDisposition, lastCallDateChanged, significantContactIdSet
                                         ,accountMethodsAcctIdSet, accountMethodsUserIdSet);
   } // if (!checkCallDisposition

   if (!idsDialedSet.isEmpty())
   {    User runningUser = UserHelper.getRunningUser();     
        NSSMethods.checkDuplicatePhone(idsDialedSet, runningUser.id);
   }
   
   if (!checkDialed.isEmpty()) {
      // clear the flags
      for (Account acct : checkDialed) {
         acct.Dialed__c = false;
         acct.DialedUserId__c = null;
         acct.DialedLastUsed__c = DateTime.now();
      }
   } // if
   
   AccountMethods.ACCOUNT_BEFORE_TRIGGER_EXECUTING = false;
} // trigger AccountBefore