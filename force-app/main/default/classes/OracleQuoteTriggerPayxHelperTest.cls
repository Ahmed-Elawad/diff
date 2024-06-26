/* 
Test methods for the OpptyLineItem trigger.. 

History
-------
06/24/2020	Carrie Marciano	Created
05/18/2021 	Carrie Marciano updated StageNames with OppStage labels
05/22/2023    Dan Carmen      Updated Quote test to set the Data Set name based on the cafsl__Embedded_CPQ_Settings__c
07/31/2023    Dan Carmen      add setupOracleUserTrigger so that Oracle doesn't try to perform a callout in a test method
10/16/2023    Pratik Das      APR0116247: Added testDelete for Delete trigger
*/
@isTest
public class OracleQuoteTriggerPayxHelperTest {
    @testSetup
    public static void setupData() {
        setupMapping();
        setupOracleSetting();
    } // setupData
    
    // this is used to get around an oracle error that happens during test runs where the Oracle trigger is trying to sync the user back to Oracle.
    // Assuming that you do NOT need to test the actual callout to CPQ’s User REST endpoint, you can skip this two ways:
    // 1.	When the seed the Oracle_User__c, set Link_to_CPQ_User__c=false
    // 2.	Before inserting the Oracle_User__c, set the custom setting CAFSL_Settings__c’s Disable_Update_CPQ_User__c=true (this is more “global” approach)
    // Both will skip the logic that attempts (and fails) to construct a JSON “cafsl.OracleUserTriggerHelper.UserSyncException: No action steps found for "userUpdate"
    
    public static void setupOracleUserTrigger() {
        cafsl__CAFSL_Settings__c setting = cafsl__CAFSL_Settings__c.getOrgDefaults();
        setting.cafsl__Disable_Update_CPQ_User__c = true;
        upsert setting cafsl__CAFSL_Settings__c.Id;
    } // setupOracleUserTrigger
    
    public static void setupOracleSetting() {
        cafsl__Embedded_CPQ_Settings__c embeddedCPQSetting = new cafsl__Embedded_CPQ_Settings__c();
        embeddedCPQSetting.Name = 'OracleQuoteTriggerPayxHelperTest';
        embeddedCPQSetting.cafsl__Callout_URL__c = 'https://paychexinctest2.bigmachines.com/';
        embeddedCPQSetting.cafsl__Connected_App_Name__c = 'OracleCPQUAT';
        embeddedCPQSetting.cafsl__Copy_Action_Id__c = '36844333';
        embeddedCPQSetting.cafsl__Data_Set__c = 'paychexinctest2';
        embeddedCPQSetting.cafsl__Document_Id__c = '36843701';
        embeddedCPQSetting.cafsl__Open_Action_Id__c = '36844341';
        embeddedCPQSetting.cafsl__Primary__c = True;
        embeddedCPQSetting.cafsl__Process_Id__c = '36843633';
        embeddedCPQSetting.cafsl__Process_Name__c  = 'paychexCommerceProcess';
        embeddedCPQSetting.cafsl__Embed_In_Lightning__c = True;    
        embeddedCPQSetting.cafsl__Use_Opportunity_Currency__c = True;
        embeddedCPQSetting.cafsl__Use_Opportunity_Pricebook__c = True;   
        embeddedCPQSetting.cafsl__Version_Id__c = '36850804';
        embeddedCPQSetting.cafsl__Version_Number__c = 2022.300;
        insert embeddedCPQSetting; 
        
    } // setupOracleSetting
    
