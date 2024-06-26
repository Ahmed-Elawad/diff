/* 
   DNC related methods
   
  History
  -------
  05/26/2017 Jermaine Stukes    Created 
  10/16/2018 Jake Hinds         Condensing code, adding check for record dnc
  01/08/2018 Dan Carmen         Modified to add some more flexibility
  10/15/2019 Dan Carmen         Modified to use TriggerMethods.clearVariables 
  01/25/2023 Dan Carmen         Change to TriggerInterfaceC, update API
  01/25/2024 Dan Carmen         Removed an unneeded methods, increment API

 */

@isTest
public class DNCHelperTest {
    
   @testSetup 
   static void setupData () {
      DNCQueueableTest.setupData();
      
        Account acct1 = new Account (name = 'Test Account'
                                     ,type = 'MMS Client'
                                     ,BillingPostalCode = '10000'
                                     ,AccountNumber = '11-A234567'
                                     ,Phone = '585-222-1111'
                                     ,Do_Not_Call__c = false
                                     ,Email_Opt_Out__c = false
                                     ,AnnualRevenue = 25);
        
        Account acct2 = new Account (name = 'Test Account2'
                                     ,type = 'MMS Client'
                                     ,BillingPostalCode = '10000'
                                     ,AccountNumber = '12-1234567'
                                     ,Phone = '585-222-4444'
                                     ,Do_Not_Call__c = false
                                     ,Email_Opt_Out__c = false
                                     ,AnnualRevenue = 25);
        ZipCheckOwner.SKIP_TRIGGERS=true;
        Account[] accts = new Account[]{acct1,acct2};
        insert accts;                             
        
        Contact con1 = new Contact(Firstname = 'First'
                                   ,Lastname = 'Contact'
                                   ,Phone = '585-222-1111'
                                   ,Email = 'contact@one.com'
                                   ,DoNotCall = false
                                   ,HasOptedOutOfEmail = false
                                   ,AccountId=acct1.Id);
                                   
        Contact con2 = new Contact(Firstname = 'Second'
                                   ,Lastname = 'Contact'
                                   ,Phone = '585-222-3333'
                                   ,Email = 'contact@two.com'
                                   ,DoNotCall = false
                                   ,HasOptedOutOfEmail = false
                                   ,AccountId=acct1.Id);
        
        Contact con3 = new Contact(Firstname = 'Third'
                                   ,Lastname = 'Contact'
                                   ,Phone = '585-555-2222'
                                   ,Email = 'testEmail@testMethod.com'
                                   ,DoNotCall = false
                                   ,HasOptedOutOfEmail = false
                                   ,AccountId=acct2.Id);
        
        Contact con4 = new Contact(Firstname = 'Fourth'
                                   ,Lastname = 'Contact'
                                   ,Phone = '585-555-2222'
                                   ,Email = 'testEmail@testMethod.com'
                                   ,DoNotCall = false
                                   ,HasOptedOutOfEmail = false
                                   ,AccountId=acct2.Id);
        Contact[] ctcts = new Contact[]{con1,con2,con3,con4};
        insert ctcts;
        ZipCheckOwner.SKIP_TRIGGERS=false;

   }   // setupData

