/** Trigger for the DialSource object
 *
 * History
 * -------
   12/12/2018 Dan Carmen            Created.
   02/26/2019 Dan Carmen            Add after actions

*/
trigger DialSourceAction on DS_Denali__DialSource_Action__c (before insert, before update, after update) {
    DialSourceActionHelper.processTrigger(Trigger.new, Trigger.oldMap);
} // trigger DialSourceAction