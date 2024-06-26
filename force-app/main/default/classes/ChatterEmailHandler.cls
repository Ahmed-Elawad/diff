/**
 * Chatter as a context user since some users can't chatter

  History
  -------
  10/15/2019 Dan Carmen        Created
  08/31/2021 Dan Carmen        Commented out code
  
 */
global with sharing class ChatterEmailHandler implements Messaging.InboundEmailHandler {
    
   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      /*
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
      UserHelper.SKIP_CACHE = true;
      String myPlainText = email.plainTextBody;
      System.debug('handleInboundEmail myPlainText='+myPlainText);
      Boolean hasRefMessage = myPlainText.startsWith(ChatterMessageSend.CHAT_EMAIL_MESSAGE);
      Integer endOfLineIdx = myPlainText.indexOf('\n');
      if(endOfLineIdx == -1){endOfLineIdx = myPlaintext.length();}
      String recordIdSubString = myPlainText.subString(ChatterMessageSend.CHAT_EMAIL_MESSAGE.length(),endOfLineIdx);
      System.debug('handleInboundEmail hasRefMessage='+hasRefMessage+' endOfLineIdx='+endOfLineIdx+' recordIdSubString='+recordIdSubString);
      Boolean successful = String.isNotBlank(recordIdSubString);
      if (successful) {
         List<String> recordIdStrings = recordIdSubString.split(ChatterMessageSend.ID_SEPARATOR);
         successful = !recordIdStrings.isEmpty();
         if (successful) {
            Id[] recordIds = new Id[]{};
            for (String recordIdStr : recordIdStrings) {
               recordIds.add((Id)recordIdStr);
            }
            try {
               String[] textPosts = new String[]{'A lead has been entered in Salesforce for you.'};
               ChatterMessageSend.processChatterMessage(recordIds, textPosts);
            } catch (Exception e) {
               System.debug('ChatterEmailHandler.handleInboundEmail exception='+e.getMessage()+'; '+e.getStackTraceString());
               successful = false;
            }
            
         } // if (successful
      } // if (successful
      return result;
      */
      return null;
   } // handleInboundEmail

} // ChatterEmailHandler