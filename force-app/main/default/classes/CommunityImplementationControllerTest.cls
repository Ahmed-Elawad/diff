@isTest
public class CommunityImplementationControllerTest {
    
    @testSetup
    Static void setupData() {
        User usr = new User(FirstName = 'Test', LastName = 'User', Username = 'testUserInfopath@email.com', Email = 'test@email.com',
                        Alias = 'test', CommunityNickname = 'testUser', TimeZoneSidKey = 'America/New_York',LocaleSidKey = 'sq_AL',
                        EmailEncodingKey = 'UTF-8',ProfileId = '00e0g0000010D3TAAU',LanguageLocaleKey = 'en_US',Phone = '123-456-7891',
                        Title = 'Test Title',IsActive = true, Sales_Org__c = 'PAY');
        insert usr;
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', RecordTypeId=rtAcct.getRecordTypeId(), 
                                    Phone='123-456-7890');
        insert acctA;
        PEO_Onboarding_Checklist__c checklistA = new PEO_Onboarding_Checklist__c(Name='Test',Prospect_Client__c=acctA.Id, Community_User__c=usr.Id, 
                                                                                Sales_Analyst__c=usr.Id);
        insert checklistA;        
        
        Account acctB = new Account(Name = 'ChildTestAccountCommunities', RecordTypeId=rtAcct.getRecordTypeId(), 
                                    SalesParent__c=acctA.Id, Phone='123-456-7890');
        insert acctB;
        PEO_Onboarding_Checklist__c checklistB = new PEO_Onboarding_Checklist__c(Name='Test Child',Prospect_Client__c=acctB.Id, Parent_PEO_Checklist__c=checklistA.Id);
        insert checklistB;
    }
    
    static testMethod void getPEOImplementationChecklistTest(){
        List<Account> acc = [select id, name from Account];
        List<PEO_Onboarding_Checklist__c> chkList = [select Id, Name, Community_User__c, Prospect_Client__c, Client_Add_on__c from PEO_Onboarding_Checklist__c limit 1];
        String parentAccountId = acc[0].Id;
        Test.startTest();
        Map<String, Object> data = CommunityImplementationController.getPEOImplementationChecklist(chkList[0], acc, parentAccountId);
        Test.stopTest();
        system.Assert(data!=null);
    }
    
    static testMethod void getParentPEOImplementationChecklist(){
        List<Account> acc = [select id, name from Account limit 1];
        List<PEO_Onboarding_Checklist__c> chkList = [select Id from PEO_Onboarding_Checklist__c limit 1];
        Id accId = acc[0].Id;
        Test.startTest();
        PEO_Implementation_Checklist__c implChecklist = new PEO_Implementation_Checklist__c(Prospect_Client__c = acc[0].Id, Parent_Underwriting_Checklist__c = chkList[0].Id,
                                                                                             PEO_Underwriting_Checklist__c = chkList[0].Id);
        insert implChecklist;
        PEO_Implementation_Checklist__c data = CommunityImplementationController.getParentPEOImplementationChecklist(implChecklist.Id);
        Test.stopTest();
        system.Assert(data!=null);
    }
    
    static testMethod void getPEOImplementationChecklistTest2(){
        List<Account> acc = [select id, name from Account];
        List<PEO_Onboarding_Checklist__c> chkList = [select Id, Name, Community_User__c, Prospect_Client__c, Client_Add_on__c from PEO_Onboarding_Checklist__c limit 1];
        String parentAccountId = acc[0].Id;
        PEO_Implementation_Checklist__c implChecklistA = new PEO_Implementation_Checklist__c(Prospect_Client__c=acc[0].Id, Parent_Underwriting_Checklist__c=chkList[0].Id,
                                                                                             PEO_Underwriting_Checklist__c=chkList[0].Id);
        insert implChecklistA;
        Test.startTest();
        Map<String, Object> data = CommunityImplementationController.getPEOImplementationChecklist(chkList[0], acc, parentAccountId);
        Test.stopTest();
        system.Assert(data!=null);
    }
    
    static testMethod void getPEOImplementationChecklistResponseTest(){
        List<Account> acc = [select id, name from Account];
        List<PEO_Onboarding_Checklist__c> chkList = [select Id from PEO_Onboarding_Checklist__c limit 1];
        Id accId = acc[1].Id;
        String parentAccountId = acc[0].Id;
        PEO_Implementation_Checklist__c implChecklistA = new PEO_Implementation_Checklist__c(Prospect_Client__c=acc[0].Id, Parent_Underwriting_Checklist__c=chkList[0].Id,
                                                                                             PEO_Underwriting_Checklist__c=chkList[0].Id);
        insert implChecklistA;
        Test.startTest();
        Map<String, Object> data = CommunityImplementationController.getPEOImplementationChecklistResponse(accId, parentAccountId);
        Test.stopTest();
        system.Assert(data!=null);
    }
    
    static testMethod void isPeoUwImplementationReadyForFinalizeTest(){
        List<Account> acc = [select id, name from Account];
        String parentAccountId = acc[0].Id;
        List<PEO_Onboarding_Checklist__c> chkList = [select Id from PEO_Onboarding_Checklist__c limit 1];
        PEO_Implementation_Checklist__c implChecklistA = new PEO_Implementation_Checklist__c(Prospect_Client__c=acc[0].Id, Parent_Underwriting_Checklist__c=chkList[0].Id,
                                                                                             PEO_Underwriting_Checklist__c=chkList[0].Id);
        insert implChecklistA;
        Test.startTest();
        Boolean isValid = CommunityImplementationController.isPeoUwImplementationReadyForFinalize(acc, parentAccountId);
        Test.stopTest();
        system.Assert(!isValid);
    }
    
    static testMethod void savePEOImplementationChecklistTest(){
        List<Account> acc = [select id, name from Account];
        List<PEO_Onboarding_Checklist__c> chkList = [select Id from PEO_Onboarding_Checklist__c limit 1];
        PEO_Implementation_Checklist__c implChecklist = new PEO_Implementation_Checklist__c(Prospect_Client__c=acc[0].Id,Parent_Underwriting_Checklist__c=chkList[0].Id,
                                                                                            PEO_Underwriting_Checklist__c=chkList[0].Id);
        insert implChecklist;
        Test.startTest();
        Map<String, Object> data = CommunityImplementationController.savePEOImplementationChecklist(implChecklist, true, false, '');
        Test.stopTest();
        system.Assert(data!=null);
    }
    
    static testMethod void processFieldsCmplTest(){
        List<Account> acc = [select id, name from Account];
        List<PEO_Onboarding_Checklist__c> chkList = [select Id from PEO_Onboarding_Checklist__c limit 1];
        PEO_Implementation_Checklist__c implChecklist = new PEO_Implementation_Checklist__c(Prospect_Client__c=acc[0].Id,Parent_Underwriting_Checklist__c=chkList[0].Id,
                                                                                            PEO_Underwriting_Checklist__c=chkList[0].Id,
                                                                                            Own_5_of_the_company__c = 'Yes',
                                                                                            Users_own_5_of_company__c = 'Name1|1;',Status__c = 'Completed');
        insert implChecklist;
        implChecklist.Any_individuals_who_are_officers__c = 'Yes';
        implChecklist.Names_individuals_who_are_officers__c = 'SDName1';
        
            
        List<PEO_Implementation_Checklist__c> implChecklists = new List<PEO_Implementation_Checklist__c>();
        implChecklists.add(implChecklist);
        List<String> sections = new List<String>{'Section_A','Section_D'};
        Test.startTest();
        CommunityImplementationController.createRelatedComplianceData(implChecklists);
        PEO_Compliance_Info__c data = CommunityImplementationController.processFieldsCmpl(sections, implChecklist);
        update implChecklist;
        Test.stopTest();
        Assert.areEqual('Name1', data.SectionAName1__c, 'Section A name is matching'); // Succeeds
        //system.Assert(data!=null);
}
    
    static testMethod void returnImplChecklistTest(){
        List<Account> acc = [select id, name from Account];
        List<PEO_Onboarding_Checklist__c> chkList = [select Id from PEO_Onboarding_Checklist__c limit 1];
        PEO_Implementation_Checklist__c implChecklist = new PEO_Implementation_Checklist__c(Prospect_Client__c=acc[0].Id,Parent_Underwriting_Checklist__c=chkList[0].Id,
                                                                                            PEO_Underwriting_Checklist__c=chkList[0].Id,
                                                                                            Own_5_of_the_company__c = 'Yes',
                                                                                            Users_own_5_of_company__c = 'Name1|1;',Status__c = 'Completed');
        insert implChecklist;
        Test.startTest();
        List<PEO_Implementation_Checklist__c> implChks = CommunityImplementationController.returnImplChecklist(acc, acc[0].Id);
        Test.stopTest();
        Assert.areEqual(True, implChks.size()>0, 'Impl checklist value returned'); // Succeeds
    }

}