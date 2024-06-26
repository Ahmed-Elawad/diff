/*
 *  This class will gather input from BenAdminOnboardingSetupInfo.vfp create XML and email to the BenAdminOnboardingEmail email service
 *
 * History
 * --------
 * 06/10/2022  Carrie Marciano  created
 * 09/20/2022  Carrie Marciano  added code to remove < and > from input fields, changed to email initial email input sfdc_automation, changed parse error to email instead of process log
 * 
 */ 

public class BenAdminOnboardingSetupInfoController {
    
    public boolean isForm {get;set;} 
    public Id opptyId = null;
    
    public String brokerContactforImp {get;set;}  
    public String clientContactforImp {get;set;}
    public String openEnrollmentDates {get;set;}
    public String clientReqDeliveryDate {get;set;}
    public String notes {get;set;}  

    public List<CarrierWrapper> carriers {get;set;}
    public Integer nbrCarriers{get;set;}
   
    public String plainTextBody = '';    
    
    public static Integer SHORT_NOTES_LENGTH=Process_Log__c.Short_Note__c.getDescribe().getLength();
    
    private Opportunity onbOppty;
    private static PaychexSettings__c payxSetting = null;
    
    //***** Constructor *****
    public BenAdminOnboardingSetupInfoController(ApexPages.StandardController stdController) {
        System.debug('BenAdminOnboardingSetupInfoController');
        isForm = true;
        nbrCarriers = null;
        carriers = new List<CarrierWrapper>();
        opptyId = System.currentPageReference().getParameters().get('Id');
        System.debug('controller opptyId: '+opptyId+' nbrCarriers: '+nbrCarriers);        
    }
    
    public PageReference changeNbrCarriers() {
        if (nbrCarriers != null) {
            while (carriers.size() < nbrCarriers) {
                System.debug('changeNbrCarriers adding record: '+nbrCarriers);
                CarrierWrapper cw = new CarrierWrapper();
                carriers.add(cw);
            }
        }
        return null;
    }
    
    public PageReference submit() {
                
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        Process_Log__c procLog = new Process_Log__c(Process_Name__c='BenAdminOnboardingSetupInfoController', Status__c = 'In Process');
        
        brokerContactforImp = brokerContactforImp.replaceAll('<',' ');
        brokerContactforImp = brokerContactforImp.replaceAll('>',' ');
        clientContactforImp = clientContactforImp.replaceAll('<',' ');
        clientContactforImp = clientContactforImp.replaceAll('>',' ');
        openEnrollmentDates = openEnrollmentDates.replaceAll('<',' ');
        openEnrollmentDates = openEnrollmentDates.replaceAll('>',' ');       
        clientReqDeliveryDate = clientReqDeliveryDate.replaceAll('<',' ');
        clientReqDeliveryDate = clientReqDeliveryDate.replaceAll('>',' ');
        notes = notes.replaceAll('<',' ');
        notes = notes.replaceAll('>',' ');   
        
        if(opptyId != null){
            onbOppty =  [Select Id, Name, AccountId, OwnerId, Owner.Person_ID_Number__c, Onboarding_Info_Sent__c From Opportunity
                         Where Id = :opptyId];
            
            procLog.ID1__c=opptyId;
            
            /* build email body */
            String benAdminMsg = '<BenAdminOnb>\r <AccountId>'+onbOppty.AccountId+'</AccountId>\r <OpportunityId>'+onbOppty.Id+'</OpportunityId>\r';
                   benAdminMsg += '<SalesRepId>'+(onbOppty.Owner.Person_ID_Number__c != null ? onbOppty.Owner.Person_ID_Number__c : '') +'</SalesRepId>\r <Origin>BenAdmin</Origin>\r <BrokerContactforImp>'+brokerContactforImp+'</BrokerContactforImp>\r <ClientContactforImp>'+clientContactforImp+'</ClientContactforImp>\r';           
            	   benAdminMsg += '<OpenEnrollmentDates>'+openEnrollmentDates+'</OpenEnrollmentDates>\r <ClientReqDeliveryDate>'+clientReqDeliveryDate+'</ClientReqDeliveryDate>\r <Notes>'+notes+'</Notes>\r';
            
            //loop thru carrierwrapper to build carrierInfo tags
            if(carriers.size() != 0){
                for(CarrierWrapper carrier : carriers){
                    benAdminMsg += '<CarrierInfo>\r <CarrierName>'+carrier.carrierName+'</CarrierName>\r <EDIConnection>'+carrier.ediConnection+'</EDIConnection>\r <GroupPolicyNumber>'+carrier.groupPolicyNumber+'</GroupPolicyNumber>\r <CarrierContact>'+carrier.carrierContact+'</CarrierContact>\r </CarrierInfo>\r';
                }
                System.debug('submit added carrier info to benAdminMsg: '+benAdminMsg);    
            }            
            
            benAdminMsg += '</BenAdminOnb>'; 
            System.debug('submit complete benAdminMsg: '+benAdminMsg);
            
            email.plainTextBody = benAdminMsg;
           try{ 
                //send email to email service
                forwardEmail (email, 'BenAdmin Onboarding - HNBF Opportunity Submission');
            
                //update opportunity to use in validation rule - if this is false when moving to sold pop message requiring rep to fill out onboarding info
        		onbOppty.Onboarding_Info_Sent__c = True;
        		update onbOppty;
        		System.debug('BenAdminOnboardingSetupInfoController update Opportunity Onboarding Info Sent: '+onbOppty.Onboarding_Info_Sent__c);
            }
            catch (Exception e){
                procLog.Notes__c = (String.isNotBlank(procLog.Notes__c) ? procLog.Notes__c+'\n' : '') +'Exception e:'+e.getMessage()+'; '+e.getStackTraceString();
                forwardEmail (email, 'BenAdmin Onboarding error email - Unable to call email service '+e.getMessage());
            }
                        
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Successfully gathered information.  Onboarding case will be created.'));
        	//return null;
  
            procLog.Notes__c = email.plainTextBody;
            procLog.Status__c = 'Completed';
            insert procLog;
            return returnToOpportunity(); 
        }
        else
        {
            nbrCarriers = null;
            procLog.Notes__c = 'No Opportunity, could not proceed';
            procLog.Status__c = 'Failure';
            insert procLog;
            return null;
        }                       
    }
    
