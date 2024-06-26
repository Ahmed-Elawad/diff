/* 
   Methods for parsing out enterprise 

   
  History
  -------
  11/02/2022 Dan Carmen        Created
  01/16/2024 Dan Carmen        Additional Parsing to handle more complex responses

*/
public class EntRespHelper {
    
   // comma separated list of error codes that aren't necessarily errors because we actually have the information
   public static String[] addrErrors = Label.EntRep_AddrErrors.split(',');
   // status codes returned that we'll translate as okay
   public static String[] addrStatusCodes = Label.EntResp_AddrStatusCodes.split(',');

   // compile any errors
   public static void checkErrors(EZOnboardingRegistration.EntResponse entResp, EZOnboardingRegistration.AddrResp addrResp, CsoQueueable.AcctCsoWrap wrap, Object errorObj) {
      ErrResp[] errors = parseErrors(wrap, entResp, errorObj);
      Boolean addrStatusCodeOkay = (String.isNotBlank(entResp.statusCode) && addrStatusCodes.contains(entResp.statusCode));
      Boolean hadAddressErrors = false;
      System.debug('checkErrors errors='+errors.size()+' addrErrors='+addrErrors+' addrStatusCodeOkay='+addrStatusCodeOkay);
      for (ErrResp error : errors) {
         Boolean addrErrorOkay = (String.isNotBlank(error.errCode) && addrErrors.contains(error.errCode));
         System.debug('checkErrors error.errCode='+error.errCode+' addrErrorOkay='+addrErrorOkay+' error.correlationId='+error.correlationId+' error.addrInfo='+(error.addrInfo != null));
         // this error happens if the address id we send in matches what's already in enterprise. We'll make sure it's set properly
         // on the account.
         if (addrStatusCodeOkay && error.errCode == 'ACCOUNT_ADDRESS_ID_EXISTS' && String.isNotBlank(error.correlationId) && error.addrInfo == null) {
            error.addrInfo = new EZOnboardingRegistration.AddrResp();  
            error.addrInfo.aid = error.correlationId;
            if (!entResp.addrMap.containsKey(error.correlationId)) {
               entResp.addrMap.put(error.correlationId, error.addrInfo);
            }
         } 
         if (addrStatusCodeOkay && addrErrorOkay && error.addrInfo != null && String.isNotBlank(error.addrInfo.aid)) {
            System.debug('checkErrors not adding error to the error list');
            // do we need to do anything here? Should have already set this.  
            if (error.addrInfo != null) {
               
            }
         } else {
            System.debug('checkErrors add error to the error list');
            entResp.errs.add(error);
            if (String.isNotBlank(error.correlationId)) {
               entResp.errMap.put(error.correlationId, error);
            }
         }
      } // for (ErrResp error
      // if we have a validated address, do we also have an address id?
      Boolean hasAddrId = (wrap != null && wrap.cso != null && ((String.isNotBlank(wrap.cso.ValidAddr1__Street__s) && String.isNotBlank(wrap.cso.ValidAddr1Aid__c))
                           || (String.isNotBlank(wrap.cso.ValidAddr2__Street__s) && String.isNotBlank(wrap.cso.ValidAddr2Aid__c))));
      System.debug('checkErrors addrStatusCodeOkay='+addrStatusCodeOkay+' entResp.errs='+entResp.errs.size()+' errors='+errors.size()+' hasAddrId='+hasAddrId);
      if (addrStatusCodeOkay && ((!errors.isEmpty() && entResp.errs.isEmpty()) || (errors.isEmpty() && hasAddrId))) {
         entResp.statusCode='200';
      }
    } // checkErrors
    
    /*
    "errors" : [ {
        "errorCode" : "POSTAL_ADDRESS_COULD_NOT_BE_VERIFIED",
        "errorDescription" : "The postal address could not be verified",
        "conflictResource":{"links":[{"rel":"matchingClient","href":"https://ent-ose-client-svc-pyx.n2a-lb.paychex.com/clients?ceid=00H2A1IUL9YMFARWMV10"}]}
      } ]
 

,"conflictResources":[{"detail":"Client with this tax ID already exists"
                      ,"key":"ENT-CLIENT-VIOLATION-40"
					  ,"conflictResource":{"links":[{"rel":"matchingClient"
					                                 ,"href":"https://ent-ose-client-svc-pyx.n2a-lb.paychex.com/clients?ceid=00H2A1IULGQW7QJR0C13"}]}
			          ,"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/subtypes/ConflictResourceProblemDetails.java"}]

     */
    public static ErrResp[] parseErrors(CsoQueueable.AcctCsoWrap wrap, EZOnboardingRegistration.EntResponse entResp, Object errValue) {
       ErrResp[] retValues = new ErrResp[]{};
       Object[] errors = (Object[])errValue;
       System.debug('parseErrors errors='+(errors != null ? errors.size() : -1)+' errValue='+errValue);
       for (Object err : errors) {
          ErrResp erResp = new ErrResp();
          Map<String,Object> errMap2 = (Map<String,Object>)err;
          System.debug('parseErrors errMap2 keys='+errMap2.keySet());
          for (String errkey : errMap2.keySet()) {
             handleErrorKeys(wrap, entResp, erResp, errKey, errMap2);
          } // for (String errkey : errMap2
          System.debug('parseErrors resp.field='+erResp.field+' resp.errCode='+erResp.errCode);
          if (String.isNotBlank(erResp.field) && String.isBlank(erResp.errCode)) {
             erResp.errCode = erResp.field;
          }
          //if (String.isNotBlank(resp.fieldMsg) && String.isBlank(resp.errDesc)) {
          if (String.isNotBlank(erResp.fieldMsg)) {
             erResp.errDesc = erResp.fieldMsg;
          }
          System.debug('parseErrors erResp.correlationId='+erResp.correlationId+' addrInfo='+(erResp.addrInfo != null));
          if (String.isNotBlank(erResp.correlationId)) {
             System.debug('parseErrors matchFromValidation='+erResp.matchFromValidation);
             System.debug('parseErrors wrap.billingIdSet='+wrap.billingIdSet+' wrap.shippingIdSet='+wrap.shippingIdSet);
             String[] locations = new String[]{};
             if (wrap.billingIdSet.contains(erResp.correlationId)) {
                locations.add('Billing Address');
                if (erResp.addrInfo != null) {
                   System.debug('parseErrors setting billAddr');
                   entResp.billingId = erResp.addrInfo.aid;
                   entResp.billAddr = erResp.addrInfo;
                   if (wrap.cso != null) {
                      wrap.cso.ValidAddr1Aid__c = erResp.addrInfo.aid;
                      wrap.cso.ValidAddr1__Street__s = entResp.billAddr.street;
                      wrap.cso.ValidAddr1__City__s = entResp.billAddr.city;
                      wrap.cso.ValidAddr1__StateCode__s = entResp.billAddr.state;
                      wrap.cso.ValidAddr1__PostalCode__s = entResp.billAddr.postal;
                      wrap.cso.ValidAddr1__CountryCode__s = entResp.billAddr.country;
                   }
                }
             }
             if (wrap.shippingIdSet.contains(erResp.correlationId)) {
                locations.add('Shipping Address');
                if (erResp.addrInfo != null) {
                   System.debug('parseErrors setting shipAddr');
                   entResp.shippingId = erResp.addrInfo.aid;
                   entResp.shipAddr = erResp.addrInfo;
                   if (wrap.cso != null) {
                      wrap.cso.ValidAddr2Aid__c = erResp.addrInfo.aid;
                      wrap.cso.ValidAddr2__Street__s = entResp.shipAddr.street;
                      wrap.cso.ValidAddr2__City__s = entResp.shipAddr.city;
                      wrap.cso.ValidAddr2__StateCode__s = entResp.shipAddr.state;
                      wrap.cso.ValidAddr2__PostalCode__s = entResp.shipAddr.postal;
                      wrap.cso.ValidAddr2__CountryCode__s = entResp.shipAddr.country;
                   }
                }
             }
             erResp.location = (!locations.isEmpty() ? String.join(locations,' and ') : null);
          }
          if (String.isNotBlank(erResp.correlationId) && erResp.addrInfo != null) {
             entResp.addrMap.put(erResp.correlationId, erResp.addrInfo);
          }
          if (erResp.matchFromValidation && erResp.addrInfo != null && erResp.location != null) {
             erResp.location = null;
             erResp.errDesc = null;
          }
          if (String.isNotBlank(erResp.errDesc)) {
             retValues.add(erResp);
             erResp.errDesc = checkErrCode(erResp.errCode, erResp.errDesc);
          }
          erResp.errDesc = (String.isNotBlank(erResp.location) ? (erResp.location+': '+erResp.errDesc) : erResp.errDesc);
          System.debug('parseErrors erResp='+erResp);
       } // for (Object err : errors
       return retValues;
    } // parseErrors
    
