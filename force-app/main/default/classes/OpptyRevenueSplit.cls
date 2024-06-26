/**
 * Methods for splitting revenue between opportunities
 
 PEO/ASO Opportunity - split revenue always - different rules if linked to another opp
 Split if part of an internal referral
 Split if part of integrated selling
 
  History
  -------
  07/28/2017 Dan Carmen        		Created
  11/15/2017 Dan Carmen        		Changes to handle the Zip Tier
  08/31/2022 Carrie Marciano   		added check on SalesOrg custom setting to determine oppty owner SalesOrg to look for correct OpptyRevSplit__mdt entry
  10/21/2022 Shilpa Govindarajulu	APR0127737 - Modified the criteria to fetch Opportunities for processing to include closed opportunities
  08/22/2023 Reetesh Pandey			APR0154079 - Exclude Productcode for flock and flockwithPay for 30 pct 
  11/10/2023 Reetesh Pandey			APR0148894 - Exclude Product from revenue split process-[Exclude Revenue Split]
  15/02/2024 Reetesh Pandey			INC3637037- APR0148894 - Exclude Product from revenue split process-[Exclude Revenue Split] set adjPct to 0
*/
public without sharing class OpptyRevenueSplit implements TriggerInterface {

   public static Boolean SKIP_TRIGGER=false;
   
   public static Boolean LOG_SPLIT=(Label.OpptyRevenueSplit_LogData == 'Y');
    
   public void checkBeforeTrigger(SObject newRec, SObject oldRec) {
   } // checkBeforeTrigger
   
   public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void processBeforeTriggerActions() {
   } // processBeforeTriggerActions
   
   public static Map<Id,Opportunity> v_oppMap = new Map<Id, Opportunity>();
   public static Set<Id> v_oppIdSet = new Set<Id>();
   
   public static Set<Id> oppIdsProcessed = new Set<Id>();
   
   public void checkAfterTrigger(SObject newRec, SObject oldRec) {
      if (SKIP_TRIGGER) {
         return;
      }
      Opportunity opp = (Opportunity)newRec;
      Opportunity oldOpp = (Opportunity)oldRec;
      // if the amount on the revenue changes, do further checking on it.
      // TODO - define record types we are triggering off of
      System.debug('OpptyRevenueSplit checkAfterTrigger opp='+opp.Name+' Amount='+opp.Amount+' old Amt='+(oldOpp != null ? oldOpp.Amount : -1)+' already processed='+oppIdsProcessed.contains(opp.Id));
      if (!oppIdsProcessed.contains(opp.Id) 
           && opp.Amount != null && opp.Amount != 0 
           //&& !opp.isClosed			//Commented as part of APR0127737
           && opp.Probability <= MAX_OPP_PERCENT
           && !opp.OverrideRevenueSplit__c
           && (oldOpp == null
                || (oldOpp != null && opp.Amount != oldOpp.Amount))) {
         oppIdsProcessed.add(opp.Id);
         v_oppIdSet.add(opp.Id);
      } // if (opp.Amount != null
   } // checkAfterTrigger

   // for testing purposes
   public static Boolean SKIP_FUTURE=false;
      
   public void processAfterTriggerActions() {
      System.debug('OpptyRevenueSplit processAfterTriggerActions v_oppIdSet='+v_oppIdSet);
      if (!v_oppIdSet.isEmpty()) {
         if (SKIP_FUTURE || System.isBatch() || System.isFuture()) {
            checkLinkedOppsNow(v_oppIdSet);
         } else {
            checkLinkedOppsFuture(v_oppIdSet);
         }
         v_oppIdSet.clear();
      } // if (!oppIdSet.isEmpty
      
   } // processAfterTriggerActions

   public static String[] REFERRAL_TYPES=new String[]{ReferralController.REF_INTERNAL, ReferralController.REF_INTSELL};

   //@future   
   public static void checkLinkedOppsFuture(Set<Id> oppIdSet) {
      checkLinkedOppsNow(oppIdSet);
   } // checkLinkedOppsFuture
   
   // The maximum opportunity probability percent 
   public static Decimal MAX_OPP_PERCENT = Decimal.valueOf(Label.OpptyRevenueSplitPct);
   
   public static void checkLinkedOppsNow(Set<Id> oppIdSet) {
      System.debug('checkLinkedOppsNow oppIdSet='+oppIdSet.size());
      Map<Id, Referral__c> refBySellingOppIdMap = new Map<Id, Referral__c>();
      
      // create a new set to capture the other opportunity ids so we can retain the original set of ids (triggering records)
      Set<Id> allOppIdSet = new Set<Id>();
      allOppIdSet.addAll(oppIdSet);
      
      // select all of the referrals first
      // check for referrals of a certain type where these are the selling opportunities
      Referral__c[] refs = [Select Id
                                  ,PartnerType__c
                                  ,ReferralJoin__c
                                  ,ReferralJoin__r.Id
                                  ,ReferralJoin__r.PAS_Referral__r.Selling_Opportunity__c
                                  ,ReferralJoin__r.MMS_Referral__r.Selling_Opportunity__c
                                  ,ReferralJoin__r.Core_Referral__r.Selling_Opportunity__c
                                  ,ReferringLineItemId__c  // for an internal referral, this is the id of the line item from the referring opp that equates to the selling opp
                                                           // we can use this for any relationship for easy reference
                                  ,Referring_Opportunity__c
                                  ,Selling_Opportunity__c
                              From Referral__c
                             Where Selling_Opportunity__c in :oppIdSet
                               and PartnerType__c in :REFERRAL_TYPES];
      System.debug('checkLinkedOppsNow refs='+refs.size());
                               
      // map of referrals by the opportunity line item id (if it exists)
      Map<Id, Referral__c> refByOliIdMap = new Map<Id, Referral__c>();
            
      for (Referral__c ref : refs) {
         // get the ids of all of the opportunities, then we'll select all of them at once.
         if (ref.ReferralJoin__r != null) {
            addToSet(allOppIdSet, ref.ReferralJoin__r.PAS_Referral__r);
            addToSet(allOppIdSet, ref.ReferralJoin__r.MMS_Referral__r);
            addToSet(allOppIdSet, ref.ReferralJoin__r.Core_Referral__r);
         }
         addToSet(allOppIdSet, ref.Referring_Opportunity__c);
         addToSet(allOppIdSet, ref.Selling_Opportunity__c);
         // for easy access
         refBySellingOppIdMap.put(ref.Selling_Opportunity__c, ref);
         
         //if (ref.ReferringLineItemId__c != null) {
         //   refByOliIdMap.put((Id)ref.ReferringLineItemId__c, ref);
         //}
      } // for (Referral ref
      System.debug('checkLinkedOppsNow allOppIdSet='+allOppIdSet);

      //Map<Id, OpportunityLineItem> oliMap = new Map<Id, OpportunityLineItem> (
      //                        [Select Id
      //                           From OpportunityLineItem
      //                          Where Id in :refByOliIdMap.keySet()]);

      // clear out the array to start                                
      olisToUpsert.clear();
                                
      // select all of the opportunities that are updateable
      Map<Id, Opportunity> oppMap = new Map<Id, Opportunity> (
                              [select Id, Amount, CloseDate, Name, Probability, IsClosed
                                     ,Account.Id
                                     ,Account.CurrentClient__c
                                     ,Account.Time_and_Attendance__c
                                     ,Owner.Id
                                     ,Owner.Sales_Org__c
                                     ,Owner.NSS_Team__c
                                     ,OverrideRevenueSplit__c
                                     ,Pricebook2Id
                                     ,RecordTypeId
                                     ,RecordType.Name
                                     ,StageName
                                     ,Zip_Tier__c
                                     ,(select Id
                                             ,Estimated_Revenue__c                
                                             ,Non_Discounted_Revenue__c
                                             ,Non_Payroll_Unit__c
                                             ,Payroll_Unit__c
                                             ,Product2Id                 
                                             ,Product2.Name 
                                             ,Product2.ProductCode
                                             ,Product2.Exclude_Revenue_Split__c
                                             ,QuoteLineGroupAcct__c
                                             ,SplitAdjustment__c
                                             ,SplitPercent__c
                                             ,TotalPrice
                                         from OpportunityLineItems )
                                 From Opportunity
                                Where Id in :allOppIdSet
                                  and OverrideRevenueSplit__c = false
                                  //and IsClosed = false				//Commented as part of APR0127737
                                  and Probability <= :MAX_OPP_PERCENT]);
      System.debug('checkLinkedOppsNow oppMap='+oppMap.size());
      
      OppWrapper[] foundRecs = new OppWrapper[]{};
      // loop through the id set originally passed in. If they don't meet the criteria, will not be selected.
      for (Id oppId : oppIdSet) {
         Referral__c ref = refBySellingOppIdMap.get(oppId);
         Opportunity originalOpp = oppMap.get(oppId);
         
         System.debug('checkLinkedOppsNow oppId='+oppId+' opp Selected='+(originalOpp != null));
         
         if (originalOpp != null) {
            OppWrapper oppWrap = new OppWrapper(originalOpp, ref, oppMap);
            if (String.isNotBlank(oppWrap.splitType)) {
               foundRecs.add(oppWrap);
               processSplit(oppWrap);
            }
         }
      } // for (Id oppId : oppIdSet
      
      System.debug('checkLinkedOppsNow olisToUpsert='+olisToUpsert.size());
      if (!olisToUpsert.isEmpty()) {
         OpptyLineItem.SKIP_TRIGGER = true;
         OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
         System.debug('checkLinkedOppsNow olisToUpsert='+olisToUpsert.size());
         DmlHelper.performDML2(olisToUpsert, DmlHelper.DML_UPSERT, 'OpptyRevenueSplit', 'checkLinkedOppsNow', 'upsert olisToUpsert', true);
         System.debug('checkLinkedOppsNow olisToUpsert after upsert');
         if (LOG_SPLIT && !logsToInsert.isEmpty()) {
            DmlHelper.performDML2(logsToInsert, DmlHelper.DML_UPSERT, 'OpptyRevenueSplit', 'checkLinkedOppsNow', 'insert logs', true);
         }
         OpptyMethods.SKIP_OPPTY_TRIGGERS = false;
         OpptyLineItem.SKIP_TRIGGER = false;
      }
   } // checkLinkedOppsNow

   public static OpportunityLineItem[] olisToUpsert = new OpportunityLineItem[]{};
   public static ErrorLog__c[] logsToInsert = new ErrorLog__c[]{};

   public static void addToSet(Set<Id> oppIdSet, Referral__c ref) {
      if (ref != null) {
         addToSet(oppIdSet, ref.Selling_Opportunity__c);
      }
   } // addToSet
   
   public static void addToSet(Set<Id> oppIdSet, Id oppId) {
      if (oppId != null) {
         oppIdSet.add(oppId);
      }
   } // addToSet
   
   public static void processSplit(OppWrapper oppWrap) {
      ErrorLog__c log = new ErrorLog__c(ClassName__c='OpptyRevenueSplit',MethodName__c='processSplit',CodeKey__c='LOG_DATA', ObjectId__c=oppWrap.originalOpp.Id);
      addToLog(log,'process split '+oppWrap.splitType);
      
      handleOriginalOpp(oppWrap,log);
      handleReferringOpp(oppWrap,log);
      logsToInsert.add(log);
   } // processSplit
   
   public static void addToLog(ErrorLog__c log, String textToAdd) {
      StringHelper.addNotesToField(log, 'Description__c', ErrorLog.DESCRIPTION_SIZE, textToAdd, true);
   } // addToLog
   
   // figure out the deduction on the main opportunity (source, original opp)
   public static void handleOriginalOpp(OppWrapper oppWrap, ErrorLog__c log) {
      System.debug('handleOriginalOpp opp='+oppWrap.originalOpp.Name);
      oppWrap.adjustmentAmount = 0;
      oppWrap.originalOli = null;
      
      for (OpportunityLineItem oli : oppWrap.originalOpp.OpportunityLineItems) {
         Decimal adjAmount = null;
         Decimal adjPct = (oli.Product2.Exclude_Revenue_Split__c ? 0 : ((oppWrap.planCodePctMap.containsKey('All') && oppWrap.excludeProdMap != null && oppWrap.excludeProdMap.containsKey('All') && !(oppWrap.excludeProdMap.get('All').contains(oli.Product2.ProductCode)))?
                                    oppWrap.planCodePctMap.get('All') : 
                                    (oppWrap.planCodePctMap.containsKey('All') && oppWrap.excludeProdMap != null && oppWrap.excludeProdMap.containsKey('All') &&  (oppWrap.excludeProdMap.get('All').contains(oli.Product2.ProductCode)))?
                                    oppWrap.planCodePctMap.get(oli.Product2.ProductCode) :                 
                                    oppWrap.planCodePctMap.containsKey('All') ? oppWrap.planCodePctMap.get('All') : oppWrap.planCodePctMap.get(oli.Product2.ProductCode)                          
                         ));
         if (oli.Product2.ProductCode == oppWrap.oliAdjCode) {
            // get the opportunity line item that will store the adjustment
            oppWrap.originalOli = oli;
            addToLog(log,'Found oli for adjustment product code='+oppWrap.oliAdjCode+' oli='+oli.Id);
         } else if (adjPct != null && oli.TotalPrice != null && oli.TotalPrice != 0) {
            adjAmount = (oli.TotalPrice * adjPct/100).setScale(2, RoundingMode.HALF_UP);
            addToLog(log,'adjustment for '+oli.Product2.ProductCode+'= TotalPrice='+oli.TotalPrice+' adjAmount='+adjAmount+' adjPct='+adjPct);
            System.debug('handleOriginalOpp oli.TotalPrice='+oli.TotalPrice+' adjAmount='+adjAmount+' adjPct='+adjPct);
         }

         if (adjAmount != null) {
            oppWrap.adjustmentAmount += adjAmount;
         }         
         if (oli.Product2.ProductCode != oppWrap.oliAdjCode && (oli.SplitAdjustment__c != adjAmount || oli.SplitPercent__c != adjPct)) {
            // log the amount just for tracking purposes.
            oli.SplitAdjustment__c = adjAmount;
            oli.SplitPercent__c = adjPct;
            olisToUpsert.add(oli);
            addToLog(log,'handleOriginalOpp updated SplitAdjustment__c and SplitPercent__c olisToUpsert='+olisToUpsert.size());
         }
      } // for (OpportunityLineItem oli

      System.debug('handleOriginalOpp adjustmentAmount='+oppWrap.adjustmentAmount+' originalOli='+oppWrap.originalOli);
      addToLog(log,'handleOriginalOpp adjustmentAmount='+oppWrap.adjustmentAmount);
      
      if (oppWrap.originalOli == null && String.IsNotBlank(oppWrap.oliAdjCode) && oppWrap.adjustmentAmount != 0) {
         // create a new line item.
         PricebookEntry pbe = getProductByCode(oppWrap.originalOpp.Pricebook2Id, oppWrap.oliAdjCode);
         System.debug('handleOriginalOpp create New Oli pbe='+pbe);
         addToLog(log,'handleOriginalOpp create New Oli prod code='+oppWrap.oliAdjCode+' pbe='+(pbe != null ? (String)pbe.Id : 'Not Found!'));
         if (pbe != null) {
            oppWrap.originalOli = new OpportunityLineItem(OpportunityId=oppWrap.originalOpp.Id, PricebookEntryId=pbe.Id
                                           ,ServiceDate=oppWrap.originalOpp.CloseDate, Quantity=1);
         }
         
      } // if (oppWrap.originalOli == null
      
      if (oppWrap.originalOli != null) {
         oppWrap.originalOli.TotalPrice = oppWrap.adjustmentAmount*(-1);  // to subtract the amount from this opportunity
         olisToUpsert.add(oppWrap.originalOli);
         addToLog(log,'handleOriginalOpp set adjustment amount='+oppWrap.originalOli.TotalPrice+' olisToUpsert='+olisToUpsert.size());
      }
      System.debug('handleOriginalOpp olisToUpsert='+olisToUpsert.size());
   } // handleOriginalOpp
   
   public static void handleReferringOpp(OppWrapper oppWrap, ErrorLog__c log) {
      System.debug('handleReferringOpp hasReferringOpp='+oppWrap.referringOpp != null+' adjustmentAmount='+oppWrap.adjustmentAmount);
      if (oppWrap.referringOpp == null || oppWrap.adjustmentAmount == 0) {
         return;
      }
      oppWrap.referringOli = null;
      for (OpportunityLineItem oli : oppWrap.referringOpp.OpportunityLineItems) {
         if ((oppWrap.referringOliId != null && oppWrap.referringOliId == oli.Id)
             || (oppWrap.referringOliId == null && String.isNotBlank(oppWrap.oliAdjCodeReferring) && oppWrap.oliAdjCodeReferring == oli.Product2.ProductCode)
            ) {
            oppWrap.referringOli = oli;
            break;
         } 
      } // for
      
      System.debug('handleReferringOpp oppWrap.referringOli='+oppWrap.referringOli);
      addToLog(log,'handleReferringOpp oppWrap.referringOli='+oppWrap.referringOli);
      
      if (oppWrap.referringOli == null && String.isNotBlank(oppWrap.oliAdjCodeReferring)) {
         // create a new line item.
         PricebookEntry pbe = getProductByCode(oppWrap.referringOpp.Pricebook2Id, oppWrap.oliAdjCodeReferring);
         System.debug('handleReferringOpp create New Oli pbe='+pbe);
         addToLog(log,'handleReferringOpp create New Oli prod code='+oppWrap.oliAdjCodeReferring+' pbe='+(pbe != null ? (String)pbe.Id : 'Not Found!'));
         if (pbe != null) {
            oppWrap.referringOli = new OpportunityLineItem(OpportunityId=oppWrap.referringOpp.Id, PricebookEntryId=pbe.Id
                                           ,ServiceDate=oppWrap.referringOpp.CloseDate, Quantity=1);
         }
      }
      
      if (oppWrap.referringOli != null) {
         oppWrap.referringOli.TotalPrice = oppWrap.adjustmentAmount;
         olisToUpsert.add(oppWrap.referringOli);
         addToLog(log,'handleReferringOpp set adjustment amount='+oppWrap.referringOli.TotalPrice+' olisToUpsert='+olisToUpsert.size());
      }
      System.debug('handleReferringOpp olisToUpsert='+olisToUpsert.size());
   } // handleReferringOpp
   
   // Create new products - Integrated Selling Adjustment, HR Services/PEO Adjustment 
   
   public static String PROD_INTEGRATED_SELLING = Label.ProdIntegratedSelling;   // Integrated Selling Adjustment
   public static String PROD_INTERNAL = Label.ProdInternalRef;
   public static String PROD_NON_INTEGRATED_SELLING = Label.ProdNonIntegrated; // Non-Integrated Selling Adjustment
   public static String ALL_PRODS = 'All';
   
   public static String ATTR_PROSPECT='Prospect';
   public static String ATTR_CUR_CLIENT='Current Client';
   public static String ATTR_NO_T_AND_A='No Time and Attendance';
      
   public class OppWrapper {
      public OppWrapper(Opportunity p_originalOpp, Referral__c p_ref, Map<Id, Opportunity> oppMap) {
         originalOpp = p_originalOpp;
         ref = p_ref;
         checkSplitType(oppMap);
      } // OppWrapper
      
      public void checkSplitType(Map<Id, Opportunity> oppMap) {
         System.debug('checkSplitType has ref='+ref != null);
         if (ref != null) {
            // if there's already an id set on the referral, keep track of that
            referringOliId = (Id)ref.ReferringLineItemId__c;
            
            System.debug('checkSplitType referringOliId='+referringOliId+' ref.PartnerType__c='+ref.PartnerType__c+' ref.ReferralJoin__r='+ref.ReferralJoin__r);
            // for both of the following, make sure both of the opportunities are open and available
            if (ref.PartnerType__c == ReferralController.REF_INTERNAL) {
               referringOpp = (ref.Referring_Opportunity__c != null ? oppMap.get(ref.Referring_Opportunity__c) : null);
               if (referringOpp != null) {
                  splitType = ReferralController.REF_INTERNAL;
                  oliAdjCode = PROD_INTERNAL;
                  // for internal referrals the referring line item should already exist
                  oliAdjCodeReferring = null;
                  //deductAllProds = false;
               }
            } else if (ref.PartnerType__c == ReferralController.REF_INTSELL && ref.ReferralJoin__r != null
                        && ref.ReferralJoin__r.PAS_Referral__r != null && ref.ReferralJoin__r.PAS_Referral__r.Selling_Opportunity__c == originalOpp.Id) {
               // "originalOpp" should be HR Services
               // "referringOpp" should be Payroll
               Id referringOppId = (ref.ReferralJoin__r.MMS_Referral__r != null && ref.ReferralJoin__r.MMS_Referral__r.Selling_Opportunity__c != null 
                                           ? ref.ReferralJoin__r.MMS_Referral__r.Selling_Opportunity__c 
                                           : (ref.ReferralJoin__r.Core_Referral__r != null ? ref.ReferralJoin__r.Core_Referral__r.Selling_Opportunity__c : null));
               referringOpp = (referringOppId != null ? oppMap.get(referringOppId) : null);
               
               System.debug('checkSplitType Integrated Selling referringOppId='+referringOppId+' referringOpp='+referringOpp);
               if (referringOpp != null) {
                  splitType = ReferralController.REF_INTSELL;
                  oliAdjCode = PROD_INTEGRATED_SELLING;
                  oliAdjCodeReferring = PROD_INTEGRATED_SELLING;
                  //deductAllProds = true;
                  //allProdDeduction = .5; // TODO - have to pull this from a table or something
               }
            }

         } // if (ref != null
         
         if (String.isBlank(splitType)) {
            RecordType__c recordTypeSetting = RecordTypeHelper.getRtSetting(originalOpp.RecordType.Name);
            if (recordTypeSetting != null && recordTypeSetting.NonIntegratedSellingAdjustment__c) {
               // if PEO/ASO opp, deduct based on product
               splitType = 'Non Integrated Selling'; //PROD_NON_INTEGRATED_SELLING;
               oliAdjCode = PROD_NON_INTEGRATED_SELLING;
               oliAdjCodeReferring = null;
               //deductAllProds = false;
            }
         } // if (String.isBlank(splitType
         System.debug('checkSplitType splitType='+splitType);
         checkSplitRules();
      } // checkSplitType
      
      public String splitType = null;
      
      public void checkSplitRules() {
         // can't do anything if there are no split rules
         if (String.IsBlank(splitType)) {
            return;
         }
         OpptyRevSplit__mdt[] checkRules = [Select Id, Label
                                                  ,AccountAttributes__c
                                                  ,PctReferring__c
                                                  ,ProductCodes__c
                                                  ,ReferringSalesOrg__c
                                                  ,SellingNSSTeam__c
                                                  ,SellingRecordType__c
                                                  ,SellingSalesOrg__c
                                                  ,SellingZipTier__c
                                                  ,Type__c
                                                  ,ExcludeProdCode__c
                                              From OpptyRevSplit__mdt
                                             Where Type__c = :splitType];

         System.debug('checkSplitRules splitType='+splitType+' checkRules='+checkRules.size());
         String referringSalesOrg = (referringOpp != null ? checkSalesOrg(referringOpp.RecordType.Name,referringOpp.Owner) : null);
         String sellingSalesOrg = (originalOpp != null ? checkSalesOrg(originalOpp.RecordType.Name,originalOpp.Owner) : null);
         String sellingNssTeam = (originalOpp != null ? originalOpp.Owner.NSS_Team__c : null);
         String sellingZipTier = (originalOpp != null ? originalOpp.Zip_Tier__c : null);
         System.debug('checkSplitRules referringSalesOrg='+referringSalesOrg+' sellingSalesOrg='+sellingSalesOrg+' sellingNssTeam='+sellingNssTeam+' sellingZipTier='+sellingZipTier);

         for (OpptyRevSplit__mdt checkRule : checkRules) {
            System.debug('checkSplitRules checkRule='+checkRule.Label);
            // check perform the outer check - correct rep types on selling 
            if (((checkRule.SellingSalesOrg__c == sellingSalesOrg)
                    || (sellingSalesOrg == 'Virtual' && checkRule.SellingNSSTeam__c == sellingNssTeam))
                && ((referringOpp == null && String.isBlank(checkRule.ReferringSalesOrg__c))
                     || (referringSalesOrg == checkRule.ReferringSalesOrg__c))
               ) {
               System.debug('checkSplitRules checkRule='+checkRule.Label+' entered the first If statement');
               if (checkOtherAttributes(checkRule,sellingZipTier)) {
                  setPlanCodeRules(checkRule);
               }
            } // if (((checkRule.SellingSalesOrg__c
         } // for (OpptyRevSplit__mdt checkRule
         System.debug('checkSplitRules splitType='+splitType+' planCodePctMap='+planCodePctMap.size());
      } // checkSplitRules
      
      public String checkSalesOrg(String recordTypeName, User checkUsr) {
         RecordType__c rt = RecordTypeHelper.getRtSetting(recordTypeName);
         System.debug('checkSalesOrg checkUsr.Sales_Org__c: '+checkUsr.Sales_Org__c); 
         SalesOrg__c salesOrgCS = SalesOrg__c.getInstance(checkUsr.Sales_Org__c); 
         System.debug('checkSalesOrg salesOrgCS: '+salesOrgCS); 
         //String salesOrg = (rt != null ? rt.Sales_Org__c : null);
         String salesOrg = ((salesOrgCS != null && salesOrgCS.Use_for_Rev_Split__c) ? checkUsr.Sales_Org__c : (rt != null ? rt.Sales_Org__c : null));
         if (String.isBlank(salesOrg) && checkUsr != null) {
            salesOrg = checkUsr.Sales_Org__c;
            System.debug('checkSalesOrg salesOrg: '+salesOrg); 
         }
         return salesOrg;
      } // checkSalesOrg
      
      public void setPlanCodeRules(OpptyRevSplit__mdt checkRule) {
         System.debug('setPlanCodeRules ProductCodes__c='+checkRule.ProductCodes__c+' PctReferring__c='+checkRule.PctReferring__c);
         if (String.isNotBlank(checkRule.ProductCodes__c) && checkRule.PctReferring__c != null) {
            String[] planCodes = checkRule.ProductCodes__c.split(',');
            for (String planCode : planCodes) {
               planCodePctMap.put(planCode.trim(), checkRule.PctReferring__c);
               If(String.isNotBlank(checkRule.ExcludeProdCode__c)){
                  excludeProdMap.put(planCode.trim(),checkRule.ExcludeProdCode__c );
               }
            }
         } // if
      } // setPlanCodeRules
      
      public Boolean checkOtherAttributes(OpptyRevSplit__mdt checkRule, String sellingZipTier) {
         Boolean okay = true;
         System.debug('checkOtherAttributes checkRule='+checkRule.Label+' SellingRecordType__c='+checkRule.SellingRecordType__c);
         if (String.isNotBlank(checkRule.SellingRecordType__c)) {
            okay = false;
            String[] recordTypes = checkRule.SellingRecordType__c.split(',');
            for (String recordType : recordTypes) {
               if (originalOpp.RecordType.Name == recordType.trim()) {
                  okay = true;
                  break;
               }
            } // for (String recordType
         } // if (String.isNotBlank(recordTypeNames
         
         System.debug('checkOtherAttributes checkRule='+checkRule.Label+' okay='+okay+' AccountAttributes__c='+checkRule.AccountAttributes__c);
         if (okay && String.isNotBlank(checkRule.AccountAttributes__c) && checkRule.AccountAttributes__c != 'NA') {
            if (checkRule.AccountAttributes__c == ATTR_PROSPECT && originalOpp.Account.CurrentClient__c) {
               okay = false;
            } else if (checkRule.AccountAttributes__c == ATTR_CUR_CLIENT && !originalOpp.Account.CurrentClient__c) {
               okay = false;
            } else if (checkRule.AccountAttributes__c == ATTR_NO_T_AND_A && String.isNotBlank(originalOpp.Account.Time_and_Attendance__c)) {
               okay = false;
            }
         } // if (okay && String.isNotBlank(checkRule.AccountAttributes__c
         
         if (okay && String.isNotBlank(checkRule.SellingZipTier__c)) {
            Set<String> zipTierSet = new Set<String>(checkRule.SellingZipTier__c.split(','));
            okay = (String.isNotBlank(sellingZipTier) && zipTierSet.contains(sellingZipTier));
         }
         System.debug('checkOtherAttributes checkRule='+checkRule.Label+' okay='+okay+' end of method');
         return okay;
      } // checkOtherAttributes
      
      public Id referringOliId = null;

      // the triggering opportunity - this is the source of the revenue that will be split
      public Opportunity originalOpp = null;
      //public Decimal originalRevenue = 0;
      public OpportunityLineItem originalOli = null;
      
      // map of plan codes and the associated percent deducted.
      // If all plan codes are deducted, there will be an entry for "ALL_PRODS"
      public Map<String,Decimal> planCodePctMap = new Map<String,Decimal>();
      
      //public Decimal originalAdjustment = 0;
      //public Decimal allProdDeduction = 0;

      // the amount of the adjustment being calculated
      public Decimal adjustmentAmount = 0;
      
      // if the revenue is being split to another opportunity, this is where it will go.
      public Opportunity referringOpp = null;
      //public Decimal referringRevenue = 0;
      public OpportunityLineItem referringOli = null;
      
      public Referral__c ref = null;
      // the product code of the product for the adjustment of the revenue (if there isn't already a line item present)
      public String oliAdjCode = null;
      // the product code of the product for the adjustment on the original opportunity
      //public String originalAdjCode = null;
      // the product code of the product for the adjustment on the referring opportunity
      public String oliAdjCodeReferring = null;
      
      // do we deduct the revenue from all of the products?
      //public Boolean deductAllProds = false;
      // where we don't deduct from all of the products, have to provide a mapping of product code and percent/amount to adjust
      // TODO - mapping!
      public Map<String,String> excludeProdMap = new Map<String,String>();
             
      
   } // OppWrapper
   
   public static String CACHE_KEY='OpptyRevenueSplitPricebookEntryCacheKey';

   public static Map<String,PricebookEntry> pbeMap = null;
   
   public static PricebookEntry getProductByCode(Id pricebookId, String productCode) {
      if (pricebookId == null || String.isBlank(productCode)) {
         return null;
      }
      if (pbeMap == null) {
         pbeMap = (Map<String,PricebookEntry>)CacheManager.getOrg(CACHE_KEY);
         if (pbeMap == null) {
            pbeMap = new Map<String,PricebookEntry>();
         }
      } // if (v_dgWrap == null
      
      String mapKey = pricebookId+productCode;

      PricebookEntry pbe = pbeMap.get(mapKey);
      if (pbe == null) {
         try {
            PricebookEntry[] entries = [Select Id
                                              ,IsActive
                                              ,Pricebook2Id
                                              ,Product2Id
                                              ,Product2.Name
                                              ,Product2.IsActive
                                          From PricebookEntry
                                         Where Pricebook2Id = :pricebookId
                                           and Product2.ProductCode = :productCode];
            // should only be one product
            pbe = (!entries.isEmpty() ? entries[0] : null);
         } catch (Exception e) {
            System.debug('getProductByCode unable to retrieve for pricebook id='+pricebookId+' product code='+productCode+': '+e.getMessage()+'; '+e.getStackTraceString());
         }
         if (pbe == null) {
            // put a blank entry in the map so we don't try retrieving it again
            System.debug('getProductByCode could not find product pricebookId='+pricebookId+' productCode='+productCode);
            pbe = new PricebookEntry();
         }
         pbeMap.put(mapKey, pbe);
         // since something has changed, put into the cache
         CacheManager.putOrg(CACHE_KEY, pbeMap);
      } // if (pbe == null
      return (pbe.Id != null ? pbe : null);
   } // getProductByCode
  
} // class OpptyRevenueSplit