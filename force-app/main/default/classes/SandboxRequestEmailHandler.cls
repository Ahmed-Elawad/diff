/* 
   Email Handler for sandbox user requests
   
  History
  -------
  02/21/2024 Dan Carmen   Created

 */
global class SandboxRequestEmailHandler implements Messaging.InboundEmailHandler {

   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
      String myPlainText = email.plainTextBody;
      System.debug('handleInboundEmail subject='+email.subject);
      //System.debug('handleInboundEmail myPlainText='+myPlainText);
      // this is to account for any footers or anything else added to the end - strip off the end
      Integer tailPos = (String.isNotBlank(myPlainText) ? myPlainText.indexOf(SandboxRequest.emailTail) : -1);
      String emailBody = (tailPos > -1 ? myPlainText.subString(0,tailPos) : myPlainText);
      try {
         if (email.subject.contains(SandboxRequest.requestSubject)) {
            SandboxRequest.handleEmailRequest(emailBody);
         } else if (email.subject.contains(SandboxRequest.responseSubject)) {
            SandboxRequest.handleEmailResponse(emailBody);
         }
         result.success=true;
      } catch (Exception e) {
         result.success = false;
         result.message='Exception occurred: '+e.getMessage()+' \n'+e.getStackTraceString();
      }

      return result;
   } // handleInboundEmail

} // class SandboxRequestEmailHandler