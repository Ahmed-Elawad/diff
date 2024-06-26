/* Methods used to test the StringHelper class.
   
  History
  -------
  10/01/2009 Dan Carmen   Created
  10/18/2010 Dan Carmen   Add initCap method
  12/20/2011 Dan Carmen   Additional logic for initCap method
  01/24/2013 Dan Carmen   Added fieldIsBlank method
  08/28/2013 Dan Carmen   Added parseFullName method
  08/11/2015 Dan Carmen   Adjust initCap to not change strings that are already mixed case
  06/29/2017 Dan Carmen   Add addNotesToField method
  03/26/2018 Dan Carmen   Adjustments to addNotesToField - to be able to pad the field
  08/23/2018 Dan Carmen   Added additional addToProcessNotes methods.
  12/12/2018 Dan Carmen   Add formatPhoneNumber method
  02/18/2019 Jake Hinds   Add Case method
  02/28/2019 Dan Carmen   Check for leading 1 in phone number string greater than 10 characters.
  07/01/2022 Dan Carmen   Add parsePhone
  06/13/2023 Dan Carmen   Add TIN validation  
  01/31/2024 Dan Carmen   Add an override for addToProcessNotes

 */
@isTest
private class StringHelperTest {

   static testMethod void testGetTokens() {
      String testStr = 'ONE,TWO;THREE';
      String[] tokens = StringHelper.getTokens(testStr, ';', ',');
      System.assertEquals(3,tokens.size());
      System.assertEquals(tokens[0],'ONE');
      System.assertEquals(tokens[1],'TWO');
      System.assertEquals(tokens[2],'THREE');

      testStr = 'FOUR';
      tokens = StringHelper.getTokens(testStr, ';', ',');
      System.assertEquals(1,tokens.size());
      System.assertEquals(tokens[0],'FOUR');

      testStr = 'FOUR,FIVE,SIX';
      tokens = StringHelper.getTokens(testStr, ';', ',');
      System.assertEquals(3,tokens.size());
      System.assertEquals(tokens[0],'FOUR');
      System.assertEquals(tokens[1],'FIVE');
      System.assertEquals(tokens[2],'SIX');

      testStr = 'FOUR;FIVE,SIX';
      tokens = StringHelper.getTokens(testStr, ';', ',');
      System.assertEquals(3,tokens.size());
      System.assertEquals(tokens[0],'FOUR');
      System.assertEquals(tokens[1],'FIVE');
      System.assertEquals(tokens[2],'SIX');

      testStr = 'FOUR,FIVE;SIX,SEVEN;EIGHT,NINE';
      tokens = StringHelper.getTokens(testStr, ';', ',');
      System.assertEquals(6,tokens.size());
      System.assertEquals(tokens[0],'FOUR');
      System.assertEquals(tokens[1],'FIVE');
      System.assertEquals(tokens[2],'SIX');
      System.assertEquals(tokens[3],'SEVEN');
      System.assertEquals(tokens[4],'EIGHT');
      System.assertEquals(tokens[5],'NINE');

      tokens = StringHelper.getTokens(null,';',null);
      System.assertEquals(tokens.size(),0);
        
      tokens = StringHelper.getTokens('TEST', null, null);
      System.assertEquals(tokens[0],'TEST');
   } // testGetTokens
   
