/** Check the Do Not Sync flag on the contact and lead.
 *
 * History
 * -------
   01/16/2018 Dan Carmen          Created.
   01/23/2018 Dan Carmen          Additional checks for accounts.
   02/12/2018 Dan Carmen          Set the Contact_Email_Available__c field on the account
   04/06/2018 Dan Carmen          Added CreatedByProcess__c field
   04/27/2018 Dan Carmen          Adjustments for Marketo
   08/08/2018 Dan Carmen          Change method of caching
   09/20/2018 Dan Carmen          Marketo user wasn't being stored in the cache
   03/26/2019 Dan Carmen          Added check for EmailOptOut
   08/21/2019 Carrie Marciano     Added custom label CreatedByProcess and changed the Do Not Sync evaluation to check if record Created_By_Process__c value in is set
   07/13/2020 Pujitha Madamanchi  Mirrored Referral Contacts will also sync to Marketo for nuturing
   07/29/2020 Pujitha Madamanchi  Update Mirrored Referral Contacts logic
   08/24/2020 Pujitha Madamanchi  Add Marketing Dupe Check logic
   09/14/2020 Pujitha Madamanchi  Add logic for NSS Team 'Inbound'  or 'Inbound Oasis'
   10/27/2021 Pujitha Madamanchi  Add Purchased List logic
   01/04/2023 Dan Carmen          Add ability to skip checks for users
   02/06/2023 Pujitha Madamanchi  Add Ecomm check
   06/26/2023 Pujitha Madamanchi  Add more logic to Marketing block reason
   
*/
public with sharing class DoNotSyncCheck implements TriggerInterfaceC {
   
  // for the initial rollout, once a record is part of the sync, we're not going to remove it 
   // from the sync. So we'll only be checking records on insert if the Do Not Sync checkbox is false
   // if this variable is true. 
   public static Boolean ALLOW_REMOVE_FROM_SYNC_ON_UPDATE = Label.DoNotSyncCheck_AllowRemove == 'Y';
   // the created date has to be within a certain number of months to be allowed in the sync.
   public static Integer CREATED_DATE_NBR_MONTHS = Integer.valueOf(Label.DoNotSyncCheck_NbrMonths);
   // the name for the Marketo Sync User
   public static String MARKETO_SYNC_USER=Label.User_MarketoSync;
   
   public static String CREATED_BY_MARKETO='Marketo';
   public static String ALWAYS_SYNC='Always Sync';
   
   // did this code already execute? To make sure we only run it one time.
   public static Boolean ALREADY_RAN=false;
   
   public static Boolean nssUser=false;
    
   // do we skip the Do Not Sync check?
   public static Boolean skipDNS = null;
   public static final String PREFIX_DNS='DNS-';
   // do we skip this process based on the user?
   public static Boolean skipDNSUser() {
      if (skipDNS == null) {
         User runningUser = UserHelper.getRunningUser();
         skipDNS = (runningUser != null ? UserHelper.hasActiveProcessName(PREFIX_DNS+runningUser.Name) : false);
      }
      return skipDNS;
   } // isClientSpaceUser
    
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      Boolean skipDNS = skipDNSUser();
      SObject[] recs = (!skipDNS ? TriggerMethods.checkRecs('DoNotSyncCheck', p_recs, oldMap, isBefore, isAfter, null, null) : p_recs);
      System.debug('DoNotSyncCheck.handleTrigger skipDNS='+skipDNS+' ALREADY_RAN='+ALREADY_RAN+' recs='+recs.size());

      if (skipDNS || recs.isEmpty() || ALREADY_RAN) {
         return;
      }
      
      if (isBefore) {
          if (TriggerMethods.objType == Lead.sObjectType) {
             checkLeadsBefore((Lead[])recs, (Map<Id,Lead>) oldMap);
          } else if (TriggerMethods.objType == Contact.sObjectType) {
             checkCtctsBefore((Contact[])recs, (Map<Id,Contact>) oldMap);
          }
      } else if (isAfter) {
          if (TriggerMethods.objType == Contact.sObjectType) {
             checkCtctsAfter((Contact[])recs, (Map<Id,Contact>)oldMap);
          }
      }

   } // handleTrigger

   /* Criteria to keep in the marketo sync:
      If created by the Marketo API user then always keep in the sync.
      Otherwise:
         - Created within the past X months (CREATED_DATE_NBR_MONTHS variable) (lead, contact)
         - Has a Company Name - if this is a contact, do we need to check the account? (lead, account)
         - Has a Company Address (lead, account)
         - Has a First Name and Last Name (lead, contact)
             - Not Blank
             - Not a Number
             - Does not contain: /,?, unknown, TBD, infogroup, seasonal, #
         - Has an email address (lead, contact)
         - Is a Sales Contact (contact)
         - Is not a referral source (contact) - this should be handled by the sales contact checkbox.
         - Is not a Paychex Employee (Paychex Inc SA) (contact - check the hr person id field)
   
for Contacts -- "Current client, open opportunity or lost within 12 months" 

   */
   //Check if the current user part of NSS Team 'Inbound' or 'Inbound Oasis'
   public static Boolean checkNssTeam(){
       User runningUser = UserHelper.getRunningUser();
       if(runningUser.NSS_Team__c!= null && (runningUser.NSS_Team__c == 'Inbound' || runningUser.NSS_Team__c == 'Inbound Oasis' )){
           nssUser = true;
       }   
       return nssUser;
   } 
    
   public static void checkCtctsBefore(Contact[] ctcts, Map<Id,Contact> oldMap) {
      System.debug('checkCtctsBefore ctcts='+ctcts.size());
      Map<Id,Contact[]> ctctsByAcctIdMap = new Map<Id,Contact[]>();
      for (Contact ctct : ctcts) {
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         checkCtctBefore(ctct,oldCtct,ctctsByAcctIdMap);
      }
       
      if (!ctctsByAcctIdMap.isEmpty()) {
         checkAccountsForCtcts(ctctsByAcctIdMap);
      }

   } // checkCtctsBefore
    
   public static void checkCtctBefore(Contact ctct, Contact oldCtct, Map<Id,Contact[]> ctctsByAcctIdMap) {
      System.debug('checkCtctBefore checking ctct='+ctct.LastName);
      // Contact has to be associated with an Account.
      // always evaluate on an insert or if the Do Not Sync flag is true (to see if it now meets the sync criteria)
      // only evaluate if it's false on an update if the ALLOW_REMOVE_FROM_SYNC_ON_UPDATE flag is true.
      // when Marketing block reason is populated, it should not sync with Marketo
      if(ctct.Marketing_Block_Reason__c!= null){
           if(ctct.Marketing_Block_Reason__c==ALWAYS_SYNC){
               ctct.Do_Not_Sync__c = false;
               StringHelper.addToProcessNotes(ctct,'setting DoNotSync to false based on Marketing Block reason');
           }
           else{
               ctct.Do_Not_Sync__c = true;
               StringHelper.addToProcessNotes(ctct,'setting DoNotSync to true as its duplicate Contact');
           } 
         return;   
      } 
      if (checkCreatedByProcess(ctct)) {
         return;
      }
      /*
      if (oldCtct != null && String.isNotBlank(ctct.CreatedByProcess__c) && ctct.CreatedByProcess__c == CREATED_BY_MARKETO) {
         // make sure the flag is set. If it already is, leave it.
         if (ctct.Do_Not_Sync__c) {
            ctct.Do_Not_Sync__c = false;
            System.debug('checkCtctBefore Do_Not_Sync__c set to false because of CreatedByProcess__c');
            StringHelper.addToProcessNotes(ctct,'Do_Not_Sync__c set to false because of CreatedByProcess__c='+CREATED_BY_MARKETO);
         }
         return;
      }
      */
      if (ctct.AccountId == null || String.isNotBlank(ctct.HR_Person_Id__c)) {
         System.debug('checkCtctBefore AccountId='+ctct.AccountId+' HR_Person_Id__c='+ctct.HR_Person_Id__c);
         if (!ctct.Do_Not_Sync__c) {
            System.debug('checkCtctBefore setting Do Not Sync due to no Account Id for ctct='+ctct.LastName);
            StringHelper.addToProcessNotes(ctct,'setting DoNotSync due to no AccountId');
            ctct.Do_Not_Sync__c = true;
         } 
       } else if (ctct.Email != null && ctct.HasOptedOutOfEmail) {
            // if there's an email address and has opted out, Marketo wants to see those records 
            if (ctct.Do_Not_Sync__c) {
              StringHelper.addToProcessNotes(ctct,'setting DoNotSync to false due to Email Opt Out');
              ctct.Do_Not_Sync__c = false;
              return;
            }
        } else if (oldCtct == null || ctct.Do_Not_Sync__c || ALLOW_REMOVE_FROM_SYNC_ON_UPDATE ) {
         if (checkCreatedByUser(ctct.CreatedById != null ? ctct.CreatedById : UserInfo.getUserId())) {
            // if this is true we don't need to proceed because we are keeping these records in the sync.
            System.debug('checkCtctBefore setting Do_Not_Sync__c to false for '+ctct.LastName);
            ctct.CreatedByProcess__c=CREATED_BY_MARKETO;
            ctct.Do_Not_Sync__c = false;
            return;
         }
         //if (oldCtct != null && !ctct.Do_Not_Sync__c && !doesThisPassDateCheck(ctct.CreatedDate)) {
         //   System.debug('checkCtctBefore setting Do_Not_Sync__c to true for '+ctct.LastName);
         //   ctct.Do_Not_Sync__c = true;
         //   return;
         //}
         
         checkNssTeam(); 
         performCtctChecks(ctct, oldCtct, ctctsByAcctIdMap);
      }
      System.debug('checkCtctBefore Do_Not_Sync='+ctct.Do_Not_Sync__c);
   } // checkCtctBefore
   
   public static Boolean checkCreatedByProcess(SObject recToCheck) {
      Boolean stopProcess = false;
      String createdByProcess = (String)recToCheck.get('CreatedByProcess__c');
      Set<String> createdByProcessSet = new Set<String>();
      createdByProcessSet.addAll(Label.CreatedByProcess.split(';'));
      if (String.isNotBlank(createdByProcess) && createdByProcessSet.contains(createdByProcess)) {
         stopProcess = true;
         // make sure the flag is set. If it already is, leave it.
         Boolean doNotSync = (Boolean)recToCheck.get('Do_Not_Sync__c');
         if (doNotSync == null || doNotSync) {
            recToCheck.put('Do_Not_Sync__c',false);
            System.debug('checkCreatedByProcess Do_Not_Sync__c set to false because of CreatedByProcess__c');
            StringHelper.addToProcessNotes(recToCheck,'Do_Not_Sync__c set to false because of CreatedByProcess__c='+createdByProcess);
         }
      }
      return stopProcess;
   } // checkCreatedByProcess

   public static void checkLeadsBefore(Lead[] lds, Map<Id,Lead> oldMap) {
      for (Lead ld : lds) {
         Lead oldLd = (oldMap != null ? oldMap.get(ld.Id) : null);
         checkLeadBefore(ld,oldLd);
      }
   } // checkLeadsBefore
    
   public static void checkLeadBefore(Lead ld, Lead oldLd) {
      System.debug('checkLeadBefore ld='+ld.LastName+' CreatedByProcess__c='+ld.CreatedByProcess__c+' HasOptedOutOfEmail='+ld.HasOptedOutOfEmail);
       //If Lead Source is Purchased Lists, it should not sync with Marketo (Doesn't apply to Contacts)
       if(ld.LeadSource!= null && ld.LeadSource == 'Purchased List'){
         ld.Do_Not_Sync__c = true;
         StringHelper.addToProcessNotes(ld,'setting DoNotSync to true as its a Purchased List');
         return;   
      } 
       
       // when Marketing block reason is populated, it should not sync with Marketo
       if(ld.Marketing_Block_Reason__c!= null){
           if(ld.Marketing_Block_Reason__c==ALWAYS_SYNC){
               ld.Do_Not_Sync__c = false;
               StringHelper.addToProcessNotes(ld,'setting DoNotSync to false based on Marketing Block reason');
           }
           else{
               ld.Do_Not_Sync__c = true;
               StringHelper.addToProcessNotes(ld,'setting DoNotSync to true as its duplicate Lead');
           } 
         return;   
      } 
      if (checkCreatedByProcess(ld)) {
         return;
      }
      
       if (ld.Email != null && ld.HasOptedOutOfEmail) {
         System.debug('checkLeadBefore HasOptedOutOfEmail=true');
         // if there's an email address and has opted out, Marketo wants to see those records 
         if (ld.Do_Not_Sync__c) {
            StringHelper.addToProcessNotes(ld,'setting DoNotSync to false due to Email Opt Out');
            ld.Do_Not_Sync__c = false;
         }
         // no further checks required
         return;
      } // if (ld.Email != null
      /*
      if (oldLd != null && String.isNotBlank(ld.CreatedByProcess__c) && ld.CreatedByProcess__c == CREATED_BY_MARKETO) {
         // make sure the flag is set. If it already is, leave it.
         if (ld.Do_Not_Sync__c) {
            ld.Do_Not_Sync__c = false;
            System.debug('checkLeadBefore Do_Not_Sync__c set to false because of CreatedByProcess__c');
            StringHelper.addToProcessNotes(ld,'Do_Not_Sync__c set to false because of CreatedByProcess__c='+CREATED_BY_MARKETO);
         }
         return;
      } // if (oldLd != null && String.isNotBlank(ld.CreatedByProcess__c)
      */
      Boolean enterLoop = (oldLd == null || ld.Do_Not_Sync__c || ALLOW_REMOVE_FROM_SYNC_ON_UPDATE);
      System.debug('checkLeadBefore checking ld='+ld.LastName+' Do_Not_Sync__c='+ld.Do_Not_Sync__c+' enterLoop='+enterLoop+' override='+ALLOW_REMOVE_FROM_SYNC_ON_UPDATE);
      // always evaluate on an insert or if the Do Not Sync flag is true (to see if it now meets the sync criteria)
      // only evaluate if it's false on an update if the ALLOW_REMOVE_FROM_SYNC_ON_UPDATE flag is true.
      if (enterLoop) {
         
         if (checkCreatedByUser(ld.CreatedById != null ? ld.CreatedById : UserInfo.getUserId())) {
            // if this is true we don't need to proceed because we are keeping these records in the sync.
            System.debug('checkLeadBefore setting Do_Not_Sync__c to false for '+ld.LastName);
            ld.CreatedByProcess__c=CREATED_BY_MARKETO;
            ld.Do_Not_Sync__c = false;
            return;
         }
         if (oldLd != null && !ld.Do_Not_Sync__c && !doesThisPassDateCheck(ld.CreatedDate)) {
            System.debug('checkLeadBefore setting Do_Not_Sync__c to true for '+ld.LastName);
            ld.Do_Not_Sync__c = true;
            return;
         }
         //Pujitha APR0142646: Check for ecom user
         if (ld.Do_Not_Sync__c = true && ld.OwnedByPrev__c=='eCommerce'){
           User ecomUser = EcomMethods.getEcomUser();
           if (ecomUser != null && ld.OwnerId == ecomUser.Id ) {
              System.debug('checkLeadBefore setting Do_Not_Sync__c to true for '+ld.LastName);
              ld.Do_Not_Sync__c = false;
              return;
           }
        }
        performLeadChecks(ld, oldLd);
      } // if (oldLd == null
   } // checkLeadBefore
   
   //public static Map<Id,Contact[]> ctctsByAcctIdMap = new Map<Id,Contact[]>();
   
   public static void performCtctChecks(Contact ctct, Contact oldCtct, Map<Id,Contact[]> ctctsByAcctIdMap) {
      Boolean okayToSync = checkFirstLastName(ctct.FirstName, ctct.LastName);
      okayToSync = okayToSync && String.isNotBlank(ctct.Email) && String.isNotBlank(ctct.Phone);
      // should be a sales contact and the hr person id field should be blank (to filter out paychex employees)
        System.debug('1:::'+okayToSync);
       if(okayToSync && (ctct.Mirror_Ref_Ctct__c!= null && ctct.OwnerId == Label.ReferralOwnerName)){
           StringHelper.addToProcessNotes(ctct,'setting DoNotSync to false due to Mirrored Ctct');
           ctct.Do_Not_Sync__c = false;
       } 
       else if (okayToSync && ((ctct.Sales_Contact__c && String.isBlank(ctct.HR_Person_Id__c)) || nssUser)) {
           System.debug('3:::'+okayToSync);
           // if we get to this point we need to collect the account ids to check against the accounts.
           Contact[] ctcts = ctctsByAcctIdMap.containsKey(ctct.AccountId) ? ctctsByAcctIdMap.get(ctct.AccountId) : new Contact[]{};
           ctcts.add(ctct);
           ctctsByAcctIdMap.put(ctct.AccountId, ctcts);
       } else {
           System.debug('performCtctChecks set Do Not Sync to true for '+ctct.LastName);
           ctct.Do_Not_Sync__c = true;
       }
   } // performCtctChecks
      
   public static void performLeadChecks(Lead ld, Lead oldLd) {
      Boolean okayToSync = checkFirstLastName(ld.FirstName, ld.LastName);
      okayToSync = okayToSync && String.isNotBlank(ld.Email) && String.isNotBlank(ld.Phone);
      okayToSync = okayToSync && checkCompanyInfo(ld.Company, ld.Street, ld.PostalCode, ld.NumberOfEmployees);
      System.debug('performLeadChecks ld='+ld.LastName+' okayToSync='+okayToSync);
      ld.Do_Not_Sync__c = !okayToSync;
   } // performLeadChecks
   
   public static String[] NAME_EXCLUDE_CRITERIA = Label.DoNotSyncCheck_NamesExclude.split(',');
   
   public static Boolean checkFirstLastName(String firstName, String lastName) {
      Boolean namesOkay = (String.IsNotBlank(firstName) && String.isNotBlank(lastName));
      // make sure they're not a number
      namesOkay = namesOkay && checkIfNameIsNotNumber(firstName, lastName);
      // make sure no invalid values in the names
      namesOkay = namesOkay && doesNameContainOnlyValidValues(firstName, lastName);
      System.debug('checkFirstLastName namesOkay='+namesOkay+' firstName='+firstname+' lastName='+lastName);
      return namesOkay;
   } // checkFirstLastName
   
   public static Boolean doesNameContainOnlyValidValues(String firstName, String lastName) {
      Boolean isValid = true;
      for (String tokenToCheck : NAME_EXCLUDE_CRITERIA) {
         tokenToCheck = tokenToCheck.trim();
         if (firstName.containsIgnoreCase(tokenToCheck) || lastName.containsIgnoreCase(tokenToCheck)) {
            isValid = false;
            break;
         }
      } // for (String tokenToCheck
      return isValid;
   } // doesNameContainOnlyValidValues
   
   public static User marketoSyncUser = null;
   public static String CACHE_KEY='marketoSyncUserId';
   
   public static Id getMarketoSyncId() {
      if (marketoSyncUser == null) {
         marketoSyncUser = (User)CacheManager.getOrg(CACHE_KEY);
         if (marketoSyncUser == null) {
            try {
               marketoSyncUser = [Select Id, Name from User where Name=:MARKETO_SYNC_USER and IsActive=true limit 1];
               CacheManager.putOrg(CACHE_KEY, marketoSyncUser);
            } catch (Exception e) {
               System.debug('getMarketoSyncId could not find a user with name='+MARKETO_SYNC_USER+'! '+e.getMessage());
            }
         }
      }
      System.debug('getMarketoSyncId marketoSyncUser='+marketoSyncUser);
      return (marketoSyncUser != null ? marketoSyncUser.Id : null);
   } // getMarketoSyncId
   /*
   // store the user record in the cache so we don't have to keep on retrieving it.
   public class MarketoIdCache implements Cache.CacheBuilder {
      public Object doLoad(String cacheKey) {
         Id userId = null;
         try {
            User usr = [Select Id, Name from User where Name=:MARKETO_SYNC_USER and IsActive=true limit 1];
            userId = usr.Id;
            System.debug('MarketoIdCache found user with name='+MARKETO_SYNC_USER+' userId='+userId);
         } catch (Exception e) {
            System.debug('MarketoIdCache could not find a user with name='+MARKETO_SYNC_USER+'! '+e.getMessage());
         }
         return userId;
      }
   } // class MarketoIdCache
   */
   
   // if the record was created by the marketo sync, we're going to leave it in the sync.
   public static Boolean checkCreatedByUser(Id createdById) {
      Id marketoSyncUserId = getMarketoSyncId();
      System.debug('checkCreatedByUser marketoSyncUserId='+marketoSyncUserId+' createdById='+createdById);
      Boolean wasCreatedByUser = (createdById != null && marketoSyncUserId != null && createdById == marketoSyncUserId);
      System.debug('checkCreatedByUser wasCreatedByUser='+wasCreatedByUser+' marketoSyncUserId='+marketoSyncUserId+' createdById='+createdById);
      return wasCreatedByUser;
   } // checkCreatedByUser
   
   public static Boolean doesThisPassDateCheck(DateTime dateToCheck) {
      //created date has to be within the past x number of months
      Boolean passedDateCheck = (dateToCheck != null && dateToCheck.addMonths(CREATED_DATE_NBR_MONTHS) >= Date.today());
      System.debug('doesThisPassDateCheck passedDateCheck='+passedDateCheck);
      return passedDateCheck;
   } // doesThisPassDateCheck
   
   public static Boolean checkCompanyInfo(String companyName, String address, String postalCode, Integer numberOfEmployees) {
      Boolean companyOkay = String.isNotBlank(companyName) && String.IsNotBlank(address) && String.IsNotBlank(postalCode);
      companyOkay = companyOkay && (numberOfEmployees != null);
      System.debug('checkCompanyInfo companyName='+companyName+' companyOkay='+companyOkay+' address='+address+' postalCode='+postalCode+' numberOfEmployees='+numberOfEmployees);
      return companyOkay;
   } // checkCompanyInfo
   
   public static Boolean checkIfNameIsNotNumber(String firstName, String lastName) {
      Boolean isNotNumber = true;
      if (firstName.isNumeric() || lastName.isNumeric()) {
         isNotNumber = false;
      }

      return isNotNumber;
   } // checkIfNameIsNotNumber

   public static void checkAccountsForCtcts(Map<Id,Contact[]> ctctsByAcctIdMap) {
      Account[] accts = [Select Id, Name
                               ,NumberOfEmployees
                               ,BillingStreet
                               ,BillingCity
                               ,BillingState
                               ,BillingPostalCode
                               ,ShippingStreet
                               ,ShippingCity
                               ,ShippingState
                               ,ShippingPostalCode
                               ,Owner_Zip_Code__c
                               ,Bis_ID__c
                               ,CurrentClient__c
                               ,Lost_Date__c
                               ,Type
                               ,CreatedDate
                               ,(Select Id, Name from Opportunities where IsClosed=false limit 1)
                           From Account
                          Where Id in :ctctsByAcctIdMap.keySet()];
      for (Account acct : accts) {
         Contact[] ctcts = ctctsByAcctIdMap.get(acct.Id);
         System.debug('checkAccountsForCtcts acct='+acct.Name+' ctcts='+(ctcts != null ? ctcts.size() : -1));
         if (ctcts != null) {
           // String zipNss = (String.isNotBlank(acct.ShippingPostalCode) ? acct.ShippingPostalCode : acct.BillingPostalCode);
            String address = (String.isNotBlank(acct.ShippingStreet) ? acct.ShippingStreet : acct.BillingStreet);
            Boolean acctCheck = (nssUser && String.isNotBlank(acct.Owner_Zip_Code__c)) || checkCompanyInfo(acct.Name, address, acct.Owner_Zip_Code__c, acct.NumberOfEmployees);
            System.debug('5:::'+acctCheck);
             acctCheck = acctCheck && checkAccountInfo(acct);
             System.debug('6:::'+acctCheck);
            System.debug('checkAccountsForCtcts acct='+acct.Name+' acctCheck='+acctCheck);
            // if we've gotten to this point then the contact meets all of the rest of the criteria for sync.
            for (Contact ctct : ctcts) {
               ctct.Do_Not_Sync__c = !acctCheck;
            }
         }
      } // for (Account acct
   } // checkAccountsForCtcts
       
   public static Date LOST_DATE_CHECK=null;
   
   public static Boolean checkAccountInfo(Account acct) {
      Boolean acctOkay = (acct != null);
      if (acctOkay) {
         if (LOST_DATE_CHECK == null) {
            LOST_DATE_CHECK = Date.today().addMonths(-12);
         }
         acctOkay = (acct.CurrentClient__c || !acct.Opportunities.isEmpty() 
                     || (acct.Lost_Date__c != null && acct.Lost_Date__c > LOST_DATE_CHECK));
      }
      System.debug('checkAccountInfo acct='+acct.Name+' acctOkay='+acctOkay);
      return acctOkay;
   } // checkAccountInfo
   
   public void checkCtctsAfter(Contact[] ctcts, Map<Id,Contact>oldMap) {
      Set<Id> acctIdsToCheck = new Set<Id>();
      for (Contact ctct : ctcts) {
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         // if the sync flag changes on the contacts, evaluate the account
         if (ctct.AccountId != null && (oldCtct == null || ctct.Do_Not_Sync__c != oldCtct.Do_Not_Sync__c)) {
            acctIdsToCheck.add(ctct.AccountId);
         }
      } // for (Contact ctct
      System.debug('checkCtctsAfter ctcts='+ctcts.size()+' acctIdsToCheck='+acctIdsToCheck.size());
      
      if (!acctIdsToCheck.isEmpty()) {
         if (Utilities.allowFuture()) {
            checkAcctSyncFuture(acctIdsToCheck);
         } else {
            checkAcctSyncNow(acctIdsToCheck);
         }
      }
   } // checkCtctsAfter
   
   @future
   public static void checkAcctSyncFuture(Set<Id> acctIdSet) {
      checkAcctSyncNow(acctIdSet);
   } // checkAcctSyncFuture

   public static void checkAcctSyncNow(Set<Id> acctIdSet) {
      Account[] accts = [Select Id, Name, Contact_Email_Available__c
                               ,(select Id, Email
                                   From Contacts
                                  where Email != null
                                    and Do_Not_Sync__c=false
                                  limit 1)
                           from Account
                          Where Id in :acctIdSet];
      Account[] updateAccts = new Account[]{};
      
      AccountCheckContactEmail acce = new AccountCheckContactEmail();
      acce.checkAcctFlag(accts, updateAccts);

      if (!updateAccts.isEmpty()) {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         DmlHelper.performDML2(updateAccts, DmlHelper.DML_UPDATE, 'DoNotSyncCheck', 'checkAcctSyncNow', 'updating accounts', true);
      }

   } // checkAcctSyncNow 

} // DoNotSyncCheck