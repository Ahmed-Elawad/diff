/* Methods for the Commission Info object
   
  History
  -------
  02/19/2016 Dan Carmen   Created
  08/29/2016 Dan Carmen   Added ability to update selling opportunity at the same time.
  07/31/2018 Dan Carmen   Added additional logging
  05/09/2022 Dan Carmen   Update API, change order of record saving
  
 */
public with sharing class CommissionMethods {

   public static Map<String,ComWrapper> byRefIdMap = new Map<String,ComWrapper>();
   public static Map<String,ComWrapper[]> byAcctNbrMap = new Map<String,ComWrapper[]>();
   public static Map<String,ComWrapper> byOppIdMap = new Map<String,ComWrapper>();
      
   public static Map<Id,Opportunity> updateOppMap = new Map<Id,Opportunity>();
   public static Map<String,Referral__c> updateRefMap = new Map<String,Referral__c>();
   
   // were new referrals created?
   public static Map<String,ComWrapper> newRefsCreatedMap = new Map<String,ComWrapper>();
   

   public static void checkTriggerBeforeActions(CommissionInfo__c comInfo, CommissionInfo__c oldComInfo) {
      if (!comInfo.Processed__c) {
         try {
            if (comInfo.Opportunity__c == null) {
               comInfo.Opportunity__c = comInfo.OpportunityId__c;
            }
         } catch (Exception e) {
            system.debug('checkTriggerBeforeActions exception: '+e.getMessage()+'; '+e.getStackTraceString());
         }
         // make sure the branch client number are formatted correctly
         comInfo.BranchClientNumber__c = AccountHelper.verifyAcctNbr(comInfo.BranchClientNumber__c);
         ComWrapper comWrap = new ComWrapper(comInfo);
         System.debug('checkTriggerBeforeActions comInfo='+comInfo);
         if (comInfo.Opportunity__c != null) {
            byOppIdMap.put(comInfo.Opportunity__c,comWrap);
            addToNotes(comInfo,'By Opp Id', true);
         } else if (String.isNotBlank(comWrap.comInfo.Referral_Id__c)) {
            byRefIdMap.put(comInfo.Referral_Id__c,comWrap);
            addToNotes(comInfo,'By Referral_Id__c Id', true);
         } else {
            checkAddToAcctNbrMap(comWrap);
         } // if (String.isNotBlank
         // mark all records as processed
         comInfo.Processed__c=true;
      } // if (!comInfo.Processed__c
   } // checkTriggerBeforeActions

   public static Boolean checkAddToAcctNbrMap(ComWrapper comWrap) {
      Boolean addedToMap = false;
      if (String.isNotBlank(comWrap.comInfo.BranchClientNumber__c)) {
         addedToMap = true;
         ComWrapper[] comList = byAcctNbrMap.get(comWrap.comInfo.BranchClientNumber__c);
         if (comList == null) {
            comList = new ComWrapper[]{};
            byAcctNbrMap.put(comWrap.comInfo.BranchClientNumber__c,comList);
            addToNotes(comWrap.comInfo,'By Branch-Client Nbr', true);
         }
         comList.add(comWrap);
      } else {
         comWrap.comInfo.Success__c=false;
         comWrap.comInfo.Error__c=true;
         comWrap.comInfo.Notes__c='Not enough information to process this record (ex no referral id, branch-client number, or client name)';
      } // if (String.isNotBlank
      return addedToMap;
   } // checkAddToAcctNbrMap
   
   public static void processTriggerBefore() {
      //oppsToUpdate.clear();
      System.debug('processTriggerBefore byOppIdMap='+byOppIdMap.size()+' byRefIdMap='+byRefIdMap.size()+' byAcctNbrMap='+byAcctNbrMap.size());
      
      if (!byOppIdMap.isEmpty()) {
         findByOppId();
      }

      if (!byRefIdMap.isEmpty()) {
         findByRefId();
      }
      
      if (!byAcctNbrMap.isEmpty()) {
         findByBranchCltNbr();
      }

      saveData();
      
      byRefIdMap.clear();
      byAcctNbrMap.clear();
      byOppIdMap.clear();
      updateOppMap.clear();
      updateRefMap.clear();
   } // processTriggerBefore

   public static void checkTriggerAfterActions(CommissionInfo__c comInfo, CommissionInfo__c oldComInfo) {
      
   } // checkTriggerAfterActions
   
   public static void processTriggerAfter() {
      
   } // processTriggerAfter
   
   //public static Opportunity[] oppsToUpdate = new Opportunity[]{};
   
   // search for Opportunity
   // If Opportunity exists, check for referral
   // if referral exists, update both records
   // if referral doesn't exist, create referral and partner referral
   public static void findByOppId() {
      
      Map<Id,PartnerReferral__c> partRefByOppIdMap = new Map<Id, PartnerReferral__c>();
      Map<Id,Referral__c> refByOppIdMap = new Map<Id, Referral__c>();
      Referral__c[] newRefs = new Referral__c[]{};
      Opportunity[] oppsWithNewRefs = new Opportunity[]{};
      
      
      for (Opportunity opp : [Select Id, Name
                                    ,AccountId
                                    ,Account.Id
                                    ,Account.Name
                                    ,Actual_Revenue__c
                                    ,Bank_Lead_ID__c
                                    ,Disposition__c
                                    ,Month_Sale_Reported__c
                                    ,Of_Employees__c
                                    ,Pending_Run_Of_Payroll__c
                                    ,BranchClientNumber__c
                                    ,FedIdNumber__c
                                    ,Referral_Contact__c
                                    ,Referral_Contact__r.Id
                                    ,Referral_Contact__r.Contact__c
                                    ,Referral_Contact__r.Referral_Account__c
                                    ,Referral_Contact__r.Referral_Account__r.Id
                                    ,Referral_Contact__r.Referral_Account__r.Name
                                    ,Referral_Contact__r.Referral_Account__r.Account__c
                                    ,Referral_Contact__r.Referral_Account__r.Parent_Referral_Account__r.Id
                                    ,Referral_Contact__r.Referral_Account__r.Parent_Referral_Account__r.Name
                                    ,Referral_Contact__r.Referral_Account__r.Parent_Referral_Account__r.Account__c
                                    ,ReferralLookup__c
                                    ,ReferralLookup__r.Name
                                    ,ReferralLookup__r.NbrOfEmployees__c
                                    ,ReferralLookup__r.ActualRevenue__c
                                    ,ReferralLookup__r.BranchClientNumber__c
                                    ,ReferralLookup__r.CommissionOverride__c
                                    ,ReferralLookup__r.Disposition__c
                                    ,ReferralLookup__r.FedIdNumber__c
                                    ,ReferralLookup__r.MonthSaleReported__c
                                    ,ReferralLookup__r.PaymentAmount__c
                                    ,ReferralLookup__r.PaymentConfirmation__c
                                    ,ReferralLookup__r.PaymentRequestDate__c
                                    ,ReferralLookup__r.PendingRunOfPayroll__c
                                   ,(Select Id, ContactId
                                           ,Contact.FirstName
                                           ,Contact.LastName
                                       From OpportunityContactRoles
                                      Where IsPrimary = true
                                       limit 1)
                                From Opportunity
                               Where Id in :byOppIdMap.keySet()]) {
         ComWrapper comWrap = byOppIdMap.remove(opp.Id);
         if (comWrap != null) {
            comWrap.comInfo.MatchedByOppId__c = true;
            comWrap.opp = opp;
            comWrap.comInfo.Opportunity__c = opp.Id;
            comWrap.comInfo.Opportunity__r = opp;
            comWrap.ref = opp.ReferralLookup__r;
            addToNotes(comWrap.comInfo,'Found Opp by findByOppId', false);
            
            if (opp.ReferralLookup__r == null) {
               // create the referral
               Referral__c ref = createNewReferral(comWrap, opp.Account);
               oppsWithNewRefs.add(opp);
               addToNotes(comWrap.comInfo,'created new referral', false);
            } else if (opp.ReferralLookup__r != null) {
               setCommissionFields(comWrap);
               addToNotes(comWrap.comInfo,'Used existing referral', false);
            }
         }
      } // for (Opportunity opp
      
      // for any records we created the referrals for, set the commission fields
      
      // if any records left in the map, add to one of the other maps for processing
      for (ComWrapper comWrap : byOppIdMap.values()) {
         if (String.isNotBlank(comWrap.comInfo.Referral_Id__c)) {
            byRefIdMap.put(comWrap.comInfo.Referral_Id__c,comWrap);
         } else {
            checkAddToAcctNbrMap(comWrap);
         } // if (String.isNotBlank
      } // for (CommissionInfo__c comInfo
   } // findByOppId
   
   // find referrals by the referral id
   public static void findByRefId() {
      Set<String> querySet = new Set<String>();
      querySet.addAll(byRefIdMap.keySet());
      System.debug('findByRefId querySet='+querySet);

      Referral__c[] refs = [Select Id, Name
                                  ,Referral_Id__c
                                  ,NbrOfEmployees__c
                                  ,ActualRevenue__c
                                  ,BranchClientNumber__c
                                  ,CommissionOverride__c
                                  ,Disposition__c
                                  ,FedIdNumber__c
                                  ,MonthSaleReported__c
                                  ,PaymentAmount__c
                                  ,PaymentConfirmation__c
                                  ,PaymentRequestDate__c
                                  ,PendingRunOfPayroll__c
                                  ,Selling_Opportunity__r.Id
                                  ,Selling_Opportunity__r.Name
                                  ,Selling_Opportunity__r.Actual_Revenue__c
                                  ,Selling_Opportunity__r.Disposition__c
                                  ,Selling_Opportunity__r.Month_Sale_Reported__c
                                  ,Selling_Opportunity__r.Of_Employees__c
                                  ,Selling_Opportunity__r.Pending_Run_Of_Payroll__c
                                  ,Selling_Opportunity__r.BranchClientNumber__c
                                  ,Selling_Opportunity__r.FedIdNumber__c
                              From Referral__c
                            Where Referral_Id__c != null
                              and Referral_Id__c in :querySet ];
      for (Referral__c ref : refs) {
         ComWrapper comWrap = byRefIdMap.remove(ref.Referral_Id__c);
         if (comWrap != null) {
            comWrap.ref = ref;
            comWrap.opp = ref.Selling_Opportunity__r;
            setCommissionFields(comWrap);
            comWrap.comInfo.MatchedByReferralId__c = true;
            addToNotes(comWrap.comInfo,'Found referral with findByRefId', false);
         } // if (comInfo != null
      } // for (Referral__c ref : refs
      
      /*
      if (!refs.isEmpty()) {
         //update refs;
         DmlHelper.performDML2(refs, DmlHelper.DML_UPDATE, 'CommissionMethods', 'findByRefId', 'update referrals', true);
      }
      
      OpptyMethods.SKIP_PAYMENT_TO_REFERRAL = true;
      DmlHelper.performDML2(oppsToUpdate, DmlHelper.DML_UPDATE, 'CommissionMethods', 'findByRefId', 'update opportunities', true);
      */
      // if there are any left in the map, we didn't find a matching referral. 
      if (!byRefIdMap.isEmpty()) {
         for (ComWrapper comWrap : byRefIdMap.values()) {
            addToNotes(comWrap.comInfo,'Did not find a referral in findByRefId', false);
            checkAddToAcctNbrMap(comWrap);
         }
      } // if (!byRefIdMap
   } // findByRefId
   
   // look for an account record with the specified branch-client number.
   // if a record exists, do we look for an existing referral, or just create a new one?
   // if an account doesn't exist, do we create both the account and referral?
   public static void findByBranchCltNbr() {
      Account[] accts = [Select Id
                               ,Name
                               ,AccountNumber
                           From Account
                          Where AccountNumber in :byAcctNbrMap.keySet()];
      System.debug('findByBranchCltNbr byAcctNbrMap='+byAcctNbrMap.size()+' accts='+accts.size());
      for (Account acct : accts) {
         ComWrapper[] comWraps = byAcctNbrMap.remove(acct.AccountNumber);
         System.debug('findByBranchCltNbr comWraps='+(comWraps != null ? comWraps.size() : -1));
         if (comWraps != null) {
            for (ComWrapper comWrap : comWraps) {
               createNewReferral(comWrap, acct);
               comWrap.comInfo.MatchedByBrCltNbr__c = true;
               addToNotes(comWrap.comInfo,'Found Account in findByBranchCltNbr', false);
            } // for (CommissionInfo__c comInfo
         } // if (comList != null
      } // for
      
      if (!byAcctNbrMap.isEmpty()) {
         checkForNewAccounts();
      }
      
   } // findByBranchCltNbr
   
   public static Referral__c[] newReferrals = new Referral__c[]{};
   public static PartnerReferral__c[] newPartnerRefs = new PartnerReferral__c[]{};
   
   public static Boolean saveData() {
      // insert the partner referrals
      System.debug('saveData newPartnerRefs='+newPartnerRefs.size()+' newReferrals='+newReferrals.size());
      DmlHelper.performDML2(newPartnerRefs, DmlHelper.DML_INSERT, 'CommissionMethods', 'saveData', 'create new partner referrals', false);
      
      Map<Id,PartnerReferral__c> partRefMap = (!newPartnerRefs.isEmpty() ?  new Map<Id,PartnerReferral__c>([Select Id, Name from PartnerReferral__c where Id in :newPartnerRefs]) : new Map<Id,PartnerReferral__c>());
       
      // link the referrals back to the partner referrals
      for (ComWrapper comWrap : newRefsCreatedMap.values()) {
         if (comWrap.partRef != null && comWrap.ref != null && comWrap.partRef.Id != null) {
            comWrap.ref.PartnerReferral__c = comWrap.partRef.Id;
            if (partRefMap.containsKey(comWrap.partRef.Id)) {
               comWrap.ref.Referral_Id__c = partRefMap.get(comWrap.partRef.Id).Name;
            }
         }
      } // for (ComWrapper comWrap

      // save the referrals
      DmlHelper.performDML2(newReferrals, DmlHelper.DML_INSERT, 'CommissionMethods', 'saveData', 'create new referrals', false);
      
      // re-query the new referrals to get the referral id
      Map<Id,Referral__c> refMap = new Map<Id,Referral__c>([Select Id, Name, Referral_Id__c
                                                                  ,Selling_Opportunity__c
                                                                  ,PartnerReferral__r.Name
                                                              from Referral__c 
                                                             where Id in :newReferrals]);
      
      System.debug('saveData newRefsCreatedMap='+newRefsCreatedMap.size());
      // make sure the referral ids are set on the partner referrals
      for (ComWrapper comWrap : newRefsCreatedMap.values()) {
         Referral__c checkRef = refMap.get(comWrap.ref.Id);
         System.debug('saveData comInfo='+comWrap.comInfo.ClientName__c+' ref='+comWrap.ref.Id+' checkRef='+checkRef);
         if (comWrap.partRef != null && comWrap.ref != null && comWrap.ref.Id != null) {
            comWrap.partRef.Referral__c = comWrap.ref.Id;
            if (checkRef != null && comWrap.opp != null && comWrap.opp.Bank_Lead_ID__c != checkRef.Referral_Id__c) {
               updateOppMap.put(comWrap.opp.Id, comWrap.opp);
            }
         } // if (comWrap.partRef != null
         // make sure the bank lead id is set on the opportunity
         if (checkRef != null) {
            comWrap.comInfo.Referral__c = checkRef.Id;
            comWrap.comInfo.Referral__r = null;
            String refId = (String.isNotBlank(checkRef.Referral_Id__c) ? checkRef.Referral_Id__c : (checkRef.PartnerReferral__r != null ? checkRef.PartnerReferral__r.Name : null ));
            comWrap.comInfo.Referral_Id__c = refId;
         }
         if (comWrap.opp != null && (String.isBlank(comWrap.opp.Bank_Lead_ID__c) || comWrap.opp.ReferralLookup__c == null)) {
            if (String.isBlank(comWrap.opp.Bank_Lead_ID__c) && checkRef != null) {
               comWrap.opp.Bank_Lead_ID__c = checkRef.Referral_Id__c;
            }
            if (comWrap.opp.ReferralLookup__c == null && comWrap.ref != null) {
               comWrap.opp.ReferralLookup__c = comWrap.ref.Id;
            }
            updateOppMap.put(comWrap.opp.Id, comWrap.opp);
         }
      } // for (ComWrapper comWrap


      System.debug('saveData 1 updateRefMap='+updateRefMap.size()+' keys='+updateRefMap.keySet());
      for (Referral__c rfrl : newReferrals) {
         updateRefMap.put(rfrl.Id, rfrl);
      }
      System.debug('saveData 2 updateRefMap='+updateRefMap.size()+' keys='+updateRefMap.keySet());
      /*
      if (Test.IsRunningTest()) {
         for (Referral__c rfrl : updateRefMap.values()) {
            System.debug('saveData rfrl id='+rfrl.Id+' name='+rfrl.Name);
         }
      }
      */
      // update the referrals so the ids are saved
      ReferralTriggerActions.SKIP_TRIGGER=true;
      DmlHelper.performDML2(updateRefMap.values(), DmlHelper.DML_UPDATE, 'CommissionMethods', 'saveData', 'udpate referrals', false);
      OpptyMethods.SKIP_PAYMENT_TO_REFERRAL = true;
      DmlHelper.performDML2(updateOppMap.values(), DmlHelper.DML_UPDATE, 'CommissionMethods', 'saveData', 'udpate opportunities', false);
      ErrorLog.checkSave();
      return true;
   } // saveData
   
   public static Referral__c createNewReferral(ComWrapper comWrap, Account acct) {
                                                 
      System.debug('createNewReferral acct='+(acct != null ? acct.Name : 'no account'));
      CommissionInfo__c comInfo = comWrap.comInfo;
      Referral_Partner__c refPartner = PartnerWrapper.findReferralPartner(null);
      comWrap.ref = new Referral__c(Name=comInfo.ClientName__c, Referral_Partner__c=(refPartner != null ? refPartner.Id : null));
                          
      comWrap.partRef = new PartnerReferral__c();

      if (acct != null) {
         comWrap.ref.Account__c = acct.Id;
         if (acct.Id == null) {
            comWrap.ref.Account__r = acct;
         }
         comWrap.partRef.Company__c = acct.Name;
      } // if (acct != null
      
      if (comWrap.opp != null) {
         comWrap.ref.Selling_Opportunity__c=comWrap.opp.Id;
         
         if (comWrap.opp.Referral_Contact__r != null) {
            comWrap.partRef.PartnerAcct__c = (comWrap.opp.Referral_Contact__r.Referral_Account__r.Parent_Referral_Account__r != null ? comWrap.opp.Referral_Contact__r.Referral_Account__r.Parent_Referral_Account__r.Account__c : null);
            comWrap.partRef.PartnerBranchAcct__c = comWrap.opp.Referral_Contact__r.Referral_Account__r.Account__c;
            comWrap.partRef.PartnerContact__c = comWrap.opp.Referral_Contact__r.Contact__c;
            
            comWrap.ref.Referral_Contact__c = comWrap.opp.Referral_Contact__c;
            comWrap.ref.Referral_Account__c = comWrap.opp.Referral_Contact__r.Referral_Account__c;
            comWrap.ref.ReferralSourceAccount__c = comWrap.opp.Referral_Contact__r.Referral_Account__r.Account__c;
            comWrap.ref.ReferralSourceContact__c = comWrap.opp.Referral_Contact__r.Contact__c;
            comWrap.ref.ReferringAccountParent__c = comWrap.partRef.PartnerAcct__c;
         }
         
         if (comWrap.opp.OpportunityContactRoles != null && !comWrap.opp.OpportunityContactRoles.isEmpty()) {
            Contact ctct = comWrap.opp.OpportunityContactRoles[0].Contact;
            if (ctct != null) {
               comWrap.partRef.FirstName__c = ctct.FirstName;
               comWrap.partRef.LastName__c = ctct.LastName;
            }
         }
      } // if (opp != null
      
      if (String.isNotBlank(comInfo.Referral_Id__c)) {
         comWrap.ref.Referral_Id__c = comInfo.Referral_Id__c;
      } else {
         comWrap.ref.GenerateReferralId__c=true;
      }
      comInfo.CreatedReferral__c = true;
      setCommissionFields(comWrap);
      comInfo.Referral__r = comWrap.ref;
      newRefsCreatedMap.put(comWrap.comInfo.ClientName__c+comWrap.comInfo.BranchClientNumber__c, comWrap);
      
      newReferrals.add(comWrap.ref);
      newPartnerRefs.add(comWrap.partRef);
      
      return comWrap.ref;
   } // createNewReferral
   
   // if accounts weren't found, create new ones
   public static void checkForNewAccounts() {
      Referral__c[] tempNewRefs = new Referral__c[]{};
      Account[] newAccts = new Account[]{};
      Map<String,Account> newAcctMap = new Map<String,Account>();
      
      for (String key : byAcctNbrMap.keySet()) {
         ComWrapper[] comWraps = byAcctNbrMap.get(key);
         if (comWraps != null && !comWraps.isEmpty()) {
            CommissionInfo__c firstComInfo = comWraps[0].comInfo;
            if (String.isNotBlank(firstComInfo.ClientName__c)) {
               Account acct = new Account(Name=firstComInfo.ClientName__c, AccountNumber=firstComInfo.BranchClientNumber__c, Federal_ID_Number__c=firstComInfo.FedIdNumber__c);
               newAcctMap.put(key,acct);
            } // if (String.isNotBlank(firstComInfo.ClientName__c
         } // if (comInfos != null
      } // for (String key

      if (!newAcctMap.isEmpty()) {
         DmlHelper.performDML2(newAcctMap.values(), DmlHelper.DML_INSERT, 'CommissionMethods', 'checkForNewAccounts', 'create new accounts', false);
      } // if (!newAccts.isEmpty

      for (String key : byAcctNbrMap.keySet()) {
         ComWrapper[] comWraps = byAcctNbrMap.get(key);
         Account acct = newAcctMap.get(key); 
         if (comWraps != null && acct != null) {
            for (ComWrapper comWrap : comWraps) {
               Referral__c ref = createNewReferral(comWrap, acct);
               comWrap.comInfo.CreatedAccount__c = true;
            } // for (CommissionInfo__c comInfo
         } // if (comWraps != null
      } // for (String key
      
   } // checkForNewAccounts

   
   public static void checkFields(CommissionInfo__c comInfo, String comInfoFieldName
                                 ,Referral__c ref, String refFieldName
                                 ,Opportunity opp, String oppFieldName) {
      if (comInfo.get(comInfoFieldName) != null) {
         if (ref != null && refFieldName != null) {
            //System.debug('checkFields refFieldName='+refFieldName+' value='+comInfo.get(comInfoFieldName));
            ref.put(refFieldName,comInfo.get(comInfoFieldName));
            addToNotes(comInfo,'set Ref field '+refFieldName+' to '+comInfo.get(comInfoFieldName), false);
         }
         if (opp != null && oppFieldName != null) {
            //System.debug('checkFields oppFieldName='+oppFieldName+' value='+comInfo.get(comInfoFieldName));
            opp.put(oppFieldName, comInfo.get(comInfoFieldName));
            addToNotes(comInfo,'set Opp field '+refFieldName+' to '+comInfo.get(comInfoFieldName), false);
         }
      }
   } // checkFields
   
   public static String LOCK_DISPOSITION = Label.DispositionLock;
   
   public static void setCommissionFields(ComWrapper comWrap) {

      CommissionInfo__c comInfo = comWrap.comInfo;
      Opportunity opp = comWrap.opp;
      Referral__c ref = comWrap.ref;

      // only allow a change if the 
      Boolean allowChange = ((comInfo != null && comInfo.Override__c) 
                             || ((opp == null || (opp != null && opp.Disposition__c != LOCK_DISPOSITION))
                                 && (ref == null || (ref != null && ref.Disposition__c != LOCK_DISPOSITION)))
                            );

      addToNotes(comInfo,'allowChange='+allowChange,true);
      System.debug('setCommissionFields allowChange='+allowChange+' opp='+(opp != null ? opp.Name : 'No Opp')+' ref='+(ref != null ? ref.Name : 'No Ref'));
      
      if (comInfo != null && (ref != null || opp != null)) {
         ref.CommissionOverride__c = comInfo.Override__c;

         if (allowChange) {
            checkFields(comInfo, 'NbrOfEmployees__c', ref, 'NbrOfEmployees__c', opp, 'Of_Employees__c');
            checkFields(comInfo, 'ActualRevenue__c', ref, 'ActualRevenue__c', opp, 'Actual_Revenue__c');
            checkFields(comInfo, 'BranchClientNumber__c', ref, 'BranchClientNumber__c', opp, 'BranchClientNumber__c');
            checkFields(comInfo, 'Disposition__c', ref, 'Disposition__c', opp, 'Disposition__c');
            checkFields(comInfo, 'FedIdNumber__c', ref, 'FedIdNumber__c', opp, 'FedIdNumber__c');
            checkFields(comInfo, 'MonthSaleReported__c', ref, 'MonthSaleReported__c', opp, 'Month_Sale_Reported__c');
            checkFields(comInfo, 'PendingRunOfPayroll__c', ref, 'PendingRunOfPayroll__c', opp, 'Pending_Run_Of_Payroll__c');
         } else {
            comInfo.Notes__c = 'Change is not allowed on the Actual Revenue due to the '+LOCK_DISPOSITION+' disposition';
         }
         checkFields(comInfo, 'PaymentAmount__c', ref, 'PaymentAmount__c', opp, null);
         checkFields(comInfo, 'PaymentConfirmation__c', ref, 'PaymentConfirmation__c', opp, null);
         checkFields(comInfo, 'PaymentRequestDate__c', ref, 'PaymentRequestDate__c', opp, null);

         if (opp != null && opp.Id != null) {
            comInfo.Opportunity__c = opp.Id;
            comInfo.OpportunityUpdated__c=true;
            //System.debug('setCommissionFields added opp '+opp.Id+' to update');
            updateOppMap.put(opp.Id, opp);
            //oppsToUpdate.add(opp);
         }
         if (ref != null && ref.Id != null) {
            comInfo.Referral__c = ref.Id;
            //System.debug('setCommissionFields added ref '+ref.Id+' to update');
            updateRefMap.put(ref.Id, ref);
         }
         comInfo.Success__c=true;
      } // if (ref != null && comInfo != null
      system.debug('setCommissionFields comInfo='+(comInfo != null ? comInfo.ClientName__c+' success='+comInfo.Success__c : 'Not Found'));
   } // setCommissionFields
   
   public class ComWrapper {
      public ComWrapper(CommissionInfo__c p_comInfo) {
         comInfo = p_comInfo;
      }
      public CommissionInfo__c comInfo;
      public Referral__c ref;
      public PartnerReferral__c partRef;
      public Opportunity opp;
   } // class ComWrapper
   
   public static final Integer PROCESS_NOTES_SIZE = CommissionInfo__c.ProcessNotes__c.getDescribe().getLength();
   
   public static void addToNotes(CommissionInfo__c obj, String notesToAdd, Boolean addTimeStamp) {
      StringHelper.addNotesToField(obj, 'ProcessNotes__c', PROCESS_NOTES_SIZE, notesToAdd, addTimeStamp);
   } // addToNotes

   
} // class CommissionMethods