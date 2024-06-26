/**
* HISTORY
* -----------------------
* 4/20/2021 Ahmed Elawad    Created 
* 7/12/2021 Ahmed Elawad    Added methods to update location to match information found in cs
* 09/20/2021 Jake Hinds    Change to use id instead of name for location match, general code refactor
* 01/11/2022 Jake Hinds		Web Service Logging
*/

public class ClientSpaceLocationQueueable implements Queueable, Database.AllowsCallouts {
    
    public final String  CLASS_NAME = 'ClientSpaceLocationQueueable';
    public final string END_POINT = 'callout:CS_API/next/api/dataform/v1.0/';
    public String tableName;
    public String operation;
    public String searchName;
    public Id parentId;
    public Account[] accounts;
    public Map<String, boolean> locations;
    public Boolean creatingLocation = false;
    public Account locationAccount;
    public String WORK_SPACE_ID;
    //public List<String> missingLocationsToAdd;
    public Map<Id,Account> missingLocationsToAdd;
    public String z_SFAccountGUID;
    public String patch_Table_Id;
    public Boolean patch_Location = false;
    public Integer NUM_OF_API_CALLS_FOR_THIS_CLASS = 0;
    public String testChildId;
    public String testChildId2;
    public String formerChildId;
    public Web_Service_Log__c wsl;
    public Attachment[] allFiles;
    
    public Map<String, Map<Integer, Account>> locationsToSyncMap = new Map<String, Map<Integer, Account>>();
    
    // instantiates the class using params for runtime
    public ClientSpaceLocationQueueable(String tblName, String method, String srchName, Id accId, Account[] accs, Boolean createLoc, Account acc, String wrkSpc, Map<Id,Account> rmngMissingLocs,Web_Service_Log__c p_wsl,Attachment[] p_files) {
        tableName = tblName;
        operation = method;
        searchName = srchName;
        parentId = accId;
        accounts = accs;
        creatingLocation = createLoc;
        locationAccount = acc;
        WORK_SPACE_ID = wrkSpc;
        missingLocationsToAdd = rmngMissingLocs;
        wsl = p_wsl;
        allFiles = p_files;
    }
    
    // Excecution starts by checking the functionality needed
    // First step is to get the locations. A parent acc ID is required on first pass to get a list of all children
    // and be used as the first query in the get locations. CS API responsds with all the locations for the mapped account.
    // For any accounts associated to the parent where a location doesn't exist a new job is queued to send a new location add
    // request using the returned ProjectId from the initial query(WORK_SPACE_ID in subsequent calls)
    // NOTES: 2 methods use hard coded values since I there are no linked accs from personal box. Otherwise can plug in
    // returned query values.
    // method findMissingLocations needs to assign dynamic wrskpace id from query
    public void execute(QueueableContext context) {
        System.debug('Starting to excecute ClientSpaceLocationQueueable. operation='+operation+' tableName='+tableName+' searchName='+searchName+' creatingLocation='+creatingLocation);
        if(wsl==null){
            wsl = new Web_Service_Log__c(ServiceName__c='ClientspaceLocationQueueable',CalledBy__c=UserInfo.getUserId(),
                                         CalledDt__c=system.now(),ServiceStart__c=system.now(),SobjName__c='Account',SobjId__c=parentId);
            allFiles = new Attachment[]{};
        }
        if (operation == 'POST' && tableName == 'gen_ClientMaster' && searchName != null && !creatingLocation) {
            System.debug('Executing location search...');
            getLocations(parentId, operation, tableName, searchName);
        } else if (operation == 'POST' && tableName == 'gen_ClientLocation' && creatingLocation) {
            System.debug('Executing create...');
            createLocation(locationAccount);
        } else if (operation == 'PATCH') {
            StartSyncLocations(locationsToSyncMap);
        }
    }
    
