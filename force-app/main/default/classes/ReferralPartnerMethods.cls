/* 
 * Methods for the Referral_Partner__c object
 *
 * History
 * -------
 * 08/22/2012 Dan Carmen   Created
   10/29/2018 Dan Carmen   Increment API to version 44

 */
public with sharing class ReferralPartnerMethods {

   public static String[] MAPPING_TYPES = new String[]{RecordTypeHelper.MAPPING_DEFAULT};
   
   /** Check for the opportunity record type id on the referral partner records
    */
   public static void checkRecordTypeId(Referral_Partner__c[] recs) {
   	String[] partnerTypes = new String[]{};
   	for (Referral_Partner__c rp : recs) {
   	   partnerTypes.add(rp.Name);
   	}
   	// retrieve the mappings
      Map<String,Record_Type_Mapping__c> recordTypeMap = RecordTypeHelper.getRecordTypeByMapping(partnerTypes,'Opportunity',MAPPING_TYPES);
      
      // set the record type id (if it exists)
      for (Referral_Partner__c rp : recs) {
         Record_Type_Mapping__c rtm = recordTypeMap.get(rp.Name+RecordTypeHelper.MAPPING_DEFAULT);
         if (rtm != null) {
         	rp.Selling_Opp_RecordTypeId__c = rtm.RecordTypeId__c;
         }
      } // for (Referral_Partner__c
   } // checkRecordTypeId
   
} // class ReferralPartnerMethods