   static testMethod void testInitCap() {
      // setup some exceptions
      InitCap_Exceptions__c[] exceptions = new InitCap_Exceptions__c[]{};
      exceptions.add(new InitCap_Exceptions__c(Name='bla',Replace_Token__c='BLA'));
      exceptions.add(new InitCap_Exceptions__c(Name='Bla',Replace_Token__c='BLA'));
      exceptions.add(new InitCap_Exceptions__c(Name='hiccup',Replace_Token__c='HiCcUp'));
      insert exceptions;

      System.assertEquals(null,StringHelper.initCap(null));
      System.assertEquals('Hello',StringHelper.initCap('HELLO'));
      System.assertEquals('Hello World',StringHelper.initCap('HELLO WORLD'));
        System.assertEquals('HELLo WoRLD',StringHelper.initCap('HELLo WoRLD'));
        System.assertEquals('Jimmy McDonald',StringHelper.initCap('Jimmy McDonald'));
      System.assertEquals('The Empire State Building',StringHelper.initCap('the empire state building'));
      System.assertEquals('Deborah Gibson',StringHelper.initCap('DEBORAH GIBSON'));
      System.assertEquals('Seamus O\'Malley',StringHelper.initCap('SEAMUS O\'MALLEY'));
      System.assertEquals('Jimmy\'s Coffee Shop',StringHelper.initCap('JIMMY\'S COFFEE SHOP'));
      System.assertEquals('Donna Smith-Harrison',StringHelper.initCap('DONNA SMITH-HARRISON'));
      System.assertEquals('Donna Smith-Harrison-O\'Malley',StringHelper.initCap('DONNA SMITH-HARRISON-O\'MALLEY'));
      System.assertEquals('Jen Hewitt II',StringHelper.initCap('JEN HEWITT II'));
      System.assertEquals('Jimmy(Jim)',StringHelper.initCap('JIMMY(JIM)'));
      System.assertEquals('Circle(K)/Test',StringHelper.initCap('circle(k)/test'));
      

      // test with exceptions
      System.assertEquals('This Is A BLA BLA HiCcUp Test.',StringHelper.initCap('THIS IS A BLA BLA HICCUP TEST.'));
      System.assertEquals('This Is A Test-BLA',StringHelper.initCap('THIS IS A TEST-BLA'));

      
   } // testInitCap
   
   static testMethod void testNormalize() {
      // setup some test data.
      Normalization_Options__c[] options = new Normalization_Options__c[]{};
      options.add(new Normalization_Options__c(Name='Test1',Field_Type__c='Test',Filter_Value_1__c='INC',Replace_Value__c='INCORPORATED'));
      options.add(new Normalization_Options__c(Name='Test2',Field_Type__c='Test',Filter_Value_1__c='THE'));
      insert options;
      
      System.assertEquals('TEST VALUE INCORPORATED',StringHelper.normalizeString('The Test Value Inc.', 'Test'));
   } // testNormalize
   
   static testMethod void testFieldIsBlank() {
    System.assertEquals(true,StringHelper.fieldIsBlank(null));
      System.assertEquals(true,StringHelper.fieldIsBlank(''));
      System.assertEquals(false,StringHelper.fieldIsBlank('N'));
   } // testFileIsBlank
   
   static testMethod void testParseName() {
      StringHelper.parseFullName('Test');
      System.assertEquals(null,StringHelper.firstName);
      System.assertEquals('Test',StringHelper.lastName);
      
      StringHelper.parseFullName(null);
      System.assertEquals(null,StringHelper.firstName);
      System.assertEquals(null,StringHelper.lastName);

      StringHelper.parseFullName('   jimmy    test  ');
      System.assertEquals('jimmy',StringHelper.firstName);
      System.assertEquals('test',StringHelper.lastName);

      StringHelper.parseFullName('JoHn  DoE');
      System.assertEquals('JoHn',StringHelper.firstName);
      System.assertEquals('DoE',StringHelper.lastName);

      StringHelper.parseFullName('Jimmy John Jr');
      System.assertEquals('Jimmy',StringHelper.firstName);
      System.assertEquals('John Jr',StringHelper.lastName);

   } // testParseName

