/* 
 * Tests for the general utilities
 *
 * History
 * -------
 * 10/06/2009 Dan Carmen   Created
   11/08/2011 Dan Carmen   Changed to not use the AAConfig__c object.
   12/28/2011 Dan Carmen   Added isSalesRep method.
   05/24/2012 Dan Carmen   Added variable for DSA profiles/Sales Rep profiles
   07/13/2012 Dan Carmen   Added variable for DSM profiles.
   03/23/2013 Dan Carmen   Added checks for more profiles
   02/25/2014 Cindy Freeman Added check for runTrigger
   04/10/2014 Cindy Freeman Expanded check for runTrigger method
   01/06/2015 Dan Carmen   Added checkDialedTimeOkay
   02/02/2014 Justin Stouffer Added Clone method.
   12/04/2017 Dan Carmen      Modifications to cleanUrl to handle myDomain
   10/16/2020 Dan Carmen      Added allowFuture method
   10/19/2020 Brandon Vidro   Added 4 profiles
   09/26/2023 Dan Carmen      Comment out logic for checkDupeBlocker
   03/17/2024 Dan Carmen      Removed rcdsAffectedSet,runTrigger logic

 */
@isTest
private class UtilitiesTest {

   static testMethod void testInstanceUrl() {
      String url = Utilities.instanceUrl();
      String testUrl = '';
      String testUrlClean = Utilities.cleanUrl(testUrl, 'i');
        
      testUrl = '';
      testUrlClean = Utilities.cleanUrl(testUrl, 'i');
      
      // test mydomain urls
      Utilities.OVERRIDE_PRODUCTION = true;

      Utilities.OVERRIDE_PRODUCTION = false;

   } // testInstanceURL
   
   static testMethod void testNextBusinessDay() {
      // run this process
      Date thisDay = Utilities.getNextBusinessDay(0);
      
      // the starting date - a Thursday
      Datetime dt1 = Datetime.newInstance(2009, 10, 29);
      // the end date - a Friday
      Date finalDate1 = Date.newInstance(2009, 10, 30);
      // the following Monday
      Date finalDate2 = Date.newInstance(2009, 11, 2);
      // This interprets to a Friday, should return Friday
      Date nextDay = Utilities.getNextBusinessDay(dt1, 1);
      System.assertEquals(finalDate1,nextDay);
      // This interprets to a Saturday, should return the Monday
      nextDay = Utilities.getNextBusinessDay(dt1, 2);
      System.assertEquals(finalDate2,nextDay);
      // This interprets to a Sunday, should return the Monday
      nextDay = Utilities.getNextBusinessDay(dt1, 3);
      System.assertEquals(finalDate2,nextDay);
   } // testNextBusinessDay

   static testMethod void testIsSalesProf() {
      Profile_List__c prof1 = new Profile_List__c(Name=Utilities.PROF_CORE_SALES, IsFieldSales__c=true);
      Profile_List__c prof2 = new Profile_List__c(Name=Utilities.PROF_CORE_SALES_TRAIN, IsFieldSales__c=true);
      Profile_List__c prof3 = new Profile_List__c(Name=Utilities.PROF_MMS_SALES, IsFieldSales__c=true);
      Profile_List__c prof4 = new Profile_List__c(Name=Utilities.PROF_MMS_SALES_TRAIN, IsFieldSales__c=true);
      Profile_List__c prof5 = new Profile_List__c(Name=Utilities.PROF_CORE_SALES_ADMIN, IsFieldSales__c=true,Dsa__c=true);
      Profile_List__c prof6 = new Profile_List__c(Name=Utilities.PROF_CORE_MGR, IsFieldSales__c=true,Dsm__c=true);
      Profile_List__c prof7 = new Profile_List__c(Name=Utilities.PROF_CORE_ZONE_ADMIN, IsFieldSales__c=true,ZSA__c=true);
      Profile_List__c prof8 = new Profile_List__c(Name=Utilities.PROF_CORE_SENIOR_MGR, IsFieldSales__c=true,ZSM__c=true);
      insert new Profile_List__c[]{prof1,prof2,prof3,prof4,prof5,prof6,prof7,prof8};
           
      System.assertEquals(true,Utilities.isSalesProf(Utilities.PROF_CORE_SALES));
      System.assertEquals(true,Utilities.isSalesProf(Utilities.PROF_CORE_SALES_TRAIN));
      System.assertEquals(true,Utilities.isSalesProf(Utilities.PROF_MMS_SALES));
      System.assertEquals(true,Utilities.isSalesProf(Utilities.PROF_MMS_SALES_TRAIN));
      System.assertEquals(false,Utilities.isSalesProf('test job'));
      
      System.assertEquals(true,Utilities.isDsaProf(Utilities.PROF_CORE_SALES_ADMIN));

      System.assertEquals(true,Utilities.isDsmProf(Utilities.PROF_CORE_MGR));

      System.assertEquals(true,Utilities.isZsaProf(Utilities.PROF_CORE_ZONE_ADMIN));
      
      System.assertEquals(true,Utilities.isZsmProf(Utilities.PROF_CORE_SENIOR_MGR));
      System.assertEquals(false,Utilities.isZsmProf('test job'));
   } // testIsSalesProf

