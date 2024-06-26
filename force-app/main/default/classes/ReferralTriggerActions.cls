/* 
 * Handle actions in the referral trigger
 *
 * History
 * -------
   01/27/2016 Dan Carmen      Created
   01/26/2017 Dan Carmen      Ability to update from the referral to the opportunity
   04/21/2017 Jacob Hinds     Adding in Round Robin and Related Object Sync.
   11/01/2018 Dan Carmen      Add the LatestReferral__c flag
   07/06/2020 Matt Fritschi   Added ability to create Referring Opportunities for Amp Referrals.
   07/31/2020 Jake Hinds      Change to how CreateReferringOpp is called
   03/12/2021 Manmeet Vaseer  APR0116745 - Tracking for Inbound Internal referral Opportunities
                                Requirements: https://wiki.paychex.com/pages/viewpage.action?spaceKey=CP&title=APR0116745+-+Tracking+for+Inbound+Internal+referral+Opportunities
   04/30/2021 Pujitha Madamanchi APR0119471 : Added SOAR Identification for eComm
   07/16/2021 Dan Carmen      Make refApprovedIds public
   01/24/2021 Pujitha Madamanchi APR0130503 - CA Mandate: Referral Approval Date
   10/25/2023 Dan Carmen       Update call to ReferralMethods.updateDSAOpptyRefJoin method
   10/27/2023 Lalan Kumar      INC3151825:the opportunity is not updating with the information from the Referral - "Month Sale Reported" field 
   03/21/2024 Pujitha Madamanchi APR0165167 - Update Referral Inbound_Opportunity__c logic


 */
