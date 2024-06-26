/* 
 * Set deadlines on the opportunity if it's in a certain stage
 *
 * History
 * -------
   08/02/2018 Demand Gen       Created
   10/02/2018 Dan Carmen       Add in a Stage History record
   07/06/2020  Jacob Hinds         Added without sharing per PMD
   08/07/2020 Dan Carmen          Fix for the expiration dates calculating properly.
   01/30/2024 Dan Carmen          Comment out logic for setting the SLA date fields
   
 */
public without sharing class DG_OpportunityAcceptDeadline {
    @InvocableMethod(label='Add Accept Deadline' description='Set Accept Reminder and Deadline')
    public static void updateAcceptReminderDeadline(List<Opportunity> opportunities) {
      System.debug('updateAcceptReminderDeadline opportunities='+opportunities.size());
      /* commented out 1/30/2024
      List<Opportunity> updateOppList = new List<Opportunity>();
        
      checkDeadline(opportunities, updateOppList);
      DmlHelper.performDML(updateOppList, DmlHelper.DML_UPDATE, 'DG_OpportunityAcceptDeadline', 'updateAcceptReminderDeadline', 'Update accept deadline on opps', false);
      checkStageHistorySave();
      ErrorLog.checkSave();
      */
   } // updateAcceptReminderDeadline
   
   public static void checkStageHistorySave() {}
    public static void checkDeadline(Opportunity[] opps, Opportunity[] updateOppList) {}

   /* commented out 1/30/2024
   public static Stage_History__c[] histRecsToInsert = new Stage_History__c[]{};
   
   public static void checkStageHistorySave() {
      System.debug('checkStageHistorySave histRecsToInsert='+histRecsToInsert.size());
      if (!histRecsToInsert.isEmpty()) {
         for (Stage_History__c hist : histRecsToInsert) {
            // clear out the reference and put in the Id.
            System.debug('checkStageHistorySave Id='+(hist.Opportunity__r != null ? hist.Opportunity__r.Id : null));
            if (hist.Opportunity__r != null && hist.Opportunity__r.Id != null) {
               System.debug('checkStageHistorySave updating opportunity');
               hist.Opportunity__c = hist.Opportunity__r.Id;
               hist.Opportunity__r = null;
            }
         } // for
         DmlHelper.performDML(histRecsToInsert, DmlHelper.DML_INSERT, 'DG_OpportunityAcceptDeadline', 'updateAcceptReminderDeadline', 'Create Opp Stage History recs', true);
         histRecsToInsert.clear();
      }
   } // checkStageHistorySave
   
   public static void checkDeadline(Opportunity[] opps, Opportunity[] updateOppList) {
      
      // select the accounts to get the time zone information
      Set<Id> acctIdSet = new Set<Id>();
      for (Opportunity opp : opps) {
         if (opp.AccountId != null) {
            acctIdSet.add(opp.AccountId);
         }
      } // for (Opportunity opp
      
      System.debug('checkDeadline acctIdSet='+acctIdSet.size());
      
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, TimeZoneAbbrev__c from Account where Id in :acctIdSet and TimeZoneAbbrev__c != null]);
      
      for(Opportunity opp : opps) {
         Stage_SLA__mdt stageSLA = SLAHelperBatch.getStageSLA(ObjectHelper.OBJECT_OPPTY, opp.StageName);
         Opportunity updateOpp = (updateOppList == null ? opp : new Opportunity(Id=opp.Id, AcceptDeadlineRecalc__c=false, ProcessNotes__c=opp.ProcessNotes__c));
         if (stageSLA != null) {
            Stage_History__c stageHist = new Stage_History__c(Opportunity__c=opp.Id, New_Stage__c=opp.StageName, Opportunity__r=opp);
            Account acct = opp.AccountId != null ? acctMap.get(opp.AccountId) : null;
            BusinessHours busHours = DG_LMF_Service.getBusinessHours((acct != null ? acct.TimeZoneAbbrev__c : 'NoAcct'));
            String oppNotes = 'Found SLA information for Stage '+opp.StageName+' busHours='+(busHours != null ? busHours.Name : 'No BusinessHours!!');
            
            Datetime startTime = (opp.CreatedDate != null ? opp.CreatedDate : System.now());
            
            if (busHours != null && opp.Accept_Reminder_Deadline__c == null) { 
               Long calcTime = (Integer.valueOf(stageSLA.SAL_Minutes__c) * 60000);
               updateOpp.Accept_Reminder_Deadline__c = BusinessHours.add(busHours.Id,startTime, calcTime);
               oppNotes += '; Updated Reminder Deadline to '+updateOpp.Accept_Reminder_Deadline__c.format('M/d/yyyy H:mm:ss');
               stageHist.SLAMinutes__c = stageSLA.SAL_Minutes__c;
               stageHist.SLA_Deadline__c = updateOpp.Accept_Reminder_Deadline__c;
            }
            if (busHours != null && opp.Accept_Deadline__c == null) { 
               Long calcTime = (Integer.valueOf(stageSLA.Expiration_Minutes__c) * 60000);
               updateOpp.Accept_Deadline__c = BusinessHours.add(busHours.Id,startTime, calcTime);
               oppNotes += '; Updated Accept Deadline to '+updateOpp.Accept_Deadline__c.format('M/d/yyyy H:mm:ss');
               stageHist.ExpirationMinutes__c = stageSLA.Expiration_Minutes__c;
               stageHist.Expiration_Deadline__c = updateOpp.Accept_Deadline__c;
            }
            System.debug('updateAcceptReminderDeadline oppNotes='+oppNotes);
            SLAHelperBatch.addToOppNotes(updateOpp, oppNotes);
            
            SlaHelperBatch.addToHistNotes(stageHist, oppNotes);
            histRecsToInsert.add(stageHist);
         } else {
            System.debug('updateAcceptReminderDeadline Could not find SLA information for Stage '+opp.StageName);
            SLAHelperBatch.addToOppNotes(updateOpp, 'Could not find SLA information for Stage '+opp.StageName);
            
         } // if (stageSLA != null
         if (updateOppList != null) {
            updateOppList.add(updateOpp);
         }
      } // for(Opportunity opp

   } // checkDeadline
    
    */    
} // class DG_OpportunityAcceptDeadline