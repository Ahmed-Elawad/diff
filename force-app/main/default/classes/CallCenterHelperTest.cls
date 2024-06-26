/* 
 * Test Methods for CallCenterHelper
 *
 * History
 * -------
   12/05/2018 Dan Carmen       Created
   01/23/2023 Dan Carmen       Change to InterfaceC

 */
@isTest
private class CallCenterHelperTest {

   @testSetup
   public static void setup(){
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false,new String[]{'CallCenterHelper'});
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false,new String[]{'CallCenterHelper'});
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false,new String[]{'CallCenterHelper'});
      TriggerMethodsTest.saveSetupClasses();

   } // setup


   static testMethod void testDateFields() {
      Lead ld = new Lead(LastName='LeadLast', Company='LeadCompany');
      Account acct = new Account(Name='AcctCompany');
      Contact ctct = new Contact(LastName='CtctLast');
      // put in a value we can compare against
      ctct.put(CallCenterHelper.CALL_TIME_FLD, Datetime.now().addDays(-2));
      
      // needs to be at least 1 field value
      System.assertEquals(true, CallCenterHelper.CHECK_DATE_FLDS.size() >= 1);
      
      Datetime compareDate = Datetime.now().addDays(-1);
      
      // set 1 field to a date
      String fldName = CallCenterHelper.CHECK_DATE_FLDS[0];
      
      ld.put(fldName, compareDate);
      acct.put(fldName, compareDate);
      ctct.put(fldName, compareDate);
      
      Test.startTest();
      insert ld;
      insert acct;
      insert ctct;
      Test.stopTest();
      
      Id leadId = ld.Id;
      Id acctId = acct.Id;
      Id ctctId = ctct.Id;
      
      String ldQuery = 'select Id, Name, '+CallCenterHelper.CALL_TIME_FLD+' from Lead where Id=:leadId';
      String acctQuery = 'select Id, Name, '+CallCenterHelper.CALL_TIME_FLD+' from Account where Id=:acctId';
      String ctctQuery = 'select Id, Name, '+CallCenterHelper.CALL_TIME_FLD+' from Contact where Id=:ctctId';
      
      ld = Database.query(ldQuery);
      Datetime checkDate = (Datetime)ld.get(CallCenterHelper.CALL_TIME_FLD);
      Assert.areEqual(compareDate, checkDate);
      
      acct = Database.query(acctQuery);
      checkDate = (Datetime)acct.get(CallCenterHelper.CALL_TIME_FLD);
      Assert.areEqual(compareDate, checkDate);
      
      ctct = Database.query(ctctQuery);
      checkDate = (Datetime)ctct.get(CallCenterHelper.CALL_TIME_FLD);
      Assert.areEqual(compareDate, checkDate);
      
      
   } // testDateFields
   
   static testMethod void testMisc() {
      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();
      Assert.isNotNull(rtInbound);
      
      Schema.RecordTypeInfo rtOutbound = CallCenterHelper.getOutboundRt();
      Assert.isNotNull(rtOutbound);

   } // testMisc
   
} // class CallCenterHelperTest