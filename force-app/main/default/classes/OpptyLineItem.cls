/* 
   Methods to handle the OpportunityLineItems from the trigger.
   
  History
  -------
  12/22/2011 Dan Carmen   Created
  12/29/2011 Dan Carmen   Added update to Opportunity revenue, setup fee, and payroll units field if line item changes.
  02/02/2012 Dan Carmen   If a lineitem is inserted, if there's a non-default and default product on 
                          the same opportunity, remove the default product.
  08/29/2013 Cindy Freeman  Added processAppendOlis. If line item was added to MMS opportunity rebuild product_summary__c field on oppty  
  08/17/2015 Carrie Marciano Added calculations for multi-id opportunities to fields with number of Ids, and list of Ids to be passed to Onboarding Case    
  12/02/2015 Lynn Michels    Add to processAppendOlis for Core Opportunity Record Type - used for MPSC Documents
  01/12/2016 Dan Carmen   Change to without sharing.
  04/06/2016 Carrie Marciano changed the ORDER BY in processMultiID to use QuoteLineGroup__c
  03/13/2017 Carrie Marciano removed queries from within for loop
  07/24/2017 Dan Carmen      Remove update from within loop
  08/08/2017 Dan Carmen     Added INSERT_TRIGGER_PROCESSED, UPDATE_TRIGGER_PROCESSED variables to handle insert/update separately.  Replaces AFTER_TRIGGER_PROCESSED
  02/13/2018 Lynn Michels   Added ASO and HNBF opportunity RT to populate Product Summary field on opptys
  05/04/2018 Cindy Freeman  roll up Non-Payroll Units to opportunity
  04/18/2019 Dan Carmen     Call OpptyRevenueSplit on revenue change on the lineitem
  07/30/2019 Dan Carmen     Update the WIN__c (Discount Percent) field on the opp
  08/23/2019 Jacob Hinds    adding method for exclude revenue
  09/04/2019 Dan Carmen     Add additional recursion checks
  12/18/2019 Jacob Hinds    fix for setup fee calc
  03/16/2020 Matt Fritschi  Added checks for Oracle_Quote_Line__c in addition to SBQQ__QuoteLine__c
  04/29/2020 Carrie Marciano updated formula for Non_Discounted_Revenue__c and fixed processMultiId so that it doesn't clear out the value if oracle quote
  06/01/2020 Jake Hinds     Changing ALLOW DELETE to PREVENT DELETE per label name
  06/11/2020 Carrie Marciano updated processMultiId to not clear out Number of Ids for Oracle quotes and only clear out Primary Oracle Quote when updating with an Oracle Quoteline
  08/04/2020 Justin Stouffer split the query into one for opportunity and one for opportunity lines to eliminate error we were getting for CPQ when aggregate query was returning too many rows
  11/21/2020 Carrie Marciano commenting out setting of INSERT_TRIGGER_PROCESSED, this was preventing oracle quotelines of more than 200 to update opptylines with data
  03/16/2021 Carrie Marciano    Removing call to OpptyProducts.getProdStatus-will now set the prodStatus to the Oppty.StageName, removing MultiId functionality that was for Steelbrick - Oracle passes this thru field mappings
  05/14/2021 Carrie Marciano added code to update Primary Oracle Quote on the oppty in processSumOlis so that its updated timely for MSA generation to be accurate
  06/15/2021 Carrie Marciano added code to update Oppty Recordtype, Type, Service Location, and Payroll Platform based on products added to oppty for ASO/PEO
  08/12/2021 Carrie Marciano added code to exclude DSA/FSS record types from the Oppty updates based on products 
  08/23/2021 Carrie Marciano added code to exclude referral record types from the Oppty updates based on products 
  03/17/2022 Shilpa Govindarajulu   Commented SBQQ component references
  06/07/2022 Dan Carmen      Only set oli.Payroll_Unit__c is it's currently null for Oracle.
  01/06/2023 Shilpa Govindarajulu APR0143201: Updated method processSumOlis to allow FSS Opportunity Record types to keep opp type listed as chargeback or true up
  05/15/2023 Jaipal  APR0151060 Added check(Potential_min_cal) to get the Total Price from the Customer Annual Total Price 
  08/22/2023 Carrie Marciano added code to evaluate Exclude_From_Revenue__c on quotelines that are in Compare Quote, removed recursion checks which were preventing CPQ subsequent batches from being processed
  09/15/2023 Carrie Marciano moved update to oli.Status__c outside of IF in checkOliValueBefore, was not updating products that had Exclude Revenue criteria
  09/20/2023 Carrie Marciano changes for Potential_min_calc__c causing issues with UnitPrice and TotalPrice, moving Quanity to Unit field on opptyLine and setting Quantity = 1 on Potential_min_calc__c products 
  12/13/2023 Dan Carmen      Changes for performance
  01/18/2024 Dan Carmen      Change in checkOliValueBefore to only match the quote line item by cpq id

 */ 

