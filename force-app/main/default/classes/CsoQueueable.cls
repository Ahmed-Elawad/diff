/** CSO Queueable used for validation
 * 
 * History
 * -------
   04/19/2022   Jermaine Stukes Created
   10/25/2022   Dan Carmen      Additional changes for CSO/Enterprise registraion
   04/01/2023   Dan Carmen      Don't require user validation
   11/13/2023   Dan Carmen      Handle SSN for validation call
   01/11/2024   Dan Carmen      Add ceid to AcctCsoWrap
   02/08/2024   Dan Carmen      format the City for the validation call
 
 */
public class CsoQueueable implements Queueable, Database.AllowsCallouts{ 
	
    public static final String CLASSNAME='CsoQueueable';
    
    // Do we use this for both CSO and Enterprise validation?
    public static final String VALIDATE_ACCT_CSO='CSO_Account_Validation';
    public static final String VALIDATE_ACCT_ENT='Enterprise Account Validation';
    // this is only for CSO
    public static final String VALIDATE_USER='CSO_User_Validation';
    public static Boolean ALLOW_USER_VAL=(Label.CSO_UserValidation == 'True');
    public static Boolean SKIP_TRIGGERS=false;
    
    //public Account[] accts;
    //public Map<Id, CSO_Tracking__c> csoMap;
    //public Boolean relaunchForUserValidation = false;
    public List<CSO_Tracking__c> csoUpdateList = new List<CSO_Tracking__c>();
    //public String accountName{get;set;}
    public String validationType;
    
    public AcctCsoWrap[] recsToProcess = new AcctCsoWrap[]{};
        
