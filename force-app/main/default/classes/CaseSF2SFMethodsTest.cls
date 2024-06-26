/* Test methods for the CaseSF2SFMethods class

  History
  -------
  08/07/2017 Cindy Freeman        Created
  11/02/2020 Brandon Vidro        Added test for update MSP Client Type to Ascentis when Origin = 'Email-to-Case MSP Asc'
  11/23/2020 Brandon Vidro        Updates to myTest1
  
 */
 
 
@isTest
private class CaseSF2SFMethodsTest {
  
   static testMethod void myTest1() {
   	   	
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerSetup__c trigSetup = TriggerMethodsTest.createCustomSetting(null, 'CaseAfter', false, true, 
      																	new String[]{'CaseSF2SFMethods'}, setupClasses);
      insert setupClasses;
      
      CaseSF2SFMethods csf2sf = new CaseSF2SFMethods();
      // these are for code coverage 
      csf2sf.checkAfterTrigger(null, null);
      csf2sf.processAfterTriggerActions();
  
  	  CreateTestData.createSingleAandTwoCts();
  	  Account acct = [Select Id, Name from Account where Name = 'Test Account1'];
  	  
  	  Schema.RecordTypeInfo caseRt = RecordTypeHelper.getRecordType('Service Support MSP Case', ObjectHelper.OBJECT_CASE); 
  	  Case kase1 = new Case(recordTypeId=caseRt.getRecordTypeId(), MSP_Client_Type__c='Ascentis', AccountId=acct.Id);
  	  insert kase1;
       
  	  ErrorLog__c[] logList = [Select Id, ClassName__c, CodeKey__c from ErrorLog__c 
  	  						where createdDate = TODAY and ClassName__c = 'CaseSF2SFMethods' and CodeKey__c = 'missing PartnerNetworkConnection'];
  	  System.assertEquals(0,logList.size());
  	  
  	  Case kase2 = new Case(recordTypeId=caseRt.getRecordTypeId(), MSP_Client_Type__c='Ascentis', AccountId=acct.Id);
  	  insert kase2; 
  	  
  	  logList = [Select Id, ClassName__c, CodeKey__c from ErrorLog__c 
  	  						where createdDate = TODAY and ClassName__c = 'CaseSF2SFMethods' and CodeKey__c = 'missing PartnerNetworkConnection'];
       
  	  System.assertEquals(1,logList.size());
       
      Case kase3 = new Case(recordTypeId=caseRt.getRecordTypeId(), MSP_Client_Type__c='Direct', AccountId=acct.Id);
      insert kase3; 
      kase3.MSP_Client_Type__c = 'Ascentis';
      update kase3;
       
       logList = [Select Id, ClassName__c, CodeKey__c from ErrorLog__c 
                  where createdDate = TODAY and ClassName__c = 'CaseSF2SFMethods' and CodeKey__c = 'missing PartnerNetworkConnection'];
       
       System.assertEquals(2,logList.size());
 
   } // myTest1
    
    static testMethod void testMspClientTypeAscentis() {
        
        TriggerSetupClasses__c[] setupClassesBefore = new TriggerSetupClasses__c[]{};
            TriggerSetup__c trigSetupBefore = TriggerMethodsTest.createCustomSetting(null, 'CaseBefore', true, false, 
                                                                                     new String[]{'CaseSF2SFMethods'}, setupClassesBefore);
        insert setupClassesBefore;
        
        CaseSF2SFMethods csf2sf = new CaseSF2SFMethods();
        
        Case kase3 = new Case(MSP_Client_Type__c='Flex', Origin = 'Email-to-Case MSP Asc');
        insert kase3;      
        
        Case kase4 = [Select Id, MSP_Client_Type__c from Case Where Origin = 'Email-to-Case MSP Asc'];
        
        System.assertEquals(kase4.MSP_Client_Type__c, 'Ascentis');
        
    } // testMspClientTypeAscentis
    
}