/** Batch job to check the owner of an account against a referral account

  AccountZipCodeBatch azcb = new AccountZipCodeBatch();
  Database.executeBatch(azcb, 20);

  Check_Days__c=number of days to look back for record check
  BatchSize__c = batch size for account zip ownership
  Minutes_till_Launch__c = batch size for contact ownership

* History
* -------
  03/04/2022 Dan Carmen       Created
  04/10/2022 Susmitha Somavarapu Daily job is run to re-evaluate all records to ensure that they are updated
*/
global without sharing class AccountZipCodeBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    public static final String CLASS_NAME='AccountZipCodeBatch';
    
    public static final String MODE_ZIPS='UseZipAssignmentRules';
    public static final String CTCT_OWNER='ContactOwnership';
    public static final String MODE_PO='ProspectOwnership';
    public static final String Mode_Cadence = 'CadenceQue'; 
        
    global JobHelper jh = new JobHelper(CLASS_NAME);
    
    global Integer numRecordsFound = 0;
    global Integer nbrUpdated = 0;
    global String mode = null;

    // In order to schedule a batch run
    global void execute(SchedulableContext sc) { 
       launchBatch(MODE_ZIPS);
    } // execute
    
    global static Apex_Batch_Control__c getAbc(String p_mode) {
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(RecordTypeHelper.cleanRtName(CLASS_NAME+p_mode));
        if (abc == null) {
           abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
        }
        return abc;
    } // getAbc
    
    global static void launchBatch(String mode) {
        AccountZipCodeBatch azcb = new AccountZipCodeBatch();
        azcb.mode = mode;
        // so we can set a different value for each mode
        Apex_Batch_Control__c abc = getAbc(mode);
        // we want to keep a small batch because of row locks
        Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 10);
        //if (String.isBlank(mode) || mode == MODE_ZIPS) {
        //   batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 10);
        //} else if (mode == CTCT_OWNER || mode == MODE_PO || mode == Mode_Cadence) {
        //   batchSize = ((abc != null && abc.Minutes_till_Launch__c != null) ? (Integer)abc.Minutes_till_Launch__c : 200);
        //}
        
        database.executeBatch(azcb, batchSize);
      
    } // launchBatch

    global Database.QueryLocator start(Database.BatchableContext BC){
        jh.setStarted();
        
        // get the number of days to query back in time for to limit the result set
        Apex_Batch_Control__c abc = getAbc(mode);
        
        Integer queryDays = (abc != null && abc.Check_Days__c != null ? (Integer)abc.Check_Days__c : 10);
        Datetime queryDate = Datetime.now().addDays(-queryDays);
        
        mode = (String.isBlank(mode) ? MODE_ZIPS : mode);
        
        if (mode == CTCT_OWNER) {
           return Database.getQueryLocator([Select Id, Name, OwnerId, OwnerMismatch__c, LastActivityDate
                                                  ,AccountId, Account.Name, Account.OwnerId, Account.Owner.IsActive
                                                  ,LastModifiedBy.Name 
                                              from Contact 
                                             where (LastModifiedDate > :queryDate or Account.LastModifiedDate > :queryDate)
                                               and Account.Owner.IsActive=true
                                               and OwnerMismatch__c=true and Hold_Out__c=false]);
        } else if (mode == MODE_PO) {
           return Database.getQueryLocator([Select Id, Name, CreatedDate, Decision_Maker__c, Lead__c
                                                  ,DialSource_Action_That_Created_PO__c, ProcessTracker__c,Prospect_Client__c
                                              From Prospect_Ownership__c
                                             Where DialSource_Action_That_Created_PO__c = null
                                               and (Decision_Maker__c != null or Lead__c != null)
                                               and CreatedDate > :queryDate]);
        }
        else if(mode == Mode_Cadence){
           Date closeDateCheck = Date.today().addDays(-queryDays);
           return Database.getQueryLocator([Select Id, Name, CreatedDate, AccountId__c, LeadId__c, ReferralAccount__c from Cadence_Assignment_Record__c 
                                      Where CreatedDate >= :queryDate or Close_Date__c >= :closeDateCheck]);
        }
        
        return Database.getQueryLocator([Select Id, Name, Use_Zip_Assignment_Rules__c
                                           From Account
                                          Where LastModifiedDate >= :queryDate
                                            and Use_Zip_Assignment_Rules__c = true]);

    } // start
    
    global void execute(Database.BatchableContext BC, List<SObject> scope){
       numRecordsFound += scope.size();
       if (mode == MODE_ZIPS) {
          Account[] accts = (Account[])scope;
          nbrUpdated += accts.size();
          DmlHelper.performDML2(accts, DmlHelper.DML_UPDATE, CLASS_NAME, 'execute', 'Update Accounts', true);
       } else if (mode == CTCT_OWNER) {
          Contact[] ctcts = (Contact[])scope;       
          for (Contact ctct : ctcts) {
             ctct.OwnerId = ctct.Account.OwnerId;
          }
          // we can skip the triggers here.
          ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
          ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
          nbrUpdated += ctcts.size();
          DmlHelper.performDML2(ctcts, DmlHelper.DML_UPDATE, CLASS_NAME, 'execute', 'Update Contact Owners', true);
       } else if (mode == MODE_PO) {
          handleProspectOwnership((Prospect_Ownership__c[])scope);
       }
       else if (mode == Mode_Cadence) {
         List<String> quryIds = new List<String>(); 
         for (Cadence_Assignment_Record__c loopRec : (List<Cadence_Assignment_Record__c>)scope) {
            if (loopRec.AccountId__c != null ) {
               quryIds.add(loopRec.AccountId__c);
            }
            if (loopRec.LeadId__c != null ) {
               quryIds.add(loopRec.LeadId__c);
               
            }
            if (loopRec.ReferralAccount__c != null ) {
               quryIds.add(loopRec.ReferralAccount__c);  
            }  
         }
          
         CadenceQueueable caq = new CadenceQueueable(quryIds);
         CadenceQueueable.RUN_INLINE=true;
         CadenceQueueable.launchQueueable(caq);

          
       }
    } // execute
                 
    public static Integer timeOffset = Integer.valueOf(System.Label.DialSourceCreatedDate);

    global void handleProspectOwnership(Prospect_Ownership__c[] pos) {
       Map<Id,Prospect_Ownership__c> updateMap = new Map<Id,Prospect_Ownership__c>();
       ProspectOwnershipMethods.MapDialSourceActionToPO(pos, updateMap);
       nbrUpdated += updateMap.size();
       DmlHelper.performDML2(updateMap.values(), DmlHelper.DML_UPDATE, CLASS_NAME, 'execute', 'Update Contact Owners', true);
    } // handleProspectOwnership
    
    global void finish(Database.BatchableContext bc) {
       String message = 'Mode='+mode;
       message += '\nRecords Found: '+numRecordsFound;
       message += '\nRecords Update: '+nbrUpdated;
       jh.completeJob(bc, 'AccountZipCodeBatch', message);
       if (mode == MODE_ZIPS && !Test.isRunningTest()) {
          launchBatch(CTCT_OWNER);
       } else if (mode == CTCT_OWNER && !Test.isRunningTest()) {
          launchBatch(MODE_PO);
       } else if (mode == MODE_PO && !Test.isRunningTest()) {
          launchBatch(Mode_Cadence);
       }
    } // finish
    
} // class AccountZipCodeBatch