    public Class AcctCsoWrap {
       public AcctCsoWrap(AcctCsoWrap p_wrap) {
          acct=p_wrap.acct;
          cso= P_wrap.cso;
       } // AccCsoWrap
        
       public AcctCsoWrap(Account p_acct, CSO_Tracking__c p_cso) {
          acct = p_acct;
          cso = p_cso;
          validateClient = (cso != null && !cso.ClientDataValidated__c);
          validateUser = (cso != null && cso.CanUseCSO__c && !cso.User_Validated__c);
          System.debug('AcctCsoWrap validateClient='+validateClient+' validateUser='+validateUser+' cso.User_Validated__c='+(cso != null ? cso.User_Validated__c : false));
       } // public AcctCsoWrap
       public Account acct;
       // if multi id, child accounts
       public Account[] accts = new Account[]{};
       // if multi id, child records
       public AcctCsoWrap[] children = new AcctCsoWrap[]{};
       public CSO_Tracking__c cso;
       public Opportunity opp;
       // for a multi-id client, store the ceid here to use in the message
       public String ceid;
       // the address ids of the billing and shipping addresses
       // this is so if we get an error back from a non-legal, we can identify what type of address it was
       public Set<String> billingIdSet = new Set<String>();
       public Set<String> shippingIdSet = new Set<String>();
       public Boolean validateClient = false;
       public Boolean validateUser = false;
       // keep track so we only try once
       public Boolean clientValidationAttempted = false;
       public Boolean userValidationAttempted = false;
       public Boolean useClientValidation() {
          return (validateClient && !clientValidationAttempted);
       } // useClientValidation
       public Boolean useUserValidation() {
          return (validateUser && !userValidationAttempted);
       }
       public String setRequestStart(String requestType) {
          String requestKey = null;
          cso.UserFacingError__c = false;
          if (requestType == VALIDATE_ACCT_ENT || requestType == VALIDATE_ACCT_CSO
                || requestType == EZOnboardingRegistration.CLT_VALIDATE || requestType == EZOnboardingRegistration.CLT_VALIDATE_ADDR) {
             cso.ValidationStart__c=Datetime.now();
             cso.ValidationEnd__c=null;
             cso.ValidationStatusCode__c=null;
             cso.ValidationDetail__c=null;
          } else if (requestType == EZOnboardingRegistration.REG_CSO || requestType == EZOnboardingRegistration.REG_ENT) {
             cso.RegistrationStart__c=Datetime.now();
             cso.RegistrationEnd__c=null;
             cso.RegistrationStatusCode__c = null;
             cso.RegistrationDetail__c = null;
             cso.RegistrationDetail2__c = null;
             cso.RegistrationUUID__c = (String.isNotBlank(cso.RegistrationUUID__c) ? cso.RegistrationUUID__c : System.UUID.randomUUID().toString());
             requestKey = cso.RegistrationUUID__c;
          } else if (requestType == EZOnboardingRegistration.REG_CLT_UPDATE) {
             cso.RegUpdateStart__c=Datetime.now();
             cso.RegUpdateEnd__c=null;
             cso.RegUpdateStatusCode__c = null;
             cso.RegUpdateDetail__c = null;
             cso.RegUpdateUUID__c = (String.isNotBlank(cso.RegUpdateUUID__c) ? cso.RegUpdateUUID__c : System.UUID.randomUUID().toString());
             requestKey = cso.RegUpdateUUID__c;
          } else if (requestType == EZOnboardingRegistration.OSS_KEYS) {
             if (cso.OSSKeysFirstAttempt__c == null) {
                cso.OSSKeysFirstAttempt__c = Datetime.now();
             }
             cso.OSSKeysStart__c=Datetime.now();
             cso.OSSKeysEnd__c = null;
             cso.OSSKeysStatusCode__c = null;
             cso.OSSKeysDetail__c = null;
             cso.OSSKeysNbrTries__c = (cso.OSSKeysNbrTries__c != null ? cso.OSSKeysNbrTries__c : 0) + 1;
             cso.OSSKeysUUID__c = (String.isNotBlank(cso.OSSKeysUUID__c) ? cso.OSSKeysUUID__c : System.UUID.randomUUID().toString());
             requestKey = cso.OSSKeysUUID__c;
          } else if (requestType == EZOnboardingRegistration.CPQ_KEYS) {
             cso.CPQKeysStart__c = Datetime.now();
             cso.CPQKeysEnd__c = null;
             cso.CPQKeysStatusCode__c = null;
             cso.CPQKeysDetail__c = null;
             cso.CPQKeysUUID__c = (String.isNotBlank(cso.CPQKeysUUID__c) ? cso.CPQKeysUUID__c : System.UUID.randomUUID().toString());
             requestKey = cso.CPQKeysUUID__c;
          } else if (requestType == EZOnboardingRegistration.CPQ_SUB) {
             cso.CPQSubStart__c = Datetime.now();
             cso.CPQSubEnd__c = null;
             cso.CPQSubStatusCode__c = null;
             cso.CPQSubDetail__c = null;
             cso.CPQSubUUID__c = (String.isNotBlank(cso.CPQSubUUID__c) ? cso.CPQSubUUID__c : System.UUID.randomUUID().toString());
             requestKey = cso.CPQSubUUID__c;
          } else {
             cso.ValidationUserStart__c=Datetime.now();
             cso.ValidationUserEnd__c=null;
             cso.ValidationUserStatusCode__c=null;
          }
           
          if (requestType == EZOnboardingRegistration.CLT_VALIDATE || requestType == EZOnboardingRegistration.CLT_VALIDATE_ADDR) {
             // clear out the addresses for the validation call so we'll know if it's been populated on return
             // not sure we always do this but we'll try it for now.
             cso.ValidAddr1__Street__s = null;
             cso.ValidAddr1__City__s = null;
             cso.ValidAddr1__StateCode__s = null;
             cso.ValidAddr1__PostalCode__s = null;
             cso.ValidAddr1__CountryCode__s = null;
             cso.ValidAddr2__Street__s = null;
             cso.ValidAddr2__City__s = null;
             cso.ValidAddr2__StateCode__s = null;
             cso.ValidAddr2__PostalCode__s = null;
             cso.ValidAddr2__CountryCode__s = null;
          }
          return requestKey;
       } // setRequestStart
        
       public void setRequestEnd(String requestType, String statusCode, String statusDetail) {
          System.debug('setRequestEnd requestType='+requestType+' statusCode='+statusCode+' statusDetail='+statusDetail);
          if (String.isNotBlank(statusDetail)) {
             for (EntRegError__c checkValue : EntRegError__c.getAll().values()) {
                if ((String.isNotBlank(checkValue.StatusCode__c) && checkValue.StatusCode__c == statusCode)
                     || (String.isNotBlank(statusDetail) && statusDetail.contains(checkValue.ValueToCheck__c))) {
                   cso.UserFacingError__c = checkValue.UserFacing__c;
                   break;
                }
             }
          } // if (String.isNotBlank(statusDetail
          if (requestType == VALIDATE_ACCT_ENT || requestType == VALIDATE_ACCT_CSO
                || requestType == EZOnboardingRegistration.CLT_VALIDATE || requestType == EZOnboardingRegistration.CLT_VALIDATE_ADDR) {
             if (String.isNotBlank(statusCode)) {
                cso.ValidationStatusCode__c=statusCode;
                cso.ValidationEnd__c=Datetime.now();
             }
             clientValidationAttempted=true;
             //Schema.DescribeFieldResult dfr = CSO_Tracking__c.ValidationDetail__c.getDescribe();
             //StringHelper.addToProcessNotes(cso, dfr, statusDetail,false);
             checkAddToField(cso, CSO_Tracking__c.ValidationDetail__c.getDescribe(), cso.ValidationDetail__c, statusDetail);
          } else if (requestType == EZOnboardingRegistration.REG_CSO || requestType == EZOnboardingRegistration.REG_ENT) {
             if (String.isNotBlank(statusCode)) {
                cso.RegistrationStatusCode__c = statusCode;
                cso.RegistrationEnd__c=Datetime.now();
                cso.RegistrationStarted__c = (statusCode == '200');
                if (statusCode != '200') {
                   cso.RegistrationProcessing__c = false;
                }
             }
             //Schema.DescribeFieldResult dfr = CSO_Tracking__c.RegistrationDetail__c.getDescribe();
             //StringHelper.addToProcessNotes(cso, dfr, statusDetail,false);
             checkAddToField(cso, CSO_Tracking__c.RegistrationDetail__c.getDescribe(), cso.RegistrationDetail__c, statusDetail);
             // a shortened version of the detail field that can be used in formulas
             //Schema.DescribeFieldResult dfr2 = CSO_Tracking__c.RegistrationDetail2__c.getDescribe();
             //StringHelper.addToProcessNotes(cso, dfr2, statusDetail,false);
             checkAddToField(cso, CSO_Tracking__c.RegistrationDetail2__c.getDescribe(), cso.RegistrationDetail2__c, statusDetail);
          } else if (requestType == EZOnboardingRegistration.REG_CLT_UPDATE) {
             if (String.isNotBlank(statusCode)) {
                cso.RegUpdateEnd__c = Datetime.now();
                cso.RegUpdateStatusCode__c = statusCode;
             }
             //Schema.DescribeFieldResult dfr = CSO_Tracking__c.RegUpdateDetail__c.getDescribe();
             //StringHelper.addToProcessNotes(cso, dfr, statusDetail,false);
             checkAddToField(cso, CSO_Tracking__c.RegUpdateDetail__c.getDescribe(), cso.RegUpdateDetail__c, statusDetail);
          } else if (requestType == EZOnboardingRegistration.OSS_KEYS) {
             if (String.isNotBlank(statusCode)) {
                cso.OSSKeysEnd__c = Datetime.now();
                cso.OSSKeysStatusCode__c = statusCode;
             }
             //Schema.DescribeFieldResult dfr = CSO_Tracking__c.OSSKeysDetail__c.getDescribe();
             //StringHelper.addToProcessNotes(cso, dfr, statusDetail);
             checkAddToField(cso, CSO_Tracking__c.OSSKeysDetail__c.getDescribe(), cso.OSSKeysDetail__c, statusDetail);
          } else if (requestType == EZOnboardingRegistration.CPQ_KEYS) {
             if (String.isNotBlank(statusCode)) {
                cso.CPQKeysEnd__c = Datetime.now();
                cso.CPQKeysStatusCode__c = statusCode;
             }
             //Schema.DescribeFieldResult dfr = CSO_Tracking__c.CPQKeysDetail__c.getDescribe();
             //StringHelper.addToProcessNotes(cso, dfr, statusDetail,false);
             checkAddToField(cso, CSO_Tracking__c.CPQKeysDetail__c.getDescribe(), cso.CPQKeysDetail__c, statusDetail);
          } else if (requestType == EZOnboardingRegistration.CPQ_SUB) {
             if (String.isNotBlank(statusCode)) {
                cso.CPQSubEnd__c = Datetime.now();
                cso.CPQSubStatusCode__c = statusCode;
             }
             //Schema.DescribeFieldResult dfr = CSO_Tracking__c.CPQSubDetail__c.getDescribe();
             //StringHelper.addToProcessNotes(cso, dfr, statusDetail,false);
             checkAddToField(cso, CSO_Tracking__c.CPQSubDetail__c.getDescribe(), cso.CPQSubDetail__c, statusDetail);
          } else {
             cso.ValidationUserStatusCode__c=statusCode;
             cso.ValidationUserEnd__c=Datetime.now();
             userValidationAttempted=true;
          }
       } // setRequestEnd

    } // Class AcctCsoWrap
    