    public static void handleErrorKeys(CsoQueueable.AcctCsoWrap wrap, EZOnboardingRegistration.EntResponse entResp, ErrResp erResp, String errKey, Map<String,Object> errMap2) {
       Object errObj = errMap2.get(errkey);
       System.debug('handleErrorKeys errKey='+errKey+' errObj='+errObj);
       switch on errkey {
          when 'errorCode' {erResp.errCode = String.valueOf(errObj);}
          when 'errorDescription' {erResp.errDesc = String.valueOf(errObj);}
          when 'key' {erResp.errCode = String.valueOf(errObj);}
          when 'detail' {
              String checkValue = String.valueOf(errObj);

              if (String.isNotBlank(checkValue) && !Label.EntResp_BadDetails.contains(checkValue)) {
                 erResp.errDesc = checkValue;
              }
          }
          when 'fieldError' {
             Map<String,Object> fldErrMap = (Map<String,Object>)errObj;
             for (String fldErrKey : fldErrMap.keySet()) {
                switch on fldErrKey {
                   when 'field' {erResp.field = String.valueOf(fldErrMap.get(fldErrKey));}
                   when 'defaultMessage' {erResp.fieldMsg = String.valueOf(fldErrMap.get(fldErrKey));}
                   when else {}
                } // switch on fldErrKey
             } // for (String fldErrKey
          } // when 'fieldError'
          when 'correlationId' {erResp.correlationId = String.valueOf(errObj);}
          when 'error' {
             System.debug('handleErrorKeys error key');
             parseErrorContent(erResp,wrap,entResp,errObj);
          } // when 'error'
          when 'conflictResource' {
              parseErrorConflictResource(erResp, wrap, errKey, errMap2);
          } // when 'conflictResource'
          when 'additionalContent' {
             Map<String,Object> addlContMap = (Map<String,Object>)errObj;
             if (addlContMap.containsKey('candidateAddresses')) {
                handleCandidateAddr(wrap, entResp , erResp, addlContMap.get('candidateAddresses'));
             }
          }
          when else { // do nothing
          }
       } // switch on addrKey

    } // handleErrorKeys
    
    // this is a multi-level error response returning from ECAG
    public static void parseErrorContent(ErrResp erResp, CsoQueueable.AcctCsoWrap wrap, EZOnboardingRegistration.EntResponse entResp, Object errObj) {
       Map<String,Object> errMap3 = (Map<String,Object>)errObj;
       if (errMap3.containsKey('content')) {
          System.debug('parseErrorContent content key');
          Map<String,Object> errMap4 = (Map<String,Object>)errMap3.get('content');
          if (errMap4.containsKey('errors')) {
             System.debug('parseErrorContent errors key');
             Object[] errList = (Object[])errMap4.get('errors');
             for (Object err : errList) {
                Map<String,Object> errMap5 = (Map<String,Object>)err;
                System.debug('parseErrorContent errMap5='+errMap5.keySet());
                for (String key : errMap5.keySet()) {
                   handleErrorKeys(wrap,entResp,erResp,key,errMap5);
                }
             } // for (Object err : errList
          } else if (errMap4.containsKey('conflictResources')) {
             System.debug('parseErrorContent conflictResources key');
             checkErrors(entResp, null, wrap, errMap4.get('conflictResources'));

          } // if (errMap4.containsKey('errors'
       } // if (errMap3.containsKey('content'

    } // parseErrorContent
    
    // parse the conflict resource tag to try to pull out the link to the matching record (if any)
    public static void parseErrorConflictResource(ErrResp erResp, CsoQueueable.AcctCsoWrap wrap, String errKey, Map<String,Object> errMap2) {
       try {
          String checkValue = String.valueOf(errMap2.get(errkey));
          if (errMap2.containsKey(errkey)) {
             System.debug('parseErrorConflictResource conflictResource='+errMap2.get(errkey));
             Map<String,Object> conflictMap = (Map<String,Object>)errMap2.get(errkey);
             //System.debug('parseErrorConflictResource conflictMap keys='+conflictMap.keySet());
             for (String conflictKey : conflictMap.keySet()) {
                switch on conflictKey {
                   when 'links' { 
                      Object[] links = (Object[])conflictMap.get('links');
                      handleLinks((Object[])conflictMap.get('links'), erResp);
                    }
                   when 'id' {
                      // this id will represent the address id that we passed in for a DUPLICATE_ADDR response
                      erResp.correlationId = String.valueOf(conflictMap.get(conflictKey));
                   }
                   when 'caid' {
                      erResp.caid = String.valueOf(conflictMap.get(conflictKey));
                   }
                   when 'content' {
                      // thils will contain the address information in a clientPostalAddress tag
                      Map<String,Object> contentMap = (Map<String,Object>)conflictMap.get(conflictKey);
                      erResp.addrInfo = new EZOnboardingRegistration.AddrResp();
                      for (String addrKey : contentMap.keySet()) {
                         switch on addrKey {
                             when 'id' {
                                erResp.addrInfo.aid = String.valueOf(contentMap.get(addrKey));
                             }
                             when 'caid' {
                                erResp.addrInfo.caid = String.valueOf(contentMap.get(addrKey));
                             }
                         } // switch
                      } // for (String addrKey : contentMap
                      // handle outside the loop to make sure the other keys are set first
                      if (contentMap.containsKey('clientPostalAddress')) {
                         Map<String,Object> addrMap = (Map<String,Object>)contentMap.get('clientPostalAddress');
                         handleAddressKeys(addrMap, null, erResp.addrInfo, null, false, false);

                      }
                   } // when 'content'
                   when else {  }
                } // switch on addrKey

             } // for (String conflictKey : conflictMap.keySet
             if (erResp.addrInfo != null && String.isNotBlank(erResp.correlationId)) {
                erResp.addrInfo.sfId = erResp.correlationId;
             }        
          } // if (String.isNotBlank(checkValue
       } catch (Exception e) {
          System.debug('parseErrorConflictResource e='+e.getMessage()+'; '+e.getStackTraceString());
       }
 
    } // parseErrorConflictResource
    
