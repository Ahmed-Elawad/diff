/* Controller for PEOGettingStartedHelpCenter Lightning Component
*   HISTORY
* ___________
*
*   10/05/2021  Jake Hinds  Created
*/ 
@IsTest
public class PEOGettingStartedHelpControllerTest {
    static testMethod void testHelpScreen(){
        Account acct = new Account(Name='test acct');
        insert acct;
        
        Contact ctct = new Contact(FirstName='test',LastName='user',Email='test@testPEOGettingStartedHelp.com',AccountId=acct.Id);
        insert ctct;
        
        
        Schema.RecordTypeInfo caseRT = RecordTypeHelper.getRecordType('Prospect Help Request Case','Case');
        Case testCase = new Case(AccountId=acct.id,RecordTypeId = caseRT.getRecordTypeId(), Subject='test',Status = 'New');
        insert testCase;
        
        Id commUserId = ConvertContactToCommunityUser.createCommunityUserNew('test@testPEOGettingStartedHelp.com', 'testNicknamePEOGettingStartedHelp', ctct.Id,'testAlia', '', null);
        User commUser = [SELECT Id FROM User WHERE Id=:commUserId LIMIT 1];
        
        User salesRep = [SELECT Id FROM User WHERE Profile.Name='HRS PEO-ASO Sales - SB' LIMIT 1];
        salesRep.Phone='';
        salesRep.MobilePhone='+1 5555555555';
        update salesRep;
        
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c = acct.Id,Sales_Rep__c = salesRep.Id);
        insert checklist;
        
        
        test.startTest();
        system.runAs(commUser){
            User retUser = PEOGettingStartedHelpController.getSalesRep();
            system.assert(retUser!=null);
            system.assertEquals('(555) 555-5555',retUser.Phone);
            Case[] allCases = PEOGettingStartedHelpController.getProspectCases();
            system.assert(allCases!=null && allCases.size() == 1);
        }
        
        test.stopTest();
    }
}