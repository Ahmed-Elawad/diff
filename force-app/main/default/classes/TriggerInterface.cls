/* Abstract class to allow us to make the triggers more generic

  History
  -------
  01/09/2017 Dan Carmen        Created
  05/09/2017 Dan Carmen        Change from an Interface to Abstract class, add new methods.
                                  Abstract class, methods don't have to be overridden.
  
 */
public interface TriggerInterface {
   
   void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap);

   void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap);

   void checkBeforeTrigger(SObject newRec, SObject oldRec);
   
   void processBeforeTriggerActions();
   
   void checkAfterTrigger(SObject newRec, SObject oldRec);
   
   void processAfterTriggerActions();
   
} // interface TriggerInterface