   public static void handleLinks(Object[] links, ErrResp erResp) {
      System.debug('handleLinks links='+links.size());
      for (Object link : links) {
         System.debug('handleLinks link='+link);
         Map<String,Object> linkMap = (Map<String,Object>)link;
         //System.debug('handleLinks linkMap='+linkMap.keySet());
         if (linkMap.containsKey('href')) {
            String checkUrl = (String)linkMap.get('href');
            if (checkUrl.contains('ceid=')){
               String ceidMatch = 'Existing match Found with CEID='+checkUrl.substringAfterLast('ceid=');
               System.debug('handleLinks ceidMatch='+ceidMatch);
               erResp.matches.add(ceidMatch);
            }
         } // if (linkMap.containsKey
      } // for (Object link : links

   } // handleLinks
    
    public class ErrResp {
       public String errCode;
       public String errDesc;
       // if we get the caid at the error level
       public String caid;
       // this is the id from SF we passed into the service
       // This could be the account id if account level error or one of the address ids
       // if this is an address level error
       public String correlationId;
       public String location;
       public String field;
       public String fieldMsg;
       // if this is a validation call and we get back a matching address that we'd use instead
       public Boolean matchFromValidation=false;
       // if the error comes back DUPLICATE_ADDR we will get back the address info too.
       public EZOnboardingRegistration.AddrResp addrInfo;
       public String[] matches = new String[]{};
       public String getOutput() {
          String output='errCode='+errCode+' errDesc='+errDesc;
          return output;
       }
    } // ErrResp

    public static EZOnboardingRegistration.EntResponse parseResponse(CsoQueueable.AcctCsoWrap wrap, String response, String reqType) {  
       if (reqType == EZOnboardingRegistration.REG_ENT || reqType == EZOnboardingRegistration.REG_CLT_UPDATE
           || reqType == EZOnboardingRegistration.CLT_VALIDATE || reqType == EZOnboardingRegistration.CLT_VALIDATE_ADDR) {
          String checkResp = response;
          if (checkResp.startsWith('[') && checkResp.endsWith(']')) {
             checkResp = checkResp.substring(1, checkResp.length()-1);
          }
          return parseOicResponse(wrap, checkResp);
       } else if (reqType == EZOnboardingRegistration.OSS_KEYS) {
          return handleKeysResp(response); 
       } else {
          return parseResponse(response);
       }
    } // parseResponse
    
    // look for the description in the response.
    public static EZOnboardingRegistration.EntResponse parseResponse(String response) {
       EZOnboardingRegistration.EntResponse entResp = new EZOnboardingRegistration.EntResponse();
       System.debug('parseResponse response='+response);
       if (String.isNotBlank(response)) {
          try {
             JSONParser parser = JSON.createParser(response);
             while (parser.nextToken() != null) {
                 if(parser.getCurrentToken() == JSONToken.FIELD_NAME){
                    string currentName = parser.getText();
                    System.debug('parseResponse currentName='+currentName);
                    parser.nextToken();
                    if (currentName == 'description') {
                       entResp.errDesc = parser.getText();
                    } else if (currentName == 'code') {
                       entResp.errCode = parser.getText();
                    } else if (currentName == 'ceid' || currentName == 'clientCeid') {
                       entResp.ceid = parser.getText();
                    } else if (currentName == 'caid' || currentName == 'clientCaid') {
                       entResp.caid = parser.getText();
                    } else if (currentName == 'assignedName') {
                       entResp.cltNbr = parser.getText();
                    } else if (currentName == 'aaids') {
                       entResp.aaid = parser.getText();
                    } else if (currentName == 'id') {
                       entResp.responseId = parser.getText();
                    } else if (currentName == 'guid') {
                       entResp.userGuid = parser.getText();
                    }
                }     
             } // while (parser.nextToken() != null
          } catch (Exception e) {
             // this is just as a backup - shouldn't have to use
             System.debug('parseResponse exception='+e.getMessage()+'; '+e.getStackTraceString());
             if (response.contains('description')) {
                entResp.errDesc = response.substringBetween('"description":"', '"');
             }
          }
          entResp.errDesc = checkErrCode(entResp.errCode, entResp.errDesc);
       } // if (String.isNotBlank 
       System.debug('parseResponse resp='+entResp);
       return entResp;
    } // parseResponse
    
    // check the custom setting to see if we have a translation for the error code returned
    public static String checkErrCode(String checkErrCode, String origDesc) {
       String retDesc = origDesc;
       if (String.isNotBlank(checkErrCode)) {
          CSOErrorCodes__c errCode = CSOErrorCodes__c.getInstance(RecordTypeHelper.cleanRtName(checkErrCode));
          System.debug('checkErrCode checking CS for '+checkErrCode+' errCode='+(errCode != null));
          if (errCode != null && errCode.Display_Message__c) {
             retDesc = errCode.Error_Message__c;
          }
       }
       return retDesc;
    } // checkErrCode
    
    /* the format of the usage complex
     "usages" : [ {
        "type" : "LEGAL"
      } ],
    */
    // should only be one value. Should we account for more values?
    public static String[] getUsages(Object usageObj) {

       String[] usages = new String[]{};
       System.debug('getUsages usageObj='+usageObj);
       Object[] usageArray = (Object[])usageObj;
       for (Object usageToken : usageArray) {
          Map<String,Object> usageMap = (Map<String,Object>)usageToken;
          if (usageMap.containsKey('type')) {
             usages.add(String.valueOf(usageMap.get('type')));
             //usage = String.valueOf(usageMap.get('type'));
          }
       } //  for (Object usageToken
       System.debug('getUsages usages='+usages);
       return usages;
    } // getUsage
    
