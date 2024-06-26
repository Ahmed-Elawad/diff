/*
 *  This class will process messages received from email services.  The email is sent from AICPA
 *  This class uses the class AICPAEmailHelper to parse and process the incoming emails.
 *
 * History
 * --------
 * 10/02/2018  Cindy Freeman    created
 * 12/26/2018  Cindy Freeman    modified forwardEmail to handle multiple email addresses
   12/28/2022  Dan Carmen       Modify to use SF Duplicate Management

 */ 
 
global class AICPAEmailHandler implements Messaging.InboundEmailHandler {

   public static String[] TAG_OPTIONS = Label.AICPA_Tag_Options.split(';');

   global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env) {
 
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
      
      List<AICPAEmailHelper.aicpaLead> aicpaList = new List<AICPAEmailHelper.aicpaLead>();
      
      //if (!Test.isRunningTest())
        forwardEmail(email, 'AICPA Incoming Email', false); 
      
      PartnerReferral__c partRef = new PartnerReferral__c();
      partRef.Source__c = 'AICPA';
      partRef.Comments__c = 'Pending';                                                          
                                                           
      String myPlainText= ''; 
      String msgBody = email.plainTextBody;      
      if (String.isBlank(msgBody))
      {   msgBody += email.htmlBody;      }
      
      if (String.isBlank(msgBody))
      {   String msg = 'AICPA email body is blank.';
         throw new AICPAException(msg);
      }
      
      // be able to account for multiple tags
      for (String tagOption : TAG_OPTIONS) {
         String startTag = '<'+tagOption+'>';
         String endTag = '</'+tagOption+'>';
         Integer msgStart = msgBody.indexOf(startTag);
         // look for the closing node tag 
         Integer msgEnd = msgBody.indexOf(endTag);
         if (msgStart >= 0 && msgEnd > 0) {
            //myPlainText = myPlainText.substring(0, idx - 1);
            myPlainText = msgBody.substring(msgStart, msgEnd + endTag.length());
            System.debug('handleInboundEmail tagOption='+tagOption+' myPlainText='+myPlainText);
            break;
         } // if (msgStart >= 0
      } // for (String tagOption
      
      
            
    if (String.isBlank(myPlainText))
    {    System.debug('AICPAEmailHandler no text within email body!!'); 
        Throw new AICPAException('AICPA error email - Empty Email Body'); 
    }
    else
      {   partRef.description__c = myPlainText;
          System.debug('AICPAEmailHandler plain text of html body before'+myPlainText);
          //myPlainText = myPlainText.replace('_',' ');
          try {
            xmlHelper xlHelper = new xmlHelper('AICPAEmailHelper.aicpaLead',myPlainText);            
            System.debug('handleInboundEmail before parsing the aicpaLead object');
            AICPAEmailHelper.aicpaLead al = new AICPAEmailHelper.aicpaLead();
            al = (AICPAEmailHelper.aicpaLead)xlHelper.xmlObject;
            aicpaList.add(al);
         } catch(Exception ex) {
            String msg = 'Unable to Parse XML' + (Test.isRunningTest() || String.isNotBlank(Utilities.checkForProduction()) ? ': '+ex.getMessage()+'; '+ex.getStackTraceString() : '');
            Throw new AICPAException(msg);   
         } // try
      } // if (String.isBlank(myPlainText
      
      try { PartnerReferral__c[] partrefList = new PartnerReferral__c[]{partRef}; 
            DmlHelper.performDML2(partRefList, DmlHelper.DML_INSERT, 'AICPAEmailHandler', 'handleInboundEmail', 'Insert Partner Referral', false);
      }
      catch (Exception e) {
            forwardEmail(email, 'AICPAEmailHandler partRef insert error-' + e.getMessage(), true);        
      }
      
      try {
          if (!aicpaList.isEmpty())
          {   aicpaList.get(0).partRefId = partRef.Id;  
              AICPAEmailHelper.processAicpaLeads(aicpaList);     
          }
      }
      catch (Exception ex) {
          forwardEmail(email, 'AICPAEmailHandler error-' + ex.getMessage(), true);                                                           
      }
      
      return result;
        
   } //handleInboundEmail 
       
  
    // this exception is used to throw missing data messages
    public class AICPAException extends Exception {}
    
    private static PaychexSettings__c payxSetting = null;  
    private static PaychexSettings__c payxErrorSetting = null;
  
    /* method to send incoming or error email to person listed in custom setting
    */
    private static void forwardEmail (Messaging.inboundEmail p_email, String p_subj, Boolean p_error) {   
      
        System.debug('AICPAEmailHandler.forwardemail p_error='+p_error+' email='+p_email.plainTextBody);      
        if (!p_error && payxSetting == null)  
        {   payxSetting = PaychexSettings__c.getInstance('AICPAForwardEmail');
            if (payxSetting != null && !payxSetting.IsActive__c) 
            {  payxSetting = null;  }
        }
        if (p_error && payxErrorSetting == null)  
        {   payxErrorSetting = PaychexSettings__c.getInstance('AICPAForwardErrorEmail');
            if (payxErrorSetting != null && !payxErrorSetting.IsActive__c) 
            {  payxErrorSetting = null;  }
        } 
       
        if (!p_error && payxSetting != null && payxSetting.Attribute1__c != null)
        {   Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage(); 
              List<String> addrList = new List<String>();
              addrList = payxSetting.Attribute1__c.split(';');
              mail.setToAddresses(addrList);
              //mail.setToAddresses (new String[]{payxSetting.Attribute1__c});
              mail.setSubject (p_subj);
              mail.setHtmlBody(p_email.htmlBody);
              mail.setPlainTextBody(p_email.plainTextBody);            
              Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }  
        if (p_error && payxErrorSetting != null && payxErrorSetting.Attribute1__c != null)
        {   Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
              List<String> addrList = new List<String>();
              addrList = payxSetting.Attribute1__c.split(';');
              mail.setToAddresses(addrList);
              //mail.setToAddresses (new String[]{payxSetting.Attribute1__c});
              mail.setSubject (p_subj);
              mail.setHtmlBody(p_email.htmlBody);
              mail.setPlainTextBody(p_email.plainTextBody);            
              Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    } // forwardEmail
     

} // AICPAEmailHandler