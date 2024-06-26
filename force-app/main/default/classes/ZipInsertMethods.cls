/* Methods on the Zip Insert methods
   
  History
  -------
  03/12/2015 Dan Carmen   Created
  09/11/2015 Dan Carmen   Change to handle HRS WHOLESALERS
  09/05/2023 Dan Carmen   Add handleTrigger method to be able to launch a batch from the trigger.
  02/09/2024 Dan Carmen   Extra check for creating a change record
  
 */
public with sharing class ZipInsertMethods {
    
   public static Boolean runImportBatch = false;
    
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> p_oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      if (isBefore) {
         runImportBatch = false;
      }
      ZipImport__c[] recs = (ZipImport__c[])p_recs;
      Map<Id,ZipImport__c> oldMap = (Map<Id,ZipImport__c>)p_oldMap;
      for (ZipImport__c rec : recs) {
         ZipImport__c oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         if (isBefore && oldRec != null && rec.RunBatch__c) {
             runImportBatch = true;
             rec.RunBatch__c = false;
         }
      }
      if (isAfter && runImportBatch) {
         ZipInsertBatch.launchBatch(); 
         runImportBatch = false;
      }
   } // handleTrigger
    
   public static Boolean checkDistrict(List<ZipImportDetail__c> zips) {
      // group by district key
      Map<String,List<ZipImportDetail__c>> zipByDistrictMap = new Map<String,List<ZipImportDetail__c>>();
      Set<String> districtNbrSet = new Set<String>();
      Set<String> salesOrgSet = new Set<String>();
      
      for (ZipImportDetail__c zipDetail : zips) {
         if (zipDetail.ImportFieldsOkay__c) {
            String salesOrg = zipDetail.Sales_Org__c;
            // for wholesalers, use the HRS sales org
            if (salesOrg == UserHelper.SO_WHOLESALER) {
               salesOrg = UserHelper.SO_401;
            }
         	String districtKey = salesOrg+zipDetail.DistrictNbr__c;
         	
            List<ZipImportDetail__c> zipList = zipByDistrictMap.get(districtKey);
            if (zipList == null) {
               zipList = new List<ZipImportDetail__c>();
               zipByDistrictMap.put(districtKey,zipList);
               districtNbrSet.add(zipDetail.DistrictNbr__c);
               salesOrgSet.add(salesOrg);
            }
            zipList.add(zipDetail);
         } else {
            zipDetail.IsSuccess__c = false;
            zipDetail.Processed__c = true;
            zipDetail.Notes__c = 'Required fields for import are not all present';
         }
      } // for (ZipImportDetail
      
      Boolean hasRecordsToProcess = false;
      
      if (!zipByDistrictMap.isEmpty()) {
         hasRecordsToProcess = findDistrictsAndTerritories(zipByDistrictMap, districtNbrSet, salesOrgSet);
      }
      return hasRecordsToProcess;
   } // checkDistrict
   
   private static Boolean findDistrictsAndTerritories(Map<String,List<ZipImportDetail__c>> zipByDistrictMap, Set<String> districtNbrSet, Set<String> salesOrgSet) {
      Boolean hasRecordsToProcess = false;
      Org_Unit__c[] districts = [Select Id, Name, Sales_Org__c
                                       ,(Select Id, Name, District__c
                                               ,Rep_Name__c, Sales_Org__c, TerritoryRep__c, TerritoryRep__r.IsActive
                                               ,TerritoryRep__r.HR_Person_Id__c, TerritoryRep__r.Name
                                               ,Zip_Segment__c, Zip_Segment__r.Name
                                           From Zip_Territories__r
                                           )
                                   From Org_Unit__c
                                  Where Name in :districtNbrSet
                                    and Sales_Org__c in :salesOrgSet
                                    and Org_Type__c = :OrgUnitMethods.TYPE_DISTRICT];
      for (Org_Unit__c district : districts) {
         String districtKey = district.Sales_Org__c+district.Name;
         // remove the value so we can see what's left after
         List<ZipImportDetail__c> zipList = zipByDistrictMap.remove(districtKey);
         if (zipList != null) {
         	Map<String,ZipTerritory__c> territoryMap = getTerritoryMap(district);
         	
            for (ZipImportDetail__c zipDetail : zipList) {
               zipDetail.District__c = district.Id;
               String territoryKey = zipDetail.ZipSegmentName__c+zipDetail.ZipTerritoryName__c;
               ZipTerritory__c territory = territoryMap.get(territoryKey);
               if (territory != null) {
                  // as long as one territory matches, there are records to process
                  hasRecordsToProcess = true;
                  zipDetail.ZipTerritory__r = territory;
               } else {
                  // territory not found
                  zipDetail.IsSuccess__c = false;
                  zipDetail.Processed__c = true;
                  zipDetail.Notes__c = 'Territory not found for Segment '+zipDetail.ZipSegmentName__c+' Territory Name '+zipDetail.ZipTerritoryName__c;
               }
            } 
         } // if (zipList != null
      } // for (Org_Unit__c district
      
      // check for records where district was not found
      for (String districtKey : zipByDistrictMap.keySet()) {
         List<ZipImportDetail__c> zipList = zipByDistrictMap.get(districtKey);
         if (zipList != null) {
            for (ZipImportDetail__c zipDetail : zipList) {
               zipDetail.IsSuccess__c = false;
               zipDetail.Processed__c = true;
               zipDetail.Notes__c = 'District not found for Sales Org '+zipDetail.Sales_Org__c+' Number '+zipDetail.DistrictNbr__c;
            } // for
         } // if (zipList != null
      } // for (String districtKey
      
      return hasRecordsToProcess;
   } // findDistrictsAndTerritories
   
   // make a map of the territories for easy reference
   public static Map<String,ZipTerritory__c> getTerritoryMap(Org_Unit__c district) {
      Map<String,ZipTerritory__c> territoryMap = new Map<String,ZipTerritory__c>();
      for (ZipTerritory__c territory : district.Zip_Territories__r) {
         String key=territory.Zip_Segment__r.Name+territory.Name;
         territoryMap.put(key,territory);
      }
      return territoryMap;
   } // getTerritoryMap
   
   public static Boolean findZipAssignments(List<ZipImportDetail__c> zips, List<Zip_Assignment__c> updateZas, List<ZipImportDetail__c> checkZipDetailInsert, List<Zip_Assignment__c> insertZas) {
      Set<String> salesOrgSet = new Set<String>();
      Set<String> zipSegmentSet = new Set<String>();
      Set<String> zipCodeSet = new Set<String>();
      
      Map<String,ZipImportDetail__c> zipDetailMap = new Map<String,ZipImportDetail__c>();
      
      for (ZipImportDetail__c zipDetail : zips) {
         // only look at records where the Processed flag is false
         if (!zipDetail.Processed__c) {
            salesOrgSet.add(zipDetail.Sales_Org__c);
            zipSegmentSet.add(zipDetail.ZipSegmentName__c);
            zipCodeSet.add(zipDetail.Name);
            String key = zipDetail.Sales_Org__c+zipDetail.Name+zipDetail.ZipSegmentName__c;
            zipDetailMap.put(key,zipDetail);
         } // if (!zipDetail.Processed__c
      } // for (ZipImportDetail__c
      
      // find existing zip codes and move them to the new territories
      if (!zipDetailMap.isEmpty()) {
         Zip_Assignment__c[] zipAssigns = [Select Id, Name
                                                 ,CreateChangeRecord__c
                                                 ,District__c
                                                 ,HR_Person_Id__c
                                                 ,Rep_Name__c
                                                 ,Sales_Org__c
                                                 ,Segment_Name__c
                                                 ,ZipTerritory__c
                                                 ,User__c
                                                 ,Zip_Code_Information__c
                                                 ,Zip_Segment__c
                                             From Zip_Assignment__c
                                            Where Name in :zipCodeSet
                                              and Sales_Org__c in :salesOrgSet
                                              and Segment_Name__c in :zipSegmentSet ];
         for (Zip_Assignment__c zipAssign : zipAssigns) {
            String key = zipAssign.Sales_Org__c+zipAssign.Name+zipAssign.Segment_Name__c;
            // remove found records from the map. Any left in the map means the zip code didn't exist and we'll create a new one.
            ZipImportDetail__c zipDetail = zipDetailMap.remove(key);
            if (zipDetail != null) {
            	updateZas.add(zipAssign);
               zipDetail.Zip_Assignment__c = zipAssign.Id;
               zipDetail.ZipTerritoryOld__c = zipAssign.ZipTerritory__c;
            	setZipAssignmentFields(zipDetail, zipAssign);
            } // if (zipDetail != null
         } // for (Zip_Assignment__c zipAssign
         
      } // if (!zipImportMap.isEmpty()
      
      // anything left - zip should not exist - create a new record
      if (!zipDetailMap.isEmpty()) {
         for (ZipImportDetail__c zipDetail : zipDetailMap.values()) {
            checkZipDetailInsert.add(zipDetail);
            // this should always exist here but just in case
            if (zipDetail.ZipTerritory__r != null) {
               Zip_Assignment__c zipAssign = new Zip_Assignment__c(Name=zipDetail.Name, Sales_Org__c=zipDetail.Sales_Org__c);
               setZipAssignmentFields(zipDetail, zipAssign);
               insertZas.add(zipAssign);
               zipDetail.Zip_Assignment__r = zipAssign;
            }
         } // for (ZipImportDetail__c zipDetail
      	
      } // if (!zipDetailMap.isEmpty()
      return true;
   } // findZipAssignments
   
   public static void setZipAssignmentFields(ZipImportDetail__c zipDetail, Zip_Assignment__c zipAssign) {
      // this should always be true at this point, but check just in case.
      if (zipDetail.ZipTerritory__r != null) {
         zipAssign.District__c = zipDetail.ZipTerritory__r.District__c;
         zipAssign.ZipTerritory__c = zipDetail.ZipTerritory__r.Id;
         // these are because of inserting new zip assigns
         zipAssign.Zip_Segment__c = zipDetail.ZipTerritory__r.Zip_Segment__c;
         zipAssign.Segment_Name__c = zipDetail.ZipTerritory__r.Zip_Segment__r.Name;
         zipAssign.CreateChangeRecord__c = true;
         
         if (zipDetail.ZipTerritory__r.TerritoryRep__r != null && zipDetail.ZipTerritory__r.TerritoryRep__r.IsActive) {
            zipAssign.User__c = zipDetail.ZipTerritory__r.TerritoryRep__c;
            zipAssign.HR_Person_Id__c = zipDetail.ZipTerritory__r.TerritoryRep__r.HR_Person_Id__c;
            zipAssign.Rep_Name__c = zipDetail.ZipTerritory__r.TerritoryRep__r.Name;
         } else {
            zipAssign.User__c = null;
            zipAssign.HR_Person_Id__c = null;
            zipAssign.Rep_Name__c = zipDetail.ZipTerritory__r.Rep_Name__c;
         } // if (zipDetail.ZipTerritory__r.TerritoryRep__r != null
         
         // remove this reference
         zipDetail.ZipTerritory__r = null;
         zipDetail.IsSuccess__c = true;
         zipDetail.Processed__c = true;
      } // if (zipDetail.ZipTerritory__r != null
   } // setZipAssignmentFields
   
   public static void processCompleteZipImports(Set<Id> zipImportIdSet) {
   	// select only the failed detail records to report them to the user
      ZipImport__c[] zipImports = [Select Id, Name, CreatedById, CreatedDate, LastModifiedDate, SystemModStamp
                                         ,JobComplete__c, Notes__c
                                         ,TotalProcessed__c, TotalZipCodes__c
                                         ,(Select Id, Name, DistrictKey__c, ImportFieldsOkay__c, Notes__c
                                             From ZipImportDetails__r 
                                            Where IsSuccess__c=false)
                                     From ZipImport__c
                                    Where Id in :zipImportIdSet
                                      and JobComplete__c = true];

      if (!zipImports.isEmpty()) {
         Messaging.SingleEmailMessage[] emailMessages = new Messaging.SingleEmailMessage[]{};
         for (ZipImport__c zipImport : zipImports) {
            emailMessages.add(createEmailMessage(zipImport));
         } // for (ZipImport__c zipImport
      
         // send the messages
         if (!emailMessages.isEmpty()) {
            Messaging.sendEmail(emailMessages);
         } 
      } // if (!zipImports.isEmpty
   } // processCompleteZipImports
   
   public static Messaging.SingleEmailMessage createEmailMessage(ZipImport__c zipImport) {
      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      email.setSaveAsActivity(false);
         
      Boolean hasErrors = (zipImport.ZipImportDetails__r.size() > 0);
      String subject = 'The Zip Import job completed '+(hasErrors ? 'with errors' : 'successfully');
      
      email.setTargetObjectId(zipImport.CreatedById);
      email.setSubject(subject);
      
      String body = 'The Zip Import job was submitted at '+zipImport.CreatedDate+' and finished processing at '+zipImport.SystemModStamp;
      body += '\nNumber of Zips imported='+zipImport.TotalZipCodes__c;
      body += '\nNumber of Errors='+zipImport.ZipImportDetails__r.size();
      
      if (zipImport.ZipImportDetails__r.size() > 0) {
         body += '\n\nError Details:';
         for (ZipImportDetail__c zipDetail : zipImport.ZipImportDetails__r) {
            body += '\n   '+zipDetail.DistrictKey__c+': '+zipDetail.Notes__c;
         }
      } // if (zipImport.ZipImportDetails__r.size()
      email.setPlainTextBody (body);
      return email;
   } // createEmailMessage
   
} // class ZipInsertMethods