/** Tests for NavigateToPEOUWFormsComponent
*
* History
* -------
* 12/15/2022    Ahmed Elawad        Created.
*/

@isTest
public class NavigateToPEOUWFormsComponentTest {

    @testSetup 
    static void recordSetup() {
        
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST');
        insert acctA;
        Account acctB = new Account(Name = 'ChildTestAccountCommunities', AccountNumber = '8-12345678',NumberOfEmployees = 60, BillingStreet = ' Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='5678', Phone='123-456-7891', DBA__c='TEST',
                                    SalesParent__c = acctA.Id, RecordTypeId=rtAcct.getRecordTypeId());
        insert acctB;
        Account_Junction__c acctJunc = new Account_Junction__c(Child_Account__c=acctB.Id, Parent_Account__c=acctA.Id);
        insert acctJunc;
        
        Contact c1_a1 = new Contact(FirstName='Test Comm Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@whoknows.com');
        insert c1_a1;
    }
    
     static testMethod void checkPermissions() {
        User runningUser = UserHelper.getRunningUser();
        Contact newCommUserContact = [SELECT Id,AccountId FROM Contact WHERE email='c1a1@whoknows.com' LIMIT 1];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String audience = 'Oasis';
        String alias = 'cUserAli';
        Test.startTest();
        system.assertEquals(new String[]{},NavigateToPEOUWFormsComponent.checkPermissions(runningUser));
        Test.stopTest();
     }
    
    static testMethod void checkRunningUser() {
        User runningUser = UserHelper.getRunningUser();
        Test.startTest();
        User usr = NavigateToPEOUWFormsComponent.getRunningUser();
        Test.StopTest();
        
        System.assertEquals(usr.Id, runningUser.Id);
    }
}