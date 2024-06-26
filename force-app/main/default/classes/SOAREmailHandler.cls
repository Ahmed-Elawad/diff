/*
 *  This class will process messages received from email services.  The email is sent from the SOAR SharePoint form
 *  used by Payroll Specialists to input referrals for new clients and upsells.
 *  This class uses the class SOARHelper to parse and process the incoming emails.
 *
 * History
 * --------
 * 08/23/2013  Cindy Freeman  created
 * 07/29/3014  Cindy Freeman  added method to send incoming email to person listed in custom setting
 * 05/17/2016  Cindy Freeman  changed parser to return null if missing key data, sends error email and stops, changed to xmlparser
 * 06/05/2016  Cindy Freeman  added back parser of plain text email body
 * 05/07/2017  Cindy Freeman  getting extra FONT tags so added a replace inside the htmlBody parse section
 * 06/14/2017  Cindy Freeman  added try/catch around processSoarEmail
 * 06/20/2017  Cindy Freeman  removed commented out code
 * 06/28/2017  Cindy Freeman  add code for PartnerReferral creation and update
 * 03/26/2019  Cindy Freeman  add code handel garbage at end of emails, now sends error emails and updates comment on Partner Referral if problems  
 * 07/06/2020  Jacob Hinds    Added without sharing per PMD
 */ 
 
