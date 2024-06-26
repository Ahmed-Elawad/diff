/* 
 * Trigger to handle the Round Robin functionality.
 *
 * History
 * -------
   06/29/2011 Dan Carmen        Added check to only trigger if owner is a queue
   08/11/2011 Dan Carmen        Clean up trigger code - move logic to separate class (CaseRoundRobin)
   07/30/2015 Jacob Hinds       Route cases to new RoundRobin Class
   06/01/2016 Jacob Hinds       Changed the way the trigger hits the rr class.
   12/04/2023 Carrie Marciano   moved code into CaseBefore trigger to control when the round robin code was called
 *
 */
trigger caseRoundRobin on Case (before insert, before update) {

/*   //Check if assignment owner has changed
   System.debug('*****Entering caseRoundRobin...');
    
   // use map to only store queue id once
   Map<Id,Id> queueIds = new Map<Id,Id>();   //Trigger index --> Queue ID
   // list of cases that meet the criteria
   Case[] cases = new Case[]{};

   // get the prefix of the Queue (Group) object
   Schema.DescribeSObjectResult dor = Group.sObjectType.getDescribe();
   String queuePrefix = dor.getKeyPrefix();
   System.debug('queuePrefix='+queuePrefix);
    
   for (Case cs : Trigger.new) {
    
      if (Trigger.isUpdate) {  
         System.debug('>>>>>cs.OwnerId: '+cs.OwnerId);
         System.debug('>>>>>Trigger.oldMap.get(cs.id).OwnerId: '+Trigger.oldMap.get(cs.id).OwnerId);
         System.debug('>>>>>cs.TempOwnerId__c: '+cs.TempOwnerId__c);
         
         // only proceed if owner changes   
         if (cs.OwnerId <> Trigger.oldMap.get(cs.id).OwnerId) {
            // this wasn't used - and won't work because sometimes trigger is hit multiple times
            //if (cs.TempOwnerId__c == 'SKIP') {
            //   cs.TempOwnerId__c = '';
            //} else {
               String ownerId = cs.OwnerId;
               // make sure this is a queue
               if (ownerId.startsWith(queuePrefix)) {
                  queueIds.put(cs.OwnerId, cs.OwnerId);
                  cases.add(cs);
               } 
            //}
         } // if (cs.OwnerId
      } else if (Trigger.isInsert) {
         String ownerId = cs.OwnerId;
         // make sure this is a queue
         if (ownerId.startsWith(queuePrefix)) {
            queueIds.put(cs.OwnerId, cs.OwnerId);
            cases.add(cs);
         } 
      }   
   } // for
   System.debug('>>>>>queueIds: '+queueIds);

   if (!queueIds.isEmpty()) {
      RoundRobin.prepareCaseRoundRobin(cases, queueIds.values());
   }
*/
} // trigger caseRoundRobin