    /* parse this structure
   "postalAddresses" : [ {
      "AID" : "00H2A1IULCYST9997M6W",
      "usages" : [ {
        "type" : "LEGAL"
      } ],
      "errors" : [ {
        "errorCode" : "",
        "errorDescription" : ""
      } ]

     */
    public static void parseAddressInfo(EZOnboardingRegistration.EntResponse resp, CsoQueueable.AcctCsoWrap wrap, Object p_respObj, Boolean isLegal) {
       Object[] addresses = (Object[])p_respObj;
       System.debug('parseAddressInfo addresses='+addresses.size());
       for (Object addrInfo : addresses) {
          System.debug('parseAddressInfo addrInfo='+addrInfo);
          EZOnboardingRegistration.AddrResp addr = new EZOnboardingRegistration.AddrResp();
          Map<String,Object> addrMap = (Map<String,Object>)addrInfo;
          handleAddressKeys(addrMap, resp, addr, wrap, isLegal, true);
       } // for (Object addrInfo
        
    } // parseAddressInfo
    
    public static void handleAddressKeys(Map<String,Object> addrMap, EZOnboardingRegistration.EntResponse resp
                                           ,EZOnboardingRegistration.AddrResp addr, CsoQueueable.AcctCsoWrap wrap, Boolean isLegal, Boolean setAid) {
          String[] usages = (isLegal ? new String[]{EZOnboardingRegistration.ADDR_LEGAL} : new String[]{});
              
          for (String key : addrMap.keySet()) {
             System.debug('handleAddressKeys key='+key);
             Object addrObj = addrMap.get(key);
             handleAddressKey(key, addrObj, resp, addr, wrap, setAid, isLegal, usages);
             /*
             if (setAid && (key == 'AID' || key == 'id' || key == 'enterpriseAccountAddressId')) {
                addr.aid = String.valueOf(addrObj);
             } else if (isLegal && key == 'enterpriseClientAddressId') {
                // for the legal address should only have this key. For non-legal, will have both keys
                addr.aid = String.valueOf(addrObj);
             } else if (key == 'usages') {
                usages = getUsages(addrObj);
             } else if (key == 'type') {
                usages.add(String.valueOf(addrObj));
             } else if (key == 'errors' && resp != null && wrap != null) {
                checkErrors(resp, addr, wrap, addrObj);
             } else if (key == 'streetAddress1' || key == 'addressLine1') {
                addr.street = String.valueOf(addrObj);
             } else if (key == 'streetAddress2' || key == 'addressLine2') {
                addr.street2 = String.valueOf(addrObj);
             } else if (key == 'city') {
                addr.city = String.valueOf(addrObj);
             } else if (key == 'countrySubdivision') {
                addr.state = String.valueOf(addrObj);
             } else if (key == 'postalCode') {
                addr.postal = formatPostal(String.valueOf(addrObj));
              } else if (key == 'iso2CountryCode' || key == 'countryCodeISO') {
                addr.country = String.valueOf(addrObj);
             } else if (key == 'poBoxIndicator') {
                addr.poBox = Boolean.valueOf(addrObj);
             } else if (key == 'ceid') {
                addr.ceid = String.valueOf(addrObj);
             } else if (key == 'currentLegalAddressIndicator') {
                addr.isLegalAddr = Boolean.valueOf(addrObj);
             }
             // TODO - do we need to pull out the rest of the address information? 
             */
          } // for (String key
          // if there's a street2 value concatenate with the main street field
          if (String.isNotBlank(addr.street2)) {
             addr.street = (String.isNotBlank(addr.street) ? addr.street+'\n' : '') + addr.street2;
          }
          System.debug('parseAddressInfo usages='+usages+' aid='+addr.aid+' isLegal='+isLegal);
          for (String usage : usages) {
             if (usage == EZOnboardingRegistration.ADDR_LEGAL) {
                System.debug('parseAddressInfo setting aaid');
                resp.aaid = addr.aid;
                resp.legalAddr = addr;
             } else if (usage == EZOnboardingRegistration.ADDR_BILL) {
                System.debug('parseAddressInfo setting billingId');
                resp.billingId = addr.aid;
                resp.billAddr = addr;
             } else if (usage == EZOnboardingRegistration.ADDR_SHIP) {
                System.debug('parseAddressInfo setting shippingId');
                resp.shippingId = addr.aid;
                resp.shipAddr = addr;
             }
          } // for (String usage : usages
          // store by the key in case there's a problem with the usages (are they even relevant since we're passing in the id??)
          if (String.isNotBlank(addr.aid) && resp != null) {
             resp.addrMap.put(addr.aid,addr);
          }
          // store by this key also in case what we sent in changed
          if (String.isNotBlank(addr.sfId) && resp != null) {
             resp.addrMap.put(addr.sfId,addr);
          }

    } // handleAddressKeys
    
    public static void handleAddressKey(String key, Object addrObj, EZOnboardingRegistration.EntResponse resp
                                       ,EZOnboardingRegistration.AddrResp addr, CsoQueueable.AcctCsoWrap wrap
                                       ,Boolean setAid, Boolean isLegal, String[] usages) {
             System.debug('handleAddressKey key='+key+' addrObj='+addrObj);
             if (setAid && (key == 'AID' || key == 'id' || key == 'enterpriseAccountAddressId')) {
                addr.aid = String.valueOf(addrObj);
             } else if (isLegal && key == 'enterpriseClientAddressId') {
                // for the legal address should only have this key. For non-legal, will have both keys
                addr.aid = String.valueOf(addrObj);
             } else if (key == 'usages' && usages != null) {
                usages.addAll(getUsages(addrObj));
             } else if (key == 'type' && usages != null) {
                usages.add(String.valueOf(addrObj));
             } else if (key == 'errors' && resp != null && wrap != null) {
                checkErrors(resp, addr, wrap, addrObj);
             } else if (key == 'streetAddress1' || key == 'addressLine1' || key == 'streetLine1') {
                addr.street = String.valueOf(addrObj);
             } else if (key == 'streetAddress2' || key == 'addressLine2' || key == 'streetLine2') {
                addr.street2 = String.valueOf(addrObj);
             } else if (key == 'city') {
                addr.city = String.valueOf(addrObj);
             } else if (key == 'countrySubdivision') {
                addr.state = String.valueOf(addrObj);
             } else if (key == 'postalCode') {
                addr.postal = formatPostal(String.valueOf(addrObj));
              } else if (key == 'iso2CountryCode' || key == 'countryCodeISO') {
                addr.country = String.valueOf(addrObj);
             } else if (key == 'poBoxIndicator') {
                addr.poBox = Boolean.valueOf(addrObj);
             } else if (key == 'ceid') {
                addr.ceid = String.valueOf(addrObj);
             } else if (key == 'currentLegalAddressIndicator') {
                addr.isLegalAddr = Boolean.valueOf(addrObj);
             } else if (key == 'components') {
                handleStreetComponents(addr,addrObj);
             }
             // TODO - do we need to pull out the rest of the address information? 

    } // handleAddressKey
    
