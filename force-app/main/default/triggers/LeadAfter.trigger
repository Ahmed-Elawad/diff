/* 
 *  A trigger to handle after update/insert operations.
 *   
 * History
 * -------
 * 09/19/2012 Cindy Freeman     created
   10/02/2013 Dan Carmen        Added logic from LeadCheckContactRecordType trigger
   12/20/2013 Carrie Marciano   Added bank lead stuff
 * 04/01/2014 Cindy Freeman     Added check for DataFlux delta service
 * 04/21/2014 Cindy Freeman     Added check for DataFlux delta service converted leads 
 * 06/05/2014 Cindy Freeman     Added logic to set Significant Lead on Lead Company
   06/20/2014 Carrie Marciano   Added code for ChatterPost on new SurePayroll leads
   11/09/2015 Dan Carmen         Modifications for new Chatter code.
   04/27/2016 Carrie Marciano   Updated SurePayroll criteria to match Status changes made to Lead Process 
   01/04/2017 Josh Cartwright new code to send insert vs update action to datafluxDelta Service
   01/20/2017 Dan Carmen   Add call to TriggerMethods
   04/05/2017 Cindy Freeman     Added call to LeadConvertMethods to push converted Lead employees to correct field on Account
   05/11/2017 Dan Carmen      Add additional call to TriggerMethods
   04/15/2018 Dan Carmen         Remove leadCreatorMap - not being used.
   06/25/2018 Cindy Freeman      Added call to LeadMethods.checkOwnedBy for PEOC ownership
   09/07/2018 Jacob Hinds     Merging DNC code
   09/21/2018 Dan Carmen         Added extra debug statement
   10/11/2018 Jacob Hinds     Re-mergine DNC code that got overwritten
   12/31/2018 Dan Carmen         Move DNC code to DNCHelper
   02/11/2019 Dan Carmen         Use UserHelper method for runningUser
   10/24/2019 Dan Carmen        Move all LatestCampaign__c code to CampaignMethods
   09/15/2020 Dan Carmen        Change dataflux checks.
   04/13/2021 Brandon Vidro    Added call to LeadMethods.handleReferralOwershipDriftLeads
   11/13/2021 Reetesh Pandey    Change for Chatter Notification to surepayRoll Lead owner SFDC-8068
   09/26/2023 Pujitha Madamanchi   Close TP steps when DNC is set on Lead
   03/16/2024 Dan Carmen        Remove BankLeadSalesRepChatterPost and DataFluxDeltaService calls - added to TriggerInterface
 
 */

