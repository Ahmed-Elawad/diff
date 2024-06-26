/* Trigger Handler for Work Queue Trigger
*
*   HISTORY
*  ---------
*   05/16/2024  Jidesh     Created

*/
public class WorkQueueTriggerHandler {

    //This method checks if the Account workqueue is created
    //If yes, reset the workqueues for other objects
    public static void afterInsertHandler(Map<id,Work_Queue__c> oldMap ,Map<id,Work_Queue__c> newMap){
        System.debug('Inside afterInsertHandler');
        List<Id> accIdList = new List<Id>();
        for(Work_Queue__c newRec : newMap.values()){
            if(newRec.Object__c == ObjectHelper.OBJECT_ACCOUNT){
                accIdList.add(newRec.Account_ID__c);
            }
        }
        if(accIdList.size()>0){
            System.debug('Inside afterInsertHandler calling resetWorkquesForAccount');
            resetWorkquesForAccount(accIdList);
        }
    }
    
    //This method sets all the workqueue completed status to false when an account Worqueue is created.
    public static void resetWorkquesForAccount(List<Id> Accounts) {
        System.debug('Inside resetWorkquesForAccount');
        List<Id> accIdList = new List<Id>();
        accIdList = Accounts;
        Work_Queue__c[] refreshWorkQueues = new Work_Queue__c[]{};
        System.debug('resetWorkquesForAccount accIdList:'+accIdList);   
        List<Work_Queue__c> queues = [SELECT Account_ID__c,Completed__c,Id,Name,Object_Record_ID__c,Object__c FROM Work_Queue__c WHERE Completed__c = true AND Account_ID__c IN: accIdList AND Object__c != 'Account']; 
        System.debug('resetWorkquesForAccount queues:'+queues);    
        if(queues.size()>0){
            for(Work_Queue__c wqs: queues){
                wqs.Completed__c = false;
                refreshWorkQueues.add(wqs);
            }   
            if(refreshWorkQueues.size()>0){
                DmlHelper.performDML2(refreshWorkQueues, DmlHelper.DML_UPDATE, 'WorkQueueTriggerHandler', 'resetWorkquesForAccount', 'Refreshing related Workqueues', true);
            }
        }
    }
}