    public static void handleStreetComponents(EZOnboardingRegistration.AddrResp addr, Object objComponents) {
       if (String.isBlank(addr.street)) {
          Map<String,Object> compMap = (Map<String,Object>)objComponents;
          String[] strTokens = new String[]{};
          addToken(strTokens, String.valueOf(compMap.get('primaryNumber')));
          addToken(strTokens, String.valueOf(compMap.get('streetName')));
          addToken(strTokens, String.valueOf(compMap.get('streetSuffix')));
          if (!strTokens.isEmpty()) {
             addr.street = String.join(strTokens,' ');
          }
          System.debug('handleStreetComponents street='+addr.street);
       }
    } // handleStreetComponents
    
    public static void addToken(String[] strTokens, String checkVal) {
       if (String.isNotBlank(checkVal)) {
          strTokens.add(checkVal);
       }
    } // addToken
    
  /*
               "candidateAddresses": [
                    {
                        "content": {
                            "correlationId": "0",
                            "poBoxIndicator": false,
                            "city": "Penfield",
                            "countrySubdivision": "NY",
                            "postalCode": "14526191028",
                            "usPostalCodeComponents": {
                                "zip": "14526",
                                "plus4": "1910",
                                "zipPlus4": "145261910",
                                "deliveryPointNumber": "28"
                            },
                            "county": "Monroe",
                            "countryCodeISO": "US",
                            "components": {
                                "primaryNumber": "28",
                                "streetName": "Helmsford",
                                "streetSuffix": "Way",
                                "cityName": "Penfield",
                                "defaultCityName": "Penfield",
                                "stateAbbreviation": "NY",
                                "zipCode": "14526",
                                "plus4Code": "1910",
                                "deliveryPoint": "28",
                                "deliveryPointCheckDigit": "1"
                            },
                            "metadata": {
                                "recordType": "S",
                                "countyFips": "36055",
                                "countyName": "Monroe",
                                "carrierRoute": "C015",
                                "latitude": 43.13462,
                                "longitude": -77.4204,
                                "coordinatePrecision": "Zip9"
                            },
                            "analysis": {
                                "dpvMatchCode": "Y",
                                "dpvFootnotes": "AABB",
                                "dpvCmra": "N",
                                "dpvVacant": "N",
                                "dpvNoStat": "N",
                                "matchDetails": {
                                    "correctedZipCode": false,
                                    "correctedCityStateSpelling": false,
                                    "invalidCityStateZip": false,
                                    "noZipPlus4Assigned": false,
                                    "sameZipForMultiple": false,
                                    "missingSecondaryNumber": false,
                                    "insufficientAddressData": false,
                                    "cardinalRuleMatch": false,
                                    "changedAddressComponent": false,
                                    "correctedStreetSpelling": true,
                                    "fixedAbbreviations": false,
                                    "multipleZipPlus4LowestUsed": false,
                                    "betterAddressExists": false,
                                    "unrecognizedSecondaryAddress": false,
                                    "unofficialCityName": false,
                                    "unverifiableCityState": false,
                                    "matchedWithZIPMOVE": false
                                }
                            },
                            "normAddrRpcInd": "N"
                        },
                        "type": "com.paychex.client.resource.rest.v1.addressstandard.VerifyAddressResource"
                    }

   */
    public static void handleCandidateAddr(CsoQueueable.AcctCsoWrap wrap, EZOnboardingRegistration.EntResponse resp
                                          ,ErrResp erResp, Object addrObj) {
       System.debug('handleCandidateAddr');
       Object[] addresses = (Object[])addrObj;
       erResp.matchFromValidation = (addresses != null && addresses.size() >= 1);
       for (Object addrInfo : addresses) {
          // TODO - what do we do with more than one address?
          erResp.addrInfo = new EZOnboardingRegistration.AddrResp(); 
          Map<String,Object> addrMap = (Map<String,Object>)addrInfo;
          if (addrMap.containsKey('content')) {
             Map<String,Object> contentMap = (Map<String,Object>)addrMap.get('content');
             for (String key : contentMap.keySet()) {
                System.debug('handleCandidateAddr key='+key);
                Object contentToken = contentMap.get(key);
                handleAddressKey(key, contentToken, resp, erResp.addrInfo, wrap, false, false, null);
             }
          }
       } // for (Object addrInfo           
    } // handleCandidateAddr
    
    public static String formatPostal(String valueToFormat) {
       String postal = valueToFormat;
       if (String.isNotBlank(postal)) {
          // US ones should be all numeric
          if (postal.isNumeric()) {
             if (postal.length() > 5) {
                // remove any extra chars - might return as zip+6
                postal = postal.left(9);
                postal = postal.left(5)+'-'+postal.right(4);
             }
          }
       } // if (String.isNotBlank
       System.debug('formatPostal valueToFormat='+valueToFormat+' postal='+postal);
       return postal;
    } // formatPostal
    
    public static void parseAccounts(EZOnboardingRegistration.EntResponse resp, CsoQueueable.AcctCsoWrap wrap, Object p_respObj) {
       Object[] accts = (Object[])p_respObj;
       for (Object acctObj : accts) {
          EZOnboardingRegistration.EntResponse acct = new EZOnboardingRegistration.EntResponse();
          Map<String,Object> respMap = (Map<String,Object>)acctObj;
          for (String key : respMap.keySet()) {
             if (key == 'caid' || key == 'enterpriseCaid') {
                acct.caid = String.valueOf(respMap.get(key));
             } else if (key == 'accountNumber') {
                acct.cltNbr = String.valueOf(respMap.get(key));
             //} else if (key == 'sourceSystemId') {
             //   acct.acctId = String.valueOf(respMap.get(key));
             } else if (key == 'accountAddresses' || key == 'postalAddresses') {
                parseAddressInfo(acct, wrap, respMap.get(key), false);
             } else if (key == 'correlationId') {
                acct.acctId = String.valueOf(respMap.get(key));
             } else if (key == 'primarySourceSystem') {
                // TODO - this is only for OIC
                Object sourceSystemObj = respMap.get(key);
                Map<String,Object> systemMap = (Map<String,Object>)sourceSystemObj;
                for (String systemKey : systemMap.keySet()) {
                   if (systemKey == 'id') {
                      acct.acctId = String.valueOf(systemMap.get(systemKey));
                   } else if (systemKey == 'name') {
                      acct.sourceSystem = String.valueOf(systemMap.get(systemKey));
                   }
                } 
             }
          } // for (String key : respMap.keySet     
          System.debug('parseAccounts acct.acctId='+acct.acctId+' acct.caid='+acct.caid);
          if (String.isNotBlank(acct.acctId) || String.isNotBlank(acct.caid)) {
             resp.accts.add(acct);
             resp.acctMap.put(acct.acctId, acct);
             if (String.isBlank(resp.caid)) {
                resp.caid = acct.caid;
                resp.acctId = acct.acctId;
                resp.cltNbr = acct.cltNbr;
                resp.billingId = acct.billingId;
                resp.shippingId = acct.shippingId;
             }
          }
       } // for (Object acctObj : accts
    } // parseAccounts
    
