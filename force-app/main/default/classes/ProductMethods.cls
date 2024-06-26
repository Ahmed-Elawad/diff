/* 
   Methods for working with the Product (Product2) object
   
  History
  -------
  06/16/2011 Dan Carmen   Created
  04/02/2012 Dan Carmen   Cleaned up methods and tests.
  03/31/2020 Dan Carmen   Add logic to generate a unique id
  08/06/2021 Dan Carmen   Change for Standard Price Book
   
 */
public with sharing class ProductMethods {

   /** Used in normal code execution. */
   public static final String STANDARD='Standard';
   
   public static void checkPricebookEntries(Product2[] checkEntries) {
      // save the sales orgs in a map to prevent duplicates
      Map<String,String> salesOrgMap = new Map<String,String>();
      // get the standard pricebook
      salesOrgMap.put(STANDARD,STANDARD);
      // get the product ids
      Set<Id> prodIds = new Set<Id>();
      
      // get all of the sales orgs
      for (Product2 prod : checkEntries) {
         prodIds.add(prod.Id);
      	if (prod.Sales_Org__c != null) {
      		// to handle multiple sales orgs
      	   String[] salesOrgs = prod.Sales_Org__c.split(';');
      	   for (String salesOrg : salesOrgs) {
               salesOrgMap.put(salesOrg,salesOrg);
      	   }
      	}
      } // for (Product2 prod
      
      // get all of the existing entries for the products
      Map<Id, Map<Id,PricebookEntry>> allEntryMap = getExistingEntries(prodIds);
      
      // get the ids of all of the Pricebooks
      Map<String,Id> pricebookIdMap = new ProductQuery().getPricebookIdsBySalesOrgs(salesOrgMap.values());
      
      // a collection for all of the new entries
      PricebookEntry[] newEntries = new PricebookEntry[]{};
      // the id for the standard pricebook
      Id standardId = (Test.isRunningTest() ? Test.getStandardPricebookId() : pricebookIdMap.get(STANDARD));
      System.debug('checkPricebookEntries standardId='+standardId);
      
      // go through all of the products. Create a PricebookEntry record for each (standard and sales force)
      for (Product2 prod : checkEntries) {
         // handle the standard pricebook
         if (standardId != null) {
            // see if there's already an entry
            PricebookEntry standEntry = findEntry(allEntryMap,prod.Id, standardId);
            if (standEntry == null) {
               System.debug('checkPricebookEntries new standard entry created');
               newEntries.add(createEntry(prod,standardId));
            }
         } // if (standardId != null
         if (prod.Sales_Org__c != null) {

            // to handle multiple sales orgs
            String[] salesOrgs = prod.Sales_Org__c.split(';');
            for (String salesOrg : salesOrgs) {
	            Id pricebookId = pricebookIdMap.get(salesOrg);
	            System.debug('checkPricebookEntries salesOrg='+salesOrg+' pricebookId='+pricebookId);
               if (pricebookId != null) {

                  PricebookEntry checkEntry = findEntry(allEntryMap,prod.Id, pricebookId);
                  if (checkEntry == null) {
                     System.debug('checkPricebookEntries new pricebook entry created');
                     newEntries.add(createEntry(prod,pricebookId));
                  }
               } // if (pricebookId
            } // for (String salesOrg
         } // if (pricebookIdMap
         //prod.IsActive = true;
      } // for (Product2
      
      System.debug('checkPricebookEntries newEntries='+newEntries.size());

      if (!newEntries.isEmpty()) {
         insert newEntries;
      } // if (!entries.isEmpty()
      
      // if anything is left in the allEntryMap, can be deleted
      PricebookEntry[] deleteEntries = new PricebookEntry[]{};
      for (Id prodId : allEntryMap.keySet()) {
      	Map<Id,PricebookEntry> entryMap = allEntryMap.get(prodId);
      	deleteEntries.addAll(entryMap.values());
      }
      
      if (!deleteEntries.isEmpty()) {
         Database.delete(deleteEntries,false);
      }
   } // addToPricebook
   
   /** Get all of the existing pricebook entries for the product ids.
    */
   public static Map<Id, Map<Id,PricebookEntry>> getExistingEntries(Set<Id> prodIds) {
   	PricebookEntry[] entries = [Select Id
   	                                  ,Product2Id
   	                                  ,Pricebook2Id
   	                              From PricebookEntry
   	                             Where Product2Id in :prodIds];
   	Map<Id, Map<Id,PricebookEntry>> allEntryMap = new Map<Id, Map<Id,PricebookEntry>>();
   	for (PricebookEntry entry : entries) {
   	   Map<Id,PricebookEntry> entryMap = allEntryMap.get(entry.Product2Id);
   	   if (entryMap == null) {
   	      entryMap = new Map<Id,PricebookEntry>();
   	      allEntryMap.put(entry.Product2Id,entryMap);
   	   }
   	   entryMap.put(entry.Pricebook2Id,entry);
   	} // for (PricebookEntry
      return allEntryMap;
   } // getExistingEntries
   
   /** See if the entry exists. If it does, return it.
    */
   public static PricebookEntry findEntry(Map<Id, Map<Id,PricebookEntry>> allEntryMap, Id product2Id, Id pricebook2Id) {
      PricebookEntry entry = null;

      Map<Id,PricebookEntry> entryMap = allEntryMap.get(product2Id);
      if (entryMap != null) {
         entry = entryMap.remove(pricebook2Id);
      } // if (entryMap != null
      return entry;
   } // findEntry
   
   public static PricebookEntry createEntry(Product2 prod, Id pricebookId) {
      PricebookEntry entry = new PricebookEntry();
      entry.Pricebook2Id = pricebookId;
      entry.Product2Id = prod.Id;
      entry.UnitPrice = 0;
      entry.UseStandardPrice = false;
      entry.IsActive = true;
      return entry;
   } // createEntry
   
   public static void checkRollupProduct(Product2[] checkRollups) {
      Set<String> prodCodes = new Set<String>();
      Set<String> salesOrgSet = new Set<String>();
      String[] salesOrgs = new String[]{};
   	  
   	// clear out lookup fields, get product codes
      for (Product2 prod : checkRollups) {
      	 prod.Rollup_Product__c = null;
      	 
      	 if (prod.Rollup_Product_Code__c != null) {
      	    prodCodes.add(prod.Rollup_Product_Code__c);
      	 }
      	 if (prod.Sales_Org__c != null && !salesOrgSet.contains(prod.Sales_Org__c)) {
      	    salesOrgSet.add(prod.Sales_Org__c);
      	    salesOrgs.add(prod.Sales_Org__c);
      	 }
      } // for (Product_Mapping__c
      
      if (prodCodes.isEmpty()) {
      	 // no records to process
         return;
      }
      
      ProductQuery pq = new ProductQuery();
      Map<String,Pricebook2> pricebookMap = pq.getPricebooksBySalesOrgs(salesOrgs);
      // list of records where pricebook is found
      Product2[] foundProds = new Product2[]{}; 
      
      // check to see if matches found for all sales orgs
      for (Product2 prod : checkRollups) {
      	if (prod.Sales_Org__c != null) {
            Pricebook2 pb = pricebookMap.get(prod.Sales_Org__c);
            if (pb != null) {
         	   foundProds.add(prod);
            } else {
         	   prod.Sales_Org__c.addError('Pricebook was not found for the '+prod.Sales_Org__c+' Sales Org!');
            }
      	 } // if (pm.Sales_Org__c != null)
      } // for
      // if no matches found, no need to proceed.
      if (foundProds.isEmpty()) {
         return;
      }
      
      // create a map by product code
      Map<String,PricebookEntry> productMap = new Map<String,PricebookEntry>();
      for (Pricebook2 pb : pricebookMap.values()) {
         for (PricebookEntry pe : pb.PricebookEntries) {
            if (prodCodes.contains(pe.Product2.ProductCode)) {
               productMap.put(pe.Product2.ProductCode,pe);
            }
         } // for (PricebookEntry
      } // for (Pricebook2
      
      for (Product2 prod : foundProds) {
      	 // get the product ids
      	 if (prod.Rollup_Product_Code__c != null) {
      	    if (productMap.containsKey(prod.Rollup_Product_Code__c)) {
      	       PricebookEntry pe = productMap.get(prod.Rollup_Product_Code__c);
      	       prod.Rollup_Product__c = pe.Product2Id;
      	    } else {
      	       prod.Rollup_Product_Code__c.addError('The Product Code '+prod.Rollup_Product_Code__c+' could not be found!');
      	    }
      	 }
      	 
      } // for
      
   } // checkRollupProduct
    
    public static void checkForUniqueId(Product2[] prods) {
       Map<String,Product2> prodKeyMap = new Map<String,Product2>();
       for (Product2 prod : prods) {
           if (String.isBlank(prod.cafsl__Part_Number__c)) {
               generateUniqueId(prod,prodKeyMap);
           }
       } // for (Product2 prod : prods
       if (!prodKeyMap.isEmpty()) {
          new ProductMethods().checkForProdDupes(prodKeyMap,1);
       }
    } // checkForUniqueId
    
    // let's keep the size of the data to 50 characters less than the actual field size
    public static Integer ID_FLD_SIZE=Product2.cafsl__Part_Number__c.getDescribe().getLength()-130;
   
    public static void generateUniqueId(Product2 prod, Map<String,Product2> prodKeyMap) {
       String name=Utilities.removeExtraChars(prod.Name, Utilities.ALL_ALPHAS+Utilities.ALL_NUMBERS);
       String prodCode=Utilities.removeExtraChars(prod.ProductCode, Utilities.ALL_ALPHAS+Utilities.ALL_NUMBERS);
       String descrip=Utilities.removeExtraChars(prod.Description, Utilities.ALL_ALPHAS+Utilities.ALL_NUMBERS);
       String family=Utilities.removeExtraChars(prod.Family, Utilities.ALL_ALPHAS+Utilities.ALL_NUMBERS);
       String freq=Utilities.removeExtraChars(prod.PayrollFrequency__c, Utilities.ALL_ALPHAS+Utilities.ALL_NUMBERS);
       String key = name+(String.isNotBlank(prodCode) ? '-'+prodCode : '')+(String.isNotBlank(descrip) ? '-'+descrip : '');
       if (key.length() < ID_FLD_SIZE/2 && String.isNotBlank(family)) {
          key += '-'+family;
       }
       if (key.length() < ID_FLD_SIZE/2 && String.isNotBlank(freq)) {
          key += '-'+freq;
       }
       // make sure the key isn't too long
       key = key.left(ID_FLD_SIZE).toLowerCase();
       String checkKey = key;
       Integer cnt=1;
       // see if the key is already in the map - we'll check for records in the database later.
       while (prodKeyMap.containsKey(checkKey)) {
          checkKey=key+cnt;
          cnt++;
       }
       System.debug('generateUniqueId prod='+prod.Name+' checkKey='+checkKey);
       prod.cafsl__Part_Number__c = checkKey;
       prodKeyMap.put(checkKey,prod);
    } // generateUniqueId
    
    // see if there are any products already out there with the products we've already identified
    public void checkForProdDupes(Map<String,Product2> prodKeyMap, Integer cnt) {
       String[] dupeKeys = getDupeKeys(prodKeyMap.keySet());
       Map<String,Product2> newProdKeyMap = new Map<String,Product2>();
       for (String key : dupeKeys) {
          Product2 prod = prodKeyMap.get(key);
           if (prod != null) {
              String newKey = key+String.valueOf(cnt);
              prod.cafsl__Part_Number__c = newKey;
              newProdKeyMap.put(newKey, prod);
           }
       }
       if (!newProdKeyMap.isEmpty() && cnt < 15) {
          new ProductMethods().checkForProdDupes(newProdKeyMap,cnt+1);
       } else if (!newProdKeyMap.isEmpty() && cnt >= 15) {
          for (Product2 prod : newProdKeyMap.values()) {
             prod.cafsl__Part_Number__c.addError('Could not find a unique value after '+cnt+' tries!');
          }
       }
    } // checkForProdDupes
    
    public String[] getDupeKeys(Set<String> keysToCheck) {
        String[] dupeKeys = new String[]{};
        Product2[] foundProds = [Select Id, Name, cafsl__Part_Number__c from Product2 where cafsl__Part_Number__c in :keysToCheck];
        for (Product2 prod : foundProds) {
           dupeKeys.add(prod.cafsl__Part_Number__c);
        }
        return dupeKeys;
    } // getDupeKeys
    
} // class ProductMethods