public with sharing class ReferralTriggerActions {
   
   public static Boolean SKIP_TRIGGER=false;

   // the records to check email field
   private static Referral__c[] checkEmail = new Referral__c[]{};
   // check the referral partner name
   private static Map<Id,Referral__c[]> checkRefPartnerMap = new Map<Id,Referral__c[]>();
   
   // the records to move reject reason from approval to referral 
   private static Referral__c[] refRejectedReasons = new Referral__c[]{};
   
   private static Referral__c[] refTrackerList = new Referral__c[]{};
   
   private static Referral__c[] refRoundRobinList  = new Referral__c[]{};
   
   private static Referral__c[] amplifinityReferralsWithOpp  = new Referral__c[]{};
       
   private static Id[] refOwnerSyncList  = new Id[]{};
   
   private static Set<Id> skipRelatedOwnerUpdateSet = new Set<Id>();
   
   private static Map<Id,Referral__c[]> latestRefMap = new Map<Id,Referral__c[]>();

   private static Map<Id,Referral__c[]> newInternalRefMap = new Map<Id,Referral__c[]>();
   private static Referral__c[] soarRefsList = new Referral__c[]{};
    
   public static void checkBeforeActions(Referral__c newRef, Referral__c oldRef) {
      if (newRef.Referral_Partner__c != null) {
         if (oldRef == null) {
            StringHelper.addToProcessNotes(newRef,'Referral_Partner__c set on insert '+newRef.Referral_Partner__c);
         } else if (newRef.Referral_Partner__c != oldRef.Referral_Partner__c) {
            StringHelper.addToProcessNotes(newRef,'Referral_Partner__c set on update '+newRef.Referral_Partner__c);
         }
      }
       
       //Capture the EE Title of the referring employee on all new Referral records
       //Attempt to grab first from the related referring user's title field, then from the 'refer from contact' record, then from the running user 
       if(Trigger.isInsert) {
           if(newRef.Referring_User__c != null) {
               newRef.Referring_Employee_Title__c = newRef.Referring_User__r.Title;
           }
           if(newRef.ReferFromContact__c != null && String.isBlank(newRef.Referring_Employee_Title__c)) {
               newRef.Referring_Employee_Title__c = newRef.ReferFromContact__r.Title;
           }
           if(String.isBlank(newRef.Referring_Employee_Title__c)) {
               User runningUser = UserHelper.getRunningUser();
               newRef.Referring_Employee_Title__c = runningUser != null ? runningUser.Title : null;
           }
           //If successfully populated the referring employee title field, add that to process notes
           if(!String.isBlank(newRef.Referring_Employee_Title__c)) {
               StringHelper.addToProcessNotes(newRef,'Referring_Employee_Title__c set on insert '+newRef.Referring_Employee_Title__c);
           }
           System.debug('MAK - End of Populating Referring Employee Title: ' + newRef.Referring_Employee_Title__c);
       }
      
      if (newRef.Referral_Partner__c != null
          && (String.isBlank(newRef.ReferralPartnerName__c) 
              || (oldRef != null && newRef.Referral_Partner__c != oldRef.Referral_Partner__c))) {
         StringHelper.addToProcessNotes(newRef,'Adding Referral Partner Name check for '+newRef.Referral_Partner__c);
         Referral__c[] refs = (checkRefPartnerMap.containsKey(newRef.Referral_Partner__c) ? checkRefPartnerMap.get(newRef.Referral_Partner__c) : new Referral__c[]{});
         refs.add(newRef);
         checkRefPartnerMap.put(newRef.Referral_Partner__c,refs);
      } // if ((String.isBlank(ref.ReferralPartnerName__c
         
      if (Trigger.isUpdate && newRef.BypassRelatedOwnerUpdate__c) {
         skipRelatedOwnerUpdateSet.add(newRef.Id);
         newRef.BypassRelatedOwnerUpdate__c = false;
      }
      // check the email on all inserts, or if a contact field changes on update
      if (newRef.Email__c == null || Trigger.isInsert ||
          (Trigger.isUpdate && oldRef != null && (oldRef.Contact__c != newRef.Contact__c || 
                                                  oldRef.Referral_Contact__c != newRef.Referral_Contact__c)) ) {
         checkEmail.add(newRef);
      }
         
      if (newRef.CreateSellerEvent__c && newRef.ActivityDateTime__c != null) {
         newRef.ActivityDateTimeFormatted__c = Utilities.formatDate('Referral Format Date', newRef.ActivityDateTime__c, newRef.TimeZoneOffset__c, newRef.TimeZoneAbbrev__c);
      }
      if (newRef.Reject_Reason__c == 'Rejected' && String.isBlank(oldRef.Reject_Reason__c))
      {  refRejectedReasons.add(newRef);    }
      
      system.debug('jsh trigger before check isInsert='+Trigger.isInsert+' refTrackerList: '+refTrackerList.size());
      //referral is inserted or owner changes
      //refTrackerList = new Referral__c[]{};
      if ((Trigger.isInsert || newRef.OwnerId != oldRef.OwnerId)){
         refTrackerList.add(newRef);
      }
      system.debug('jsh trigger after check isInsert='+Trigger.isInsert+' refTrackerList: '+refTrackerList.size());
      
      //owner changed to queue, try round robin
      if(Trigger.isUpdate){
        system.debug('jsh ownertype: ' + newRef.OwnerId.getsobjecttype()+' new: '+newRef.OwnerId +' old: '+ oldRef.OwnerId);
      }
      
      if ((Trigger.isInsert || newRef.OwnerId != oldRef.OwnerId)){
         StringHelper.addToProcessNotes(newRef,'OwnerId set to '+newRef.OwnerId+(oldRef != null ? ' from '+oldRef.OwnerId : '')+' user='+newRef.User__c);
         if (newRef.OwnerId.getsobjecttype() != User.sobjecttype) {
            refRoundRobinList.add(newRef);
         }
      }
      
      if (newRef.User__c != null && (oldRef == null || newRef.User__c != oldRef.User__c)) {
         StringHelper.addToProcessNotes(newRef,'User__c set to '+newRef.User__c+(oldRef != null ? ' from '+oldRef.User__c : ''));
      }
      
      if (String.isNotBlank(newRef.Status__c) && newRef.Status__c=='Approved'
              && (oldRef == null || newRef.Status__c != oldRef.Status__c)) {
         // count the number of times this referral record goes to approved.
         newRef.ApprovedCount__c = ((newRef.ApprovedCount__c != null ? newRef.ApprovedCount__c : 0) + 1); 
         //APR0130503 - CA Mandate: Referral Approval Date
         newRef.Referral_Approved_Date__c = System.now();
         newRef.Referral_Approved_Timeframe__c = newRef.Referral_Approved_Date__c!=null ? newRef.Referral_Approved_date__c.format(Label.CallTime_format,Label.CallTime_TimeZone):DateTime.now().format(Label.CallTime_format,Label.CallTime_TimeZone);
      }
      
      // log the status change in process notes
      if (oldRef != null && String.isNotBlank(newRef.Status__c) && newRef.Status__c != oldRef.Status__c) {
         StringHelper.addToProcessNotes(newRef,'Status changed from '+oldRef.Status__c+' to '+newRef.Status__c+' by '+UserInfo.getUserId());
      }

      SRRTransitionHelper.checkBeforeActions(newRef,oldRef);

      ReferralMethods.checkDisposition(newRef,oldRef);
      
      if (Trigger.isInsert && (newRef.Account__c != null || newRef.SourceLead__c != null)) {
         // check for any other referrals attached to the lead/account and remove the LatestReferral__c checkbox if they exist.
         Id key = (newRef.Account__c != null ? newRef.Account__c : newRef.SourceLead__c);
         Referral__c[] refs = (latestRefMap.containsKey(key) ? latestRefMap.get(key) : new Referral__c[]{});
         refs.add(newRef);
         latestRefMap.put(key,refs);
      }
      
      
       System.debug('ReferralTriggerActions newRef.Selling_Opportunity__c='+newRef.Selling_Opportunity__c);
       //System.debug('Trigger.isUpdate='+Trigger.isUpdate);
       if(oldRef != null && oldRef.Selling_Opportunity__c == null && newRef.Selling_Opportunity__c != null && newRef.Amplifinity_Referral__c != null)
       {
           System.debug('ReferralTriggerActions Creating Refrring Opp in ReferralTriggerActions');
           amplifinityReferralsWithOpp.add(newRef);
       }
       
       /*
        * APR0116745
        * If this is an Internal Referral, 
        * find the Inbound Opportunities in the last 90 days in the Account associated with this Internal Referral
        * and link that Inbound Opportunities to the 'Inbound Opportunity' field of this Internal Referral.
        * APR0119471 : Added SOAR Referral
        */
       if (Trigger.isInsert)    {
           if ((newRef.Referral_Type__c == 'Internal Referral' || newRef.Referral_Type__c == 'SOAR Referral')  && newRef.Account__c != null) {
               Id key = newRef.Account__c;
               Referral__c[] refs = (newInternalRefMap.containsKey(key) ? newInternalRefMap.get(key) : new Referral__c[]{});
               refs.add(newRef);
               newInternalRefMap.put(key,refs);   
               soarRefsList.add(newRef);            
           }
       }
       
   } // checkBeforeActions
   
   
   
   // the approved referrals
   public static Id[] refApprovedIds = new Id[]{};
   // the rejected referrals
   private static Id[] refRejectedIds = new Id[]{};
   // keep track of accounts we are going to try to update
   private static Map<Id, Referral__c[]> refByAcctIdMap = new Map<Id,Referral__c[]>();
   // when an opportunity is linked up, move the payment info from the referral to the opp.
   private static Map<Id, Referral__c> refsByOppIdMap = new Map<Id,Referral__c>();
   //Rohit
   //public static List<Referral__c> referalList = new List<Referral__c>();
   // when the selling opportunity is set, check for a matching Dialsource Action record.
   public static Id[] checkOppDsaLookup = new Id[]{};

   public static void checkAfterActions(Referral__c newRef, Referral__c oldRef) {
      // if the status changes - handle any actions.
      System.debug('checkAfterActions refApprovedIds='+refApprovedIds.size()+' isInsert='+Trigger.isInsert+' new Status='+newRef.Status__c+' old='+(oldRef != null ? oldRef.Status__c : 'N/A'));
      if (Trigger.isInsert || (newRef.Status__c != oldRef.Status__c)) {
         if (newRef.Status__c == 'Approved') {
            refApprovedIds.add(newRef.Id);
         } else if (newRef.Status__c == 'Rejected') {
            refRejectedIds.add(newRef.Id);
         }
      } // if (ref.Status__c 
      System.debug('checkAfterActions refApprovedIds='+refApprovedIds.size());
       
      if (oldRef != null && newRef.Account__c != null
          && ((String.isNotBlank(newRef.BranchClientNumber__c) && newRef.BranchClientNumber__c != oldRef.BranchClientNumber__c)
             || (String.isNotBlank(newRef.FedIdNumber__c) && newRef.FedIdNumber__c != oldRef.FedIdNumber__c))
         ) {
         Referral__c[] refList = refByAcctIdMap.get(newRef.Account__c);
         if (refList == null) {
            refList = new Referral__c[]{};
            refByAcctIdMap.put(newRef.Account__c, refList);
         }
         refList.add(newRef);
      } // if (oldOpp != null
      
      if /*(oldRef != null && newRef.Selling_Opportunity__c != null && newRef.Selling_Opportunity__c != oldRef.Selling_Opportunity__c
             && String.IsNotBlank(newRef.Disposition__c) && newRef.Referral_Id__c != null) */
          /*INC3151825: Removed newRef.Selling_Opportunity__c != oldRef.Selling_Opportunity__c check from condition  */
       (newRef.Selling_Opportunity__c != null
             && String.IsNotBlank(newRef.Disposition__c) && newRef.Referral_Id__c != null){
         refsByOppIdMap.put(newRef.Selling_Opportunity__c, newRef);
      }
      
      //owner changed to user, sync related objects
      //if ((Trigger.isInsert || newRef.OwnerId != oldRef.OwnerId) && newRef.OwnerId.getsobjecttype() == User.sobjecttype){
      // don't fire the trigger if the owner is the running user.
      if (newRef.SetOwnerHoldout__c 
          || (!skipRelatedOwnerUpdateSet.contains(newRef.Id) && newRef.OwnerId != UserInfo.getUserId() && (Trigger.isInsert || newRef.OwnerId != oldRef.OwnerId))
         ){
         system.debug('checkAfterActions adding to refOwnerSyncList');
         refOwnerSyncList.add(newRef.Id);
      }
      // Rohit  
       if ( newRef.Selling_Opportunity__c != null && newRef.Primary__c == True && (oldRef == null || newRef.Selling_Opportunity__c != oldRef.Selling_Opportunity__c)){ 
          //System.debug('oldRef>>'+oldRef +'====='+'newRef >>'+newRef+'>>Done');
           checkOppDsaLookup.add(newRef.Selling_Opportunity__c);
       }
       
   } // checkAfterActions
   
   public static void handleBeforeActions() {
      if (!checkRefPartnerMap.isEmpty()) {
         ReferralMethods.checkRefPartnerName(checkRefPartnerMap);
      }
   
      if (!checkEmail.isEmpty()) {
         ReferralMethods.checkEmail(checkEmail);
      } // if (!checkEmail.isEmpty

      if (!refRejectedReasons.isEmpty()) {
         ReferralMethods.moveRejectedReasons(refRejectedReasons);
      } // if (!refRejectedReasonIds.isEmpty
      
      if (!refTrackerList.isEmpty()){
         ReferralMethods.manageTransferTrackingBefore(refTrackerList);
      }
       
      if (!refRoundRobinList.isEmpty()){
         Map<String,PartnerReferral__c> refTransIdPartReferralMap = ReferralMethods.getPartnerReferralMap(refRoundRobinList);
         RoundRobin.prepareGenericRoundRobin(refRoundRobinList,refTransIdPartReferralMap);
         for (Referral__c ref : refRoundRobinList) {
            StringHelper.addToProcessNotes(ref,'After RoundRobin ownerId='+ref.OwnerId+' user='+ref.User__c);
         }
         refRoundRobinList.clear();
      }

      SRRTransitionHelper.processBeforeActions();
      
      if (!latestRefMap.isEmpty()) {
         checkForPreviousReferrals();
      }
       
      if(!amplifinityReferralsWithOpp.isEmpty())
      {
          System.debug('Creating the Referring Opp for: '+amplifinityReferralsWithOpp);
          CreateReferringOpp.createOpp(amplifinityReferralsWithOpp);
          amplifinityReferralsWithOpp.clear();
      }
       
       /*
        * APR0116745
        * If this is an Internal Referral, 
        * find the Inbound Opportunities in the last 90 days in the Account associated with this Internal Referral
        * and link that Inbound Opportunities to the 'Inbound Opportunity' field of this Internal Referral.
        */
      /* if(!newInternalRefMap.isEmpty())       {
           Account[] rAccts = [SELECT Id, (SELECT Id FROM Opportunities WHERE CreatedDate >= LAST_N_DAYS:90  and NSS_Source__c LIKE 'Inbound%' ORDER BY CreatedDate DESC) FROM Account WHERE Id IN :newInternalRefMap.keySet()];
           for(Account rAcct : rAccts)  {
               Referral__c[] refs = newInternalRefMap.get(rAcct.Id);
               for(Referral__c ref : refs)  {
                   for(Opportunity opp : rAcct.Opportunities)   {
                       ref.Inbound_Opportunity__c = opp.Id;
                       break;
                   }
               }
           }
*/
        if(!newInternalRefMap.isEmpty()&& soarRefsList!=null){

         Opportunity[] opps = [SELECT Id, AccountId, ReferralLookup__c, ReferralLookup__r.Referral_Partner__c
                                 ,ReferralLookup__r.Referral_Partner__r.Referral_Product_Type__c, ReferralLookup__r.Primary__c
                                 FROM Opportunity 
                                 WHERE AccountId IN :newInternalRefMap.keySet() and CreatedDate >= LAST_N_DAYS:90 
                                             and NSS_Source__c LIKE 'Inbound%' and ReferralLookup__r.Primary__c=true ORDER BY CreatedDate DESC];
         if(!opps.isEmpty() && opps!=null){
            for(Referral__c ref: soarRefsList){
               for(Opportunity opp : opps){
                  if(opp.ReferralLookup__c!=null){
                     ref.Inbound_Opportunity__c = opp.Id;  
                     break; 
                  }         
               } 
            } 
         }
      }
   } // handleBeforeActions
   
   public static void handleAfterActions() {
      // to prevent recursion
      SKIP_TRIGGER = true;
      
      system.debug('handleAfterActions refTrackerList='+refTrackerList.size()+' refOwnerSyncList='+refOwnerSyncList.size()+' refApprovedIds='+refApprovedIds.size());
      if (!refTrackerList.isEmpty()){
         ReferralMethods.manageTransferTrackingAfter(refTrackerList);
         refTrackerList.clear();
      }
      
      if (!refApprovedIds.isEmpty()) {
         ReferralMethods.handleApproved(refApprovedIds);
         refApprovedIds.clear();
      } // if (!refApprovedIds.isEmpty
      system.debug('handleAfterActions refApprovedIds='+refApprovedIds.size());
       
      if (!refRejectedIds.isEmpty()) {
         ReferralMethods.handleRejected(refRejectedIds);
         refRejectedIds.clear();
      } // if (!refRejectedIds.isEmpty
      
      if (!refByAcctIdMap.isEmpty()) {
         checkForAcctsToUpdate();
      }
      
      if (!refsByOppIdMap.isEmpty()) {
         updateOppsForPayment();
      }
      
      if (!refOwnerSyncList.isEmpty()){
         ReferralMethods.checkSyncRelatedOwners(refOwnerSyncList);
         refOwnerSyncList.clear();
      }
       if (!checkOppDsaLookup.isEmpty()) {
          ReferralMethods.updateDSAOpptyRefJoin(checkOppDsaLookup,1);
          checkOppDsaLookup.clear();
       }

      skipRelatedOwnerUpdateSet.clear();
   } // handleAfterActions
   
   public static void checkForPreviousReferrals() {
      Referral__c[] prevRefs = [Select Id, Account__c, SourceContact__c, SourceLead__c, LatestReferral__c
                              From Referral__c
                             Where LatestReferral__c = true
                               and (Account__c in :latestRefMap.keySet() or SourceLead__c in :latestRefMap.keySet())];
      System.debug('checkForPreviousReferrals prevRefs='+prevRefs.size());
      // update all returned referrals to false
      if (!prevRefs.isEmpty()) {
         for (Referral__c ref : prevRefs) {
            ref.LatestReferral__c = false;
         }
         ReferralTriggerActions.SKIP_TRIGGER = true;
         DmlHelper.performDML2(prevRefs, DmlHelper.DML_UPDATE, 'ReferralTriggerActions', 'checkForPreviousReferrals', 'set LatestReferral__c to false', true);
         ReferralTriggerActions.SKIP_TRIGGER = false;
      }
      // set the flag to true on the referrals passed in
      for (Referral__c[] refs : latestRefMap.values()) {
         System.debug('checkForPreviousReferrals setting to true refs='+refs.size());
         // if more than one at a time we'll make the first the latest. Rest will remain false.
         refs[0].LatestReferral__c = true;
      }
      latestRefMap.clear();
   } // checkForPreviousReferrals
   
   // if the branch-client and/or fed id are populated on the opportunity, update the account if we don't already have those values.
   public static void checkForAcctsToUpdate() {
      Account[] accts = [Select Id, AccountNumber, Federal_ID_Number__c from Account where Id in :refByAcctIdMap.keySet()];
      Account[] acctsChanged = new Account[]{};
      
      for (Account acct : accts) {
         Boolean acctChanged = false;
         Referral__c[] refList = refByAcctIdMap.get(acct.Id);
         if (refList != null) {
            for (Referral__c ref : refList) {
               if (String.isNotBlank(ref.BranchClientNumber__c) && String.isBlank(acct.AccountNumber)) {
                  acct.AccountNumber = ref.BranchClientNumber__c; // TODO - format number!
                  acctChanged = true;
               }
               if (String.isNotBlank(ref.FedIdNumber__c) && String.isBlank(acct.Federal_ID_Number__c)) {
                  acct.Federal_ID_Number__c = ref.FedIdNumber__c;
                  acctChanged = true;
               }
            } // for (Opportunity opp
         } // if (oppList != null
         if (acctChanged) {
            acctsChanged.add(acct);
         }
      } // for (Account acct
      
      if (!acctsChanged.isEmpty()) {
         DmlHelper.performDML(acctsChanged, DmlHelper.DML_UPDATE, 'ReferralTriggerActions', 'checkForAcctsToUpdate', 'update accts from ref', true);
      }
   } // checkForAcctsToUpdate

   public static void updateOppsForPayment() {
      Opportunity[] oppsToUpdate = new Opportunity[]{};
      for (Opportunity opp : [Select Id
                                    ,Of_Employees__c
                                    ,Actual_Revenue__c
                                    ,BranchClientNumber__c
                                    ,Disposition__c
                                    ,FedIdNumber__c
                                    ,Month_Sale_Reported__c
                                    ,Pending_Run_Of_Payroll__c
                                    ,ReferralLookup__c
                                From Opportunity
                               Where Id in :refsByOppIdMap.keySet()]) {
         Referral__c ref = refsByOppIdMap.get(opp.Id);
         if (ref != null &&
                (ref.Id != opp.ReferralLookup__c
                 ||ref.NbrOfEmployees__c != opp.Of_Employees__c
                 || ref.ActualRevenue__c != opp.Actual_Revenue__c
                 || ref.BranchClientNumber__c != opp.BranchClientNumber__c
                 || ref.Disposition__c != opp.Disposition__c
                 || ref.FedIdNumber__c != opp.FedIdNumber__c
                 || ref.MonthSaleReported__c != opp.Month_Sale_Reported__c
                 || ref.PendingRunOfPayroll__c != opp.Pending_Run_Of_Payroll__c)
             ) {
            oppsToUpdate.add(opp);
            opp.ReferralLookup__c = ref.Id;
            opp.Of_Employees__c = ref.NbrOfEmployees__c;
            opp.Actual_Revenue__c = ref.ActualRevenue__c; 
            opp.BranchClientNumber__c = ref.BranchClientNumber__c; 
            opp.Disposition__c = ref.Disposition__c;
            opp.FedIdNumber__c = ref.FedIdNumber__c;
            opp.Month_Sale_Reported__c = ref.MonthSaleReported__c;
            opp.Pending_Run_Of_Payroll__c = ref.PendingRunOfPayroll__c;
         } // if (ref != null
                                   
      } // for (Opportunity opp
      
      if (!oppsToUpdate.isEmpty()) {
         // don't let the opportunity triggers fire
         OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
         DmlHelper.performDML2(oppsToUpdate, DmlHelper.DML_UPDATE, 'ReferralTriggerActions', 'updateOppsForPayment', 'update opps from ref', true);
         OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      }
   } // updateOppsForPayment
   
   
} // class ReferralTriggerActions