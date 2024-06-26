/* 
 * Create a reference object on creation of a case.
 *
 * History
 * -------
 * 06/30/2010 Dan Carmen   Created
 * 02/21/2011 Dan Carmen   Changed version number.
 * 09/09/2019 Jake Hinds   deactivated - moved to CaseAfter
 *
 */
trigger CaseCreateReference on Case (after insert) {
/*
   Id[] caseIds = new Id[]{};

   Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
   String[] objectNames = new String[]{'Case'};
   RecordTypeHelper.getRecordTypesMap(objectNames,null,byName);
   
   Map<Id,Id> excludeIdMap = new Map<Id,Id>();
   
   if (byName.containsKey('Service Onboarding HRO Case Record Type')) {
      Id recordTypeId = byName.get('Service Onboarding HRO Case Record Type').getRecordTypeId();
      excludeIdMap.put(recordTypeId,recordTypeId );
   }
   
   for ( Case newCase: Trigger.new) {
      if ((newCase.ParentId == null) ||
          (newCase.ParentId != null && !excludeIdMap.containsKey(newCase.recordTypeId))) {
         caseIds.add(newCase.Id);
      } // if (newCase
   } // for (Case
   
   if (!caseIds.isEmpty()) {
      CaseCreateReference.createReference(caseIds);
   } // if (!caseIds
*/

} // trigger CaseCreateReference