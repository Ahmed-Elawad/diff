/* Trigger on EmailMessage object

  History
  -------
  04/16/2021 Dan Carmen   Created
  06/25/2021 Dan Carmen   Add after actions

 */
trigger EmailMessage on EmailMessage (before insert, before update, after insert, after update) {
   System.debug('trigger EmailMessage EmailMessageMethods.SKIP_TRIGGER='+EmailMessageMethods.SKIP_TRIGGER);
   if (Trigger.isBefore && Trigger.new != null && !Trigger.new.isEmpty()) {
      EmailMessage msg = Trigger.new[0];
      StringHelper.addToProcessNotes(msg, 'EmailMessage trigger SKIP_TRIGGER='+EmailMessageMethods.SKIP_TRIGGER+' lastOpened='+msg.LastOpenedDate);
   }
   if (!EmailMessageMethods.SKIP_TRIGGER) {
      new EmailMessageMethods().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
   } // if (!EmailMessageMethods.SKIP_TRIGGER

} // trigger EmailMessage