/* Test methods for MutualClientDA

  History
  -------
  10/10/2019 Dan Carmen        Clean up test, get better test coverage
  03/23/2022 Dan Carmen        Clean up Code
  
 */
@IsTest
private class MutualClientDATest {
   
   public static String CTCT1_NAME='Donald Duck';
   public static String CTCT2_NAME='Daisy Duck';
   
   @testSetup
   public static void setupData() {
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test Referral Account');
      insert refAcct;
      Referral_Contact__c refCtct1 = new Referral_Contact__c(Name=CTCT1_NAME, Referral_Account__c=refAcct.Id);
      Referral_Contact__c refCtct2 = new Referral_Contact__c(Name=CTCT2_NAME, Referral_Account__c=refAcct.Id);
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtct1,refCtct2};
      insert refCtcts;
   } // setupData
   
   public static Referral_Contact__c getRefCtct(String ctctName) {
      Referral_Contact__c refCtct = [Select Id, Name from Referral_Contact__c where Name=:ctctName];
      return refCtct;
   }  // getRefCtct

    @IsTest
    static void getMutualClientsByReferralContactId_GivenRefContactIdOfCPA_ReturnsCountOfMutualClients() {
        Referral_Contact__c testReferralContact = getRefCtct(CTCT1_NAME);
        test.startTest();

        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60, CPA_Name_Ref__c = testReferralContact.Id);
        Account testAccount2 = new Account(Name = 'testAccountB', AccountNumber = '8-00081234', NumberOfEmployees = 60, CPA_Name_Ref__c = testReferralContact.Id);
        Account testAccount3 = new Account(Name = 'testAccountC', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        Account[] accts = new Account[]{testAccount,testAccount2,testAccount3};
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert accts;
        test.stopTest();

        Integer returnedMutualClientCount = new MutualClientDA().getMutualClientsByReferralContactId(testReferralContact.Id);

        System.assertEquals(returnedMutualClientCount, 2);
    }

    @IsTest
    static void getMutualClientsByReferralContactId_GivenRefContactIdOfBanker_ReturnsCountOfMutualClients() {
        Referral_Contact__c testReferralContact = getRefCtct(CTCT1_NAME);

        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60, Banker_Name_Ref__c = testReferralContact.Id);
        Account testAccount2 = new Account(Name = 'testAccountB', AccountNumber = '8-00081234', NumberOfEmployees = 60, Banker_Name_Ref__c = testReferralContact.Id);
        Account testAccount3 = new Account(Name = 'testAccountC', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        Account[] accts = new Account[]{testAccount,testAccount2,testAccount3};
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert accts;

        Integer returnedMutualClientCount = new MutualClientDA().getMutualClientsByReferralContactId(testReferralContact.Id);

        System.assertEquals(returnedMutualClientCount, 2);
    }

    @IsTest
    static void getMutualClientsByReferralContactId_GivenRefContactIdOfBroker_ReturnsCountOfMutualClients() {
        Referral_Contact__c testReferralContact = getRefCtct(CTCT1_NAME);
        test.startTest();

        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60, Broker_Name_Ref__c = testReferralContact.Id);
        Account testAccount2 = new Account(Name = 'testAccountB', AccountNumber = '8-00081234', NumberOfEmployees = 60, Broker_Name_Ref__c = testReferralContact.Id);
        Account testAccount3 = new Account(Name = 'testAccountC', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        Account[] accts = new Account[]{testAccount,testAccount2,testAccount3};
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert accts;

        test.stopTest();

        Integer returnedMutualClientCount = new MutualClientDA().getMutualClientsByReferralContactId(testReferralContact.Id);

        System.assertEquals(returnedMutualClientCount, 2);
    }

    @IsTest
    static void getMutualClientsByReferralContactId_GivenRefContactIdOfInsurance_ReturnsCountOfMutualClients() {
        Referral_Contact__c testReferralContact = getRefCtct(CTCT1_NAME);
        test.startTest();

        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60, Insurance_Broker_Name_Ref__c = testReferralContact.Id);
        Account testAccount2 = new Account(Name = 'testAccountB', AccountNumber = '8-00081234', NumberOfEmployees = 60, Insurance_Broker_Name_Ref__c = testReferralContact.Id);
        Account testAccount3 = new Account(Name = 'testAccountC', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        Account[] accts = new Account[]{testAccount,testAccount2,testAccount3};
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert accts;

        test.stopTest();

        Integer returnedMutualClientCount = new MutualClientDA().getMutualClientsByReferralContactId(testReferralContact.Id);

        System.assertEquals(returnedMutualClientCount, 2);
    }

    /*@IsTest
    static void getMutualClientsByReferralContactId_GivenRefContactIdOfPortfolio_ReturnsCountOfMutualClients() {
        test.startTest();
        Referral_Contact__c testReferralContact = new Referral_Contact__c();
        insert testReferralContact;

        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60, Portfolio_Manager_Name_Ref__c = testReferralContact.Id);
        insert testAccount;

        Account testAccount2 = new Account(Name = 'testAccountB', AccountNumber = '8-00081234', NumberOfEmployees = 60, Portfolio_Manager_Name_Ref__c = testReferralContact.Id);
        insert testAccount2;

        Account testAccount3 = new Account(Name = 'testAccountC', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        insert testAccount3;

        test.stopTest();

        MutualClientDAInterface testMutualClientDA = new MutualClientDA();
        Integer returnedMutualClientCount = testMutualClientDA.getMutualClientsByReferralContactId(testReferralContact.Id);

        System.assertEquals(returnedMutualClientCount, 2);
    }*/

    @IsTest
    static void getMutualClientsByReferralContacts_GivenRefContactIds_ReturnsCountOfMutualClients() {
        Referral_Contact__c testReferralContact = getRefCtct(CTCT1_NAME);
        Referral_Contact__c testReferralContact2 = getRefCtct(CTCT2_NAME);
        test.startTest();

        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60, CPA_Name_Ref__c = testReferralContact.Id);
        Account testAccount2 = new Account(Name = 'testAccountB', AccountNumber = '8-00081234', NumberOfEmployees = 60, Banker_Name_Ref__c = testReferralContact2.Id);
        Account testAccount3 = new Account(Name = 'testAccountC', AccountNumber = '8-00081234', NumberOfEmployees = 60);

        Account[] accts = new Account[]{testAccount,testAccount2,testAccount3};
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert accts;

        test.stopTest();

        Integer returnedMutualClientCount = new MutualClientDA().getMutualClientsByReferralContacts(new List<Referral_Contact__c>{testReferralContact, testReferralContact2});

        System.assertEquals(returnedMutualClientCount, 2);
    }
   static testMethod void testGetMutualClients1() {
      Referral_Contact__c refCtct1 = getRefCtct(CTCT1_NAME);
      Referral_Contact__c refCtct2 = getRefCtct(CTCT2_NAME);

      Account acct1 = new Account(Name = 'Acct1', AccountNumber = '8-00081231', NumberOfEmployees = 1, CPA_Name_Ref__c = refCtct1.Id);
      Account acct2 = new Account(Name = 'Acct2', AccountNumber = '8-00081232', NumberOfEmployees = 2, Banker_Name_Ref__c = refCtct1.Id);
      Account acct3 = new Account(Name = 'Acct3', AccountNumber = '8-00081233', NumberOfEmployees = 3, Broker_Name_Ref__c = refCtct2.Id);
      Account acct4 = new Account(Name = 'Acct4', AccountNumber = '8-00081234', NumberOfEmployees = 4, Insurance_Broker_Name_Ref__c = refCtct2.Id);
      Account acct5 = new Account(Name = 'Acct5', AccountNumber = '8-00081235', NumberOfEmployees = 5);
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;

      MutualClientDA mcda = new MutualClientDA();
      Account[] retAccts = mcda.getMutualClientFieldsByByReferralContactId(refCtct1.Id);
      System.assertEquals(2,retAccts.size());
      
      retAccts = mcda.getMutualClientFieldsByByReferralContacts(new Referral_Contact__c[]{refCtct1,refCtct2});
      System.assertEquals(4,retAccts.size());

   } // testGetMutualClients1
   
} // class MutualClientDATest