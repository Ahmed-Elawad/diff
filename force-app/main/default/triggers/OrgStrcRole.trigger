/* 
 * Set the Role Name and Id on the Organization Structure object
 *
 * History
 * -------
 * 09/14/2011 Dan Carmen   Created
   03/05/2012 Dan Carmen   Added logic to populate zone and area role information
   04/30/2020 Dan Carmen   Add code back in to maintain roles if needed.

*/
trigger OrgStrcRole on Organization_Structure__c (before insert, before update) {

   OrgStrcRole.processStrcs((Organization_Structure__c[])Trigger.new, Trigger.oldMap);
} // trigger OrgStrcRole