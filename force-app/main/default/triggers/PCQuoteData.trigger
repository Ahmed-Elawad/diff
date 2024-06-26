/* 
   If P&C Quote Data record has updates potentially update the related opportunity
   
  History
  -------
  12/14/2022 Carrie Marciano   Created
    
 */

trigger PCQuoteData on PC_Quote_Data__c (after insert, after update) {
   new PCQuoteDataMethods().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
} // trigger PCQuoteData