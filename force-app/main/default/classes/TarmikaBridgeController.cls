/* 
 * Tarmika Bridge controller for the lightning components
 *
 * History
    * -------
    10/17/2022 Carrie Marciano      Created
	12/06/2022 Jermaine Stukes		Added formatText Method
    03/03/2023 Reetesh Pandey		Apex code scan fix for validCheck(RecordId)
    1/23/2024  Carrie Marciano		Added newDQ.P_C_Quoted_Tool__c = 'Tarmika' so we can tell where the P&C Quote Data record is going
 */


public class TarmikaBridgeController { 
    //Wrapper returned to component
    public class OppWrapper{
        @AuraEnabled public PC_Quote_Data__c quoteRec;
        //validation fields
        @AuraEnabled public String OpptyProbability;
        @AuraEnabled public String OpptyRecordType; 
        @AuraEnabled public String OpptyQuote;
        //validation response fields
        @AuraEnabled public Boolean hasOpptyStage=False;
        @AuraEnabled public Boolean hasOpptyRecordType=False;
		@AuraEnabled public Boolean hasOpptyQuote=False;
		@AuraEnabled public Boolean hasValidUser=False;
        @AuraEnabled public Boolean validForBridge=False;
        @AuraEnabled public String validForBridgeMsg=null;
        @AuraEnabled public Boolean validRecCreate=False;
        @AuraEnabled public Boolean validAPICall=False;
        @AuraEnabled public String validAPICallMsg=null;
        @AuraEnabled public Boolean quoteCreated=False;
        @AuraEnabled public String quoteCreatedMsg=null;
        //PC_Quote_Data__c fields
        @AuraEnabled public String tarmikaIntegrationRecordId;      
        @AuraEnabled public String runningUserEmail;
        @AuraEnabled public String opptyId;
        @AuraEnabled public String opptyAcctId;
        @AuraEnabled public String opptyOwnerId;
        @AuraEnabled public String opptyType;
        @AuraEnabled public Decimal opptyEEPerPay;
        @AuraEnabled public Date opptyRenewalDate;
		@AuraEnabled public String acctName;
        @AuraEnabled public String acctOrgType;
        @AuraEnabled public String acctFedIdNum;
        @AuraEnabled public String acctShipStreet;
        @AuraEnabled public String acctShipCity;
        @AuraEnabled public String acctShipState;
        @AuraEnabled public String acctShipPostalCode;
        @AuraEnabled public String contFirstName;
        @AuraEnabled public String contLastName;
        @AuraEnabled public String contPhone;
        @AuraEnabled public String contEmail;
        @AuraEnabled public String quoteURL;
        @AuraEnabled public String quoteTool;
        
    } 
    
    public static String errorMsg;
    public static User runningUser;
    public static String HTML_YES='<font color="green"><b>YES</b></font>';
    public static String HTML_NO='<font color="red"><b>NO</b></font>';
    public static PC_Quote_Data__c digitalQuoteRec = null;
    
