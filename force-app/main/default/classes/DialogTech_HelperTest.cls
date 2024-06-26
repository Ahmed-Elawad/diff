/* 
 * Test Methods for the DialogTech_Helper class
 *
 * History
 * -------
   02/27/2019 Cindy Freeman    created
   03/26/2019 Cindy Freeman     cleaned up test
   12/03/2019 Cindy Freeman     added test for gclid 
 */
@isTest
private class DialogTech_HelperTest{

   @testSetup 
   public static void setupTestData() {
       
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerSetup__c trigSetup1 = TriggerMethodsTest.createCustomSetting(null, 'DialogTechCallAfter', false, true, new String[]{'DialogTech_Helper'},setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;

      CreateTestData.createSingleAandTwoCts();
      Id leadId = CreateTestData.createTestLead();
      Lead newLead = new Lead(id = leadId, phone = '(585) 555-1111', MobilePhone='(585) 555-1112',Other_Phone__c='(585) 555-1113');
      update newLead;
      
} // setupTestData

static testMethod void testDialogTechCall() {

    DialogTech_Helper.TEST_PROCESS_NOW = true;
  
    Contact testct = [select Id, phone, AssistantPhone, HomePhone, MobilePhone, OtherPhone, NSS_Other_Phone__c  from Contact where FirstName = 'Second'];
    testct.AssistantPhone = '585-555-9999';
    testct.HomePhone = '555-5555';
    testct.MobilePhone = '666-6666';
    testct.OtherPhone = '777-7777';
    testct.NSS_Other_Phone__c = '888-8888';
    update testct;
    
    // you must give the test the sosl results
    List<Id> fixedSoslResults = new List<Id>();
    Contact[] ctctList = [select Id, phone, AssistantPhone, HomePhone, MobilePhone, OtherPhone, NSS_Other_Phone__c  from Contact];
    for (Contact ct : ctctList)
    {  fixedSoslResults.add(ct.Id);   }
    Lead[] ldList = [select Id, phone, MobilePhone, Other_Phone__c from Lead];
    for (Lead ld :ldList)
    {  fixedSoslResults.add(ld.Id);  }
    Test.setFixedSearchResults(fixedSoslResults);
    
    // match to a Lead
    /*BAU Changes*/
    /* IBP__Ifbyphone_Call__c dtCall1 = new IBP__Ifbyphone_Call__c(Name='Test1', IBP__CallerID__c='5855551111', IBP__SessionID__c='1', IBP__DateAdded__c=System.now(), IBP__ST_GCLID__c='Googleclick');
     insert dtCall1;*/
     INVOCA_FOR_SF__Invoca_Call_Log__c dtCall1 = new INVOCA_FOR_SF__Invoca_Call_Log__c(INVOCA_FOR_SF__advertiser_name__c='Test1', INVOCA_FOR_SF__calling_phone_number__c='5855551111', INVOCA_FOR_SF__transaction_id__c='1', INVOCA_FOR_SF__start_time_local__c=System.now(), INVOCA_FOR_SF__Customer_String_Value_2__c='Googleclick');
     insert dtCall1;
    /*BAU Changes*/
    //BAU Changes--Replacing DialogTech_Call__c by Invoca_Call_Log__c    
    Marketing_Call_Tracking__c[] mctList = [Select Id, Invoca_Call_Log__c, Account__c, Contact__c, Lead__c, MM_Call_Date__c, MM_caller_number__c, gclid__c 
              from Marketing_Call_Tracking__c];
    System.assertEquals(1, mctList.size());
    System.assertNotEquals(null, mctList[0].Lead__c);
    System.assertEquals('Googleclick', mctList[0].gclid__c);
 
    // match to a contact
    /*BAU Changes*/
    /*IBP__Ifbyphone_Call__c dtCall2 = new IBP__Ifbyphone_Call__c(Name='Test2', IBP__CallerID__c='5855551212', IBP__SessionID__c='2', IBP__DateAdded__c=System.now());
    insert dtCall2;*/
    INVOCA_FOR_SF__Invoca_Call_Log__c dtCall2 = new INVOCA_FOR_SF__Invoca_Call_Log__c(INVOCA_FOR_SF__advertiser_name__c='Test2', INVOCA_FOR_SF__calling_phone_number__c='5855551212', INVOCA_FOR_SF__transaction_id__c='2', INVOCA_FOR_SF__start_time_local__c=System.now());
    insert dtCall2;
    /*BAU Changes*/
    //BAU Changes--Replacing DialogTech_Call__c by Invoca_Call_Log__c
    mctList = [Select Id, Invoca_Call_Log__c, Account__c, Contact__c, Lead__c, MM_Call_Date__c, MM_caller_number__c 
              from Marketing_Call_Tracking__c where Contact__c != null];
    System.assertEquals(1, mctList.size());
    
    // no match
    fixedSoslResults = new List<Id>();
    Test.setFixedSearchResults(fixedSoslResults);
    /*BAU Changes*/
    /*IBP__Ifbyphone_Call__c dtCall3 = new IBP__Ifbyphone_Call__c(Name='Test3', IBP__CallerID__c='5855559999', IBP__SessionID__c='3', IBP__DateAdded__c=System.now());
    insert dtCall3;*/
    INVOCA_FOR_SF__Invoca_Call_Log__c dtCall3 = new INVOCA_FOR_SF__Invoca_Call_Log__c(INVOCA_FOR_SF__advertiser_name__c='Test3', INVOCA_FOR_SF__calling_phone_number__c='5855559999', INVOCA_FOR_SF__transaction_id__c='3', INVOCA_FOR_SF__start_time_local__c=System.now());
    insert dtCall3; 
    /*BAU Changes*/
    //BAU Changes--Replacing DialogTech_Call__c by Invoca_Call_Log__c
    mctList = [Select Id, Invoca_Call_Log__c, Account__c, Contact__c, Lead__c, MM_Call_Date__c, MM_caller_number__c 
              from Marketing_Call_Tracking__c where MM_Caller_number__c = '5855559999'];
    System.assertEquals(0, mctList.size());

    Lead updatedLead = [Select Id, Phone, MobilePhone from Lead where LastName = 'Last lead1'];    
    updatedLead.MobilePhone = '(585) 555-9999';
    update updatedLead;
  
    // get new sosl results
    fixedSoslResults = new List<Id>();
    fixedSoslResults.add(updatedLead.Id);
    //ldList = [select Id, phone from Lead];
    //for (Lead ld :ldList)
    //{  fixedSoslResults.add(ld.Id);  }
    Test.setFixedSearchResults(fixedSoslResults);
    
    dtCall3.createMCT__c = true;
    update dtCall3;
    //BAU Changes--Replacing DialogTech_Call__c by Invoca_Call_Log__c
    mctList = [Select Id, Invoca_Call_Log__c, Account__c, Contact__c, Lead__c, MM_Call_Date__c, MM_caller_number__c 
              from Marketing_Call_Tracking__c where Invoca_Call_Log__c = :dtCall3.Id];
    System.assertEquals(1, mctList.size());
  
    /*BAU Changes*/
    /*IBP__Ifbyphone_Call__c updatedCall = [select Id, createMCT__c, IBP__Lead__c from IBP__Ifbyphone_Call__c where id = :dtCall3.Id];
    System.assertEquals(false, updatedCall.createMCT__c);
    System.assertEquals(updatedLead.Id, updatedCall.IBP__Lead__c);*/
    INVOCA_FOR_SF__Invoca_Call_Log__c updatedCall = [select Id, createMCT__c, INVOCA_FOR_SF__Lead__c from INVOCA_FOR_SF__Invoca_Call_Log__c where id = :dtCall3.Id];
    System.assertEquals(false, updatedCall.createMCT__c);
    System.assertEquals(updatedLead.Id, updatedCall.INVOCA_FOR_SF__Lead__c);
    /*BAU Changes*/
    
    
} // testDialogTechCall
  
} // DialogTech_HelperTest