    public PageReference returnToOpportunity() {
        PageReference returnPr = new PageReference('/'+opptyId);
        System.debug('returnToOpportunity returnPr='+returnPr); 
        return returnPr;
    } // returnToOpportunity
    
    public PageReference cancel() {
        return returnToOpportunity();         
    }
    
    /** number of carriers being added */
    public List<CarrierWrapper> displayCarriers{
        get {
            System.debug('displayCarriers'); 
            return carriers;
        } 
    } // displayCarriers 
    
    //Wrapper class for Carrier info 
    public class CarrierWrapper {
        
        public String carrierName {get;set;}
        public String ediConnection {get;set;}
        public String groupPolicyNumber {get;set;}
        public String carrierContact {get;set;}
        
        public CarrierWrapper() {
            
            carrierName = null;
            ediConnection = null;
            groupPolicyNumber = null;
            carrierContact = null;
        }        
    }
    
    private static void forwardEmail (Messaging.inboundEmail p_email, String p_subj) {   
      System.debug('BenAdminOnboardingSetupInfoController forwardEmail, subj='+p_subj); 
      String benAdminEmailService = Label.BenAdminOnbEmailService;
      System.debug('BenAdminOnboardingSetupInfoController benAdminEmailService='+benAdminEmailService); 
      if (payxSetting == null){  
           payxSetting = PaychexSettings__c.getInstance('BenAdminOnbErrorEmail');
            if (payxSetting != null && !payxSetting.IsActive__c) {
               payxSetting = null; 
            }
      }
      List<String> addrList = new List<String>(); 
      if (payxSetting != null && payxSetting.Attribute1__c != null){          
          addrList = payxSetting.Attribute1__c.split(';');
      }    
      if (benAdminEmailService != null){
          addrList.add(benAdminEmailService);
      }
      System.debug('BenAdminOnboardingSetupInfoController forwardEmail, addrList='+addrList);  
      if (addrList != null){  
           Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
           mail.setToAddresses(addrList);
           mail.setSubject (p_subj);
           mail.setHtmlBody(p_email.htmlBody);
           mail.setPlainTextBody(p_email.plainTextBody);            
           Messaging.SendEmailResult[] results= Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
           system.debug('JGS Send Email Result :' + results);
      }
        
   } // forwardEmail
}