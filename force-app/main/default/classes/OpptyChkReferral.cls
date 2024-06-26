/* 
   Check to make sure the Referral_Contact is set on the Account if it's set on the opportunity. 
   
  History
  -------
  12/11/2008 Dan Carmen   Created
  06/30/2010 Dan Carmen   Changed to make it a future method.
  09/13/2011 Dan Carmen   Added logic to populate the Referral Account field on the Opportunity.
  09/23/2011 Dan Carmen   Changed to allow partial commit of updates.
  10/09/2014 Dan Carmen   Adjusted code to not run future methods during test - causing issues.
  09/01/2015 Dan Carmen   Added additional criteria for checking the referral contact linkage on the account.
  11/06/2016 Dan Carmen   Update back to the Opportunity moved to the SRRTransitionHelper class (temporarily)
  07/19/2018 Jake Hinds   Adding Credit Card Sensitivity
  09/20/2018 Jake Hinds   Updating Credit Card Sensitivity to set account directly
  03/19/2019 Dan Carmen   Add logic to set other types of referral sources
  01/15/2020 Cindy Freeman  remove special code for Credit Card Sensitivity, handle it like all other sensitivities
  07/06/2020  Jacob Hinds         Added without sharing per PMD
 */
public without sharing class OpptyChkReferral implements TriggerInterface2 {

   public static Set<String> ALREADY_RAN_SET = new Set<String>();
    
   public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
      // check what the type of the first record is
      System.debug('OpptyChkReferral.checkAllBeforeTrigger recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      if (isAfter && recs != null && !recs.isEmpty()) {
         SObjectType objType = recs[0].getSObjectType();
         String objTypeName = objType.getDescribe().getName();
         if (!ALREADY_RAN_SET.contains(objTypeName)) { 
            if (objType == Lead.sObjectType) {
               checkLeads((Lead[])recs, (Map<Id,Lead>)oldMap);
            } else if (objType == Opportunity.sObjectType) {
               checkOpportunities((Opportunity[])recs, (Map<Id,Opportunity>)oldMap);
            }
            // so we only hit the trigger once per object in the transaction
            ALREADY_RAN_SET.add(objTypeName);
         } // if (!ALREADY_RAN_SET
      } // if (recs != null
   } // triggerCheckAllFirst

   public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
   
   // see if there are any actions that need to take place at the end of the trigger.
   public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
   
   public static Boolean SKIP_FUTURE=Test.isRunningTest();
   
   public static void checkOpportunities(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
      System.debug('checkOpportunities opps='+opps.size());
      Id[] opptyIds = new Id[]{};
      for (Opportunity opp : opps) {
         Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
         // see if the referral contact changed
         // if the stage changes perform the check again, just to make sure the values are set.
         if (opp.Referral_Contact__c != null && String.isNotBlank(opp.LeadSource)
               && (oldOpp == null
                  || ((opp.StageName != oldOpp.StageName)
                       || (opp.Referral_Contact__c == null && oldOpp.Referral_Contact__c != null)
                       || (opp.Referral_Contact__c != null && opp.Referral_Contact__c != oldOpp.Referral_Contact__c)
                       || (opp.LeadSource != oldOpp.LeadSource))
            )) {
            System.debug('checkOpportunities add opp='+opp.Name+' to check list');
            opptyIds.add(opp.Id);
         }
      } // for (Opportunity opp
      
      if (!opptyIds.isEmpty()) {
         checkOpptys(opptyIds);
      }
   } // checkOpportunities
   

   public static void checkOpptys(Id[] opptyIds) {
      if (SKIP_FUTURE || System.isBatch() || System.isFuture()) {
         checkOpptysNow(opptyIds);
      } else {
         checkOpptysFuture(opptyIds);
      }
   } // checkOpptys

   @future
   public static void checkOpptysFuture(Id[] opptyIds) {
      checkOpptysNow(opptyIds);
   }
  
   public static Map<Id,Account> updateAcctMap = new Map<Id,Account>();
   public static Map<Id,Referral_Contact__c> updateRefCtctMap = new Map<Id,Referral_Contact__c>();
   
   public static void initializeSaveMaps() {
      updateAcctMap.clear();
      updateRefCtctMap.clear();
   } // initializeSaveMaps
   
   public static void checkSaveMaps() {
      DmlHelper.performDML2(updateAcctMap.values(), DmlHelper.DML_UPDATE, 'OpptyChkReferral', 'checkSaveMaps', 'Update Accounts', false);
      DmlHelper.performDML2(updateRefCtctMap.values(), DmlHelper.DML_UPDATE, 'OpptyChkReferral', 'checkSaveMaps', 'Update Referral Contacts', false);
      ErrorLog.checkSave();
   } // checkSaveMaps
   
   public static void checkOpptysNow(Id[] opptyIds) {
      System.debug('checkOpptysNow opptyIds='+opptyIds.size());
      List<Opportunity> opptys = new List<Opportunity>([Select Id, LeadSource, Name, IsClosed, IsWon
                                                               ,Referral_Contact__c
                                                               ,Referral_Contact__r.Referral_Account__c
                                                               ,Referral_Contact__r.Referral_Account__r.Id
                                                               ,Referral_Contact__r.Sensitivity_Credit_Card_Processing__c
                                                               ,Referral_Account__c
                                                               ,Referral_Account__r.Id
                                                               ,AccountId
                                                               ,Account.Id
                                                               ,Account.Name
                                                               ,Account.CPA_Name_Ref__c
                                                               ,Account.Broker_Name_Ref__c
                                                               ,Account.Banker_Name_Ref__c
                                                               //,Account.Credit_Card_Sensitivity__c
                                                               ,Account.Insurance_Broker_Name_Ref__c
                                                               ,Account.Referral_National_Account__c
                                                           from Opportunity
                                                          where Id in :opptyIds]);
       
       initializeSaveMaps();
       
       
      // Map<Id,Id> acctRfrlMap = new Map<Id,Id>();
       //List<Account> updateAccts = new List<Account>();
       //List<Opportunity> updateOpptys = new List<Opportunity>();
       //List<Referral_Contact__c> updateRefCtcts = new List<Referral_Contact__c>();
       
       
      for (Opportunity oppty : opptys) {
         System.debug('checkOpptysNow oppty='+oppty.Name+' isClosed='+oppty.IsClosed+' isWon='+oppty.IsWon);
         if (!oppty.IsClosed && !oppty.IsWon) {
            Referral_Account__c refAcct = (oppty.Referral_Account__r != null ? oppty.Referral_Account__r
                                             : (oppty.Referral_Contact__r != null ? oppty.Referral_Contact__r.Referral_Account__r : null));
            checkRecord(oppty.LeadSource, oppty.Referral_Contact__r, refAcct, oppty.Account);
         } 

/*
          // don't set the referral on the account if the opportunity is closed and lost
          if ((!oppty.IsClosed || oppty.IsWon) &&  
              (oppty.LeadSource != null && oppty.LeadSource.startsWith(Label.LeadSource_ReferralCPA_start)) &&
              (oppty.Account.CPA_Name_Ref__c != oppty.Referral_Contact__c)) {
             oppty.Account.CPA_Name_Ref__c = oppty.Referral_Contact__c;
             updateAccts.add(oppty.Account);
          }
          else if ((!oppty.IsClosed || oppty.IsWon) &&  
              (oppty.LeadSource != null && oppty.LeadSource.startsWith(Label.LeadSource_ReferralBank))) {
             Referral_Contact__c refCtct = oppty.Referral_Contact__r;
             if(refCtct!=null && !refCtct.Sensitivity_Credit_Card_Processing__c){
               refCtct.Sensitivity_Credit_Card_Processing__c = true;
               updateRefCtcts.add(refCtct);
             }
             if(!oppty.Account.Credit_Card_Sensitivity__c){
                oppty.Account.Credit_Card_Sensitivity__c  = true;
                updateAccts.add(oppty.Account);
             }
          }
          */
          /*
         if (oppty.Referral_Account__c != oppty.Referral_Contact__r.Referral_Account__c) {
            oppty.Referral_Account__c = oppty.Referral_Contact__r.Referral_Account__c;
            System.debug('OpptyChkReferral setting Referral_Account__c on '+oppty.Name+': '+oppty.Referral_Account__c);
            updateOpptys.add(oppty);
         }
         */
       } // for
       checkSaveMaps();
       
    //if (!updateRefCtcts.isEmpty()){
    //     Database.update(updateRefCtcts,false);
    //}
    //  if (!updateAccts.isEmpty()) {
    //     Database.update(updateAccts,false);
    //  }
      /*
      if (!updateOpptys.isEmpty()) {
         Database.update(updateOpptys,false);
      }
     */
   } // checkOpptys
   
   public static void checkLeads(Lead[] lds, Map<Id,Lead> oldMap) {
      Id[] leadIds = new Id[]{};
      for (Lead ld : lds) {
         // only process leads on convert - we want to set information on the account from the lead
         Lead oldLd = (oldMap != null ? oldMap.get(ld.Id) : null);
         if (oldLd != null && ld.IsConverted && !oldLd.isConverted) {
            leadIds.add(ld.Id);
         }
      } // for (Lead ld : lds
      
      if (!leadIds.isEmpty()) {
         if (SKIP_FUTURE || System.isBatch() || System.isFuture()) {
            checkLeadsNow(leadIds);
         } else {
            checkLeadsFuture(leadIds);
         }
      } // if (!leadIds.isEmpty
   } // checkLeads
   
   @future
   public static void checkLeadsFuture(Id[] leadIds) {
      checkLeadsNow(leadIds);
   } // checkLeadsFuture
   
   public static void checkLeadsNow(Id[] leadIds) {
      Lead[] leads = [Select Id, LeadSource, Name
                            ,Referral_Contact__c
                            ,Referral_Contact__r.Referral_Account__c
                            ,Referral_Contact__r.Referral_Account__r.Id
                            ,Referral_Contact__r.Sensitivity_Credit_Card_Processing__c
                            ,Referral_National_Account__c
                            ,Referral_National_Account__r.Id
                            ,ConvertedAccountId
                            ,ConvertedAccount.Id
                            ,ConvertedAccount.Name
                            ,ConvertedAccount.CPA_Name_Ref__c
                            ,ConvertedAccount.Broker_Name_Ref__c
                            ,ConvertedAccount.Banker_Name_Ref__c
                            //,ConvertedAccount.Credit_Card_Sensitivity__c
                            ,ConvertedAccount.Insurance_Broker_Name_Ref__c
                            ,ConvertedAccount.Referral_National_Account__c
                        from Lead
                       where Id in :leadIds
                         and IsConverted=true
                         and ConvertedAccountId != null];
       
       initializeSaveMaps();
       
       for (Lead ld : leads) {
             Referral_Account__c refAcct = (ld.Referral_National_Account__r != null ? ld.Referral_National_Account__r
                                              : (ld.Referral_Contact__r != null ? ld.Referral_Contact__r.Referral_Account__r : null));
             checkRecord(ld.LeadSource, ld.Referral_Contact__r, refAcct, ld.ConvertedAccount);

       } // for
       checkSaveMaps();
       
   } // checkLeadsNow
   
   public static void checkRecord(String leadSource, Referral_Contact__c refCtct, Referral_Account__c refAcct, Account acct) {
      String lsCategory = LeadSourceHelper.checkSettingForCategory(leadSource);
      System.debug('checkRecord lsCategory='+lsCategory+' acct='+(acct != null ? acct.Name : 'No Acct!'));
      if (acct != null && refCtct != null && String.isNotBlank(lsCategory)) {
         if (lsCategory == Label.LeadSourceCat_CPA && acct.CPA_Name_Ref__c != refCtct.Id) {
            System.debug('checkRecord CPA field');
            acct.CPA_Name_Ref__c = refCtct.Id;
            updateAcctMap.put(acct.Id,acct);
         } else if (lsCategory == Label.LeadSourceCat_Bank) {
            System.debug('checkRecord Bank');
            if (!refCtct.Sensitivity_Credit_Card_Processing__c) {
               refCtct.Sensitivity_Credit_Card_Processing__c = true;
               updateRefCtctMap.put(refCtct.Id, refCtct);
            }
            //if (!acct.Credit_Card_Sensitivity__c || acct.Banker_Name_Ref__c != refCtct.Id) {
            if (acct.Banker_Name_Ref__c != refCtct.Id) {
               //acct.Credit_Card_Sensitivity__c = true;
               acct.Banker_Name_Ref__c = refCtct.Id;
               updateAcctMap.put(acct.Id,acct);
            }
         } else if (lsCategory == Label.LeadSourceCat_FinAdv && acct.Broker_Name_Ref__c != refCtct.Id) {
            System.debug('checkRecord Financial Advisor');
            acct.Broker_Name_Ref__c = refCtct.Id;
            updateAcctMap.put(acct.Id,acct);
         } else if (lsCategory == Label.LeadSourceCat_InsAgent && acct.Insurance_Broker_Name_Ref__c != refCtct.Id) {
            System.debug('checkRecord Agent');
            acct.Insurance_Broker_Name_Ref__c = refCtct.Id;
            updateAcctMap.put(acct.Id,acct);
         }
      } // if (String.isNotBlank(leadSource
      
      if (acct != null && refAcct != null 
                 && String.isNotBlank(lsCategory) && lsCategory == Label.LeadSourceCat_Strategic
                 && acct.Referral_National_Account__c != refAcct.Id) {
         System.debug('checkRecord Strategic Acct');
         acct.Referral_National_Account__c = refAcct.Id;
         updateAcctMap.put(acct.Id,acct);
      }
   } // checkRecord

   private static Map<Id, Opportunity[]> oppByRefCtctIdMap = new Map<Id, Opportunity[]>();

/* 
   public static void checkOpptyTriggerBeforeActions(Opportunity opp, Opportunity oldOpp) {
      if (opp.ReferralContact__c != null 
             && (oldOpp == null || opp.ReferralContact__c != oldOpp.ReferralContact__c || opp.ReferralAccount__c == null )) {
         Opportunity[] oppList = oppByRefCtctIdMap.get(opp.ReferralContact__c);
         if (oppList == null) {
            oppList = new Opportunity[]{};
            oppByRefCtctIdMap.put(opp.ReferralContact__c, oppList);
         }
         oppList.add(opp);
      } // if
   } // checkOpptyTriggerBeforeActions
   
   public static void handleTriggerBeforeActions() {
      if (!oppByRefCtctIdMap.isEmpty()) {
         
      }
   } // handleTriggerBeforeActions
   
   public static void checkRefAcctOnOpps() {
      Contact[] ctcts = [Select Id, AccountId
                           From Contact
                          Where Id in :oppByRefCtctIdMap.keySet()];
      
   } // checkRefAcctOnOpps
   */
} // class OpptyChkReferral