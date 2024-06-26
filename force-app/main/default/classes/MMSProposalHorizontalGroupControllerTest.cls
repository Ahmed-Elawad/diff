// test for MMSProposalHorizontalGroupController

/* 

  History
  --------
  
  10/08/2018 Frank Lurz   created
  
*/  
@isTest

public class MMSProposalHorizontalGroupControllerTest {
    static testMethod void testMMSGroupControllerMethod(){
        MMSProposalHorizontalGroupController insMMSGroupController = new MMSProposalHorizontalGroupController();
    }
/* static testMethod void testQuoteTemplate() {
    // insert account 
      Account acct1 = new Account(Name='Test Account1');
      Account[] accts = new Account[]{acct1};
      insert accts;
     
    // create Opportunity
      Schema.Recordtypeinfo mmsRt = RecordTypeHelper.getRecordType('MMS Opportunity Record Type', 'Opportunity');
      Opportunity opp1 = new Opportunity(Name='Test 1', leadSource = 'Cold Call', CloseDate=Date.today(), StageName='Pending', RecordTypeId=mmsRt.getRecordTypeId());
      Opportunity[] opps = new Opportunity[]{opp1};
      insert opps;
     
    // verify opportunity values updated
      opp1 = [Select Id, StageName, Amount, Revenue__c, Setup_Fee__c, Payroll_Units__c, Product_Summary__c  from Opportunity where Id = :opp1.Id];
    
    // insert product 
      Product2 prod1 = new Product2(Name='Direct Deposit',ProductCode='Direct Deposit',IsActive=true,Family='Direct Deposit', Pricing_Type__c='Per Pay Period', Level_1_Approval__c=1
                                    , Level_1_Discount_Level__c=25, Level_2_Approval__c=2, Level_2_Discount_Level__c=40, Level_3_Approval__c=5
                                    , Level_3_Discount_Level__c=60);
      Product2 prod2 = new Product2(Name='Taxpay',ProductCode='Taxpay',IsActive=true,Family='Taxpay', Pricing_Type__c='Per Pay Period', Level_1_Approval__c=1
                                    , Level_1_Discount_Level__c=25, Level_2_Approval__c=2, Level_2_Discount_Level__c=40, Level_3_Approval__c=5
                                    , Level_3_Discount_Level__c=60);  
      Product2 prod3 = new Product2(Name='Badge Rack Setup',ProductCode='Badge Rack Setup',IsActive=true,Family='Badge Rack', Pricing_Type__c='One-time', Level_1_Approval__c=1
                                    , Level_1_Discount_Level__c=25, Level_2_Approval__c=2, Level_2_Discount_Level__c=40, Level_3_Approval__c=5
                                    , Level_3_Discount_Level__c=60); 
                                    //, Is_Setup_Fee__c=TRUE);  
      Product2[] prods = new Product2[]{prod1,prod2,prod3};
      insert prods; 
        
    // verify product values updated
      Product2[] nProds = [Select Id, Name from Product2 where Id in :prods];
      System.debug('***FRL*** After inserted Products nProds: ' + nProds);
        
    // create pricebookentry
      Id spricebookId = Test.getStandardPricebookId();
      System.debug('***FRL*** spricebookId: ' + spricebookId);
     
      PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = prod1.Id, UnitPrice=5.00, isActive=true, UseStandardPrice=false);
      PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = prod2.Id, UnitPrice=7.00, isActive=true, UseStandardPrice=false);  
      PricebookEntry spbe3 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = prod3.Id, UnitPrice=1.00, isActive=true, UseStandardPrice=false);  
      PricebookEntry[] spbes = new PricebookEntry[]{spbe1,spbe2,spbe3};
      insert spbes;
        
      Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
      insert flexPB;
        
      flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];
      System.debug('***FRL*** flexPB.Id: ' + flexPB.Id); 
        
      PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = prod1.Id, UnitPrice=5.00, isActive=true);
      PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = prod2.Id, UnitPrice=7.00, isActive=true);
      PricebookEntry pbe3 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = prod3.Id, UnitPrice=1.00, isActive=true);
      PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2,pbe3};
      insert pbes;
        
    // verify pricebookentry values updated
      PricebookEntry[] nPbes = [Select Id, Pricebook2Id, Product2Id, UnitPrice, Product2.Name, Pricebook2.Name from PricebookEntry where Id in :pbes];
      System.debug('***FRL*** After inserted PricebookEntries nPbes: ' + nPbes);
      
    // create quote
      //Schema.Recordtypeinfo mmsQRt = RecordTypeHelper.getRecordType('MMS Quote', 'SBQQ__Quote__c');
      Schema.Recordtypeinfo mmsQRt = RecordTypeHelper.getRecordType('Quote', 'SBQQ__Quote__c');
      SBQQ__Quote__c q1 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.id, SBQQ__Status__c='Draft', Necessary_Approvers__c='*5*0*', RecordTypeId=mmsQRt.getRecordTypeId());
      insert q1;
    
     // create quotelinegroups
      SBQQ__QuoteLineGroup__c qlg1 = new SBQQ__QuoteLineGroup__c(SBQQ__Quote__c= q1.id, Name='Group1', SBQQ__Account__c=acct1.id, SBQQ__Number__c=00001, Annualized_Fees__c=0.00, One_Time_Fees__c=0.00, SBQQ__NetTotal__c=0.00);
      SBQQ__QuoteLineGroup__c qlg2 = new SBQQ__QuoteLineGroup__c(SBQQ__Quote__c= q1.id, Name='Group2', SBQQ__Account__c=acct1.id, SBQQ__Number__c=00002, Annualized_Fees__c=0.00, One_Time_Fees__c=0.00, SBQQ__NetTotal__c=0.00);  
      SBQQ__QuoteLineGroup__c[] qlgs = new SBQQ__QuoteLineGroup__c[]{qlg1,qlg2};
      insert qlgs; 
        
     // verify quotelinegroups values updated
      SBQQ__QuoteLineGroup__c[] nQlgs = [Select Id, SBQQ__Quote__c, Name, SBQQ__Account__c, Annualized_Fees__c, One_Time_Fees__c, SBQQ__NetTotal__c from SBQQ__QuoteLineGroup__c where Id in :qlgs];
      System.debug('***FRL*** After inserted quotelinegroups nQlgs: ' + nQlgs);
        
     // create quotelines
      SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q1.id, SBQQ__Group__c=qlg1.id, SBQQ__Product__c=prod1.Id, Pricing_Type__c='Per Pay Period', PayrollFrequency__c='Weekly', SBQQ__Quantity__c=1, SBQQ__ListPrice__c=5.00, SBQQ__NetPrice__c=91.00, SBQQ__Discount__c=65, ApprovalLevel__c=5);
      SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q1.id, SBQQ__Group__c=qlg1.id, SBQQ__Product__c=prod2.Id, Pricing_Type__c='Per Pay Period', PayrollFrequency__c='Weekly', SBQQ__Quantity__c=1, SBQQ__ListPrice__c=7.00, SBQQ__NetPrice__c=0.00, SBQQ__Discount__c=null, ApprovalLevel__c=0);  
      SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q1.id, SBQQ__Group__c=qlg2.id, SBQQ__Product__c=prod1.Id, Pricing_Type__c='Per Pay Period', PayrollFrequency__c='Weekly', SBQQ__Quantity__c=1, SBQQ__ListPrice__c=5.00, SBQQ__NetPrice__c=260.00);
      SBQQ__QuoteLine__c qli6 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q1.id, SBQQ__Group__c=qlg2.id, SBQQ__Product__c=prod2.Id, Pricing_Type__c='Per Pay Period', PayrollFrequency__c='Weekly', SBQQ__Quantity__c=1, SBQQ__ListPrice__c=7.00, SBQQ__NetPrice__c=0.00);  
      SBQQ__QuoteLine__c qli7 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q1.id, SBQQ__Group__c=qlg1.id, SBQQ__Product__c=prod3.Id, Pricing_Type__c='One-time', PayrollFrequency__c='Weekly', SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1.00, SBQQ__NetPrice__c=1.00, SBQQ__Discount__c=null, ApprovalLevel__c=0);  
      SBQQ__QuoteLine__c qli8 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q1.id, SBQQ__Group__c=qlg2.id, SBQQ__Product__c=prod3.Id, Pricing_Type__c='One-time', PayrollFrequency__c='Weekly', SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1.00, SBQQ__NetPrice__c=1.00, SBQQ__Discount__c=null, ApprovalLevel__c=0);  
    
      
      SBQQ__QuoteLine__c[] qlis = new SBQQ__QuoteLine__c[]{qli3,qli4,qli5,qli6,qli7,qli8};
      insert qlis; 
        
     // verify quoteline values updated
      SBQQ__QuoteLine__c[] nQlis = [Select Id, SBQQ__Quote__c, SBQQ__Group__c, SBQQ__Product__c, SBQQ__Discount__c, ApprovalLevel__c, NetTotalPerPeriod__c, SBQQ__NetTotal__c from SBQQ__QuoteLine__c where Id in :qlis];
      System.debug('***FRL*** After inserted quotelines nQlis: ' + nQlis);

     // verify returns totals    
      Test.StartTest();   
      /////MMSProposalHorizontalGroupController mphgc = new MMSProposalHorizontalGroupController();
      PageReference pageRef = Page.MMSProposalHorizontalGroupSection; 
      Test.setCurrentPage(pageRef);
      ApexPages.currentPage().getParameters().put('qId', q1.Id);
    
      MMSProposalHorizontalGroupController mphgc = new MMSProposalHorizontalGroupController();
      System.debug('***FRL*** mphgc.qid: ' + mphgc.qid);    
      //List<MMSProposalHorizontalGroupController.GroupLine> sumQgls = mphgc.grouplines;
      System.assertNotEquals(null, mphgc.grouplines);
      Test.stopTest(); 

      
 }//end testMethod
 */
}