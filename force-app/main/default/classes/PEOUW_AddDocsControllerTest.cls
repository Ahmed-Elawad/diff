/* 
* Test class for the PEOUW_AddDocsController apex
*
* History
* -------
* 07/20/2023    Jidesh   	Created
*/

@isTest
public class PEOUW_AddDocsControllerTest {

    @testSetup
    public static void setup(){
        List<Account> Accs = new List<Account>();
        //Creating accounts for test
        Account acc = new Account();
        acc.Name = 'Peo test';
        acc.ShippingState = 'Texas';
        Accs.add(acc);
        Account acc2 = new Account();
        acc2.Name = 'Peo test2';
        acc2.ShippingState = 'Texas';
        Accs.add(acc2);
        insert Accs;
        
        //Creating contacts for test
        List<Contact> Conts = new List<Contact>();
        Contact c = new Contact(AccountId=acc.id,
                                FirstName = 'test',
                                LastName = 'contact',
                                Email='testing@testing.com');
        Conts.add(c);
        Contact c2 = new Contact(AccountId=acc2.id,
                                 FirstName = 'test',
                                 LastName = 'contact2',
                                 Email='testing2@testing.com');
        Conts.add(c2);
        insert Conts;
        
        //Creating checklists for test
        List<PEO_Onboarding_Checklist__c> Clists = new List<PEO_Onboarding_Checklist__c>();
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acc.id,Name='testing Peo',Sales_Rep__c = UserInfo.getUserId(), CS_CM_WC_UW_Status__c ='Approved',
                                                                                CS_CM_Contract_Status__c='Approved',Medical_Benefits_Underwriting_Requested__c ='No',
                                                                                CensusRequired__c = true);  
        
        //PEO_Onboarding_Checklist__c checklist2 = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acc2.id,Name='testing Peo2',Sales_Rep__c = UserInfo.getUserId(),Medical_Pre_Qualifier_Status__c = '');
        checklist.Additional_Misc_Documents_Required__c = true;
        checklist.Benefit_Summaries_Required__c = true;
        checklist.CensusRequired__c = true;
        checklist.Claims_Report_required__c = true;
        checklist.Health_Insurance_Renewal_required__c = true;
        checklist.Health_Invoice_required__c = true;
        checklist.Loss_Runs_required__c = true;
        checklist.Medical_Invoice_Required__c = true;
        checklist.Miscellaneous_Docs_Required__c = true;
        checklist.Miscellaneous_Docs_Required_WC__c = true;
        checklist.Payroll_Register_Required__c = true;
        checklist.SUI_Required__c = true;
        checklist.WCClassesWages_Required__c = true;
        checklist.WC_Declarations_Required__c = true;
        checklist.WC_RatesAndPricing_Required__c = true;
        Clists.add(checklist);
        //Clists.add(checklist2);
        insert Clists;
        
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone'];
        
        User communityUsr = new User(
            UserName = c.email,
            FirstName = c.FirstName,
            LastName = c.LastName,
            Alias = 'alias',
            email = c.Email,
            ContactId = c.id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'nickName',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'PAS'
        );
        insert communityUsr;
        
        // create document owned by user
        /*PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=Clists[0].Id,
                                                                        Routing_Name__c='Census',
                                                                        Name='Census');*/
        //doc.Date_Uploaded__c = System.today();
        //insert doc;
    }
    
    public static testMethod void testgetPEOOnboardingChecklist(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id,Prospect_Client__c,Send_Discrepancy_Email__c FROM PEO_Onboarding_Checklist__c LIMIT 1];
        PEOUW_AddDocsController.getPEOOnboardingChecklist(checklist.Prospect_Client__c, checklist, 'Test Class');
        List<PEO_Onboarding_Document__c> createdDocs = [SELECT Id, Name FROM PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c =: checkList.Id];
        System.debug('testgetPEOOnboardingChecklist docs size:'+createdDocs.size());
        System.assertEquals(15, createdDocs.size());
    }//testgetPEOOnboardingChecklist
}