    // Builds the class to send a POST request with the searchName as a param
    public  void getLocations(String cmId, String method, String tableName, String searchName) {
        System.debug('getting locations ...');
        Boolean test = false;
        String reqBody = buildSearchForAccountBody(cmId);
        String endPoint = buildEndpoint(method, searchName, tableName, null);
        System.debug('EP: '+ endPoint);
        HttpRequest req = setRequest(endPoint, operation, reqBody);
        sendRequest(req);
    }
    
    // create a new location for the referenced account
    public void createLocation(Account acc) {
        System.debug('Creating location... ');
        Boolean test = false;
        String reqBody = buildPostForAcc(acc, 'Activate');
        String endPoint = buildEndpoint(operation, null, tableName, WORK_SPACE_ID);
        System.debug(endPoint);
        HttpRequest req = setRequest(endPoint, operation, reqBody);
        sendRequest(req);
    }
    
    // builds the request body for a POST Search query to retireve locations list from CS
    public String buildSearchForAccountBody(Id parentAccId) {
        System.debug('Building body to search for locations ...');
        System.debug('{"AccountGuid": "'+parentAccId+'"}');
        return '{"AccountGuid": "'+parentAccId+'"}'; 
    }
    
    // build the post request body for the passed in account: all required fields for API are added
    // ERROR NOTE: any null values should be left blank;
    public String buildPostForAcc(Account acc, String activation) {
        String body = '{';
        
        if(acc != null) {
            body+= '"z_SFAccountGUID":"'+acc.Id+'",\n';
            body+= '"LocationName":"'+acc.Name+'",\n';
            
            // These values don't need to be assigned as of 6/5/2021
            body+=  '"Addr2":"",\n';
            body+= '"County":"",\n';
            body+= '"luLocationType":"Other",\n';
            if(activation != null) {
                body+= '"z_SFActivation":"' + activation + '",\n';
            }
            
            // conditionally add these values if they exist on the account
            if (acc.ShippingStreet != null) body+= '"Addr1":"'+acc.ShippingStreet+'",\n';
            else body+= '"Addr1":"",\n';
            
            if (acc.ShippingCity != null) body+= '"City":"'+acc.ShippingCity+'",\n';
            else body+= '"City":"",\n';
            
            if (acc.NAICS_Code__c != null) body+= '"OverrideNAICS":"'+acc.NAICS_Code__c+'",\n';
            else body+= '"OverrideNAICS":"",\n';
            
            if (acc.Phone != null) body+= '"PhoneNumber":"'+acc.Phone+'",\n';
            else body += '"PhoneNumber":"",\n';
            
            if (acc.ShippingState != null) body+= '"State":"'+acc.ShippingState+'",\n';
            else body+= '"State":"",\n';
            
            if (acc.ShippingPostalCode != null) body+= '"ZipCode":"'+acc.ShippingPostalCode+'",\n';
            else body+= '"ZipCode":"",\n';
            
            if (acc.DBA__c != null) body+= '"z_DBA":"'+acc.DBA__c+'",\n';
            else body+= '"z_DBA":"",\n';
            
            body+= '"z_XML":"",\n';
            
            if (acc.Federal_ID_Number__c != null) body+= '"z_LocationFEIN":"' + acc.Federal_ID_Number__c + '"}';
            else body+= '"z_LocationFEIN":""}';
        }
        else if(acc == null && activation != null) {
            body+= '"z_SFActivation":"' + activation + '"}';
        }   
        
        // return the constructed body
        System.debug('MGF buildPostForAcc body='+body);
        Return body;
    }

    
    // build the endpoint to be attached to the HTTP header
    public String buildEndpoint(String method, String searchName, String tableName, String workspaceId) {
        System.debug('Building endpoint ...');
        System.debug('searchName='+searchName+' method='+method+' tableName='+tableName+' workspaceId='+workspaceId);
        // throw an error if no wrkspce id
        if (workspaceId != null && tableName == 'gen_ClientLocation') {
            return END_POINT + tableName + '/' + workspaceId;
        }
        
        if (method == 'PATCH') {
            return END_POINT + 'gen_ClientLocation/' + '/' + searchName;
        }
        
        return END_POINT + 'search/' + tableName + '/' + searchName;
    }
    
