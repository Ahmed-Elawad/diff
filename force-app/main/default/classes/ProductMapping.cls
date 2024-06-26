/* 
 * Map the lookup fields on the object on change.
 *
 * History
 * -------
 * 09/22/2011 Dan Carmen          Created
   08/10/2012 Dan Carmen          Modified getMapping method
   10/03/2012 Dan Carmen          Added check in for Sales Org.
   07/30/2015 Dan Carmen          Change to handle pilot users
   04/05/2019 Dan Carmen          Add in the cache for the default products
   07/22/2020 Jake Hinds          Added Product Name to query

 */
public with sharing class ProductMapping {

   public static void processData(Product_Mapping__c[] pms) {
    
      Set<String> prodCodes = new Set<String>();
    Set<String> salesOrgSet = new Set<String>();
      
      // clear out lookup fields, get product codes
      for (Product_Mapping__c pm : pms) {
         pm.Product__c = null;
         pm.Parent_Product__c = null;
         pm.Product_Parent_Child_Link__c = null;
         pm.PricebookEntryId__c = null;
         pm.PricebookId__c = null;
         pm.Parent_PricebookEntryId__c = null;
         
         if (String.isNotBlank(pm.Sales_Org__c)) {
             if (String.IsNotBlank(pm.Product_Code__c)) {
                prodCodes.add(pm.Product_Code__c);
             }
             if (String.isNotBlank(pm.Parent_Product_Code__c)) {
                prodCodes.add(pm.Parent_Product_Code__c);
             }
             salesOrgSet.add(pm.Sales_Org__c);
         } // if (String.isNotBlank(pm.Sales_Org__c
      } // for (Product_Mapping__c
      
      if (prodCodes.isEmpty()) {
         // no records to process
         return;
      }
      
      String[] salesOrgs = new String[]{};
      salesOrgs.addAll(salesOrgSet);
      
      ProductQuery pq = new ProductQuery();
      Map<String,Pricebook2> pricebookMap = pq.getPricebooksBySalesOrgs(salesOrgs);
      // list of records where pricebook is found
      Product_Mapping__c[] foundPb = new Product_Mapping__c[]{}; 
      
      // check to see if matches found for all sales orgs
      for (Product_Mapping__c pm : pms) {
         if (String.isNotBlank(pm.Sales_Org__c)) {
            Pricebook2 pb = pricebookMap.get(pm.Sales_Org__c);
            if (pb != null) {
               foundPb.add(pm);
            } else if (!pm.DoNotRequireProduct__c) {
               pm.Sales_Org__c.addError('Pricebook was not found for the '+pm.Sales_Org__c+' Sales Org!');
            }
         } // if (pm.Sales_Org__c != null)
      } // for
      // if no matches found, no need to proceed.
      if (foundPb.isEmpty()) {
         return;
      }
      // only proceed with the ones where we found the pricebook
      pms = foundPb;
      
      // create a map by product code and sales org
      Map<String,PricebookEntry> productMap = new Map<String,PricebookEntry>();
      for (String salesOrg : pricebookMap.keySet()) {
        Pricebook2 pb = pricebookMap.get(salesOrg);
         for (PricebookEntry pe : pb.PricebookEntries) {
            // store the products by the sales org and product code
            String key=salesOrg+pe.Product2.ProductCode;
            System.debug('add to map key='+key+'.');
            // only add the product codes we are searching for
            if (prodCodes.contains(pe.Product2.ProductCode)) {
               productMap.put(key,pe);
            }
         } // for (PricebookEntry
      } // for (Pricebook2
      
      Map<String,Product_Mapping__c> hasParentChild = new Map<String,Product_Mapping__c>();
      Set<String> childProdCodes = new Set<String>();
      Set<String> parentProdCodes = new Set<String>();

      for (Product_Mapping__c pm : pms) {
         // get the product ids
         if (String.IsNotBlank(pm.Product_Code__c)) {
            String key = pm.Sales_Org__c+pm.Product_Code__c;
            System.debug('check in map key='+key+'.');
            if (productMap.containsKey(key)) {
               PricebookEntry pe = productMap.get(key);
               pm.PricebookEntryId__c = pe.Id;
               pm.Product__c = pe.Product2Id;
               pm.PricebookId__c = pe.Pricebook2Id;
            } else if (!pm.DoNotRequireProduct__c) {
               pm.Product_Code__c.addError('The Product Code '+pm.Product_Code__c+' could not be found for sales org '+pm.Sales_Org__c+'!');
            }
         }
         if (String.IsNotBlank(pm.Parent_Product_Code__c)) {
            String key = pm.Sales_Org__c+pm.Parent_Product_Code__c;
            if (productMap.containsKey(key)) {
               PricebookEntry pe = productMap.get(key);
               pm.Parent_PricebookEntryId__c = pe.Id;
               pm.Parent_Product__c = pe.Product2Id;
            } else if (!pm.DoNotRequireProduct__c) {
               pm.Parent_Product_Code__c.addError('The Parent Product Code '+pm.Parent_Product_Code__c+' could not be found for sales org '+pm.Sales_Org__c+'!');
            }
         } 

         // if has both parent and child products...
         if (pm.Product__c != null && pm.Parent_Product__c != null) {
            String mapKey = pm.Sales_Org__c + pm.Product__c + pm.Parent_Product__c;
            hasParentChild.put(mapKey,pm);
            childProdCodes.add(pm.Product__c);
            parentProdCodes.add(pm.Parent_Product__c);
         }
      } // for (Product_Mapping__c
      
      // if no parent child relations do not need to proceed.
      if (hasParentChild.isEmpty()) {
         return;
      }
      // get the parent-child relation objects
      for (Product_Parent_Child_Link__c ppcl : [Select Id, Sales_Org__c
                                                      ,Child_Product__c
                                                      ,Parent_Product__c
                                                  FROM Product_Parent_Child_Link__c
                                                 WHERE Child_Product__c in :childProdCodes
                                                   AND Parent_Product__c in :parentProdCodes
                                                   AND Sales_Org__c IN :salesOrgs]) {
         String mapKey = ppcl.Sales_Org__c + ppcl.Child_Product__c + ppcl.Parent_Product__c;
         Product_Mapping__c pm = hasParentChild.get(mapKey);
         if (pm != null) {
            pm.Product_Parent_Child_Link__c = ppcl.Id;
         }
      } // for (Product_Parent_Child_Link__c ppcl
      // if anything happens with the product mappings, remove from cache so they can be reselected.
      CacheManager.removeOrg(CACHE_KEY);
   } // processData
   
   /** Get a Product_Mapping__c record.
    */
   public static Product_Mapping__c getMapping(String mappingKey, String mappingType, String salesOrg) {
      Product_Mapping__c mapping = null;
      String[] mappingKeys = new String[]{mappingKey};
      String[] salesOrgs = new String[]{};
      if (salesOrg != null) {
         salesOrgs.add(salesOrg);
      }
      Product_Mapping__c[] mappings = getMappings(mappingKeys,mappingType,salesOrgs);
      // should only be one record returned - assume this
      if (!mappings.isEmpty()) {
         mapping = mappings.get(0);
      }
      return mapping;
   } // getMapping
   
   /** Get Product_Mapping__c records based on the passed in parameters.
    */
   public static Product_Mapping__c[] getMappings(String[] mappingKeys, String mappingType, String[] salesOrgs) {
      Product_Mapping__c[] mappings = [Select Id
                                             ,Clear_Parent__c
                                             ,IsSetup__c
                                             ,Mapping_Key__c
                                             ,Product__c
                                            ,Product__r.Name
                                             ,Parent_Product__c
                                             ,Product_Parent_Child_Link__c
                                             ,PricebookEntryId__c
                                             ,PricebookId__c
                                             ,Parent_PricebookEntryId__c
                                             ,Sales_Org__c
                                             ,Type__c
                                             ,Use_Net_Revenue__c
                                             ,Use_Revenue2__c
                                             ,Use_Revenue3__c
                                             ,ZipSegmentName__c
                                         from Product_Mapping__c
                                        where Mapping_Key__c in :mappingKeys
                                          and Type__c = :mappingType
                                          and Sales_Org__c in :salesOrgs];
      return mappings;
   } // getMappings
   
   // used for testing purposes.
   public static Boolean CHECK_USER=!Test.isRunningTest();

   public static String getSalesOrg(String recordTypeName, User usr) {
      return getSalesOrg(recordTypeName,usr,CHECK_USER);
   }
   
   public static String getSalesOrg(String recordTypeName, User usr, Boolean checkForPilot) {
      String salesOrg = 'none';
      try {
         if (String.isNotBlank(recordTypeName)) {
            salesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(recordTypeName);
         } else if (usr != null) {
            salesOrg = usr.Sales_Org__c;
         }
   
         // not sure if this is causing problems when running tests in production.
         if (checkForPilot && usr != null && usr.PilotUser__c != null) {
            salesOrg += '-'+usr.PilotUser__c;
         }
      } catch (Exception e) {
         
      }
      System.debug('getSalesOrg salesOrg='+salesOrg);
      return salesOrg;
   } // getSalesOrg
   
   public static String CACHE_KEY='DefaultProductMappings';
   
   public class MappingWrapper {
      public Map<String,Product_Mapping__c> byPricebookIdMap = new Map<String,Product_Mapping__c>();
      public Map<String,Product_Mapping__c> bySalesOrgMap = new Map<String,Product_Mapping__c>();
   } // class MappingWrapper
   
   // use the cache so we don't have to always retrieve this
   public static MappingWrapper getDefaultMappings() {
      MappingWrapper mapWrap = (MappingWrapper)CacheManager.getOrg(CACHE_KEY);
      if (mapWrap == null) {
         mapWrap = new MappingWrapper();
         Product_Mapping__c[] mappings = [Select Id
                                             ,Clear_Parent__c
                                             ,IsSetup__c
                                             ,Mapping_Key__c
                                             ,Product__c
                                             ,Product__r.Name
                                             ,Parent_Product__c
                                             ,Product_Parent_Child_Link__c
                                             ,PricebookEntryId__c
                                             ,PricebookId__c
                                             ,Parent_PricebookEntryId__c
                                             ,Sales_Org__c
                                             ,Type__c
                                             ,Use_Net_Revenue__c
                                             ,Use_Revenue2__c
                                             ,Use_Revenue3__c
                                             ,ZipSegmentName__c
                                         from Product_Mapping__c
                                        where Type__c = :OpptyProducts.MAP_TYPE];
         for (Product_Mapping__c mapping : mappings) {
            if (mapping.PricebookId__c != null) {
               mapWrap.byPricebookIdMap.put(mapping.PricebookId__c,mapping);
            }
            if (mapping.Sales_Org__c != null) {
               mapWrap.bySalesOrgMap.put(mapping.Sales_Org__c,mapping);
            }
         } // for (Product_Mapping__c mapping
         CacheManager.putOrg(CACHE_KEY, mapWrap);
      } // if (mappings == null
      return mapWrap;
   } // getDefaultMappings
   
} // class ProductMapping