/* 
 * Queries for the products
 *
 * History
 * -------
 * 05/23/2011 Dan Carmen   Created
   05/16/2012 Dan Carmen   Allow to have multiple sales orgs on prices
   02/14/2013 Dan Carmen   Code modifications to reduce script statements.
   07/30/2015 Dan Carmen   Updates for product mappings
   02/28/2020 Jake Hinds	Adding Default Package
   11/06/2020 Dan Carmen    Cache Pricebooks
   03/25/2021 Dan Carmen    Add cafsl__Part_Number__c and StockKeepingUnit to query  
   07/14/2021 Dan Carmen    rewrite the cache to save the individual pricebooks in separate cache keys versus all in one.
   03/02/2022 Dan Carmen    APR0131613 Updated to assume the Sales_Division__c field from the Pricebook2 could be a list
   04/24/2022 Dan Carmen    Adjust criteria for Pricebook selection.
   12/12/2023 Dan Carmen    Add getProdMap method
   03/06/2024 Dan Carmen    Fix for NPE

*/
public with sharing class ProductQuery {

   // Default constructor.
   public ProductQuery() {
   	
   } // ProductQuery
   
   // Order of searching for a pricebook.
   // If User is not null:
   //     if Pilot User has a value, Will look at salesdivion-Pilot User
   //     Will look at just Sales division
   //     if Pilot user has a value, Will look at sales org-pilot user
   //     look at sales org
   public static Pricebook2 getPrimaryPricebook(User usr, String p_salesOrg, String p_salesDivision) {
      System.debug('getPrimaryPricebook p_salesOrg='+p_salesOrg+' p_salesDivision='+p_salesDivision);
      String salesOrg = p_salesOrg;
      String salesDivision = (String.isNotBlank(p_salesDivision) ? p_salesDivision : (usr != null ? usr.Sales_Division__c : 'NoSalesDiv'));
      String salesDivisionPilot = (usr != null && String.isNotBlank(usr.PilotUser__c) ? salesDivision+'-'+usr.PilotUser__c : 'NoSalesDivPilot');
      if (String.isBlank(salesOrg) && usr != null) {
         SalesOrg__c salesOrgSetting = SalesOrg__c.getInstance(usr.Sales_Org__c);
         if (salesOrgSetting != null && salesOrgSetting.isSales__c) {
            salesOrg = usr.Sales_Org__c;
         } else {
            // default to core
            salesOrg = UserHelper.SO_CORE;
         }
      } // if (String.isBlank(salesOrg)
      System.debug('getPrimaryPricebook usr='+(usr != null ? 'HasUser' : 'NoUser')+' salesOrg='+salesOrg+' salesDivision='+salesDivision);
      Pricebook2 selectedPB = null;
       
      if (String.isNotBlank(salesOrg)) {
         Map<String,Pricebook2[]> pricebookMap = getAllPricebooksBySalesOrgs(new String[]{salesOrg},new String[]{salesDivision,salesDivisionPilot});
         System.debug('getPrimaryPricebook pricebookMap='+pricebookMap.size());
         if (!pricebookMap.isEmpty()) {
             String pilotUser = (usr != null && String.isNotBlank(usr.PilotUser__c) ? usr.PilotUser__c : '');
             if (pricebookMap.containsKey(salesDivisionPilot)) {
                // should only be one value to match this unique key
                selectedPB = pricebookMap.get(salesDivisionPilot)[0];
             } else if (pricebookMap.containsKey(salesDivision)) {
                 System.debug('getPrimaryPricebook contains salesDivision='+salesDivision);
                 for (Pricebook2 pricebook : pricebookMap.get(salesDivision)) {
                     if ((String.isBlank(pilotUser) && String.isBlank(pricebook.Quote_User__c))
                          || (String.isNotBlank(pilotUser) && pricebook.Quote_User__c == pilotUser)) {
                        selectedPB = pricebook;
                     }
                 } // for (Pricebook2 pricebook
             } else if (pricebookMap.containsKey(salesOrg)) {
                 System.debug('getPrimaryPricebook contains salesOrg='+salesOrg);
                 for (Pricebook2 pricebook : pricebookMap.get(salesOrg)) {
                     if ((String.isBlank(pilotUser) && String.isBlank(pricebook.Quote_User__c))
                          || (String.isNotBlank(pilotUser) && pricebook.Quote_User__c == pilotUser)) {
                        selectedPB = pricebook;
                     }
                 } // for (Pricebook2 pricebook
             }
         } // if (!pricebooksBySalesOrgMap
      } // if (String.isNotBlank)
      System.debug('pricebooks selectedPB='+selectedPB);
      return selectedPB;
   } // getPrimaryPricebook

   public static Map<String,Pricebook2[]> getAllPricebooksBySalesOrgs(String[] salesOrgs,String[] salesDivisions) {
      Map<String,Pricebook2[]> pricebookMap = new Map<String,Pricebook2[]>();
      Pricebook2[] pricebooks = new ProductQuery().getPricebooks(new String[]{}, new Id[]{}, salesOrgs, salesDivisions);
      for (Pricebook2 pricebook : pricebooks) {
         addToPricebookMap(pricebook.Sales_Org__c, salesOrgs, pricebook, pricebookMap);
         addToPricebookMap(pricebook.Sales_Org2__c, salesOrgs, pricebook, pricebookMap);
         if (String.isNotBlank(pricebook.Sales_Division__c)) {
            String[] divisions = pricebook.Sales_Division__c.split(',');
            for (String div : divisions) {
               addToPricebookMap(div, salesDivisions, pricebook, pricebookMap);
            }
         }
      } // for (Pricebook2 pricebook
      return pricebookMap;
   } // getAllPricebooksBySalesOrgs
   
   private static void addToPricebookMap(String keyFld, String[] checkList, Pricebook2 pricebook, Map<String,Pricebook2[]> pricebooksBySalesOrgMap) {
      // make sure to only add the ones for the values that were passed in
      if (String.isNotBlank(keyFld) && checkList != null && checkList.contains(keyFld)) {
         Pricebook2[] pbList = (pricebooksBySalesOrgMap.containsKey(keyFld) ? pricebooksBySalesOrgMap.get(keyFld) : new Pricebook2[]{});
         pricebooksBySalesOrgMap.put(keyFld,pbList);
         Boolean pbInList = false;
         for (Pricebook2 pb : pbList) {
            if (pb.Id == pricebook.Id) {
               pbInList=true;
               break;
            }
         } // for (Pricebook2 pb : pbList
         if (!pbInList) {
            pbList.add(pricebook);
         }
         System.debug('addToPricebookMap keyFld='+keyFld+' pbInList='+pbInList+' pbList='+pbList.size());
      } // if (String.isNotBlank(salesOrg
   } // addToPricebookMap
    
   // Get all of the pricebooks based on the sales orgs passed in.
   public Map<String,Pricebook2> getPricebooksBySalesOrgs(String[] salesOrgs) {
   	  Map<String,Pricebook2> pricebookBySalesOrgMap = new Map<String,Pricebook2>();
   	  // get the names of the pricebooks
      Map<String,String> pricebookMap = getPricebookNamesBySalesOrg(salesOrgs);
      System.debug('getPricebooksBySalesOrgs salesOrgs='+salesOrgs.size()+' pricebookMap='+pricebookMap.size());
      if (!pricebookMap.isEmpty()) {
         Pricebook2[] pricebooks = getPricebooks(pricebookMap.values(),new Id[]{});
         // loop through the pricebook map
         for (String salesOrg :pricebookMap.keySet()) {
         	String pricebookName = pricebookMap.get(salesOrg);
         	// loop through the pricebooks retrieved and see if there's a match
         	for (Pricebook2 pb : pricebooks) {
         	   if (pricebookName == pb.Name) {
         	   	  // if match found store in return map and break out of loop
         	      pricebookBySalesOrgMap.put(salesOrg,pb);
         	      break;
         	   } // if (pricebookName
         	} // for (Pricebook2
         } // for (String salesOrg
      } // if (!pricebookMap.isEmpty
      return pricebookBySalesOrgMap;
   } // getPricebooksBySalesOrgs
   
   // Get the name of the Pricebook for the Sales Org passed in.
   public String getPricebookNameBySalesOrg(String salesOrg) {
   	  if (salesOrg != null) {
         String[] salesOrgs = new String[]{salesOrg};
         Map<String,String> pricebookMap = getPricebookNamesBySalesOrg(salesOrgs);
         return pricebookMap.get(salesOrg);
   	  } // if (salesOrg != null
   	  return null;
   } // getPricebookNameBySalesOrg
   
   public Map<String,Id> getPricebookIdsBySalesOrgs(String[] salesOrgs) {
      Map<String,Id> pricebookIdMap = new Map<String,Id>();
      Pricebook2[] pricebooks = [Select Id, Name, Sales_Org__c, Sales_Org2__c 
                                   From Pricebook2
                                  Where (IsActive=true or IsStandard=true)
                                    And (Sales_Org__c in :salesOrgs or Sales_Org2__c in :salesOrgs)];
      for (Pricebook2 pb : pricebooks) {
         pricebookIdMap.put(pb.Sales_Org__c,pb.Id);
         if (String.isNotBlank(pb.Sales_Org2__c)) {
            pricebookIdMap.put(pb.Sales_Org2__c,pb.Id);
         }
      } // for (Pricebook2 pb
      System.debug('getPricebookIdsBySalesOrgs salesOrgs='+salesOrgs.size()+' pricebookIdMap='+pricebookIdMap.size());
      /*
      Product_Pricebook_Map__c[] ppms = [Select Id, Name
                                               ,Sales_Org__c
                                               ,Pricebook_Id__c
                                               ,Pricebook_Name__c
                                           from Product_Pricebook_Map__c
                                          where Sales_Org__c in :salesOrgs];
       System.debug('ppms pricebook ids  = '+ppms);
      for (Product_Pricebook_Map__c ppm : ppms) {
         pricebookIdMap.put(ppm.Sales_Org__c,ppm.Pricebook_Id__c);
      } 
      */
      return pricebookIdMap;
   } // getPricebookIdsBySalesOrgs
    
   /** Get the name of the Pricebooks for the Sales Orgs passed in.
    */
   public Map<String,String> getPricebookNamesBySalesOrg(String[] salesOrgs) {
      Map<String,String> pricebookMap = new Map<String,String>();
      Pricebook2[] pricebooks = [Select Id, Name, Sales_Org__c, Sales_Org2__c 
                                   From Pricebook2
                                  Where (IsActive=true or IsStandard=true)
                                    And (Sales_Org__c in :salesOrgs or Sales_Org2__c in :salesOrgs)];
      for (Pricebook2 pb : pricebooks) {
         pricebookMap.put(pb.Sales_Org__c,pb.Name);
         if (String.isNotBlank(pb.Sales_Org2__c)) {
            pricebookMap.put(pb.Sales_Org2__c,pb.Name);
         }
      } // for (Pricebook2 pb
      System.debug('getPricebookIdsBySalesOrgs salesOrgs='+salesOrgs.size()+' pricebookMap='+pricebookMap.size());
      /*
      Product_Pricebook_Map__c[] ppms = [Select Id, Name
                                               ,Sales_Org__c
                                               ,Pricebook_Id__c
                                               ,Pricebook_Name__c
                                           from Product_Pricebook_Map__c
                                          where Sales_Org__c in :salesOrgs];
      Map<String,String> pricebookMap = new Map<String,String>();
       System.debug('ppms pricebook ids  = '+ppms);
      for (Product_Pricebook_Map__c ppm : ppms) {
         pricebookMap.put(ppm.Sales_Org__c,ppm.Pricebook_Name__c);
      }
      */
      return pricebookMap;
   } // getPricebookNamesBySalesOrg
   
   public Pricebook2 pricebook=null;

   //Get one pricebook and return that to the user. If more than one matches,
   //    the first one retrieved will be returned.
   public Pricebook2 getPricebook(String pricebookName, Id pricebookId) {
   	  System.debug('getPricebook pricebookName='+pricebookName+' pricebookId='+pricebookId);
   	  // default to null
   	  pricebook = null;
   	  String[] pricebookNames = new String[]{};
   	  if (priceBookName != null) {
   	     pricebookNames.add(priceBookName);
   	  }
   	  Id[] pricebookIds = new Id[]{};
   	  if (pricebookId != null) {
   	     pricebookIds.add(pricebookId);
   	  }
   	  Pricebook2[] pricebooks = getPricebooks(pricebookNames,pricebookIds);
   	  // assume only one row returned, so only look at first
   	  if (!pricebooks.isEmpty()) {
   	     pricebook = pricebooks[0];
   	  }

      return pricebook;
   } // getPricebook
   
   // Get all of the pricebooks that match the passed in names and ids.
   public Pricebook2[] getPricebooks(String[] pricebookNames, Id[] pricebookIds) {
      return(getPricebooks(pricebookNames, pricebookIds,new String[]{}));
   }

   // cache key for the pricebooks
   public static final String PB_CACHE_KEY='ProductQueryAllPricebooks';
   public static final String CACHE_KEY='ProductQueryByPricebook';
    
   public static void clearCache() {
      aPBsWrap = (AllPricebooksWrapper)CacheManager.getOrg(PB_CACHE_KEY);
      if (aPBsWrap != null) {
         CacheManager.removeOrg(PB_CACHE_KEY);
         // remove all of the individual pricebooks
         for (Id pbId : aPBsWrap.pbByNameMap.values()) {
            CacheManager.removeOrg(CACHE_KEY+pbId);
         }
      }
      aPBsWrap = null;
   } // clearCache
    
   public class AllPricebooksWrapper {
      public Map<String,Id> pbByNameMap = new Map<String,Id>();
      public Map<String,Set<Id>> pbBySalesOrg = new Map<String,Set<Id>>();
      public Map<String,Set<Id>> pbBySalesDivision = new Map<String,Set<Id>>();
   } // AllPricebooksWrapper
    
   public class PricebookWrapper {
      public Pricebook2 pricebook;
      public Map<Id,PricebookEntry> entryMap = new Map<Id,PricebookEntry>();
   } // PricebookWrapper

   private static AllPricebooksWrapper aPBsWrap = null;

   // get the product information from the cache or query
   public AllPricebooksWrapper getAllPricebooksWrapper() {
      if (aPBsWrap == null) {
         aPBsWrap = (AllPricebooksWrapper)CacheManager.getOrg(PB_CACHE_KEY);
      }
      // not found in the cache - retrieve the data
      if (aPBsWrap == null) {
         aPBsWrap = new AllPricebooksWrapper();
         String query = getQuery()+ ' order by SortOrder__c';
         Pricebook2[] pricebooks = Database.query(query);

         for (Pricebook2 pricebook : pricebooks) {
            // store the name of the pricebook for easy lookup
            aPBsWrap.pbByNameMap.put(pricebook.Name, pricebook.Id);
            // store by the sales orgs for easy lookup
            setSalesOrgMap(pricebook.Sales_Org__c, pricebook.Id);
            setSalesOrgMap(pricebook.Sales_Org2__c, pricebook.Id);
            setSalesDivisionMap(pricebook.Sales_division__c, pricebook.Id);
            setPricebookInCache(pricebook);
         } // for (Pricebook2 pricebook
         CacheManager.putOrg(PB_CACHE_KEY,aPBsWrap);
      } // if (allPBs == null
      return aPBsWrap;
   } // getAllPricebooksWrapper
   
   public static void setPricebookInCache(Pricebook2 pricebook) {
      PricebookWrapper pwb = new PricebookWrapper();
      pwb.pricebook = pricebook;
      for (PricebookEntry entry : pricebook.PricebookEntries) {
         pwb.entryMap.put(entry.Id, entry);
      }
      String cacheKey = CACHE_KEY+pricebook.Id;
      // store each pricebook separately to alleviate cache size problems.
      CacheManager.putOrg(cacheKey,pwb);
   } // setPricebookInCache

   // retrieve pricebooks by id and set in the cache
   public static Pricebook2[] getPricebooksSetInCache(Id[] pbIds) {
      String query = getQuery()+' and Id in :pbIds order by Name ';
      Pricebook2[] pbs = Database.query(query);
      System.debug('getPricebookNoCache pbIds='+pbIds.size()+' pbs='+pbs.size());
      for (Pricebook2 pb : pbs) {
         setPricebookInCache(pb);
      }
      return pbs;
   } // getPricebooksSetInCache

   public static Id prodMapPbId = null;
   public static Map<Id,Product2> pbProdMap = null;
   
   public static Map<Id,Product2> getProdMap(Id pricebook2Id) {
      if (pricebook2Id != null && pricebook2Id != prodMapPbId) {
         pbProdMap = new Map<Id,Product2>();
         Pricebook2 pb = new ProductQuery().getPricebook(null, pricebook2Id);
         System.debug('getProdMap pb='+(pb != null ? pb.Name+'-'+pb.PricebookEntries.size() : 'Not Found'));
         if (pb != null) {
            for (PricebookEntry pbe : pb.PricebookEntries) {
               pbProdMap.put(pbe.Product2Id, pbe.Product2);
            }
         }
      }
      return pbProdMap;
   } // getProdMap
    
   public static String CACHE_QUERY='ProductQueryStaticQuery';
    
   public static String getQuery() {
      String query = (String)CacheManager.getOrg(CACHE_QUERY);
      if (query == null) {
         Set<String> fldSet = new Set<String>();
         DmlHelper.addFieldsToSet(Schema.SObjectType.Pricebook2.fieldSets.ProductQuery, '', fldSet);
         String[] fldList = new String[]{};
         fldList.addAll(fldSet);
         fldList.sort();
         // Pricebook2 fields. 
         query = 'Select '+String.join(fldList,',');
         // Now get the PricebookEntry fields. 
         fldSet.clear();
         DmlHelper.addFieldsToSet(Schema.SObjectType.PricebookEntry.fieldSets.ProductQuery, '', fldSet);
         DmlHelper.addFieldsToSet(Schema.SObjectType.Product2.fieldSets.ProductQuery, 'Product2.', fldSet);
         String subQuery = DmlHelper.buildQueryFromSet(fldSet, 'PricebookEntries');
         subQuery += ' where IsActive=true and Product2.IsActive=true order by Product2.Sort_Order__c, Product2.Name ';
         query += ',('+subQuery+') from Pricebook2 Where IsActive=true ';
         System.debug('getQuery query='+query);
         CacheManager.putOrg(CACHE_QUERY,query);
      }
      return query;
   } // getQuery

   public void setSalesOrgMap(String salesOrg, Id pricebookId) {
      if (String.isNotBlank(salesOrg)) {
         Set<Id> pbIds = (aPBsWrap.pbBySalesOrg.containsKey(salesOrg) ? aPBsWrap.pbBySalesOrg.get(salesOrg) : new Set<Id>());
         pbIds.add(pricebookId);
         aPBsWrap.pbBySalesOrg.put(salesOrg,pbIds);
      }
   } // setSalesOrgMap
   
   public static void setSalesDivisionMap(String salesDivision, Id pricebookId) {
      if (String.isNotBlank(salesDivision)) {
         // in theory a sales division should only represent one pricebook. We'll keep a list just in case.
         String[] divisionTokens = salesDivision.split(',');
         for (String token : divisionTokens) {
            Set<Id> pbIds = (aPBsWrap.pbBySalesDivision.containsKey(token) ? aPBsWrap.pbBySalesDivision.get(token) : new Set<Id>());
            pbIds.add(pricebookId);
            aPBsWrap.pbBySalesDivision.put(token,pbIds);
         }
      } // if (String.isNotBlank(salesDivision
   } // setSalesDivisionMap
    
   public Pricebook2 getPricebookNoCache(String pricebookName) {
      Pricebook2 pricebook = null;
      try {
         String query = getQuery()+' and Name=:pricebookName ';
         pricebook = Database.query(query);
      } catch (Exception e) {
         System.debug('getPricebookNoCache exception: '+e.getMessage());
      }
      return pricebook;
   } // getPricebookNoCache
  
   public Pricebook2[] getPricebooks(String[] pricebookNames, Id[] pricebookIds, String[] salesOrgs) {
      return getPricebooks(pricebookNames, pricebookIds, salesOrgs, new String[]{});
   } // getPricebooks

   public Pricebook2[] getPricebooks(String[] pricebookNames, Id[] pricebookIds, String[] salesOrgs, String[] salesDivisions) {
      pricebookNames = (pricebookNames == null) ? new String[]{} : pricebookNames;
      pricebookIds = (pricebookIds == null) ? new Id[]{} : pricebookIds;
      salesOrgs = (salesOrgs == null) ? new String[]{} : salesOrgs;
      salesDivisions = (salesDivisions == null) ? new String[]{} : salesDivisions;

      System.debug('getPricebooks pricebookNames='+pricebookNames.size()+' pricebookIds='+pricebookIds.size()+ 'salesOrgs='+salesOrgs.size()+' salesDivisions='+salesDivisions.size());
      Pricebook2[] pricebooks = new Pricebook2[]{};
      id[] pricebookIdsFromSalesDivision = new id[]{};
      if (pricebookNames.isEmpty() && pricebookIds.isEmpty() && salesOrgs.isEmpty() && salesDivisions.isEmpty()) {
          return pricebooks;
      }

      AllPricebooksWrapper apbw = getAllPricebooksWrapper();
      // keep track if we have ids but can't retrieve the pricebook. Keep track to reselect
      Id[] pbsNotFound = new Id[]{};
      // to make sure a pricebook is only added to the list once.
      Set<Id> pbsAdded = new Set<Id>();
      for (String pbName : pricebookNames) {
         Id pbId = apbw.pbByNameMap.get(pbName);
         addPricebookToList(pricebooks, pbId, pbsAdded, pbsNotFound);
      } // for (String pbName : pricebookNames

      for (Id pbId : pricebookIds) {
         addPricebookToList(pricebooks, pbId, pbsAdded, pbsNotFound);
      }
      // finding by Id or Name should be primary - not sure we'd need to continue.
      for (String salesDivision : salesDivisions) {
         if (apbw.pbBySalesDivision.containsKey(salesDivision)) {
            Set<Id> pbIdSet = apbw.pbBySalesDivision.get(salesDivision);
            System.debug('Pricebook ids from Sales Division = '+pbIdSet  );
            if (pbIdSet != null) {
               for (Id pbId : pbIdSet) {
                  pricebookIdsFromSalesDivision.add(pbId);
                  addPricebookToList(pricebooks, pbId, pbsAdded, pbsNotFound);
               }
            } 
         }
      } // for (String salesDivision : salesDivisions
      // question: does getting a pb by sales division preclude also getting the pricebook by salesOrg?
      System.debug('pricebookIdsFromSalesDivision = '+pricebookIdsFromSalesDivision.size());
      if (pricebookIdsFromSalesDivision.isEmpty()) {
         for (String salesOrg : salesOrgs) {
            Set<Id> pbIdSet = apbw.pbBySalesOrg.get(salesOrg);
            System.debug('pbIdSet from Pradeep = '+pbIdSet  );
            if (pbIdSet != null) {
                for (Id pbId : pbIdSet) {
                    addPricebookToList(pricebooks, pbId, pbsAdded, pbsNotFound);
                }
            } // if (pbIdSet != null
         } // for (String salesOrg : salesOrgs
           
      }
      if (!pbsNotFound.isEmpty()) {
         pricebooks.addAll(getPricebooksSetInCache(pbsNotFound));
      }
      return pricebooks;
   } // getPricebooks
   
   public void addPricebookToList(Pricebook2[] pricebooks, Id pbId, Set<Id> pbsAdded, Id[] pbsNotFound) {
      if (pbId != null && !pbsAdded.contains(pbId)) {
         PricebookWrapper pwb = (PricebookWrapper)cacheManager.getOrg(CACHE_KEY+pbId);
         if (pwb != null) {
            pbsAdded.add(pbId);
            pricebooks.add(pwb.pricebook);
         } else {
            pbsNotFound.add(pbId);
         }
      } // if (pbId != null

   } // addPricebookToList
   
   public Pricebook2 getPricebook(Id pricebook2Id) {
      Pricebook2 pb = null;
      //System.debug('getPricebook pricebook2Id='+pricebook2Id);
      if (pricebook2Id != null) {
         // make sure pricebooks are selected
         AllPricebooksWrapper apbw = getAllPricebooksWrapper();
         PricebookWrapper pwb = (PricebookWrapper)cacheManager.getOrg(CACHE_KEY+pricebook2Id);
         pb = (pwb != null ? pwb.pricebook : null);
         
      } // if (pricebook2Id != null
      return pb;
   } // getPricebook
    
   public PricebookEntry getEntry(Id pricebook2Id, Id entryId) {
      PricebookEntry entry = null;
      // make sure pricebooks are selected
      AllPricebooksWrapper apbw = getAllPricebooksWrapper();
      PricebookWrapper pwb = (PricebookWrapper)cacheManager.getOrg(CACHE_KEY+pricebook2Id);
      if (pwb != null) {
         entry = pwb.entryMap.get(entryId);
      }
      return entry;
   } // getEntry
   
   /** Get a map of the links for ease of lookup.
    */
   public Map<Id,List<Product_Parent_Child_Link__c>> getProductLinksByParentMap(Id[] parentIds, String salesOrg) {
   	Map<Id,List<Product_Parent_Child_Link__c>> productLinksByParentMap = new Map<Id,List<Product_Parent_Child_Link__c>>();
   	if (parentIds != null && !parentIds.isEmpty()) {
         String tempSalesOrg = '%'+salesOrg+'%';
   	   for (Product_Parent_Child_Link__c[] productLinks : [Select Id, Name
                        ,Add_Price__c
                        ,Child_Product__c
                        ,Child_Product_Code__c
                        ,Enter_Rev_Adj__c
                        ,Included_in_Parent_Price__c
                        ,Include_Type__c
                        ,Parent_Product__c
                        ,Parent_Product_Code__c
                        ,Rev_Adj_If_Parent_And_Child__c
                        ,Price_Schedule_Product_Code__c
                        ,Product_Group__c
                        ,Product_Group_Product_Code__c
                        ,Remove_Price__c
                        ,Rev_Allocation_BW_SM__c
                        ,Rev_Allocation_Monthly__c
                        ,Rev_Allocation_Setup__c
                        ,Rev_Allocation_Weekly__c
                        ,Sales_Org__c
                        ,Sort_Order__c
                    from Product_Parent_Child_Link__c
                   where Parent_Product__c in :parentIds
                     and Child_Product__r.IsActive=true
                     and Parent_Product__r.IsActive=true
                     and Sales_Org__c like :tempSalesOrg
                    order by Sort_Order__c] ) {
            for (Product_Parent_Child_Link__c productLink : productLinks) {
               List<Product_Parent_Child_Link__c> productLinksList = productLinksByParentMap.get(productLink.Parent_Product__c);
               if (productLinksList == null) {
                  productLinksList = new List<Product_Parent_Child_Link__c>();
                  productLinksByParentMap.put(productLink.Parent_Product__c,productLinksList);
               }
               productLinksList.add(productLink);
            } // for (Product_Parent_Child_Link__c productLink
         } // for (Product_Parent_Child_Link__c
      } // if (parentIds != null
      return productLinksByParentMap;
   } // getProductLinksByParentMap
   

} // ProductQuery