   static testMethod void testCheckForProduction() {
      String sandboxName = Utilities.checkForProduction();
      System.debug('sandboxName='+sandboxName);
      // cannot use assert because we don't know where this will be run (which is why we have this in the first place).
      //System.assertEquals(sandboxName,'develop');
   } // testCheckForProduction
   
   static testMethod void testCheckDsaZsaProf() {
      User u1 = [Select Id from User where isActive=true and (Profile.Name=:Utilities.PROF_CORE_SALES_ADMIN OR Profile.Name = :Utilities.PROF_CORE_SALES_ADMIN_SB) limit 1];
      System.assertEquals(true,Utilities.checkDsaZsaProf(u1.Id));
   } // testCheckDsaZsaProf
   
   static testMethod void testSysAdminProf() {
      System.assertEquals(true,Utilities.checkSysAdminProf(Utilities.PROF_SYS_ADMIN));
      System.assertEquals(false,Utilities.checkSysAdminProf(Utilities.PROF_MMS_SALES_ZSA));
   } // testSysAdminProf
   
   static testMethod void testNvl() {
      System.assertEquals(123.45,Utilities.nvl(123.45,0));
      System.assertEquals(0,Utilities.nvl((Decimal)null,0));
      
      System.assertEquals(123.45,Utilities.nvl(123.45));
      System.assertEquals(0,Utilities.nvl((Decimal)null));
   } // testNvl
   
   static testMethod void testFormatAsInteger() {
      // test a null Decimal value
      System.assertEquals(null,Utilities.formatAsInteger((Decimal)null,null));
      // test a null Integer value
      System.assertEquals(null,Utilities.formatAsInteger((Integer)null,null));
      // test a regular decimal value, no format
      System.assertEquals('3',Utilities.formatAsInteger(3.4,null));
      // test a regular decimal value with a currency format
      System.assertEquals('$3',Utilities.formatAsInteger(3.4,Utilities.FORMAT_CURRENCY));
      // test a regular Integer value, no format
      System.assertEquals('3',Utilities.formatAsInteger(3,null));
      // test a regular Integer value with a currency format
      System.assertEquals('$3',Utilities.formatAsInteger(3,Utilities.FORMAT_CURRENCY));
   } // testFormatAsInteger
   
   static testMethod void testFormattedNumber() {
      // test a null Decimal value
      System.assertEquals(null,Utilities.formattedNumber((Decimal)null,0,null));
      // test a null Integer value
      System.assertEquals(null,Utilities.formattedNumber((Integer)null,null));
      // test a regular decimal value, no format
      System.assertEquals('3',Utilities.formattedNumber(3.4,0,null));
      // test a regular decimal value with a currency format
      System.assertEquals('$3',Utilities.formattedNumber(3.4,0,Utilities.FORMAT_CURRENCY));
      System.assertEquals('($3.40)',Utilities.formattedNumber(-3.4,2,Utilities.FORMAT_CURRENCY));
      // test a regular Integer value, no format
      System.assertEquals('3',Utilities.formattedNumber(3,null));
      // test a regular Integer value with a currency format
      System.assertEquals('$3',Utilities.formattedNumber(3,Utilities.FORMAT_CURRENCY));
      
      // test with decimal points
      // test a regular decimal value, no format
      System.assertEquals('3.4',Utilities.formattedNumber(3.4,1,null));
      System.assertEquals('3.4',Utilities.formattedNumber(3.43,1,null));
      System.assertEquals('3.0',Utilities.formattedNumber(3.011,1,null));
      System.assertEquals('3.01',Utilities.formattedNumber(3.01,2,null));
      System.assertEquals('3.0',Utilities.formattedNumber(3.011,1,null));
   } // testFormattedNumber
   
