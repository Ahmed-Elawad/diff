/*
*  This class will process messages received from email services.  The email is sent from multiple power apps used by MPSC
*  
*  This class uses the class MPSCHelper to parse and process the incoming emails.
*
* History
* --------
* 04/10/2024  Carrie Marciano  created
*/ 

global without sharing class MPSCEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){
        
        ErrorLog__c log = new ErrorLog__c(ClassName__c='MPSCEmailHandler',MethodName__c='handleInboundEmail', CodeKey__c='LOG_DATA');
        
        // Create an InboundEmailResult object for returning the result of the  Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        List<MPSCEmailHelper.pAppInfo> pAppInfoList = new List<MPSCEmailHelper.pAppInfo>();
        
        try {
            Throw new PAIEmailException('MPSC Information incoming email');
        }
        catch (PAIEmailException pAe) {
            //forwardEmail(email, pAe.getMessage());
            forwardEmail(pAe.getMessage(), email.plainTextBody);
        }                                                          
        String myPlainText = email.plainTextBody;
        system.debug('MPSCEmailHandler myPlainText: '+ myPlainText);
        if (!String.isBlank(myPlainText) && myPlainText.length()>0){         
            myPlainText = myPlainText.replace('_',' ');
            myPlainText = myPlainText.replace(';','","');
            boolean caps =  myPlainText.contains('<MPSCINFORMATION>') && myPlainText.contains('</MPSCINFORMATION>');
            Integer endIdx = 0;
            Integer startIdx = 0;
            if (caps){
                startIdx = myPlainText.indexOf('<MPSCINFORMATION>');
                endIdx = myPlainText.indexOf('</MPSCINFORMATION>');
            }
            else{
                startIdx = myPlainText.indexOf('<MPSCInformation>');
                endIdx = myPlainText.indexOf('</MPSCInformation>');
            }
            String goodPlainText = myPlainText.substring(startIdx,endIdx+18);
            String logMsg = 'goodPlainText plain text: '+goodPlainText; 
			ErrorLog.addToDescription(log,logMsg); 
            
            try {
                if (String.isBlank(goodPlainText)){  	
                    System.debug('MPSCEmailHandler no text within email body!!'); 
                    Throw new PAIEmailException('MPSC error email - no text within email body'); 
                }
                else{ 
                    MPSCEmailHelper.pAppInfo pAppInfo = MPSCEmailHelper.parseXml(goodPlainText);
                    System.debug('MPSCEmailHandler MPSCEmailHelper pAppInfo.parseMsg: '+pAppInfo.parseMsg); 
                    if (pAppInfo.parseMsg == 'Success'){
                        pAppInfoList.add(pAppInfo); 
                        log.ObjectId__c = (pAppInfo == null ? null : pAppInfo.CaseId);
            			log.ObjectAPIName__c='Case';
                        Attachment attach = new Attachment(ParentId = pAppInfo.CaseId, Name='originalEmailBody.txt',Body=Blob.valueOf(email.plainTextBody), ContentType='text');
        				insert attach;
                    	System.debug('MPSCEmailHandler myPlainText after insert attachment'); 
                    }  
                    else{
                        Throw new PAIEmailException('MPSC plain text parseXml error - '+pAppInfo.parseMsg); 
                    }
                }
            } // try
            catch (PAIEmailException pAe) {
                //MPSCEmailHelper.forwardEmail(pAe.getMessage(), email.plainTextBody);
                ErrorLog.logError('MPSCEmailHandler', 'handleInboundEmail', 'plain text', null, pAe, null, true);
            } // catch      
        } // if !isBlank(myPlainText)
        else{
            myPlainText += email.htmlBody;
            System.debug('MPSCEmailHandler text of html body before'+myPlainText);
            myPlainText = myPlainText.replace('_',' ');   
            myPlainText = myPlainText.replace(';','","');
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
            
            System.debug('MPSCEmailHandler plain text of html body after'+myPlainText);          
            boolean caps = myPlainText.contains('<MPSCINFORMATION>') && myPlainText.contains('</MPSCINFORMATION>');  
            try {
                if (!caps && (!myPlainText.contains('<MPSCInformation>') && !myPlainText.contains('</MPSCInformation>'))){
                    Throw new PAIEmailException('MPSC error email - no html within email body');    
                }
                else{    // strip off beginning and ending <node>s and parse stuff in the middle
                    Integer endIdx = 0;
                    Integer startIdx = 0;
                    if (caps){
                        startIdx = myPlainText.indexOf('<MPSCINFORMATION>');
                        endIdx = myPlainText.indexOf('</MPSCINFORMATION>');
                    }
                    else{
                        startIdx = myPlainText.indexOf('<MPSCInformation>');
                        endIdx = myPlainText.indexOf('</MPSCInformation>');
                    }
                    String goodPlainText = myPlainText.substring(startIdx,endIdx+18);
                    MPSCEmailHelper.pAppInfo pAppInfo = new MPSCEmailHelper.pAppInfo();
                    pAppInfo.parseMsg = 'Success';
                    String errMsg = '';
                    try{
                        System.debug('MPSCEmailHandler calling xmlHelper');
                        xmlHelper pAppInfoHelper = new xmlHelper('MPSCEmailHelper.pAppInfo',goodPlainText); 
                        pAppInfo = (MPSCEmailHelper.pAppInfo)pAppInfoHelper.xmlObject; 
                        if (pAppInfo.parseMsg == 'Success'){
                            pAppInfoList.add(pAppInfo); 
                            log.ObjectId__c = (pAppInfo == null ? null : pAppInfo.CaseId);
                            log.ObjectAPIName__c='Case';
                            Attachment attach = new Attachment(ParentId = pAppInfo.CaseId, Name='originalEmailBody.txt',Body=Blob.valueOf(email.plainTextBody), ContentType='text');
                            insert attach;
                            System.debug('MPSCEmailHandler html after insert attachment'); 
                        }
                        else{
                        	Throw new PAIEmailException('MPSC html parse error - '+pAppInfo.parseMsg); 
                    	}
                    }
                    catch(Exception ex){
                        Throw new PAIEmailException('MPSC error email - MPSC html error '+ex.getMessage()+' goodPlainText='+goodPlainText);
                    }
                } // else
            } // try
            catch (PAIEmailException pAe) {
                //MPSCEmailHelper.forwardEmail(pAe.getMessage(), email.htmlBody);
                ErrorLog.logError('MPSCEmailHandler', 'handleInboundEmail', 'html', null, pAe, null, true);
            } // catch
        } // else
        
        if (!pAppInfoList.isEmpty()){   
            Try{
                MPSCEmailHelper.processInfo(pAppInfoList);
            }
            catch(Exception ex){
                if(!Test.isRunningTest()){
                    Throw new PAIEmailException('Unable to Process MPSC Information: '+pAppInfoList[0]);
                }
            } 
        }
        
        ErrorLog.saveLog(log);
        return result;
        
    } //handleInboundEmail
        
    // this exception is used to throw missing attachment messages
    public class PAIEmailException extends Exception {}     
    
    private static PaychexSettings__c payxSetting = null;
    
     /* method to send incoming email to person listed in custom setting */
    private static void forwardEmail (String p_subj, String p_body) {
      System.debug('MPSCEmailHandler forwardEmail, subj='+p_subj);
      System.debug('MPSCEmailHandler forwardEmail, body='+p_body);
      if (payxSetting == null)  
        {  payxSetting = PaychexSettings__c.getInstance('MPSCForwardErrorEmail');
        if (payxSetting != null && !payxSetting.IsActive__c) 
        {  payxSetting = null;  }
        }
        
        try {
            if (payxSetting != null && payxSetting.Attribute1__c != null)
            {  Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                List<String> addrList = new List<String>();
                addrList = payxSetting.Attribute1__c.split(';');
                mail.setToAddresses(addrList);
                //mail.setToAddresses (new String[]{payxSetting.Attribute1__c});
                mail.setSubject (p_subj);
                mail.setPlainTextBody(p_body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        } // try
        catch (Exception ex) {
            if (payxSetting != null && payxSetting.Attribute1__c != null)
            {  Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                List<String> addrList = new List<String>();
                addrList = payxSetting.Attribute1__c.split(';');
                mail.setToAddresses(addrList);
                //mail.setToAddresses (new String[]{payxSetting.Attribute1__c});
                mail.setSubject('Problem with MPSC email');
                mail.setPlainTextBody('An MPSC email was just received but it had incomplete data or was missing the SFDC ID. \n\n'+p_body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            } // if
        } // catch   
              
    } // forwardEmail
} //MPSCEmailHandler

/* XML should look like this, depending on the power app a subset of these tags could be sent.  Case Number, Case Id, Process Type and Status are required and will always be sent

<MPSCInformation>
<CaseNumber></CaseNumber>
<CaseId></CaseId>
<ProcessType></ProcessType>
<Status></Status>
<x1099ChangesOnly></x1099ChangesOnly>
<AccountForTraining></AccountForTraining>
<AdditionalContact></AdditionalContact>
<AdditionalDetails></AdditionalDetails>
<AdditionalModules></AdditionalModules>
<AdditionalNotes></AdditionalNotes>
<AddProductAreaAtRisk></AddProductAreaAtRisk>
<AgencySelection></AgencySelection>
<AgencyType></AgencyType>
<AlreadyHavePayroll></AlreadyHavePayroll>
<AmededReturnsNeeded></AmededReturnsNeeded>
<AssignedTo></AssignedTo>
<Attachments></Attachments>
<BeginningCheckDate></BeginningCheckDate>
<ClientProducts></ClientProducts>
<ClientRegisteredSSO></ClientRegisteredSSO>
<ConcernType></ConcernType>
<CorrectAgencyDBL></CorrectAgencyDBL>
<CorrectAgencyLocal></CorrectAgencyLocal>
<CorrectAgencyState></CorrectAgencyState>
<CorrectAgencySUI></CorrectAgencySUI>
<CreditRefundAmount></CreditRefundAmount>
<CreditRefundOffered></CreditRefundOffered>
<CurrentReportName></CurrentReportName>
<Description></Description>
<DiscountAmount></DiscountAmount>
<DiscountOffered></DiscountOffered>
<DiscountPercent></DiscountPercent>
<DiscountType></DiscountType>
<EENumbers></EENumbers>
<EmpDashboardOptions></EmpDashboardOptions>
<EndingCheckDate></EndingCheckDate>
<EnrolledTrainees></EnrolledTrainees>
<ErrorResponsibilityClient></ErrorResponsibilityClient>
<ErrorResponsibilityPaychex></ErrorResponsibilityPaychex>
<ErrorType></ErrorType>
<EstCompleteDate></EstCompleteDate>
<ExplanationOfLoss></ExplanationOfLoss>
<filedOnTaxpay></filedOnTaxpay>
<FirstRunDate></FirstRunDate>
<FlexUsername></FlexUsername>
<FuturePayroll></FuturePayroll>
<ImpactedEENumber></ImpactedEENumber>
<ImpactedYrQtr></ImpactedYrQtr>
<IncorrectAgencyDBL></IncorrectAgencyDBL>
<IncorrectAgencyLocal></IncorrectAgencyLocal>
<IncorrectAgencyState></IncorrectAgencyState>
<IncorrectAgencySUI></IncorrectAgencySUI>
<IntegrationType></IntegrationType>
<IsClientASO></IsClientASO>
<LastCheckDate></LastCheckDate>
<LastPayrollDate></LastPayrollDate>
<LastTaxQuarterWorked></LastTaxQuarterWorked>
<LateOriginalsNeeded></LateOriginalsNeeded>
<MgrDashboardOptions></MgrDashboardOptions>
<NeedYEReturns></NeedYEReturns>
<NumOfEEsAffected></NumOfEEsAffected>
<OriginatorOfConcern></OriginatorOfConcern>
<PackageChangeOffered></PackageChangeOffered>
<PackageOffered></PackageOffered>
<PayFrequency></PayFrequency>
<PayrollInfo></PayrollInfo>
<PayrollPolicy></PayrollPolicy>
<PayrollTermDate></PayrollTermDate>
<PlanNumber></PlanNumber>
<PQAComplete></PQAComplete>
<ProductAreaAtRisk></ProductAreaAtRisk>
<ReasonForEscalation></ReasonForEscalation>
<ReasonForLeaving></ReasonForLeaving>
<ReasonForLeaving2></ReasonForLeaving2>
<ReasonForLeaving3></ReasonForLeaving3>
<ReasonForRequest></ReasonForRequest>
<RequestDetails></RequestDetails>
<RequestReason></RequestReason>
<RequestType></RequestType>
<RiskDetails></RiskDetails>
<SipmIpmRm></SipmIpmRm>
<SpecialInstructions></SpecialInstructions>
<TrainedByDate></TrainedByDate>
<TrainingOptions></TrainingOptions>
<TrainingType></TrainingType>
<TypeOfRequest></TypeOfRequest>
<Vendor></Vendor>
<VendorContact></VendorContact>
<VendorWebsite></VendorWebsite>
<WhatAdjCorrecting></WhatAdjCorrecting>
</MPSCInformation>
*/