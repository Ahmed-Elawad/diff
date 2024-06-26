/*
*  This class will parse the messages received from email services.  It will create Case | BeneTrac Onboarding Record type and Reference BeneTrac Onboarding records 
*		
*       <BenAdminOnb>
*		<AccountId></AccountId>
*		<OpportunityId></OpportunityId>
*		<SalesRepId></SalesRepId>
*		<Origin></Origin>
*		<BrokerContactforImp></BrokerContactforImp>
*		<ClientContactforImp></ClientContactforImp>
*		<OpenEnrollmentDates></OpenEnrollmentDates>
*		<ClientReqDeliveryDate></ClientReqDeliveryDate>
*		<Notes></Notes>
*		<CarrierInfo>
*			<CarrierName></CarrierName>
*			<EDIConnection></EDIConnection>
*			<GroupPolicyNumber></GroupPolicyNumber>
*			<CarrierContact></CarrierContact>
*		</CarrierInfo>
*		</BenAdminOnb>
*
* History
* --------
* 06/10/2022  Carrie Marciano  created
* 08/30/2023  Shilpa G		   APR0143763: Updated method processbenAdminOnb to set Onboarding Type and Subject of new Case based on Flock Sale or Ancillary Only Sale
* 03/25/2024 Jaipal            APR015314 Changed recordtype of BeneTrac Onboarding' to 'Benefits Administration Onboarding'
*/


public class BenAdminOnboardingHelper {
    
    public class benAdminOnb {
        public String accountId;
        public String opportunityId;
        public String salesRepId;
        public String brokerContactforImp;  
        public String clientContactforImp;
        public String openEnrollmentDates;
        public String origin;
        public String clientReqDeliveryDate;
        public String notes;  
        public String carrierName;
        public String ediConnection;
        public String groupPolicyNumber;
        public String carrierContact;
        public String carrierDetails;
        public String plainTextBody;
        public String parseMsg;                   // set to errMsg if something happened during parsing    
    } //class benAdminOnb
    
