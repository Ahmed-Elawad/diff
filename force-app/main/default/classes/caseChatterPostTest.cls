/**
 * Test for caseChatterPost.cls
 * History
 * -------
 * 01/26/2016 Lynn Michels created
 */
@isTest
private class caseChatterPostTest {

   @isTest(SeeAllData=true)  //needed to check chatter posts using ConnectAPI
   static void checkChatterPost() 
   { 
      Schema.RecordTypeInfo caseRT = RecordTypeHelper.getRecordType('Adoption Agreement Review', ObjectHelper.OBJECT_CASE);
      Case testCase = new Case(recordtypeId = caseRT.getRecordTypeId());							
      insert testCase;
      
      List<Reference_Adoption_Agreement_Review__c> raar = [SELECT Case_Lookup__r.Account.Name, Name, Bis_ID__c, Sales_Rep__c, Implementation_Manager__c, Client_Relationship_Account_Manager__c, Case_Lookup__c
		FROM Reference_Adoption_Agreement_Review__c WHERE Case_Lookup__c =: testCase.id]; 
		System.assertEquals(1, raar.size());
		
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
      	User uA = new User(Alias = 'userA', Email='userA@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='userA', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='userA@testorg.com', Sales_Org__c = 'Training');
        User uB = new User(Alias = 'userB', Email='userB@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='userB', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='userB@testorg.com', Sales_Org__c = 'Training');
        User uC = new User(Alias = 'userC', Email='userC@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='userC', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='userC@testorg.com', Sales_Org__c = 'Training');
            insert uA;
            insert uB;
            insert uC;
            
        raar[0].Sales_Rep__c = uA.id;
        raar[0].Client_Relationship_Account_Manager__c = uB.id;
        raar[0].Implementation_Manager__c = uC.id;
        update raar[0];
        
		testCase.Status = 'Completed';
		update testCase;
		
		list<feedItem> caseFeedItem = [SELECT Id, Body FROM feedItem WHERE parentId =: testCase.id];
		System.assertEquals(1, caseFeedItem.size());
		System.assertEquals(true, caseFeedItem[0].Body.contains('Contact your Field Support Manager with any questions.'));	
   }
}