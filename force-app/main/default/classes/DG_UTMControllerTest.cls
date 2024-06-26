/**********************************************************/
//Created by: Gram Bischof 11/13/2018
//Last Modified: Gram Bischof 11/13/2018
//
//Description: 
//This is the test class of DG_UTMController
//
/**********************************************************/
/* 

  History
  -------
  04/18/2019 Dan Carmen        Fix NPE
  
 */
@isTest
public class DG_UTMControllerTest {
    /*public static testMethod void LeadAllUTMValuesUpdatedTest(){
        Campaign testCampaign = new Campaign(Name='Test Campaign');
        insert testCampaign;
        Lead testLead = new Lead(Company='Test Company',firstName='Test',lastName='Person',email='test@email.com',Status='Suspect');
        insert testLead;
        CampaignMember testCM = new CampaignMember(LeadId = testLead.Id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM;
        Test.startTest();
        testLead.UTM_Campaign_Most_Recent__c = 'abc';
        testLead.UTM_Content_Most_Recent__c = 'abcd';
        testLead.UTM_Medium_Most_Recent__c = 'abce';
        testLead.UTM_Source_Most_Recent__c = 'abcf';
        update testLead;
        Test.stopTest();
        
        CampaignMember theCM = [Select UTM_Campaign_Most_Recent__c,UTM_Content_Most_Recent__c,
                                UTM_Medium_Most_Recent__c,UTM_Source_Most_Recent__c From CampaignMember Where LeadId = :testLead.id];
        System.assertEquals(theCM.UTM_Campaign_Most_Recent__c,testLead.UTM_Campaign_Most_Recent__c);
        System.assertEquals(theCM.UTM_Content_Most_Recent__c,testLead.UTM_Content_Most_Recent__c);
        System.assertEquals(theCM.UTM_Medium_Most_Recent__c,testLead.UTM_Medium_Most_Recent__c);
        System.assertEquals(theCM.UTM_Source_Most_Recent__c,testLead.UTM_Source_Most_Recent__c);
        
    }*/
    
    public static testMethod void LeadAllUTMValuesCreatedTest(){
        Campaign testCampaign = new Campaign(Name='Test Campaign');
        insert testCampaign;
        Lead testLead = new Lead(Company='Test Company',firstName='Test',lastName='Person',email='test@email.com',Status='Suspect');
        insert testLead;
        testLead.UTM_Campaign_Most_Recent__c = 'abc';
        testLead.UTM_Content_Most_Recent__c = 'abcd';
        testLead.UTM_Medium_Most_Recent__c = 'abce';
        testLead.UTM_Source_Most_Recent__c = 'abcf';
        update testLead;
        
        Test.startTest();
        CampaignMember testCM = new CampaignMember(LeadId = testLead.Id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM;
        Test.stopTest();

        CampaignMember theCM = [Select UTM_Campaign_Most_Recent__c,UTM_Content_Most_Recent__c,
                                UTM_Medium_Most_Recent__c,UTM_Source_Most_Recent__c From CampaignMember Where LeadId = :testLead.id];
        System.assertEquals(theCM.UTM_Campaign_Most_Recent__c,testLead.UTM_Campaign_Most_Recent__c);
        System.assertEquals(theCM.UTM_Content_Most_Recent__c,testLead.UTM_Content_Most_Recent__c);
        System.assertEquals(theCM.UTM_Medium_Most_Recent__c,testLead.UTM_Medium_Most_Recent__c);
        System.assertEquals(theCM.UTM_Source_Most_Recent__c,testLead.UTM_Source_Most_Recent__c);
        
    }
    
    /*public static testMethod void ContactAllUTMValuesUpdatedTest(){
        Campaign testCampaign = new Campaign(Name='Test Campaign');
        insert testCampaign;
        Account testAccount = new Account(Name='Test Company');
        insert testAccount;
        Contact testContact = new Contact(firstName='Test',lastName='Person',email='test@email.com',Contact_Status__c='Suspect',AccountId=testAccount.id);
        insert testContact;
        CampaignMember testCM = new CampaignMember(ContactId = testContact.Id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM;
        
        
        Test.startTest();
        testContact.UTM_Campaign_Most_Recent__c = 'abc';
        testContact.UTM_Content_Most_Recent__c = 'abcd';
        testContact.UTM_Medium_Most_Recent__c = 'abce';
        testContact.UTM_Source_Most_Recent__c = 'abcf';
        update testContact;
        Test.stopTest();

        CampaignMember theCM = [Select UTM_Campaign_Most_Recent__c,UTM_Content_Most_Recent__c,
                                UTM_Medium_Most_Recent__c,UTM_Source_Most_Recent__c From CampaignMember Where ContactId = :testContact.id];
        System.assertEquals(theCM.UTM_Campaign_Most_Recent__c,testContact.UTM_Campaign_Most_Recent__c);
        System.assertEquals(theCM.UTM_Content_Most_Recent__c,testContact.UTM_Content_Most_Recent__c);
        System.assertEquals(theCM.UTM_Medium_Most_Recent__c,testContact.UTM_Medium_Most_Recent__c);
        System.assertEquals(theCM.UTM_Source_Most_Recent__c,testContact.UTM_Source_Most_Recent__c);
        
    }*/
    
    public static testMethod void ContactAllUTMValuesCreatedTest(){
        Campaign testCampaign = new Campaign(Name='Test Campaign');
        insert testCampaign;
        Account testAccount = new Account(Name='Test Company');
        insert testAccount;
        Contact testContact = new Contact(firstName='Test',lastName='Person',email='test@email.com',Contact_Status__c='Suspect',AccountId=testAccount.id);
        insert testContact;
        testContact.UTM_Campaign_Most_Recent__c = 'abc';
        testContact.UTM_Content_Most_Recent__c = 'abcd';
        testContact.UTM_Medium_Most_Recent__c = 'abce';
        testContact.UTM_Source_Most_Recent__c = 'abcf';
        update testContact;
        
        Test.startTest();
        CampaignMember testCM = new CampaignMember(ContactId = testContact.Id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM;
        Test.stopTest();

        CampaignMember theCM = [Select UTM_Campaign_Most_Recent__c,UTM_Content_Most_Recent__c,
                                UTM_Medium_Most_Recent__c,UTM_Source_Most_Recent__c From CampaignMember Where ContactId = :testContact.id];
        System.assertEquals(theCM.UTM_Campaign_Most_Recent__c,testContact.UTM_Campaign_Most_Recent__c);
        System.assertEquals(theCM.UTM_Content_Most_Recent__c,testContact.UTM_Content_Most_Recent__c);
        System.assertEquals(theCM.UTM_Medium_Most_Recent__c,testContact.UTM_Medium_Most_Recent__c);
        System.assertEquals(theCM.UTM_Source_Most_Recent__c,testContact.UTM_Source_Most_Recent__c);
        
    }

}