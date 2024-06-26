/* Batch process to clean up the account team member
   
  History
  -------
  09/11/2017 Dan Carmen       Created
  05/03/2019 Dan Carmen       Changes for tests failing
  
 */
global without sharing class AccountTeamMemberBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable{
    
   // The total number of account team members found. 
   global Integer numberATMs = 0;
   
   global Integer numberInternalReferral = 0;
   global Integer numberInactive = 0;
   
   // messages that occur during the process.
   global String processNotes = '';
   
   // used to ensure fields are only added once and to know the owner field
   global Map<String,String> holdOutFldMap = new Map<String,String>();
   
   global JobHelper jh = new JobHelper('AccountTeamMemberBatch');

   global AccountTeamMemberBatch() {
   } // AccountTeamMemberBatch

   public static Boolean CHECK_ACTIVE_FLAG=false;   
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      
      // build the query
      String query = 'Select Id, TeamMemberRole, UserId, User.Id, User.Name, User.IsActive ';
      query += ',Account.Id ';

      holdOutFldMap.clear();
      for (HoldOut_ExpirationDates__c hoed : HoldOut_ExpirationDates__c.getAll().values()) {
         String holdOutFld = hoed.Account_Hold_Out__c;
         if (String.isNotBlank(holdOutFld) && !holdOutFldMap.containsKey(holdOutFld)) {
            query += ' ,Account.'+holdOutFld; 
            String ownerFld = (String.isNotBlank(hoed.Account_Owner__c) ? hoed.Account_Owner__c : 'None');
            if (ownerFld != 'None') {
               query += ' ,Account.'+ownerFld;
            }
            holdOutFldMap.put(holdOutFld, ownerFld);
         }
      } // for (HoldOut_ExpirationDates__c hoed
      
      // make sure there are values before proceeding
      if (!holdOutFldMap.isEmpty()) {
         query += ' From AccountTeamMember Where (TeamMemberRole = \'Internal Referral\' ';
         if (CHECK_ACTIVE_FLAG) {
            query += ' or User.IsActive=true ';
         }
         query += ')';
         return Database.getQueryLocator(query);
      }
      return null;
      /*
      return Database.getQueryLocator([SELECT Id
                                             ,Account.Id
                                             ,Account.OwnerId
                                             ,Account.Hold_Out__c
                                             ,Account.HNBF_Hold_Out__c
                                             ,Account.HNBF_Account_Owner__c
                                             ,Account.HRS_Account_Owner__c
                                             ,Account.HRS_Hold_Out__c
                                             ,Account.MS_Hold_Out__c
                                             ,Account.Premier_PBS_Hold_Out__c
                                             ,Account.Premier_PBS_Account_Owner__c
                                             ,TeamMemberRole
                                             ,UserId
                                             ,User.Id
                                             ,User.Name
                                             ,User.IsActive
                                         FROM AccountTeamMember 
                                        WHERE (TeamMemberRole = 'Internal Referral' 
                                                //or User.IsActive=false
                                                )
                                        ORDER BY CreatedDate ASC]);
      */
   } // start

   // In order to schedule a batch run
   global void execute(SchedulableContext sc) {
      AccountTeamMemberBatch atmb = new AccountTeamMemberBatch();
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('AccountTeamMemberBatch');
      Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 500);
      database.executeBatch(atmb, batchSize);
   } // execute

   // Execute a batch.
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      AccountTeamMember[] atms = (AccountTeamMember[])scope;
      numberATMs += atms.size();
      
      AccountTeamMember[] atmsToDelete = new AccountTeamMember[]{};
      for (AccountTeamMember atm : atms) {
         checkOwners(atm, atmsToDelete);
      }
      // save the AddedToSummary__c flag
      if (!atmsToDelete.isEmpty()) {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         Database.delete(atmsToDelete,false);
         ZipCheckOwner.SKIP_TRIGGERS=false;
      }
   } // execute
   
   global void checkOwners(AccountTeamMember atm, AccountTeamMember[] atmsToDelete) {
      // if the Internal Referral Team Member is not equal to any of the owners (and no holdout) then we'll delete.
      if (CHECK_ACTIVE_FLAG && !atm.User.IsActive) {
         atmsToDelete.add(new AccountTeamMember(Id=atm.Id));
      } else if (atm.TeamMemberRole == 'Internal Referral') {
         Boolean deleteAtm = true;
         Account acct = atm.Account;
         for (String holdOutFld : holdOutFldMap.keySet()) {
            String ownerFldName = holdOutFldMap.get(holdOutFld);
            if (ownerFldName != 'None') {
               Id ownerId = (Id)acct.get(ownerFldName);
               if (ownerId != null && ownerId == atm.UserId) {
                  deleteAtm = false;
                  break;
               }
            } else {
               // if we have a hold out field set without an owner field and it's true, we'll leave the internal referral for now.
               Boolean holdOutValue = (Boolean)acct.get(holdOutFld);
               if (holdOutValue) {
                  deleteAtm = false;
               }
            }
               
         } // for (String holdOutFld
         if (deleteAtm) {
            atmsToDelete.add(new AccountTeamMember(Id=atm.Id));
         }
      }
   } // checkOwners

   global void finish(Database.BatchableContext bc){
      String message = '\nTotal Number of AccountTeamMembers processed: '+numberATMs+' ';
      message += '\n Number Internal Referrals Deleted: '+numberInternalReferral+' ';
      message += '\n Number of Inactive Owners Deleted: '+numberInactive+' ';
      
      message += '\n\n'+processNotes;
      
      jh.completeJob(bc, 'AccountTeamMemberBatch', message);
   } // finish


} // class AccountTeamMemberBatch