    static testMethod void test_DoNotCall_ClientLevel_Case()
    {
      DNCHelper.skipUncheck = false;
        Schema.RecordTypeInfo caseDNCrt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case');
        User uzer = [Select Id, name, profile.Name, profileId, IsActive from User where profile.Name = 'System Administrator' and IsActive = true limit 1];
        
        test.startTest();
        //Test 
        String descrip = 'Below is the result..<br>';
        descrip += 'company: Test Account<br>';
        descrip += + 'branchnum: 0011<br>';
        descrip += 'clientnum: A234567<br>';
        descrip += 'phone: 585-222-1111<br>';
        descrip += 'donotcall: Do Not Call<br>';
        descrip += 'emailoptout: no<br>';
        descrip += 'entirecompany: True<br>';
        descrip += 'contactemail: sftest1abcd@test.com<br>';
        descrip += 'comments: Test Comment<br>';
        descrip += 'submitter: Jermaine Stukes<br>';
        
        Case case1 = new Case (recordtypeId = caseDNCrt.getRecordTypeId()
                          ,status = 'New'
                          ,origin = 'Web'
                          ,Send_Case_to_Service_Now__c = false
                          ,subject = 'Do Not Contact Request Form'
                          ,description = descrip
                          ,OwnerId = uzer.Id);              
        insert case1; 
        
        //Verify Reference Do Not Contact Created
        Reference_Do_Not_Contact__c testDNCRecord = [Select Id, CaseID__c,Name,Branch_Client_Num__c, Do_Not_Call_Client_Level__c, Email_Opt_Out_Client_Level__c,Contact_Phone__c,Contact_Email__c, Requestor__c from Reference_Do_Not_Contact__c where CaseID__c = :case1.Id limit 1];
        System.assertEquals(true, testDNCRecord.Do_Not_Call_Client_Level__c); 
        System.assertEquals(false, testDNCRecord.Email_Opt_Out_Client_Level__c); 
        System.assertEquals('5852221111', testDNCRecord.Contact_Phone__c); 
        System.assertEquals('sftest1abcd@test.com', testDNCRecord.Contact_Email__c); 
        System.assertEquals('Jermaine Stukes', testDNCRecord.Requestor__c); 
        System.assertEquals('11-A234567', testDNCRecord.Branch_Client_Num__c); 
        System.assertEquals('Do Not Call Requested', testDNCRecord.Name);
        test.stopTest();
        //both contacts and account should be marked dnc
        Account acct1 = [SELECT Id,Do_Not_Call__c,(SELECT Id,DoNotCall,HasOptedOutOfEmail FROM Contacts) FROM Account WHERE Name='Test Account' LIMIT 1];
        system.assertEquals(true,acct1.Do_Not_Call__c);
        for(Contact ctct:acct1.Contacts){
          system.assertEquals(true,ctct.DoNotCall);
        }
    }
    
    static testMethod void test_EOO_ClientLevel_Case()
    {
      DNCHelper.skipUncheck = false;
        Schema.RecordTypeInfo caseDNCrt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case');
        User uzer = [Select Id, name, profile.Name, profileId, IsActive from User where profile.Name = 'System Administrator' and IsActive = true limit 1];
        
        test.startTest();
        //Test 
        String descrip = 'Below is the result..<br>';
        descrip += 'company: Test Account<br>';
        descrip += 'branchnum: 0011<br>';
        descrip += 'clientnum: A234567<br>';
        descrip += 'phone: 585-222-1111<br>';
        descrip += 'donotcall: No<br>';
        descrip += 'emailoptout: Email Opt-out\\Unsubscribe<br>';
        descrip += 'entirecompany: True<br>';
        descrip += 'contactemail: sfTest1abcd@test.com<br>';
        descrip += 'comments: Test Comment<br>';
        descrip += 'submitter: Jermaine Stukes<br>';
        
        Case case1 = new Case (recordtypeId = caseDNCrt.getRecordTypeId()
                          ,status = 'New'
                          ,origin = 'Web'
                          ,subject = 'Do Not Contact Request Form'
                          ,description = descrip
                          ,OwnerId = uzer.Id);              
        insert case1; 
        
        //Verify Reference Do Not Contact Created
        Reference_Do_Not_Contact__c testDNCRecord = [Select Id, CaseID__c,Name,Branch_Client_Num__c, Do_Not_Call_Client_Level__c, Email_Opt_Out_Client_Level__c,Contact_Phone__c,Contact_Email__c, Requestor__c from Reference_Do_Not_Contact__c where CaseID__c = :case1.Id limit 1];
        System.assertEquals(false, testDNCRecord.Do_Not_Call_Client_Level__c); 
        System.assertEquals(true, testDNCRecord.Email_Opt_Out_Client_Level__c); 
        System.assertEquals('5852221111', testDNCRecord.Contact_Phone__c); 
        System.assertEquals('sfTest1abcd@test.com', testDNCRecord.Contact_Email__c); 
        System.assertEquals('Jermaine Stukes', testDNCRecord.Requestor__c); 
        System.assertEquals('11-A234567', testDNCRecord.Branch_Client_Num__c); 
        System.assertEquals('Email Opt Out Requested', testDNCRecord.Name);
        test.stopTest();
        //both contacts and account should be marked eoo
        Account acct1 = [SELECT Id,Email_Opt_Out__c,(SELECT Id,DoNotCall,HasOptedOutOfEmail FROM Contacts) FROM Account WHERE Name='Test Account' LIMIT 1];
        system.assertEquals(true,acct1.Email_Opt_Out__c);
        for(Contact ctct:acct1.Contacts){
          system.assertEquals(true,ctct.HasOptedOutOfEmail);
        }
    } // test_EOO_ClientLevel_Case
    
