/* To be able to setup a new user as a context user 
   
   History
   -------
   04/23/2024 Dan Carmen   Created
  
 */
global class NewUserEmailHandler implements Messaging.InboundEmailHandler {
    
   // for testing only so we can check the ids came through
   public static Id[] testIds;
    
   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
      String myPlainText = email.plainTextBody;
      System.debug('handleInboundEmail subject='+email.subject);
      //System.debug('handleInboundEmail myPlainText='+myPlainText);
      // this is to account for any footers or anything else added to the end - strip off the end
      Integer tailPos = (String.isNotBlank(myPlainText) ? myPlainText.indexOf(NewUserHelper.emailTail) : -1);
      String emailBody = (tailPos > -1 ? myPlainText.subString(0,tailPos) : myPlainText);
      System.debug('handleInboundEmail emailBody='+String.isNotBlank(emailBody));
      if (String.isNotBlank(email.subject) &&  email.subject.contains(NewUserHelper.SUBJECT_REQUEST)) {
         System.debug('handleInboundEmail in request before checking ids');
         Id[] recIds = new Id[]{};
         Object[] objectIds = (Object[])json.deserializeUntyped(emailBody);
         for (Object objectId : objectIds) {
            Id recId = (Id)objectId;
            recIds.add(recId);
         }
         testIds = recIds;
         System.debug('handleInboundEmail recIds='+recIds);
         NewUserQueueable nuq = new NewUserQueueable(recIds);
         NewUserQueueable.checkLaunchQueueable(nuq);
      } else if (String.isNotBlank(email.subject) &&  email.subject.contains(NewUserHelper.SUBJECT_SAVE)) {
         System.debug('handleInboundEmail in save routine');
         NewUserHelper.ReqWrap rWrap =  (NewUserHelper.ReqWrap)json.deserialize(emailBody, NewUserHelper.ReqWrap.class);
         if (rWrap != null && rWrap.req != null) {
            upsert rWrap.req;
         }
         if (rWrap.newLicenseRequests != null && !rWrap.newLicenseRequests.isEmpty()) {
            insert rWrap.newLicenseRequests;
         }
      }
      return result;
   } // handleInboundEmail
    
} // class NewUserEmailHandler