    // builds the HTTP request object based on operation and tablename
    public HttpRequest setRequest(String endPoint, String operation, String reqBody) {
        System.debug('Building req ...');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod(operation);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setHeader('Accept', 'application/json');
        
        req.setBody(reqBody);
        return req;
    }
    
    // sends off the request using the provided HTTP object and headers. 
     public void sendRequest(HttpRequest req){
        System.debug('Sending req ...');
        addCallToWSL(req,req.getBody(),'request',false);
        this.NUM_OF_API_CALLS_FOR_THIS_CLASS += 1;
        
        Http http = new Http();
        HTTPResponse res = new HttpResponse();
        Map<Boolean,String> responseMap = new Map<Boolean,String>();
        String response;
        Integer code;
        Map<String, List<Object>> responseHdr;
        Map<Id,Account> missingLocations;
        if(!Test.isRunningTest()){
            try{
                res = http.send(req); 
                response = res.getBody();
                code = res.getStatusCode();
                System.debug('MGF response='+response);
                System.debug('MGF code='+code);
                responseHdr = deserealize(response);
                addCallToWSL(req,response,'response',true);
                system.debug('creatingLocation: '+creatingLocation+' patch_Location: '+patch_Location);
                if (creatingLocation) {
                    missingLocations = missingLocationsToAdd;
                } else if (!patch_Location) {
                    missingLocations = findMissingLocations(responseHdr.get('Data'), accounts);
                }
                system.debug('missingLocations: '+missingLocations+' this.locationsToSyncMap:'+this.locationsToSyncMap);
                if (missingLocations != null && missingLocations.size() > 0) {
                    System.debug('Need to queue more jobs...');
                    // create new instances of the class to add a location for each
                    // : Should I pass anything here? Probably a design change to only pass the accounts I need creation for
                    queueNextJobForLocationCreate(missingLocations);
                } else if(!this.locationsToSyncMap.isEmpty()){
                    // send the loop to sync all locations    
                    StartSyncLocations(this.locationsToSyncMap);
                }
                if((missingLocations == null || (missingLocations != null && missingLocations.isEmpty())) &&
                          (this.locationsToSyncMap == null || (this.locationsToSyncMap != null && this.locationsToSyncMap.isEmpty()))){
                    completeWSL();
                }
            }
            catch(System.CalloutException e){ 
                response = e.getMessage();
                code = res.getStatusCode();
                System.debug('code:'+code+'\nerror: '+response);
                System.debug(code+' - '+response);
                System.debug('failed after send');
                ErrorLog.logError('ClientspaceLocationQueueable', 'sendRequest', 'too many callouts', accounts[0].id, e.getMessage());
                addCallToWSL(req,'too many callouts','response',false);
            }
        }
        else{ //isRunningTest
            System.debug('creatingLocation:'+creatingLocation);
            if(!creatingLocation && !patch_Location){
                String fakeResponse = returnFakeResponse('Initial Search');
                responseHdr = deserealize(fakeResponse);
                System.debug('responseHdr: '+responseHdr);
                missingLocations = findMissingLocations(responseHdr.get('Data'), this.accounts);
                System.debug('missingLocations: '+ missingLocations);
                queueNextJobForLocationCreate(missingLocations);
            }
            else if(creatingLocation){
                String fakeResponse = returnFakeResponse('Location Create Success');
                responseHdr = deserealize(fakeResponse);
            }
            if(!this.locationsToSyncMap.isEmpty()){
                StartSyncLocations(this.locationsToSyncMap);
            }
            
        }
    }
    
