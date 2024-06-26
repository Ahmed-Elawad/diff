/* 
 * Helper class for dealing with Products and Pricebooks.
 *
 * History
 * -------
 * 04/04/2011 Dan Carmen   Created
   11/01/2011 Dan Carmen   Performance enhancements.
   01/12/2012 Dan Carmen   Fix for "always include prods" showing up twice.
   05/16/2012 Dan Carmen   Allow to have multiple sales orgs on prices
   05/30/2012 Dan Carmen   Added logic for Payroll Platform
   11/01/2012 Dan Carmen   Modifications to allow Account clone to calculate revenue
   11/06/2012 Dan Carmen   Fixes for adding CHARGEBACK adjustments
   12/10/2012 Dan Carmen   Fix for Managed Products always displaying Payroll Platform as MMS upon entry.
   02/14/2013 Dan Carmen   Code modifications to reduce script statements.
   11/10/2015 Dan Carmen   Modifications for Quoting tool
   01/29/2015 Jacob Hinds  Added Non-Payroll Units.
   08/12/2016 Carrie Marciano moved "totalRecord.oli.Payroll_Unit__c = null;" and "totalRecord.oli.Non_Payroll_Unit__c = null;" into setupTotalRecord
   08/02/2017 Cindy Freeman   changed checkProductSelector so only sets quantity to 1 if it is null or 0
   11/02/2017 Jacob Hinds  changed how payroll platform picklist is built
   10/11/2018 Carrie Marciano   Updated code to not pull in product pricing when using quoting tool
   08/06/2019 Dan Carmen      Update the delete function to make sure OLIs are unique
   02/28/2020 Jake Hinds    Adding Default Package
   05/29/2020 Jake Hinds    added call to setChildrenToParentFlag in changeShowChildren.  This will calculate defaults for children any time the plus sign is hit
   03/16/2021 Carrie Marciano	Removing call to OpptyProducts.getProdStatus, will now set the prodStatus to the Oppty.StageName
   10/22/2021 Josh Cartwright changed how enter enterRevenueManually is calculated - prod.enterRevenueManually = (prod.entry != null ? !prod.entry.product2.Is_Default_Product__c : true);                
   06/07/2022 Dan Carmen      Change to allow Units field to display for Quote Opportunity
   06/06/2023 Jaipal  APR0152229: FY24 - Non-PR Unit Tracking In Manage Products, invoked checkForNonPayrollUnit in method: setupQuoteProds && buildProdList
   
 */
