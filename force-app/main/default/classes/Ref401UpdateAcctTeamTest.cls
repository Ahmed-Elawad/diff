/* 
 *This is the test class for the Reference401After trigger and Ref401UpdateAcctTeam class.
 *
 * History
 * -------
 * 03/24/2014 Frank Lurz   Created
 * 11/19/2019 Cindy Freeman    removed role file on query since noone is active with that role anymore
 */
@isTest
private class Ref401UpdateAcctTeamTest {
    static testMethod void myUnitTest() {

        Schema.RecordTypeInfo CaseOnb401kConvrt = RecordTypeHelper.getRecordType('Service Onboarding 401k Conversion', 'Case');

        Schema.RecordTypeInfo refOnb401kConvrt = RecordTypeHelper.getRecordType('Service Onboarding 401k Conversions', 'Reference_401k_S125__c');
        Schema.RecordTypeInfo refOnb401kLMNCrt = RecordTypeHelper.getRecordType('Service Onboarding 401k Large Market New Case', 'Reference_401k_S125__c');
        Schema.RecordTypeInfo refOnbEPlanrt = RecordTypeHelper.getRecordType('Service Onboarding ePlan', 'Reference_401k_S125__c');
        Schema.RecordTypeInfo refOnbRRSrt = RecordTypeHelper.getRecordType('Service Onboarding RRS', 'Reference_401k_S125__c');
        Schema.RecordTypeInfo refOnbSEBSrt = RecordTypeHelper.getRecordType('Service Onboarding SEBS', 'Reference_401k_S125__c');      
 
        User user4S1 = [Select Name, Email from User
                     where profile.Name = '2008-09 HRS 4S Operations B'
                      //and Userrole.Name = 'HRS 4S Conversions In Supervisor I'
                      and Email != null
                      and IsActive = true limit 1];
        
        //create Account and Contact records via the createTestAandC method in the CreateTestData test class
        CreateTestData.createTestAandC();
        Account testAcct1 = [select Id, Name, AccountNumber from Account where name = 'Test Account1'];
 
        //create Case records and link to Account records
        Case kase1 = new Case(recordtypeid = CaseOnb401kConvrt.getRecordTypeId(),
                              AccountId=testAcct1.Id, Current_Step__c='Case Creation',
                              Origin='Inbound Call',Status='New',
                              Product__c='401K', HRS4SCategory1__c='Ops - Conversion In',
                              Disposition_1__c='Administrator', Disposition_2__c='Self' );
        insert kase1;

        // verify 401k-S125 reference objects were created
        Reference_401k_S125__c refOnb401kConv = [Select Id, RecordType.Name from Reference_401k_S125__c where Case_Lookup__r.Id = :kase1.Id];
        System.assertEquals('Service Onboarding 401k Conversions', refOnb401kConv.RecordType.Name);


        refOnb401kConv.Client_Relationship_Account_Manager__c = user4S1.Id; 

        Test.startTest();
        update refOnb401kConv;
        Test.stopTest(); 
               
        // get the AccountTeamMember Record
        AccountTeamMember act1 = [Select Id, AccountId, UserId, CreatedDate from AccountTeamMember where AccountId =: testAcct1.Id Order By CreatedDate DESC Limit 1];
        
        // verify the UserID on the AccountTeamMember record has been populated as expected.
        system.assertEquals(user4S1.Id, act1.UserId);            
      
} //end testMethod
} //end class