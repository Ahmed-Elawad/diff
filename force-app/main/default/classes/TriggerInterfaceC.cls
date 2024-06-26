/* Abstract class to allow us to make the triggers more generic

  History
  -------
  11/15/2019 Dan Carmen        Created from TriggerInterface
  
 */
public interface TriggerInterfaceC {

   // Handle all interactions from the triggers
   void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete);

} // interface TriggerInterfaceC