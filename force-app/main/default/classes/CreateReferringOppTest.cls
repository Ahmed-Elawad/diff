/*
 * HISTORY
 * 08/08/2023	Carrie Marciano	Added P_C_Quote_Result__c = 'Warm Transfer to PC' to get by validation errors

 */


@isTest
public class CreateReferringOppTest {

    static testMethod void testAmplifinityReferringOppCreation()
    {
        User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE and IsActive = true limit 1];
        User u2 = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE and Id != :u.Id and IsActive = true limit 1];
        User u3 = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE and Id != :u.Id and Id != :u2.Id and IsActive = true limit 1];
        
        Pricebook2 ampPB = new Pricebook2(Name='Amp Referral Products', IsActive=true, Sales_Org__c='PAY');
      	insert ampPB;
        ampPB = [SELECT Id, Name FROM Pricebook2 WHERE Name='Amp Referral Products' LIMIT 1];
        
        Product_Pricebook_Map__c testPBM = new Product_Pricebook_Map__c(Name='Test pbm',Sales_Org__c='PAY',Pricebook_Id__c=ampPB.Id,Pricebook_Name__c=ampPB.Name);
        insert testPBM;
        
        Product2 testProduct = new Product2(Name='Amp Test Product 123');
        insert testProduct;
        testProduct = [SELECT Id, Name FROM Product2 WHERE Name='Amp Test Product 123' LIMIT 1];
        
        Id spricebookId = Test.getStandardPricebookId();
        PricebookEntry spbe = new PricebookEntry(Pricebook2Id=spricebookId, Product2Id=testProduct.Id, UnitPrice=0, IsActive=True, UseStandardPrice=false);
        insert spbe;
        
        //PricebookEntry pe = new PricebookEntry(Pricebook2Id=ampPB.Id, Product2Id=testProduct.Id, UnitPrice=0, IsActive=True, UseStandardPrice=false);
        //insert pe;
        
        Account acct = new Account(Name='Test Account', OwnerId=u.Id);
        insert acct;
        
        Contact referringEmployee = new Contact(User_Lookup__c = u3.Id, FirstName='Test', LastName='Contact', HR_Person_Id__c='1234', AccountId=acct.Id, RecordTypeId = '012700000001UNG');
        insert referringEmployee;
        
        Record_Type_Mapping__c rtm = new Record_Type_Mapping__c(Sales_Org__c='PAY', Object_API_Name__c=ObjectHelper.OBJECT_OPPTY, RecordTypeName__c='Core Referral Revenue Opportunity Record Type - Rep',Mapping_Type__c=RecordTypeHelper.MAPPING_REFERRAL);
         insert rtm;
        
        Contact ctct = new Contact(FirstName='First',LastName='Last',AccountId=acct.Id, OwnerId=u.Id);
        insert ctct;
        
        acct.SignificantContact__c = ctct.Id;
        update acct;
        
        amp_dev__Amp_Advocate__c ampAdv = new amp_dev__Amp_Advocate__c(Name='TestAdvocate', amp_dev__Status__c = 'Active', Account__c=acct.Id, OwnerId = u2.Id);
        insert ampAdv;
        
        amp_dev__Amp_Referral__c ampReferral = new amp_dev__Amp_Referral__c(OwnerId=u.Id, amp_dev__Advocate__c=ampAdv.Id);
        insert ampReferral;
        
        Referral__c ref = new Referral__c(Name='Test Referral', SourceContact__c=ctct.Id, Amplifinity_Referral__c=ampReferral.Id, Account__c=acct.Id, Selling_Opportunity__c=null, Referring_User__c=u3.Id);
        insert ref;
        
        Opportunity opp = new Opportunity(Owner=u, AccountId=acct.Id, Name='Test Oppty', StageName='Sold', P_C_Quote_Result__c = 'Warm Transfer to PC', CloseDate=System.Date.today()+1);
        insert opp;
        
        opp = [SELECT Id, Name FROM Opportunity WHERE Id=:opp.Id];
        
        ref.Selling_Opportunity__c = opp.Id;
        Test.startTest();
        ReferralTriggerActions.SKIP_TRIGGER = false;
        System.runAs(u)
        {
             update ref;
        }
       
        Test.stopTest();
        ref = [SELECT Id, Name, Referring_Opportunity__c, Selling_Opportunity__c FROM Referral__c WHERE Id=:ref.Id];
        System.assertNotEquals(ref.Referring_Opportunity__c, null);
        
        Opportunity referringOpp = [SELECT Id, Name, Referring_Employee__c, Pricebook2Id FROM Opportunity WHERE Id=:ref.Referring_Opportunity__c];
        Opportunity sellingOpp = [SELECT Id, Name, Referring_Employee__c FROM Opportunity WHERE Id=:ref.Selling_Opportunity__c];
        System.assertNotEquals(null, referringOpp.Referring_Employee__c);
        System.assertEquals(referringOpp.Pricebook2Id, spricebookId);
        System.assertNotEquals(null, sellingOpp.Referring_Employee__c);
    }
 
}