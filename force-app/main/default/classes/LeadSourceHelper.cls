/* 
 * Helper for setting working on the lead source
 *
 * History
 * -------
   01/10/2019 Dan Carmen       Created
   01/26/2023 Dan Carmen       Increment API, change to TriggerInterfaceC

 */
public with sharing class LeadSourceHelper implements TriggerInterfaceC {
        
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('LeadSourceHelper', p_recs, oldMap, isBefore, isAfter, null, null);
      // check what the type of the first record is
      System.debug('LeadSourceHelper.checkAllBeforeTrigger recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      if (isBefore && recs != null && !recs.isEmpty()) {
         SObjectType recType = TriggerMethods.objType;
         if (recType == Opportunity.sObjectType) {
            checkOppLeadSource((Opportunity[])recs, (Map<Id,Opportunity>)oldMap);
         }
      } // if (recs != null
   } // checkAllBeforeTrigger

   public static void checkOppLeadSource(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
      for (Opportunity opp : opps) {
         Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
         
         if (String.isBlank(opp.LeadSourceCategory__c) 
                || (oldOpp != null && opp.LeadSource != oldOpp.LeadSource)
                || (oldOpp != null && opp.NSS_Source__c != oldOpp.NSS_Source__c)) {
            opp.LeadSourceCategory__c = getLeadSourceCategory(opp.LeadSource, opp.NSS_Source__c);
         }
      } // for (Opportunity opp
   } // checkOppLeadSource
   
   public static String DEFAULT_CATEGORY=Label.LeadSource_DefaultCategory;
   
   public static String getLeadSourceCategory(String leadSource, String nssSource) {
      String lsCategory = checkSettingForCategory(nssSource);
      if (String.isBlank(lsCategory)) {
         lsCategory = checkSettingForCategory(leadSource);
      }
      // as long as there is a lead source, we'll set a default category if nothing is found in the mapping
      if (String.isBlank(lsCategory) && String.isNotBlank(leadSource) && DEFAULT_CATEGORY != 'None') {
         lsCategory = DEFAULT_CATEGORY;
      } // if (String.isNotBlank

      System.debug('getLeadSourceCategory leadSource='+leadSource+' lsCategory='+lsCategory);
      return lsCategory;
      
   } // getLeadSourceCategory
   
   public static String checkSettingForCategory(String name) {
      String lsCategory = null;
      if (String.isNotBlank(name)) {
         String customSettingName = RecordTypeHelper.cleanRtName(name); 
         try {
            LeadSource__c ls = LeadSource__c.getInstance(customSettingName);
            if (ls != null) {
               lsCategory = ls.Category__c;
            }
         } catch (Exception e) {
            System.debug('checkSettingForCategory exception: '+e.getMessage()+'; '+e.getStackTraceString());
         }
      }
      System.debug('checkSettingForCategory name='+name+' lsCategory='+lsCategory);
      return lsCategory;
   } // checkSettingForCategory

} // class LeadSourceHelper