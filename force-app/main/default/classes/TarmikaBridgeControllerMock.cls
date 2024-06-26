/* 
   Mock Tarmika Call for both the Tarmika Token and Tarmika Posts
   Tests these two classes
	- TarmikaBridgeController
	- TarmikaBridgeToken

   
  History
  -------
  12/13/2022 Carrie Marciano    Created

*/

@isTest
global class TarmikaBridgeControllerMock implements HttpCalloutMock {
    
    public static String returnToken = 'd1320367-c3e4-497c-860f-29b367e29f85';
    public static String tokenResponse = '{"access_token":"'+returnToken+'","token_type":"Bearer","expires_in":28800}';
    
    global String responseToUse = tokenResponse;
    
	global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody(responseToUse);
        res.setStatusCode(200);
        return res;
    }
    
    public static String successResponse = '{'+
        '"status": {'+
        '    "statusCode": "Success",'+ 
        '    "statusDescription": "Request processed successfully"'+
        '},'+
        '"messages": ['+
        '    {'+
        '        "messageDescription": "Insured Business data saved"'+
        '    }'+
        '],'+
        '"errors": [],'+
        '"quoteResponseHeader": {'+
        '    "quoteResponseIdentifier": "0b981714-ace0-4c52-be1c-dc00b08327b2",'+
        '    "externalQuoteRequestIdentifier": "0000009574",'+
        '    "quoteResponseDate": 1670333939000,'+
        '    "internalQuoteRequestIdentifier": "0000063054",'+
        '    "agency": {'+
        '        "agencyNumber": null,'+
        '        "producerCode": null,'+
        '        "userName": "akosel@paychex.com",'+
        '        "password": null'+
        '    },'+
        '    "quoteProcessingStatus": {'+
        '        "statusCode": "Saved as Draft Quote Request",'+
        '        "statusDescription": null'+
        '    }'+
        '},'+
        '"quoteResponseDetail": {'+
        '    "lineOfBusinessQuote": ['+
        '        {'+
        '            "lineOfBusiness": "WC",'+
        '            "internalQuoteRequestIdentifier": "0000056175",'+
        '            "quoteLinkURL": "https://demo.tarmika.com/agentportal/?quotelink=2Uzam0sF1jsdwZakugmCOYL8MNXiBVJci2IgUaF40aqLSzY3JqKAMCe5yhzh5GLAU%2FLLe%2FS7o57n%0ADqxKS0dBm8Z%2F2sQSMBM5Kyrkh5HZK8sppIiO3UPqA3SVJPiV9IaArJ4NcNxoti45mVN0KXwzbg%3D%3D"'+
        '        }'+
        '    ],'+
        '    "insurerQuoteResponse": {'+
        '        "insurerName": null,'+
        '        "insurerQuoteNumber": null,'+
        '        "insurerQuoteStatus": null,'+
        '        "totalPremium": null,'+
        '        "insurerQuoteLinkURL": null,'+
        '        "insurerQuoteStatusRemarks": null,'+
        '        "proposalDocument": null,'+
        '        "lineOfBusiness": null,'+
        '        "quoteProcessingIdentifier": null,'+
        '        "quoteResponseStatus": null'+
        '    }'+
        '}'+
    	'}';
        
    public static String failureResponse = '{'+
        '"status": {'+
        '    "statusCode": "Failure",'+ 
        '    "statusDescription": "Error in processing the request"'+
        '},'+
        '"messages": [],'+
        '"errors": ['+
        '{'+
        '	"errorCode": "100",'+
        '	"errorDescription": "The agent id passed in the field agency.userName  not exist on TARMIKA"'+
        '}'+
        '],'+
        '"quoteResponseHeader": {'+
        '    "quoteResponseIdentifier": null,'+
        '    "externalQuoteRequestIdentifier": "0000009574",'+
        '    "quoteResponseDate": 1670333939000,'+
        '    "internalQuoteRequestIdentifier": null,'+
        '    "agency": {'+
        '        "agencyNumber": null,'+
        '        "producerCode": null,'+
        '        "userName": null,'+
        '        "password": null'+
        '    },'+
        '    "quoteProcessingStatus": {'+
        '        "statusCode": "Aborted",'+
        '        "statusDescription": null'+
        '    }'+
        '},'+
        '"quoteResponseDetail": {'+
        '    "lineOfBusinessQuote": [],'+
        '    "insurerQuoteResponse": {'+
        '        "insurerName": null,'+
        '        "insurerQuoteNumber": null,'+
        '        "insurerQuoteStatus": null,'+
        '        "totalPremium": null,'+
        '        "insurerQuoteLinkURL": null,'+
        '        "insurerQuoteStatusRemarks": null,'+
        '        "proposalDocument": null,'+
        '        "lineOfBusiness": null,'+
        '        "quoteProcessingIdentifier": null,'+
        '        "quoteResponseStatus": null'+
        '    }'+
        '}'+
    	'}';
    
/*Response from Tarmika  
  
  
  Token Response
  	  {"access_token":"d1320367-c3e4-497c-860f-29b367e29f85","token_type":"Bearer","expires_in":28800}
  
 
  POST Response
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