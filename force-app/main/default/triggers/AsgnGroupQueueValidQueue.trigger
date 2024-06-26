/* 
 * Trigger to validate the name equals a queue name and to populate the id.
 *
 * History
 * -------
   08/19/2011 Dan Carmen        Created
 *
 */
trigger AsgnGroupQueueValidQueue on Assignment_Group_Queues__c (before insert, before update) {

   // the records to check
   Assignment_Group_Queues__c[] agqs = new Assignment_Group_Queues__c[]{};
   
   for (Assignment_Group_Queues__c agq : Trigger.new) {
      if (Trigger.isInsert) {
         agqs.add(agq);
      } else if (Trigger.isUpdate) {
      	 // if the name changes or Queue Id is null
         if ((agq.QueueId__c == null) || (agq.Name != Trigger.oldMap.get(agq.id).Name)) {
         	// clear out the queueId
         	agq.QueueId__c = null;
            agqs.add(agq);
         }
      } // if (Trigger
   } // for (Assignment_Group_Queues__c

   if (!agqs.isEmpty()) {
      AsgnGroupQueueValidQueue.setQueueIds(agqs);
      RoundRobin.clearAssignGroupQueueCache(); 

   }
} // AsgnGroupQueueValidQueue