/* 
 * 
 *
 * History
 * -------
   01/25/2024 Dan Carmen       Increment API version

 */
@isTest
public with sharing class UnsubscribeEmailControllerTest {

    static testMethod void updateRecordTest(){
        String emailAdd = 'Unsubscribe@paychextest.com';
        Account acc = new Account(name='testacc', Email__c=emailAdd, Email_Opt_Out__c=FALSE);
        insert acc;
        Lead ld = new Lead(FirstName ='firstTest',LastName ='lastTest', Company='testCompany',Email=emailAdd, HasOptedOutOfEmail=FALSE);
 		insert ld;
                                  
        User u = [select id from user where usertype='Guest' limit 1];
        
        system.runAs(u){
            UnsubscribeEmailController.updateRecord(emailAdd);        
        }
        Reference_Do_Not_Contact__c refDNC = [SELECT Id, Contact_Email__c from Reference_Do_Not_Contact__c WHERE Contact_Email__c=:emailAdd LIMIT 1];
        System.debug('refDNC:'+refDNC);
        system.assertEquals(emailAdd, refDNC.Contact_Email__c);
        Account acct1 = [Select Id, Email_Opt_Out__c from Account Where Email__c=:emailAdd];
        Lead ld1 = [Select Id, HasOptedOutOfEmail from Lead Where Email=:emailAdd];
        System.debug('acc: '+acct1+ ' ld:'+ld1);
        
        Set<Id> idSet = new Set<Id>{refDNC.Id};
        ReferenceDNCEmailHelper.processRecords(idSet);
                                  
        Account acct2 = [Select Id, Email_Opt_Out__c from Account Where Email__c=:emailAdd];
        Lead lead2 = [Select Id, HasOptedOutOfEmail from Lead Where Email=:emailAdd];
        
        
    }

    static testMethod void sendEmailTest(){
        Reference_Do_Not_Contact__c refDNC = new Reference_Do_Not_Contact__c(Contact_Email__c='Unsubscribe@paychextest.com', Prospect_Client_Email__c='Unsubscribe@paychextest.com');
        insert refDNC;
    
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'Test';
        email.fromname = 'Test Test';
        env.fromAddress = 'Test@email.com';
        email.plainTextBody = ReferenceDNCEmailHelper.TAG_START+refDNC.Id+ReferenceDNCEmailHelper.TAG_END;
        //email.plainTextBody = 'Reference DNC Email Submitted:'+refDNC.Id;
        
        UnsubscribeEmailHandler emailProcess = new UnsubscribeEmailHandler();
        emailProcess.handleInboundEmail(email, env);

    }
}