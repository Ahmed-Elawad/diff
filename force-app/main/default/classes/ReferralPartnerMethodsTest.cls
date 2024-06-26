/* 
 * Test methods for the ReferralPartnerMethods class
 *
 * History
 * -------
 * 08/22/2012 Dan Carmen   Created
   12/28/2012 Dan Carmen   refactored setupReferralPartner method
   07/08/2015 Dan Carmen   Added additional criteria
   10/29/2018 Dan Carmen   Increment API to version 44

 */
@isTest
public class ReferralPartnerMethodsTest {

   public static Referral_Partner__c setupReferralPartner(String salesOrg, String recordTypeName) {
      return setupReferralPartner(salesOrg, recordTypeName, ReferralController.REF_INTERNAL);
   }

   public static Referral_Partner__c setupReferralPartner(String salesOrg, String recordTypeName, String partnerType) {
   	Referral_Partner__c rp = null;
      if (recordTypeName != null) {

         Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(recordTypeName, ObjectHelper.OBJECT_OPPTY);

         if (!Utilities.isTestSiloed()) {
            // delete if already exists
            delete [select id from Referral_Partner__c where Name=:salesOrg and Partner_Type__c = :partnerType];

            // delete mapping if already exists
            delete [select id from Record_Type_Mapping__c where Sales_Org__c=:salesOrg and Object_API_Name__c=:ObjectHelper.OBJECT_OPPTY];
         }
         Record_Type_Mapping__c rtm = new Record_Type_Mapping__c(Sales_Org__c=salesOrg, Object_API_Name__c=ObjectHelper.OBJECT_OPPTY, RecordTypeName__c=recordTypeName,Mapping_Type__c=RecordTypeHelper.MAPPING_DEFAULT);
         insert rtm;
         // verify record type id is set
         rtm = [select id, name, Object_API_Name__c, RecordTypeName__c, RecordTypeId__c from Record_Type_Mapping__c where Id = :rtm.Id];
         System.assertEquals(rt.getRecordTypeId(),rtm.RecordTypeId__c);
      
         // test single record
         rp = new Referral_Partner__c(Name=salesOrg,CreateRefOpp__c=true,Partner_Type__c=partnerType);
         insert rp;
         rp = [Select Id, Name, Selling_Opp_RecordTypeId__c from Referral_Partner__c where Id=:rp.Id];
         System.assertEquals(rp.Selling_Opp_RecordTypeId__c,rt.getRecordTypeId());
      } // if (recordTypeName != null
      return rp;
      
   } // setupReferralPartner
   
   /** Test setting the record type id on the Referral_Partner__c record
    */
   static testMethod void testRecordTypeId() {
      // object name and good record type name
      // get all valid record types and pick one
      Referral_Partner__c rp = setupReferralPartner(UserHelper.SO_CORE,OpportunityCreateCase.RT_OPPTY_CORE);
      
      Referral_Partner__c rp1 = new Referral_Partner__c(Name=UserHelper.SO_CORE,CreateRefOpp__c=true,Partner_Type__c=ReferralController.REF_INTERNAL);
      Referral_Partner__c rp2 = new Referral_Partner__c(Name=UserHelper.SO_401,CreateRefOpp__c=true,Partner_Type__c=ReferralController.REF_INTERNAL);
      Referral_Partner__c rp3 = new Referral_Partner__c(Name=UserHelper.SO_AGENCY,CreateRefOpp__c=false,Partner_Type__c=ReferralController.REF_INTERNAL);
      
      Referral_Partner__c[] rps = new Referral_Partner__c[]{rp1,rp2,rp3};
      insert rps;
      
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);

      // verify results
      rp1 = [Select Id, Name, Selling_Opp_RecordTypeId__c from Referral_Partner__c where Id=:rp1.Id];
      System.assertEquals(rp1.Selling_Opp_RecordTypeId__c,rt.getRecordTypeId());
      
      rp2 = [Select Id, Name, Selling_Opp_RecordTypeId__c from Referral_Partner__c where Id=:rp2.Id];
      System.assertEquals(rp2.Selling_Opp_RecordTypeId__c,null);

      rp3 = [Select Id, Name, Selling_Opp_RecordTypeId__c from Referral_Partner__c where Id=:rp3.Id];
      System.assertEquals(rp3.Selling_Opp_RecordTypeId__c,null);

        
   } // testRecordTypeId
   
} // class ReferralPartnerMethodsTest