/* 
* Check for all of the sensitivities on an account
*
* History
* -------
11/02/2018 Dan Carmen       Created
06/15/2020 Brandon Vidro    Added createAPS() and deleteAPS() to create and delete Account Product Sensitivities Object on Acct
08/11/2021 Dan Carmen       Fix logging
12/22/2023 Dan Carmen       Add additional check for launching the queueable

*/
public without sharing class AcctSensitivityQueueable implements Queueable {
    
    public static Apex_Batch_Control__c getBatchControl() {
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('AcctSensitivityQueueable');
        return abc;
    } // getBatchControl
    
    public ErrorLog__c runLog;
    
    public Id[] acctIdsToProcessNext = new Id[]{};
        public Id[] acctIdsToProcessNow = new Id[]{};
            
            public AcctSensitivityQueueable(Id[] acctIds) {
                // log the id of the first record
                runLog = ErrorLog.logError('AcctSensitivityQueueable', 'LOG_DATA', 'LOG_DATA', (acctIds != null && !acctIds.isEmpty() ? acctIds[0] : ''), 'acctIds='+acctIds.size());
                runLog.BatchSize__c = (acctIds != null ? acctIds.size() : 0); 
                Apex_Batch_Control__c abc = getBatchControl();
                // get the number of records to process in a batch - default to 50
                Integer nbrRecsToProcess = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 10);
                // get the ids to process
                // pull the ids out of the passed in list until we get to the maximum
                while (acctIdsToProcessNow.size() <= nbrRecsToProcess && !acctIds.isEmpty()) {
                    acctIdsToProcessNow.add(acctIds.remove(0));
                } // while (acctIdsToProcessNow.size()
                // if there are any remaining ids, process next
                acctIdsToProcessNext = acctIds;
                addToLog('acctIdsToProcessNow='+acctIdsToProcessNow.size()+' acctIdsToProcessNext='+acctIdsToProcessNext.size());
            } // AcctSensitivityQueueable
    
    public void execute(QueueableContext context) {
        processAccts();
        inQueueable=true;
        launchQueueable(acctIdsToProcessNext);
    } // execute
    
    private String log = '';
    
    public Boolean inQueueable=false;
    
    public static Boolean LOG_QUERY=(Label.AcctSensitivity_LogQuery == 'Y');
    
    public void processAccts() {
        String query = getAcctQuery();
        query += ' where id in :acctIdsToProcessNow';
        if (LOG_QUERY) {
            addToLog('query='+query);
        }
        System.debug('query='+query);
        System.debug('** AcctSensitivityQueueable.processAccts ctctFldLabelMap='+ctctFldLabelMap+' acctFldLabelMap='+acctFldLabelMap);
        Account[] accts = Database.query(query);
        log = 'accts='+accts.size();
        
        populateAPSMap();
        
        Account[] acctsToUpdate = new Account[]{};
            //TODO: Add call to method to populate list of APS objects
            for (Account acct : accts) {
                checkAcct(acct, acctsToUpdate);
            } // for (Account acct
        
        log += '; acctsToUpdate='+acctsToUpdate.size();
        addToLog(log);
        ZipCheckOwner.SKIP_TRIGGERS=true;
        
        DmlHelper.performDML2(acctsToUpdate, DmlHelper.DML_UPDATE, 'AcctSensitivityQueueable', 'processAccts', 'Update Sensitivity List on Account', true);
        
        saveLog();
        
        createAPS();
        
        if(!(Test.isRunningTest())){
            deleteAPS();
        }
        
    } // processAccts
    
    public void checkAcct(Account acct, Account[] acctsToUpdate) {
        String curSensitivityList = (String.IsNotBlank(acct.SensitivityList__c) ? acct.SensitivityList__c : '');
        log+= '; acct='+acct.Id+' Name='+acct.Name+' curSensitivityList='+curSensitivityList;
        Set<String> sensitivitySet = new Set<String>();
        
        for (String tableName : REF_CTCT_TABLES) {
            Referral_Contact__c refCtct = (Referral_Contact__c)acct.getSobject(tableName);
            checkSensitivityFlds(refCtct, ctctFldLabelMap, sensitivitySet);
        } // for (String tableName : REF_CTCT_TABLES
        
        for (String tableName : REF_ACCT_TABLES) {
            Referral_Account__c refAcct = (Referral_Account__c)acct.getSobject(tableName);
            checkSensitivityFlds(refAcct, acctFldLabelMap, sensitivitySet);
        } // for (String tableName : REF_CTCT_TABLES
        
        Account_Product_Sensitivities__c aps = apsMap.get(acct.Id);
        checkSensitivityFlds(aps, apsFldLabelMap, sensitivitySet);
        
        String[] sensitivityListSorted = new String[]{};
            sensitivityListSorted.addAll(sensitivitySet);
        sensitivityListSorted.sort();
        
        String newSensitivityList = '';
        for (String sense : sensitivitySet) {
            if (String.isNotBlank(newSensitivityList)) {
                newSensitivityList += ',';
            }
            newSensitivityList += sense;
        }
        log += '; newSensitivityList='+newSensitivityList;
        if (newSensitivityList != curSensitivityList) {
            Account updateAcct = new Account(Id=acct.Id, SensitivityList__c=newSensitivityList);
            acctsToUpdate.add(updateAcct);
            log += '; updating the sensitivity list';
        }
    } // checkAcct
    
    public void checkSensitivityFlds(SObject rec, Map<String,String> fldLabelMap, Set<String> sensitivitySet) {
        if (rec != null) {
            for (String fldName : fldLabelMap.keySet()) {
                Boolean checkValue = (Boolean)rec.get(fldName);
                // add to the set if it's a true value
                if (checkValue != null && checkValue) {
                    sensitivitySet.add(fldLabelMap.get(fldName));
                }
            } // for (String fldName
        }
    } // checkSensitivityFlds
    
    public static String[] REF_CTCT_TABLES = new String[]{'Banker_Name_Ref__r','Broker_Name_Ref__r','CPA_Name_Ref__r','Insurance_Broker_Name_Ref__r'};
    public static String[] REF_ACCT_TABLES = new String[]{'Referral_National_Account__r'};
            
    public static String acctQuery = null;
    
    public static String getAcctQuery() {
        if (acctQuery == null) {
            acctQuery = 'Select Id, Name, SensitivityList__c ';
            for (String tableName : REF_CTCT_TABLES) {
                acctQuery += getRefSourceFlds(tableName,true, false, false);
            }
            for (String tableName : REF_ACCT_TABLES) {
                acctQuery += getRefSourceFlds(tableName,false, true, false);
            }
            //Call getRefSourceFlds one more time to populate apsFldLabelMap
            getRefSourceFlds(null, false, false, true);
            acctQuery += ' From Account ';
        } // if (acctQuery == null
        System.debug('getAcctQuery acctQuery='+acctQuery);
        return acctQuery;
    } // getAcctQuery
    
    // mappings of the sensitivity fields and their associated labels   
    public static Map<String,String> ctctFldLabelMap = new Map<String,String>();
    public static Map<String,String> acctFldLabelMap = new Map<String,String>();
    public static Map<String,String> apsFldLabelMap = new Map<String,String>();
    
    public static String getRefSourceFlds(String tableName, Boolean isCtctFld, Boolean isAcctFld, Boolean isAPSFld) {
        String query = ','+tableName+'.Id';
        for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
            if (String.isNotBlank(psf.Label__c) && ((isCtctFld && psf.RefCtct__c) || (!isCtctFld && psf.RefAcct__c))) {
                query += ' ,'+tableName+'.'+psf.FieldName__c;
                if (isCtctFld) {
                    ctctFldLabelMap.put(psf.FieldName__c, psf.Label__c);
                }
                if(isAcctFld) {
                    acctFldLabelMap.put(psf.FieldName__c, psf.Label__c);
                }
            }// if (String.isNotBlank(psf.Label__c) && ((isCtctFld))
            if (String.isNotBlank(psf.Label__c) && (isAPSFld && psf.APS__c)) {
                apsFldLabelMap.put(psf.FieldName__c, psf.Label__c);
            }
        } // for (ProductSensitivityFields__c psf
        return query;
    } // getRefSourceFlds
    
    public Map<Id, Account_Product_Sensitivities__c> apsMap = new Map<Id, Account_Product_Sensitivities__c>();
    
    //Get the Account Product Sensitivity objects related to the accounts
    public void populateAPSMap() {
        String query = 'SELECT Prospect_Client__c';
        if (!apsFldLabelMap.isEmpty()) {
        	for (String fieldName : apsFldLabelMap.keySet()) {
            	query += ', ' + fieldName;
        	}
        }
        query += ' FROM Account_Product_Sensitivities__c WHERE Prospect_Client__c IN :acctIdsToProcessNow';
        
        List<Account_Product_Sensitivities__c> apsList = Database.query(query);
        if (!apsList.isEmpty()) {
            for (Account_Product_Sensitivities__c aps : apsList) {
                apsMap.put(aps.Prospect_Client__c, aps);
            }
        }
        
    } // populateAPSMap
    
    //Create Account Product Sensitivity Object when Sensitivity List gets populated
    public void createAPS() {
        List<Account> acctsWithSens = new List<Account>();
        if(acctIdsToProcessNow != null && !(acctIdsToProcessNow).isEmpty()) {
            acctsWithSens = [Select Id, Name, SensitivityList__c, (Select Id FROM Account_Product_Sensitivities__r) FROM Account WHERE Id IN :acctIdsToProcessNow];
        }
        List<Account_Product_Sensitivities__c> acctProductSensToInsert = new List<Account_Product_Sensitivities__c>();
        if(acctsWithSens != null && !(acctsWithSens).isEmpty()) {
            for (Account a : acctsWithSens) {
                if((a.Account_Product_Sensitivities__r == null || (a.Account_Product_Sensitivities__r).size() != 1) && (a.SensitivityList__c != null || a.SensitivityList__c != '')) {
                    Account_Product_Sensitivities__c accProdSensInsert = new Account_Product_Sensitivities__c(Prospect_Client__c = a.id, Name= a.Name + ' Product Sensitivities');
                    acctProductSensToInsert.add(accProdSensInsert);
                } 
            }
        }
        if(acctProductSensToInsert != null && !(acctProductSensToInsert).isEmpty()) {
            DmlHelper.performDML2(acctProductSensToInsert, DmlHelper.DML_INSERT, 'AcctSensitivityQueueable', 'processAccts', 'Insert Account Product Sensitivity Related Object on Account', true);
        }
    }
    
    //Delete Account Product Sensitivity Object if Sensitivity List is blank
    public void deleteAPS() {
        List<Account> acctsWithSens = new List<Account>();
        if(acctIdsToProcessNow != null && !(acctIdsToProcessNow).isEmpty()) {
            acctsWithSens = [Select Id, Name, SensitivityList__c, (Select Id, No_Sensitivity_2__c FROM Account_Product_Sensitivities__r) FROM Account WHERE Id IN :acctIdsToProcessNow];
        }
        List<Account_Product_Sensitivities__c> acctProductSens = new List<Account_Product_Sensitivities__c>();
        List<Account_Product_Sensitivities__c> acctProductSensToDelete = new List<Account_Product_Sensitivities__c>();
        if(acctsWithSens != null && !(acctsWithSens).isEmpty()) {
            for (Account a: acctsWithSens) {
                if(a.Account_Product_Sensitivities__r != null && !(a.Account_Product_Sensitivities__r.isEmpty())) {
                    acctProductSens.addAll(a.Account_Product_Sensitivities__r);
                }
            }
        }
        if(acctProductSens != null && !(acctProductSens).isEmpty()) {
            for (Account_Product_Sensitivities__c aPS: acctProductSens) {
                if(aPS.No_Sensitivity_2__c == true) {
                    acctProductSensToDelete.add(aPS);
                }
            }
        }
        if(acctProductSensToDelete != null && !(acctProductSensToDelete).isEmpty()) {
            DmlHelper.performDML2(acctProductSensToDelete, DmlHelper.DML_DELETE, 'AcctSensitivityQueueable', 'processAccts', 'Delete Account Product Sensitivity Related Object on Account', true);
        }
    }
    
    // we don't want this to relaunch during a test - will fail
    public static Boolean RUNNING_TEST=Test.isRunningTest();
    
    public static void launchQueueable(Id[] acctIds) {
        Apex_Batch_Control__c abc = getBatchControl();
        System.debug('launchQueueable acctIds='+acctIds.size()+' testing='+Test.isRunningTest()+' abc='+abc);
        // enqueue this back up if there are more records to process and we're not running a test
        if (!RUNNING_TEST && abc != null && abc.Active__c && !acctIds.isEmpty()) {
            // re-enqueue the job - can't chain the jobs from tests
            AcctSensitivityQueueable asq = new AcctSensitivityQueueable(acctIds);
            System.enqueueJob(asq);
        }
    } // launchQueueable
    
    public void addToLog(String notesToAdd) {
        StringHelper.addNotesToField(runLog, 'Description__c', ErrorLog.DESCRIPTION_SIZE, notesToAdd, true); 
    } // addToLog
    
    public void saveLog() {
        Apex_Batch_Control__c abc = getBatchControl();
        if (runLog != null && abc != null && abc.SendCompletionEmail__c) {
            ErrorLog.saveErrorLog(runLog);
        }
    } // saveLog
    
    // if launching externally, see if we're already in a queueable context
    public static void checkLaunchQueueable(Id[] acctIds) {
        if (System.isQueueable() || (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs())) {
            // if we're already in a queueable context, or we're at the limit, just run inline
            AcctSensitivityQueueable asq = new AcctSensitivityQueueable(acctIds);
            asq.processAccts();
        } else {
            launchQueueable(acctIds);
        }
    } // checkLaunchQueueable
} // class AcctSensitivityQueueable