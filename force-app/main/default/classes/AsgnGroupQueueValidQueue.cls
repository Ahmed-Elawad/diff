/* 
 * Validate the name equals a queue name and to populate the id.
 *
 * History
 * -------
   08/19/2011 Dan Carmen        Created
   03/31/2015 Dan Carmen        Change to without sharing
   10/26/2018 Dan Carmen        Increment API to version 44

 */
public without sharing class AsgnGroupQueueValidQueue {

   /** Set the queue ids on the incoming records.
    */
   public static void setQueueIds(Assignment_Group_Queues__c[] agqs) {
   	  // get all of the queue names
      Map<String,String> queueNames = new Map<String,String>();
      for (Assignment_Group_Queues__c agq : agqs) {
         queueNames.put(agq.Name,agq.Name);
      } // for
      
      // select queues based on the names
      Map<String,Group> queues = new Map<String,Group>();     //Queue name --> Queue
    
      for (Group[] grps :  [SELECT Name FROM Group WHERE Type= 'Queue' and Name in :queueNames.values()]) {
         for (Group grp : grps) {
            queues.put(grp.Name, grp);
         }
      } // for (Group[]

      // make sure there's not already an assignment group queue with the queue      
      Map<String,String> agNames = new Map<String,String> ();
      for (Assignment_Group_Queues__c[] checkAgqs : [SELECT Name, Assignment_Group_Name__r.Name
                                               FROM Assignment_Group_Queues__c 
                                              WHERE Active__c = 'True'
                                                and Name in :queueNames.values()]) {
          for (Assignment_Group_Queues__c agq : checkAgqs) {
             agNames.put(agq.Name, agq.Assignment_Group_Name__r.Name);
          }
      } // for (Assignment_Group_Queues)

      //Find Queues matching on name
      for (Assignment_Group_Queues__c agq : agqs) {
         if (queues.containsKey(agq.Name)) {
            Id qId = queues.get(agq.Name).Id;
            System.debug('>>>>>Queue Id for name ' + agq.Name + ': '+qId);
            
            //Check if Queue is already assigned to an Assignment_Group_Queues__c record
            if (agNames.containsKey(agq.Name)) {
                agq.Valid_Queue__c = false;
                agq.addError('Queue "'+agq.Name+'" already assigned to another Assignment Group "'+agNames.get(agq.Name)+'".');
            } else {
                agq.QueueId__c = qId;
                agq.Valid_Queue__c = true;
            }
         } else {
            //Error: queue not found
            agq.Valid_Queue__c = false;
            agq.addError('Invalid Queue name: Queue name ' + agq.Name + ' cannot be found.');
         }   
      } // for (Assignment_Group_Queues__c


   } // setQueueIds
   
} // class AsgnGroupQueueValidQueue