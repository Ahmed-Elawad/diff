@isTest
public with sharing class CampaignRelatedListTest {
    
    static testMethod void TestCampaignMember(){

        Test.startTest();
        
        // create test account
        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        insert testAccount;

        // create test contact
        Contact testContact = new Contact(FirstName = 'Test Contact', LastName = 'Contact 1', AccountId = testAccount.Id, DoNotCall = false, Email = 'c1a1@whoknows.com', HasOptedOutOfEmail = false);
        insert testContact;
              
        Campaign camp = new Campaign(Name='Campaign1', IsActive=true, StartDate=Date.today(), Originator__c = 'Marketing');
        insert camp;

        //Creates a new campaign memeber, associaites it with 1 provider sales campaign, and inserts
        CampaignMember newMember = new CampaignMember(ContactId = testContact.id, status='Sent', campaignid = camp.id);
        insert newMember;

        List<Campaign> returnCamps = CampaignRelatedList.getOpenCampaigns(testContact.Id);

        Test.stopTest();
        System.assert(returnCamps.size() >0, 'Should have returned expected records');

    }
}