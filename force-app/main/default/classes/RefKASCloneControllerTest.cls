/**
 * 05/04/2018 Lynn Michels Created
 */
@isTest
private class RefKASCloneControllerTest {

    static testMethod void testCloning() {
    	CreateTestData.createTestAandC ();
    	Account testAccount = [SELECT id FROM Account WHERE AccountNumber = '83-1234567'];
    	system.debug('testAccount' +testAccount);
    	Contact testContact = [SELECT id FROM Contact WHERE AccountId =: testAccount.id
    							AND Phone =: '585-555-1212'];
    	Id CaseKAS = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Support KAS').getRecordTypeId(); 
		
        Case testCase = new Case(AccountId = testAccount.id,
        						ContactId = testContact.id,
        						RecordTypeId = CaseKAS,
        						Status =' New',
        						Origin = 'Proactive',
        						Description = 'Test KAS case');
        insert testCase;
        Reference_KAS__c testKAS = new Reference_KAS__c(Case_Lookup__c = testCase.id);
        insert testKAS;
        
        
        
        //Set Current Page to new reference
        PageReference pageRef = Page.ReferenceKASClone;
        test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(testKAS);
        RefKASCloneController controller = new RefKASCloneController(sc);
    System.assertEquals(true, controller.confirmClone);
    System.assertEquals(false, controller.success); 
        controller.cloneRecords();
    System.assertEquals(false, controller.confirmClone);
    System.assertEquals(false, controller.success); 
    //process the clone without selecting a new Account or Contact
        controller.processClone();
    System.assertEquals(false, controller.confirmClone);
    System.assertEquals(false, controller.success);
    System.assert(ApexPages.hasMessages(ApexPages.SEVERITY.WARNING));
    	//choose an account for the cloned case
    	Account testAccount2 = [SELECT id FROM Account WHERE AccountNumber = '99-7654321'];
    	controller.clonedCase.AccountId = testAccount2.id;
    	controller.processClone();
    System.assertEquals(true, controller.success);
    System.assert(ApexPages.hasMessages(ApexPages.SEVERITY.CONFIRM));
    List<Case> caseList = new List<Case>([SELECT id FROM Case]);
    system.debug('caseList' +caseList);
    	 
    }
}