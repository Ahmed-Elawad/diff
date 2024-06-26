/* 
 * Actions on the Area Code Link object
 *
 * History
 * -------
 * 09/17/2013 Dan Carmen   Created
   03/30/2015 Dan Carmen   Trigger modification
 *
 */
trigger AreaCodeLink on AreaCodeLink__c (after insert, after update, after delete) {

   // gather the unique area code ids, perform calculations
   Set<Id> areaCodeIdSet = new Set<Id>();
   
   if (Trigger.isInsert || Trigger.isUpdate) {
      for (AreaCodeLink__c acl : Trigger.new) {
         areaCodeIdSet.add(acl.AreaCode__c);
   	}
   } else if (Trigger.isDelete) {
      for (AreaCodeLink__c acl : Trigger.old) {
         areaCodeIdSet.add(acl.AreaCode__c);
      }
   } // if (Trigger.isInsert
   
   System.debug('AreaCodeLink areaCodeIdSet='+areaCodeIdSet.size());
   if (!areaCodeIdSet.isEmpty()) {
      AreaCodeMethods.findTimeZones(areaCodeIdSet);
   }
   
} // trigger AreaCodeLink