/* Test methods for MergeHelper class

  History
  -------
  07/16/2019 Dan Carmen        Created
  08/25/2021 Dan Carmen        Replace the Referral Contact Create Merge Tracking and Referral Account Merge Request Tracking process builders
  
 */
@isTest
private class MergeHelperTest {

   @testSetup
   public static void setupTestData() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'MergeHelper'});
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false, new String[]{'MergeHelper'});
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'MergeHelper'});
      TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false, new String[]{'MergeHelper'});
      TriggerMethodsTest.createTriggerSetting('ReferralContactAfter', false, true, false, false,new String[]{'MergeHelper'});
      TriggerMethodsTest.createTriggerSetting('ReferralAccountAfter', false, true, false, false,new String[]{'MergeHelper'});
      TriggerMethodsTest.saveSetupClasses();

   } // setupTestData
   
   static testMethod void testAcctCtctMerge() {
      Account acct1 = new Account(Name='Account1', Merge_Name__c='acct1Merge Primary1');
      Account acct2 = new Account(Name='Account2', Merge_Name__c='acct1Merge');
      Account acct3 = new Account(Name='Account3');
      Account acct4 = new Account(Name='Account4');
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      
      insert accts;
      System.assertEquals(2,[select count() from Merge_Request_Tracking__c where Account__c in :accts]);
      
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='Contact1', Merge_Name__c='ctct1Merge Primary1');
      Contact ctct2 = new Contact(AccountId=acct1.Id, LastName='Contact2', Merge_Name__c='ctct1Merge');
      Contact ctct3 = new Contact(AccountId=acct1.Id, LastName='Contact3');
      Contact ctct4 = new Contact(AccountId=acct1.Id, LastName='Contact4');
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;

      Merge_Request_Tracking__c[] mrts = [Select Account__c, Account_ID__c
                                                ,Contact__c, Contact_ID__c
                                                ,Date_Merge_Requested__c
                                                ,Merge_Requested_Type__c
                                                ,Merge_Object__c
                                            from Merge_Request_Tracking__c];
      System.assertEquals(4,mrts.size());
      Integer nbrFound = 0;
      for (Merge_Request_Tracking__c mrt : mrts) {
         if (mrt.Account__c == acct1.Id) {
            System.assertEquals('Survivor Record',mrt.Merge_Requested_Type__c);
            System.assertEquals('Account',mrt.Merge_Object__c);
            nbrFound++;
         } else if (mrt.Account__c == acct2.Id) {
            System.assertEquals('To be Merged',mrt.Merge_Requested_Type__c);
            System.assertEquals('Account',mrt.Merge_Object__c);
            nbrFound++;
         } else if (mrt.Contact__c == ctct1.Id) {
            System.assertEquals('Survivor Record',mrt.Merge_Requested_Type__c);
            System.assertEquals('Contact',mrt.Merge_Object__c);
            nbrFound++;
         } else if (mrt.Contact__c == ctct2.id) {
            System.assertEquals('To be Merged',mrt.Merge_Requested_Type__c);
            System.assertEquals('Contact',mrt.Merge_Object__c);
            nbrFound++;
         }
         
      } // for (Merge_Request_Tracking__c mrt
      System.assertEquals(4,nbrFound);
      
      MergeHelper.ALREADY_RAN_SET.clear();
      
      acct3.Merge_Name__c='acct3Merge Primary1';
      acct4.Merge_Name__c='acct3Merge';
      ctct3.Merge_Name__c='ctct3Merge Primary1';
      ctct4.Merge_Name__c='ctct4Merge';
      update accts;
      update ctcts;
      
      mrts = [Select Account__c, Account_ID__c
                                                ,Contact__c, Contact_ID__c
                                                ,Date_Merge_Requested__c
                                                ,Merge_Requested_Type__c
                                                ,Merge_Object__c
                                            from Merge_Request_Tracking__c];
      System.assertEquals(8,mrts.size());
      nbrFound = 0;
      for (Merge_Request_Tracking__c mrt : mrts) {
         if (mrt.Account__c == acct3.Id) {
            System.assertEquals('Survivor Record',mrt.Merge_Requested_Type__c);
            System.assertEquals('Account',mrt.Merge_Object__c);
            nbrFound++;
         } else if (mrt.Account__c == acct4.Id) {
            System.assertEquals('To be Merged',mrt.Merge_Requested_Type__c);
            System.assertEquals('Account',mrt.Merge_Object__c);
            nbrFound++;
         } else if (mrt.Contact__c == ctct3.Id) {
            System.assertEquals('Survivor Record',mrt.Merge_Requested_Type__c);
            System.assertEquals('Contact',mrt.Merge_Object__c);
            nbrFound++;
         } else if (mrt.Contact__c == ctct4.id) {
            System.assertEquals('To be Merged',mrt.Merge_Requested_Type__c);
            System.assertEquals('Contact',mrt.Merge_Object__c);
            nbrFound++;
         }
         
      } // for (Merge_Request_Tracking__c mrt
      System.assertEquals(4,nbrFound);
      
   } // testAcctCtctMerge
    
   static testMethod void testRefCtctMerge() {
      Referral_Account__c refAcct1 = new Referral_Account__c(Name='RefAcct1');
      Referral_Account__c refAcct2 = new Referral_Account__c(Name='RefAcct2');
      Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2};
      insert refAccts;
       
      Referral_Contact__c refCtct1 = new Referral_Contact__c(Name='Test Ctct1', Referral_Account__c=refAcct1.Id, Merge_Name__c='ctct1Merge Primary1');
      Referral_Contact__c refCtct2 = new Referral_Contact__c(Name='Test Ctct2', Referral_Account__c=refAcct2.Id, Merge_Name__c='ctct1Merge');
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtct1,refCtct2};
      insert refCtcts;
       
      Merge_Request_Tracking__c[] mrts = [Select Account__c, Account_ID__c
                                                ,Contact__c, Contact_ID__c
                                                ,Referral_Account__c, Referral_Account_Id__c, Referral_Account_Name__c
                                                ,Referral_Contact__c, Referral_Contact_Id__c, Referral_Contact_Name__c
                                                ,Date_Merge_Requested__c
                                                ,Merge_Requested_Type__c
                                                ,Merge_Object__c
                                            from Merge_Request_Tracking__c];
      System.assertEquals(2,mrts.size());
      Integer nbrFound = 0;
      for (Merge_Request_Tracking__c mrt : mrts) {
         if (mrt.Referral_Contact__c == refCtct1.Id) {
            System.assertEquals('Survivor Record',mrt.Merge_Requested_Type__c);
            System.assertEquals('Referral Contact',mrt.Merge_Object__c);
            nbrFound++;
         } else if (mrt.Referral_Contact__c == refCtct2.Id) {
            System.assertEquals('To be Merged',mrt.Merge_Requested_Type__c);
            System.assertEquals('Referral Contact',mrt.Merge_Object__c);
            nbrFound++;
         }
         
      } // for (Merge_Request_Tracking__c mrt
      System.assertEquals(2,nbrFound);

   } // testRefCtctMerge
   
   static testMethod void testRefAcctMerge() {
      Referral_Account__c refAcct1 = new Referral_Account__c(Name='RefAcct1', Merge_Name__c='ctct1Merge Primary1');
      Referral_Account__c refAcct2 = new Referral_Account__c(Name='RefAcct2', Merge_Name__c='ctct1Merge');
      Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2};
      insert refAccts;
       
      Merge_Request_Tracking__c[] mrts = [Select Account__c, Account_ID__c
                                                ,Contact__c, Contact_ID__c
                                                ,Referral_Account__c, Referral_Account_Id__c, Referral_Account_Name__c
                                                ,Referral_Contact__c, Referral_Contact_Id__c, Referral_Contact_Name__c
                                                ,Date_Merge_Requested__c
                                                ,Merge_Requested_Type__c
                                                ,Merge_Object__c
                                            from Merge_Request_Tracking__c];
      System.assertEquals(2,mrts.size());
      Integer nbrFound = 0;
      for (Merge_Request_Tracking__c mrt : mrts) {
         if (mrt.Referral_Account__c == refAcct1.Id) {
            System.assertEquals('Survivor Record',mrt.Merge_Requested_Type__c);
            System.assertEquals('Referral Account',mrt.Merge_Object__c);
            nbrFound++;
         } else if (mrt.Referral_Account__c == refAcct2.Id) {
            System.assertEquals('To be Merged',mrt.Merge_Requested_Type__c);
            System.assertEquals('Referral Account',mrt.Merge_Object__c);
            nbrFound++;
         }
         
      } // for (Merge_Request_Tracking__c mrt
      System.assertEquals(2,nbrFound);

   } // testRefCtctMerge
   
} // class MergeHelperTest