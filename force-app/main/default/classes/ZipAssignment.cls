/* 
 * Actions on the Zip Assignment object
 *
 * History
 * -------
 * 04/20/2012 Dan Carmen   Created
   06/06/2012 Dan Carmen   Added logic to ensure Zip_Code_Information__c is linked to Zip_Assignment__c.
                             Link the Zip_Code_Information object to the Zip_Assignment_Change__c object.
   07/18/2012 Dan Carmen   Filter out users that do not have a role id.
   08/22/2012 Dan Carmen   Added logic for a Cost Center field.
   11/21/2012 Dan Carmen   Changed to use person id for Unassigned users
   12/12/2012 Dan Carmen   Added asset criteria
   03/28/2013 Dan Carmen   Added additional changes for wholesalers
   01/30/2014 Dan Carmen   Added checkTerritory method
   10/22/2014 Dan Carmen   Cleaned up code due to NSS coming into Salesforce
   02/08/2016 Dan Carmen   Clean up checkUseCriteria
   06/21/2016 Dan Carmen   Change to handle team members not using zip criteria
   03/25/2017 Dan Carmen   Added future processing for zip assignments
   05/13/2019 Dan Carmen   Ability to create separate change records for clients and prospects
   06/21/2019 Dan Carmen   Update how criteria is evaluated.
   07/15/2020 Dan Carmen   Fix for NPE
   05/25/2021 Dan Carmen   Increment the API version
   03/25/2022 Dan Carmen   Populate the RecordType Ids on the Zip Segment
   05/10/2022 Dan Carmen   Check for delete of Zip Segment
   09/27/2023 Dan Carmen   Remove recursion check, clean up code.
   02/08/2024 Dan Carmen   Try to force the change record creation
   03/04/2024 Dan Carmen   Updated checkZipCodeLength method
   
 */
