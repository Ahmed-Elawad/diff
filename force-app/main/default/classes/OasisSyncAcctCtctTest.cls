/* Test Methods for the OasisSyncAcctCtct class


  History
  -------
  05/20/2019 Dan Carmen        Created
  03/10/2020 Dan Carmen        Comment out all code
  
 */
@isTest
private class OasisSyncAcctCtctTest {
    static testMethod void testNothing() {
        OasisSyncAcctCtct.sendAccounts((Account[])null, (Map<Id,Account>)null, (ErrorLog__c)null);
        OasisSyncAcctCtct.sendContacts((Contact[])null, (Map<Id,Contact>)null, (ErrorLog__c)null);
    }
  /*
   @testSetup
   public static void setupTestData() {
      OasisSyncHelperTest.setupCustomSettings();
   } // setupTestData
   
   static testMethod void testAcctCtct() {
      OasisSyncHelper.SKIP_NAME_SET.clear();
      // get a client space user
      User csUser = OasisSyncHelperTest.getTestCSUser();
      Account acct = new Account(OwnerId=csUser.Id, Name='Disney World', BillingState='FL', BillingPostalCode='32830');
      insert acct;
      
      Contact ctct = new Contact(AccountId=acct.Id, OwnerId=csUser.Id, FirstName='Mickey', LastName='Mouse', Email='mickey@disneyworld.com');
      insert ctct;
      
      // an OasisSync__c record should have been created
      Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(new Contact[]{ctct});
      System.assertEquals(1,syncMap.size());
      OasisSync__c sync = syncMap.get(ctct.Id);
      System.assertEquals(OasisSyncHelper.SOURCE_PAYX, sync.Source__c);
      System.assertEquals(OasisSyncHelper.SYNC_NEW, sync.SyncType__c);
      System.assertEquals(1,sync.NbrTransits__c);
      System.assertEquals(ctct.Id, sync.ContactIdPayx__c);
      System.assertEquals(ctct.FirstName, sync.FirstName__c);
      System.assertEquals(ctct.LastName, sync.LastName__c);
      System.assertEquals(ctct.Email, sync.Email__c);
      System.assertEquals(acct.Id, sync.AccountIdPayx__c);
      System.assertEquals(acct.Name, sync.Company__c);
      System.assertEquals(acct.BillingPostalCode, sync.PostalCode__c);
      System.assertEquals(csUser.HR_Person_Id__c, sync.OwnerHrPersonId__c);
      
      OasisSyncHelper.ALREADY_RAN_SET.clear();
      acct.BillingCity='Lake Buena Vista';
      acct.DBA__c='Happiest Place On Earth';
      acct.Website='www.disneyworld.com';
      update acct;
      
      syncMap = OasisSyncHelper.getExistingSyncMap(new Account[]{acct});
      System.assertEquals(1,syncMap.size());
      sync = syncMap.get(acct.Id);
      
      System.assertEquals(OasisSyncHelper.SYNC_UPDATE, sync.SyncType__c);
      System.assertEquals(2,sync.NbrTransits__c);
      System.assertEquals(acct.Id, sync.AccountIdPayx__c);
      System.assertEquals(acct.Name, sync.Company__c);
      System.assertEquals(acct.BillingCity, sync.City__c);
      System.assertEquals(acct.BillingPostalCode, sync.PostalCode__c);
      System.assertEquals(acct.DBA__c, sync.DBA__c);
      System.assertEquals(acct.Website, sync.Website__c);
      
      OasisSyncHelper.ALREADY_RAN_SET.clear();
      ctct.Title='Head Mouse';
      ctct.Phone='(407) 934-7639';
      update ctct;

      syncMap = OasisSyncHelper.getExistingSyncMap(new Contact[]{ctct});
      System.assertEquals(1,syncMap.size());
      sync = syncMap.get(ctct.Id);
      
      System.assertEquals(OasisSyncHelper.SYNC_UPDATE, sync.SyncType__c);
      System.assertEquals(3,sync.NbrTransits__c);
      System.assertEquals(acct.Id, sync.AccountIdPayx__c);
      System.assertEquals(acct.Name, sync.Company__c);
      System.assertEquals(acct.BillingCity, sync.City__c);
      System.assertEquals(acct.BillingPostalCode, sync.PostalCode__c);
      System.assertEquals(acct.DBA__c, sync.DBA__c);
      System.assertEquals(acct.Website, sync.Website__c);
      System.assertEquals(ctct.Id, sync.ContactIdPayx__c);
      System.assertEquals(ctct.FirstName, sync.FirstName__c);
      System.assertEquals(ctct.LastName, sync.LastName__c);
      System.assertEquals(ctct.Email, sync.Email__c);
      System.assertEquals(ctct.Title, sync.Title__c);
      System.assertEquals(ctct.Phone, sync.Phone__c);
        
   } // testAcctCtct
   */
} // class OasisSyncAcctCtctTest