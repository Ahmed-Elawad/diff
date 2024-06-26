/* 
 * 
 Test Class: UnsubscribeEmailControllerTest
 *
 * History
 * -------
   01/25/2024 Dan Carmen       Increment API

 */
global with sharing class UnsubscribeEmailHandler implements Messaging.InboundEmailHandler{
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        // Create an InboundEmailResult object for returning the result of the  Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        UserHelper.SKIP_CACHE = true;
        String myPlainText = email.plainTextBody;
        System.debug('handleInboundEmail myPlainText='+myPlainText);
        Integer startIdx = myPlainText.indexOf(ReferenceDNCEmailHelper.TAG_START);
        Integer endIdx = myPlainText.indexOf(ReferenceDNCEmailHelper.TAG_END);
        Boolean hasTags = (startIdx > -1 && endIdx > startIdx);
        String idList = (hasTags ? myPlainText.substring(startIdx+ReferenceDNCEmailHelper.TAG_START.length(), endIdx) : '');
        System.debug('handleInboundEmail startIdx='+startIdx+' endIdx='+endIdx+' hasTags='+hasTags+' idList='+idList);
        Boolean successful = String.isNotBlank(idList);
        /*
        Boolean hasRefMessage = myPlainText.startsWith(ReferenceDNCEmailHelper.REF_EMAIL_MESSAGE);
        Integer endOfLineIdx = myPlainText.indexOf('\n');
        if(endOfLineIdx == -1){endOfLineIdx = myPlaintext.length();}
        String recordIdSubString = myPlainText.subString(ReferenceDNCEmailHelper.REF_EMAIL_MESSAGE.length(),endOfLineIdx);
        System.debug('handleInboundEmail hasRefMessage='+hasRefMessage+' endOfLineIdx='+endOfLineIdx+' recordIdSubString='+recordIdSubString);
        Boolean successful = String.isNotBlank(recordIdSubString);
        */
        if (successful) {
           //List<String> recordIds = recordIdSubString.split(ReferenceDNCEmailHelper.ID_SEPARATOR);
           List<String> recordIds = idList.split(ReferenceDNCEmailHelper.ID_SEPARATOR);
           successful = !recordIds.isEmpty();
           if (successful) {
              Set<Id> recordIdSet = new Set<Id>();
              for (String recordIdStr : recordIds) {
                 recordIdSet.add((Id)recordIdStr);
              }
              try {
                ReferenceDNCEmailHelper.processRecords(recordIdSet);
              } catch (Exception e) {
                 System.debug('UnsubscribeEmailHandler.handleInboundEmail exception='+e.getMessage()+'; '+e.getStackTraceString());
                 successful = false;
              }
              
           } // if (successful
        } // if (successful
        return result;
     } // handleInboundEmail
}