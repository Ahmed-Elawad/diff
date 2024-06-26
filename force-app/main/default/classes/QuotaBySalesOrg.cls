/* 
 * Find the UserRole for the data entered.
 *
 * History
 * -------
 * 09/13/2011 Dan Carmen   Created
   10/04/2011 Dan Carmen   Added role population.
   03/05/2012 Dan Carmen   Added Zone and Area checks
   08/01/2014 Dan Carmen   Rewrote to use the Org Unit object
   10/27/2015 Dan Carmen   Changed to select active and inactive user records.
   11/16/2019 Dan Carmen   Small change to allow tests to pass

 */
public with sharing class QuotaBySalesOrg {

   /** Get the role info and the user info (if found)
    */
   public static void setupLookupData(Quota_By_Sales_Org__c[] allQuotas) {
   	setUsers(allQuotas);
   	  
      setStructureRole(allQuotas);
   } // findUserRoles
   
   /** Set the User information on the Quota record. */
   public static Boolean setUsers(Quota_By_Sales_Org__c[] allQuotas) {
      Set<String> personIds = new Set<String>();
      Set<String> salesOrgs = new Set<String>();
      Map<String,List<Quota_By_Sales_Org__c>> quotaMap = new Map<String,List<Quota_By_Sales_Org__c>>();
   	   for (Quota_By_Sales_Org__c quota : allQuotas) {
   	  	  // clear out the User record
   	  	  quota.User__c = null;
           // clear out the roleid
   	     quota.UserRoleId__c = null;
   	     quota.UserRole_Name__c = null;

   	     if (String.isNotBlank(quota.HR_Person_Id__c) && String.isNotBlank(quota.Sales_Org__c) && String.isNotBlank(quota.Org_Number__c)) {
   	        personIds.add(quota.HR_Person_Id__c);
   	        salesOrgs.add(quota.Sales_Org__c);
   	        String key = quota.Sales_Org__c+quota.HR_Person_Id__c+Utilities.removeLeadingZero(quota.Org_Number__c);
              System.debug('setUsers adding user quota key='+key);
   	        addToQuotaMap(quotaMap,key,quota);
   	     }
   	     
   	  } // for (Quota_By_Sales_Org__c
   	  
        System.debug('setUsers quotaMap='+quotaMap.size());
        // see if we need to continue
   	  if (quotaMap.isEmpty()) {
   	     return true;
   	  }

   	  // select Users
   	  User[] users = [SELECT Id, Name, HR_Person_ID__c, Sales_Org__c, IsActive
   	                        ,District__c, District_Name__c
   	                        ,UserRoleId,UserRole.Name
   	                    FROM User
   	                   WHERE HR_Person_ID__c in :personIds
   	                     //AND IsActive=true
   	                     AND Sales_Org__c in :salesOrgs
   	                    order by IsActive desc];
   	                     
        System.debug('setUsers users='+users.size());
   	  if (users.isEmpty()) {
   	     return true;
   	  }
   	  // store in a map for easy lookup
   	  Map<String,User> userMap = new Map<String,User>();
   	  for (User u : users) {
   	  	  String key = u.Sales_Org__c+u.HR_Person_Id__c+Utilities.removeLeadingZero(u.District__c);
           System.debug('setUsers user='+u.Name+' key='+key);
           if (!userMap.containsKey(key)) {
              userMap.put(key,u);
           }
   	  } // for (User u : users
   	  
   	  for (String key : quotaMap.keySet()) {
   	     List<Quota_By_Sales_Org__c> quotas = quotaMap.get(key);
   	     User u = userMap.get(key);
           System.debug('setUsers quotaMap loop key='+key+' u='+u+' quotas='+quotas);

   	     if (quotas != null && u != null) {
   	     	  System.debug('setUsers inside the if statement');
   	     	  for (Quota_By_Sales_Org__c quota : quotas) {
   	     	     quota.User__c = u.Id;
   	     	     quota.Org_Number__c = (u.District__c != null ? u.District__c : quota.Org_Number__c);
   	     	     quota.Org_Name__c = (u.District_Name__c != null ? u.District_Name__c : quota.Org_Name__c);
      	 	     quota.UserRoleId__c = u.UserRoleId;
      	 	     quota.UserRole_Name__c = u.UserRole.Name;
   	     	  }
   	     } // if (quotas != null
   	  } // for
   	  
      return true;
   } // setUsers
   
   public static void addToQuotaMap(Map<String,List<Quota_By_Sales_Org__c>> quotaMap, String key, Quota_By_Sales_Org__c quota) {
      List<Quota_By_Sales_Org__c> quotas = quotaMap.get(key);
      if (quotas == null) {
         quotas = new List<Quota_By_Sales_Org__c>();
         quotaMap.put(key,quotas);
      }
      quotas.add(quota);
   } // addToQuotaMap
   
   public static Boolean setStructureRole(Quota_By_Sales_Org__c[] allQuotas) {
   	/*
      Set<String> districtNbrs = new Set<String>();
      Set<String> zoneNbrs = new Set<String>();
      Set<String> areaNbrs = new Set<String>();
      Set<String> salesOrgs = new Set<String>();
      Set<String> queryKeySet = new Set<String>();
      //Set<String> distQueryKeys = new Set<String>();
      
      Quota_By_Sales_Org__c[] distQuotas = new Quota_By_Sales_Org__c[]{};
      Quota_By_Sales_Org__c[] zoneQuotas = new Quota_By_Sales_Org__c[]{};
      Quota_By_Sales_Org__c[] areaQuotas = new Quota_By_Sales_Org__c[]{};
      */
      Map<String,List<Quota_By_Sales_Org__c>> quotaListByKeyMap = new Map<String,List<Quota_By_Sales_Org__c>>();

      for (Quota_By_Sales_Org__c quota : allQuotas) {
         // only do it for non-employee records
      	if (String.isNotBlank(quota.Sales_Org__c) && String.isNotBlank(quota.Org_Number__c) 
      	       && String.isNotBlank(quota.Org_Type__c) && String.isBlank(quota.HR_Person_Id__c)) {
      	   addToMap(quotaListByKeyMap, quota);
      	} // if (String.isNotBlank
      	
      	/*
         if (quota.Sales_Org__c != null && quota.Org_Number__c != null) {
            salesOrgs.add(quota.Sales_Org__c); 
      	   // only do it for non-employee records
      	   if (quota.HR_Person_Id__c == null && quota.Org_Type__c == UserHelper.ORG_DISTRICT) {
      	 	   // make sure no leading zeroes
      	 	   //distQueryKeys.add(getQueryKey(quota.Sales_Org__c,quota.Org_Number__c));
      	 	   districtNbrs.add( Utilities.removeLeadingZero(quota.Org_Number__c));
      	 	   distQuotas.add(quota);
      	   } else if (quota.Org_Type__c == UserHelper.ORG_ZONE) {
               zoneNbrs.add( Utilities.removeLeadingZero(quota.Org_Number__c));
               zoneQuotas.add(quota);
            } else if (quota.Org_Type__c == UserHelper.ORG_AREA) {
               areaNbrs.add( Utilities.removeLeadingZero(quota.Org_Number__c));
               areaQuotas.add(quota);
      	   }
         } // if (quota.Sales_Org__c
         */
      } // for
      
      if (!quotaListByKeyMap.isEmpty()) {
      	String[] keyList = new String[]{};
      	keyList.addAll(quotaListByKeyMap.keySet());
         Org_Unit__c[] orgUnits = OrgUnitMethods.getOrgUnits(null, null, null, null, keyList);
         for (Org_Unit__c orgUnit : orgUnits) {
            setQuotaRole(orgUnit, quotaListByKeyMap.get(orgUnit.Query_Key__c));
         }
         
      } // if (!quotaByKeyMap
      
      /*
      // do nothing if no data
      if (districtNbrs.isEmpty() && zoneNbrs.isEmpty() && areaNbrs.isEmpty()) {
      	 return true;
      }
      
      // select the org structure records
      Organization_Structure__c[] strcs = [Select Id, Name, District_Name__c
                                               ,Sales_Org__c, District_Query_Key__c
                                               ,Zone__c, Zone_Name__c
                                               ,Area_Number__c, Area__c
                                               ,RoleId_Sales_Office__c, Role_Sales_Office__c
                                               ,RoleId_District__c, Role_District__c
                                               ,RoleId_Zone__c, Role_Zone__c
                                               ,RoleId_Area__c, Role_Area__c
                                           from Organization_Structure__c
                                          Where Sales_Org__c in :salesOrgs
                                            and (Name in :districtNbrs
                                                 or Zone__c in :zoneNbrs
                                                 or Area_Number__c in :areaNbrs)
                                           Order by Sales_Org__c, Name, RoleId_District__c NULLS LAST];
      //Store in a map for easy reference
      Map<String,Organization_Structure__c> strcMap = new Map<String,Organization_Structure__c>();
      for (Organization_Structure__c strc : strcs) {
      	checkAddToMap(districtNbrs, strc, UserHelper.ORG_DISTRICT, strc.Name, strcMap);
         checkAddToMap(zoneNbrs, strc, UserHelper.ORG_ZONE, strc.Zone__c, strcMap);
         checkAddToMap(areaNbrs, strc, UserHelper.ORG_AREA, strc.Area_Number__c, strcMap);
      } // for
      
      setRoleInfo(distQuotas, UserHelper.ORG_DISTRICT, strcMap);
      setRoleInfo(zoneQuotas, UserHelper.ORG_ZONE, strcMap);
      setRoleInfo(areaQuotas, UserHelper.ORG_AREA, strcMap);
      */
      return true;
   } // setStructureRole
   
   public static void setQuotaRole(Org_Unit__c orgUnit, List<Quota_By_Sales_Org__c> quotaList) {
      if (quotaList != null) {
         for (Quota_By_Sales_Org__c quota : quotaList) {
            quota.UserRole_Name__c = orgUnit.UserRoleName__c;
            quota.UserRoleId__c = orgUnit.UserRoleId__c;
            quota.Org_Name__c = orgUnit.Org_Unit_Name__c;
         }
      } // if (quotaList != null
      
   } // setQuotaOrgUnit
   
   public static void addToMap(Map<String,List<Quota_By_Sales_Org__c>> quotaListByKeyMap, Quota_By_Sales_Org__c quota) {
      String key = getQueryKey2(quota.Org_Type__c, quota.Sales_Org__c, quota.Org_Number__c);
      List<Quota_By_Sales_Org__c> quotaList = quotaListByKeyMap.get(key);
      if (quotaList == null) {
         quotaList = new List<Quota_By_Sales_Org__c>();
         quotaListByKeyMap.put(key,quotaList);
      }
      quotaList.add(quota);
   } // addToMap
   
   /*
   public static void setRoleInfo(Quota_By_Sales_Org__c[] quotas, String orgType, Map<String,Organization_Structure__c> strcMap) {
      for (Quota_By_Sales_Org__c quota : quotas) {
         String queryKey = getQueryKey(orgType,quota.Sales_Org__c,quota.Org_Number__c);
         Organization_Structure__c strc = strcMap.get(queryKey); 
         if (strc != null) {
            if (orgType == UserHelper.ORG_DISTRICT) {
               quota.UserRoleId__c = strc.RoleId_District__c;
               quota.UserRole_Name__c = strc.Role_District__c;
               quota.Org_Name__c = strc.District_Name__c;
            } else if (orgType == UserHelper.ORG_ZONE) {
               quota.UserRoleId__c = strc.RoleId_Zone__c;
               quota.UserRole_Name__c = strc.Role_Zone__c;
               quota.Org_Name__c = strc.Zone_Name__c;
            } else if (orgType == UserHelper.ORG_AREA) {
               quota.UserRoleId__c = strc.RoleId_Area__c;
               quota.UserRole_Name__c = strc.Role_Area__c;
               quota.Org_Name__c = strc.Area__c;
            }
         } // if (strc != null
      } // for (Quota_By_Sales_Org__c quota : distQuotas
   } // setRoleInfo
   
   public static void checkAddToMap(Set<String> orgNbrSet, Organization_Structure__c strc, String orgType, String orgNbr, Map<String,Organization_Structure__c> strcMap) {
      if (orgNbrSet.contains(orgNbr)) {
      	String key = getQueryKey(orgType,strc.Sales_Org__c,orgNbr);
         if (!strcMap.containsKey(key)) {
            strcMap.put(key,strc);
         }
      } // if (!districtNbrs.isEmpty)
   } // checkAddToMap
   
   public static String getQueryKey(String orgType, String salesOrg, String orgNbr) {
      String checkOrgNbr = Utilities.removeLeadingZero(orgNbr);
      return (orgType + salesOrg + checkOrgNbr);
   } // getQueryKey
   */
   public static String getQueryKey2(String orgType, String salesOrg, String orgNbr) {
      String checkOrgNbr = Utilities.removeLeadingZero(orgNbr);
      return (salesOrg + orgType + checkOrgNbr);
   } // getQueryKey
   

} // class QuotaBySalesOrg