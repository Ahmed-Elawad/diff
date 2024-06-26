/* 
  Methods to handle the QuoteLineItems from the trigger.
   
  History
  -------
  06/22/2016 Carrie Marciano   Created
  01/30/2017 Carrie Marciano   Added loop through QuoteLineGroups to total up Frequency values for Multi-Id quote template display
  03/13/2017 Carrie Marciano   Removed queries from within for loop
  03/01/2018 Carrie Marciano   Changed delimiter for Necessary Approvers to be pipe to help parsing in approval process
  
 */ 

public without sharing class QuoteLineAfter {
    public QuoteLineAfter(){}
 /*   
   public static Boolean TRIGGER_EXECUTED=false;

   public static void processLineItems(Set<Id> quoteIdsToUpdate) {
      System.debug('***CLM*** quoteIdsToUpdate: ' + quoteIdsToUpdate.size());
      //System.debug('***CLM*** quoteIdsToUpdate: ' + quoteIdsToUpdate);
      processNecessaryApprovals(quoteIdsToUpdate);
      processMultiId(quoteIdsToUpdate);
       
   } // processLineItems 
    
   public static void processNecessaryApprovals(Set<Id> quoteIdsToUpdate) {
       System.debug('processNecessaryApprovals quoteIdsToUpdate='+quoteIdsToUpdate.size());
       Map<Id,SBQQ__Quote__c> updateNAQuote = new Map<Id,SBQQ__Quote__c>();
       decimal currentApprovalLevel;
       
       if (!quoteIdsToUpdate.isEmpty()) {
         // get the quotes
         List<SBQQ__Quote__c> quotes = [Select Id, SBQQ__Status__c, Necessary_Approvers__c
                                        ,(select Id
                                         ,SBQQ__Quote__r.Id 
                                         ,ApprovalLevel__c            
                                         from SBQQ__LineItems__r 
                                         ORDER BY ApprovalLevel__c DESC)
                                       from SBQQ__Quote__c 
                                      where Id in :quoteIdsToUpdate];
          System.debug('processNecessaryApprovals quotes=' + quotes.size());
           
          for (SBQQ__Quote__c quote : quotes) {
            quote.Necessary_Approvers__c = '*';
             System.debug('processNecessaryApprovals quote.SBQQ__LineItems__r: ' + quote.SBQQ__LineItems__r.size()); 
             currentApprovalLevel=null;              
             for (SBQQ__QuoteLine__c qli : quote.SBQQ__LineItems__r){ 
                System.debug('***CLM*** qli.ApprovalLevel__c: ' + qli.ApprovalLevel__c);                
                if (qli.ApprovalLevel__c != null) {                    
                   //System.debug('***CLM*** currentApprovalLevel: ' + currentApprovalLevel + ' qli.ApprovalLevel__c: '+ qli.ApprovalLevel__c) ;
                   if (currentApprovalLevel <> qli.ApprovalLevel__c){
                       //System.debug('***CLM*** inside IF currentApprovalLevel: ' + currentApprovalLevel + ' qli.ApprovalLevel__c: '+ qli.ApprovalLevel__c) ;
                       currentApprovalLevel=qli.ApprovalLevel__c; 
                        if(quote.Necessary_Approvers__c == '*'){
                            quote.Necessary_Approvers__c= '*' + String.valueof(qli.ApprovalLevel__c);
                        }
                        else
                        {
                            quote.Necessary_Approvers__c = quote.Necessary_Approvers__c + '*' + String.valueof(qli.ApprovalLevel__c);
                            //System.debug('***CLM*** quote.Necessary_Approvers__c: ' + quote.Necessary_Approvers__c);
                        }    
                   }    
                } 
             } // for 
             quote.Necessary_Approvers__c = quote.Necessary_Approvers__c + '*';
             updateNAQuote.put(quote.Id, quote);
             System.debug('updateNAQuote=' + updateNAQuote.size());
             if (!updateNAQuote.isEmpty()) {
                // todo - capture errors that occur!
                DmlHelper.performDml2(updateNAQuote.values(), DmlHelper.DML_UPDATE, 'QuoteLineAfter', 'processNecessaryApprovals', 'updateNAQuote', true);
             }
           } // for
      } // if (!opptyIdsMultiIds.isEmpty() 
   } // processNecessaryApprovals
    
   public static void processMultiId(Set<Id> quoteIdsToUpdate) {
       System.debug('processMultiId quoteIdsToUpdate=' + quoteIdsToUpdate.size());
       if (quoteIdsToUpdate.isEmpty()) {
          return;
       }
       //Map<Id,quoteIdsToUpdate> summaryMap = new Map<Id,quoteIdsToUpdate>();
       //List<quoteIdsToUpdate> summaryGroups = new List<quoteIdsToUpdate>();
       SBQQ__QuoteLineGroup__c[] qlgToUpdate = new SBQQ__QuoteLineGroup__c[]{};
       string currentPricingType;
       
       SBQQ__QuoteLineGroup__c[] quoteLineGroups = [SELECT Id, Name, SBQQ__Number__c, SBQQ__Account__r.Name
                              , Per_Pay_Period_Fees__c, Monthly_Fees__c, One_Time_Fees__c 
                              , Annual_Fees__c, Annualized_Fees__c, SBQQ__NetTotal__c
                              , (select Id, Pricing_Type__c, SBQQ__Group__c, SBQQ__Group__r.SBQQ__Number__c
                                 , NetTotalPerPeriod__c, SBQQ__NetTotal__c from SBQQ__LineItems__r
                                 ORDER BY Pricing_Type__c DESC)
                             FROM SBQQ__QuoteLineGroup__c Where SBQQ__Quote__c in :quoteIdsToUpdate];
       System.debug('processMultiId quoteLineGroups=' + quoteLineGroups.size());
        
       //decimal currentqlgID=null;
       for(SBQQ__QuoteLineGroup__c qlg : quoteLineGroups){
           System.debug('***CLM*** qlg.SBQQ__LineItems__r: ' + qlg.SBQQ__LineItems__r.size());
           currentPricingType=null; 
           qlg.Per_Pay_Period_Fees__c = 0.00;
           qlg.Monthly_Fees__c = 0.00; 
           qlg.Annual_Fees__c = 0.00;
           qlg.One_Time_Fees__c = 0.00;          
           for(SBQQ__QuoteLine__c ql : qlg.SBQQ__LineItems__r){
               //System.debug('***CLM*** ql.SBQQ__Group__r.SBQQ__Number__c: ' + ql.SBQQ__Group__r.SBQQ__Number__c);  
               //if(currentqlgID <> ql.SBQQ__Group__r.SBQQ__Number__c){
               //    currentqlgID = ql.SBQQ__Group__r.SBQQ__Number__c;
               //}    
               //System.debug('***CLM*** ql.Pricing_Type__c: ' + ql.Pricing_Type__c);
               if(currentPricingType <> ql.Pricing_Type__c){
                   currentPricingType = ql.Pricing_Type__c;
                   //System.debug('***CLM*** first time for Pricing Type: ' + ql.SBQQ__NetTotal__c);
                   if(ql.Pricing_Type__c == 'Per Pay Period'){
                       //System.debug('***CLM*** Per Pay Period ql.NetTotalPerPeriod__c: ' + ql.NetTotalPerPeriod__c);
                       qlg.Per_Pay_Period_Fees__c = (ql.NetTotalPerPeriod__c!=null?ql.NetTotalPerPeriod__c:0.00);
                       //System.debug('***CLM*** qlg.Per_Pay_Period_Fees__c after adding ql.NetTotalPerPeriod__c: ' + qlg.Per_Pay_Period_Fees__c);
                   } else if(ql.Pricing_Type__c == 'Monthly'){
                       qlg.Monthly_Fees__c = (ql.NetTotalPerPeriod__c!=null?ql.NetTotalPerPeriod__c:0.00); 
                   } else if (ql.Pricing_Type__c == 'Annual'){
                       qlg.Annual_Fees__c = (ql.SBQQ__NetTotal__c!=null?ql.SBQQ__NetTotal__c:0.00);
                   } else if (ql.Pricing_Type__c == 'One-time'){
                       qlg.One_Time_Fees__c = (ql.SBQQ__NetTotal__c!=null?ql.SBQQ__NetTotal__c:0.00);
                   }
               }else{
                   //System.debug('***CLM*** Subsequent Times for Pricing Type: ' + ql.SBQQ__NetTotal__c);
                   if(ql.Pricing_Type__c == 'Per Pay Period'){
                       //System.debug('***CLM*** Per Pay Period ql.NetTotalPerPeriod__c: ' + ql.NetTotalPerPeriod__c + ' qlg.Per_Pay_Period_Fees__c: ' + qlg.Per_Pay_Period_Fees__c);
                       qlg.Per_Pay_Period_Fees__c = qlg.Per_Pay_Period_Fees__c + (ql.NetTotalPerPeriod__c!=null?ql.NetTotalPerPeriod__c:0.00);
                       //System.debug('***CLM*** qlg.Per_Pay_Period_Fees__c after adding ql.NetTotalPerPeriod__c: ' + qlg.Per_Pay_Period_Fees__c);
                   } else if(ql.Pricing_Type__c == 'Monthly'){
                       qlg.Monthly_Fees__c = qlg.Monthly_Fees__c + (ql.NetTotalPerPeriod__c!=null?ql.NetTotalPerPeriod__c:0.00);
                   } else if (ql.Pricing_Type__c == 'Annual'){
                       qlg.Annual_Fees__c = qlg.Annual_Fees__c + (ql.SBQQ__NetTotal__c!=null?ql.SBQQ__NetTotal__c:0.00);
                   } else if (ql.Pricing_Type__c == 'One-time'){
                       //System.debug('***CLM*** before add ql.SBQQ__NetTotal__c to qlg.One_Time_Fees__c: ' + qlg.One_Time_Fees__c + ' ql.SBQQ__NetTotal__c; ' + ql.SBQQ__NetTotal__c);
                       qlg.One_Time_Fees__c = qlg.One_Time_Fees__c + (ql.SBQQ__NetTotal__c!=null?ql.SBQQ__NetTotal__c:0.00);
                       //System.debug('***CLM*** qlg.One_Time_Fees__c: ' + qlg.One_Time_Fees__c);
                   }
               } 
           } // for(SBQQ__QuoteLine__c ql : qlg.SBQQ__LineItems__r
           qlg.Annualized_Fees__c = (qlg.SBQQ__NetTotal__c!=null?qlg.SBQQ__NetTotal__c:0.00) - qlg.One_Time_Fees__c;
           System.debug('***CLM*** qlg.Annualized_Fees__c=' + qlg.Annualized_Fees__c + ' qlg.SBQQ__NetTotal__c=' + qlg.SBQQ__NetTotal__c + ' qlg.One_Time_Fees__c=' + qlg.One_Time_Fees__c);
           qlgToUpdate.add(qlg);
           //System.debug('***CLM*** after update qlg' + qlg.Name + ' PPP: ' + qlg.Per_Pay_Period_Fees__c + ' monthly: ' + qlg.Monthly_Fees__c + ' annual: ' + qlg.Annual_Fees__c + ' onetime: ' + qlg.One_Time_Fees__c + ' Annualized: ' + qlg.Annualized_Fees__c);
       } // for(SBQQ__QuoteLineGroup__c qlg : quoteLineGroups
       System.debug('processMultiId qlgToUpdate='+qlgToUpdate.size());
       DmlHelper.performDml2(qlgToUpdate, DmlHelper.DML_UPDATE, 'QuoteLineAfter', 'processMultiId', 'update qlgToUpdate', true);
   }  //processMultiId  
   */ 
} // class QuoteLineAfter