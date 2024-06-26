/* 
 * Queries for the products
 *
 * History
 * -------
 * 05/23/2011 Dan Carmen   Created
   10/18/2012 Dan Carmen   Added matchKey method
   02/14/2013 Dan Carmen   Code modifications to reduce script statements.
   08/26/2015 Dan Carmen   Changes to handle grouped products (steelbrick)
   11/11/2020 Dan Carmen   Don't store the pricebook entry in the product selector
   06/15/2023 Jaipal      Added hasNonPayrollUnit APR0152229: FY24 - Non-PR Unit Tracking In Manage Products

*/
public with sharing class ProductSelector {

   /** Default no-argument constructor
    */
   public ProductSelector() {
      displayAllChildren = false;
      enterRevenueManually = false;
      hasPricingInfo = false;
      //entry = null;
      selected = false;
      pricingExistsButDoesntMatch = false;
      unitChanged = false;
   } // ProductSelector
   
   public ProductSelector(PricebookEntry p_entry, Opportunity p_oppty) {
      this();
      entryId = (p_entry != null ? p_entry.Id : null);
      pricebookId = (p_entry != null ? p_entry.Pricebook2Id : null);
       
     // entry = p_entry;
      oppty = p_oppty;
   } // ProductSelector

   public ProductSelector(ProductSelector p_ps) {
      this();
      entryId = p_ps.entryId;
      pricebookId = p_ps.pricebookId;
      //entry = p_ps.entry;
      oppty = p_ps.oppty;
      parent = p_ps.parent;
      prodLink = p_ps.prodLink;
   } // ProductSelector
   
   // for testing purposes
   public void resetProdId() {
      v_prodId = null;
   } // resetProdId
   
   private String v_prodId = null;
   /** A unique key for this product line item. Needs to have an id even if not saved.
    */
   public String prodId {
      get {
         if (v_prodId == null) {
            
            if (oli != null && oli.Id != null) {
               v_prodId = oli.Id;
            } else if (oli != null && entry != null) {
               v_prodId = entryId+oli.Adj_Type__c;
               if (oli != null && oli.QuoteLineGroupAcct__c != null) {
                  v_prodId += 'grp'+oli.QuoteLineGroupAcct__c;
               }
            } else {
               v_prodId = 'NoId';
            }
         } // if (v_prodId
         return v_prodId;
      } // get
   } // prodId
    
   public Id pricebookId{get;set;}
   public Id entryId{get;set;}
   
   //public PricebookEntry entry{get; set;}
   public PricebookEntry entry{
      get {
         PricebookEntry v_entry = null;
         v_entry = new ProductQuery().getEntry(pricebookId,entryId);
         System.debug('entry pricebookId='+pricebookId+' entryId='+entryId+' v_entry='+v_entry);
         return v_entry;
      }
   } // entry

   //public QuoteLineItem qli{get; set;}

   public Opportunity oppty{get; set;}
   
   public OpportunityLineItem oli{get;
        set {
          oli = value;
          // if a saved value is passed in, do not reset the initial calc values
          initialCalcPerformed = (oli != null && oli.Id != null);
        } // set
   } // oli
      
   public String name {
      get {
         if (entry != null) {
            return entry.Product2.Name;
         }
         return 'Total';
      } // get
   } // name
   
   /** Get the name of the product, and the parent.
    */
   public String getDescription() {
      String output = null;
      if (entry != null) {
         output = entry.Product2.Name;
         if (parent != null) {
            output += ', parent='+parent.getDescription();
         }
      } // if (entry != null
      return output;
   } // getDescription
   
   public List<ProductSelector> childProducts{get; set;}
   
   public Boolean hasEntry {
      get {return entry != null; } // get
   } // hasEntry
   
   /** Get the product code used for pricing.
    */
   public String pricingProdCode{
      get {
         if (prodLink != null && prodLink.Price_Schedule_Product_Code__c != null) {
            return prodLink.Price_Schedule_Product_Code__c;
         }
         return entry.ProductCode;
      }
   } // pricingProdCode
      
   /** Is this a child of a package?
    */
   public Boolean isChildOfPackage() {
        // if no parent, return false
        // if parent is a package, return true
        // if parent has a parent, return result of that.
        if (parent == null) {
           return false;
        }
        if (parent.isPkg) {
           return true;
        }
        if (parent.parent != null) {
         return parent.isChildOfPackage();
      }
      return false;
   } // isChildOfPackage
   
   /** If this is the child of a package (no matter how many levels), return the package id.
    */
   public Id getPackageId() {
      if (parent != null) {
         if (parent.isPkg && parent.entry != null) {
            return parent.entry.Product2Id;
         } else if (parent.parent != null) {
            return parent.getPackageId();
         }
      } // if (parent != null
      return null;
   } // getPackageId
   
   /** Does this match the product info passed in?
    */
   public Boolean productMatches(Id p_entryId, Id linkId) {
      if (p_entryId != null && p_entryId == entryId) {
         if ((linkId == null && prodLink == null) ||
             (linkId != null && prodLink != null && linkId == prodLink.Id)) {
            return true;
         }
      } // if (entryId != null
      return false;
   } // productMatches
   
   
   public String matchKey = null;
   /*
      get {
         return getKey(entry.Id,(prodLink == null ? null : prodLink.Id));
      } // get
   } // matchKey
   */
   
   public void setMatchKey() {
      matchKey = getKey(entryId,(prodLink == null ? null : prodLink.Id), (oli != null ? String.valueOf(oli.QuoteLineGroupAcct__c) : null));
   } // setMatchKey
   
   public String getKey(Id entryId, Id parentChildId, String groupId) {
      String key = (entryId + 'ParentChild' + (parentChildId == null ? 'NULL' : parentChildId));
      
      return key;
   } // getKey
   
   /** Does the passed in LineItem match the product currently set. If it does, set it here and return true,
       else return false.
    */
   public Boolean lineItemMatchesProd(OpportunityLineItem check_oli, String check_matchKey, List<ProductSelector> adjustments) {
      Boolean match = false;
      //String oliKey = getKey(check_oli.PricebookEntryId,check_oli.Product_Parent_Child_Link__c);
      System.debug('check_matchKey='+check_matchKey+' matchKey='+matchKey);
      // make sure the product is the same, and if there is a Product_Parent_Child_Link__c, that should match too.
      if (matchKey == check_matchKey) {
//      if (check_oli.PricebookEntryId == entry.Id) {
//         if ((check_oli.Product_Parent_Child_Link__c == null && prodLink == null) ||
//             (check_oli.Product_Parent_Child_Link__c != null && prodLink != null &&
//              check_oli.Product_Parent_Child_Link__c == prodLink.Id)) {
              // only match if oli is not already set
              //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'lineItemMatchesProd name='+getDescription()+' oli='+oli ));
              if (oli == null) {
                 match=true;
                 setupLineItem(check_oli);
              } else {
                 // check if incoming record is an adjustment
                 if (check_oli.Adj_Type__c != null && (check_oli.Adj_Type__c == ProductHelper.CHARGEBACK ||
                                                       check_oli.Adj_Type__c == ProductHelper.TRUEUP ||
                                                       check_oli.Adj_Type__c == ProductHelper.REFERRAL)) {
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'lineItemMatchesProd name='+getDescription()+' adjustment match:'+check_oli.Adj_Type__c ));
                    ProductSelector ps = new ProductSelector(this);
                    ps.setupLineItem(check_oli);
                    addAdjustment(ps);
                    adjustments.add(ps); 
                 //} else {
                  //throw new FoundAlreadySetException();
                 }
              }
//         } // if (check_oli
        } // if (oli != null
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'lineItemMatchesProd name='+getDescription()+' match='+match ));
        return match;
   } // lineItemMatchesProd
   
   public void addAdjustment(ProductSelector adjPs) {
      adjPs.enterRevenueManually = true;
      if (adjPs.oli.Adj_Type__c == ProductHelper.CHARGEBACK) {
         chargeback = adjPs;
         adjPs.chargebackParent = this;
      } else if (adjPs.oli.Adj_Type__c == ProductHelper.TRUEUP) {
         trueup = adjPs;
         adjPs.trueupParent = this;
      } else if (adjPs.oli.Adj_Type__c == ProductHelper.REFERRAL) {
         referral = adjPs;
         adjPs.referralParent = this;
      }
   } // addAdjustment
   
   public class FoundAlreadySetException extends Exception {}
   
   /** Setup up the OpportunityLineItem. If one is passed in, use that.
       Otherwise create a new record or reset the existing record.
    */
   public void setupLineItem(OpportunityLineItem p_oli) {
      if (p_oli != null) {
         oli = p_oli;
      } else {
          if (oli == null || (oli != null && oli.Id != null)) {
             oli = new OpportunityLineItem();
             if (entry != null) {
                oli.PricebookEntryId = entryId;
             } // if (entry != null
             if (oppty != null) {
               oli.OpportunityId = oppty.Id;
            }
          } // if (oli == null
          oli.Quantity = 0;
          oli.TotalPrice = 0;
          if (oppty != null) {
            oli.ServiceDate = oppty.CloseDate;
            oli.Unit__c = (entry.Product2.Default_Units_to_Employees__c ? oppty.Employees_Paid_Per_Payroll__c : 1);
          } // if (oppty != null
      }
      selected = (oli.Quantity > 0);
      //if (oli.id != null)
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupLineItem name='+getDescription()+' selected='+selected+' oli='+oli ));
   } // setupLineItem
   
   /** Do we display this product as a child of its parent?
    */
   public Boolean showAsChild{
      get {
         if (parent != null && (!parent.isPkg || (parent.isPkg && includedInParentPrice))) {
            return true;
         }
         return false;
      }
   } // showAsChild
   
   public Product_Parent_Child_Link__c prodLink{get;set;}
      
   public Id linkId {
      get { return (prodLink != null ? prodLink.Id : null); }
   } // linkId
   
   public ProductSelector parent{get;set;}
   
   //public List<Product_Parent_Child_Link__c> childLinks{get;set;}
   
   /** If this has children that aren't always displayed. */
   public Boolean hasHiddenChildren{
      get {
         if (hasChildren) {
            for (ProductSelector ps : childProducts) {
               // if this record has a quantity or any of its children has a quantity return true
               if (ps.showAsChild && !ps.hasRevenue() && !ps.hasAlwaysDisplayChildren()) {
                    return true;
               }
            } // for (ProductSelector
         
         } // if (hasChildren
         return false;
      }
   } // hasHiddenChildren
   
   /** If there are children, do we display all, or only the ones that affect revenue. */
   public Boolean displayAllChildren{get;set;}
   
   /** Does this product have revenue? */
   public Boolean hasRevenue() {
      if ((selected && hasPricingInfo) ||
          (oli != null && oli.TotalPrice != null && oli.TotalPrice != 0)) {
         return true;
      }
      return false;
   } // hasRevenue
   
   /** Do we need to show the revenue field? */
   public Boolean showRevenue {
      get {return hasRevenue(); }
   } // showRevenue
   
   /** This is a recursive call to build a tree.
       if the parent is a package and the children are included in the price, or if not a package.
    */
   public void getDisplayChildren(List<ProductSelector> displayRecords) {
      if (hasChildren && displayRecords != null) {
           //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in getDisplayChildren displayAllChildren='+displayAllChildren));
         for (ProductSelector ps : childProducts) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in getDisplayChildren checking='+ps.entry.Product2.Name+' showAsChild='+ps.showAsChild+' hasRevenue='+ps.hasRevenue()+' ps.hasAlwaysDisplayChildren='+ps.hasAlwaysDisplayChildren()));
            if (!ps.isAdjustment && ps.showAsChild && (displayAllChildren || ps.hasRevenue()  || ps.hasAlwaysDisplayChildren())) {
               displayRecords.add(ps);
               // add any adjustments so they're with the products
               ps.addAdjustments(displayRecords);
               if (ps.hasChildren) {
                  ps.getDisplayChildren(displayRecords);
               }
            } // if (displayAllChildren
         } // for (ProductSelector
      } // if (hasChildren
   } // getDisplayChildren
   
   /** Get the children that have been saved, or if it has children that have been saved.
    */
   public void getSavedChildren(List<ProductSelector> displayRecords) {
      if (hasChildren && displayRecords != null) {
         for (ProductSelector ps : childProducts) {
            // if has an Id is a saved record
            if (!ps.isAdjustment && ps.showAsChild && (ps.prodIsSaved || ps.hasSavedChildren())) {
               displayRecords.add(ps);
               ps.addAdjustments(displayRecords);
               if (ps.hasSavedChildren()) {
                  ps.getDisplayChildren(displayRecords);
               }
            }
         } // for (ProductSelector
         
      } // if (hasChildren
   } // getSavedChildren
   
   /** Is this product saved?
    */
   public Boolean prodIsSaved {
      get {return (oli != null && oli.Id != null); }
   } // prodIsSaved
   
   /** Does this have any children that have been saved?
    */
   public Boolean hasSavedChildren() {
      if (hasChildren) {
         for (ProductSelector ps : childProducts) {
            // if has an Id is a saved record
            if (ps.showAsChild && (ps.prodIsSaved || ps.hasSavedChildren())) {
               return true;
            }
         } // for (ProductSelector
      } // if (hasChildren
      return false;
   } // hasSavedChildren
   
   /** If this product has children that will always be displayed. */
   public Boolean hasAlwaysDisplayChildren() {
      //get {
         if (hasChildren) {
            for (ProductSelector ps : childProducts) {
               // if this record has a quantity or any of its children has a quantity return true
               if (ps.hasRevenue() || ps.hasAlwaysDisplayChildren()) {
                    return true;
               }
            } // for (ProductSelector
         } // if (hasChildren
         return false;
      //} // get
   } // hasAlwaysDisplayChildren
   
   /** Does this have any children that are included in the parent's price?
    */
   public Boolean hasIncludedChildren() {
      if (hasChildren) {
         for (ProductSelector ps : childProducts) {
            // if this record has a quantity or any of its children has a quantity return true
            if (ps.includedInParentPrice) {
               return true;
            }
         } // for (ProductSelector
      } // if (hasChildren
      return false;
   } // hasIncludedChildren
   
   /** Get the level of this record. If there is no parent, it is at level 0. */
   public Integer getlevel() {
      if (showAsChild && parent != null) {
         return (parent.getLevel()+1);
      }
      return 0;
   } // getLevel
   
   public Integer[] levels {
      get {
         Integer[] levels = new Integer[]{};
         Integer numLevels = getLevel();
         for (Integer cnt=0; cnt < numLevels; cnt++) {
            levels.add(cnt);
         }
         return levels;
      } // get
   } // levels
   
   /** Does this have children? */
   public Boolean hasChildren{
      get { return (childProducts != null && !childProducts.isEmpty()); }
   } // hasChildren
   
   /** Add a child to a parent
    */  
   public ProductSelector addChild(PricebookEntry entry, Product_Parent_Child_Link__c childProdLink) {
        if (entry == null || childProdLink == null) {
           return null;
        }
      ProductSelector ps = new ProductSelector(entry,oppty);
      ps.prodLink = childProdLink;
      //addChildLink(childProdLink);
      ps.parent = this;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in addChild parent='+getDescription()+' child='+ps.getDescription()));
      //if (ps.isSetIfParentSet()) {
      //   selected=true;
      //}
      //ps.oli.Product_Parent_Child_Link__c = childProdLink.Id;
      // add the product to the list of children
      addChild(ps);
      //if (childProducts == null) {
      //   childProducts = new List<ProductSelector>();
      //}
      
      //childProducts.add(ps);
      return ps;
   } // addChild
   
   /** Add a child record. Search through the list to see if one of the same product already exists. If so, add this one 
    *  immediately after the existing one.
    */
   public Boolean addChild(ProductSelector child) {
        if (child == null) {
           return false;
        }
      if (childProducts == null) {
         childProducts = new List<ProductSelector>();
      }
      Integer lastMatchPos = -1;
      // find the latest position (in case more than one record)
      for (Integer cnt=0; cnt<childProducts.size(); cnt++) {
         ProductSelector checkChild = childProducts.get(cnt);
         if (checkChild.entryId == child.entryId) {
            lastMatchPos = cnt;
         }
      } // for
      if (lastMatchPos > -1 && lastMatchPos < (childProducts.size()-1)) {
         childProducts.add(lastMatchPos+1,child);
      } else {
         childProducts.add(child);
      }
      return true;
   } // addChild
   
   public Boolean setChildrenToParentFlag() {
      if (hasChildren) {
         for (ProductSelector ps : childProducts) {
              if (ps.isSetIfParentSet()) {
                 ps.selected = selected;
              }
         } // for (ProductSelector
      } // if (hasChildren
      return true;
   } // setChildrenToParentFlag
   
   /** If this would be selected normally because of parent settings, return true.
    */
   public Boolean isSetIfParentSet() {
      return (prodLink != null && (prodLink.Include_Type__c == 'Mandatory' || prodLink.Include_Type__c == 'Default'));
   } // isSetIfParentSet
   
   /** When changing a package, clear out all variables.
    */
   public void resetProd() {
      selected = false;
      displayAllChildren = false;
      initialCalcPerformed = false;
      
      if (oli != null) {
         oli.Quantity = 0;
         clearLineItem();
      }
   } // clearLink
   
   public void clearLineItem() {
      if (oli != null) {
         oli.Price_Per_Frequency__c = null;
         oli.Total_Calced__c = null;
         oli.TotalPrice = 0;
         oli.Setup_Fee__c = null;
         oli.Rev_Adj__c = null;
      } // if (oli != null
   } // clearLineItem
   
   /** Was the initial calc performed on this record? */
   public Boolean initialCalcPerformed{get;set;}
   
   /** Is this product a child of another? */
   public Boolean isChild {
      get {
         // it's part of a package if it's not the package itself and it has a pkgLink
         return (parent != null);
      }
   } // isChild
   
   /** Is this an adjustment made to a product?
    */   
   public Boolean isAdjustment {
      get { return (oli != null && oli.Adj_Type__c != null); }
   } // isAdjustment
   
   /** Is this record always shown? 
       We are going to hide products that are part of a package that do not affect the revenue.
    */
   public Boolean alwaysShowProd {
      get {
         return (!isChild || (isChild && prodLink.Remove_Price__c != null));
      }
   } // alwaysShowProd
      
   public Boolean isPkg{
        get {return (entry != null && entry.Product2.Is_Package__c);}
   } // isPkg
   
   /** Is there a parent to this record and if there is a parent, is it selected? */
   public Boolean isParentSelected{
      get { return (parent != null && parent.selected); }
   } // isParentSelected
   
   /** Is this a mandatory item? */      
   public Boolean isMandatory {
      get {
         return (isParentSelected && prodLink != null && prodLink.Include_Type__c == 'Mandatory');
      } // get
   } // isMandatory
      
   public Boolean hasSelectedChildren() {
        if (hasChildren) {
           for (ProductSelector ps : childProducts) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'hasSelectedChildren ps='+ps.getDescription()+' ps.selected='+ps.selected+' ps.hasSelectedChildren()='+ps.hasSelectedChildren()));
            if ((ps.oli != null && ps.oli.Id != null && ps.selected) || ps.hasSelectedChildren()) {
               return true;
            }
           } // for (ProductSelector
        } // if (hasChildren
      return false;
   } // hasSelectedChildren
      
   /** Is this item selected? */
   public Boolean selected{get;
        set {
           selected = value;
           if (selected) {
              if (oli == null) {
                oli = new OpportunityLineItem();
                if (entry != null) {
                   oli.PricebookEntryId = entryId;
                } // if (entry != null
                if (oppty != null) {
                  oli.OpportunityId = oppty.Id;
               }
               oli.Quantity = 1;
                oli.TotalPrice = 0;
               
              } // if (oli == null
            // if this record is not previously saved and now selected, set the units based on current value.
              if (oli.Id == null) {
               if (entry != null && entry.Product2.Is_Payroll_Unit__c) {
                    oli.Payroll_Unit__c = 1;
                 }
                 if (entry != null && entry.Product2.Is_Non_Payroll_Unit__c) {
                    oli.Non_Payroll_Unit__c = 1;
                 }
               oli.Quantity = 1;
               oli.ServiceDate = (oppty != null ? oppty.CloseDate : Date.today());
               oli.Unit__c = ((entry != null && entry.Product2.Default_Units_to_Employees__c && oppty != null) ? oppty.Employees_Paid_Per_Payroll__c : 1);
              } // if (oli.Id == null
           } else {
              // if not selected
              if (oli != null) {
                 oli.Payroll_Unit__c = null;
                 oli.Non_Payroll_Unit__c = null;
               if (isParentSelected && hasRemovePrice) {
                    oli.Quantity = -1;
                 } else {
                    oli.Quantity = 0;
                 }
              } // if (oli != null
           } // if (selected
           /*
           if (oli != null) {
              if (selected) {
                 // if this record is not previously saved and now selected, set the unit based on current value.
                 if (oli.Id == null) {
                  if (entry != null && entry.Product2.Is_Payroll_Unit__c) {
                       oli.Payroll_Unit__c = 1;
                    }
                    if (entry != null && entry.Product2.Is_Non_Payroll_Unit__c) {
                       oli.Non_Payroll_Unit__c = 1;
                    }
                  oli.Quantity = 1;
                    oli.Unit__c = ((entry != null && entry.Product2.Default_Units_to_Employees__c && oppty != null) ? oppty.Employees_Paid_Per_Payroll__c : 1);
                 }
                 
              } else {
                 oli.Payroll_Unit__c = null;
                 oli.Non_Payroll_Unit__c = null;
                 if (isParentSelected && hasRemovePrice) {
                    oli.Quantity = -1;
                 } else {
                    oli.Quantity = 0;
                 }
              }
              if (oli.Quantity == 0) {
                 clearLineItem();
               initialCalcPerformed = false;
              }
           } // if (oli != null
           */
           if (oli != null && oli.Quantity == 0) {
              oli = null;
            initialCalcPerformed = false;
           } // if (oli != null
        } // set
   } // selected

   public String includeType {
      get { return (prodLink != null ? prodLink.Include_Type__c : null); }
   } // includeType
      
   /** Does this have a setup fee enterable by the user? */
   public Boolean hasEnterableSetupFee {get; set;}
   
   /** Is there a current value set for the setup fee? */
   public Boolean hasSetupFee {
      get {return (oli != null && oli.Setup_Fee__c != null); }
   } // hasSetupFee
   
   public String setupFeeSelectedOption{
        get {
           if (oli != null && oli.Setup_Fee__c != null) {
              return String.valueOf(oli.Setup_Fee__c.intValue());
           }
           return null;
        } // get
        set {
           setupFeeSelectedOption = value;
           // put the selected value into the Setup_Fee__c field so it can be saved.
           try {
            oli.Setup_Fee__c = Decimal.valueOf(value); 
           } catch (Exception e) {
              oli.Setup_Fee__c = null;
           }
        } // set
   } // setupFeeSelectedOption
   
   public List<SelectOption> setupFeeOptions{get;set;}
   
   /** Is there a setup fee picklist. */
   public Boolean hasSetupFeePicklist{
      get {return (setupFeeOptions != null && !setupFeeOptions.isEmpty()); }
   } // hasSetupFeePicklist
   
   public String setupFee{
        get {
           return ((oli != null && oli.Setup_Fee__c != null) ? String.valueOf(oli.Setup_Fee__c.setScale(2)) : null);
        }
        set {
          if (value == null || value == '') {
             oli.Setup_Fee__c = null;
             // keep track of the setup fee in a separate field for tracking purposes.
             oli.Estimated_Setup_Fee__c = null;
          } else {
             try {
               oli.Setup_Fee__c = Decimal.valueOf(value);
               // keep track of the setup fee in a separate field for tracking purposes.
               oli.Estimated_Setup_Fee__c = oli.Setup_Fee__c;
             } catch (Exception e) {
               oli.Setup_Fee__c.addError('Value \''+value+'\' is not a valid value for Setup Fee');
             } // try
          } // if 
        } // set
   } // setupFee
   

   public Boolean hasPricingInfo{get;set;}
   
   public Boolean pricingExistsButDoesntMatch{get;set;}
   
   public Boolean enterRevenueManually{get;set;}
   
   /** Is this product included in the price of it's parent? */
   public Boolean includedInParentPrice{
      get {return (prodLink != null && prodLink.Included_In_Parent_Price__c); }
   } // includedInParentPrice
   
   /** Show the billing? */ 
   public Boolean showPricePerFreq {
        get {return ((selected && !includedInParentPrice && oli!= null && oli.Price_Per_Frequency__c != null) ||
                    (!selected && isChild && prodLink != null && prodLink.Remove_Price__c != null)); }
   } // showPricePerFreq
   
   public Boolean enterUnit{
      get {
         PricebookEntry v_entry = entry;
         System.debug('enterUnit v_entry='+v_entry+' prodLink='+prodLink);
         return (selected && !pricingExistsButDoesntMatch && v_entry != null && v_entry.Product2.Unit_Type__c != null &&
                 (prodLink == null || (prodLink != null && !prodLink.Included_in_Parent_Price__c)));
      }
   } // enterUnit
   
   public Boolean unitChanged{get;set;}
   
   public String unit{
      get{
         return ((oli != null && oli.Unit__c != null) ? String.valueOf(oli.Unit__c.intValue()) : null);
      } // get
      set{
          unitChanged = false;
          try {
             Decimal d_value = Decimal.valueOf(value).intValue();
             // check if the value changed
             if (d_value != oli.Unit__c) {
                unitChanged = true;
                oli.Unit__c = d_value;
             }
          } catch (Exception e) {
            oli.Unit__c.addError('Value \''+value+'\' is not a valid value for Trans Qty');
          }
      } // set
   } // unit
   
   /** Do we show the revenue adjustment value? */
   public Boolean showRevAdj {
      get {
          return ((selected && !pricingExistsButDoesntMatch && hasPricingInfo) || 
                  (oli != null && oli.Rev_Adj__c != null && oli.Rev_Adj__c != 0));
      } // get
   } // showRevAdj

   /** Get the revenue adjustment as a String so we can format it. */
   public String revAdj {
        get {
           return ((oli != null && oli.Rev_Adj__c != null) ? String.valueOf(oli.Rev_Adj__c.setScale(2)) : null);
        }
        set {
          if (value == null || value == '') {
             oli.Rev_Adj__c = null;
          } else {
             try {
               oli.Rev_Adj__c = Decimal.valueOf(value);
             } catch (Exception e) {
               oli.Rev_Adj__c.addError('Value \''+value+'\' is not a valid value for Rev Adj');
             } // try
          }
        } // set
   } // revAdj
   
   /** The estimated revenue. */
   public String estRev {
        get {
           return ((oli != null && oli.TotalPrice != null) ? String.valueOf(oli.TotalPrice.setScale(2)) : null);
        }
        set {
          if (value == null || value == '') {
             oli.TotalPrice = null;
             oli.Estimated_Revenue__c = null;
          } else {
             try {
               oli.TotalPrice = Decimal.valueOf(value);
               oli.Estimated_Revenue__c = oli.TotalPrice;
             } catch (Exception e) {
               oli.TotalPrice.addError('Value \''+value+'\' is not a valid value for Estimated Revenue!');
             } // try
          }
        } // set
   } // revAdj
      
   /** If there's a value in the calced field display it. */
   public Boolean showRevCalcd{
      get {
          return (oli != null && oli.Total_Calced__c != null);
      } // get
   } // showRevCalcd
   
   public Boolean showRevTotal{
      get {
          return ((selected && (hasPricingInfo || !hasEntry)) ||
                  (!selected && isParentSelected && hasRemovePrice));
      } // get
   } // showRevAdj
   
   /** If there is a deduction in the parent price because this product, which is normalls included, is removed. */
   public Boolean hasRemovePrice {
      get {
          return (prodLink != null && prodLink.Remove_Price__c != null);
      }
   } // hasRemovePrice
   
   /** Does this have a payroll unit?
    */
   public Boolean hasPayrollUnit {
      get { return (oli != null && oli.Payroll_Unit__c != null); }
   } // hasPayrollUnit
    
    public Boolean hasNonPayrollUnit {
      get { return (oli != null && oli.Non_Payroll_Unit__c != null); }
   } // hasNonPayrollUnit
   
   /** Get the billing period */
   public String billingPeriod{
      get {
         if (oli != null && oli.Frequency__c != null) {
            if (oli.Frequency__c == 52) {
               return ' /Weekly';
            } else if (oli.Frequency__c == 26) {
               return ' /Bi-Weekly';
            } else if (oli.Frequency__c == 24) {
               return ' /Semi-Monthly';
            } else if (oli.Frequency__c == 12) {
               return ' /Monthly';
            } else if (oli.Frequency__c == 4) {
               return ' /Quarterly';
            } else if (oli.Frequency__c == 2) {
               return ' /Semi-Annually';
            } else if (oli.Frequency__c == 1) {
               return ' /Annually';
            }
         }
         return null;
      } // get
   } // billingPeriod

   public Boolean freeMonthsAllowed{get{return (!pricingExistsButDoesntMatch && maxFreeMonths>0);}}

   /** The maximum number of free months allowed. If 0, no free months allowed. */   
   public Integer maxFreeMonths = 0;
   /** The selected value for free months. */
   public String selectedFreeMonths{
        get {
           if (oli != null && oli.Discount_Free_Months__c != null) {
              return String.valueOf(oli.Discount_Free_Months__c.intValue());
           }
           return null;
        } // get
        set {
           selectedFreeMonths = value;
           // put the selected value into the Setup_Fee__c field so it can be saved.
           if (oli != null) {
              try {
               oli.Discount_Free_Months__c = Decimal.valueOf(value); 
              } catch (Exception e) {
                 oli.Discount_Free_Months__c = null;
              }
           } // if (oli != null
        } // set
   } // selectedFreeMonths

   public List<SelectOption> freeMonthsOptions {
      get { return getMonthOptions(maxFreeMonths); }
   } //freeMonthsOptions
   
   public Boolean discPctAllowed{get{return (!pricingExistsButDoesntMatch && maxDiscMonths>0);}}
   
   /** Does this have a discount percent? */
   public Boolean hasDiscPct {
      get { return (oli != null && oli.Discount_Percent__c != null); }
   } // hasDiscPct
   
   /** The maximum number of discount months allowed. */
   public Integer maxDiscMonths = 0;
   /** The selected value for discount months. */
   public String selectedDiscMonths{
        get {
           if (oli != null && oli.Discount_Months__c != null) {
              return String.valueOf(oli.Discount_Months__c.intValue());
           }
           return null;
        } // get
        set {
           selectedDiscMonths = value;
           // put the selected value into the Setup_Fee__c field so it can be saved.
           try {
            oli.Discount_Months__c = Decimal.valueOf(value); 
           } catch (Exception e) {
              oli.Discount_Months__c = null;
           }
        } // set
   } // selectedDiscMonths
   
   public List<SelectOption> discMonthsOptions {
      get { return getMonthOptions(maxDiscMonths); }
   } //freeMonthsOptions
   
   private List<SelectOption> getMonthOptions(Integer numberMonths) {
      List<SelectOption> monthsOptions = new List<SelectOption>();
      if (numberMonths > 0) {
         monthsOptions.add(new SelectOption('--None--','--None--'));
         for (Integer cnt=1; cnt<= numberMonths; cnt++) {
            monthsOptions.add(new SelectOption(String.valueOf(cnt),String.valueOf(cnt)+(cnt==1 ? + ' Month' : ' Months')));
         }
      } // if (maxFreeMonths
      return monthsOptions;
   } // getMonthOptions
   
   /** Get the product id of the topmost parent product.
    */
   public Id getRollupProductId() {
        if (entry != null && entry.Product2.Rollup_Product__c != null) {
           return entry.Product2.Rollup_Product__c;
        } else if (parent != null) {
         return parent.getRollupProductId();
      } else if (entry != null) {
         return entry.Product2Id;
      }
      return null;
   } // getRollupProductId
   
   /** Is this line item closed for modification? Once the external system id is set, allow no further modifications. */
   public Boolean isClosed{
      get {return (oli != null && oli.Has_External_Id__c != null && oli.Has_External_Id__c == 'true');}
   } // isClosed
   
   public ProductSelector chargebackParent = null;
   public ProductSelector trueupParent = null;
   public ProductSelector referralParent = null;
   
   public Boolean hasChargeback{ get {return chargeback != null;}}
   public Boolean hasTrueup{ get {return trueup != null;}}
   public Boolean hasReferral {get {return referral != null;}}
   
   /** Link the chargeback to the parent record. */
   public ProductSelector chargeback{get;set;}
   /** Link the true-up to the parent record. */
   public ProductSelector trueup{get;set;}
   /** Link the referral to the parent record. */
   public ProductSelector referral{get;set;}
   
   public void addAdjustments(List<ProductSelector> displayRecords) {
      if (trueup != null) {
         displayRecords.add(trueup);
      }
      if (chargeback != null) {
         displayRecords.add(chargeback);
      }
      if (referral != null) {
         displayRecords.add(referral);
      }
   } // addAdjustments
} // ProductSelector