   static testMethod void testAddNotesToField() {
      StringHelper.PCT_TO_PAD = 0;
      Referral__c ref = new Referral__c(ProcessNotes__c='Test Notes');
      StringHelper.addToProcessNotes(ref,'More Notes');
      System.debug('testAddNotesToField ref='+ref);
      System.assertEquals(true, ref.ProcessNotes__c.contains('More Notes'));
      System.assertEquals(true, ref.ProcessNotes__c.contains('Test Notes'));
      
      StringHelper.addToProcessNotes(ref,'Lots of notes');
      System.assertEquals(true, ref.ProcessNotes__c.contains('Lots of notes'));
      System.assertEquals(true, ref.ProcessNotes__c.contains('More Notes'));
      System.assertEquals(true, ref.ProcessNotes__c.contains('Test Notes'));
      
      PartnerReferral__c partRef = new PartnerReferral__c();
      StringHelper.addToProcessNotes(partRef,'Here are some notes to add I hope you enjoy!');
      System.assertEquals(true, partRef.ProcessNotes__c.contains('Here are some notes to add I hope you enjoy!'));
      
      // test a bad field
      Account acct = new Account();
      StringHelper.addNotesToField(acct, 'ThisIsABadFieldName', 100, 'These are some notes', false);
      // nothing should have happened here.
      StringHelper.addNotesToField(acct, 'Description', 20, 'This is to test the truncation of the value that is being passed in', false);
      System.assertEquals('This is to test the ',acct.Description);
      
      StringHelper.PCT_TO_PAD = 15; // this will go down to the maximum of 10
      acct.Description=null;
      StringHelper.addNotesToField(acct, 'Description', 20, 'ThisWillTestTheFieldTruncation', false);
      System.assertEquals('ThisWillTestTheFie',acct.Description);
      
      Contact ctct = new Contact();
      StringHelper.addToProcessNotes(ctct,'Test Process Notes');
      System.assertEquals(true, ctct.ProcessNotes__c.contains('Test Process Notes'));

      Lead ld = new Lead();
      StringHelper.addToProcessNotes(ld,'Test Process Notes');
      System.assertEquals(true, ld.ProcessNotes__c.contains('Test Process Notes'));
      
      Referral_Account__c refAcct = new Referral_Account__c();
      StringHelper.addToProcessNotes(refAcct,'Test Process Notes');
      System.assertEquals(true, refAcct.ProcessNotes__c.contains('Test Process Notes'));
      
      Case ca = new Case();
      StringHelper.addToProcessNotes(ca,'Test Process Notes');
      System.assertEquals(true, ca.ProcessNotes__c.contains('Test Process Notes'));

   } // testAddNotesToField
   
   static testMethod void testAppend() {
      Lead l1 = new Lead(Description='Hello this is a message');
      Lead l2 = new Lead(Description='This is another message');
      StringHelper.appendFields(l1, 'Description', l2, 'Description', ' yadayada ', 100);
      System.assertEquals('This is another message yadayada Hello this is a message', l1.Description);

      l1.Description = 'Hello this is a message';
      l2.Description = 'a message';
      StringHelper.appendFields(l1, 'Description', l2, 'Description', ' yadayada ', 100);
      System.assertEquals('Hello this is a message', l1.Description);
      
      l1.Description = null;
      l2.Description = 'This is another message';
      StringHelper.appendFields(l1, 'Description', l2, 'Description', ' yadayada ', 100);
      System.assertEquals('This is another message yadayada ', l1.Description);
      
      l1.Description = 'Hello this is a message';
      l2.Description = null;
      StringHelper.appendFields(l1, 'Description', l2, 'Description', ' yadayada ', 100);
      System.assertEquals('Hello this is a message', l1.Description);
      
   } // testAppend
    
   static testMethod void testPhone() {
      System.assertEquals('223-4567',StringHelper.formatPhoneNumber('2234567'));
      System.assertEquals('',StringHelper.formatPhoneNumber('223456'));
      System.assertEquals('(123) 456-7890',StringHelper.formatPhoneNumber('1234567890'));
      System.assertEquals('(223) 456-7890 ext 1234',StringHelper.formatPhoneNumber('2234567890ABCD1234'));
      System.assertEquals('(223) 456-7890',StringHelper.formatPhoneNumber('(223) 456-7890'));
      System.assertEquals('(223) 456-7',StringHelper.formatPhoneNumber('(223) 456-7',false));
      System.assertEquals('(223) 456-7890 ext 1234',StringHelper.formatPhoneNumber('22345678901234',false));
      // should ignore the leading 1 if more than 10 digits
      System.assertEquals('(223) 456-7890',StringHelper.formatPhoneNumber('12234567890'));
      
   } // testPhone
    
