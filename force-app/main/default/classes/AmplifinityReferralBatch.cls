/* 
 * Batch job for amplifinity referrals
 * History
 * -------
 * 09/04/2019 Josh Cartwright  created
 *  
 */
global with sharing class AmplifinityReferralBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable {
   global static final String CHECKAMPREFERRAL_BATCH='CheckAmplifinityReferralBatch';
   global date dateToCheck = system.today().adddays(-120);        

   // The total number of purge records found.
   global Integer numberRecs = 0;
   
   // The total number of records purged
   global Integer numberRecsSuccess = 0;
   global Integer numberRecsError = 0;
   /** The time the process started. */
   global DateTime startTime;
   
   // messages that occur during the process. 
   global String processNotes = '';
   
   global JobHelper jh = new JobHelper(CHECKAMPREFERRAL_BATCH);
   
   // if we hit a limit, do we want to relaunch the batch job?
   global Boolean relaunchBatch = false;
       
    global string notSold = '';
	//global string sold = 'Successful'; 
    
    global AmplifinityReferralBatch() {
        
    }
    global Map<String,Amplifinity_AR_Status_Mapping__mdt> statusMap = new Map<String,Amplifinity_AR_Status_Mapping__mdt>();
    
    /* moved to AmplifinityHelper
    global Map<String,Amplifinity_AR_Status_Mapping__mdt> setupStatusMap() {
        Amplifinity_AR_Status_Mapping__mdt[] statusMapping = [select MasterLabel, label, AR_Status__c, AMP_Status__c, Allow_Updates__c,IsClosedStatus__c from Amplifinity_AR_Status_Mapping__mdt]; // where label ='Not sold']; 
        for (Amplifinity_AR_Status_Mapping__mdt ampStatus : statusMapping) {
            statusMap.put(ampStatus.AMP_Status__c,ampStatus);
            if (ampStatus.label == 'Not Sold') {
                notSold =ampStatus.AMP_Status__c;
            }//if
        }//for
        return statusMap;
    } // setupStatusMap
    */
	global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      // todo - add a "closed status" checkbox
      //setupStatusMap();
      AmplifinityHelper.checkAmpMaps();
      statusMap = AmplifinityHelper.statusMap;
      notSold = AmplifinityHelper.notSoldStatus;
      system.debug('JC notSold '+ notSold); 
  //use custom meta data closed to only pull in those 120 days old and open 
      //string query = 'Select id , amp_dev__Opportunity__c, amp_dev__Opportunity__r.StageName, amp_dev__Lead__r.IsConverted, createdDate, amp_dev__Status__c from amp_dev__Amp_Referral__c where  createdDate <: dateToCheck and amp_dev__Status__c not like\''+sold+'\' and amp_dev__Status__c !=\'' + notSold+'\'';
        jh.setStarted();
      return Database.getQueryLocator([select id 
                                      , amp_dev__Opportunity__c
                                      , amp_dev__Opportunity__r.StageName
                                      , amp_dev__Lead__r.IsConverted
                                      , createdDate, amp_dev__Status__c
                                      from amp_dev__Amp_Referral__c
                                      where createdDate <: dateToCheck 
                                      and Open_Close_Status__c = 'Open'
                                      ]);
                                                                   
      } // start    
    
  global void execute(SchedulableContext sc) { 
      AmplifinityReferralBatch arb = new AmplifinityReferralBatch();
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CHECKAMPREFERRAL_BATCH);
      Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 200);
      database.executeBatch(arb, batchSize);
   } // execute
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<amp_dev__Amp_Referral__c> aRList = (List<amp_dev__Amp_Referral__c>)scope;
      amp_dev__Amp_Referral__c[] updateRefs = new amp_dev__Amp_Referral__c[]{};          
      numberRecs += aRList.size();
      system.debug('JC aRList '+ aRList);
      system.debug('JC updateRefs '+ updateRefs); 
      checkStatus(aRList,updateRefs); 

      DmlHelper.performDML2(aRList, DmlHelper.DML_UPDATE, 'CheckAmplifinityReferralBatch', 'execute', 'update the Referral records', true);
       
      numberRecsSuccess += DmlHelper.performDmlResult.nbrSuccess;
      numberRecsError += DmlHelper.performDmlResult.nbrError;
   } // execute
	
    public void checkStatus(amp_dev__Amp_Referral__c[] aRList, amp_dev__Amp_Referral__c[] updateRefs){
        //check referrals, opportunity is not sold, set referral to unsuccessful 
        for(amp_dev__Amp_Referral__c aR : aRList){
           Amplifinity_AR_Status_Mapping__mdt ampStatus = statusMap.get(aR.amp_dev__Status__c);
            // todo - create a close reason field on the amp referral -done
             ar.Open_Close_Status__c = 'Closed'; 
            system.debug ('jc ar.Open_Close_Status__c = ' + ar.Open_Close_Status__c ); 
            if (ampStatus == null) {
                ar.Close_Reason__c = 'Status Not Found';
                // we couldn't find a matching status
                // close the referral and change the close reason to "Status not found"
            }//if
                        // else if the status is not a closed status
                        // change the status to not sold
                		// close reason to exceeded SLA
                else if(!ampstatus.IsClosedStatus__c ){
                    ar.amp_dev__Status__c = notSold; 
					ar.Close_Reason__c = 'Exceeded SLA';                    
                }//else if 
        }//for 
    }//checkStatus
    
	  global void finish(Database.BatchableContext bc){
      String message = '\nTotal recors selected: '+numberRecs+' '; 
      message += '\nTotal records success: '+numberRecsSuccess+' '; 
      message += '\nTotal records error: '+numberRecsError+' '; 
      //message += '\nTotal Users updated: '+nbrUsersUpdated+' '; 
      
      message += '\n\n'+processNotes;
      
      jh.completeJob(bc, 'Check Amplifinity Referrals Batch', message);
     

 
   } // finish
    
}//AmplifinityReferralBatch