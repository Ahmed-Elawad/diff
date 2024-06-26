/* 
 * A Helper class for checking duplicates in code
 *
 * History
 * -------
   11/16/2022 Dan Carmen        Created
 
 */
public class DuplicateHelper {
   
   public class DupeResult{
      public Boolean success=false;
      public Account[] accts = new Account[]{};
      public Lead[] leads = new Lead[]{};
      public Contact[] ctcts = new Contact[]{};
      public SObject[] otherRecs = new SObject[]{};
      public Id[] acctIds = new Id[]{};
      public Id[] leadIds = new Id[]{};
      public Id[] ctctIds = new Id[]{};
      public Id[] refAcctIds = new Id[]{};
      public Id[] refCtctIds = new Id[]{};
      public Id[] otherIds = new Id[]{};
      public Boolean hasResults{
         get {
             System.debug('DupeResult acctIds='+acctIds.size()+' leadIds='+leadIds.size()+' ctctIds='+ctctIds.size()+' refAcctIds='+refAcctIds.size()+' refCtctIds='+refCtctIds.size()+' otherIds='+otherIds.size());
             return (!acctIds.isEmpty() || !leadIds.isEmpty() || !ctctIds.isEmpty() || !otherIds.isEmpty() || !refAcctIds.isEmpty() || !refCtctIds.isEmpty());
         }
      }
      public Integer nbrResults{
         get {return (acctIds.size()+leadIds.size()+ctctIds.size()+otherIds.size()+refAcctIds.size()+refCtctIds.size());}
      }
   } // class DupeResult
    
   public static Integer dupeBatchSize = 50;
    
   public static DupeResult[] findDuplicates(SObject[] searchRecs) {
      System.debug('findDuplicates searchRecs='+searchRecs.size());
      DupeResult[] results = new DupeResult[]{};
      if (searchRecs.size() <= dupeBatchSize) {
         results = findDuplicates2(searchRecs);
      } else {
         SObject[] batchRecs = new SObject[]{};
         for (integer cnt=0; cnt<searchRecs.size(); cnt++) {
            batchRecs.add(searchRecs[cnt]);
            if (batchRecs.size() >= dupeBatchSize) {
               DupeResult[] theseResults = findDuplicates2(batchRecs);
               results.addAll(theseResults);
               batchRecs.clear();
            }
         } // for (integer cnt=0; cnt<searchRecs.size(); cnt++
         // final check of the records.
         if (batchRecs.size() > 0) {
            DupeResult[] theseResults = findDuplicates2(batchRecs);
            results.addAll(theseResults);
         }

      }
      return results;
   } // findDuplicates
   
   public static DupeResult[] findDuplicates2(SObject[] searchRecs) {
      System.debug('findDuplicates2 searchRecs='+searchRecs.size());
      Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(searchRecs);
      DupeResult[] returnResults = new DupeResult[]{};
      //System.debug('results='+results);
      for (Datacloud.FindDuplicatesResult result : results) { 
          DupeResult retResult = new DupeResult();
          returnResults.add(retResult);
          System.debug('findDuplicates success='+result.success);
          retResult.success = result.success;
          Datacloud.DuplicateResult[] theseResults = result.duplicateresults;
          for (Datacloud.DuplicateResult thisResult : theseResults) {
             System.debug('findDuplicates dupeRule='+thisResult.getDuplicateRule());
	         //System.debug('matchResults='+thisResult.getMatchResults());
	         for (Datacloud.MatchResult matchRes : thisResult.getMatchResults()) {
	            System.debug('findDuplicates entityType='+matchRes.getEntityType()+' numDupes='+matchRes.getSize());
                for (Datacloud.MatchRecord matchRec : matchRes.getMatchRecords()) {
                   System.debug('findDuplicates confidence='+matchRec.getMatchConfidence());
			       SObject rec = matchRec.getRecord();
                   System.debug('findDuplicates recType='+rec.getSObjectType()+' rec='+rec);
                   if (rec.getSObjectType() == Lead.sObjectType) {
                       retResult.leads.add((Lead)rec);
                       retResult.leadIds.add(rec.Id);
                   } else if (rec.getSObjectType() == Contact.sObjectType) {
                       retResult.ctcts.add((Contact)rec);
                       retResult.ctctIds.add(rec.Id);
                   } else if (rec.getSObjectType() == Account.sObjectType) {
                       retResult.accts.add((Account)rec);
                       retResult.acctIds.add(rec.Id);
                   } else if (rec.getSObjectType() == Referral_Account__c.sObjectType) {
                       retResult.refAcctIds.add(rec.Id);
                   } else if (rec.getSObjectType() == Referral_Contact__c.sObjectType) {
                       retResult.refCtctIds.add(rec.Id);
                   } else {
                       retResult.otherRecs.add(rec);
                       retResult.otherIds.add(rec.Id);
                   }
		        } // for (Datacloud.MatchRecord matchRec
	  
	         } // for (Datacloud.MatchResult matchRes
	  
          } // for (DuplicateResult thisResult
      } // for (Datacloud.FindDuplicatesResult result

      return returnResults;
   } // findDuplicates
    
   // get the DML options to allow a save even if it hits the duplicate rules.
   public static Database.DMLOptions getDmlSkipCheck() {
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true; 
      return dml;
   } // getDmlSkipCheck
    
} // class DuplicateHelper