    public static Account acct {get; set;}    // account being onboarded
    public static Opportunity oppty {get; set;}    // opportunity related to onboarding
    public static User salesRep {get; set;}   // sales rep
    //APR015314 changed record type: BeneTrac Onboarding' to 'Benefits Administration Onboarding'
    public static void processbenAdminOnb(List<benAdminOnb> bAOList) {
        Schema.RecordTypeInfo caseBenAdminRT = RecordTypeHelper.getRecordType('Benefits Administration Onboarding', 'Case');
        Schema.RecordTypeInfo refBenAdminRT = RecordTypeHelper.getRecordType('Ref BeneTrac Implementation Onboarding','Reference_BeneTrac_Onboarding__c');
        String benAdminOnbQueue = Label.BenAdminOnbQueue;
        
        Process_Log__c procLog = new Process_Log__c(Process_Name__c='BenAdminOnboardingHelper', Status__c = 'In Process');
    
        for(benAdminOnb bAO : bAOList){
            System.debug('processbenAdminOnb benAdminOnb='+bAO);            
            try{
                Boolean okay;
           		if (String.IsNotBlank(bAO.accountId)){
                    okay = findAcct(bAO);
                    if ( !okay || (okay && acct == null)){     
                        Throw new BenAdminException('Bad account ID no existing account, accountId='+bAO.accountId); 
                    }                       
            	} 
                else{
                    Throw new BenAdminException('No account ID, accountId='+bAO.accountId);
                }
                
                if (String.IsNotBlank(bAO.opportunityId)){
                    okay = findOppty(bAO);
                    if ( !okay || (okay && oppty == null)){   
                        Throw new BenAdminException('Bad opportunity ID no existing opportunity, opportunityId='+bAO.opportunityId); 
                    }
                    else{
                        procLog.ID1__c=oppty.Id;
                    }
                } 
                else{
                    Throw new BenAdminException('No opportunity ID, opportunityId='+bAO.opportunityId);
                }
                
                if((bAO.salesRepId).length() > 0){
                   System.debug('processbenAdminOnb bAO.salesRepId: '+bAO.salesRepId); 
                   salesRep = getPayxUser(bAO.salesRepId);
                }              
                
                Case bAOKase = new Case(RecordTypeId = caseBenAdminRT.getRecordTypeId()
                                , AccountId = acct.Id
                                , Opportunity__c = oppty.Id
                                , Sales_Rep__c = (salesRep != null ? salesRep.Id : null)
                                , OwnerId = benAdminOnbQueue      
                                , Origin = bAO.origin
                                , Originator_Type__c = 'Internal' 
                                , Current_Step__c = 'Data Gathering'        
                                , Onboarding_Type__c = oppty.Reference_Opportunity_Products__r[0].Flock__c==true || oppty.Reference_Opportunity_Products__r[0].Flock_with_Payroll__c==true ? 'Flock' : 'Ancillary Only'
                                , Priority = 'Medium'
                                , Status = 'New'
                                , Subject = oppty.Reference_Opportunity_Products__r[0].Flock__c==true || oppty.Reference_Opportunity_Products__r[0].Flock_with_Payroll__c==true ? acct.Name + ' - Flock Onboarding' : acct.Name + ' - Ancillary Only Onboarding'
                                , Description = bAO.plainTextBody
                                , Product__c = 'Flock');                         
                
                Database.Saveresult rsltK = Database.insert(bAOKase,false);
                List<Id> kaseIds = new List<Id>();
                if (rsltK.isSuccess()){
                  kaseIds.add(rsltK.getId());  
                }           
                else{
                  Database.Error[] err = rsltK.getErrors();            
                  Throw new BenAdminException('Bad insert of new case: '+err.get(0).getMessage());
                }
             
                Reference_BeneTrac_Onboarding__c refBAOnb = new Reference_BeneTrac_Onboarding__c(RecordTypeId = refBenAdminRT.getRecordTypeId()
                                                                                      , Case_Number__c = bAOKase.Id
                                                                                      , OwnerId = benAdminOnbQueue           
                                                                                      , Current_Step__c = 'Data Gathering'
                                                                                      , Type__c = oppty.Reference_Opportunity_Products__r[0].Flock__c==true || oppty.Reference_Opportunity_Products__r[0].Flock_with_Payroll__c==true ? 'Flock' : 'Ancillary Only'
                                                                                      , Total_Lives__c = oppty.Employees_Paid_Per_Payroll__c    
                                                                                      , Cobra__c = (oppty.Reference_Opportunity_Products__r[0].COBRA_Administration_Services__c==true?'Yes':'No') 
                                                                                      , Balance_Benefits__c = (oppty.Reference_Opportunity_Products__r[0].BalanceBenefits_Call_Center__c==true?'Yes':'No')           
                                                                                      , ESR__c = (oppty.Reference_Opportunity_Products__r[0]. Employer_Shared_Responsibility__c==true?'Yes':'No')
                                                                                      , Client_day_to_day_contact_for_imp__c = bAO.clientContactforImp
                                                                                      , Broker_day_to_day_contact_for_imp__c = bAO.brokerContactforImp
                                                                                      , Open_Enrollment_Date_s_if_known__c = bAO.openEnrollmentDates
                                                                                      , Client_requested_delivery_date__c = bAO.clientReqDeliveryDate
                                                                                      , Notes_for_Implementation_team__c = bAO.notes
                                                                                      , Carrier_Details__c = bAO.carrierDetails);
              
                Database.Saveresult rsltR = Database.insert(refBAOnb,false);
                List<Id> refBOIds = new List<Id>();
                if (rsltR.isSuccess()){
                  refBOIds.add(rsltR.getId()); 
                  procLog.Status__c = 'Complete';  
                }           
                else{
                  Database.Error[] err = rsltR.getErrors();            
                  Throw new BenAdminException('Bad insert of new reference object: '+err.get(0).getMessage());
                }
            }
            catch (BenAdminException be) {
                procLog.Notes__c = (String.isNotBlank(procLog.Notes__c) ? procLog.Notes__c+'\n' : '') +'BenAdminException be:'+be.getMessage()+'; '+be.getStackTraceString();
            	procLog.Status__c = 'Failure';
         	} // catch BenAdminException
        } 
        
        insert procLog;
    }
    
