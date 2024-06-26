/* 
   Email Handler to launch the DataLoadBatch3 job as a specific user
   
  History
  -------
  04/13/2021 Dan Carmen   Created

 */
global class DataLoadEmailHandler implements Messaging.InboundEmailHandler {

   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
      String myPlainText = email.plainTextBody;
      System.debug('handleInboundEmail myPlainText='+myPlainText);
      Boolean launchBatch3 = myPlainText.contains('Launch DataLoadBatch3');
      if (launchBatch3) {
         DataLoadBatch3.launchBatch();
      }
      return result;
   } // handleInboundEmail

} // class DataLoadEmailHandler