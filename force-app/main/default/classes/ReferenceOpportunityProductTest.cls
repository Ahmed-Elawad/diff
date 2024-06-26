/* 
   Test methods for the ReferenceOpportunityProduct class.. 
   
  History
  -------
  04/03/2019 Carrie Marciano   Created
  08/20/2019 Brandon Vidro     Modified to include MSA changes and standalone products test
  07/17/2023 Dan Carmen        Refactor code
    
 */

@isTest
public class ReferenceOpportunityProductTest {
    static testMethod void testOpptyProduct() {
          // create ServiceAgreementTemplateMapping
          List<ServiceAgreementTemplateMapping__c> satList = new List<ServiceAgreementTemplateMapping__c>();    				
          satList.add(new ServiceAgreementTemplateMapping__c(Name='Flex Enterprise',Product_Code__c='PFE', TemplateIDs__c='a1B0g000008RTmy,a1B2F000001SFKZ,a1B0g000008RTme,a1B2F000001SG2Z,a1B0g000008RTmt', API_Name__c = 'Flex_Enterprise__c'));       
          satList.add(new ServiceAgreementTemplateMapping__c(Name='Flex Select',Product_Code__c='PFS', TemplateIDs__c='a1B0g000008RTmy,a1B2F000001SJQU,a1B0g000008RTme,a1B2F000001SG2Z,a1B0g000008RTmt', API_Name__c = 'Flex_Select__c'));      
          satList.add(new ServiceAgreementTemplateMapping__c(Name='Flex Pro',Product_Code__c='PFP', TemplateIDs__c='a1B0g000008RTmy,a1B0g000008RTmZ,a1B0g000008RTme,a1B0g000008RTmo,a1B0g000008RTmt', API_Name__c = 'Paychex_Flex_Pro__c')); 
          satList.add(new ServiceAgreementTemplateMapping__c(Name='Tax Credit Service',Product_Code__c='TCS', Additional_Template_Check__c = true, Additional_Template__c='a1B2h0000012IzF', API_Name__c = 'Tax_Credit_Service__c')); 
          insert satList;
        
          // create Opportunity
          Schema.Recordtypeinfo mmsRt = RecordTypeHelper.getRecordType('MMS Opportunity Record Type', 'Opportunity');
          Opportunity opp1 = new Opportunity(Name='Test 1', CloseDate=Date.today(), StageName='Pending', RecordTypeId=mmsRt.getRecordTypeId());
          Opportunity opp2 = new Opportunity(Name='Test 2', CloseDate=Date.today(), StageName='Pending', RecordTypeId=mmsRt.getRecordTypeId());
          Opportunity opp3 = new Opportunity(Name='Test 3', CloseDate=Date.today(), StageName='Pending', RecordTypeId=mmsRt.getRecordTypeId());
          Opportunity opp4 = new Opportunity(Name='Test 4', CloseDate=Date.today(), StageName='Pending', RecordTypeId=mmsRt.getRecordTypeId());
          Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4};
          insert opps;
          
          // create ReferenceOpportunityProducts
          Reference_Opportunity_Product__c rop1 = new Reference_Opportunity_Product__c(Opportunity__c=opp1.Id);
          Reference_Opportunity_Product__c rop2 = new Reference_Opportunity_Product__c(Opportunity__c=opp2.Id);
          Reference_Opportunity_Product__c rop3 = new Reference_Opportunity_Product__c(Opportunity__c=opp3.Id);
          Reference_Opportunity_Product__c rop4 = new Reference_Opportunity_Product__c(Opportunity__c=opp4.Id);
          Reference_Opportunity_Product__c[] rops = new Reference_Opportunity_Product__c[]{rop1,rop2,rop3,rop4};
          insert rops;
        
          // get a pricebookentry
          String[] prodNames = new String[]{'PFE','PFS','PFP','TCS'};
          PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'OpptyLineItemTest',null);
          PricebookEntry entryPFE = entries.get(0);
          PricebookEntry entryPFS = entries.get(1);
          PricebookEntry entryPFP = entries.get(2);
          PricebookEntry entryTCS = entries.get(3);
        
          OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entryPFE.Id, Status__c='Pending', ServiceDate=Date.today(), Quantity=1, TotalPrice=0, Setup_Fee__c=0, Payroll_Unit__c=0);
          OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opp2.Id, PricebookEntryId=entryPFS.Id, Status__c='Pending', ServiceDate=Date.today(), Quantity=1, TotalPrice=0, Setup_Fee__c=0, Payroll_Unit__c=0);
          OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId=opp3.Id, PricebookEntryId=entryPFP.Id, Status__c='Pending', ServiceDate=Date.today(), Quantity=1, TotalPrice=0, Setup_Fee__c=0, Payroll_Unit__c=0);
          OpportunityLineItem oli4 = new OpportunityLineItem(OpportunityId=opp4.Id, PricebookEntryId=entryTCS.Id, Status__c='Pending', ServiceDate=Date.today(), Quantity=1, TotalPrice=0, Setup_Fee__c=0, Payroll_Unit__c=0);
          OpportunityLineItem [] olis = new OpportunityLineItem[]{oli1,oli2,oli3,oli4};
          insert olis;
      	         
          // verify product was created and templates retrieved
      	  opp1 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, CongaTemplateIds__c, OpportunityId__c
                from Opportunity where Id = :opp1.Id];
          System.assertEquals(true, opp1.HasOpportunityLineItem); 
        
          opp2 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, CongaTemplateIds__c, OpportunityId__c
                from Opportunity where Id = :opp2.Id];
          System.assertEquals(true, opp2.HasOpportunityLineItem);
        
          opp3 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, CongaTemplateIds__c, OpportunityId__c
                from Opportunity where Id = :opp3.Id];
          System.assertEquals(true, opp3.HasOpportunityLineItem);
           
          opp4 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, CongaTemplateIds__c, OpportunityId__c
                from Opportunity where Id = :opp4.Id];
          System.assertEquals(true, opp4.HasOpportunityLineItem);
          System.assert(opp4.CongaTemplateIds__c != null);
        
       } // testOpptyProduct
}