    public static void setupMapping() {
        //oracle field mappings
        cafsl__Field_Mapping__c qFieldMapping1 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest2', cafsl__Type__c='Oracle Quote to Opportunity', cafsl__Source__c='multi_id__c', cafsl__Target__c='multi_id_client__c');
        cafsl__Field_Mapping__c qFieldMapping2 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest2', cafsl__Type__c='Oracle Quote to Opportunity', cafsl__Source__c='multiple_pay_frequencies__c', cafsl__Target__c='multi_frequency__c');
        cafsl__Field_Mapping__c qFieldMapping3 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest2', cafsl__Type__c='Oracle Quote to Opportunity', cafsl__Source__c='number_of_related_accounts__c', cafsl__Target__c='number_of_ids__c');
        cafsl__Field_Mapping__c qFieldMapping4 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest2', cafsl__Type__c='Oracle Quote to Opportunity', cafsl__Source__c='status__c', cafsl__Target__c='primary_oracle_quote_status__c');
        cafsl__Field_Mapping__c qlFieldMapping1 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest2', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='discount_percent__c', cafsl__Target__c='discount_percent__c');
        cafsl__Field_Mapping__c qlFieldMapping2 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest2', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='customer_price_unit__c', cafsl__Target__c='unitprice');
        cafsl__Field_Mapping__c qlFieldMapping3 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest2', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='cafsl__quantity__c', cafsl__Target__c='quantity');
        cafsl__Field_Mapping__c qlFieldMapping4 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest2', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='cafsl__cpq_external_id__c', cafsl__Target__c='cpq_external_id__c');
        cafsl__Field_Mapping__c qlFieldMapping5 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='cafsl__sales_price__c', cafsl__Target__c='oracle_sales_price__c');
        
        
        cafsl__Field_Mapping__c[] fMappings = new cafsl__Field_Mapping__c[]{qFieldMapping1,qFieldMapping2,qFieldMapping3,qFieldMapping4
            ,qlFieldMapping1,qlFieldMapping2,qlFieldMapping3,qlFieldMapping4, qlFieldMapping5};
                insert fMappings;
    }
    
    public static cafsl__Embedded_CPQ_Settings__c getOracleSetting() {
        cafsl__Embedded_CPQ_Settings__c setting = [Select Id, Name, cafsl__Data_Set__c
                                                   From cafsl__Embedded_CPQ_Settings__c
                                                   Where Name='OracleQuoteTriggerPayxHelperTest'];
        return setting;
    } // getOracleSetting
    
    
    
    static testMethod void testStatusUpdate() {
        // create account
        Account acct = new Account(Name='Test Account1', ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
        insert acct;
        // create opportunity
        ProductHelper ph = new ProductHelper();
        Schema.Recordtypeinfo asoRt = RecordTypeHelper.getRecordType('ASO Opportunity Record Type', 'Opportunity');
        System.debug('asoRt: '+asoRt);
        List<String> validPBs = Label.OracleQuotePricebookId.split(',');
        String asoPB = validPBs[0];
        System.debug('asoPB: '+asoPB);
        
        User oppOwner = [Select Id, Name, Sales_Org__c from User 
                         where IsActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO limit 1];
        System.debug('oppOwner: '+oppOwner);
        
        Opportunity opp1 = new Opportunity(Name='Test Opp1', RecordTypeId=asoRt.getRecordTypeId(), Pricebook2Id=asoPB, OwnerId=oppOwner.Id, CloseDate=Date.today().addDays(7),StageName=Label.OppStage_Gained_Access, Primary_Oracle_Quote__c=null, Primary_Oracle_Quote_Status__c='', Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id); 
        insert opp1;
        
        cafsl__Embedded_CPQ_Settings__c setting = getOracleSetting();
        
        cafsl__Field_Mapping__c[] newFMappings = [SELECT Id, Name, cafsl__Type__c, cafsl__Source__c, cafsl__Target__c FROM cafsl__Field_Mapping__c];
        System.debug('newFMappings='+newFMappings);
        
        //New Quote
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opp1.AccountId;
        quote.cafsl__Opportunity__c = opp1.Id;
        quote.cafsl__Syncing__c = true;
        quote.Name = 'TestQuote';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        quote.Multi_ID__c = false;
        quote.cafsl__Pricebook_Id__c = asoPB;
        quote.cafsl__CPQ_External_Id__c='12345678';
        quote.Status__c = 'draft';
        quote.cafsl__Start_Upserting_Lines__c = true;
        insert quote;
        
        cafsl__Oracle_Quote__c newQuote = [SELECT Id, Name, cafsl__CPQ_External_Id__c, Approver__c, Status__c FROM cafsl__Oracle_Quote__c WHERE Id=:quote.Id];
        System.debug('newQuote='+newQuote);
        System.assertEquals('draft', newQuote.Status__c);
        
        Opportunity opp1Updated = [SELECT Id, Name, StageName, Primary_Oracle_Quote__c, Primary_Oracle_Quote_Status__c FROM Opportunity WHERE Primary_Oracle_Quote__c=:quote.Id];
        System.debug('opp1Updated='+opp1Updated);
        System.assertEquals(Label.OppStage_Discovery, opp1Updated.StageName);
    }
    
    //APR0116247: Remove the ability to Delete Oracle Quotes--Start
    static testMethod void testDelete(){
        // create account
        Account acct = new Account(Name='Test Account1', ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
        insert acct;
        // create opportunity
        ProductHelper ph = new ProductHelper();
        Schema.Recordtypeinfo asoRt = RecordTypeHelper.getRecordType('ASO Opportunity Record Type', 'Opportunity');
        System.debug('asoRt: '+asoRt);
        List<String> validPBs = Label.OracleQuotePricebookId.split(',');
        String asoPB = validPBs[0];
        System.debug('asoPB: '+asoPB);
        
        User oppOwner = [Select Id, Name, Sales_Org__c from User 
                         where IsActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO limit 1];
        System.debug('oppOwner: '+oppOwner);
        
        Opportunity opp1 = new Opportunity(Name='Test Opp1', RecordTypeId=asoRt.getRecordTypeId(), Pricebook2Id=asoPB, OwnerId=oppOwner.Id, CloseDate=Date.today().addDays(7),StageName=Label.OppStage_Gained_Access, Primary_Oracle_Quote__c=null, Primary_Oracle_Quote_Status__c='', Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id); 
        insert opp1;
        
        cafsl__Embedded_CPQ_Settings__c setting = getOracleSetting();
        
        cafsl__Field_Mapping__c[] newFMappings = [SELECT Id, Name, cafsl__Type__c, cafsl__Source__c, cafsl__Target__c FROM cafsl__Field_Mapping__c];
        System.debug('newFMappings='+newFMappings);
        
        //New Quote
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opp1.AccountId;
        quote.cafsl__Opportunity__c = opp1.Id;
        quote.cafsl__Syncing__c = true;
        quote.Name = 'TestQuote';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        quote.Multi_ID__c = false;
        quote.cafsl__Pricebook_Id__c = asoPB;
        quote.cafsl__CPQ_External_Id__c='12345678';
        quote.Status__c = 'draft';
        quote.cafsl__Start_Upserting_Lines__c = true;
        insert quote;
        try{
            Delete quote;
        }
        catch(Exception ex){
            
        }
        
    }
    //APR0116247: Remove the ability to Delete Oracle Quotes--End
}