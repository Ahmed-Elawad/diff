/* 
* Test methods for PEOUnderwritingDocumentAfterTest.
*
* History
* -------
* 07/26/2021	Ahmed Elawad		Created with method to test document sharing on create and reassignment
* 08/09/2021 Jake Hinds         Removing Doc shares
* 11/01/2021	Matt Fritschi	Tests Last_Change_Made__c field on Checklist when a doc gets upoloaded.
*/

@isTest
public class PEOUnderwritingDocumentAfterTest {
    
    // Setup: two new users for record assignment
    @testSetup
    Static void setupData() {
        TriggerSetupClasses__c uwAfterSetup = new TriggerSetupClasses__c();
        uwAfterSetup.IsAfter__c = true;
        uwAfterSetup.ClassName__c ='PEOUnderwritingDocumentAfter';
        uwAfterSetup.TriggerKey__c = 'PEOUnderwritingDocument';
        uwAfterSetup.Active__c = true;
        uwAfterSetup.Name = 'Test uw after';
        uwAfterSetup.InterfaceVersion__c = 'C';
        uwAfterSetup.SortOrder__c = 1;
        insert uwAfterSetup;
    }
    
    static testMethod void testSetLastChangeDate(){
        
        // create account for the user
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='12345');
        insert acctA;
        
        // create checklist owned by user
        PEO_Onboarding_Checklist__c peoOnbChecklist = new PEO_Onboarding_Checklist__c(Name='MGF parentChecklist4', 
                                                                                      Prospect_Client__c = acctA.Id, 
                                                                                      Peo_EPLI_formStatus__c='Complete', 
                                                                                      Medical_Benefits_Underwriting_Requested__c='No', 
                                                                                      Peo_WC_formStatus__c='Complete', 
                                                                                      Peo_401k_formStatus__c='Complete',
                                                                                      CensusRequired__c = true, 
                                                                                      Last_Change_Made__c = DateTime.Now());
        insert peoOnbChecklist;
        
        // create document owned by user
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=peoOnbChecklist.Id,
                                                                        Routing_Name__c='Census',
                                                                        Name='Census');
        insert doc;
        
        Test.startTest();
        doc.Date_Uploaded__c = System.today();
        update doc;
        Test.stopTest();
        
        peoOnbChecklist = [SELECT Id, Name, Last_Change_Made__c FROM PEO_Onboarding_Checklist__c WHERE Id=:peoOnbChecklist.Id];
        System.assertNotEquals(null, peoOnbChecklist.Last_Change_Made__c);
    }
}