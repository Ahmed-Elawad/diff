/**
 * Methods for checking duplicates with opportunities
 
 
  History
  -------
  10/25/2017 Dan Carmen        Created
  10/10/2018 Dan Carmen        Add additional logging
  11/01/2018 Dan Carmen        Add Employees_Paid_Per_Payroll__c to opp query
  10/26/2021 Dan Carmen        Add logic for Product Groups
  
 */
public without sharing class OpptyDupeCheck {
   
   public static Opportunity dupeOpp = null;
   public static Boolean LOG_DATA=(Label.CampaignInfluenceHelper_LogData == 'Y');
   public static ErrorLog__c errLog = new ErrorLog__c();

   //public static String[] EXCLUDE_TYPES = Label.OpptyDupe_ExcludeTypes.split(',');
   public static Set<String> EXCLUDE_TYPE_SET = new Set<String>(Label.OpptyDupe_ExcludeTypes.split(','));
   
   // TODO - have to exclude internal referrals - should this be done from the calling code?
   // Called from ReferralMethods and CreateOppAndMeeting
   public static Opportunity[] dupeOpps(Opportunity oppToCheck) {
      String logDetail = 'oppToCheck='+(oppToCheck != null ? oppToCheck.RecordTypeId+'; '+oppToCheck.OpportunityType__c : 'null');
      errLog = ErrorLog.logError('OpptyDupeCheck', 'dupeOpps', 'LOG_DATA', null, logDetail, null, false);
      Opportunity[] dupeOpps = new Opportunity[]{};
      dupeOpp = null;
      if (oppToCheck != null && !oppToCheck.isClosed 
             && String.isNotBlank(oppToCheck.OpportunityType__c)
             && !EXCLUDE_TYPE_SET.contains(oppToCheck.OpportunityType__c)
          ) {
          if (oppToCheck.Id == null) {
             // we want to reference the ProductGroupByOpptyType__c formula so make sure it's calculated
             List<FormulaRecalcResult> results = Formula.recalculateFormulas(new Opportunity[]{oppToCheck});
          }
         // check if this is a record type we're going to check
         Schema.RecordTypeInfo rtInfo = OpptyMethods.getRtInfo(oppToCheck.RecordTypeId);
         Boolean doWeCheck = doWeCheckForDupes(oppToCheck, (rtInfo != null ? rtInfo.getName() : null));
         System.debug('dupeOpps doWeCheck='+doWeCheck);
         ErrorLog.addToDescription(errLog,'doWeCheck='+doWeCheck);
         if (doWeCheck) {
            // find the record types we're going to check against
            Id[] recordTypeIds = getRecordTypesToCheckAgainst(oppToCheck);
            ErrorLog.addToDescription(errLog,'recordTypeIds='+recordTypeIds.size());
            errLog.NbrFailure__c = recordTypeIds.size();
            //if (!recordTypeIds.isEmpty()) {
               dupeOpps = getMatchingOpps(oppToCheck, recordTypeIds);
            //}
         } // if (doWeCheck

      } // if (oppToCheck != null
      if (LOG_DATA) {
         //ErrorLog__c errLog = ErrorLog.logError('OpptyDupeCheck', 'dupeOpps', 'LOG_DATA', null, v_runLog, null, true);
         ErrorLog.checkSave();
      }

      return dupeOpps;
   } // dupeOpps
   
   public static Boolean doWeCheckForDupes(Opportunity opp, String recordTypeName) {
      Boolean checkForDupes = false;
      if (String.isNotBlank(recordTypeName)) {
         RecordType__c rtSetting = RecordTypeHelper.getRtSetting(recordTypeName);
         checkForDupes = (rtSetting != null && rtSetting.CheckForOppDupes__c);
      }
      return checkForDupes;
   } // doWeCheckForDupes
   
   public static Id[] getRecordTypesToCheckAgainst(Opportunity opp) {
      return getRecordTypesToCheckAgainst(opp.RecordTypeId);
   } // getRecordTypesToCheckAgainst
   
   public static Id[] getRecordTypesToCheckAgainst(Id recordTypeId) {
      Id[] idsToCheck = new ID[]{};
      OpptyCheckJoin.checkMatchingRTIdSetMap();
      if (recordTypeId != null) {
         idsToCheck.addAll(OpptyCheckJoin.matchingRTIdSetMap.get(recordTypeId)); 
      }
      return idsToCheck;
   } // getRecordTypesToCheckAgainst
   
   public static Opportunity[] getMatchingOpps(Opportunity opp, Id[] recordTypeIds) {
      System.debug('getMatchingOpps opp.AccountId='+opp.AccountId+' oppType='+opp.OpportunityType__c+' recordTypeIds='+recordTypeIds.size());
      // make sure we have an account to query against
      if (opp.AccountId != null && String.isNotBlank(opp.OpportunityType__c) && !recordTypeIds.isEmpty()) {
         Id[] excludeIds = new Id[]{};
         // if the record already has an id, make sure we don't reselect it.
         if (opp.Id != null) {
            excludeIds.add(opp.Id);
         }
         Opportunity[] queriedOpps = queryOpps(opp.AccountId, excludeIds);
         System.debug('getMatchingOpps queriedOpps='+queriedOpps.size());

         return getMatchingOpps(opp, queriedOpps, recordTypeIds);
      } // if (opp.AccountId != null &&
      return new Opportunity[]{};
   } // getMatchingOpps
   
   public static Opportunity[] getMatchingOpps(Opportunity checkOpp, Opportunity[] queriedOpps, Id[] recordTypeIds) {
      Opportunity[] matchingOpps = new Opportunity[]{};
      System.debug('getMatchingOpps checkOpp.OpportunityType__c='+checkOpp.OpportunityType__c);
      if (String.isNotBlank(checkOpp.OpportunityType__c)) {
         for (Opportunity queryOpp : queriedOpps) {
            if ((recordTypeIds.contains(queryOpp.RecordTypeId) && queryOpp.OpportunityType__c == checkOpp.OpportunityType__c)
                || (checkOpp.EvaluateProductGroup__c && String.isNotBlank(checkOpp.AdditionalProductsOfInterest__c) && String.isNotBlank(queryOpp.ProductGroupByOpptyType__c)
                          && checkOpp.AdditionalProductsOfInterest__c.contains(queryOpp.ProductGroupByOpptyType__c))
                || (queryOpp.EvaluateProductGroup__c && String.isNotBlank(queryOpp.AdditionalProductsOfInterest__c) && String.isNotBlank(checkOpp.ProductGroupByOpptyType__c)
                          && queryOpp.AdditionalProductsOfInterest__c.contains(checkOpp.ProductGroupByOpptyType__c))
                ) {
               System.debug('getMatchingOpps added '+queryOpp.Name+ 'to matchingOpps');
               matchingOpps.add(queryOpp);
            }
         }
      } // if (String.isNotBlank
      errLog.NbrSuccess__c = matchingOpps.size();
      return matchingOpps;
   } // getMatchingOpps
   
   public static Opportunity[] queryOpps(Id accountId, Id[] excludeIds) {
      excludeIds = (excludeIds == null ? new Id[]{} : excludeIds);
      Opportunity[] opps = [Select Id, Name, LastActivityDate, Probability, RecordTypeId
                               ,AccountId, Account.Name, Account.LastActivityDate
                               ,CreatedDate, CreatedById
                               ,Employees_Paid_Per_Payroll__c
                               ,NSS_Source__c, LeadSource, StageName, CloseDate
                               ,OpportunityType__c
                               ,OwnerId, Owner.Id, Owner.ManagerId, Owner.DSA_FSS__c
                               ,AdditionalProductsOfInterest__c, EvaluateProductGroup__c, ProductGroupsSelected__c, ProductGroupByOpptyType__c
                           From Opportunity
                          Where AccountId = :accountId
                            //and RecordTypeId in :recordTypeIds
                            and Id not in :excludeIds
                            and IsClosed = false
                          order by Probability desc, CreatedDate desc
                        ];
      System.debug('queryOpps opps='+opps.size()+' accountId='+accountId);
      errLog.ObjectId__c = accountId;
      errLog.BatchSize__c = opps.size();
      ErrorLog.addToDescription(errLog,'queryOpps opps='+opps.size()+' accountId='+accountId +' excludeIds='+excludeIds);
      if (opps.size() > 0) {
         ErrorLog.addToDescription(errLog,'opp='+opps[0]);
      }
      return opps;
   } // queryOpps
      
} // class OpptyDupeCheck