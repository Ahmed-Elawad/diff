/**
 * History
 * -------------------------------------------------------------------
   04/05/2023 Vinay           Created.
   06/02/2023 Dan Carmen      Moved to TriggerInterface
   12/08/2023 Dan Carmen      Updated debug statements

*/
public without sharing class MutualClientRelationMethods implements TriggerInterfaceC {
   public static final String CLASSNAME='MutualClientRelationMethods';
   public static final String RLTN_CPA='CPA';
    
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('MutualClientRelationMethods.handleTrigger p_recs='+(p_recs != null ? p_recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete+' Trigger.old='+(Trigger.old != null ? Trigger.old.size() : -1));
      SObject[] recs = TriggerMethods.checkRecs(CLASSNAME, p_recs, oldMap, isBefore, isAfter, isDelete, null, null);
      if (recs == null || recs.isEmpty()) {
         System.debug('handleTrigger trigger ran');
         return;
      }

      Id[] checkMutualRltns = new Id[]{};
      for (Account acct : (Account[])recs) {
          System.debug('MutualClientRelationMethods.handleTrigger acct='+acct.Name);
         Account oldAcct = (oldMap != null ? ((Map<Id,Account>)oldMap).get(acct.Id) : null);
         if ((oldAcct == null && acct.CPA_Name_Ref__c != null) 
               || (oldAcct != null && acct.CPA_Name_Ref__c != oldAcct.CPA_Name_Ref__c)) {
            checkMutualRltns.add(acct.Id);
         }
      } // for (Account acc : newAccountList
      
      if (!checkMutualRltns.isEmpty()) {
         handleRelations(checkMutualRltns,false, oldMap);
      } // if (!chkAcctMap.isEmpt

   } // handleTrigger
    
   public static void handleRelations(Id[] acctIds, Boolean updateVerificationDate, Map<Id,SObject> oldMap) {
      System.debug('handleRelations updateVerificationDate='+updateVerificationDate+' acctIds='+acctIds.size());
       System.debug('handleRelations oldMap='+(oldMap!=null ? oldMap.size(): -1));
      MutualClientRltn__c[] updateRltns = new MutualClientRltn__c[]{};
      MutualClientRltn__c[] insertRltns = new MutualClientRltn__c[]{};
      Account[] accts = [SELECT Id, CPA_Name_Ref__c, CPA_Name_Ref__r.Referral_Account__c, CPA_Name_Ref__r.Referral_Account__r.OwnerId
                               , CPA_Name_Ref__r.Referral_Account__r.ARM_Owner__c
                                ,(Select Id, Account__c, Verification_Action__c, RltnType__c
                                        ,ReferralAccount__c, ReferralContact__c, StartDate__c, EndDate__c
                                        ,ReferralSourceVerification__c, ReferralSourceVerificationDate__c
                                    From MutualClientRelations__r
                                   Where EndDate__c = null)
                             FROM Account WHERE Id in :acctIds];
       
      Set<String> setOLdCpas = new Set<String>();
       if(oldMap != null){
         for(Account acc : ((Map<Id,Account>)oldMap).values()){
           setOLdCpas.add(acc.CPA_Name_Ref__c);
       	}   
       }
      
      Map<Id, Referral_Contact__c> mapIdToRefContact = new Map<Id, Referral_Contact__c>([Select id,Referral_Account__c, Referral_Account__r.ARM_Owner__c from  Referral_Contact__c where Id IN :setOLdCpas]);
      System.debug('handleRelations mapIdToRefContact='+mapIdToRefContact.size());
      Set<String> systemAdminProfiles = new Set<String>{'System Administrator API','System Administrator API-Alteryx','System Administrator'};
      Map<Id, Profile> mapIdToProfile = new Map<Id, Profile>([Select Id, Name from Profile where Name in : systemAdminProfiles]);
      for (Account acct : accts) {
           Account oldAcct = (oldMap != null ? ((Map<Id,Account>)oldMap).get(acct.Id) : null);
          System.debug('handleRelations oldAcct='+(oldAcct!=null));
         MutualClientRltn__c foundRltn = null;
         for (MutualClientRltn__c mcr : acct.MutualClientRelations__r) {
            if (mcr.RltnType__c == RLTN_CPA) {
                if (acct.CPA_Name_Ref__c != null && acct.CPA_Name_Ref__r.Referral_Account__c != null) {
                    if (UserInfo.getUserId() == acct.CPA_Name_Ref__r.Referral_Account__r.ARM_Owner__c) {
                        mcr.ReferralSourceVerification__c = 'ARM';
                    }
                    else if(mapIdToProfile.containsKey(UserInfo.getProfileId())){
                        mcr.ReferralSourceVerification__c = 'Data Update';
                    }
                    else {
                        
                        mcr.ReferralSourceVerification__c = 'Sales';
                    }
                }
               if (mcr.ReferralContact__c != acct.CPA_Name_Ref__c )  {
                  System.debug('handleRelations ending existing relation');
                  // end it
                  mcr.EndDate__c = System.today();
                  mcr.Verification_Action__c = 'Removed';
                  updateRltns.add(mcr);
               } else {
                  foundRltn = mcr;
                  if (updateVerificationDate) {
                     System.debug('handleRelations Updating Verification Date');
                     mcr.Verification_Action__c = 'Verified';
                     mcr.ReferralSourceVerificationDate__c = Datetime.now();
                     updateRltns.add(mcr);
                  }
               }
            }
         } // for (MutualClientRltn__c mcr : acct.MutualClientRelations__r
          System.debug('handleRelations acct.CPA_Name_Ref__c='+acct.CPA_Name_Ref__c);
         if (foundRltn == null && acct.CPA_Name_Ref__c != null) {
            System.debug('handleRelations creating new relation');
            // create a new one
            MutualClientRltn__c mcr = new MutualClientRltn__c();
            mcr.Account__c = acct.Id;
            mcr.ReferralSourceVerificationDate__c = System.now();
            mcr.RltnType__c = RLTN_CPA;
            mcr.Verification_Action__c = 'Verified';
            mcr.ReferralAccount__c = acct.CPA_Name_Ref__c != null ? acct.CPA_Name_Ref__r.Referral_Account__c : null;
            mcr.ReferralContact__c = acct.CPA_Name_Ref__c;
            mcr.StartDate__c = System.today();
            if (acct.CPA_Name_Ref__c != null && acct.CPA_Name_Ref__r.Referral_Account__c != null) {
               if (UserInfo.getUserId() == acct.CPA_Name_Ref__r.Referral_Account__r.ARM_Owner__c) {
                  mcr.ReferralSourceVerification__c = 'ARM';
               }
               else if(mapIdToProfile.containsKey(UserInfo.getProfileId())){
                    mcr.ReferralSourceVerification__c = 'Data Update';
                }
                else {
                   
                  mcr.ReferralSourceVerification__c = 'Sales';
               }
            } // if (acct.CPA_Name_Ref__c != null
            insertRltns.add(mcr);
         } // if (foundRltn == null
         if (foundRltn == null && acct.CPA_Name_Ref__c == null) {
             System.debug('>>>>>>>>Entered here  foundRltn == null && acct.CPA_Name_Ref__c == null');
            MutualClientRltn__c mcr = new MutualClientRltn__c();
            mcr.Account__c = acct.Id;
            mcr.RltnType__c = RLTN_CPA;
             if(mapIdToRefContact.containsKey(oldAcct.CPA_Name_Ref__c)){
                 System.debug('handleRelations mapIdToRefContact.get(acct.Id)='+mapIdToRefContact.get(acct.Id));
                 mcr.ReferralAccount__c = mapIdToRefContact.get(oldAcct.CPA_Name_Ref__c).Referral_Account__c;
                 mcr.ReferralContact__c = oldAcct.CPA_Name_Ref__c; //to add referral contact to removed cpa;
                 if (mapIdToRefContact.get(oldAcct.CPA_Name_Ref__c).Referral_Account__c != null) {
                   if (UserInfo.getUserId() == mapIdToRefContact.get(oldAcct.CPA_Name_Ref__c).Referral_Account__r.ARM_Owner__c) {
                      mcr.ReferralSourceVerification__c = 'ARM';
                   }
                   else if(mapIdToProfile.containsKey(UserInfo.getProfileId())){
                        mcr.ReferralSourceVerification__c = 'Data Update';
                    }
                    else {
                       
                      mcr.ReferralSourceVerification__c = 'Sales';
                   }
                } 
             }
             
            mcr.Verification_Action__c = 'Removed';
            mcr.StartDate__c = System.today();
            mcr.EndDate__c = System.today();
            insertRltns.add(mcr);
         }
      } // for (Account acct : accts
      DmlHelper.performDML2(updateRltns, DmlHelper.DML_UPDATE, CLASSNAME, 'handleRelations', 'Update existing relations', false);
      DmlHelper.performDML2(insertRltns, DmlHelper.DML_INSERT, CLASSNAME, 'handleRelations', 'Insert new relations', false);
      ErrorLog.checkSave();
   } // handleRelations

  @AuraEnabled
  public static void handleMutualClientVerification(Id accountId){
     handleRelations(new Id[]{accountId}, true, null);

  } // handleMutualClientVerification
    
  @AuraEnabled(cacheable = true)
  public static Account getAccountCPA(String accountId){
    try {
      return [SELECT Id, OwnerId, CPA_Name_Ref__c, CPA_Name_Ref__r.Name, CPA_Name_Ref__r.Referral_Account__c,CPA_Name_Ref__r.PrimaryReferralType__c,(Select Id, CreatedBy.Name, Name,EndDate__c,ReferralAccount__c,ReferralContact__c,ReferralSourceVerification__c,ReferralSourceVerificationDate__c,RltnType__c,StartDate__c from MutualClientRelations__r where EndDate__c = null Limit 1) FROM Account WHERE Id =: accountId];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  } // getAccountCPA
    
  @AuraEnabled
  public static string removeCPAFromAccount(Id accountId){
     System.debug('removeCPAFromAccount accountId='+accountId);
     try {
        Account acc = new Account(Id=accountId, CPA_Name_Ref__c=null);
        update acc;
     } catch (Exception e) {
        return e.getMessage() +'--'+e.getStackTraceString();
     }
     return 'SUCCESS';

  } // removeCPAFromAccount
   
  @AuraEnabled
  public static String getReferralAccountId(Id referralContactId){
    return [SELECT Id, Referral_Account__c FROM Referral_Contact__c WHERE Id =: referralContactId].Referral_Account__c;
  } // getReferralAccountId
    
  @AuraEnabled(cacheable = true)
  public static String getUserDetalsAndRefOwnereAndARM(Id refAccId){
    System.debug('getUserDetalsAndRefOwnereAndARM refAccId='+ refAccId);
     Referral_Account__c ref = [SELECT Id, OwnerId, ARM_Owner__c  FROM Referral_Account__c WHERE Id =: refAccId];
     UserDetailsForRefAccounts objUD = new UserDetailsForRefAccounts();
     objUD.ARMId = ref.ARM_Owner__c;
     objUD.OwnerId = ref.OwnerId;
     objUD.userId = UserInfo.getUserId();
     Boolean isOwnerOrARM =false;
     if(objUD.ARMId == objUD.userId || objUD.OwnerId == objUD.userId){
       isOwnerOrARM = true;
     }
     objUD.isOwnerOrARM = isOwnerOrARM;
     return JSON.serialize(objUD);
  } // getUserDetalsAndRefOwnereAndARM
    
  public class UserDetailsForRefAccounts{
    public String ARMId;
    public String OwnerId;
    Public String userId;
    Public Boolean isOwnerOrARM;

  } // class UserDetailsForRefAccounts

  @AuraEnabled
  public static void updateProspectAccount(String accountId, String cpaFullName) {
    Account acc = [SELECT Id, CPA_Name_Ref__c FROM Account WHERE Id=: accountId];
    acc.CPA_Name_Ref__c = cpaFullName != '' ? cpaFullName : null;
    try {
      update acc;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  } // updateProspectAccount
    
} // class MutualClientRelationMethods