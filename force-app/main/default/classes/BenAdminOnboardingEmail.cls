/*
 *  This class will process messages received from email services.  The email is sent from PACO or from Flow when a BenAdmin sale is ready for onboarding
 *
 * History
 * --------
 * 06/10/2022  Carrie Marciano  created
 * 
 */ 


global without sharing class BenAdminOnboardingEmail implements Messaging.InboundEmailHandler{

   global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){
                                                       
        Process_Log__c procLog = new Process_Log__c(Process_Name__c='BenAdminOnboardingEmail', Status__c = 'In Process');
       
        // Create an InboundEmailResult object for returning the result of the  Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        List<BenAdminOnboardingHelper.benAdminOnb> bAOList = new List<BenAdminOnboardingHelper.benAdminOnb>();                                                   
        try {
              Throw new BenAdminException('BenAdmin Onboarding Email - Email Service');
        }
        catch (BenAdminException ba0) {
              forwardEmail(email, ba0.getMessage());
        } 
                                                               
        String myPlainText= ''; 
        // Add the email plain text into the local variable 
        myPlainText = email.plainTextBody;
        System.debug('BenAdminOnboardingEmail myPlainText: '+myPlainText);
        if (!String.isBlank(myPlainText) && myPlainText.length()>0) {
            //partRef.description__c = myPlainText;       
            myPlainText = myPlainText.replace('_',' ');
            boolean caps =  myPlainText.contains('<BENADMINONB>') && myPlainText.contains('</BENADMINONB>');
            Integer endIdx = 0;
            Integer startIdx = 0;
            if (caps){
                   startIdx = myPlainText.indexOf('<BENADMINONB>');
                   endIdx = myPlainText.indexOf('</BENADMINONB>');
            }
            else{
                   startIdx = myPlainText.indexOf('<BenAdminOnb>');
                   endIdx = myPlainText.indexOf('</BenAdminOnb>');
            }
            System.debug('BenAdminOnboardingEmail startIdx: '+startIdx+' endIdx: '+endIdx);
            String goodPlainText = myPlainText.substring(startIdx,endIdx+14); 
            
            try {
                if (String.isBlank(goodPlainText)){  
                    System.debug('BenAdminOnboardingEmail no text within email body!!'); 
                	Throw new BenAdminException('BenAdminOnboardingEmail error email - Empty Email Body'); 
                }
                else
                {  
                	BenAdminOnboardingHelper.benAdminOnb bAO = BenAdminOnboardingHelper.parseXml(goodPlainText);
                 	if (bAO.parseMsg == 'Success'){   
                        bAOList.add(bAO); 
                    }
                 	else{
                    	Throw new BenAdminException('BenAdminOnboardingEmail error email - Error Parsing XML'); 
                    }          
                }
            } // try
            catch (BenAdminException ba) {
                procLog.Notes__c = (String.isNotBlank(procLog.Notes__c) ? procLog.Notes__c+'\n' : '') +'BenAdminException ba:'+ba.getMessage()+'; '+ba.getStackTraceString();
                procLog.Status__c = 'Failure';
            } // catch    
        } // if !isBlank(myPlainText)
        else
        { 
          myPlainText += email.htmlBody;
          System.debug('BenAdminOnboardingEmail plain text of html body: '+myPlainText);
          myPlainText = myPlainText.replace('_',' ');      
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
                
          boolean caps =  myPlainText.contains('<BENADMINONB>') && myPlainText.contains('</BENADMINONB>');  
          try {
              if (!caps && (!myPlainText.contains('<BenAdminOnb>') && !myPlainText.contains('</BenAdminOnb>'))){
                 Throw new BenAdminException('BenAdminOnboardingEmail - Empty Email Body');    
              }
              else
              {    // strip off beginning and ending <node>s and parse stuff in the middle
                  Integer endIdx = 0;
                  Integer startIdx = 0;
                  if (caps){
                        startIdx = myPlainText.indexOf('<BENADMINONB>');
                        endIdx = myPlainText.indexOf('</BENADMINONB>');
                   }
                   else{
                        startIdx = myPlainText.indexOf('<BenAdminOnb>');
                        endIdx = myPlainText.indexOf('</BenAdminOnb>');
                   }
                   String goodPlainText = myPlainText.substring(startIdx,endIdx+14);
                   BenAdminOnboardingHelper.benAdminOnb bAO = new BenAdminOnboardingHelper.benAdminOnb();                    
                   bAO.parseMsg = 'Success';
                   try{
                       System.debug('BenAdminOnboardingEmail calling xmlHelper');
                        xmlHelper bAOHelper = new xmlHelper('BenAdminOnboardingHelper.benAdminOnb',goodPlainText);                
                        bAO = (BenAdminOnboardingHelper.benAdminOnb)bAOHelper.xmlObject;  
                        System.debug('BenAdminOnboardingEmail  bAO: '+ bAO);
                        bAO.parseMsg = 'Success';                                                 
                        if (bAO.parseMsg == 'Success'){
                           bAOList.add(bAO); 
                        }
                        else
                        {   
                            Throw new BenAdminException('BenAdminOnboardingEmail error email - Error Parsing XML');     
                        }
                    }
                    catch(Exception ex){
                       	//partRef.Comments__c = 'Unable to Parse XML';
                       	Throw new BenAdminException('BenAdminOnboardingEmail - Unable to Parse XML '+ex.getMessage()+' goodPlainText='+goodPlainText); 
                    }
              } // else
           } // try
           catch (BenAdminException ba) {
               procLog.Notes__c = (String.isNotBlank(procLog.Notes__c) ? procLog.Notes__c+'\n' : '') +'BenAdminException ba:'+ba.getMessage()+'; '+ba.getStackTraceString();
               procLog.Status__c = 'Failure';
           } // catch

        }  //else                                                     
      
        try {
            if (!bAOList.isEmpty()){
                BenAdminOnboardingHelper.processbenAdminOnb(bAOList); 
                procLog.Status__c = 'Complete';
            }                              
        }      
        catch (BenAdminException ba) {  
            procLog.Notes__c = (String.isNotBlank(procLog.Notes__c) ? procLog.Notes__c+'\n' : '') +'BenAdminException ba:'+ba.getMessage()+'; '+ba.getStackTraceString();
            procLog.Status__c = 'Failure';
        } 
        
       insert procLog;
       return result;                                                    
   }
   
   /* this exception is used to throw missing data messages */
   public class BenAdminException extends Exception {} 
   
   private static PaychexSettings__c payxSetting = null;
   
   /* method to send incoming email to person listed in custom setting */ 
   private static void forwardEmail (Messaging.inboundEmail p_email, String p_subj) {   
      System.debug('BenAdminOnboardingEmail forwardEmail, subj='+p_subj);      
      if (payxSetting == null){  
           payxSetting = PaychexSettings__c.getInstance('BenAdminOnbErrorEmail');
            if (payxSetting != null && !payxSetting.IsActive__c) {
               payxSetting = null; 
            }
      }
       
      if (payxSetting != null && payxSetting.Attribute1__c != null){
           Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
            List<String> addrList = new List<String>();
            addrList = payxSetting.Attribute1__c.split(';');
            mail.setToAddresses(addrList);
            mail.setSubject (p_subj);
            mail.setHtmlBody(p_email.htmlBody);
            mail.setPlainTextBody(p_email.plainTextBody);            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
        
   } // forwardEmail 
}