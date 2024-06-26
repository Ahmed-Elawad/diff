/* 
   Mock CSO Call

   
  History
  -------
  07/11/2022 Harish Lanka    Created

*/
@isTest
global class EZOnboardingRegistrationMock implements HttpCalloutMock {
    
    global static String defaultResponse = '{"example":"test","caid":"test1234567890","ceid":"test0987654321","id":"thisistheidfield","guid":"thisistheguid"}';
    
    global String responseToUse = defaultResponse;
    global Integer responseCode = 200;
    
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        //res.setBody('{"example":"test","caid":"test1234567890","ceid":"test0987654321","id":"thisistheidfield","guid":"thisistheguid"}');
        res.setBody(responseToUse);
        res.setStatusCode(responseCode);
        return res;
    }
    
    global static String acctId1='0017500000GOI2lAAH';
    global static String acctId2='0017500000GOI2mAAH';
    global static String acctId3='0017500000GOI2nAAH';
    
   global static String testCeid='00H2A1IULCYST9997M6W';
   global static String testCaid='00H2A1IULCYST9M69I3Y';
   global static String testCaid2='00H2A1IULCYST9M69I3Z';
   global static String testLegalAid='00H2A1IULCYST9997M6W';
   global static String testBillAid='8faef214-4e5a-47f1-9323-9e005be1d2c2';
   global static String testShipAid='44367d10-7591-4918-bd47-793acd5fb5d0';
   global static String testBillAid2='8faef214-4e5a-47f1-9323-9e005be1d2c4';
   global static String testShipAid2='44367d10-7591-4918-bd47-793acd5fb5d4';
   global static String testAcctNbr1='70192442';
   global static String testAcctNbr2='70192443';
    
   /*
{"client" : {
    "ceid" : "00H2A1IULCYST9997M6W",
    "postalAddresses" : [ {
      "AID" : "00H2A1IULCYST9997M6W",
      "usages" : [ {
        "type" : "LEGAL"
      } ]
    }, {
      "AID" : "8faef214-4e5a-47f1-9323-9e005be1d2c2",
      "usages" : [ {
        "type" : "BILLING"
      } ]
    }, {
      "AID" : "44367d10-7591-4918-bd47-793acd5fb5d0",
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
    "clientValidationStatusCode" : "200",
    "primarySourceSystem" : {
      "id" : "0017500000GOI2lAAH",
      "name" : "SFDC"
    }
  } ]
}
   */
    /*
   global String getTestOicResponse(String acctId) {
     JSONGenerator gen = JSON.createGenerator(true);
     gen.writeStartObject();
       gen.writeFieldName('client');
         gen.writeStartObject();
           gen.writeStringField('ceid',EZOnboardingRegistrationMock.testCeid);

           gen.writeFieldName('postalAddresses');
             gen.writeStartArray();
               gen.writeStartObject();
                 //gen.writeStringField('AID',EZOnboardingRegistrationMock.testLegalAid);
                 gen.writeStringField('enterpriseClientAddressId',EZOnboardingRegistrationMock.testLegalAid);
                 gen.writeStringField('streetAddress1','5254 Spencerport Rd');
                 gen.writeStringField('city','Rochester');
                 gen.writeStringField('countrySubdivision','NY');
                 gen.writeStringField('postalCode','14606');
                 gen.writeBooleanField('poBoxIndicator',false);
                 gen.writeStringField('iso2CountryCode','US');
                 gen.writeFieldName('usages');
                   gen.writeStartArray();
                     gen.writeStartObject();
                       gen.writeStringField('type','LEGAL');
                     gen.writeEndObject();
     	          gen.writeEndArray();
               gen.writeEndObject();
 
               gen.writeStartObject();
                 gen.writeStringField('AID',EZOnboardingRegistrationMock.testBillAid);
                 gen.writeFieldName('usages');
                   gen.writeStartArray();
                     gen.writeStartObject();
                       gen.writeStringField('type','BILLING');
                     gen.writeEndObject();
     	          gen.writeEndArray();
               gen.writeEndObject();

               gen.writeStartObject();
                 gen.writeStringField('AID',EZOnboardingRegistrationMock.testShipAid);
                 gen.writeFieldName('usages');
                   gen.writeStartArray();
                     gen.writeStartObject();
                       gen.writeStringField('type','SHIPPING');
                     gen.writeEndObject();
                   gen.writeEndArray();
                 gen.writeFieldName('errors');
                   gen.writeStartArray();
                     gen.writeStartObject();
                       gen.writeStringField('errorCode','POSTAL_ADDRESS_COULD_NOT_BE_VERIFIED');
                       gen.writeStringField('errorDescription','The postal address could not be verified');
     	            gen.writeEndObject();
     	          gen.writeEndArray();
     	   
     	      gen.writeEndObject();
             gen.writeEndArray();
         gen.writeEndObject();
     
       gen.writeFieldName('accounts');
         gen.writeStartArray();
           gen.writeStartObject();
             gen.writeStringField('caid',EZOnboardingRegistrationMock.testCaid);
             gen.writeStringField('clientValidationStatusCode','200');
             gen.writeFieldName('primarySourceSystem');
               gen.writeStartObject();
                 gen.writeStringField('id',acctId);
                 gen.writeStringField('name','SFDC');
	           gen.writeEndObject();
           gen.writeEndObject();
         gen.writeEndArray();
     
         gen.writeEndObject();
	   System.debug('getTestOicResponse='+gen.getAsString());
       return gen.getAsString();
    } // getTestOicResponse
    */
   global String getTestEcagResponse(String acctId) {
     JSONGenerator gen = JSON.createGenerator(true);
     gen.writeStartObject();
       gen.writeFieldName('client');
         gen.writeStartObject();
           gen.writeStringField('ceid',EZOnboardingRegistrationMock.testCeid);

           gen.writeFieldName('postalAddresses');
             gen.writeStartArray();
               gen.writeStartObject();
                 //gen.writeStringField('id',EZOnboardingRegistrationMock.testLegalAid);
                 gen.writeStringField('enterpriseClientAddressId',EZOnboardingRegistrationMock.testLegalAid);
                 gen.writeStringField('streetAddress1','5254 Spencerport Rd');
                 gen.writeStringField('city','Rochester');
                 gen.writeStringField('countrySubdivision','NY');
                 gen.writeStringField('postalCode','14606');
                 gen.writeBooleanField('poBoxIndicator',false);
                 gen.writeStringField('iso2CountryCode','US');
                 gen.writeFieldName('usages');
                   gen.writeStartArray();
                     gen.writeStartObject();
                       gen.writeStringField('type','LEGAL');
                     gen.writeEndObject();
     	          gen.writeEndArray();
               gen.writeEndObject();
 
             gen.writeEndArray();
         gen.writeEndObject();
     
       gen.writeFieldName('billingAccounts');
         gen.writeStartArray();
           gen.writeStartObject();
             gen.writeStringField('enterpriseCaid',EZOnboardingRegistrationMock.testCaid);
             gen.writeStringField('accountNumber',EZOnboardingRegistrationMock.testAcctNbr1);
             gen.writeStringField('correlationId',acctId);
             //gen.writeFieldName('primarySourceSystem');
             //   gen.writeStartObject();
             //      gen.writeStringField('id',acctId);
             //      gen.writeStringField('name','SFDC');
             //   gen.writeEndObject();
             gen.writeStringField('clientValidationStatusCode','200');
       
             //gen.writeFieldName('accountAddresses');
             gen.writeFieldName('postalAddresses');
               gen.writeStartArray();
                 gen.writeStartObject();
                   //gen.writeStringField('id',EZOnboardingRegistrationMock.testBillAid);
                   //gen.writeStringField('caid',EZOnboardingRegistrationMock.testCaid);
                   //gen.writeStringField('type','BILLING');
                   //gen.writeStringField('startDate','2022-11-11');
                   gen.writeStringField('enterpriseAccountAddressId',EZOnboardingRegistrationMock.testBillAid);
                   gen.writeStringField('streetAddress1','5254 Spencerport Rd');
                   gen.writeStringField('city','Rochester');
                   gen.writeStringField('countrySubdivision','NY');
                   gen.writeStringField('postalCode','14606');
                   gen.writeBooleanField('poBoxIndicator',false);
                   gen.writeStringField('iso2CountryCode','US');
                   gen.writeFieldName('usages');
                     gen.writeStartArray();
                       gen.writeStartObject();
                         gen.writeStringField('type','BILLING');
                       gen.writeEndObject();
                     gen.writeEndArray();

                 gen.writeEndObject();
                 gen.writeStartObject();
                   //gen.writeStringField('id',EZOnboardingRegistrationMock.testShipAid);
                   //gen.writeStringField('caid',EZOnboardingRegistrationMock.testCaid);
                   //gen.writeStringField('type','SHIPPING');
                   //gen.writeStringField('startDate','2022-11-11');
                   gen.writeStringField('enterpriseAccountAddressId',EZOnboardingRegistrationMock.testShipAid);
                   gen.writeStringField('streetAddress1','4390 Buffalo Rd');
                   gen.writeStringField('city','North Chili');
                   gen.writeStringField('countrySubdivision','NY');
                   gen.writeStringField('postalCode','14514');
                   gen.writeBooleanField('poBoxIndicator',false);
                   gen.writeStringField('iso2CountryCode','US');
                   gen.writeFieldName('usages');
                     gen.writeStartArray();
                       gen.writeStartObject();
                         gen.writeStringField('type','SHIPPING');
                       gen.writeEndObject();
                     gen.writeEndArray();
                   gen.writeFieldName('errors');
                     gen.writeStartArray();
                       gen.writeStartObject();
                         gen.writeStringField('errorCode','POSTAL_ADDRESS_COULD_NOT_BE_VERIFIED');
                         gen.writeStringField('errorDescription','The postal address could not be verified');
                       gen.writeEndObject();
     	             gen.writeEndArray();
                 gen.writeEndObject();

               gen.writeEndArray();
           gen.writeEndObject();

         gen.writeEndArray();
     
       gen.writeEndObject();
	   System.debug('getTestEcagResponse='+gen.getAsString());
       return gen.getAsString();
    } // getTestEcagResponse

   global String getTestOicError(String acctId) {
     JSONGenerator gen = JSON.createGenerator(true);
     gen.writeStartObject();
       gen.writeFieldName('client');
         gen.writeStartObject();
           gen.writeStringField('ceid',EZOnboardingRegistrationMock.testCeid);
           gen.writeStringField('clientValidationStatusCode','400');

           gen.writeFieldName('postalAddresses');
             gen.writeStartArray();
               gen.writeStartObject();
                 gen.writeStringField('AID',EZOnboardingRegistrationMock.testLegalAid);
                 gen.writeFieldName('usages');
                   gen.writeStartArray();
                     gen.writeStartObject();
                       gen.writeStringField('type','LEGAL');
                     gen.writeEndObject();
     	          gen.writeEndArray();
                 gen.writeFieldName('errors');
                   gen.writeStartArray();
                     gen.writeStartObject();
                       gen.writeStringField('errorCode','ENT-CLIENT-VIOLATION-39');
                       gen.writeStringField('errorDescription','Client with this legal name and address already exists');
                       gen.writeFieldName('conflictResource');
                         gen.writeStartObject();
                           gen.writeFieldName('links');
                             gen.writeStartArray();
                               gen.writeStartObject();
                                 gen.writeStringField('rel','matchingClient');
                                 gen.writeStringField('href','https://ent-ose-client-svc-pyx.n2a-lb.paychex.com/clients?ceid=00H2A1IUL9YMFARWMV10');
                               gen.writeEndObject();
                             gen.writeEndArray();
                         gen.writeEndObject();
     	            gen.writeEndObject();
       
                     gen.writeStartObject();
                       gen.writeStringField('errorCode','ENT-CLIENT-VIOLATION-1');
                       gen.writeStringField('errorDescription','Invalid Error 1');
     	            gen.writeEndObject();
     	          gen.writeEndArray();
               gen.writeEndObject();

               gen.writeStartObject();
                 gen.writeStringField('AID',EZOnboardingRegistrationMock.testBillAid);
                 gen.writeFieldName('usages');
                   gen.writeStartArray();
                     gen.writeStartObject();
                       gen.writeStringField('type','BILLING');
                     gen.writeEndObject();
     	          gen.writeEndArray();
               gen.writeEndObject();

               gen.writeStartObject();
                 gen.writeStringField('AID',EZOnboardingRegistrationMock.testShipAid);
                 gen.writeFieldName('usages');
                   gen.writeStartArray();
                     gen.writeStartObject();
                       gen.writeStringField('type','SHIPPING');
                     gen.writeEndObject();
                   gen.writeEndArray();
                 gen.writeFieldName('errors');
                   gen.writeStartArray();
                     gen.writeStartObject();
                       gen.writeStringField('errorCode','POSTAL_ADDRESS_COULD_NOT_BE_VERIFIED');
                       gen.writeStringField('errorDescription','The postal address could not be verified');
     	            gen.writeEndObject();
     	          gen.writeEndArray();
     	   
     	      gen.writeEndObject();
             gen.writeEndArray();
         gen.writeEndObject();
     
       gen.writeFieldName('accounts');
         gen.writeStartArray();
           gen.writeStartObject();
             gen.writeStringField('clientValidationStatusCode','200');
             gen.writeStringField('caid',EZOnboardingRegistrationMock.testCaid);
             gen.writeFieldName('primarySourceSystem');
               gen.writeStartObject();
                 gen.writeStringField('id',acctId);
                 gen.writeStringField('name','SFDC');
	           gen.writeEndObject();
           gen.writeEndObject();
         gen.writeEndArray();
     
         gen.writeEndObject();
	   System.debug('getTestOicError='+gen.getAsString());
       return gen.getAsString();
    } // getTestOicError

        
    global String testOICResponse = '{'+