    public static void checkAddToField(CSO_Tracking__c tracker, Schema.DescribeFieldResult dfr, String curFldValue, String valueToAdd) {
       if (String.isNotBlank(valueToAdd)) {
          if (String.isBlank(curFldValue) || !curFldValue.contains(valueToAdd)) {
             StringHelper.addToProcessNotes(tracker, dfr, valueToAdd,false);
          }
            
       } // if (String.isNotBlank(valueToAdd)
    } // checkAddToField
    
    //JSON Request and Web Service
    public class RestWrapper{
        String jsonRequest;
        String requestType;
        Id acctId;
        Id opptyId;
        WebServiceSettings__c wss;
    } // RestWrapper
    
    public CsoQueueable() {      
    } // CsoQueueable
    
    public void addRecsToProcess(Account acct, CSO_Tracking__c cso) {
       AcctCsoWrap wrap = new AcctCsoWrap(acct, cso);
       if (wrap.validateClient || wrap.validateUser) {
          recsToProcess.add(wrap);
       }
    } // addRecsToProcess
    /*
    public CsoQueueable(Account[] p_accts, Map<Id, CSO_Tracking__c> p_csoMap, Boolean relaunch) {
        accts = p_accts;
        csoMap = csoMap;
        relaunchForUserValidation = relaunch;
    } //CsoQueueable
    */
    public static void checkLaunchQueueable(CsoQueueable csoQue) {
       System.debug('checkLaunchQueueable csoQue='+(csoQue != null ? csoQue.recsToProcess.size() : -1));
        if(!SKIP_TRIGGERS){
            if (csoQue != null && !csoQue.recsToProcess.isEmpty()) {
                Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
                System.debug('checkLaunchQueueable abc='+abc);
                if(abc.Active__c){
                    System.enqueueJob(csoQue);
                }
            } // if (csoQue != null
        }
    } // checkLaunchQueueable
    /*
    //Executable method
    public static void launchQueueable(Account[] p_accts, Map<Id, CSO_Tracking__c> p_csoMap){
        if (!p_accts.isEmpty()){
            Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
            if(abc.Active__c){
                CsoQueueable newCSO = new CsoQueueable(p_accts, p_csoMap, null);
                System.enqueueJob(newCSO);
            }
        }
    } // launchQueueable
    */
    public void execute(QueueableContext context) {
        try {
           processRecs(true);
        
           if (!Test.isRunningTest() && !recsToProcess.isEmpty()) {
               CsoQueueable relaunchCso = new CsoQueueable();
               relaunchCso.recsToProcess.addAll(recsToProcess);
               System.enqueueJob(relaunchCso);
           }
        } catch (Exception e) {
           SObject errorRec = (recsToProcess != null && !recsToProcess.isEmpty() ? recsToProcess[0].cso : null);
           ErrorLog.logError(CLASSNAME, 'execute', 'General Error', (errorRec != null ? errorRec.Id : null), e, errorRec, true);
        }
    } // execute
    
