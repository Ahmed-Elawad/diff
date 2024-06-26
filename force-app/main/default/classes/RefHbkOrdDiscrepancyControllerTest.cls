/* 
 * The test methods for the RefHbkOrdDiscrepancyController.
 *
 * History
 * -------
 * 07/13/2021 Jermaine Stukes   Created
 */
@isTest
public class RefHbkOrdDiscrepancyControllerTest {
    
   
    static testMethod void testgetReference() {
        User rep = [Select Id, Name from User where ManagerId != null and IsActive=true and Manager.IsActive=true limit 1];
        Account a1 = new Account(Name='Test Account', ownerId=rep.Id,AccountNumber='17-A123');
        // create one of these accounts just in case
        Account a2 = new Account(Name='Paychex Inc SA');
        Account[] accts = new Account[]{a1,a2};
            insert accts;
        
        Contact c1 = new Contact(FirstName='Test',LastName='Contact',AccountId=a1.Id, OwnerId=rep.Id);
        Contact c2 = new Contact(FirstName='Test',LastName='Employee',Email='test@test.com', AccountId=a2.Id);
        Contact[] ctcts = new Contact[]{c1,c2};
            insert ctcts;
        
        // select users to attach to reference object
        User[] users = [Select Id, Name from User where IsActive=true limit 2];
        
        Reference_HRE_CHB_Onboarding__c refHre = new Reference_HRE_CHB_Onboarding__c(Account_Lookup__c=a1.Id);
        refHre.Sales_Rep__c = users[0].Id;
        refHre.FSS__c = users[1].Id;
        insert refHre;
        
        Reference_HRE_CHB_Orders__c chbOrder = new Reference_HRE_CHB_Orders__c(Reference_HR_Essentials__c = refHre.Id);
        insert chbOrder;
        Reference_Handbooks_Order_Discrepancy__c disc1 = new Reference_Handbooks_Order_Discrepancy__c(Reference_Handbook_Order__c = chbOrder.Id,Status__c = 'Open',Discrepancy_Type__c = 'Other');
        insert disc1;
        Test.SetCurrentPageReference(Page.ReferenceHreDiscrepancy);
        ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(chbOrder);
        System.CurrentPageReference().getParameters().put('id',chbOrder.Id);
        RefHbkOrdDiscrepancyController rpdc = new RefHbkOrdDiscrepancyController(sc1);
        string mailText = rpdc.getMessageBody(true);
        System.assertEquals(true, rpdc.getReference(chbOrder.Id));
    }
}