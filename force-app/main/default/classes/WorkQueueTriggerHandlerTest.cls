/* Test Methods for WorkQueueTriggerHandler

History
-------
05/21/2024 Jidesh        Created

*/

@isTest
public class WorkQueueTriggerHandlerTest {
    
    static testMethod void testResetWorkques(){
        User nonCsUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and CSUserId__c = null limit 1];
        Account acct1 = new Account(Name='Account1', OwnerId=nonCsUser.Id, SendToClientSpace__c=false);
        insert acct1;
        Contact ctct1 = new Contact(AccountId=acct1.Id, OwnerId=acct1.OwnerId, LastName='Ctct1', CSContactId__c='234', Sales_Contact__c=true);
        insert ctct1;
        Work_Queue__c wqc = new Work_Queue__c(Object_Record_ID__c=ctct1.Id, Contact_ID__c=ctct1.Id, Account_ID__c=(acct1!= null ? acct1.Id : null), Object__c=ObjectHelper.OBJECT_CONTACT);
        wqc.Completed__c=true;
        insert wqc;
        Work_Queue__c wq = new Work_Queue__c(Completed__c=false, Object_Record_ID__c=acct1.Id, Contact_ID__c=ctct1.Id, Account_ID__c=(acct1 != null ? acct1.Id : null), Object__c=ObjectHelper.OBJECT_ACCOUNT);
        insert wq;
        Integer queuesCnt = [select count() from Work_Queue__c where Completed__c = false and Account_ID__c=: acct1.Id];
        System.assertEquals(2,queuesCnt);
    }
}