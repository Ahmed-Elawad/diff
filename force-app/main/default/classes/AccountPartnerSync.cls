/* 
 * Method for managing the relationship between the partner and account objects.
               
 *
 * History
 * -------
   09/28/2015 Dan Carmen   Created
   12/06/2016 Dan Carmen   Modifications to make it more flexible
   05/25/2017 Dan Carmen      Move logic to class
   01/24/2023 Dan Carmen      Increment API, change to InterfaceC

 */
public with sharing class AccountPartnerSync implements TriggerInterfaceC {
    
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('AccountPartnerSync', p_recs, oldMap, isBefore, isAfter, null, null);
      System.debug('AccountPartnerSync.handleTrigger recs='+(recs != null ? recs.size() : -1));
      if (!recs.isEmpty() && isAfter) {
         checkAccountsAfter((Account[])recs, (Map<Id,Account>)oldMap);
      }
   } // handleTrigger  

   // this should be a more dynamic setup
   public static Set<String> getSyncReferralTypes() {
      Set<String> syncReferralTypes = new Set<String>();
      for (ReferralType__c refType : ReferralType__c.getAll().values()) {
         if (refType.PartnerReferralForm__c) {
            syncReferralTypes.add(refType.Name.trim());
         }
      }
      System.debug('getSyncReferralTypes syncReferralTypes='+syncReferralTypes);
      return syncReferralTypes;
   } // getSyncReferralTypes

   public void checkAccountsAfter(Account[] accts, Map<Id,Account> oldMap) {
      Set<String> syncReferralTypes = getSyncReferralTypes();
      Set<Id> parentAcctIdSet = new Set<Id>();
      Set<Id> branchAcctIdSet = new Set<Id>();

      for (Account acct : accts) {
         // check all children, and parents where the referral type is one of the specified values
         if (acct.ReferralParent__c != null
             || (String.isNotBlank(acct.Referral_Type__c) && syncReferralTypes.contains(acct.Referral_Type__c.trim()))
             || (String.isNotBlank(acct.Referral__c) && syncReferralTypes.contains(acct.Referral__c.trim()))) {
            if (acct.ReferralParent__c == null) {
               parentAcctIdSet.add(acct.Id);
            } else {
               parentAcctIdSet.add(acct.ReferralParent__c);
               branchAcctIdSet.add(acct.Id);
            }
         }
      } // for (Account acct
      if (!parentAcctIdSet.isEmpty() || !branchAcctIdSet.isEmpty()) {
         if (Utilities.allowFuture()) {
            processUpdatesInsertsFuture(parentAcctIdSet, branchAcctIdSet);
         } else {
            processUpdatesInserts(parentAcctIdSet, branchAcctIdSet);
         }
      }
   } // checkAccountsAfter

   public void checkDeleteBefore(SObject[] oldRecs, Map<Id,SObject> oldRecMap) {
      handleDeletes(oldRecMap.keySet());
   }
   
   
   //@future
   private static void processUpdatesInsertsFuture(Set<Id> parentAcctIdSet, Set<Id> branchAcctIdSet) {
      processUpdatesInserts(parentAcctIdSet, branchAcctIdSet);
   } // processUpdatesInsertsFuture

   public static void processUpdatesInserts(Set<Id> parentAcctIdSet, Set<Id> branchAcctIdSet) {
      // get the accounts - only select the ones that are linked to a referral id (vendor id)
      Map<Id,Account> allAcctMap = new Map<Id,Account>([Select Id, Name, ParentId
                                                              ,End_Date__c
                                                              ,Owner_Zip_Code__c
                                                              ,PartnerId__c
                                                              ,Referral_Type__c
                                                              ,ReferralProducts__c
                                                              ,ReferralParent__c
                                                              ,ReferralParent__r.Id
                                                              ,ReferralParent__r.PartnerId__c
                                                              ,(Select Id, Name
                                                                      ,Account__c
                                                                  from PartnerDetails__r)
                                                              ,(Select Id, Name, Account__c
                                                                      ,EndDate__c
                                                                      ,ParentPartner__c, PartnerId__c
                                                                      ,PostalCode__c, ReferralProducts__c
                                                                      ,PartnerDetail__c
                                                                  From Partners__r
                                                                 order by createdDate asc)
                                                          from Account
                                                         Where (Id in :parentAcctIdSet or Id in :branchAcctIdSet)
                                                           and (PartnerId__c != null or ReferralParent__r.PartnerId__c != null)
                                                         ]);
      System.debug('handleUpdatesInserts allAcctMap='+allAcctMap.size());
      /*
      // get the existing partner records
      Partner__c[] partners = [Select id, Name, Account__c, ParentPartner__c, PartnerId__c
                                     ,PostalCode__c, ReferralProducts__c
                                     ,PartnerDetail__c
                           From Partner__c
                          Where Account__c in :allAcctMap.keySet()];
      System.debug('handleUpdatesInserts allAcctMap='+allAcctMap.size()+' existing partners='+partners.size());
      */                  
      // store the partners in a map by account id.
      Map<Id,Partner__c> partnerMap = new Map<Id,Partner__c>();
      /*
      for (Partner__c partner : partners) {
         partnerMap.put(partner.Account__c, partner);
      }
      */
      // check the parents first
      Map<Id,Partner__c> insertPartnerMap = new Map<Id,Partner__c>();
      Map<Id,Partner__c> updatePartnerMap = new Map<Id,Partner__c>();
      Map<Id,Partner__c> deletePartnerMap = new Map<Id,Partner__c>();
      
      System.debug('handleUpdatesInserts checking parents');
      handleIdSet(parentAcctIdSet, allAcctMap, partnerMap,insertPartnerMap, updatePartnerMap, deletePartnerMap);
      
      // insert parents at this point so they can be linked to branches in the next step. The update does not need to occur here.
      DmlHelper.performDML2(insertPartnerMap.values(), DmlHelper.DML_INSERT,'AccountPartnerSync', 'handleUpdatesInserts', 'Inserting new parent partners', false);
      insertPartnerMap.clear();
      
      System.debug('handleUpdatesInserts checking children');
      handleIdSet(branchAcctIdSet, allAcctMap, partnerMap,insertPartnerMap, updatePartnerMap, deletePartnerMap);

      DmlHelper.performDML2(insertPartnerMap.values(), DmlHelper.DML_INSERT, 'AccountPartnerSync', 'handleUpdatesInserts', 'Inserting new branches', false);
      DmlHelper.performDML2(updatePartnerMap.values(), DmlHelper.DML_UPDATE, 'AccountPartnerSync', 'handleUpdatesInserts', 'Updating branches', false);
      DmlHelper.performDML2(deletePartnerMap.values(), DmlHelper.DML_DELETE, 'AccountPartnerSync', 'handleUpdatesInserts', 'deleting branches', false);

      ErrorLog.checkSave();
      
   } // processUpdatesInserts

   private static void handleIdSet(Set<Id> acctIdSet, Map<Id,Account> allAcctMap, Map<Id,Partner__c> partnerMap
                                ,Map<Id,Partner__c> insertPartnerMap, Map<Id,Partner__c> updatePartnerMap
                                ,Map<Id,Partner__c> deletePartnerMap) {
      
      for (Id acctId : acctIdSet) {
         Account acct = allAcctMap.get(acctId);
         if (acct != null) {
            Partner__c partner = getPartner(acct, partnerMap, deletePartnerMap);
            Partner__c parentPartner = (acct.ReferralParent__c != null ? getPartner(allAcctMap.get(acct.ReferralParent__c), partnerMap, deletePartnerMap) : null);
            

            //Partner__c partner = partnerMap.get(acctId);
            //Partner__c parentPartner = (acct != null && acct.ReferralParent__c != null ? partnerMap.get(acct.ReferralParent__c) : null);
            PartnerDetail__c partnerDetail = (acct != null && !acct.PartnerDetails__r.isEmpty() ? acct.PartnerDetails__r[0] : null);
            System.debug('handleIdSet acct='+acct.Name+' partner='+(partner != null)+' parentPartner='+(parentPartner != null)+' partnerDetail='+(partnerDetail != null));
         
            // only create a new partner if there's not an end date
            if (partner == null && acct.End_Date__c == null) {
               System.debug('handleIdSet acct='+acct.Name+' inserting partner');
               partner = new Partner__c(Name=acct.Name, PartnerId__c=acct.PartnerId__c, PostalCode__c=acct.Owner_Zip_Code__c, Account__c=acct.Id
                           ,ParentPartner__c=(parentPartner != null ? parentPartner.Id : null)
                           ,PartnerDetail__c = (partnerDetail != null ? partnerDetail.Id : null)
                           ,ReferralProducts__c=acct.ReferralProducts__c
                           ,EndDate__c=acct.End_Date__c);
               insertPartnerMap.put(acctId, partner);
               partnerMap.put(acctId, partner);
            } else if (partner != null) {
               // shouldn't be a parent here, but just in case.
               checkForChanges(acct, partner, parentPartner, partnerDetail, updatePartnerMap);
            }
         } // if (acct != null
      } // for (Id acctId
   } // handleIdSet
   
   private static Partner__c getPartner(Account acct, Map<Id,Partner__c> partnerMap, Map<Id,Partner__c> deletePartnerMap) {
      Partner__c partner = (acct != null ? partnerMap.get(acct.Id) : null);
      if (partner == null && acct != null) {
         Partner__c[] partners = acct.Partners__r;
         if (partners != null && !partners.isEmpty()) {
            partner = partners[0];
            // there should only be one partner per account - delete any extra!
            for (Integer cnt=1; cnt<partners.size(); cnt++) {
               deletePartnerMap.put(partners[cnt].Id, partners[cnt]);
            }
         } // if (partners != null
         if (partner != null) {
            partnerMap.put(acct.Id, partner);
         }
      } // if (acct != null
      return partner;
   } // getPartner

   private static void checkForChanges(Account acct, Partner__c partner, Partner__c parentPartner, PartnerDetail__c partnerDetail, Map<Id,Partner__c> updatePartnerMap) {
      Boolean parentChanged = (parentPartner != null && partner.ParentPartner__c != parentPartner.Id 
                               || parentPartner == null && partner.ParentPartner__c != null);
      
      Id partnerDetailId = (partnerDetail != null ? partnerDetail.Id : null);
      
      System.debug('handleIdSet acct='+acct.Name+' parentChanged='+parentChanged+' partnerDetailId='+partnerDetailId);

      if (parentChanged || partner.Name != acct.Name 
          || partner.PostalCode__c != acct.Owner_Zip_Code__c
          || partner.PartnerId__c != acct.PartnerId__c
          || partner.ReferralProducts__c != acct.ReferralProducts__c
          || partner.PartnerDetail__c != partnerDetailId
          || partner.EndDate__c != acct.End_Date__c) {
         partner.Name = acct.Name;
         partner.PostalCode__c = acct.Owner_Zip_Code__c;
         partner.PartnerId__c = acct.PartnerId__c;
         partner.ParentPartner__c = (parentPartner != null ? parentPartner.Id : null);
         partner.ReferralProducts__c = acct.ReferralProducts__c;
         partner.PartnerDetail__c = partnerDetailId;
         partner.EndDate__c = acct.End_Date__c;
         System.debug('handleIdSet acct='+acct.Name+' adding to update map');
         updatePartnerMap.put(acct.Id, partner);
      }
   } // checkForChanges
   
   public static void handleDeletes(Set<Id> deleteAcctIdSet) {
      // delete the Partner records associated with the accounts deleted.
      try {
         delete [Select Id from Partner__c where Account__c in :deleteAcctIdSet];
      } catch (Exception e) {
         // what do we need to do here?
         System.debug('handleDeletes error deleting the partner: '+e);
      }
   } // handleDeletes
   
} // class AccountPartnerSync