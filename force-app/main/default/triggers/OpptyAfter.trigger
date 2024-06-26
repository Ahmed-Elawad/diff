/* 
   Handle all of the "After" trigger actions.
   1) If a Referral Contact is added to an Opportunity, link the Referral Account to the Opportunity, and if the lead source is CPA, set
      the referral contact on the Account also (CPA_Name_Ref__c)
   2) If an Opportunity is moved to sold, check if we will be creating a Case for it.
   3) If the Opportunity status or close date changes, update the opportunity line items with the new information
   4) When an Opportunity is created, set the default products on it.
   
  History
  -------
  12/21/2012 Dan Carmen   Created from
                               OpptyCheckReferral
                               OpptyCheckStatus
                               OpptyProducts
  04/05/2013 Cindy Freeman  modified to send all Sold opportunities with Object Relationship definition to CreateRelatedObjects class 
  07/10/2013 Cindy Freeman  modified check of opportunity record types against Object Relationship definitions
  11/19/2013 Dan Carmen     Added logic to add NSR to opportunity if in a commissionable stage
  04/12/2015 Dan Carmen     Added extra check for account id when checking for update to account.
  08/06/2015 Dan Carmen     Fix for default products not being created.
  09/01/2015 Dan Carmen     Added additional criteria for checking the referral contact linkage on the account.
  09/10/2015 Cindy Freeman   Added logic to update Hold Out expiration date when opty is marked Sold
  09/14/2016 Dan Carmen     Add ability to skip the triggers.
  09/21/2016 Jermaine Stukes Added logic to update account record type if NSS Opp/Core Acct or vise versa
  11/18/2016 Jacob Hinds    When an opportunity goes not sold, check account to see if it needs the profiled expiration date to be set.
  01/05/2017 Jacob Hinds    Removing the profiled changes listed above.
  03/07/2017 Lynn Michels   If Opp moves to Not Sold or Pending, send them all to be processed 
  01/23/2018 Dan Carmen     Change criteria for checking account link info.
  02/15/2018 Lynn Michels   if an MMS, HNBF, or ASO Opportunity went sold and has a FLEX Benefits Administration Essentials product,
                            send id to OpportunityCreateCase to see if it fits criteria to create BenAdmin Case
  05/03/2018 Sunnish Annu   Adding Target Field update when an MMS opportunity Recordtype is created                        
  05/07/2018 Lynn Michels   made changes for HNBF opportunitites to create the BenAdmin cases. Status used is 'Picked Up'
  07/03/2018 Lynn Michels	 add critiera for PC Onboarding Opportunities 
  09/07/2018 Dan Carmen     Remove updates to the account from this trigger - OpptyMethods.setLatestOpps
  09/21/2018 Jake Hinds		Add lead source change to opptychkreferral
  07/26/2019 Dan Carmen     Add additional criteria for checking products
  06/01/2020 Dan Carmen     Move logic for HoldOutExpirationMethods to Interface
  12/02/2020 Dan Carmen     Move logic for OpptyMethods to Interface
  01/18/2020 Pradeep Garlapaati  Wrote logic to create oppty TeamMember demoed in last 12 months from all oppy of that prospect when new oppty is created. 
  05/19/2021 Dan Carmen     Updated to use Probability to check if a sold status.
  02/06/2024 Carrie Marciano	added logic to call CreateRelatedObjects2.processSObjects on insert of Huckleberry opportunity with OppSource = 'Huckleberry Clone'
  
 */
