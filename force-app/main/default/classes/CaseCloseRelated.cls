/* 
 * Close cases that are related to a parent case
 *
 * History
 * -------
   12/12/2012 Dan Carmen   Created
 *
 */
public with sharing class CaseCloseRelated {

   /** The records type names that will cause the trigger to fire. */
   public static Set<String> recordTypeNames401k = new Set<String>{'Service Support 401k/S125 Case'};
   
   public static Set<String> recordTypeNamesHRO = new Set<String>{'Service Onboarding HRO Case Record Type'};
                      
   private static Map<String,Schema.RecordTypeInfo> byId = null;
   
   public static Set<String> getRecordTypeIds() {
      if (byId == null) {
      	// get all of the recordtypes for the case
      	byId = new Map<String,Schema.RecordTypeInfo>();
      	String[] objectNames = new String[]{'Case'};
      	String[] recordTypeNames = new String[]{};
      	recordTypeNames.addAll(recordTypeNames401k);
         recordTypeNames.addAll(recordTypeNamesHRO);
         RecordTypeHelper.getRecordTypesMap(objectNames, recordTypeNames, byId, null);
      }
      return byId.keySet();
   } // getRecordTypeIds

   public static void checkCloseRelated(Id[] caseIds) {
      // run as future if not already in a future invocation
      if (System.isFuture()) {
         processCloseRelated(caseIds);
      } else {
         processCloseRelatedFuture(caseIds);
      }
   } // checkCloseRelated
   
   public static void processCloseRelatedFuture(Id[] caseIds) {
      processCloseRelated(caseIds);
   } // processCloseRelatedFuture
   
   private static void processCloseRelated(Id[] caseIds) {
   	System.debug('processCloseRelated caseIds='+caseIds);
   	// select the data to update
   	for (List<Case> relatedCases : [Select Id, Status
   	                                      ,Parent.Status
   	                                  From Case
   	                                 Where ParentId in :caseIds
   	                                   and IsClosed = false
   	                                   and ((RecordType.Name in :recordTypeNames401k
   	                                         and Parent.Status = 'Solved'
   	                                         and Parent.Mass_Create_Indicator__c = 'Bis ID')
   	                                        or (RecordType.Name in :recordTypeNamesHRO
   	                                          and Parent.Action__c in ('HRO Onboarding/Setup', 'EAO Onboarding/Setup', 'W2 Only Onboarding/Setup')
   	                                          and Parent.Status in ('Completed','Refused'))
   	                                       )
   	                                ]) {
   	   for (Case c : relatedCases) {
   	   	// set the status to the status of the parent
   	   	c.Status = c.Parent.Status;
   	   } // for (Case c
   	
   	   update relatedCases;
   	} // for (List<Case> relatedCases 
   	
   } // processCloseRelated
   
} // class CaseCloseRelated