'"ceid" : "'+testCeid+'",'+
'"client" : {'+
'"postalAddresses" : [ {'+
'"id" : "'+testLegalAid+'",'+
'"streetAddress1" : "123 E Main St",'+
'"city" : "Rochester",'+
'"countrySubdivision" : "NY",'+
'"postalCode" : "14604",'+
'"iso2CountryCode" : "US",'+
'"usages" : [{"type" :"LEGAL"}],'+
'"audit" : "",'+
'"validated" : "false",'+
'"primary" : "false"'+
'} ],'+
'"names" : {'+
'"primary" : {'+
'"name" : "Dans Dandy Donuts",'+
'"active" : "false"'+
'}'+
'}'+
'},'+
'"clientAddresses" : [ {'+
'"id" : "8faef214-4e5a-47f1-9323-9e005be1d2c2",'+
'"addressLine1" : "125 E Main St",'+
'"city" : "Rochester",'+
'"countrySubdivision" : "NY",'+
'"postalCode" : "14604",'+
'"countryCodeISO" : "US",'+
'"usages" : [{"type" :"BILLING"}],'+
'"usPostalCodeComponents" : "US"'+
'}, {'+
'"id" : "59d62e15-7868-4ecc-94e5-91ab216fe120",'+
'"addressLine1" : "123 E Main St",'+
'"city" : "Rochester",'+
'"countrySubdivision" : "NY",'+
'"postalCode" : "14604",'+
'"countryCodeISO" : "US",'+
'"usages" : [{"type" :"SHIPPING"}],'+
'"usPostalCodeComponents" : "US"'+
'} ],'+
'"billingAccounts" : [ {'+
'"name" : "Dans Dandy Donuts",'+
'"audit" : {'+
'"effectivity" : {'+
'"active" : "true"'+
'}'+
'},'+
'"enterpriseCaid" : "'+testCaid+'",'+
'"accountNumber" : "'+testAcctNbr1+'",'+
'"sendInvoiceByEmail" : "false",'+
'"primarySourceSystem" : {"id" : "'+acctId1+'","name" : "SFDC"},'+
'"sourceSystemId" : "'+acctId1+'",'+
//'"accountAddresses" : [ {'+
'"id" : "'+testBillAid+'",'+
'"usages" : [{"type" :"BILLING"}],'+
'"caid" : "'+testCaid+'",'+
'"startDate" : "2022-11-11",'+
'"status" : "PENDING",'+
'"clientPostalAddressId" : "8faef214-4e5a-47f1-9323-9e005be1d2c2"'+
'}, {'+
'"id" : "'+testShipAid+'",'+
'"usages" : [{"type" :"SHIPPING"}],'+
'"caid" : "'+testCaid+'",'+
'"startDate" : "2022-11-11",'+
'"status" : "PENDING",'+
'"clientPostalAddressId" : "44367d10-7591-4918-bd47-793acd5fb5d0"'+
'} ]'+
'} ]'+
'}';
    
    global String testOICResponseMultiple = '{'+
