//Account profiled

/** Handles the expiration date for the Account Profiled field
 *
 * History
 * -------
 * 11/18/2016 Jake Hinds	  Created
 * 01/05/2017 Jake Hinds	  Removing Opportunity stuff
 * 02/23/2017 Jermaine Stukes Added logic for contact
   07/19/2017 Dan Carmen      Update Profiled logic
   01/29/2018 Jacob Hinds	  Adding Referral Contact
   11/05/2021 Dan Carmen      Rewrite code to use TriggerInterfaceC
   12/01/2021 Dan Carmen      Ability to require contacts for profiling
   12/04/2023 Susmitha Somavarapu Commented out the code from 310-325 lines for field removal for cpa profiling work(APR0160191)
 */
public without sharing class AccountProfiled implements TriggerInterfaceC {

   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      TriggerMethods.objType = (recs != null && !recs.isEmpty() ? recs[0].getSObjectType() : null);
      if (TriggerMethods.objType == null) {
         return;
      }
      System.debug('AccountProfiled.handleTrigger recs='+recs.size()+' objType='+TriggerMethods.objType);
      if (isBefore) {
         if (TriggerMethods.objType == Account.sObjectType) {
            checkAcctsBefore((Account[])recs, (Map<Id,Account>)oldMap);
         } else if (TriggerMethods.objType == Contact.sObjectType) {
            checkCtctsBefore((Contact[])recs, (Map<Id,Contact>)oldMap);
         } else if (TriggerMethods.objType == Referral_Contact__c.sObjectType) {
            checkRefCtctsBefore((Referral_Contact__c[])recs, (Map<Id,Referral_Contact__c>)oldMap);
         }
      } // if (isBefore
      if (isAfter) {
         if (TriggerMethods.objType == Event.sObjectType
             || TriggerMethods.objType == Task.sObjectType) {
            checkActivityAfter(recs, oldMap);
         }
      }
   } // handleTrigger

   public static void checkActivityAfter(SObject[] recs, Map<Id,SObject> oldMap) {
      Map<Id,String> acctIdSalesOrgMap = new Map<Id,String>();
      Map<Id, SObject> activityByAcctIdMap = new Map<Id, SObject>();
      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         Id acctId = (Id)rec.get('AccountId');
         if (acctId != null) {
            Id recordTypeId = (Id)rec.get('RecordTypeId');
            SalesOrg__c salesOrg = getSalesOrgCustomSetting(recordTypeId, false);
            System.debug('checkActivityAfter salesOrg='+salesOrg);
            if (salesOrg != null && salesOrg.ProfiledExpirationDays__c != null) {
               // should be a new activity or the activity date has to change
               if (oldRec == null || (oldRec != null && rec.get('ActivityDate') != oldRec.get('ActivityDate'))) {
                  acctIdSalesOrgMap.put(acctId, salesOrg.Name);
                  activityByAcctIdMap.put(acctId, rec);
               }
            } // if (salesOrg != null
         } // if (acctId != null
      } // for (SObject rec : recs
      if (!acctIdSalesOrgMap.isEmpty()) {
         processActivityAfter(acctIdSalesOrgMap,activityByAcctIdMap);
      }
   } // checkActivityAfter

   public static void processActivityAfter(Map<Id,String> acctIdSalesOrgMap, Map<Id, SObject> activityByAcctIdMap) {
      Account[] acctsToUpdate = new Account[]{};
      Contact[] ctctsToUpdate = new Contact[]{};
      // retrieve all of the accounts/contacts that are profiled
      Account[] accts = [Select Id, Name, RecordTypeId, Profiled__c, Profiled_Date__c, Profiled_Expiration_Date__c
                              ,(Select Id, Name, Profiled__c, Profiled_Date__c, Profiled_Expiration_Date__c
                                  From Contacts
                                 Where Profiled__c=true)
                           From Account
                          Where Id in :activityByAcctIdMap.keySet()];
      for (Account acct : accts) {
         String activitySalesOrg = acctIdSalesOrgMap.get(acct.Id);
         SObject activity = activityByAcctIdMap.get(acct.Id);
         checkAcctCtct(activity, acct, activitySalesOrg, acctsToUpdate, ctctsToUpdate);
      }
      
      DmlHelper.performDML2(acctsToUpdate, DmlHelper.DML_UPDATE, 'AccountProfiled', 'processActivityAfter', 'Update Accounts', false);
      DmlHelper.performDML2(ctctsToUpdate, DmlHelper.DML_UPDATE, 'AccountProfiled', 'processActivityAfter', 'Update Contacts', false);
      ErrorLog.checkSave();
   } // processActivityAfter
   
   public static void checkAcctCtct(SObject activity, Account acct, String activitySalesOrg, Account[] acctsToUpdate, Contact[] ctctsToUpdate) {
      if (activity == null || String.isBlank(activitySalesOrg)) {
         return;
      }
      // is the account of the same sales org type? If not, we don't update
      SalesOrg__c acctSalesOrgCs = getSalesOrgCustomSetting(acct.RecordTypeId, false);
      String acctSalesOrg = (acctSalesOrgCs != null ? acctSalesOrgCs.Name : null);

      if (String.isBlank(acctSalesOrg) || acctSalesOrg != activitySalesOrg) {
         return;
      }
      SalesOrg__c salesOrg = SalesOrg__c.getInstance(acctSalesOrg);
      // is this associated with a contact?
      Id ctctId = (Id)activity.get('WhoId');
      Date activityDate = (Date)activity.get('ActivityDate');
      System.debug('checkAcctCtct acct='+acct.Name+' activityDate='+activityDate);
      Date expireDate = activityDate.addDays(Integer.valueOf(salesOrg.ProfiledExpirationDays__c));
      // update any profiled contacts
      checkContacts(acct.Contacts, activityDate, expireDate, ctctsToUpdate);
      if (acct.Profiled__c && acct.Profiled_Date__c < activityDate) {
         System.debug('checkAcctCtct updating account');
         acct.Profiled_Date__c = activityDate;
         acct.Profiled_Expiration_Date__c = expireDate;
         acctsToUpdate.add(acct);
      }
   } // checkAcctCtct
   
   public static void checkContacts(Contact[] ctcts, Date activityDate, Date expireDate, Contact[] ctctsToUpdate) {
      // only profiled contacts should have been returned, but check to make sure
      for (Contact ctct : ctcts) {
         if (ctct.Profiled__c && ctct.Profiled_Date__c < activityDate) {
            System.debug('checkContacts updating ctct='+ctct.Name);
            ctct.Profiled_Date__c = activityDate;
            ctct.Profiled_Expiration_Date__c = expireDate;
            ctctsToUpdate.add(ctct);
         }
      } // for (Contact ctct
   } // checkContacts
   
   public static String CACHE_KEY = 'AccountProfiledCacheKey';
   
   public static Map<Id,String> rtNameByIdMap = null;
   public static User runningUser = null;
   
   public static void checkSetup() {
      if (runningUser == null) {
         runningUser = UserHelper.getRunningUser();
      }
      if (rtNameByIdMap == null) {
         rtNameByIdMap = (Map<Id,String>)CacheManager.getOrg(CACHE_KEY);
         if (rtNameByIdMap == null) {
            rtNameByIdMap = new Map<Id,String>();
            addToRtByIdMap(Account.getSobjectType().getDescribe().getRecordTypeInfosById());
            addToRtByIdMap(Task.getSobjectType().getDescribe().getRecordTypeInfosById());
            addToRtByIdMap(Event.getSobjectType().getDescribe().getRecordTypeInfosById());
            CacheManager.putOrg(CACHE_KEY,rtNameByIdMap);
         } // if (rtByIdMap == null
      } // if (rtByIdMap == null
   } // checkSetup
   
   public static void addToRtByIdMap(Map<Id,Schema.RecordTypeInfo> rtMap) {
      for (Id rtId : rtMap.keySet()) {
         rtNameByIdMap.put(rtId, rtMap.get(rtId).getName());
      }
   } // addToRtByIdMap
   
   public static SalesOrg__c getSalesOrgCustomSetting(Id recordTypeId, Boolean checkRunningUser) {
      String recordSalesOrg = getSalesOrgFromRecordType(recordTypeId, checkRunningUser);
      SalesOrg__c salesOrg = (String.isNotBlank(recordSalesOrg) ? SalesOrg__c.getInstance(recordSalesOrg) : null);
      return salesOrg;
   } // getSalesOrgCustomSetting
   
   public static String getSalesOrgFromRecordType(Id recordTypeId, Boolean checkRunningUser) {
      checkSetup();
      String salesOrg = null;
      if (recordTypeId != null) {
         String rtName = rtNameByIdMap.get(recordTypeId);
         if (rtName != null) {
            RecordType__c recordTypeSetting = RecordType__c.getInstance(rtName);
            if (recordTypeSetting != null) {
               salesOrg = recordTypeSetting.Sales_Org__c;
            }
         }
         // the sales org of the running user should match the sales org of the passed in record type id
         if (checkRunningUser && String.isNotBlank(salesOrg) && salesOrg != runningUser.Sales_Org__c) {
            salesOrg = null;
         }
      } // if (recordTypeId != null
      return salesOrg;
   } // getSalesOrgFromRecordType
   
   // In case there's a problem, we want to easily turn this off
   // we don't want the code for processes running as api users to break so putting this caveat in here
   public static Boolean checkForProfiledContact = (Label.AccountProfiled_CheckRelatedCtcts == 'Y') && !UserHelper.isRunningUserAnySystemAdmin();
    
   public static void checkAcctsBefore(Account[] accts, Map<Id,Account> oldMap) {
      User runningUser = UserHelper.getRunningUser();
      Map<Id,Account> profiledAccts = new Map<Id,Account>();
      for (Account acct : accts) {
         Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
         if (oldAcct != null && !acct.Profiled__c && oldAcct.Profiled__c) {
            System.debug('AccountProfiled.checkAcctsBefore acct remove profile date');
            acct.Profiled_Date__c = null;
            acct.Profiled_Expiration_Date__c = null;
         }
         if (acct.Profiled__c) {
            // set the profiled checkbox - don't need to check the user
            Boolean setProfiled = (oldAcct == null || !oldAcct.Profiled__c || acct.RenewProfiled__c);
            Boolean renewProfiled = (oldAcct != null && ((oldAcct.NumberOfEmployees != acct.NumberOfEmployees)  // or did one of the other fields change.
                         || (oldAcct.Frequency__c != acct.Frequency__c) 
                         || (oldAcct.Industry != acct.Industry)
                         || (oldAcct.Current_Prior_Method__c != acct.Current_Prior_Method__c)));
            if (setProfiled || renewProfiled) {
               Boolean doNotCheckRunningUserSalesOrg = setProfiled || UserHelper.isRunningUserSystemAdmin();
               System.debug('AccountProfiled.checkAcctsBefore acct setProfiled='+setProfiled+' renewProfiled='+renewProfiled+' doNotCheckRunningUserSalesOrg='+doNotCheckRunningUserSalesOrg);
               // reset the flag
               acct.RenewProfiled__c = false;
               SalesOrg__c salesOrg = getSalesOrgCustomSetting(acct.RecordTypeId, !doNotCheckRunningUserSalesOrg);
               SalesOrg__c userSalesOrg = (String.isNotBlank(runningUser.Sales_Org__c) ? SalesOrg__c.getInstance(runningUser.Sales_Org__c) : null);
               System.debug('AccountProfiled.checkAcctsBefore acct salesOrg='+salesOrg);
               if (salesOrg != null && salesOrg.ProfiledExpirationDays__c != null) {
                  acct.Profiled_Date__c = Date.today();
                  acct.Profiled_Expiration_Date__c = Date.today().addDays(Integer.valueOf(salesOrg.ProfiledExpirationDays__c));
                  if (acct.Id != null && userSalesOrg != null && userSalesOrg.ProfileAcctChkCtct__c) {
                     profiledAccts.put(acct.Id,acct);
                  }
               } else {
                  acct.Profiled__c = false;
                  acct.Profiled_Date__c = null;
                  acct.Profiled_Expiration_Date__c = null;
               }
            } // if (setProfiled || renewProfiled
  
         } // if (acct.Profiled__c
      } // for (Account acct : accts

      System.debug('AccountProfiled.checkAcctsBefore checkForProfiledContact='+checkForProfiledContact+' profiledAccts='+profiledAccts.size());
      if (checkForProfiledContact && !profiledAccts.isEmpty()) {
         Map<Id,Account> acctMap = new Map<Id,Account>([Select Id,Profiled__c ,(Select Id,Profiled__c from Contacts where Profiled__c = true limit 1)from Account where Id in :profiledAccts.keySet()]);
         // make sure there's a profiled contact in order to set an account as profiled.
         // THIS CHECK CANNOT HAPPEN ON A NEW ACCOUNT - NO CONTACTS
         for (Account acct : profiledAccts.values()) {
            Account checkAcct = acctMap.get(acct.Id);
            if (checkAcct != null && checkAcct.Contacts.isEmpty()) {
               acct.Profiled__c.addError('Account cannot be Profiled, at least one Contact must be Profiled'); 
            }
         }
           
      } // if (checkForProfiledContact &&
   } // checkAcctsBefore

   public static void checkCtctsBefore(Contact[] ctcts, Map<Id,Contact> oldMap) {
      Map<Id, Contact[]> ctctByAcctIdCheckUserMap = new Map<Id, Contact[]>();
      Map<Id, Contact[]> ctctByAcctIdNoUserCheckMap = new Map<Id, Contact[]>();
       
      for (Contact ctct : ctcts) {
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         if (oldCtct != null && !ctct.Profiled__c && oldCtct.Profiled__c) {
            ctct.Profiled_Date__c = null;
            ctct.Profiled_Expiration_Date__c = null;
         }
         if (ctct.Profiled__c && ctct.AccountId != null) {
            // set the profiled checkbox - don't need to check the user
            Boolean setProfiled = (oldCtct == null || oldCtct.Profiled__c != ctct.Profiled__c || ctct.RenewProfiled__c);
            Boolean renewProfiled = (oldCtct != null && ((oldCtct.FirstName != ctct.FirstName)  // or did one of the other fields change.
                      || (oldCtct.LastName != ctct.LastName) 
                      || (oldCtct.Title != ctct.Title)
                      || (oldCtct.Phone != ctct.Phone)
                      || (oldCtct.Email != ctct.Email)));
            if (setProfiled || renewProfiled) {
               Boolean doNotCheckRunningUserSalesOrg = setProfiled || UserHelper.isRunningUserSystemAdmin();
               System.debug('AccountProfiled.checkBefore ctct setProfiled='+setProfiled+' renewProfiled='+renewProfiled+' doNotCheckRunningUserSalesOrg='+doNotCheckRunningUserSalesOrg);
               ctct.RenewProfiled__c = false;
               if (doNotCheckRunningUserSalesOrg) {
                  addToMap(ctct, ctctByAcctIdNoUserCheckMap);
               } else {
                  addToMap(ctct, ctctByAcctIdCheckUserMap);
               }
            } // if (setProfiled || renewProfiled
         } // if (ctct.Profiled__c
 
      } // for (Contact ctct
      if (!ctctByAcctIdCheckUserMap.isEmpty() || !ctctByAcctIdNoUserCheckMap.isEmpty()) {
         checkContactsByAccount(ctctByAcctIdCheckUserMap, ctctByAcctIdNoUserCheckMap);
      }

   } // checkCtctsBefore
    
   public static void addToMap(Contact ctct, Map<Id, Contact[]> ctctListMap) {
      Contact[] ctctList = (ctctListMap.containsKey(ctct.AccountId) ? ctctListMap.get(ctct.AccountId) : new Contact[]{});
      ctctList.add(ctct);
      ctctListMap.put(ctct.AccountId, ctctList);
   } // addToMap
   
   public static void checkContactsByAccount(Map<Id, Contact[]> ctctByAcctIdCheckUserMap, Map<Id, Contact[]> ctctByAcctIdNoUserCheckMap) {
      Set<Id> acctIdSet = new Set<Id>();
      acctIdSet.addAll(ctctByAcctIdCheckUserMap.keySet());
      acctIdSet.addAll(ctctByAcctIdNoUserCheckMap.keySet());

      // select the accounts
      Account[] accts = [Select Id, RecordTypeId from Account where Id in :acctIdSet];
      for (Account acct : accts) {
         Boolean checkRunningUserSalesOrg = ctctByAcctIdCheckUserMap.containsKey(acct.Id);
         SalesOrg__c salesOrg = getSalesOrgCustomSetting(acct.RecordTypeId, checkRunningUserSalesOrg);
         System.debug('AccountProfiled.checkBefore salesOrg='+salesOrg);
         if (salesOrg != null && salesOrg.ProfiledExpirationDays__c != null) {
            Contact[] ctcts = (checkRunningUserSalesOrg ? ctctByAcctIdCheckUserMap.remove(acct.Id) : ctctByAcctIdNoUserCheckMap.remove(acct.Id));
            System.debug('AccountProfiled.checkBefore ctcts='+(ctcts != null ? ctcts.size() : -1));
            if (ctcts != null) {
               for (Contact ctct : ctcts) {
                  ctct.Profiled_Date__c = Date.today();
                  ctct.Profiled_Expiration_Date__c = Date.today().addDays(Integer.valueOf(salesOrg.ProfiledExpirationDays__c));
               } // for (Contact ctct : ctcts
            } // if (ctcts != null
         } // if (salesOrg != null
      } // for (Account acct : accts
   } // checkContactsByAccount
    
   public static void checkRefCtctsBefore(Referral_Contact__c[] refCtcts, Map<Id,Referral_Contact__c> oldMap) {
      for (Referral_Contact__c refCtct : refCtcts) {
         Referral_Contact__c oldRefCtct = (oldMap != null ? oldMap.get(refCtct.Id) : null);
   	     if (oldRefCtct != null && !refCtct.Profiled__c && oldRefCtct.Profiled__c) {
            oldRefCtct.Profiled_Date__c = null;
         }
         // Boolean isProfiled = (
         //    //refCtct.Opportunities_to_Refer_Last_12_Months__c !=null // or did one of the other fields change.
         //           // && 
         //         //  refCtct.Pay_Providers_Referred_Last_12_Months__c!=null 
         //            // && 
         //           // refCtct.Preferred_Method__c != null
         //          //  &&
         //           refCtct.Number_of_Payroll_Clients__c != null);
      
         // if (isProfiled && refCtct.Profiled_Date__c == null) {
         //    refCtct.Profiled__c = true;
         //    refCtct.Profiled_Date__c = Date.today();
         // } else if (!isProfiled) {
         //    refCtct.Profiled__c = false;
         //    refCtct.Profiled_Date__c = null;
         // }

      } // for (Referral_Contact__c refCtct : refCtcts
   } // checkRefCtctsBefore
  
	
} // class AccountProfiled