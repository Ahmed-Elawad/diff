/* Trigger on the Sandbox User Request object
        
  
           
  History
  -------
  03/05/2024 Dan Carmen      Created

 */
trigger SandboxUserRequest on SandboxUserRequest__c (before insert, after insert, before update, after update) {
   new SandboxRequest().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter, Trigger.IsDelete);
} // trigger SandboxUserRequest