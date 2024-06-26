/* 
 * If the owner of the case changes, see if anything needs to be done.
 *
 * History
 * -------
 * 06/29/2010 Dan Carmen        Created
   02/21/2011 Dan Carmen        Added the Credit Risk object
   09/20/2011 Dan Carmen        Added PEO
   10/17/2011 Michelle Brown    Added 401k MM Change
   12/28/2011 Carrie Marciano   Added Service HRO BeneTrac Integration Record Type
   03/27/2012 Carrie Marciano   changed HRO NCT to HRO LCT
   01/16/2013 Justin Stouffer   added the Service Onboarding PEM Case Record Type
   01/18/2013 Justin Henderson  added the Service Onboarding PEO Existing Clients Record Type
   04/23/2013 Dan Carmen        Add HRE object to class. Rewrite code to be a little more generic.
   07/02/2013 Josh Cartwright   Added MSP
   08/29/2013 Cindy Freeman     MMS Onboarding case if owner changes to queue change reference mms payroll owner
   10/16/2013 Josh Cartwright   Added OSMAM
   10/16/2013 Justin Henderson  Added Reference ASO
   01/02/2014 Josh Cartwright   added CA HRO  
   01/07/2014 Josh Cartwright   Added HNBF  
   01/13/2015 Frank Lurz        Added more HRE/Handbook record types for HK-0005 effort
   03/23/2015 Frank Lurz        Added more HRE/Handbook record types for HRE Support effort
   03/31/2015 Justin Stouffer   Added MPSC Case Record Types
   08/10/2015 Jacob Hinds       Added Benetrac record types, STM Conversion, STM Onboarding, Enterprise Services Onboarding, HRS Termination/Transfer
   10/14/2015 Jacob Hinds       Added Account Management object
   10/28/2015 Lynn Michels      added Reference MPSC Client Training Request object and associated Record Type
   10/30/2015 Jacob Hinds       Added Reference Incoming Funds
   12/11/2015 Jacob Hinds       Added Reference Enterprise Service ERR Account Management
   01/22/2016 Lynn Michels      Added Reference Adoption Agreement Review
   02/25/2016 Carrie Marciano   Added Reference MPSC Escalation
   05/03/2016 Lynn Michels      Added MPSC Client Audit and MPSC Employee Audit Record Types for Ref Core Payroll
   06/10/2016 Lynn Michels      Added PEO Client Risk Assessment for Reference PEO
   06/16/2016 Jacob Hinds       Added ESR New Case
   06/16/2016 Cindy Freeman     Added Reference Core Payroll record types to Record_Locked__c reset
   08/03/2016 Jacob Hinds       Added Ref Operations Support
   08/08/2016 Jacob Hinds       Added in hotfix for multiple objects with a single case record type.
   10/04/2016 Jacob Hinds       Added ESR Dedicated Service
   10/27/2016 Lynn Michels      Updated Case Record type that Reference MPSC uses
   11/03/2016 Jacob Hinds       Added MPSC Reload
   12/07/2016 Jacob Hinds       Added MPSC Exception
   01/05/2017 Jacob Hinds       Adding 401k Manual Collection
   02/01/2017 Lynn Michels      Added Reference S125 Onboarding object
   02/03/2017 Dan Carmen        Added check to not run as future when in batch/future/test
   03/03/2017 Sunnish Annu      The owner on the Reference Core Payroll MPSC ASO Upgrade record type update when the MPSC ASO Upgrade Case Owner updates
   07/20/2017 Jacob Hinds       Added Reference Incoming Funds - Miscellaneous Check RT.
   09/15/2017 Lynn Michels		Added Reference MPSC BenAdmin Essentials, MPSC BenAdmin Plan Design Record Type
   11/08/2017 Lynn Michels		Added Reference KAS 
   07/06/2018 Lynn Michels		Added Reference P&C	
   11/13/2018 Cindy Freeman     Added Reference MPSC Upgrade record type for Reference Core Payroll 
   12/11/2018 CIndy Freeman	    Fix MPSC Upgrade case record type to update Ref Core Payroll
   03/31/2019 Jake Hinds		Added Reference Business Continuity Response
   03/22/2021 Manmeet Vaseer	SFDC-6526 - Don't call the future method if there is only one case.
   09/01/2021 Carrie Marciano   Removed the Credit Risk object due to uninstalling Equifax package
   10/12/2021 Carrie Marciano   Added CER case and Reference CER object
   03/25/2024 Jaipal            APR015314 Changed recordtype of BeneTrac Onboarding' to 'Benefits Administration Onboarding'
   5/20/2024  Carrie Marciano    Commented code related to MPSC tech Debt and added new Multi-Product Service Case 
 *
 */