   static testMethod void testParsePhone() {
      StringHelper.parsePhone('+1 (123) 456-7890 ext 234');
      Assert.areEqual('+1',StringHelper.phoneCountry);
      Assert.areEqual('123',StringHelper.phoneArea);
      Assert.areEqual('4567890',StringHelper.phoneTele);
      Assert.areEqual('234',StringHelper.phoneExt);
       
      StringHelper.parsePhone('333-1234');
      Assert.areEqual('',StringHelper.phoneCountry);
      Assert.areEqual('',StringHelper.phoneArea);
      Assert.areEqual('3331234',StringHelper.phoneTele);
      Assert.areEqual('',StringHelper.phoneExt);
       
      StringHelper.parsePhone('1234567890');
      Assert.areEqual('',StringHelper.phoneCountry);
      Assert.areEqual('123',StringHelper.phoneArea);
      Assert.areEqual('4567890',StringHelper.phoneTele);
      Assert.areEqual('',StringHelper.phoneExt);
       
      StringHelper.parsePhone('555-111-2222 x 45');
      Assert.areEqual('',StringHelper.phoneCountry);
      Assert.areEqual('555',StringHelper.phoneArea);
      Assert.areEqual('1112222',StringHelper.phoneTele);
      Assert.areEqual('45',StringHelper.phoneExt);
       
   } // testParsePhone
    
   static testMethod void testValidTin() {
      String result = StringHelper.validateTin('000000000',StringHelper.SSN);
      Assert.isTrue(result.contains('SSN can\'t be'),result);
      result = StringHelper.validateTin('123456789',StringHelper.SSN);
      Assert.isTrue(result.contains('SSN can\'t be'),result);       
      result = StringHelper.validateTin('987654321',StringHelper.SSN);
      Assert.isTrue(result.contains('SSN can\'t be'),result);
      result = StringHelper.validateTin('MISSING',StringHelper.SSN);
      Assert.isTrue(result.contains('Tax ID should be 9 digits numeric'),result);
      result = StringHelper.validateTin('3215345',StringHelper.SSN);
      Assert.isTrue(result.contains('Tax ID should be 9 digits numeric'),result);
      result = StringHelper.validateTin('321534543243',StringHelper.SSN);
      Assert.isTrue(result.contains('Tax ID should be 9 digits numeric'),result);
      result = StringHelper.validateTin('999999999',StringHelper.FEIN);
      Assert.isTrue(result.contains('Tax ID can\'t be'),result);
      result = StringHelper.validateTin('000432123',StringHelper.SSN);
      Assert.isTrue(result.contains('Cannot begin with 000'),result);
      result = StringHelper.validateTin('666432123',StringHelper.SSN);
      Assert.isTrue(result.contains('Cannot begin with 000'),result);
      result = StringHelper.validateTin('900432123',StringHelper.SSN);
      Assert.isTrue(result.contains('Cannot begin with 000'),result);
      result = StringHelper.validateTin('934432123',StringHelper.SSN);
      Assert.isTrue(result.contains('Cannot begin with the number 9'),result);
      result = StringHelper.validateTin('434430000',StringHelper.SSN);
      Assert.isTrue(result.contains('The third group cannot consisting of four digits as 0000'),result);
      result = StringHelper.validateTin('434002123',StringHelper.SSN);
      Assert.isTrue(result.contains('The second group cannot consist of two digits as 00'),result);
      result = StringHelper.validateTin('074402123',StringHelper.FEIN);
      Assert.isTrue(result.contains('Tax ID can\'t start with one of the following'),result);
      result = StringHelper.validateTin('194402123',StringHelper.FEIN);
      Assert.isTrue(result.contains('Tax ID can\'t start with one of the following'),result);
      result = StringHelper.validateTin('704402123',StringHelper.FEIN);
      Assert.isTrue(result.contains('Tax ID can\'t start with one of the following'),result);
      result = StringHelper.validateTin('991111111',StringHelper.FEIN);
      Assert.isTrue(result.contains('FEIN can\'t be 123456789'),result);
      result = StringHelper.validateTin('333333333',StringHelper.FEIN);
      Assert.isTrue(result.contains('can\'t be all same numbers'),result);
      result = StringHelper.validateTin('212121212',StringHelper.FEIN);
      Assert.isTrue(result.contains('FEIN can\'t have repetitive patterns'),result);
      result = StringHelper.validateTin('656565656',StringHelper.FEIN);
      Assert.isTrue(result.contains('FEIN can\'t have repetitive patterns'),result);
   } // testValidTin
   
} // class StringHelperTest