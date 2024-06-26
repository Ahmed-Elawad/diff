/**
 * This class contains unit tests for validating the CaseAfter trigger
 * and triggers.
 *
 * History
 * --------
 * 11/23/2012	Cindy Freeman	created
 * 05/24/2017	Jermaine Stukes	Updated Methods
 * 10/19/2018   Jacob Hinds 	Removing DNC Method
 * 06/29/2021	Jermaine Stukes	Removed Code Coverage
 */
 @IsTest
private class CaseAfterTest {
   
    static testMethod void testCaseOther() {
    	createTestData();

    	RecordType caseGLType = [Select Id, Name, sobjectType from RecordType 
    								where sObjectType = 'Case' and Name = 'Service Onboarding GL Case' and IsActive = true]; 
    	
    	Contact ctct = [Select Id, Name from Contact where Name = 'First Last4'];
    	Case caseGL = new Case (recordtypeId = caseGLType.Id
    							,contactId = ctct.Id
    							,status = 'New'
    							,origin = 'Email'
    							,Product__c = 'GL'
    							,Reassign_Category_1__c = 'GL Onboarding'
    							,subject = 'GL Onboarding');
    	insert caseGL;
    	
    	Case updatedGL = [Select Id, subject, status, isClosed from Case where id = :caseGL.Id];
    	System.assertEquals(false, updatedGL.IsClosed);
   
    } // testCaseOther
   
   /*static testMethod void codeCoverage()
   {
       createTestData();
       RecordType caseMPSCType = [Select Id, Name, sobjectType from RecordType 
                                where sObjectType = 'Case' and Name = 'MPSC Client Audit' and IsActive = true]; 
       Account acct1 = [Select Id from Account where name=:'Test Account1' limit 1];
       Contact ctct = [Select Id, Name from Contact where Name = 'First Last4'];
       User testSalesRep = [Select Id, Name, Profile.Name, UserRole.Name from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and IsActive=true limit 1];
       Case caseMPSCAudit = new Case (recordtypeId = caseMPSCType.Id
                               ,status = 'New'
                               ,origin = 'Internal Request');
       insert caseMPSCAudit;
       caseMPSCAudit.status = 'In Review';
       update caseMPSCAudit;
       
       RecordType caseMMSSupportType = [Select Id, Name, sobjectType from RecordType 
                                        where sObjectType = 'Case' and Name = 'Service Support MMS Case' and IsActive = true]; 
       Case caseMMSSupport = new Case (recordtypeId = caseMMSSupportType.Id
                                       ,status = 'New'
                                       ,AccountId = acct1.Id
                                       ,MMS_Category_1__c='GENERAL'
                                       ,MMS_Client_Issue_Reported_By__c='Support Rep'
                                       ,MMS_CSR__c = testSalesRep.Id
                                       ,Description='This is just a test');
       insert caseMMSSupport;
       caseMMSSupport.status = 'In Progress';
       update caseMMSSupport;
       
       RecordType caseMMRecordType = [Select Id, Name, sobjectType from RecordType 
                                        where sObjectType = 'Case' and Name = 'Service Support 401k MM Change Case Record' and IsActive = true]; 
       Case caseMoneyManager = new Case (recordtypeId = caseMMSSupportType.Id
                                         ,status = 'New'
                                         ,AccountId = acct1.Id
                                         ,Call_Topic__c ='Account Balance'
                                         ,Description='This is just a test');
       insert caseMoneyManager;
       caseMoneyManager.recordtypeId = caseMMRecordType.Id;
       update caseMoneyManager;
       
   }*/
    private static void createTestData () {
        Account acct1 = new Account (name = 'Test Account1'
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        Contact con1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
        insert con1;
 
        Account acct2 = new Account (name = 'Test Account2'
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '99-7654321'
                                ,Do_Not_Call__c = false
                                ,Email_Opt_Out__c = false
                                ,AnnualRevenue = 25);
        insert acct2;
        Contact con2 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last4'
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast4@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct2.Id);
        insert con2;     
        
        Account acct3 = new Account (name = 'Test Prospect1'
                                ,type = 'Prospect'
                                ,BillingPostalCode = '10000');
        insert acct3;
        Contact con3 = new Contact(Firstname = 'First'
                                ,Lastname = 'Prospect1'
                                ,Phone = '585-555-1212'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct3.Id);
        insert con3;
                     
        
        
        } // createTestData
   
}