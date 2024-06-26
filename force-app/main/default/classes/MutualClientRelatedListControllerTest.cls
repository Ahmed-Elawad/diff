@isTest
private class MutualClientRelatedListControllerTest {
	
	@isTest static void getMutualClientsForReferralContactTest_giveReferralContact_receiveMutualClients() {
        test.startTest();
		
        Referral_Account__c expectedRefAcct = new Referral_Account__c();
        insert expectedRefAcct;
        
        Referral_Contact__c expectedRefContact = new Referral_Contact__c(Referral_Account__c=expectedRefAcct.Id);
        insert expectedRefContact;

        Account expectedAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234',NumberOfEmployees = 60, CPA_Name_Ref__c=expectedRefContact.Id);
        insert expectedAccount;

        MutualClientRelatedListController.DataEnvelope envelope = MutualClientRelatedListController.getMutualClientsForReferralContact(expectedRefContact.Id);
        List<Account> mutualClients = envelope.mutualClients;
        test.stopTest();
        
        System.assertEquals(mutualClients.size() == 1, true, 'There is a mutual client');
	}
	
	@isTest static void getMutualClientsForReferralAccountTest_giveReferralAccount_receiveMutualClients() {

        test.startTest();
        Referral_Account__c expectedRefAcct = new Referral_Account__c();
        insert expectedRefAcct;

        Referral_Contact__c expectedRefContact = new Referral_Contact__c(Referral_Account__c=expectedRefAcct.Id);
        insert expectedRefContact;

        Account expectedAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234',NumberOfEmployees = 60, CPA_Name_Ref__c=expectedRefContact.Id);
        insert expectedAccount;


        MutualClientRelatedListController.DataEnvelope envelope = MutualClientRelatedListController.getMutualClientsForReferralAccount(expectedRefAcct.Id);
        List<Account> mutualClients = envelope.mutualClients;
        test.stopTest();

        System.assertEquals(mutualClients.size() == 1, true, 'There is a mutual client');

	}
	
}