   static testMethod void testRemoveExtraChars() {
      System.assertEquals(null,Utilities.removeExtraChars(null, Utilities.ALL_NUMBERS));
      System.assertEquals('AB-1234',Utilities.removeExtraChars('AB-1234', null));
      System.assertEquals('1234',Utilities.removeExtraChars('AB-1234', Utilities.ALL_NUMBERS));
      System.assertEquals('AB',Utilities.removeExtraChars('AB-1234', 'AB'));
      System.assertEquals('--',Utilities.removeExtraChars('AB-1234-CD', '-'));
      System.assertEquals('0123456789',Utilities.removeExtraChars('0123456789', Utilities.ALL_NUMBERS));
      System.assertEquals('0123456789',Utilities.removeExtraChars('A0123456789B_!', Utilities.ALL_NUMBERS));
      System.assertEquals('',Utilities.removeExtraChars('ABCD', Utilities.ALL_NUMBERS));
   } // testRemoveExtraChars
   
   // Test the checkLimits method to make sure correct values are returned. 
   static testMethod void testCheckLimits() {
      // test with not hitting the limits
      System.assertEquals(null,Utilities.checkLimits('test message', 1, 1));
      // test with reaching the Statements limit - a message should be returned.
      String errorMsg = Utilities.checkLimits('test message', Limits.getLimitDmlStatements()+1, 1);
      System.assertEquals(true,errorMsg.startsWith('DMLStatement Limits were reached'));    
      // test with reaching the rows limit - a message should be returned.
      errorMsg = Utilities.checkLimits('test message', 1, Limits.getLimitDmlRows()+1);
      System.assertEquals(true,errorMsg.startsWith('DMLRows Limits were reached') );    
   } // testCheckLimitsOkay

   static testMethod void testCleanUrlString() {
      System.assertEquals(null,Utilities.cleanUrlString(null));
      System.assertEquals('',Utilities.cleanUrlString(''));
      System.assertEquals('Hello',Utilities.cleanUrlString('Hello'));
      System.assertEquals('Hello %26 Goodbye',Utilities.cleanUrlString('Hello & Goodbye'));
      System.assertEquals('Hello %26 Goodbye -%23test',Utilities.cleanUrlString('Hello & Goodbye \n#test'));
   } // testCleanUrlString
   
   static testMethod void testRemoveLeadingZero() {
      System.assertEquals(null,Utilities.removeLeadingZero(null));
      System.assertEquals(null,Utilities.removeLeadingZero('00'));
      System.assertEquals('17',Utilities.removeLeadingZero('0017'));
      System.assertEquals('1234',Utilities.removeLeadingZero('0001234'));
      System.assertEquals('1234',Utilities.removeLeadingZero('1234'));
      System.assertEquals('TEST00',Utilities.removeLeadingZero('00TEST00'));
   } // testRemoveLeadingZero
   
   static testMethod void testLeftPad() {
      System.assertEquals('0123',Utilities.leftPad('123', '0', 4));
      System.assertEquals('000123',Utilities.leftPad('123', '0', 6));
      System.assertEquals('123',Utilities.leftPad('123', '0', 2));
      System.assertEquals('0000',Utilities.leftPad(null, '0', 4));
      System.assertEquals('000123',Utilities.leftPad('0123', '0', 6));
   } // testLeftPad
   
   // Test the getFY, getFYs, and getFYByDate methods.
   static testMethod void testGetFy() {
      // negative test with null
      System.assertEquals(null,Utilities.getFY(null));
      // test with far off fiscal year
      System.assertEquals(null,Utilities.getFY('2200'));
      // test valid value
      System.assertEquals(true,(Utilities.getFY('2010') != null));
      // test multiple values
      String[] fiscalYears = new String[]{'2009','2010'};
      System.assertEquals(2,Utilities.getFYs(fiscalYears).size());
      
      // test getFYByDate using valid date
      Date testDate = Date.newInstance(2012, 1, 1);
      System.assertEquals(true,(Utilities.getFYByDate(testDate) != null));
      // test using a date we do not have fiscal year settings for
      testDate = Date.newInstance(2000, 1, 1);
      System.assertEquals(true,(Utilities.getFYByDate(testDate) == null));
      
   } // testGetFy
   
