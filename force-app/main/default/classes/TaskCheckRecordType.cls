/** Check the record type of the record and make sure it is correct.
 *
 * History
 * -------
 * 02/16/2011 Dan Carmen        Created.
   10/26/2018 Dan Carmen        Increment API version - not sure that we actually need this anymore

 */
public with sharing class TaskCheckRecordType {

   public static void checkTasks(Task[] tasks) {
   	  // only handle Core tasks right now. Use a set to prevent duplicates
   	  Set<Id> ownerIdSet = new Set<Id>();
   	   
   	  for (Task t : tasks) {
   	  	 ownerIdSet.add(t.OwnerId);
   	  } // for (Task t
   	  
   	  Map<Id,User> ownerMap = new Map<Id,User>([Select Id, Sales_Org__c from User where Id in :ownerIdSet]);
   	  
   	  Schema.Recordtypeinfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_TASK, 'Task');
   	  
   	  // if the owner is a core rep, but it is not a core record type, update that.
   	  for (Task t : tasks) {
         User u = ownerMap.get(t.OwnerId);
         if (u != null && u.Sales_Org__c == UserHelper.SO_CORE) {
            t.RecordTypeId = coreRT.getRecordTypeId();
         }
   	  } // for (Task t
   	  
   } // checkTasks

} // class TaskCheckRecordType