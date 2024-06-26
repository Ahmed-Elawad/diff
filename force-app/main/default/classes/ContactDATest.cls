/* 

  History
  -------
  03/22/2022 Dan Carmen          Cleaned up code
  06/05/2023 Pujitha Madamanchi  APR0153007: Update Marketing Nurture logic
 */
@IsTest
private class ContactDATest {
    @IsTest
    static void getContactsByHRPersonId() {
        test.startTest();

        // create test account
        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        insert testAccount;

        // create test contact
        Contact expectedContact = new Contact(FirstName = 'Test Contact', LastName = 'Contact 1', AccountId = testAccount.Id, DoNotCall = false, Email = 'c1a1@whoknows.com', HasOptedOutOfEmail = false, HR_Person_Id__c = 'TEST000');
        Contact otherContact = new Contact(FirstName = 'Test Contact', LastName = 'Contact 1', AccountId = testAccount.Id, DoNotCall = false, Email = 'c1a1@whoknows.com', HasOptedOutOfEmail = false, HR_Person_Id__c = 'TEST999');
        insert new Contact[]{expectedContact,otherContact};

        List<string> hrPersonIds = new List<string>();
        hrPersonIds.add(expectedContact.HR_Person_Id__c);
        
        List<Contact> returnedContacts =  new ContactDA().getContactsByHRPersonId(hrPersonIds);
        test.stopTest();

        System.assertEquals(returnedContacts.size(), 1);
    } // getContactsByHRPersonId
	
	@IsTest
    static void getAllContactsForAccount() {
        test.startTest();

        // create test account
        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        insert testAccount;

        // create test contacts
        Contact expectedContact = new Contact(FirstName = 'Test Contact', LastName = 'Contact 1', AccountId = testAccount.Id, DoNotCall = true, Email = 'c1a1@whoknows.com', HasOptedOutOfEmail = true, Phone = '585-555-5555');
        insert expectedContact;

        Contact otherContact = new Contact(FirstName = 'Contact2', LastName = 'Contact 2', AccountId = testAccount.Id, DoNotCall = false, Email = 'c2a2@whoknows.com', HasOptedOutOfEmail = false, NSSOwnership__c = 'Marketing', Phone = '585-444-4444', In_Marketing_Nurture__c=true);
        insert otherContact;
        
        test.stopTest();
        
        List<Contact> returnedContacts =  new ContactDA().getAllContactsForAccount(testAccount.Id);	
        System.debug('return contact for a Account ++ ' + returnedContacts);
		List<Contact> returnedDNCContacts =  new ContactDA().getDoNotCallContactsForAccount(testAccount.Id);
        List<Contact> returnedMarketingContacts =  new ContactDA().getMarketingOwnedContact(testAccount.Id);
		List<Contact> returnedEOOContacts =  new ContactDA().getEmailOptOutContactsForAccount(testAccount.Id);
		
		
		System.assertEquals(returnedContacts.size(),2);
		
        System.assertEquals(1, returnedDNCContacts.size());
        System.assertEquals(expectedContact.Id, returnedDNCContacts[0].Id);

        System.assertEquals(1, returnedMarketingContacts.size());
        System.assertEquals(otherContact.Id, returnedMarketingContacts[0].Id);
        
        System.assertEquals(1, returnedEOOContacts.size());
        System.assertEquals(expectedContact.Id, returnedEOOContacts[0].Id);
		
    } // getAllContactsForAccount

} // class ContactDATest