    static testMethod void test_Both_ClientLevel_Case()
    {        
      DNCHelper.skipUncheck = false;
        Schema.RecordTypeInfo caseDNCrt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case');
        User uzer = [Select Id, name, profile.Name, profileId, IsActive from User where profile.Name = 'System Administrator' and IsActive = true limit 1];
        
        test.startTest();
        //Test 
        String descrip = 'Below is the result..<br>';
        descrip += 'company: Test Account<br>';
        descrip += 'branchnum: 0011<br>';
        descrip += 'clientnum: A234567<br>';
        descrip += 'phone: 585-222-1111<br>';
        descrip += 'donotcall: Do Not Call<br>';
        descrip += 'emailoptout: Email Opt-out\\Unsubscribe<br>';
        descrip += 'entirecompany: True<br>';
        descrip += 'contactemail: sfTest1abcd@test.com<br>';
        descrip += 'comments: Test Comment<br>';
        descrip += 'submitter: Jermaine Stukes<br>';
        
        Case case1 = new Case (recordtypeId = caseDNCrt.getRecordTypeId()
                          ,status = 'New'
                          ,origin = 'Web'
                          ,subject = 'Do Not Contact Request Form'
                          ,description = descrip
                          ,OwnerId = uzer.Id);
        System.debug('test_Both_ClientLevel_Case before case insert');              
        insert case1;
        System.debug('test_Both_ClientLevel_Case after case insert');              
        
        //Verify Reference Do Not Contact Created
        Reference_Do_Not_Contact__c testDNCRecord = [Select Id, CaseID__c,Name,Branch_Client_Num__c, Do_Not_Call_Client_Level__c, Email_Opt_Out_Client_Level__c,Contact_Phone__c,Contact_Email__c, Requestor__c from Reference_Do_Not_Contact__c where CaseID__c = :case1.Id limit 1];
        System.assertEquals(true, testDNCRecord.Do_Not_Call_Client_Level__c); 
        System.assertEquals(true, testDNCRecord.Email_Opt_Out_Client_Level__c); 
        System.assertEquals('5852221111', testDNCRecord.Contact_Phone__c); 
        System.assertEquals('sfTest1abcd@test.com', testDNCRecord.Contact_Email__c); 
        System.assertEquals('Jermaine Stukes', testDNCRecord.Requestor__c); 
        System.assertEquals('11-A234567', testDNCRecord.Branch_Client_Num__c); 
        System.assertEquals('Do Not Call/Email Opt Out Requested', testDNCRecord.Name);
        test.stopTest();
        //both contacts and account should be marked eoo+dnc
        Account acct1 = [SELECT Id,Do_Not_Call__c,Email_Opt_Out__c,(SELECT Id,DoNotCall,HasOptedOutOfEmail FROM Contacts) FROM Account WHERE Name='Test Account' LIMIT 1];
        system.assertEquals(true, acct1.Email_Opt_Out__c);
        system.assertEquals(true, acct1.Do_Not_Call__c);
        for(Contact ctct:acct1.Contacts){
          system.assertEquals(true,ctct.HasOptedOutOfEmail);
          system.assertEquals(true,ctct.DoNotCall);
        }
    } // test_Both_ClientLevel_Case

