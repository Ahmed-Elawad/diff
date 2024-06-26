/** Batch job to check the owner of an account against a referral account

* History
* -------
05/17/2018 Dan Carmen       Created
01/24/2019 Dan Carmen       Add NumberOfEmployees criteria
04/27/2020 Jake Hinds       Changed to use referral account team
08/20/2020 Jake Hinds	    Adding Oasis Hold out 
01/18/2020 Jake Hinds	    Adding extra tracking for debugging
02/08/2021 Matt Fritschi	Query additional fields
12/30/2021 Dan Carmen       Refactor code
11/15/2022 Jaipal           Adding another mode of Lead to query Leads and update the ownership based on Referral Account team

*/
global without sharing class ReferralAccountChkAcctBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    public static final String CLASS_NAME='ReferralAccountChkAcctBatch';
    public static String MODE_ACCT='Account';
    public static String MODE_LEAD='Lead';
    //public static final String BATCH_RFRL_ACCT='ReferralAccountBatch';
    //public static final String BATCH_ACCT='AccountBatch';
        
    global JobHelper jh = new JobHelper(CLASS_NAME);
    
    global Integer numRefAccts = 0;
    global Integer numAccts = 0;
    global Integer holdoutSet = 0;
    global Integer holdoutRemoved = 0;
    global String mode = null;
    
    //global Integer notEligible = 0;
    global Boolean relaunchJob = false;
    global String processNotes = '';
    global Integer queryLimit = 200;
    global Map <Id,String> acctMap = new Map<Id,String>();
    global Map <String,Integer> holdoutReasonCountMap = new Map<String,Integer>();
    global Id[] unableToFindHoldout = new Id[]{};
    global Id[] unableToFindNewOwner = new Id[]{};
    global Set<Id> notEligibleForDedicatedRep = new Set<Id>();
    global Integer accountsCorrectlySet=0;
    
    global Id[] refAcctIds = new Id[]{};
    global Map<Id, Referral_Account__c> refAcctMap;
    
    //global String batchType=BATCH_RFRL_ACCT;
    //    
    global static void launchBatch(String mode) {
        ReferralAccountChkAcctBatch racab = new ReferralAccountChkAcctBatch();
        racab.mode = mode;
        // so we can set a different value for each mode
        Apex_Batch_Control__c abc = getAbc(mode);
        // we want to keep a small batch because of row locks
        Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 200);
        //if (String.isBlank(mode) || mode == MODE_ZIPS) {
        //   batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 10);
        //} else if (mode == CTCT_OWNER || mode == MODE_PO || mode == Mode_Cadence) {
        //   batchSize = ((abc != null && abc.Minutes_till_Launch__c != null) ? (Integer)abc.Minutes_till_Launch__c : 200);
        //}
        
        database.executeBatch(racab, batchSize);
      
    } // launchBatch
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        //jh = new JobHelper(CLASS_NAME+'-'+batchType);
        // save the record - show that the job started
        jh.setStarted();
        // make sure there's a default value
        //batchType = (String.isBlank(batchType) ? BATCH_RFRL_ACCT : batchType);
        
        // how many referral accounts are we selecting at a time for the batch.
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
        queryLimit = ((abc != null && abc.Minutes_till_Launch__c != null) ? (Integer)abc.Minutes_till_Launch__c : 100);
        relaunchJob = false;
        /*
        if (batchType == BATCH_ACCT) {
           // just to reduce the result set since filtering on only a checkbox isn't very efficient
           return Database.getQueryLocator([Select Id, Name
                                              From Account
                                             Where LastModifiedDate >= :dateCheck
                                               and EvaluateRefAcctOwner__c=true]);
        }
        */
        refAcctMap = new Map<Id, Referral_Account__c>([Select Id, DedicatedRepChanged__c
                                                       ,ProcessNotes__c
                                                       From Referral_Account__c
                                                       Where DedicatedRepChanged__c=true
                                                       limit :queryLimit]);
        refAcctIds.addAll(refAcctMap.keySet());
        numRefAccts = refAcctIds.size();
        relaunchJob = numRefAccts >= queryLimit;
        

        Datetime dateCheck = Datetime.now().addDays(-7);
        mode = (String.isBlank(mode) ? MODE_ACCT : mode);
        if(mode == MODE_LEAD){ 
            return Database.getQueryLocator([Select Id, Name
                                         From Lead
                                         Where Referral_Contact__r.Referral_Account__c in :refAcctIds
                                         or Referral_Contact__r.Referral_Account__r.Parent_Referral_Account__c in :refAcctIds
                                         or Referral_National_Account__c in :refAcctIds
                                         or Referral_National_Account__r.Parent_Referral_Account__c in :refAcctIds
                                         or (LastModifiedDate >= :dateCheck and EvaluateRefAcctOwner__c=true)
                                        ]);
                 }
        return Database.getQueryLocator([Select Id, Name
                                         From Account
                                         Where Banker_Name_Ref__r.Referral_Account__c in :refAcctIds
                                         or Banker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__c in :refAcctIds
                                         or CPA_Name_Ref__r.Referral_Account__c in :refAcctIds
                                         or CPA_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__c in :refAcctIds
                                         or Insurance_Broker_Name_Ref__r.Referral_Account__c in :refAcctIds
                                         or Insurance_Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__c in :refAcctIds
                                         or Broker_Name_Ref__r.Referral_Account__c in :refAcctIds
                                         or Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__c in :refAcctIds
                                         or Referral_National_Account__c in :refAcctIds
                                         or Referral_National_Account__r.Parent_Referral_Account__c in :refAcctIds
                                         or (LastModifiedDate >= :dateCheck and EvaluateRefAcctOwner__c=true)
                                        ]);

         
    } // start
    
    // In order to schedule a batch run
    global void execute(SchedulableContext sc) { 
        ReferralAccountChkAcctBatch racab = new ReferralAccountChkAcctBatch();
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
        Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 200);
        database.executeBatch(racab, batchSize);
    } // execute
    
    global static Apex_Batch_Control__c getAbc(String p_mode) {
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(RecordTypeHelper.cleanRtName(CLASS_NAME+p_mode));
        if (abc == null) {
           abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
        }
        return abc;
    } // getAbc
    
    // Execute a batch.
    global void execute(Database.BatchableContext BC, List<SObject> scope){
        Id[] acctIds = new Id[]{};
        if(mode == MODE_ACCT) {
            Account[] accts = (Account[])scope;
        // get the account ids to query the accounts with all the fields. This way the query is only maintained in one place.
        
        Map<Id,Account> acctMap = new Map<Id,Account>(accts);
        acctIds.addAll(acctMap.keySet());
        numAccts += acctIds.size();
                              }
        else if(mode == MODE_LEAD){        
            Lead[] leads = (Lead[])scope;
        // get the account ids to query the accounts with all the fields. This way the query is only maintained in one place.
        Map<Id,Lead> leadmap = new Map<Id,Lead>(leads);
        acctIds.addAll(leadMap.keySet());
        numAccts += acctIds.size();
        }
        ReferralAccountChkAcctOwner.checkRfrlSrcOwnershipNow(acctIds);

        holdoutSet += ReferralAccountChkAcctOwner.holdoutSet;
        holdoutRemoved += ReferralAccountChkAcctOwner.holdoutRemoved;
        
        if(ReferralAccountChkAcctOwner.holdoutReasonCountMap!=null && !ReferralAccountChkAcctOwner.holdoutReasonCountMap.isEmpty()){
            for(String reason: ReferralAccountChkAcctOwner.holdoutReasonCountMap.keySet()){
                if(holdoutReasonCountMap.containsKey(reason)){
					Integer currCount = holdoutReasonCountMap.get(reason);
                    Integer newCount = ReferralAccountChkAcctOwner.holdoutReasonCountMap.get(reason);
                    currCount += newCount;
                    holdoutReasonCountMap.put(reason,currCount);
                }
                else{
                    holdoutReasonCountMap.put(reason,ReferralAccountChkAcctOwner.holdoutReasonCountMap.get(reason));
                }
            }
            holdoutReasonCountMap.putAll(ReferralAccountChkAcctOwner.holdoutReasonCountMap);
        }
        unableToFindHoldout.addAll(ReferralAccountChkAcctOwner.unableToFindHoldout);
        unableToFindNewOwner.addAll(ReferralAccountChkAcctOwner.unableToFindNewOwner);
        notEligibleForDedicatedRep.addAll(ReferralAccountChkAcctOwner.notEligibleForDedicatedRep);
        accountsCorrectlySet+=ReferralAccountChkAcctOwner.accountsCorrectlySet;
    } // execute
    
    global void finish(Database.BatchableContext bc){
        String message = '\nReferral Accounts selected: '+numRefAccts+' '; 
        message += '\nAccount records found: '+numAccts+' ';  
        message += '\nAccount records not eligible: '+notEligibleForDedicatedRep.size()+' '; 
        message += '\nNumber of accounts already correctly set: '+accountsCorrectlySet+' '; 
        message += '\nAccounts holdout Owner Set: '+holdoutSet+' '; 
        message += '\nAccounts holdout Removed: '+holdoutRemoved+' ';
        
        for(String holdout:holdoutReasonCountMap.keySet()){
        	Integer count = holdoutReasonCountMap.get(holdout);
            message += '\nNumber of '+holdout+'(s): '+count+' ';
        }
        
        message += '\n\nSelected Accounts: ';
        for(Id acctId : acctMap.keySet()){
            message += '\nAccount Name:'+acctMap.get(acctId)+' Account Id:'+acctId+' ';
        }
        for(Id acctId:unableToFindHoldout){
            message +='\nUnable to find holdout setting for acct: '+acctId+' ';
        }
        for(Id acctId:unableToFindNewOwner){
            message +='\nUnable to find new owner for acct: '+acctId+' ';
        }
        for(Id acctId:notEligibleForDedicatedRep){
            message +='\nNot eligible for dedicated rep: '+acctId+' ';
        }
        
        // mark the referral accounts as complete so they're not picked up in the batch again.
        Referral_Account__c[] refAcctsToUpdate = new Referral_Account__c[]{};
        for (Referral_Account__c refAcct : refAcctMap.values()) {
           Referral_Account__c updateRfrl = new Referral_Account__c(Id=refAcct.Id, DedicatedRepChanged__c=false, ProcessNotes__c=refAcct.ProcessNotes__c);
           StringHelper.addToProcessNotes(updateRfrl,'Dedicated Rep Changed set to false');
           refAcctsToUpdate.add(updateRfrl);
        }

        ReferralAccountMethods.SKIP_TRIGGERS=true;
        Database.update(refAcctsToUpdate, false);
        message += '\nChanged Dedicated Rep Changed to false on '+refAcctsToUpdate.size()+' Referral Accounts';
        
        message += '\n\n relaunchJob='+relaunchJob+' runningTest='+Test.isRunningTest(); 
        //jh.completeJob(bc, 'Check Referrals Batch '+batchType, message);
        jh.completeJob(bc, 'Check Referrals Batch', message);
        
        // see if we need to relaunch the process
        //if ((relaunchJob || (batchType==BATCH_RFRL_ACCT)) && !Test.isRunningTest()) {
        if (relaunchJob && !Test.isRunningTest()) {
            Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
            if (abc != null && abc.Active__c) {
                Integer batchSize = (abc.BatchSize__c != null ? (Integer)abc.BatchSize__c : 200);
                ReferralAccountChkAcctBatch rab = new ReferralAccountChkAcctBatch();
                //rab.batchType = (relaunchJob ? batchType : BATCH_ACCT);
                Database.executeBatch(rab, batchSize);
            } // if (abc != null
        } // if (relaunchBatch
        if (mode == MODE_ACCT && !Test.isRunningTest()) {
          launchBatch(MODE_LEAD);
        }
    } // finish
    
} // class ReferralAccountChkAcctBatch