/** Batch process to calculate opportunity revenue
 *
 * History
 * -------
 * 11/07/2012 Dan Carmen   Created
   08/06/2019 Dan Carmen   Add additional fields to query

*/
global with sharing class ProductCalculatorBatch implements Database.Batchable<SObject>, Database.Stateful{

   /* the start time of the process. */
   global DateTime startTime = DateTime.now();
   
   global Id[] opptyIds = null;
   
   global User curUser = null;

   global Integer nbrOpptys = 0;
   
   global String outputMsg = '';
   
   global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select Id
                                          ,AccountId
                                          ,Account.Id
                                          ,Account.Name
                                          ,Account.AccountNumber
                                          ,Account.NumberOfEmployees
                                          ,Active_Employees__c
                                          ,CampaignId
                                          ,Child_Unit__c
                                          ,Client_Referral__c
                                          ,CloseDate
                                          ,Core_Branch_Client_Number__c
                                          ,Core_Conversion_Reason__c
                                          ,Employees_Paid_Per_Payroll__c
                                          ,Frequency__c
                                          ,LeadSource
                                          ,Local_Competitors__c
                                          ,Mthd_Lead_Rcvd__c
                                          ,Multi_Frequency__c
                                          ,Multi_ID_Client__c
                                          ,NSR_Email__c
                                          ,NSS_Prospect_ID__c
                                          ,NSS_Rep__c
                                          ,Name
                                          ,Office_Price_Schedule_Map__c
                                          ,OpportunityId__c
                                          ,Other_Competition__c
                                          ,OwnerId
                                          ,Payroll_Platform__c
                                          ,Payroll_Unit__c
                                          ,Payroll_Units__c
                                          ,Pricebook2.Sales_Org__c
                                          ,Pricebook2.Sales_Org2__c
                                          ,Pricebook2Id
                                          //,Primary_Competition__c
                                          ,Primary_Competitor__c
                                          ,RecordTypeId
                                          ,RecordType.Name
                                          ,Referral__c
                                          ,Setup_Fee_Actual__c
                                          ,Setup_Fee__c
                                          ,StageName
                                          ,Total_Revenue__c
                                          ,(Select Id
                                                  ,Actual_Revenue__c
                                                  ,Adj_Type__c
                                                  ,Annual_Base_Trans_Disc__c
                                                  ,Annual_Base_and_Trans__c
                                                  ,Annual_Discount_Dollars__c
                                                  ,Base_Fee__c
                                                  ,Description
                                                  ,Discount_Annualized__c
                                                  ,Discount_Free_Months__c
                                                  ,Discount_Months__c
                                                  ,Discount_Percent__c
                                                  ,Discounted_Annual_Price__c
                                                  ,Estimated_Revenue__c
                                                  ,Estimated_Setup_Fee__c
                                                  ,Frequency__c
                                                  ,Has_External_Id__c
                                                  ,Is_Default__c
                                                  ,Non_Discount_Price_Per_Frequency__c
                                                  ,Non_Discounted_Price__c
                                                  ,Non_Discounted_Revenue__c
                                                  ,Non_Payroll_Unit__c
                                                  ,OpportunityId
                                                  ,Oppty_Product_Id__c
                                                  ,Payroll_Unit__c
                                                  ,Price_Per_Frequency__c
                                                  ,Price_Schedule__c
                                                  ,PricebookEntryId
                                                  ,PricebookEntry.Product2.Default_Units_to_Employees__c
                                                  ,PricebookEntry.Product2.Is_Default_Product__c
                                                  ,PricebookEntry.Product2.Name
                                                  ,Product_Parent_Child_Link__c
                                                  ,Quantity
                                                  ,QuoteLineGroupAcct__c
                                                  ,Reporting_Status__c
                                                  ,Rev_Adj_Calcd__c
                                                  ,Rev_Adj__c
                                                  ,Rollup_Product__c
                                                  ,ServiceDate
                                                  ,Service_Category__c
                                                  ,Setup_Fee_Original__c
                                                  ,Setup_Fee__c
                                                  ,SortOrder
                                                  ,Status__c
                                                  ,TotalPrice
                                                  ,Total_Calced__c
                                                  ,Transaction_Fee__c
                                                  ,Unit__c
                                                  ,User_Override__c
                                              From OpportunityLineItems)
                                      From Opportunity
                                     Where Id in :opptyIds]);
   } // start

   global void execute(Database.BatchableContext BC, List<SObject> scope){
   	if (curUser == null) {
   	   curUser = [Select Id, Cost_Center__c, Sales_Org__c from User where Id = :UserInfo.getUserId()];
   	}
      List<Opportunity> opptys = (List<Opportunity>)scope;

      // line items to update
      List<OpportunityLineItem> updateOlis = new List<OpportunityLineItem>();
      
      for (Opportunity oppty : opptys) {
      	outputMsg += 'Calculating Opportunity '+oppty.Name+' for Prospect-Client '+oppty.Account.Name+': ';
         ProductCalculator.calcOpptyProducts(curUser, oppty, oppty.OpportunityLineItems);
         outputMsg += 'Success!\n';
         // make sure all line items have a non-null TotalPrice
         for (OpportunityLineItem oli : oppty.OpportunityLineItems) {
            if (oli.TotalPrice == null) {
               oli.TotalPrice = 0;
            }
         }
         updateOlis.addAll(oppty.OpportunityLineItems);
      } // for
      // save opportunities and line items
      
      update opptys;
      update updateOlis;
      
      nbrOpptys += opptys.size();
   } // execute
      
   global void finish(Database.BatchableContext BC){
      // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
                               TotalJobItems, CreatedById
                          from AsyncApexJob where Id = :BC.getJobId()];
      // Send an email to the Apex job's submitter notifying of job completion.
      DateTime endTime = DateTime.now();
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

      mail.setTargetObjectId(a.CreatedById);
      mail.setSaveAsActivity(false);
      
      mail.setSubject('Calc Opportunity Products completed with status: ' + a.Status);
      String message = '\n\n'+outputMsg; 
      message += '\nTotal Opportunities recalced: '+nbrOpptys+' '; 
      message += ' \n\n     Start Time='+startTime.format();
      message +=    '\n     End Time='+endTime.format();
      //message += '\n\n'+emailStatus;
       
      mail.setPlainTextBody ('The Calc Opportunity Products process finished processing ' + a.TotalJobItems +
       ' batches with '+ a.NumberOfErrors + ' failures.'+message);
      // only send the message if on production.
      //if (Utilities.checkForProduction().length() == 0) {
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      //}
   } // finish
   
} // class ProductCalculatorBatch