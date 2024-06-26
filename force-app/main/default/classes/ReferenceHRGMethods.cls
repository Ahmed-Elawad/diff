/* 
   Methods specific to the reference HRG object.
   
  History
  -------
  08/02/2013 Dan Carmen   Created
  04/19/2016 Jacob Hinds  Update owner of onboarding record when account HRG changes.
   
 */
public with sharing class ReferenceHRGMethods {

   public class RefHrgUsers {
      public Id accountId;
      public Id ownerId;
      public Id hrsSalesRepId;
   } // RefHrgUsers
   
   /** Check users on the reference objects. If anything changes it will update them.
    */
   public static void checkReferenceHrgs(RefHrgUsers[] recsToCheck) {
    // make sure there are records to process
      if (recsToCheck == null || recsToCheck.isEmpty()) {
         return;
      }
      
      // map of the records by the account ids for easy reference
      Map<Id,RefHrgUsers> refHrgUserMap = new Map<Id,RefHrgUsers>();
      for (RefHrgUsers rhu : recsToCheck) {
         refHrgUserMap.put(rhu.accountId,rhu);
      }
      
      Reference_HRG__c[] recsToUpdate = new Reference_HRG__c[]{};
      // select the reference HRGs
      for (Reference_HRG__c[] refHRGs : [Select Id, OwnerId, Account__c
                                               ,HRS_Account_Owner__c
                                           From Reference_HRG__c
                                          Where Account__c in :refHrgUserMap.keySet()]) {
         for (Reference_HRG__c refHRG : refHRGs) {
            RefHrgUsers rhu = refHrgUserMap.get(refHRG.Account__c);
            if (rhu != null) {
                Boolean changed = false;
               if (rhu.ownerId != null && rhu.ownerId != refHRG.OwnerId) {
                  refHRG.OwnerId = rhu.ownerId;
                  changed = true;
               } // if (rhu.ownerId != null
               
               if (rhu.hrsSalesRepId != null && rhu.hrsSalesRepId != refHRG.HRS_Account_Owner__c) {
                  refHRG.HRS_Account_Owner__c = rhu.hrsSalesRepId;
                  changed = true;
               }
               if (changed) {
                  recsToUpdate.add(refHRG);
               }
            } // if (rhu != null
         } // for (Reference_HRG__c refHRG
      } // for (Reference_HRG__c[] refHRGs
      
      if (!recsToUpdate.isEmpty()) {
         update recsToUpdate;
      }
   } // checkReferenceHrgs
   
   public static String RT_PREMIER_SURVEY = 'Service Premier Record Type';
   public static String SURVEY_CASE_ORIGIN = 'NC - Survey Alert';
   
   public static void checkPremierSurveyDate(Map<Id,Id> acctCaseIdMap) {
      // select the reference objects to populate the survey date
      Reference_HRG__c[] refs = [Select Id, Account__c, NCSurveyCase__c, NCSurveyDate__c from Reference_HRG__c where Account__c in :acctCaseIdMap.keySet()];
      for (Reference_HRG__c ref : refs) {
         // get the case id
         Id caseId = acctCaseIdMap.get(ref.Account__c);
         if (caseId != null) {
            ref.NCSurveyCase__c = caseId;
            ref.NCSurveyDate__c = Date.today();
         }
      } // for
      // save the changes
      update refs;
   } // checkPremierSurveyDate
   
   
   public static void ownerSync(Map<Id,Id> contactAcctMap){
    Reference_HRG__c[] uRefs = new Reference_HRG__c[]{};
    Map<Id,Id> acctUserMap = new Map<Id,Id>();
      //since the hrg on the account is a contact, we need to get the user record of that contact via User_Lookup__c 
      //which gets linked when the HR Person Id gets filled on both records.
      for (Contact hrg:[SELECT Id,HR_Person_Id__c,User_Lookup__c from Contact WHERE Id in :contactAcctMap.keySet()] ){      
        Id accountId = contactAcctMap.get(hrg.Id);
        if(accountId != null){
            acctUserMap.put(accountId,hrg.User_Lookup__c);
        }
      }
      //find all hrg onboarding records on the account
      if(!acctUserMap.isEmpty()){
          for (Reference_HRG__c ref : [Select Id, OwnerId,Account__c from Reference_HRG__c where Account__c in :acctUserMap.keySet()]) {
             // get the case id 
             Id ownerId = acctUserMap.get(ref.Account__c);         
             if (ownerId != null && ref.OwnerId != ownerId) {
                ref.OwnerId = ownerId;
                uRefs.add(ref);
             }
          } // for
      }
      if(!uRefs.isEmpty()){
        DmlHelper.performDML2(uRefs, DmlHelper.DML_UPDATE, 'ReferenceHRGMethods', 'ownerSync', 'Update Ref HRG', false);
      }
   }
   
} // class ReferenceHRGMethods