    public static void parseClientInfo(EZOnboardingRegistration.EntResponse resp, CsoQueueable.AcctCsoWrap wrap, Object p_respObj) {
       Map<String,Object> respMap = (Map<String,Object>)p_respObj;
       for (String key : respMap.keySet()) {
          Object respObj = respMap.get(key);
          if (key == 'ceid') {
             resp.ceid = String.valueOf(respObj);
          } else if (key == 'clientValidationStatusCode') {
             resp.statusCode = String.valueOf(respObj);
          } else if (key == 'postalAddresses') {
             parseAddressInfo(resp, wrap, respObj, true);
          } else if (key == 'names') {
             handleNames(resp,wrap,respObj);
          } else if (key == 'taxpayerIdentification') {
             handleTaxpayerId(resp,wrap,respObj);
          }
       } // for (String key

    } // parseClientInfo
    
    public static void handleTaxpayerId(EZOnboardingRegistration.EntResponse resp, CsoQueueable.AcctCsoWrap wrap, Object nameInfo) {
       Map<String,Object> taxpayMap = (Map<String,Object>)nameInfo;
       resp.taxpayType = (taxpayMap.containsKey('type') ? String.valueOf(taxpayMap.get('type')) : null);
       String taxpayId = (taxpayMap.containsKey('id') ? String.valueOf(taxpayMap.get('id')) : null);
       // if FEIN format xx-xxxxxxx if SSN format xxx-xx-xxxx
       if (String.isNotBlank(taxpayId) && taxpayId.length() >= 9 && String.isNotBlank(resp.taxpayType)) {
          resp.taxpayId = (resp.taxpayType == 'SSN' ? (taxpayId.left(3)+'-'+taxpayId.substring(3,5)+'-'+taxpayId.substring(5))
                           : (taxpayId.left(2)+'-'+taxpayId.substring(2)));
       }
    } // handleTaxpayerId
    
    public static void handleNames(EZOnboardingRegistration.EntResponse resp, CsoQueueable.AcctCsoWrap wrap, Object nameInfo) {
       Map<String,Object> nameMap = (Map<String,Object>)nameInfo;
       if (nameMap.containsKey('primary')) {
          Map<String,Object> primaryMap = (Map<String,Object>)nameMap.get('primary');
          if (primaryMap.containsKey('name')) {
             resp.acctName = String.valueOf(primaryMap.get('name'));
          }
       }
    } // handleNames
    
    public static EZOnboardingRegistration.EntResponse parseOicResponse(CsoQueueable.AcctCsoWrap wrap, String response) {
       EZOnboardingRegistration.EntResponse entResp = new EZOnboardingRegistration.EntResponse();
       //resp.respMap = new Map<String,EntResponse>();
       System.debug('parseOicResponse response='+response);
        
       // TODO - only handling for 1 Id right now. 
       Map<String,Object> respMap = (Map<String,Object>)JSON.deserializeUntyped(response);
       System.debug('parseOicResponse respMap keys='+respMap.keySet());
       // check the status first because we might need it later on in the process.
       if (respMap.containsKey('status')) {
          entResp.statusCode = String.valueOf(respMap.get('status'));
       }
       for (String key : respMap.keySet()) {
          handleTopLevelKeys(entResp, wrap, key, respMap.get(key));
       } // for (String key : respMap.
       entResp.checkErrors();
       // if we get an error back from a previously registered client based on address, the account section won't be populated
       if (String.isBlank(entResp.caid) && entResp.accts.isEmpty() && (entResp.billAddr != null || entResp.shipAddr != null)) {
          entResp.caid = ((entResp.billAddr != null && String.isNotBlank(entResp.billAddr.caid)) ? entResp.billAddr.caid
                         : (entResp.shipAddr != null ? entResp.shipAddr.caid : null));
       }
       return entResp;
    } // parseOicResponse
    
    public static void handleTopLevelKeys(EZOnboardingRegistration.EntResponse entResp, CsoQueueable.AcctCsoWrap wrap, String key, Object respObj) {
       System.debug('handleTopLevelKeys key='+key+' respObj='+respObj);
       if (key == 'client') {
          parseClientInfo(entResp, wrap, respObj);
       } else if (key == 'ceid') {
          // todo - this shouldn't be at this level - only here temporarily
          entResp.ceid = String.valueOf(respObj);
       } else if (key == 'accounts' || key == 'billingAccounts') {
          parseAccounts(entResp, wrap, respObj);
       } else if (key == 'conflictResources' || key == 'errors') {
          checkErrors(entResp, null, wrap, respObj);
       } else if (key == 'successResponse') {
          Map<String,Object> successMap = (Map<String,Object>)respObj;
          if (successMap.containsKey('content')) {
             Map<String,Object> contentMap = (Map<String,Object>)successMap.get('content');
             for (String contentKey : contentMap.keySet()) {
                handleTopLevelKeys(entResp,wrap,contentKey,contentMap.get(contentKey));
             }
          }
       }
        
    } // handleTopLevelKeys
    
    
    
   /*
Sample response from OIC   1/16/2023

{
  "client" : {
    "ceid" : "00H2A1IULCYST9997M6W",
    "postalAddresses" : [ {
      "AID" : "00H2A1IULCYST9997M6W",
      "usages" : [ {
        "type" : "LEGAL"
      } ],
      "errors" : [ {
        "errorCode" : "",
        "errorDescription" : ""
      } ]
    }, {
      "AID" : "",
      "usages" : [ {
        "type" : "BILLING"
      } ],
      "errors" : [ {
        "errorCode" : "POSTAL_ADDRESS_COULD_NOT_BE_VERIFIED",
        "errorDescription" : "The postal address could not be verified"
      } ]
    }, {
      "AID" : "",
      "usages" : [ {
        "type" : "SHIPPING"
     } ],
      "errors" : [ {
        "errorCode" : "POSTAL_ADDRESS_COULD_NOT_BE_VERIFIED",
        "errorDescription" : "The postal address could not be verified"
      } ]
    } ]
  },
  "accounts" : [ {
    "caid" : "00H2A1IULCYST9M69I3Y",
    "primarySourceSystem" : {
      "id" : "0017500000GOI2lAAH",
      "name" : "SFDC",
      "effectivity" : {
        "active" : true
      }
    }
  } ]
}



  */
    
