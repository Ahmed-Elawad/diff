/*
*   10/07/2019  Matt Fritschi       Created. 
*   12/03/2019  Jake Hinds          Adding web service custom setting, limit to returned orders
*   07/06/2020  Jacob Hinds         Added without sharing per PMD 
* 
* 
* 
*/

public without sharing class HRISOrderSearchController {
    
    public boolean ordersFound {get;set;}
    public boolean returnedFound {get;set;}
    public boolean AMAPIAFound {get;set;}
    public boolean activeTAA {get;set;}
    public boolean error{get; set;}
    public String BISClientId {get; set;}
    public String companyName {get; set;}
    public String branchClient {get; set;}
    public String orderBalance {get; set;}
    public account acc;
    
    public Map<String, Order> ordersMap {get; set;}
    public List<Order> ordersList {get; set;}
    public List<ReturnedEquipment> returnedEquipList {get; set;}
    public List<AMAPIA> AMAPIAList {get; set;}
    public WebServiceSettings__c cs;
    //Constructor
    public HRISOrderSearchController(ApexPages.StandardController stdController) {
        System.debug('Getting Order info now');
        ordersFound = false;
        returnedFound = false;
        AMAPIAFound = false;
        error = false;
        ordersList = new List<Order>();
        ordersMap = new Map<String, Order>();
        returnedEquipList = new List<ReturnedEquipment>();
        AMAPIAList = new List<AMAPIA>();
        
        companyName = '';
        branchClient = '';
        orderBalance = '';
        
        //This will need to be dynamically assigned
        acc = (Account)stdController.getRecord();
        List<Account> chosenAccount = [select id, name, Bis_Id__c from Account where Id=:acc.Id];
        BISClientId = '';
        
        if(chosenAccount.size() == 1)
        {
            BISClientId = String.valueOf(chosenAccount[0].Bis_Id__c);
        }
        
        //BISClientId='691356';
        cs = WebServiceSettings__c.getInstance('OrderSearch');
        if(cs!=null && cs.isActive__c){
            requestOrders();
        }
        
        
        for(Order o : ordersMap.values())
        {
            ordersList.add(o);
        }
        
        System.debug('The orders are: '+ ordersList);
        
        if(ordersList.size() > 0)
        {
            ordersFound = true;
        }
        if(returnedEquipList.size() > 0)
        {
            returnedFound = true;
        }
        if(AMAPIAList.size() > 0)
        {
            System.debug('An AMAPIA Was found');
            AMAPIAFound = true;
        }
        if(ordersFound == false && returnedFound == false && AMAPIAFound == false)
        {
            error = true;
        }
    }//HRISOrderSearchController()
    
    
    //Submits an HTTP Request to get Orders linked to this Client.
    public void requestOrders()
    {
        if(String.isNotBlank(BISClientId))
        {
            Http http = new Http();
            httpRequest request = new HttpRequest();
            
            //Need to set the endpoint of this request.
            String endpoint = cs.Endpoint__c;
            endpoint += BISClientId;
            
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            
            //Set the Headers
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            request.setHeader('X-PAYX-USER-ID', 'HRS_SFREM_ASV');
            
            request.setTimeout(Integer.valueOf(cs.Timeout__c));
            
            try
            {
                HttpResponse response = new HttpResponse();
                if(!Test.isRunningTest())
                {
                    request.setClientCertificateName(cs.Certificate__c);
                    response = http.send(request);
                }
                else
                {
                    response = HRISOrderSearchControllerTest.WebserviceExpectedResponse();
                }
                System.debug('requestOrders.body='+response.getBody());
                System.debug('requestOrders.statusCode='+response.getStatusCode());
                //Make sure the call was successful
                if(response.getStatusCode()==200)
                {
                    parseData((String) response.getBody());
                } //if(response.getStatusCode()==200)
                else
                {
                    String responseBody = (String) response.getBody();
                    if(responseBody.contains('The result set will be too large'))
                    {
                        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'The result set will be too large. You must narrow your search.'));
                    }
                }
            }
            catch(System.CalloutException e)
            {
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Request took too long, please try again.'));
            }
        }
        else
        {
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'There is no BIS Client Id for this Prospect-Client.'));
        }
        
    }//requestOrders()
    
    //Parses the body returned from the HTTP request
    public void parseData(String body)
    {
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(body);
        companyName = (String) results.get('CompanyName');
        
        //Change the header based on if this is an Active or Inactive TAA
        activeTAA = (results.get('IsTimeAndAttendanceActive') == 1 ? true : false);
        if(!activeTAA)
        {
            orderBalance = '$' + String.valueOf(results.get('OrderBalance'));
        }
        branchClient = (String) results.get('CostCenter') + '-' + (String)results.get('PayrollClientNumber');
        List<Object> returnedOrderList = (List<Object>) results.get('SalesforceOrders');
        
        For(Object orderRecord : returnedOrderList)
        {
            Map<String, Object> orderRecordMap = (Map<String, Object>) orderRecord;
            String orderNum = String.valueOf(orderRecordMap.get('OrderId'));
            String state = (String)orderRecordMap.get('OrderType');
            System.debug('The State is: '+ state);
            //If no Order with that ID exists, create a new Order and add the item to it.
            if(!ordersMap.containsKey(orderNum) && (state == 'CUR' || state == 'AMA'))
            {
                Order newOrder = new Order();
                newOrder.orderDate = formatDate((String)orderRecordMap.get('OrderDate'));
                newOrder.orderNumber = orderNum;
                String shipMethod = (String)orderRecordMap.get('ShippingCode');
                String trackingNumber = (String)orderRecordMap.get('TrackingNumber');
                //If there is tracking information, add it to the order.
                if(String.isNotBlank(shipMethod) || String.isNotBlank(trackingNumber))
                {
                    TrackRec track = new TrackRec();
                    track.shipMethod=shipMethod;
                    track.trackNum=trackingNumber;
                    newOrder.trackingInfo.add(track);
                }
                
                addEquipment(orderRecordMap, newOrder);
                ordersMap.put(newOrder.orderNumber, newOrder);
                
                if(state == 'AMA')
                {
                    System.debug('Adding an AMA Product Now');
                    addAMAProd(orderRecordMap); 
                }
            }
            //If existing Order exists, add the item to that order.
            else if(ordersMap.containsKey(orderNum) && (state == 'CUR' || state == 'AMA'))
            {
                Order existingOrder = ordersMap.get(orderNum);
                String trackingNumber = (String)orderRecordMap.get('TrackingNumber');
                boolean containsItem = false;
                //If this contains new Tracking infomation, add it to the Order.
                if(String.isNotBlank(trackingNumber))
                {
                    Boolean foundTrackMatch = false;
                    for(TrackRec tr : existingOrder.TrackingInfo)
                    {
                        if(tr.trackNum == trackingNumber)
                        {
                            foundTrackMatch = true;
                            break;
                        }
                    }
                    
                    if(!foundTrackMatch)
                    {
                        TrackRec track = new TrackRec();
                        track.shipmethod=(String)orderRecordMap.get('ShippingCode');
                        track.trackNum = trackingNumber;
                        existingOrder.trackingInfo.add(track);
                    }
                }
                
                //Make sure the order doesn't already contain this Item Id. No duplicate items (Unless AMA).
                if(state != 'AMA')
                {
                    for(Equipment eq : existingOrder.equipList)
                    {
                        
                        if(eq.itemNumber == (String)orderRecordMap.get('ItemId'))
                        {
                            containsItem = true;
                            break;
                        }
                    }
                    
                    if(!containsItem)
                    {
                        addEquipment(orderRecordMap, existingOrder);
                    }
                }
                else
                {
                    System.debug('Adding an AMA Product Now');
                    addAMAProd(orderRecordMap); 
                }
                
                
            } //else if(ordersMap.containsKey(orderNum) && (state == 'CUR' || state == 'AMA'))
            //If the item has been returned, create a ReturnedItem record.
            else if(state == 'RET' && returnedEquipList.size()<1000)
            {
                ReturnedEquipment retEq = new ReturnedEquipment();
                retEq.orderDate = formatDate((String)orderRecordMap.get('OrderDate'));
                retEq.orderNumber = orderNum;
                retEq.serialNumber = (String)orderRecordMap.get('SerialNumber');
                retEq.rmaQuantity = String.valueOf(orderRecordMap.get('Quantity'));
                retEq.itemNumber = (String)orderRecordMap.get('ItemId');
                retEq.itemDescription = (String)orderRecordMap.get('ItemDescription');
                retEq.returnDate = formatDate((String)orderRecordMap.get('ReturnDate'));
                
                returnedEquipList.add(retEq);
            } //else if(state == 'RET')
        } //For(Object orderRecord : returnedOrderList)
    } //parseData(String body)
    
    
    public void addEquipment(Map<String, Object> addEquipMap, Order existingOrder)
    {
        Equipment newEq = new Equipment();
        newEq.serialNumber = (String)addEquipMap.get('SerialNumber');
        newEq.orderQuantity = String.valueOf(addEquipMap.get('Quantity'));
        newEq.itemNumber = (String)addEquipMap.get('ItemId');
        newEq.itemDescription = (String)addEquipMap.get('ItemDescription');
        
        existingOrder.equipList.add(newEq);
    }
    
    
    //Formats the dates correctly
    public String formatDate(String dateText)
    {
        String formattedDate = '';
        if(String.isNotBlank(dateText))
        {
            formattedDate += dateText.substring(5, 7) + '/' + dateText.substring(8, 10) + '/' + dateText.substring(0, 4);
        }
        return formattedDate;
    }
    
    
    //Adds a product to AMA/PIA section
    public void addAMAProd(Map<String, Object> addAMAMap)
    {
        AMAPIA amapia = new AMAPIA();
        amapia.orderDate = formatDate((String)addAMAMap.get('OrderDate'));
        amapia.orderNumber = String.valueOf(addAMAMap.get('OrderId'));
        amapia.orderQuantity = String.valueOf(addAMAMap.get('Quantity'));
        amapia.itemNumber = (String)addAMAMap.get('ItemId');
        amapia.itemDescription = (String)addAMAMap.get('ItemDescription');
        amapia.startDate = formatDate((String)addAMAMap.get('ChargeStartDate'));
        amapia.endDate = formatDate((String)addAMAMap.get('ChargeEndDate'));
        amapia.orderBalance = String.valueOf(addAMAMap.get('AmaOrderBalance'));
        
        AMAPIAList.add(amapia);
    }
    
    
    //Container Class for Orders
    public class Order {
        
        public String orderDate {get; set;}
        public String orderNumber {get; set;}
        public List<Equipment> equipList {get; set;}
        public List<ReturnedEquipment> retEquipList {get; set;}
        public List<TrackRec> trackingInfo {get; set;}
        
        public Order() {
            equipList = new List<Equipment>();
            retEquipList = new List<ReturnedEquipment>();
            trackingInfo = new List<TrackRec>();
            orderDate = '';
            orderNumber = '';
        }
    }
    
    
    //Container Class for Equipment/Software
    public class Equipment {
        
        public String serialNumber {get; set;}
        public String orderQuantity {get; set;}
        public String itemNumber {get; set;}
        public String itemDescription {get; set;}
        
        public Equipment() {
            serialNumber = '';
            orderQuantity = '';
            itemNumber = '';
            itemDescription = '';
        }
    }
    
    
    //Container Class for Returned Equipment/Software
    public class ReturnedEquipment {
        
        public String orderDate {get; set;}
        public String orderNumber {get; set;}
        public String serialNumber {get; set;}
        public String rmaQuantity {get; set;}
        public String itemNumber {get; set;}
        public String itemDescription {get; set;}
        public String returnDate {get; set;}
        
        public ReturnedEquipment() {
            orderDate = '';
            orderNumber = '';
            serialNumber = '';
            rmaQuantity = '';
            itemNumber = '';
            itemDescription = '';
            returnDate = '';
        }
    }
    
    
    //ContainerClass for AMAPIA Info
    public class AMAPIA {
        
        public String orderDate {get; set;}
        public String orderNumber {get; set;}
        public String orderQuantity {get; set;}
        public String itemNumber {get; set;}
        public String itemDescription {get; set;}
        public String startDate {get; set;}
        public String endDate {get; set;}
        public String orderBalance {get; set;}
        
        public AMAPIA() {
            orderDate = '';
            orderNumber = '';
            orderQuantity = '';
            itemNumber = '';
            itemDescription = '';
            startDate = '';
            endDate = '';
            orderBalance = '';
        }
    }
    
    
    //ContainerClass for Tracking Info
    public class TrackRec {
        
        public String ShipMethod {get; set;}
        public String trackNum {get; set;}
        
        public TrackRec() {
            shipMethod = '';
            trackNum = '';
        }
    }
    
}