trigger OpptyAfter on Opportunity (after insert, after update) {
   System.debug('OpptyAfter OpptyMethods.SKIP_OPPTY_TRIGGER='+OpptyMethods.SKIP_OPPTY_TRIGGERS);
   if (OpptyMethods.SKIP_OPPTY_TRIGGERS) {
      return;
   }
   
   // for the records that were just marked as sold
   Id[] soldOpptyIds = new Id[]{};
   // for the records that were sold, and are not Not Sold
   Id[] noLongerSoldIds = new Id[]{};
   // for the records that may need related object created
   SObject[] soldTriggerRcds = new SObject[]{};
      
   // check to update the status of the products to match the opportunity
   Id[] opptyStatusIds = new Id[]{};
   // for records that we need to add a default product for
   Id[] setDefaultProductIds = new Id[]{};
   
   // If a large market opportunity, we want to check/set the sales team
   // only set when value is initially set in the field
   Id[] checkLargeMarketSalesTeamId = new Id[]{};
    
   //Check NSS records to sync Account Record Type
   Id[] oppIdsToCheckRT = new Id[]{};
         
   // when an opportunity is created, see if there's an ownership record that's in the commissionable phase for the opportunity type
   Opportunity[] checkNSRSalesTeam = new Opportunity[]{};
   // the opportunities we are checking to see if we need to add an audit record
   Opportunity[] oppsToCheckForNSSAudit = new Opportunity[]{};
   
   Map<Id,Opportunity> acctOppsOldMap = new Map<Id,Opportunity>();
   
   // do not check for default products if Relational Junction user.
   Boolean checkDefaultProds = !UserHelper.isRelationalJunction(UserInfo.getName());
   
   TriggerMethods.checkBeforeLoop('OpptyAfter', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
   
   ID mmsOppRecordTypeId = RecordTypeHelper.getRecordType('MMS Opportunity Record Type','Opportunity').getRecordTypeId();
   
   public static set<Id> AllNewOpptyListAccountIds = new set<Id>();

   public static list<opportunity> AllNewOpptyList = new list<opportunity>();

   /**BAU Changes**/
   Map<Id,Id> mapOpportunityidAccountid=new Map<Id,Id>();
   /**BAU Changes**/
    
    for ( Opportunity newOppty: Trigger.new) {
      // get the old record
      Opportunity oldOppty = (Trigger.isUpdate ? (Opportunity)Trigger.oldMap.get(newOppty.Id) : null);
      TriggerMethods.checkInLoop('OpptyAfter', newOppty, oldOppty, Trigger.IsBefore, Trigger.IsAfter);
      System.debug('OpptyAfter opp='+newOppty.Name);
      if (Trigger.isInsert) {
        
         // if no line items (there shouldn't be on insert) we'll add them
         // check the OpportunityId to determine if it's a cloned record
         System.debug('checkDefaultProds='+checkDefaultProds+' newOppty.Pricebook2Id='+newOppty.Pricebook2Id+' HasOpportunityLineItem='+newOppty.HasOpportunityLineItem+' OpportunityId__c='+newOppty.OpportunityId__c);
         if (checkDefaultProds && /*newOppty.Pricebook2Id == null &&*/ !newOppty.HasOpportunityLineItem &&
             ((newOppty.OpportunityId__c == null) ||
              (newOppty.OpportunityId__c == OpptyCheckFields.OPP_NEW) || 
              (newOppty.OpportunityId__c != null && newOppty.Id != null && newOppty.OpportunityId__c == (String)newOppty.Id))) {
            System.debug('OpptyAfter add to setDefaultProductIds');
            setDefaultProductIds.add(newOppty.Id);
         }

         if (newOppty.Zip_Tier__c != null && newOppty.Zip_Tier__c == OpptyCheckFields.LARGE_MARKET) {
            checkLargeMarketSalesTeamId.add(newOppty.Id);
         }
         
         // check all inserted opportunities
         checkNSRSalesTeam.add(newOppty);
         
         //Sync Account record type for NSS
         if(String.isNotBlank(newOppty.NSS_Source__c) && newOppty.OpportunityType__c == OpptyMethods.Opp_TYPE_PAY){           
             oppIdsToCheckRT.add(newOppty.Id);
         } 
          
          if(newOppty.AccountId != null){
              AllNewOpptyListAccountIds.add(newOppty.AccountId);
              AllNewOpptyList.add(newOppty);
              /**BAU Changes**/
              mapOpportunityidAccountid.put(newOppty.Id,newOppty.AccountId);
              /**BAU Changes**/
          }       

         //for PC Onboarding Opportunity, when opp reaches 40% probability
         system.debug('OpptyAfter isInsert newOppty.Probability: '+newOppty.Probability);
         system.debug('OpptyAfter isInsert newOppty.OppSource__c: '+newOppty.OppSource__c);
         ID pcOppRecordTypeId = RecordTypeHelper.getRecordType('PC Opportunity Record Type','Opportunity').getRecordTypeId();
         system.debug('OpptyAfter isInsert newOppty.RecordTypeId: '+newOppty.RecordTypeId+' pcOppRecordTypeId: '+pcOppRecordTypeId);
         if (newOppty.RecordTypeId == pcOppRecordTypeId && newOppty.Probability >= 40 && newOppty.OppSource__c == 'Huckleberry Clone'){
         		soldTriggerRcds.add(newOppty);
                system.debug('OpptyAfter isInsert add oppty to soldTriggersRcds: '+soldTriggerRcds.size());
         }
         
      } else if (Trigger.isUpdate) {
         // get recordtype info
         Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordTypeById(newOppty.RecordTypeId, 'Opportunity');
         
         //for PC Onboarding Opportunity, when opp reaches 40% probability
         system.debug('OpptyAfter isUpdate newOppty.OppSource__c: '+newOppty.OppSource__c);
         system.debug('OpptyAfter isUpdate newOppty.Probability: '+newOppty.Probability+' oldOppty.Probability: '+oldOppty.Probability);
         system.debug('OpptyAfter isUpdate newOppty.StageName: '+newOppty.StageName+' oldOppty.StageName: '+oldOppty.StageName);
         ID pcOppRecordTypeId = RecordTypeHelper.getRecordType('PC Opportunity Record Type','Opportunity').getRecordTypeId();
         if (newOppty.RecordTypeId == pcOppRecordTypeId && (newOppty.StageName != oldOppty.StageName) && newOppty.Probability >= 40 && oldOppty.Probability < 40){ 
         		soldTriggerRcds.add(newOppty);
                system.debug('OpptyAfter isUpdate add oppty to soldTriggersRcds: '+soldTriggerRcds.size());
         }
         
         // do not trigger because of task or event id changing
         // THIS IS BECAUSE OF THE NSR STATUS BACK EMAIL WORKFLOW.
         // WE NEED TO FIGURE OUT A WAY AROUND THIS.
         //if (checkIds.contains(newOppty.RecordTypeId) &&
         if ((newOppty.Task_Id__c == oldOppty.Task_Id__c) &&
             (newOppty.Event_Id__c == oldOppty.Event_Id__c)) {
                
            // if the StageName or CloseDate changes and the Opportunity has line items
            if (newOppty.HasOpportunityLineItem && (newOppty.StageName != oldOppty.StageName ||
                                                    newOppty.CloseDate != oldOppty.CloseDate)) {
               // check the stage/close date of products to make sure they match
               opptyStatusIds.add(newOppty.Id);
            }

            // make sure the stage has changed and current stage is sold
            // and opportunity is of correct record type
            //LM added criteria for HNBF opps bc their DSAs use "Picked Up" status
            //if (soldRTIds.contains(newOppty.RecordTypeId) &&
            if ( newOppty.Service_Location__c != null &&
                (newOppty.StageName != oldOppty.StageName) &&
                ((newOppty.Probability >= 80 && newOppty.Probability < 100) ||
                (rt.getName() == OpportunityCreateCase.RT_OPPTY_HNBF && newOppty.StageName == 'Picked Up'))){
                    
                 /*LM commented out. OpportunityCreateCase.SOLD_STATUS_SET.contains(newOppty.StageName) &&
                 (newOppty.StageName != oldOppty.StageName)) {*/
                 
                    system.debug('OpptyAfter before CreateRelatedObjects2.getObjRelOptyRcdTypes');                    
                    if (CreateRelatedObjects2.getObjRelOptyRcdTypes().contains(newOppty.RecordTypeId)){
                        soldTriggerRcds.add(newOppty);
                        system.debug('OpptyAfter soldTriggerRcds: '+soldTriggerRcds.size());
                    }
                    else {
                        soldOpptyIds.add(newOppty.Id);  
                        system.debug('OpptyAfter soldOpptyIds: '+soldOpptyIds.size());
                    } 
                    
                    //if an MMS, HNBF, or ASO Opportunity went sold and has a FLEX Benefits Administration Essentials product 
                   if((rt.getName() == OpportunityCreateCase.RT_OPPTY_ASO ||
                        rt.getName() == OpportunityCreateCase.RT_OPPTY_MMS ||
                        rt.getName() == OpportunityCreateCase.RT_OPPTY_HNBF) &&
                        newOppty.Product_Summary__c != null &&
                        newOppty.Product_Summary__c.contains('FBAE;'))
                    {  system.debug('LM HNBF, MMS, ASO');
                        system.debug('LM - ' + rt.getName() + ', stage '+newOppty.StageName+ ' , product '+newOppty.Product_Summary__c); 
                        soldOpptyIds.add(newOppty.Id);  }
            
//             } else if (OpportunityCreateCase.SOLD_STATUS_SET_MPSC.contains(oldOppty.StageName) &&
//                       OpportunityCreateCase.NO_LONGER_SOLD_SET.contains(newOppty.StageName)) {
             } else if (oldOppty.Probability >= 80 && newOppty.Probability < 80) {
                        
                        //LM pass all opps and sort based on criteria in OpportunityCreateCase.cls 
                        noLongerSoldIds.add(newOppty.Id); 
             
            
            } // if (soldOpptyIds.contains
            
            // for large market opportunities - only check when changed to that value.
            if (newOppty.Zip_Tier__c != null && newOppty.Zip_Tier__c == OpptyCheckFields.LARGE_MARKET && newOppty.Zip_Tier__c != oldOppty.Zip_Tier__c) {
               checkLargeMarketSalesTeamId.add(newOppty.Id);
            } // if (newOppty.Zip_Tier__c
            
         } // if ((newOppty.Task_Id__c == oldOppty.Task_Id__c

         if (newOppty.StageName != oldOppty.StageName && OpptyMethods.AUDIT_STAGENAMES.contains(newOppty.StageName)) {
            oppsToCheckForNSSAudit.add(newOppty);
         } 

      } // if (Trigger.isInsert

   } // for

   TriggerMethods.checkOutsideLoop('OpptyAfter', Trigger.isBefore, Trigger.isAfter);
   
   System.debug('OpptyAfter opptyStatusIds='+opptyStatusIds.size()+' setDefaultProductIds='+setDefaultProductIds.size());

   // update line items to match opportunity close date and stage   
   if (!opptyStatusIds.isEmpty()) {
      OpptyProducts.checkOpptyAndProductStatus(opptyStatusIds);
   }
   
   // set default products on insert of an opportunity
   if (!setDefaultProductIds.isEmpty()) {
      OpptyProducts.addDefaultOpptyLineItem(setDefaultProductIds);
   }

   // if it's a large market opportunity set the sales team
   if (!checkLargeMarketSalesTeamId.isEmpty()) {
      OpptyCheckFields.checkForSalesTeam(checkLargeMarketSalesTeamId);
   } // if (!checkLargeMarketSalesTeamId
   
   // check if we need to create a case thru OpportunityCreateCase process
   if (!soldOpptyIds.isEmpty()) {
      OpportunityCreateCase.processOpptysSold(soldOpptyIds);
   }

   // check if we need to create a case thru CreateRelatedObjects process
   if (!soldTriggerRcds.isEmpty()) {
      CreateRelatedObjects2.processSObjects('Opportunity',soldTriggerRcds);
   }
   
   // if moving from sold to pending or not sold, see if there are cases we need to delete
   //LM - pass all ids and sort record types later
   if (!noLongerSoldIds.isEmpty()) {
      OpportunityCreateCase.processStageChangedFromSold(noLongerSoldIds); 
   } // if
   
   // check if we need to add an NSR to the sales team 
   if (!checkNSRSalesTeam.isEmpty()) {
      OpptyMethods.checkSalesTeamforNSR(checkNSRSalesTeam);
   } // if (!checkNSRAcctTeamIds
   
   if (!oppsToCheckForNSSAudit.isEmpty()) {
      OpptyMethods.checkForNSSAudit(oppsToCheckForNSSAudit);
   }
   
   if(!oppIdsToCheckRT.isEmpty()){
      SyncAcct.checkAfterTrigger(oppIdsToCheckRT);
   }
   
   if(!AllNewOpptyListAccountIds.isEmpty()){
      /**BAU Changes**/
      if(mapOpportunityidAccountid!=null && !mapOpportunityidAccountid.isEmpty()){
         List<OpportunityTeamMember> lstOTMs=OpptyMethods.CreateSDROppTeamMmembers(mapOpportunityidAccountid);
         if(lstOTMs!=null && !lstOTMs.isEmpty()){
            OpptyMethods.InsertOTMs(lstOTMs);
         }
      }
      /**BAU Changes**/
      OpptyMethods.CreateOppTeamMmembers(AllNewOpptyListAccountIds,AllNewOpptyList);
   }

   // if we're not running a test set the flag to not trigger again.
   OpptyMethods.SKIP_OPPTY_TRIGGERS = (!Test.isRunningTest());
    
} // trigger OpptyAfter