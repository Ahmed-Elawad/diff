/* 
 * Methods for the Asset object.
 *
 * History
 * -------
   07/11/2012 Dan Carmen        Created - merged code from UpdateTaskEvent
   02/01/2013 Carrie Marciano   Added logic for TAA plan codes to check for plan cancel dates and update TAA Support Ref Obj
   08/30/2016 Lynn Michels      Added logic for Payroll plan codes to update fields on the Account
   11/03/2016 Lynn Michels      Backing out code for Payroll plan codes to update fields on the Account per Leslie
   05/12/2017 Lynn Michels      populate the Client Start Date on Reference HRS Term/Transfer
   12/08/2017 Dan Carmen      Consolidate code
   
 */
public with sharing class AssetMethods {

   /** For if there's no bundle/package setup for an opportunity (according to the information from HRIS) */
   public static String NO_BUNDLE='No Bundle';
   
   // So we can turn this off and on - currently not being used.
   public static Boolean PERFORM_PROD_CHECK=Label.Asset_CheckProduct2 == 'Y';
   
   public static Asset[] checkForProds = new Asset[]{};

   public static void checkBeforeTrigger(Asset asst, Asset oldAsst) {
      if (PERFORM_PROD_CHECK && 
             (asst.Product2Id == null
               || (oldAsst == null) 
               || (asst.Product_Plan_Code__c != oldAsst.Product_Plan_Code__c
                       || asst.Admin_By__c != oldAsst.Admin_By__c
                       || asst.Ext_App_Id__c != oldAsst.Ext_App_Id__c
                       || asst.Plan_Type__c != oldAsst.Plan_Type__c))) {
         System.debug('checkBeforeTrigger checking update for '+asst.Name);
         checkForProds.add(asst);
      }
   } // checkBeforeTrigger

   public static void processBeforeTrigger() {
      if (!checkForProds.isEmpty()) {
         findProducts(checkForProds);
         checkForProds.clear();
      }
   }
   
   /** Try to link a Product2 record to the passed in Assets.
    */
   public static void findProducts(Asset[] assts) {
      // get all of the query fields
      Set<String> adminBySet = new Set<String>();
      Set<String> extAppIdSet = new Set<String>();
      Set<String> planTypeSet = new Set<String>();
      Set<String> planCodeSet = new Set<String>();
      
      Asset[] checkAssts = new Asset[]{};
      for (Asset asst : assts) {
         // make sure at least one of the fields is populated
         if (asst.Admin_By__c != null || asst.Ext_App_Id__c != null || asst.Plan_Type__c != null || asst.Product_Plan_Code__c != null) {
            System.debug('checking Asset '+asst.Name);
            checkAssts.add(asst);
            // clear the value that's there
            asst.Product2Id = null;
            addIfNotNull(asst.Admin_By__c,adminBySet);
            addIfNotNull(asst.Ext_App_Id__c,extAppIdSet);
            addIfNotNull(asst.Plan_Type__c,planTypeSet);
            addIfNotNull(asst.Product_Plan_Code__c,planCodeSet);
         } // if (asst.Admin_By__c
      } // for (Asset asst
      
      // continue as long as there is at least one value to search for
      if (!checkAssts.isEmpty()) {
        System.debug('adminBySet='+adminBySet);
        System.debug('extAppIdSet='+extAppIdSet);
        System.debug('planTypeSet='+planTypeSet);
        System.debug('planCodeSet='+planCodeSet);
         Product_Mapping__c[] mappings = getMappings(adminBySet,extAppIdSet,planTypeSet,planCodeSet);
         if (!mappings.isEmpty()) {
            // try to match asset to product
            for (Asset asst : checkAssts) {
               findMapping(asst,mappings);
            } // for (Asset asst
         } // if (!mappings.isEmpty
      } // if (!checkAssts.isEmpty
   } // findProducts
   
   private static void findMapping(Asset asst, Product_Mapping__c[] mappings) {
      // search through the mappings for one that matches.
      for (Product_Mapping__c pm : mappings) {
         // check if matches all three params
         if (asst.Admin_By__c != null && asst.Ext_App_Id__c != null && asst.Plan_Type__c != null
             && asst.Admin_By__c == pm.Admin_By__c
             && asst.Ext_App_Id__c == pm.Ext_App_Id__c
             && asst.Plan_Type__c == pm.Plan_Type__c) {
            System.debug('Mapping found for '+asst.Name+',admin by, pm='+pm);
            asst.Product2Id = pm.Product__c;
            break;
         } else if (asst.Product_Plan_Code__c != null 
                    && asst.Product_Plan_Code__c == pm.Plan_Code__c) {
            System.debug('Mapping found for '+asst.Name+',plan code, pm='+pm);
            asst.Product2Id = pm.Product__c;
            break;
         } // if (asst.AdminBy)
      } // for (Product_Mapping__c
   } // findMapping
   
   private static void addIfNotNull(String value, Set<String> setToAddTo) {
      if (value != null) {
         setToAddTo.add(value);
      }
   } // addIfNotNull
   
   public static String PM_TYPE='HRIS Feed';
   
   public static Product_Mapping__c[] getMappings(Set<String> adminBySet, Set<String> extAppIdSet
                                 ,Set<String> planTypeSet, Set<String> planCodeSet) {
      Product_Mapping__c[] mappings = [Select Id, Name
                                             ,Admin_By__c
                                             ,Ext_App_Id__c
                                             ,Mapping_Key__c
                                             ,Plan_Code__c
                                             ,Plan_Type__c
                                             ,Product__c
                                             ,Sales_Org__c
                                             ,Type__c
                                         From Product_Mapping__c
                                        Where Type__c = :PM_TYPE
                                          and Product__c != null
                                          and (Admin_By__c in :adminBySet 
                                               or Ext_App_Id__c in :extAppIdSet
                                               or Plan_Type__c in :planTypeSet
                                               or Plan_Code__c in :planCodeSet)];
      System.debug('getMappings mappings='+mappings.size());
      return mappings;
   } // getMapping
   
   //public static void checkAccountBundle(Map<Id,String> checkAcctBundleMap) {
      // select the Accounts and any packages they currently have
      /*
      Account accts = [Select Id, Name
                            ,(Select Id, Name
                                    ,Product2.ProductCode
                                From Assets
                               Where Product2.Is_Package__c = true)
                         From Account
                        Where Id in :checkAcctBundleMap.keySet()];
      */
   //} // checkAccountBundle
   
   // all of the plan codes the process checks
   public static Set<String> planCodesSet = new Set<String>{'688','1089','1029','884','793','1010','1005'};
   
   //LM 5/12/2017
   // all of the plan codes used to populate the Client Start Date on Reference HRS Term/Transfer object
   public static Set<String> HRSPlanCodesSet = new Set<String>{'884','793','1010','1005', '1029'};
   
   // all of the activity record type names the process checks
   public static final String[] actyRecordTypeNames = new String[]{'2008-09 Premier Safety Event Record Type'
                         ,'2008-09 Premier Safety Task Record Type'};
   
   // all of the plan codes the process checks
   public static Set<String> TAAPlanCodesSet = new Set<String>{'992','993','1053'};
   
   // all of the activity record type names the process checks
   public static final String[] refObjTAARecordTypeName = new String[]{'Reference TAA Support Record Type'};
                                               
   public static void updateActivityRecord(Set<Id> acctIdSet) {
      // Map of account ids and a flag indicating if all of the products have been ended.
      Map<Id, Boolean> cancelStatusMap = getCancelStatusMap(acctIdSet, planCodesSet);
      updateTaskCancelFlag(cancelStatusMap);
      updateEventCancelFlag(cancelStatusMap);
            
    } // updateActivityRecord

    // start date map by the account id.    
    public static Map<Id, Date> v_hrsStartDateMap = new Map<Id, Date>();
    public static Set<Id> v_taaAcctIdSet = new Set<Id>();
    public static Set<Id> v_premierAcctIdSet = new Set<Id>();
    
    public static void checkAfterTrigger(Asset asst, Asset oldAsst) {
       if (asst.AccountId != null && asst.Product_Plan_Code__c != null 
                     && asst.Start_Date__c != null && asst.Plan_Cancel_Date__c == null 
                     && AssetMethods.HRSPlanCodesSet.contains(asst.Product_Plan_Code__c)) {
          Date checkDate = v_hrsStartDateMap.get(asst.AccountId);
          if (checkDate == null) {
             checkDate = asst.Start_Date__c;
          } else {
             // take the lesser of the two dates.
             if (checkDate < asst.Start_Date__c) {
                checkDate = asst.Start_Date__c;
             }
          }
          v_hrsStartDateMap.put(asst.AccountId, checkDate);
       } // if (asst.AccountId != null
       
       if (asst.AccountId != null && asst.Product_Plan_Code__c != null
                   && AssetMethods.TAAPlanCodesSet.contains(asst.Product_Plan_Code__c)
                   && asst.Plan_Cancel_Date__c != null
                   && (oldAsst == null || asst.Plan_Cancel_Date__c != oldAsst.Plan_Cancel_Date__c)) {
          // only want to proceed if product is end dated and is new or the cancel date changes
          v_taaAcctIdSet.add(asst.AccountId);
       }

       if (asst.AccountId != null && !v_premierAcctIdSet.contains(asst.AccountId) 
                 && asst.Product_Plan_Code__c != null && AssetMethods.planCodesSet.contains(asst.Product_Plan_Code__c)
                 && (oldAsst == null || asst.Plan_Cancel_Date__c != oldAsst.Plan_Cancel_Date__c)) {
          v_premierAcctIdSet.add(asst.AccountId);
       }

    } // checkAfterTrigger
    
   public static void processAfterTrigger() {
      if (!v_hrsStartDateMap.isEmpty() || !v_taaAcctIdSet.isEmpty() || !v_premierAcctIdSet.isEmpty()) {
         if (Test.isRunningTest() || System.isBatch() || System.isFuture()) {
            processAfterTriggerNow(v_hrsStartDateMap, v_taaAcctIdSet,v_premierAcctIdSet);
         } else {
            processAfterTriggerFuture(v_hrsStartDateMap, v_taaAcctIdSet,v_premierAcctIdSet);
         }
         v_hrsStartDateMap.clear();
         v_taaAcctIdSet.clear();
         v_premierAcctIdSet.clear();
      } // if (!v_hrsStartDateMap.isEmpty()
       
    } // processAfterTrigger
    
   @future
   public static void processAfterTriggerFuture(Map<Id, Date> hrsStartDateMap, Set<Id> taaAcctIdSet, Set<Id> premierAcctIdSet) {
      processAfterTriggerNow(hrsStartDateMap, taaAcctIdSet,premierAcctIdSet);
   }
    
   public static void processAfterTriggerNow(Map<Id, Date> hrsStartDateMap, Set<Id> taaAcctIdSet, Set<Id> premierAcctIdSet) {
      if (!hrsStartDateMap.isEmpty()) {
         populateClientStartDate(hrsStartDateMap);
      }
       
      if (!taaAcctIdSet.isEmpty()) {
         updateTAARefObjRecord(taaAcctIdSet);
      }
       
      if (!premierAcctIdSet.isEmpty()) {
         updateActivityRecord(premierAcctIdSet);
      }

   } // processAfterTrigger
    
   //LM See if the account has a Reference HRS Termination/Transfer object and, if it does, populate its Client Start Date
   public static void populateClientStartDate(Map<Id, Date> startDateMap){
      // update records that change  
      List<Reference_HRS_Termination_Transfer__c> recordsToUpdate = new List<Reference_HRS_Termination_Transfer__c>();

      //query to find the HRS Term/Transfer records that are associated with these Accounts
      List<Reference_HRS_Termination_Transfer__c> termTransToCheck = [SELECT Id, Client_Start_Date__c, Case_Lookup__r.AccountId 
                                                                   FROM Reference_HRS_Termination_Transfer__c
                                                                  WHERE Case_Lookup__r.AccountId IN: startDateMap.keyset()];   
      //loop through the HRS Term/Transfer records to update the Client Start Date
      for (Reference_HRS_Termination_Transfer__c termTrans : termTransToCheck) {
         Date checkDate = startDateMap.get(termTrans.Case_Lookup__r.AccountId);
         if (checkDate != null) {
            //if the Client Start Date is less than the assets Start Date, use the new asst.Start_Date__c
            if (termTrans.Client_Start_Date__c == null || termTrans.Client_Start_Date__c < checkDate) {
               termTrans.Client_Start_Date__c = checkDate;
               recordsToUpdate.add(termTrans);
            }
         } // if (checkDate != null
      } // for (Reference_HRS_Termination_Transfer__c
         
      if(!recordsToUpdate.isEmpty()){
         update recordsToUpdate;
      }
   }//populateClientStartDate
/*
    //LM See if the account has a Reference HRS Termination/Transfer object and, if it does, populate its Client Start Date
    public static void populateClientStartDate(List<Asset> assetList){  
        List<Reference_HRS_Termination_Transfer__c> recordsToUpdate = new List<Reference_HRS_Termination_Transfer__c>();
        Map<Id, List<Asset>> accountIdAssetMap = new Map<Id, List<Asset>>();
        //populate the map
        for(Asset asst: assetList){
            //if the map already contains this asset's account id, put the asset in the list and add the updated list to the map        
            if(accountIdAssetMap.keyset().contains(asst.AccountId)){
                List<Asset> tempList = accountIdAssetMap.get(asst.AccountId);
                tempList.add(asst);
                accountIdAssetMap.put(asst.Accountid, tempList);    
            }
            //if the asset's account id is not in the map, add it to the map and the asset to the asset list
            else{
                accountIdAssetMap.put(asst.Accountid, new List<Asset> {asst});
            }  
        }//end for assetList
        //query to find the HRS Term/Transfer records that are associated with these Accounts
        List<Reference_HRS_Termination_Transfer__c> HRSToUpdate = [SELECT Id, Client_Start_Date__c, Case_Lookup__r.AccountId FROM Reference_HRS_Termination_Transfer__c
                                                                WHERE Case_Lookup__r.AccountId IN: accountIdAssetMap.keyset()]; 
        if(!HRSToUpdate.isEmpty()){
            //loop through the HRS Term/Transfer records to update the Client Start Date
            for(Reference_HRS_Termination_Transfer__c HRS: HRSToUpdate){
                //for this account if there are more than 1 asset , loop through each one
                if(accountIdAssetMap.get(HRS.Case_Lookup__r.AccountId).size() > 1){
                    for(Asset asst : accountIdAssetMap.get(HRS.Case_Lookup__r.AccountId)){
                        //if the Client Start Date is less than the assets Start Date, use the new asst.Start_Date__c
                        if(HRS.Client_Start_Date__c != null && asst.Plan_Cancel_Date__c == null
                            && HRS.Client_Start_Date__c < asst.Start_Date__c){
                            HRS.Client_Start_Date__c = asst.Start_Date__c;
                        }
                        //if there are more than one asset and the client start date is not yet populated,
                        //populate it with the first asset in this loop and evaluate the others against it to get the most recent one
                        else if(HRS.Client_Start_Date__c == null && asst.Plan_Cancel_Date__c == null){
                            HRS.Client_Start_Date__c = asst.Start_Date__c;
                        }
                        
                    }//end for loop
                }//if accountIdAssetMap
                //if there is only one asset, use it's date to populate Client Start Date
                else{
                    if(HRS.Client_Start_Date__c != null && HRS.Client_Start_Date__c < accountIdAssetMap.get(HRS.Case_Lookup__r.AccountId)[0].Start_Date__c
                        && accountIdAssetMap.get(HRS.Case_Lookup__r.AccountId)[0].Plan_Cancel_Date__c == null){
                        HRS.Client_Start_Date__c = accountIdAssetMap.get(HRS.Case_Lookup__r.AccountId)[0].Start_Date__c;
                    }
                    else if(HRS.Client_Start_Date__c == null && accountIdAssetMap.get(HRS.Case_Lookup__r.AccountId)[0].Plan_Cancel_Date__c == null){
                        HRS.Client_Start_Date__c = accountIdAssetMap.get(HRS.Case_Lookup__r.AccountId)[0].Start_Date__c;
                    }
                    
                }           
            recordsToUpdate.add(HRS); 
            }//for HRSToUpdate
        }
            
        if(!HRSToUpdate.isEmpty()){
            update HRSToUpdate;
        }
    }//populateClientStartDate
    */
    
   /** Check the assets for the passed in account ids. See if all of the specified products have an end date. If they all do,
       return a true for that account id. If even one does not have an end date, a false will be returned.
    */
   public static Map<Id, Boolean> getCancelStatusMap(Set<Id> acctIds, Set<String> queryPlanCodeSet) {
      System.debug('getCancelStatusMap acctIds='+acctIds.size()+' queryPlanCodeSet='+queryPlanCodeSet);
      // Map of account ids and a flag indicating if all of the products have been ended.
      Map<Id, Boolean> cancelStatusMap = new Map<Id,Boolean>();
      for (Id acctId : acctIds) {
         cancelStatusMap.put(acctId,true);
      } // for
      
      // retrieve all of the active products, otherwise will be defaulted to true.
      AggregateResult[] prodResults = [SELECT count(Id) nbr_assets, AccountId 
                                            FROM Asset
                                           Where AccountId IN: acctIds
                                             and Start_Date__c != null
                                             and Plan_Cancel_Date__c = null
                                             and Product_Plan_Code__c in :queryPlanCodeSet
                                           group by AccountId];
      System.debug('getCancelStatusMap prodResults='+prodResults.size());
      for (AggregateResult ar : prodResults) {
         Id acctId = (Id)ar.get('AccountId');
         Integer nbrRecs = Integer.valueOf(ar.get('nbr_assets'));
         System.debug('getCancelStatusMap acctId='+acctId+' nbrRecs='+nbrRecs);
         if (nbrRecs > 0) {
            cancelStatusMap.put(acctId,false);
         }
      } // for (AggregateResult ar
    /*
      for (Asset[] assets : [Select Id, AccountId,Product_Plan_Code__c, Plan_Cancel_Date__c 
                               from Asset 
                              where AccountId IN: acctIds 
                                and Product_Plan_Code__c in :TAAPlanCodesSet ]) {
         for (Asset asst : assets) {
            Boolean checkValue = cancelStatusMap.get(asst.AccountId);
            Boolean newValue = ((checkValue != null && checkValue) && 
            // get the value from the map if it exists
            if (checkValue == null) {
               // if it doesn't exist default it to null
               checkValue = true;
               cancelStatusMap.put(asst.AccountId,checkValue);
            }
            // if the value is true and the cancel date is null, that means there is at least one product not cancelled 
            // so we want to change the value to false.
            // if all were cancelled we would never get into this if statement and the value would remain true.
            if (checkValue && asst.Plan_Cancel_Date__c == Null) {
               cancelStatusMap.put(asst.AccountId,false);
            } // if check value  
         
         } // for (Asset asst              
      } // for (Asset[] assets
      */
      return cancelStatusMap;
   } // getCancelStatusMap
   
   public static void updateTaskCancelFlag(Map<Id, Boolean> cancelStatusMap) {

      // select all of the tasks to check if the HR_Solution_Cancel__c flag needs to change
      // based on the Account Id.
      for (Task[] tsks : [Select Id, ActivityDate, HR_Solution_Cancel__c,AccountId, whatId 
                            from task 
                           where RecordType.Name in :actyRecordTypeNames 
                             and ActivityDate >= :Date.today() 
                             and IsClosed = false 
                             and AccountId IN :cancelStatusMap.keySet()]) {
         checkActivity(tsks, cancelStatusMap);
      } // for (Task[] tsks
   } // updateTaskCancelFlag
   
   public static void updateEventCancelFlag(Map<Id, Boolean> cancelStatusMap) {

      // select all of the tasks to check if the HR_Solution_Cancel__c flag needs to change
      // based on the Account Id.
      for (Event[] evnts : [Select Id, HR_Solution_Cancel__c,AccountId, whatId 
                              from event 
                             where RecordType.Name in :actyRecordTypeNames 
                               and ActivityDate >= :Date.today() 
                               and AccountId IN :cancelStatusMap.keySet()]) {
         System.debug('updateEventCancelFlag evnts='+evnts.size());        
         checkActivity(evnts, cancelStatusMap);
      } // for (Event[] evnts
   } // updateEventCancelFlag
   
   public static void checkActivity(SObject[] records, Map<Id, Boolean> cancelStatusMap) {
      // the events to update
      List<SObject> updateActivity = new List<SObject>();
      for (SObject rec : records) {
         // the value from the Assets
         Id acctId = (Id)rec.get('AccountId');
         Boolean checkValue = cancelStatusMap.get(acctId);
         // what the current value is
         String curValue = (String)rec.get('HR_Solution_Cancel__c');
         Boolean actyValue = (curValue != null && curValue == 'Yes');
         System.debug('checkActivity acctId='+acctId+' checkValue='+checkValue+' curValue='+curValue+' actyValue='+actyValue);
         // only update the event if the value changes
         if (checkValue != actyValue) {
            System.debug('checkActivity update HR_Solution_Cancel__c field to '+(checkValue ? 'Yes' : 'No'));
            rec.put('HR_Solution_Cancel__c',(checkValue ? 'Yes' : 'No'));
            updateActivity.add(rec);
         }
      } // for
      if (!updateActivity.isEmpty()) {
         update updateActivity;
      } // checkActivity
   } // checkActivity
   
  
   public static void updateTAARefObjRecord(Set<Id> acctIdSet) {
      Set<Id> acctWithCancel = new Set<Id>();
      
      // setting planCodesSet to TAA plan codes to re-use query in getCancelStatusMap
      //planCodesSet = TAAPlanCodesSet;
      // Map of account ids with if there are no active TAA products
      Map<Id, Boolean> cancelStatusMap = getCancelStatusMap(acctIdSet, TAAPlanCodesSet);
      getReferenceTAAtoUpdate(cancelStatusMap);
     
    } // updateSupportRefObjRecord
   
    public static void getReferenceTAAtoUpdate(Map<Id, Boolean> cancelStatusMap) {
      // select all of the Support Ref Objects to check if the Current Step needs to change
      // based on the Account Id.
      Reference_TAA__c[] supTAAs = [Select Id, Current_Step__c, Support_Case_Lookup__c, Case_Lookup__r.Account.Id
                                                 ,Date_Opened__c  
                                             from Reference_TAA__c
                                            where RecordType.Name = 'Reference TAA Support Record Type'
                                              and Case_Lookup__r.Account.Id IN :cancelStatusMap.keySet()
                                             ORDER BY Date_Opened__c DESC];
      
      Reference_TAA__c[] updatesupTAAs = new Reference_TAA__c[]{};  
      
      for (Reference_TAA__c supTAA : supTAAs){
         Boolean resetValue = cancelStatusMap.get(supTAA.Case_Lookup__r.Account.Id);
         // get the value from the map if it exists
         if (resetValue == True) {
            supTAA.Current_Step__c = 'Cancelled in Support';
               updatesupTAAs.add(supTAA); 
         }   
      } // for   
                 
      if (!updatesupTAAs.isEmpty()) {
         update updatesupTAAs;
      }          
    } // getReferenceTAAtoUpdate
    
    //LM - Payroll Assets
    /* LM - pull out code per Leslie 11/3/2016
    public static Set<String> PayrollAssetPlanCodesSet = new Set<String>{'CA-MMS_PAY','CA-BPR','CA-PBSPR', 'CA-PP_PR', 
                                                                         'CA-ADV', 'CA-ADVP'};
    //LM - update Account with the Reason Lost from the Asset's Plan Lost Reason field
    //get all of the Payroll Assets that exist on the Accounts passed over
    //order by account Ids so all of the assets with the same Account are together, 
    //then order by plan cancel date so the most recent one is first. If no plan cancel date,
    //it will display first and we can clear the lost date and reason values.
    
    public static void updateAccount(Set<id> acctIds) {
        map<Id,Account> acctMap = new Map<Id,Account>();
        list<Asset> AssetList = new List<Asset>();
        AssetList = [SELECT AccountId, Product_Plan_Code__c, Plan_Cancel_Date__c, Plan_Lost_Reason__c, Start_Date__c FROM Asset
            WHERE AccountId IN: acctIds and Product_Plan_Code__c IN: PayrollAssetPlanCodesSet
            ORDER BY AccountId, Plan_Cancel_Date__c DESC];
        
            for(Asset asst : AssetList){
                    if (!acctMap.keySet().contains(asst.AccountId))
                    {
                        if(asst.Plan_Cancel_Date__c == null){
                            acctMap.put(asst.AccountId,new Account(Id=asst.AccountId, 
                                                                   Reason_Lost__c = '', 
                                                                   Lost_Date__c = null));
                        }
                        else{
                            acctMap.put(asst.AccountId,new Account(Id=asst.AccountId, 
                                                                   Reason_Lost__c = asst.Plan_Lost_Reason__c, 
                                                                   Lost_Date__c = asst.Plan_Cancel_Date__c));
                        }   
                    }//end if
                    //if the account is in the map, it already has a value for Reason Lost, so go to the next account               
            }//end for AssetList

        if(!acctMap.isEmpty()){
            update(acctMap.values()); 
        }//end isEmpty
        
      }//end updateAccount*/
} // class AssetMethods