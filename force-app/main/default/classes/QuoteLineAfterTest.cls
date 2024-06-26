/* 
   Test methods for the QuoteLineAfter trigger.. 
   
  History
  -------
  06/28/2016 Carrie Marciano   	Created
  03/06/2018 Carrie Marciano	updated test to use asterisk for quote approvals
      
 */

@isTest
public class QuoteLineAfterTest {
    static testMethod void testQuoteLineAfterMethod(){
    	QuoteLineAfter insQuoteLineAfter = new QuoteLineAfter();
  	}
 /*   
    static testMethod void testQuoteUpdate() {
     // insert account 
    Account acct1 = new Account(Name='Test Account1');
    Account acct2 = new Account(Name='Test Account2');
    Account[] accts = new Account[]{acct1,acct2};
    ZipCheckOwner.SKIP_TRIGGERS=true;
    insert accts;
     
    // create Opportunity
      Schema.Recordtypeinfo mmsRt = RecordTypeHelper.getRecordType('MMS Opportunity Record Type', 'Opportunity');
      Opportunity opp1 = new Opportunity(Name='Test 1', leadSource = 'Cold Call', CloseDate=Date.today(), StageName='Pending', RecordTypeId=mmsRt.getRecordTypeId());
      Opportunity[] opps = new Opportunity[]{opp1};
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
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
      Product2[] prods = new Product2[]{prod1,prod2};
      insert prods; 
        
    // verify product values updated
      Product2[] nProds = [Select Id, Name from Product2 where Id in :prods];
      System.debug('***CLM*** After inserted Products nProds: ' + nProds);
        
    // create pricebookentry
      Id spricebookId = Test.getStandardPricebookId();
      System.debug('***CLM*** spricebookId: ' + spricebookId);
     
      PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = prod1.Id, UnitPrice=5.00, isActive=true, UseStandardPrice=false);
      PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = prod2.Id, UnitPrice=7.00, isActive=true, UseStandardPrice=false);  
      PricebookEntry[] spbes = new PricebookEntry[]{spbe1,spbe2};
      insert spbes;
        
      Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
      insert flexPB;
        
      flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];
      System.debug('***CLM*** flexPB.Id: ' + flexPB.Id); 
        
      PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = prod1.Id, UnitPrice=5.00, isActive=true);
      PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = prod2.Id, UnitPrice=7.00, isActive=true);
      PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
      insert pbes;
        
    // verify pricebookentry values updated
      PricebookEntry[] nPbes = [Select Id, Pricebook2Id, Product2Id, UnitPrice, Product2.Name, Pricebook2.Name from PricebookEntry where Id in :pbes];
      System.debug('***CLM*** After inserted PricebookEntries nPbes: ' + nPbes);
      
    // create quote
      //Schema.Recordtypeinfo mmsQRt = RecordTypeHelper.getRecordType('MMS Quote', 'SBQQ__Quote__c');
      Schema.Recordtypeinfo mmsQRt = RecordTypeHelper.getRecordType('Quote', 'SBQQ__Quote__c');
      SBQQ__Quote__c q1 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.id, SBQQ__Status__c='Draft', Necessary_Approvers__c='*5*0*', RecordTypeId=mmsQRt.getRecordTypeId());
      SBQQ__Quote__c q2 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.id, SBQQ__Status__c='Draft', Necessary_Approvers__c='*5*0*', RecordTypeId=mmsQRt.getRecordTypeId());
      SBQQ__Quote__c[] qs = new SBQQ__Quote__c[]{q1,q2};
      insert qs;
    
     // create quotelinegroups
      SBQQ__QuoteLineGroup__c qlg1 = new SBQQ__QuoteLineGroup__c(SBQQ__Quote__c= q2.id, Name='Group1', SBQQ__Account__c=acct1.id, SBQQ__Number__c=00001, Annualized_Fees__c=0.00, One_Time_Fees__c=0.00, SBQQ__NetTotal__c=0.00);
      SBQQ__QuoteLineGroup__c qlg2 = new SBQQ__QuoteLineGroup__c(SBQQ__Quote__c= q2.id, Name='Group2', SBQQ__Account__c=acct2.id, SBQQ__Number__c=00002, Annualized_Fees__c=0.00, One_Time_Fees__c=0.00, SBQQ__NetTotal__c=0.00);  
      SBQQ__QuoteLineGroup__c[] qlgs = new SBQQ__QuoteLineGroup__c[]{qlg1,qlg2};
      insert qlgs; 
        
     // verify quotelinegroups values updated
      SBQQ__QuoteLineGroup__c[] nQlgs = [Select Id, SBQQ__Quote__c, Name, SBQQ__Account__c, Annualized_Fees__c, One_Time_Fees__c, SBQQ__NetTotal__c from SBQQ__QuoteLineGroup__c where Id in :qlgs];
      System.debug('***CLM*** After inserted quotelinegroups nQlgs: ' + nQlgs);
        
     // create quotelines
      SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q1.id, SBQQ__Product__c=prod1.Id, SBQQ__Quantity__c=1, SBQQ__ListPrice__c=5.00, SBQQ__Discount__c=65, ApprovalLevel__c=5);
      SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q1.id, SBQQ__Product__c=prod2.Id, SBQQ__Quantity__c=1, SBQQ__ListPrice__c=7.00, SBQQ__Discount__c=null, ApprovalLevel__c=0);  
      SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q2.id, SBQQ__Group__c=qlg1.id, SBQQ__Product__c=prod1.Id, Pricing_Type__c='Per Pay Period', PayrollFrequency__c='Weekly', SBQQ__Quantity__c=1, SBQQ__ListPrice__c=5.00, SBQQ__NetPrice__c=91.00, SBQQ__Discount__c=65, ApprovalLevel__c=5);
      SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q2.id, SBQQ__Group__c=qlg1.id, SBQQ__Product__c=prod2.Id, Pricing_Type__c='Per Pay Period', PayrollFrequency__c='Weekly', SBQQ__Quantity__c=1, SBQQ__ListPrice__c=7.00, SBQQ__NetPrice__c=0.00, SBQQ__Discount__c=null, ApprovalLevel__c=0);  
      SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q2.id, SBQQ__Group__c=qlg2.id, SBQQ__Product__c=prod1.Id, Pricing_Type__c='Per Pay Period', PayrollFrequency__c='Weekly', SBQQ__Quantity__c=1, SBQQ__ListPrice__c=5.00, SBQQ__NetPrice__c=260.00);
      SBQQ__QuoteLine__c qli6 = new SBQQ__QuoteLine__c(SBQQ__Quote__c= q2.id, SBQQ__Group__c=qlg2.id, SBQQ__Product__c=prod2.Id, Pricing_Type__c='Per Pay Period', PayrollFrequency__c='Weekly', SBQQ__Quantity__c=1, SBQQ__ListPrice__c=7.00, SBQQ__NetPrice__c=0.00);  
      SBQQ__QuoteLine__c[] qlis = new SBQQ__QuoteLine__c[]{qli1,qli2,qli3,qli4,qli5,qli6};
      insert qlis; 
        
     // verify quoteline values updated
      SBQQ__QuoteLine__c[] nQlis = [Select Id, SBQQ__Quote__c, SBQQ__Group__c, SBQQ__Product__c, SBQQ__Discount__c, ApprovalLevel__c, NetTotalPerPeriod__c, SBQQ__NetTotal__c from SBQQ__QuoteLine__c where Id in :qlis];
      System.debug('***CLM*** After inserted quotelines nQlis: ' + nQlis);

      Set<Id> quoteIdsToUpdate = new Set<Id>();
    // verify quote values updated    
      q1 = [Select Id, Necessary_Approvers__c from SBQQ__Quote__c where Id = :q1.Id];    
      quoteIdsToUpdate.add(q1.Id);
      if (!quoteIdsToUpdate.isEmpty()) {
            System.debug('***CLM*** calling QuoteLineAfter class for processNecessaryApprovals');
            QuoteLineAfter.processLineItems(quoteIdsToUpdate);
      }
      System.assertEquals('*5*0*',q1.Necessary_Approvers__c);
      
      // verify quotelinegroup values updated    
      //q2 = [Select Id from SBQQ__Quote__c where Id = :q2.Id];
      qlg1 = [select Id, SBQQ__Quote__c, Name, SBQQ__Account__c, Annualized_Fees__c, One_Time_Fees__c, SBQQ__NetTotal__c from SBQQ__QuoteLineGroup__c where Id = :qlg1.Id and SBQQ__QuoteLineGroup__c.SBQQ__Quote__r.Id = :q2.Id];
      System.debug('qlg1='+qlg1);
      quoteIdsToUpdate.add(q2.Id);
      if (!quoteIdsToUpdate.isEmpty()) {
            System.debug('***CLM*** calling QuoteLineAfter class for processMultiId');
            QuoteLineAfter.processLineItems(quoteIdsToUpdate);
      }
      
      qlg1 = [select Id, SBQQ__Quote__c, Name, SBQQ__Account__c, Annualized_Fees__c, One_Time_Fees__c, SBQQ__NetTotal__c from SBQQ__QuoteLineGroup__c where Id = :qlg1.Id and SBQQ__QuoteLineGroup__c.SBQQ__Quote__r.Id = :q2.Id];
      System.assertEquals(8.75,qlg1.Annualized_Fees__c);
   } // testQuoteUpdate*/
} // class QuoteLineAfterTest