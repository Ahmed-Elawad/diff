/* Methods for interacting with BLS system

    History
    -------
	NOTE : 
	Custom label is used to store endpoint & registration key : BLS_Api_Endpoint,BLS_Registration_Key
	Custom Settings store all the default values for Average wages, Medical Participation and Turnover rate
    07/13/2022 Jidesh Created
	09/13/2022 Jidesh Updated the code to make Synchronous call to BLS System from the component and Performance improvements.
*/
public without sharing class BlsDataAPIQueueable implements Queueable,Database.AllowsCallouts  {
    public List<Account> accounts;
    public List<PEO_Onboarding_Checklist__c> checklists;
    public String operation;
    public List<String> seriesIdsToFetch;
    public Web_Service_Log__c wsl;
    public Attachment[] allFiles;
    //Key value pair that stores the data format <SeriesId, DatapointValue>
    public Map<String,Decimal> dataValueMap = new Map<String,Decimal>();
    public String fieldResponseToSave;
    public Decimal turnOverRate; 

    public BlsDataAPIQueueable(List<String> seriesId, String task, List<Account> acc, List<PEO_Onboarding_Checklist__c> chklist, Web_Service_Log__c p_wsl, Attachment[] p_files){
        seriesIdsToFetch = seriesId;
        operation = task;
        accounts  = acc;
        wsl = p_wsl;
        checklists  = chklist;
        allFiles = p_files;
    }
    
    public void execute(QueueableContext context) {
        if(wsl==null){
            //Creating a new web service log for BLS Public Data API
            wsl = new Web_Service_Log__c(ServiceName__c='BlsDataAPIQueueable',CalledBy__c=UserInfo.getUserId(),
                                         CalledDt__c=system.now(),ServiceStart__c=system.now(),SobjName__c='PEOUW_BLS_Data__c');
            for(PEO_Onboarding_Checklist__c checklist : checklists){
                if(checklist!=null){
                    wsl.SobjId__c=checklist.Id;
                }
            }
            allFiles = new Attachment[]{};
        }
        //operation = 'Fetch info' describes we are fetching the info from BLS system
        if(operation == 'Fetch info'){
            fetchSeriesIdInfoFromBLSCallout(seriesIdsToFetch, 'BLS Data points');
        }
    }
    
    public Boolean fetchSeriesIdInfoFromBLSCallout(List<String> seriesIdsToFetch, String dataPoint){
        
        if(dataPoint == 'BLS Data points for UI'){
            wsl = new Web_Service_Log__c(ServiceName__c='BlsDataAPIQueueable',CalledBy__c=UserInfo.getUserId(),
                                         CalledDt__c=system.now(),ServiceStart__c=system.now(),SobjName__c='PEOUW_BLS_Data__c');
            for(PEO_Onboarding_Checklist__c checklist : checklists){
                if(checklist!=null){
                    wsl.SobjId__c=checklist.Id;
                }
            }
            allFiles = new Attachment[]{};
                }
        
        string calloutType = 'POST';
        //string endpoint = 'https://api.bls.gov/publicAPI/v2/timeseries/data/';
        //Custom label is used to store endpoint
        string endpoint = Label.BLS_Api_Endpoint;
        HttpRequest req = buildRequest(calloutType,endpoint);
        //String registrationkey = '9159faddb4da4d9aa0a55e5a4534d8b4';// registraion key for user : Jidesh
        //Custom label is used to store registration key
        String registrationkey = Label.BLS_Registration_Key;
        String filebody = buildFileJSON(seriesIdsToFetch,registrationkey);
        String value;
        //Value to be set on BLS record
        Decimal blsValue = 0;
        Integer  blsYear = 2021;
        req.setBody(fileBody);
        Map<Boolean,String> responseMap = sendRequest(req,Test.isRunningTest());
        for(Boolean success : responseMap.keySet()){
            system.debug('responseMap:'+responseMap);
            if(success){
                try{
                    Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(responseMap.get(success));
                    //The BLS response to be stored on PEOUW_BLS_Data__c record
                    fieldResponseToSave  = (String)responseMap.get(success);
                    
                    Map<String, Object> m2 = (Map<String, Object>)m.get('Results');
                    List<Object> m3 = (List<Object>)m2.get('series');
                    for(Object str:m3){
                        Map<String, Object> m4 = (Map<String, Object>)str;
                        List<Object> m5 = (List<Object>)m4.get('data');
                        String seriesId = (String)m4.get('seriesID');
                        system.debug('seriesId:'+seriesId);
                        //This section determines what type of datapoint is being processed
                        // Prefix JT - Turnover rate
                        // Prefix EN - Average wages
                        // Prefix NB - Medical participation
                        if(seriesId.startsWith('JT')){
                            //As per the requirement turnover rates are calculated as the total for last 12 months
                            blsValue = fetchTurnoverRates(m5);
                        }
                        else{
                            blsValue = 0;
                            if(m5.size() != 0){
                                Map<String, Object> m6 = (Map<String, Object>)m5[0];
                                value  = (String)m6.get('value');
                                System.debug('final value:'+value);
                                blsValue = decimal.ValueOf(value);
                                blsYear = Integer.ValueOf((String)m6.get('year'));
                                System.debug('Blsyear:'+blsYear);
                            }
                            else{
                                system.debug('BlsDataAPIQueueable fetchSeriesIdInfoFromBLSCallout value doesnt exist');
                            }
                        }
                        if(seriesId.startsWith('EN')){
                            dataValueMap.put('ENAvgWageYear', blsYear);
                        }
                        dataValueMap.put(seriesId, blsValue);
                    }
                    if(dataPoint == 'BLS Data points for UI'){
                        return updateBLSRecordWithValuesFromAura();
                    }
                    else{
                        updateBLSRecordWithValues();
                    }
                }
                catch(Exception e){ 
                    System.debug('Error in data processing');
                    return false;
                }
            }
            else{
                System.debug('Error log:'+responseMap.get(success));
                System.debug('Error in endpoint');
                String response = responseMap.get(success);
                addCallToWSL(req,response,'response',false);
                return false;
            }
        }
        return true;
    }
    
    
    public HttpRequest buildRequest(string calloutType,string endpoint){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(calloutType);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setHeader('Accept', 'application/json');
        return req;
    }
    
    public String buildFileJSON(List<String> seriesIdsToFetch,String registrationkey){
        //String body = '{"seriesid":["'+seriesIdsToFetch[0]+'"],"registrationkey":"9159faddb4da4d9aa0a55e5a4534d8b4"}';
        //String body = '{ "startyear":"2018", "endyear":"2018","registrationkey":"9159faddb4da4d9aa0a55e5a4534d8b4"}';
        //String startYear = '2020';
        String startYear = String.valueOf(System.Today().year()-1);
        String endYear = String.valueOf(System.Today().year());
        System.debug('startYear:'+startYear+'endYear:'+endYear);
        String seriesString ='{"seriesid":["';
        if(seriesIdsToFetch.size()>0){
            for(Integer i=0; i<seriesIdsToFetch.size();i++){
                if(i != seriesIdsToFetch.size()-1){
                    seriesString += seriesIdsToFetch[i]+'","';
                }
                else{
                    seriesString += seriesIdsToFetch[i]+'"],';
                }
            }
        }
        System.debug('seriesString:'+seriesString);
        String body = seriesString+'\n';
        body += '"registrationkey":"'+registrationkey+'",';
        //body += '"registrationkey":"'+registrationkey+';
        body += '"startyear":"'+startYear+'",';
        body += '"endyear":"'+endYear+'"';
        body +=     '}';
        system.debug('body:'+body);
        return body;
    }
    
    public Map<Boolean,String> sendRequest(HttpRequest req,Boolean isRunningTest){
        addCallToWSL(req,req.getBody(),'request',false);
        Http http = new Http();
        HTTPResponse res = new HttpResponse();
        Map<Boolean,String> responseMap = new Map<Boolean,String>();
        String response;
        Integer code;
        if(!Test.isRunningTest()){
            System.debug('not running test');
            try{
                res = http.send(req); 
                response = res.getBody();
                code = res.getStatusCode();
                System.debug('code:'+code+'\nbody: '+response);
                // handle the error codes provided by the CS API
                if (code == 401) {
                    String errResp = '{"Data": [],"Errors":{"Fatal_Error": "Unable to access BLS server"}}';
                    responseMap.put(false, errResp);
                    addCallToWSL(req,'Cannot Reach Server','response',false);
                } else {
                    responseMap.put(true,response); 
                    addCallToWSL(req,response,'response',true);
                }
            }
            catch(System.CalloutException e){ 
                System.debug('Error in HTTPS');
                response = e.getMessage();
                code = res.getStatusCode();
                System.debug('code:'+code+'\nerror: '+response);
                System.debug(res.toString());
                responseMap.put(false,code+' - '+response);
                addCallToWSL(req,response,'response',false);
            }
            completeWSL();
        }
        else{
            String fakeResponse;
            fakeResponse = '{';
            fakeResponse += '"status":"REQUEST_SUCCEEDED","responseTime":192,';
            fakeResponse += '"message":["No Data Available for Series NBU21572000000000026179 Year: 2022","No Data Available for Series ENU0600050572111 Year: 2022"],';
            fakeResponse += '"Results": {';
            fakeResponse +='"series":[';
            fakeResponse += '{"seriesID":"NBU21572000000000026179","data":[{"year":"2021","period":"A01","periodName":"Annual","latest":"true","value":"10","footnotes":[{}]}]},';
            fakeResponse += '{"seriesID":"ENU0600050572111","data":[{"year":"2021","period":"A01","periodName":"Annual","latest":"true","value":"41782","footnotes":[{"code":"P","text":"Preliminary"}]}]},';
            fakeResponse += '{"seriesID":"JTS720000000000000JOR","data":[{"year":"2022","period":"M05","periodName":"May","latest":"true","value":"9.5","footnotes":[{"code":"P","text":"preliminary"}]},';
            fakeResponse += '{"year":"2022","period":"M04","periodName":"April","value":"9.1","footnotes":[{}]},{"year":"2022","period":"M03","periodName":"March","value":"9.9","footnotes":[{}]},';
            fakeResponse += '{"year":"2022","period":"M02","periodName":"February","value":"10.3","footnotes":[{}]},';
            fakeResponse += '{"year":"2022","period":"M01","periodName":"January","value":"10.4","footnotes":[{}]},';
            fakeResponse += '{"year":"2021","period":"M12","periodName":"December","value":"12.2","footnotes":[{}]},';
            fakeResponse += '{"year":"2021","period":"M11","periodName":"November","value":"10.3","footnotes":[{}]},';
            fakeResponse += '{"year":"2021","period":"M10","periodName":"October","value":"10.3","footnotes":[{}]},';
            fakeResponse += '{"year":"2021","period":"M09","periodName":"September","value":"9.7","footnotes":[{}]},';
            fakeResponse += '{"year":"2021","period":"M08","periodName":"August","value":"10.9","footnotes":[{}]},';
            fakeResponse += '{"year":"2021","period":"M07","periodName":"July","value":"9.9","footnotes":[{}]},';
            fakeResponse += '{"year":"2021","period":"M06","periodName":"June","value":"9.5","footnotes":[{}]},';
            fakeResponse += '{"year":"2021","period":"M05","periodName":"May","value":"9.1","footnotes":[{}]}]';
            fakeResponse += '}'; 
            fakeResponse += ']}}';
            
            System.debug('fakeResponse:'+fakeResponse);
            responseMap.put(true,fakeResponse);
        }
         return responseMap;
    }
    
    public void addCallToWSL(HttpRequest request,String body,String requestOrResponse,Boolean successful){
        system.debug('BLSAPIQueueable addCallToWSL wsl'+wsl);
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
        system.debug('BLSAPIQueueable completeWSL wsl'+wsl);
        if(wsl!=null){
            wsl.ServiceEnd__c = system.now();
            //take the last operation because it will likely be the most specific name
            wsl.NamedFunction__c=operation;
            DmlHelper.performDML2(new List<Web_Service_Log__c>{wsl}, DmlHelper.DML_INSERT, 'BLSAPIQueueable', 'completeWSL', 'Inserting Web Service Log', true);
        }
        system.debug('BLSAPIQueueable completeWSL allFiles'+allFiles);
        if(allFiles!=null && !allFiles.isEmpty() && wsl!=null && String.isNotBlank(wsl.Id)){
            for(Attachment file:allFiles){
                file.ParentId = wsl.Id;
            }
            DmlHelper.performDML2(allfiles, DmlHelper.DML_INSERT, 'BLSAPIQueueable', 'completeWSL', 'Inserting Web Service Log Attachments', true);
        }
    }
    
    //Method to fetch turnover rate for the last 12 months
    public Decimal fetchTurnoverRates(List<Object> response){
        System.debug('BlsDataAPIQueueable fetchTurnoverRates');
        Integer i=0;
        Decimal turnOverRatePerMonth=0;
        //Iterate over the response per month
        //Set an Integer to break when count== 12 i.e. 12 months
        for(Object jtValue: response){
            i++;
            Map<String, Object> m6 = (Map<String, Object>)jtValue;
            String value  = (String)m6.get('value');
            //Add turnover rate values for each month
            turnOverRatePerMonth = turnOverRatePerMonth + decimal.ValueOf(value);
            if(i==12){
                break;
            }
        }
        return turnOverRatePerMonth;
    }
    
    //This method Insert/Update the PEOUW_BLS_Data__c with the value received from BLS system
    public void updateBLSRecordWithValues(){ 
        for(Account account: accounts){
            Id accountId = account.Id;
            PEOUW_BLS_Data__c[] blsRecordsToUpdate = new PEOUW_BLS_Data__c[]{};
                PEOUW_BLS_Data__c[] blsRecordsToInsert = new PEOUW_BLS_Data__c[]{};
                    //dataValueMap contains the key value pairs to store records in SF
                    //Check if records have been retrieved through api call
                    if(dataValueMap.size()!=0){
                        //Select the checklist for account
                        PEO_Onboarding_Checklist__c checklist = [Select id, Name from PEO_Onboarding_Checklist__c where Prospect_Client__c =:accountId limit 1];
                        System.debug('checklist:'+checklist);
                        if(checklist != null){
                            //If checklist exists build a soql query to fetch the BLS related list info
                            List<Schema.FieldSetMember>  blsDataFieldSet = SObjectType.PEOUW_BLS_Data__c.FieldSets.BLS_Api_fields.getFields();
                            String[] fields = new String[]{};
                                for (SChema.FieldSetMember field : blsDataFieldSet) {
                                    fields.add(field.getFieldPath());
                                }
                            String query = 'Select '+ String.join(fields,',')  + ' FROM PEOUW_BLS_Data__c WHERE PEO_Underwriting_Checklist__c=\'' + checklist.Id + '\'  LIMIT 1';
                            PEOUW_BLS_Data__c[] recs = Database.query(query);
                            //If Bls records exist then update it
                            //else create a new PEOUW_BLS_Data__c record
                            if(recs != null && recs.size() > 0) {
                                //BLS records exist
                                Boolean needUpdate = false;
                                for(String key: dataValueMap.keySet()){
                                    if(key.startsWith('NB')){
                                        //To check if the data is Medical participation
                                        recs[0].Medical_Participation__c = dataValueMap.get(key);
                                        needUpdate = true;
                                    }else if(key.startsWith('JT')){
                                        //To check if the data is for Turnover rate
                                        recs[0].Turnover_rate__c = dataValueMap.get(key);
                                        needUpdate = true;
                                    }
                                    else if(key.startsWith('EN')){
                                        //To check if the data is for Average wages
                                        if(key == 'ENAvgWageYear'){
                                            recs[0].Avg_wages_last_updated_on__c = dataValueMap.get(key);
                                            needUpdate = true;
                                        }
                                        else{
                                            recs[0].Average_wages__c = dataValueMap.get(key);
                                            needUpdate = true;
                                        }
                                    }
                                }
                                if(needUpdate){
                                    //If update is needed, add it to the list and call the DML Update
                                    //We are also storing the Response received from BLS in BLS_System_response__c field in PEOUW_BLS_Data__c object
                                    recs[0].BLS_System_response__c = fieldResponseToSave;
                                    recs[0].NAICS_Code__c = account.NAICS_Code__c;
                                    blsRecordsToUpdate.add(recs[0]);
                                }
                                if(blsRecordsToUpdate!=null){
                                    DmlHelper.performDML2(blsRecordsToUpdate, DmlHelper.DML_UPDATE, 'BlsDataAPIQueueable', 'updateBLSRecordWithValues', 'Upserting BLS values', true);
                                }
                            } 
                            else{
                                //BLS records doesnt exist
                                Boolean needInsert = false;
                                PEOUW_BLS_Data__c blsRecordnew = new PEOUW_BLS_Data__c();
                               
                                for(String key: dataValueMap.keySet()){
                                    if(key.startsWith('NB')){
                                        //To check if the data is Medical participation
                                        blsRecordnew.Medical_Participation__c = dataValueMap.get(key);
                                        needInsert = true;
                                    }else if(key.startsWith('JT')){
                                        //To check if the data is for Turnover rate
                                        blsRecordnew.Turnover_rate__c = dataValueMap.get(key);
                                        needInsert = true; 
                                    }
                                    else if(key.startsWith('EN')){
                                        //To check if the data is for Average wages
                                        System.debug('EN Key:'+key);
                                        if(key == 'ENAvgWageYear'){
                                            blsRecordnew.Avg_wages_last_updated_on__c = dataValueMap.get(key);
                                            needInsert = true;
                                        }
                                        else{
                                            blsRecordnew.Average_wages__c = dataValueMap.get(key);
                                            needInsert = true;
                                        }
                                    }
                                }
                                if(needInsert){
                                    //If Insert is needed, add it to the list and call the DML Insert
                                    //Mapping the Checklist to the BLS Data
                                    //Checklist name should match the BLS record Name
                                    blsRecordnew.Name = checklist.Name;
                                    blsRecordnew.PEO_Underwriting_Checklist__c = checklist.Id;
                                    blsRecordnew.BLS_System_response__c = fieldResponseToSave;
                                    blsRecordnew.NAICS_Code__c = account.NAICS_Code__c;
                                    blsRecordsToInsert.add(blsRecordnew);
                                }
                                if(blsRecordsToInsert !=null){
                                    DmlHelper.performDML2(blsRecordsToInsert, DmlHelper.DML_INSERT, 'BlsDataAPIQueueable', 'updateBLSRecordWithValues', 'Creating a BLS record', true);
                                }               
                            }
                        }
                    }
        }
    }
    
    //This method Insert/Update the PEOUW_BLS_Data__c with the value received from BLS system
    //A boolean value will be returned to the Benchmark Component
    public Boolean updateBLSRecordWithValuesFromAura(){  
        for(Account account: accounts){
            Id accountId = account.Id;
            System.debug('accountId:'+accountId);
            System.debug('dataValueMap:'+dataValueMap);
            PEOUW_BLS_Data__c[] blsRecordsToUpdate = new PEOUW_BLS_Data__c[]{};
                PEOUW_BLS_Data__c[] blsRecordsToInsert = new PEOUW_BLS_Data__c[]{};
                    //dataValueMap contains the key value pairs to store records in SF
                    //Check if records have been retrieved through api call
                    if(dataValueMap.size()!=0){
                        //Select the checklist for account
                        PEO_Onboarding_Checklist__c checklist = [Select id, Name from PEO_Onboarding_Checklist__c where Prospect_Client__c =:accountId limit 1];
                        System.debug('checklist:'+checklist);
                        if(checklist != null){
                            //If checklist exists build a soql query to fetch the BLS related list info
                            List<Schema.FieldSetMember>  blsDataFieldSet = SObjectType.PEOUW_BLS_Data__c.FieldSets.BLS_Api_fields.getFields();
                            String[] fields = new String[]{};
                                for (SChema.FieldSetMember field : blsDataFieldSet) {
                                    fields.add(field.getFieldPath());
                                }
                            String query = 'Select '+ String.join(fields,',')  + ' FROM PEOUW_BLS_Data__c WHERE PEO_Underwriting_Checklist__c=\'' + checklist.Id + '\'  LIMIT 1';
                            PEOUW_BLS_Data__c[] recs = Database.query(query);
                            //If Bls records exist then update it
                            //else create a new PEOUW_BLS_Data__c record
                            if(recs != null && recs.size() > 0) {
                                //BLS records exist
                                Boolean needUpdate = false;
                                for(String key: dataValueMap.keySet()){
                                    if(key.startsWith('NB')){
                                        //To check if the data is Medical participation
                                        recs[0].Medical_Participation__c = dataValueMap.get(key);
                                        needUpdate = true;
                                    }else if(key.startsWith('JT')){
                                        //To check if the data is for Turnover rate
                                        recs[0].Turnover_rate__c = dataValueMap.get(key);
                                        needUpdate = true;
                                    }
                                    else if(key.startsWith('EN')){
                                        //To check if the data is for Average wages
                                        if(key == 'ENAvgWageYear'){
                                            recs[0].Avg_wages_last_updated_on__c = dataValueMap.get(key);
                                            needUpdate = true;
                                        }
                                        else{
                                            recs[0].Average_wages__c = dataValueMap.get(key);
                                            needUpdate = true;
                                        }
                                    }
                                }
                                if(needUpdate){
                                    //If update is needed, add it to the list and call the DML Update
                                    recs[0].BLS_System_response__c = fieldResponseToSave;
                                    recs[0].NAICS_Code__c = account.NAICS_Code__c;
                                    blsRecordsToUpdate.add(recs[0]);
                                }
                                if(blsRecordsToUpdate!=null){
                                    return DmlHelper.performDML2(recs, DmlHelper.DML_UPDATE, 'BlsDataAPIQueueable', 'updateBLSRecordWithValues', 'Upserting BLS values', true);
                                }
                            } 
                            else{
                                //BLS records doesnt exist
                                Boolean needInsert = false;
                                PEOUW_BLS_Data__c blsRecordnew = new PEOUW_BLS_Data__c();
                                for(String key: dataValueMap.keySet()){
                                    if(key.startsWith('NB')){
                                        //To check if the data is Medical participation
                                        blsRecordnew.Medical_Participation__c = dataValueMap.get(key);
                                        needInsert = true;
                                    }else if(key.startsWith('JT')){
                                        //To check if the data is for Turnover rate
                                        blsRecordnew.Turnover_rate__c = dataValueMap.get(key);
                                        needInsert = true; 
                                    }
                                    else if(key.startsWith('EN')){
                                        //To check if the data is for Average wages
                                        if(key == 'ENAvgWageYear'){
                                            blsRecordnew.Avg_wages_last_updated_on__c = dataValueMap.get(key);
                                            needInsert = true; 
                                        }
                                        else{
                                            blsRecordnew.Average_wages__c = dataValueMap.get(key);
                                            needInsert = true; 
                                        }
                                    }
                                }
                                if(needInsert){
                                    //If Insert is needed, add it to the list and call the DML Insert
                                    //Mapping the Checklist to the BLS Data
                                    blsRecordnew.Name = checklist.Name;
                                    blsRecordnew.PEO_Underwriting_Checklist__c = checklist.Id;
                                    blsRecordnew.BLS_System_response__c = fieldResponseToSave;
                                    blsRecordnew.NAICS_Code__c = account.NAICS_Code__c;
                                    blsRecordsToInsert.add(blsRecordnew);
                                }
                                if(blsRecordsToInsert !=null){
                                    return DmlHelper.performDML2(blsRecordsToInsert, DmlHelper.DML_INSERT, 'BlsDataAPIQueueable', 'updateBLSRecordWithValues', 'Creating a BLS record', true);
                                }               
                            }
                            
                        }
                    }
        }
        return false;
    }
    
}