    public String returnFakeResponse(String operation){
        system.debug('returnFakeResponse operation: '+operation);
        // create a fake response
        String fakeResponse='';
        if(operation == 'Initial Search'){
            fakeResponse += '{"Data":[\n';
            fakeResponse += '{"RowNum": 1,';
            fakeResponse += '"SourceID": "0010q00000ZTEc2AAH",';
            fakeResponse += '"ProjectID": 193436,';
            fakeResponse += '"LocationId": 589665,';
            fakeResponse += '"SFAccountGUID": null,';
            fakeResponse += '"LocationName": "Main",';
            fakeResponse += '"LocationActive": true,';
            fakeResponse += '"pkCollateralID": 180988,';
            fakeResponse += '"CollateralRowGuid": "5e0a92dc-1bf3-4379-aba0-7c5c117d60fc",';
            fakeResponse += '"pkRFPQuestionnaireID": 14531,';
            fakeResponse += '"RiskUWGuid": "28093133-3566-4e07-95ee-83f3cbcd47f9",';
            fakeResponse += '"pkzBenefitsUnderwritingID": 16667,';
            fakeResponse += '"BenUWGuid": "c5abaa30-5260-4170-80ef-5939e567517c",';
            fakeResponse += '"pkzPEOOnboardingChecklistID": 3,';
            fakeResponse += '"UWChecklistGuid": "3f83126d-5596-445c-bd9e-60f3e82ce7c5"},';
            
            fakeResponse += '{"RowNum": 2,';
            fakeResponse += '"SourceID": "0010q00000ZTEc2AAH",';
            fakeResponse += '"ProjectID": 193436,';
            fakeResponse += '"LocationId": 589666,';
            fakeResponse += '"SFAccountGUID": "'+testChildId+'",';
            fakeResponse += '"LocationName": "test Child 1",';
            fakeResponse += '"LocationActive": false,';
            fakeResponse += '"pkCollateralID": 180988,';
            fakeResponse += '"CollateralRowGuid": "5e0a92dc-1bf3-4379-aba0-7c5c117d60fc",';
            fakeResponse += '"pkRFPQuestionnaireID": 14531,';
            fakeResponse += '"RiskUWGuid": "28093133-3566-4e07-95ee-83f3cbcd47f9",';
            fakeResponse += '"pkzBenefitsUnderwritingID": 16667,';
            fakeResponse += '"BenUWGuid": "c5abaa30-5260-4170-80ef-5939e567517c",';
            fakeResponse += '"pkzPEOOnboardingChecklistID": 3,';
            fakeResponse += '"UWChecklistGuid": "3f83126d-5596-445c-bd9e-60f3e82ce7c5"},';
            
            fakeResponse += '{"RowNum": 3,';
            fakeResponse += '"SourceID": "0010q00000ZTEc2AAH",';
            fakeResponse += '"ProjectID": 193436,';
            fakeResponse += '"LocationId": 589666,';
            fakeResponse += '"SFAccountGUID": "'+testChildId2+'",';
            fakeResponse += '"LocationName": "test Child 1",';
            fakeResponse += '"LocationActive": true,';
            fakeResponse += '"pkCollateralID": 180988,';
            fakeResponse += '"CollateralRowGuid": "5e0a92dc-1bf3-4379-aba0-7c5c117d60fc",';
            fakeResponse += '"pkRFPQuestionnaireID": 14531,';
            fakeResponse += '"RiskUWGuid": "28093133-3566-4e07-95ee-83f3cbcd47f9",';
            fakeResponse += '"pkzBenefitsUnderwritingID": 16667,';
            fakeResponse += '"BenUWGuid": "c5abaa30-5260-4170-80ef-5939e567517c",';
            fakeResponse += '"pkzPEOOnboardingChecklistID": 3,';
            fakeResponse += '"UWChecklistGuid": "3f83126d-5596-445c-bd9e-60f3e82ce7c5"},';
            
            fakeResponse += '{"RowNum": 4,';
            fakeResponse += '"SourceID": "0010q00000ZTEc2AAH",';
            fakeResponse += '"ProjectID": 193436,';
            fakeResponse += '"LocationId": 589666,';
            fakeResponse += '"SFAccountGUID": "'+formerChildId+'",';
            fakeResponse += '"LocationName": "test former child",';
            fakeResponse += '"LocationActive": false,';
            fakeResponse += '"pkCollateralID": 180988,';
            fakeResponse += '"CollateralRowGuid": "5e0a92dc-1bf3-4379-aba0-7c5c117d60fc",';
            fakeResponse += '"pkRFPQuestionnaireID": 14531,';
            fakeResponse += '"RiskUWGuid": "28093133-3566-4e07-95ee-83f3cbcd47f9",';
            fakeResponse += '"pkzBenefitsUnderwritingID": 16667,';
            fakeResponse += '"BenUWGuid": "c5abaa30-5260-4170-80ef-5939e567517c",';
            fakeResponse += '"pkzPEOOnboardingChecklistID": 3,';
            fakeResponse += '"UWChecklistGuid": "3f83126d-5596-445c-bd9e-60f3e82ce7c5"}],';
            
            fakeResponse += '"Errors":[],';
            fakeResponse += '"Total": 4}';
        }
        else if(operation == 'Location Create Success'){
            fakeResponse += '{"ID":"725772",';
            fakeResponse += '"RowGUID":"89347dc8-ddef-4b74-806d-9e7714fee049",';
            fakeResponse += '"TableName":"gen_ClientLocation",';
            fakeResponse += '"ProjectTypeID":173,';
            fakeResponse += '"WorkspaceID":"331493",';
            fakeResponse += '"Fields":{"LocationName":"test child 3","luLocationType":"Other","z_SFActivation":"Activate","Addr1":"632 test cir","z_LocationFEIN":null,"Addr2":null,"ZipCode":"14225","City":"Testtown","State":"ny","County":null,"PhoneNumber":null,"OverrideNAICS":null,"z_SFAccountGUID":"0013K00000l7y95QAA","State_D":"New York","luLocationType_D":"Other"},';
            fakeResponse += '"Errors":[]}';
        }
        
        return fakeResponse;
    }


