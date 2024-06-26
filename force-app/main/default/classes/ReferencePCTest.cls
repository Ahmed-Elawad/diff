/**
 * Test class for ReferencePCTest
 * 07/24/2018 Lynn Michels  Created
 * 08/06/2018 Lynn Michels  Edited to test more functionality of the class
 */
@isTest
private with sharing class ReferencePCTest {
    
     @testSetup
    static void setupData() {
        TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
        TriggerSetup__c trigSetup = TriggerMethodsTest.createCustomSetting(null, 'ReferencePC', false, true, new String[]{'ReferencePC'}, setupClasses);
        insert setupClasses;
    } // setupData
    
    static testMethod void ReferencePCInsert() {
        Account acct = new Account(Name='Test Acct');
        insert acct;
        Acord__c acord = new Acord__c(Prospect_Client__c = acct.id);
        insert acord;
        Test.setCreatedDate(acord.Id, DateTime.newInstance(2012,12,11));        
        
        Carrier_Quote__c cquote = new Carrier_Quote__c(Acord_Name__c = acord.id);
        insert cquote;
        Test.setCreatedDate(cquote.Id, DateTime.newInstance(2012,12,12));
       
        //need to insert them separately so they have different created time stamps
        Acord__c acord2 = new Acord__c(Prospect_Client__c = acct.id);
        insert acord2;
        Test.setCreatedDate(acord2.Id, DateTime.newInstance(2012,12,12));
        
        Carrier_Quote__c cquote2 = new Carrier_Quote__c(Acord_Name__c = acord2.id, Carrier_Name__c = 'Test Carrier');
        insert cquote2;
        Test.setCreatedDate(cquote2.Id, DateTime.newInstance(2012,12,13));
        
        Carrier_Quote__c cquote3 = new Carrier_Quote__c(Acord_Name__c = acord2.id, Carrier_Name__c = 'test2 Carrier');
        insert cquote3;
        Test.setCreatedDate(cquote3.Id, DateTime.newInstance(2012,12,14));
        
        Id caseRTId = RecordTypeHelper.getRecordType('Service Onboarding P&C Case', 'Case').getRecordTypeID();
        Case c = new Case(AccountId = acct.id, recordtypeId = caseRTId);
        insert c;
        Id refPCTypeId = RecordTypeHelper.getRecordType('P&C Onboarding', 'Reference_P_C__c').getRecordTypeID();
        Reference_P_C__c refPC = new Reference_P_C__c(Case_Lookup__c = c.id, recordTypeId = refPCTypeId);
        
        test.startTest();
        List<Carrier_Quote__c> quoteList = [SELECT id, CreatedDate, Acord_Name__c FROM Carrier_Quote__c];
        system.debug('LM Created Date ' + quoteList);
        
            insert refPC;
            list<Reference_P_C__c> refPCList = [SELECT id, Carrier_Quote_Lookup__c FROM Reference_P_C__c];
            system.assertEquals(1,refPCList.size());
            system.assertEquals(cquote3.id,refPCList[0].Carrier_Quote_Lookup__c);
        test.stopTest();
        
    }//end ReferencePCInsert
    
    static testMethod void ReferencePCUpdate() {
        Account acct = new Account(Name='Test Acct');
        insert acct;
        Id caseRTId = RecordTypeHelper.getRecordType('Service Onboarding P&C Case', 'Case').getRecordTypeID();
        Case c = new Case(AccountId = acct.id, recordtypeId = caseRTId, Current_step__c = 'New');
        insert c;
        Id refPCTypeId = RecordTypeHelper.getRecordType('P&C Onboarding', 'Reference_P_C__c').getRecordTypeID();
        Reference_P_C__c refPC = new Reference_P_C__c(Case_Lookup__c = c.id, recordTypeId = refPCTypeId, Current_Step__c = 'New');
        insert refPC;
        
        test.startTest();
            refPC.current_step__c = 'in progress';
            update refPC;
            list<Reference_P_C__c> refPCList = [SELECT id, Current_Step__c FROM Reference_P_C__c];
            list<Case> caseList = [SELECT id, current_step__c FROM Case];
            system.assertEquals(caseList[0].current_step__c,refPCList[0].current_Step__c);
        test.stopTest();
        
    }//end ReferencePCInsert
    
    //for code coverage
    static testMethod void testMisc() {     
            ReferencePC refPC = new ReferencePC();
            refPC.checkAllBeforeTrigger(null, null);
            refPC.checkBeforeTrigger(null, null); 
            refPC.processBeforeTriggerActions();
            refPC.checkAfterTrigger(null, null);
            refPC.processAfterTriggerActions(); 
                       
    }//end testMisc
}