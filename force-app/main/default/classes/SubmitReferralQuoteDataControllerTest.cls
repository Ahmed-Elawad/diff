/*
*Test Class  of SubmitReferralQuoteDataController
*History
*------------------
*09/25/2023 Pratik Das         Created APR0154201: Add process/button to P&C Quote Data 
*/ 

@isTest
public class SubmitReferralQuoteDataControllerTest{
    public static String [] dqSalesOrgs = Label.PCQuoteDataSalesOrg.split(',');
    public static ID pcRT = Label.PCQuoteDataRecordTypeId;
    //setup
    @TestSetup
    static void setupPCData(){
        User userPC = [SELECT Id, Email FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:dqSalesOrgs LIMIT 1];
        Account acct = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                   ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
            insert acct;
                
            Contact ctct = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct.id);
            insert ctct;
            
            Opportunity opp = new Opportunity(Name='PC OPP', AccountId=acct.Id, RecordTypeId = pcRT, OpportunityType__c = 'BOP (Business Owners Package)', HNBF_Sales_Type__c = 'New Case', CloseDate=Date.today().addDays(7), StageName = 'Discovery', Probability = 40);
            insert opp;
            Test.startTest();
            //initial insert of P&C Quote Data as if created by TarmikaBridgeController
            PC_Quote_Data__c pcqD = new PC_Quote_Data__c(Opportunity__c = opp.Id, Prospect_Client__c=acct.Id, Opportunity_Type__c=opp.OpportunityType__c,Prospect_Client_Name__c=acct.Name,
                                                         Prospect_Client_Street__c=acct.ShippingStreet, Prospect_Client_City__c=acct.ShippingCity, Prospect_Client_State__c=acct.ShippingState,
                                                         Prospect_Client_Postal_Code__c=acct.ShippingPostalCode, Contact_First_Name__c=ctct.FirstName, Contact_Last_Name__c=ctct.LastName,
                                                         Contact_Phone_Number__c=ctct.Phone, Contact_Email_Address__c=ctct.Email);
            insert pcqD;
    }

    @isTest(seeAllData=false)
    static void testPCQuoteData(){

        List<Account> lstAccount=[Select id from Account where Name='ACCT1'];
        List<PC_Quote_Data__c> lstPCQuoteData=[Select id from PC_Quote_Data__c where Prospect_Client__c=:lstAccount[0].Id];
        Test.SetCurrentPageReference(Page.SubmitReferralQuoteData);
        System.CurrentPageReference().getParameters().put('Id',lstPCQuoteData[0].Id);
        SubmitReferralQuoteDataController srqd=new SubmitReferralQuoteDataController();
        test.startTest();
        srqd.redirectReferral();
        test.stopTest();
    }

}