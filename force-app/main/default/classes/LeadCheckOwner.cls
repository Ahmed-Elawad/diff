/* 
   Check the zip code. If it's populated and/or changed, set the owner based on the NSS zip codes 
   
  History
  -------
  01/20/2011 Dan Carmen   Created
  09/08/2011 Dan Carmen   Cleaned up the code.   
  06/01/2012 Dan Carmen   Changes for Zip_Assignment__c object
  03/28/2013 Carrie Marciano    Added check for Pending_Leads record type - should not change record type if set to this
  06/12/2014 Dan Carmen   Changes to handle the lead hold out field\
  05/05/2015 Dan Carmen   Added a trim to the product division field to check ownership.
  11/18/2015 Dan Carmen   Changed to use a custom setting for recordtype mapping.
  08/01/2016 Dan Carmen   Change to account for the SkipJoinCriteria__c field when finding a zip assignment
  06/11/2018 Cindy Freeman  modified getZa method to handle PEOCentric logic, set record type for PEO Centric Leads
  08/01/2018 Dan Carmen    Update ownership code to not check ownership for webleads.
  01/16/2019 Dan Carmen    change getZa method to public
  03/19/2019 Jake Hinds    Reworking PEOC to use product division
  06/06/2019 Dan Carmen    Use RecordTypeHelper.cleanRtName
  11/01/2019 Dan Carmen    Change to skip processLeads if Marketo or Connection users. 
  03/11/2020 Dan Carmen    Remove calls to Oasis code.
  03/29/2021 Karthik Pedditi	Update City and State based on ZIPCODE
  01/07/2022 Dan Carmen    Remove references to PeoHelper code
  01/10/2021 Pujitha Madamanchi APR0129320 Removed LeadState code - moved to TrackRecordEntry 
  05/10/2022 Dan Carmen    Update ownership code     
  10/22/2023 Dan Carmen    Update criteria check
  01/02/2024 Dan Carmen    Additional linkage for ZipSegmentCriteriaLink__c for more flexibility

 */
