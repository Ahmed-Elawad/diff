/* 
  Trigger for actions performed on the Zip Territory object.
     
  History
  -------
  01/31/2014 Dan Carmen   Created
  03/31/2015 Cindy Freeman    did the override assistant or manager change?
  04/28/2015 Dan Carmen   Added actions on insert
  05/25/2021 Dan Carmen   Moved logic to ZipTerritoryMethods
   
 */
trigger ZipTerritory on ZipTerritory__c (before update, after update, before insert, after insert) {
   System.debug('ZipTerritory ZipTerritoryMethods.SKIP_TRIGGER='+ZipTerritoryMethods.SKIP_TRIGGER);
   if (ZipTerritoryMethods.SKIP_TRIGGER) {
      return;
   }
   ZipTerritoryMethods.handleTriggerActions(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter);

} // trigger ZipTerritory