    static testMethod void test_DoNotCall_ContactLevel_Case()
    {       
      DNCHelper.skipUncheck = false; 
        Schema.RecordTypeInfo caseDNCrt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case');
        User uzer = [Select Id, name, profile.Name, profileId, IsActive from User where profile.Name = 'System Administrator' and IsActive = true limit 1];
        
        //set fixed results, sosl doesn't return results for tests.
        Map<Id,Contact> contactResults = new Map<Id,Contact>([SELECT Id FROM Contact WHERE Phone='585-555-2222']);
        Id[]fixedSearchResults = new Id[]{};
        fixedSearchResults.addAll(contactResults.keySet());
        Test.setFixedSearchResults(fixedSearchResults);
        test.startTest();
        //Test 
        String descrip = 'Below is the result..<br>';
        descrip += 'company: Test Account2<br>';
        descrip += 'branchnum: 0012<br>';
        descrip += 'clientnum: 1234567<br>';
        descrip += 'phone: 585-555-2222<br>';
        descrip += 'donotcall: Do Not Call<br>';
        descrip += 'emailoptout: No<br>';
        descrip += 'entirecompany: False<br>';
        descrip += 'contactemail: sfTest1abcd@test.com<br>';
        descrip += 'comments: Test Comment<br>';
        descrip += 'submitter: Jermaine Stukes<br>';
        
        Case case1 = new Case (recordtypeId = caseDNCrt.getRecordTypeId()
                          ,status = 'New'
                          ,origin = 'Web'
                          ,subject = 'Do Not Contact Request Form'
                          ,description = descrip
                          ,OwnerId = uzer.Id);              
        insert case1;
        
        //Verify Reference Do Not Contact Created
        Reference_Do_Not_Contact__c testDNCRecord = [Select Id, CaseID__c,Name,Branch_Client_Num__c, Do_Not_Call_Client_Level__c, Email_Opt_Out_Client_Level__c,Do_Not_Call_Contact_Level__c,Email_Opt_Out_Contact_Level__c,Contact_Phone__c,Contact_Email__c, Requestor__c from Reference_Do_Not_Contact__c where CaseID__c = :case1.Id limit 1];
        System.assertEquals(false, testDNCRecord.Do_Not_Call_Client_Level__c); 
        System.assertEquals(false, testDNCRecord.Email_Opt_Out_Client_Level__c); 
        System.assertEquals(true, testDNCRecord.Do_Not_Call_Contact_Level__c); 
        System.assertEquals(false, testDNCRecord.Email_Opt_Out_Contact_Level__c); 
        System.assertEquals('5855552222', testDNCRecord.Contact_Phone__c); 
        System.assertEquals('Jermaine Stukes', testDNCRecord.Requestor__c); 
        System.assertEquals('12-1234567', testDNCRecord.Branch_Client_Num__c); 
        System.assertEquals('Do Not Call Requested', testDNCRecord.Name);
        test.stopTest();
        //should get two contacts back since there are two with that phone number.  Both should have dnc.
        Contact[] ctcts = [SELECT Id,DoNotCall,HasOptedOutOfEmail FROM Contact WHERE Phone='585-555-2222'];
        system.assertEquals(2,ctcts.size());
        for(Contact ctct:ctcts){
          system.assertEquals(true, ctct.DoNotCall);
        }
    }
    
    static testMethod void test_EOO_ContactLevel_Case()
    {
      DNCHelper.skipUncheck = false;
        Schema.RecordTypeInfo caseDNCrt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case');
        User uzer = [Select Id, name, profile.Name, profileId, IsActive from User where profile.Name = 'System Administrator' and IsActive = true limit 1];
        
        //set fixed results, sosl doesn't return results for tests.
        Map<Id,Contact> contactResults = new Map<Id,Contact>([SELECT Id,Email FROM Contact WHERE Email='testEmail@testMethod.com']);
        system.debug('contactResults'+contactResults);
        Id[]fixedSearchResults = new Id[]{};
        fixedSearchResults.addAll(contactResults.keySet());
        Test.setFixedSearchResults(fixedSearchResults);
                
        test.startTest();
        //Test 
        String descrip = 'Below is the result..<br>';
        descrip += 'company: Test Account2<br>';
        descrip += 'branchnum: 0012<br>';
        descrip += 'clientnum: 1234567<br>';
        descrip += 'phone: 585-555-2222<br>';
        descrip += 'donotcall: No<br>';
        descrip += 'emailoptout: Email Opt-out\\Unsubscribe<br>';
        descrip += 'entirecompany: False<br>';
        descrip += 'contactemail: testEmail@testMethod.com<br>';
        descrip += 'comments: Test Comment<br>';
        descrip += 'submitter: Jermaine Stukes<br>';
        
        Case case1 = new Case (recordtypeId = caseDNCrt.getRecordTypeId()
                          ,status = 'New'
                          ,origin = 'Web'
                          ,subject = 'Do Not Contact Request Form'
                          ,description = descrip
                          ,OwnerId = uzer.Id);              
        insert case1; 
        
        //Verify Reference Do Not Contact Created
        Reference_Do_Not_Contact__c testDNCRecord = [Select Id, CaseID__c,Name,Branch_Client_Num__c, Do_Not_Call_Client_Level__c, Email_Opt_Out_Client_Level__c,Do_Not_Call_Contact_Level__c,Email_Opt_Out_Contact_Level__c,Contact_Phone__c,Contact_Email__c, Requestor__c from Reference_Do_Not_Contact__c where CaseID__c = :case1.Id limit 1];
        System.assertEquals(false, testDNCRecord.Do_Not_Call_Client_Level__c); 
        System.assertEquals(false, testDNCRecord.Email_Opt_Out_Client_Level__c); 
        System.assertEquals(false, testDNCRecord.Do_Not_Call_Contact_Level__c); 
        System.assertEquals(true, testDNCRecord.Email_Opt_Out_Contact_Level__c); 
        System.assertEquals('5855552222', testDNCRecord.Contact_Phone__c); 
        System.assertEquals('Jermaine Stukes', testDNCRecord.Requestor__c); 
        System.assertEquals('12-1234567', testDNCRecord.Branch_Client_Num__c); 
        System.assertEquals('Email Opt Out Requested', testDNCRecord.Name);
        test.stopTest();
        
        //should get two contacts back since there are two with that email.  Both should have eoo.
        Contact[] ctcts = [SELECT Id,DoNotCall,HasOptedOutOfEmail FROM Contact WHERE Email='testEmail@testMethod.com'];
        system.debug('DNCHelperTest contact after update: '+ctcts);
        system.assertEquals(2,ctcts.size());
        for(Contact ctct:ctcts){
          system.assertEquals(true, ctct.HasOptedOutOfEmail);
        }
    } // test_EOO_ContactLevel_Case
    
