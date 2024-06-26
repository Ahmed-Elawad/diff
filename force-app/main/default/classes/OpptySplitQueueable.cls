/* 
 * Continue splitting an opportunity asynchronously if there are a lot of ids.
 *
 * History
 * -------
   05/23/2023 Dan Carmen       Created

*/
public without sharing class OpptySplitQueueable implements Queueable {
    
   public Id originalOppId;
   public Id quoteId;
   public Id[] acctIds;
   public Boolean cloneHandbookContact;
   public OpptySplitController.ResultWrapper results;
   
   public OpptySplitQueueable(Id p_originalOppId, Id p_quoteId, Id[] p_acctIds, Boolean p_cloneHandbookContact, OpptySplitController.ResultWrapper p_results) {
      originalOppId = p_originalOppId;
      quoteId = p_quoteId;
      acctIds = p_acctIds;
      cloneHandbookContact = p_cloneHandbookContact;
      results = p_results;
   } // OpptySplitQueueable

   public void execute(QueueableContext context) {
      OpptySplitController osc = new OpptySplitController(originalOppId, cloneHandbookContact, true);
      osc.handleSplitOpp(originalOppId, quoteId, acctIds, results);
   } // execute
    
   public static void launchQueueable(OpptySplitQueueable osq) {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(OpptySplitController.CLASSNAME);
      System.debug('launchQueueable acctIds='+osq.acctIds.size()+' abc='+abc);
      if (abc != null && abc.Active__c && !osq.acctIds.isEmpty()) {
         System.enqueueJob(osq);
      }
   } // launchQueueable
    
} // class OpptySplitQueueable