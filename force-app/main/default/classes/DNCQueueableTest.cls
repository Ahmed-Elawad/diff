/* 
   DNC Queueable job test
   
  History
  -------
  06/28/2018 Jake Hinds        Created
  01/08/2018 Dan Carmen        Modified to add some more flexibility 
  10/30/2019 Cindy Freeman	   took out tests checking for flags to be cleared if there is no match
  04/02/2020 Cindy Freeman	   added batchsize for more test coverage
  09/15/2020 Dan Carmen         Don't launch queueable if in a batch/future/queueable context
  01/25/2023 Dan Carmen        Increment API, use TriggerMethodsTest.createTriggerSetting

*/
@isTest
public class DNCQueueableTest {

   @testSetup 
   public static void setupData() {
      setupTriggerClasses();
      
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = DNCQueueable.CLASS_NAME, Active__c = true, BatchSize__c = 10);
      insert abc; 
      
      Id acctRtId = RecordTypeHelper.getRecordType('Core Account Record Type', 'Account').getRecordTypeId();
      Id cort = RecordTypeHelper.getRecordType('Core Contact Record Type', 'Contact').getRecordTypeId();
      
      Account acct1a = new Account(Name='testAcct1a');
      Account acct1b = new Account(RecordTypeId=acctRtId,Name='Acct1b');
      Account acct2b = new Account(RecordTypeId=acctRtId,Name='Acct2b');
      Account acct3b = new Account(RecordTypeId=acctRtId,Name='Acct3b');
      Account[] accts = new Account[]{acct1a,acct1b,acct2b,acct3b};
      insert accts;
      
      //ctct1 base record for initial matches
      Contact ctct1a = new Contact(AccountId=acct1a.Id,FirstName='testa',LastName='contact1',phone='1234567890',mobilephone='0987654321',email='test@te.st',DoNotCall=true,Consent_to_Text__c=true,HasOptedOutOfEmail=true);
      Contact ctct2a = new Contact(AccountId=acct1a.Id,FirstName='testa',LastName='contact2');
      Contact ctct3a = new Contact(AccountId=acct1a.Id,FirstName='testa',LastName='contact3');
      Contact ctct4a = new Contact(AccountId=acct1a.Id,FirstName='testa',LastName='contact4',MobilePhone='5555555555',email='test2@te.st',DoNotCall=true,Consent_to_Text__c=true,HasOptedOutOfEmail=true);
      Contact ctct5a = new Contact(AccountId=acct1a.Id,FirstName='testa',LastName='contact5',MobilePhone='3333333333',email='test6@te.st',DoNotCall=true,Consent_to_Text__c=true,HasOptedOutOfEmail=true);
      Contact ctct1b = new Contact(RecordTypeId=cort,AccountId=acct1b.Id,FirstName='testb',LastName='contact1',phone='1111111111',mobilephone='2222222222',email='test1@te.st');
      Contact ctct2b = new Contact(RecordTypeId=cort,AccountId=acct1b.Id,FirstName='testb',LastName='contact2',phone='1111111111',mobilephone='2222222222',email='test1@te.st');
      Contact ctct3b = new Contact(RecordTypeId=cort,AccountId=acct2b.Id,FirstName='testb',LastName='contact3',phone='3333333333',mobilephone='4444444444',email='test2@te.st');
      Contact ctct4b = new Contact(RecordTypeId=cort,AccountId=acct2b.Id,FirstName='testb',LastName='contact4',phone='3333333333',mobilephone='4444444444',email='test2@te.st');
      Contact ctct5b = new Contact(RecordTypeId=cort,AccountId=acct3b.Id,FirstName='testb',LastName='contact5',phone='5555555555');
     
      Contact[] ctcts = new Contact[]{ctct1a,ctct2a,ctct3a,ctct4a,ctct5a,ctct1b,ctct2b,ctct3b,ctct4b,ctct5b};
      insert ctcts;
      
      //ld1 base record for initial matches
      Lead ld1a = new Lead(FirstName='testa',LastName='lead1',Company='testerguys',email='test3@te.st',HasOptedOutOfEmail=true,MobilePhone='9999999999',DoNotCall=true,Consent_to_Text__c=true);
      Lead ld2a = new Lead(FirstName='testa',LastName='lead2',Company='mr.test');
      Lead ld3a = new Lead(FirstName='testa',LastName='lead3',Company='TESTCO',MobilePhone='8888888888',email='test4@te.st',DoNotCall=true,Consent_to_Text__c=true,HasOptedOutOfEmail=true);
      Lead ld4a = new Lead(FirstName='testa',LastName='lead4',Company='best test',MobilePhone='9999999999',email='test5@te.st',DoNotCall=true,Consent_to_Text__c=true,HasOptedOutOfEmail=true);
      Lead ld1b = new Lead(FirstName='testb',LastName='lead1',Company='testerguys',email='test3@te.st',MobilePhone='5555555555',Consent_to_Text__c=true);
      Lead[] lds = new Lead[]{ld1a,ld2a,ld3a,ld4a,ld1b};
      insert lds;
 