public with sharing class ZipAssignment {
   // do we want to skip the ZipAssignment trigger actions?
   public static Boolean SKIP_TRIGGER=false;

   public static final String CHANGE_OWNER_FIELD='Owner Fields';
   public static final String CHANGE_TEAM_MEMBER='Team Members';
   public static final String CHANGE_CLIENT='Client Only';
   public static final String CHANGE_PROSPECT='Prospect Only';
   
   /** We want to stop using these and start using the ones in UserHelper. */
   public static String UNASSIGNED_CORE_PERSON_ID=UserHelper.UNASSIGNED_CORE_PERSON_ID;
   public static String UNASSIGNED_MMS_PERSON_ID=UserHelper.UNASSIGNED_MMS_PERSON_ID;
   public static String[] UNASSIGNED = UserHelper.UNASSIGNED;
   public static Set<String> UNASSIGNED_SET = UserHelper.UNASSIGNED_SET;
   
   // The ids of the zip assignments that have owner changes in the before trigger
   public static Set<Id> ownerIdChangeBeforeTrigger = new Set<Id>();
   public static Set<String> zipCodeSetBeforeTrigger = new Set<String>();
    
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      //SObject[] recs = TriggerMethods.checkRecs('ZipAssignment', p_recs, oldMap, isBefore, isAfter, isDelete, 'ZipAssignment', null);
      System.debug('ZipAssignment.handleTrigger recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      //if (recs == null || recs.isEmpty()) {
      //  return;
      //}
      SObjectType objType = (recs != null && !recs.isEmpty() ? recs[0].getSObjectType() : null);
      System.debug('ZipAssignment.handleTrigger objType='+objType);
      if (objType == Zip_Assignment__c.sObjectType) {
         Zip_Assignment__c[] zas = (Zip_Assignment__c[])recs;
         if (isDelete) {
            handleDelete(zas, (Map<Id,Zip_Assignment__c>)oldMap, isBefore, isAfter);
         } else {
            if (isBefore && zas != null) {
               handleBeforeActions(zas, (Map<Id,Zip_Assignment__c>)oldMap);
            } else if (isAfter && zas != null) {
               handleAfterActions(zas, (Map<Id,Zip_Assignment__c>)oldMap);
            } // if (isBefore && zas != null
         }
      } else if (!isDelete && objType == Zip_Segment__c.sObjectType) {
         if (isBefore) {
            handleZipSegmentBefore((Zip_Segment__c[])recs, (Map<Id,Zip_Segment__c>)oldMap);
         }
         if (isAfter) {
            ZipQueries.clearSegments();
         }
      }
   } // handleTrigger
    
   public static void handleZipSegmentBefore(Zip_Segment__c[] segments, Map<Id,Zip_Segment__c> oldMap) {
      Map<String,Schema.RecordTypeInfo> acctRtMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
      Map<String,Schema.RecordTypeInfo> leadRtMap = Lead.SObjectType.getDescribe().getRecordTypeInfosByName();
      Map<String,Schema.RecordTypeInfo> refAcctRtMap = Referral_Account__c.SObjectType.getDescribe().getRecordTypeInfosByName();
      
      // if a specific record type isn't specified for accounts, assume it's for all
      String[] accountDefaultRTs = new String[]{};
      String[] refAcctDefaultRTs = new String[]{};
      for (RecordType__c rt : RecordType__c.getAll().values()) {
         if (rt.ObjectName__c == ObjectHelper.OBJECT_ACCOUNT && rt.UsedInOwnership__c && String.isNotBlank(rt.RecordTypeName__c)) {
            accountDefaultRTs.add(rt.RecordTypeName__c);
         } else if (rt.ObjectName__c == ObjectHelper.OBJECT_REF_ACCOUNT && rt.UsedInOwnership__c && String.isNotBlank(rt.RecordTypeName__c)) {
            refAcctDefaultRTs.add(rt.RecordTypeName__c);
         }
      } // for (RecordType__c rt
      String acctDefaultString = String.join(accountDefaultRTs,';');
      String refAcctDefaultString = String.join(refAcctDefaultRTs,';');
       
      // TODO - add in checks to enforce record type rules
       
      
       
      for (Zip_Segment__c seg : segments) {
         Zip_Segment__c oldSeg = (oldMap != null ? oldMap.get(seg.Id) : null);
         String acctRecTypes = ((String.isNotBlank(seg.AcctOwnerFldName__c) || String.isNotBlank(seg.TeamRole__c))
                                ? (String.isNotBlank(seg.AccountRecordTypes__c) ? seg.AccountRecordTypes__c : acctDefaultString)
                                : null);
         seg.AccountRecordTypeIds__c = getRecordTypeString(acctRecTypes, acctRtMap);
         seg.LeadRecordTypeId__c = getRecordTypeString(seg.LeadRecordTypeName__c, leadRtMap);
         String refRecTypes = (String.isNotBlank(seg.RfrlAcctOwnerFldName__c) 
                                    ? (seg.RfrlAcctOwnerFldName__c != 'OwnerId' && String.isBlank(seg.RfrlRecordTypes__c) ? refAcctDefaultString : seg.RfrlRecordTypes__c)
                                    : null);
         seg.RfrlRecordTypeIds__c = getRecordTypeString(refRecTypes, refAcctRtMap);
      } // for (Zip_Segment__c
       
   } // handleZipSegmentBefore
    
   public static final String ID_SEPARATOR=',';
    
   // always evaluate on zip segment save
   public static String getRecordTypeString(String recordTypes, Map<String,Schema.RecordTypeInfo> rtMap) {
      String retValue = '';
      if (String.isNotBlank(recordTypes)) {
         String[] ids = new String[]{};
         String[] rtNames = recordTypes.split(';');
         for (String rtName : rtNames) {
            Schema.RecordTypeInfo rtInfo = rtMap.get((rtName.trim()));
            System.debug('getRecordTypeString rtName='+rtName+' rtInfo='+(rtInfo != null ? rtInfo.getName() : 'Not Found'));
            if (rtInfo != null) {
               // store in quotes to use directly in a query
               ids.add(rtInfo.getRecordTypeId());
            }
         } // for (String rtName : rtNames
         if (!ids.isEmpty()) {
            retValue = String.join(ids,ID_SEPARATOR);  
         }
      } // if (String.isNotBlank
      return retValue;
   } // getRecordTypeString
    
   public static void handleDelete(Zip_Assignment__c[] zas, Map<Id,Zip_Assignment__c> oldMap, Boolean isBefore, Boolean isAfter) {
     if (isBefore && oldMap != null && !oldMap.isEmpty()) {
       Set<String> zipCodeSet = new Set<String>();
       for (Zip_Assignment__c oldZa : oldMap.values()) {
          zipCodeSet.add(oldZa.Name);
       } // for
       System.debug('handleDelete zipCodeSet='+zipCodeSet.size());
       Set<Id> ownerChangeSet = new Set<Id>();
       checkZipSegmentation(zipCodeSet, ownerChangeSet);
     }
     
   } // handleDelete
   
   public static void handleBeforeActions(Zip_Assignment__c[] zas, Map<Id,Zip_Assignment__c> oldMap) {
      // make sure we have a zip code information record linked
      Zip_Assignment__c[] zaCheckZci = new Zip_Assignment__c[]{};
      // the records to check for a user
      Zip_Assignment__c[] zaCheckUsers = new Zip_Assignment__c[]{};
      // the records to check for the segment
      Zip_Assignment__c[] zaCheckSegments = new Zip_Assignment__c[]{};
      for (Zip_Assignment__c za : zas) {
         Zip_Assignment__c oldZa = (oldMap != null ? oldMap.get(za.Id) : null);
         String checkZip = ZipAssignment.checkZipCodeLength(za.Name,null);
         // since we're not using these fields anymore, make sure they're not set
         // leave these fields in for now since they're referenced in other code.
         if (za.SkipJoinCriteria__c || String.isNotBlank(za.CriteriaToSkip__c)) {
            za.SkipJoinCriteria__c = false;
            za.CriteriaToSkip__c = null;
            zipCodeSetBeforeTrigger.add(za.Name);
         }
         // make sure the zip code is the correct length. 
         // TODO - need to change if we handle international zips
         if (checkZip != za.Name) {
            za.Name = checkZip;
         }
         String key=za.Sales_Org__c + za.Name;
         if (za.QueryKey__c != key) {
            za.QueryKey__c = key;
         }
         if (za.Zip_Code_Information__c == null 
               || (oldZa != null && za.Name != oldZa.Name)) {
            zaCheckZci.add(za);
         }
         if (za.CreateChangeRecord__c && za.Id != null) {
            ownerIdChangeBeforeTrigger.add(za.Id);
            za.CreateChangeRecord__c=false;
         }
         if (za.EvaluateSkipJoin__c && za.Id != null) {
            zipCodeSetBeforeTrigger.add(za.Name);
            za.EvaluateSkipJoin__c = false;
         }
         // set the unassigned user if no user for payroll
         if (za.User__c == null && (za.Sales_Org__c == UserHelper.SO_CORE || za.Sales_Org__c == UserHelper.SO_MMS)) {
            zaCheckUsers.add(za);
         }
         if (za.Zip_Segment__c == null && za.Sales_Org__c != null && za.Segment_Name__c != null) {
            zaCheckSegments.add(za);
         }
      } // for (Zip_Assignment__c za
      if (!zaCheckUsers.isEmpty()) {
         ZipAssignment.checkForUser(zaCheckUsers);
      } // if (!zaCheckUser
   
      if (!zaCheckSegments.isEmpty()) {
         ZipAssignment.checkForSegmentRecord(zaCheckSegments);
      } // if (!zaCheckSegment.isEmpty
      if (!zaCheckZci.isEmpty()) {
         ZipAssignment.checkZipCodeInformation(zaCheckZci);
      } // if (!zaCheckZci

   } // handleBeforeActions
    
   public static void handleAfterActions(Zip_Assignment__c[] zas, Map<Id,Zip_Assignment__c> oldMap) {
      Set<Id> ownerChangeSet = new Set<Id>();
      ownerChangeSet.addAll(ownerIdChangeBeforeTrigger);
      ownerIdChangeBeforeTrigger.clear();
       
      Set<String> zipCodeSet = new Set<String>();
      zipCodeSet.addAll(zipCodeSetBeforeTrigger);
      zipCodeSetBeforeTrigger.clear();
      System.debug('handleAfterActions 1 ownerChangeSet='+ownerChangeSet.size());
       
      for (Zip_Assignment__c za : zas) {
         Zip_Assignment__c oldZa = (oldMap != null ? oldMap.get(za.Id) : null);
         if (oldZa == null || za.User__c != oldZa.User__c) {
            ownerChangeSet.add(za.Id);
         }
         if (oldZa == null || (za.Zip_Segment__c != null && za.Zip_Segment__c != oldZa.Zip_Segment__c) ) {
            // on insert, or if zip segment changes
            zipCodeSet.add(za.Name);
         }
      } // for (Zip_Assignment__c za
      System.debug('handleAfterActions 2 ownerChangeSet='+ownerChangeSet.size()+' zipCodeSet='+zipCodeSet.size());
      if (!zipCodeSet.isEmpty()) {
         checkZipSegmentation(zipCodeSet, ownerChangeSet);
      }
      if (!ownerChangeSet.isEmpty()) {
         createChangeRecords(ownerChangeSet);
      }

   } // handleAfterActions

   public static String[] ownershipSalesOrgs = null;
   
   // Create a change record for all zip codes that do not currently have a pending change record.
   public static void createChangeRecords(Set<Id> ownerChangeIdSet) {
      // select all records including the open requests and pending changes.
      System.debug('createChangeRecords ownerChangeIdSet='+ownerChangeIdSet.size());
      if (ownershipSalesOrgs == null) {
         ownershipSalesOrgs = new String[]{};
    
         for (SalesOrg__c salesOrg : SalesOrg__c.getAll().values()) {
            if (salesOrg.HasOwnership__c) {
               ownershipSalesOrgs.add(salesOrg.Name);
            }
         } // for (SalesOrg__c salesOrg
           
      } // if (ownershipSalesOrgs == null
      System.debug('createChangeRecords setting up ownershipSalesOrgs='+ownershipSalesOrgs.size());
    
      Zip_Assignment__c[] zas = [Select Id
                                     ,Name
                                     ,CreateChangeRecord__c
                                     ,Sales_Org__c
                                     ,Segment_Name__c
                                     ,User__c
                                     ,Zip_Code_Information__c
                                     ,Zip_Segment__c
                                     ,Zip_Segment__r.Id
                                     ,Zip_Segment__r.Name
                                     ,Zip_Segment__r.AcctOwnerFldName__c
                                     ,Zip_Segment__r.AlwaysAssignTeamMember__c
                                     ,Zip_Segment__r.RfrlAcctOwnerFldName__c
                                     ,Zip_Segment__r.HasOwnerOnObject__c
                                     ,Zip_Segment__r.HasTeamMember__c
                                     ,Zip_Segment__r.TeamRole__c
                                     ,(Select Id, Name, ZipAssignment__c
                                             ,ZipSegment__c
                                             ,ZipSegment__r.Id
                                             ,ZipSegment__r.Name
                                             ,ZipSegment__r.AcctOwnerFldName__c
                                             ,ZipSegment__r.AlwaysAssignTeamMember__c
                                             ,ZipSegment__r.RfrlAcctOwnerFldName__c
                                             ,ZipSegment__r.HasOwnerOnObject__c
                                             ,ZipSegment__r.HasTeamMember__c
                                             ,ZipSegment__r.TeamRole__c
                                         From ZipAssignmentFallbacks__r)
                                     ,(Select Id, Name
                                             ,ZipSegment__c
                                         From Zip_Assignment_Changes__r
                                        Where Processed__c=false)
                                 From Zip_Assignment__c
                                Where Id in :ownerChangeIdSet 
                                  and Sales_Org__c in :ownershipSalesOrgs
                                  ];
      // collection of changes we will create
      Zip_Assignment_Change__c[] changesToCreate = new Zip_Assignment_Change__c[]{};
      
      for (Zip_Assignment__c za : zas) {
         // only create a new change if there aren't any previous changes
         if (za.Zip_Segment__r != null) {
            checkCreateChange(za, za.Zip_Segment__r, null, changesToCreate);
            // break out the team members from the ownership fields on the object
         } // if (za.Zip_Segment__r != null
         for (ZipAssignmentFallback__c zaf : za.ZipAssignmentFallbacks__r) {
            checkCreateChange(za, zaf.ZipSegment__r, zaf, changesToCreate);
         }
         
      } // for (Zip_Assignment__c za
      
      if (!changesToCreate.isEmpty()) {
         SKIP_TRIGGER=true;
         DmlHelper.performDML2(changesToCreate, DmlHelper.DML_INSERT, 'ZipAssignment', 'createChangeRecords', 'Create New Changes', true);
         SKIP_TRIGGER=false;
         //insert changesToCreate;
      }
      
   } // createChangeRecords
   
   public static void checkCreateChange(Zip_Assignment__c za, Zip_Segment__c seg, ZipAssignmentFallback__c fallback, Zip_Assignment_Change__c[] changesToCreate) {
      if (seg != null) {
         // make sure there isn't an existing change for this segment
         for (Zip_Assignment_Change__c zac : za.Zip_Assignment_Changes__r) {
             if (zac.ZipSegment__c == seg.Id) {
                System.debug('checkCreateChange change already exists for za='+za.Name+' seg='+seg.Name);
                return;
             }
         } // for (Zip_Assignment_Change__c zac
       
         // break out the team members from the ownership fields on the object
         if (seg.AlwaysAssignTeamMember__c) {
            if (seg.HasTeamMember__c) {
               newChange(CHANGE_TEAM_MEMBER, za, seg, fallback, changesToCreate);
            }
            if (seg.HasOwnerOnObject__c) {
               newChange(CHANGE_OWNER_FIELD, za, seg, fallback, changesToCreate);
            }
          } else {
            if (seg.HasOwnerOnObject__c || seg.HasTeamMember__c) {
               newChange(null, za, seg, fallback, changesToCreate);
            }
         }
      } // if (seg != null
   } // checkCreateChange
      
   public static void newChange(String ownerType, Zip_Assignment__c za, Zip_Segment__c seg, ZipAssignmentFallback__c fallback, Zip_Assignment_Change__c[] changesToCreate) {
      Zip_Assignment_Change__c zac = new Zip_Assignment_Change__c(Zip_Assignment__c = za.Id, ZipSegment__c=seg.Id);
      zac.Zip_Code_Information__c = za.Zip_Code_Information__c;
      zac.ZipAssignmentFallback__c = (fallback != null ? fallback.Id : null);
      zac.OwnershipType__c = ownerType;
      changesToCreate.add(zac);
   } // newChange
      
   // if core or mms, have to have a user - this defines the owner on the account/contact/lead
   // core - ZipAssignment.UNASSIGNED_CORE_PERSON_ID
   // mms - ZIpAssignment.UNASSIGNED_MMS_PERSON_ID
   public static void setTerritoryRep(ZipTerritory__c terr, User p_territoryRep) {
      User territoryRep = p_territoryRep;
      if ((terr.TerritoryRep__c == null || (territoryRep != null && !territoryRep.isActive ))  
           && (terr.Sales_Org__c == UserHelper.SO_CORE || terr.Sales_Org__c == UserHelper.SO_MMS)) {
         String personId = ((terr.Sales_Org__c == UserHelper.SO_MMS) ? UserHelper.UNASSIGNED_MMS_PERSON_ID : UserHelper.UNASSIGNED_CORE_PERSON_ID);
         // select the user
         territoryRep = new UserHelper().getUserByPersonId(personId);
         terr.TerritoryRep__c = (territoryRep != null ? territoryRep.Id : null);

      } // if (editTerritoryRecord.TerritoryRep__c == null
      
      // populate the rep name if a user is selected
      if (terr.TerritoryRep__c != null && String.isBlank(terr.Rep_Name__c)) {
         // select the user record
         if (territoryRep == null) {
            territoryRep = new UserHelper().getUserById(terr.TerritoryRep__c);
         }
         if (territoryRep != null) {
            terr.Rep_Name__c = territoryRep.Name;
         }
      } // if (editTerritoryRecord.TerritoryRep__c != null

   } // setTerritoryRep
   
   /** Find a User if a person id is set but the User lookup is not.
       If a Core or MMS record, always set an owner
    */
   public static void checkForUser(Zip_Assignment__c[] zaCheckUsers) {
      // collection for the person ids
      
      User[] users = [Select Id, Name, Cost_Center__c, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c in :UserHelper.UNASSIGNED_SET and UserRoleId != null];
      User unassignedCore = null;
      User unassignedMMS = null;
      for (User usr : users) {
         if (usr.HR_Person_Id__c == UserHelper.UNASSIGNED_CORE_PERSON_ID) {
            unassignedCore = usr;
         } else if (usr.HR_Person_Id__c == UserHelper.UNASSIGNED_MMS_PERSON_ID) {
            unassignedMMS = usr;
         }
      } // for
      
      for (Zip_Assignment__c za : zaCheckUsers) {
         if (za.User__c == null && za.Sales_Org__c == UserHelper.SO_CORE) {
            za.User__c = unassignedCore.Id;
         } else if (za.User__c == null && za.Sales_Org__c == UserHelper.SO_MMS) {
            za.User__c = unassignedMMS.Id;
         }
      }

   } // checkForUser
   
   // Check if a segment record exists. If it does exist, link to it. If it does not exist, create it.
   //    If the information changes, update it.
   public static void checkForSegmentRecord(Zip_Assignment__c[] zaCheckSegments) {
      // look for records based on the segment key - group the records together
      Map<String,List<Zip_Assignment__c>> zipSegmentKeyMap = new Map<String,List<Zip_Assignment__c>>();
      // get the sales orgs to only retrieve the ones we need
      Set<String> salesOrgSet = new Set<String>();
      
      // look for records based on the segment name - group the records together
      for (Zip_Assignment__c za : zaCheckSegments) {
         if (String.isNotBlank(za.Sales_Org__c) && String.isNotBlank(za.Segment_Name__c)) {
            salesOrgSet.add(za.Sales_Org__c);
            String key = getSegmentKey(za);
            Zip_Assignment__c[] zas = (zipSegmentKeyMap.containsKey(key) ? zipSegmentKeyMap.get(key) : new Zip_Assignment__c[]{});
            zas.add(za);
            zipSegmentKeyMap.put(key,zas);
         } // if (String.isNotBlank(za.Sales_Org__c
      } // for (Zip_Assignment__c
      
      System.debug('checkForSegmentRecord number keys in zaCheckSegments='+zaCheckSegments+' zipSegmentKeyMap='+zipSegmentKeyMap.size());
      if (!zipSegmentKeyMap.isEmpty()) {
        // the records to insert
        Zip_Segment__c[] insertSegments = new Zip_Segment__c[]{};
        
        Map<String,Zip_Segment__c> segmentMap = getSegmentKeyMap(salesOrgSet, zipSegmentKeyMap.keySet());
        for (String key : segmentMap.keySet()) {
            // check for the segment and make sure it matches
            checkSegment(key, segmentMap.get(key), zipSegmentKeyMap.get(key), insertSegments);
        }

        System.debug('checkForSegmentRecord insertSegments='+insertSegments.size());
        if (!insertSegments.isEmpty()) {
            // save the records
            DmlHelper.performDML2(insertSegments, DmlHelper.DML_INSERT, 'ZipAssignment', 'checkForSegmentRecord', 'Insert new Zip Segment', true);

            // re-retrieve the segments to get any we just created
            ZipQueries.clearSegments();
            segmentMap = getSegmentKeyMap(salesOrgSet, zipSegmentKeyMap.keySet());
            //segmentMap = getSegmentMap(salesOrgSet, segmentKeyMap.keySet(), segmentMapById, segsBySalesOrgMap);
         } // if (!insertSegments.isEmpty
            
         // make sure the zip assignment records are linked to the appropriate segments
         for (String key : zipSegmentKeyMap.keySet()) {
            Zip_Segment__c segment = segmentMap.get(key);
            List<Zip_Assignment__c> zas = zipSegmentKeyMap.get(key);
            if (segment != null && zas != null) {
               for (Zip_Assignment__c za : zas) {
                  za.Zip_Segment__c = segment.Id;
               }
            } // if (zas != null
         } // for (String key
         
      } // if (!mcIdMap.isEmpty
      
   } // checkForSegmentRecord
    
   public static Map<String,Zip_Segment__c> getSegmentKeyMap(Set<String> salesOrgSet, Set<String> segmentKeySet) {
      Map<String,Zip_Segment__c> segmentKeyMap = new Map<String,Zip_Segment__c>();
      String[] salesOrgList = new String[]{};
      salesOrgList.addAll(salesOrgSet);
      Zip_Segment__c[] segments = ZipQueries.getSegments(salesOrgList);
      for (Zip_Segment__c segment : segments) {
         if (segmentKeySet == null || segmentKeySet.contains(segment.Segment_Key__c)) {
            segmentKeyMap.put(segment.Segment_Key__c, segment);
         }
      } // for (Zip_Segment__c segment : segments
      return segmentKeyMap;
   } // getSegmentKeyMap

   // Find the existing segment record if it exists. If it does exist, check that the values are the same as the incoming record.
   //    If the values are different, update the record. If the values are the same, do nothing. 
   //    If no segment record is found, create a new one.
   public static void checkSegment(String key, Zip_Segment__c segment, List<Zip_Assignment__c> zas, Zip_Segment__c[] insertSegments) {
      // use the first record in the list - since all are part of the same update, all of the values should be the same.
      Zip_Assignment__c za = zas.get(0);
      System.debug('checkSegment za='+za.Sales_Org__c+'-'+za.Name);
      // create a new one if passed in record is null;
      if (segment == null) {
         segment = new Zip_Segment__c(Name=za.Segment_Name__c, Sales_Org__c = za.Sales_Org__c);
         insertSegments.add(segment);
      }
      // look for an existing segment record
      System.debug('checkSegment segment='+segment);
      
   } // checkSegment

   public static String getSegmentKey(Zip_Assignment__c za) {
      String segmentKey = za.Sales_Org__c+'-'+za.Segment_Name__c;
      return segmentKey;
   } // getSegmentKey

   // Ensure that we're returning a correct postal code length.
   public static String checkZipCodeLength(String checkZip, String country) {
      String retZip = null;
      Boolean usPostal = (String.isBlank(country) || country=='US' || country == 'United States');
      if (String.isNotBlank(checkZip) && usPostal) {
         retZip = checkZip;
         if (checkZip.length() < 5) {
            retZip = Utilities.leftPad(checkZip,'0',5);
         } else if (checkZip.length() > 5) {
            // trim if more than 5 characters
            retZip = checkZip.left(5);
         }
      } // if (String.isNotBlank
      return retZip;

   } // checkZipCodeLength
   
   // Populate the Zip_Code_Information__c lookup on the Zip_Assignment object.
   public static void checkZipCodeInformation(Zip_Assignment__c[] zas) {
    // keep track of records for easy reference
    Map<String,List<Zip_Assignment__c>> zaListMap = new Map<String,List<Zip_Assignment__c>>();
    for (Zip_Assignment__c za : zas) {
        za.Zip_Code_Information__c = null;
    
        List<Zip_Assignment__c> zaList = zaListMap.get(za.Name);
        if (zaList == null) {
          zaList = new List<Zip_Assignment__c>();
          zaListMap.put(za.Name,zaList);
        }
       zaList.add(za);
    }
    // query for the zip codes
    Zip_Code_Information__c[] zcis = [Select Id, Name
                                        From Zip_Code_Information__c
                                       Where Name in :zaListMap.keySet()];
      assignZci(zaListMap,zcis);
    
    // if there are values remaining in the map, create new zip code assignment records
    if (!zaListMap.isEmpty()) {
       zcis = new Zip_Code_Information__c[]{};
       for (String zipCode : zaListMap.keySet()) {
          Zip_Code_Information__c zci = new Zip_Code_Information__c(Name=ZipCode, Zip_Code_Key__c='Z'+ZipCode);
          zcis.add(zci);
       }
       insert zcis;
       assignZci(zaListMap,zcis);
    } // if (!zaListMap.isEmpty
   } // checkZipCodeInformation
   
   // Assign the Zip Code Information record to the zip assignment record.
   public static void assignZci(Map<String,List<Zip_Assignment__c>> zaListMap, Zip_Code_Information__c[] zcis) {
      for (Zip_Code_Information__c zci : zcis) {
         List<Zip_Assignment__c> zaList = zaListMap.remove(zci.Name);
         if (zaList != null) {
            for (Zip_Assignment__c za : zaList) {
               za.Zip_Code_Information__c = zci.Id;
            } // for (Zip_Assignment__c
         } // if (zaList != null
      } // for (Zip_Code_Information__c
   } // assignZci
      
   public static void checkZipSegmentation(Set<String> p_zipCodeSet, Set<Id> ownerChangeSet) {

      Zip_Segment__c[] allSegments = ZipQueries.getAllSegments();
      System.debug('checkZipSegmentation allSegments='+allSegments.size());
       
      // group all of the zip code together by name (zip code). This will cause all zip codes to be evaluated
      // more often, but ultimately it should keep things more accurate (no changes will occur if nothing changes)
      Map<String,Zip_Assignment__c[]> zasByNameMap = new Map<String,Zip_Assignment__c[]>();
       
      System.debug('checkZipSegmentation p_zipCodeSet='+p_zipCodeSet.size()+' allSegments='+allSegments.size());
      // select all of the zip codes for the sales orgs of the zips in the trigger so we can evaluate them all together
      for (Zip_Assignment__c[] zas : [Select Id, Name
                                            ,CriteriaToSkip__c
                                            ,QueryKey__c
                                            ,Query_Key__c
                                            ,Sales_Org__c
                                            ,Segment_Name__c
                                            ,SkipJoinCriteria__c
                                            ,UseForReferralSource__c
                                            ,Zip_Segment__c
                                            ,(Select Id, Name, ZipAssignment__c
                                                    ,ZipSegment__c
                                                From ZipAssignmentFallbacks__r)
                                        From Zip_Assignment__c
                                       Where Name in :p_zipCodeSet
                                         and Zip_Segment__c != null]) {
         System.debug('checkZipSegmentation zas='+zas.size());
         for (Zip_Assignment__c za : zas) {
            // group the zip codes together - so all the same zips in the same sales org are together
             
            Zip_Assignment__c[] zasByName = (zasByNameMap.containsKey(za.Name) ? zasByNameMap.get(za.Name) : new Zip_Assignment__c[]{});
            zasByName.add(za);
            zasByNameMap.put(za.Name, zasByName);
            //System.debug('checkUseCriteriaNow setting map key='+za.QueryKey__c+' zasByKey='+zasByKey.size()+' zasByName='+zasByName.size()+' zasByNameMap='+zasByNameMap.size());
            System.debug('checkZipSegmentation zasByName='+zasByName.size()+' zasByNameMap='+zasByNameMap.size());
            //addToMap(za);
         } // for (Zip_Assignment__c za
      } // for (Zip_Assignment__c[] zas
      System.debug('checkZipSegmentation zasByNameMap='+zasByNameMap.size());
      
      //Zip_Assignment__c[] updateZas = new Zip_Assignment__c[]{};
      ZipAssignmentFallback__c[] insertFallbacks = new ZipAssignmentFallback__c[]{};
      ZipAssignmentFallback__c[] updateFallbacks = new ZipAssignmentFallback__c[]{};
      ZipAssignmentFallback__c[] deleteFallbacks = new ZipAssignmentFallback__c[]{};
          
      for (String zipCode : zasByNameMap.keySet()) {
         Zip_Assignment__c[] zas = zasByNameMap.get(zipCode);
         System.debug('checkZipSegmentation zipCode='+zipCode+' zas='+(zas != null ? zas.size() : -1));
         if (zas != null && !zas.isEmpty()) {
            processZipGroup2(zas, allSegments, insertFallbacks, updateFallbacks, deleteFallbacks);
         }
      } // for (String zipCode

      SKIP_TRIGGER=true;
      System.debug('checkZipSegmentation insertFallbacks='+insertFallbacks.size()+' updateFallbacks='+updateFallbacks.size()+' deleteFallbacks='+deleteFallbacks.size());
      checkDeleteFallbacks(deleteFallbacks, ownerChangeSet);
      DmlHelper.performDML2(insertFallbacks, DmlHelper.DML_INSERT, 'ZipAssignment', 'checkZipSegmentation', 'inserting fallback record', false);
      DmlHelper.performDML2(updateFallbacks, DmlHelper.DML_UPDATE, 'ZipAssignment', 'checkZipSegmentation', 'updating fallback record', false);
      ErrorLog.checkSave();
      SKIP_TRIGGER=false;
      
   } // checkZipSegmentation
    
   public static void checkDeleteFallbacks(ZipAssignmentFallback__c[] deleteFallbacks, Set<Id> ownerChangeSet) {
       System.debug('checkDeleteFallbacks deleteFallbacks='+deleteFallbacks.size());
       if (deleteFallbacks.isEmpty()) {
           return;
       }
       // if there are any open change records with these fallbacks, delete them
       // get the ids of the records
       Id[] fallbackIds = new Id[]{};
       System.debug('checkDeleteFallbacks 1 ownerChangeSet='+ownerChangeSet.size());
       for (ZipAssignmentFallback__c fallback : deleteFallbacks) {
          fallbackIds.add(fallback.Id);
          // the zip assignment record should get evaluated for a change
          ownerChangeSet.add(fallback.ZipAssignment__c);
       }
       Zip_Assignment_Change__c[] changes = [Select Id from Zip_Assignment_Change__c where ZipAssignmentFallback__c in :fallbackIds and Processed__c=false];
       System.debug('checkDeleteFallbacks changes='+changes.size()+' ownerChangeSet='+ownerChangeSet.size());
       if (!changes.isEmpty()) {
          delete changes;
       }
       DmlHelper.performDML2(deleteFallbacks, DmlHelper.DML_DELETE, 'ZipAssignment', 'checkDeleteFallbacks', 'deleting fallback records', false);
   } // checkDeleteFallbacks
    
   public class ZipCheck{
       public ZipCheck(Zip_Assignment__c p_za, Zip_Segment__c p_seg) {
          za = p_za;
          seg = p_seg;
       }
       
       public Zip_Assignment__c za;
       public Zip_Segment__c seg;
       
       //public Zip_Segment__c[] foundFallBacks = new Zip_Segment__c[]{};
   } // class ZipCheck
   
   // select all of the zip codes no matter the sales org
   // get primary zip segment assignments
   // group any fallback records
   // if there's a fallback record and also a primary assignment, delete the fallback.
   // if a segment isn't assigned and there isn't a fallback, create one.
   public static void processZipGroup2(Zip_Assignment__c[] zas, Zip_Segment__c[] allSegments
                                      ,ZipAssignmentFallback__c[] insertFallbacks, ZipAssignmentFallback__c[] updateFallbacks, ZipAssignmentFallback__c[] deleteFallbacks) {
      Integer NAME_SIZE = ZipAssignmentFallback__c.Name.getDescribe().getLength();           
      // this map will contain all segments so we can reference them anytime
      Map<Id,Zip_Segment__c> segmentMapById = new Map<Id,Zip_Segment__c>(allSegments);
      // this map we'll remove Zip Segments from as we find them so we'll know which ones aren't assigned
      Map<Id,Zip_Segment__c> checkSegmentMapById = new Map<Id,Zip_Segment__c>(allSegments);
      System.debug('processZipGroup2 1 checkSegmentMapById='+checkSegmentMapById.size());
      // for the zip assignments we find matches for, keep track so we can find them again later
      Map<String,ZipCheck> foundMap = new Map<String,ZipCheck>();
      Map<String,ZipAssignmentFallback__c> foundFallbacks = new Map<String,ZipAssignmentFallback__c>();

      for (Zip_Assignment__c za : zas) {
         // if we find a segment directly linked to a zip assignment, remove that from the map - we don't need to do anything further with it.
         Zip_Segment__c seg = checkSegmentMapById.remove(za.Zip_Segment__c);
         if (seg != null) {
            // store the segment keys we find.
            foundMap.put(seg.Segment_Key__c, new ZipCheck(za,seg));
         }
         // see if there are existing fallback records
         checkForFallbacks(za, segmentMapById, foundFallbacks);
      } // for (Zip_Assignment__c za : zas
      System.debug('processZipGroup2 2 checkSegmentMapById='+checkSegmentMapById.size()+' foundMap='+foundMap.size());
                                          
      // check if any in the foundMap are also in the foundFallbacks - we want to delete these.
      for (String key : foundMap.keySet()) {
         ZipAssignmentFallback__c zaf = foundFallbacks.remove(key);
         if (zaf != null) {
            deleteFallbacks.add(zaf);
         }
      } // for (String key : foundMap.keySet
                                          
      // if there any zip segments left in the segmentByIdMap map, then we will look for existing fallback records (if the fallback segment key has a value). 
      // If there isn't one and we can find a zip assignment in the fallback segment, we will create a record.
      for (Zip_Segment__c seg : checkSegmentMapById.values()) {
          System.debug('seg='+seg.Segment_Key__c+' in foundFallbacks='+foundFallbacks.containsKey(seg.Segment_Key__c)+' FallbackSegment__c='+seg.FallbackSegment__c);
          ZipCheck zipChk = (String.isNotBlank(seg.FallbackSegment__c) ? foundMap.get(seg.FallbackSegment__c) : null);

          // if a fallback record exists, make sure it's attached to the correct zip assignment (incase the fallback segment changes)
          ZipAssignmentFallback__c zaf = foundFallbacks.get(seg.Segment_Key__c);
          if (zaf != null) {
             // if there is no longer a fallback segment on this, delete this fallback.
             if (zipChk == null) {
                deleteFallbacks.add(zaf);
             } else if (zaf.ZipAssignment__c != zipChk.za.Id) {
                // if the zip assignment it was originally attached to changes, update the zip assignment
                String nameValue = (zipChk.za.Name+'-'+seg.FallbackSegment__c+'-'+seg.Name).left(NAME_SIZE);
                zaf.Name = nameValue;
                zaf.ZipAssignment__c = zipChk.za.Id;
                updateFallbacks.add(zaf);
             }
          } else if (zaf == null && zipChk != null) {
             // a fallback segment record doesn't already exist and we have a zip assignment in the fallback segment - create a new one
             // create a new one
             String nameValue = (zipChk.za.Name+'-'+seg.FallbackSegment__c+'-'+seg.Name).left(NAME_SIZE);
             zaf = new ZipAssignmentFallback__c(Name=nameValue, ZipAssignment__c=zipChk.za.Id
                                                                        ,ZipSegment__c=seg.Id);
             insertFallbacks.add(zaf);
          }                                   
      }
   } // processZipGroup2
    
   // if there are existing fallback records saved on the zip assignment, make a list of those.
   public static void checkForFallbacks(Zip_Assignment__c za, Map<Id,Zip_Segment__c> segmentMapById, Map<String,ZipAssignmentFallback__c> foundFallbacks) {
       for (ZipAssignmentFallback__c zaf : za.ZipAssignmentFallbacks__r) {
          Zip_Segment__c seg = segmentMapById.get(zaf.ZipSegment__c);
          if (seg != null) {
             foundFallbacks.put(seg.Segment_Key__c, zaf);
          }
       }
   } // checkForFallbacks

} // class ZipAssignment