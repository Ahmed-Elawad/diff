/* Check if we can delete an account record

  History
  -------
  01/10/2017 Dan Carmen        Created
  10/02/2023 Carrie Marciano	added criteria to exclude the Paychex Inc SA account from being deleted, removed commented code, incremented API version
  
 */
public without sharing class AccountDeleteCheck {
    
   public static void checkForDelete(Account[] accts) {
      Id[] acctIds = new Id[]{};
      Id[] parentIds = new Id[]{};
      Account[] checkForParents = new Account[]{};
      Schema.RecordTypeInfo rtSysAdmin = RecordTypeHelper.getRecordType(Label.RT_System_Admin_Account, ObjectHelper.OBJECT_ACCOUNT);
       
      for (Account acct : accts) {
          if(acct.Name.contains('Paychex') && acct.RecordTypeId == rtSysAdmin.getRecordTypeId()){
          	acct.addError('Cannot delete Paychex Inc SA record');  
            System.debug('checkForDelete '+acct.Id+' Cannot delete Paychex Inc SA record');  
          } 
          else 
          {
          	acctIds.add(acct.Id);
         	if (acct.ReferralParent__c != null) {
            	acctIds.add(acct.ReferralParent__c);
          	}
          }
          
      } // for (Account acct
      
      System.debug('acctIds='+acctIds);
      if (!acctIds.isEmpty()) {
         Map<Id,Account> acctMap = new Map<Id,Account>([Select Id
                                                              ,PartnerId__c
                                                              ,PartnerDetail__r.Id
                                                              ,PartnerDetail__r.ReferralPaymentStart__c
                                                              ,PartnerDetail__r.ReferralPaymentEnd__c
                                                              ,(Select Id, ReferralPaymentStart__c, ReferralPaymentEnd__c from PartnerDetails__r)
                                                          From Account where Id in :acctIds]);
         for (Account acct : accts) {
            Id checkAcctId = (acct.ReferralParent__c != null ? acct.ReferralParent__c : acct.Id);
            Account checkAcct = acctMap.get(checkAcctId);
            System.debug('checkAcctId='+checkAcctId+' checkAcct='+checkAcct);
            if (checkAcct != null) {
               PartnerDetail__c partDetail = checkAcct.PartnerDetail__r;
               if (partDetail == null && checkAcct.PartnerDetails__r != null && checkAcct.PartnerDetails__r.size() > 0) {
                  partDetail = checkAcct.PartnerDetails__r[0];
               }
               System.debug('partDetail='+partDetail);
               if (partDetail != null) {
                  if (checkAcct.PartnerId__c != null && partDetail.ReferralPaymentStart__c != null) {
                     if (partDetail.ReferralPaymentEnd__c == null || partDetail.ReferralPaymentEnd__c > Date.today()) {
                        acct.addError('Cannot delete a record setup for referral payment');
                     }
                  }
               }
            } // if (checkAcct != null
         } // for (Account acct
      } // if (!acctIds.isEmpty
   } // checkForDelete
   
} // class AccountDeleteCheck