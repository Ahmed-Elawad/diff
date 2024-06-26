/* 
 * Actions on the Zip Code Information object
 *
 * History
 * -------
 * 09/17/2013 Dan Carmen   Created
   03/27/2015 Dan Carmen   Change how time zones are being set
   08/17/2018 Dan Carmen   Use Daylight Savings for Time Zone assignment
   12/30/2022 Dan Carmen   Increment API version
   03/04/2024 Dan Carmen   Move code to the apex class.

 */
trigger ZipCodeInformation on Zip_Code_Information__c (before insert, before update, after insert, after update) {

   new ZipCodeInformation().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter, Trigger.IsDelete);

} // trigger ZipCodeInformation