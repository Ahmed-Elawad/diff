/* 
  Tests for the WebServiceLogAfter trigger. 
   
  History
  -------
  06/26/2014 Cindy Freeman   Created

 */
 
 @isTest
private class WebServiceLogAfterTest {
/*
   static testMethod void myUnitTest() {
            
        DataFluxDeltaServiceTest.populateEndpoint();
                
      WebServicesHelper.WebServiceWrapper wsWrap = new WebServicesHelper.WebServiceWrapper();
        wsWrap.svcName = 'DFDeltaSvc';
        wsWrap.requestxml = makeCtctRequestXML();
        wsWrap.namedFunction = 'Test function';
        wsWrap.sobjName = 'Test SObject';
        wsWrap.sendMsg = true;
        WebServicesHelper.logServiceCall(wsWrap);
        
        Test.StartTest();
        DataFluxDeltaBatch deltaBatch = new DataFluxDeltaBatch();
        //batches.query = 'Select Id, Name, ServiceName__c, SobjName__c, NamedFunction__c, SendMsg__c, Successful__c, Notes__c ';
        //batches.query += 'from Web_Service_Log__c where ServiceName__c = \'WebSvcLogAfter Test\' and SendMsg__c = true';
        Id batchprocessId = Database.executeBatch(deltaBatch);
        Test.stopTest();
        
        Web_Service_Log__c wslog = [Select Id, ServiceName__c, CalledBy__c, CalledDT__c, Successful__c, ErrorMsg__c, Notes__c, NamedFunction__c, SobjName__c 
                                    from Web_Service_Log__c where ServiceName__c = 'DFDeltaSvc']; //'WebSvcLogAfter Test'];
        System.assertEquals(System.Today(), wslog.CalledDT__c.date());
        System.assertEquals(UserInfo.getUserId(), wslog.CalledBy__c);
        System.assertEquals(true, wslog.Successful__c);
        
        Attachment[] attached = [Select Id, Name, ParentId, Body from Attachment where ParentId = :wslog.Id];
        System.assertEquals(2, attached.size());
                
    } // myUnitTest    
    
    private static String makeCtctRequestXML() {
        String requestxml = '<?xml version="1.0" encoding="UTF-8"?>';
        requestxml += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v1="http://xml.paychex.com/paychex/enterprise/service/v1/" xmlns:v4="http://xml.paychex.com/paychex/enterprise/common/v4/">';
        requestxml += '<soapenv:Header/><soapenv:Body><v1:Change><v1:ServiceRequest><v1:RequestContext correlationId="token"/>';
        requestxml += '<v1:DataArea><v1:DataAreaContext/><v1:VerbNounExpressions>';
        requestxml += '<v1:Nouns xsi:type="v9:SalesLeadType" xmlns:v9="http://www.openapplications.org/oagis/v9/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
        requestxml += '<v4:IDs xsi:type="v9:IdentifierType" schemeID="GUID">003S000000meyimIAA</v4:IDs>';
        requestxml += '<v9:SalesLeadHeader><v9:CustomerParty><v4:IDs xsi:type="v9:IdentifierType" schemeID="SFDC_ID">001S000000hJZNLIA4</v4:IDs>';
        requestxml += '<v9:Contact><v4:IDs xsi:type="v9:IdentifierType" schemeID="SFDC_ID">003S000000abcdeABC</v4:IDs>';
        requestxml += '<v4:IDs xsi:type="v9:IdentifierType" schemeID="DF_ID">123</v4:IDs>';
        requestxml += '<v9:Name sequenceName="First">Freddie Test</v9:Name><v9:Name sequenceName="Last">Freeloader</v9:Name>';
        requestxml += '<v9:EMailAddressCommunication><v9:EMailAddressName></v9:EMailAddressName></v9:EMailAddressCommunication>';
        requestxml += '<v9:TelephoneCommunication><v9:DialNumber>(801) 960-6318</v9:DialNumber></v9:TelephoneCommunication>';
        requestxml += '<v9:Address><v9:LineOne>10 Maple Drive</v9:LineOne><v9:CityName>Batavia</v9:CityName><v9:CountrySubDivisionCode>NY</v9:CountrySubDivisionCode>';
        requestxml += '<v9:PostalCode>14414</v9:PostalCode></v9:Address></v9:Contact></v9:CustomerParty></v9:SalesLeadHeader>';
        requestxml += '</v1:Nouns><v1:VerbContexts actionCode ="Modify"><v1:Where><v1:NamedFunction name="DELTA_JOB_CONTACT"/></v1:Where>';
        requestxml += '</v1:VerbContexts></v1:VerbNounExpressions></v1:DataArea></v1:ServiceRequest></v1:Change></soapenv:Body></soapenv:Envelope>';
        return requestxml;
    } // makeCtctRequestxml
 */       
}