public without sharing class CaseOwnerChange {

   /** Map of the reference object to the case lookup field names. */
   public static Map<String,String> caseLookupMap = new Map<String,String>();
   
   /** Map between the record type name and the object it refers to. */
   public static Map<String,String> recordTypeObjectMap = new Map<String,String>();
   
   /** Map between the record type name and the object it refers to. Use this one if there are multiple reference objects for one case record type. */
   public static Map<String,List<String>> recordTypeObjectsListMap = new Map<String,List<String>>();
   
   static {
      caseLookupMap.put('Reference_Core_Payroll__c','Case_Lookup__c');
      caseLookupMap.put('Reference_TAA__c','Case_Lookup__c');      
      caseLookupMap.put('Reference_HRO__c','Case_Number__c');      
      caseLookupMap.put('Reference_401k_S125__c','Case_Lookup__c');      
      caseLookupMap.put('Reference_GL__c','Case_Lookup__c');      
      caseLookupMap.put('Reference_Client_Relations__c','Case_Lookup__c');      
      caseLookupMap.put('Reference_PEO__c','Parent_Case__c');      
      caseLookupMap.put('Reference_HRE_CHB_Onboarding__c','Parent_Case__c');
      caseLookupMap.put('Reference_MMS_Payroll__c','Case_Number__c');
      caseLookupMap.put('Reference_ASO__c','Case_Number__c');
      caseLookupMap.put('Reference_HNBF__c','Case_Number__c');  
      caseLookupMap.put('Reference_MPSC__c','Case_Lookup__c');
      caseLookupMap.put('Reference_BeneTrac_Onboarding__c','Case_Number__c');
      caseLookupMap.put('Reference_Enterprise_Service__c','Case_Lookup__c');
      caseLookupMap.put('Reference_Account_Management__c','Case_Lookup__c');
      caseLookupMap.put('Reference_Incoming_Funds__c','Case_Lookup__c');
      caseLookupMap.put('Reference_Terms_Transfers__c','Case_Lookup__c');
      caseLookupMap.put('Reference_Adoption_Agreement_Review__c','Case_Lookup__c');
      //caseLookupMap.put('Reference_MPSC_Escalations__c','Case_Number__c');
      caseLookupMap.put('Reference_S125_Onboarding__c','Case_Lookup__c');
      //caseLookupMap.put('Reference_MPSC_BenAdmin_Essentials__c','Case_Lookup__c');
      caseLookupMap.put('Reference_KAS__c','Case_Lookup__c');
      caseLookupMap.put('Reference_P_C__c','Case_Lookup__c');
      caseLookupMap.put('Reference_CTT__c','Case__c');
      caseLookupMap.put('Reference_Business_Continuity_Response__c','Case_Lookup__c');
      caseLookupMap.put('Reference_CER_Object__c','Case__c'); 
      
      recordTypeObjectMap.put('MPSC Transfer Case','Reference_MPSC__c');
      recordTypeObjectMap.put('Service Onboarding Core Payroll Case','Reference_Core_Payroll__c');
      recordTypeObjectMap.put('Service Onboarding MPSC Core Payroll Case','Reference_Core_Payroll__c'); 
      //recordTypeObjectMap.put('MPSC Employee Audit','Reference_Core_Payroll__c');
      recordTypeObjectMap.put('MPSC Client Audit','Reference_Core_Payroll__c');
      //recordTypeObjectMap.put('MPSC Upgrade','Reference_Core_Payroll__c');
      //recordTypeObjectMap.put('Reference MPSC Upgrade','Reference_Core_Payroll__c');
      recordTypeObjectMap.put('Service Onboarding TAA Case2','Reference_TAA__c');
      recordTypeObjectMap.put('Service Onboarding HRO Case Record Type','Reference_HRO__c');
      recordTypeObjectMap.put('Service HRO BeneTrac Integration Record Type','Reference_HRO__c');
      recordTypeObjectMap.put('Service Onboarding EAO Case Record Type','Reference_HRO__c');
      recordTypeObjectMap.put('Service Onboarding W2 Only Case Record Type','Reference_HRO__c');
      recordTypeObjectMap.put('Service Additional HRO LCT Contact Record Type','Reference_HRO__c');
      recordTypeObjectMap.put('Service Onboarding PEM Case Record Type','Reference_HRO__c');
      recordTypeObjectMap.put('Service Onboarding MSP Case Record Type','Reference_HRO__c');
      recordTypeObjectMap.put('Service Onboarding CA HRO Record Type','Reference_HRO__c');           
      recordTypeObjectMap.put('Service Onboarding OSMAM Case Record Type','Reference_HRO__c');       
      recordTypeObjectMap.put('Service Onboarding ASO New Business','Reference_ASO__c');  
      recordTypeObjectMap.put('Service Onboarding HNBF Case Record Type','Reference_HNBF__c'); 
      recordTypeObjectMap.put('Service Onboarding ESR Case','Reference_HNBF__c');     
      recordTypeObjectMap.put('Service Support ESR Dedicated Service Case','Reference_HNBF__c');
      recordTypeObjectMap.put('Service Onboarding 401k Conversion','Reference_401k_S125__c');
      recordTypeObjectMap.put('Service Onboarding 401k New Case','Reference_401k_S125__c');
      recordTypeObjectMap.put('Service Onboarding S125 New Case','Reference_S125_Onboarding__c');
      recordTypeObjectMap.put('Service Onboarding S125 Conversion','Reference_401k_S125__c');
      recordTypeObjectMap.put('Service Support 401k MM Change Case Record','Reference_401k_S125__c');
      recordTypeObjectMap.put('Service Onboarding GL Case','Reference_GL__c');
      recordTypeObjectMap.put('Service Support Corporate Concerns','Reference_Client_Relations__c');
      recordTypeObjectMap.put('Service Onboarding PEO New Business','Reference_PEO__c');
      recordTypeObjectMap.put('Service Onboarding PEO Existing Clients','Reference_PEO__c');
      recordTypeObjectMap.put('PEO Client Risk Assessment','Reference_PEO__c');
      recordTypeObjectMap.put('Service Onboarding HRE/CHB','Reference_HRE_CHB_Onboarding__c');
      recordTypeObjectMap.put('Service Support Handbook HR Solutions','Reference_HRE_CHB_Onboarding__c');
      recordTypeObjectMap.put('Service Support Handbook PEO','Reference_HRE_CHB_Onboarding__c');
      recordTypeObjectMap.put('Service Support Handbook HRE/CHB','Reference_HRE_CHB_Onboarding__c');
      recordTypeObjectMap.put('Service Support HRE/CHB','Reference_HRE_CHB_Onboarding__c');
      recordTypeObjectMap.put('Service Onboarding MMS Payroll Case','Reference_MMS_Payroll__c');
      recordTypeObjectMap.put('Service Onboarding HRO MAA Case','Reference_HRO__c');
      recordTypeObjectMap.put('Service Support HRO MAA Client Data Sheet Case','Reference_HRO__c');
      recordTypeObjectMap.put('Service Onboarding MSP Add On Module Case','Reference_HRO__c');
      recordTypeObjectMap.put('Benefits Administration Onboarding','Reference_BeneTrac_Onboarding__c');
      recordTypeObjectMap.put('Service STM Conversion Case','Reference_TAA__c');
      recordTypeObjectMap.put('Service Onboarding STM Record Type','Reference_TAA__c');
      recordTypeObjectMap.put('Service Onboarding Enterprise Services Case Record Type','Reference_Enterprise_Service__c');
      recordTypeObjectMap.put('ERR Account Management','Reference_Enterprise_Service__c');  
      recordTypeObjectMap.put('Service Support 401k/S125 Account Management Record Type','Reference_Account_Management__c');
      recordTypeObjectMap.put('Adoption Agreement Review','Reference_Adoption_Agreement_Review__c');
      //recordTypeObjectMap.put('Service Support MPSC Escalation Case','Reference_MPSC_Escalations__c');
      //recordTypeObjectMap.put('MPSC Exception','Reference_Core_Payroll__c');
      //recordTypeObjectMap.put('MPSC Reload','Reference_Core_Payroll__c');
      recordTypeObjectMap.put('Service Support Benetrac ESR Dedicated Service Case','Reference_HNBF__c');
      recordTypeObjectMap.put('401k Manual Collection','Reference_Incoming_Funds__c');
      recordTypeObjectMap.put('401k Miscellaneous Checks','Reference_Incoming_Funds__c');
      //recordTypeObjectMap.put('MPSC BenAdmin Case','Reference_MPSC_BenAdmin_Essentials__c');
      recordTypeObjectMap.put('Service Support KAS','Reference_KAS__c'); 
      recordTypeObjectMap.put('Service Onboarding P&C Case','Reference_P_C__c'); 
      recordTypeObjectMap.put('Sales CTT','Reference_CTT__c'); 
      recordTypeObjectMap.put('Business Continuity Response','Reference_Business_Continuity_Response__c'); 
      recordTypeObjectMap.put('CER Sales Record Type','Reference_CER_Object__c');
      recordTypeObjectMap.put('Multi-Product Service Case','Reference_MPSC_Service_Submission__c');
       
      String[] four01kRefs = new String[]{'Reference_Incoming_Funds__c','Reference_Terms_Transfers__c'};
      recordTypeObjectsListMap.put('401k/S125 Operations Support', four01kRefs);

   } // static
   
   public static void processOwnerChange(Id[] caseIds) { 
      if (caseIds.size() > 0) {
         // SFDC-6526 - Don't call the future method if there is only one case.
         if (caseIds.size() == 1 || System.isFuture() || System.isBatch() || Test.isRunningTest()) {
            processOwnerChangeNow(caseIds);
         } else {
            processOwnerChangeFuture(caseIds);
         }
      }
   } // processOwnerChange
   
   /** Process the records now (synchronously).
    */
   public static void processOwnerChangeNow(Id[] caseIds) {
      processRecords(caseIds);
   } // processOwnerChangeNow
   
   /** Process the records in the future (asynchronously).
    */
   @future
   public static void processOwnerChangeFuture(Id[] caseIds) {
      processRecords(caseIds);
   } // processOwnerChangeFuture
   
   public static void processRecords(Id[] caseIds) {
      List<Case> cases = new List<Case>([Select Id
                                               ,RecordTypeId
                                               ,RecordType.Id
                                               ,RecordType.Name
                                               ,OwnerId
                                           from Case
                                          where Id in :caseIds]);
      
      Map<String,List<Case>> objectCaseMap = new Map<String,List<Case>>();

      for (Case c : cases) {
        String objectName = recordTypeObjectMap.get(c.RecordType.Name);

        // only continue if we have a mapping for it.
        if (objectName != null) {
            system.debug('TEEST'+c.RecordType.Name);
            addToMap(objectCaseMap,objectName,c);
        }
        else{
            List<String> multiObjects = recordTypeObjectsListMap.get(c.RecordType.Name);
            if(multiObjects != null){
                for(String obj:multiObjects){
                    addToMap(objectCaseMap,obj,c);
                }
            }
        }      

      } // for (Case c

      // process the reference objects we have data for      
      for (String objectName : objectCaseMap.keySet()) {
         processReferenceObjects(objectName,caseLookupMap.get(objectName),objectCaseMap.get(objectName));
      }

   } // processOwnerChange
   

   /** Add the case to the map for the particular object type. */
   private static void addToMap(Map<String,List<Case>> objectCaseMap, String objectName, Case c) {
      List<Case> caseList = objectCaseMap.get(objectName);
      if (caseList == null) {
         caseList = new List<Case>();
         objectCaseMap.put(objectName,caseList);
      }
      caseList.add(c);
   } // addToMap
   
   /** Create a map of the reference objects by case id. */
   private static Map<String,SObject> getRefMap(String objectName, String caseField, List<Id> caseIds) {
      Map<String,SObject> objectMap = new Map<String,SObject>();
      String query = null;

      if (!String.isBlank(objectName) && !String.isBlank(caseField)) {
         query = 'Select Id, OwnerId, '+caseField+' from '+objectName+' where '+caseField+' in (';
         for (Integer cnt=0; cnt<caseIds.size(); cnt++) {
            if (cnt > 0) {
               query += ',';
            }
            query += '\''+caseIds[cnt]+'\'';
         } // for
         query += ')';
         SObject[] sobjects = Database.query(query);

         if (sObjects != null) {
            for (SObject so : sObjects) {
               String value = (String)so.get(caseField);
               if (value != null) {
                  objectMap.put(value,so);
               }
            } // for
         } // if (sObjects != null
      } // if (objectName != null
      
      return objectMap;
   } // getRefMap
   
   /** process the owner change for each reference object type. */
   private static void processReferenceObjects(String objectName, String caseField, List<Case> cases) {
      List<Id> caseIds = getCaseIds(cases);
      Map<String,SObject> objectMap = getRefMap(objectName,caseField,caseIds);
      if (!objectMap.isEmpty()) {
         for (Case c : cases) {
            
            SObject so = objectMap.get(c.Id);
            if (so != null) {
               so.put('OwnerId',c.OwnerId);
               system.debug('TEEST2'+c.OwnerId);
               //LM add 6/14/16
                if (c.RecordType.Name == 'PEO Client Risk Assessment' 
                    || c.RecordType.Name == 'MPSC Client Audit' 
                    /*|| c.RecordType.Name == 'MPSC Employee Audit'*/)
                {   so.put('Record_Locked__c', false);  }
            } // if (so != null            
         } // for
         updateRecords(objectMap.values(),cases);
      } // if (!objectMap.isEmpty
      
   } // processReferenceObjects
   
   /** Handle an exception if it occurs.
    */
   public static void updateRecords(List<SObject> updateRecs, List<Case> cases) {
      if (!updateRecs.isEmpty()) {
         DmlHelper.performDML2(updateRecs, DmlHelper.DML_UPDATE, 'CaseOwnerChange', 'updateRecords', 'updating records', true);
      } // if (!updateRecs.isEmpty
   } // handleException
   
   private static List<Id> getCaseIds(List<Case> cases) {
      List<Id> caseIds = new List<Id>();
      for (Case c : cases) {
         caseIds.add(c.Id);
      }
      return caseIds;
   } // getCaseIds
   
} // class CaseOwnerChange