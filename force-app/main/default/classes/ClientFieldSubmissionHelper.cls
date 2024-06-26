/*
 *  This class is triggered by the creation of a Client & Field Submission record.  It will search for existing prospect-client and contact, and then create a Case and Reference PAC record.
 *  It will then search for a related Reference PAC (and parent Case) created with the same Tax Agency value. 
 *  If found, the Case / Reference PC will be added to the xxx queue.  If no match is found, then the xxx field is populated so that workflow rules will assign the queue
 *
 * History
 * --------
 * 10/01/2017  Frank Lurz       Created
 *
*/

public without sharing class ClientFieldSubmissionHelper {
   public class CltFldSubmit {
      public String id;                   // account id
                  
   } // class CltFldSubmit
   
   public static Account acct {get; set;} 
   
   public static void processCFS(Map<Client_Field_Submission__c,datetime> cfsMapSD) {
        Boolean hasClientID = FALSE;
        String acctNumCheck;
   /***     Account acct {get; set;} ***/
        
        system.debug('*** FRL *** enter processCFS');   
        for(Client_Field_Submission__c CFS : cfsMapSD.keySet()){
          if(CFS.Paychex_Client_ID__c != null) {
             hasClientID = TRUE;
             String verifiedClientID;  // will contain the string value of verified account number format ***/
             verifiedClientID = AccountHelper.verifyAcctNbr(CFS.Paychex_Client_ID__c);
             system.debug('FRL in processCFS - hasClientID = ' + hasClientID);
             system.debug('FRL in processCFS - verifiedClientID = ' + verifiedClientID);
             Boolean validatedClientID = FALSE;
             validatedClientID = AccountHelper.isAcctNbrValid(verifiedClientID);
             system.debug('FRL in processCFS - validatedClientID = ' + validatedClientID);
             if(validatedClientID) {
                acctNumCheck = verifiedClientID;
             }
 
/****             if(validatedClientID) {
                Account[] acctList;
                acctList = [Select Id, Name, AccountNumber, Bis_ID__c, Federal_ID_Number__c, Lost_Date__c, Reason_Lost__c from Account Where AccountNumber = :verifiedClientID AND Federal_ID_Number__c = :CFS.Federal_ID_Number__c];
                system.debug('FRL in processCFS - acctList = ' + acctList.get(0));
             }
             else
             {
                Account[] acctList;
                acctList = [Select Id, Name, AccountNumber, Bis_ID__c, Federal_ID_Number__c, Lost_Date__c, Reason_Lost__c from Account Where Federal_ID_Number__c = :CFS.Federal_ID_Number__c];
                system.debug('FRL in processCFS - acctList = ' + acctList.get(0));             
             }
****/
          }
         acct = getAcct(CFS.Federal_ID_Number__c, acctNumCheck); 
         system.debug('FRL in processCFS just AFTER running getAcct method using fedID and acctnum.  acct -- ' + acct);
         if (acct != NULL) {
             system.debug('FRL in processCFS just BEFORE inserting a Case using  acct.id -- ' + acct.id);
             Case thisCase = new Case(ContactId = null 
                ,AccountId = acct.id
                ,Origin = 'TaxNotice1'
                ,recordtypeid = Label.PACServiceSupportCaseRecType
                ,TempOwnerId__c = CFS.id
                ,Subject = 'PAC - TaxNotice Submission');
             insert thisCase;
         }
         else {
             system.debug('FRL in processCFS just AFTER running getAcct method and not finding a matching fedID or acctnum.');
             Case thisCase = new Case(ContactId = null 
                ,AccountId = null
                ,Origin = 'TaxNotice2'
                ,recordtypeid = Label.PACServiceSupportCaseRecType
                ,TempOwnerId__c = CFS.id
                ,OwnerId = Label.PACmissingFieldContact
                ,Subject = 'PAC - TaxNotice Submission');
             insert thisCase;
         }
       }// for(Client_Field_Submission__c CFS
   }// processCFS

   /**  query for account that matches the CFS Federal_ID_Number__c and Paychex_Client_ID__c (if it's included and then verified **/
   private static Account getAcct(String fedID, String acctnum) {
     Account[] acctList;
     Boolean checkedWithJustFedId = FALSE;
     if (String.isNotBlank(acctnum)) {
        acctList = [Select Id, Name, AccountNumber, Bis_ID__c, Federal_ID_Number__c, Lost_Date__c, Reason_Lost__c from Account Where AccountNumber = :acctnum AND Federal_ID_Number__c = :fedID];
        system.debug('FRL in getAcct - querying on fedID and acctnum... ');
     }
     else {
        acctList = [Select Id, Name, AccountNumber, Bis_ID__c, Federal_ID_Number__c, Lost_Date__c, Reason_Lost__c from Account Where Federal_ID_Number__c = :fedID];
        system.debug('FRL in getAcct - querying on JUST fedID... ');
        checkedWithJustFedId = TRUE;
     }   
         if (!acctList.isEmpty())
      {  return acctList.get(0);  }
      else
         if (checkedWithJustFedId) 
      {  return null; }
         else {
            acctList = [Select Id, Name, AccountNumber, Bis_ID__c, Federal_ID_Number__c, Lost_Date__c, Reason_Lost__c from Account Where Federal_ID_Number__c = :fedID];
            system.debug('FRL in getAcct - querying on JUST fedID but in the second spot... ');
            checkedWithJustFedId = TRUE;
         }   
            if (!acctList.isEmpty())
                { return acctList.get(0);  }
            else   
                { return null; }
   } //getAcct
      
   
   /*****/
   
   /*****/
   public static void TaxNoticeEmail(Map<Client_Field_Submission__c,id> cfsMapId) {
      //Boolean submitAsEmail = false;
      System.debug('** FRL ** TaxNoticeEmail - cfsMapId = '+cfsMapId.size());
         for(Client_Field_Submission__c CFSid : cfsMapId.keySet()){
             if(CFSid.id != null) {
                // double check if the record was created as a guest user - all guest user submissions should be as email.
                UserHelper.SKIP_CACHE = true;
                //submitAsEmail = UserHelper.isRunningUserGuest();
                sendTaxNoticeEmail(CFSid);
             } //if
         } //for
   } //TaxNoticeEmail
   
   public static String TAX_EMAIL_MESSAGE='Tax Notice Submitted:';
   public static String ID_SEPARATOR=';';
   
   public static void sendTaxNoticeEmail(Client_Field_Submission__c CFSid ) { 
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       if (Label.TaxNoticeEmail!='User') {
           String[] toAddresses = new String[] {Label.TaxNoticeEmail};
               mail.setToAddresses(toAddresses);
       }
       else{
           mail.setTargetObjectId(Label.TaxNoticeEmailId);  
       }
       mail.setSaveAsActivity(false);
       
       mail.setSubject('Tax Notice Submission');
       
       String body = '';

       if (CFSid.id != NULL) {
           body = TAX_EMAIL_MESSAGE + CFSid.id;
       } 
       System.debug('** FRL ** - body = ' + body);
       mail.setPlainTextBody (body);
       if(!test.isRunningTest()&&Label.TaxNoticeEmailId!='NoEmail'){
       	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
       }
   } //SendTaxNoticeEmail   
 
 
 
   public static void modifySubmissionDates(Set<Id> idsToProcessSet) {
        list<Client_Field_Submission__c> cltFldSubs = [Select id, Submission_Date__c from Client_Field_Submission__c where id in :idsToProcessSet];
        if (!cltFldSubs.isEmpty()) {
              /***** cltFldSubs.Submission_Date__c = System.now(); *****/
              For (Client_Field_Submission__c  cfs:cltFldSubs) {
                    cfs.Submission_Date__c = System.now();
              }

             update cltFldSubs;
        }
   } //modifySubmissionDates

     /**  setting the CFS Submission Done field  **/
    public static void setSubmissionDone(Id cfsSDid) {
      Client_Field_Submission__c CFS = new Client_Field_Submission__c();
      CFS.id = cfsSDid;
      CFS.submission_done__c = TRUE;
      update CFS;
      return;
     } 

      
} // class ClientFieldSubmissionHelper