public with sharing class ProductHelper {
   
   public PriceHelper priceHelper{get; set;}

   /** The sales org for the Opportunity. */
   public String salesOrg{get;set;}
   
   //public ProductQuery productQuery{get;set;}
   
   public static final String STANDALONE='Stand Alone Products';
   
   /** Default constructor.
    */
   public ProductHelper() {
      priceHelper = new PriceHelper();
      //productQuery = new ProductQuery();
      setupTotalRecord();
      
      isShortPkgList = true;
      showProdList = false;
      showAllProducts = false;
      showAllColumns = false;
      readOnly = false;
      includedChildrenExist = false;
      hasRevenueSplit = false;
      hasPayrollUnit = false;
      hasNonPayrollUnit = false;
   } // ProductHelper
   
   public void setupTotalRecord() {
      // setup the total record
      totalRecord = new ProductSelector();
      // create a default line item
      totalRecord.setupLineItem(null);
      totalRecord.selected = true;
      // default these to zero - base them off of the products selected
      totalRecord.maxFreeMonths = 0;
      totalRecord.maxDiscMonths = 0;

      totalRecord.oli.TotalPrice = 0;
      totalRecord.oli.Setup_Fee__c = 0;
      totalRecord.oli.Total_Calced__c = 0;
      totalRecord.oli.Rev_Adj__c = 0;
      totalRecord.maxDiscMonths = 0;
      totalRecord.maxFreeMonths = 0;
      totalRecord.oli.Payroll_Unit__c = null;
      totalRecord.oli.Non_Payroll_Unit__c = null;

   } // setupTotalRecord
   
    public Id pricebookId{get;set;}
   //public Pricebook2 pricebook {get; private set;}
   public Pricebook2 pricebook {
       get {
          Pricebook2 pb = new ProductQuery().getPricebook(pricebookId);
          return pb;
       }
   } // pricebook
   public String quoteToolName = null;
   public Boolean usingQuoteTool{
      get {return String.IsNotBlank(quoteToolName); }
   }
   
   /** A master list of all products and packages. This includes children of parents and can be duplicate entries. */
   public List<ProductSelector> allProdsAndPackages = null;
   /** All packages. */
   public List<ProductSelector> allPackages {get; private set;}
   /** All Standalone products. */
   private List<ProductSelector> allStandaloneProds = null;
   /** A mapping of all of the entries for easy selection. */
   private Map<Id,ProductSelector> allEntryMap = null;
   /** A mapping of all of the Pricebook entries for easy selection. */
   //private Map<Id,PricebookEntry> pricebookEntryMap = null;
   /** The record that contains all of the totals. */
   public ProductSelector totalRecord{get; private set;}
      
   public Pricebook2 getPricebookBySalesOrg(String p_salesOrg) {
      return getPricebook(new ProductQuery().getPricebookNameBySalesOrg(p_salesOrg), null);
   } // getPricebookBySalesOrg

   public Pricebook2 getPricebook(String pricebookName, Id p_pricebookId) {
      System.debug('ProductHelper.getPricebook pricebookName='+pricebookName+' pricebookId='+p_pricebookId);
      Pricebook2 pb = new ProductQuery().getPricebook(pricebookName, p_pricebookId);
      System.debug('ProductHelper.getPricebook pb='+pb);
      if (pb != null) {
         // set this so the code will return the pricebook as needed.
         pricebookId = pb.Id;
      }
      quoteToolName = (pb != null ? pb.Quote_User__c : null);

      setupProducts();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'pricebook='+pricebook+' num prods='+allProdsAndPackages.size()));
      return pb;
   } // getPricebook
      
   /** Are there any packages available? */
   public Boolean hasPackages {
      get {return (allPackages != null && !allPackages.isEmpty()); }
   } // hasPackages
   
   /** Does this have a default product - minimal functionality. */
   public Boolean hasDefaultProd{
     get {return defaultProds != null && !defaultProds.isEmpty(); }
   } // hasDefaultProd
   
   /** The default prodcts (if any). */
   public List<ProductSelector> defaultProds{get;set;}
   
   private ProductSelector[] defaultProdSelectors = new ProductSelector[]{};

   private List<ProductSelector> alwaysIncludeProds = null;
   
   /** The available payroll platforms. If there is only 1, that will be defaulted. If there is more than one,
       the user will be able to select. */
   public List<SelectOption> availPayrollPlatforms{get;set;}
   
   /** Are there multiple payroll platforms available? */
   public Boolean hasMultiplePlatforms{
      get {return availPayrollPlatforms != null && availPayrollPlatforms.size() > 1; }
   } // hasMultiplePlatforms
   
   public void setupProducts() {

      if (!usingQuoteTool) {
         setupAllProdStructure();
         setupLineItems();
         setupSelectedPkg(true);     
         buildProdList(true, true);
      } else {
         setupAllProdStructure();
         setupQuoteProds();
         setupSelectedPkg(true); 
         List<ProductSelector> tempProds = displayProdList;  
         calcAllProds(true);
         
      }


      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'allPackages.size()='+allPackages.size()+' selectedPkg='+selectedPkg+' opptyLineItems.size='+opptyLineItems.size()+' isStandAlone='+isStandAlone));
      
   } // setupProducts

   public Boolean setupAllProdStructure() {
      Boolean okay = true;

      hasNonShortList = false;
      isStandAlone = false;
      
      defaultProds = null;
      
      availPayrollPlatforms = new List<SelectOption>();
      
      // a set of found platforms
      Set<String> payrollPlatformSet = new Set<String>();
      
      // default to the sales org if not already set
      if (oppty != null && oppty.Payroll_Platform__c == null) {
         oppty.Payroll_Platform__c = salesOrg;
         System.debug('ProductHelper setupAllProdStructure oppty is not null and payroll platform is null. set sales org as platform= '+oppty.Payroll_Platform__c);
      }
      
      if(oppty !=null){
        SalesOrg__c socs;
        if(oppty.PriceBook2.Sales_Org__c != null){
          socs = SalesOrg__c.getInstance(oppty.Pricebook2.Sales_Org__c);
                
        }
        if (socs == null && oppty.Pricebook2.Sales_Org2__c != null){
          socs = SalesOrg__c.getInstance(oppty.Pricebook2.Sales_Org2__c);
            
        }
        if (socs != null && String.isNotBlank(socs.Payroll_Platforms__c)) {    
          for(String so : socs.Payroll_Platforms__c.split(';')){
            System.debug('ProductHelper setupAllProdStructure so= '+so); 
            payrollPlatformSet.add(so);
            availPayrollPlatforms.add(new SelectOption(so,so));
          }  
        }
      }
      
      
      /** All of the packages. */
      allPackages = new List<ProductSelector>();
      /** All of the standalone products. */
      allStandaloneProds = new List<ProductSelector>();

      allProdsAndPackages = new List<ProductSelector>(); 
      
      alwaysIncludeProds = new List<ProductSelector>();
      
      // for parents, setup all of their children
      List<Id> parentIds = new List<Id>();
      // set up a map of all entries for easy retrieval when setting up
      allEntryMap = new Map<Id,ProductSelector>();
      Map<Id,PricebookEntry> pricebookEntryMap = new Map<Id,PricebookEntry>();
      System.debug('setupAllProdStructure pricebookId='+pricebookId+' pricebook='+pricebook);
       
      if (pricebook == null) {
         return false;
      }
      
      // find all entries that have a child
      for (PricebookEntry entry : pricebook.PricebookEntries) {
         // all of the entries that have a child, so all link records can be selected at once.
         if (entry.Product2.Has_Child__c) {
            parentIds.add(entry.Product2Id);
         }
         pricebookEntryMap.put(entry.Product2Id,entry);
      } // for (PricebookEntry
      
      // select all parent-child links
      //Product_Parent_Child_Link__c[] allLinks = productQuery.getProductLinks(parentIds, salesOrg);
      Map<Id,List<Product_Parent_Child_Link__c>> productLinksByParentMap = (!usingQuoteTool ? new ProductQuery().getProductLinksByParentMap(parentIds, salesOrg) : new Map<Id,List<Product_Parent_Child_Link__c>>());
      defaultProdSelectors.clear();
      
      
      // loop through all - setup non-dependent products and all children
      for (PricebookEntry entry : pricebook.PricebookEntries) {
         ProductSelector ps = new ProductSelector(entry,oppty);
         if (!entry.Product2.Is_Dependent_Product__c) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupProds1 ps='+ps.getDescription()));
            // check for payroll platform
            /*if (entry.Product2.Payroll_Platform__c != null && !payrollPlatformSet.contains(entry.Product2.Payroll_Platform__c)) {
               payrollPlatformSet.add(entry.Product2.Payroll_Platform__c);
               // TODO - add a different label for readability?
               availPayrollPlatforms.add(new SelectOption(entry.Product2.Payroll_Platform__c,entry.Product2.Payroll_Platform__c));
            }*/
            allProdsAndPackages.add(ps);
            checkForChildren(ps,productLinksByParentMap, pricebookEntryMap);
            // for products always included in the list, no matter what package is selected
            if (entry.Product2.Always_Include__c) {
               alwaysIncludeProds.add(ps);
            }
            // set the match key
         } else if (entry.Product2.Is_Default_Product__c) {
            // set the match key
            defaultProdSelectors.add(ps);
            if (entry.Product2.Has_Child__c) {
               checkForChildren(ps,productLinksByParentMap, pricebookEntryMap);
            }
            // for products always included in the list, no matter what package is selected
            if (entry.Product2.Always_Include__c) {
               alwaysIncludeProds.add(ps);
            }
            
         }
         
      } // for
      System.debug('ProductHelper.setupAllProdStructure allProdsAndPackages='+allProdsAndPackages.size());
      System.debug('ProductHelper.setupAllProdStructure alwaysIncludeProds='+alwaysIncludeProds.size());
      System.debug('ProductHelper.setupAllProdStructure defaultProdSelectors='+defaultProdSelectors.size());      
      return okay;
   } // setupAllProdStructure
   
   // does this have more than one group of products (for multi-id type of situations)
   public Boolean hasGroupedProducts{
      get {return (groupedProdMap != null && groupedProdMap.size() > 1); }
   }
   
   private Map<String,ProductSelector[]> groupedProdMap = new Map<String,ProductSelector[]>();
   
   private Map<String,ProductSelector> allProdsByProdIdMap = new Map<String,ProductSelector>();
   
   public Boolean setupQuoteProds() {
      Boolean okay = true;
      groupedProdMap.clear();
      if (opptyLineItems != null && !opptyLineItems.isEmpty()) {
         for (OpportunityLineItem oli : opptyLineItems) {
            ProductSelector ps = new ProductSelector(oli.PricebookEntry, oppty);
            ps.oli = oli;
            ps.selected = true;
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupQuoteProds ps='+ps.getDescription()+' id='+oli.Id+' ps.prodId='+ps.prodId+' ps.isAdjustment='+ps.isAdjustment));

            if (ps.isAdjustment) {
               // add the adjustment to the existing records
               ProductSelector existingPs = allProdsByProdIdMap.get(ps.oli.Oppty_Product_Id__c);
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupQuoteProds ps='+ps.getDescription()+' id='+oli.Id+' ps.Oppty_Product_Id__c='+ps.oli.Oppty_Product_Id__c+' existingPs='+existingPs));
               if (existingPs != null) {
                  existingPs.addAdjustment(ps);
                  addToTotal(ps);
                  
               }
            } else {
               String groupKey = (oli.QuoteLineGroupAcct__c != null ? String.valueOf(oli.QuoteLineGroupAcct__c) : '__None');
               ProductSelector[] prodList = groupedProdMap.get(groupKey);
               if (prodList == null) {
                  prodList = new ProductSelector[]{};
                  groupedProdMap.put(groupKey,prodList);
               }
               addToTotal(ps);
               prodList.add(ps);
               allProdsByProdIdMap.put(ps.prodId, ps);
            }
         } // for (OpportunityLineItem oli
         //calcAllProds(true);
         checkForPayrollUnit();
         checkForNonPayrollUnit();
      } // if (opptyLineItems != null
      return okay;
   } // setupQuoteProds
   
   // Setup the opportunity line items.
   public Boolean setupLineItems() {
      Boolean okay = true;
      groupedProdMap.clear();
      
      
      // if only one line item check if it's a default product
      // loop through all records created and setup opptyLineItems
      if (opptyLineItems != null && !opptyLineItems.isEmpty()) {
         // for the records that match but will need to be inserted into the list
         ProductSelector[] extraPS = new ProductSelector[]{};
         Integer matchCount = 0;

         // store them in a map for easy lookup
         Map<String, ProductSelector> defaultProdSelectorsMap = new Map<String, ProductSelector>();
         Map<String, ProductSelector> allProdSelectorsMap = new Map<String, ProductSelector>();
         
         integer counter=0;
         // setup matchkey on all records so is only generated once
         for (ProductSelector ps : defaultProdSelectors) {
            ps.setMatchKey();
            defaultProdSelectorsMap.put(ps.matchKey,ps);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupLineItems nbr='+(counter++)+' nbr defaultProdSelectorsMap='+defaultProdSelectorsMap.size()));
         }
         for (ProductSelector ps : allProdsAndPackages) {
            ps.setMatchKey();
            allProdSelectorsMap.put(ps.matchKey,ps);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupLineItems nbr='+(counter++)+' nbr allProdSelectorsMap='+allProdSelectorsMap.size()));
         }
         
         List<ProductSelector> adjustments = new List<ProductSelector>();
         
         // used for generating match keys of the OpportunityLineItems
         ProductSelector tempPs = new ProductSelector();

         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'number lineitems='+opptyLineItems.size()+' nbr allProdSelectorsMap='+allProdSelectorsMap.size()));
         for (OpportunityLineItem oli : opptyLineItems) {
            counter++;
            // generate match key here
            String matchKey = tempPs.getKey(oli.PricebookEntryId,oli.Product_Parent_Child_Link__c,String.valueOf(oli.QuoteLineGroupAcct__c));
            
            System.debug('check opptyLineItems nbr='+counter+' matchKey='+matchKey+' id='+oli.Id+' is default='+oli.PricebookEntry.Product2.Is_Default_Product__c);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'check opptyLineItems nbr='+counter+' matchKey='+matchKey+' id='+oli.Id+' is default='+oli.PricebookEntry.Product2.Is_Default_Product__c));
                        
            // if more than one line item and one is a default product, don't use the default - mark it to be deleted.
            if (oli.PricebookEntry.Product2.Is_Default_Product__c && opptyLineItems.size() > 1) {
               oli.Quantity = 0;
            } else if (oli.PricebookEntry.Product2.Is_Default_Product__c && opptyLineItems.size() == 1 && !defaultProdSelectors.isEmpty()) {
               ProductSelector ps = defaultProdSelectorsMap.get(matchKey);
               //for (Integer cnt=0; cnt<defaultProdSelectors.size(); cnt++) {
                  //ProductSelector ps = defaultProdSelectors.get(cnt);
                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'ps='+ps.entry));
                  if (ps != null && ps.lineItemMatchesProd(oli, matchKey, adjustments)) {
                     if (defaultProds == null) {
                        defaultProds = new List<ProductSelector>();
                     }
                     defaultProds.add(ps);
                     //defaultProdSelectors.remove(cnt);
                     //break;
                  } // if (ps.lineItemMatchesProd
               //} // for (Integer cnt=0)
            } else {
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'oli='+oli));
               // check for adjustment record
               // based on created date, adjustments should always be last in the list, so main adjustment should be created first.
               Boolean isAdjustment = oli.Adj_Type__c != null;
            
               ProductSelector ps = allProdSelectorsMap.get(matchKey);
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'nbr='+counter+' isAdjustment='+isAdjustment+' ps='+ps.getDescription() ));
               
               //for (Integer cnt=0; cnt<allProdsAndPackages.size(); cnt++) {
                  //ProductSelector ps = allProdsAndPackages.get(cnt);
                  //try {
                     if ( ps != null && ps.lineItemMatchesProd(oli, matchKey, adjustments)) {
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'found match for ps='+ps.getDescription()+' selected='+ps.selected ));
                        // if matches, break out of this loop to move to next oli
                        matchCount++;
                        // check for default product - should only ever be one but handle more just in case.
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'default Product='+ps.entry.Product2.Is_Default_Product__c));
                        //break;
                     }
                  //} catch (ProductSelector.FoundAlreadySetException fase) {
                     //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'FoundAlreadySetException name='+ps.getDescription()+' oli='+oli ));
                     // this means that the criteria matches, but there is already a line item set. We will need to create a new ProductSelector
                     //ProductSelector insertPS = new ProductSelector(ps);
                     //insertPS.setupLineItem(oli);

                     // add child to parent if it exists.
                     //if (insertPS.parent != null) {
                     //   insertPS.parent.addChild(insertPS);
                     //}

                     //if (cnt < (allProdsAndPackages.size()-1)) {
                        // if not at the end of the array
                        //allProdsAndPackages.add(cnt,insertPS);
                     //} else {
                        // at the end of the array
                     //   allProdsAndPackages.add(insertPS);
                     //}
                     //matchCount++;
                     //cnt++;
                  //} // try
               //} // for (ProductSelector
            } // if (oli.PricebookEntry.Product2.Is_Default_Product__c
         } // for (OpportunityLineItem
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'defaultProds='+defaultProds));

         // add adjustments
         allProdsAndPackages.addAll(adjustments);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'nbr of allProdsAndPackages='+allProdsAndPackages.size()));
         
         // check to make sure all match (they should!)
         if (matchCount != opptyLineItems.size()) {
            System.debug('Not all opportunity line items could be matched to products! matched='+matchCount+' line items='+opptyLineItems.size());
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Not all opportunity line items could be matched to products! matched='+matchCount+' line items='+opptyLineItems.size()));
         }
         //calcAllProds();
      } // if (opptyLineItems
      return okay;
   } // setupLineItems
   
   /** Set the selected package.
    */
   public Boolean setupSelectedPkg(Boolean setupNullOli) {
      Boolean okay = true;
      System.debug('setupSelectedPkg allProdsAndPackages='+allProdsAndPackages.size());
      for (ProductSelector ps : allProdsAndPackages) {
         // if we want to setup a blank OpportunityLineItem on all ProductSelector records
         if (setupNullOli && ps.oli == null) {
            ps.setupLineItem(null);
         } else {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'oli already found for '+ps.getDescription()));
         }
         
         if (ps.entry.Product2.Is_Package__c && !ps.isAdjustment) {
            allPackages.add(ps);
            System.debug('setupSelectedPkg ps='+ps+' entry='+(ps.entry != null));
            if (!ps.entry.Product2.In_Short_List__c) {
               hasNonShortList = true;
            }
            if(ps.entry.Product2.Default_Package__c){
               selectedPkg = ps;
            }
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'ps='+ps.getDescription()+' ps.selected='+ps.selected+' ps.hasSelectedChildren()='+ps.hasSelectedChildren()));
            // if a package is already selected or has children that were selected
            if (ps.selected || ps.hasSelectedChildren()) {
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'ps='+ps.getDescription()+' ps.selected='+ps.selected+' ps.hasSelectedChildren()='+ps.hasSelectedChildren()));
               // have to determine which list to default to
               isShortPkgList = ps.entry.Product2.In_Short_List__c;
               selectedPkg = ps;
               selectedPkgOption = ps.entry.Product2.ProductCode;
               checkForRevenueSplit(selectedPkg);
            }
         } else {
            // check to see if is a child of another
            if (!ps.isChild) {
               allStandaloneProds.add(ps);
            }
         } // if
         
      } // for (ProductSelector
            
      
      // if there are packages, there are currently products on the opportunity, and a package is not selected, assume standalone
      if ((allPackages.size() == 0) || (!hasDefaultProd && selectedPkg == null && opptyLineItems != null && !opptyLineItems.isEmpty())) {
         isStandAlone = true;
      }
      return okay;
   } // setupSelectedPkg
   
   /** Does the selected package have a revenue split with its child products? */
   public Boolean hasRevenueSplit{get; set;}
   
   /** Check if the passed in product has a revenue split with its children products.
    */
   public Boolean checkForRevenueSplit(ProductSelector pkg) {
      hasRevenueSplit = false;
      if (pkg != null && pkg.hasChildren) {
         for (ProductSelector ps : pkg.childProducts) {
            // if products have a revenue split (and is included in price), take percentage from original calculated package amount
            if (ps.includedInParentPrice && (ps.prodLink.Rev_Allocation_Setup__c != null ||
                                             ps.prodLink.Rev_Allocation_Weekly__c != null ||
                                             ps.prodLink.Rev_Allocation_BW_SM__c != null ||
                                             ps.prodLink.Rev_Allocation_Monthly__c != null)) {
               hasRevenueSplit = true;
               break;
            } // if
         } // for (ProductSelector
      } // if (ps != null
      return true;
   } // checkForRevenueSplit
   
   /** Does the product selection have payroll units available? */
   public Boolean hasPayrollUnit{get;set;}
   
   /** Does the product selection have non-payroll units available? */
   public Boolean hasNonPayrollUnit{get;set;}   
   
   /** Are there packages that are not in the short list? */
   public Boolean hasNonShortList{get;set;}
   
   /** Recursive call to check for children for a record. 
    */
   public void checkForChildren(ProductSelector ps, Map<Id,List<Product_Parent_Child_Link__c>> productLinksByParentMap, Map<Id,PricebookEntry> pricebookEntryMap) {
      if (ps.entry.Product2.Has_Child__c) {
         List<Product_Parent_Child_Link__c> productLinksList = productLinksByParentMap.get(ps.entry.Product2Id);
         if (productLinksList != null && !productLinksList.isEmpty()) {
            // get the package id
            Id pkgId = ps.getPackageId();
            for (Product_Parent_Child_Link__c ppcl : productLinksList) {
               // if there's a product group that has to match the parent also
               if ((ppcl.Product_Group__c == null && pkgId == null) ||
                   (ppcl.Product_Group__c != null && pkgId != null &&
                    ppcl.Product_Group__c == pkgId)) {
                  PricebookEntry entry = pricebookEntryMap.get(ppcl.Child_Product__c);
                  if (entry != null) {
                     ProductSelector childPs = ps.addChild(entry, ppcl);
                     //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupProds2 childPs='+childPs.getDescription()));
                     allProdsAndPackages.add(childPs);
                     // see if the children have children
                     checkForChildren(childPs,productLinksByParentMap, pricebookEntryMap);
                  } else {
                     if (!System.isBatch()) {
                        System.debug('ProductHelper.checkForChildren pkgId='+pkgId+' product group='+ppcl.Product_Group__c+' child product='+ppcl.Child_Product__c);                        
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Could not find PricebookEntry for '+ppcl.Child_Product_Code__c+' id='+ppcl.Child_Product__c));
                     }
                  }
               } // if ((ppcl.Product_Group__c
            } // for (Product_Parent_Child_Link__c ppcl
            
         } // if (productLinksList != null
      } // if (ps.entry.Product2.Has_Child__c
   } // checkForChildren
   
   /** Does at least one product have discounting? */
   public Boolean hasDiscounting{get; set;}
   
   /** Build the product list of all products displayable on the form.
    * If the opportunity is closed, only include the records that have been saved (oli.Id != null)
    *
    * @param showAllProds true to show all products or false to hide products included as part of a package
    */
   public Boolean buildProdList(Boolean initialSetup, Boolean performCalc) {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'In buildProdList'));
      Boolean okay = true;
      includedChildrenExist = false;
      
      prodList = new List<ProductSelector>();
      // keep track of products added to list as part of the package to make sure they're not added a second time.
      Map<Id,Id> prodsInPkg = new Map<Id,Id>();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'selectedPkg='+(selectedPkg!=null)));
      if (selectedPkg != null) {
         prodList.add(selectedPkg);
         selectedPkg.addAdjustments(prodList);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'selectedPkg name='+selectedPkg.getDescription()+' hasChildren='+selectedPkg.hasChildren+' size='+prodList.size()));
         // if there are children in the package,
         if (selectedPkg.hasChildren) {
            includedChildrenExist = selectedPkg.hasIncludedChildren();
            
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in hasChildren size='+prodList.size()));
            selectedPkg.getDisplayChildren(prodList);
            // go through the children to add the ones not included in price
            for (ProductSelector prod : selectedPkg.childProducts) {
               if (!prod.IsAdjustment && !prod.showAsChild) {
                  prodList.add(prod);
                  prod.addAdjustments(prodList);
                  prod.getDisplayChildren(prodList);
               } // if (!prod.showAsChild
            } // for (ProductSelector
            
         } // if (selectedPkg.hasChildren

         // add products
      } else if (allStandaloneProds != null) { 

         // go through the list of products, adding in the rest
         for (ProductSelector prod : allStandaloneProds) {
            // if the product has not already been added, then add it.
            if (((oppty != null && oppty.Payroll_Platform__c == null) 
                 || prod.entry.Product2.Payroll_Platform__c == null
                 || (oppty != null && oppty.Payroll_Platform__c != null && prod.entry.Product2.Payroll_Platform__c != null &&
                    oppty.Payroll_Platform__c == prod.entry.Product2.Payroll_Platform__c))
                && (!prodsInPkg.containsKey(prod.entry.Product2.Id) && !prod.entry.Product2.Always_Include__c)) {
//               if ((opptyIsClosed && (prod.prodIsSaved || prod.hasSavedChildren())) || !opptyIsClosed) {
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'adding '+prod.getDescription()+' hasChildren='+prod.hasChildren));
                  prodList.add(prod);
                  prod.addAdjustments(prodList);
                  if (prod.hasChildren) {
                     //if (opptyIsClosed) {
                     //   prod.getSavedChildren(prodList);
                     //} else {
                        prod.getDisplayChildren(prodList);
                     //}
                  }
//               } // if ((opptyIsClosed 
            }
         } // for
      } // if (selectedPkg != null
      
      if (alwaysIncludeProds != null && !alwaysIncludeProds.isEmpty()) {
         prodList.addAll(alwaysIncludeProds);
      }
      if (performCalc) {
         calcAllProds(initialSetup);

         // add the total record to the end of the list
         //prodList.add(totalRecord);

      } // if (performCalc
      checkForPayrollUnit();
      checkForNonPayrollUnit();
      return okay;
   } // buildProdList

   /** Check all products in the product list to see if there's at least one product that
       has a payroll unit. 
    */
   public Boolean checkForPayrollUnit() {
      ProductSelector[] checkList = (prodList == null ? displayProdList : prodList);
      System.debug('checkForPayrollUnit prodList='+(prodList != null ? prodList.size() : -1)+' checkList='+(checkList != null ? checkList.size() : -1));
      hasPayrollUnit = false;
      if (checkList != null) {
           
      for (ProductSelector prod: checkList) {
         //System.debug('checkForPayrollUnit entryId='+prod.entryId+' prod.hasEntry='+prod.hasEntry);
         if (prod.hasEntry && prod.entry.Product2.Is_Payroll_Unit__c) {
            //System.debug('checkForPayrollUnit hasPayrollUnit1');
            hasPayrollUnit = true;
            break;
         } else if (prod.hasEntry && prod.hasChildren) {
            // loop through the children and see if any children have a unit
            for (ProductSelector childProd : prod.childProducts) {
               if (childProd.hasEntry && childProd.entry.Product2.Is_Payroll_Unit__c) {
            //System.debug('checkForPayrollUnit hasPayrollUnit2');
                  hasPayrollUnit = true;
                  break;
               }
            } // for (ProductSelector childProd
         }
      } // for (ProductSelector prod
      }
      return true;
   } // checkForPayrollUnit
   
   /** Check all products in the product list to see if there's at least one product that
       has a payroll unit. 
    */
   public Boolean checkForNonPayrollUnit() {
      hasNonPayrollUnit = false;
      if (prodList != null) {
           
      for (ProductSelector prod: prodList) {
         if (prod.hasEntry && prod.entry.Product2.Is_Non_Payroll_Unit__c) {
            hasNonPayrollUnit = true;
            break;
         } else if (prod.hasEntry && prod.hasChildren) {
            // loop through the children and see if any children have a unit
            for (ProductSelector childProd : prod.childProducts) {
               if (childProd.hasEntry && childProd.entry.Product2.Is_Non_Payroll_Unit__c) {
                  hasNonPayrollUnit = true;
                  break;
               }
            } // for (ProductSelector childProd
         }
      } // for (ProductSelector prod
      } // if (prodList != null
      return true;
   } // checkForPayrollUnit
   
   public final static String SELECT_PKG='--Select a Package--';

   /** Get the package options displayed on the screen. */  
   public List<SelectOption> pkgOptions{
      get {
         List<ProductSelector> pkgs = allPackages;
         if (isShortPkgList) {
            pkgs = new List<ProductSelector>();
            for (ProductSelector ps : allPackages) {
               if (ps.entry.Product2.In_Short_List__c) {
                  pkgs.add(ps);
               }
            } // for (ProductSelector ps : allPackages
         } // if (isShortPkgList
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption(SELECT_PKG,SELECT_PKG));
         options.add(new SelectOption(STANDALONE,STANDALONE));

         // only add the ones that match the payroll platform. If null, always add.
         for (ProductSelector pkg : pkgs) {
            if (oppty.Payroll_Platform__c == null 
                || pkg.entry.Product2.Payroll_Platform__c == null
                || (oppty.Payroll_Platform__c != null && pkg.entry.Product2.Payroll_Platform__c != null &&
                    oppty.Payroll_Platform__c == pkg.entry.Product2.Payroll_Platform__c)) {
               options.add(new SelectOption(pkg.entry.Product2.ProductCode,pkg.entry.Product2.Name));
            } // if
         } // for (ProductSelector
         return options;
      } // get
   } // pkgOptions
   
   public Boolean isShortPkgList{get; set;}
   
   /** Are packages available for display? */
   public Boolean packagesAvailable{
      get {return (allPackages != null && allPackages.size() > 0); }
   } // packagesAvailable
   
   /** Deselect all existing selections, give user the package picklist.
    *  If saved records existed, add them to the delete list and create a new line item.
    */
   public PageReference changePackage() {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'In changePackage'));
    
      isStandAlone = false;
      hasRevenueSplit = false;
      selectedPkg = null;
      selectedPkgOption = null;
      // deselect all products
      for (ProductSelector ps : allProdsAndPackages) {
         /*
         if (ps.oli != null) {
            // if the OpportunityLineItem was already saved, add to delete queue and create a new record.
            if (ps.oli.Id != null) {
               oliDelete.add(ps.oli);
               // remove the old record
               ps.oli = null;
               // create a new line item
               ps.setupLineItem(null);
            }
            ps.oli.Quantity = 0;
         } // if (ps.oli != null
         */
         ps.resetProd();
      } // for (ProductSelector ps : allProdsAndPackages
      //setPkg();
      return null;
   } // changePackage
   
   public Boolean isStandAlone{get;set;}
   
   public ProductSelector selectedPkg{get; private set;}
   
   /** Get the name of the selected package.
    */
   public String selectedPkgName{
      get {
         if (selectedPkg != null) {
            return selectedPkg.entry.Name;
         } else if (isStandAlone) {
            return STANDALONE;
         }
         return '';
      }
   } // selectedPkgName
   
   public Boolean pkgSelected {
      get {
         return (selectedPkg != null || isStandAlone);
      }
   } // pkgSelected
   
   /** Recalculate all of the products.
    */
   public Boolean calcAllProds(Boolean initialScreenEntry) {
      // reset the discounting flag
      hasDiscounting = false;
       //Set of all entry id's
      set <String> entryIdSet = new set<String>();
      Boolean allOkay = true;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'calcAllProds prodList='+(prodList != null && !prodList.isEmpty())));
      if (prodList != null && !prodList.isEmpty() && allProdsAndPackages != null) {
         // clear total record
         system.debug('ProductHelper calcAllProds before setupTotalRecord');
          setupTotalRecord();
         
         // the sales org to use for calculation purposes
         //String calcSalesOrg = (oppty != null && oppty.Payroll_Platform__c != null ? oppty.Payroll_Platform__c : salesOrg);
         String calcSalesOrg = salesOrg;
         system.debug('ProductHelper calcAllProds calcSalesOrg: '+calcSalesOrg);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'calcAllProds Starting loop through prodList'));
         
         for (ProductSelector prod : prodList) {
            if (!prod.isClosed && prod.hasEntry && !calculateTotal(prod,calcSalesOrg,initialScreenEntry)) {
               allOkay = false;
            }
            
            if (prod.hasEntry && totalRecord != null && !prod.pricingExistsButDoesntMatch) {
               addToTotal(prod);
                entryIdSet.add(prod.entryId);
            }
         } // for (ProductSelector
         
         // this is the status for the products based on the status of the Opportunity
         String prodStatus = (oppty != null ? oppty.StageName : null);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'prodStatus='+prodStatus ));
         system.debug('ProductHelper calcAllProds prodStatus: '+prodStatus);
          
         // get the payroll units - the payroll product isn't always displayed
         for (ProductSelector prod : allProdsAndPackages) {
            if(!(entryIdSet.contains(prod.entryId)))
            {
                if (prod.selected && prod.oli.Payroll_Unit__c != null) {
                    totalRecord.oli.Payroll_Unit__c = Utilities.nvl(totalRecord.oli.Payroll_Unit__c) + prod.oli.Payroll_Unit__c;
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'*** ProductHelper*** In For(ProductSelector loop). totalRecord.oli.Payroll_Unit__c= '+totalRecord.oli.Payroll_Unit__c));
                }
                if (prod.selected && prod.oli.Non_Payroll_Unit__c != null) {
                    totalRecord.oli.Non_Payroll_Unit__c = Utilities.nvl(totalRecord.oli.Non_Payroll_Unit__c) + prod.oli.Non_Payroll_Unit__c;
                }
            }

            // check that date and status match oppty
            if (!initialScreenEntry) {
               if (prod.selected && !prod.oli.User_Override__c) {
                  prod.oli.ServiceDate = oppty.CloseDate;
                  if (prodStatus != null) {
                     prod.oli.Status__c = prodStatus;
                  }
               }
            } // if (!initialScreenEntry
            
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prod='+prod.getDescription()+' is payroll='+prod.entry.Product2.Is_Payroll_Unit__c+' qty='+prod.oli.Quantity+' total payroll unit='+totalRecord.oli.Payroll_Unit__c));
            //totalRecord.payrollUnits += (prod.entry.Product2.Is_Payroll_Unit__c ? Utilities.nvl(prod.oli.Quantity).intValue() : 0);
            if (!prod.isClosed && !initialScreenEntry) {
               // check for Revenue adjustment
               if (prod.selected && prod.parent != null && prod.parent.selected && prod.prodLink != null && 
                   prod.prodLink.Rev_Adj_If_Parent_And_Child__c != null && 
                   prod.parent.oli.TotalPrice != null ) {
                  // remove revenue adjustment (if any);
                  Decimal checkRev = prod.parent.oli.TotalPrice - Utilities.nvl(prod.parent.oli.Rev_Adj__c);
                  Decimal revChange = (checkRev * (prod.prodLink.Rev_Adj_If_Parent_And_Child__c/100)).setScale(2);
                  String debugMsg = 'prod='+prod.getDescription()+' origRev='+prod.parent.oli.TotalPrice+' checkRev='+checkRev+' revChange='+revChange+' childRev='+prod.oli.TotalPrice;
                  System.debug(debugMsg);
                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,debugMsg ));
                  // add amount to child record
                  prod.oli.TotalPrice = Utilities.nvl(prod.oli.TotalPrice) + revChange;
                  totalRecord.oli.TotalPrice += Utilities.nvl(revChange);
               } // if
            } // if (!initialScreenEntry
         } // for (ProductSelector
         System.debug('***ProductHelper*** out of For(ProductSelector loop). totalRecord.oli.Payroll_Unit__c= '+totalRecord.oli.Payroll_Unit__c);
         // if there's a package, see if there's a revenue split
         
         if (!initialScreenEntry && hasRevenueSplit) {
            checkRevenueSplit();
         }
      } // if (prodList != null
      return allOkay;
   } // calcAllProds

   /** Add the passed in record to the total record.
    */
   public Boolean addToTotal(ProductSelector prod) {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prod='+prod.getDescription()+' TotalPrice='+prod.oli.TotalPrice));
      if (totalRecord != null && prod != null && prod.oli != null) {
         totalRecord.oli.TotalPrice += Utilities.nvl(prod.oli.TotalPrice,0);
         totalRecord.oli.Setup_Fee__c += Utilities.nvl(prod.oli.Setup_Fee__c,0);
         totalRecord.oli.Total_Calced__c += Utilities.nvl(prod.oli.Total_Calced__c,0);
         totalRecord.oli.Rev_Adj__c += Utilities.nvl(prod.oli.Rev_Adj__c,0);
         System.debug('***ProductHelper*** prod.oli.Payroll_Unit__c='+prod.oli.Payroll_Unit__c);
         if (prod.oli.Payroll_Unit__c != null) {
            totalRecord.oli.Payroll_Unit__c = Utilities.nvl(totalRecord.oli.Payroll_Unit__c,0) + Utilities.nvl(prod.oli.Payroll_Unit__c,0);
         }
         if (prod.oli.Non_Payroll_Unit__c != null) {
            totalRecord.oli.Non_Payroll_Unit__c = Utilities.nvl(totalRecord.oli.Non_Payroll_Unit__c,0) + Utilities.nvl(prod.oli.Non_Payroll_Unit__c,0);
         }
         System.debug('***ProductHelper*** totalRecord.oli.Payroll_Unit__c='+totalRecord.oli.Payroll_Unit__c);
      } // if (totalRecord
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prod='+prod.getDescription()+' totalRecord='+totalRecord.oli.TotalPrice));
      return true;
   } // addToTotal

   /** Check if there's a revenue split between a package and its included products.
    */
   public boolean checkRevenueSplit() {
      // if there's a package, see if there's a revenue split
      if (selectedPkg != null && selectedPkg.selected && selectedPkg.hasChildren) {
         Decimal splitSetup = 0;
         Decimal splitRev = 0;
         Integer opptyFreq = getOpptyFreq();
         // loop through child products
         for (ProductSelector ps : selectedPkg.childProducts) {
            // if products have a revenue split (and is included in price), take percentage from original calculated package amount
            if (ps.oli != null && ps.includedInParentPrice &&
                   (ps.selected || (!ps.selected && !ps.hasRemovePrice))) {
               ps.oli.Setup_Fee__c = null;
               ps.oli.TotalPrice = 0;
               // if has a setup fee allocation
               if (ps.selected) {
                  if (ps.prodLink != null && selectedPkg.oli.Setup_Fee__c != null && ps.prodLink.Rev_Allocation_Setup__c != null) {
                     ps.oli.Setup_Fee__c = (selectedPkg.oli.Setup_Fee__c * (ps.prodLink.Rev_Allocation_Setup__c/100)).setScale(2);
                     splitSetup += ps.oli.Setup_Fee__c;
                     //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prod='+ps.getDescription()+' splitSetup='+splitSetup));
                  }
                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prod='+ps.getDescription()+' opptyFreq='+opptyFreq+' Annual='+selectedPkg.oli.Annual_Base_Trans_Disc__c+' weekly='+ps.prodLink.Rev_Allocation_Weekly__c+' BW='+ps.prodLink.Rev_Allocation_BW_SM__c+' monthly='+ps.prodLink.Rev_Allocation_Monthly__c));
                  if (ps.prodLink != null && selectedPkg.oli.Annual_Base_Trans_Disc__c != null && 
                      (opptyFreq == 52 && ps.prodLink.Rev_Allocation_Weekly__c != null)) {
                     // weekly allocation
                     ps.oli.TotalPrice = (selectedPkg.oli.Annual_Base_Trans_Disc__c * (ps.prodLink.Rev_Allocation_Weekly__c/100)).setScale(2)+Utilities.nvl(ps.oli.Setup_Fee__c);
                     splitRev += ps.oli.TotalPrice;
                     //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prod='+ps.getDescription()+' weekly splitRev='+splitRev));
                  } else if (ps.prodLink != null && selectedPkg.oli.Annual_Base_Trans_Disc__c != null && 
                      ((opptyFreq == 26 || opptyFreq == 24) && ps.prodLink.Rev_Allocation_BW_SM__c != null)) {
                     // bi-weekly/semi-monthly allocation
                     ps.oli.TotalPrice = (selectedPkg.oli.Annual_Base_Trans_Disc__c * (ps.prodLink.Rev_Allocation_BW_SM__c/100)).setScale(2)+Utilities.nvl(ps.oli.Setup_Fee__c);
                     splitRev += ps.oli.TotalPrice;
                     //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prod='+ps.getDescription()+' BW_SM splitRev='+splitRev));
                  } else if (ps.prodLink != null && selectedPkg.oli.Annual_Base_Trans_Disc__c != null && 
                      (opptyFreq == 12 && ps.prodLink.Rev_Allocation_Monthly__c != null)) {
                     // monthly allocation
                     ps.oli.TotalPrice = (selectedPkg.oli.Annual_Base_Trans_Disc__c * (ps.prodLink.Rev_Allocation_Monthly__c/100)).setScale(2)+Utilities.nvl(ps.oli.Setup_Fee__c);
                     splitRev += ps.oli.TotalPrice;
                     //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prod='+ps.getDescription()+' monthly splitRev='+splitRev));
                  }
               } // if (ps.selected
            } // if (ps.includedInParentPrice
         } // for (ProductSelector
         // after going through all products, update the package to the new amount.
         if (splitSetup > 0 || splitRev > 0) {
            if (splitSetup != 0) {
               selectedPkg.oli.Setup_Fee__c = Utilities.nvl(selectedPkg.oli.Setup_Fee__c) - splitSetup;
            }
            selectedPkg.oli.TotalPrice -= (splitSetup + splitRev);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prod='+selectedPkg.getDescription()+' setupFee='+selectedPkg.oli.Setup_Fee__c+' TotalPrice='+selectedPkg.oli.TotalPrice));
         }
      } // if (selectedPkg
      return true;
   } // checkRevenueSplit
   
   /** Calculate the total for the product.
    */
   public Boolean calculateTotal(ProductSelector prod, String calcSalesOrg, Boolean initialScreenEntry) {
      // default these flags to false
      prod.hasPricingInfo = false;
      prod.enterRevenueManually = false;
      prod.pricingExistsButDoesntMatch = false;
      
      if (prod.selected && !prod.isAdjustment) {
          system.debug('ProductHelper calculateTotal prod.selected and not adjustment: '+prod.name);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'calculateTotal isSelected and !isAdjustment prod='+prod.getDescription()));
         // need to have a quantity to calculate - default to 1 for now?? - should already have a value
         if (prod.oli.Unit__c == null) {
            prod.oli.Unit__c = 1;
            //prod.oli.Unit__c.addError('Value must be populated for '+prod.entry.Name+' to proceed!');
            //return false;
         }
         if (!prod.includedInParentPrice) {
             system.debug('ProductHelper calculateTotal not prod.includedInParentPrice. prod.pricingProdCode: '+prod.pricingProdCode);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'calculateTotal prod='+prod.getDescription()+' prod.includedInParentPrice'));
            if (!usingQuoteTool && (priceHelper.calcPrice(prod.pricingProdCode, calcSalesOrg, getOpptyFreq(), prod.oli.Unit__c.intValue()
                                     ,prod.oli.Discount_Free_Months__c,prod.oli.Discount_Percent__c,prod.oli.Discount_Months__c))) {
               // price information was found
               prod.hasPricingInfo = true;
               system.debug('ProductHelper calculateTotal prod.hasPricingInfo= '+prod.hasPricingInfo);                          
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'calculateTotal prod='+prod.getDescription()+' hasPricingInfo='+prod.hasPricingInfo));
               // if initial screen entry do not change any values
               if (!initialScreenEntry) {
                  prod.oli.Price_Schedule__c = priceHelper.baseRecord.Pricing_Schedule__c;
                  prod.oli.Frequency__c = priceHelper.annualFrequency;
                  prod.oli.Base_Fee__c = priceHelper.baseFee;
                  prod.oli.Transaction_Fee__c = priceHelper.transactionFee;
                  prod.oli.Non_Discount_Price_Per_Frequency__c = priceHelper.baseFee + priceHelper.transactionFee;
               } // if (!initialScreenEntry
               
               // discount information
               prod.maxDiscMonths = ((priceHelper.discountPctAllowed != null) ? 12 : 0);
               prod.maxFreeMonths = priceHelper.discountFreeMonthsAllowed;

               // check to see if max records are greater than total record - set total record to the max available of all products
               totalRecord.maxDiscMonths = ((prod.discPctAllowed && prod.maxDiscMonths > totalRecord.maxDiscMonths) ? prod.maxDiscMonths : totalRecord.maxDiscMonths);
               totalRecord.maxFreeMonths = ((prod.freeMonthsAllowed && prod.maxFreeMonths > totalRecord.maxFreeMonths) ? prod.maxFreeMonths : totalRecord.maxFreeMonths);
               
               if (!initialScreenEntry) {
                  prod.oli.Discount_Free_Months__c = priceHelper.discountFreeMonthsSet;
                  prod.oli.Discount_Months__c = priceHelper.discountMonthsSet;
                  prod.oli.Discount_Percent__c = priceHelper.discountPctSet;
                  prod.oli.Discount_Annualized__c = priceHelper.discountPctAnnualized;
               
                  // get the discounted amount
                  Decimal discountAmtPerFreq = 0;
                  if (priceHelper.discountPctAnnualized != null) {
                     discountAmtPerFreq = (prod.oli.Non_Discount_Price_Per_Frequency__c * (priceHelper.discountPctAnnualized/100) * 100).round(System.RoundingMode.HALF_UP);
                     discountAmtPerFreq = discountAmtPerFreq/100;
                  } // if (priceHelper.discountPctAnnualized

                  // the price per frequency including any discounts
                  prod.oli.Price_Per_Frequency__c = prod.oli.Non_Discount_Price_Per_Frequency__c - discountAmtPerFreq;
               } // if (!initialScreenEntry
               
               //prod.hasSetupFee = priceHelper.hasSetupFee;
               prod.hasEnterableSetupFee = priceHelper.hasSetupFee;
               
               prod.setupFeeOptions = null;
               // if there is a picklist for the setup fee, 
               if (priceHelper.setupFeeOptions != null && !priceHelper.setupFeeOptions.isEmpty()) {
                  prod.setupFeeOptions = new List<SelectOption>(); 
                  for (String setupFee : priceHelper.setupFeeOptions) {
                     prod.setupFeeOptions.add(new SelectOption(setupFee,setupFee));
                  }
               } // if
               
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,prod.getDescription()+' prod.unitChanged='+prod.unitChanged));
               
               // only set these the first time or if setup fee is tiered and quantity changes
               if (!prod.initialCalcPerformed || (priceHelper.setupFeeTieredPricing && prod.unitChanged)) {
                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,prod.getDescription()+' setting setup fee!='+priceHelper.setupFee));
                  prod.oli.Setup_Fee_Original__c = priceHelper.setupFee;
                  prod.oli.Setup_Fee__c = priceHelper.setupFee;
               }
               
               if (!initialScreenEntry) {
                  // annual price without the setup fee
                  prod.oli.Annual_Base_and_Trans__c = (((Utilities.nvl(prod.oli.Frequency__c) * Utilities.nvl(prod.oli.Non_Discount_Price_Per_Frequency__c)))*100).round(System.RoundingMode.HALF_UP);
                  prod.oli.Annual_Base_and_Trans__c = prod.oli.Annual_Base_and_Trans__c/100;
                  // discounted annual price without the setup fee
                  prod.oli.Annual_Base_Trans_Disc__c = (((Utilities.nvl(prod.oli.Frequency__c) * Utilities.nvl(prod.oli.Price_Per_Frequency__c)))*100).round(System.RoundingMode.HALF_UP);
                  prod.oli.Annual_Base_Trans_Disc__c = prod.oli.Annual_Base_Trans_Disc__c/100;
                  
                  // get the non-discounted annualized price
                  prod.oli.Non_Discounted_Price__c = (((Utilities.nvl(prod.oli.Frequency__c) * Utilities.nvl(prod.oli.Non_Discount_Price_Per_Frequency__c)) + Utilities.nvl(prod.oli.Setup_Fee__c))*100).round(System.RoundingMode.HALF_UP);
                  prod.oli.Non_Discounted_Price__c = prod.oli.Non_Discounted_Price__c/100;
               
                  // get the discounted annualized price
                  prod.oli.Discounted_Annual_Price__c = (((Utilities.nvl(prod.oli.Frequency__c) * Utilities.nvl(prod.oli.Price_Per_Frequency__c)) + Utilities.nvl(prod.oli.Setup_Fee__c))*100).round(System.RoundingMode.HALF_UP);
                  prod.oli.Discounted_Annual_Price__c = prod.oli.Discounted_Annual_Price__c/100;

                  // check if there a price-revenue adjustment
                  prod.oli.Rev_Adj_Calcd__c = 0;
                  Decimal revAdj = 0;
                  if (priceHelper.baseRecord.Price_Revenue_Adj__c != null) {
                     revAdj = (priceHelper.baseRecord.Price_Revenue_Adj__c * Utilities.nvl(prod.oli.Frequency__c));
                     //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prod='+prod.getDescription()+' revAdj='+revAdj));
                  }

                  // get the non-discounted revenue credited to the rep
                  prod.oli.Non_Discounted_Revenue__c = prod.oli.Non_Discounted_Price__c + revAdj;
               
                  // if the rep only gets a percentage of the revenue
                  Decimal revAdjPct = (priceHelper.baseRecord.Revenue_Pct__c != null ? priceHelper.baseRecord.Revenue_Pct__c : null);
               
                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prod='+prod.getDescription()+' nonDiscRev='+prod.oli.Non_Discounted_Revenue__c+' revAdjPct='+revAdjPct));
                  if (revAdjPct != null) {
                     prod.oli.Non_Discounted_Revenue__c = (prod.oli.Non_Discounted_Revenue__c*revAdjPct).round(System.RoundingMode.HALF_UP);
                     prod.oli.Non_Discounted_Revenue__c = prod.oli.Non_Discounted_Revenue__c/100;
                     //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'after revAdjPct prod='+prod.getDescription()+' nonDiscRev='+prod.oli.Non_Discounted_Revenue__c));
                  }
                  prod.oli.Non_Discounted_Revenue__c += Utilities.nvl(prod.oli.Rev_Adj__c);
               
                  // get the discounted revenue credited to the rep
                  // discounted revenue adjustment
                  revAdj = (revAdj - (revAdj*(Utilities.nvl(prod.oli.Discount_Annualized__c)/100))).setScale(2);
                  // Use TotalPrice for the estimated revenue the rep will receive 
                  prod.oli.TotalPrice = prod.oli.Discounted_Annual_Price__c + revAdj;
                  if (revAdjPct != null) {
                     prod.oli.TotalPrice = (prod.oli.TotalPrice*revAdjPct).round(System.RoundingMode.HALF_UP);
                     prod.oli.TotalPrice = prod.oli.TotalPrice/100;
                  }
                  prod.oli.TotalPrice += Utilities.nvl(prod.oli.Rev_Adj__c);
                  // store the estimated revenue elsewhere so it will not be overwritten
                  prod.oli.Estimated_Revenue__c = prod.oli.TotalPrice;
               
                  // get the total price
                  prod.oli.Total_Calced__c = (((Utilities.nvl(prod.oli.Frequency__c) * Utilities.nvl(prod.oli.Price_Per_Frequency__c)) + Utilities.nvl(prod.oli.Setup_Fee__c))*100).round(System.RoundingMode.HALF_UP);
                  prod.oli.Total_Calced__c = prod.oli.Total_Calced__c/100;
               
               } // if (!initialScreenEntry
            } else {
               //prod.enterRevenueManually = priceHelper.enterRevenueManually;
               //prod.hasEnterableSetupFee = priceHelper.hasSetupFee;
               //prod.pricingExistsButDoesntMatch = priceHelper.pricingExistsButDoesntMatch;

               prod.enterRevenueManually = (prod.entry != null ? !prod.entry.product2.Is_Default_Product__c : true);                
               
                prod.pricingExistsButDoesntMatch = false;
               prod.hasEnterableSetupFee = false; 
               system.debug('ProductHelper calculateTotal prod.enterRevenueManually: '+prod.enterRevenueManually);
               if (prod.pricingExistsButDoesntMatch) {
                 // clear out fields
                 prod.clearLineItem();
                 prod.hasEnterableSetupFee = false;
               }
            } // if (priceHelper.calcPrice
            
            prod.initialCalcPerformed = true;
         } else {
            if (!initialScreenEntry) {
               prod.oli.TotalPrice = null;
            }
            
         } // if (!prod.includedInParentPrice)
      } else if (prod.isAdjustment) {
         prod.enterRevenueManually = true;
      } else {
         // if not selected and there is a remove price
         if (prod.hasRemovePrice && prod.isParentSelected && prod.oli != null) {
            prod.oli.Price_Per_Frequency__c = prod.prodLink.Remove_Price__c*-1;
            prod.oli.Unit__c = 1;
            prod.oli.Frequency__c = getOpptyFreq();
            prod.oli.Total_Calced__c = prod.oli.Price_Per_Frequency__c * prod.oli.Frequency__c;
            prod.oli.TotalPrice = prod.oli.Total_Calced__c + Utilities.nvl(prod.oli.Rev_Adj__c);
         } else {
         }
      } // if (prod.selected

      return true;  
   } // calculateTotal
   
   public String selectedPkgOption{get;set;}
   
   public Boolean showProdList{get; set;}
   
   /** The list of all products available for the form */
   public List<ProductSelector> prodList{get;private set;}
   
   public Boolean setupQuoteProds = false;
   
   public List<ProductSelector> displayProdList{
      get {
         if (usingQuoteTool && !setupQuoteProds) {
            prodList = setupQuoteProdList();
         } // if (usingQuoteTool
          system.debug('jc prodList'+prodList); 
         return prodList;
      } // get
   } // displayProdList
   
   public List<ProductSelector> setupQuoteProdList() {
      List<ProductSelector> quoteProdList = new List<ProductSelector>();
      // return only the selected products.
      List<String> sortedKeys = new List<String>();
      sortedKeys.addAll(groupedProdMap.keySet());
      sortedKeys.sort();

      prodList = new List<ProductSelector>();
      for (String key : sortedKeys) {
         for (ProductSelector ps : groupedProdMap.get(key)) {
            quoteProdList.add(ps);
            ps.addAdjustments(quoteProdList);
         }
      } // for (String key
      return quoteProdList;
   } // setupQuoteProdList

   public Boolean showAllProducts {get; set;}
   
   /** Change the show product list option.
    */
   public PageReference changeShowProdList() {
      showProdList = !showProdList;
      return null;
   } // changeShowProdList
   
   /** Change the show package option.
    */
   public PageReference changeShowPkg() {
      isShortPkgList = !isShortPkgList;
      return null;
   } // changeShowPkg
   
   /** Delete an adjustment made by the user.
    */
   public PageReference deleteAdjustment() {
      String prodId = System.currentPageReference().getParameters().get('prodId');
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'deleteAdjustment prodId='+prodId));
      if (prodId != null) {
         if (usingQuoteTool) {
            removeFromList(prodId,prodList,true);
         } else {
            removeFromList(prodId,prodList,false);
            removeFromList(prodId,allProdsAndPackages,true);
         }
      } // if (prodId != null
      return null;
   } // deleteAdjustment
   
   /** Remove from the list and delete the record (if it's been saved).
    */
   public Boolean removeFromList(String prodId, List<ProductSelector> checkList, Boolean deleteRecord) {
      for (Integer cnt=0; cnt<checkList.size(); cnt++) {
         ProductSelector ps = checkList.get(cnt);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'removeFromList id='+ps.oli.Id+' ps='+ps.getDescription()));
         if (ps.prodId == prodId) {
            // remove from the list
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'removeFromList prodId matches'));
            checkList.remove(cnt);
            if (ps.isAdjustment && ps.oli.Adj_Type__c == CHARGEBACK && ps.chargebackParent != null) {
               ps.chargebackParent.chargeback = null;
            } else if (ps.isAdjustment && ps.oli.Adj_Type__c == TRUEUP && ps.trueupParent != null) {
               ps.trueupParent.trueup = null;
            } else if (ps.isAdjustment && ps.oli.Adj_Type__c == REFERRAL && ps.referralParent != null) {
               ps.referralParent.referral = null;
            }
            if (deleteRecord && ps.oli.Id != null) {
               oliDelete.add(ps.oli);
            }
            break;
         } // if (ps.prodId
      } // for (Integer
      return true;
   } // removeFromList
   
   public static final String CHARGEBACK='Chargeback';
   public static final String TRUEUP='True-Up';
   public static final String REFERRAL='Referral';
   
   /** Add a line to true-up the revenue for a product.
    */
   public PageReference addAdjustment() {
      String prodId = System.currentPageReference().getParameters().get('prodId');
      String adjType = System.currentPageReference().getParameters().get('adjType');
      system.debug('ProductHelper PageReference prodId: '+prodId + 'adjType: '+adjType); 
      if (prodId != null && adjType != null) {
         ProductSelector ps = findLineItem(prodId);
         if (ps != null) {
            addLineItem(ps,adjType);
            //ProductSelector ps = addLineItem(prodId, adjType);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in addAdjustment ps='+ps.getDescription()+' adjType='+adjType+' selected='+ps.selected+' isPkg='+ps.isPkg+' hasChildren='+ps.hasChildren));
            if (adjType == CHARGEBACK && ps != null && ps.selected && ps.isPkg && ps.hasChildren) {
               // if a package, add chargebacks to all of its line items that were saved.
               for (ProductSelector child : ps.childProducts) {
                  if (child.selected && child.oli != null && child.oli.Id != null && !child.isAdjustment ) {
                     addLineItem(child,adjType);
                  }
               } // for (ProductSelector child
            } // if (adjType == 
         } // if (foundPs != null
      } // if (prodId != null)
      if (!usingQuoteTool) {          
         buildProdList(false,false);
      }
      system.debug('not using quote tool: '+ usingQuoteTool);
      return null;
   } // addAdjustment
   
   // Find a record coming directly from the form. All products will be in prodList
   public ProductSelector findLineItem(String prodId) {
      ProductSelector foundPs = null;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in findLineItem prodId='+prodId));
      if (prodId != null) {
         foundPs = allProdsByProdIdMap.get(prodId);
         if (foundPs == null) {
            // find the line in the prodList
            for (ProductSelector checkPs : prodList) {
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in addTrueUp checkPs='+checkPs.getDescription()));
               if (checkPs.prodId == prodId) {
                  foundPs = checkPs;
                  break;
               }
            } // for (Inte
         } // if (foundPs == null)
      } // if (prodId != null
      return foundPs;
   } // findLineItem
   
   public Boolean addLineItem(ProductSelector ps, String adjType) {
      Boolean okay = true;

      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in addLineItem ps='+ps.getDescription()+' adjType='+adjType));
      if (ps != null) {
         Boolean isChargeback = (adjType == CHARGEBACK);
         ProductSelector newPs = null;
         newPs = new ProductSelector(ps);
         newPs.setupLineItem(null);
         newPs.selected=true;
         newPs.oli.User_Override__c = true;
         // negate numbers for chargebacks.
         newPs.oli.TotalPrice = (ps.oli.TotalPrice != null ? (ps.oli.TotalPrice * (isChargeback ? -1 : 0)) : null);
         newPs.oli.Setup_Fee__c = (ps.oli.Setup_Fee__c != null ? (ps.oli.Setup_Fee__c * (isChargeback ? -1 : 0)) : null);
         newPs.oli.Adj_Type__c = adjType;
         newPs.oli.ServiceDate = Date.today(); //ps.oli.ServiceDate;
         newPs.enterRevenueManually = true;
         newPs.oli.Payroll_Unit__c = (ps.oli.Payroll_Unit__c != null ? (ps.oli.Payroll_Unit__c * (isChargeback ? -1 : 1)) : null);
         newPs.oli.Non_Payroll_Unit__c = (ps.oli.Non_Payroll_Unit__c != null ? (ps.oli.Non_Payroll_Unit__c * (isChargeback ? -1 : 1)) : null);
         newPs.oli.Unit__c = null;
         newPs.oli.Oppty_Product_Id__c = ps.oli.Id;
         newPs.oli.Status__c = ps.oli.Status__c; //OpptyProducts.getProdStatus(oppty.StageName);

         addToTotal(newPs);
         if (isChargeback) {
            ps.chargeback = newPs;
            newPs.chargebackParent = ps;
         } else if (adjType == TRUEUP) {
            ps.trueup = newPs;
            newPs.trueupParent = ps;
         } else if (adjType == REFERRAL) {
            ps.referral = newPs;
            newPs.referralParent = ps;
         }

         // add line to allProductsAndGroups
         if (newPs != null) {
            allProdsAndPackages.add(newPs);
         }
      } // ps != null
      return okay;
   } // addLineItem
   
   /** Change the flag about showing children for a particular group.
    */
   public PageReference changeShowChildren() {
      Id entryId = System.currentPageReference().getParameters().get('entryId');
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in changeShowChildren entryId='+entryId));
      if (entryId != null && prodList != null) {
         // find the record
         
         for (ProductSelector ps : prodList) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Name='+ps.entry.Product2.Name+' hasChildren='+ps.hasChildren+' id='+ps.entry.Id));
            if (ps.hasChildren && ps.entryId == entryId) {
               ps.displayAllChildren = !ps.displayAllChildren;
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'found record to change displayAllChildren flag! Name='+ps.entry.Product2.Name+' flag value='+ps.displayAllChildren));
            }
             ps.setChildrenToParentFlag();
         } // for (ProductSelector
        
      } // if (entryId != null
      buildProdList(false, true);
      return null;
   } // changeShowChildren
      
   public PageReference selectStandaloneProduct() {
      // if there are default products, reset and clear.
      clearDefaultProds();
      isStandAlone = true;
      
      return null;
   } // selectStandaloneProduct
   
   private void clearDefaultProds() {
      // if there are default products, reset and clear.
      if (defaultProds != null) {
         for (ProductSelector ps : defaultProds) {
            ps.resetProd();
         }
         defaultProds = null;
      } // if (defaultProds != null
   } // clearDefaultProds
   
   /** Select a package.
    */
   public PageReference selectPkg() {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in selectPkg'));
      // if there are default products, reset and clear.
      clearDefaultProds();
      
      markSelectPkg();
      if (prodList != null) {
         for (ProductSelector ps : prodList) {
            if (ps.selected) {
               if (ps.entry.Product2.Default_Units_to_Employees__c) {
                  ps.oli.Unit__c = oppty.Employees_Paid_Per_Payroll__c;
               } else {
                  // default to 1 otherwise. 
                  // TODO - do we want to have a place to store a default unit? Probably not...
                  ps.oli.Unit__c = 1;
               }
            }
         } // for (ProductSelector
      } // if (prodList
      return null;
   } // selectPkg
   
   private void markSelectPkg() {
      if (selectedPkgOption == STANDALONE) {
         isStandalone = true;
      } else if (allPackages != null) {
         // mark the selected package
         for (ProductSelector pkg : allPackages) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'selectedPkgOption='+selectedPkgOption+' ProdCode='+entry.Product2.ProductCode+' pkg='+entry.Product2.Payroll_Package__c));
            if (pkg.entry.Product2.ProductCode == selectedPkgOption) {
               selectedPkg = pkg;
               selectedPkg.selected=true;
               selectedPkg.setChildrenToParentFlag();
               checkForRevenueSplit(selectedPkg);
               break;
            }
         } // for
      } // if (selectedPkgOption
      
      // build the product list
      buildProdList(false, true);

   } // markSelectPkg
   
    /*
   // If a product selection changes, check if extra logic needs to happen.
   public PageReference changeProdSelection() {
      // see if the entryId is passed in
      Id entryId = System.currentPageReference().getParameters().get('entryId');
      Id linkId = null;
      try {
         linkId = System.currentPageReference().getParameters().get('linkId');
      } catch (Exception e) {
         linkId = null;
      } // try
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'entryId='+entryId+' linkId='+linkId));
      // if passed in, find the product
      if (entryId != null && prodList != null) {
         // find the record that matches
         ProductSelector foundPs = null;
         for (ProductSelector ps : prodList) {
            if (ps.productMatches(entryId, linkId)) {
               foundPs = ps;
               break;
            }
         } // for
         
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'found entryId foundPs='+foundPs));
         // if this is now selected and has children, check for mandatory fields to set as selected
         if (foundPs != null && foundPs.hasChildren) {
            // go through the children
            foundPs.setChildrenToParentFlag();
         } // if (foundPs != null
      } // if (entryId != null
      
      // recalc all products just to make sure
      calcAllProds(false);
      return null;
   } // changeProdSelection
   */
   public Opportunity oppty {get; set;}
   
   public List<OpportunityLineItem> opptyLineItems = null;
   
   /** The Opportunity products in a Map for easy reference. */
   //private Map<Id,OpportunityLineItem> opptyLineItemMap = new Map<Id,OpportunityLineItem>();
   
   /** The Quote products in a Map for easy reference. */
   //private Map<Id,QuoteLineItem> quoteLineItemMap = new Map<Id,QuoteLineItem>();
   
   //public Quote qute {get;set;}
   
   public Integer frequency{get;set;}
   
   public Boolean opptyOkay{get;private set;}
   
   private Id opptyId = null;
   
   /** Setup the opportunity and product records.
    */
   public Boolean setOpportunity(Id p_opptyId, User curUser, Boolean userIsSalesRep) {
      opptyId = p_opptyId;
      opptyOkay = true;
      try {
         oppty = [Select Id, Name, CloseDate, Frequency__c, Employees_Paid_Per_Payroll__c,Account.CSCMContractStatus__c
                     ,Owner.Id, Owner.PilotUser__c, Owner.Sales_Org__c
                     ,ForecastCategory, ForecastCategoryName
                     ,Service_Location__c
                     ,StageName, IsClosed, IsWon
                     ,Payroll_Platform__c
                     ,Payroll_Units__c
                     ,Non_Payroll_Units__c
                     ,Pricebook2Id
                     ,Pricebook2.DoesNotHavePricing__c
                     ,Pricebook2.Quote_User__c
                     ,Pricebook2.Sales_Org__c
                     ,Pricebook2.Sales_Org2__c
                     ,Office_Price_Schedule_Map__c
                     ,RecordType.Name
                 From Opportunity
                where Id = :opptyId];
      } catch (Exception e) {
         if (!System.isBatch()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Unable to find an Opportunity with Id=='+opptyId));
         }
         oppty = null;
         opptyOkay = false;
         return false;
      }
      
      quoteToolName = oppty.Pricebook2.Quote_User__c;
      
      // default to the sales org on the pricebook
      if (oppty.Pricebook2 != null) {
         salesOrg = oppty.Pricebook2.Sales_Org__c;
         System.debug('ProductHelper.setOpportunity setting sales org from pricebook: '+salesOrg);
      }
      
      // default to the value from the Opportunity
      if (salesOrg == null) {
         //salesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(oppty.RecordType.Name);
         salesOrg
             = ProductMapping.getSalesOrg(oppty.RecordType.Name, oppty.Owner);
         System.debug('ProductHelper.setOpportunity setting sales org from product mapping: '+salesOrg);
      }
      // default the payroll platform to the user's sales org
      if (oppty.Payroll_Platform__c == null) {
         oppty.Payroll_Platform__c = salesOrg;
      }
      
      isDsaRecordType = RecordTypeHelper.isDSAOpptyRT(oppty.RecordType.Name);
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'salesOrg='+salesOrg));
      // if DSA/FSS record type and user is a sales rep, set record as readOnly 
      if (userIsSalesRep && isDsaRecordType) {
         readOnly = true;
      }
      List<String>restrictedPEOProfileList = Label.PEO_Implementation_Profiles.split(';');
      Set<String>restrictedPEOProfileSet = new Set<String>();
      restrictedPEOProfileSet.addall(restrictedPEOProfileList);
       
      List<String>restrictedPEOValueList = Label.PEO_Implementation_Values.split(';');
      Set<String>restrictedPEOValueSet = new Set<String>();
      restrictedPEOValueSet.addall(restrictedPEOValueList);
       if(curUser!=null && restrictedPEOProfileSet.contains(curUser.Profile.Name) && restrictedPEOValueSet.contains(oppty.Account.CSCMContractStatus__c)
       //&& (oppty.RecordType.Name == Label.RT_Oppty_PeoC || oppty.RecordType.Name == Label.RT_Oppty_PeoC_FSS)){
         ){
           readOnly = true;
           ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.PEO_Implementation_Message));
       }
      // set readOnly flag if not sold
      if (!readOnly && isNotSold) {
         readOnly = true;
      }
      return checkOpptyInfo();
   } // setOpportunity
   
   public Boolean isDsaRecordType{get;set;}
   public Boolean readOnly{get;set;}
   
   /** Is this opportunity closed? */
   public Boolean opptyIsClosed {
      get { return (oppty != null && oppty.IsClosed); }
   } // opptyIsClosed
   
   /** Is this Opportunity closed and not sold? */
   public Boolean isNotSold {
      get { return (opptyIsClosed && !oppty.IsWon); }
   } // isNotSold
   
   /** Is this Opportunity marked as sold? */
   public Boolean isSold {
      get { return (oppty != null && (oppty.StageName.startsWith('Sold') ||
                                      oppty.StageName == 'Referred Sold' ||
                                      oppty.StageName == 'Referred Started')); }
   } // isNotSold

   public Boolean includedChildrenExist{get;set;}
   
   public Boolean useFrequency {
      get { return (String.isNotBlank(salesOrg) && 
                    ((salesOrg.startsWith(UserHelper.SO_CORE)) ||
                     (salesOrg.startsWith(UserHelper.SO_MMS)) ||
                     (salesOrg.startsWith(UserHelper.SO_PEO_ASO))
                    ));
      } // get
   } // useFrequency
   
   public Boolean useEmpsPerPay {
      get { return (String.isNotBlank(salesOrg) && 
                    ((salesOrg.startsWith(UserHelper.SO_CORE)) ||
                     (salesOrg.startsWith(UserHelper.SO_MMS)) ||
                     (salesOrg.startsWith(UserHelper.SO_PEO_ASO))
                    ));
      } // get
   } // useEmpsPerPay
   
   public Boolean checkOpptyInfo() {
      opptyOkay = true;
      if (useFrequency && oppty.Frequency__c == null) {
         Schema.DescribeFieldResult dfr = Schema.SObjectType.Opportunity.fields.Frequency__c;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The '+dfr.getLabel()+' field must have a value in order to proceed!'));
         opptyOkay = false;
      }
      if (useEmpsPerPay && oppty.Employees_Paid_Per_Payroll__c == null) {
         Schema.DescribeFieldResult dfr = Schema.SObjectType.Opportunity.fields.Employees_Paid_Per_Payroll__c;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The '+dfr.getLabel()+' field must have a value in order to proceed!'));
         opptyOkay = false;
      }
      if (opptyOkay) {
         if (useFrequency) {
            frequency = Integer.valueOf(oppty.Frequency__c);
         }

         //opptyLineItemMap.clear();
         //quoteLineItemMap.clear();
      
        /*
         try {
            qute = [Select Id, Name
                          ,Presented_Products__c
                          ,(Select Id
                                  ,PricebookEntryId
                                  ,ServiceDate
                                  ,Quantity
                                  ,Discount
                                  ,UnitPrice
                              From QuoteLineItems)
                      From Quote
                     Where OpportunityId = :opptyId
                       and Presented_Products__c = true
                     limit 1];
            // add quote items to the Map
            for (QuoteLineItem qli : qute.QuoteLineItems) {
               quoteLineItemMap.put(qli.PricebookEntryId,qli);
            }
         } catch (Exception e) {
            // do nothing if quote exists
         }
         if (qute == null) {
            try {
               // if no quote, look for Contact info so new quote can be created
               OpportunityContactRole oppContactRole= [Select Id, ContactId, IsPrimary
                                                      From OpportunityContactRole
                                                     where OpportunityId = :opptyId
                                                     limit 1];
               contactId = oppContactRole.ContactId;
            } catch (Exception e) {
               // do nothing if can't find the contact id
            }
         } // if (qute == null
         */
         opptyLineItems = [Select Id
                                 ,PricebookEntryId
                                 ,PricebookEntry.Id
                                 ,PricebookEntry.Name
                                 ,PricebookEntry.Pricebook2Id
                                 ,PricebookEntry.ProductCode
                                 ,PricebookEntry.Product2Id
                                 ,PricebookEntry.Product2.Default_Units_to_Employees__c
                                 ,PricebookEntry.Product2.Is_Default_Product__c
                                 ,PricebookEntry.Product2.Is_Package__c
                                 ,PricebookEntry.Product2.Is_Payroll_Unit__c
                                 ,PricebookEntry.Product2.Is_Non_Payroll_Unit__c
                                 ,PricebookEntry.Product2.Name
                                 ,PricebookEntry.Product2.Rollup_Product__c
                                 ,PricebookEntry.Product2.Unit_Type__c
                                 ,Actual_Revenue__c
                                 ,Adj_Type__c
                                 ,Annual_Base_and_Trans__c
                                 ,Annual_Base_Trans_Disc__c
                                 ,Base_Fee__c
                                 ,CreatedDate
                                 ,Description
                                 ,Discount_Annualized__c
                                 ,Discount_Free_Months__c
                                 ,Discount_Months__c
                                 ,Discount_Percent__c
                                 ,Discounted_Annual_Price__c
                                 ,Estimated_Revenue__c
                                 ,External_Integration__c
                                 ,External_System_Id__c
                                 ,Frequency__c
                                 ,Has_External_Id__c
                                 ,ListPrice
                                 ,Non_Discounted_Price__c
                                 ,Non_Discounted_Revenue__c
                                 ,Oppty_Product_Id__c
                                 ,OpportunityId
                                 ,Payroll_Unit__c
                                 ,Non_Payroll_Unit__c
                                 ,Price_Per_Frequency__c
                                 ,Price_Schedule__c
                                 ,Product_Parent_Child_Link__c
                                 ,Quantity
                                 ,QuoteLineGroupAcct__c
                                 ,Rev_Adj_Calcd__c
                                 ,Rev_Adj__c
                                 ,ServiceDate
                                 ,Setup_Fee__c
                                 ,Setup_Fee_Original__c
                                 ,SortOrder
                                 ,Status__c
                                 ,UnitPrice
                                 ,Total_Calced__c
                                 ,TotalPrice
                                 ,Transaction_Fee__c
                                 ,Unit__c
                                 ,User_Override__c
                             From OpportunityLineItem
                            where OpportunityId = :opptyId
                             order by PricebookEntry.Name, CreatedDate ];
         // add Opportunity products to the map
         //for (OpportunityLineItem oli : opptyLineItems) {
         //   opptyLineItemMap.put(oli.PricebookEntryId, oli);
         //} // for
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkOpptyInfo opptyLineItems='+opptyLineItems.size()));
      } // if (opptyOkay
      return opptyOkay;
   } // checkOpptyInfo
   
   public Boolean saveSelectedProducts(Id opptyId) {
      System.debug('saveSelectedProducts opptyId='+opptyId);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveSelectedProducts opptyId='+opptyId));
      Boolean allOkay = true;
      // save to quotes & opportunity products
      if (!saveOpptyProducts(opptyId)) {
         allOkay = false;
      }
      //saveQuoteProducts(opptyId);
      return allOkay;
   } // saveSelectedProducts
   
   // the records that will be deleted. This is a class variable because records can be added when the package changes.  
   private OpportunityLineItem[] oliDelete = new OpportunityLineItem[]{};
   
   public Boolean saveOpptyProducts(Id opptyId) {
      Boolean okay = true;
      // check for deletes for records that were previously saved
      System.debug('saveOpptyProducts opptyLineItems='+(opptyLineItems != null ? opptyLineItems.size() : -1));
      if (opptyLineItems != null) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveOpptyProducts opptyLineItems='+opptyLineItems.size()));
         for (OpportunityLineItem oli : opptyLineItems) {
            if (oli.Quantity == 0) {
               oliDelete.add(oli);
            }
         } // for
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveOpptyProducts oliDelete='+oliDelete.size()));
         if (!oliDelete.isEmpty()) {
            // let's make sure we have a unique list of items to delete
            Map<Id,OpportunityLineItem> delMap = new Map<Id,OpportunityLineItem>();
            for (OpportunityLineItem oli : oliDelete) {
               if (oli.Id != null) {
                  delMap.put(oli.Id, oli);
               }
            } // for
            
            if (!delMap.isEmpty()) {
               // double check products still exist
               OpportunityLineItem[] delRecCheck = [Select Id, PricebookEntryId, OpportunityId from OpportunityLineItem where Id in :delMap.keySet()]; 
               System.debug('saveOpptyProducts oliDelete='+oliDelete.size()+' delMap='+delMap.size()+' delRecCheck='+delRecCheck.size());
               ErrorLogCS__c errLog = ErrorLogCS__c.getInstance('ProductHelper');
               if (errLog != null && errLog.LogDeleteError__c) {
                  DmlHelper.performDML2(delRecCheck, DmlHelper.DML_DELETE, 'ProductHelper', 'saveOpptyProducts', 'Delete OpportunityLineItems', true);
               } else {
                  Database.delete(delRecCheck,false);
               } 
               //Database.DeleteResult[] results = Database.delete(delMap.values(),false);
            }
         }
      } // if (opptyLineItems
      OpportunityLineItem[] oliUpsert = new OpportunityLineItem[]{};

      // check to make sure if a record is already saved, we're only adding it to the list once.
      Set<Id> updateCheckSet = new Set<Id>();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveOpptyProducts allProdsAndPackages='+(allProdsAndPackages != null)));
      if (allProdsAndPackages != null) {
         for (ProductSelector ps : allProdsAndPackages) {
        
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in saveOpptyProducts name='+ps.getDescription()+' ps.entry='+(ps.entry != null)+' ps.oli='+(ps.oli != null)+' ps.oli.Quantity='+ps.oli.Quantity));
            //if (ps.selected || (!ps.selected && ps.hasRemovePrice)) {
            if (ps.entry != null && ps.oli != null && ps.oli.Quantity != 0) {
               // this should always exist. This would be an error if it doesn't
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in saveOpptyProducts name='+ps.getDescription()+' oli='+ps.oli));
               checkProductSelector(ps, oliUpsert, updateCheckSet);
/*
               if (ps.hasRemovePrice) {
                  ps.oli.Quantity = (ps.selected ? 1 : -1);
               } else {
                  ps.oli.Quantity = 1;
               }
               //ps.oli.ServiceDate = oppty.CloseDate;
               if (ps.prodLink != null) {
                  ps.oli.Product_Parent_Child_Link__c = ps.prodLink.Id;
               }
               // TotalPrice is required
               if (ps.oli.TotalPrice == null) {
                  ps.oli.TotalPrice=0;
               }
               if (ps.oli.id != null) {
                    // check to make sure only adding to list once.
                    if (!updateCheckSet.contains(ps.oli.Id)) {
                     oliUpsert.add(ps.oli);
                     updateCheckSet.add(ps.oli.Id);
                    }
               } else {
                  oliUpsert.add(ps.oli);
               }
               ps.oli.Rollup_Product__c = ps.getRollupProductId();
              */
            /*
            } else {
               // this was selected and is no longer - delete the record
               if (ps.oli != null && ps.oli.Id != null) {
                  oliDelete.add(ps.oli);
               }
               */
            }
         } // for
      } 
      System.debug('saveOpptyProducts oliUpsert='+oliUpsert.size()+' prodList='+(prodList != null ? prodList.size() : -1));
      // there should be SOMETHING here to save. But just in case...
      if (oliUpsert.isEmpty() && prodList != null && !prodList.isEmpty()){
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveOpptyProducts else clause for prodList'));
         for (ProductSelector ps : prodList) {
            if (ps.selected && ps.oli != null) {
               checkProductSelector(ps, oliUpsert, updateCheckSet);
            }
         }
      } // if (allProdsAndPackages
      
      if (defaultProds != null) {
         for (ProductSelector ps : defaultProds) {
            oliUpsert.add(ps.oli);
         }
      } // if (defaultProds != null
      
      System.debug('saveOpptyProducts oliUpsert='+oliUpsert.size());
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in saveOpptyProducts oliUpsert='+oliUpsert.size()));
      if (!new SObjectHelper().saveRecords(oliUpsert,null,null)) {
         okay = false;
      }
      //if (!oliDelete.isEmpty()) {
      //   delete oliDelete;
      //}
      return okay;
   } // saveOpptyProducts
   
   private void checkProductSelector(ProductSelector ps, OpportunityLineItem[] oliUpsert, Set<Id> updateCheckSet) {
      System.debug('checkProductSelector name='+ps.getDescription()+' Payroll Unit='+ps.oli.Payroll_Unit__c);
      if (ps.hasRemovePrice) {
         ps.oli.Quantity = (ps.selected ? 1 : -1);
      } else if (ps.oli.Quantity == null || ps.oli.Quantity < 1) {
         ps.oli.Quantity = 1;
      }
      //ps.oli.ServiceDate = oppty.CloseDate;
      if (ps.prodLink != null) {
         ps.oli.Product_Parent_Child_Link__c = ps.prodLink.Id;
      }
      // TotalPrice is required
      if (ps.oli.TotalPrice == null) {
         ps.oli.TotalPrice=0;
      }
      if (ps.oli.id != null) {
         // check to make sure only adding to list once.
         if (!updateCheckSet.contains(ps.oli.Id)) {
            oliUpsert.add(ps.oli);
            updateCheckSet.add(ps.oli.Id);
         }
      } else {
         oliUpsert.add(ps.oli);
      }
      ps.oli.Rollup_Product__c = ps.getRollupProductId();
   } // checkProductSelector
   
   /** The contact id. Used if have to create a new quote record. */
   public Id contactId{get;set;}
   
   /*
   public Boolean saveQuoteProducts(Id opptyId) {
      Boolean okay = true;
      if (qute == null) {
         // if no quote exists, create a new one
         qute = new Quote(Name='Presented Products', OpportunityId = opptyId
                         ,Presented_Products__c = true
                         ,Pricebook2Id = pricebook.Id);
         if (contactId != null) {
            qute.ContactId = contactId;
         }
         insert qute;
      } // if (qute
      QuoteLineItem[] qliUpsert = new QuoteLineItem[]{};
      QuoteLineItem[] qliDelete = new QuoteLineItem[]{};

      for (ProductSelector ps : prodList) {
         if (ps.selected) {
            if (ps.qli == null) {
               // if the line item doesn't already exist, create it.
               ps.qli = new QuoteLineItem(QuoteId = qute.Id
                                               ,PricebookEntryId = ps.entry.Id
                                               ,ServiceDate = oppty.CloseDate
                                               ,Quantity = 1
                                               ,Discount = null
                                               ,UnitPrice= 10);
            }
            qliUpsert.add(ps.qli);
         } else {
            // this was selected and is no longer - delete the record
            if (ps.qli != null && ps.qli.Id != null) {
               qliDelete.add(ps.qli);
            }
         }
      } // for

      if (!SObjectHelper.saveRecords(qliUpsert,null,null)) {
         okay = false;
      }

      if (!qliDelete.isEmpty()) {
         delete qliDelete;
      }
      return okay;
   } // saveQuoteProducts
    */

   /** Get the quote and products associated with the Opportunity.
    */
    /*
   public void getOpptyQuote(Id opptyId) {
      Quote q = [Select Id, Name
                       ,Pricebook2Id
                       ,(Select Id
                               ,Description
                               ,Discount
                               ,LineNumber
                               ,ListPrice
                               ,ServiceDate
                               ,SortOrder
                               ,Subtotal
                               ,TotalPrice
                               ,UnitPrice
                               ,PricebookEntryId
                               ,PricebookEntry.Product2Id
                               ,PricebookEntry.Product2.Name
                               ,PricebookEntry.Product2.ProductCode
                               ,PricebookEntry.Product2.Is_Package__c
                               ,PricebookEntry.Product2.Sort_Order__c
                               ,PricebookEntry.Product2.Actively_Sold__c
                               ,PricebookEntry.Product2.Actively_Sold_Stand_Alone__c
                               ,PricebookEntry.Product2.Is_Default__c
                               ,PricebookEntry.Product2.Is_Payroll_Pkg__c
                               ,PricebookEntry.Product2.In_Short_List__c
                           From QuoteLineItems)
                   From Quote
                  where OpportunityId = :opptyId];
   } // getOpptyQuote
   
   */
   
   /** Does this have a price schedule? */
   public Boolean hasPriceSchedule{
      get {return priceHelper.doPriceSchedulesExist(salesOrg); }
      //get{ return priceHelper.priceScheduleMap != null; }
   } // hasPriceSchedule
   
   /** The selected cost center. */
   public String costCenter{get;set;}
   
   public void setPriceScheduleByCostCenter() {
      if (oppty != null) {
         priceHelper.setPriceSchedule(costCenter,salesOrg);
         oppty.Office_Price_Schedule_Map__c = (priceHelper.priceScheduleMap != null ? priceHelper.priceScheduleMap.Id : null);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'setPriceScheduleByCostCenter oppty.Office_Price_Schedule_Map__c='+oppty.Office_Price_Schedule_Map__c));
      }
   } // setPriceScheduleByCostCenter
   
   public void setupPriceHelper(User u, String salesOrg) {
      // setup prices for all products in the pricebook
      if (oppty != null) {
         // if one already exists on the opportunity use that one
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'setupPriceHelper1 oppty.Office_Price_Schedule_Map__c='+oppty.Office_Price_Schedule_Map__c));
         if (oppty.Office_Price_Schedule_Map__c != null) {
            priceHelper.setPriceSchedule(oppty.Office_Price_Schedule_Map__c);
         } else {
            // else try to find on based on user information
            priceHelper.setPriceSchedule(u.Cost_Center__c,salesOrg);
         }
         // save it on the opportunity
         oppty.Office_Price_Schedule_Map__c = (priceHelper.priceScheduleMap != null ? priceHelper.priceScheduleMap.Id : null);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'setupPriceHelper2 oppty.Office_Price_Schedule_Map__c='+oppty.Office_Price_Schedule_Map__c));
         costCenter = (priceHelper.priceScheduleMap != null ? priceHelper.priceScheduleMap.Cost_Center__c : null);
         
      } // if (oppty != null
   } // setupPriceHelper

   public Integer getOpptyFreq() {
      Integer freq = 0;
      if (oppty != null && oppty.Frequency__c != null) {
         freq = Integer.valueOf(oppty.Frequency__c);
         frequency = freq;
//           if (freq == 24) {
//              freq = 26;
//           }
      }
      return freq;
   } // getOpptyFreq
   
   /** If the employee count changes on the opportunity, set the new count on records that default
       to employee count and recalculate.
    */
   public PageReference changeEmpCount() {
      if (allProdsAndPackages != null) {
         for (ProductSelector ps : allProdsAndPackages) {
            if (ps.selected && ps.entry.Product2.Default_Units_to_Employees__c && 
                ps.oli.Unit__c != oppty.Employees_Paid_Per_Payroll__c) {
               ps.oli.Unit__c = oppty.Employees_Paid_Per_Payroll__c;
               // recalculate for the new number
            }
         } // for
         calcAllProds(false);
      } // if (allProdsAndPackages
      return null;
   } // changeEmpCount
   
   /** If the frequency changes, recalc all products.
    */
   public PageReference changeFrequency() {
      calcAllProds(false);
      return null;
   } // changeFrequency
   
   /** Apply the discount to all products.
    */
   public PageReference applyDiscountAllProducts() {
      if (prodList != null) {
         for (ProductSelector prod : prodList) {
            if (prod.selected && prod.hasEntry) {
               prod.oli.Discount_Free_Months__c = totalRecord.oli.Discount_Free_Months__c;
               prod.oli.Discount_Months__c = totalRecord.oli.Discount_Months__c;
               prod.oli.Discount_Percent__c = totalRecord.oli.Discount_Percent__c;
           }
         } // for
      
         calcAllProds(false);
      } // if (prodList != null
      
      return null;
   } // applyDiscountAllProducts
   
   /** Should we show all of the columns in the table? */
   public Boolean showAllColumns{get;set;}
   
   /** Change the showAllColumns flag. */
   public PageReference changeShowColumns() {
      showAllColumns = !showAllColumns;
      return null;
   } // changeShowColumns
   
} // class ProductHelper