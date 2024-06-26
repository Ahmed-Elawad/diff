/* 
 * Handle reference DNC records

 Test Class: UnsubscribeEmailControllerTest,DNCHelperTest

 *
 * History
 * -------
   01/25/2024 Dan Carmen       Update to handle REST email opt out

 */
public with sharing class ReferenceDNCEmailHelper {
    
   public static void checkAfterActions(Reference_Do_Not_Contact__c[] recs, Map<Id,Reference_Do_Not_Contact__c> oldMap) {
      //Pujitha: Send it to emailhandler if, submitted via Unsubscribe form
      Boolean runningUserIsGuest = UserHelper.isRunningUserGuest();
      Set<Id> emailIds = new Set<Id>();
      
      Map<Id,Case> caseStatusMap = new Map<Id,Case>();
      List<Id> casesCompleted = new List<Id>();
    
      //used for client level setting of dnc/eoo/both
      Map<String,String> operationByClientNumber = new Map<String,String>();
      //used for contact level setting of dnc
      Reference_Do_Not_Contact__c[] contactDNCList = new Reference_Do_Not_Contact__c[]{};
      Reference_Do_Not_Contact__c[] contactEOOList = new Reference_Do_Not_Contact__c[]{};
      Reference_Do_Not_Contact__c[] contactBothList = new Reference_Do_Not_Contact__c[]{};
    
      for (Reference_Do_Not_Contact__c dnc : recs) {
         Reference_Do_Not_Contact__c oldDNC = (oldMap != null ? oldMap.get(dnc.id) : null);
         if (runningUserIsGuest) {
            emailIds.add(dnc.Id);
         } else {
            if (oldDNC==null) {
               if (String.isNotBlank(dnc.Branch_Client_Num__c) && dnc.Do_Not_Call_Client_Level__c && dnc.Email_Opt_Out_Client_Level__c) {
                  operationByClientNumber.put(dnc.Branch_Client_Num__c,'Both');
               } else if (String.isNotBlank(dnc.Branch_Client_Num__c) && dnc.Do_Not_Call_Client_Level__c) {
                  operationByClientNumber.put(dnc.Branch_Client_Num__c,'Call');
               } else if (String.isNotBlank(dnc.Branch_Client_Num__c) && dnc.Email_Opt_Out_Client_Level__c) {
                  operationByClientNumber.put(dnc.Branch_Client_Num__c,'Email');
               } else if (String.isNotBlank(dnc.Contact_Phone__c) && dnc.Do_Not_Call_Contact_Level__c 
                             && String.isNotBlank(dnc.Contact_Email__c) && dnc.Email_Opt_Out_Contact_Level__c) {
                  contactBothList.add(dnc);
               } else if (String.isNotBlank(dnc.Contact_Phone__c) && dnc.Do_Not_Call_Contact_Level__c) {
                  contactDNCList.add(dnc);
               } else if (String.isNotBlank(dnc.Contact_Email__c) && dnc.Email_Opt_Out_Contact_Level__c) {
                  contactEOOList.add(dnc);
               }
            } // if (oldDNC==null
            if (dnc.CaseID__c != null && (oldDNC == null || (oldDNC!=null && dnc.Status__c != oldDNC.Status__c))) {
               Case c = new Case(Id=dnc.CaseID__c, Status=dnc.Status__c,Rejection_Reason__c = dnc.Rejection_Reason__c,Comments_and_follow_up__c=dnc.Message_to_Requester__c);
               caseStatusMap.put(dnc.CaseID__c,c);
               if(dnc.Status__c == 'Completed'){
                  casesCompleted.add(dnc.CaseID__c);
               }
            }

         } // if (runningUserIsGuest

      } // for (Reference_Do_Not_Contact__c dnc 
    
      if (!operationByClientNumber.keySet().isEmpty()) {
         DNCHelper.handleDNCSharepointClientLevel(operationByClientNumber);
      }
      if (!contactDNCList.isEmpty()) {
         DNCHelper.handleDNCSharepointContactLevel(contactDNCList,'Call');
      }
      if (!contactEOOList.isEmpty()) {
         DNCHelper.handleDNCSharepointContactLevel(contactEOOList,'Email');
      }
      if (!contactBothList.isEmpty()) {
         DNCHelper.handleDNCSharepointContactLevel(contactBothList,'Both');
      }
    
      if (!caseStatusMap.keySet().isEmpty()) {
         DmlHelper.performDML2(caseStatusMap.values(), DmlHelper.DML_UPDATE, 'ReferenceDNCEmailHelper', 'checkAfterActions', 'Update case status', true); 
      }
       
      if (!casesCompleted.isEmpty()) {
         DNCHelper.handleDNC(casesCompleted);
      }
       
      if (!emailIds.isEmpty()) {
         sendDNCEmail(emailIds);  
      }
   } // checkAfterActions
    
    public static final String REF_EMAIL_MESSAGE='Reference DNC Email Submitted:';
    public static final String ID_SEPARATOR=';';
    public static final String TAG_START='<refIds>';
    public static final String TAG_END='</refIds>';
    public static Boolean emailSent=false;

    public static void sendDNCEmail(Set<Id> idsToProcessSet){
       emailSent = false;
       System.debug('sendDNCEmail Label.UnsubscribeEmail='+Label.UnsubscribeEmail);
       if (String.isNotBlank(Label.UnsubscribeEmail)) {
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          String[] toAddresses = new String[] {Label.UnsubscribeEmail};
          mail.setToAddresses(toAddresses);
          mail.setSaveAsActivity(false);
       
          mail.setSubject('DNC Email Submission');
          //String body = REF_EMAIL_MESSAGE+String.join(idsToProcessSet,ID_SEPARATOR);
          String body = TAG_START+String.join(idsToProcessSet,ID_SEPARATOR)+TAG_END;
          /*
          for (Id refId : idsToProcessSet) {
             if (String.isBlank(body)) {
                body = REF_EMAIL_MESSAGE;
             } else {
                body += ID_SEPARATOR;
             }
             body += refId;
          } // for (Id refId
          */
          System.debug('sendDNCEmail body='+body);
          mail.setPlainTextBody (body);
          Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
          for ( Messaging.SendEmailResult result : results) {
             System.debug('sendDNCEmail result='+result.isSuccess());
          }
          emailSent=true;
       } // if (String.isNotBlank(Label
       System.debug('sendDNCEmail emailSent='+emailSent);
    }//sendDNCEmail

    public static void processRecords(Set<Id> idsToProcessSet){
        
        Reference_Do_Not_Contact__c[] recToProcess = queryRefDNCEmails(idsToProcessSet);
        System.debug('enter processing dnc email rec'+recToProcess);
        
        String searchString;
        List<List<sObject>> searchList;
        Sobject[] searchResults = new Sobject[]{};
        Map<Id,SObject> searchResultsMap = new Map<Id,SObject>();
        Map<String, Reference_Do_Not_Contact__c> emailToRecMap = new Map<String, Reference_Do_Not_Contact__c>();
        
        for(Reference_Do_Not_Contact__c rec: recToProcess){
            if(searchString==null) {
                searchString = '("'+rec.Contact_Email__c+'")';
            } else {
            searchString += ' OR ("'+rec.Contact_Email__c+'")';
            }  
            emailToRecMap.put(rec.Contact_Email__c, rec); 
        }
        System.debug('email search string'+searchString);
        
          DNCQueueable dncJob = new DNCQueueable();
        if(searchString!=null){
            dncJob.addToQueue('Email','Lead/Contact',searchString,null,null,emailToRecMap); 
        //    searchList = queryRecords(searchString);
        }
        dncJob.checkLaunchQueuable();
     //   System.debug('searchList'+searchList);
        
    }

    public static Reference_Do_Not_Contact__c[] queryRefDNCEmails(Set<Id> recIds){
        Reference_Do_Not_Contact__c[] refDNCEmails;
        try {
            Set<String> fldSet = new Set<String>();
            DmlHelper.addFieldsToSet(Schema.SObjectType.Reference_Do_Not_Contact__c.fieldSets.UnsubscribeEmail, '', fldSet);
            String query = DmlHelper.buildQueryFromSet(fldSet,'Reference_Do_Not_Contact__c')+' where Id=:recIds';
            refDNCEmails = Database.query(query);
        } catch (Exception e) {
            System.debug('queryRefDNCEmails e='+e.getMessage());
        }
        return refDNCEmails;
    } // queryRefDNCEmails
}