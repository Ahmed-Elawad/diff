/* 
*Test methods for the HRISOrderSearchController.
*
* History
* ------------------------------------------------------------------------------
* 10/14/2019	Matt Fritschi		Created.
* 12/03/2019	Jake Hinds			Adding web service custom setting
*/

@isTest
public class HRISOrderSearchControllerTest {
    
    //Tests successfully getting a list of orders.
    static testmethod void testResponseWithAllOrderTypes(){
        insert new WebServiceSettings__c(Name='OrderSearch',IsActive__c=true,Certificate__c=
                                         Label.Test_Class_Certificate_Name,
                                         Endpoint__c='https://webservices.paychex.com/rest/hrs/sfdc/salesforce-rem/OrderSearch/',
                                         Timeout__c='60000');
        Account acct = new Account(Name='Test Account', BIS_ID__c=1234);
        insert acct; 
        
        ApexPages.StandardController sc = new ApexPages.StandardController(acct);
        
        
        HRISOrderSearchController orderSearch = new HRISOrderSearchController(sc);
        
        System.assertEquals('1234', orderSearch.BISClientId);
        System.assertEquals(1, orderSearch.returnedEquipList.size());
        System.assertEquals(false, orderSearch.activeTAA);
        System.assertEquals(1, orderSearch.ordersList.size());
        System.assertEquals(2, orderSearch.ordersList[0].equipList.size());
        System.assertEquals(2, orderSearch.ordersList[0].trackingInfo.size());
        System.assertEquals(2, orderSearch.AMAPIAList.size());
        System.assertEquals(false, orderSearch.error);
    }
    
	//Fake response from Http Request    
    public static HttpResponse WebserviceExpectedResponse() 
    { 
        HttpResponse httpResponse = new HttpResponse();
        httpResponse.setStatusCode(200);
        httpResponse.setBody('{"CompanyName":"BCT\\/G FOUR GRAPHICS","CostCenter":"1050","IsTimeAndAttendanceActive":0,"OrderBalance":100,"PayrollClientNumber":"1243","SalesforceOrders":[{"AmaOrderBalance":null,"ChargeEndDate":null,"ChargeStartDate":null,"ItemDescription":"TIB DIRECT BILL SOFTWARE ANNUAL MAINT FEE","ItemId":"156889","OrderDate":"2019-03-14T00:00:00Z","OrderId":10637279,"OrderType":"AMA","Quantity":1,"ReturnDate":null,"SerialNumber":"","ShippingCode":"UPS","TrackingNumber":"1Z1176260303267494"},{"AmaOrderBalance": null,"ChargeEndDate": null, "ChargeStartDate": null, "ItemDescription": "HRS GROUND SHIPPING","ItemId":"HRSGRND","OrderDate":"2010-09-17T00:00:00Z","OrderId":10637279,"OrderType":"CUR","Quantity":1,"ReturnDate":null, "SerialNumber":"","ShippingCode":"UPS","TrackingNumber":"1Z1176260303267494"},{"AmaOrderBalance": null,"ChargeEndDate": null, "ChargeStartDate": null, "ItemDescription": "HRS GROUND SHIPPING","ItemId":"HRSGRND","OrderDate":"2010-09-17T00:00:00Z","OrderId":10637279,"OrderType":"CUR","Quantity":1,"ReturnDate":null, "SerialNumber":"","ShippingCode":"UPS","TrackingNumber":"Z1176260303267494"},{"AmaOrderBalance": null,"ChargeEndDate": null, "ChargeStartDate": null, "ItemDescription": "HRS GROUND SHIPPING","ItemId":"HRSGRND","OrderDate":"2010-09-17T00:00:00Z","OrderId":10637279,"OrderType":"CUR","Quantity":1,"ReturnDate":null, "SerialNumber":"","ShippingCode":"UPS","TrackingNumber":"1Z1176260303267494"},{"AmaOrderBalance": null,"ChargeEndDate": null, "ChargeStartDate": null, "ItemDescription": "HRS GROUND SHIPPING","ItemId":"HRSGRND","OrderDate":"2010-09-17T00:00:00Z","OrderId":10637279,"OrderType":"RET","Quantity":1,"ReturnDate":null, "SerialNumber":"","ShippingCode":"UPS","TrackingNumber":"1Z1176260303267494"},{"AmaOrderBalance":0,"ChargeEndDate":"2020-04-30T00:00:00Z","ChargeStartDate":"2019-05-01T00:00:00Z","ItemDescription":"TIB DIRECT BILL HARDWARE ANNUAL MAINT FEE","ItemId":"156890","OrderDate":"2019-03-14T00:00:00Z","OrderId":10637279,"OrderType":"AMA","Quantity":1,"ReturnDate":null,"SerialNumber":"","ShippingCode":"","TrackingNumber":""}]}'); 
        return httpResponse;
    }
    
}