    /*
Please find the OIC endpoint URL for new client registration.
https://paycm56tst-idwtpqsqijlw-ia.integration.ocp.oraclecloud.com:443/ic/api/integration/v1/flows/rest/PAYXCRT_SFCREATE_INT_V1/1.0/NewClientRegistration
 
1.Sample Request from SF to OIC.
 
{
  "ceid" : "",
  "id" : "",
  "client" : {
    "id" : "",
    "ceid" : "",
    "type" : "",
    "taxPayerIdentification" : {
      "id" : "321223799",
      "type" : "FEIN"
    },
    "contacts" : "",
    "postalAddresses" : [ {
      "id" : "",
      "type" : "",
      "primarySourceSystem" : "",
      "secondarySourceSystems" : "",
      "recipient" : "",
      "streetAddress1" : "addrline1-1656092718332",
      "streetAddress2" : "",
      "city" : "ROCHESTER",
      "countrySubdivision" : "NY",
      "postalCode" : "123",
      "poBoxIndicator" : "",
      "iso2CountryCode" : "US",
      "region" : "",
      "attention" : "",
      "alternateCityNames" : "",
      "usages" : [ {
        "id" : "",
        "type" : "LEGAL",
        "audit" : {
          "dateTime" : "",
          "type" : "",
          "effectivity" : {
            "startDateTime" : "",
            "endDateTime" : "",
            "active" : "true"
          }
        },                                                                                          
        "sourceSystem" : {
          "id" : "KDJ-PARTY-SITE-USAGE-CDM-ID-12",
          "name" : "CDM",
          "effectivity" : {
            "startDateTime" : "",
            "endDateTime" : "",
            "active" : "true"
          }
        }
      } ],
      "audit" : "",
      "validated" : "false",
      "primary" : "false"
    } ],
    "names" : {
      "legal" : "",
      "primary" : {
        "id" : "",
        "name" : "Test-r-Documentation-Test5678432",
        "type" : "",
        "active" : "false"
      },
      "marketing" : ""
    },
    "primarySourceSystem" : "",
    "secondarySourceSystems" : "",
    "audit" : "",
    "usages" : ""
  },
  "accounts" : [ {
    "id" : "",
    "name" : "TEST-ENTRR-ACNT-1656091788336",
    "audit" : {
      "dateTime" : "",
      "type" : "",
      "effectivity" : {
        "startDateTime" : [ 2022, 6, 24, 13, 29, 48 ],
        "endDateTime" : [ 2022, 6, 29, 13, 29, 48 ],
        "active" : "false"
      }
    },
    "enterpriseCaid" : "",
    "accountNumber" : "",
    "salesChannelCode" : "",
    "type" : "",
    "contacts" : "",
    "postalAddresses" : "",
    "primarySourceSystem" : {
      "id" : "49184149953626",
      "ownerId" : "",
      "name" : "ENTERPRISE",
      "ownerName" : "",
      "effectivity" : {
        "startDateTime" : "",
        "endDateTime" : "",
        "active" : "true"
      }
    },
    "secondarySourceSystems" : "",
    "sendInvoiceByEmail" : "false",
    "profileClass" : "",
    "receiptMethodDto" : "",
    "payrollRunFrequency" : ""
  } ]
}
 
 
2.Sample Response to SF from OIC.
 
{
  "metadata" : {
    "contentItemCount" : 1
  },
  "content" : [ {
    "id" : "dba9a22b-05f0-4d82-b335-435f9d9897a2",
    "ceid" : "00H2A1IUL6CI7GWL1M0X",
    "addressLine1" : "1234 Swimming Way",
   "city" : "Melbourne",
    "countryCodeISO" : "AU",
    "poBoxIndicator" : false,
    "snapshotVersionNumber" : 1,
    "dpvMatchCode" : "N",
    "currentLegalAddressIndicator" : false
  } ]
}
     */

    public class ClientReq {
       public String ceid{get;set;}
    } // class ClientReq
    
    public class ClientResp {
       public String ceid{get;set;}
       public String ebsPartyId{get;set;}
       public String ossPartyId{get;set;}
    } // class ClientReq

    public class BillAcctReq{
       public String enterpriseCaid{get;set;}
       public CltAddrReq[] clientAddresses {get;set;}
    } // class BillAcctReq
    
    public class CltAddrReq{
       public String enterpriseAddressId{get;set;}
    } // class CltAddrResp

    public class ErrorResp{
       public String errorCode{get;set;}
       public String errorDescription{get;set;}
    } // class ErrorResp
    
    public class CltAddrResp{
       public String enterpriseAddressId{get;set;}
       public String ebsBillToSiteId{get;set;}
       public String ossBillToSiteId{get;set;}
       public String ebsShipToSiteId{get;set;}
       public String ossShipToSiteId{get;set;}
    } // class CltAddrResp

    public class BillAcctResp{
       public String enterpriseCaid{get;set;}
       public String ebsAccountId {get;set;}
       public String ossAccountId {get;set;}
       public CltAddrResp[] clientAddresses {get;set;}
       public ErrorResp[] errors {get;set;}
    } // class BillAcctResp

    public class OssIdRequest {
       public ClientReq client; 
       public BillAcctReq[] billingAccounts{get;set;}
    } // OssIdRequest
    
    public class OssIdResponse {
       public ClientResp client;
       public BillAcctResp[] billingAccounts{get;set;}
    } // class OssIdResponse
    
    public static EZOnboardingRegistration.EntResponse handleKeysResp(String response) {
       EZOnboardingRegistration.EntResponse resp = new EZOnboardingRegistration.EntResponse();
       EntRespHelper.OssIdResponse ossResp = (String.isNotBlank(response) ? (EntRespHelper.OssIdResponse)json.deserialize(response, EntRespHelper.OssIdResponse.class) : new EntRespHelper.OssIdResponse());
       resp.ossKeysResp = ossResp;
       return resp;
    } // handleKeysResp
    
    public static String getAddressKeyJson(CsoQueueable.AcctCsoWrap wrap) {
       return getAddressKeyJson(new Account[]{wrap.cso.AccountId__r});
    }
    
    public static String getAddressKeyJson(Account[] accts) {
       System.debug('getAddressIds accts='+accts.size());
       OssIdRequest oReq = new OssIdRequest();
       oReq.client = new ClientReq();
       oReq.client.ceid = accts[0].Paychex_CEID__c;
       oReq.billingAccounts = new BillAcctReq[]{};
       for (Account acct : accts) {
          BillAcctReq billAcct = new BillAcctReq();
          billAcct.enterpriseCaid = acct.Paychex_CAID__c;
          billAcct.clientAddresses = new CltAddrReq[]{};
          if (String.isNotBlank(acct.EnterpriseBillingId__c)) {
             CltAddrReq car = new CltAddrReq();
             car.enterpriseAddressId = acct.EnterpriseBillingId__c;
             billAcct.clientAddresses.add(car);
          }
          if (String.isNotBlank(acct.EnterpriseShippingId__c) && acct.EnterpriseShippingId__c != acct.EnterpriseBillingId__c) {
             CltAddrReq car = new CltAddrReq();
             car.enterpriseAddressId = acct.EnterpriseShippingId__c;
             billAcct.clientAddresses.add(car);
          }
          // only add if there's at least one address.
          if (!billAcct.clientAddresses.isEmpty()) {
             oReq.billingAccounts.add(billAcct);
          }
       } // for (Account acct
       String output = null;
       if (!oReq.billingAccounts.isEmpty()) {
          output = json.serialize(oReq).replace('number_Z','number');
       } 
       return output;
    } // getAddressKeyJson
    
