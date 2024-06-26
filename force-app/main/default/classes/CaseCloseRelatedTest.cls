/* 
 * Test methods for the CaseCloseRelated class and trigger.
 *
 * History
 * -------
   12/12/2012 Dan Carmen   Created
 *
 */
@isTest
private class CaseCloseRelatedTest {

   static testMethod void test401k() {
      testRecordType(CaseCloseRelated.recordTypeNames401k,1,4,'Solved',true);
   } // test401k
    
   static testMethod void test401kBadStatus() {
      testRecordType(CaseCloseRelated.recordTypeNames401k,1,4,'Completed',false);
   } // test401k
    
   static testMethod void testHROCompleted() {
      testRecordType(CaseCloseRelated.recordTypeNamesHRO,2,3,'Completed',true);
   } // test401k
    
   static testMethod  void testBadRecordType() {
      Set<String> recordTypeNames = new Set<String>{'COE Enhancement Submission Case Record Type'};
      testRecordType(recordTypeNames,1,4,'Completed',false);
   }   
   static void testRecordType(Set<String> recordTypeNames, Integer numberOfEachParent, Integer numOfChildren, String finalStatusName, Boolean childrenShouldUpdate) {
      System.debug('testRecordType recordTypeNames='+recordTypeNames+' finalStatusName='+finalStatusName+' numberOfEachParent='+numberOfEachParent+' numOfChildren='+numOfChildren+' childrenShouldUpdate='+childrenShouldUpdate);
      
      // create a parent cases
      Case[] parentCases = new Case[]{};
      for (String recordTypeName : recordTypeNames) {
         // get the record type id
         Schema.RecordTypeInfo recordType = RecordTypeHelper.getRecordType(recordTypeName, 'Case');
         // verify we have a record type
         System.assertEquals(true, (recordType != null));

         for (Integer cnt=0; cnt<numberOfEachParent; cnt++) {
            // create with all of the different criteria so it will fall in by record type
            Case c = new Case(RecordTypeId = recordType.getRecordTypeId(), Mass_Create_Indicator__c='Bis ID', Action__c = 'HRO Onboarding/Setup', Status='New');
            parentCases.add(c);
         } // for (Integer
      } // for (String
      insert parentCases;
      
      // create child cases for each parent
      Case[] childrenCases = new Case[]{};
      // get the parent ids to check later
      Id[] parentCaseIds = new Id[]{};
      
      for (Case parentC : parentCases) {
      	for (Integer cnt=0; cnt<numOfChildren; cnt++) {
            Case childC = new Case(RecordTypeId = parentC.recordTypeId, ParentId=parentC.Id, Status='New');
            childrenCases.add(childC);
      	} // for (Integer cnt
      	
      	// set the status - update after inserting the children
      	parentC.Status = finalStatusName;
      	parentCaseIds.add(parentC.Id);
      } // for (Case
      insert childrenCases;
      
      // use StartTest because of future method
      Test.StartTest();
      // update the parent cases - status was changed above
      update parentCases;
      Test.StopTest();
      
      // verify results
      String finalChildStatus = (childrenShouldUpdate ? finalStatusName : 'New');
      Integer numResults = parentCaseIds.size() * numOfChildren;
      System.assertEquals(numResults,[Select count() from Case where ParentId in :parentCaseIds and Status=:finalChildStatus]);
   } // testRecordType
   
} // class CaseCloseRelatedTest