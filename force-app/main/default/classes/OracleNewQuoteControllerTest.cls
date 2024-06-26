/** Test methods for the AccountCloneController class
 *
 * History
 * -------
 * 06/12/2020 Carrie Marciano   Created
 * 05/18/2021 Carrie Marciano	Carrie Marciano updated StageNames with OppStage labels
 *
*/
@isTest
public class OracleNewQuoteControllerTest {

    static testMethod void testBadPricebook() {
        
    	// create the source account
      	Account acct = new Account(Name='Test Account1', ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
        insert acct;
        // create opportunity
        ProductHelper ph = new ProductHelper();
        Schema.Recordtypeinfo mmsRt = RecordTypeHelper.getRecordType('MMS Opportunity Record Type', 'Opportunity');
        System.debug('mmsRt: '+mmsRt);
        Pricebook2 mmsPB = new Pricebook2(Name='MMS Products', IsActive=true);
      	insert mmsPB;
        
      	mmsPB= [Select Id, Name, IsActive from Pricebook2 where Name='MMS Products'];
        System.debug('mmsPB: '+mmsPB.Id);
      	Opportunity opp1 = new Opportunity(Name='Test Opp1', RecordTypeId=mmsRt.getRecordTypeId(), Pricebook2Id=mmsPB.Id, CloseDate=Date.today().addDays(7),StageName=Label.OppStage_Gained_Access
,Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id); 
      	insert opp1;
        
        //Set Current Page to new reference
        test.setCurrentPageReference(Page.OracleNewQuote);
        System.CurrentPageReference().getParameters().put('Id',opp1.Id);
        ApexPages.Standardcontroller sc = New ApexPages.StandardController(opp1);
        OracleNewQuoteController newOQC = new OracleNewQuoteController(sc);
        
        System.assertEquals(opp1.Id, newOQC.opptyId);
        System.assertEquals(false, newOQC.checkOpportunity(opp1.Id));   
       
    }
    static testMethod void testBadRecordtype() {
        // create the source account
      	Account acct = new Account(Name='Test Account1', ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
        insert acct;
        // create opportunity
        ProductHelper ph = new ProductHelper();
        Schema.Recordtypeinfo mmsDSARt = RecordTypeHelper.getRecordType('MMS Opportunity (DSA) Record Type', 'Opportunity');
        System.debug('mmsDSARt: '+mmsDSARt);
        List<String> validPBs = Label.OracleQuotePricebookId.split(',');
        String flexPB = validPBs[0];
        
        System.debug('flexPB: '+flexPB);
      	Opportunity opp1 = new Opportunity(Name='Test Opp1', RecordTypeId=mmsDSARt.getRecordTypeId(), Pricebook2Id=flexPB, CloseDate=Date.today().addDays(7),StageName=Label.OppStage_Gained_Access
,Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id); 
      	insert opp1;
        
        //Set Current Page to new reference
        test.setCurrentPageReference(Page.OracleNewQuote);
        System.CurrentPageReference().getParameters().put('Id',opp1.Id);
        ApexPages.Standardcontroller sc = New ApexPages.StandardController(opp1);
        OracleNewQuoteController newOQC = new OracleNewQuoteController(sc);
        
        System.assertEquals(opp1.Id, newOQC.opptyId);
        System.assertEquals(false, newOQC.checkOpportunity(opp1.Id));
    }
    static testMethod void testBadStage() {
        // create the source account
      	Account acct = new Account(Name='Test Account1', ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
        insert acct;
        // create opportunity
        ProductHelper ph = new ProductHelper();
        Schema.Recordtypeinfo mmsDSARt = RecordTypeHelper.getRecordType('MMS Opportunity Record Type', 'Opportunity');
        System.debug('mmsDSARt: '+mmsDSARt);
        List<String> validPBs = Label.OracleQuotePricebookId.split(',');
        String flexPB = validPBs[0];
        
        System.debug('flexPB: '+flexPB);
      	Opportunity opp1 = new Opportunity(Name='Test Opp1', RecordTypeId=mmsDSARt.getRecordTypeId(), Pricebook2Id=flexPB, CloseDate=Date.today().addDays(7),StageName=Label.OppStage_Lost,Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id); 
      	insert opp1;
        
        //Set Current Page to new reference
        test.setCurrentPageReference(Page.OracleNewQuote);
        System.CurrentPageReference().getParameters().put('Id',opp1.Id);
        ApexPages.Standardcontroller sc = New ApexPages.StandardController(opp1);
        OracleNewQuoteController newOQC = new OracleNewQuoteController(sc);
        
        System.assertEquals(opp1.Id, newOQC.opptyId);
        System.assertEquals(false, newOQC.checkOpportunity(opp1.Id));
    }
    static testMethod void testValidOppty() {
    // create the source account
      	Account acct = new Account(Name='Test Account1', ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
        insert acct;
        // create opportunity
        ProductHelper ph = new ProductHelper();
        Schema.Recordtypeinfo mmsDSARt = RecordTypeHelper.getRecordType('MMS Opportunity Record Type', 'Opportunity');
        System.debug('mmsDSARt: '+mmsDSARt);
        List<String> validPBs = Label.OracleQuotePricebookId.split(',');
        String flexPB = validPBs[0];
        
        System.debug('flexPB: '+flexPB);
      	Opportunity opp1 = new Opportunity(Name='Test Opp1', RecordTypeId=mmsDSARt.getRecordTypeId(), Pricebook2Id=flexPB, CloseDate=Date.today().addDays(7),StageName=Label.OppStage_Gained_Access,Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id); 
      	insert opp1;
        
        //Set Current Page to new reference
        test.setCurrentPageReference(Page.OracleNewQuote);
        System.CurrentPageReference().getParameters().put('Id',opp1.Id);
        ApexPages.Standardcontroller sc = New ApexPages.StandardController(opp1);
        OracleNewQuoteController newOQC = new OracleNewQuoteController(sc);
        
        System.assertEquals(opp1.Id, newOQC.opptyId);
        System.assertEquals(true, newOQC.checkOpportunity(opp1.Id));  
        System.assert(true,newOQC.checkRedirect());
    }
}