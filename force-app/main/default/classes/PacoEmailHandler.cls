/*

07/06/2020  Jacob Hinds      Added without sharing per PMD
01/15/2021  Manmeet Vaseer   Added ErrorLog for INC2561269.05/17/2023  Dan Carmen       Added CEID/CAID
05/17/2023  Dan Carmen       Added CEID/CAID
05/22/2023  Eric Porter      Added Filters for FFSService.cls logic filtering out RCP Filter types
*/
global without sharing class PacoEmailHandler implements Messaging.InboundEmailHandler {
    

     global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                           Messaging.InboundEnvelope env){
                                                            
 		// ErrorLog__c log = new ErrorLog__c(ClassName__c='PacoEmailHandler',MethodName__c='handleInboundEmail', CodeKey__c='LOG_DATA');
                                                                 
        // // Create an InboundEmailResult object for returning the result of the  Apex Email Service
        // Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        // String myPlainText = '';
        // myPlainText += (email.htmlBody != NULL ? email.htmlBody : email.plainTextBody);                                                       
        // //system.debug('JGS htmlBody' + email.htmlBody);
        // system.debug('JGS MyPlainText' + myPlainText); 
        
        // boolean caps =  myPlainText.contains('<NODE>') && myPlainText.contains('</NODE>');  
        
        // if (!caps && (!myPlainText.contains('<node>') && !myPlainText.contains('</node>') ))
        // {   
        //     ErrorLog.addToDescription(log,'Empty Email Body');
		// 	ErrorLog.saveLog(log);
        //     Throw new PACOEmailHandlerException('Empty Email Body');    
        // }
        // else
        // {  
        //    ErrorLog.addToDescription(log,myPlainText);
            
        //    Integer endIdx = 0;
        //     Integer startIdx = 0;
        //     if(caps){
        //         startIdx = myPlainText.indexOf('<NODE>');
        //         endIdx = myPlainText.indexOf('</NODE>');
        //     }
        //     else{
        //         startIdx = myPlainText.indexOf('<node>');
        //         endIdx = myPlainText.indexOf('</node>');
        //     }
        //     String goodPlainText = myPlainText.substring(startIdx,endIdx+7);
        //     PACOEmailHandler.PACOEmail PACOEml = new PACOEmailHandler.PACOEmail();
        //     try
        //     {   xmlHelper esrHelper = new xmlHelper('PACOEmailHandler.PACOEmail',goodPlainText);                
        //         PACOEml = (PACOEmailHandler.PACOEmail)esrHelper.xmlObject;
        //         PACOEml.rcpChanged = FALSE;
        //         PACOEml.ownerChanged = FALSE;
        //     }
        //     catch(Exception ex)
        //     {   
        //         String logMsg = 'Unable to Parse XML '+ex.getMessage()+' goodPlainText='+goodPlainText;
		// 		ErrorLog.addToDescription(log, logMsg);
		// 		ErrorLog.saveLog(log);
        //         Throw new PACOEmailHandlerException(logMsg);    
        //     }   
            
            
		// 	ErrorLog.addToDescription(log, 'PACOEml.opportunityId: ' + PACOEml.opportunityId);
        //     if(PACOEml.opportunityId != NULL){
        //         log.ObjectId__c = PACOEml.opportunityId;
        //         log.ObjectAPIName__c = 'Opportunity';
                
        //         PACOEml = popValues(PACOEml);
        //         if(PACOEml.RCPFound){
		// 			ErrorLog.addToDescription(log, 'PACOEml.RCPFound.');
        //             PACOEml = processValues(PACOEml, log);
        //             if(PACOEml.rcpChanged){
		// 				ErrorLog.addToDescription(log, 'PACOEml.rcpChanged.');
        //                 update PACOEml.RCP;
        //             }
        //             if(PACOEml.ownerChanged){
		// 				ErrorLog.addToDescription(log, 'PACOEml.ownerChanged.');
        //                 update PACOEml.RCP.Case_Lookup__r;    
        //             }
        //         }
        //     }
            
        //     ErrorLog.saveLog(log);
        // } // else
        
        return null;
           
      } //handleInboundEmail
      
      // this exception is used to throw missing attachment messages
      public class PACOEmailHandlerException extends Exception {} 
      
      public class PACOEmail{
            public boolean rcpChanged;
            public boolean ownerChanged;
            public boolean RCPFound;
            public Id opportunityId;
            public string ownerEmail;
            public id ownerId;
            public string status;
            public string clientNumber;
            public string ceid;
            public string caid;
            public string dateToUpdate;
            public Reference_Core_Payroll__c RCP;
      }
      
    //   private PACOEmail popValues(PACOEmail PACOEml){
    //         PACOEmail tmpEmail = PACOEml;
    //         tmpEmail.RCPFound = FALSE;
    //         // RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Reference_Core_Payroll__c' AND DeveloperName = 'Reference_MPSC_Onboarding_Core_Payroll'];
    //         // To be released when Insite updates the feed with CEID and CAID data sent 06/05/2023 ECP
    //         List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Reference_Core_Payroll__c' AND (DeveloperName = 'Reference_MPSC_Onboarding_Core_Payroll' OR DeveloperName = 'Reference_Onboarding_Core_Payroll')];
    //         List<id> recordTypeIds = new List<Id>();
    //         for(RecordType rt: rts){
    //             recordTypeIds.add(rt.id);
    //         }
    //         list<Reference_Core_Payroll__c> rcp = [Select Id
    //                                          ,OwnerId
    //                                          ,Case_Lookup__c
    //                                          ,Case_Lookup__r.OwnerID
    //                                          ,Case_Lookup__r.AccountId
    //                                          ,CAID__c
    //                                          ,CEID__c
    //                                          ,Client_Load_Complete__c
    //                                          ,Client_Load_Received__c
    //                                          ,Current_Step__c
    //                                          ,Date_Client_Load_Complete__c
    //                                          ,Date_Client_Load_Received__c
    //                                          ,New_Prospect_Client_Number__c
    //                                          ,Opportunity_Lookup__c
    //                                          ,Opportunity_Lookup__r.AccountId
    //                                          ,Payroll_Run_Date__c
    //                                          ,RecordTypeId
    //                                      from Reference_Core_Payroll__c
    //                                      //where Opportunity_Lookup__c = :String.escapeSingleQuotes(tmpEmail.opportunityId) order by createdDate DESC Limit 1];
    //                                      where (Opportunity_Lookup__c = :String.escapeSingleQuotes(tmpEmail.opportunityId) AND (Not RecordTypeId IN :recordTypeIds))order by createdDate DESC Limit 1];
    //         if(!rcp.isEmpty()){
    //             tmpEmail.RCPFound = TRUE;
    //             tmpEmail.RCP = RCP[0];
    //             list<user> newUser = [Select Id from user where isActive = TRUE and License_Type__c != 'Chatter Free User' and email = :String.escapeSingleQuotes(tmpEmail.ownerEmail) limit 1];
    //             if(!newUser.isEmpty()){
    //                 tmpEmail.ownerId = newUser[0].id;
    //             }
    //         }
    //         return tmpEmail;            
    //   }
      
    //   private PACOEmail processValues(PACOEmail PACOEml, ErrorLog__c log){
    //         PACOEmail tmpEmail = PACOEml;
    //         If(tmpEmail.ownerId != NULL){
    //             tmpEmail.RCP.Case_Lookup__r.OwnerID = tmpEmail.ownerId;
    //             tmpEmail.ownerChanged = TRUE;   
	// 			ErrorLog.addToDescription(log, 'tmpEmail.RCP.Case_Lookup__r.OwnerID: ' + tmpEmail.RCP.Case_Lookup__r.OwnerID);
    //         }
    //         If(tmpEmail.clientNumber != NULL && tmpEmail.clientNumber != ''){
    //             tmpEmail.RCP.New_Prospect_Client_Number__c = tmpEmail.clientNumber;
    //             tmpEmail.rcpChanged = TRUE; 
	// 			ErrorLog.addToDescription(log, 'tmpEmail.RCP.New_Prospect_Client_Number__c : ' + tmpEmail.RCP.New_Prospect_Client_Number__c);
    //         }
    //         If(String.isNotBlank(tmpEmail.ceid)){
    //             tmpEmail.RCP.CEID__c = tmpEmail.ceid;
    //             tmpEmail.rcpChanged = TRUE; 
	// 			ErrorLog.addToDescription(log, 'tmpEmail.RCP.CEID__c : ' + tmpEmail.RCP.CEID__c);
    //         }
    //         If(String.isNotBlank(tmpEmail.caid)){
    //             tmpEmail.RCP.CAID__c = tmpEmail.caid;
    //             tmpEmail.rcpChanged = TRUE; 
	// 			ErrorLog.addToDescription(log, 'tmpEmail.RCP.CAID__c : ' + tmpEmail.RCP.CAID__c);
    //         }
    //         If(tmpEmail.clientNumber != NULL && tmpEmail.clientNumber != ''){
    //             tmpEmail.RCP.New_Prospect_Client_Number__c = tmpEmail.clientNumber;
    //             tmpEmail.rcpChanged = TRUE; 
	// 			ErrorLog.addToDescription(log, 'tmpEmail.RCP.New_Prospect_Client_Number__c : ' + tmpEmail.RCP.New_Prospect_Client_Number__c);
    //         }
    //         If(tmpEmail.status == 'Assigned'){
    //             tmpEmail.RCP.Current_Step__c =  '(1 of 4) Client Load Received';
    //             tmpEmail.RCP.Client_Load_Received__c = TRUE;
    //             tmpEmail.RCP.Date_Client_Load_Received__c = (tmpEmail.dateToUpdate != NULL ? Date.parse(tmpEmail.dateToUpdate) : Date.Today());
    //             tmpEmail.rcpChanged = TRUE;
	// 			ErrorLog.addToDescription(log, 'tmpEmail.RCP.Client_Load_Received__c: ' + tmpEmail.RCP.Client_Load_Received__c);
	// 			ErrorLog.addToDescription(log, 'tmpEmail.RCP.Date_Client_Load_Received__c: ' + tmpEmail.RCP.Date_Client_Load_Received__c);
    //         }
    //         else if(tmpEmail.status == 'Complete' || tmpEmail.status == 'Completed'){
    //             tmpEmail.RCP.Current_Step__c =  '(2 of 4) Client Load Complete';
    //             tmpEmail.RCP.Client_Load_Complete__c = TRUE;
    //             tmpEmail.RCP.Date_Client_Load_Complete__c = (tmpEmail.dateToUpdate != NULL ? Date.parse(tmpEmail.dateToUpdate) : Date.Today());
    //             tmpEmail.rcpChanged = TRUE;
	// 			ErrorLog.addToDescription(log, 'tmpEmail.RCP.Date_Client_Load_Complete__c: ' + tmpEmail.RCP.Date_Client_Load_Complete__c);
    //         }
    //         else if(tmpEmail.status == 'Ran'){
    //             tmpEmail.RCP.Current_Step__c =  '(3 of 4) First Payroll Ran';
    //             tmpEmail.RCP.Payroll_Run_Date__c = (tmpEmail.dateToUpdate != NULL ? Date.parse(tmpEmail.dateToUpdate) : Date.Today());
    //             tmpEmail.rcpChanged = TRUE;
	// 			ErrorLog.addToDescription(log, 'tmpEmail.RCP.Payroll_Run_Date__c: ' + tmpEmail.RCP.Payroll_Run_Date__c);
    //         }
    //         return tmpEmail;                
    //   }
}

/* XML Should look like:

<node>
<opportunityId>00618000002vPRS</opportunityId>
<clientNumber>901-1111</clientNumber>
<ownerEmail>jstouffer@paychex.com</ownerEmail>
<status>Assigned</status>
<dateToUpdate>11/12/2015</dateToUpdate>
</node>

<node>
      <opportunityId>0064u00001FfmP1</opportunityId>
      <ceid>00H2A1IULFS7P13O006M</ceid>
      <caid>00HWYNTDLFS7P1RU4W56</caid>
      <clientNumber>34-18171522</clientNumber>
      <ownerEmail>adunn2@paychex.com</ownerEmail>
      <status>Assigned</status>
      <dateToUpdate>5/17/2023</dateToUpdate>
    </node>

*/