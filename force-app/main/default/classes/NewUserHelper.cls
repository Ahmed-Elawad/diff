/* Helper class for the NewUserRequest__c object 
   
   History
   -------
   04/23/2024 Dan Carmen   Created
  
 */
public without sharing class NewUserHelper {
   public static Boolean SKIP_TRIGGER=false;
    
   public static void handleTrigger(NewUserRequest__c[] recs, Map<Id,NewUserRequest__c> oldMap, Boolean isBefore, Boolean isAfter) {
      System.debug('NewUserHelper.handleTrigger recs='+recs.size()+' SKIP_TRIGGER='+SKIP_TRIGGER+' isBefore='+isBefore+' isAfter='+isAfter);
      if (!SKIP_TRIGGER && isAfter) {
         checkRequestsAfter(recs,oldMap);
      } // if (!SKIP_TRIGGER && isAfter
   } // handleTrigger
    
   public static final String emailTail='<ThisIsTheEnd>';
   public static String userRequestEmail=Label.UserRequestEmail;
   public static String SUBJECT_REQUEST='User Request';
   public static String SUBJECT_SAVE='Save Request';
    
   // for testing purposes
   public static String emailBody = '';

   public static void checkRequestsAfter(NewUserRequest__c[] recs, Map<Id,NewUserRequest__c> oldMap) {
      NewUserRequest__c[] submittedRequests = new NewUserRequest__c[]{};
      Id[] recIdsToProcess = new Id[]{};
      NewUserRequest__c[] updatedReqs = new NewUserRequest__c[]{};
      for (NewUserRequest__c req : recs) {
         NewUserRequest__c oldReq = (oldMap != null ? oldMap.get(req.Id) : null);
         // on insert or can click the checkbox.
         if (oldReq == null || req.SubmitRequest__c) {
            if ((req.Request_Type__c == 'Chatter Free User')
                || (req.Request_Type__c == 'Reactivate' && req.User__c != null)
                || (req.Request_Type__c == 'Standard User' && req.User__c != null && req.User_to_Mirror__c != null)) {
               submittedRequests.add(req);
               recIdsToProcess.add(req.Id);
            }
            if (req.SubmitRequest__c) {
               NewUserRequest__c updateReq = new NewUserRequest__c(Id=req.Id, SubmitRequest__c = false);
               updatedReqs.add(updateReq);
            }
         }  
      } // for (NewUserRequest__c req : recs
      System.debug('checkRequestsAfter updatedReqs='+updatedReqs.size()+' recIdsToProcess='+recIdsToProcess.size()+' userRequestEmail='+userRequestEmail);
      if (!updatedReqs.isEmpty()) {
         SKIP_TRIGGER=true;
         DmlHelper.performDML2(updatedReqs, DmlHelper.DML_UPDATE, 'NewUserHelper', 'checkRequestsAfter', 'Update Requests', true); 
      }
      if (!recIdsToProcess.isEmpty() && userRequestEmail != 'NoMail') {
         // send an email to the email service to process as a context user
         emailBody = json.serialize(recIdsToProcess).replace('number_Z','number')+emailTail;
         Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
         emailToSend.setSaveAsActivity(false);
         emailToSend.setToAddresses(new String[]{userRequestEmail});
         emailToSend.setSubject(SUBJECT_REQUEST);
         emailToSend.setPlainTextBody(emailBody);
         Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emailToSend}, false);
         System.debug('checkRequestsAfter results='+results);
      }
   } // checkRequestsAfter
    
    public class ReqWrap {
       public NewUserRequest__c req;
       public Manage_Package_License__c[] newLicenseRequests;
    } // class ReqWrap
    
} // class NewUserHelper