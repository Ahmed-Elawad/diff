/* Trigger for working on the Reference Client Retention object

  History
  -------
  03/29/2023 Carrie Marciano        Created
  04/03/2023 Chris Santoro			Added isUpdate 
  05/02/2023 Carrie Marciano		moved isUpdate to class added SKIP_TRIGGER
 */


trigger ReferenceClientRetention on Reference_Client_Retention__c (before insert, before update, after insert, after update) {
    System.debug('ReferenceClientRetention ReferenceClientRetentionMethods.SKIP_TRIGGER='+ReferenceClientRetentionMethods.SKIP_TRIGGER);
    if (ReferenceClientRetentionMethods.SKIP_TRIGGER) {
       return;
    }
	new ReferenceClientRetentionMethods().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
  
}