'"ceid" : "'+testCeid+'",'+
'"client" : {'+
'"postalAddresses" : [ {'+
'"id" : "'+testLegalAid+'",'+
'"streetAddress1" : "123 E Main St",'+
'"city" : "Rochester",'+
'"countrySubdivision" : "NY",'+
'"postalCode" : "14604",'+
'"iso2CountryCode" : "US",'+
'"usages" : [{"type" :"LEGAL"}],'+
'"audit" : "",'+
'"validated" : "false",'+
'"primary" : "false"'+
'} ],'+
'"names" : {'+
'"primary" : {'+
'"name" : "Dans Dandy Donuts",'+
'"active" : "false"'+
'}'+
'}'+
'},'+
'"clientAddresses" : [ {'+
'"id" : "8faef214-4e5a-47f1-9323-9e005be1d2c2",'+
'"addressLine1" : "125 E Main St",'+
'"city" : "Rochester",'+
'"countrySubdivision" : "NY",'+
'"postalCode" : "14604",'+
'"countryCodeISO" : "US",'+
'"usages" : [{"type" :"BILLING"}],'+
'"usPostalCodeComponents" : "US"'+
'}, {'+
'"id" : "59d62e15-7868-4ecc-94e5-91ab216fe120",'+
'"addressLine1" : "123 E Main St",'+
'"city" : "Rochester",'+
'"countrySubdivision" : "NY",'+
'"postalCode" : "14604",'+
'"countryCodeISO" : "US",'+
'"usages" : [{"type" :"SHIPPING"}],'+
'"usPostalCodeComponents" : "US"'+
'}, {'+
'"id" : "59d62e15-7868-4ecc-94e5-91ab216fe122",'+
'"addressLine1" : "121 E Main St",'+
'"city" : "Rochester",'+
'"countrySubdivision" : "NY",'+
'"postalCode" : "14604",'+
'"countryCodeISO" : "US",'+
'"usages" : [{"type" :"BILLING"},{"type" : "SHIPPING"}],'+
'"usPostalCodeComponents" : "US"'+
'} ],'+
'"billingAccounts" : [ {'+
'"name" : "Dans Dandy Donuts",'+
'"audit" : {'+
'"effectivity" : {'+
'"active" : "true"'+
'}'+
'},'+
'"enterpriseCaid" : "'+testCaid+'",'+
'"accountNumber" : "'+testAcctNbr1+'",'+
'"sendInvoiceByEmail" : "false",'+
'"primarySourceSystem" : {"id" : "'+acctId1+'","name" : "SFDC"},'+
//'"sourceSystemId" : "'+acctId1+'",'+
'"accountAddresses" : [ {'+
'"id" : "'+testBillAid+'",'+
'"usages" : [{"type" :"BILLING"}],'+
'"caid" : "'+testCaid+'",'+
'"startDate" : "2022-11-11",'+
'"status" : "PENDING",'+
'"clientPostalAddressId" : "8faef214-4e5a-47f1-9323-9e005be1d2c2"'+
'}, {'+
'"id" : "'+testShipAid+'",'+
'"usages" : [{"type" :"SHIPPING"}],'+
'"caid" : "'+testCaid+'",'+
'"startDate" : "2022-11-11",'+
'"status" : "PENDING",'+
'"clientPostalAddressId" : "44367d10-7591-4918-bd47-793acd5fb5d0"'+
'} ]'+
'}, {'+
'"name" : "Dans Delightful Doodads",'+
'"audit" : {'+
'"effectivity" : {'+
'"active" : "true"'+
'}'+
'},'+
'"enterpriseCaid" : "'+testCaid2+'",'+
'"accountNumber" : "'+testAcctNbr2+'",'+
'"sendInvoiceByEmail" : "false",'+
//'"sourceSystemId" : "'+acctId2+'",'+
'"primarySourceSystem" : {"id" : "'+acctId2+'","name" : "SFDC"},'+
'"accountAddresses" : [ {'+
'"id" : "'+testBillAid2+'",'+
'"usages" : [{"type" :"BILLING"},{"type" : "SHIPPING"}],'+
'"caid" : "'+testCaid2+'",'+
'"startDate" : "2022-11-11",'+
'"status" : "PENDING",'+
'"clientPostalAddressId" : "59d62e15-7868-4ecc-94e5-91ab216fe123"'+
'} ]'+
'} ]'+
'}';
 /*
 public static String testOICErrResp=
'{"ceid" : "00H2A1IUL9YMFARWMV10",'+
'  "clientValidationStatusCode" : "400",'+
'  "caid" : "",'+
'  "detail" : {'+
'    "errors" : [ {'+
'      "errorCode" : "ENT-CLIENT-VIOLATION-39",'+
'      "errorDescription" : "Client with this legal name and address already exists",'+
'      "conflictResource" : {"links":[{"rel":"matchingClient","href":"https://ent-ose-client-svc-pyx.n2a-lb.paychex.com/clients?ceid=00H2A1IUL9YMFARWMV10"'+
'    } ]}'+
'   },'+
'          {"errorCode":"ENT-CLIENT-VIOLATION-1",'+
'           "errorDescription":"Invalid Error 1.",'+
'           "conflictResource":""'+
'	   }'+
'   ]'+
' }'+
'}';
  */ 
    public static String ossPartyId = 'ossPartyId';
    public static String ebsPartyId = 'ebsPartyId';
    public static String ossAcctId = 'ossAcctId';
    public static String ebsAcctId = 'ebsAcctId';
    public static String ossBill1 = 'ossBill1';
    public static String ossBill2 = 'ossBill2';
    public static String ossShip1 = 'ossShip1';
    public static String ossShip2 = 'ossShip2';
    public static String ebsBill1 = 'ebsBill1';
    public static String ebsBill2 = 'ebsBill2';
    public static String ebsShip1 = 'ebsShip1';
    public static String ebsShip2 = 'ebsShip2';
    
    public static String getOssKeyResp() {
       
       EntRespHelper.OssIdResponse resp = new EntRespHelper.OssIdResponse();
       resp.client = new EntRespHelper.ClientResp();
       resp.client.ceid = testCeid;
       resp.client.ebsPartyId = ebsPartyId;
       resp.client.ossPartyId = ossPartyId;
       EntRespHelper.BillAcctResp billAcct = new EntRespHelper.BillAcctResp();   
       billAcct.enterpriseCaid = testCaid;
       billAcct.ebsAccountId = ebsAcctId;
       billAcct.ossAccountId = ossAcctId;
       //billAcct.errors = new EntRespHelper.ErrorResp[]{};
       EntRespHelper.CltAddrResp addr1 = new EntRespHelper.CltAddrResp();
       addr1.enterpriseAddressId = testBillAid;
       addr1.ebsBillToSiteId = ebsBill1;
       addr1.ossBillToSiteId = ossBill1;
       addr1.ebsShipToSiteId = ebsShip1;
       addr1.ossShipToSiteId = ossShip1;
        
       EntRespHelper.CltAddrResp addr2 = new EntRespHelper.CltAddrResp();
       addr2.enterpriseAddressId = testShipAid;
       addr2.ebsBillToSiteId = ebsBill2;
       addr2.ossBillToSiteId = ossBill2;
       addr2.ebsShipToSiteId = ebsShip2;
       addr2.ossShipToSiteId = ossShip2;
       billAcct.clientAddresses = new EntRespHelper.CltAddrResp[]{addr1,addr2};
       resp.billingAccounts = new EntRespHelper.BillAcctResp[]{billAcct};
           
       String respStr = json.serialize(resp).replace('number_Z','number');
       return respStr;
    } // getOssKeyResp
    
    public static String getOssKeyRespPartial() {
       
       EntRespHelper.OssIdResponse resp = new EntRespHelper.OssIdResponse();
       resp.client = new EntRespHelper.ClientResp();
       resp.client.ceid = testCeid;
       resp.client.ebsPartyId = ebsPartyId;
       resp.client.ossPartyId = ossPartyId;
       EntRespHelper.BillAcctResp billAcct = new EntRespHelper.BillAcctResp();   
       billAcct.enterpriseCaid = testCaid;
       billAcct.ebsAccountId = ebsAcctId;
       billAcct.ossAccountId = ossAcctId;
       //billAcct.errors = new EntRespHelper.ErrorResp[]{};
       EntRespHelper.CltAddrResp addr1 = new EntRespHelper.CltAddrResp();
       addr1.enterpriseAddressId = testBillAid;
       //addr1.ebsBillToSiteId = ebsBill1;
       //addr1.ossBillToSiteId = ossBill1;
       addr1.ebsShipToSiteId = ebsShip1;
       addr1.ossShipToSiteId = ossShip1;
        
       EntRespHelper.CltAddrResp addr2 = new EntRespHelper.CltAddrResp();
       addr2.enterpriseAddressId = testShipAid;
       //addr2.ebsBillToSiteId = ebsBill2;
       //addr2.ossBillToSiteId = ossBill2;
       addr2.ebsShipToSiteId = ebsShip2;
       addr2.ossShipToSiteId = ossShip2;
       billAcct.clientAddresses = new EntRespHelper.CltAddrResp[]{addr1,addr2};
       resp.billingAccounts = new EntRespHelper.BillAcctResp[]{billAcct};
           
       String respStr = json.serialize(resp).replace('number_Z','number');
       return respStr;
    } // getOssKeyResp
    
    
    /*
{
"client" : {
"ceid" : "0097TVI8LGGM0EF4023G"
},
"billingAccounts" : [ {
"enterpriseCaid" : "008WQ28JLGGM0EZY13Y4",
"errors" : [ {
"errorCode" : "404",
"errorDescription" : "No matching records found"
} ]
} ]
}    
*/ 
    public static String getOssKeysNotFound() {
       EntRespHelper.OssIdResponse resp = new EntRespHelper.OssIdResponse();
       resp.client = new EntRespHelper.ClientResp();
       resp.client.ceid = testCeid;
       EntRespHelper.BillAcctResp billAcct = new EntRespHelper.BillAcctResp();   
       billAcct.enterpriseCaid = testCaid;
        
       EntRespHelper.ErrorResp errResp = new EntRespHelper.ErrorResp();
       errResp.errorCode = '404';
       errResp.errorDescription='No matching records found';
       billAcct.errors = new EntRespHelper.ErrorResp[]{errResp};
       resp.billingAccounts = new EntRespHelper.BillAcctResp[]{billAcct};

       String respStr = json.serialize(resp).replace('number_Z','number');
       return respStr;
   } // getOssKeysNotFound
    
    // they don't return anything in the body I believe
    public static String getCPQKeysResp() {
       //return '{"revisionId":"21,0","documents":{"bs_id":"87944403","subscriptionIntegrationResponse_t":"success","links":[{"rel":"self","href":"https://paychexinctest2.bigmachines.com/rest/v14/commerceDocumentsPaychexCommerceProcessTransaction/87944403"}';
       return '';
    } // getCPQKeysResp
    
   // if there's a 207 response from ECAG, https://wiki.paychex.com/pages/viewpage.action?pageId=1126631219
   public static String response207='{"successResponse":{"content":{"ceid":"0097TVI8LGXQDYV80LIN","client":{"ceid":"0097TVI8LGXQDYV80LIN","postalAddresses":[{"enterpriseClientAddressId":"3520000130790171","streetAddress1":"4390 Buffalo Rd","city":"North Chili","countrySubdivision":"NY","postalCode":"14514","poBoxIndicator":false,"iso2CountryCode":"US","usages":[{"type":"LEGAL","audit":{"effectivity":{"active":true}}}],"audit":{"effectivity":{"startDateTime":"2023-04-26T00:00:00","endDateTime":"4712-12-31T00:00:00","active":true}},"validated":false,"primary":false}],"names":{"primary":{"name":"Violets Violins 3141122","active":true}},"sampleClient":false},"billingAccounts":[{"correlationId":"0018I00000QM4jkQAD","name":"Violets Violins 3141122","audit":{"effectivity":{"startDateTime":"2023-04-26T00:00:00","endDateTime":"4712-12-31T00:00:00","active":true}},"enterpriseCaid":"0097TVI8LGXQDYV80LIO","accountNumber":"70246776","sendInvoiceByEmail":false}]},"type":"com.paychex.corp.clientmanagementservice.domain.ClientAggregate"},"errors":[{"detail":"bad.integration.request","error":{"content":{"instance":"a3e0d89e-c9bc-4311-958b-73821ca8484d","errors":[{"fieldError":{"objectName":"com.paychex.enterprise.common.resource.rest.v1.ErrorResource","field":"clientPostalAddress","defaultMessage":"The postal address could not be verified."},"correlationId":"e0666929-e25b-4a1a-b131-036b51c16194","type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/subtypes/FieldErrorProblemDetails.java"}],"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/IntegrationBadRequestProblemDetails.java","title":"Bad Integration Request","key":"bad.integration.request","retryable":false,"status":400},"type":"com.paychex.corp.springbootstarter.errorhandling.problem.IntegrationBadRequestProblemDetails"},"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/subtypes/PartialFailureErrorProblemDetails.java"}],"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/PartialFailureProblemDetails.java","instance":"a3e0d89e-c9bc-4311-958b-73821ca8484d","key":"PARTIAL.FAILURE.OCCURRED","retryable":false,"status":207}';    
    
   public static String legalUpdateCEID='00HWYNTDLRRWABOW9IHI';
   public static String legalUpdateCAID='00HWYNTDLRRWABOW9IHJ';
   public static String legalName='Wendys Wonderful Wigs 3152534';
   public static String legalStreet='4390 Buffalo Rd';
   public static String legalCity='North Chili';
   public static String legalState='NY';
   public static String legalPostal='14514';
   public static String legalCountry='US';
   public static String legalUpdateResp='[{"ceid":"00HWYNTDLRRWABOW9IHI","client":{"ceid":"00HWYNTDLRRWABOW9IHI","taxpayerIdentification":{"id":"413152534","type":"FEIN"},"postalAddresses":[{"enterpriseClientAddressId":"3520000137369497","type":"POSTAL","streetAddress1":"4390 Buffalo Rd","city":"North Chili","countrySubdivision":"NY","postalCode":"14514","poBoxIndicator":false,"iso2CountryCode":"US","usages":[{"type":"LEGAL"}],"audit":{"effectivity":{"active":true}}}],"names":{"primary":{"name":"Wendys Wonderful Wigs 3152534","active":false}},"sampleClient":false},"billingAccounts":[{"name":"Wendys Wigs n2a 3152534","audit":{"effectivity":{"startDateTime":"2024-01-24T00:00:00","endDateTime":"4712-12-31T00:00:00","active":true}},"enterpriseCaid":"00HWYNTDLRRWABOW9IHJ","accountNumber":"70383568","sendInvoiceByEmail":false}]}]';
    
   public static String legalAddrId='3520000137574548';
   public static String sfAddrId='a12b02c9-d5ef-46a6-8848-ef04cbbabd7b';
   public static String entAddrId='62540f68-5ee4-4255-acb2-7e5e22687833';
   public static String entCltNbr='70388688';
   // the id in the response, so we can replace with the one in the test.
   public static String duplAddrSfId='001DC00000hEAo6YAG';
   // if a client is registered, and the legal address is registered as a non-legal address within the same call, so when the non-legal addresses register they get a duplicate address response. 
   // 
   public static String duplicateAddrOnRegister = '{"successResponse":{"content":{"ceid":"00HWYNTDLRRWABOW9IHI","client":{"ceid":"00HWYNTDLRRWABOW9IHI","postalAddresses":[{"enterpriseClientAddressId":"3520000137574548","streetAddress1":"4390 Buffalo Rd","city":"North Chili","countrySubdivision":"NY","postalCode":"14514","poBoxIndicator":false,"iso2CountryCode":"US","usages":[{"type":"LEGAL","audit":{"effectivity":{"active":true}}}],"audit":{"effectivity":{"active":true}},"validated":false,"primary":false}],"names":{"primary":{"name":"Kens Kites n2a 3152543","active":true}},"sampleClient":false},"billingAccounts":[{"correlationId":"001DC00000hEAo6YAG","name":"Kens Kites n2a 3152543","audit":{"effectivity":{"startDateTime":"2024-02-10T00:00:00","endDateTime":"4712-12-31T00:00:00","active":true}},"enterpriseCaid":"00HWYNTDLRRWABOW9IHJ","accountNumber":"70388688","sendInvoiceByEmail":false}]},"type":"com.paychex.corp.clientmanagementservice.domain.ClientAggregate"},"errors":[{"detail":"conflicting.integration.request","error":{"content":{"instance":"6e90a758-16dd-4000-9c5c-d31fd1e62529","conflictResources":[{"detail":"The Address already exists.","key":"DUPLICATE_ADDR","conflictResource":{"id":"a12b02c9-d5ef-46a6-8848-ef04cbbabd7b","content":{"id":"62540f68-5ee4-4255-acb2-7e5e22687833","caid":"00HWYNTDLRRWABOW9IHJ","snapshotVersionNumber":1,"startDate":"2024-02-10","status":"ACTIVE","clientPostalAddress":{"id":"8569130d-2e34-486d-a753-6e9d539681b9","ceid":"00HWYNTDLRRWABOW9IHI","streetLine1":"4390 Buffalo Rd","city":"North Chili","county":"Monroe","countrySubdivision":"NY","postalCode":"14514102599","iso2CountryCode":"US","poBoxIndicator":false,"snapshotVersionNumber":1,"currentLegalAddressIndicator":true}},"type":"com.paychex.corp.enterpriseclientaccountgateway.integration.webservice.client.resource.enterpriseaddress.NormalizedOutboundClientAccountAddressResource"},"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/subtypes/ConflictResourceProblemDetails.java"}],"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/IntegrationConflictProblem.java","title":"Conflicting Integration Request","key":"conflicting.integration.request","retryable":false,"status":409},"type":"com.paychex.corp.springbootstarter.errorhandling.problem.IntegrationConflictProblemDetails"},"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/subtypes/PartialFailureErrorProblemDetails.java"}],"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/PartialFailureProblemDetails.java","instance":"6e90a758-16dd-4000-9c5c-d31fd1e62529","key":"PARTIAL.FAILURE.OCCURRED","retryable":false,"status":207}';
    
   public static String addrNot_Name='Relianse MT North LLC';
   public static String addrNot_legalStreet='5353 Midland Road';
   public static String addrNot_legalCity='Billings';
   public static String addrNot_legalPostal='59101';
   // the address id sent in by SF - correlationId
   public static String addrNot_shipAddrId='5fa9025c-4082-42b2-9c5c-069d08fca5a9';
   public static String addrNot_shipStreet='PO BOX 3104';
   public static String addrNot_shipCity='McKinney';
   public static String addrNot_shipPostal='75070-8184';
   // 207 response
   public static String addrNotVerified = '{"successResponse":{"content":{"ceid":"00HWYNTDLRRWABOW9IHI","client":{"ceid":"00HWYNTDLRRWABOW9IHI","postalAddresses":[{"enterpriseClientAddressId":"3520000137574548","streetAddress1":"5353 Midland Road","city":"Billings","countrySubdivision":"MT","postalCode":"59101","poBoxIndicator":false,"iso2CountryCode":"US","usages":[{"type":"LEGAL","audit":{"effectivity":{"active":true}}}],"audit":{"effectivity":{"active":true}},"validated":false,"primary":false}],"names":{"primary":{"name":"Relianse MT North LLC","active":true}},"sampleClient":false},"billingAccounts":[{"correlationId":"001DC00000hEAo6YAG","name":"Relianse MT North LLC","audit":{"effectivity":{"startDateTime":"2024-03-07T00:00:00","endDateTime":"4712-12-31T00:00:00","active":true}},"enterpriseCaid":"00HWYNTDLRRWABOW9IHJ","accountNumber":"70119830","sendInvoiceByEmail":false}]},"type":"com.paychex.corp.clientmanagementservice.domain.ClientAggregate"},"errors":[{"detail":"bad.integration.request","error":{"content":{"instance":"8965b258-3710-44eb-9c01-d24c83312faa","errors":[{"key":"POSTAL_ADDRESS_COULD_NOT_BE_VERIFIED","fieldError":{"objectName":"com.paychex.enterprise.common.resource.rest.v1.ErrorResource","field":"clientPostalAddress","defaultMessage":"The postal address could not be verified."},"correlationId":"5fa9025c-4082-42b2-9c5c-069d08fca5a9","type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/subtypes/FieldErrorProblemDetails.java","additionalContent":{"candidateAddresses":[{"content":{"correlationId":"0","streetAddress1":"PO BOX 3104","poBoxIndicator":true,"city":"McKinney","county":"Collin","countrySubdivision":"TX","postalCode":"75070818404","usPostalCodeComponents":{"zip":"75070","plus4":"8184","zipPlus4":"750708184","deliveryPointNumber":"04"},"iso2CountryCode":"US","components":{"primaryNumber":"3104","streetName":"PO Box","cityName":"McKinney","defaultCityName":"McKinney","stateAbbreviation":"TX","zipCode":"75070","plus4Code":"8184","deliveryPoint":"04","deliveryPointCheckDigit":"6"},"metadata":{"recordType":"P","countyFips":"48085","countyName":"Collin","carrierRoute":"B028","latitude":33.15574,"longitude":-96.69902,"coordinatePrecision":"Zip6"},"analysis":{"dpvMatchCode":"Y","dpvFootnotes":"AABB","dpvCmra":"N","dpvVacant":"N","dpvNoStat":"N","matchDetails":{"correctedZipCode":true,"correctedCityStateSpelling":false,"invalidCityStateZip":false,"noZipPlus4Assigned":false,"sameZipForMultiple":false,"missingSecondaryNumber":false,"insufficientAddressData":false,"cardinalRuleMatch":false,"changedAddressComponent":false,"correctedStreetSpelling":false,"fixedAbbreviations":false,"multipleZipPlus4LowestUsed":false,"betterAddressExists":false,"unrecognizedSecondaryAddress":false,"unofficialCityName":false,"unverifiableCityState":false,"matchedWithZIPMOVE":false}},"normAddrRpcInd":"N"},"type":"com.paychex.client.resource.rest.v1.addressstandard.VerifyAddressResource"}]}}],"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/IntegrationBadRequestProblemDetails.java","title":"Bad Integration Request","key":"bad.integration.request","retryable":false,"status":400},"type":"com.paychex.corp.springbootstarter.errorhandling.problem.IntegrationBadRequestProblemDetails"},"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/subtypes/PartialFailureErrorProblemDetails.java"}],"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/PartialFailureProblemDetails.java","instance":"8965b258-3710-44eb-9c01-d24c83312faa","key":"PARTIAL.FAILURE.OCCURRED","retryable":false,"status":207}';
    
   // status 400 - account address id already exists
   /* the request for the 400 response. 
     If we get the key back ACCOUNT_ADDRESS_ID_EXISTS
    then we can assume the correlationId is correct and populate the enterprise uuid field
    {
"client" : {
"ceid" : "001GJICFLTYOZMIE75Y5",
"taxPayerIdentification" : {
"id" : "863122148",
"type" : "FEIN"
},
"postalAddresses" : [ {
"streetAddress1" : "1176 Farmington Ave",
"poBoxIndicator" : false,
"city" : "Berlin",
"countrySubdivision" : "CT",
"postalCode" : "06037",
"iso2CountryCode" : "US",
"usages" : [ {
"type" : "LEGAL"
} ]
} ],
"names" : {
"primary" : {
"name" : "Entrepreneur Connect Inc",
"active" : false
}
}
},
"accounts" : [ {
"name" : "Entrepreneur Connect Inc",
"enterpriseCaid" : "001GJICFLTYOZMKS75Y6",
"primarySourceSystem" : {
"id" : "0014u000027kMiHAAU",
"name" : "SFDC",
"effectivity" : {
"active" : true
}
},
"postalAddresses" : [ {
"enterpriseAccountAddressId" : "6247b000-ee6a-407e-9513-2f112803cc7b",
"streetAddress1" : "1176 Farmington Ave",
"city" : "Berlin",
"countrySubdivision" : "CT",
"postalCode" : "060372302",
"iso2CountryCode" : "US",
"usages" : [ {
"type" : "SHIPPING"
}, {
"type" : "BILLING"
} ]
} ]
} ]
}
   */
   public static String addrIdExists400 = '{"instance":"0122a5ef-2160-4525-ab6b-7ecab5543c5c","errors":[{"key":"ACCOUNT_ADDRESS_ID_EXISTS","fieldError":{"objectName":"com.paychex.enterprise.common.resource.rest.v1.ErrorResource","field":"id","defaultMessage":"The given client account address id already exists."},"correlationId":"6247b000-ee6a-407e-9513-2f112803cc7b","type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/subtypes/FieldErrorProblemDetails.java"}],"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/IntegrationBadRequestProblemDetails.java","title":"Bad Integration Request","key":"bad.integration.request","retryable":false,"status":400}';