     static testMethod void test_Both_ContactLevel_Case()
    {       
      DNCHelper.skipUncheck = false; 
        Schema.RecordTypeInfo caseDNCrt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case');
        User uzer = [Select Id, name, profile.Name, profileId, IsActive from User where profile.Name = 'System Administrator' and IsActive = true limit 1];
        
        //set fixed results, sosl doesn't return results for tests.
        Map<Id,Contact> contactResults = new Map<Id,Contact>([SELECT Id,Email FROM Contact WHERE Phone = '585-555-2222' OR Email='testEmail@testMethod.com']);
        system.debug('contactResults'+contactResults);
        Id[]fixedSearchResults = new Id[]{};
        fixedSearchResults.addAll(contactResults.keySet());
        Test.setFixedSearchResults(fixedSearchResults);
        
        test.startTest();
        //Test 
        String descrip = 'Below is the result..<br>';
        descrip += 'company: Test Account<br>';
        descrip += 'branchnum: 0011<br>';
        descrip += 'clientnum: A234567<br>';
        descrip += 'phone: 585-222-1111<br>';
        descrip += 'donotcall: Do Not Call<br>';
        descrip += 'emailoptout: Email Opt-out\\Unsubscribe<br>';
        descrip += 'entirecompany: False<br>';
        descrip += 'contactemail: testEmail@testMethod.com<br>';
        descrip += 'comments: Test Comment<br>';
        descrip += 'submitter: Jermaine Stukes<br>';
        
        Case case1 = new Case (recordtypeId = caseDNCrt.getRecordTypeId()
                          ,status = 'New'
                          ,origin = 'Web'
                          ,subject = 'Do Not Contact Request Form'
                          ,description = descrip
                          ,OwnerId = uzer.Id);              
        insert case1;
        
        //Verify Reference Do Not Contact Created
        Reference_Do_Not_Contact__c testDNCRecord = [Select Id, CaseID__c,Name,Branch_Client_Num__c, Do_Not_Call_Client_Level__c, Email_Opt_Out_Client_Level__c,Do_Not_Call_Contact_Level__c,Email_Opt_Out_Contact_Level__c,Contact_Phone__c,Contact_Email__c, Requestor__c from Reference_Do_Not_Contact__c where CaseID__c = :case1.Id limit 1];
        System.assertEquals(false, testDNCRecord.Do_Not_Call_Client_Level__c); 
        System.assertEquals(false, testDNCRecord.Email_Opt_Out_Client_Level__c); 
        System.assertEquals(true, testDNCRecord.Do_Not_Call_Contact_Level__c); 
        System.assertEquals(true, testDNCRecord.Email_Opt_Out_Contact_Level__c); 
        System.assertEquals('Do Not Call/Email Opt Out Requested', testDNCRecord.Name);
        test.stopTest();
        
        //should get two contacts back since there are two with that phone number.  Both should have dnc.
        Contact[] ctcts = [SELECT Id,Name, DoNotCall,HasOptedOutOfEmail FROM Contact WHERE Phone='585-555-2222' OR Email='testEmail@testMethod.com'];
        system.assertEquals(2,ctcts.size());
        for(Contact ctct:ctcts){
          System.debug('test_Both_ContactLevel_Case ctct='+ctct);
          system.assertEquals(true, ctct.DoNotCall);
          system.assertEquals(true, ctct.HasOptedOutOfEmail);
        }
    } // test_Both_ContactLevel_Case