	@AuraEnabled 
    //make sure the criteria is met to allow a user to access the Tarmika Bridge
    public static OppWrapper validCheck(String recordId, Opportunity returnOpptyInfo){
        Opportunity currentOppty = null;
        Boolean validUser = False;
        Boolean isSuccess = false;
       
        ErrorLog__c log = new ErrorLog__c(ClassName__c='TarmikaBridgeController',MethodName__c='validCheck', CodeKey__c='LOG_DATA');
        
        String recidstr= String.escapeSingleQuotes(recordId);
        Id recId = Id.ValueOf(recidstr);
		
        OppWrapper returnWrapper = new OppWrapper();
        String[] fldList = new String[]{};
		Schema.FieldSet oppFldSet = Schema.SObjectType.Opportunity.fieldSets.PCQuoteData;
        for (Schema.FieldSetMember fsm : oppFldSet.getFields()) {
            String fldName = fsm.getFieldPath();
            fldList.add(fldName);
        }
		String queryString = 'Select '+String.join(fldList,',')
            +',(Select Contact.FirstName, Contact.LastName, Contact.Id, Contact.Email, Contact.Phone, Id, IsPrimary, Role, OpportunityId from OpportunityContactRoles WHERE IsPrimary = True)'     
            +' from Opportunity where Id =\'' + recId +'\'';
        
		currentOppty = Database.query(queryString);
        log.ObjectId__c= currentOppty.Id;
        log.ObjectAPIName__c='Opportunity';
		System.debug('validCheck queryString: '+queryString);
               
        validUser = isPCSalesUser();
        System.debug('validCheck runningUser.Email: '+runningUser.Email);
        
        if(currentOppty.Probability < Integer.valueOf(label.PCQuoteDataProbability) || currentOppty.RecordTypeId != label.PCQuoteDataRecordTypeId || 
           currentOppty.Tarmika_Quote__c != null || !validUser){
			returnWrapper.validForBridge = False;
            returnWrapper.validForBridgeMsg = 'Criteria to send to Bridge is not met.'; 
            returnWrapper.hasOpptyStage=(currentOppty.Probability >= Integer.valueOf(label.PCQuoteDataProbability)?True:False);
        	returnWrapper.hasOpptyRecordType=(currentOppty.RecordTypeId == label.PCQuoteDataRecordTypeId?True:False);
			returnWrapper.hasOpptyQuote=(currentOppty.Tarmika_Quote__c !=null?True:False);
			returnWrapper.hasValidUser=validUser; 
            String logMsg = 'validCheck validForBridge: '+returnWrapper.validForBridge+' validUser:' +returnWrapper.hasValidUser+' hasOpptyStage: '+returnWrapper.hasOpptyStage+' hasOpptyRecordType: '+returnWrapper.hasOpptyRecordType+' hasOpptyQuote: '+returnWrapper.hasOpptyQuote;
        	ErrorLog.addToDescription(log,logMsg);   
        }
        else{                                   
            returnWrapper.validForBridge = True;
            returnWrapper.runningUserEmail = runningUser.Email;
            returnWrapper.opptyId = currentOppty.Id;
            returnWrapper.opptyAcctId = currentOppty.Account.Id;
            returnWrapper.opptyOwnerId = currentOppty.OwnerId;
            returnWrapper.opptyType = currentOppty.OpportunityType__c;
            returnWrapper.opptyEEPerPay = (currentOppty.Employees_Paid_Per_Payroll__c != null?currentOppty.Employees_Paid_Per_Payroll__c:0);
            returnWrapper.opptyRenewalDate = (currentOppty.Renewal_Date__c != null?currentOppty.Renewal_Date__c:null);
            returnWrapper.acctName = currentOppty.Account.Name;
            returnWrapper.acctOrgType = currentOppty.Account.Organization_Type__c;
            returnWrapper.acctFedIdNum = currentOppty.Account.Federal_ID_Number__c;
            returnWrapper.acctShipStreet = currentOppty.Account.ShippingStreet;
            returnWrapper.acctShipCity = currentOppty.Account.ShippingCity;
            returnWrapper.acctShipState = currentOppty.Account.ShippingState;
            returnWrapper.acctShipPostalCode = currentOppty.Account.ShippingPostalCode;
            returnWrapper.contFirstName = currentOppty.OpportunityContactRoles[0].Contact.FirstName;
            returnWrapper.contLastName = currentOppty.OpportunityContactRoles[0].Contact.LastName;
            returnWrapper.contPhone = currentOppty.OpportunityContactRoles[0].Contact.Phone;
            returnWrapper.contEmail = currentOppty.OpportunityContactRoles[0].Contact.Email;
            returnWrapper.hasOpptyStage=(currentOppty.Probability >= Integer.valueOf(label.PCQuoteDataProbability)?True:False);
        	returnWrapper.hasOpptyRecordType=(currentOppty.RecordTypeId == label.PCQuoteDataRecordTypeId?True:False);
			returnWrapper.hasOpptyQuote=(currentOppty.Tarmika_Quote__c !=null?True:False);
			returnWrapper.hasValidUser=validUser; 
            String logMsg = 'validCheck validForBridge: ' +returnWrapper.validForBridge;
        	ErrorLog.addToDescription(log,logMsg); 
               
            //create staging record
            try{
                System.debug('validCheck createDigitalQuoteRecord');
                digitalQuoteRec = createDigitalQuoteRecord(returnWrapper); 
            	returnWrapper.validRecCreate = true;
			  	returnWrapper.validForBridgeMsg = 'P&C Quote Data record created.'; 
        		ErrorLog.addToDescription(log,'validCheck validRecCreate: ' +returnWrapper.validRecCreate);
                
            }
            catch (Exception e){
                System.debug('Exception='+e);
         		errorMsg = e.getMessage();
                ErrorLog.logError('TarmikaBridgeController', 'validCheck', 'insert P&C Quote Data', currentOppty.Id, errorMsg, currentOppty, true);				
                returnWrapper.validRecCreate = False;
                returnWrapper.validForBridgeMsg = 'There was an issue creating P&C Quote record, did not send to Tarmika Bridge.'+errorMsg;
            }
        }

        System.debug('validCheck returnWrapper.hasOpptyStage: '+returnWrapper.hasOpptyStage); 
        System.debug('validCheck returnWrapper.hasOpptyRecordType: '+returnWrapper.hasOpptyRecordType);
        System.debug('validCheck returnWrapper.hasOpptyQuote: '+returnWrapper.hasOpptyQuote);
        System.debug('validCheck returnWrapper.hasValidUser: '+returnWrapper.hasValidUser); 
        System.debug('validCheck returnWrapper.validForBridge: '+returnWrapper.validForBridge);
        System.debug('validCheck returnWrapper.validRecCreate: '+returnWrapper.validRecCreate);
        System.debug('validCheck returnWrapper.validForBridgeMsg: '+returnWrapper.validForBridgeMsg);
		
        ErrorLog.saveLog(log);
        
        return returnWrapper;
	}
    
