/* Abstract class to allow us to make the triggers more generic

  History
  -------
  04/24/2018 Dan Carmen        Created from TriggerInterface
  
 */
public interface TriggerInterface2 {
   
   // check all of the records as a group before cycling through them individually
   void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter);

   // check each record individually
   void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter);
   
   // see if there are any actions that need to take place at the end of the trigger.
   void triggerCheckActions(Boolean isBefore, Boolean isAfter);
   
} // interface TriggerInterface2