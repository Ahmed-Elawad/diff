/**
 * Test method for ClientReferencesMethods
 * 
 * History
 * --------
 * 03/07/2018   Cindy Freeman   modifed for new ClientReferencesSelected trigger and methods
   05/08/2018   Dan Carmen      Moved TriggerSetup into testSetup method. 
 
 */

@isTest
private class ClientReferencesSelectedMethodsTest {

    @testSetup
    static void setupData() {
       TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
       TriggerSetup__c trigSetup = TriggerMethodsTest.createCustomSetting(null, 'ClientReferencesSelectedBefore', true, false, new String[]{'ClientReferencesSelectedMethods'}, setupClasses);       
       trigSetup = TriggerMethodsTest.createCustomSetting(null, 'ClientReferencesSelectedAfter', false, true, new String[]{'ClientReferencesSelectedMethods'}, setupClasses); 
       insert setupClasses;
    } // setupData

    static testMethod void myUnitTest1() {
        
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25
                                ,BIS_Id__c = 1001001);
        insert acct1;
        Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,Sales_Contact__c = true);
       insert ctct1;       
       Id optyId = CreateTestData.createTestCoreOptys (acct1.Id, ctct1.Id);
        
 
       Client_Reference__c cref = new Client_Reference__c(Bis_Id__c = 1001001,VoC_Indicator__c='Waiting on Approval',
                                    Primary_Contact__c = 'First Last1',Primary_Contact_Email__c='fLast1@abc.com');
       insert cref;
            
       ClientReferencesSelectedMethods crsm = new ClientReferencesSelectedMethods();
       
       Client_References_Selected__c crs = new Client_References_Selected__c(Client_Reference__c = cref.Id
                                                                              ,Account__c = acct1.Id
                                                                              ,Contact__c = ctct1.Id
                                                                              ,Opportunity__c = optyId
                                                                              ,Status__c = 'Waiting on Approval');
       insert crs;
       
       crs.Status__c = 'Approved';
       update crs;
       // did Client Ref get updated to Out for Reference?
       cref = [Select id, VoC_Indicator__c from Client_Reference__c where id = :cref.Id];
       System.assertEquals('Out for reference', cref.VoC_Indicator__c);
        
       // uh oh client went lost
       acct1.Type = 'Lost Client';
       update acct1;
       crs = [Select Id, Status__c, VoC_Indicator__c from Client_References_Selected__c where id = :crs.Id];
       System.assertEquals('No Longer an Active Client', crs.Status__c);
       System.assertEquals('No Longer an Active Client', crs.VoC_Indicator__c); 
       cref = [Select id, VoC_Indicator__c from Client_Reference__c where id = :cref.Id];
       System.assertEquals('No Longer an Active Client', cref.VoC_Indicator__c);  
        
    } // myUnittest1
        
    static testMethod void myUnitTest2() {
        
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25
                                ,BIS_Id__c = 1001001);
        insert acct1;
        Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,Sales_Contact__c = true);
       insert ctct1;       
       Id optyId = CreateTestData.createTestCoreOptys (acct1.Id, ctct1.Id);
         
       Client_Reference__c cref = new Client_Reference__c(Bis_Id__c = 1001001,VoC_Indicator__c='Waiting on Approval',
                                    Primary_Contact__c = 'First Last1',Primary_Contact_Email__c='fLast1@abc.com');
       insert cref;
            
       ClientReferencesSelectedMethods crsm = new ClientReferencesSelectedMethods();
       
       Client_References_Selected__c crs = new Client_References_Selected__c(Client_Reference__c = cref.Id
                                                                              ,Account__c = acct1.Id
                                                                              ,Contact__c = ctct1.Id
                                                                              ,Opportunity__c = optyId
                                                                              ,Status__c = 'Waiting on Approval');
       insert crs;
       
       // Create and submit an approval request 
       Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
       req1.setObjectId(crs.id);
       req1.setProcessDefinitionNameOrId('Client_Reference_Selected_Approval');
       req1.setSkipEntryCriteria(true);
       Approval.ProcessResult result = Approval.process(req1);
       System.assert(result.isSuccess());

       List<Id> newWorkItemIds = result.getNewWorkitemIds();
       Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
       req2.setComments('No this is rejected');
       req2.setAction('Reject');
       req2.setWorkitemId(newWorkItemIds.get(0));
       Approval.ProcessResult result2 =  Approval.process(req2);
       System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
        
       crs = [Select id, Rejected_Reason__c from Client_References_Selected__c where id = :crs.Id];
       System.assertEquals('No this is rejected', crs.Rejected_Reason__c);
        
    } // myUnittest2
            
}