/**
 * When an email is submitted, an email will kick off the process for a particular record id.
 * History
 * --------
 * 10/26/2017  Frank Lurz       Created
 *
*/
global class TaxNoticeEmailHandler implements Messaging.InboundEmailHandler {

   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
      UserHelper.SKIP_CACHE = true;
      String myPlainText = email.plainTextBody;
      System.debug('** FRL ** in handleInboundEmail - myPlainText = ' + myPlainText);
      Boolean hasTaxMessage = myPlainText.contains(ClientFieldSubmissionHelper.TAX_EMAIL_MESSAGE);
      integer start = myPlainText.indexOf(ClientFieldSubmissionHelper.TAX_EMAIL_MESSAGE) + ClientFieldSubmissionHelper.TAX_EMAIL_MESSAGE.length();
      String recordIdSubString = myPlainText.subString(start);
      System.debug('** FRL ** in handleInboundEmail - hasTaxMessage = ' + hasTaxMessage + ' recordIdSubString = ' + recordIdSubString);
      Boolean successful = String.isNotBlank(recordIdSubString);
      if (successful) {
         List<String> recordIds = recordIdSubString.split(ClientFieldSubmissionHelper.ID_SEPARATOR);
         successful = !recordIds.isEmpty();
         if (successful) {
            Set<Id> recordIdSet = new Set<Id>();
            for (String recordIdStr : recordIds) {
               recordIdSet.add((Id)recordIdStr);
            }
            try {
               ClientFieldSubmissionHelper.modifySubmissionDates(recordIdSet);
            } catch (Exception e) {
               System.debug('** FRL ** in TaxNoticeEmailHandler.handleInboundEmail exception = ' + e.getMessage() + '; ' + e.getStackTraceString());
               successful = false;
            }
            
         } // if (successful
      } // if (successful
      return result;
   } // handleInboundEmail
   
} // class TaxNoticeEmailHandler