    // returns map of repsonse attribute: response values
    // ex: {Data: [
    //              {'locationName': 'Main', 'ProjectId':'xxxxxxxxxxx', ...}, 
    //              {'locationName':'',...}, 
    //              ...
    //          ]
    //      }
    public Map<String, List<Object>> deserealize(String resString) {
        System.debug('Deserializing response json...');
        Map<String, List<Object>> retVal = new Map<String, List<Object>>();
        List<Object> locObjs = new List<Object>();
        
        // start to desearlaize: get the keysets
        Map<String, Object> keySets = (Map<String, Object>)JSON.deserializeUntyped(resString);
        Set<String> respObjs = keySets.keySet();
        
        // retrieves the dataSet & errors if present
        System.debug('Getting data');
        System.debug(keySets.keySet());
        List<Object> data = (List<Object>)keySets.get('Data');
        List<Object> errors;
        if (respObjs.contains('Errors')) errors = (List<Object>)keySets.get('Errors');
        // iterates the return data and adds all locations to list of locations
        if(errors != null) {
            for (Object err : errors) {
                Map<String, Object> location = (Map<String, Object>)err;
                System.debug('Error: '+ err);
            }
        }
        
        if(data != null) {
            System.debug('MGF Adding Location...');
            for (Object loc : data) {
                Map<String, Object> location = (Map<String, Object>)loc;
                locObjs.add(location);
            }
        }
        
        // add the data property into the map
        retVal.put('Data', locObjs);
        return retVal;
    }
    public Map<Id,Account> findMissingLocations(List<Object> locs, Account[] accs) {
        System.debug('Got to missing locs');
        List<String> missingLocations = new  List<String>();
        Map<Id,Account> acctMap = new Map<Id,Account>();
        for (Account acc : accs) {
            if (!acc.isParent__c) { // do not need to create any location for main account
                acctMap.put(acc.Id,acc);
            }
        }
            // handle this section: the logic should jump into loop only if locations exist. If locations are blank
            // Iterate the locations and add any missing account names to the return val list(list of account locations to be created)
        for (Object loc : locs) {
            Map<String, Object> location = (Map<String, Object>)loc;
            System.debug('Checklist location for Workspace Id:'+(Integer)location.get('ProjectID'));
            if (WORK_SPACE_ID == null) {
                Integer wrkspcInt = (Integer)location.get('ProjectID');
                WORK_SPACE_ID= String.valueOf(wrkspcInt);
            } // should use wrksps from loc
            //main location doesn't return an ID, don't need to do anything with it anyway
            if((String)location.get('LocationName') == 'Main'){
                continue;   
            }    
            String acctGuid = (String)location.get('SFAccountGUID');
            Account acct = (String.isNotBlank(acctGuid) ? acctMap.remove(acctGuid) : null);
            
            // if the location is main it should have sfguid attached
            // if sfguid is empty we need to send a patch request to update the field
            // so we need to break out of this loop and logic completely and restart the process: functionality for patch not added
            if (acct!=null && (Boolean)location.get('LocationActive')) {
                // check the locations values to make sure they match what we currently have in sf
                System.debug('location is active for acct:'+acct.Name);
                addLocationAccToSyncMap(acct, (Integer)location.get('LocationId'), 'noOp');
            }
            else if (acct!=null && !(Boolean)location.get('LocationActive')) {
                System.debug('location is inactive for acct:'+acct.Name);
                addLocationAccToSyncMap(acct, (Integer)location.get('LocationId'), 'Activate');
            }
            //no account found, need to deactivate as long as it isn't the main location.  main location doesn't return an ID
            else if(acct == null){
                System.debug('No account for ' + (Integer)location.get('LocationId'));
                addLocationAccToSyncMap(null, (Integer)location.get('LocationId'), 'Deactivate');
            }
        }
        system.debug('need to create locations for '+acctMap.keySet());
        system.debug('locationsToSyncMap'+locationsToSyncMap);
        
        return acctMap;
    }
    