    public static String formatText(String valueToCheck) {
        // make sure we're not returning a null value
        String retValue = (String.isNotBlank(valueToCheck) ? valueToCheck : '');
        return retValue;
    } // formatText
    
    @AuraEnabled
    public static OppWrapper postCall(PC_Quote_Data__c digitalQuoteRec) {
        System.debug('postCall digitalQuoteRec.Opportunity_Type__c: '+digitalQuoteRec.Opportunity_Type__c);
        String Token;
        String webServiceName;
        String response;
        Integer resCode;
        String resBody;
        String errResp;
        String resURL;
        
        ErrorLog__c log = new ErrorLog__c(ClassName__c='TarmikaBridgeController',MethodName__c='postCall', CodeKey__c='LOG_DATA');
        
        OppWrapper returnWrapperAPI = new OppWrapper();
        returnWrapperAPI.opptyId = digitalQuoteRec.Opportunity__c;
        
        //call class to get token
        Token = TarmikaBridgeToken.getToken();
        System.debug('postCall Token: '+Token);
        
        if (Token != null){
			ErrorLog.addToDescription(log, 'postCall received Token from Tarmika');
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            
            if(digitalQuoteRec.Opportunity_Type__c == 'BOP (Business Owners Package)'){
                webServiceName = 'TarmikaBOP';
            }
            else if (digitalQuoteRec.Opportunity_Type__c == 'Workers Comp'){    
                webServiceName = 'TarmikaWC';
            }
                
            WebServiceSettings__c wss = WebServicesHelper.getWebSvcSetting(webServiceName); 
            if (String.isNotBlank(wss.Timeout__c)) {
                try {
                    Integer timeout = Integer.valueOf(wss.Timeout__c);
                    req.setTimeout(timeout);
                } catch (Exception e) {
                    System.debug('Error setting timeout: '+e.getMessage()+'; '+e.getStackTraceString());
                }
            } // if (String.isNotBlank 
            System.debug('postCall wss: '+wss);
            if (wss.NamedCredential__c) {
                req.setEndpoint(wss.Comment__c);
            } else {
                req.setEndpoint(wss.Endpoint__c);
            }
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            //req.setHeader('Authorization', 'Bearer 4c8554e5-8245-4a9c-9d63-aa7912f08ec8');
            req.setHeader('Authorization', 'Bearer '+Token);
            
            System.debug('postCall buildPostBody');
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            if(digitalQuoteRec.Opportunity_Type__c == 'BOP (Business Owners Package)'){
                gen.writeFieldName('quoteRequestHeader');
                gen.writeStartObject();
                gen.writeStringField('requestIdentifier',formatText(digitalQuoteRec.Id));
                gen.writeDateField('requestDate', System.today());
                gen.writeFieldName('agency');
                gen.writeStartObject();
                gen.writeStringField('userName',formatText(digitalQuoteRec.Submitted_By__c));
                gen.writeEndObject();
                gen.writeEndObject();
                gen.writeFieldName('quoteRequest');
                gen.writeStartObject();
                gen.writeFieldName('namedInsured');
                gen.writeStartObject();
                gen.writeFieldName('organization');
                gen.writeStartObject();
                gen.writeStringField('name',formatText(digitalQuoteRec.Prospect_Client_Name__c));
                gen.writeStringField('typeOfEntity',formatText(digitalQuoteRec.Organization_Type__c));
                gen.writeStringField('yearOfCommencementOfBusiness','');
                gen.writeFieldName('locationAddress');
                gen.writeStartObject();
                gen.writeStringField('addressText',formatText(digitalQuoteRec.Prospect_Client_Address_Text__c));
                gen.writeStringField('addressLine1',formatText(digitalQuoteRec.Prospect_Client_Street__c));
                gen.writeStringField('city',formatText(digitalQuoteRec.Prospect_Client_City__c));
                gen.writeStringField('stateCode',formatText(digitalQuoteRec.Prospect_Client_State__c));
                gen.writeStringField('county','');
                gen.writeStringField('postalCode',formatText(digitalQuoteRec.Prospect_Client_Postal_Code__c));
                gen.writeStringField('country','');
                gen.writeEndObject();
                gen.writeEndObject();
                gen.writeEndObject();
                gen.writeFieldName('quoteContact');
                gen.writeStartObject();
                gen.writeFieldName('person');
                gen.writeStartObject();
                gen.writeStringField('firstName',formatText(digitalQuoteRec.Contact_First_Name__c));
                gen.writeStringField('lastName',formatText(digitalQuoteRec.Contact_Last_Name__c));
                gen.writeStringField('emailAddress',formatText(digitalQuoteRec.Contact_Email_Address__c));
                gen.writeStringField('phoneNumber',formatText(digitalQuoteRec.Contact_Phone_Number__c));
                gen.writeEndObject();
                gen.writeEndObject();
                if(digitalQuoteRec.Renewal_Date__c == null){
                   gen.writeNullField('policyStartDate'); 
                } else {
                   gen.writeDateField('policyStartDate',digitalQuoteRec.Renewal_Date__c); 
                }
                //gen.writeDateField('policyStartDate',digitalQuoteRec.Renewal_Date__c);
                gen.writeFieldName('insurableBusinessUnitInformation');
                gen.writeStartArray();
                gen.writeStartObject();
                gen.writeFieldName('generalBusinessInformation');
                gen.writeStartObject();
                if(digitalQuoteRec.Employees_Paid_Per_Payroll__c == null || digitalQuoteRec.Employees_Paid_Per_Payroll__c <= 0){
                   gen.writeNullField('numberOfEmployees'); 
                } else {
                   gen.writeNumberField('numberOfEmployees',digitalQuoteRec.Employees_Paid_Per_Payroll__c); 
                }
                //gen.writeNumberField('numberOfEmployees',digitalQuoteRec.Employees_Paid_Per_Payroll__c);
                gen.writeEndObject();
                gen.writeEndObject();
                gen.writeEndArray();
                gen.writeEndObject();
                gen.writeEndObject();  
            }
            else if(digitalQuoteRec.Opportunity_Type__c == 'Workers Comp'){
                gen.writeFieldName('quoteRequestHeader');
                gen.writeStartObject();
                gen.writeStringField('requestIdentifier',formatText(digitalQuoteRec.Id));
                gen.writeDateField('requestDate', System.today());
                gen.writeFieldName('agency');
                gen.writeStartObject();
                gen.writeStringField('userName',formatText(digitalQuoteRec.Submitted_By__c));
                gen.writeEndObject();
                gen.writeEndObject();
                gen.writeFieldName('quoteRequest');
                gen.writeStartObject();
                gen.writeFieldName('namedInsured');
                gen.writeStartObject();
                gen.writeFieldName('organization');
                gen.writeStartObject();
                gen.writeStringField('name',formatText(digitalQuoteRec.Prospect_Client_Name__c));
                gen.writeStringField('typeOfEntity',formatText(digitalQuoteRec.Organization_Type__c));
                gen.writeStringField('taxIDType','FEIN');
                gen.writeStringField('taxIDNumber',formatText(digitalQuoteRec.Federal_Id_Number__c));
                gen.writeFieldName('locationAddress');
                gen.writeStartObject();
                gen.writeStringField('addressText',formatText(digitalQuoteRec.Prospect_Client_Address_Text__c));
                gen.writeStringField('addressLine1',formatText(digitalQuoteRec.Prospect_Client_Street__c));
                gen.writeStringField('city',formatText(digitalQuoteRec.Prospect_Client_City__c));
                gen.writeStringField('stateCode',formatText(digitalQuoteRec.Prospect_Client_State__c));
                gen.writeStringField('county','');
                gen.writeStringField('postalCode',formatText(digitalQuoteRec.Prospect_Client_Postal_Code__c));
                gen.writeStringField('country','');
                gen.writeEndObject();
                gen.writeEndObject();
                gen.writeEndObject();
                gen.writeFieldName('quoteContact');
                gen.writeStartObject();
                gen.writeFieldName('person');
                gen.writeStartObject();
                gen.writeStringField('firstName',formatText(digitalQuoteRec.Contact_First_Name__c));
                gen.writeStringField('lastName',formatText(digitalQuoteRec.Contact_Last_Name__c));
                gen.writeStringField('emailAddress',formatText(digitalQuoteRec.Contact_Email_Address__c));
                gen.writeStringField('phoneNumber',formatText(digitalQuoteRec.Contact_Phone_Number__c));
                gen.writeEndObject();
                gen.writeEndObject();
                System.debug('postCall WC digitalQuoteRec.Renewal_Date__c: '+digitalQuoteRec.Renewal_Date__c);
                if(digitalQuoteRec.Renewal_Date__c == null){
                   gen.writeNullField('policyStartDate'); 
                } else {
                   gen.writeDateField('policyStartDate',digitalQuoteRec.Renewal_Date__c); 
                }
                //gen.writeDateField('policyStartDate',digitalQuoteRec.Renewal_Date__c);
                gen.writeFieldName('insurableBusinessUnitInformation');
                gen.writeStartObject();
                gen.writeFieldName('generalBusinessInformation');
                gen.writeStartObject();
                System.debug('postCall WC digitalQuoteRec.Employees_Paid_Per_Payroll__c: '+digitalQuoteRec.Employees_Paid_Per_Payroll__c);
                if(digitalQuoteRec.Employees_Paid_Per_Payroll__c == null || digitalQuoteRec.Employees_Paid_Per_Payroll__c <= 0){
                   gen.writeNullField('numberOfEmployees'); 
                } else {
                   gen.writeNumberField('numberOfEmployees',digitalQuoteRec.Employees_Paid_Per_Payroll__c); 
                }
                //gen.writeNumberField('numberOfEmployees',digitalQuoteRec.Employees_Paid_Per_Payroll__c);
                gen.writeEndObject();
                gen.writeEndObject();
                gen.writeEndObject();
                gen.writeEndObject();  	    
            }
            
            System.debug('postCall gen: '+gen.getAsString());
            ErrorLog.addToDescription(log, 'postCall json: '+gen.getAsString());
            req.setBody(gen.getAsString());
            HTTPResponse res = new HttpResponse();
            
            try{                
                res = http.send(req); 
                if(res !=null){
                    resCode = res.getStatusCode();
                    System.debug('postCall resCode:'+resCode);
                    resBody = res.getBody();                   
                    System.debug('postCall resBody:'+resBody);
                    if (String.isNotBlank(resBody)){ 
                        if(resCode == 401){
                            errResp = String.valueOf(resBody); 
                            returnWrapperAPI.validAPICall = false;
                            returnWrapperAPI.validAPICallMsg = 'Error connecting to Tarmika. '+errResp; 
                            ErrorLog.addToDescription(log, 'postCall Error connecting to Tarmika: '+errResp);
                        } else {
                            Map<String,Object> respMap = (Map<String,Object>)JSON.deserializeUntyped(resBody);                        
                            for(String key: respMap.keySet()){
                                Object respObj = respMap.get(key);
                                System.debug('postCall key: '+key+' respObj: '+respObj);                                                        
                                if(key == 'quoteResponseDetail'){
                                    Map<String,Object> lobMap = (Map<String,Object>)respObj; 
                                    if(lobMap.containsKey('lineOfBusinessQuote')){
                                        Object[] lobs = (Object[])lobMap.get('lineOfBusinessQuote');
                                        for(object lob : lobs){
                                            Map<String,Object> lobMap2 = (Map<String,Object>)lob;
                                            System.debug('postCall lobMap2 keys: '+lobMap2.keySet());
                                            for (String lobkey : lobMap2.keySet()){
                                                System.debug('postCall lobkey: '+lobkey);
                                                if(lobkey =='quoteLinkURL'){
                                                    returnWrapperAPI.quoteURL = String.valueOf(lobMap2.get(lobkey));                   
                                                    returnWrapperAPI.validAPICall = true;
                                                    returnWrapperAPI.validAPICallMsg = 'P&C Quote Data successfully sent to Tarmika.'; 
                                                    System.debug('postCall returnWrapperAPI.quoteURL: '+returnWrapperAPI.quoteURL);
                                                    updateOppty(returnWrapperAPI);
                                                    returnWrapperAPI.quoteCreated = true;
                                                    returnWrapperAPI.quoteCreatedMsg = 'Tarmika quote created.';
                                                    ErrorLog.addToDescription(log, 'postCall P&C Quote Data successfully sent to Tarmika, Quote Returned: '+returnWrapperAPI.quoteURL);
                                                    break; 
                                                } //if lobkey
                                            } //for lobMap2.keySet()                                    
                                        } //for lobs
                                    } //if lobMap 
                                } else if(key == 'errors'){
                                    //Map<String,Object> errMap = (Map<String,Object>)respObj;                                      
                                    //if (errMap.containsKey('errors')){
                                    Object[] errs = (Object[])respMap.get('errors');
                                    for(object err : errs){
                                        Map<String,Object> errMap2 = (Map<String,Object>)err;
                                        System.debug('postCall errMap2 keys: '+errMap2.keySet());
                                        for (String errkey : errMap2.keySet()){
                                            System.debug('postCall errkey: '+errkey);
                                            if(errkey =='errorDescription'){                                                
                                                errResp = String.valueOf(errMap2.get(errkey));
                                                returnWrapperAPI.validAPICall = false;
                                                returnWrapperAPI.validAPICallMsg = 'Error connecting to Tarmika. '+errResp;	
                                                ErrorLog.addToDescription(log, 'postCall Error connecting to Tarmika: '+errResp);
                                                System.debug('postCall errResp: '+errResp); 
                                            } //if errkey
                                        } //for errMap2.keySet()                                    
                                    } //for errs
                                    //}// if contains key                                     
                                } //if key
                            } //for respMap.keySet() 
                        }//if resCode                                                    
                    }//if resBody not blank 
                }//if res != null	                
            }    
            catch(System.CalloutException e){ 
                System.debug('postCall Error in HTTPS');
                resBody = e.getMessage();
                resCode = res.getStatusCode();
                ErrorLog.logError('TarmikaBridgeController', 'postCall', 'Error in HTTPS', digitalQuoteRec.Id, resBody, digitalQuoteRec, true);
                System.debug('postCall resCode:'+resCode+'\nerror: '+resBody);
                System.debug('postCall res: '+res.toString());
            }
        } else {
            ErrorLog.logError('TarmikaBridgeController', 'postCall', 'invalid Tarmika Token', digitalQuoteRec.Id, errorMsg, digitalQuoteRec, true);	
        }
        
        ErrorLog.saveLog(log);
    	return returnWrapperAPI;       
    } //postCall
    
