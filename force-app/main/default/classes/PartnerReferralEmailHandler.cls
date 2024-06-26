/**
 * When an email is submitted, an email will kick off the process for a particular record id.
 */
global class PartnerReferralEmailHandler implements Messaging.InboundEmailHandler {

   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
      UserHelper.SKIP_CACHE = true;
      String myPlainText = email.plainTextBody;
      System.debug('handleInboundEmail myPlainText='+myPlainText);
      Boolean hasRefMessage = myPlainText.startsWith(PartnerReferralHelper.REF_EMAIL_MESSAGE);
      Integer endOfLineIdx = myPlainText.indexOf('\n');
      if(endOfLineIdx == -1){endOfLineIdx = myPlaintext.length();}
      String recordIdSubString = myPlainText.subString(PartnerReferralHelper.REF_EMAIL_MESSAGE.length(),endOfLineIdx);
      System.debug('handleInboundEmail hasRefMessage='+hasRefMessage+' endOfLineIdx='+endOfLineIdx+' recordIdSubString='+recordIdSubString);
      Boolean successful = String.isNotBlank(recordIdSubString);
      if (successful) {
         List<String> recordIds = recordIdSubString.split(PartnerReferralHelper.ID_SEPARATOR);
         successful = !recordIds.isEmpty();
         if (successful) {
            Set<Id> recordIdSet = new Set<Id>();
            for (String recordIdStr : recordIds) {
               recordIdSet.add((Id)recordIdStr);
            }
            try {
               PartnerReferralHelper.processReferrals(recordIdSet);
            } catch (Exception e) {
               System.debug('PartnerReferralEmailHandler.handleInboundEmail exception='+e.getMessage()+'; '+e.getStackTraceString());
               successful = false;
            }
            
         } // if (successful
      } // if (successful
      return result;
   } // handleInboundEmail
   
} // class PartnerReferralEmailHandler