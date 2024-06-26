/* Temporary methods we can use for the transition from the custom to standard referral records.
   
  History
  -------
  04/08/2016 Dan Carmen   Created
  09/02/2016 Dan Carmen   Added logic in for Cases
  02/01/2018 Dan Carmen   Implement the TriggerInterface code.
  06/02/2020 Dan Carmen   Change to TriggerInterfaceC
  
 */
public without sharing class SRRTransitionHelper implements TriggerInterfaceC {

   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('SRRTransitionHelper', p_recs, oldMap, isBefore, isAfter, isDelete, null, null);
      if (recs == null || recs.isEmpty()) {
         return;
      }
      SObjectType objType = TriggerMethods.objType;
      String objTypeName = TriggerMethods.objectTypeName;
      System.debug('SRRTransitionHelper objTypeName='+objTypeName+' recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete);
      if (isBefore) {
         if (objType == Lead.sObjectType) {
            //processLeadsBefore((Lead[])recs,(Map<Id,Lead>)oldMap);
            checkBeforeCtctMap(recs, oldMap, 'Referral_Contact__c', 'ReferralContact__c', null, null);
         } else if (objType == Contact.sObjectType) {
            //processContactsBefore((Contact[])recs,(Map<Id,Contact>)oldMap);
            checkBeforeCtctMap(recs, oldMap, 'Referral_Contact__c', 'ReferralContact__c', null, null);
         } else if (objType == Opportunity.sObjectType) {
            checkBeforeCtctMap(recs, oldMap, 'Referral_Contact__c', 'ReferralContact__c', 'ReferralAccount__c', 'Referral_Account__c');
         }
         processBeforeActions();
      }
   } // handleTrigger
/*
   // this is being done here because employees don't trigger the after trigger.
   public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {
   } // checkAllBeforeTrigger

   public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {
   } // checkAllAfterTrigger

   public void checkBeforeTrigger(SObject newRec, SObject oldRec) {
      System.debug('SRRTransitionHelper.checkBeforeTrigger');
      if (newRec.getSObjectType() == Contact.sObjectType) {
         checkBeforeActions((Contact)newRec, (Contact)oldRec);
      } else if (newRec.getSObjectType() == Lead.sObjectType) {
         checkBeforeActions((Lead)newRec, (Lead)oldRec);
      } else if (newRec.getSObjectType() == Opportunity.sObjectType) {
         checkBeforeActions((Opportunity)newRec, (Opportunity)oldRec);
      }
   } // checkBeforeTrigger
   
   public void processBeforeTriggerActions() {
      processBeforeActions();
   }
   
   public void checkAfterTrigger(SObject newRec, SObject oldRec) {
   } // checkAfterTrigger
   
   public void processAfterTriggerActions() {}
  */    
   // map for querying the records. Key is ref ctct id, value is list of ids for that referral contact
   public static Map<Id,SObject[]> objectByRefCtctIdMap = new Map<Id,SObject[]>();
   // map for querying the records. Key is ref ctct id, value is list of ids for that referral contact
   public static Map<Id,SObject[]> objectByRefAcctIdMap = new Map<Id,SObject[]>();
   // the api name of the field to populate with the contact id
   public static String ctctMapCtctFld = null;
   public static String ctctMapAcctFld = null;
   public static String ctctMapRefAcctFld = null;
   
   public static String acctMapAcctFld = null;
   //public static String ctctFldName = null;
   // the api name of the field to populate with the account id (if any - can be blank)
   //public static String acctFldName = null;

   public static void checkBeforeCtctMap(SObject[] recs, Map<Id,SObject> oldMap, String refCtctFld, String ctctFld, String acctFld, String refAcctFld) {
      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         if (rec.get(refCtctFld) != null && (oldRec == null
                                         || (acctFld != null && rec.get(acctFld) == null)
                                         || rec.get(ctctFld) == null
                                         || rec.get(refCtctFld) != oldRec.get(refCtctFld))) {
            addToCtctObjectMap((Id)rec.get(refCtctFld), rec, ctctFld, acctFld);
            ctctMapRefAcctFld = refAcctFld;
         }
      } // for (SObject rec : recs
   } // checkBeforeActions

   /*
 
   public static void checkBeforeActions(Opportunity rec, Opportunity oldRec) {
      if (rec.Referral_Contact__c != null && (oldRec == null 
                                               || rec.Referral_Account__c == null
                                               || rec.ReferralContact__c == null 
                                               || (rec.Referral_Contact__c != oldRec.Referral_Contact__c ))) {
         addToCtctObjectMap(rec.Referral_Contact__c, rec, 'ReferralContact__c', 'ReferralAccount__c');
         ctctMapRefAcctFld = 'Referral_Account__c';
      }
   } // checkBeforeActions

   public static void checkBeforeActions(Lead rec, Lead oldRec) {
      if (rec.Referral_Contact__c != null && (oldRec == null 
                                               || rec.ReferralContact__c == null 
                                               || (rec.Referral_Contact__c != oldRec.Referral_Contact__c ))) {
         addToCtctObjectMap(rec.Referral_Contact__c, rec, 'ReferralContact__c', null);
      }
   } // checkBeforeActions
   
   public static void checkBeforeActions(Contact rec, Contact oldRec) {
      System.debug('checkBeforeActions Contact');
      if (rec.Referral_Contact__c != null && (oldRec == null 
                                               || rec.ReferralContact__c == null 
                                               || (rec.Referral_Contact__c != oldRec.Referral_Contact__c ))) {
         addToCtctObjectMap(rec.Referral_Contact__c, rec, 'ReferralContact__c', null);
      }
   } // checkBeforeActions
  */ 
   public static void checkBeforeActions(Case rec, Case oldRec) {
      System.debug('checkBeforeActions Case');
      if (rec.Referral_Contact__c != null && (oldRec == null 
                                               || rec.ReferralContact__c == null 
                                               || (rec.Referral_Contact__c != oldRec.Referral_Contact__c ))) {
         addToCtctObjectMap(rec.Referral_Contact__c, rec, 'ReferralContact__c', null);
      }
                                              
   } // checkBeforeActions
   
   public static void checkBeforeActions(CSA_Inquiries__c rec, CSA_Inquiries__c oldRec) {
      if (rec.Referral_Bank_Name__c != null && (oldRec == null 
                                               || rec.ReferralBankName__c == null 
                                               || (rec.Referral_Bank_Name__c != oldRec.Referral_Bank_Name__c ))) {
         addToAcctObjectMap(rec.Referral_Bank_Name__c, rec, 'ReferralBankName__c');
      }
   } // checkBeforeActions
   
   public static void checkBeforeActions(Cleansing_Object__c rec, Cleansing_Object__c oldRec) {
      if (rec.Parent_Referral_Account__c != null && (oldRec == null 
                                               || rec.ParentReferralAccount__c == null 
                                               || (rec.Parent_Referral_Account__c != oldRec.Parent_Referral_Account__c ))) {
         addToAcctObjectMap(rec.Parent_Referral_Account__c, rec, 'ParentReferralAccount__c');
      }
   } // checkBeforeActions
   
   public static void checkBeforeActions(Reference_401k_S125__c rec, Reference_401k_S125__c oldRec) {
      if (rec.Financial_Advisor__c != null && (oldRec == null 
                                               || rec.FinancialAdvisor__c == null 
                                               || (rec.Financial_Advisor__c != oldRec.Financial_Advisor__c ))) {
         addToCtctObjectMap(rec.Financial_Advisor__c, rec, 'FinancialAdvisor__c', null);
      }
   } // checkBeforeActions
   
   public static void checkBeforeActions(Referral_Partner__c rec, Referral_Partner__c oldRec) {
      if (rec.Referral_Contact__c != null && (oldRec == null 
                                               || rec.DefaultReferralContact__c == null 
                                               || (rec.Referral_Contact__c != oldRec.Referral_Contact__c ))) {
         addToCtctObjectMap(rec.Referral_Contact__c, rec, 'DefaultReferralContact__c', null);
      }
   } // checkBeforeActions
   
   public static void checkBeforeActions(Referral__c rec, Referral__c oldRec) {
      if (rec.Referral_Contact__c != null && (oldRec == null 
                                               || rec.ReferralSourceContact__c == null 
                                               || (rec.Referral_Contact__c != oldRec.Referral_Contact__c ))) {
         addToCtctObjectMap(rec.Referral_Contact__c, rec, 'ReferralSourceContact__c', null);
      }
      if (rec.Referral_Account__c != null && (oldRec == null 
                                               || rec.ReferralSourceAccount__c == null 
                                               || (rec.Referral_Account__c != oldRec.Referral_Account__c ))) {
         addToAcctObjectMap(rec.Referral_Account__c, rec, 'ReferralSourceAccount__c');
      }
   } // checkBeforeActions
   
   public static void addToCtctObjectMap(Id refCtctId, sObject rec, String ctctFldName, String acctFldName) {
      ctctMapCtctFld = ctctFldName;
      ctctMapAcctFld = acctFldName;
      ctctMapRefAcctFld = null;
      SObject[] recList = objectByRefCtctIdMap.get(refCtctId);
      if (recList == null) {
         recList = new SObject[]{};
         objectByRefCtctIdMap.put(refCtctId,recList);
      }
      recList.add(rec);
   } // addToCtctObjectMap
   
   public static void addToAcctObjectMap(Id refCtctId, sObject rec, String acctFldName) {
      acctMapAcctFld = acctFldName;
      SObject[] recList = objectByRefAcctIdMap.get(refCtctId);
      if (recList == null) {
         recList = new SObject[]{};
         objectByRefAcctIdMap.put(refCtctId,recList);
      }
      recList.add(rec);
   } // addToCtctObjectMap
   
   public static void processBeforeActions() {
      if (!objectByRefCtctIdMap.isEmpty()) {
         Referral_Contact__c[] refCtcts = getRefCtcts();
         for (Referral_Contact__c refCtct : refCtcts) {
            setContactFlds(refCtct);
         }
         objectByRefCtctIdMap.clear();
      } // if (!objectByRefCtctIdMap.isEmpty
      
      if (!objectByRefAcctIdMap.isEmpty()) {
         Referral_Account__c[] refAccts = getRefAccts();
         for (Referral_Account__c refAcct : refAccts) {
            setAccountFlds(refAcct);
         }
         objectByRefAcctIdMap.clear();
      } // if (!objectByRefAcctIdMap
   } // processBeforeActions

   public static void setContactFlds(Referral_Contact__c refCtct) {
      SObject[] recList = objectByRefCtctIdMap.get(refCtct.Id);
      System.debug('setContactFlds refCtct='+refCtct.Name+' recList='+(recList != null ? recList.size() : -1));
      if (recList != null) {
         for (SObject rec : recList) {
            if (refCtct.Contact__r != null) {
               setFieldValue(rec,ctctMapCtctFld,refCtct.Contact__r.Id);
               setFieldValue(rec,ctctMapAcctFld,refCtct.Contact__r.AccountId);
            }
            setFieldValue(rec,ctctMapRefAcctFld,refCtct.Referral_Account__c);
         }
      } // if (recList != null
   } // setContactFlds
   
   public static void setAccountFlds(Referral_Account__c refAcct) {
      SObject[] recList = objectByRefAcctIdMap.get(refAcct.Id);
      if (recList != null && refAcct.Account__c != null) {
         for (SObject rec : recList) {
            setFieldValue(rec,acctMapAcctFld,refAcct.Account__c);
         }
      } // if (recList != null
   } // setAccountFlds
   
   public static void setFieldValue(SObject rec, String fieldName, Object value) {
      //System.debug('setFieldValue fieldName='+fieldName+' value='+value);
      if (String.isNotBlank(fieldName) && rec != null && value != null) {
         try {
            rec.put(fieldName, value);
         } catch (Exception e) {
            System.debug('setFieldValue fieldName='+fieldName+' exception='+e.getStackTraceString());
         }
      }
   } // setFieldValue
   
   public static Referral_Contact__c[] getRefCtcts() {
      Referral_Contact__c[] refCtcts = [Select Id, Name, Contact__c, Contact__r.Id, Contact__r.AccountId
                                              ,Referral_Account__c, Referral_Account__r.Id, Referral_Account__r.Account__c
                                          From Referral_Contact__c
                                         Where Id in :objectByRefCtctIdMap.keySet()];
      return refCtcts;
   } // getRefCtcts
   
   public static Referral_Account__c[] getRefAccts() {
      Referral_Account__c[] refAccts = [Select Id, Name, Account__c
                                          From Referral_Account__c
                                         Where Id in :objectByRefAcctIdMap.keySet()];
      return refAccts;
   } // getRefAccts
   
} // class SRRTransitionHelper