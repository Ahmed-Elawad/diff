/**
 * This class contains unit tests for validating the CaseServiceNow class.
 * 
 *
 * History
 * --------
 * 09/23/2013   Cindy Freeman   created   
 * 01/30/2018   Lynn Michels    Add description on to Service Now case to avoid validation rule
 */
 
@isTest
private class CaseServiceNowTest {

    static testMethod void mySNowTest() {
        Account payxEmp = CreateTestData.createPaychexEmp();
        List<Contact> payxCtctList = payxEmp.Contacts;
        Contact payxCtct = payxCtctList.get(0);
        
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name, AccountNumber from Account where name = 'Test Account1'];
        Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
        
        User u1 = [Select Id, Name, Email from User 
                    where profile.Name = '2008-09 TAA Operations' 
                    and Email <> null
                    and IsActive = true limit 1];
        
        Schema.RecordTypeInfo svcCaseRt = RecordTypeHelper.getRecordType('Service Premier Record Type','Case');
        
        System.runAs(u1) {
            Case snowCase = new Case (RecordTypeId=svcCaseRt.getRecordTypeId()
                                    , Subject = 'Test Case'
                                    , AccountId = a1.Id
                                    , ContactId = ctct1.Id
                                    , Status = 'New'
                                    , Product__c = 'Premier'
                                    , Type = 'Client Concern'
                                    , Premier_Sub_Product_1__c = 'Cobra'
                                    , Premier_Concern_1__c = 'Other'
                                    , Originator__c = payxCtct.Id
                                    , OwnerId = u1.Id
                                    , Assignment_Group__c = 'ES - PASS'
                                    , Impact__c = '2 - Medium'
                                    , Urgency__c = '2 - Medium'
                                    , Business_Application__c = 'Other'
                                    , Send_Case_to_Service_Now__c = TRUE
                                    , Description = 'send to service now');
            insert snowCase;
            Case snowCase2 = [Select Id, Service_Now_Affected_User__c, Service_Now_Caller__c, 
                            Service_Now_Client_ID__c, OwnerId, SupervisorAlert__c from Case where id = :snowCase.Id];
            System.assertEquals(snowCase2.Service_Now_Affected_User__c, payxCtct.Email);        
            System.assertEquals(snowCase2.Service_Now_Client_ID__c, a1.AccountNumber);                           
            //System.assertEquals(snowCase2.Service_Now_Caller__c, u1.Email);
            //System.assertEquals(1, snowCase2.SupervisorAlert__c);           // testing workaround for CaseSetAlertTimeStamp
        }
        
    } // mySnowTest
    
    static testMethod void testBatch() {
        Account payxEmp = CreateTestData.createPaychexEmp();
        List<Contact> payxCtctList = payxEmp.Contacts;
        Contact payxCtct = payxCtctList.get(0);
        
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name, AccountNumber from Account where name = 'Test Account1'];
        Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
        Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name = 'CaseServiceNowBatch' 
                                                              , Active__c = FALSE);
        insert abc;
        
        ServiceNow__c snCS = new ServiceNow__c(SN_User_Name__c = 'TestUser'
                                        , SN_User_Password__c = 'TPW'
                                        , SN_Endpoint__c = 'http://api.salesforce.com/foo/bar');
        insert snCS;
        
        User u1 = [Select Id, Name, Email from User 
                    where profile.Name = '2008-09 TAA Operations' 
                    and Email <> null
                    and IsActive = true limit 1];
        
        Schema.RecordTypeInfo svcCaseRt = RecordTypeHelper.getRecordType('Service Premier Record Type','Case');
        
        Case snowCase = new Case (RecordTypeId=svcCaseRt.getRecordTypeId()
                            , Subject = 'Test Case'
                            , Description = 'Test Description'
                            , Manager_Escalation_Comments__c = 'Manager Escalation Comment'
                            , AccountId = a1.Id
                            , ContactId = ctct1.Id
                            , Employee_ID__c = 'Employee Id'
                            , Status = 'New'
                            , Product__c = 'Premier'
                            , Type = 'Client Concern'
                            , Premier_Sub_Product_1__c = 'Cobra'
                            , Premier_Concern_1__c = 'Other'
                            , Originator__c = payxCtct.Id
                            , Send_Case_to_Service_Now__c = TRUE
                            , Sent_Case_to_Service_Now__c = FALSE
                            , Assignment_Group__c = 'ES - PASS'
                            , Impact__c = '2 - Medium'
                            , Urgency__c = '2 - Medium'
                            , Business_Application__c = 'Other'
                            , OwnerId = u1.Id);
        insert snowCase;
        list<AsyncApexJob> asyncJobList = [SELECT Id
                                                 FROM AsyncApexJob 
                                           WHERE JobType='BatchApex' 
                                                AND (Status = 'Processing' 
                                                OR Status = 'Preparing'
                                                OR Status = 'Queued'
                                                OR Status = 'Holding') 
                                                 AND
                                                 ApexClassId = :[SELECT Id 
                                                                 FROM ApexClass 
                                                                 WHERE NamespacePrefix = null 
                                                                 AND Name = 'CaseServiceNowBatch' 
                                                                 Limit 1].Id];
        system.assert(asyncJobList.isEmpty());// There should be no job at this point because Active is FALSE
        abc.Active__c = TRUE;
        update abc; //Updating Active to TRUE
        
        CaseServiceNowBatch cSNBatch = new CaseServiceNowBatch(); 
        snowCase.Subject = 'Test Case Update 1';
        id csnbJobId;
        Test.startTest();
        try{
           System.scheduleBatch(cSNBatch, 'CaseServiceNowBatch', 15);// Schedule to start in 15 minutes to stay below concurrent Batch job limit.
        } 
        catch(AsyncException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        } //Don't do anything if there is an exception when kicking off the batch
        update snowCase;
        asyncJobList = [SELECT Id
                        FROM AsyncApexJob 
                        WHERE JobType='BatchApex' 
                        AND (Status = 'Processing' 
                             OR Status = 'Preparing'
                             OR Status = 'Queued'
                             OR Status = 'Holding') 
                        AND
                        ApexClassId = :[SELECT Id 
                                        FROM ApexClass 
                                        WHERE NamespacePrefix = null 
                                        AND Name = 'CaseServiceNowBatch' 
                                        Limit 1].Id];
        system.assertEquals(1, asyncJobList.size());//Should only be one job
        try{
            System.abortJob(csnbJobId);//Aborting csnbJob that was scheduled for 15 minutes
        } 
        catch(Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        } //Don't do anything if there is an exception when aborting the batch
        
        snowCase.Subject = 'Test Case Update 2'; 
        update snowCase;
        asyncJobList = [SELECT Id
                        FROM AsyncApexJob 
                        WHERE JobType='BatchApex' 
                        AND (Status = 'Processing' 
                             OR Status = 'Preparing'
                             OR Status = 'Queued'
                             OR Status = 'Holding') 
                        AND
                        ApexClassId = :[SELECT Id 
                                        FROM ApexClass 
                                        WHERE NamespacePrefix = null 
                                        AND Name = 'CaseServiceNowBatch' 
                                        Limit 1].Id];
        system.assertEquals(1, asyncJobList.size());//Should only be one job
        
        Test.stopTest();
        
        case snowCaseAfter = [Select id, Sent_Case_to_Service_Now__c from Case Where Id = :snowCase.Id Limit 1];
        system.assertEquals(TRUE, snowCaseAfter.Sent_Case_to_Service_Now__c);
    }//testBatch
    
}