public without sharing class OpptyLineItem {

   // used for testing
   public static void resetFlags() {
      AFTER_TRIGGER_PROCESSED=false;
      INSERT_TRIGGER_PROCESSED=false;
      UPDATE_TRIGGER_PROCESSED=false;
      BEFORE_PROCESSED=false;
      AFTER_PROCESSED=false;
   }
   public static Boolean SKIP_TRIGGER=false;

   public static Set<Id> oppIdsProcessed = new Set<Id>();
   public static Boolean AFTER_TRIGGER_PROCESSED=false;
   public static Boolean INSERT_TRIGGER_PROCESSED=false;
   public static Boolean UPDATE_TRIGGER_PROCESSED=false;
   public static Boolean BEFORE_PROCESSED=false;
   public static Boolean AFTER_PROCESSED=false;
   
   public static Boolean ALLOW_FUTURE=Label.OpptyLineItem_UseFuture=='Y';
   public static Boolean DISABLE_DELETE=Label.OpptyLineItem_DisableDelete=='Y';
   
   public static Boolean SKIP_REVENUE_SPLIT=false; 
       
   public static void processLineItems(Set<Id> opptyIdsCheckDef, Set<Id> opptyIdsToSold, Set<Id> opptyIdsToSumProds, Set <Id> opptyIdsToAppendProds) {
      System.debug('processLineItems opptyIdsCheckDef='+opptyIdsCheckDef.size()+' opptyIdsToSold='+opptyIdsToSold.size()+' opptyIdsToSumProds='+opptyIdsToSumProds.size()+' opptyIdsToAppendProds='+opptyIdsToAppendProds);
      // the opportunities to update
      oppIdsProcessed.addAll(opptyIdsCheckDef);
      oppIdsProcessed.addAll(opptyIdsToSold);
      oppIdsProcessed.addAll(opptyIdsToSumProds);
      oppIdsProcessed.addAll(opptyIdsToAppendProds);
      
      /* we cannot do any kind of recursion due to the way CPQ sends lines over to us, recurrsion prevents subsequent batches of lines from being processed 
       if (Trigger.isInsert) {
          //INSERT_TRIGGER_PROCESSED = true;
       } else if (Trigger.isUpdate) {
          //UPDATE_TRIGGER_PROCESSED = true;
       }
       */

      //AFTER_TRIGGER_PROCESSED = true;
      //Map<Id,Opportunity> updateOpptys = new Map<Id,Opportunity>();
      System.debug('processLineItems opptyIdsToSumProds=' + opptyIdsToSumProds.size());
      if (!DISABLE_DELETE) {
         if (ALLOW_FUTURE && !System.isBatch() && !System.isFuture()) {
            processCheckDefaultFuture(opptyIdsCheckDef);
         } else {
            processCheckDefault(opptyIdsCheckDef);
         }
         
      } // if (ALLOW_DELETE
      
      processSumOlis(opptyIdsToSumProds);
      
      System.debug('processLineItems opptyIdsToSumProds='+opptyIdsToSumProds.size()+' SKIP_REVENUE_SPLIT='+SKIP_REVENUE_SPLIT);
      // if the value of the line items changes check at the Opportunity level
      if (!SKIP_REVENUE_SPLIT && !opptyIdsToSumProds.isEmpty()) {
         OpptyRevenueSplit ors = new OpptyRevenueSplit();
         OpptyRevenueSplit.v_oppIdSet.addAll(opptyIdsToSumProds);
         ors.processAfterTriggerActions();
      }
   } // processLineItems

   @future
   public static void processCheckDefaultFuture(Set<Id> opptyIdsCheckDef) {
      processCheckDefault(opptyIdsCheckDef);
   }

   // Check if the default product exists among the other products
   public static void processCheckDefault(Set<Id> opptyIdsCheckDef) {
       system.debug('processCheckDefault at begin opptyIdsCheckDef: '+opptyIdsCheckDef.size());
       if (!opptyIdsCheckDef.isEmpty()) {
         // the records to delete
         OpportunityLineItem[] deleteRecs = new OpportunityLineItem[]{};
         // select the opportunities
         Opportunity[] opptys = [Select Id, Name
                                       ,(Select Id
                                               ,PricebookEntry.Product2.Is_Default_Product__c
                                           From OpportunityLineItems)
                                   From Opportunity
                                  Where Id in :opptyIdsCheckDef];
         System.debug('processCheckDefault opptys='+opptys.size());
         for (Opportunity oppty : opptys) {
            checkLineItems(oppty,deleteRecs);
         } // for
         
         if (!deleteRecs.isEmpty()) {
            DmlHelper.performDml2(deleteRecs, DmlHelper.DML_DELETE, 'OpptyLineItem', 'processCheckDefault', 'Delete Default Line Items', true);
         }
      } // if (!opptyIdsCheckDef.isEmpty
   } // processCheckDefault
   
   public static Boolean checkLineItems(Opportunity oppty, OpportunityLineItem[] deleteRecs) {
      system.debug('checkLineItems at begin');
      OpportunityLineItem defProd = null;
      Boolean hasNonDefault = false;
      for (OpportunityLineItem oli : oppty.OpportunityLineItems) {
         system.debug('checkLineItems for oli: '+oli.PricebookEntry.Product2); 
         if (oli.PricebookEntry.Product2.Is_Default_Product__c) {
            defProd = oli;
         } else {
            hasNonDefault = true;
         }
         if (hasNonDefault && defProd != null) {
            // can stop here if both conditions are met
            deleteRecs.add(defProd);
            break;
         }
      } // for
      return true;
   } // checkLineItems
   
   public static Set<String> appendRecordTypeNameSet = new Set<String>{'MMS Opportunity (DSA) Record Type','MMS Opportunity Record Type'
                       ,'Core Opportunity Record Type','Core Opportunity DSA Record Type'
                       ,'HNBF Opportunity Record Type','ASO Opportunity Record Type'};

   public class OppResults {
      public Double totalRev=0;
      public Double totalSetup = 0;
      public Double payrollUnits = 0;
      public Double nonPayrollUnits = 0;
      public Decimal maxDisc = 0;
      public String prodMapProdCode = null;
      public Set<String> prodFamilySet = new Set<String>();
   } // class OppResults
    
   public static Opportunity[] opptys = null;
   public static Id[] queryOppIds = new Id[]{};
                           
   public static void processSumOlis(Set<Id> opptyIdsToSumProds) {
      System.debug('processSumOlis opptyIdsToSumProds='+opptyIdsToSumProds.size());
      if (opptyIdsToSumProds.isEmpty()) {
          return;
      }

      //ProductOpptyMapping custom setting details what oppty fields need to be set based on product code of opptylineitems
      ProductOpptyMapping__c[] pomCSList = ProductOpptyMapping__c.getall().values();
      Set<String> pomCSPB = new Set<String>();  
      System.debug('processSumOlis pomCSList=' + pomCSList.size());
      Map<String,ProductOpptyMapping__c> pomCSMap = new Map<String,ProductOpptyMapping__c>();
      for (ProductOpptyMapping__c pom : pomCSList) {
         pomCSMap.put(pom.ProductCode__c, pom);
         System.debug('processSumOlis pom.OpptyPricebookName__c=' + pom.OpptyPricebookName__c);
         pomCSPB.add(pom.OpptyPricebookName__c); 
      }
      System.debug('processSumOlis pomCSMap='+pomCSMap.size()+' pomCSPB='+pomCSPB.size());
      Map<Id,OpportunityLineItem> updateOlis = new Map<Id,OpportunityLineItem>();
      Opportunity[] updateOpps = new Opportunity[]{};
      for (Id oppId : opptyIdsToSumProds) {
         if (!queryOppIds.contains(oppId)) {
            opptys = null;
            queryOppIds.clear();
            break;
         }
      }
      
      if (opptys == null) {
         // get the opportunities
         opptys = [Select Id, StageName, Product_Summary__c, Amount
                                           ,Revenue__c, Setup_Fee__c, Payroll_Units__c, Non_Payroll_Units__c, Primary_Oracle_Quote__c   
                                           ,RecordType.Name
                                           ,Pricebook2Id, Pricebook2.Name
                                           ,WIN__c
                                           ,OpportunityType__c
                                           ,Payroll_Platform__c
                                           ,Service_Location__c
                                           ,(Select Id, Oracle_Quote_Line__r.cafsl__Oracle_Quote__c
                                               From OpportunityLineItems
                                              Where Oracle_Quote_Line__r.cafsl__Oracle_Quote__c != null limit 1 )
                                       from Opportunity 
                                      where id in :opptyIdsToSumProds];
         queryOppIds.addAll(opptyIdsToSumProds);
      } // if (opptys == null
       Boolean checkPomLineItems = false;
       for (Opportunity opp : opptys) {
           system.debug('processSumOlis opp.Amount: '+opp.Amount);
           if (opp.Pricebook2Id != null && pomCSPB.contains(opp.Pricebook2.Name)) {
              checkPomLineItems = true;
              break;
           }
       } // for (Opportunity opp : opptys
       
        // get the total amount of the line items
        AggregateResult[] revResults =  [Select sum(TotalPrice) totalRev, sum(Setup_Fee__c) totalSetup, sum(Payroll_Unit__c) payrollUnits
                                            ,sum(Non_Payroll_Unit__c) nonPayrollUnits, max(Discount_Percent__c) maxDisc, OpportunityId, Product2.Family prodFamily
                                        From OpportunityLineItem
                                       Where Product2.Is_Default_Product__c = false
                                         And OpportunityId in :opptyIdsToSumProds
                                       group by OpportunityId, Product2.Family];
       Map<Id,OppResults> oppResultMap = new Map<Id,OppResults>();
       for (AggregateResult result : revResults) {
           System.debug('processSumOlis result='+result);
           Id oppId = (Id)result.get('OpportunityId');
           String prodFamily = (String)result.get('prodFamily');
           OppResults oppRes = (oppResultMap.containsKey(oppId) ? oppResultMap.get(oppId) : new OppResults());
           if (String.isNotBlank(prodFamily)) {
              oppRes.prodFamilySet.add(prodFamily);
           }
           oppRes.totalRev += (result.get('totalRev') != null ? (Double)result.get('totalRev') : 0);
           oppRes.totalSetup += (result.get('totalSetup') != null ? (Double)result.get('totalSetup') : 0);
           oppRes.payrollUnits += (result.get('payrollUnits') != null ? (Double)result.get('payrollUnits') : 0);
           oppRes.nonPayrollUnits += (result.get('nonPayrollUnits') != null ? (Double)result.get('nonPayrollUnits') : 0);
           Decimal disc = (Decimal)result.get('maxDisc');
           if (disc != null && disc > oppRes.maxDisc) {
              oppRes.maxDisc = disc;
           }
           oppResultMap.put(oppId, oppRes);
           
       } // for (AggregateResult result
      
        // retrieve any line items that match up to the mapping
        OpportunityLineItem[] pomOlis = (!checkPomLineItems ? new OpportunityLineItem[]{}
                                        : [Select Id, OpportunityId, Product2.ProductCode
                                           From OpportunityLineItem
                                          Where OpportunityId in :opptyIdsToSumProds
                                            and Product2.ProductCode in :pomCSMap.keySet()]);
        System.debug('processSumOlis pomOlis='+pomOlis.size()+' pomCSMap.keySet()='+pomCSMap.keySet());
        for (OpportunityLineItem oli : pomOlis) {
           OppResults oppRes = (oppResultMap.containsKey(oli.OpportunityId) ? oppResultMap.get(oli.OpportunityId) : new OppResults());
           oppRes.prodMapProdCode = oli.Product2.ProductCode;
           oppResultMap.put(oli.OpportunityId, oppRes);
        } // for (OpportunityLineItem oli
        
         System.debug('processSumOlis opptys=' + opptys.size());                                                          
         // add the opportunities to the array
         for (Opportunity oppty : opptys) {
            Boolean oppUpdated = false;             
            Boolean dsaRT = oppty.RecordType.Name.contains('DSA') || oppty.RecordType.Name.contains('FSS'); 
            Boolean referralRT = oppty.RecordType.Name.contains('Referral'); 

            OppResults oppRes = oppResultMap.get(oppty.Id);
            Opportunity updateOpp = new Opportunity(Id=oppty.Id);
            if (oppRes != null) {
               Double revNet = (oppRes.totalRev - oppRes.totalSetup);
               if (oppty.Setup_Fee__c != oppRes.totalSetup
                     || oppty.Payroll_Units__c != oppRes.payrollUnits
                     || oppty.Non_Payroll_Units__c != oppRes.nonPayrollUnits
                     || oppty.Revenue__c != revNet) {
                  updateOpp.Setup_Fee__c = oppRes.totalSetup;
                  updateOpp.Payroll_Units__c = oppRes.payrollUnits;
                  updateOpp.Non_Payroll_Units__c = oppRes.nonPayrollUnits;
                  updateOpp.Revenue__c = revNet;
                  updateOpp.Amount = oppRes.totalRev;
                  oppUpdated = true;
               } // if (oppty.Setup_Fee__c
               System.debug('processSumOlis updateOpp.Revenue__c: ' +updateOpp.Revenue__c+' updateOpp.Amount: '+updateOpp.Amount); 
               if (appendRecordTypeNameSet.contains(oppty.RecordType.Name)) {
                  //oppty.Product_Summary__c = '';
                  String[] prodFamilies = new String[]{};
                  prodFamilies.addAll(oppRes.prodFamilySet);
                  prodFamilies.sort();
                  String prodSummary = (prodFamilies.isEmpty() ? '' : String.join(prodFamilies,'; '));
                  if (oppty.Product_Summary__c != prodSummary) {
                     updateOpp.Product_Summary__c = prodSummary;
                     oppUpdated = true;
                  }
               } // if (appendRecordTypeNameSet
                
               if (String.isNotBlank(oppRes.prodMapProdCode)) {
                  ProductOpptyMapping__c pomProd = pomCSMap.get(oppRes.prodMapProdCode);
                  System.debug('processSumOlis ProductCode='+oppRes.prodMapProdCode+' pomProd=' +pomProd);
                  if (pomProd !=null) {
                     id rtId = (dsaRT || referralRT ? oppty.RecordTypeId : RecordTypeHelper.getRecordType(pomProd.OpptyRecordType__c,'Opportunity').getRecordTypeId());
                     String oppType = (oppty.OpportunityType__c==ProductHelper.TRUEUP ||oppty.OpportunityType__c==ProductHelper.CHARGEBACK ? oppty.OpportunityType__c : pomProd.OpptyType__c);
                     if (oppty.RecordTypeId != rtId || oppty.OpportunityType__c != oppType || oppty.Payroll_Platform__c != pomProd.OpptyPayrollPlatform__c
                              || oppty.Service_Location__c != pomProd.OpptyServiceLocation__c) {
                        updateOpp.RecordTypeId = rtId;
                        updateOpp.OpportunityType__c = oppType;
                        updateOpp.Payroll_Platform__c = pomProd.OpptyPayrollPlatform__c;
                        updateOpp.Service_Location__c = pomProd.OpptyServiceLocation__c;  
                        oppUpdated = true; 
                     }
                     System.debug('processSumOlis oppUpdated='+oppUpdated+' RecordTypeId='+oppty.RecordTypeId+' OpportunityType__c='+oppty.OpportunityType__c+' Payroll_Platform__c='+oppty.Payroll_Platform__c+' Service_Location__c='+oppty.Service_Location__c);
                  }
               } // if (String.isNotBlank(oppRes.prodMapProdCode
                
               if (oppty.WIN__C != oppRes.maxDisc) {       
                  updateOpp.WIN__C = oppRes.maxDisc;      
                  oppUpdated = true; 
               }

            } // if (oppRes != null
             
            if (!oppty.OpportunityLineItems.isEmpty()) {
               Id quoteId = oppty.OpportunityLineItems[0].Oracle_Quote_Line__r.cafsl__Oracle_Quote__c;
               System.debug('processSumOlis current oppty.Primary_Oracle_Quote__c=' + oppty.Primary_Oracle_Quote__c + ' quoteId='+quoteId);  
               if (quoteId != null && oppty.Primary_Oracle_Quote__c != quoteId) {
                  updateOpp.Primary_Oracle_Quote__c = quoteId;
                  oppUpdated = true;                           
               }
            } // if (!oppty.OpportunityLineItems
            
            if (oppUpdated) {
               updateOpps.add(updateOpp);
            }
         } // for (Opportunity oppty
          
      if (!updateOpps.isEmpty()) {
         OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
         DmlHelper.performDml2(updateOpps, DmlHelper.DML_UPDATE, 'OpptyLineItem', 'processLineItems', 'Updating Opportunities', true);
         OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      }
      if (ErrorLog.processLog != null) {
         ErrorLog.endLog1(ErrorLog.processLog);
         //System.debug('ErrorLog.processLog='+ErrorLog.processLog);
         ErrorLog.saveLog(ErrorLog.processLog);
      }

   } // processSumOlis
   
   public static void checkAllOlisBefore(OpportunityLineItem[] olis, Map<Id,OpportunityLineItem> oldMap) {
      ErrorLog__c procLog = ErrorLog.processLog;
      if (procLog == null) {
         procLog = ErrorLog.getProcessLog('OpptyLineItem');
         ErrorLog.startLog1(procLog,'ProcessLineItems');
         if (olis != null && !olis.isEmpty()) {
            procLog.ObjectId__c = olis[0].OpportunityId;
         }
      }
      System.debug('checkAllOlisBefore olis='+olis.size());
      OpportunityLineItem[] checkValueOlis = new OpportunityLineItem[]{};
      Set<string> cpqExternalIdSet = new Set<string>(); 
      Set<Id> prodIdSet = new Set<Id>();
      Set<Id> oracleQuoteLineIdSet = new Set<Id>(); 
      Set<Id> oppIdSet = new Set<Id>();
      
      for (OpportunityLineItem oli : olis) {
          //System.debug('checkAllOlisBefore oli.cafsl__External_Id__c= '+oli.cafsl__External_Id__c+' oli.CPQ_External_Id__c'+oli.CPQ_External_Id__c);           
          OpportunityLineItem oldOli = (oldMap != null ? oldMap.get(oli.Id) : null);
          System.debug('checkAllOlisBefore oldOli.TotalPrice: '+(oldOli != null ? oldOli.TotalPrice : null)+' oli.TotalPrice: '+oli.TotalPrice);   
          
          checkValueOlis.add(oli);
          if (oli.Oracle_Quote_Line__c != null) {
              oracleQuoteLineIdSet.add(oli.Oracle_Quote_Line__c);
          } else if (oli.CPQ_External_Id__c != null) {
              cpqExternalIdSet.add(oli.CPQ_External_Id__c);
          }
          if (oli.Product2Id != null) {
              prodIdSet.add(oli.Product2Id);
          }
          if (oli.OpportunityId != null) {
              oppIdSet.add(oli.OpportunityId);
          }    
          
      } // for (OpportunityLineItem oli : olis 
      String msg = 'checkValueOlis='+checkValueOlis.size()+' cpqExternalIdSet= '+cpqExternalIdSet.size()+' prodIdSet='+prodIdSet.size()+' oppIdSet='+oppIdSet.size()+' oracleQuoteLineIdSet='+oracleQuoteLineIdSet.size();
      System.debug('checkAllOlisBefore '+msg);            
      ErrorLog.addToDescription(procLog,'olis='+olis.size()+' '+msg);
      if (!checkValueOlis.isEmpty()) {
          checkOliValueBefore(checkValueOlis, cpqExternalIdSet, prodIdSet, oppIdSet, oracleQuoteLineIdSet);
      }
      ErrorLog.endLog1(procLog);
   } // checkAllOlisBefore 
    
   public static Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
    
   public static Map<Id,Opportunity> getOppMap(Set<Id> oppIdSet) {
      // see if we already have ids
      Id[] queryIds = new Id[]{};
      for (Id oppId : oppIdSet) {
         if (!oppMap.containsKey(oppId)) {
            queryIds.add(oppId);
         }
      } // for (Id oppId : oppIdSet
      // query any opps we don't already have.
      if (!queryIds.isEmpty()) {
         Map<Id,Opportunity> queryMap = new Map<Id,Opportunity>([Select Id,Name,CloseDate,StageName,Primary_Oracle_Quote__c, Pricebook2Id
                                                                From Opportunity
                                                               Where Id in :queryIds]);
         oppMap.putAll(queryMap);
      }
      return oppMap;
   } // getOppMap
    
   public static void getProducts(Id pricebookId, Set<Id> pricebook2Ids, Map<Id,Product2> prodMap) {
      System.debug('getProducts pricebookId='+pricebookId);
      if (pricebookId != null && !pricebook2Ids.contains(pricebookId)) {
         pricebook2Ids.add(pricebookId);
         Map<Id,Product2> tempProdMap = ProductQuery.getProdMap(pricebookId);
         System.debug('getProducts tempProdMap='+tempProdMap.size());
         if (!tempProdMap.isEmpty()) {
            prodMap.putAll(tempProdMap);
         }
         System.debug('getProducts prodMap='+prodMap.size()+' tempProdMap='+tempProdMap.size());
      }

   } // getProducts
    
   public static void checkOliValueBefore(OpportunityLineItem[] olis, Set<string> cpqExternalIdSet, Set<Id> prodIdSet
                                          ,Set<Id> oppIdSet, Set<Id> oracleQuoteLineIdSet) {
      System.debug('checkOliValueBefore olis='+olis.size());
      List<Opportunity> updateOracleOpps = new List<Opportunity>();
      Map<string,cafsl__Oracle_Quote_Line_Item__c> oQuoteLineMap = new Map<string,cafsl__Oracle_Quote_Line_Item__c>();
      Boolean ExcludeQuoteLineRevenue = False;
      Set<Id> pricebook2Ids = new Set<Id>();
      // get all of the products from the cache so we don't need to requery. If there are a large number of products, will save on queries
      Map<Id,Product2> prodMap = new Map<Id,Product2>();
                                              
      if(!cpqExternalIdSet.isEmpty() || !oracleQuoteLineIdSet.isEmpty()) {    
          System.debug('checkOliValueBefore cpqExternalIdSet= '+cpqExternalIdSet.size()+' oracleQuoteLineIdSet='+oracleQuoteLineIdSet.size()); 
          // we don't want to compare against an empty set
          if (cpqExternalIdSet.isEmpty()) {
             cpqExternalIdSet.add('cpqExternalIdSet');
          }
          List<cafsl__Oracle_Quote_Line_Item__c> oqlines = [Select Id
                                                            ,cafsl__Oracle_Quote__c
                                                            ,cafsl__Oracle_Quote__r.Status__c
                                                            ,cafsl__Oracle_Quote__r.cafsl__Transaction_ID__c
                                                            ,cafsl__Oracle_Quote__r.cafsl__Syncing__c
                                                            ,cafsl__Oracle_Quote__r.cafsl__Opportunity__c
                                                            ,cafsl__Oracle_Quote__r.cafsl__Pricebook_Id__c
                                                            ,cafsl__External_Id__c
                                                            ,cafsl__CPQ_External_Id__c
                                                            ,Potential_min_calc__c
                                                            ,Customer_Total__c
                                                            ,Customer_Annual_Total__c
                                                            ,Annualized_Sale_Price_Unit__c
                                                            ,Discount_Percent__c
                                                            ,List_Price_Unit__c
                                                            ,cafsl__Product__c
                                                            ,cafsl__Product__r.Id
                                                            ,cafsl__Quantity__c
                                                            ,Exclude_From_Revenue__c
                                                            from cafsl__Oracle_Quote_Line_Item__c 
                                                            where cafsl__CPQ_External_Id__c in :cpqExternalIdSet
                                                               or Id in :oracleQuoteLineIdSet];
                          
          for (cafsl__Oracle_Quote_Line_Item__c oqline : oqlines) {
              oQuoteLineMap.put(oqline.cafsl__CPQ_External_Id__c,oqline); 
              oQuoteLineMap.put(oqline.Id, oqline);
              if (oqline.cafsl__Oracle_Quote__c != null && oqline.cafsl__Oracle_Quote__r.cafsl__Pricebook_Id__c != null) {
                 Id pricebookId = (Id)oqline.cafsl__Oracle_Quote__r.cafsl__Pricebook_Id__c;
                 getProducts(pricebookId, pricebook2Ids, prodMap);
              }
          } 
      } // if(!cpqExternalIdSet
       
      //System.debug('checkOliValueBefore oQuoteLineMap.size() '+oQuoteLineMap.size()); 
      /*
      Map<Id,Product2> prodMap = (prodIdSet.isEmpty() ? new Map<Id,Product2>()
                                   : new Map<Id,Product2>([Select Id,Name,Rollup_Product__c,Is_Payroll_Unit__c,Is_Non_Payroll_Unit__c
                                                                 ,Is_Setup_Fee__c,Exclude_Revenue_from_Opportunity__c
                                                             From Product2
                                                            Where Id in :prodIdSet])); 
      Map<Id,Opportunity> oppMap = (oppIdSet.isEmpty() ? new Map<Id,Opportunity>()
                                   : new Map<Id,Opportunity>([Select Id,Name,CloseDate,StageName,Primary_Oracle_Quote__c, Pricebook2Id
                                                                From Opportunity
                                                               Where Id in :oppIdSet]));
      */
      Map<Id,Opportunity> oppMap = getOppMap(oppIdSet);
      for (Opportunity opp : oppMap.values()) {
         System.debug('checkOliValueBefore opp.Pricebook2Id='+opp.Pricebook2Id);
         getProducts(opp.Pricebook2Id, pricebook2Ids, prodMap);
         /*
         if (opp.Pricebook2Id != null && !pricebook2Ids.contains(opp.Pricebook2Id)) {
            pricebook2Ids.add(opp.Pricebook2Id);
            Map<Id,Product2> tempProdMap = ProductQuery.getProdMap(opp.Pricebook2Id);
            if (prodMap.isEmpty()) {
               prodMap = tempProdMap;
            } else if (!tempProdMap.isEmpty()) {
               prodMap.putAll(tempProdMap);
            }
         }
         */
      } // for (Opportunity opp : oppMap
       
      System.debug('checkOliValueBefore prodMap='+prodMap.size()+' oppMap='+oppMap.size() +' oQuoteLineMap='+oQuoteLineMap.size());
      
      for (OpportunityLineItem oli : olis) {
          
         cafsl__Oracle_Quote_Line_Item__c oracleQuoteLine = null;
          
         Product2 prod = (oli.Product2Id != null ? prodMap.get(oli.Product2Id) : null);
         System.debug('checkOliValueBefore prod='+prod);
         
         //String quoteKey = (oli.Oracle_Quote_Line__c != null ? String.valueOf(oli.Oracle_Quote_Line__c) : oli.CPQ_External_Id__c);
         // There seemed to be a problem with the lookup, so only using the external id for now. 
         String quoteKey = oli.CPQ_External_Id__c;
         System.debug('checkOliValueBefore quoteKey: '+quoteKey); 
         if (String.isNotBlank(quoteKey) && oQuoteLineMap.containsKey(quoteKey)) {
             oracleQuoteLine = oQuoteLineMap.get(quoteKey);
             oli.Oracle_Quote_Line__c = (oracleQuoteLine != null ? oracleQuoteLine.Id : oli.Oracle_Quote_Line__c);
			 ExcludeQuoteLineRevenue = (oracleQuoteLine != null ? oracleQuoteLine.Exclude_From_Revenue__c : False);
             System.debug('checkOliValueBefore ExcludeQuoteLineRevenue: '+oli.Product2Id+'-'+ExcludeQuoteLineRevenue);
         }

         Opportunity opp = (oli.OpportunityId != null ? oppMap.get(oli.OpportunityId) : null);
         oli.ServiceDate = opp.CloseDate;
         oli.Status__c = opp.StageName; 
         if (oli.Unit__c == null) { 
         	oli.Unit__c = oli.Quantity; 
         }    
         //system.debug('checkOliValueBefore opp='+(opp != null ? opp.Name : 'NoOpp')+' Primary_Oracle_Quote__c'+(opp != null ? opp.Primary_Oracle_Quote__c : 'NoOpp')
         //                   +' !prod.Exclude_Revenue_from_Opportunity__c'+(prod != null ? !prod.Exclude_Revenue_from_Opportunity__c : false));
         if (prod != null && opp != null && opp.Primary_Oracle_Quote__c != null 
                        && !prod.Exclude_Revenue_from_Opportunity__c && !ExcludeQuoteLineRevenue && oracleQuoteLine != null) {
            
            if(oracleQuoteLine.Potential_min_calc__c){
               oli.Quantity = 1;
               oli.UnitPrice = oracleQuoteLine.Customer_Annual_Total__c; 
               oli.Non_Discounted_Price__c = oracleQuoteLine.Customer_Annual_Total__c; 
               System.debug('checkOliValueBefore Potential_min_calc__c and Quantity set to 1 and UnitPrice set to Customer Annual Total: '+oli.UnitPrice); 
            } 
            System.debug('checkOliValueBefore oli.UnitPrice: '+(oli.UnitPrice != null ? oli.UnitPrice : null)+' oli.Non_Discounted_Price__c: '+(oli.Non_Discounted_Price__c != null ? oli.Non_Discounted_Price__c : 0));
                            
            //*******************NEED TO FIND THE LIST PRICE*************************
            oli.Non_Discounted_Revenue__c = ((oli.Non_Discounted_Price__c == null || oli.Non_Discounted_Price__c == 0) ? 0 : oli.Non_Discounted_Price__c)*oli.Quantity;             
            System.debug('checkOliValueBefore Non_Discounted_Revenue__c='+oli.Non_Discounted_Revenue__c+' Discount_Amount__c='+oli.Discount_Amount__c);   
            
            oli.Estimated_Revenue__c = (oli.UnitPrice-((oli.Discount_Amount__c == 0 || oli.Discount_Amount__c == null) ? 0 : oli.Discount_Amount__c))*oli.Quantity;             
		    System.debug('checkOliValueBefore Estimated_Revenue__c='+oli.Estimated_Revenue__c+' Rollup_Product__c='+oli.Rollup_Product__c+' Payroll_Unit__c='+oli.Payroll_Unit__c+
                            ' Non_Payroll_Unit__c='+oli.Rollup_Product__c+' Setup_Fee__c='+oli.Setup_Fee__c);
                            
            oli.Rollup_Product__c = prod.Rollup_Product__c;
            oli.Payroll_Unit__c = (prod.Is_Payroll_Unit__c && oli.Payroll_Unit__c == null ? 1 : oli.Payroll_Unit__c);
            oli.Non_Payroll_Unit__c = (prod.Is_Non_Payroll_Unit__c && oli.Non_Payroll_Unit__c == null ? 1 : oli.Non_Payroll_Unit__c);
            oli.Setup_Fee__c = (prod.Is_Setup_Fee__c ? ((oli.UnitPrice-((oli.Discount_Amount__c == 0 || oli.Discount_Amount__c == null) ? 0 : oli.Discount_Amount__c))*oli.Quantity) : oli.Setup_Fee__c);
            //from Oppty
                                        
         } else if (prod != null && (prod.Exclude_Revenue_from_Opportunity__c || ExcludeQuoteLineRevenue)){
            System.debug('checkOliValueBefore in Exclude_Revenue_from_Opportunity__c OR ExcludeQuoteLineRevenue');
            oli.Transaction_Fee__c=0;
            oli.Non_Discount_Price_Per_Frequency__c=0;
            oli.Non_Discounted_Price__c=0;
            oli.Price_Per_Frequency__c=0;
            oli.Setup_Fee__c=0;
            oli.Payroll_Unit__c=0;
            oli.Discounted_Annual_Price__c=0;
            oli.Rev_Adj_Calcd__c=0;
            oli.Non_Discounted_Revenue__c=0;
            oli.Estimated_Revenue__c=0;
            // only 1 field - UnitPrice or TotalPrice - can be set at a time.
            if (oli.UnitPrice != null) {
               oli.UnitPrice=0;
            } else if (oli.TotalPrice != null) {
               oli.TotalPrice=0;
            }
            System.debug('checkOliValueBefore oli.UnitPrice: '+oli.UnitPrice+' oli.TotalPrice: '+oli.TotalPrice+' oli.Non_Discounted_Price__c: '+oli.Non_Discounted_Price__c);
            oli.Annual_Base_and_Trans__c=0;
            oli.Annual_Base_Trans_Disc__c=0;
         }
          
      } // for (OpportunityLineItem oli : olis
   } // checkOliValueBefore
   
} // class OpptyLineItem