trigger LeadAfter on Lead (after insert, after update) {
   System.debug('LeadAfter LeadMethods.LEAD_AFTER_EXECUTING='+LeadMethods.LEAD_AFTER_EXECUTING);
   SObject[] recs = TriggerMethods.checkRecs('LeadAfter', Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, 'LeadBefore', Schema.SObjectType.Lead.fieldSets.LeadAfterFlds);
   if (recs == null || recs.isEmpty()) {
      System.debug('LeadAfter recs is empty');
      return;
   }
   Lead[] lds = (Lead[])recs;
   if (TriggerMethods.DISABLE_CHECKRECS && LeadMethods.LEAD_AFTER_EXECUTING) {
       return;
   }
   LeadMethods.LEAD_AFTER_EXECUTING = true;
    
   // leads that need to be sent to DataFlux delta service for new DataFlux id or because match code fields were updated
   List<Id> datafluxIdList = new List<Id>();
   List<Lead> dataFluxObjList = new List<Lead>();

   // the leads to check the contacts for.
   List<Id> convertedLeadIds = new List<Id>();
   
   // the leads to check if we need to create an NSS ownership record   
   Set<Id> checkForNSSOwnershipIds = new Set<Id>();
   // the ids of all the owners of leads we are checking
   Set<Id> allOwnerIds = new Set<Id>();
   // map from lead id to old ownerid
   Map<Id,Id> oldOwnerIdMap = new Map<Id,Id>();
    
   Map<Id, Lead> driftChatQueueLeads = new Map<Id, Lead>();
  
   // the ids where the dialed flag is set - have to do here in case it's an insert - we want to have the lead id
   Set<Id> dialedIsSet = new Set<Id>();
   Set<Id> ownerChangedSet = new Set<Id>();
   Set<Id> callDispositionSet = new Set<Id>();
   
   // product of interest changes - have to reevaluate ownership (if it already exists)
   Set<Id> leadIdsProdChanged = new Set<Id>();
   
   // the ids to check the owned by field for
   Set<Id> checkOwnedByIdSet = new Set<Id>();
   
   // if the call disposition field on the lead changes
   // has to be done on the after call because it could theoretically be called on an insert.
   List<Lead> callDispositionChangeLeads = new List<Lead>();
    
   Schema.RecordTypeInfo leadPendingRT = RecordTypeHelper.getRecordType('Pending Leads', 'Lead');

   Boolean isSysAdmin = UserHelper.isRunningUserSystemAdmin();
   Boolean isLeadLoader = UserHelper.isLeadLoader(UserInfo.getName());
   Boolean isSfdcData = UserHelper.isSfdcData(UserInfo.getName());
   Boolean isRelJunc = UserHelper.isRelationalJunction(UserInfo.getName());
   Map<Id,Lead> dncOldMap = new Map<Id,Lead>(); //Pujitha
   Map<Id,Lead> dncNewMap = new Map<Id,Lead>(); //Pujitha
   
   TriggerMethods.checkBeforeLoop('LeadAfter', lds, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
   
   for (Lead newL : lds) {
    
      if (!LeadMethods.leadIdsProcessed.contains(newL.Id)) {
         Lead oldL = (Trigger.isUpdate ? Trigger.oldMap.get(newL.id) : null);
             
         TriggerMethods.checkInLoop('LeadAfter', newL, oldL, Trigger.IsBefore, Trigger.IsAfter);
            
         // check for Converted Leads 
         if (Trigger.isUpdate) 
         {  LeadConvertMethods.checkAfterTrigger(newL, oldL);   }
         
         if (Trigger.isInsert && String.isNotBlank(newL.OwnedBy__c) && isLeadLoader) {
            checkOwnedByIdSet.add(newL.Id);
         }
          
         if (!newL.IsConverted && newL.Dialed__c) {
            dialedIsSet.add(newL.Id);
            checkForNSSOwnershipIds.add(newL.Id);
            if (String.isNotBlank(newL.DialedUserId__c)) {
               allOwnerIds.add(newL.DialedUserId__c);
            }
         }        
         if (Trigger.isUpdate) {
            //LeadCompanyMethods.checkForSignificanceRecalc(newL, oldL);
            if(newL.OwnerId != null && newL.OwnerId != Label.Drift_Chat_Queue_Id && oldL.OwnerId != null && oldL.OwnerId == Label.Drift_Chat_Queue_Id) {
                driftChatQueueLeads.put(newL.Id, newL);
            }
            if (newL.IsConverted && ((oldL != null) && (oldL.IsConverted != newL.IsConverted))) {
               convertedLeadIds.add(newL.Id);
               System.debug('**CMF ** LeadAfter, lead converted adding lead to converted DFlist '+newL.Id);               
            } // if (newL.IsConverted        
            System.debug('LeadAfter newL.OwnerId='+newL.OwnerId+' old='+(oldL != null ? oldL.OwnerId : null));
             
            // check all records where the ownership changes
            if (!LeadMethods.doNotCheckOwnedIdSet.contains(newL.Id) && !newL.IsConverted && oldL != null && oldL.OwnerId != newL.OwnerId) {
                System.debug('LeadAfter meets criteria to check ownership record');
                allOwnerIds.add(oldL.OwnerId); // I don't think we care about the old owner - but just because...
                allOwnerIds.add(newL.OwnerId);
                ownerChangedSet.add(newL.Id);
                checkForNSSOwnershipIds.add(newL.Id);
                oldOwnerIdMap.put(newL.Id,oldL.OwnerId);
            } else if (oldL != null && oldL.Products__c != newL.Products__c && !dialedIsSet.contains(newL.Id)) {
               // if the owner doesn't change but the products do change, evaluate the NSS Team to see if it changed
               // do not evaluate them again if already being dialed
               leadIdsProdChanged.add(newL.Id);
            } // if (oldL != null && oldL.OwnerId != newL.OwnerId
                            //If updated, and MSP send Chatter Post

            //Pujitha
            if(oldL!=null && (!oldL.DoNotCall && newL.DoNotCall) || (!oldL.HasOptedOutOfEmail && newL.HasOptedOutOfEmail) ){
               dncOldMap.put(oldL.Id, oldL);
               dncNewMap.put(newL.Id, newL);
            }
        } // if isUpdate
           else if (Trigger.isInsert) {
              if (newL.RecordTypeId != leadPendingRT.getRecordTypeId()
                   && String.isNotBlank(newL.LeadSource)) {
                     // Changed Reetesh SFDC-8068
                     if (newL.LeadSource.equals(Label.LeadSource_Internal_SurePayroll) && newL.status == 'New') {
                         String chatterText = ' You have received a new '+newL.Products__c+' referral from SurePayroll referral! Please see the Lead for full details.';
                         ChatterMentionPost.createChatterMentionPost(newL.id,((!String.isBlank(newL.OwnerId))?new Id [] {newL.OwnerId} : new Id [] {UserInfo.getUserId()}), new String[]{chatterText},true,true);                              
                     } 
             }
           } // if (Trigger.isInsert
           
         // if the value in the call disposition field changes
         if (String.isNotBlank(newL.NSSCallDisposition__c) 
             && (Trigger.isInsert || (Trigger.isUpdate && oldL != null && newL.NSSCallDisposition__c != oldL.NSSCallDisposition__c))) {
            callDispositionChangeLeads.add(newL);
            callDispositionSet.add(newL.Id);
         }
      } else  {         
         // they've already been through the trigger - don't need to process again
         System.debug('LeadAfter leadIdsProcessed contains the id '+newL.Id);
      } // if (!LeadMethods.leadIdsProcessed.contains(newL.Id

   } // for Trigger.new
                
   TriggerMethods.checkOutsideLoop('LeadAfter', Trigger.isBefore, Trigger.isAfter);
   
   // process converted leads
   LeadConvertMethods.processAfterTriggerActions(); 
     
   if (!convertedLeadIds.isEmpty()) {
      //User runningUser = [Select Id, Profile.Name from User where Id=:UserInfo.getUserId()];
      User runningUser = UserHelper.getRunningUser();
      // for NSS, we're going to override user default record types
      Boolean overrideRecordType = ((runningUser != null && runningUser.ProfileId != null) ? UserHelper.isNSSProfile(runningUser.Profile.Name) : false);
      LeadCheckContactRecordType.checkLeads(convertedLeadIds, overrideRecordType);
   }
   
   if (!leadIdsProdChanged.isEmpty()) {
      ProspectOwnershipMethods.evaluateLeadNSSTeam(leadIdsProdChanged);
   }
   if(!driftChatQueueLeads.isEmpty()) {
       LeadMethods.handleReferralOwnershipDriftLeads(driftChatQueueLeads);
   }
   
   if (!checkOwnedByIdSet.isEmpty()) {
      LeadMethods.checkOwnedBy(checkOwnedByIdSet);
   }
  
   ChatterMentionPost.checkPostFeedElements();
   
   if (!dialedIsSet.isEmpty() || !ownerChangedSet.isEmpty() || !callDispositionSet.isEmpty()) {
      LeadMethods.checkLeadAfterTrigger(dialedIsSet, ownerChangedSet, callDispositionSet);
   }
    
   if (!dialedIsSet.isEmpty())
   {        
      NSSMethods.checkDuplicatePhone(dialedIsSet, UserInfo.getUserId());
   }    
   if(!dncNewMap.isEmpty()){
      CadenceUpdate.closeTp(dncNewMap, dncOldMap, true, false);
   }
   
   // so the triggers only execute once and we don't break test methods
   if (Test.isRunningTest()) {
      LeadMethods.LEAD_AFTER_EXECUTING = false;
   }
} // trigger LeadAfter