global without sharing class SOAREmailHandler implements Messaging.InboundEmailHandler {

   global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                       Messaging.InboundEnvelope env){
 
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
      List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
      try {
          Throw new SOARException('SOAR Incoming Email');
      }
      catch (SOARException se0) {
          forwardEmail(email, se0.getMessage());
      }                                                     
      
      PartnerReferral__c partRef = new PartnerReferral__c();
      partRef.Source__c = 'SOAR';
      partRef.Comments__c = 'Pending';                                                          
                                                           
      String myPlainText= ''; 
      // Add the email plain text into the local variable 
      myPlainText = email.plainTextBody;
      if (!String.isBlank(myPlainText) && myPlainText.length()>0) 
      {     partRef.description__c = myPlainText;       
            myPlainText = myPlainText.replace('_',' ');
            boolean caps =  myPlainText.contains('<SOARINFORMATION>') && myPlainText.contains('</SOARINFORMATION>');
            Integer endIdx = 0;
            Integer startIdx = 0;
            if (caps){
                   startIdx = myPlainText.indexOf('<SOARINFORMATION>');
                   endIdx = myPlainText.indexOf('</SOARINFORMATION>');
            }
            else{
                   startIdx = myPlainText.indexOf('<SoarInformation>');
                   endIdx = myPlainText.indexOf('</SoarInformation>');
            }
            String goodPlainText = myPlainText.substring(startIdx,endIdx+18);
       
            try {
                    if (String.isBlank(goodPlainText))
                    {  	System.debug('**CMF ** no text within email body!!'); 
                     	partRef.Comments__c = 'SOAR error email - Empty Email Body';
                        Throw new SOARException('SOAR error email - Empty Email Body'); 
                    }
                    else
                    {  SOARHelper.SoarRef sr = SOARHelper.parseXml(goodPlainText);
                        System.debug('handleInboundEmail SOARHelper sr.parseMsg: '+sr.parseMsg); 
                     	if (sr.parseMsg == 'Success')
                        {   srList.add(sr); }
                        else
                        {   partRef.Comments__c = 'SOAR error: ' + sr.parseMsg; }          
                    }
            } // try
            catch (SOARException se) {
                forwardEmail(email, se.getMessage());
            } // catch      
      } // if !isBlank(myPlainText)
      else
      {   myPlainText += email.htmlBody;
          partRef.description__c = myPlainText;
          System.debug('**CMF ** plain text of html body before'+myPlainText);
          myPlainText = myPlainText.replace('_',' ');
          //myPlainText = myPlainText.replace('Soar ID', 'Soar_ID');      
          myPlainText = myPlainText.replace('&lt;', '<');
          myPlainText = myPlainText.replace('&gt;', '>');
          myPlainText = myPlainText.replace('<BR>', '');
          myPlainText = myPlainText.replace('\r\n', ' ');
          myPlainText = myPlainText.replace('<BR/>', '');
          myPlainText = myPlainText.replace('<br>', '');
          myPlainText = myPlainText.replace('<br/>', '');
          myPlainText = myPlainText.replace('&nbsp;', ' ');
          myPlainText = myPlainText.replace('</FONT><FONT face="Segoe UI">','');      
          myPlainText = myPlainText.trim();
       
         System.debug('SoarEmailHandler plain text of html body after'+myPlainText);          
         boolean caps =  myPlainText.contains('<SOARINFORMATION>') && myPlainText.contains('</SOARINFORMATION>');  
         try {
              if (!caps && (!myPlainText.contains('<SoarInformation>') && !myPlainText.contains('</SoarInformation>') ))
              {   Throw new SOARException('SOAR error email - Empty Email Body');    }
              else
              {    // strip off beginning and ending <node>s and parse stuff in the middle
                  Integer endIdx = 0;
                  Integer startIdx = 0;
                  if (caps){
                        startIdx = myPlainText.indexOf('<SOARINFORMATION>');
                        endIdx = myPlainText.indexOf('</SOARINFORMATION>');
                   }
                   else{
                        startIdx = myPlainText.indexOf('<SoarInformation>');
                        endIdx = myPlainText.indexOf('</SoarInformation>');
                   }
                   String goodPlainText = myPlainText.substring(startIdx,endIdx+18);
                   SOARHelper.SoarRef soarRef = new SOARHelper.SoarRef();
                   soarRef.parseMsg = 'Success';
                   String errMsg = '';
                   try
                    {   System.debug('SOAREmailHandler calling xmlHelper');
                        xmlHelper srHelper = new xmlHelper('SOARHelper.SoarRef',goodPlainText);                
                        soarRef = (SOARHelper.SoarRef)srHelper.xmlObject;  
                        soarRef.fullName = soarRef.firstName + ' ' + soarRef.lastName;
                        soarRef.parseMsg = 'Success';
                        if (String.isBlank(soarRef.companyName))
                        {   errMsg += ' Missing Company Name  ';   }
                        if (String.isBlank(soarRef.fullName))
                        {   errMsg += ' Missing Contact Name. ';  }
                        if ((soarRef.product != 'New Client' && String.isBlank(soarRef.Id)) ||
                            (soarRef.product == 'New Client' && soarRef.addOnclient == 'Yes' && String.isBlank(soarRef.Id)))
                        {   errMsg += ' Missing account ID, needed for additional product or Add On client. ';  }
                        if (String.isNotBlank(soarRef.contactEmail) && 
                            (soarRef.contactEmail.countMatches('@')>1 || soarRef.contactEmail.contains('<')))
                        {   errMsg += ' Bad contact email address. ';  }        
                        if (String.isNotBlank(errMsg)) {
                            forwardEmail(email, 'SOAR error: '+errMsg);
                            soarRef.parseMsg = errMsg;                              
                        }
                        if (soarRef.parseMsg == 'Success')
                        {   srList.add(soarRef); }
                        else
                        {   partRef.Comments__c = 'SOAR error: ' + soarRef.parseMsg;    }
                    }
                    catch(Exception ex)
                    {   partRef.Comments__c = 'SOAR error: Unable to Parse XML';
                        Throw new SOARException('SOAR error email - Unable to Parse XML '+ex.getMessage()+' goodPlainText='+goodPlainText);    
                    }
              } // else
           } // try
           catch (SOARException se) {
                forwardEmail(email, se.getMessage());
           } // catch
      } // else
      
      try {
        /*if (partRef.Comments__c != 'Pending'){
           partRef.Processed__c = true;    
        } */
        System.debug('SOAREmailHandler before insert partRef');  
        insert partRef;
      }
      catch (Exception e) {
         forwardEmail(email, 'SOAREmailHandler partner Referral insert error-' + e.getMessage());
      }
      
      try {
          if (!srList.isEmpty())
          {     srList.get(0).partRefId = partRef.Id;   
                SOARHelper.processSoarRef(srList);                 
          }
      }
      catch (Exception ex) {
          forwardEmail(email, 'SOAREmailHandler processSoarRef error-' + ex.getMessage());                                                 
      }
      
      return result;
        
   } //handleInboundEmail
  
   // this exception is used to throw missing data messages
   public class SOARException extends Exception {}
    
   private static PaychexSettings__c payxSetting = null;  
  
   /* method to send incoming email to person listed in custom setting
   */
   private static void forwardEmail (Messaging.inboundEmail p_email, String p_subj) {   
      System.debug('SOAREmailHandler forwardEmail, subj='+p_subj);      
      if (payxSetting == null)  
      {     payxSetting = PaychexSettings__c.getInstance('SoarForwardErrorEmail');
            if (payxSetting != null && !payxSetting.IsActive__c) 
            {   payxSetting = null; }
      }
       
      if (payxSetting != null && payxSetting.Attribute1__c != null)
      {     Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
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
    
                
} // class SOAREmailHandler