    public static void updateOppty(OppWrapper returnWrapper){
        if(returnWrapper.opptyId != null && returnWrapper.quoteURL != null){
            system.debug('updateOppty have OpptyId and quote URL');
            Opportunity opptoUpdate = [Select Id, Name, Tarmika_Quote__c from Opportunity where Id =:returnWrapper.opptyId];
            opptoUpdate.Tarmika_Quote__c = returnWrapper.quoteURL;
            update opptoUpdate;
        }    
    }

    public static Boolean isPCSalesUser(){
        String[] dqSalesOrgs = Label.PCQuoteDataSalesOrg.split(',');
        runningUser = UserHelper.getRunningUser();
        System.debug('isPCSalesUser runningUser: '+runningUser);
        //System.debug('Running User: ' + u.Name + ', Sales Org: ' + u.Sales_Org__c);
        return (runningUser != null && dqSalesOrgs.contains(runningUser.Sales_Org__c)) ;   
    } // isPCSalesUser
    
    
    public static PC_Quote_Data__c createDigitalQuoteRecord(OppWrapper returnWrapper){
        Boolean okay = true;
        PC_Quote_Data__c newDQ = new PC_Quote_Data__c();
        
        If(returnWrapper != null){
           	newDQ.Submitted_By__c = returnWrapper.runningUserEmail;  
          	newDQ.Opportunity__c =  returnWrapper.opptyId;
            newDQ.Prospect_Client__c = returnWrapper.opptyAcctId;
           	newDQ.Opportunity_Type__c = returnWrapper.opptyType;
            newDQ.Employees_Paid_Per_Payroll__c = returnWrapper.opptyEEPerPay;
            newDQ.Renewal_Date__c = returnWrapper.opptyRenewalDate;
            newDQ.Prospect_Client_Name__c = returnWrapper.acctName;
            newDQ.Organization_Type__c = returnWrapper.acctOrgType;
            newDQ.Federal_Id_Number__c = returnWrapper.acctFedIdNum;
            newDQ.Prospect_Client_Street__c = returnWrapper.acctShipStreet;
            newDQ.Prospect_Client_City__c = returnWrapper.acctShipCity;
            newDQ.Prospect_Client_State__c = returnWrapper.acctShipState;
            newDQ.Prospect_Client_Postal_Code__c = returnWrapper.acctShipPostalCode;
            if(returnWrapper.acctShipStreet == null || returnWrapper.acctShipCity == null || returnWrapper.acctShipState == null || returnWrapper.acctShipPostalCode == null){
            	newDQ.Prospect_Client_Address_Text__c = '';
              	system.debug('createDigitalQuoteRecord blank addresstext');  
            } else {
              	newDQ.Prospect_Client_Address_Text__c = formatText(returnWrapper.acctShipStreet) + ', ' + formatText(returnWrapper.acctShipCity) + ', ' + formatText(returnWrapper.acctShipState) + ' ' + formatText(returnWrapper.acctShipPostalCode);   
              	system.debug('createDigitalQuoteRecord addresstext created');  
            } 
            newDQ.Contact_First_Name__c = returnWrapper.contFirstName;
            newDQ.Contact_Last_Name__c = returnWrapper.contLastName;
            newDQ.Contact_Phone_Number__c = returnWrapper.contPhone;
            newDQ.Contact_Email_Address__c = returnWrapper.contEmail;
            newDQ.P_C_Quoted_Tool__c = 'Tarmika';
            
            insert newDQ;
            returnWrapper.quoteRec = newDQ;
        }
        
    	return newDQ;
        
    } // createDigitalQuoteRecord
    
/*  API structures
 POST for WC
 				{
                    "quoteRequestHeader": {
                      "requestIdentifier": "0000009584",
                      "requestDate": "2021-11-15T00:00:00.000Z",
                      "partnerIdentifier": "ACME"
                    },
                    "quoteRequest": {
                      "namedInsured": {
                        "organization": {
                          "name": "Test WC POS API",
                          "typeOfEntity": "ASSOCIATION",
                          "yearOfCommencementOfBusiness": "2010",
                          "taxIDType": "FEIN",
                          "taxIDNumber": "987496223",
                          "locationAddress": {
                            "addressText": "6621 Fannin St, Houston, TX 77030, USA",
                            "addressLine1": "6621 Fannin Street",
                            "city": "Houston",
                            "state": "Texas",
                            "stateCode": "TX",
                            "county": "Harris County",
                            "postalCode": "77030"
                          },
                          "mailingAddress": {
                            "mailingAddressSameAsLocationAddress": "false",
                            "address": {
                              "addressText": "400 Bizzell St, College Station, TX 77843, USA",
                              "addressLine1": "400 Bizzell Street",
                              "city": "College Station",
                              "state": "Texas",
                              "stateCode": "TX",
                              "county": "Brazos County",
                              "postalCode": "77843"
                            }
                          }
                        }
                      },
                      "quoteContact": {
                        "person": {
                          "firstName": "George",
                          "lastName": "smith",
                          "emailAddress": "George@gmail.com",
                          "phoneNumber": "8870623080"
                        }
                      },
                      "policyStartDate": "2021-12-07T00:00:00.000Z",
                      "typeOfBusiness": "444130-002",
                      "typeOfBusinessDescription": "Hardware stores",
                      "generalBusinessInformation": {
                        "yearsOfManagementExperience": 10,
                        "policyCancelledOrNonRenewed": false,
                        "operatedWithoutInsuranceCoverage": false
                      },
                      "insurableBusinessUnitInformation": {
                        "generalBusinessInformation": {
                          "annualRevenue": 500000,
                          "numberOfEmployees": 10,
                          "totalPayroll": 19888
                        }
                      },
                      "insurableBusinessUnitInformationList": [
                        {
                          "businessUnitDescription": "HeadQuarters",
                          "building": {
                            "address": {
                              "addressText": "6621 Fannin St, Houston, TX 77030, USA",
                              "addressLine1": "6621 Fannin Street",
                              "city": "Houston",
                              "state": "Texas",
                              "stateCode": "TX",
                              "county": "Harris County",
                              "postalCode": "77030"
                            }
                          },
                          "generalBusinessInformation": {
                            "annualRevenue": 500000
                          },
                          "generalClassificationInformation": [
                            {
                              "classCode": "3146-0022",
                              "classDescription": "Hardware Manufacturing Noc",
                              "numberOfEmployees": "15",
                              "numberOfEmployeesFullTime": 10,
                              "numberOfEmployeesPartTime": 5,
                              "totalPayRoll": "90000"
                            }
                          ]
                        }
                      ]
                    }
                  }
 
 
 
 POST for BOP
 					{
                        "quoteDataHeader": {
                            "quoteDataTransmissionDate": "2022-10-27T09:51:28.000Z",
                            "externalQuoteRequestIdentifier": "0000002069",
                            "quoteRequestDate": "2022-09-02T00:00:00.000Z",
                            "internalQuoteRequestIdentifier": "0000047450",
                            "quoteLinkURL": "https://urldefense.com/v3/__https://demo.tarmika.com/agentportal/?quotelink=2Uzam0sF1jsdwZakugmCOYL8MNXiBVJci2IgUaF40ao2Ut4YkJcKCDK*2BrOBL*2FzR2U*2FLLe*2FS7o57n*0ADqxKS0dBm2tl8jaN26gpx*2Boqt6*2BNdtZWAAIQr5wbBmjm89NR7j5fwzD6H*2FCojyoMDCFNkoVCqQ*3D*3D__;JSUlJSUlJSUlJQ!!PIfy-9xbww!EhRLToRaMGbMUO7k4CDwZfVcabNGnHrwyXmib77Ry-V6EOpg3wdjKSpoKrZiQ8ntJhX-OwFcZ-jIsgYBFA36Wcab_g$  ",
                            "lineOfBusiness": "BOP",
                            "agency": {
                                "userName": "quotingagent@acmeagency.com"
                            }
                        },
                        "quoteDataDetail": {
                            "namedInsured": {
                                "organization": {
                                    "name": "Test BOP Cycle 01",
                                    "typeOfEntity": "CORPORATION",
                                    "yearOfCommencementOfBusiness": "2019",
                                    "taxIDType": "FEIN",
                                    "locationAddress": {
                                        "addressText": "544  Massachusetts  Ave Boston, MA 02118",
                                        "addressLine1": "544  Massachusetts  Ave",
                                        "city": "Boston",
                                        "stateCode": "MA",
                                        "county": "Suffolk",
                                        "postalCode": "02118"
                                    },
                                    "mailingAddress": {
                                        "mailingAddressSameAsLocationAddress": "false",
                                        "address": {
                                            "addressText": "400  Texas a and M Univ   College Station, TX 77843",
                                            "addressLine1": "400  Texas a and M Univ  ",
                                            "city": "College Station",
                                            "stateCode": "TX",
                                            "postalCode": "77843"
                                        }
                                    }
                                }
                            },
                            "quoteContact": {
                                "person": {
                                    "firstName": "Marry",
                                    "lastName": "S",
                                    "emailAddress": "marry@amc.com",
                                    "phoneNumber": "9874513003"
                                }
                            },
                            "policyStartDate": "2022-10-01T00:00:00.000Z",
                            "typeOfBusiness": "444130-002",
                            "typeOfBusinessDescription": "Hardware stores",
                            "generalBusinessInformation": {
                                "yearsOfManagementExperience": 5,
                                "anyDesignatedPastLossesOrClaims": "false",
                                "priorPolicyInformation": {
                                    "hasPriorPolicy": "false"
                                }
                            },
                            "insurableBusinessUnitInformation": [
                                {
                                    "building": {
                                        "ownedBuilding": "true",
                                        "yearOfConstruction": 2010,
                                        "builtUpArea": 1500,
                                        "replacementCost": 30000,
                                        "typeOfConstruction": "WOODFRAME",
                                        "numberOfStories": 1,
                                        "numberOfUnits": 1,
                                        "soleOccupant": "true",
                                        "yearOfRenovation": 2018,
                                        "buildingSprinklered": "false",
                                        "equippedWithFireAlarm": "CENTRAL-STATION",
                                        "equippedWithBurglarAlarm": "CENTRAL-STATION",
                                        "condoUnit": "false",
                                        "flatRoofed": "true"
                                    },
                                    "generalBusinessInformation": {
                                        "annualRevenue": 211222,
                                        "numberOfEmployees": 20,
                                        "totalPayroll": 198888
                                    },
                                    "classSpecificBusinessInformation": {
                                        "areaOccupied": 1200,
                                        "areaOccupiedByOthers": 300,
                                        "valueOfContentsWithinBusiness": 10000,
                                        "questionAnswer": [
                                            {
                                                "questionCode": "BOP-14",
                                                "answer": "false"
                                            },
                                            {
                                                "questionCode": "BOP-147",
                                                "answer": "false"
                                            },
                                            {
                                                "questionCode": "BOP-25",
                                                "answer": "false"
                                            },
                                            {
                                                "questionCode": "BOP-26",
                                                "answer": "false"
                                            },
                                            {
                                                "questionCode": "BOP-28",
                                                "answer": "false"
                                            },
                                            {
                                                "questionCode": "BOP-29",
                                                "answer": "false"
                                            },
                                            {
                                                "questionCode": "BOP-39",
                                                "answer": "false"
                                            },
                                            {
                                                "questionCode": "BOP-47",
                                                "answer": "434"
                                            },
                                            {
                                                "questionCode": "BOP-7",
                                                "answer": "false"
                                            },
                                            {
                                                "questionCode": "BOP-591",
                                                "answer": "false"
                                            },
                                            {
                                                "questionCode": "BOP-592",
                                                "answer": "true"
                                            },
                                            {
                                                "questionCode": "BOP-580",
                                                "answer": "store"
                                            }
                                        ]
                                    }
                                }
                            ],
                            "policyCoverage": {
                                "employmentPracticesLiabilityCoverageRequired": "false",
                                "cyberCoverageRequired": "false",
                                "generalLiabilityLimit": "1,000,000/2,000,000",
                                "propertyDeductible": "500",
                                "hiredAndNonOwnedCoverageRequired": "false",
                                "equipmentBreakdownCoverageRequired": "false",
                                "employeeDishonestyCoverageRequired": "false",
                                "employeeBenefitsCoverageRequired": "false",
                                "employeeBenefitsProofOfCoverage": "true",
                                "employmentPracticesLiabilityProofOfCoverage": "true"
                            },
                            "insurerSpecificInformation": [
                                {
                                    "insurerIdentifier": "0000004",
                                    "insurerName": "Liberty Mutual Insurance",
                                    "insurerShortName": "LibertyMutual",
                                    "insurerClassification": {
                                        "classCode": "80091",
                                        "classDescription": "Regular BOP - Hardware Stores",
                                        "classGroup": "Regular",
                                        "displayText": "Regular BOP - Hardware Stores(80091)"
                                    }
                                }
                            ]
                        }
                    }     
  
 
  Response from Tarmika  
      {
        "status": {
            "statusCode": "Success",
            "statusDescription": "Request processed successfully"
        },
        "messages": [
            {
                "messageDescription": "Insured Business data saved"
            }
        ],
        "errors": [],
        "quoteResponseHeader": {
            "quoteResponseIdentifier": "0b981714-ace0-4c52-be1c-dc00b08327b2",
            "externalQuoteRequestIdentifier": "0000009574",
            "quoteResponseDate": 1670333939000,
            "internalQuoteRequestIdentifier": "0000063054",
            "agency": {
                "agencyNumber": null,
                "producerCode": null,
                "userName": "akosel@paychex.com",
                "password": null
            },
            "quoteProcessingStatus": {
                "statusCode": "Saved as Draft Quote Request",
                "statusDescription": null
            }
        },
        "quoteResponseDetail": {
            "lineOfBusinessQuote": [
                {
                    "lineOfBusiness": "WC",
                    "internalQuoteRequestIdentifier": "0000056175",
                    "quoteLinkURL": "https://demo.tarmika.com/agentportal/?quotelink=2Uzam0sF1jsdwZakugmCOYL8MNXiBVJci2IgUaF40aqLSzY3JqKAMCe5yhzh5GLAU%2FLLe%2FS7o57n%0ADqxKS0dBm8Z%2F2sQSMBM5Kyrkh5HZK8sppIiO3UPqA3SVJPiV9IaArJ4NcNxoti45mVN0KXwzbg%3D%3D"
                }
            ],
            "insurerQuoteResponse": {
                "insurerName": null,
                "insurerQuoteNumber": null,
                "insurerQuoteStatus": null,
                "totalPremium": null,
                "insurerQuoteLinkURL": null,
                "insurerQuoteStatusRemarks": null,
                "proposalDocument": null,
                "lineOfBusiness": null,
                "quoteProcessingIdentifier": null,
                "quoteResponseStatus": null
            }
        }
    }
  
 */  
}