    /*
     {
  "client":{
     "ceid":"00J5VPBJLM6N3V8C6FKU"
  },
  "billingAccounts":[ {
     "enterpriseCaid":"00J5VPBJLM6N3V8C6FKV"
     "clientAddresses" : [ {
        "enterpriseAddressId" : "86ce78d8-944d-402c-802c-f1138ffde819",
          "enterpriseAddressId" : "c3412498-dbbe-4575-9595-8f3182a43e32"
     } ]
  } ] 
}

  Account acct = new Account(Paychex_CEID__c='00J5VPBJLM6N3V8C6FKU', Paychex_CAID__c='00J5VPBJLM6N3V8C6FKV');  
  acct.EnterpriseBillingId__c='86ce78d8-944d-402c-802c-f1138ffde819'; 
  acct.EnterpriseShippingId__c='c3412498-dbbe-4575-9595-8f3182a43e32'; 
  String resp=EntRespHelper.getAddressKeyJson2(new Account[]{acct});
  System.debug('resp='+resp);
*/
    /*
    public static String getAddressKeyJson2(Account[] accts) {
       JSONGenerator gen = JSON.createGenerator(true);
       gen.writeStartObject();
       gen.writeFieldName('client');
       gen.writeStartObject();
       EZOnboardingRegistration.addStringField(gen,'ceid',accts[0].Paychex_CEID__c,true);
       gen.writeEndObject();

       gen.writeFieldName('billingAccounts');
       gen.writeStartArray();
       for (Account acct : accts) {
          gen.writeStartObject();
          EZOnboardingRegistration.addStringField(gen,'enterpriseCaid',acct.Paychex_CAID__c,true);
          gen.writeFieldName('clientAddresses');
          gen.writeStartArray();
          gen.writeStartObject();
          if (String.isNotBlank(acct.EnterpriseBillingId__c)) {
             EZOnboardingRegistration.addStringField(gen,'enterpriseAddressId',acct.EnterpriseBillingId__c,true);
          }
          if (String.isNotBlank(acct.EnterpriseShippingId__c) && acct.EnterpriseShippingId__c != acct.EnterpriseBillingId__c) {
             EZOnboardingRegistration.addStringField(gen,'enterpriseAddressId',acct.EnterpriseShippingId__c,true);
          }
          gen.writeEndObject();
          gen.writeEndArray();
          gen.writeEndObject();
       } // for (Account acct : accts
           
       gen.writeEndArray();
        
       gen.writeEndObject();  // end of JSON string
       System.debug('getAddressKeyJson gen='+gen.getAsString());
       return gen.getAsString();
    } // getAddressKeyJson
    */
    /*
    public static void testIdReq() {
       OssIdRequest oReq = new OssIdRequest();
       oReq.client = new ClientReq();
       oReq.client.ceid = '00JD49W7GSJK6MPX321A';
       oReq.billingAccounts = new BillAcctReq[]{};
       BillAcctReq billAcct = new BillAcctReq();
       billAcct.enterpriseCaid = '00DWS906HKXYJ88ATDNC';
       oReq.billingAccounts.add(billAcct);
       String output = json.serialize(oReq).replace('number_Z','number');
       System.debug('output='+output);
       
       
    } // testIdReq
    */
    public class CpqKeys {
       public CpqDoc documents = new CpqDoc();
       public CpqCriteria criteria = new CpqCriteria();
    } // class CpqKeys
    
    public class CpqDoc {
       public String partyId_t{get;set;}
       public String accountNumber_t{get;set;}
       public String billToSiteUseId_t{get;set;}
       public String shipToAccountId_t{get;set;}
       public String shipToPartyId_t{get;set;}
       public String shipToSiteId_t{get;set;}
       public String SFDCChildAccountData_t{get;set;}
    } // CpqDoc
    
    public class CpqCriteria {
       public CpqCriteria() {
          fields = new String[]{};
          fields.add('bs_id');
       }
       public String[] fields;
    } // class CpqCriteria
    
    public static String getCpqChildren(Account[] accts) {
       JSONGenerator gen = JSON.createGenerator(false);
       gen.writeStartArray();
       for (Account acct : accts) {
          gen.writeStartObject();
          EZOnboardingRegistration.addStringField(gen,'Id',acct.Id,true);
          EZOnboardingRegistration.addStringField(gen,'Name',EZOnboardingRegistration.formatName(acct.Name),true);
          EZOnboardingRegistration.addStringField(gen,'OSSPartyID__c',acct.OSSPartyID__c,true);
          EZOnboardingRegistration.addStringField(gen,'OSSAccountID__c',acct.OSSAccountID__c,true);
          EZOnboardingRegistration.addStringField(gen,'OSSBillToSiteID__c',acct.OSSBillToSiteID__c,true);
          EZOnboardingRegistration.addStringField(gen,'OSSShipToSiteID__c',acct.OSSShipToSiteID__c,true);
          gen.writeEndObject();
       } // for (Account acct
       gen.writeEndArray(); 
       return gen.getAsString();
    } // getCpqChildren

    public static String getLegalUpdateJson(String ceid, String legalName, String street, String city, String state, String postal, String country) {
       if (String.isBlank(ceid)) {
          return null;
       }
       JSONGenerator gen = JSON.createGenerator(true);
       gen.writeStartArray();
       gen.writeStartObject();
       EZOnboardingRegistration.addStringField(gen,'ceid',ceid,true);
       gen.writeFieldName('jsonPatch');
       gen.writeStartArray();
       if (String.isNotBlank(legalName)) {
          gen.writeStartObject();
             EZOnboardingRegistration.addStringField(gen,'op','replace',true);
             EZOnboardingRegistration.addStringField(gen,'path','/legalName',true);
             EZOnboardingRegistration.addStringField(gen,'value',EZOnboardingRegistration.formatName(legalName),true);
          gen.writeEndObject();
       }
       if (String.isNotBlank(street) && String.isNotBlank(postal)) {
          gen.writeStartObject();
             EZOnboardingRegistration.addStringField(gen,'op','replace',true);
             EZOnboardingRegistration.addStringField(gen,'path','/postalAddresses',true);
             gen.writeFieldName('value');
             gen.writeStartArray();
             EZOnboardingRegistration.addAddress(gen,null,new String[]{EZOnboardingRegistration.ADDR_LEGAL}, (String)null, street, city, state, postal, country
                     ,'addressLine1','addressLine2','poBoxIndicator','city','state','postalCode','country');
                     //,'streetAddress1','streetAddress2','poBoxIndicator','city','countrySubdivision','postalCode','iso2CountryCode');
             gen.writeEndArray();
          gen.writeEndObject();
       }
       gen.writeEndArray();  // jsonPatch
       
       gen.writeEndObject();  // end of JSON string
       gen.writeEndArray();
        
       System.debug('getLegalUpdateJson gen='+gen.getAsString());
       return gen.getAsString();
    } // getLegalUpdateJson

    
} // class EntRespHelper