    static testMethod void testConsentToTextLead() {
       // to run as lead loader
      //User runningUser = UserHelper.getRunningUser();
      //ProcessNameMap__c pnm = new ProcessNameMap__c(Name=UserHelper.PREFIX_LL+runningUser.Name,IsActive__c=true);
      //insert pnm;
      //System.runAs(runningUser) {
      
      Lead ld1 = new Lead(LastName='Lead1', Company='Lead Company1', PostalCode='12345', MobilePhone='(585) 555-1234', Consent_to_Text__c=true);
      Lead ld2 = new Lead(LastName='Lead2', Company='Lead Company2', PostalCode='12345', MobilePhone='(585) 555-1235', Consent_to_Text__c=false);
      Lead[] leads = new Lead[]{ld1,ld2};
      insert leads;
      
      Map<Id,Lead> leadMap = new Map<Id,Lead>([Select Id, LastName, MobilePhone, Consent_to_Text__c, Consent_to_Text_Date__c, Consent_to_Text_reason__c from Lead]);
      
      System.assertEquals(1,[select count() from Reference_Do_Not_Contact__c where Lead__c=:ld1.Id]);
      
      ld1 = leadMap.get(ld1.Id);
      System.assertEquals(true,ld1.Consent_to_Text__c);
      System.assertEquals(Date.today(), ld1.Consent_to_Text_Date__c.date());
      System.assertEquals('User change', ld1.Consent_to_Text_reason__c);
      
      ld2 = leadMap.get(ld2.Id);
      System.assertEquals(false,ld2.Consent_to_Text__c);
      System.assertEquals(null, ld2.Consent_to_Text_Date__c);
      System.assertEquals(null, ld2.Consent_to_Text_reason__c);

      ld2.Consent_to_Text__c=true;
      ld1.Consent_to_Text_Date__c = Datetime.now().addDays(-2);  // to make sure the date updates
      ld1.MobilePhone='(585) 555-1236';
      leads = new Lead[]{ld1,ld2};
      TriggerMethods.clearVariables();
      update leads;
      
      leadMap = new Map<Id,Lead>([Select Id, LastName, MobilePhone, Consent_to_Text__c, Consent_to_Text_Date__c, Consent_to_Text_reason__c from Lead]);
      
      ld1 = leadMap.get(ld1.Id);
      System.assertEquals(false,ld1.Consent_to_Text__c);
      System.assertEquals(Date.today(), ld1.Consent_to_Text_Date__c.date());
      System.assertEquals('Mobile Phone change', ld1.Consent_to_Text_reason__c);
      
      ld2 = leadMap.get(ld2.Id);
      System.assertEquals(true,ld2.Consent_to_Text__c);
      System.assertEquals(Date.today(), ld2.Consent_to_Text_Date__c.date());
      System.assertEquals('User change', ld2.Consent_to_Text_reason__c);
    } // testConsentToTextLead
    
   static testMethod void testConsentToTextContact() {
      Account acct1 = new Account(Name='Account1');
      Account acct2 = new Account(Name='Account2');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      Account[] accts = new Account[]{acct1,acct2};
      insert accts;
       
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='Contact1', MobilePhone='(585) 555-1234', Consent_to_Text__c=true);
      Contact ctct2 = new Contact(AccountId=acct2.Id, LastName='Contact2', MobilePhone='(585) 555-1235', Consent_to_Text__c=false);
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      insert ctcts;
       
      Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id, LastName, MobilePhone, Consent_to_Text__c, Consent_to_Text_Date__c, Consent_to_Text_reason__c from Contact]);

      System.assertEquals(1,[select count() from Reference_Do_Not_Contact__c where Contact__c=:ctct1.Id]);
      
      ctct1 = ctctMap.get(ctct1.Id);
      System.assertEquals(true,ctct1.Consent_to_Text__c);
      System.assertEquals(Date.today(), ctct1.Consent_to_Text_Date__c.date());
      System.assertEquals('User change', ctct1.Consent_to_Text_reason__c);
      
      ctct2 = ctctMap.get(ctct2.Id);
      System.assertEquals(false,ctct2.Consent_to_Text__c);
      System.assertEquals(null, ctct2.Consent_to_Text_Date__c);
      System.assertEquals(null, ctct2.Consent_to_Text_reason__c);
 
    } // testConsentToTextContact

} // class DNCHelperTest