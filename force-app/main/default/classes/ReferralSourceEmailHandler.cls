/**
 * Handle inbound emails for processing referral sources.
 
 2.   Done when the content of the email includes the following
a. Subject Line: PNG SSO Registration Complete
b. From: noreply@paychex.com
c. Content of the body of the email:
i. Salesforce ID: [Variable: user’s Salesforce ID]
ii.   Account Status: Created
 
 
 2.   Done when the content of the email includes the following
a. Subject Line: PNG SSO Account Deleted
b. From: noreply@paychex.com
c. Content of the body of the email:
i. Salesforce ID: [Variable: user’s Salesforce ID]
ii.   Account Status: Deleted
 
 
  History
  -------
  11/08/2016 Dan Carmen      Created
    07/06/2020  Jacob Hinds         Added without sharing per PMD
  
 */
global without sharing class ReferralSourceEmailHandler implements Messaging.InboundEmailHandler {

   public static String SETUP_ONLINE=Label.ReferralSourceOnlineLabel;
   public static String ID_IDENTIFIER='Salesforce ID:';

   public static Integer SHORT_NOTES_LENGTH=Process_Log__c.Short_Note__c.getDescribe().getLength();

   public static Boolean LOG_NOTES=(Label.ReferralSourceEmailLogBody == 'Y');

   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      System.debug('handleInboundEmail email='+email);
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
      String emailBody = email.plainTextBody;
      Boolean isHtml = false;
      if (String.isBlank(emailBody)) {
         // check for html
         emailBody = email.htmlBody;
         isHtml = true;
      }
      String subject = email.subject;
      System.debug('handleInboundEmail subject='+subject+' emailBody='+emailBody);
      Boolean success=false;
      Process_Log__c procLog = new Process_Log__c(Process_Name__c='ReferralSourceEmailHandler', Short_Note__c=('Subject: '+subject+', emailBody: '+emailBody).left(SHORT_NOTES_LENGTH));
      if (LOG_NOTES) {
         procLog.Notes__c = 'plainTextBody='+email.plainTextBody+'; htmlBody='+email.htmlBody;
      }
      if (String.isNotBlank(subject) && String.isNotBlank(emailBody)) {
         // extract the contact id - make sure it exists.
         Integer idPos = emailBody.indexOf(ID_IDENTIFIER);
         System.debug('handleInboundEmail idPos='+idPos);
         if (idPos > -1) {
            // go to the end of the String.
            idPos += ID_IDENTIFIER.length();
            // look for an end tag if html
            Integer endOfLine = (isHtml ? emailBody.indexOf('<',idPos) : -1);
            //Integer endOfLine = emailBody.indexOf('\n',idPos);
            if (endOfLine == -1) {
               // look for a carraige return character instead
               endOfLine = emailBody.indexOf('\n',idPos);
            }
            System.debug('handleInboundEmail idPos='+idPos+' endOfLine='+endOfLine+' ID_IDENTIFIER='+ID_IDENTIFIER);
            // account for there not being a carriage return.
            endOfLine = (endOfLine == -1 ? emailBody.length() : endOfLine);
            System.debug('handleInboundEmail after check idPos='+idPos+' endOfLine='+endOfLine);
            // make sure there is data there
            if (endOfLine > idPos) {
               success = findContact(subject, emailBody.subString(idPos, endOfLine).trim(), procLog);
            }
         }
         /*
         // find the referral contact
         try {
            Referral_Contact__c refCtct = [Select Id, Name, Contact_Id__c, User_Name__c from Referral_Contact__c where Contact_Id__c = :subject];
            if (emailBody == 'Active') {
               refCtct.User_Name__c=SETUP_ONLINE;
            } else if (emailBody == 'Deleted') {
               refCtct.User_Name__c=null;
            }
            update refCtct;
         } catch (Exception e) {
            System.debug('Exception e:'+e.getMessage()+'; '+e.getStackTraceString());
         }*/
      } // if (String.isNotBlank(subject
      procLog.Status__c = (success ? Label.ProcessLogSuccess : Label.ProcessLogFailure);
      insert procLog;
      return result;
   } // handleInboundEmail
   
   public static Boolean findContact(String transactionType, String idOfRecord, Process_Log__c procLog) {
      Boolean success = false;
      System.debug('findContact idOfRecord='+idOfRecord+' transactionType='+transactionType);
      // find the referral contact
      procLog.ID1__c=idOfRecord;
      try {
         Referral_Contact__c refCtct = [Select Id, Name, Contact_Id__c, User_Name__c from Referral_Contact__c where Contact_Id__c = :idOfRecord];
         if (transactionType == Label.ReferralSourceEmailActive) {
            refCtct.User_Name__c=SETUP_ONLINE+' on '+DateTime.now().format('MM/dd/yyyy');
         } else if (transactionType == Label.ReferralSourceEmailDelete) {
            refCtct.User_Name__c=null;
         }
         update refCtct;
         success=true;
      } catch (Exception e) {
         procLog.Notes__c = (String.isNotBlank(procLog.Notes__c) ? procLog.Notes__c+'\n' : '') +'Exception e:'+e.getMessage()+'; '+e.getStackTraceString();
         System.debug('Exception e:'+e.getMessage()+'; '+e.getStackTraceString());
      }
      return success;
   } // findContact
} // class ReferralSourceEmailHandle