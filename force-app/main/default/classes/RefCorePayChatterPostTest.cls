/**
 * Test for caseChatterPost.cls
 * History
 * -------
 * 01/26/2016 Lynn Michels created
 * 3/20/2024  Carrie Marciano    Removed code related to old MPSC Process
 */
@isTest
private class RefCorePayChatterPostTest {

   @isTest(SeeAllData=true)  //needed to check chatter posts using ConnectAPI
   static void checkChatterPost() 
   { 
      Schema.RecordTypeInfo mpscClientRT= RecordTypeHelper.getRecordType('MPSC Client Audit', ObjectHelper.OBJECT_CASE);
      //Schema.RecordTypeInfo mspcEmployeeRT= RecordTypeHelper.getRecordType('MPSC Employee Audit', ObjectHelper.OBJECT_CASE);
      Case testCase = new Case(recordtypeId = mpscClientRT.getRecordTypeId());                            
      insert testCase;
  
     /*List<Reference_Core_Payroll__c> rcp = [SELECT Id, Implementation_Specialist_Name__c, Payroll_Status__c
            FROM Reference_Core_Payroll__c WHERE Case_Lookup__c =: testCase.id ]; 
        System.assertEquals(1, rcp.size());
        */
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User uA = new User(Alias = 'userA', Email='userA@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='userA', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='userA@testorg.com', Sales_Org__c = 'Training');
        
            insert uA;
            
            Reference_Core_Payroll__c rcp = new Reference_Core_Payroll__c(Case_Lookup__c = testCase.id, Implementation_Specialist_Name__c = uA.id);
			insert rcp;

       /* rcp[0].Implementation_Specialist_Name__c = uA.id;
        update rcp[0];*/
        
        testCase.Status = 'On Hold';
        update testCase;
        
        list<feedItem> caseFeedItem = [SELECT Id, Body FROM feedItem WHERE parentId =: rcp.id];
        System.assertEquals(1, caseFeedItem.size());
        System.assertEquals(true, caseFeedItem[0].Body.contains('The Status of the audit has been changed to')); 
   }
}