/* Mock call for Dataflux
   
   History
   -------
   03/16/2024 Dan Carmen        Created

*/
@isTest
global class DataFluxDeltaServiceMock implements HttpCalloutMock {

    global String responseToUse = '';
    global Integer responseCode = 200;

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody(responseToUse);
        res.setStatusCode(responseCode);
        return res;
    }

    public static String makeLeadResponseXML2() {
        
    List <Lead> leadList = [Select Id, Name, Lead_Company__c from Lead where Name = 'Mary Lead1' or Name = 'John Lead2' order by LastName];
        
        string xml = '<?xml version="1.0" encoding="UTF-8"?>';  
            xml += '<SOAP-ENV:Envelope'; 
            xml += 'xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"'; 
            xml += 'xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"';
            xml += 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'; 
            xml += 'xmlns:xsd="http://www.w3.org/2001/XMLSchema"'; 
            xml += 'xmlns:archwsdl="archserver.wsdl.dataflux.com"'; 
            xml += 'xmlns:archxsd="archserver.xsd.dataflux.com"><SOAP-ENV:Header></SOAP-ENV:Header><SOAP-ENV:Body>'; 
            xml += '<archxsd:GetArchitectServiceResponse><status>0</status>'; 
            xml += '<fieldDefinitions><fieldName>REQUESTID</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>DF_UID</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>RECORD_PROCESSED</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>SFDC_ID</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>SHIPPING_ADDR_MATCHCODE1_STREET1</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>BILLING_ADDR_MATCHCODE1_STREET1</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>NAME_MATCHCODE1</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>';                
            xml += '<dataRows>'; //start data rows 
            xml += '<value>'; 
            xml += '123456789'; //leadList.get(0).Id; 
            xml += '</value>'; 
            xml += '<value>'; 
            xml += '123456789'; // leadList.get(0).Id; 
            xml += '</value>';  
            xml += '<value>'; 
            xml += 'True'; 
            xml += '</value>';     
            xml += '<value>'; 
            xml += leadList.get(0).Id; 
            xml += '</value>';  
            xml += '<value>'; 
            xml += 'ABC123'; 
            xml += '</value>';  
            xml += '<value>'; 
            xml += '123ABC'; 
            xml += '</value>';  
            xml += '<value>'; 
            xml += 'DEF456'; 
            xml += '</value>';              
            xml += '</dataRows>'; //end data rows           
                
                if (leadList.size() == 2){          
                xml += '<dataRows>';                
                xml += '<value>'; 
                xml += '111222333'; 
                xml += '</value>'; 
                xml += '<value>'; 
                xml += '111222333'; 
                xml += '</value>';  
                xml += '<value>'; 
                xml += 'True'; 
                xml += '</value>';     
                xml += '<value>'; 
                xml += leadList.get(1).Id; 
                xml += '</value>'; 
                xml += '<value>'; 
                xml += 'ABC123'; 
                xml += '</value>';  
                xml += '<value>'; 
                xml += '123ABC'; 
                xml += '</value>';  
                xml += '<value>'; 
                xml += 'DEF456'; 
                xml += '</value>';              
                xml += '</dataRows>';           
                }//if
            xml += '<svcId>140</svcId><logFile xsi:nil="true"/>'; 
            xml += '</archxsd:GetArchitectServiceResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>'; 
            
            return xml; 
            
            
        
    }   //makeLeadResponse2       
 
    public static String makeCtctResponseXML2() {
        List<String> nameList = new List<String>{'Lead1','Lead2','Last1','Last4','Prospect1'};
        List<Contact> ctctList = [select Id, Name, Dataflux_Id__c from Contact where LastName in :nameList];
        
            string xml = '<?xml version="1.0" encoding="UTF-8"?>';  
            xml += '<SOAP-ENV:Envelope'; 
            xml += 'xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"'; 
            xml += 'xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"';
            xml += 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'; 
            xml += 'xmlns:xsd="http://www.w3.org/2001/XMLSchema"'; 
            xml += 'xmlns:archwsdl="archserver.wsdl.dataflux.com"'; 
            xml += 'xmlns:archxsd="archserver.xsd.dataflux.com"><SOAP-ENV:Header></SOAP-ENV:Header><SOAP-ENV:Body>'; 
            xml += '<archxsd:GetArchitectServiceResponse><status>0</status>'; 
            xml += '<fieldDefinitions><fieldName>REQUESTID</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>DF_UID</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>RECORD_PROCESSED</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>SFDC_ID</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>SHIPPING_ADDR_MATCHCODE1_STREET1</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>BILLING_ADDR_MATCHCODE1_STREET1</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>NAME_MATCHCODE1</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>';            
            
            for(Contact ct:ctctList){
                xml += '<dataRows>';                
                xml += '<value>'; 
                xml += ct.id; 
                xml += '</value>'; 
                xml += '<value>'; 
                xml += ct.id; 
                xml += '</value>';  
                xml += '<value>'; 
                xml += 'True'; 
                xml += '</value>';     
                xml += '<value>'; 
                xml += ct.Id; 
                xml += '</value>'; 
                xml += '<value>'; 
                xml += 'ABC123'; 
                xml += '</value>'; 
                xml += '<value>'; 
                xml += '123ABC'; 
                xml += '</value>'; 
                xml += '<value>'; 
                xml += 'DEF456'; 
                xml += '</value>';                                              
                xml += '</dataRows>';        
            }           
                
            xml += '<svcId>140</svcId><logFile xsi:nil="true"/>'; 
            xml += '</archxsd:GetArchitectServiceResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>';         
            
            return xml; 
    }//make contact response 2 

   // for DataFlux delta trigger, see if field went from null to a value or the value changed
   public static String makeAcctResponseXML2() {        
        Account acct = [select Id, Name from Account where Name = 'Test Account1'];
        string xml = '<?xml version="1.0" encoding="UTF-8"?>';  
            xml += '<SOAP-ENV:Envelope'; 
            xml += 'xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"'; 
            xml += 'xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"';
            xml += 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'; 
            xml += 'xmlns:xsd="http://www.w3.org/2001/XMLSchema"'; 
            xml += 'xmlns:archwsdl="archserver.wsdl.dataflux.com"'; 
            xml += 'xmlns:archxsd="archserver.xsd.dataflux.com"><SOAP-ENV:Header></SOAP-ENV:Header><SOAP-ENV:Body>'; 
            xml += '<archxsd:GetArchitectServiceResponse><status>0</status>'; 
            xml += '<fieldDefinitions><fieldName>REQUESTID</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>DF_UID</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>RECORD_PROCESSED</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>SFDC_ID</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>';            
            xml += '<fieldDefinitions><fieldName>SHIPPING_ADDR_MATCHCODE1_STREET1</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>BILLING_ADDR_MATCHCODE1_STREET1</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            xml += '<fieldDefinitions><fieldName>ORG_MATCHCODE1</fieldName><fieldType>STRING</fieldType><fieldLength>255</fieldLength></fieldDefinitions>'; 
            
            
            xml += '<dataRows>';                
            xml += '<value>'; 
            xml += acct.id; 
            xml += '</value>'; 
            xml += '<value>'; 
            xml += acct.id; 
            xml += '</value>';  
            xml += '<value>'; 
            xml += 'True'; 
            xml += '</value>';     
            xml += '<value>'; 
            xml += acct.Id; 
            xml += '</value>'; 
            xml += '<value>'; 
            xml += 'ABC123'; 
            xml += '</value>'; 
            xml += '<value>'; 
            xml += '123ABC'; 
            xml += '</value>'; 
            xml += '<value>'; 
            xml += 'DEF456'; 
            xml += '</value>';          
            xml += '</dataRows>';        
            xml += '<svcId>140</svcId><logFile xsi:nil="true"/>'; 
            xml += '</archxsd:GetArchitectServiceResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>';         
            
            return xml; 
        
    }//makeAcctResponseXML2

} // class DataFluxDeltaServiceMock