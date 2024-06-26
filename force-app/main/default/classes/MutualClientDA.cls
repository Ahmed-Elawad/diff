/* Test methods for MutualClientDA

  History
  -------
  10/10/2019 Dan Carmen        Clean up test, get better test coverage
  03/23/2022 Dan Carmen        Clean up Code
  04/05/2023 Vinay             Added fields to "getMutualClients" method
 */
public with sharing class MutualClientDA {
   
    public Integer getMutualClientsByReferralContactId(Id referralContactId) {
       Integer recCount = 0;
       if (referralContactId != null) {
          recCount = countMutualClients(new Id[]{referralContactId});
       }
       return recCount;
    } // getMutualClientsByReferralContactId

    public Integer getMutualClientsByReferralContacts(List<Referral_Contact__c> referralContacts) {
       Integer recCount = 0;
       if (referralContacts != null && !referralContacts.isEmpty()) {
          Id[] refCtctIds = new Id[]{}; 
          for (Referral_Contact__c refCtct : referralContacts) {
             if (refCtct.Id != null) {
                refCtctIds.add(refCtct.Id);
             }
          } // for
          recCount = countMutualClients(refCtctIds);
       }
       return recCount;
    } // getMutualClientsByReferralContacts
    
   public Integer countMutualClients(Id[] refCtctIds) {
      Integer nbrClients = 0;
      if (refCtctIds != null && !refCtctIds.isEmpty()) {
          nbrClients = [SELECT Count()
                          FROM Account
                         WHERE CPA_Name_Ref__c IN :refCtctIds
                            OR Banker_Name_Ref__c IN :refCtctIds
                            OR Broker_Name_Ref__c IN :refCtctIds
                            OR Insurance_Broker_Name_Ref__c IN :refCtctIds];
      }
      return nbrClients;
   } // countMutualClients

   public List<Account> getMutualClientFieldsByByReferralContactId(Id referralContactId) {
      Account[] accts = (referralContactId == null ? new Account[]{} : getMutualClients(new Id[]{referralContactId}));
      return accts;
   } // getMutualClientFieldsByByReferralContactId

   public List<Account> getMutualClientFieldsByByReferralContacts(List<Referral_Contact__c> referralContacts) {
      Id[] refCtctIds = new Id[]{};
      if (referralContacts != null) {
         for (Referral_Contact__c refCtct : referralContacts) {
            if (refCtct.Id != null) {
               refCtctIds.add(refCtct.Id);
            }
         }
      } // if (referralContacts != null
      Account[] accts = (refCtctIds.isEmpty() ? new Account[]{} : getMutualClients(refCtctIds));
      return accts;
   } // getMutualClientFieldsByByReferralContacts
    
   public Account[] getMutualClients(Id[] refCtctIds) {
      Account[] accts = (refCtctIds == null || refCtctIds.isEmpty() ? new Account[]{}
                         : [SELECT Id, 
                                   Name, 
                                   Fed_ID_Name__c, 
                                   Bis_ID__c, 
                                   CreatedDate, 
                                   AccountNumber, 
                                   Type,
                                   ShippingAddress,
                                   First_Run_Date__c,
                                   Legal_State__c,
                                   Owner_Zip_Code__c,
                                   SignificantContact__r.Name,
                                   BillingAddress, 
                                   NumberOfEmployees, 
                                   Owner.LastName,
                                   X401K_Assets__c,
                                   Paychex_401K_Assets__c,
                                   CPA_Name_Ref__r.Name,(Select Id, CreatedBy.Name, Name,EndDate__c,ReferralAccount__c,ReferralContact__c,ReferralSourceVerification__c,ReferralSourceVerificationDate__c,RltnType__c,StartDate__c from MutualClientRelations__r where EndDate__c = null Limit 1)
                              FROM Account
                             WHERE CPA_Name_Ref__c IN :refCtctIds
                                OR Banker_Name_Ref__c IN :refCtctIds
                                OR Broker_Name_Ref__c IN :refCtctIds
                                OR Insurance_Broker_Name_Ref__c IN :refCtctIds]);
      return accts;
   } // getMutualClients
} // class MutualClientDA