      Id cart = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case').getRecordTypeId();
      Case c1 = new Case(RecordTypeId=cart,Subject='testcase1',Type='Do Not Contact',Sub_Type__c='Do Not Call',AccountId=ctct3b.AccountId,Expiration_Date__c = date.today());
      Case c2 = new Case(RecordTypeId=cart,Subject='testcase2',Type='Do Not Contact',Sub_Type__c='Email Opt Out',ContactId=ctct1b.Id,AccountId=ctct1b.AccountId);
      Case c3 = new Case(RecordTypeId=cart,Subject='testcase3',Type='Do Not Contact',Sub_Type__c='Text Opt Out',Lead__c=ld1b.Id);
      Case c4 = new Case(RecordTypeId=cart,Subject='testcase4',Type='Do Not Contact',Sub_Type__c='Do Not Call',ContactId=ctct5b.Id,AccountId=ctct5b.AccountId,Expiration_Date__c = date.today());
      Case[] cases = new Case[]{c1,c2,c3,c4};
      insert cases;
       
      Reference_Do_Not_Contact__c dnc1 = new Reference_Do_Not_Contact__c(Name='dnc1', CaseID__c=c1.Id,Status__c='New');
      Reference_Do_Not_Contact__c dnc2 = new Reference_Do_Not_Contact__c(Name='dnc2', CaseID__c=c2.Id,Status__c='New');
      Reference_Do_Not_Contact__c dnc3 = new Reference_Do_Not_Contact__c(Name='dnc3', CaseID__c=c3.Id,Status__c='New');
      Reference_Do_Not_Contact__c dnc4 = new Reference_Do_Not_Contact__c(Name='dnc4', CaseID__c=c4.Id,Status__c='New');
      Reference_Do_Not_Contact__c[] dncs = new Reference_Do_Not_Contact__c[]{dnc1,dnc2,dnc3,dnc4};
      insert dncs;
 
   } // setupData
   
   public static void setupTriggerClasses() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false,new String[]{'DNCHelper'});
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false,new String[]{'DNCHelper'});
      TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false,new String[]{'DNCHelper'});
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false,new String[]{'DNCHelper'});
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false,new String[]{'DNCHelper'});
      TriggerMethodsTest.createTriggerSetting('CaseAfter', false, true, false, false,new String[]{'DNCHelper'});
      TriggerMethodsTest.saveSetupClasses();

   } // setupTriggerClasses
   
   public static Map<String,Contact> getTestContacts(String firstName) {
      Map<String, Contact> ctctMap = new Map<String, Contact>();
      Contact[] ctcts = [Select Id, AccountId, FirstName, LastName, Name, Phone, MobilePhone, Email, DoNotCall, Consent_to_Text__c, HasOptedOutOfEmail from Contact where FirstName=:firstName];
      for (Contact ctct : ctcts) {
         ctctMap.put(ctct.LastName, ctct);
      }
      return ctctMap;
   } // getTestContacts
   
   public static Map<String, Lead> getTestLeads(String firstName) {
      Map<String, Lead> leadMap = new Map<String, Lead>();
      Lead[] leads = [Select Id, FirstName, LastName, Name, Company, Email, Phone, MobilePhone, HasOptedOutOfEmail, DoNotCall, Consent_to_Text__c from Lead where FirstName=:firstName];
      for (Lead ld : leads) {
         leadMap.put(ld.LastName, ld);
      }
      return leadMap;
   } // getTestLeads
   
   public static Map<String,Reference_Do_Not_Contact__c> getRefDNCMap() {
      Map<String,Reference_Do_Not_Contact__c> refMap = new Map<String,Reference_Do_Not_Contact__c>();
      Reference_Do_Not_Contact__c[] refs = [Select Id, Name, CaseID__c, Status__c from Reference_Do_Not_Contact__c where Name like 'dnc%'];
      for (Reference_Do_Not_Contact__c ref : refs) {
         refMap.put(ref.Name, ref);
      }
      return refMap;
   } // getRefDNCMap

   //when a record has its phone or email updated, find matching records that may have dnc/eoo and mark the updated records accordingly
   static testMethod void testCheckContactDNC() {
      DNCHelper.skipUncheck = false;
      DNCQueueable.SKIP_QUEUEABLE=true;
      Map<String,Contact> ctctMap = getTestContacts('testa');
      Map<String, Lead> leadMap = getTestLeads('testa');
      Lead ld1 = leadMap.get('lead1');
      Contact ctct1 = ctctMap.get('contact1');
      Contact ctct2 = ctctMap.get('contact2');
      Contact ctct3 = ctctMap.get('contact3');
      Contact ctct4 = ctctMap.get('contact4');
      Contact ctct5 = ctctMap.get('contact5');
      
      System.assertEquals(true,ctct1.DoNotCall);
      System.assertEquals(true,ctct1.Consent_to_Text__c);
      System.assertEquals(true,ctct1.HasOptedOutOfEmail);

      //have to set fixed results for SOSL,sosl doesn't actually return values in tests, need to set results.
      Id[]fixedSearchResults = new Id[]{ld1.Id,ctct1.Id};
      Test.setFixedSearchResults(fixedSearchResults);
        
      //updated to match dnc+eoo, match on ctct1 phone+email
      ctct2.MobilePhone = ctct1.MobilePhone;
      ctct2.email = ctct1.email;
      //updated to match dnc and consent to text, match on ctct1 phone
      ctct3.Phone = ctct1.phone;
      //updated to clear all, phone and email changed with no match
      ctct4.MobilePhone='4444444444';
      ctct4.Email = 'clearEOO@dnc.test';
      ctct5.MobilePhone='';
      ctct5.Email='';
      //updated to match eoo, match on ld1 email
      //Contact ctct6 = new Contact(FirstName='test',LastName='contact6',email=ld1.email);
      Contact[] ctcts = new Contact[]{ctct2,ctct3,ctct4,ctct5}; //,ctct6};

      DNCQueueable.SKIP_QUEUEABLE = false;
      DNCHelper.DNC_CHECKED = false;
      Test.startTest();
      System.debug('testCheckContactDNC start upsert ctcts');
      update ctcts;
      Test.stopTest();
        
      Contact[] uCtcts = [SELECT Id,LastName,HasOptedOutOfEmail,DoNotCall,Consent_to_Text__c FROM Contact WHERE Id in :ctcts ORDER BY LastName ASC];
      Contact uCtct2 = uCtcts[0];
      Contact uCtct3 = uCtcts[1];
      Contact uCtct4 = uCtcts[2];
      Contact uCtct5 = uCtcts[3];
      //Contact uCtct6 = uCtcts[4];
        
      //updated to match dnc+eoo, match on ctct1 phone+email
      system.debug('updated contact 2'+uCtct2);
      system.assertEquals(true,uCtct2.DoNotCall);
      system.assertEquals(true,uCtct2.Consent_to_Text__c);
      system.assertEquals(true,uCtct2.HasOptedOutOfEmail);

      //updated to match dnc, match on ctct1 phone
      system.debug('updated contact 3'+uCtct3);
      system.assertEquals(true,uCtct3.DoNotCall);
      system.assertEquals(false,uCtct3.Consent_to_Text__c);
      system.assertEquals(false,uCtct3.HasOptedOutOfEmail);
        
      //updated to clear all, phone and email changed with no match, not done anymore 10/20/19
      system.debug('updated contact 4'+uCtct4);
      //system.assertEquals(false,uCtct4.DoNotCall);
      //system.assertEquals(false,uCtct4.Consent_to_Text__c);
      //system.assertEquals(false,uCtct4.HasOptedOutOfEmail);
        
      //should have been cleared by before trigger
      system.debug('updated contact 5'+uCtct5);
      system.assertEquals(false,uCtct5.DoNotCall);
      system.assertEquals(false,uCtct5.Consent_to_Text__c);
      system.assertEquals(false,uCtct5.HasOptedOutOfEmail);
      //  for some reason, the contact trigger won't fire the insert on this record?
      //updated to match eoo, match on ld1 email
      //system.debug('updated contact 6'+uCtct6);
      //system.assertEquals(false,uCtct6.DoNotCall);
      //system.assertEquals(false,uCtct6.Consent_to_Text__c);
      //system.assertEquals(true,uCtct6.HasOptedOutOfEmail);

   } // testCheckContactDNC

   static testMethod void testCheckLeadDNC() {
      DNCHelper.skipUncheck = false;
      Map<String,Contact> ctctMap = getTestContacts('testa');
      Map<String, Lead> leadMap = getTestLeads('testa');
      Lead ld1 = leadMap.get('lead1');
      Lead ld2 = leadMap.get('lead2');
      Lead ld3 = leadMap.get('lead3');
      Lead ld4 = leadMap.get('lead4');
      Contact ctct1 = ctctMap.get('contact1');

      //have to set fixed results for SOSL,sosl doesn't actually return values in tests, need to set results.
      Id[]fixedSearchResults = new Id[]{ld1.Id,ctct1.Id};
      Test.setFixedSearchResults(fixedSearchResults);
        
      Test.startTest();
        
      //update to match dnc, match on ld1 mobile
      ld2.MobilePhone = ld1.MobilePhone;
      //update to not match anything, should clear dnc+eoo
      ld3.MobilePhone = '2222222222';
      ld3.Email = 'clearEOOLead@dnc.test';
      //update to clear mobile+email, before trigger should clear dnc+eoo
      ld4.MobilePhone = '';
      ld4.Email = '';
      //insert to match ctct1 eoo
      //Lead ld5 = new Lead(FirstName='test',LastName='lead5',Company='test inc.',Email=ctct1.email);
      Lead[] lds = new Lead[]{ld2,ld3,ld4}; //,ld5};
      System.debug('testCheckLeadDNC before upsert');
      upsert lds;
      //update ld2;
        
      Test.stopTest();
      System.debug('testCheckLeadDNC after upsert');
      
      Map<Id,Lead> uLeadMap = new Map<Id,Lead>([SELECT Id,LastName,HasOptedOutOfEmail,DoNotCall,Consent_to_Text__c FROM Lead WHERE Id in :lds]);
      Lead uLd2 = uLeadMap.get(ld2.Id);
      Lead uLd3 = uLeadMap.get(ld3.Id);
      Lead uLd4 = uLeadMap.get(ld4.Id);
      //Lead uLd5 = uLeadMap.get(ld5.Id);

      //updated to match dnc+eoo, match on ctct1 phone+email
      system.debug('updated lead 2'+uLd2);
      system.assertEquals(true,uLd2.DoNotCall);
      system.assertEquals(true,uLd2.Consent_to_Text__c);
      system.assertEquals(false,uLd2.HasOptedOutOfEmail);

      //updated to clear all, phone and email changed with no match, not done anymore 10/20/19
      system.debug('updated lead 3'+uld3);
      //system.assertEquals(false,uLd3.DoNotCall);
      //system.assertEquals(false,uLd3.Consent_to_Text__c);
      //system.assertEquals(false,uLd3.HasOptedOutOfEmail);
        
      //dnc and eoo cleared by before trigger
      system.debug('updated lead 4'+uLd4);
      system.assertEquals(false,uLd4.DoNotCall);
      system.assertEquals(false,uLd4.Consent_to_Text__c);
      system.assertEquals(false,uLd4.HasOptedOutOfEmail);
        
      //updated to match dnc, match on ctct1 phone
      //system.debug('updated lead 5'+uLd5);
      //system.assertEquals(false,uLd5.DoNotCall);
      //system.assertEquals(false,uLd5.Consent_to_Text__c);
      //system.assertEquals(true,uLd5.HasOptedOutOfEmail);

   } // testCheckLeadDNC


   static testMethod void testCaseCompletion1() {
      runCaseCompletionTest('dnc1');
   } // testCaseCompletion1

   static testMethod void testCaseCompletion2() {
      runCaseCompletionTest('dnc2');
   } // testCaseCompletion1

   static testMethod void testCaseCompletion3() {
      runCaseCompletionTest('dnc3');
   } // testCaseCompletion1

   static testMethod void testCaseCompletion4() {
      runCaseCompletionTest('dnc4');
   } // testCaseCompletion1

   public static void runCaseCompletionTest(String testName) {
      System.debug('runCaseCompletionTest testName='+testName);
      DNCHelper.skipUncheck = false;
      
      Map<String,Contact> ctctMap = getTestContacts('testb');
      Map<String, Lead> leadMap = getTestLeads('testb');
      Lead ld1 = leadMap.get('lead1');
      Contact ctct1 = ctctMap.get('contact1');
      Contact ctct2 = ctctMap.get('contact2');
      Contact ctct3 = ctctMap.get('contact3');
      Contact ctct4 = ctctMap.get('contact4');
      Contact ctct5 = ctctMap.get('contact5');

      Id[] ctctIds = new Id[]{ctct1.Id,ctct2.Id,ctct3.Id,ctct4.Id,ctct5.Id};

      Map<String,Reference_Do_Not_Contact__c> refMap = getRefDNCMap();
      Reference_Do_Not_Contact__c dnc = refMap.get(testName);
       
      //have to spoof sosl results, sosl doesn't return anything in tests :(
      Id[]fixedSearchResults = new Id[]{ld1.Id,ctct1.Id,ctct2.Id,ctct5.Id};
      Test.setFixedSearchResults(fixedSearchResults);
      
      System.debug('runCaseCompletionTest before the update');
      Test.startTest();
      dnc.Status__c='Completed';
      update dnc;
      Test.stopTest();
      System.debug('runCaseCompletionTest after the update');
       
      //Contact[] uCtcts = [SELECT Id,Phone,MobilePhone,OtherPhone,Email,DoNotCall,Consent_to_Text__c,HasOptedOutOfEmail,DNC_Expiration__c FROM Contact WHERE Id in:ctctIds ORDER BY LastName ASC];
      Map<Id,Contact> uCtctMap = new Map<Id,Contact> ([SELECT Id,Phone,MobilePhone,OtherPhone,Email,DoNotCall,Consent_to_Text__c,HasOptedOutOfEmail,DNC_Expiration__c FROM Contact WHERE Id in:ctctIds ORDER BY LastName ASC]);
      Contact uCtct1 = uCtctMap.get(ctct1.Id);
      Contact uCtct2 = uCtctMap.get(ctct2.Id);
      Contact uCtct3 = uCtctMap.get(ctct3.Id);
      Contact uCtct4 = uCtctMap.get(ctct4.Id);
      Contact uCtct5 = uCtctMap.get(ctct5.Id);
       
      //updated to match dnc+eoo, match on ctct1 phone+email
      System.debug('runCaseCompletionTest checking results testName='+testName);
      if (testName == 'dnc2') {
         system.debug('updated contact 1'+uCtct1);
         system.assertEquals(true,uCtct1.HasOptedOutOfEmail);
         system.debug('updated contact 2'+uCtct2);
         system.assertEquals(true,uCtct2.HasOptedOutOfEmail);
      }
      if (testName == 'dnc1') {
         system.debug('testCaseCompletion1 updated contact 3'+uCtct3);
         system.assertEquals(true,uCtct3.DoNotCall);
         system.assertEquals(date.today(),uCtct3.DNC_Expiration__c);
         system.debug('testCaseCompletion1 updated contact 4'+uCtct4);
         system.assertEquals(true,uCtct4.DoNotCall);
         system.assertEquals(date.today(),uCtct4.DNC_Expiration__c);
      }
      if (testName == 'dnc4') {
         system.debug('updated contact 5'+uCtct5);
         system.assertEquals(true,uCtct5.DoNotCall);
         system.assertEquals(date.today(),uCtct5.DNC_Expiration__c);
      }
      if (testName == 'dnc3') {
         Lead uLd = [SELECT Id,DoNotCall,Consent_to_Text__c,HasOptedOutOfEmail FROM Lead WHERE Id=:ld1.Id LIMIT 1];
         system.assertEquals(false,uLd.Consent_to_Text__c);
         // since I split the tests out, the following assertion will not be set (it's based on dnc4)
         //system.assertEquals(true,uLd.DoNotCall);
      }        
       
   } // testCaseCompletion1

   static testMethod void testBatchSize() {
       DNCQueueable dncQueue = new DNCQueueable();
      
      Account acct1a = new Account(Name='testBatchSize');
      insert acct1a;      
      for (Integer cnt=10; cnt< 30; cnt++) {
      		Contact ctct = new Contact(AccountId=acct1a.Id,FirstName='test'+cnt+'name',LastName='contact'+cnt,phone='12345678'+cnt, Email='testBatch'+cnt+'@testing.com');
      		insert ctct;
      		dncQueue.addToQueue('checkPhone','Lead/Contact', null, ctct.Id, null);      		
      }
      System.assertEquals(1,dncQueue.wrappersToProcessList.size());
      
      DNCQueueable.DNCWrapper dncWrap = dncQueue.wrappersToProcessList.remove(0);
      //System.assertEquals(0,dncQueue.wrappersToProcessList.size()); // should be 0 since removed 1
      dncQueue.checkSearchIds(dncWrap);
      System.assertEquals(10,dncWrap.searchOpMap.size());        
      System.assertEquals(1,dncQueue.wrappersToProcessList.size());  // coz cloned wrapper
      
   } // testBatchSize 
    
} // class DNCQueueableTest