    // searches the accounts & missing locations list and creates a new queable job to launch the creation API call
    public void queueNextJobForLocationCreate(Map<Id,Account> missingLocations) {
        System.debug('Next Job queue pre-set...');
        System.debug('queueNextJobForLocationCreate Missing locs: '+missingLocations);
        // iterates the list of accounts set on the class
        // a match for an account name and missingLocation name removes both values from the respective lists
        // A new job is queued for the account to be created
        Account missingAcct;
        for (Account acct : accounts) {
            if(missingLocations.containsKey(acct.Id)){
                missingAcct = missingLocations.remove(acct.Id);
                break;
            }
        }
        accounts = missingLocations.values();
        
        System.debug('queueNextJobForLocationCreate missingAcct: '+missingAcct);
        if (Test.isRunningTest() && missingAcct != null) {
            skipQueueableLaunchForTest(missingAcct, WORK_SPACE_ID, missingLocations);
            return;
        }
        else if (!Test.isRunningTest() && missingAcct != null) {
            launchLocationCreate(missingAcct, WORK_SPACE_ID, missingLocations);
        }
        
    }        
    
    public void skipQueueableLaunchForTest(Account acc, String wrkspc,  Map<Id,Account> missingLocs) {
        system.debug('skipQueueableLaunchForTest');
        this.tableName = 'gen_ClientLocation';
        this.operation = 'POST';
        this.creatingLocation = true;
        this.locationAccount = acc;
        this.WORK_SPACE_ID = wrkspc;
        this.missingLocationsToAdd = missingLocs;
        launchLocationCreate(acc,wrkspc, missingLocs);
    }
    
    // launches a new queud job creating 
    public void launchLocationCreate(Account acc, String workSpace, Map<Id,Account> missingLocs) {
        System.debug('Queueing new location create job for: '+ acc.Name +' missingLocs: '+ missingLocs.keySet());
        ClientSpaceLocationQueueable qj = new ClientSpaceLocationQueueable('gen_ClientLocation', 'POST', searchName, parentId, accounts, true, acc, WORK_SPACE_ID, missingLocs,wsl,allFiles);
        qj.locationsToSyncMap = this.locationsToSyncMap;
        if (!Test.isRunningTest()) System.enqueueJob(qj);   
        //if (!Test.isRunningTest()) createLocation(acc);   
        else createLocation(acc);
    }
    
