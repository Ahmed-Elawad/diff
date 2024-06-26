/* 
 * Set ASO Ownership on Accounts Owned by MMS rep when ASO Partner is set.
 *
 * History
 * -------
 * 05/21/2018 Jake Hinds    Created
 * 03/07/2020 Jake Hinds    Adding in SMB
 * 05/18/2021 Jermaine Stukes	Add HRS Partner logic
   08/09/2021 Dan Carmen        Rewrite for efficiency

 */

public with sharing class MMSASOPartnerQueueable implements Queueable{
    
    public static String CLASSNAME='MMSASOPartnerQueueable';
            
    public User[] owners;
    //public Integer rowLimit = Integer.valueOf(Label.MMSASOPartnerQueueableRowLimit);
    public Integer attemptNbr = 1;
    
    public MMSASOPartnerQueueable(User[] p_owners){
        owners = p_owners;
    }//MMSASOPartnerQueueable  

   public void execute(QueueableContext context) {
      //remove rep from stack.  if query limit is hit, add user back into the stack to finish processing
      User owner = (owners != null && !owners.isEmpty() ? owners.remove(0) : null);
      if (owner == null) {
         return;
      }
      //create job tracker to track job
      Job_Tracker__c jt= new Job_Tracker__c(Process_Start__c=system.now(),Job_Name__c = CLASSNAME);
      jt.Job_Id__c = owner.Id;
      jt.Notes__c = 'Processing user: '+owner.Id+' attemptNbr='+attemptNbr+' owners='+owners.size();
      jt.Nbr_Batches__c = 0;
      jt.Nbr_Errors__c = 0;  

      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      Integer rowLimit = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 500);

      Boolean skipTriggers = (owner.HR_Services_Partner__c != null);
      Account[] searchAccts = null;
       
      Id mmsRTID = RecordTypeHelper.getRecordType(Label.RT_MMS_Account,'Account').getRecordTypeId();
      Id smbRTID = RecordTypeHelper.getRecordType(Label.RT_Core_Account,'Account').getRecordTypeId();
      Id[] rtIds = new Id[]{mmsRTId,smbRTId};
                
      //if HR Services Partner is null, find accounts owned by rep which had previously been set with partner
      if (owner.HR_Services_Partner__c != null) {
         searchAccts = [Select Id, Premier_PBS_Account_Owner__c, Premier_PBS_Hold_Out__c, Premier_PBS_Hold_Out_Expiration__c
                              ,PEO_ASO_Permanent_Hold_Out_Description__c
                          From Account
                         Where OwnerId = :owner.Id
                           and Owner.HR_Services_Partner__c != null
                           and CurrentClient__c = false
                           and Premier_PBS_Hold_Out__c = false
                           and RecordTypeId in :rtIds
                           and Id in (Select AccountId from Opportunity
                                       Where OwnerId = :owner.Id
                                         and OpportunityType__c = 'Payroll' and isClosed = false)
                        limit :rowLimit]; 
             /*
                acctsToUpdate = [SELECT Id,(Select Id,OwnerId
                                            From Opportunities
                                            Where OwnerId =: owner.Id and OpportunityType__c = 'Payroll' and isClosed = false)
                                 From Account WHERE OwnerID = :owner.Id AND Owner.HR_Services_Partner__c != null 
                                           AND CurrentClient__c = false and Premier_PBS_Hold_Out__c = false LIMIT :rowLimit];
       */
       } else {
        
          String[] holdoutReasons = new String[]{Label.Account_Partnership_Holdout_Reason, Label.Account_HR_Partnership_Holdout_Reason};
          //May need to incorporate Current Non Payroll Client field
          searchAccts = [Select ID, Premier_PBS_Account_Owner__c, Premier_PBS_Hold_Out__c, Premier_PBS_Hold_Out_Expiration__c
                              ,PEO_ASO_Permanent_Hold_Out_Description__c
                           From Account 
                          WHERE OwnerID = :owner.Id 
                            AND RecordTypeId in:rtIds 
                            AND CurrentClient__c = false
                            AND Premier_PBS_Hold_Out__c = true AND PEO_ASO_Permanent_Hold_Out_Description__c in :holdoutReasons LIMIT :rowLimit];
              /*
                    acctsToUpdate = [SELECT ID From Account WHERE OwnerID = :owner.Id AND RecordTypeId in:rtIds AND CurrentClient__c = false
                                     AND Premier_PBS_Hold_Out__c = true AND PEO_ASO_Permanent_Hold_Out_Description__c in:holdoutReasons LIMIT :rowLimit];
              */
       } // if (owner.HR_Services_Partner__c != null
       
       // if there are too many accounts selected, continue to process
       if (searchAccts !=null && searchAccts.size( )>=rowLimit ) {
          owners.add(owner);
       }
       
       if (searchAccts != null && !searchAccts.isEmpty()) {
          jt.Nbr_Batches__c = searchAccts.size();
          for (Account acct : searchAccts) {
             if (owner.HR_Services_Partner__c != null){
                acct.Premier_PBS_Account_Owner__c = owner.HR_Services_Partner__c;
                acct.Premier_PBS_Hold_Out__c = true;
                acct.Premier_PBS_Hold_Out_Expiration__c = null;
                acct.PEO_ASO_Permanent_Hold_Out_Description__c = Label.Account_HR_Partnership_Holdout_Reason;
             } else {
                //if no partner set, remove holdout
                acct.Premier_PBS_Account_Owner__c = null;
                acct.Premier_PBS_Hold_Out__c = false;
                acct.PEO_ASO_Permanent_Hold_Out_Description__c = null;
                acct.Use_Zip_Assignment_Rules__c = true;
             }
         } // for (Account acct : searchAccts
         jt.Notes__c += '\nTotal Accts processed: '+ searchAccts.size();
         try {
            ZipCheckOwner.SKIP_TRIGGERS=skipTriggers;
            update searchAccts;
         } catch (DMLException e) {
            //loop through and capture any errors, add to notes
            for (Integer i = 0; i < e.getNumDml(); i++) {
               Id acctId = searchAccts[e.getDMLIndex(i)].Id; 
               jt.Notes__c += '\n Error at Id:'+acctId+' - '+e.getDMLMessage(i);
               jt.Nbr_Errors__c ++;
            } // for (Integer i = 0; i < e.getNumDml(); i++
         } // try
      } else {
         jt.Notes__c += '\nNo Accts found';
      } // if (searchAccts != null && !searchAccts.isEmpty
        

        //kick another job off to process the next rep in line.  Use the Apex_Batch_Control__c to allow to chain jobs. 
        Integer nbrAttempts = (abc != null && abc.NbrOfAttempts__c != null ? Integer.valueOf(abc.NbrOfAttempts__c) : 10);
        if (!owners.isEmpty() && abc != null && abc.Active__c && attemptNbr <= nbrAttempts) {
            jt.Notes__c += '\n Hit Limit, requeuing list';
            MMSASOPartnerQueueable mapq = new MMSASOPartnerQueueable(owners);
            mapq.attemptNbr = attemptNbr+1;
            System.enqueueJob(mapq);
        }
        jt.Status__c = 'Completed' + (jt.Nbr_Errors__c > 0 ? ' With Errors' : '');
        //jt.Job_Id__c = context.getJobId();
        jt.Process_End__c = system.now();
        insert jt;
    } //execute
    
} // class MMSASOPartnerQueueable