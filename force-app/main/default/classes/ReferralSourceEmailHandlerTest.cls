/**
 * Test Methods for the Referral Source Email Handler class.
 
  History
  -------
  11/08/2016 Dan Carmen      Created
  
 */
@isTest
private class ReferralSourceEmailHandlerTest {

   static testMethod void testSettingOnlineAccess() {
      ReferralObjectSyncTest.resetFlags();
      // create a contact
      id refAcctRT = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId();   
      id refCntctRT = RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId(); 
      Referral_Account__c refAcct = ReferralObjectSyncTest.createTestRefAcct(refAcctRT);
      insert refAcct;
      
      Referral_Contact__c refCtct = ReferralObjectSyncTest.createTestRefCntct(refCntctRT,refAcct.Id);
      insert refCtct;
      
      refCtct = [Select Id, Contact_ID__c from Referral_Contact__c where Id = :refCtct.Id];
      System.assertEquals(true, refCtct.Contact_Id__c != null);
      System.debug('testSettingOnlineAccess refCtct.Contact_Id__c='+refCtct.Contact_Id__c);
      
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = ReferralSourceEmailHandler.ID_IDENTIFIER+' '+refCtct.Contact_ID__c;
      System.debug('testSettingOnlineAccess plainTextBody='+email.plainTextBody);
      email.fromAddress = 'dcarmen@paychex.com';
      email.subject=Label.ReferralSourceEmailActive; 
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      ReferralSourceEmailHandler rseh = new ReferralSourceEmailHandler();

      System.debug('testSettingOnlineAccess before startTest');
      Test.startTest();
      rseh.handleInboundEmail(email, env);
      Test.stopTest();
      System.debug('testSettingOnlineAccess after stopTest');
      
      refCtct = [Select Id, Contact_Id__c, User_Name__c from Referral_Contact__c where Id=:refCtct.Id];
      System.assertEquals(true, refCtct.User_Name__c.contains(ReferralSourceEmailHandler.SETUP_ONLINE));
      System.assertEquals(1,[select count() from Process_Log__c where Status__c=:Label.ProcessLogSuccess]);
        
   } // testSettingOnlineAccess
   
   static testMethod void testDeletingOnlineAccess() {
      ReferralObjectSyncTest.resetFlags();
      // create a contact
      id refAcctRT = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId();   
      id refCntctRT = RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId(); 
      Referral_Account__c refAcct = ReferralObjectSyncTest.createTestRefAcct(refAcctRT);
      insert refAcct;
      
      Referral_Contact__c refCtct = ReferralObjectSyncTest.createTestRefCntct(refCntctRT,refAcct.Id);
      refCtct.User_Name__c='Test';
      insert refCtct;
      
      refCtct = [Select Id, Contact_Id__c, User_Name__c from Referral_Contact__c where Id=:refCtct.Id];
      System.assertEquals(true, refCtct.Contact_Id__c != null);
      System.debug('testDeletingOnlineAccess refCtct.Contact_Id__c='+refCtct.Contact_Id__c);
      
      messaging.Inboundemail email = new messaging.Inboundemail();
      //email.plainTextBody = ReferralSourceEmailHandler.ID_IDENTIFIER+' '+refCtct.Contact_ID__c+'\nAccount Status: Deleted';
      email.htmlBody = '<testtag>'+ReferralSourceEmailHandler.ID_IDENTIFIER+' '+refCtct.Contact_ID__c+'</testTag><line2>Account Status: Deleted</line2>';
      System.debug('testDeletingOnlineAccess plainTextBody='+email.plainTextBody);
      email.fromAddress = 'dcarmen@paychex.com';
      email.subject=Label.ReferralSourceEmailDelete;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      ReferralSourceEmailHandler rseh = new ReferralSourceEmailHandler();
      System.debug('testDeletingOnlineAccess before startTest');
      Test.startTest();
      rseh.handleInboundEmail(email, env);
      Test.stopTest();
      System.debug('testDeletingOnlineAccess after stopTest');
      
      refCtct = [Select Id, Contact_Id__c, User_Name__c from Referral_Contact__c where Id=:refCtct.Id];
      System.assertEquals(null, refCtct.User_Name__c);
      System.assertEquals(1,[select count() from Process_Log__c where Status__c=:Label.ProcessLogSuccess]);
        
   } // testDeletingOnlineAccess
   
   static testMethod void testBadCtctId() {
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = ReferralSourceEmailHandler.ID_IDENTIFIER+' badId'+'\nAccount Status: Deleted';
      email.fromAddress = 'dcarmen@paychex.com';
      email.subject=Label.ReferralSourceEmailActive; 
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      ReferralSourceEmailHandler rseh = new ReferralSourceEmailHandler();
      Test.startTest();
      rseh.handleInboundEmail(email, env);
      Test.stopTest();
      System.assertEquals(1,[select count() from Process_Log__c where Status__c=:Label.ProcessLogFailure]);
   } // testBadCtctId
   
   
} // class ReferralSourceEmailHandlerTest