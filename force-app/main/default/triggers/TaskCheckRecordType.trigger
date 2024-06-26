/** Check the record type of the record and make sure it is correct.
 *
 * History
 * -------
 * 02/16/2011 Dan Carmen        Created.
   08/04/2011 Dan Carmen        Fix NullPointerException
   07/11/2014 Leslie Hogan      Changed default values for Lead_Source_WAR_Call_type & Type
   10/26/2018 Dan Carmen        Increment API version - not sure that we actually need this anymore

 */
trigger TaskCheckRecordType on Task (before insert) {

   // the tasks to check further
   Task[] tasks = new Task[]{};
   
   for ( Task rec: Trigger.new) {
      // Only proceed if the owner is different than the creator and
      // the subject is for a follup up 
      if ((rec.Subject == '90-Day Follow up' || rec.Subject == '60-Day Follow up' || rec.Subject == '30-Day Follow up') &&
          (rec.WhatId != null && ((String)rec.WhatId).startsWith('006'))
         ) {
         // always set the call type
         rec.Lead_Source_WAR_Call_Type__c = 'Current Client Call';
         rec.Type = 'Call';
         
         // if the owners don't match, process further
         if (rec.CreatedById != rec.OwnerId ) {
            tasks.add(rec);
         }
      } // if ((
   } // for

   if (!tasks.isEmpty()) {
      TaskCheckRecordType.checkTasks(tasks);
   } // if (!tasks
   
} // trigger TaskCheckRecordType