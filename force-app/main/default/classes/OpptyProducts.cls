/* 
 * Check the status of an Opportunity after it's saved. Perform actions if certain criteria is met.
 *
 * History
 * -------
 * 11/10/2011 Dan Carmen   Created
   12/23/2011 Dan Carmen   Check to see if opportunity is cloned.
   07/30/2015 Dan Carmen   Modifications for pilot users
   03/01/2016 Jacob Hinds  Added Referred Commissioned and Referred Sold - Commissioned to getProdStatus
   04/18/2018 Dan Carmen   Change to future methods
   05/23/2018 Jake Hinds   Changing line item status to match opportunity stage directly
   04/05/2019 Dan Carmen   Modifying how default products are being set.
   03/16/2021 Carrie Marciano   Removing getProdStatus, will now set the prodStatus to the Oppty.StageName
   06/29/2021 Dan Carmen   Update checkOpptyAndProductStatusFuture to get around Aggregate query has too many rows error
   11/17/2021 Dan Carmen   Add more debugging
   02/07/2022   Pujitha Madamanchi  Add Referral Approved date to query
   03/01/2022   Pujitha Madamanchi  Populate Referral Approved date & Timeframe on creation
   03/02/2022 Dan Carmen   APR0131613 Change how default pricebook is set
   03/16/2022   Pujitha Madamanchi  APR0133426 Link Referral with Referral Join
   01/24/2023   Pujitha Madamanchi  APR0134608 Populate Funnel Stage details on clone Referral.
   10/18/2023 Dan Carmen       Modified addDefaultOpptyLineItemNow so it will work without pricebook sales org 

 */