    public static benAdminOnb parseXml(String toParse) {	
        String nam;
        String txt;
        String tempCarrierInfo = '';
        benAdminOnb bAO = new benAdminOnb();
        System.debug('BenAdminOnboardingHelper here at parseXml');    
        bAO.parseMsg = 'Success';
        String errMsg = '';
        
        try {
            toParse = toParse.replaceAll('&', '&amp;');
            Map<String, String> tempParse = new Map<String, String>();
            bAO.plainTextBody = toParse;
            toParse = fixNotes(toParse);
            DOM.Document doc = new DOM.Document();
            try {
                doc.load(toParse);
                for (DOM.XmlNode node : doc.getRootElement().getChildren()){
                    system.debug('BenAdminOnboardingHelper node: '+node.getName());
                    if(node.getName() == 'CarrierInfo'){
                        //loop thru carrier child fields 
                        system.debug('BenAdminOnboardingHelper CarrierInfo childnodes');
                        for (DOM.XmlNode node2 : node.getChildren()){
                            if(node2.getName() == 'CarrierName'){
                                tempCarrierInfo += 'Carrier: '+node2.getText().trim()+' ';
                                system.debug('BenAdminOnboardingHelper CarrierName: '+tempCarrierInfo); 
                            }
                            else if(node2.getName() == 'EDIConnection'){
                                tempCarrierInfo += 'EDIConnection: '+node2.getText().trim()+' '; 
                                system.debug('BenAdminOnboardingHelper EDIConnection: '+tempCarrierInfo);
                            }
                            else if(node2.getName() == 'GroupPolicyNumber'){
                                tempCarrierInfo += 'GroupPolicyNumber: '+node2.getText().trim()+' '; 
                                system.debug('BenAdminOnboardingHelper GroupPolicyNumber: '+tempCarrierInfo);
                            }
                            else if(node2.getName() == 'CarrierContact'){
                                tempCarrierInfo += 'CarrierContact: '+node2.getText().trim()+' ';
                                system.debug('BenAdminOnboardingHelper CarrierContact: '+tempCarrierInfo);
                            }                                   
                        }
                        nam = 'CarrierDetails';
                        txt = tempCarrierInfo+'\n'; 
                        system.debug('BenAdminOnboardingHelper CarrierInfo nam: '+nam+' txt: '+txt); 
                    }
                    else{
                        nam = node.getName();
                        txt = node.getText().trim();
                        txt = txt.replaceAll('\n', '');
                        txt = txt.replaceAll('\r', ''); 
                        system.debug('BenAdminOnboardingHelper node nam: '+nam+' txt: '+txt);
                    }
                    tempParse.put(nam,txt);   
                }
                
                bAO.accountId =  tempParse.get('AccountId');
                bAO.opportunityId = tempParse.get('OpportunityId');
                bAO.salesRepId = tempParse.get('SalesRepId');
                bAO.brokerContactforImp = tempParse.get('BrokerContactforImp');
                bAO.clientContactforImp = tempParse.get('ClientContactforImp');
                bAO.openEnrollmentDates = tempParse.get('OpenEnrollmentDates');
                bAO.origin = tempParse.get('Origin');
                bAO.clientReqDeliveryDate = tempParse.get('ClientReqDeliveryDate');
                bAO.notes = tempParse.get('Notes');
                bAO.carrierDetails = tempParse.get('CarrierDetails');
            }
            catch (System.Xmlexception ex) {
                errMsg += ' Parsing error '+ ex.getMessage();
            }  
                      
        }
        catch (BenAdminException be) {
            errMsg +=  (String.isNotBlank(errMsg) ? errMsg+'\n' : '') +'BenAdminException be:'+be.getMessage()+'; '+be.getStackTraceString();          
        } // catch Exception  
        
        if (String.isNotBlank(errMsg)) {
            bAO.parseMsg = errMsg;
      	}
        
        return bAO;
    }  
    
    /* find existing prospect-client of ID was included in email */
    private static Boolean findAcct(benAdminOnb bAO) {
      Boolean okay = true;
     
      acct = [Select Id, Name, AccountNumber, Bis_ID__c, RecordType.Name from Account where Id = :bAO.accountId];
      System.debug('BenAdminOnboardingHelper findAcct: '+(acct==null?'null':acct.Id));          
      if(acct == null){
      	okay = false; 
      }
      return okay;
    } //findAcct
    
    /* find existing opportunity of ID was included in email */
    private static Boolean findOppty(benAdminOnb bAO) {
      Boolean okay = true;
     
      oppty = [Select Id, Name, Employees_Paid_Per_Payroll__c, OwnerId, AccountId, OpportunityType__c, 
               (Select Id, COBRA_Administration_Services__c, BalanceBenefits_Call_Center__c, Employer_Shared_Responsibility__c, Flock__c, 
                Flock_with_Payroll__c, Opportunity__c from Reference_Opportunity_Products__r) from Opportunity where Id = :bAO.opportunityId];        
      if(oppty == null){
      	okay = false; 
      }
      return okay;
    } //findOppty
    
    /* find existing sales rep of ID was included in email */
   	private static User getPayxUser(String personId) {
        User usr = [select Id, Name, Person_ID_Number__c, IsActive from User where Person_ID_Number__c =:personId and IsActive=True];   
        return usr;
   	} // getPayxUser
    
    private static PaychexSettings__c payxSetting = null;
       
    /* need to get rid of <> around email addresses that are notes, also shorten notes that are too long */
    private static String fixNotes(String toParse) {
        Integer idxBeginNotes = toParse.indexOf('<Notes>')+7;
        Integer idxEndNotes = toParse.indexOf('</Notes>');
        String prefix = toParse.Left(idxBeginNotes);
        String suffix = toParse.substring(idxEndNotes);
        String notes = toParse.substring(idxBeginNotes, idxEndNotes);
        notes = notes.replaceAll('<',' ');
        notes = notes.replaceAll('>',' ');
        if (notes.length() > 2000 ){
           notes = notes.Left(2000);   
        }
        
        return prefix+notes+suffix;        
    } // fixNotes
    
    /* this exception is used to throw missing data error messages */
    public class BenAdminException extends Exception {}
}