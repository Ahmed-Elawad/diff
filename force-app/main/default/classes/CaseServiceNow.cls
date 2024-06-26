/* 
 * Case updates needed for Service Now integration
 *
 * History
 * -------
 * 09/23/2013 Cindy Freeman   Created
 * 01/31/2014 Justin Stouffer Updated to run CaseServiceNowBatch to send cases to ServiceNow.
   04/09/2020 Dan Carmen      Remove call to AccountHelper.getRecordType
   12/09/2021 Jake Hinds   Removing supervisor alert checkbox

 */

public without sharing class CaseServiceNow {

    public static void serviceNowUpdates(Id[] caseIds) {
        
        List<Case> updateList = new List<Case>();
        
        Case[] caseList = [Select Id, OwnerId
                                    , RecordTypeId
                                    , Service_Now_Affected_User__c
                                    , Service_Now_Caller__c
                                    , Service_Now_Client_ID__c
                                    , Originator__c
                                    , Account.AccountNumber
                                    , Originator__r.Email
                                    , Owner.Email
                                    , SupervisorAlert__c
                                    , Send_Case_to_Service_Now__c
                                    , Sent_Case_to_Service_Now__c
                                    from Case where Id in :caseIds 
                                    and Send_Case_to_Service_Now__c = TRUE
                                    and Sent_Case_to_Service_Now__c = FALSE];
        if (caseList.size() > 0)
        {   for (Case kase : caseList)
            {   if (kase.Service_Now_Affected_User__c != kase.Originator__r.Email ||
                    kase.Service_Now_Caller__c != kase.Owner.Email ||
                    kase.Service_Now_Client_ID__c != kase.Account.AccountNumber)
                {   kase.Service_Now_Affected_User__c = kase.Originator__r.Email;
                    kase.Service_Now_Caller__c = kase.Owner.Email;
                    kase.Service_Now_Client_ID__c = kase.Account.AccountNumber;
                    updateList.add(kase);
                } // if 
                /*if(kase.Send_Case_to_Service_Now__c && !kase.Sent_Case_to_Service_Now__c){
                    CaseServiceNow.kickOffBatchJob();
                }*/               
             } // for
             if (updateList.size() > 0)
             {  update caseList;    }
             CaseServiceNow.kickOffBatchJob();
        } // if size>0
        
    } // serviceNowUpdates
    
    public static void kickOffBatchJob(){
        Apex_Batch_Control__c apexCS = Apex_Batch_Control__c.getInstance('CaseServiceNowBatch');
        if (apexCS != NULL && apexCS.Active__c){
            CaseServiceNowBatch sc = new CaseServiceNowBatch();
            boolean jobScheduled = FALSE;
            //check if there are 5 active batch jobs
            list<AsyncApexJob> asyncJobList = [SELECT ApexClassID, ApexClass.Name, Status, CreatedDate
                                                 FROM AsyncApexJob 
                                                WHERE JobType='BatchApex' 
                                                AND (Status = 'Processing' 
                                                OR Status = 'Preparing'
                                                OR Status = 'Queued'
                                                OR Status = 'Holding')];
            if(!asyncJobList.isEmpty()){                
                For(AsyncApexJob a: asyncJobList){
System.debug('**CMF ** asyncApexJob status='+a.Status+' ApexclassId='+a.ApexClassId+' createdDate='+a.CreatedDate);
                    if (a.ApexClass.Name == 'CaseServiceNowBatch'){
                        jobScheduled = TRUE;
                    }   
                }
            }
            If(!jobScheduled){
                //if (asyncJobList.size() < 5){//5 is maximum number of concurrent batch job limit.
                    try{
                        Database.executeBatch(sc);    
                    } 
                    catch(AsyncException e) {
                        System.debug('The following exception has occurred: ' + e.getMessage());
                    } //Don't do anything if there is an exception when kicking off the batch
                /*}
                else {
                    try{
                       System.scheduleBatch(sc, 'CaseServiceNowBatch', 15);// Schedule to start in 15 minutes to stay below concurrent Batch job limit.
                    } 
                    catch(AsyncException e) {
                        System.debug('The following exception has occurred: ' + e.getMessage());
                    } //Don't do anything if there is an exception when kicking off the batch
                }*/
            }
        }
    }
}