public without sharing class OpptyProducts {
   
    public static void checkOpptyAndProductStatus(Id[] opptyIds) {
      if (Utilities.allowFuture()) {
         checkOpptyAndProductStatusFuture(opptyIds);
         system.debug('checkOpptyAndProductStatusFuture');
      } else {
         checkOpptyAndProductStatusNow(opptyIds);
         system.debug('checkOpptyAndProductStatusNow'); 
      }
   } // checkOpptyAndProductStatus

   @future
   public static void checkOpptyAndProductStatusFuture(Id[] opptyIds) {
      checkOpptyAndProductStatusNow(opptyIds);
   }

   // Check the status and date of the products to make sure they match the opportunity.
   public static void checkOpptyAndProductStatusNow(Id[] opptyIds) {
      // don't select the line items that have the override set to true.
      Boolean origValue = OpptyLineItem.SKIP_TRIGGER;
      OpptyLineItem.SKIP_TRIGGER = true;
      for (OpportunityLineItem[] olis : [Select Id, Status__c, ServiceDate, OpportunityId
                                             ,Opportunity.StageName, Opportunity.CloseDate
                                         From OpportunityLineItem 
                                         where OpportunityId in :opptyIds
                                           and User_Override__c = false]) {
         OpportunityLineItem[] updateItems = new OpportunityLineItem[]{};
         for (OpportunityLineItem oli : olis) {
            if ((oli.Status__c != oli.Opportunity.StageName)
                || (oli.ServiceDate != oli.Opportunity.CloseDate)) {
               oli.Status__c = oli.Opportunity.StageName;
               oli.ServiceDate =  oli.Opportunity.CloseDate;
               updateItems.add(oli);
            }
         } // for (OpportunityLineItem oli : olis
         DmlHelper.performDml2(updateItems, DmlHelper.DML_UPDATE, 'OpptyProducts', 'checkOpptyAndProductStatusNow', 'Updating Line Items', false);
      } // for (OpportunityLineItem[] olis
      OpptyLineItem.SKIP_TRIGGER = origValue;
      ErrorLog.checkSave();

   } // checkOpptyAndProductStatusNow
   
   /** no longer being used, will copy Oppty.StageName as prodStatus
    * 
    * Get the Product line status based on the status of the Opportunity.
      Valid line item statuses: 
         "Not Sold" - will be set if Oppty is "Not Sold", "Referred Not Sold"
         "Pending" - if doesn't meet other criteria
         "Sold" - if oppty is "Sold", "Sold -", "Sold:", "Referred Sold"
         "Sold - Submitted" - if oppty is "Sold - Submitted", "Sold: Submitted"
         "Sold - Started" - if oppty is "Sold - Started", "Referred Started", "Sold - Run"
         "Sold - Commissioned" - this will only be set by the integration process - don't do anything on the products if this status
  
   public static String getProdStatus(String opptyStatus) {
      // the default status
      String prodStatus = 'Pending';
      // should never be null, but just in case...
      if (opptyStatus != null) {
         if (opptyStatus == 'Not Sold' || 
             opptyStatus == 'Referred Not Sold') {
            prodStatus = 'Not Sold';
         } else if (opptyStatus == 'Sold' ||
                    opptyStatus == 'Referred Sold' ||
                    opptyStatus == 'Sold -' ||
                    opptyStatus == 'Sold:') {
            prodStatus = 'Sold';
         } else if (opptyStatus == 'Sold - Submitted' || 
                    opptyStatus == 'Sold: Submitted' ||
                    opptyStatus == 'Referred Submitted') {
            prodStatus = 'Sold - Submitted';
         } else if (opptyStatus == 'Sold - Started' || 
                    opptyStatus == 'Referred Started' || 
                    opptyStatus == 'Sold - Run') {
            prodStatus = 'Sold - Started';
         } else if (opptyStatus == COMMISSIONED || opptyStatus == 'Referred Commissioned') {
            // don't do anything on the products for this status.
            prodStatus = COMMISSIONED;
         }
         // if (opptyStatus
      } // if (opptyStatus != null
      return prodStatus;
   } // getProdStatus   */
   
   public static final String COMMISSIONED = 'Sold - Commissioned';
    
   public static String MAP_TYPE='Oppty-Default';
   
   public static void addDefaultOpptyLineItem(Id[] opptyIds) {
      if (Utilities.allowFuture()) {
         addDefaultOpptyLineItemFuture(opptyIds);
      } else {
         addDefaultOpptyLineItemNow(opptyIds);
      }
   } // checkOpptyAndProductStatus

   @future
   public static void addDefaultOpptyLineItemFuture(Id[] opptyIds) {
      addDefaultOpptyLineItemNow(opptyIds);
   }

   public static Boolean LOG_DATA=(Label.OpptyProducts_LogData == 'Y');

   public static void addDefaultOpptyLineItemNow(Id[] opptyIds) {
      System.debug('addDefaultOpptyLineItemNow opptyIds='+opptyIds.size());
      
      ErrorLog__c errLog = ErrorLog.logError('OpptyProducts', 'addDefaultOpptyLineItemNow', 'LOG_DATA', (!opptyIds.isEmpty() ? opptyIds[0] : null), 'Nbr opptyIds='+opptyIds.size());
      errLog.BatchSize__c=opptyIds.size();
      
      // the records to create
      OpportunityLineItem[] newOlis = new OpportunityLineItem[]{};
          
      Map<String,PricebookEntry> defProdMap = new Map<String,PricebookEntry>();
      PricebookEntry[] defEntries = [Select Id, Product2Id
                                           ,Product2.Id
                                           ,Product2.Is_Default_Product__c
                                           ,Product2.Name
                                           ,Product2.ProductCode
                                           ,Product2.Product_Group__c
                                           ,Product2.Sales_Org__c
                                           ,Pricebook2.Id
                                           ,Pricebook2.Quote_User__c
                                           ,Pricebook2.Sales_Org__c
                                           ,Pricebook2.Sales_Org2__c
                                           ,Pricebook2.DefaultProduct__c
                                       From PricebookEntry
                                      Where Product2.Is_Default_Product__c = true
                                        and Product2.IsActive=true
                                      order by Pricebook2Id, Product2.Sort_Order__c];
      for (PricebookEntry entry : defEntries) {
         if (String.isNotBlank(entry.Product2.Product_Group__c)) {
            defProdMap.put(entry.Pricebook2.Sales_Org__c+entry.Product2.Product_Group__c, entry);
            defProdMap.put(entry.Pricebook2.Id+entry.Product2.Product_Group__c, entry);
         }
         if (Pricebook2.DefaultProduct__c != null) {
            if (String.IsNotBlank(entry.Pricebook2.Sales_Org__c) && entry.Product2Id == entry.Pricebook2.DefaultProduct__c) {
                // to build the name 'PAS-Steelbrick' if not already the sales org name
                String key = entry.Pricebook2.Sales_Org__c
                              +((String.isNotBlank(entry.Pricebook2.Quote_User__c) && !entry.Pricebook2.Sales_Org__c.contains(entry.Pricebook2.Quote_User__c)) ? '-'+entry.Pricebook2.Quote_User__c : '');
                defProdMap.put(key, entry);
            }
            // store by pricebook2Id
            defProdMap.put(entry.Pricebook2Id, entry);
            // todo - might have to eventually build in Sales_Org2__c
         }

      } // for (PricebookEntry entry : defEntries
               
      Opportunity[] oppList = [Select Id, Name
                                         ,Owner.PilotUser__c
                                         ,Owner.Sales_Division__c
                                         ,Owner.Sales_Org__c
                                         ,RecordType.Name
                                         ,StageName, CloseDate
                                         ,HasOpportunityLineItem
                                         ,OpportunityId__c
                                         ,Pricebook2Id
                                      ,AdditionalProductsOfInterest__c
                                         ,EvaluateProductGroup__c
                                    from Opportunity where Id in :opptyIds];

      System.debug('addDefaultOpptyLineItemNow defProdMap='+defProdMap.size());
      ErrorLog.addToDescription(errLog,'Nbr of oppList='+oppList.size()+' defProdMap='+defProdMap.size());
      for (Opportunity opp : oppList) {
         ErrorLog.addToDescription(errLog,'opp='+opp.Name+' HasOpportunityLineItem='+opp.HasOpportunityLineItem);
         if (!opp.HasOpportunityLineItem) {
            Id pricebookId = opp.Pricebook2Id;
            System.debug('addDefaultOpptyLineItemNow pricebookId='+pricebookId);
            if (pricebookId == null) {
               Pricebook2 pricebook = ProductQuery.getPrimaryPricebook(opp.Owner,opp.Owner.Sales_Org__c,opp.Owner.Sales_Division__c);
               pricebookId = (pricebook != null ? pricebook.Id : null);
               System.debug('addDefaultOpptyLineItemNow searched for Pricebook pricebookId='+pricebookId);
            }
            String salesOrg = ProductMapping.getSalesOrg(opp.RecordType.Name,opp.Owner,true);
            String salesOrg2 = ProductMapping.getSalesOrg(opp.RecordType.Name,opp.Owner,false);
            ErrorLog.addToDescription(errLog,'salesOrg='+salesOrg+' salesOrg2='+salesOrg2);
            System.debug('addDefaultOpptyLineItemNow EvaluateProductGroup__c='+opp.EvaluateProductGroup__c+' AdditionalProductsOfInterest__c='+opp.AdditionalProductsOfInterest__c);
            if(opp.EvaluateProductGroup__c && String.IsNotBlank(opp.AdditionalProductsOfInterest__c)) {
                // remove all of the spaces
                String AddPOI = opp.AdditionalProductsOfInterest__c.replaceAll( '\\s+', '');                
                String[] AdditionalProductOfInterest = AddPOI.split(',');
                // handle potentially multiple products
                for (String prodOfInterest : AdditionalProductOfInterest) {
                   PricebookEntry entry = (pricebookId != null ? defProdMap.get(pricebookId+prodOfInterest) : null);
                   if (entry == null) {
                      entry = defProdMap.get(salesOrg+prodOfInterest);
                   }
                   if (entry == null) {
                      entry = defProdMap.get(salesOrg2+prodOfInterest);
                   }
                   //String pricebookentryid = (defaultProductMap.containsKey(addtn) ? +defaultProductMap.get(addtn).id : null);
                   System.debug('addDefaultOpptyLineItemNow prodOfInterest='+prodOfInterest+'. entry='+(entry != null ? entry.Id : null));
                   if (entry != null) {
                      createOppLineItem(opp, entry.Id,newOlis);
                   }
                } // for (String addtn
            } else {
                // this is the legacy way of setting the default product before the product group came around
                if (pricebookId != null) {
                   PricebookEntry entry = defProdMap.get(pricebookId);
                   //Product_Mapping__c mapping = mapWrap.byPricebookIdMap.get(opp.Pricebook2Id);
                   ErrorLog.addToDescription(errLog,'pricebookId='+pricebookId+' entry found='+(entry != null));
                   if (entry != null) {
                      createOppLineItem(opp, entry.Id,newOlis);
                   }
                } else {
                   PricebookEntry entry = defProdMap.get(salesOrg);
                   if (entry == null) {
                      entry = defProdMap.get(salesOrg2);
                      ErrorLog.addToDescription(errLog,'2nd attempt salesOrg='+salesOrg);
                   }
                   //Product_Mapping__c mapping = mapWrap.bySalesOrgMap.get(salesOrg);
                   ErrorLog.addToDescription(errLog,'salesOrg='+salesOrg+' entry found='+(entry != null));
                   if (entry != null) {
                      createOppLineItem(opp, entry.Id,newOlis);
                   }
                }
            } // if (opp.Pricebook2Id
         } // if (!opp.HasOpportunityLineItem
      } // for (Opportunity opp      
         
      ErrorLog.addToDescription(errLog,'newOlis='+newOlis.size());
      errLog.NbrSuccess__c=newOlis.size();
      if (!newOlis.isEmpty()) {
           OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
           System.debug('newOlis = '+newOlis);
           DmlHelper.performDml2(newOlis, DmlHelper.DML_INSERT, 'OpptyProducts', 'addDefaultOpptyLineItem', 'Inserting Default Line Items', true);
           //insert newOlis;
        // Set<id> opptyIdSet = new Set<id>(opptyIds);           
           //EvaluateProductOfInterest(opptyIdSet);
           OpptyMethods.SKIP_OPPTY_TRIGGERS = false;
       }
       if (LOG_DATA) {
           ErrorLog.checkSave();
       }      
   } // addDefaultOpptyLineItem
   
   public static void evaluateProductOfInterest(set<id> opptyIds) {
      if (Utilities.allowFuture()) {
         evaluateProductOfInterestFuture(opptyIds);
      } else {
         evaluateProductOfInterestNow(opptyIds);
      }
   } // checkOpptyAndProductStatus

   @future
   public static void evaluateProductOfInterestFuture(set<id> opptyIds) {
      evaluateProductOfInterestNow(opptyIds);
   }
   public static Referral__c[] referralsToUpdate = new Referral__c[]{};
   // see if there are any changes to the selected prod groups to the opp
   public static void evaluateProductOfInterestNow(set<id> opptyIds) {
      System.debug('evaluateProductOfInterestNow opptyIds='+opptyIds.size());
      Opportunity[] opptysList =  [Select Id, Name
                                         ,Owner.PilotUser__c
                                         ,Owner.Sales_Org__c
                                         ,RecordType.Name
                                         ,StageName, CloseDate
                                         ,HasOpportunityLineItem
                                         ,OpportunityId__c
                                         ,Pricebook2Id
                                         ,ProductGroupsSelected__c
                                         ,ProcessNotes__c
                                         ,EvaluateProductGroup__c
                                         ,(select id   // need to select all of the fields of the referral in order to clone
                                                 ,AdditionalProductsOfInterest__c
                                                 ,Referral_End_Date__c
                                                 ,Referral_Partner__r.Evaluate_Product_Of_Interest__c
                                                 ,Referral_Partner__r.Product_Of_Interest_Product_Group__c
                                            ,Referral_Partner__r.Partner_Type__c
                                                 ,Referral_Partner__r.NSS_Source__c
                                                 ,Account__r.name 
                                                 ,Name
                                                 ,Account__c
                                                 ,ActivityDate__c
                                                 ,ActivityDateTime__c
                                                 ,ActivityDateTimeFormatted__c
                                                 ,Activity_Type__c
                                                 ,Amplifinity_Referral__c
                                                 ,Cadence_Touchpoint__c
                                                 ,Campaign__c
                                                 ,Client_Referral__c 
                                                 ,Contact__c
                                                 ,CreateSellerEvent__c
                                                 ,CreateSellerTask__c
                                                 ,DM__c
                                                 ,DSA__c
                                                 ,DSM__c
                                                 ,Email__c
                                                 ,IsAncillary__c
                                                 ,Funnel_Stage__c
                                                 ,MQL_Date_Entered__c
                                                 ,MQL_Date_Exited__c
                                                 ,MQL_Lead_Source__c
                                                 ,MQL_Marketo_Lead_Rating__c
                                                 ,TAL_Date_Entered__c 
                                                 ,TAL_Date_Exited__c
                                                 ,TAL_Lead_Source__c
                                                 ,TAL_Marketo_Lead_Rating__c
                                                 ,Notes__c
                                                 ,Original_Owner_was_Queue__c
                                                 ,OwnerId
                                                 ,PartnerType__c
                                                 ,Potential_for_Multiple_Locations__c
                                                 ,ProcessNotes__c
                                                 ,ProductReferred__c
                                                 ,ReferFromContact__c
                                                 ,ReferralNotes__c
                                                 ,Referral_Account__c
                                                 ,Referral_Contact__c
                                                 ,Referral_Partner__c
                                                 ,ReferringLineItemId__c
                                                 ,Referral_Source__c
                                                 ,Started_From__c
                                                 ,ReferralJoin__c
                                                 ,Referral_Type__c
                                                 ,Referring_Opportunity__c
                                                 ,Referring_User__c
                                                 ,Referral_Approved_Date__c
                                                 ,Referral_Approved_Timeframe__c
                                                 ,SecondaryLeadSource__c
                                                 ,SellingLeadSource__c
                                                 ,SellingOppInfo__c
                                                 ,Selling_Opportunity__c
                                                 ,Send_Email__c
                                                 ,SetOwnerHoldout__c
                                                 ,SourceLead__c
                                                 ,SourceContact__c
                                                 ,Status__c
                                                 ,TimeZoneAbbrev__c
                                                 ,User__c
                                                 ,ZipSegment__c
                                             from Selling_Opps__r 
                                            where Referral_Partner__r.Product_Of_Interest_Product_Group__c != null)
                                         ,(select id,product2.Product_Group__c from OpportunityLineItems where product2.Product_Group__c != null)
                                     from Opportunity where Id in :opptyIds];
       
      Referral__c[] referralsToBeCreated = new Referral__c[]{};
     
      Opportunity[] oppsToUpdate = new Opportunity[]{};
          
      for (Opportunity opp : opptysList) { 
         // the existing product group referrals - so we can see if they match the products
         map<String,Referral__c> refsMaps = new map<String,Referral__c>();
         // used to see if there are existing referrals that need to be ended because no longer products
         map<String,Referral__c> refsMapsDup = new map<String,Referral__c>();
         // if we don't find a referral for a product group, include the groups here.
         Set<String> groupsNotFound = new Set<String>();
         Set<String> groupsFoundSet = new Set<String>();

         // collect the existing product groups for referrals
         for (Referral__c ref: opp.Selling_Opps__r) {
            refsMaps.put(ref.Referral_Partner__r.Product_Of_Interest_Product_Group__c, ref);
            refsMapsDup.put(ref.Referral_Partner__r.Product_Of_Interest_Product_Group__c, ref);
         } // for (Referral__c ref
          
         // check all of the product groups and make sure we have appropriate product groups.
         for (OpportunityLineItem oli: opp.OpportunityLineItems) {
            groupsFoundSet.add(oli.product2.Product_Group__c);
            if (!refsMaps.containsKey(oli.product2.Product_Group__c)) {
               groupsNotFound.add(oli.product2.Product_Group__c);
            } else {
               referral__c ref = refsMaps.get(oli.Product2.Product_Group__c);
               // clear the end date if one exists
               if (ref != null && ref.Referral_End_Date__c != null) {
                  ref.Referral_End_Date__c = null;
                  referralsToUpdate.add(ref);
               }
               // remove it from this map since we found one
               refsMapsDup.remove(oli.product2.Product_Group__c);
            }
         } // for (OpportunityLineItem oli
         
         // if anything is left in the dup map, end date it
         for (Referral__c ref : refsMapsDup.values()) {
            ref.Referral_End_Date__c = System.today();
            referralsToUpdate.add(ref);
         } // for (Referral__c ref : refsMapsDup.values
          
         // create new referrals if a product group is not found
         if(!groupsNotFound.isEmpty()  && !opp.Selling_Opps__r.isEmpty()) {
            referralsToBeCreated.addAll(createReferral(groupsNotFound,opp.Selling_Opps__r[0]));
         }
          
         String[] groupsFoundList = new String[]{};
         groupsFoundList.addAll(groupsFoundSet);
         groupsFoundList.sort();
         String groupsFound = String.join(groupsFoundList,',');
         if (opp.ProductGroupsSelected__c != groupsFound) {
            Opportunity updateOpp = new Opportunity(Id=opp.Id, ProductGroupsSelected__c=groupsFound, ProcessNotes__c=opp.ProcessNotes__c);
            StringHelper.addToProcessNotes(updateOpp,'Changed Prod Grp Selected from '+opp.ProductGroupsSelected__c+' to '+groupsFound);
            oppsToUpdate.add(updateOpp);
         }
      } //for (Opportunity opp : opptysList
       
      ReferralTriggerActions.SKIP_TRIGGER = true;
      OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
      DmlHelper.performDML2(referralsToBeCreated, DmlHelper.DML_INSERT, 'OpptyProducts', 'evaluateProductOfInterestNow', 'Insert Additional Referrals For Product OF Interest', false);
      DmlHelper.performDML2(referralsToUpdate, DmlHelper.DML_Update, 'OpptyProducts', 'evaluateProductOfInterestNow', 'Update Referrals For Product OF Interest', false);
      DmlHelper.performDML2(oppsToUpdate, DmlHelper.DML_Update, 'OpptyProducts', 'evaluateProductOfInterestNow', 'Update Opps', false);
      ErrorLog.checkSave();
   } // evaluateProductOfInterestNow
    
   public static referral__c[] createReferral(set<String> prodOfInterestSet, Referral__c ref) {
      // get all of the partner referrals of the same type
      Referral_Partner__c[] refPartners = ReferralQueries.selectRefPartnersCache(ref.Referral_Partner__r.Partner_Type__c, ref.Referral_Partner__r.NSS_Source__c);

      Referral__c[] newRefs = new Referral__c[]{};
      Map<String,Referral_Partner__c> refPartMap = new Map<String,Referral_partner__c>();
     
      for (Referral_Partner__c refp : refPartners) {
         if(String.isNotBlank(refp.Product_Of_Interest_Product_Group__c)) {
            refPartMap.put(refp.Product_Of_Interest_Product_Group__c,refp);
         }
      } // for (Referral_partner__c refp

      id refJoinForNewPOI = ref.ReferralJoin__c != null ? ref.ReferralJoin__c : createReferralJoin(ref);
      //APR0133426 - CA Mandate - Referral joins
       if(ref.ReferralJoin__c == null){
         ref.ReferralJoin__c =refJoinForNewPOI;
         referralsToUpdate.add(ref);
      }
      for (String prodInterest : prodOfInterestSet) {
         Referral_Partner__c refPart = refPartMap.get(prodInterest);
         if (refPart != null) {
            referral__c refClone = ref.clone(false,false,false,false);
            refClone.ReferralJoin__c = refJoinForNewPOI;
            refClone.Referral_End_Date__c = null;
            refClone.name = CreateOppAndMeeting.getOppName(ref.Account__r.name, refPart.name,ReferralController.REF_NAME_SIZE);
            refClone.Referral_Partner__c = refPart.id;        
            refClone.Referral_Approved_Date__c = DateTime.now();
            refClone.Referral_Approved_Timeframe__c = ref.Referral_Approved_Date__c!=null ? ref.Referral_Approved_date__c.format(Label.CallTime_format,Label.CallTime_TimeZone):DateTime.now().format(Label.CallTime_format,Label.CallTime_TimeZone);
            refClone.Funnel_Stage__c = ref.Funnel_Stage__c;
            refClone.MQL_Date_Entered__c = ref.MQL_Date_Entered__c;
            refClone.MQL_Date_Exited__c = ref.MQL_Date_Exited__c;
            refClone.MQL_Lead_Source__c = ref.MQL_Lead_Source__c;
            refClone.MQL_Marketo_Lead_Rating__c = ref.MQL_Marketo_Lead_Rating__c;
            refClone.TAL_Date_Entered__c = ref.TAL_Date_Entered__c;
            refClone.TAL_Date_Exited__c = ref.TAL_Date_Exited__c;
            refClone.TAL_Lead_Source__c = ref.TAL_Lead_Source__c ;
            refClone.TAL_Marketo_Lead_Rating__c = ref.TAL_Marketo_Lead_Rating__c;
            newRefs.add(refClone);
         }
      }
      return newRefs;
   } // createReferral
        
   public static id createReferralJoin(referral__c ref){
      ReferralJoin__c refJoin = new ReferralJoin__c();
      insert refJoin;
      return refJoin.Id;
   } // createReferralJoin

    private static void createOppLineItem(Opportunity opp, String pricebookEntryId, OpportunityLineItem[] newOlis) {
      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp.Id);
      oli.ServiceDate = opp.CloseDate;
      oli.Status__c = opp.StageName;
      oli.TotalPrice = 0;
      oli.Quantity = 1; 
      oli.Is_Default__c = true;
      oli.PricebookEntryId = pricebookEntryId;
      newOlis.add(oli);
   } // createOppLineItem
      
} // class OpptyProducts