    public Static String LEGAL='LegalAddress';
    public static String SHIPPING='Shipping';
    public static String BILLING='Billing';
    
    public void processRecs(Boolean saveCsos) {
       SKIP_TRIGGERS = true;
        //Map Field/Value pair for Json String
        // process 1 account at a time due to callout. Only do one callout at a time to allow for maximum timeout.
        AcctCsoWrap wrap = recsToProcess[0];

        Map<String,String> acctFieldMap = setAcctFldMap(wrap);
        //Process Account
        createValidationRequest(wrap, acctFieldMap);
        if (saveCsos) {
           DmlHelper.performDML2(csoUpdateList, DmlHelper.DML_UPDATE, 'CsoQueueable', 'processRecs', 'Update CSO Tracking Record', true); 
        }
    } // processRecs
    
    public Map<String,String> setAcctFldMap(AcctCsoWrap wrap) {
        Account acct = wrap.acct;
        String addressToUse = SHIPPING;
        //String addressToNotUse1 = LEGAL;
        //String addressToNotUse2 = BILLING;
        if (wrap.useClientValidation()) {
            // see which address has a value. We will look at street and postal code to determine. Only sending one address for the validation
            // TODO - is there a better way to handle this??
            addressToUse = addrToUse(acct);
            //addressToNotUse1 = (addressToUse == LEGAL ? SHIPPING : (addressToUse == SHIPPING ? BILLING : LEGAL));
            //addressToNotUse2 = (addressToUse == LEGAL ? BILLING : (addressToUse == SHIPPING ? LEGAL : SHIPPING));
        } // if (!relaunchForUserValidation
        //System.debug('processRecs addressToUse='+addressToUse+' addressToNotUse1='+addressToNotUse1+' addressToNotUse2='+addressToNotUse2);
        System.debug('processRecs addressToUse='+addressToUse);
        //Map Account API Name and Value
        Map<String, String> acctFieldMap = new Map<String, String>();
        Schema.FieldSet fieldSet = Schema.SObjectType.Account.fieldSets.CsoAccountValidationFields;
        for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
            // the field value in the fieldSet is how the CSO_Field_Mapping custom setting is setup
            String mapFldName = fsm.getFieldPath();
            // get the field name we want to use to pull the value from the Account object
            String acctFldName = checkFieldName(mapFldName, addressToUse);
            String acctFieldValue = (acct.get(acctFldName) == null ? '' : (String)acct.get(acctFldName));
            if (acctFldName == 'Federal_ID_Number__c' && acctFieldValue.contains('-')) {
                acctFieldValue = EZOnboardingRegistration.formatFedId(acctFieldValue);
                //acctFieldValue = acctFieldValue.replace('-',''); //acctFieldValue.substringBefore('-') + acctFieldValue.substringAfter('-');
            } else if (acctFldName == 'Name'){
            // remove special characters from the name field.
                acctFieldValue = EZOnboardingRegistration.formatName(acctFieldValue);
                //acctFieldValue = acctFieldValue.replaceAll('[^a-zA-Z0-9-& ]', '');//Hyphen (-),  Ampersand (&)
            } else if (mapFldName == 'ShippingState') {
                acctFieldValue = EZOnboardingRegistration.formatState(acctFieldValue);
            } else if (mapFldName == 'ShippingCity') {
                acctFieldValue = EZOnboardingRegistration.formatName(acctFieldValue);
            } else if (mapFldName == 'ShippingStreet') {
                EZOnboardingRegistration.AddressWrapper addrWrap = EZOnboardingRegistration.getAddressWrap(acctFieldValue);
                //acctFieldValue = EZOnboardingRegistration.formatAddress(acctFieldValue);
                acctFieldValue = addrWrap.addressOne;
                if (String.isNotBlank(addrWrap.addressTwo)) {
                   acctFieldMap.put('streetAddressTwo', addrWrap.addressTwo);
                }
            } else if (mapFldName == 'ShippingPostalCode') {
                acctFieldValue = EZOnboardingRegistration.formatPostalCode(acctFieldValue);
            }
            System.debug('processRecs mapFldName='+mapFldName+' acctFldName='+acctFldName+' acctFieldValue='+acctFieldValue);
            acctFieldMap.put(mapFldName, acctFieldValue);
        } // for (Schema.FieldSetMember fsm
        return acctFieldMap;
    } // setAcctFldMap
    
    public static String addrToUse(Account acct) {
       String addressToUse = ((String.isNotBlank(acct.LegalAddress__Street__s) && String.isNotBlank(acct.LegalAddress__PostalCode__s)) ? LEGAL
                              : ((String.isNotBlank(acct.ShippingStreet) && String.isNotBlank(acct.ShippingPostalCode)) ? SHIPPING
                                 : ((String.isNotBlank(acct.BillingStreet) && String.isNotBlank(acct.BillingPostalCode)) ? BILLING : SHIPPING)));
       return addressToUse;
    } // addrToUse
    
    public static String checkFieldName(String fldName, String addressToUse) {
       String retFldName = fldName;
       // since the fields are mapped in the custom setting under the Shipping field names, map the other two to that for the map 
       // TODO - is there a better way to handle this??
       if (addressToUse != SHIPPING && fldName.startsWith(SHIPPING)) {
          if (addressToUse == LEGAL) {
             retFldName = (fldName == 'ShippingStreet' ? 'LegalAddress__Street__s' 
                              : (fldName == 'ShippingCity' ? 'LegalAddress__City__s' 
                                  : (fldName == 'ShippingState' ? 'LegalAddress__StateCode__s' 
                                      : (fldName == 'ShippingPostalCode' ? 'LegalAddress__PostalCode__s'
                                         : (fldName == 'ShippingCountry' ? 'LegalAddress__CountryCode__s' : fldName)))));
          } else if (addressToUse == BILLING) {
             retFldName = (fldName == 'ShippingStreet' ? 'BillingStreet' 
                              : (fldName == 'ShippingCity' ? 'BillingCity' 
                                  : (fldName == 'ShippingState' ? 'BillingState' 
                                      : (fldName == 'ShippingPostalCode' ? 'BillingPostalCode'
                                         : (fldName == 'ShippingCountry' ? 'BillingCountry' : fldName)))));
              
          }
       } // if (addressToUse != SHIPPING
       /*
       if (fldName.startsWith(addressToUse) && addressToUse != SHIPPING) {
          retFldName = ((fldName == 'BillingStreet' || fldName == 'LegalAddress__Street__s') ? 'ShippingStreet'
                         : ((fldName == 'BillingCity' || fldName == 'LegalAddress__City__c') ? 'ShippingCity'
                             : ((fldName == 'BillingState' || fldName == 'LegalAddress__StateCode__c') ? 'ShippingState'
                                : ((fldName == 'BillingPostalCode' || fldName == 'LegalAddress__PostalCode__s') ? 'ShippingPostalCode'
                                   : ((fldName == 'BillingCountry' || fldName == 'LegalAddress__CountryCode__c') ? 'ShippingCountry' : fldName)))));
       }
       */
       //System.debug('checkFieldName fldName='+fldName+' retFldName='+retFldName+' addressToUse='+addressToUse);
       return retFldName;
    } // checkFieldName
    
    public void createValidationRequest(AcctCsoWrap wrap, Map<String, String> acctFieldMap){
        //CSO_Tracking__c csoRec = csoMap.get(acct.Id);
        //if(relaunchForUserValidation == null){
        //    relaunchForUserValidation = csoRec.ClientDataValidated__c ? true : false;
        //}
        String restRequestType = (wrap.useClientValidation() && wrap.cso.CanUseCSO__c ? VALIDATE_ACCT_CSO 
                                    : (wrap.useClientValidation() && !wrap.cso.CanUseCSO__c ? VALIDATE_ACCT_ENT
                                      : (wrap.useUserValidation() ? VALIDATE_USER : null)));
        
        StringHelper.addToProcessNotes(wrap.cso, 'createValidationRequest restRequestType='+restRequestType);
        
        //VALIDATE_ACCT_ENT
        if (restRequestType != null) {
           //String restRequestType = relaunchForUserValidation ? VALIDATE_USER : VALIDATE_ACCT;
           RestWrapper rw = new RestWrapper();
           rw.requestType = restRequestType;
           rw.acctId = wrap.acct.Id;
           rw.jsonRequest = generateJsonString(acctFieldMap, getJSONFields(restRequestType),wrap);
           rw.wss = WebServicesHelper.getWebSvcSetting(restRequestType);
           sendRequests(rw, wrap);   
        } // if (restRequestType != null
    } // createValidationRequest
    
    public List<CSO_Field_Mapping__c> getJSONFields(String jsonType) {
        String queryString = 'Select Id,CSO_Name__c,Field_API__c,Hardcoded_Value__c,IsEndObject__c,IsStartObject__c,IsStartArray__c ,IsEndArray__c,Order__c from CSO_Field_Mapping__c';
        String whereClause = ((jsonType == VALIDATE_ACCT_CSO || jsonType == VALIDATE_ACCT_ENT) ? ' where InitialValidation__c = true' : (jsonType == VALIDATE_USER ? ' where UserValidation__c = true' : ''));
        String csoQuery = queryString + whereClause + ' order by Order__c ASC';        
        return Database.query(csoQuery);
    } // getJSONFields

    //Generate the JSON string
    public String generateJsonString(Map<String, String> fieldValues, List<CSO_Field_Mapping__c> jsonBuildDetail, AcctCsoWrap wrap){
        //Start JSON String
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        for(CSO_Field_Mapping__c cfm : jsonBuildDetail){
            if(cfm.IsStartObject__c){
                gen.writeFieldName(cfm.CSO_Name__c);
                gen.writeStartObject();
            }else if(cfm.IsEndObject__c){
                gen.writeEndObject();
            }else{
                String fldKey = (String.isNotBlank(cfm.Field_API__c) ? cfm.Field_API__c : cfm.CSO_Name__c);
                String value = '';
                if (fldKey == 'tinType') {
                    if (wrap != null && wrap.cso != null && wrap.cso.Is_this_a_SSN_Number__c == 'true') {
                       value = 'SSN';
                    } else {
                       value = 'FEIN';
                    }
                } else {
                   value=EZOnboardingRegistration.formatText(cfm.Hardcoded_Value__c!=null ? cfm.Hardcoded_Value__c : fieldValues.get(fldKey));
                }
                System.debug('generateJsonString cfm.CSO_Name__c='+cfm.CSO_Name__c+' fldKey='+fldKey+' value='+value);
                gen.writeStringField(cfm.CSO_Name__c, value);
            }
        }
        gen.writeEndObject();
        return gen.getAsString();
    } // generateJsonString
    
    //Create HTTP Request and send data to CSO
    public void sendRequests(RestWrapper rw, AcctCsoWrap wrap){
        CSO_Tracking__c csoRec = wrap.cso;
        System.debug('sendRequests csoRec='+csoRec);
        //Create HTTP Request
        HttpRequest request = EZOnboardingRegistration.setupRequest(wrap, rw.requestType);
        request.setbody(rw.jsonRequest);
        EZOnboardingRegistration.addToValidationRequest(wrap.cso, 'Validation for '+rw.requestType+'\n'+rw.jsonRequest);
        System.debug('sendRequests after setBody');
        System.debug('sendRequests after setRequestStart');
        
        HTTPResponse response = EZOnboardingRegistration.sendRequest(wrap, request, rw.requestType);
        if (response != null) {
            trackResults(response, wrap, rw.requestType);
        } else {
            csoRec.Account_Eligible__c = false;
        }
        // if there are no more validations to attempt, remove from the queue
        if (!wrap.useClientValidation() && !wrap.useUserValidation()) {
            System.debug('sendRequests removing record from list');
            recsToProcess.remove(0);
        }
        csoUpdateList.add(csoRec);
        //DmlHelper.performDML2(new CSO_Tracking__c[]{csoRec}, DmlHelper.DML_UPDATE, 'CsoQueueable', 'execute', 'Update CSO Tracking Record', true); 
    } // sendRequests
	
    public void trackResults(HTTPResponse response, AcctCsoWrap wrap, String requestType){
        Integer statusCode = response.getStatusCode();
        String responseDetail = response.getBody();
        List<CSOErrorCodes__c> errorCodeList = CSOErrorCodes__c.getAll().Values();
        System.debug('trackResults requestType='+requestType+' statusCode='+statusCode);
        if (statusCode == 503) {
            wrap.cso.Opportunity_Eligible__c = false;
            wrap.cso.InitialValidationDetail__c = 'Easy Onboarding Registration is Currently Unavailable. Please Submit via PACO';           
        } else if (requestType == VALIDATE_ACCT_CSO || requestType == VALIDATE_ACCT_ENT) {
                //test.setContinuationResponse(label, System.response)
            wrap.cso.ClientDataValidated__c = statusCode == 200 ? true : false;
            EZOnboardingRegistration.addToCsoResponse(wrap.cso, 'Client Validation Status Code: '+statusCode+'\n Detail: ' +responseDetail);
            EZOnboardingRegistration.EntResponse entResp = EZOnboardingRegistration.parseResponse(responseDetail);
            wrap.cso.InitialValidationDetail__c = entResp.errDesc;
            if (!ALLOW_USER_VAL) {
               StringHelper.addToProcessNotes(wrap.cso,'User Validation Not Required');
               wrap.cso.User_Validated__c = true;
               wrap.cso.ValidationUserStatusCode__c='200';
               wrap.cso.UserValidationDetail__c = null;
               wrap.cso.ValidationUserStart__c = Datetime.now();
               wrap.cso.ValidationUserEnd__c = Datetime.now();
               wrap.validateUser = false;
            }
         } else if (requestType == VALIDATE_USER) {
            wrap.cso.User_Validated__c = statusCode == 200 ? true : false;
            EZOnboardingRegistration.addToCsoResponse(wrap.cso, 'User Validation Status Code: '+statusCode+'\n Detail: ' +responseDetail);
            EZOnboardingRegistration.EntResponse entResp = EZOnboardingRegistration.parseResponse(responseDetail);
            wrap.cso.UserValidationDetail__c = entResp.errDesc;
        } // if (requestType == VALIDATE_ACCT
        
        // todo - have to take into account non-cso where there will be no user validation
        wrap.cso.Account_Eligible__c = (((requestType == VALIDATE_USER && wrap.cso.User_Validated__c) || requestType != VALIDATE_USER) 
                                              && wrap.cso.ClientDataValidated__c && !wrap.cso.AccountKnockout__c);
        CsoMethods.isOppEligible(wrap.cso);

    } // trackResults
    
} // class CsoQueueable