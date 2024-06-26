/* 
 * Maps Assets to the product indicators on the Prospect Client using Custom Settings - AssetMapping
 *
 * History
 * -------
 * 02/01/2016 Lynn Michels            Created  
 * 06/15/2016 Dan Carmen/Lynn Michels Rewrote code
 * 07/27/2017 Sunnish Annu
   09/21/2017 Dan Carmen              Change to use Custom Metadata Type
   12/12/2017 Dan Carmen              Additional adjustments to asset code
   10/31/2018 Jake Hinds        Adding HROI into active product check
   05/22/2019 Jake Hinds        Adding Oasis into active product check
   06/11/2019 Jake Hinds        Adding RecordTypeId to acct query
   06/17/2020 Dan Carmen        Added Oasis account owner field to the query.
   06/17/2021 Dan Carmen        Added CSCMContractStatus__c to account query
   08/09/2023 Carrie Marciano	Added Other_PEO_Client_Number__c to account query
   
 */
public with sharing class AssetMappingToProductIndicators {
   
   //contains the asset ids for the Assets which the 'trigger update' box is checked
   public static Set<Id> overrideIdSet = new Set<Id>();
   public static Set<Id> accountIdSet = new Set<Id>();
   
   public static Set<Id> acctIdsProcessedSet = new Set<Id>();
    
   //public static Set<String> planCodeQuerySet = new Set<String>();
   //public static Map<Id,Set<String>> planCodeSetByAcctIdMap = new Map<Id,Set<String>>();
   
   //called from IsBefore Trigger
   //collect asset ids for the ones that have the 'Trigger Update' box checked
   public static void checkBeforeTrigger(Asset asst, Asset oldAsst) {
      if (oldAsst != null && asst.AccountId != null && asst.Trigger_Update__c) {
         overrideIdSet.add(asst.Id);
         //reset the Trigger Update box
         asst.Trigger_Update__c = false;
      }
   } // checkBeforeTrigger

   // if a field is deleted, these are the fields we will want to clear (set to false, clear picklist value)
   // if we don't get a new value in
   public static Map<Id,Map<String,Object>> fieldsToClearByAcctIdMap = new Map<Id,Map<String,Object>>();
   
   //sends in old Asset
   public static void checkTriggerDelete(Asset asst) {
      System.debug('checkTriggerDelete asst='+asst);
      // check if we process this asset
      checkToProcessPlanCode(asst, true);

   } // checkTriggerDelete

   // a map of the plan codes to the relevant fields.   
   public static Map<String,Set<AssetProductField__mdt>> planCodeFldMap = new Map<String,Set<AssetProductField__mdt>>();
   // a set of all of the unique field names
   public static Set<String> acctFldNameSet = new Set<String>();
   public static Set<String> planCodesFoundSet = new Set<String>();
   
   public static Boolean checkToProcessPlanCode(Asset asst, Boolean isDelete) {
      Boolean handlePlanCode = (String.isNotBlank(asst.Product_Plan_Code__c) && planCodesFoundSet.contains(asst.Product_Plan_Code__c));
      if (!handlePlanCode && asst.AccountId != null && String.isNotBlank(asst.Product_Plan_Code__c)) {
         AssetPlanCode__mdt[] planCodes = [select Label
                                                 ,(select Label
                                                         ,AssetPlanCode__r.Label
                                                         ,AssetProductField__r.DeveloperName
                                                         ,AssetProductField__r.Label
                                                         ,AssetProductField__r.PicklistValue__c
                                                     from AssetPlanFldLinks__r
                                                    Where IsActive__c=true)
                                             from AssetPlanCode__mdt
                                            where Label = :asst.Product_Plan_Code__c];
         System.debug('checkToProcessPlanCode planCodes='+planCodes.size());
         System.debug('checkToProcessPlanCode planCodes='+planCodes); 
         // should only be at most 1 row returned - but just in case
         for (AssetPlanCode__mdt planCode : planCodes) {
            handlePlanCode = true;
            planCodesFoundSet.add(planCode.Label);
            Set<AssetProductField__mdt> fldSet = new Set<AssetProductField__mdt>();
            for (AssetPlanFldLink__mdt link : planCode.AssetPlanFldLinks__r) {
               system.debug('checkToProcessPlanCode link=' +link);
               if (link.AssetProductField__r != null) {
                  fldSet.add(link.AssetProductField__r);
                  acctFldNameSet.add(link.AssetProductField__r.DeveloperName);
                  if (isDelete) {
                     handleDelete(asst, link.AssetProductField__r);
                  }
               }
            } // for (AssetPlanFldLink__mdt link
            
            if (!fldSet.isEmpty()) {
               planCodeFldMap.put(asst.Product_Plan_Code__c,fldSet);
               accountIdSet.add(asst.AccountId);
            }
         } // for (AssetPlanCode__mdt planCode
         
      } // if (String.isNotBlank
      return handlePlanCode;
   } // checkToProcessPlanCode
   
   // store the data to check for a delete later
   public static void handleDelete(Asset asst, AssetProductField__mdt prodFld) {
      System.debug('handleDelete asst='+asst+' prodFld='+prodFld);
      Map<String,Object> fldDataMap = (fieldsToClearByAcctIdMap.containsKey(asst.AccountId) ? fieldsToClearByAcctIdMap.get(asst.AccountId) : new Map<String,Object>());
      if (String.isNotBlank(prodFld.PicklistValue__c)) {
         fldDataMap.put(prodFld.Label, '');
      } else {
         fldDataMap.put(prodFld.Label, false);
      }
      fieldsToClearByAcctIdMap.put(asst.AccountId, fldDataMap);
   } // handleDelete
   
   // the set of Ids we'll use to check the client type
   public static Set<Id> acctIdForCltTypeSet = new Set<Id>();

   //called from isUpdate or isInsert Trigger
   public static void checkAfterTrigger(Asset asst, Asset oldAsst) {
      //Set<ID> updatedAcctIds = new Set<ID>();
      Boolean hasRequiredFlds = (asst.AccountId != null && asst.Start_Date__c != null && String.isNotBlank(asst.Product_Plan_Code__c));
      //Boolean hasEndDate = asst.Plan_Cancel_Date__c != null;
      Boolean hasChangedData = (oldAsst == null || (oldAsst.Start_Date__c != asst.Start_Date__c)||(oldAsst.Plan_Cancel_Date__c != asst.Plan_Cancel_Date__c) 
                                 || (oldAsst.Product_Plan_Code__c != asst.Product_Plan_Code__c));
      Boolean triggerUpdate = overrideIdSet.contains(asst.Id);
      System.debug('checkAfterTrigger hasRequiredFlds='+hasRequiredFlds+' hasChangedData='+hasChangedData+' triggerUpdate='+triggerUpdate);
      
      if (hasRequiredFlds && !acctIdsProcessedSet.contains(asst.AccountId) && (hasChangedData || triggerUpdate)) {
         checkToProcessPlanCode(asst, false);
         accountIdSet.add(asst.AccountId);
         //checkToAddPlanCodes(asst);
      } // if (hasChangedData || triggerUpdate
   } // checkAfterTrigger
   
   
   public static map<Id,Account> acctMap = new Map<Id,Account>();
                     
   public static Account getAcctFromMap(Id acctId) {
      Account acct = acctMap.get(acctId);
      if (acct == null) {
         acct = new Account(Id=acctId);
         acctMap.put(acctId,acct);
      }
      return acct;
   } // getAcctFromMap
         
    //holds the account field and all of the plan codes that populate it
    public static Map<String,List<String>> acctFieldPlanCodeMap = null;

   // all of the plan codes for each field name
   //public static Map<String,Set<String>> planCodesByFldNameMap = new Map<String,Set<String>>();
   // a mapping to the AssetProductField__mdt object to get the other attributes
   public static Map<String, AssetProductField__mdt> fldNameMap = new Map<String,AssetProductField__mdt>();

   public static void handleAfterActions() {
      System.debug('handleAfterActions accountIdSet='+accountIdSet.size());
      if (accountIdSet.isEmpty()) {
         // do nothing
         return;
      }
      acctIdsProcessedSet.addAll(accountIdSet);
      setupFldNameMap();
      // select data
      // query by account to group everything together
      for (Account acct : [SELECT Id,Name,Client_Status__c,HR_Generalist__c,HR_Manager__c,Payroll_Branch_Nbr__c,Type,Lost_Date__c,RecordTypeId
                                 ,OasisPEOHoldOut__c,OasisPEOHoldOutExpiration__c,OasisPEOHoldOutReason__c, Other_PEO_Client_Number__c, OasisPEOAccountOwner__c, CSCMContractStatus__c
                                 ,(SELECT Id,Plan_Cancel_Date__c,Product_Plan_Code__c,AccountId,Product_End_Date__c 
                                     FROM Assets
                                    Where (Paychex_Asset_Id__c != null OR Product_Plan_Code__c LIKE 'HROI%' OR Product_Plan_Code__c LIKE 'Oasis%')) 
                              FROM Account 
                             WHERE Id in :accountIdSet]) {

         Set<String> activeProductCodeSet = new Set<String>();
         Asset[] checkAssets = new Asset[]{};
         for (Asset asst : (acct.Assets != null ? acct.Assets : new Asset[]{})) {
           if(asst.Plan_Cancel_Date__c == null && String.isNotBlank(asst.Product_Plan_Code__c) && asst.Product_Plan_Code__c.startsWith('HROI') && !activeProductCodeSet.contains('HROI')){
             activeProductCodeSet.add('HROI');
          }
          else if(asst.Plan_Cancel_Date__c == null && String.isNotBlank(asst.Product_Plan_Code__c) && asst.Product_Plan_Code__c.startsWith('Oasis') && !activeProductCodeSet.contains('Oasis')){
             activeProductCodeSet.add('Oasis');
          }
          else if(asst.Plan_Cancel_Date__c == null && String.isNotBlank(asst.Product_Plan_Code__c) && !asst.Product_Plan_Code__c.startsWith('HROI') && !asst.Product_Plan_Code__c.startsWith('Oasis')){
             activeProductCodeSet.add(asst.Product_Plan_Code__c);
          }
            if (planCodeFldMap.containsKey(asst.Product_Plan_Code__c)) {
               checkAssets.add(asst);
            }
         } // for (Asset asst
         System.debug('handleAfterActions acct='+acct.Name+' activeProductCodeSet='+activeProductCodeSet.size()+' checkAssets='+checkAssets.size());
         AccountMethods.checkAcctType(acct, activeProductCodeSet, acctMap);
         checkProductFields(acct.Id, checkAssets);
         //planCodeSetByAcctId.put(queryAcct.Id, activeProductCodeSet);
   
      } // for (Account acct

      checkDeletedRecords();
        
      saveAcctMap();
      accountIdSet.clear();
      planCodesFoundSet.clear();
      activeFldValueSet.clear();
   } // handleAfterActions

   public static void setupFldNameMap() {
      fldNameMap.clear();
      if (!acctFldNameSet.isEmpty()) {
         AssetProductField__mdt[] prodFlds = [select Label
                                                 ,(select Label
                                                         ,AssetPlanCode__r.Label
                                                         ,AssetProductField__r.Label
                                                         ,AssetProductField__r.PicklistValue__c
                                                     from AssetPlanFldLinks__r
                                                    Where IsActive__c=true)
                                             from AssetProductField__mdt
                                            where DeveloperName in :acctFldNameSet];
         for (AssetProductField__mdt prodFld : prodFlds) {
            for (AssetPlanFldLink__mdt link : prodFld.AssetPlanFldLinks__r) {
               Set<AssetProductField__mdt> fldSet = (planCodeFldMap.containsKey(link.AssetPlanCode__r.Label) ? planCodeFldMap.get(link.AssetPlanCode__r.Label) : new Set<AssetProductField__mdt>());
               fldSet.add(link.AssetProductField__r);
               //System.debug('handleAfterActions planCode='+link.AssetPlanCode__r.Label+' fldSet='+fldSet);
               planCodeFldMap.put(link.AssetPlanCode__r.Label, fldSet);
               
               //planCodeQuerySet.add(link.AssetPlanCode__r.Label);
               fldNameMap.put(link.AssetProductField__r.Label, link.AssetProductField__r);
            }
         } // for (AssetProductField__mdt
         System.debug('handleAfterActions prodFlds='+prodFlds.size()+' fldNameMap='+fldNameMap.size()+' planCodeFldMap.keySet()='+planCodeFldMap.keySet().size()+' planCodeFldMap='+planCodeFldMap);
      }
   } // setupFldNameMap
   /*
   public static void handleAfterActions2() {
      System.debug('handleAfterActions acctIdForCltTypeSet='+acctIdForCltTypeSet.size());
      if (!acctIdForCltTypeSet.isEmpty()) {
         // retrieve the data for setting the client type
         getClientTypeData();
         AccountMethods.setAccountType(acctList, planCodeSetByAcctId, acctMap);
         System.debug('handleAfterActions acctMap='+acctMap.size());
      }
      //if (!planCodeQuerySet.isEmpty() && !accountIdSet.isEmpty()) {
         
      //planCodesByFldNameMap.clear();
      fldNameMap.clear();
      if (!planCodeFldMap.isEmpty() && !accountIdSet.isEmpty()) {
         
         AssetProductField__mdt[] prodFlds = [select Label
                                                 ,(select Label
                                                         ,AssetPlanCode__r.Label
                                                         ,AssetProductField__r.Label
                                                         ,AssetProductField__r.PicklistValue__c
                                                     from AssetPlanFldLinks__r
                                                    Where IsActive__c=true)
                                             from AssetProductField__mdt
                                            where DeveloperName in :acctFldNameSet];
         for (AssetProductField__mdt prodFld : prodFlds) {
            for (AssetPlanFldLink__mdt link : prodFld.AssetPlanFldLinks__r) {
               Set<AssetProductField__mdt> fldSet = (planCodeFldMap.containsKey(link.AssetPlanCode__r.Label) ? planCodeFldMap.get(link.AssetPlanCode__r.Label) : new Set<AssetProductField__mdt>());
               fldSet.add(link.AssetProductField__r);
               //System.debug('handleAfterActions planCode='+link.AssetPlanCode__r.Label+' fldSet='+fldSet);
               planCodeFldMap.put(link.AssetPlanCode__r.Label, fldSet);
               
               //planCodeQuerySet.add(link.AssetPlanCode__r.Label);
               fldNameMap.put(link.AssetProductField__r.Label, link.AssetProductField__r);
            }
         } // for (AssetProductField__mdt
         System.debug('handleAfterActions prodFlds='+prodFlds.size()+' fldNameMap='+fldNameMap.size()+' acctList='+acctList.size()+' planCodeFldMap.keySet()='+planCodeFldMap.keySet().size()+' planCodeFldMap='+planCodeFldMap);
        
         for (Account acct : acctList) {
            Asset[] checkAssets = new Asset[]{};
            System.debug('acct='+acct.Name+' assets='+acct.Assets.size());
            for (Asset asst : acct.Assets) {
               System.debug('acct='+acct.Name+' planCode='+asst.Product_Plan_Code__c);
               if (planCodeFldMap.containsKey(asst.Product_Plan_Code__c)) {
                  System.debug('Added to checkAssets');
                  checkAssets.add(asst);
               }
            }
            checkProductFields(acct.Id, checkAssets);
         } // for (Account acct
         /*
         Account[] accts = [Select Id, Name
                                  ,(Select Id, AccountId, Product_Plan_Code__c
                                          ,Start_Date__c, Plan_Cancel_Date__c
                                      From Assets
                                     Where Product_Plan_Code__c in :planCodeFldMap.keySet()
                                       and Start_Date__c != null
                                      order by Start_Date__c DESC)
                              From Account
                             Where Id in :accountIdSet];
         System.debug('handleAfterActions accts='+accts.size());
         for (Account queryAcct : accts) {
            checkProductFields(queryAcct.Id, queryAcct.Assets);
         }
 */
/*
      } // if (!planCodeQuerySet.isEmpty() &&
      checkDeletedRecords();
        
      saveAcctMap();
   } // handleAfterActions
   */
   /*
   public static Map<Id, Asset[]> assetByAcctIdMap = new Map<Id, Asset[]>();
   public static Map<Id,Set<String>> planCodeSetByAcctId = new Map<Id,Set<String>>();
      
   public static Account[] acctList = new Account[]{};
   
   // Retrieve all of the asset information for the account ids selected
   public static void getClientTypeData() {
      Account[] queryAccts = [SELECT Id,Name,Client_Status__c,HR_Generalist__c,HR_Manager__c,Payroll_Branch_Nbr__c,Type,Lost_Date__c 
                                 ,(SELECT Id,Plan_Cancel_Date__c,Product_Plan_Code__c,AccountId,Product_End_Date__c 
                                     FROM Assets
                                    Where Paychex_Asset_Id__c != null) 
                              FROM Account 
                             WHERE Id in :acctIdForCltTypeSet];
      System.debug('getClientTypeData queryAccts='+queryAccts.size());
      for (Account queryAcct : queryAccts) {
         Asset[] assets = queryAcct.Assets != null ? queryAcct.Assets : new Asset[]{};
         Set<String> activeProductCodeSet = new Set<String>();
         for (Asset asst : assets) {
            if (asst.Plan_Cancel_Date__c == null) {
               activeProductCodeSet.add(asst.Product_Plan_Code__c);
            } 
         } // for (Asset asst
         System.debug('getClientTypeData acct='+queryAcct.Name+' activeProductCodeSet='+activeProductCodeSet.size());
         planCodeSetByAcctId.put(queryAcct.Id, activeProductCodeSet);
         
         assetByAcctIdMap.put(queryAcct.Id, assets);
         // remove this to clear up the view state
         //queryAcct.Assets.clear();
         acctList.add(queryAcct);
      }
   } // getClientTypeData
   */
   public static void saveAcctMap() {
      System.debug('saveAcctMap acctMap='+acctMap.size());
      if (!acctMap.isEmpty()) {
         ZipCheckOwner.SKIP_TRIGGERS = true;
         DmlHelper.performDML2(acctMap.values(), DmlHelper.DML_UPDATE, 'AssetMappingToProductIndicators', 'handleAfterActions', 'updating acctMap', true);
         ZipCheckOwner.SKIP_TRIGGERS = false;
         acctMap.clear();
      }

   } // saveAcctMap
   
   public static void checkDeletedRecords() {
      System.debug('checkDeletedRecords fieldsToClearByAcctIdMap='+fieldsToClearByAcctIdMap.size());
      if (!fieldsToClearByAcctIdMap.isEmpty()) {
         for (Id acctId : fieldsToClearByAcctIdMap.keySet()) {
            Map<String,Object> fieldToClearMap = fieldsToClearByAcctIdMap.get(acctId);
            Account acct = getAcctFromMap(acctId);
            if (acct != null && fieldToClearMap != null) {
               for (String fieldName : fieldToClearMap.keySet()) {
                  if (acct.get(fieldName) == null) {
                     System.debug('checkDeletedRecords fieldName='+fieldName+' value='+fieldToClearMap.get(fieldName));
                     acct.put(fieldName, fieldToClearMap.get(fieldName));
                  }
               }
            } // if (acct != null && fieldToClearMap != null
         } // for (Id acctId : fieldsToClearByAcctIdMap
      } // if (!fieldsToClearByAcctIdMap
   } // checkDeletedRecords
        
   public static void checkProductFields(Id acctId, Asset[] assets) {
      Account acct = getAcctFromMap(acctId);
      System.debug('checkProductFields assets='+assets.size());
       
      // these are the plan codes/fields relevant to just this account based on the existing assets 
      Map<String, Set<String>> planCodesByFldMap = new Map<String, Set<String>>();
       
      // group the assets by the field name
      Map<String, Asset[]> assetByFldMap = new Map<String,Asset[]>();
       
      for (Asset asst : assets) {
         // get all of the fields for each asset
         Set<AssetProductField__mdt> fldSet = planCodeFldMap.get(asst.Product_Plan_Code__c);
         //System.debug('checkProductFields planCode='+asst.Product_Plan_Code__c+' fldSet='+fldSet);
         if (fldSet != null) {
            for (AssetProductField__mdt fld : fldSet) {
               Asset[] fldAssets = (assetByFldMap.containsKey(fld.Label) ? assetByFldMap.get(fld.Label) : new Asset[]{});
               fldAssets.add(asst);
               assetByFldMap.put(fld.Label, fldAssets);
               //System.debug('checkProductFields fld='+fld.Label+' assets='+fldAssets.size());
            } // for (AssetProductField__mdt fld
         } // if (flds != nul
      } // for (Asset asst
       
      for (String fldName : assetByFldMap.keySet()) {
         Asset[] checkAssets = assetByFldMap.get(fldName);
         AssetProductField__mdt prodFld = fldNameMap.get(fldName);
         if (checkAssets != null && prodFld != null) {
            System.debug('checkProductFields fldName='+fldName+' checkAssets='+checkAssets.size());
            try {
               handleAccountFld(acct, checkAssets);
            } catch (Exception e) {
               System.debug('checkProductFields setting fldName='+fldName+' exception: '+e.getMessage()+'; '+e.getStackTraceString());
            }
         }
      } // for (String fldName
       
   } // checkProductFields
   
   public static Set<String> activeFldValueSet = new Set<String>();
    
   public static void handleAccountFld(Account acct, Asset[] assets) {
      Set<AssetProductField__mdt> fldSet = null; // planCodeFldMap
      // assets should be in order of start date. As soon as we find a non-ended one we'll stop.
      for (Asset asst : assets) {
         if (asst.Plan_Cancel_Date__c == null) {
            fldSet = planCodeFldMap.get(asst.Product_Plan_Code__c);
            System.debug('handleAccountFld no cancel date asst='+asst.Product_Plan_Code__c+' fldSet='+fldSet);
            break;
         }
      } // for (Asset asst

      Boolean isActive = (fldSet != null);
      System.debug('handleAccountFld isActive='+isActive+' fldSet='+fldSet);
      if (fldSet == null && !assets.isEmpty()) {
         fldSet = planCodeFldMap.get(assets[0].Product_Plan_Code__c);
      }
      System.debug('handleAccountFld 2 fldSet='+fldSet);
      if (fldSet != null) {
         // set the value on the account field
         for (AssetProductField__mdt fld : fldSet) {
            String fldKey = acct.Id+fld.Label;
            System.debug('handleAccountFld activeFldValueSet fldKey='+fldKey+' contains='+activeFldValueSet.contains(fldKey));
            if (!activeFldValueSet.contains(fldKey)) {
               Object fldValue = null;
               if (String.isNotBlank(fld.PicklistValue__c)) {
                  fldValue = (isActive ? fld.PicklistValue__c : '');
               } else {
                  fldValue = (isActive ? true : false);
               }
               System.debug('handleAccountFld fld='+fld.Label+' fldValue='+fldValue);
               acct.put(fld.Label, fldValue);
               if (isActive) {
                  activeFldValueSet.add(fldKey);
               }
            } // if (!activeFldValueSet.contains
         } // for (AssetProductField__mdt fld
      } // if (fldSet != null
      
   } // handleAccountFld

} // class AssetMappingToProductIndicators