public without sharing class LeadCheckOwner {

   public static String QUEUE_NAME = 'Marketing NSS Queue';
   
   /* Get the usable zip code from a Lead. 
    */
   public static String getZipCode(String checkZip) {
      String zip = ((String.isNotBlank(checkZip) && checkZip.length() >= 5) ? checkZip.left(5) : null);
      return zip;
   } // getZipCode

      
   /** Process the leads that are passed in.
    */
   public static void processLeads(Lead[] leads, Boolean useUpdateLeads) {
      
      //Boolean isConnectionUser = OasisSyncHelper.isRunningUserConnectionUser();      
      UserHelper.setRunningUserAttributes();
      // is the running user the marketo sync user? We don't want to change owner/recordtype on these records
      Boolean isRunningAsMarketo = DoNotSyncCheck.checkCreatedByUser(UserInfo.getUserId());
      system.debug('processLeads leads='+leads.size()+' useUpdateLeads='+useUpdateLeads+' isRunningAsMarketo='+isRunningAsMarketo); //+' isConnectionUser='+isConnectionUser);
      
      // TODO - WILL HAVE TO REEVALUATE THIS. SHOULDN"T HAVE TO DO ANYTHING HERE IF COMING FROM MARKETO OR CONNECTION USER
      //if (isRunningAsMarketo || isConnectionUser) {
      if (isRunningAsMarketo) {
         return;
      }
      
      // a Set of all the zip codes. Use a Set to only keep unique values
      Set<String> zipSet = new Set<String>();
      for (Lead l : leads) {
         String zipCode = getZipCode(l.PostalCode);
         if (zipCode != null) {
            zipSet.add(zipCode);
         } // if (zipCode
      } // for

      Map<String,List<Zip_Assignment__c>> zipListMap = ZipQueries.getZipAsgnMap(zipSet, false);
      
      // only do this if working on existing Lead and we have a Lead Id
      List<Id> leadIdList = new List<Id>();
      for (Lead ld: leads)
      {  if (ld.Id != null)
         {   leadIdList.add(ld.Id); }
      }
       
      //if (!zipListMap.isEmpty()) {
         // get the record types
         Map<String,Schema.RecordTypeInfo> rtByNameMap = Lead.SObjectType.getDescribe().getRecordTypeInfosByName();
         //Map<Id,Schema.RecordTypeInfo> rtByIdMap = Lead.SObjectType.getDescribe().getRecordTypeInfosById();
         //Map<String,Schema.RecordTypeInfo> rtByName = new Map<String,Schema.RecordTypeInfo>();
         //RecordTypeHelper.getRecordTypesMap(ObjectHelper.OBJECT_LEAD,null,rtByName);
         
         // get Pending_Leads record type for exceptioned Bank Leads - we don't want to change record type if already set to this
         Schema.RecordTypeInfo pendingLeadrt = rtByNameMap.get(Label.RT_Pending_Leads);
         Id pendingLeadRtId = (pendingLeadrt != null ? pendingLeadrt.getRecordTypeId() : null);
 
         Schema.RecordTypeInfo nssLeadRt = rtByNameMap.get(Label.RT_NSS_Lead);
         Id nssLeadRtId = (nssLeadRt != null ? nssLeadRt.getRecordTypeId() : null);

         UserHelper uh = new UserHelper();
         
         Lead[] updateLeads = new Lead[]{};
         for (Lead l : leads) {
            // don't process nss webleads
            //Boolean doNotProcess = (l.RecordTypeId == nssLeadRtId && (isRunningAsMarketo || l.OwnedByPrev__c == Label.LeadRouting_Weblead));
            Boolean doNotProcess = false;
            System.debug('processLeads initial check l='+l.Company+' doNotProcess='+doNotProcess);
            // if the first check is true, see if we're running as lead loader
            if (!doNotProcess && l.RecordTypeId == nssLeadRtId && UserHelper.runningUserIsLeadLoader) {
               String ownedBy = (String.isNotBlank(l.OwnedBy__c) ? l.OwnedBy__c : l.OwnedByPrev__c);
               // check the custom setting
               LeadLoaderConfig__c llc = (String.isNotBlank(ownedBy) ? LeadLoaderConfig__c.getInstance(ownedBy) : null);
               if (llc != null) {
                  // do not process if the leadLoaderConfig does not say to use the assignment rules
                  doNotProcess = !llc.UseAssignmentRules__c;
               }
            } // if (!doNotProcess
            
            //Boolean okayToProcess = (l.RecordTypeId != nssLeadRtId || l.OwnedByPrev__c != Label.LeadRouting_Weblead);
            System.debug('processLeads l='+l.Company+' doNotProcess='+doNotProcess+' isRunningAsMarketo='+isRunningAsMarketo+' doNotProcess='+doNotProcess);
            System.debug('processLeads l.RecordTypeId='+l.RecordTypeId+' nssLeadRtId='+nssLeadRtId+' rt not equal='+(l.RecordTypeId != nssLeadRtId));
            System.debug('processLeads l.OwnedByPrev__c='+l.OwnedByPrev__c+' Label.LeadRouting_Weblead='+Label.LeadRouting_Weblead+' not equal='+(l.OwnedByPrev__c != Label.LeadRouting_Weblead));
            if (!doNotProcess) {
               String zipCode = getZipCode(l.PostalCode);
               checkLead(l,(zipCode != null ? zipListMap.get(zipCode) : null),updateLeads,rtByNameMap, uh, pendingLeadRtId);
            }
         }
         // only need to do this if not calling from a Before trigger
         //if (useUpdateLeads && !updateLeads.isEmpty()) {
         //update updateLeads;
         //}
      //} // if (!nssZips
   } // processLeads

   public static final String LEAD_MAP='LeadMap-';
    
    // do we always need to check the owner of this lead?
    public static Boolean doWeCheckOwner(Lead l) {
        Boolean checkOwner = false;
         String productDivision = (String.isNotBlank(l.Product_Division__c) ? l.Product_Division__c.trim() : null);
         System.debug('doWeCheckOwner productDivision='+productDivision);
        if (String.isNotBlank(productDivision)) {
           String key = RecordTypeHelper.cleanRtName(LEAD_MAP+productDivision);
           ProductGroupMapping__c mapping = ProductGroupMapping__c.getInstance(key);
           checkOwner = (mapping != null ? mapping.AlwaysCheckOwner__c : false);
        }
        return checkOwner;
    } // doWeCheckOwner

   private static String leadMsg = '';

   // Check the owner of the Lead. Change if necessary.
   private static Boolean checkLead(Lead l, List<Zip_Assignment__c> zaList, Lead[] updateLeads, Map<String,Schema.RecordTypeInfo> rtByName, UserHelper uh, Id pendingLeadRtId) {
      // determine the type
      if (l != null && !l.Hold_Out__c) {
         leadMsg = 'LeadCheckOwner.checkLead';
         // default to Core
         String salesOrg = UserHelper.SO_CORE;
         String recordTypeName = RecordTypeHelper.CORE_LEAD;
         
         // determine salesOrg/RecordType
         String productDivision = (String.isNotBlank(l.Product_Division__c) ? l.Product_Division__c.trim() : null);
         System.debug('LeadCheckOwner.checkLead productDivision='+productDivision);
         leadMsg += '; productDivision='+productDivision;
         Boolean notifyOwner = false;

         if ((String.isNotBlank(productDivision) && productDivision == 'MMS') ||
             (String.isBlank(productDivision) && l.NumberOfEmployees != null && l.NumberOfEmployees >= 20)) {
            System.debug('LeadCheckOwner.checkLead setting to MMS based on employee count');
            salesOrg = UserHelper.SO_MMS;
            recordTypeName = RecordTypeHelper.MMS_LEAD;
            leadMsg += '; setting to MMS based on employee count';
         } else if (String.isNotBlank(productDivision)) {
            String key = RecordTypeHelper.cleanRtName(LEAD_MAP+productDivision);
            ProductGroupMapping__c mapping = ProductGroupMapping__c.getInstance(key);
            System.debug('LeadCheckOwner.checkLead key='+key+' mapping='+mapping);
            leadMsg += '; key='+key+' mapping='+(mapping != null);
            if (mapping != null) {
               salesOrg = mapping.Sales_Org__c;
               recordTypeName = mapping.RecordTypeName__c;
                System.debug('LeadCheckOwner.checkLead - Record Type Name = '+ recordTypeName);
                leadMsg += '; recordTypeName='+recordTypeName;
                ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER = false;
                if (l.id == null && mapping.NotifyOwner__c) {
                   l.NotifyOwner__c = true;
                } else if (l.Id != null && mapping.NotifyOwner__c) {
                   ChatterMessageSend.notifyOwnerIdSet.add(l.Id);
                }
            }
         } // if ((l.Product_Division__c
        
         System.debug('LeadCheckOwner.checkLead l='+l.LastName+' productDivision='+productDivision+'. l.Product_Division__c='+l.Product_Division__c+'. salesOrg='+salesOrg+' recordTypeName='+recordTypeName);
         
         // get the zip code record
         Zip_Assignment__c za = getZa(l,zaList, salesOrg, l.NumberOfEmployees, recordTypeName);
         System.debug('LeadCheckOwner.checkLead za='+za);
        
         // if PEO Lead but cant find a PEO Centric rep, get a HRS rep instead unless PEO C created the lead
         if (za == null && recordTypeName == Label.RT_PEO_Lead) // && l.Product_Division__c == null)  
         {  recordTypeName = Label.RT_HRS_Lead;             
            za = getZa(l,zaList, 'HRS', l.NumberOfEmployees, recordTypeName); 
            System.debug('LeadCheckOwner.checkLead PEO Lead couldnt find PEO Centric rep, za='+za);
         }                
         
         // get the user if exists and is active
         Id ownerId = ((za != null && za.User__r != null && za.User__r.IsActive) ? za.User__c : null);
        
         // if no owner id, use queue group name
         if (ownerId == null && zaList != null && !zaList.isEmpty()) {
            // if the person id doesn't match use the queue 
            Group grp = uh.getQueue(QUEUE_NAME);
            ownerId = (grp != null ? grp.Id : null);
         } // if (ownerId

 
         Schema.RecordTypeInfo rt = rtByName.get(recordTypeName);
         // get Pending_Leads record type for exceptioned Bank Leads - we don't want to change record type if already set to this
         //Schema.RecordTypeInfo PendingLeadrt = rtByName.get('Pending Leads');
        
         Boolean leadChanged = false;
        
         System.debug('LeadCheckOwner.checkLead l.RecordTypeId='+l.RecordTypeId+' rt='+(rt != null ? rt.getRecordTypeId() : 'null') +' ownerId='+ownerId+' l.ownerId='+l.OwnerId+' PEOLeasing='+l.PeoLeasing__c);         
         if (l.RecordTypeId != pendingLeadRtId && rt != null && rt != null && l.RecordTypeId != rt.getRecordTypeId()) {
            l.RecordTypeId = rt.getRecordTypeId();
            if (recordTypeName == Label.RT_PEO_Lead)
            {   l.PeoLeasing__c = true; }
            leadChanged = true;
         }
         if (ownerId != null && l.OwnerId != ownerId) {
            l.OwnerId = ownerId;
            leadChanged = true;
            System.debug('LeadCheckOwner.checkLead changed ownerId');
         }
         // reset UseZipAssignmentRules__c 
         if (l.UseZipAssignmentRules__c)
         {  l.UseZipAssignmentRules__c = false;
            leadChanged = true;
         }
         System.debug('LeadCheckOwner.checkLead leadChanged='+leadChanged+' l='+l);
         if (leadChanged) {
            updateLeads.add(l);
         }
         System.debug('LeadCheckOwner.checkLead l.rcdtype='+l.RecordTypeId+' PeoLeasing='+l.PeoLeasing__c+' ownerId='+l.ownerId+' leadChanged='+leadChanged);
         StringHelper.addToProcessNotes(l,leadMsg);
      } // if (l != null
      return true;
   } // checkLead

   public static Zip_Assignment__c getZa(List<Zip_Assignment__c> zaList, String salesOrg, Integer nbrEmps, String recordTypeName) {
      return getZa(null,zaList,salesOrg,nbrEmps,recordTypeName);
   } // getZa
   public static Zip_Assignment__c getZa(Lead ld, List<Zip_Assignment__c> zaList, String salesOrg, Integer nbrEmps, String recordTypeName) {
    Zip_Assignment__c retVal = null;
    System.debug('getZa zaList='+(zaList != null && !zaList.isEmpty()));
    leadMsg += '; zaList='+(zaList != null ? zaList.size() : -1);
    if (zaList != null && !zaList.isEmpty()) {
       if (nbrEmps == null) {
          nbrEmps = 0;
       }
       leadMsg += '; nbrEmps='+nbrEmps;
       System.debug('getZa nbrEmps='+nbrEmps);
         for (Zip_Assignment__c za : zaList) {
             if (checkSegment(ld, za, za.Zip_Segment__r,salesOrg, nbrEmps, recordTypeName)) {
                retVal = za;
                break;
             }
             // see if it matches one of the other segments it's attached to.
             for (ZipAssignmentFallback__c fallback : za.ZipAssignmentFallbacks__r) {
                if (checkSegment(ld, za, fallback.ZipSegment__r,salesOrg, nbrEmps, recordTypeName)) {
                   retVal = za;
                   break;
                }
 
             }  // for (ZipAssignmentFallback__c fallback : za.ZipAssignmentFallbacks__r
                    
         } // for (Zip_Assignment__c
         if (retVal != null) {
            leadMsg += '; criteria met for '+retVal.Id;
         }
      } // if (zaList != null    
      return retVal;
   } // getZa
    
    public static Boolean checkSegment(Lead ld, Zip_Assignment__c za, Zip_Segment__c seg, String salesOrg, Integer nbrEmps, String recordTypeName) {
       Boolean criteriaMet = false;
       if (seg != null && seg.Sales_Org__c == salesOrg && seg.LeadRecordTypeName__c == recordTypeName) {
           criteriaMet = (za.SkipJoinCriteria__c 
                           || (seg.Emps_Min__c == null && seg.Emps_Max__c == null)
                           || (seg.Emps_Min__c <= nbrEmps && seg.Emps_Max__c >= nbrEmps)
                          );
           if (criteriaMet && ld != null) {
              
              criteriaMet = ZipCheckOwner.checkOtherCriteria(ld, seg, criteriaMet);
           }
       } // if (seg != null
       return criteriaMet;
    } // checkSegment
    

} // class LeadCheckOwner