   // Test the checkPostalCode method.
   static testMethod void testCheckPostalCode() {
      System.assertEquals(null,Utilities.checkPostalCode(null, null));
      System.assertEquals(null,Utilities.checkPostalCode('1', null));
      System.assertEquals(null,Utilities.checkPostalCode('12', null));
      System.assertEquals(null,Utilities.checkPostalCode('123', null));
      System.assertEquals(null,Utilities.checkPostalCode('1234', null));
      System.assertEquals('12345',Utilities.checkPostalCode('12345', null));
      System.assertEquals('12345',Utilities.checkPostalCode('123456', null));
      System.assertEquals('12345',Utilities.checkPostalCode('1234567', null));
      System.assertEquals('12345',Utilities.checkPostalCode('12345678', null));
      System.assertEquals('12345',Utilities.checkPostalCode('12345-6789', null));
   } // testCheckPostalCode
   /*
  // Test the runTrigger method.
  static testMethod void testRunTrigger() {
      TriggerFlags__c tf = new TriggerFlags__c (
            Name = 'LeadBeforeTestUser'
            ,TriggerName__c = 'LeadBefore'
            ,UserName__c = 'Test User'
            ,Component__c = null
            ,DoNotRunTrigger__c = true);
        upsert tf;
    
       Boolean runTrigger = Utilities.runTrigger('LeadBefore', 'Test User', null);
      System.assertEquals(false, runTrigger);
      runTrigger = Utilities.runTrigger('LeadBefore', null, 'LeadAfterDFdeltasvc');
      System.assertEquals(true, runTrigger);
      
  } // testRunTrigger
  */
  static testMethod void testClone() {
      WebBankLeadHelper.bankLead bl1 = new WebBankLeadHelper.bankLead();
      bl1.firstname = 'TestFName';
      bl1.lastName = 'testLName';
      WebBankLeadHelper.bankLead bl2 = (WebBankLeadHelper.bankLead)utilities.clone(bl1, 'WebBankLeadHelper.bankLead');
      bl1.firstname = 'TestFName2';
      System.assertNotEquals(bl1.firstName, bl2.firstName);
      System.assertEquals(bl1.lastName, bl2.lastName);         
  } // testClone
   
   static testMethod void testFormatDate() {
      DateTime testDt = DateTime.newInstance(2014, 1, 1, 7, 0, 0);
      String result = Utilities.formatDate('Test', testDt, 2, 'Test');
      // uses the default format - make sure the result ends in test so we're not dependent on the default format
      System.assertEquals(true, result.endsWith('Test'));
      
      PaychexSettings__c setting = new PaychexSettings__c(Name='Test Date',Attribute1__c='M/d/yyyy', IsActive__c=true);
      insert setting;
      
      result = Utilities.formatDate('Test Date', testDt, 2, 'Test');
      
      System.assertEquals('1/1/2014 Test',result);
   } // testFormatDate

   static testMethod void testCheckDialedTimeOkay() {
    // make sure it's at a known value for testing - so test doesn't break if label changes.
    Integer nbrMinutes = 5;
      Utilities.DIALED_NBR_SECONDS = nbrMinutes*60;
      
      System.assertEquals(true,Utilities.checkDialedTimeOkay(null));
      System.assertEquals(false,Utilities.checkDialedTimeOkay(DateTime.now()));
      System.assertEquals(false,Utilities.checkDialedTimeOkay(Datetime.now().addMinutes(1)));
      System.assertEquals(false,Utilities.checkDialedTimeOkay(Datetime.now().addMinutes(nbrMinutes-1)));
      System.assertEquals(true,Utilities.checkDialedTimeOkay(Datetime.now().addMinutes(nbrMinutes+1)));
   } // testCheckDialedTimeOkay

   @isTest(SeeAllData=false)
   static void testSiloed() {
      System.assertEquals(true,Utilities.isTestSiloed());
   } // testSiloed

   @isTest(SeeAllData=true)
   static void testNotSiloed() {
      System.assertEquals(false,Utilities.isTestSiloed());
   } // testNotSiloed
   
   static testMethod void testSleep() {
      Utilities.SLEEP_MODE='Callout';
      Utilities.Sleep(4);
      Utilities.SLEEP_MODE='PurgeSingle';
      Utilities.Sleep(40);
   } // testSleep

   static testMethod void testAllowFuture() {
      System.assertEquals(true,Utilities.allowFuture());
   } // testAllowFuture
/*
   @isTest(SeeAllData=false)
   static void testGetMetadataProfileNames() {
      //UserProfile__mdt prof1 = new UserProfile__mdt()
      Utilities.CACHE_IN_USE=true;
      System.debug('testGetMetadataProfileNames before first call');
      Utilities.getMetadataProfileNames('salesRepProfs', 'SalesRep__c=true');
      System.debug('testGetMetadataProfileNames before second call');
      Utilities.getMetadataProfileNames('salesRepProfs', 'SalesRep__c=true');
   } // testGetMetadataProfileNames
*/
} // class UtilitiesTest