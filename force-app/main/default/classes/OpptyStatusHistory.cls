/* 
 * Keep track of the status history of a record. Once we get a closed status then we'll close any previous open status. 
   Any status that is closed will have an end date of the same day (start = end)
 *
 * History
 * -------
   06/06/2017 Dan Carmen      Created
   07/17/2017 Dan Carmen      Link to previous status record
   04/23/2018 Dan Carmen      Change to log even closed statuses
   02/25/2019 Dan Carmen      Check for name length

 */
public without sharing class OpptyStatusHistory implements TriggerInterface {

   public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void checkBeforeTrigger(SObject newRec, SObject oldRec) {}
   
   public void processBeforeTriggerActions() {}
   
   public static Id[] oppStatusChangeIds = new Id[]{};
   public static Set<Id> oppIdsProcessed = new Set<Id>();
   
   public void checkAfterTrigger(SObject newRec, SObject oldRec) {
      // collect the ids of the opportunities on insert or on status change
      if (!oppIdsProcessed.contains(newRec.Id) && (oldRec == null || (oldRec != null && ((Opportunity)newRec).StageName != ((Opportunity)oldRec).StageName))) {
         oppStatusChangeIds.add(newRec.Id);
      }
   } // checkAfterTrigger
   
   public void processAfterTriggerActions() {
      if (!oppStatusChangeIds.isEmpty()) {
         if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
            processStatusChangeNow(oppStatusChangeIds);
         } else {
            processStatusChangeFuture(oppStatusChangeIds);
         }
      } // if (!oppStatusChangeIds
      oppIdsProcessed.addAll(oppStatusChangeIds);
      oppStatusChangeIds.clear();
   } // processAfterTriggerActions
   
   @future
   public static void processStatusChangeFuture(Id[] oppIds) {
      processStatusChangeNow(oppIds);
   } // processStatusChangeFuture
   
   public static Integer NAME_LENGTH=OpptyStatusHistory__c.Name.getDescribe().getLength();
   
   public static void processStatusChangeNow(Id[] oppIds) {
      System.debug('processStatusChangeNow oppIds='+oppIds.size());
      Opportunity[] opps = [Select Id, Name
                                  ,IsClosed
                                  ,LastModifiedDate
                                  ,StageName
                                  ,(Select Id, Name
                                          ,EndDate__c
                                          ,Opportunity__c
                                          ,PreviousStatus__c
                                          ,StartDate__c
                                          ,StageName__c
                                          ,StatusIsClosed__c
                                      From OpptyStatusHistories__r
                                     Where EndDate__c = null)
                              From Opportunity
                             Where Id in :oppIds];
      
      OpptyStatusHistory__c[] updateRecs = new OpptyStatusHistory__c[]{};
      OpptyStatusHistory__c[] insertRecs = new OpptyStatusHistory__c[]{};
      
      for (Opportunity opp : opps) {
         OpptyStatusHistory__c curOsh = null;
         // keep track of the previous to link to the new one.
         OpptyStatusHistory__c prevOsh = null;
         // loop through the existing history records, closing all that don't match the current status.
         // there should at most be one record, but just in case.
         for (OpptyStatusHistory__c osh : opp.OpptyStatusHistories__r) {
            if (osh.StageName__c != opp.StageName) {
               System.debug('processStatusChangeNow closing history for '+opp.Name+' StageName='+osh.StageName__c);
               // assume the last modified date is the date for the status
               osh.EndDate__c = opp.LastModifiedDate;
               if (prevOsh == null) {
                  prevOsh = osh;
               }
               updateRecs.add(osh);
            } else {
               curOsh = osh;
            }
         } // for (OpptyStatusHistory__c osh
         
         /*
         if (curOsh != null && !opp.isClosed) {
            // do nothing here - it's open and the opp is open. Shouldn't logically get here, but just in case...
         } else if (curOsh != null && opp.isClosed) {
            // shouldn't get here because we shouldn't be creating records on closed statuses. Adding just to cover all bases.
            curOsh.EndDate__c = opp.LastModifiedDate;
            updateRecs.add(curOsh);
         } else 
         */
         // this should be the only valid action we're doing here.
         if (curOsh == null) {
            System.debug('processStatusChangeNow creating history for '+opp.Name+' StageName='+opp.StageName);
            // create a new history record
            curOsh = new OpptyStatusHistory__c(Name=(String.isNotBlank(opp.Name) ? opp.Name.left(NAME_LENGTH) : null), Opportunity__c=opp.Id
                                               ,PreviousStatus__c = (prevOsh != null ? prevOsh.Id : null)
                                               ,StartDate__c=opp.LastModifiedDate, StageName__c=opp.StageName
                                               ,EndDate__c=(opp.IsClosed ? Datetime.now() : null)
                                               ,StatusIsClosed__c = opp.IsClosed
                                               );
            insertRecs.add(curOsh);
         }

      } // for (Opportunity opp
      
      DmlHelper.performDml2(updateRecs, DmlHelper.DML_UPDATE, 'OpptyStatusHistory', 'processStatusChangeNow', 'Update existing', false);
      DmlHelper.performDml2(insertRecs, DmlHelper.DML_INSERT, 'OpptyStatusHistory', 'processStatusChangeNow', 'Insert new', false);
      ErrorLog.checkSave();
   } // processStatusChangeNow

} // class OpptyStatusHistory