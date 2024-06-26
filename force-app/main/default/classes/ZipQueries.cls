/* Queries used with Zip Codes
   
  History
  -------
  03/04/2014 Dan Carmen   Created
  05/16/2014 Cindy Freeman    Added ManagerId and DSA_FSS__c to query
  10/27/2014 Dan Carmen       Added Owned by DSA DSM field.

  11/30/2015 Cindy Freeman    added Zip Segment.AlwaysOnReferralForm__c to query
  06/20/2017 Dan Carmen       Add NSS_Team__c to query
  06/11/2018 Cindy Freeman    Add ZipSegment.LeadRecordTypeName to query
  06/19/2018 Dan Carmen       Add zip segments to cache
  08/13/2018 Cindy Freeman    Add title to query
  08/29/2018 Jacob Hinds    Added ASO partner
  10/02/2018 Cindy Freeman    Added NSS_Team__c to ASO Partner in query
  10/09/2018 Jacob Hinds    Adding many more aso partner fields to query
  04/29/2020 Dan Carmen       Change Zip Segment query to use a fieldSet.
  10/22/2020 Dan Carmen       Add Sales_Division__c to user query
  03/04/2021 Brandon Vidro    Added SMB_Certified__c to user query
  06/08/2021 Jermaine Stukes	Add HR Service Partner fields to userMap query in occordance with APR0118366 - FY22 HR Services Segmentation
  08/25/2021 Dan Carmen         Add Job_Name__c field to the user query
  03/25/2022 Dan Carmen         Updates for Referral Account ownership
  06/19/2023 Dan Carmen         Update getZipUserMap to use fieldsets
  10/06/2023 Dan Carmen         Update getAllSegments query

 */
 
