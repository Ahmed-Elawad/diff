/* Abstract class to allow us to run classes generically from a batch

  History
  -------
  09/05/2020 Dan Carmen        Created
  
 */
public Interface BatchControlInterface {

   // run the process from the batch
   boolean handleProcessCheck(PurgeControl__c pc, PurgeControlTracker__c pcd, Messaging.SingleEmailMessage[] emails, String[] processMsgs);
    
} // BatchControlInterface