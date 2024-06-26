/*********************************************************************************************************************************
 Name:  DG_CampaignAttributionAnalyzer_Class
 Created by DemadnGen Inc.
==================================================================================================================================
Purpose: Contains logic for Campaign Attribution Analyzer.
==================================================================================================================================
History
-------
VERSION     AUTHOR          DATE(dd/mm/yyyy)    DETAIL      Description
1.0         Rick Segura     10/05/2018          Created     Created
1.1         Gram Bischof    19/03/2019         Updated     Updated
            Dan Carmen       08/09/2023          Increment API
*********************************************************************************************************************************/

public without sharing class DG_CampaignAttributionAnalyzer_Class implements TriggerInterface2 {
    
    public static Boolean SKIP_TRIGGER=false;
    public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
        System.debug('DG_CampaignAttributionAnalyzer_Class.triggerCheckAllFirst recs='+(recs != null ? recs.size() : -1));
        if (!SKIP_TRIGGER && recs != null && !recs.isEmpty()) {
            if (isAfter && recs[0].getSObjectType() == Opportunity.sObjectType) {
                system.debug('checkBeforeLoop OpptyAfter instance found for DG_CampaignAttributionAnalyzer_Class');
                //ProcessCampaignAttributionOnInsertUpdate((List<Opportunity>)recs, (Map<Id,Opportunity>)oldMap);
                List<Opportunity> theOpportunityList = (List<Opportunity>)recs;
                Map<Id,Opportunity> theoldMap = (Map<Id,Opportunity>)oldMap;
                Set<Id> theOppIdSet = new Set<Id>();
                map<Id, Boolean> IsWonMap = new map<Id, Boolean>();
                map<Id, Decimal> AmountMap = new map<Id, Decimal>();
                map<Id, Date> closeDateMap = new map<Id, Date>();
                map<Id,Id> AccountIdMap = new map<Id, Id>();
                for(Opportunity theOpp : theOpportunityList) {
                    theOppIdSet.add(theOpp.Id);
                }
                if(oldMap != null) {
                    for(Opportunity theOpp : theoldMap.values()) {
                        IsWonMap.put(theOpp.Id,theOpp.IsWon);
                        AmountMap.put(theOpp.Id,theOpp.Amount);
                        closeDateMap.put(theOpp.Id,theOpp.CloseDate);
                        AccountIdMap.put(theOpp.Id,theOpp.AccountId);
                    }
                }
                ProcessCampaignAttributionOnInsertUpdate(theOppIdSet,IsWonMap,AmountMap,closeDateMap,AccountIdMap);
            }
        }
    }
    
    public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
    public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
    
    /***************************************************************************
     Purpose: Simple system debug function for reducing keystrokes
     Parameters: string, obj
     Returns: NONE
     Throws [Exceptions]: NONE 
    ****************************************************************************/
    
    private static void sysdbg(string objName, object obj){
        system.debug('### ' + objName + ': ' + obj);    
    }
    
    /***************************************************************************
     Purpose: Returns CAA settings for use in CAA logic
     Parameters: NONE
     Returns: DG_CAA_Settings__mdt
     Throws [Exceptions]: NONE 
    ****************************************************************************/
    public static DG_CAA_Settings__mdt getCAASettings(){
        
        DG_CAA_Settings__mdt CAAsettings = new DG_CAA_Settings__mdt();
        
        //  Grab CAA settings from DG_CAA_Settings custom metadata
        try{
            CAAsettings = 
                [SELECT MasterLabel,
                        Label,
                        QualifiedApiName,
                        Attribution_Window__c,
                        //Batch_Criteria__c,
                        Batch_Email_Notification__c,
                        Batch_Email_Notification_Recipient__c,
                        //Batch_Size__c,
                        Enable__c,
                        First_Position__c,
                        Include_Accelerators_for_Bookings__c,
                        Include_Non_Response_Status__c,
                        Influence_Source__c,
                        Last_Position__c,
                        Model_Bookings_First_Touch__c,
                        Model_Bookings_Last_Touch__c,
                        Model_Bookings_Linear__c,
                        Model_Bookings_Position_Based__c,
                        Model_Bookings_Weighted__c,
                        Model_Pipeline_First_Touch__c,
                        Model_Pipeline_Last_Touch__c,
                        Model_Pipeline_Linear__c,
                        Model_Pipeline_Position_Based__c,
                        Model_Pipeline_Weighted__c
                 FROM DG_CAA_Settings__mdt WHERE MasterLabel = 'MasterSettings'];
        }catch(exception e){
            system.debug('### An exception occurred: ' + e.getMessage() + ' on DG_CampaignAttributionAnalyzer_Class.getCAASettings()');
        }
        return CAAsettings;
    }
    
    
    /***************************************************************************
     Purpose: Returns map of CAA Campaign weights for Weighted models
     Parameters: NONE
     Returns: map<String, DG_CAA_Campaign_Weight__mdt>
     Throws [Exceptions]: NONE
    ****************************************************************************/
    public static map<String, DG_CAA_Campaign_Weight__mdt> getCAACampaignWeights(){
        map<String, DG_CAA_Campaign_Weight__mdt> mapWeights = new map<String, DG_CAA_Campaign_Weight__mdt>();
        try{
            DG_CAA_Campaign_Weight__mdt[] tmp = [SELECT Label, Weight__c FROM DG_CAA_Campaign_Weight__mdt];
            
            for(DG_CAA_Campaign_Weight__mdt x: tmp){
                mapWeights.put(x.Label, x);
            }   
        }catch(exception e){
            system.debug('### An exception occurred: ' + e.getMessage() + ' on DG_CampaignAttributionAnalyzer_Class.getCAACampaignWeights()');
        }
        
        return mapWeights;
    }
    
    
    
    /***************************************************************************
     Purpose: Returns set of Opportunity Lead Source values to Exclude from CAA
     Parameters: NONE
     Returns: set<String>
     Throws [Exceptions]: NONE
    ****************************************************************************/
    public static set<string> getOpportunityLeadSourceExclusions(){
        set<string> exclusions = new set<string>();
        try{
            DG_CAA_Opportunity_LeadSource_Exclusions__mdt[]  tmp = [SELECT Label FROM DG_CAA_Opportunity_LeadSource_Exclusions__mdt];
            
            for(DG_CAA_Opportunity_LeadSource_Exclusions__mdt x: tmp){
                exclusions.add(x.Label.toLowerCase());
            }   
        }catch(exception e){
            system.debug('### An exception occurred: ' + e.getMessage() + ' on DG_CampaignAttributionAnalyzer_Class.getOpportunityLeadSourceExclusions()');
        }
        
        return exclusions;
        
    }
    
    public static void ProcessCampaignAttributionOnInsertUpdate (Set<Id> theOppIdSet, map<Id, Boolean> IsWonMap,map<Id, Decimal> AmountMap,map<Id, Date> closeDateMap,map<Id,Id> AccountIdMap) {
       if (Test.isRunningTest() || System.isBatch() || System.isFuture()) {
          ProcessCampaignAttributionOnInsertUpdateNow(theOppIdSet,IsWonMap,AmountMap,closeDateMap,AccountIdMap);
       } else {
          ProcessCampaignAttributionOnInsertUpdateFuture(theOppIdSet,IsWonMap,AmountMap,closeDateMap,AccountIdMap);
       }
    } // ProcessCampaignAttributionOnInsertUpdate 
    
    @future
    public static void ProcessCampaignAttributionOnInsertUpdateFuture (Set<Id> theOppIdSet, map<Id, Boolean> IsWonMap,map<Id, Decimal> AmountMap,map<Id, Date> closeDateMap,map<Id,Id> AccountIdMap) {
       ProcessCampaignAttributionOnInsertUpdateNow (theOppIdSet, IsWonMap,AmountMap,closeDateMap,AccountIdMap);
    }

    /***************************************************************************
     Purpose:Builds list of opportunities to process
     Parameters: NONE
     Returns: NONE
     Throws [Exceptions]: NONE
    ****************************************************************************/
    //public static void ProcessCampaignAttributionOnInsertUpdate (list<Opportunity> listNew, map<Id, Opportunity> mapOld) {
    public static void ProcessCampaignAttributionOnInsertUpdateNow (Set<Id> theOppIdSet, map<Id, Boolean> IsWonMap,map<Id, Decimal> AmountMap,map<Id, Date> closeDateMap,map<Id,Id> AccountIdMap) {
        system.debug('### Entered DG_CampaignAttributionAnalyzer_Class.ProcessCampaignAttributionOnInsertUpdate');
        Set<string> oppLSExclusions = getOpportunityLeadSourceExclusions();
        list<Opportunity> listNew = [SELECT Id,Amount,CreatedDate,IsWon,CloseDate,AccountId,LeadSource FROM Opportunity WHERE Id IN : theOppIdSet];
        //map<Id, Opportunity> mapOld;
        try{
            list<Opportunity> listOpp2Process = new list<Opportunity>();
            map<Id, Opportunity> mapOpp = new map<Id, Opportunity>();
            list<Id> listAccountId = new list<Id>();
            set<Id> setOppBookings = new set<Id>();
            map<Id, Decimal> futuremapOpp = new map<Id, Decimal>();
            list<Opportunity> listOppProcess = new list<Opportunity>();
            if(IsWonMap == Null){
                for (Opportunity tn : listNew){
                    if(tn.AccountId <> Null && !(oppLSExclusions.contains(tn.LeadSource.ToLowerCase()))){
                        listOpp2Process.add(tn);
                        mapOpp.put(tn.Id, tn);
                    }
                }
            }else{
                for (Opportunity tn : listNew){
                    //Opportunity to = mapOld.get(tn.Id);     
                    if (tn.AccountId<>Null){
                        //System.debug(mapOld);
                        System.debug('!!! new Amount' + tn.Amount);
                        //System.debug('!!! old Amount' + to.Amount);
                        //System.debug(tn.Amount <> to.Amount);
                        //if ( (tn.IsWon <> to.IsWon || tn.Amount <> to.Amount || (tn.IsWon && tn.CloseDate <> to.CloseDate) || tn.AccountId <> to.AccountId ) &&
                        if ( (tn.IsWon <> IsWonMap.get(tn.Id) || tn.Amount <> AmountMap.get(tn.Id) || (tn.IsWon && tn.CloseDate <> closeDateMap.get(tn.Id)) || tn.AccountId <> AccountIdMap.get(tn.Id)) &&
                        !(oppLSExclusions.contains(tn.LeadSource.ToLowerCase()))){
                            //System.debug(String.valueOf(tn.Amount) + ' != ' + String.valueOf(to.Amount));
                            listOpp2Process.add(tn);
                            mapOpp.put(tn.Id, tn);
                            listAccountId.add(tn.AccountId);
                        } else if( !(oppLSExclusions.contains(tn.LeadSource.ToLowerCase())) && tn.Amount <> AmountMap.get(tn.Id)){
                            // used for OpportunityLineItems as calculation is done post Trigger.after
                            listOppProcess.add(tn);
                            //futuremapOpp.put(tn.Id, AmountMap.get(tn.Id));       
                        }
                        
                    }
                }
            }
            
            system.debug('## listOpp2Process.IsEmpty(): '+listOpp2Process.IsEmpty());
            system.debug('## listOppProcess.IsEmpty(): '+listOppProcess.IsEmpty());
            system.debug('## futuremapOpp.IsEmpty(): '+futuremapOpp.IsEmpty());
            system.debug('## futuremapOpp.Size(): '+futuremapOpp.Size());
           
            if(!listOpp2Process.IsEmpty()){
                PopulateOpportunityCampaignAttribution(listOpp2Process);
                //futurePopulateOpportunityCampaignAttribution2(theOppIdSet);
            }
            System.debug(listOppProcess);
            if (listOppProcess.size() > 0){
                futurePopulateOpportunityCampaignAttribution(listOppProcess);    
            }
        }catch(exception e){system.debug('###An exception occurred: ' + e.getMessage() + ' on DG_Opp_Campaign_Attribution_Class.ProcessCampaignAttributionOnInsertUpdate()');}
    }
          
    public static void PopulateOpportunityCampaignAttribution (list<Opportunity> listOpp) {
        system.debug('### Entered DG_CampaignAttributionAnalyzer_Class.PopulateOpportunityCampaignAttribution');
        
        
        try{ // main error handler
            
            // assume CAA is disabled                       
            Boolean IsEnabled = false;
            Boolean IncludeAccelerators = false;
            Boolean IncludeNonResponses = false;
            Integer AttrWindow;
            String InfluenceSource;
            // acquire CAA settings
            DG_CAA_Settings__mdt CASettings = getCAASettings();
            sysdbg('CASettings', CASettings);
            
            try{  // set CAA enablement per settings
                IsEnabled = CASettings.Enable__c;
                AttrWindow = Integer.ValueOf(CASettings.Attribution_Window__c);
                IncludeAccelerators = CASettings.Include_Accelerators_for_Bookings__c;  
                InfluenceSource = CASettings.Influence_Source__c;   
                IncludeNonResponses = CASettings.Include_Non_Response_Status__c;    
            }catch(exception e){}
                
            sysdbg('CASettings.Enable__c', CASettings.Enable__c);
            sysdbg('CASettings.Include_Accelerators_for_Bookings__c', CASettings.Include_Accelerators_for_Bookings__c);
            sysdbg('CASettings.Attribution_Window__c', CASettings.Attribution_Window__c);

            if(IsEnabled){
                
                Date AttrDateLower;     // Min date for use in campaign member eligibility
                Date AttrDateUpper;     // Max date for use in campaign member eligibility
                Date tempUBdate;        // temporary Upper Bound Date
                set<Id> setOpps2Process = new set<Id>();
                set<Id> setAccountId = new set<Id>();  // temp set of Account IDs for Hybrid and AccountContact...means to get contacts
                set<Id> setContactId = new set<Id>();  // list of eligible contacts for CAA
                set<Id> setOpportunityId = new set<Id>();  // temp list of Opp Ids for SOQL query
                
                for(Opportunity opp: listOpp){
                    
                    setOpportunityId.add(opp.Id);  // Add opp ID to set of IDs
                    
                    // seek oldest opportunity created date
                    if(AttrDateLower == null){
                        AttrDateLower = opp.CreatedDate.date();
                    }else if(opp.CreatedDate < AttrDateLower){
                        AttrDateLower = opp.CreatedDate.date();
                    }
                    
                    // seek upper bound comparison date for campaign member eligibility
                    tempUBdate = (IncludeAccelerators && opp.IsWon) ? opp.CloseDate : opp.CreatedDate.date();
                    if(AttrDateUpper == null){
                        AttrDateUpper = tempUBdate;
                    }else if(tempUBdate > AttrDateUpper){
                        AttrDateUpper = tempUBdate;
                    }
                    
                    sysdbg('$$ IncludeAccelerators', IncludeAccelerators);
                    sysdbg('$$ tOpp.IsWon', opp.IsWon);
                    sysdbg('$$ tOpp.CloseDate', opp.CloseDate);
                    sysdbg('$$ tempUBdate', tempUBdate);
                    
                    // Assume use of all Account Contacts fro Hybrid & AccountContact option
                    if(opp.AccountID != null) setAccountId.add(opp.AccountID);
                }
                sysdbg('$$ setOpportunityId', setOpportunityId.size());
                Map<Id,CAA_Record__c> ocaToDelete = new Map<Id,CAA_Record__c>([Select Id from CAA_Record__c where Opportunity__c in :setOpportunityId]);
                list<Id> ocaToPurge = new list<Id>();
                        
                if(!ocaToDelete.IsEmpty()){
                    // change threshold to custom label
                    if(ocaToDelete.size()<=250){
                        database.delete(ocaToDelete.values(),false);
                        try{
                            Database.emptyRecycleBin(new List<ID>(ocaToDelete.keySet()));
                        }catch(exception e){
                            System.debug(e.getMessage());
                            System.debug(e.getStackTraceString());
                        }
                    }else{
                        //DG_BatchDeleteProcessor BatchDeleteObject = new DG_BatchDeleteProcessor(ocaToDelete.values());
                        //Database.executeBatch(BatchDeleteObject); 
                        System.enqueueJob(new DG_BatchDeleteProcessorQueueable(ocaToDelete));
                    }
                }   
                
                // finalize campaign member search dates
                if(AttrDateLower <> null){
                    if(AttrDateUpper == null) AttrDateUpper = AttrDateLower;
                    AttrDateLower = AttrDateLower - AttrWindow;
                }               
                sysdbg('AttrDateLower', AttrDateLower);
                sysdbg('AttrDateUpper', AttrDateUpper);

                map<Id, set<Id>> mapOppIdConId = new map<Id, set<Id>>();
                if(InfluenceSource== 'Hybrid' || InfluenceSource == 'OpportunityContact'){
                     
                    List<OpportunityContactRole> oppContactRoles = [SELECT Id, ContactId, Contact.Email, OpportunityId,Opportunity.AccountId,Opportunity.CloseDate FROM OpportunityContactRole
                                                                    WHERE OpportunityId IN : setOpportunityId]; 
                    for(OpportunityContactRole theOCR : oppContactRoles){
                        if(!mapOppIdConId.containsKey(theOCR.OpportunityId)) mapOppIdConId.put(theOCR.OpportunityId,new Set<Id>{theOCR.ContactId}); 
                        mapOppIdConId.get(theOCR.OpportunityId).add(theOCR.ContactId);    
                        setContactId.add(theOCR.ContactId);
                        if(theOCR.Opportunity.AccountId != null ) setAccountId.remove(theOCR.Opportunity.AccountId);
                    }
                }

                map<Id, set<Id>> mapActIdConId = new map<Id, set<Id>>();
                if(InfluenceSource== 'Hybrid' || InfluenceSource == 'AccountContact'){
                    
                    List<Contact> theConList  = [SELECT Id,AccountId FROM Contact WHERE AccountId IN : setAccountId];
                    for(Contact theCon : theConList){
                        if(!mapActIdConId.containsKey(theCon.AccountId)) mapActIdConId.put(theCon.AccountId,new Set<Id>{theCon.Id}); 
                        mapActIdConId.get(theCon.AccountId).add(theCon.Id);
                        setContactId.add(theCon.Id);
                    }
                    
                    if(mapActIdConId.size() > 0){
                        for(Opportunity tOpp: listOpp){
                            if(mapOppIdConId.containsKey(tOpp.Id)){
                                if(mapActIdConId.containsKey(tOpp.AccountId)){
                                    mapOppIdConId.get(tOpp.Id).addAll(mapActIdConId.get(tOpp.AccountId));
                                }
                            }else{
                                mapOppIdConId.put(tOpp.Id, mapActIdConId.get(tOpp.AccountId));
                                setOpps2Process.add(tOpp.Id);
                            }
                        }
                    }
                    
                } 
                sysdbg('setOpps2Process.size()', setOpps2Process.size());
                sysdbg('mapOppIdConId.size()', mapOppIdConId.size()); 
                sysdbg('setContactId.size()', setContactId.size()); 
                
                // Begin processing opportunities
                if(!mapOppIdConId.isEmpty()){
                    
                    //  Determine CampaignMember comparison date base on CAA settings
                    String dateField = (IncludeNonResponses) ? 'CreatedDate' : 'FirstRespondedDate';
                    
                    CampaignMember PipeFirstCampaign;
                    CampaignMember PipeLastCampaign;
                    CampaignMember BookFirstCampaign;
                    CampaignMember BookLastCampaign;
                    set<CampaignMember> setPipelineCM = new set<CampaignMember>();
                    set<CampaignMember> setBookingsCM = new set<CampaignMember>();
                    Decimal PipelineTotalWeight = 0;
                    Decimal BookingsTotalWeight = 0;
                    
                    map<Id, list<CampaignMember>> mapCIDCMs = PopulateOpportunityCampaignAttributionHelper(dateField,IncludeNonResponses,AttrDateLower,AttrDateUpper,setContactId);
                    map<Id,list<CampaignMember>> mapOppIdListCampaignMembers = new map<Id,list<CampaignMember>>();
                    map<Id,Id> mapConIdOppId = new map<Id,Id>();
                    set<Id> CampaignIds = new set<Id>();
                    sysdbg('mapOppIdConId',mapOppIdConId);
                    sysdbg('mapCIDCMs',mapCIDCMs);
                    
                    for(Id OppId : mapOppIdConId.Keyset()) {
                        for(Id ConId : mapOppIdConId.get(OppID)) {
                            if(mapCIDCMs.containsKey(ConId)) {
                                for(CampaignMember theCM : mapCIDCMs.get(ConId)) {
                                    if(!mapOppIdListCampaignMembers.containskey(OppId)) mapOppIdListCampaignMembers.put(OppId,new list<CampaignMember>());
                                    mapOppIdListCampaignMembers.get(OppId).add(theCM);
                                    CampaignIds.add(theCM.Id);
                                }
                            }
                        }
            
                    }

                    List<CAA_Record__c> theCAARecordsList = new List<CAA_Record__c>();
					List<CAA_Record__c> insertCAARecordsList = new List<CAA_Record__c>();
                    List<Opportunity> theOppList = [Select Id, Amount, CreatedDate, CloseDate, IsWon from Opportunity WHERE Id IN : mapOppIdListCampaignMembers.keyset() and NSS_Source__c =: 'Inbound'];
                    sysdbg('theOppList', theOppList);
                    for(Opportunity theOpp : theOppList) {
                        theCAARecordsList = DG_CampaignAttributionAnalyzerHelper.createCAARecords(mapOppIdListCampaignMembers.get(theOpp.Id),
                                                                                  theOpp,CASettings,datefield,theOpp.IsWon);
                    	insertCAARecordsList.addAll(theCAARecordsList);
                    }
                    sysdbg('insertCAARecordsList', insertCAARecordsList);
                    if(insertCAARecordsList.size() > 0) insert insertCAARecordsList;    
                    
                }  //  !mapOppIdConId.isEmpty()
                
            } // IsEnabled
            
            
        }catch(exception e){
            system.debug('###An exception occurred: ' + e.getMessage() + ' on DG_CampaignAttributionAnalyzer_Class.PopulateOpportunityCampaignAttribution() ' + e.getStackTraceString());
        } // END:  main error handler
    }   
    
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/ 
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/ 
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/ 
    
    /***************************************************************************
     Purpose:   Build list of Opps in a given date range and sends them to 
                Attribution process (primarily for processing historical
                opportunity records)
     Parameters: Date(start), Date (End)
     Returns: NONE
     Throws [Exceptions]: NONE
    ****************************************************************************/
    public static void ProcessCampaignAttributionUsingDateRange(Date pStartDate, Date pEndDate){
        system.debug('### Entered DG_CampaignAttributionAnalyzer_Class.ProcessCampaignAttributionUsingDateRange');
        try{
            
            Date EndDate = pEndDate.addDays(1);
            Boolean IsMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');                   
            
            set<string> oppLSExclusions = getOpportunityLeadSourceExclusions();
            
            String sqlstring;
            
            if(IsMultiCurrency){
                sqlstring = 'Select Id, AccountId, IsWon, CreatedDate, CloseDate, Amount, CurrencyIsoCode from Opportunity where CreatedDate >= :pStartDate AND CreatedDate < :EndDate AND IsDeleted = FALSE AND LeadSource NOT IN :oppLSExclusions ';
            }else{
                sqlstring = 'Select Id, AccountId, IsWon, CreatedDate, CloseDate, Amount from Opportunity where CreatedDate >= :pStartDate AND CreatedDate < :EndDate AND IsDeleted = FALSE AND LeadSource NOT IN :oppLSExclusions';
            }

            list<Opportunity> listOpportunity = new list<Opportunity>();
                
            try{
                listOpportunity = Database.query(sqlstring);
            }catch(exception e){}
                
            system.debug('### Batch Size: ' + listOpportunity.size());
            
            if(listOpportunity.size() > 0){
                PopulateOpportunityCampaignAttribution(listOpportunity);
            }
        
        }catch(exception e){system.debug('###An exception occurred: ' + e.getMessage() + ' on DG_CampaignAttributionAnalyzer_Class.ProcessCampaignAttributionUsingDateRange()');}
    }
    
    
    
    /***************************************************************************
     Purpose:   Build list of Opps with Opportunity Contact Role record changes
                and sends them to the Attribution process
     Parameters: NONE
     Returns: NONE
     Throws [Exceptions]: NONE
    ****************************************************************************/
    public static void ProcessCampaignAttributionOnOppRoleChanges(){
        system.debug('### Entered DG_CampaignAttributionAnalyzer_Class.ProcessCampaignAttributionOnOppRoleChanges');
        try{
            Date vYesterday = date.today() - 1;
            
            set<string> oppLSExclusions = getOpportunityLeadSourceExclusions();
            list<Id> listOID = new list<Id>(); 

            if(!test.isRunningTest()){
                for(OpportunityContactRole ocr : [Select Id, OpportunityId, ContactId From OpportunityContactRole where DAY_ONLY(CreatedDate) >= :vYesterday AND Opportunity.LeadSource NOT IN :oppLSExclusions]){      
                    listOID.add(ocr.OpportunityId);
                }
            }else{
                for(OpportunityContactRole ocr : [Select Id, OpportunityId, ContactId From OpportunityContactRole where DAY_ONLY(CreatedDate) >= :vYesterday AND Opportunity.LeadSource NOT IN :oppLSExclusions and Opportunity.Name = 'TestOpportunityForCampaignAttribution']){       
                    listOID.add(ocr.OpportunityId);
                }   
            }        
            
            list<Opportunity> listOpportunity = new list<Opportunity>();
            
            if(!listOID.isEmpty()){
                Boolean IsMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');   
                
                try{
                                     
                    String sqlstring;
                        
                    if(IsMultiCurrency){
                        sqlstring = 'Select Id, AccountId, IsWon, CreatedDate, CloseDate, Amount, LeadSource, CurrencyIsoCode from Opportunity where Id in :listOID';
                    }else{
                        sqlstring = 'Select Id, AccountId, IsWon, CreatedDate, CloseDate, Amount, LeadSource from Opportunity where Id in :listOID';
                    }
            
                    listOpportunity = Database.query(sqlstring);
            
                }catch(exception e){}
            }       
            
            system.debug('###Opportunity Count: ' + listOpportunity.size());
            
            if(listOpportunity.size() > 0){
                PopulateOpportunityCampaignAttribution(listOpportunity);
            }
        }catch(exception e){system.debug('###An exception occurred: ' + e.getMessage() + ' on DG_CampaignAttributionAnalyzer_Class.ProcessCampaignAttributionOnOppRoleChanges()');}
    }   
    
    
    
    
    /***************************************************************************
     Purpose:   Build list of Opps created by Lead Conversion and sends them to 
                the Attribution process
     Parameters: NONE
     Returns: NONE
     Throws [Exceptions]: NONE
    ****************************************************************************/
    public static void ProcessCampaignAttributionLeadConversion(list<lead> leadList){
        system.debug('### Entered DG_CampaignAttributionAnalyzer_Class.ProcessCampaignAttributionLeadConversion');
        
        set<Id> convertedContactIDs = new set<Id>();
        set<Id> setOppIDs = new set<Id>();
        set<string> oppLSExclusions = getOpportunityLeadSourceExclusions();
        
        for(Lead ld : leadList){
            if(ld.IsConverted && ld.ConvertedContactID <> null){
                convertedContactIDs.add(ld.ConvertedContactID);
            }
            if(ld.IsConverted && ld.ConvertedOpportunityID <> null){
                setOppIDs.add(ld.ConvertedOpportunityID);
            }
        }
        
        system.debug('## convertedContactIDs.size(): '+convertedContactIDs.size());
        
        DateTime dt = System.Now().addHours(-1);
        
        list<OpportunityContactRole> listOCR = new list<OpportunityContactRole>([SELECT Id, OpportunityID FROM OpportunityContactRole WHERE IsDeleted=false AND ContactID IN :convertedContactIDs AND CreatedDate >= :dt AND Opportunity.LeadSource NOT IN :oppLSExclusions]);
        system.debug('## listOCR.size(): '+listOCR.size());
        
        
        if(listOCR.size() > 0){
            for(OpportunityContactRole ocr:listOCR){
                setOppIDs.add(ocr.OpportunityID);
            }
        }
        system.debug('## setOppIDs.size(): '+setOppIDs.size());
        
        Boolean IsMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
        list<Opportunity> listOpps = new list<Opportunity>();
        
        if(setOppIDs.size() > 0){
            
            try{
                String sqlstring;
                if(IsMultiCurrency){
                    sqlstring = 'SELECT Id, Amount, AccountId, IsWon, CreatedDate, LeadSource, CurrencyIsoCode, CloseDate  FROM Opportunity WHERE Id IN :setOppIDs';
                    
                }else{
                    sqlstring = 'SELECT Id, Amount, AccountId, IsWon, CreatedDate, LeadSource, CloseDate FROM Opportunity WHERE Id IN :setOppIDs';
                }
                listOpps = Database.query(sqlstring);
                //ProcessCampaignAttributionOnInsertUpdate(listOpps, Null);
                Set<Id> theOppIdSet = new Set<Id>();
                for(Opportunity theOpp : listOpps) {
                    theOppIdSet.add(theOpp.Id);
                }
                ProcessCampaignAttributionOnInsertUpdate(theOppIdSet,null,null,null,null);
            }catch(exception e){system.debug('###An exception occurred: ' + e.getMessage() + ' on DG_CampaignAttributionAnalyzer_Class.ProcessCampaignAttributionLeadConversion()');}
            
        }
        
    }
    
    public static map<Id, list<CampaignMember>> PopulateOpportunityCampaignAttributionHelper(String Datefield,Boolean IncludeNonResponses,Date AttrDateLower,Date AttrDateUpper,Set<Id> setContactId) {
        // Builds SOQL string for CampaignMember list of records
        String whereCM = (!IncludeNonResponses) ? ' HasResponded=true AND ': ''; 
        String dateFieldDateOnly = (dateField == 'FirstRespondedDate') ? 'FirstRespondedDate' : 'DAY_ONLY(' + dateField + ')';
        String orderBy = (dateField == 'FirstRespondedDate') ? 'FirstRespondedDate, CreatedDate' : 'CreatedDate';
        String soqlCM = 'Select Id, Status, ContactId, CampaignId, CreatedDate, FirstRespondedDate,';
        //if(Datefield != 'CreatedDate') soqlCM = soqlCM + Datefield + ', ';
        soqlCM = soqlCM + 'Campaign.Type From CampaignMember WHERE ' + whereCM +
                dateFieldDateOnly  + ' >= : AttrDateLower  AND '  + dateFieldDateOnly 
                + ' <= :  AttrDateUpper AND ContactId IN :setContactId Order by ' + orderBy ; 
        sysdbg('soqlCM', soqlCM);
        
        // Get list of CampaignMember records
        list<CampaignMember> listConCMs = Database.Query(soqlCM);
        sysdbg('listConCMs.size()', listConCMs.size());
        map<Id, list<CampaignMember>> mapConIdCM = new map<Id, list<CampaignMember>>();         
        
        // Create map of Contacts with list of CampaignMembers
        if(listConCMs.size()>0){
            integer CMCount = 0;
            for(CampaignMember cm: listConCMs){
                if(!mapConIdCM.containsKey(cm.ContactId)) mapConIdCM.put(cm.ContactId,new List<CampaignMember>());
                mapConIdCM.get(cm.ContactId).add(cm);
            }
            return mapConIdCM;
        }   
        return mapConIdCM;
    }
    
    //@future
    //public static void futurePopulateOpportunityCampaignAttribution(Map<Id,Decimal> theOppMap){
    public static void futurePopulateOpportunityCampaignAttribution(List<Opportunity> listOppProcess){
        /*List<Opportunity> listOpp2Process = new List<Opportunity>();
        for(Opportunity theOpp : [SELECT Id,Amount,CreatedDate,IsWon,CloseDate,AccountId FROM Opportunity WHERE Id IN : theOppMap.keySet() AND NSS_Source__c = 'Inbound']) {
            System.debug(String.valueOf(theOppMap.get(theOpp.Id)) + ' != ' + String.valueOf(theOpp.Amount));
            if(theOppMap.get(theOpp.Id) != theOpp.Amount) {
                listOpp2Process.add(theOpp);
            }
        }*/
        PopulateOpportunityCampaignAttribution(listOppProcess);     
    }    
}