/* request to get 409 error back
 {
"client" : {
"ceid" : "00Z1IQF9HV6OS797ZGXZ",
"taxPayerIdentification" : {
"id" : "453211329",
"type" : "FEIN"
},
"postalAddresses" : [ {
"streetAddress1" : "1502 Lincoln Way",
"poBoxIndicator" : false,
"city" : "Mckeesport",
"countrySubdivision" : "PA",
"postalCode" : "151311712",
"iso2CountryCode" : "US",
"usages" : [ {
"type" : "LEGAL"
} ]
} ],
"names" : {
"primary" : {
"name" : "Pattis Pasticceria Inc",
"active" : false
}
}
},
"accounts" : [ {
"name" : "Pattis Pasticceria Inc",
"enterpriseCaid" : "001GJICFLTSSXH33EP5Q",
"primarySourceSystem" : {
"id" : "0017000000prfR5AAI",
"name" : "SFDC",
"effectivity" : {
"active" : true
}
},
"postalAddresses" : [ {
"enterpriseAccountAddressId" : "8d01031d-46d5-4dfd-83c3-ac6994e2407d",
"streetAddress1" : "1502 Lincoln Way",
"city" : "Mckeesport",
"countrySubdivision" : "PA",
"postalCode" : "151311712",
"iso2CountryCode" : "US",
"usages" : [ {
"type" : "BILLING"
} ]
}, {
"enterpriseAccountAddressId" : "8d01031d-46d5-4dfd-83c3-ac6994e2407d",
"streetAddress1" : "1502 Lincoln Way",
"city" : "Mckeesport",
"countrySubdivision" : "PA",
"postalCode" : "151311721",
"iso2CountryCode" : "US",
"usages" : [ {
"type" : "SHIPPING"
} ]
} ]
}, {
"name" : "Pattis Pasticceria Inc",
"enterpriseCaid" : "001GJICFLTSSXH21E5BC",
"primarySourceSystem" : {
"id" : "0014u000029mRdQAAU",
"name" : "SFDC",
"effectivity" : {
"active" : true
}
},
"postalAddresses" : [ {
"enterpriseAccountAddressId" : "80e0b928-674f-4203-bbd9-1c88ba01c12d",
"streetAddress1" : "1502 Lincoln Way",
"city" : "Mckeesport",
"countrySubdivision" : "PA",
"postalCode" : "151311712",
"iso2CountryCode" : "US",
"usages" : [ {
"type" : "BILLING"
} ]
}, {
"enterpriseAccountAddressId" : "80e0b928-674f-4203-bbd9-1c88ba01c12d",
"streetAddress1" : "2812 State St",
"city" : "Mckeesport",
"countrySubdivision" : "PA",
"postalCode" : "151311331",
"iso2CountryCode" : "US",
"usages" : [ {
"type" : "SHIPPING"
} ]
} ]
} ]
}

*/
    
   public static String addrAlreadyExists409 = '{"instance":"083efbc6-a039-49b9-9797-a43f6d4b0904","conflictResources":[{"detail":"The Address already exists.","key":"DUPLICATE_ADDR","conflictResource":{"id":"8d01031d-46d5-4dfd-83c3-ac6994e2407d","content":{"id":"dfd2ee1f-686a-4e6f-8461-032d68856656","caid":"001GJICFLTSSXH33EP5Q","name":"Pattis Pasticceria, Inc.","snapshotVersionNumber":2,"startDate":"2024-03-15","status":"ACTIVE","clientPostalAddress":{"id":"fb03816d-d4cc-f0b0-e053-1800410aa690","ceid":"00Z1IQF9HV6OS797ZGXZ","streetLine1":"1502 Lincoln Way","city":"White Oak","countrySubdivision":"PA","postalCode":"15131171202","iso2CountryCode":"US","poBoxIndicator":false,"snapshotVersionNumber":2,"currentLegalAddressIndicator":true}},"type":"com.paychex.corp.enterpriseclientaccountgateway.integration.webservice.client.resource.enterpriseaddress.NormalizedOutboundClientAccountAddressResource"},"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/subtypes/ConflictResourceProblemDetails.java"},{"detail":"The Address already exists.","key":"DUPLICATE_ADDR","conflictResource":{"id":"80e0b928-674f-4203-bbd9-1c88ba01c12d","content":{"id":"db758253-6460-4b17-8293-9010278e164a","caid":"001GJICFLTSSXH21E5BC","snapshotVersionNumber":1,"startDate":"2024-03-15","status":"ACTIVE","clientPostalAddress":{"id":"fb03816d-d4cc-f0b0-e053-1800410aa690","ceid":"00Z1IQF9HV6OS797ZGXZ","streetLine1":"1502 Lincoln Way","city":"White Oak","countrySubdivision":"PA","postalCode":"15131171202","iso2CountryCode":"US","poBoxIndicator":false,"snapshotVersionNumber":2,"currentLegalAddressIndicator":true}},"type":"com.paychex.corp.enterpriseclientaccountgateway.integration.webservice.client.resource.enterpriseaddress.NormalizedOutboundClientAccountAddressResource"},"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/subtypes/ConflictResourceProblemDetails.java"}],"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/IntegrationConflictProblem.java","title":"Conflicting Integration Request","key":"conflicting.integration.request","retryable":false,"status":409}';
} // class EZOnboardingRegistrationMock