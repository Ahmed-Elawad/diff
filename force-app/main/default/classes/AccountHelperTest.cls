/**
 * The testMethods for the AccountHelper class.
 
  History
  -------
  07/08/2009 Dan Carmen   Created
  11/04/2009 Dan Carmen   Added activity record types.
  12/03/2009 Dan Carmen   Added getRecordType tests.
  02/17/2011 Dan Carmen   Added logic so record types are only retrieved once from the database.
  07/09/2015 Dan Carmen   Added isCurrentClient method
  02/04/2016 Dan Carmen   Added verifyAcctNbr method
  11/10/2020 Dan Carmen   Ecommerce changes - mark ecom opp as sold started, close any other matching (opp types match) opps
  01/13/2021 Dan Carmen   Additional ecom changes
  05/18/2021 Dan Carmen   Changed to use OppStage Labels
  01/25/2024 Shilpa G	  APR0161315: Updated method 'testGetSalesAccountType' to check for MMS Prospects
 
 */
@isTest
public class AccountHelperTest {
        
   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'AccountHelper'});
      TriggerMethodsTest.saveSetupClasses();
      EcomMethodsTest.setupRtSetting();
      RecordTypeHelperTest.setupRecordType();

   } // setupData

   //The tests for transformAcctNbr.
   static testMethod void testTransformAcctNbr() {
      // test null value
      String acctNbr = null;
      String retVal = AccountHelper.transformAcctNbr(acctNbr);
      System.assertEquals(acctNbr,retVal);
      boolean isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(false,isValid);
      // test length < 6
      acctNbr = 'TEST';
      retVal = AccountHelper.transformAcctNbr(acctNbr);
      System.assertEquals(null,retVal);
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(false,isValid);
      // test no dash
      acctNbr = '11TEST';
      retVal = AccountHelper.transformAcctNbr(acctNbr);
      System.assertEquals(null,retVal);
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(false,isValid);
      // test 1 char branch
      acctNbr = '1-TEST';
      retVal = AccountHelper.transformAcctNbr(acctNbr);
      System.assertEquals('0001-TEST',retVal);
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(true,isValid);
      // test 2 char branch
      acctNbr = '11-TEST';
      retVal = AccountHelper.transformAcctNbr(acctNbr);
      System.assertEquals('0011-TEST',retVal);
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(true,isValid);
      // test 3 char branch
      acctNbr = '111-TEST';
      retVal = AccountHelper.transformAcctNbr(acctNbr);
      System.assertEquals('0111-TEST',retVal);
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(true,isValid);
      // test 4 char branch no leading zeroes
      acctNbr = '1111-TEST';
      retVal = AccountHelper.transformAcctNbr(acctNbr);
      System.assertEquals('1111-TEST',retVal);
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(true,isValid);
      // test 4 char branch 1 leading zero
      acctNbr = '0111-TEST';
      retVal = AccountHelper.transformAcctNbr(acctNbr);
      System.assertEquals('111-TEST',retVal);
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(true,isValid);
      // test 4 char branch 2 leading zero
      acctNbr = '0011-TEST';
      retVal = AccountHelper.transformAcctNbr(acctNbr);
      System.assertEquals('11-TEST',retVal);
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(true,isValid);
      // test 4 char branch 3 leading zero
      acctNbr = '0001-TEST';
      retVal = AccountHelper.transformAcctNbr(acctNbr);
      System.assertEquals('1-TEST',retVal);
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(true,isValid);
      // test 5 char branch
      acctNbr = '11111-TEST';
      retVal = AccountHelper.transformAcctNbr(acctNbr);
      System.assertEquals(null,retVal);
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(false,isValid);
      // test dash first
      acctNbr = '-TEST';
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(false,isValid);
      // test char in branch number
      acctNbr = 'A-TEST';
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(false,isValid);
      acctNbr = '001A-TEST';
      isValid = AccountHelper.isAcctNbrValid(acctNbr);
      System.assertEquals(false,isValid);
      
   } // testTransformAcctNbr
   
   // The tests for getSalesAccountType.
   static testMethod void testGetSalesAccountType() {
   	  System.debug('test for null sales org and null employees and null default');
   	  System.assertEquals(AccountHelper.getSalesAccountType(null, null,null),null);
   	  
   	  System.debug('test for null sales org and null employees');
   	  System.assertEquals(AccountHelper.getSalesAccountType(null, null,AccountHelper.CORE_ACCOUNT),AccountHelper.CORE_ACCOUNT);
   	  
   	  System.debug('test for null sales org and core employees');
   	  System.assertEquals(AccountHelper.getSalesAccountType(null, 25,AccountHelper.CORE_ACCOUNT),AccountHelper.CORE_ACCOUNT);

   	  System.debug('test for null sales org and mms employees');
   	  System.assertEquals(AccountHelper.getSalesAccountType(null, 50,AccountHelper.CORE_ACCOUNT),AccountHelper.MMS_ACCOUNT);

   	  System.debug('test for invalid sales org and null employees');
   	  System.assertEquals(AccountHelper.getSalesAccountType('TEST', null,AccountHelper.CORE_ACCOUNT),AccountHelper.CORE_ACCOUNT);

   	  System.debug('test for PAY sales org and null employees');
   	  System.assertEquals(AccountHelper.getSalesAccountType('PAY', null,AccountHelper.CORE_ACCOUNT),AccountHelper.CORE_ACCOUNT);

   	  System.debug('test for MMS sales org and null employees');
   	  System.assertEquals(AccountHelper.getSalesAccountType('MMS', null,AccountHelper.CORE_ACCOUNT),AccountHelper.MMS_ACCOUNT);
       
      System.debug('test for MMS Prospect employees');
   	  System.assertEquals(AccountHelper.getSalesAccountType(null, 15,AccountHelper.CORE_ACCOUNT),AccountHelper.MMS_ACCOUNT);

   } // testGetSalesAccountType
   

   static testMethod void testBranchNbr() {
      Account acct = new Account(Name='Test Acct', AccountNumber=null);
      System.assertEquals(null,AccountHelper.getBranchNumber(acct));
      // test no dash - not a valid account number
      acct.AccountNumber = '123';
      System.assertEquals(null,AccountHelper.getBranchNumber(acct));
      
      // test having a dash - valid
      acct.AccountNumber = '123-A123';
      System.assertEquals(123,AccountHelper.getBranchNumber(acct));


      // test having a leading zero
      acct.AccountNumber = '0123-A123';
      System.assertEquals(123,AccountHelper.getBranchNumber(acct));

      // test a bad branch number (has characters)
      acct.AccountNumber = 'TEST-A123';
      System.assertEquals(null,AccountHelper.getBranchNumber(acct));
   } // testBranchNbr
   
   static testMethod void testCurrentClient() {
      Account acct = new Account(Name='Test Acct',Type='Test Type');
      System.assertEquals(false,AccountHelper.isCurrentClient(acct));
      
      acct.Bis_ID__c = 1;
      acct.First_Run_Date__c = Date.today();
      System.assertEquals(true,AccountHelper.isCurrentClient(acct));
      
      acct.Bis_ID__c = 0;
      System.assertEquals(false,AccountHelper.isCurrentClient(acct));

      acct.Bis_ID__c = 2;
      System.assertEquals(true,AccountHelper.isCurrentClient(acct));

      acct.Lost_Date__c = Date.today();
      System.assertEquals(false,AccountHelper.isCurrentClient(acct));
      
      acct.Lost_Date__c = null;
      System.assertEquals(true,AccountHelper.isCurrentClient(acct));

      acct.Type = 'Lost Client';
      System.assertEquals(false,AccountHelper.isCurrentClient(acct));
      
      acct.Type = 'Client';
      System.assertEquals(true,AccountHelper.isCurrentClient(acct));
      
   } // testCurrentClient
   
   static testMethod void testVerifyAcctNbr() {
      System.assertEquals(null,AccountHelper.verifyAcctNbr(null));
      System.assertEquals('1-2345',AccountHelper.verifyAcctNbr('1-2345'));
      // too short - won't reformat
      System.assertEquals('1-234',AccountHelper.verifyAcctNbr('1-234'));
      System.assertEquals('10-0234',AccountHelper.verifyAcctNbr('10-234'));
      System.assertEquals('12-0345',AccountHelper.verifyAcctNbr('12-345'));
      System.assertEquals('1234',AccountHelper.verifyAcctNbr('1234'));
      System.assertEquals('123-0040',AccountHelper.verifyAcctNbr('123-40'));
      System.assertEquals('1234-0005',AccountHelper.verifyAcctNbr('1234-5'));
      System.assertEquals('1234-00567890',AccountHelper.verifyAcctNbr('1234-567890'));
      System.assertEquals('1234-12345678',AccountHelper.verifyAcctNbr('1234-12345678'));
      System.assertEquals('1234-123456789',AccountHelper.verifyAcctNbr('1234-123456789'));

   } // testVerifyAcctNbr
   
   // The tests for the getRecordType method. 
   static testMethod void testGetRecordType() {
       System.debug('test null object type');
       RecordType rt = AccountHelper.getRecordType(AccountHelper.CORE_LEAD, null);
       System.assertEquals(rt.Name,AccountHelper.CORE_LEAD);
       System.assertEquals(rt.SobjectType,'Lead');
       
       // test retrieving the same record type
       rt = AccountHelper.getRecordType(AccountHelper.CORE_LEAD, null);
       System.assertEquals(rt.Name,AccountHelper.CORE_LEAD);
       System.assertEquals(rt.SobjectType,'Lead');

       System.debug('test passed in object type');
       rt = AccountHelper.getRecordType(AccountHelper.MMS_LEAD, 'Lead');
       System.assertEquals(rt.Name,AccountHelper.MMS_LEAD);
       System.assertEquals(rt.SobjectType,'Lead');
   } // testGetRecordType
    
   static testMethod void testFirstRunOppClose() {
      // when the 
      Account acct = new Account(Name='Test Acct');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
       
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo rtInfo1 = byNameMap.get(EcomMethodsTest.ECOM_OPP);
      Schema.RecordTypeInfo rtInfo2 = byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE);
      Schema.RecordTypeInfo rtInfo3 = byNameMap.get(OpportunityCreateCase.RT_OPPTY_401K);
      // make sure the record types exist
      System.assertNotEquals(null,rtInfo1);
      System.assertNotEquals(null,rtInfo2);
      System.assertNotEquals(null,rtInfo3);
      RecordType__c rt = RecordType__c.getInstance(EcomMethodsTest.ECOM_OPP);
       
      Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct.Id, StageName='Pending', RecordTypeId=rtInfo1.getRecordTypeId(), OpportunityType__c='Payroll', CloseDate=Date.today().addDays(14));
      Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct.Id, StageName='Pending', RecordTypeId=rtInfo2.getRecordTypeId(), OpportunityType__c='Payroll', CloseDate=Date.today().addDays(14));
      Opportunity opp3 = new Opportunity(Name='Opp3', AccountId=acct.Id, StageName='Pending', RecordTypeId=rtInfo3.getRecordTypeId(), OpportunityType__c='Not Payroll', CloseDate=Date.today().addDays(14));
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
      insert opps;
      
      Test.startTest();
      acct.Bis_ID__c = 1234;
      acct.First_Run_Date__c = Date.today();
      ZipCheckOwner.SKIP_TRIGGERS=false;
      update acct;
      Test.stopTest();
       
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name, CloseDate, StageName, Reason_Not_Sold__c, Reason_Won__c from Opportunity]);
      System.assertEquals(3,oppMap.size());
      
      opp1 = oppMap.get(opp1.Id);
      System.assertEquals(AccountHelper.SOLD_STARTED,opp1.StageName);
      System.assertEquals(Date.today(), opp1.CloseDate);
      System.assertEquals(rt.FirstRunReasonWon__c, opp1.Reason_Won__c);
      System.assertEquals(null, opp1.Reason_Not_Sold__c);
      /* requirement to close other opps was changed, commenting out that code.
      opp2 = oppMap.get(opp2.Id);
      System.assertEquals(AccountHelper.NOT_SOLD,opp2.StageName);
      System.assertEquals(Date.today().addDays(14), opp2.CloseDate);
      System.assertEquals(null, opp2.Reason_Won__c);
      System.assertEquals(rt.FirstRunReasonLost__c, opp2.Reason_Not_Sold__c);
      */
      opp3 = oppMap.get(opp3.Id);
      System.assertEquals('Pending',opp3.StageName);
      System.assertEquals(Date.today().addDays(14), opp3.CloseDate);
      System.assertEquals(null, opp3.Reason_Won__c);
      System.assertEquals(null, opp3.Reason_Not_Sold__c);
       
   } // testFirstRunOppClose
   
} // class AccountHelperTest