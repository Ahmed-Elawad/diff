/* 
 *After a lead is converted, check the record type of the contact to make sure
  it's correct (the default record type of the profile is used for the contact).
  Use the sales org on the owner to determine the record type. If there is no Sales Org,
  use the number of employees. If all else fails, default to Core.
  Also check the record type on the Account.
*
* History
* -------
*  09/10/2009 Dan Carmen   Created
   10/28/2011 Dan Carmen   Change to use Schema.RecordTypeInfo
   07/02/2013 J Stouffer   Added Remote Locations code
   09/05/2013 J Stouffer   Added code to add Lead owners that are MSP reps to the Account Team when Lead is convereted
   10/09/2013 Dan Carmen   Link the account to the Prospect Ownership record on conversion.
   11/20/2015 Dan Carmen   Add referrals
   03/15/2016 Dan Carmen   Force the ownership to process again if the record type changes.
   10/05/2016 Dan Carmen   Don't change record type on accounts if pre-existing.
   05/24/2017 Dan Carmen   Update the Partner Referrals and Marketing Call Tracking on lead convert.
   06/28/2017 Dan Carmen   Added ability to skip segmentation check on account creation.
   06/28/2018 Dan Carmen   Added check for Prospect record type when changing the account record type
   07/10/2018 Dan Carmen   Add the Prospect record type to the RECORD_TYPE_NAMES array.
   08/15/2018 Dan Carmen   Make changes in a future method
   12/14/2018 Dan Carmen   Pull out some of the updates into a non-future method (seem to be causing an issue further down the line)
                           Have to leave most of them future because of DML limits being hit.
   02/11/2019 Dan Carmen   Move more code back to inline instead of future.
   02/25/2019 Dan Carmen   Move update of Referrals to inline.
   05/31/2019 Dan Carmen   Added ability to bypass some of the code
   02/05/2020 Dan Carmen   Added ability to skip saving the referral
   02/06/2020 Dan Carmen   Added reparent of CARs/Touchpoints on lead convert
   01/13/2021 Dan Carmen   Added Ecommerce records.
   03/28/2022 Dan Carmen   Change to allow account ownership to fire
   06/01/2022 Pujitha Madamanchi   APR0130779 Remove SignificantLead/SignificantContact

*/
public without sharing class LeadCheckContactRecordType {

   
   public static Boolean FORCE_EVALUATE_ZIP_INLINE=(Label.LeadCheckContact_ForceZipInline == 'Y');

   public static final String[] RECORD_TYPE_NAMES = new String[]{RecordTypeHelper.CORE_ACCOUNT
                                                              ,RecordTypeHelper.MMS_ACCOUNT
                                                              ,PeoHelper.RT_PROSPECT
                                                              ,RecordTypeHelper.CORE_CONTACT
                                                              ,RecordTypeHelper.MMS_CONTACT};
   
   public static void checkLeads(List<Id> leadIds, Boolean overrideRecordType) {
      updateInline(leadIds,overrideRecordType);
      if (Utilities.allowFuture()) {
         checkLeadsFuture(leadIds, overrideRecordType);
      } else {
         checkLeadsNow(leadIds, overrideRecordType);
      }
   } // checkLeads

   // so we can only do the minimum amount of updating to the lead.
   public static Boolean ONLY_REPARENT=false;
    
   public static Boolean SAVE_REFERRALS=true;
   
   // some of the relationships we're going to update inline because they seem to be causing issues.
   public static void updateInline(List<Id> leadIds, Boolean overrideRecordType) {
      //APR0130779 : Remove Significant Lead/Contact
      List<Lead> leads = new List<Lead>([select Id, Name
                       ,NumberOfEmployees
                       ,ConvertedAccountId
                       ,ConvertedAccount.Id, ConvertedAccount.Name, ConvertedAccount.RecordTypeId
                       ,ConvertedAccount.AssignedToInboundNSR__c
                       ,ConvertedAccount.AssignedToOutboundNSR__c
                       ,ConvertedAccount.Owner.Sales_Org__c
                       ,ConvertedAccount.CreatedDate
                       ,ConvertedAccount.ProcessNotes__c
                       ,ConvertedAccount.Use_Zip_Assignment_Rules__c
                       ,ConvertedContactId
                       ,ConvertedContact.Id, ConvertedContact.RecordTypeId
                       ,ConvertedDate
                       ,Owner.isActive
                       ,Owner.Profile.Name
                       ,(Select Id, Decision_Maker__c, Prospect_Client__c, NSS_Source__c
                               ,StartDate__c, EndDate__c, LastVerified__c
                           from Prospect_Ownership__r)
                       ,(Select Id, Account__c, SourceContact__c
                           From Referrals__r)
                       ,(Select Id, Contact__c, Lead__c
                           From Stage_History__r)
                       ,(Select Id, AccountId__c, ContactId__c, LeadId__c
                           From Cars__r)
                       ,(Select Id, AccountId__c, ContactId__c, LeadId__c
                           From Touchpoint__r)
                   from Lead where Id in :leadIds]);
                   
      Prospect_Ownership__c[] updateOwnerships = new Prospect_Ownership__c[]{};
      Stage_History__c[] updateHistories = new Stage_History__c[]{};
      // any Contacts that need to be updated
      List<Contact> updateCtcts = new List<Contact>();
      // any Accounts that need to be updated
      List<Account> updateAccts = new List<Account>();
      // referral record to update
      List<Referral__c> updateReferrals = new List<Referral__c>();
      Id[] updatedAcctIds = new Id[]{};
      Cadence_Assignment_Record__c[] updateCars = new Cadence_Assignment_Record__c[]{};
      Cadence_Touchpoint__c[] updateTPs = new Cadence_Touchpoint__c[]{};
      
      // get the record types
      Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      String[] objectNames = new String[]{ObjectHelper.OBJECT_ACCOUNT,ObjectHelper.OBJECT_CONTACT};
      RecordTypeHelper.getRecordTypesMap(objectNames, RECORD_TYPE_NAMES, byId, byName);
      
      for (Lead lead : leads) {
         Account acct = lead.ConvertedAccount;
         if (acct != null) {
            // was the account updated during the checks?
            Boolean acctIsUpdated = false;
            
            String acctRTName = AccountHelper.getSalesAccountType(acct.Owner.Sales_Org__c,lead.NumberOfEmployees,AccountHelper.CORE_ACCOUNT);
            String ctctRTName = (acctRTName == AccountHelper.CORE_ACCOUNT ? AccountHelper.CORE_CONTACT : AccountHelper.MMS_CONTACT);
            System.debug('updateInline l='+lead.Name+' acctRTName='+acctRTName+' ctctRTName='+ctctRTName);
         
            Schema.RecordTypeInfo ctctRT = byName.get(ctctRTName);
            Schema.RecordTypeInfo acctRT = byName.get(acctRTName);
            
            Schema.RecordTypeInfo rt = byId.get(acct.RecordTypeId);
            if (!ONLY_REPARENT) {
            // if it's currently set to the prospect record type, do not change it. 
            Boolean skipAcctRtCheck = (rt != null && rt.getName() == PeoHelper.RT_PROSPECT);
            // only check record type if the account was just created. If the account was existing, leave as is.
            Boolean datesAreEqual = acct.CreatedDate.date() == lead.ConvertedDate;
            System.debug('updateInline overrideRecordType='+overrideRecordType+' datesAreEqual='+datesAreEqual+' skipAcctRtCheck='+skipAcctRtCheck+' rt='+(rt != null ? rt.getName() : 'null'));
            System.debug('updateInline acct='+acct.Name+' acct.CreatedDate.date()='+acct.CreatedDate.date()+' lead.ConvertedDate='+lead.ConvertedDate);
            if (!skipAcctRtCheck && datesAreEqual) {
               if ((overrideRecordType && acct.RecordTypeId != acctRT.getRecordTypeId()) 
                    ||  (!overrideRecordType && rt == null)) {
                  acct.RecordTypeId = acctRT.getRecordTypeId();
                  StringHelper.addToProcessNotes(acct,'updateInline Setting RecordTypeId='+acct.RecordTypeId);
                  acct.Use_Zip_Assignment_Rules__c = true;
                  // make sure the ownership is processed again. Since the account was just created, it won't automatically process
                  // ownership again.
                  ZipCheckOwner.accountIdsProcessedSet.remove(acct.Id);
                  acctIsUpdated = true;
               } // if ((acct.RecordTypeId !=
            } // if (datesAreEqual
            } // if (!ONLY_REPARENT
            
            for (Prospect_Ownership__c po : lead.Prospect_Ownership__r) {
               po.Prospect_Client__c = lead.ConvertedAccountId;
               po.Decision_Maker__c = lead.ConvertedContactId;
               updateOwnerships.add(po);
               // is there an open ownership record? If so, set the assigned to NSR flag.
               Boolean hasOpenOwnership = false;
               if (po.EndDate__c == null) {
                  po.LastVerified__c = null;   // to force it through the verify process
                  if (!ONLY_REPARENT) {
                     if (po.NSS_Source__c == ProspectOwnershipMethods.NSS_INBOUND) {
                        acct.AssignedToInboundNSR__c = true;
                     } else if (po.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND) {
                        acct.AssignedToOutboundNSR__c = true;
                     }
                     acctIsUpdated = true;
                  } // if (!ONLY_REPARENT
               }
 
            } // for (Prospect_Ownership__c po

            for (Referral__c rfrl : lead.Referrals__r) {
               rfrl.Account__c = lead.ConvertedAccountId;
               rfrl.SourceContact__c = lead.ConvertedContactId;
               updateReferrals.add(rfrl);
            }

            if (!ONLY_REPARENT) {
               Contact ctct = lead.ConvertedContact;
               if (ctct != null) {
                  System.debug('ctct='+ctct);
                  rt = byId.get(ctct.RecordTypeId);
                  // only update the record type if not already valid
                  if ((overrideRecordType && ctct.RecordTypeId != ctctRT.getRecordTypeId()) 
                       ||  (!overrideRecordType && rt == null)) {
                     ctct.RecordTypeId = ctctRT.getRecordTypeId();
                     updateCtcts.add(ctct);
                  } // if (rt == null
               } // if (ctct != null
            } // if (!ONLY_REPARENT
            
            if (acctIsUpdated) {
               updateAccts.add(acct);
               updatedAcctIds.add(acct.Id);
            }
         } // if (acct != null
         

         for (Stage_History__c history : lead.Stage_History__r) {
            history.Contact__c = lead.ConvertedContactId;
            updateHistories.add(history);
         }
          
         for (Cadence_Touchpoint__c tp : lead.Touchpoint__r) {
            tp.AccountId__c = lead.ConvertedAccountId;
            tp.ContactId__c = lead.ConvertedContactId;
            updateTPs.add(tp);
         }
         
         for (Cadence_Assignment_Record__c car : lead.Cars__r) {
            car.AccountId__c = lead.ConvertedAccountId;
            car.ContactId__c = lead.ConvertedContactId;
            //APR0130779 : Remove Significant Lead/Contact
           // car.SignificantContact__c = lead.ConvertedContactId;
            updateCars.add(car);
         }
         
      } // for (Lead lead
      DmlHelper.performDML2(updateOwnerships, DmlHelper.DML_UPDATE, 'LeadCheckContactRecordType', 'checkLeadsNow', 'Update Prospect Ownerships', false);
      DmlHelper.performDML2(updateHistories, DmlHelper.DML_UPDATE, 'LeadCheckContactRecordType', 'checkLeadsNow', 'Update Stage History records', false);
      // we want to fire the account triggers for ownership
      ZipCheckOwner.SKIP_TRIGGERS=false;
      // skip the triggers
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      if (SAVE_REFERRALS) {
         ReferralTriggerActions.SKIP_TRIGGER=true;
         DmlHelper.performDML2(updateReferrals, DmlHelper.DML_UPDATE, 'LeadCheckContactRecordType', 'checkLeadsNow', 'Update Referrals', false);
         ReferralTriggerActions.SKIP_TRIGGER=false;
      } 
      // update accounts if necessary
      DmlHelper.performDML2(updateAccts, DmlHelper.DML_UPDATE, 'LeadCheckContactRecordType', 'checkLeadsNow', 'Update Accounts', false);
      // udpate contact if necessary
      DmlHelper.performDML2(updateCtcts, DmlHelper.DML_UPDATE, 'LeadCheckContactRecordType', 'checkLeadsNow', 'Update Contacts', false);
      // to evaluate the zip code
      /*
      if (!updatedAcctIds.isEmpty()) {
         if (FORCE_EVALUATE_ZIP_INLINE || System.isFuture() || System.isBatch()) {
            System.debug('checkAccountOwners');
            ZipCheckOwner.processAccounts(updatedAcctIds);
         } else {
            ZipCheckOwner.checkAccountOwnersFuture(updatedAcctIds);
         }
      }
      */
      if (!updateCars.isEmpty()) {
         TriggerMethods.SKIP_TRIGGERS=true;
         CadenceHelper.SKIP_TRIGGERS=true;
         DmlHelper.performDML2(updateTPs, DmlHelper.DML_UPDATE, 'LeadCheckContactRecordType', 'updateCars', 'Update Touchpoint records', false);
         DmlHelper.performDML2(updateCars, DmlHelper.DML_UPDATE, 'LeadCheckContactRecordType', 'updateCars', 'Update CAR records', false);
         TriggerMethods.SKIP_TRIGGERS=false;
         CadenceHelper.SKIP_TRIGGERS=false;
      }
      ErrorLog.checkSave();
   } // updateInline
   
   @future
   public static void checkLeadsFuture(List<Id> leadIds, Boolean overrideRecordType) {
      checkLeadsNow(leadIds, overrideRecordType);
   } // checkLeadsFuture

   public static void checkLeadsNow(List<Id> leadIds, Boolean overrideRecordType) {
      List<Lead> leads = new List<Lead>([select Id, Name
                       ,ConvertedAccountId
                       ,ConvertedContactId
                       ,ConvertedDate
                       ,OwnerId
                       ,Owner.isActive
                       ,Owner.Profile.Name
                       ,(Select Id,Prospect_Client_Name__c
                                ,RecordType.Name
                                from Remote_Locations__r)
                       ,(Select Id, Account__c, Contact__c, Lead__c
                           From Partner_Referral_Lead__r)
                       ,(Select Id, Account__c, Contact__c, Lead__c
                           From Marketing_Call_Tracking__r)
                       ,(Select id, Account__c, Contact__c, Lead__c
                           From Ecommerces__r)
                   from Lead where Id in :leadIds]);
      // the owner ids
      List<Id> ownerIds = new List<Id>();
      
      // any Remote Locations that need to be updated
      List<Remote_Locations__c> updateRLs = new List<Remote_Locations__c>();
      // any Account Team Members that need to be inserted (Specifically for and myStaffingPro leads)
      List<AccountTeamMember> insertATMs = new List<AccountTeamMember>();
      // Partner Referrals to update
      PartnerReferral__c[] updatePartRefs = new PartnerReferral__c[]{};
      Marketing_Call_Tracking__c[] updateMCTs = new Marketing_Call_Tracking__c[]{};
      Ecommerce__c[] updateEcoms = new Ecommerce__c[]{};
      
      
      // check each Lead. If record type not in collection returned, find the lead and 
      // then determine correct record type from the number of employees.

      for (Lead lead : leads) {
            
         for(remote_locations__c RL : lead.remote_locations__r) {
            RL.Prospect_Client_Name__c = lead.ConvertedAccountId;
            updateRLs.add(RL);
         }
            
         for (PartnerReferral__c partRef : lead.Partner_Referral_Lead__r) {
            partRef.Account__c = lead.ConvertedAccountId;
            partRef.Contact__c = lead.ConvertedContactId;
            updatePartRefs.add(partRef);
         }
            
         for (Marketing_Call_Tracking__c mct : lead.Marketing_Call_Tracking__r) {
            mct.Account__c = lead.ConvertedAccountId;
            mct.Contact__c = lead.ConvertedContactId;
            updateMCTs.add(mct);
         }
            
         for (Ecommerce__c ecom : lead.Ecommerces__r) {
            ecom.Account__c = lead.ConvertedAccountId;
            ecom.Contact__c = lead.ConvertedContactId;
            updateEcoms.add(ecom);
         } // for (Ecommerce__c
            
         if (!ONLY_REPARENT) {
            if (lead.Owner.Profile != null 
                && lead.Owner.Profile.Name == Utilities.PROF_MSP_REP 
                && lead.Owner.isActive){
                insertATMs.add(new AccountTeamMember(AccountId = lead.ConvertedAccountId
                                                    ,UserId = lead.OwnerId
                                                    ,TeamMemberRole = 'MSP Account Representative',AccountAccessLevel='Edit', ContactAccessLevel='Edit', OpportunityAccessLevel='Read'));
            }
         } // if (!ONLY_REPARENT
            
         
      } // for (Lead lead
      
      //update Remote Locations if necessary
      DmlHelper.performDML2(updateRLs, DmlHelper.DML_UPDATE, 'LeadCheckContactRecordType', 'checkLeadsNow', 'Update Remote Locations', false);

      DmlHelper.performDML2(updatePartRefs, DmlHelper.DML_UPDATE, 'LeadCheckContactRecordType', 'checkLeadsNow', 'Update Partner Referrals', false);
      DmlHelper.performDML2(updateMCTs, DmlHelper.DML_UPDATE, 'LeadCheckContactRecordType', 'checkLeadsNow', 'Update Marketing Call Tracking', false);
      DmlHelper.performDML2(updateEcoms, DmlHelper.DML_UPDATE, 'LeadCheckContactRecordType', 'checkLeadsNow', 'Update Ecoms', false);
      
      // insert AccountTeamMembers if necessary
      DmlHelper.performDML2(insertATMs, DmlHelper.DML_INSERT, 'LeadCheckContactRecordType', 'checkLeadsNow', 'Insert Account Team Members', false);

      ErrorLog.checkSave();
   } // checkLeadsNow

} // class LeadCheckContactRecordType