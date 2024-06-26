@isTest
private class OnboardingOverviewAuraServiceTest {
	
	@isTest static void getAccountCasesTest() {

      	Account acct = new Account(Name='Test Account');
      	insert acct;

    	Case c = new Case(AccountId=acct.Id, Subject='Subject',Description='Description', Priority = 'Critical', Status = 'Waiting on Client');
    	insert c;

    	Test.startTest();
    	List<Case> cases = OnboardingOverviewAuraService.getAccountCases(acct.Id);
    	Test.stopTest();

    	System.assertEquals(cases.size() > 0, true, 'The cases for this account were not retrieved');
	}
	
}