/* 
 * Actions on the Zip Assignment object
 *
 * History
 * -------
 * 04/20/2012 Dan Carmen   Created
   06/20/2012 Dan Carmen   Added new criteria for checking the User.
   08/22/2012 Dan Carmen   Added criteria for checking org structure
   12/12/2012 Dan Carmen   Added asset criteria
   03/22/2013 Dan Carmen   Change to always check the org structure
   10/22/2014 Dan Carmen   Cleaned up code due to NSS coming into Salesforce
   02/08/2016 Dan Carmen   Clean up checkUseCriteria
   01/19/2017 Dan Carmen   Changed criteria for delete to check in the before and run in the after
   06/21/2019 Dan Carmen   Changes for evaluating the criteria
   03/30/2020 Dan Carmen   Move logic to the ZipAssignment class
   05/25/2021 Dan Carmen   Increment the API version
   09/27/2023 Dan Carmen   Increment the API version

*/
trigger ZipAssignment on Zip_Assignment__c (before insert, before update, after insert, after update, before delete, after delete) {
   System.debug('ZipAssignment trigger ZipAssignment.SKIP_TRIGGER='+ZipAssignment.SKIP_TRIGGER);
   if (ZipAssignment.SKIP_TRIGGER) {
      return;
   }
    
   new ZipAssignment().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
   
} // trigger ZipAssignment