    // need a flag to determine when we need to send a patch request
    public void syncLocation(Account acc, Integer locationId, String activation) {
        
        // nasically build the location send but with an update call for the location
        System.debug('syncLocation Account: '+ acc);
        System.debug('MGF syncLocation locationId='+locationId);
        System.debug('MGF syncLocation activation='+activation);
        //System.debug('Naics: '+ acc.NAICS_Code__c);
        String body = buildPostForAcc(acc, activation);
        String locID = String.valueOf(locationId);
        String endpoint = buildEndpoint('PATCH', locID, null, null);
        System.debug(endpoint);
        this.patch_Location = true;
        HttpRequest req = setRequest(endpoint, 'PATCH', body);
        sendRequest(req);
        this.patch_Location = false;
        System.debug('Succesfuly patched location');
    }
    
    public void addLocationAccToSyncMap(Account Acc, Integer locationID, String activationCode){
        Map<Integer, Account> locationStorageMap = locationsToSyncMap.get(activationCode);
        if (locationStorageMap == null) {
            locationsToSyncMap.put(activationCode, new Map<Integer, Account>());
            locationStorageMap = locationsToSyncMap.get(activationCode);
        }
        
        locationStorageMap.put(locationID, Acc);
        System.debug('locationStorageMap.keySet(): '+locationStorageMap.keySet());
        for (Integer key :  locationStorageMap.keySet()) {
            System.debug(locationStorageMap.get(key));
        }
    }
    public void StartSyncLocations(Map<String, Map<Integer, Account>> locationsToSyncMap) {
        system.debug('in startSyncLocations');
        // start to loop and send API calls to sync the location
        // trigger a new queueable with all the sync locations and a patch API call
        // get an instance of an account
        Map<String, Map<Integer, Account>> syncMap = removeAccountFromMap(locationsToSyncMap);
        
        system.debug('syncMap: '+syncMap);
        if (syncMap != null) {
            String activationCode = (New List<String>(syncMap.keySet())[0]);                
            Map<Integer, Account> locSyncMap = (New Map<Integer, Account>(syncMap.get(activationCode)));
            Integer locId = (New List<Integer>(locSyncMap.keySet())[0]);
            Account acc = locSyncMap.get(locId);
            // send the patch for the account
            if (activationCode == 'noOp') activationCode = null;
            syncLocation(acc, locId, activationCode);
        }
        system.debug('StartSyncLocations locationsToSyncMap'+locationsToSyncMap);
        if (!locationsToSyncMap.isEmpty()) {
            ClientSpaceLocationQueueable qj = new ClientSpaceLocationQueueable('gen_ClientLocation', 'PATCH', this.searchName, this.parentId, this.accounts, false, null, this.WORK_SPACE_ID, null,wsl,allFiles);
            qj.locationsToSyncMap = locationsToSyncMap;
            System.enqueueJob(qj);
        }
    }
    
