/**
 * This class contains unit tests for validating the CPA_ChatterMessages class.
 *
 *
 * History
 * --------
 * 01/16/2023   Vinay                  Created test class.
 * 03/20/2023   Vinay   APR0147143     Updated code to increase coverage.
 */
@isTest(SeeAllData=true)
public with sharing class CPA_ChatterMessagesTest {
  static testMethod void chatMessagesTest() {
    String referralAccRcId = Schema.getGlobalDescribe()
      .get('Referral_Account__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Core Referral Source Record Type')
      .getRecordTypeId();
    Referral_Account__c refacct = new Referral_Account__c(
      name = 'Referral Account1',
      RecordTypeId = referralAccRcId,
      CPA_Program_status__c = 'Invited',
      MutualClientTier__c = 'Core',
      Referral_Source_Business_Type__c = 'Accounting Firm'
    );
    insert refacct;
    Test.startTest();
    refacct.CPA_Program_status__c = 'Enrolled';
    refacct.MutualClients__c = 19;
    refacct.MutualClientTier__c = 'Elite';
    update refacct;
    refacct.MutualClientTier__c = 'Signature';
    update refacct;
    FeedItem feed = [ SELECT Id, parentid FROM FeedItem WHERE parentid = :refacct.id LIMIT 1];
    System.assertNotEquals(feed, null, 'Posted feed item for Referral Account');
    list<Referral_Account__c> newRecsList = new list<Referral_Account__c>();
    newRecsList.add(refacct);
    CPA_ChatterMessages.mutualClientMoveDownTierNotification(newRecsList);
    Test.stopTest();
  }
}