public without sharing class ZipQueries {

   // The value for the Default segment. 
   public static final String SEGMENT_DEFAULT='DEFAULT';
   
   public static Zip_Segment__c[] segments = null;
   
   public static Zip_Segment__c[] getSegments(String[] salesOrgs) {
      setFilterOnSegments(salesOrgs);
      return retSegments;
   } // getSegments
   
   public static Map<Id,Zip_Segment__c> getSegmentMap(String[] salesOrgs) {
      setFilterOnSegments(salesOrgs);
      return retSegmentMap;
   } // getSegmentMap
   
   public static Zip_Segment__c[] retSegments = null;
   public static Map<Id,Zip_Segment__c> retSegmentMap = null;
   
   public static void setFilterOnSegments(String[] salesOrgs) {
      retSegments = new Zip_Segment__c[]{};
      retSegmentMap = new Map<Id,Zip_Segment__c>();
      
      Zip_Segment__c[] allSegments = getAllSegments();
      Set<String> salesOrgSet = new Set<String>();
      if (salesOrgs != null) {
         salesOrgSet.addAll(salesOrgs);
      }
      for (Zip_Segment__c segment : allSegments) {
         if (salesOrgSet.isEmpty() || salesOrgSet.contains(segment.Sales_Org__c)) {
            retSegments.add(segment);
            retSegmentMap.put(segment.Id, segment);
         }
      }
   } // setFilterOnSegments
    
   // clear the zip segments so they'll be reselected
   public static void clearSegments() {
      CacheManager.removeOrg(ZipQueries.SEGMENT_CACHE_KEY);
      ZipQueries.allSegments=null;
   } // clearSegments

   // store the zip segments in the cache   
   public static String SEGMENT_CACHE_KEY='AllZipSegmentsCacheKey';
   
   public static Zip_Segment__c[] allSegments = null;
   // for testing purposes
   public static Boolean queryPerformed = false;
    
   public static String[] segFields = new String[]{'Assistant__r.Id','Assistant__r.Name','Assistant__r.IsActive','Assistant__r.Email'};
    /*
   public static String criteriaSubquery = ' ,(Select Id, ZipSegmentCriteria__c '+
	          ',ZipSegmentCriteria__r.Name '+
	          ',ZipSegmentCriteria__r.Account__c '+
	          ',ZipSegmentCriteria__r.FieldAPIName__c '+
	          ',ZipSegmentCriteria__r.FieldType__c '+
	          ',ZipSegmentCriteria__r.Lead__c '+
	          ',ZipSegmentCriteria__r.Number1__c '+
	          ',ZipSegmentCriteria__r.Number2__c '+
	          ',ZipSegmentCriteria__r.ReferralAccount__c '+
	          ',ZipSegmentCriteria__r.Values__c '+
	      'From ZipSegmentCriteriaLinks__r Where Active__c=true) ';
   */
   // retrieve the segments from the cache if available.
   public static Zip_Segment__c[] getAllSegments() {
      System.debug('getAllSegments 1 allSegments='+(allSegments != null ? allSegments.size() : -1));
      if (allSegments == null) {
         allSegments = (Zip_Segment__c[])CacheManager.getOrg(SEGMENT_CACHE_KEY);
      }
      System.debug('getAllSegments 2 allSegments='+(allSegments != null ? allSegments.size() : -1));
      if (allSegments == null) {
         Set<String> fldSet = new Set<String>();
         DmlHelper.addFieldsToSet(Schema.SObjectType.Zip_Segment__c.fieldSets.ZipQueryFlds, '', fldSet);
         DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ZipQueryFlds, 'Assistant__r.', fldSet);
         DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ZipQueryFlds, 'Manager__r.', fldSet);
         String query = DmlHelper.buildQueryFromSet(fldSet,'');
         fldSet.clear();
         ObjectHelper.getSOQLQuery('ZipSegmentCriteriaLink__c', null, true, false, true, false, true);
         if (ObjectHelper.latestSoqlWrapper != null) {
            fldSet.addAll(ObjectHelper.latestSoqlWrapper.flds);
         }
         ObjectHelper.getSOQLQuery('ZipSegmentCriteria__c', null, true, false, true, false, true);
         for (String fldName : ObjectHelper.latestSoqlWrapper.flds) {
            fldSet.add('ZipSegmentCriteria__r.'+fldName);
         } // for (String fldName : ObjectHelper
         String subQuery = DmlHelper.buildQueryFromSet(fldSet,'ZipSegmentCriteriaLinks__r');
         query += ' ,('+subquery+' Where Active__c=true) ';
         query += ' From Zip_Segment__c order by Sort_Order__c, Name, Emps_Min__c';

         System.debug('getAllSegments query='+query);
         allSegments = Database.query(query);
         queryPerformed = true;
         CacheManager.putOrg(SEGMENT_CACHE_KEY,allSegments);
      }
      return allSegments;
   } // getAllSegments
    
   // get any additional fields to query on the account based on segmentation
   public static Set<String> getAccountQueryFields() {
      return getObjFields(true, false, false, 'getAccountQueryFields');
   } // getAccountQueryFields
   
   // get any additional fields to query on the lead based on segmentation
   public static Set<String> getLeadQueryFields() {
      return getObjFields(false, true, false, 'getLeadQueryFields');
   } // getLeadQueryFields

   // get any additional fields to query on the referral account based on segmentation
   public static Set<String> getRefAcctQueryFields() {
      return getObjFields(false, false, true, 'getRefAcctQueryFields');
   } // getRefAcctQueryFields
    
   public static Set<String> getObjFields(Boolean isAcct, Boolean isLead, Boolean isRefAcct, String cacheKey) {
      Set<String> fldSet = (Set<String>)CacheManager.getOrg(cacheKey);
      if (fldSet == null) {
          fldSet = new Set<String>();
          ZipSegmentCriteria__c[] allCriteria = [Select Id, Name, Account__c, Lead__c, ReferralAccount__c, FieldAPIName__c from ZipSegmentCriteria__c where FieldAPIName__c != null];
          for (ZipSegmentCriteria__c criteria : allCriteria) {
             if ((isAcct && criteria.Account__c==true)
                 || (isLead && criteria.Lead__c==true)
                 || (isRefAcct && criteria.ReferralAccount__c==true)) {
                fldSet.add(criteria.FieldAPIName__c);
             }
          } // for (ZipSegmentCriteria__c criteria
          CacheManager.putOrg(cacheKey,fldSet);
      } // if (fldSet == null
      return fldSet;
   } // getObjFields
    
   public static Zip_Assignment__c defCoreZip = null;
   public static Zip_Assignment__c defMMSZip = null;
   
   public static void checkDefaultZips() {
      if (defCoreZip == null) {
         // get the unassigned users
         User[] users = [Select Id, IsActive, Name, HR_Person_Id__c, DSA_FSS__c, ManagerId, FirstName, LastName
                               ,Job_Name__c, Profile.Name
                               ,Cost_Center__c
                               ,District_Name__c
                               ,Manager.Email
                               ,Manager.Name
                               ,Manager.UserRoleId
                               ,Non_Paychex_Employee__c
                               ,Non_Paychex_Employee_User_Type__c
                               ,NSS_Team__c
                               ,SalesOfficeNumber__c
                               ,Sales_Division__c
                               ,Sales_Org__c
                               ,UserRole.Id
                               ,UserRole.Name
                           from User 
                          where IsActive=true and HR_Person_Id__c in :UserHelper.UNASSIGNED_SET];
         for (User usr : users) {
            if (usr.HR_Person_Id__c == UserHelper.UNASSIGNED_CORE_PERSON_ID) {
               defCoreZip = new Zip_Assignment__c(Name=usr.Name, HR_Person_Id__c=usr.HR_Person_Id__c, Rep_Name__c=usr.Name
                                                 ,Sales_Org__c=UserHelper.SO_CORE, User__c=usr.Id, User__r=usr); 
            } else if (usr.HR_Person_Id__c == UserHelper.UNASSIGNED_MMS_PERSON_ID) {
               defMMSZip = new Zip_Assignment__c(Name=usr.Name, HR_Person_Id__c=usr.HR_Person_Id__c, Rep_Name__c=usr.Name
                                                 ,Sales_Org__c=UserHelper.SO_MMS, User__c=usr.Id, User__r=usr); 
            }
         }
      } // if (defCoreZip == null
   } // checkDefaultZips
   
   public static Map<String,List<Zip_Assignment__c>> getZipAsgnMap(Set<String> zipCodes, Boolean useDefaultPayroll) {
      return getZipAsgnMap(zipCodes, useDefaultPayroll, null);
   } // getZipAsgnMap

   // Retrieve all of the zip assignments for the passed in zip codes.
   // if the useDefaultPayroll is passed in as true, will pass back the unassigned users for payroll if there isn't currently
   // a zip assignment record.
   public static Map<String,List<Zip_Assignment__c>> getZipAsgnMap(Set<String> zipCodes, Boolean useDefaultPayroll, Set<String> salesOrgFilterSet) {
      return getZipAsgnMap(zipCodes, useDefaultPayroll, salesOrgFilterSet, null);
   } // getZipAsgnMap
   
   public static String FILTER_REFERRAL_SOURCES='FilterReferral';
   public static String FILTER_ACCOUNTS='FilterAccounts';

   public static Map<String,List<Zip_Assignment__c>> getZipAsgnMap(Set<String> zipCodes, Boolean useDefaultPayroll, Set<String> salesOrgFilterSet, String additionalFilterType) { 

      System.debug('getZipAsgnMap zipCodes='+zipCodes+' useDefaultPayroll='+useDefaultPayroll+' salesOrgFilterSet='+salesOrgFilterSet+' additionalFilterType='+additionalFilterType);
      Map<String,List<Zip_Assignment__c>> zipMap = new Map<String,List<Zip_Assignment__c>>();
      // keep a map of all sales orgs added for each zip code, so we can easily check afterwards if the payroll zips were added.
      Map<String,Set<String>> salesOrgMap = new Map<String,Set<String>>();
      
      if (zipCodes != null && !zipCodes.isEmpty()) {
         Set<Id> userIdSet = new Set<Id>();
         Zip_Assignment__c[] zipsToUse = new Zip_Assignment__c[]{};

         for (Zip_Assignment__c[] zips : [
                          Select Id, Name
                                ,HR_Person_Id__c
                                ,Owned_By_DSA_DSM__c
                                ,OwnerType__c
                                ,Query_Key__c
                                ,Rep_Name__c
                                ,Sales_Org__c
                                ,Segment_Name__c
                                ,SkipJoinCriteria__c
                                ,CriteriaToSkip__c
                                ,District__c
                                ,Organization_Structure__c
                                ,Organization_Structure__r.Name
                                ,Organization_Structure__r.Sales_Office_Number__c
                                ,Organization_Structure__r.District_Name__c
                                ,Organization_Structure__r.RoleId_District__c
                                ,User__c
                                ,User__r.Id
                                ,User__r.Sales_Division__c
                                ,User__r.Name
                                ,Zip_Segment__c
                                ,Zip_Segment__r.Id
                                ,ZipTerritory__r.OverrideAssistant__c
                                ,ZipTerritory__r.OverrideAssistant__r.Id
                                ,ZipTerritory__r.OverrideManager__c
                                ,ZipTerritory__r.OverrideManager__r.Id
                                ,ZipTerritory__r.Rep_Name__c
                                ,ZipTerritory__r.Territory_Nbr__c
                                ,ZipTerritory__r.TerritoryContact__c
                                ,ZipTerritory__r.TerritoryContact__r.Id
                                ,ZipTerritory__r.TerritoryContact__r.FirstName
                                ,ZipTerritory__r.TerritoryContact__r.LastName
                                ,ZipTerritory__r.TerritoryContact__r.Name
                                ,ZipTerritory__r.TerritoryContact__r.Email
                                ,ZipTerritory__r.TerritoryRep__c
                                ,ZipTerritory__r.TerritoryRep__r.Id
                                ,ZipTerritory__r.Zip_Segment__c
                                ,(Select Id, Name, ZipAssignment__c
                                             ,ZipSegment__c
                                             ,ZipSegment__r.Id
                                         From ZipAssignmentFallbacks__r)
                            From Zip_Assignment__c 
                           where Name IN :zipCodes
                           order by Zip_Segment__r.Sort_Order__c, Segment_Rank__c]) {
            System.debug('getZipAsgnMap nbr of zips='+zips.size());
            
            // so we don't have to maintain the segment fields separately.
            Zip_Segment__c[] segments = getAllSegments();
            Map<Id,Zip_Segment__c> segMap = new Map<Id,Zip_Segment__c>(segments);
            // select the users separately because there's a lot of info to select on them.
            for (Zip_Assignment__c zip : zips) {
               // set the zip segment
               zip.Zip_Segment__r=segMap.get(zip.Zip_Segment__c);
               Boolean useZip = checkForFilter(zip.Zip_Segment__r, salesOrgFilterSet, additionalFilterType);
               for (ZipAssignmentFallback__c fallback : zip.ZipAssignmentFallbacks__r) {
                  fallback.ZipSegment__r = segMap.get(fallback.ZipSegment__c);
                  useZip = (useZip || checkForFilter(zip.Zip_Segment__r, salesOrgFilterSet, additionalFilterType));
               } //  for (ZipAssignmentFallback__c fallback
               if (useZip) {
                  zipsToUse.add(zip);
                  checkForUserIds(zip, userIdSet);
               }
            } // for (Zip_Assignment__c zip
            
         } // for (Zip_Assignment__c[] zips

         Map<Id,User> userMap = getZipUserMap(userIdSet);

         // group all of the zips together
         for (Zip_Assignment__c zip : zipsToUse) {
            setUserIds( zip, userMap);
            List<Zip_Assignment__c> zipList = (zipMap.containsKey(zip.Name) ? zipMap.get(zip.Name) : new List<Zip_Assignment__c>());
            Set<String> salesOrgSet = (salesOrgMap.containsKey(zip.Name) ? salesOrgMap.get(zip.Name) : new Set<String>());
            zipList.add(zip);
            salesOrgSet.add(zip.Sales_Org__c);
            zipMap.put(zip.Name,zipList);
            salesOrgMap.put(zip.Name,salesOrgSet);
         } // for (Zip_Assignment__c zip : zips

         if (useDefaultPayroll) {
            checkDefaultZips();
            if (defCoreZip != null && defMMSZip != null) {
               for (String zipCode : zipCodes) {
                  Set<String> salesOrgSet = salesOrgMap.get(zipCode);
                  if (salesOrgSet == null) {
                     // nothing at all was returned for the zip code - just return the default
                     List<Zip_Assignment__c> zipList = new List<Zip_Assignment__c>();
                     zipList.add(defCoreZip);
                     zipList.add(defMMSZip);
                     zipMap.put(zipCode,zipList);
                  } else {
                     List<Zip_Assignment__c> zipList = zipMap.get(zipCode);
                     if (!salesOrgSet.contains(UserHelper.SO_CORE)) {
                        zipList.add(defCoreZip);
                     }
                     if (!salesOrgSet.contains(UserHelper.SO_MMS)) {
                        zipList.add(defMMSZip);
                     }
                  }
               } // for (String zipCode
            } // if (defCoreZip != null && defMMSZip != null
         } // if (useDefaultPayroll
      } // if (zipCodes != null &&
      System.debug('getZipAsgnMap nbr in zipMap='+zipMap.size());
      return zipMap;
   } // getZipAsgns
    
    public static Boolean checkForFilter(Zip_Segment__c seg, Set<String> salesOrgFilterSet, String additionalFilterType) {
       Boolean useZip = (seg != null && (salesOrgFilterSet != null && !salesOrgFilterSet.isEmpty() ? salesOrgFilterSet.contains(seg.Sales_Org__c) : true));
       // ability to do some additional filtering on the zip assignments
       if (useZip && seg != null && String.isNotBlank(additionalFilterType)) {
           if (additionalFilterType == FILTER_REFERRAL_SOURCES) {
              useZip = String.isNotBlank(seg.RfrlAcctOwnerFldName__c);
           } else if (additionalFilterType == FILTER_ACCOUNTS) {
              useZip = (String.isNotBlank(seg.AcctOwnerFldName__c) || String.isNotBlank(seg.TeamRole__c));
           }
        }
       return useZip;
    } // checkForFilter
   
   public static void checkForUserIds(Zip_Assignment__c za, Set<Id> userIdSet) {
      if (za.User__c != null) {
         userIdSet.add(za.User__c);
      }
      if (za.Zip_Segment__r != null && za.Zip_Segment__r.Assistant__c != null) {
         userIdSet.add(za.Zip_Segment__r.Assistant__c);
      }
      if (za.Zip_Segment__r != null && za.Zip_Segment__r.Manager__c != null) {
         userIdSet.add(za.Zip_Segment__r.Manager__c);
      }
      if (za.ZipTerritory__r != null && za.ZipTerritory__r.OverrideAssistant__c != null) {
         userIdSet.add(za.ZipTerritory__r.OverrideAssistant__c);
      }
      if (za.ZipTerritory__r != null && za.ZipTerritory__r.OverrideManager__c != null) {
         userIdSet.add(za.ZipTerritory__r.OverrideManager__c);
      }
      if (za.ZipTerritory__r != null && za.ZipTerritory__r.TerritoryRep__c != null) {
         userIdSet.add(za.ZipTerritory__r.TerritoryRep__c);
      }
   } // checkForUserIds
   
   public static void setUserIds(Zip_Assignment__c za, Map<Id,User> userMap) {
      if (za.User__c != null) {
         za.User__r = userMap.get(za.User__c);
      }
      if (za.Zip_Segment__r != null && za.Zip_Segment__r.Assistant__c != null) {
         za.Zip_Segment__r.Assistant__r = userMap.get(za.Zip_Segment__r.Assistant__c);
      }
      if (za.Zip_Segment__r != null && za.Zip_Segment__r.Manager__c != null) {
         za.Zip_Segment__r.Manager__r = userMap.get(za.Zip_Segment__r.Manager__c);
      }
      if (za.ZipTerritory__r != null && za.ZipTerritory__r.OverrideAssistant__c != null) {
         za.ZipTerritory__r.OverrideAssistant__r = userMap.get(za.ZipTerritory__r.OverrideAssistant__c);
      }
      if (za.ZipTerritory__r != null && za.ZipTerritory__r.OverrideManager__c != null) {
         za.ZipTerritory__r.OverrideManager__r = userMap.get(za.ZipTerritory__r.OverrideManager__c);
      }
      if (za.ZipTerritory__r != null && za.ZipTerritory__r.TerritoryRep__c != null) {
         za.ZipTerritory__r.TerritoryRep__r = userMap.get(za.ZipTerritory__r.TerritoryRep__c);
      }
   } // setUserIds
   
   public static Map<Id,User> getZipUserMap(Set<Id> userIdSet) {
      Map<Id,User> userMap;
      if (!userIdSet.isEmpty()) {
         String userQuery = (String)CacheManager.getOrg('getZipUserMapQuery');
         if (userQuery == null) {
            Set<String> fldSet = new Set<String>();
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ZipUserMapQuery, '', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ZipUserMap_PartnerQry, 'ASO_Partner__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ZipUserMap_PartnerQry, 'HR_Services_Partner__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ZipUserMap_PartnerQry, 'Manager.ASO_Partner__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ZipUserMap_PartnerQry, 'Manager.HR_Services_Partner__r.', fldSet);
            userQuery = DmlHelper.buildQueryFromSet(fldSet,'User');
            CacheManager.putOrg('getZipUserMapQuery',userQuery);
         } // if (userQuery == null
         Id[] userIds = new Id[]{};
         userIds.addAll(userIdSet);
         userQuery = userQuery+' Where Id in :userIds';
         User[] users = Database.query(userQuery);
         userMap = new Map<Id,User>(users);
         /*

         userMap = new Map<Id,User>([Select Id
                                           ,Email
                                           ,FirstName
                                           ,LastName
                                           ,Name
                                           ,ASO_Partner__c
                                           ,ASO_Partner__r.Id          
                                           ,ASO_Partner__r.IsActive        
                                           ,ASO_Partner__r.ManagerId        
                                           ,ASO_Partner__r.Name          
                                           ,ASO_Partner__r.HR_Person_Id__c  
                                           ,ASO_Partner__r.Non_Paychex_Employee__c
                                           ,ASO_Partner__r.Non_Paychex_Employee_User_Type__c
                                           ,ASO_Partner__r.NSS_Team__c
                                           ,ASO_Partner__r.Sales_Org__c
                                           ,ASO_Partner__r.Profile.Name
                                           ,ASO_Partner__r.Title            // CMF
                                           ,Cost_Center__c
                                           ,District_Name__c
                                           ,Hire_Date__c
                                           ,HR_Person_Id__c
                                           ,HR_Services_Partner__c
                                           ,HR_Services_Partner__r.Id          
                                           ,HR_Services_Partner__r.IsActive        
                                           ,HR_Services_Partner__r.ManagerId        
                                           ,HR_Services_Partner__r.Name          
                                           ,HR_Services_Partner__r.HR_Person_Id__c  
                                           ,HR_Services_Partner__r.Non_Paychex_Employee__c
                                           ,HR_Services_Partner__r.Non_Paychex_Employee_User_Type__c
                                           ,HR_Services_Partner__r.NSS_Team__c
                                           ,HR_Services_Partner__r.Sales_Org__c
                                           ,HR_Services_Partner__r.Profile.Name
                                           ,HR_Services_Partner__r.Title  
                                           ,isActive
                                           ,Job_Name__c
                                           ,Profile.Name
                                           ,Manager.Email
                                           ,Manager.Name
                                           ,Manager.UserRoleId
                                           ,Manager.ASO_Partner__c
                                           ,Manager.ASO_Partner__r.Id          
                                           ,Manager.ASO_Partner__r.IsActive        
                                           ,Manager.ASO_Partner__r.ManagerId        
                                           ,Manager.ASO_Partner__r.Name          
                                           ,Manager.ASO_Partner__r.HR_Person_Id__c  
                                           ,Manager.ASO_Partner__r.Non_Paychex_Employee__c
                                           ,Manager.ASO_Partner__r.Non_Paychex_Employee_User_Type__c
                                           ,Manager.ASO_Partner__r.NSS_Team__c
                                           ,Manager.ASO_Partner__r.Sales_Org__c
                                           ,Manager.ASO_Partner__r.Profile.Name
                                           ,Manager.ASO_Partner__r.Title
                                           ,Manager.HR_Services_Partner__c
                                           ,Manager.HR_Services_Partner__r.Id          
                                           ,Manager.HR_Services_Partner__r.IsActive        
                                           ,Manager.HR_Services_Partner__r.ManagerId        
                                           ,Manager.HR_Services_Partner__r.Name          
                                           ,Manager.HR_Services_Partner__r.HR_Person_Id__c  
                                           ,Manager.HR_Services_Partner__r.Non_Paychex_Employee__c
                                           ,Manager.HR_Services_Partner__r.Non_Paychex_Employee_User_Type__c
                                           ,Manager.HR_Services_Partner__r.NSS_Team__c
                                           ,Manager.HR_Services_Partner__r.Sales_Org__c
                                           ,Manager.HR_Services_Partner__r.Profile.Name
                                           ,Manager.HR_Services_Partner__r.Title
                                           ,ManagerId
                                           ,DSA_FSS__c
                                           ,Non_Paychex_Employee__c
                                           ,Non_Paychex_Employee_User_Type__c
                                           ,NSS_Team__c
                                           ,SalesOfficeNumber__c
                                           ,Sales_Division__c
                                           ,Sales_Org__c
                                           ,Selling_Start_Date__c
                                           ,SMB_Certified__c
                                           ,Title
                                           ,UserRole.Id
                                           ,UserRole.Name
                                           ,Zone__c
                                       from User
                                      Where Id in :userIdSet]);
         */
      } else {
         userMap = new Map<Id,User>();
      }
      return userMap;
   } // getZipUserMap

} // class ZipQueries