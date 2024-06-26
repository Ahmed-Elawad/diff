/* 
 * History
 * -------
  01/12/2023 Rohit Ranjan Created
  

*/



trigger RAMTrigger on Reference_Account_Management__c (before insert) { 
    List<Reference_Account_Management__c> ramList = Trigger.New;
    if(Trigger.isInsert){
      ramList= RAMTriggerHandler.setRAMOwnerRR(ramList);
    }   
}