/* 
 * Actions on the Zip Assignment object
 *
 * History
 * -------
   04/02/2020 Dan Carmen   Created
   03/25/2022 Dan Carmen   Increment API

*/
trigger ZipSegment on Zip_Segment__c (before insert, before update, after insert, after update, before delete, after delete) {

   if (ZipAssignment.SKIP_TRIGGER) {
      return;
   }
    
   new ZipAssignment().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);

} // trigger ZipSegment