    public Map<String, Map<Integer, Account>> removeAccountFromMap(Map<String, Map<Integer, Account>> fullMap) {
        
        // get the operation map
        Map<Integer, Account> accountsToSync = fullMap.get('Activate');
        // if the operation map exists but is empty delete it
        // otherwise loop the locations to be activated
        if (accountsToSync != null && accountsToSync.isEmpty()) {
            fullMap.remove('Activate');
        } else if (accountsToSync != null){ 
            // for each account clone the map
            // delete the original from the storage
            // and return the new map to be synced and processed by the calling method
            for (Integer locId : accountsToSync.keySet()) {
                Map<String, Map<Integer, Account>> fullRetMap = new Map<String, Map<Integer, Account>>();
                Map<Integer, Account> retMap = new Map<Integer, Account>();
                retMap.put(locId, accountsToSync.get(locId));
                fullRetMap.put('Activate', retMap);
                accountsToSync.remove(locId);
                return fullRetMap;
            }
        }
        
        // if activate op is empty delete emptu op
        // otherwise if acccount is empty assign account
        Map<Integer, Account> accountsWOOp = fullMap.get('noOp');
        // if the operation map exists but is empty delete if
        // otherwise loop the locations to be activated
        if (accountsWOOp != null && accountsWOOp.isEmpty()) {
            fullMap.remove('noOp');
        } else if (accountsWOOp != null){ 
            // for each account clone the map
            // delete the original from the storage
            // and return the new map to be synced and processed by the calling method
            for (Integer locId : accountsWOOp.keySet()) {
                Map<String, Map<Integer, Account>> fullRetMap = new Map<String, Map<Integer, Account>>();
                Map<Integer, Account> retMap = new Map<Integer, Account>();
                retMap.put(locId, accountsWOOp.get(locId));
                fullRetMap.put('noOp', retMap);
                accountsWOOp.remove(locId);
                return fullRetMap;
            }
        }
        
        // if deactivate is empty delete deactivate
        // otherwise return null or something to track that you only need the location ID
        // if activate op is empty delete emptu op
        // otherwise if acccount is empty assign account
        Map<Integer, Account> DeactivateLocs = fullMap.get('Deactivate');
        // if the operation map exists but is empty delete if
        // otherwise loop the locations to be activated
        if (DeactivateLocs != null && DeactivateLocs.isEmpty()) {
            fullMap.remove('Deactivate');
        } else if (DeactivateLocs != null){ 
            // for each account clone the map
            // delete the original from the storage
            // and return the new map to be synced and processed by the calling method
            for (Integer locId : DeactivateLocs.keySet()) {
                Map<String, Map<Integer, Account>> fullRetMap = new Map<String, Map<Integer, Account>>();
                Map<Integer, Account> retMap = new Map<Integer, Account>();
                retMap.put(locId, DeactivateLocs.get(locId));
                fullRetMap.put('Deactivate', retMap);
                DeactivateLocs.remove(locId);
                return fullRetMap;
            }
        }
        
        return null;
    }
    public void addCallToWSL(HttpRequest request,String body,String requestOrResponse,Boolean successful){
        system.debug('ClientspaceAPIQueueable addCallToWSL wsl'+wsl);
        if(wsl!=null){
        	wsl.Successful__c = successful;
            Attachment file = new Attachment();
            file.Name = operation+'-'+request.getMethod()+'-'+requestOrResponse;
            file.ContentType = 'text/plain';
            String fullBody = request.getEndpoint()+'\n'+request.getMethod()+'\n'+body;
            file.Body = Blob.valueOf(fullBody);
            allFiles.add(file);
        }
    }
    public void completeWSL(){
        system.debug('ClientspaceLocationQueuable completeWSL wsl'+wsl);
        if(wsl!=null && String.isBlank(wsl.Id)){
            wsl.ServiceEnd__c = system.now();
            //take the last operation because it will likely be the most specific name
            wsl.NamedFunction__c='Location Sync';
            DmlHelper.performDML2(new List<Web_Service_Log__c>{wsl}, DmlHelper.DML_INSERT, 'ClientspaceLocationQueuable', 'completeWSL', 'Inserting Web Service Log', true);
            
            system.debug('ClientspaceLocationQueuable completeWSL allFiles'+allFiles);
            if(allFiles!=null && !allFiles.isEmpty() && String.isNotBlank(wsl.Id)){
                for(Attachment file:allFiles){
                    file.ParentId = wsl.Id;
                }
                DmlHelper.performDML2(allfiles, DmlHelper.DML_INSERT, 'ClientspaceLocationQueuable', 'completeWSL', 'Inserting Web Service Log Attachments', true);
            }
        }
        
    }
}