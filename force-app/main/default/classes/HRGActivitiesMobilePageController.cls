/* 
 * Controller for HRG on-going activities on their phone.
 *
 * History
 * -------
 * 3/15/2015 Cindy Freeman and Justin Stouffer   Created
 * 01/01/2016 Justin Stouffer   Comprehensive Update
 * 05/19/2016 Justin Stouffer   Revised to be a standalone visualforce page and added mass create to client base and openSFActivity functionality.
 * 04/17/2017 Cindy Freeman     update recsPerPage so when pull up Client List you see all records
 * 04/30/2018 Cindy Freeman     modified AdditionalAccounts method to set comingFromMobile
 * 06/15/2018 Lynn Michels      modified for new Client querying in ReferenceHRGController
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
 */

global without sharing class HRGActivitiesMobilePageController {

    public static List<HRGWrapper> hrgActWrapList;
  
    public HRGActivitiesMobilePageController(ApexPages.StandardController controller){
        //ReferenceHRGController refHRGCon = new ReferenceHRGController();
    }
      
    @RemoteAction
    global static List<HRGWrapper> createHrgActivities(String accountId, Integer nbrNewOngoingActivities) {    
        User curUser = [Select Id, Name, Email, Profile.Name from User where Id = :UserInfo.getUserId()];
        
        hrgActWrapList = new List<HRGWrapper>();    
        for (Integer i = 0; i<nbrNewOngoingActivities; i++)
        {    HRGWrapper hrgWrap = new HRGWrapper();
         ReferenceHRGActivity__c hrgActivity = new ReferenceHRGActivity__c(Account__c=accountId, Assigned_to__c=curUser.Id, Notes__c='',
                                                                           Type__c='',Activity_Type__c='',Activity__c='',Activity_Date__c=null);
         hrgWrap.recId = String.valueOf(i);
         hrgWrap.activity = hrgActivity;                         
         hrgActWrapList.add(hrgWrap);
        }   
        return hrgActWrapList;
        
    } // createHrgActivities
    
    @RemoteAction
    public static Reference_HRG__c getRefHRG(string acctId) {
        ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
        return refHRGCtrllr.refHRG;
    } // getRefHRG
    
    @RemoteAction
    public static List<map<string,string>> getProductFields(string acctId) {
        List<map<string,string>> productFieldNames = new List<map<string,string>>();
        ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
        for(schema.FieldSetMember f:refHRGCtrllr.getProductFields()){
            map<string,string> tmpMap = new map<string,string>();
            tmpMap.put(f.fieldPath,f.Label);
            productFieldNames.add(tmpMap);
        }
        return productFieldNames;
    } // getProductFields
    
    @RemoteAction
    public static List<ActWrapper> getOpenSFActivities(string acctId) {
        List<ActWrapper> openSFActivities = new List<ActWrapper>();
        ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
        for(ActivityWrapper aw : refHRGCtrllr.sortedOpenActivityList){
            if(!aw.hasHRGActivity){
                ActWrapper awrap = new ActWrapper();
                awrap.key = aw.key;
                awrap.tsk = aw.tsk; 
                awrap.evnt = aw.evnt;
                awrap.isEvent = aw.isEvent;   
                awrap.isTask= aw.isTask;
                awrap.taskOrEvent= aw.taskOrEvent;
                if (aw.isEvent) {
                    awrap.javaDate =(Decimal.valueOf(aw.evnt.ActivityDate.month())<10?'0':'')
                        +aw.evnt.ActivityDate.month()+'/'+
                        +(Decimal.valueOf(aw.evnt.ActivityDate.day())<10?'0':'')
                        +aw.evnt.ActivityDate.day()+'/'+
                        aw.evnt.ActivityDate.year();
                }
                else {
                    awrap.javaDate = (Decimal.valueOf(aw.tsk.ActivityDate.month())<10?'0':'')
                        +aw.tsk.ActivityDate.month()+'/'
                        +(Decimal.valueOf(aw.tsk.ActivityDate.day())<10?'0':'')
                        +aw.tsk.ActivityDate.day()+'/'+
                        aw.tsk.ActivityDate.year();
                } 
                openSFActivities.add(awrap);
            }
        }          

        return openSFActivities;
    }
    
    @RemoteAction
    public static void deleteActivity(string acctId, string key) {
        ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
        refHRGCtrllr.comingFromMobile = TRUE;
        refHRGCtrllr.recsPerPage = 5000;
        refHRGCtrllr.deleteKey = key;
        refHRGCtrllr.deleteSalesforceActivity();
    }// saveRefHRG
      
    @RemoteAction
    public static void saveRefHRG(string acctId, Reference_HRG__c refHRG) {
        ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
        refHRGCtrllr.refHRG = refHRG;
        refHRGCtrllr.comingFromMobile = true;
        refHRGCtrllr.recsPerPage = 5000;
        refHRGCtrllr.performSave();
    }// saveRefHRG
    
    @RemoteAction
    public static List<HRGWrapper> getOngoingActivities(string acctId, string onbType) {
        ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
        hrgActWrapList = new List<HRGWrapper>();    
        for (ReferenceHrgActivityWrapper rHAW : refHRGCtrllr.pendingHrgActivityList)
        {    
            HRGWrapper hrgWrap = new HRGWrapper();
            hrgWrap.activity = rHAW.activity;                        
            hrgActWrapList.add(hrgWrap);
        }   
        return hrgActWrapList;
    } // getOngoingActivities
    
    @RemoteAction
    public static List<ReferenceHrgActivityWrapper> getOnboardingActivities(string acctId, string onbType) {
        ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
        if(onbType == 'Onboarding Setup'){
            system.debug('JGS OnboardingSetupList =' + refHRGCtrllr.onboardingSetupList);
            return refHRGCtrllr.onboardingSetupList;
        }
        else if(onbType == 'Onboarding Concerns'){
            return refHRGCtrllr.onboardingConcernsList;
        }
        else{
            return refHRGCtrllr.onboardingActivityList;
        }
    } // getOnboardingActivities   
    
    @RemoteAction
    public static string getAcctHealth(string acctId) {
        ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
        return refHRGCtrllr.acct.Premier_Account_Health__c;
    }// getAcctHealth
    
    @RemoteAction
    public static string processAcctHealth(string accountHealth, string notes, string acctId) {
        ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
        refHRGCtrllr.changeAccountHealth();
        refHRGCtrllr.comingFromMobile = true;
        refHRGCtrllr.recsPerPage = 5000;
        refHRGCtrllr.acct.Premier_Account_Health__c = accountHealth;
        refHRGCtrllr.acctHealthActivity.notes__c = notes;
        refHRGCtrllr.setAccountHealth();
        return refHRGCtrllr.acct.Premier_Account_Health__c;
    }// processAcctHealth
    
    @RemoteAction
    global static List<ActWrapper> processHRGActivities(List<HRGWrapper> newHRGActWrapList, String acctId) {
        ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
        refHRGCtrllr.setupLogActivityOptions();
        refHRGCtrllr.comingFromMobile = true;
        refHRGCtrllr.recsPerPage = 5000;
        for (HRGWrapper hrgActWrap : newHRGActWrapList)
        {    
            ReferenceHRGActivityWrapper refHRGActWrap = new ReferenceHRGActivityWrapper(hrgActWrap.recId, hrgActWrap.activity);
            refHRGActWrap.originalNotesSize =0;                   
            if(hrgActWrap.activity.Activity_Type__c == ReferenceHRGController.TYPE_ONBOARDING_ISSUES){
                for (ReferenceHRGActivityWrapper onbRefHRGAct :refHRGCtrllr.onboardingSetupList){
                    if(onbRefHRGAct.activity.Activity__c == hrgActWrap.activity.Activity__c){
                        onbRefHRGAct.activity = hrgActWrap.activity;
                    }
                }
            }
            else if(hrgActWrap.activity.Activity_Type__c == ReferenceHRGController.TYPE_ONBOARDING_CONCERNS){
                for (ReferenceHRGActivityWrapper onbRefHRGAct :refHRGCtrllr.onboardingConcernsList){
                    if(onbRefHRGAct.activity.Activity__c == hrgActWrap.activity.Activity__c){
                        onbRefHRGAct.activity = hrgActWrap.activity;
                    }
                }
            }
            else if(hrgActWrap.activity.Activity_Type__c == ReferenceHRGController.TYPE_ONBOARDING){
                for (ReferenceHRGActivityWrapper onbRefHRGAct :refHRGCtrllr.onboardingActivityList){
                    if(onbRefHRGAct.activity.Activity__c == hrgActWrap.activity.Activity__c){
                        onbRefHRGAct.activity = hrgActWrap.activity;
                    }
                }
            }
            else if(refHRGActWrap.activity != NULL && refHRGActWrap.activity.id != NULL){
                for (ReferenceHRGActivityWrapper refHRGAct :refHRGCtrllr.pendingHrgActivityList){
                    if(refHRGAct.activity.id == hrgActWrap.activity.id){
                        refHRGAct.activity = hrgActWrap.activity;
                    }
                }
            }
            else{
                refHRGCtrllr.ongoingActivityList.add(refHRGActWrap);           // move returned list of RefHRGActWrappers to controller's list
            }
        }
        refHRGCtrllr.nbrNewOngoingActivities = null;                       // reset number of HRG activities to add
        refHRGCtrllr.setVerifyActivityStep();                              // validates fields, creates tasks/events, builds activityToSaveList
        
        List<ActWrapper> stndActToSaveList = new List<ActWrapper>();
        for(ActivityWrapper aw : refHRGCtrllr.activityToSaveList){
            ActWrapper awrap = new ActWrapper();
            awrap.tsk = aw.tsk; 
            awrap.evnt = aw.evnt;
            awrap.isEvent = aw.isEvent;   
            awrap.isTask=aw.isTask;
            awrap.taskOrEvent=aw.taskOrEvent;
            awrap.isNew=aw.isNew;
            awrap.selectedTime=aw.selectedTime;
            if (aw.isEvent) {
                awrap.javaDate = aw.evnt.ActivityDate.year()+'-'
                    +(Decimal.valueOf(aw.evnt.ActivityDate.month())<10?'0':'')
                    +aw.evnt.ActivityDate.month()+'-'+
                    +(Decimal.valueOf(aw.evnt.ActivityDate.day())<10?'0':'')
                    +aw.evnt.ActivityDate.day();
            }
            else {
                awrap.javaDate = aw.tsk.ActivityDate.year()+'-'
                    +(Decimal.valueOf(aw.tsk.ActivityDate.month())<10?'0':'')
                    +aw.tsk.ActivityDate.month()+'-'
                    +(Decimal.valueOf(aw.tsk.ActivityDate.day())<10?'0':'')
                    +aw.tsk.ActivityDate.day();
            }           
            awrap.activityContactId=aw.activityContactId;
            
            //awrap.hrgActivity= new List<HRGWrapper>;         
            if(aw.hrgActivity != null){         
                for (ReferenceHrgActivityWrapper raw : aw.hrgActivity) {
                    HRGWrapper hw = new HRGWrapper();
                    hw.recId = raw.recId;
                    hw.activity = raw.activity;         
                    hw.completed = raw.completed;
                    hw.isNew = raw.isNew;
                    hw.isOnboarding = raw.isOnboarding;
                    awrap.hrgActivity.add(hw);
                }
            }
            stndActToSaveList.add(awrap);
        }  
        system.debug('JGS OnboardingSetupList =' + refHRGCtrllr.onboardingSetupList);
        system.debug('JGS stndActToSaveList =' + stndActToSaveList);
        return stndActToSaveList;   
        
    } // processHRGActivities
    
      @RemoteAction
      global static Boolean processStndActivities(List<ActWrapper> newStndActWrapList, String acctId, List<AccountWrapper> selectedAcctList, boolean extraAccounts, string acctListType) {
         List<ActivityWrapper> actWrapperList = new List<ActivityWrapper>();
         ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
         refHRGCtrllr.logActivitySelection = ReferenceHRGController.LOG_CONTROLLED;
        //LM refHRGCtrllr.setupExtraAccountsList();
            refHRGCtrllr.setUserId();
         refHRGCtrllr.activityToSaveList = new List<ActivityWrapper>();
         for (ActWrapper actWrap : newStndActWrapList)
         {    ActivityWrapper stndActWrapper;
              boolean isOnboarding = FALSE;
              boolean isOngoing = FALSE;
              if (actWrap.isTask)
              {    stndActWrapper = new ActivityWrapper(actWrap.tsk);              
                   stndActWrapper.tsk.ActivityDate = convertJavaDate(actWrap.javaDate);
                   stndActWrapper.tsk.Date_Activity_Completed__c = convertJavaDate(actWrap.javaDateCompl);               
              }
              else
              {    stndActWrapper = new ActivityWrapper(actWrap.evnt);
                   stndActWrapper.evnt.ActivityDate = convertJavaDate(actWrap.javaDate);
                   stndActWrapper.selectedTime = actWrap.selectedTime+':00';
                   System.debug('**CMF ** processStndActivities, javaDateCompl='+actWrap.javaDateCompl+';');    
                   if (actWrap.javaDateCompl != null && actWrap.javaDateCompl.length()>0)
                   {    stndActWrapper.evnt.Date_Activity_Completed__c = convertJavaDate(actWrap.javaDateCompl);    }
                   else
                   {    stndActWrapper.evnt.Date_Activity_Completed__c = null;  }
              }
              for(hrgWrapper hrgActWrap : actWrap.hrgActivity){
                  if(hrgActWrap.activity.Activity_Type__c == ReferenceHRGController.TYPE_ONBOARDING_ISSUES){
                      for (ReferenceHRGActivityWrapper onbRefHRGAct :refHRGCtrllr.onboardingSetupList){
                          if(onbRefHRGAct.activity.Activity__c == hrgActWrap.activity.Activity__c){
                              onbRefHRGAct.activity = hrgActWrap.activity;
                              stndActWrapper.addHRGActivity(onbRefHRGAct);
                              isOnboarding = TRUE;
                          }
                      }
                  }
                  else if(hrgActWrap.activity.Activity_Type__c== ReferenceHRGController.TYPE_ONBOARDING_CONCERNS){
                      for (ReferenceHRGActivityWrapper onbRefHRGAct :refHRGCtrllr.onboardingConcernsList){
                          if(onbRefHRGAct.activity.Activity__c == hrgActWrap.activity.Activity__c){
                              onbRefHRGAct.activity = hrgActWrap.activity;
                              stndActWrapper.addHRGActivity(onbRefHRGAct);
                              isOnboarding = TRUE;
                          }
                      }
                  }
                  else if(hrgActWrap.activity.Activity_Type__c == ReferenceHRGController.TYPE_ONBOARDING){
                      for (ReferenceHRGActivityWrapper onbRefHRGAct :refHRGCtrllr.onboardingActivityList){
                          if(onbRefHRGAct.activity.Activity__c == hrgActWrap.activity.Activity__c){
                              onbRefHRGAct.activity = hrgActWrap.activity;
                              stndActWrapper.addHRGActivity(onbRefHRGAct);
                              isOnboarding = TRUE;
                          }
                      }
                  }
                  else if(hrgActWrap.activity != NULL && hrgActWrap.activity.id != NULL){
                      for (ReferenceHRGActivityWrapper refHRGAct :refHRGCtrllr.pendingHrgActivityList){
                          if(refHRGAct.activity.id == hrgActWrap.activity.id){
                              refHRGAct.activity = hrgActWrap.activity;
                              stndActWrapper.addHRGActivity(refHRGAct);
                          }
                      }                 
                  }
                  else{
                      stndActWrapper.addHRGActivity(new ReferenceHRGActivityWrapper(hrgActWrap.recId, hrgActWrap.activity));
                  }
              }
              system.debug('JGS stndActWrapper =' + stndActWrapper);
              refHRGCtrllr.activityToSaveList.add(stndActWrapper);
         }
         refHRGCtrllr.comingFromMobile = true;
         if(extraAccounts){
            if(acctListType == 'LOG_CONTROLLED'){
                refHRGCtrllr.logActivitySelection = ReferenceHRGController.LOG_CONTROLLED;
            }
            else{
                refHRGCtrllr.logActivitySelection = ReferenceHRGController.LOG_CLIENTS;
            }
            refHRGCtrllr.performSave();
            for(AccountWrapper acctW: selectedAcctList){
                if(acctW.selected == TRUE){
                    for(ReferenceHRGController.acctWrapper refAW: refHRGCtrllr.extraAcctsList){
                         if(acctW.acctId == refAW.acct.id){
                            refAW.selected = TRUE;
                            extraAccounts = TRUE;
                         }
                    }
                }
            }
            refHRGCtrllr.saveAdditionalActivity();          
         }
         else{
            refHRGCtrllr.performSave();
         }
         return True;
     
      } // processStndActivities
    
      @RemoteAction
      global static List<AccountWrapper> AdditionalAccounts(String acctId,string type) {
        ReferenceHRGController refHRGCtrllr = new ReferenceHRGController((Id) acctId);
        refHRGCtrllr.comingFromMobile = true;
        list<AccountWrapper> awList = new list<AccountWrapper>();
        if(type == 'LOG_CONTROLLED'){
            refHRGCtrllr.logActivitySelection = ReferenceHRGController.LOG_CONTROLLED;
        }
        else{
            refHRGCtrllr.logActivitySelection = ReferenceHRGController.LOG_CLIENTS;
        }
        //LM refHRGCtrllr.setupExtraAccountsList();
        refHRGCtrllr.setUserId();
        system.debug('JGS refHRGCtrllr.extraAcctsList=' + refHRGCtrllr.extraAcctsList);
        for(referenceHRGController.acctWrapper aw: refHRGCtrllr.extraAcctsList){
            awList.add(new AccountWrapper(aw.acct));  
        }
        return awList;          
      } // getAdditionalAccounts
    
      global class AccountWrapper {
         public AccountWrapper(Account p_acct) {
            acctId = p_acct.Id;
            acctName = p_acct.Name;
            acctNumber = p_acct.AccountNumber;
            // default everything to selected?
            selected = false;
         } // AccountWrapper 
         public Boolean selected{get;set;}
         public string acctNumber{get;set;}
         public string acctId{get;set;}
         public string acctName{get;set;}
      } // class AccountWrapper
     
      public static List<String> hrgTypes;  // used for Type picklist 
    
      @RemoteAction
      global static List<String> gethrgTypes() {
          if (hrgTypes == null) {
    
            hrgTypes = new List<String>();
            Schema.DescribeFieldResult field = ReferenceHRGActivity__c.Type__c.getDescribe();
    
            for (Schema.PicklistEntry f : field.getPicklistValues())
              hrgTypes.add(f.getLabel());
    
          }
          return hrgTypes;                
      } // gethrgTypes
    
      public static List<String> hrgActivityTypes;  // used for Activity Type picklist  
      @RemoteAction
      global static List<String> gethrgActivityTypes() {
          if (hrgActivityTypes == null) {
    
            hrgActivityTypes = new List<String>();
            Schema.DescribeFieldResult field = ReferenceHRGActivity__c.Activity_Type__c.getDescribe();
    
            for (Schema.PicklistEntry f : field.getPicklistValues())
              hrgActivityTypes.add(f.getLabel());
    
          }
          return hrgActivityTypes;                
      } // gethrgActivityTypes
      
      @RemoteAction
            global static Map<String,List<String>> gethrgActivities() {
            return HRGActivitiesMobilePageController.GetDependentOptions('ReferenceHRGActivity__c', 'Activity_Type__c', 'Activity__c');                
        } // gethrgActivities
     
      /*
    * @Summary: Entity to represent a json version of a picklist entry
    * so that the validFor property becomes exposed
    */
    public class TPicklistEntry{
        public string active {get;set;}
        public string defaultValue {get;set;}
        public string label {get;set;}
        public string value {get;set;}
        public string validFor {get;set;}
        public TPicklistEntry(){
        }
    } // TPicklistEntry

    public static Map<String,List<String>> GetDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName){
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        //get the string to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        if (!Schema.getGlobalDescribe().containsKey(pObjName)){
            return objResults;
        }
        //get the type being dealt with
        Schema.SObjectType pType = Schema.getGlobalDescribe().get(pObjName);
        return GetDependentOptionsImpl(pType,pControllingFieldName,pDependentFieldName);        
    } // GetDependentOptions
    
    public static Map<String,List<String>> GetDependentOptionsImpl(Schema.SObjectType pType, String pControllingFieldName, String pDependentFieldName){
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        if (pType==null){
            return objResults;
        }
        Bitset BitSetInstance = new Bitset();
        Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();
        //verify field names
        if (!objFieldMap.containsKey(pControllingFieldName) || !objFieldMap.containsKey(pDependentFieldName)){
            return objResults; 
        }
        //get the control values   
        List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
        //get the dependent values
        List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();
        objFieldMap = null;
        List<Integer> lstControllingIndexes = new List<Integer>();
        //iterate through the values and get the ones valid for the controlling field name
        //set up the results
        for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++){           
            //get the pointer to the entry
            Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
            //get the label
            String pControllingLabel = ctrl_entry.getLabel();
            //create the entry with the label
            objResults.put(pControllingLabel,new List<String>());
            //keep track of the controlling indexes
            lstControllingIndexes.add(pControllingIndex);
        }
        //cater for null and empty
        objResults.put('',new List<String>());
        objResults.put(null,new List<String>());
        //load all dep entries
        List<Schema.PicklistEntry> objEntries = new List<Schema.PicklistEntry>();
        List<TPicklistEntry> objDS_Entries = new List<TPicklistEntry>();
        //add all entries
        for(Integer pDependentIndex=0; pDependentIndex<dep_ple.size(); pDependentIndex++){          
            //get the pointer to the dependent index
            Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
            objEntries.add(dep_entry); 
        } 
        //serialize once        
        objDS_Entries = (List<TPicklistEntry>)JSON.deserialize(JSON.serialize(objEntries), List<TPicklistEntry>.class);
        List<Integer> validIndexes;
        for (TPicklistEntry objDepPLE : objDS_Entries){
            //if valid for is empty, skip    
            if (objDepPLE.validFor==null || objDepPLE.validFor==''){
                continue;
            }
            //get the test for the controlling indexes
            validIndexes = BitSetInstance.testBits(objDepPLE.validFor,lstControllingIndexes);
            for (Integer validIndex : validIndexes){                
                //get the label
                String pControllingLabel = ctrl_ple[validIndex].getLabel();
                objResults.get(pControllingLabel).add(objDepPLE.label);
            }
        }
        objEntries = null;
        objDS_Entries = null;
        return objResults;
    } // GetDependentOptionsImpl
      
    public class Bitset{
        public Map<String,Integer> AlphaNumCharCodes {get;set;}
        public Map<String, Integer> Base64CharCodes { get; set; }
        public Bitset(){
            LoadCharCodes();
        }
        //Method loads the char codes
        private void LoadCharCodes(){
            AlphaNumCharCodes = new Map<String,Integer>{
            'A'=>65,'B'=>66,'C'=>67,'D'=>68,'E'=>69,'F'=>70,'G'=>71,'H'=>72,'I'=>73,'J'=>74,
            'K'=>75,'L'=>76,'M'=>77,'N'=>78,'O'=>79,'P'=>80,'Q'=>81,'R'=>82,'S'=>83,'T'=>84,
            'U'=>85,'V'=> 86,'W'=>87,'X'=>88,'Y'=>89,'Z'=>90    
            };
            Base64CharCodes = new Map<String, Integer>();
            //lower case
            Set<String> pUpperCase = AlphaNumCharCodes.keySet();
            for(String pKey : pUpperCase){
                //the difference between upper case and lower case is 32
                AlphaNumCharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey)+32);
                //Base 64 alpha starts from 0 (The ascii charcodes started from 65)
                Base64CharCodes.put(pKey,AlphaNumCharCodes.get(pKey) - 65);
                Base64CharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey) - (65) + 26);
            }
            //numerics
            for (Integer i=0; i<=9; i++){
                AlphaNumCharCodes.put(string.valueOf(i),i+48);
                //base 64 numeric starts from 52
                Base64CharCodes.put(string.valueOf(i), i + 52);
            }
        }
        /*
        Effect: Method takes a validFor string and tests it against a set of controlling indexes
        Postcondition: Returns a list of all controlling indexes for which the validFor string test True
        */
        public List<Integer> testBits(String pValidFor,List<Integer> nList){
            List<Integer> results = new List<Integer>();
            //the list of bytes (not derived from n)
            List<Integer> pBytes = new List<Integer>();
            //multiply by 6 since base 64 uses 6 bits (not derived form n)
            Integer bytesBeingUsed = (pValidFor.length() * 6)/8;
            //will be used to hold the full decimal value (not derived from n)
            Integer pFullValue = 0;
            //must be more than 1 byte
            if (bytesBeingUsed <= 1){
                return results;
            }
            //get the base64bytes
            for(Integer i=0;i<pValidFor.length();i++){
                //get currenct character value
                pBytes.Add((Base64CharCodes.get((pValidFor.Substring(i, i+1)))));
            }   
            //calculate the full decimal value
            for (Integer i = 0; i < pBytes.size(); i++)
            {
                Integer pShiftAmount = (pBytes.size()-(i+1))*6;//used to shift by a factor 6 bits to get the value
                pFullValue = pFullValue + (pBytes[i] << (pShiftAmount));
            }
            //now we don't want to always be declaring memory, so let's set the initial 
            //variables
            Integer bit;
            Integer targetOctet;
            Integer shiftBits;
            Integer tBitVal;
            Integer n;
            Integer nListSize = nList.size();
            for(Integer i=0; i<nListSize; i++){
                n = nList[i];
                //calculate the target bit for comparison
                bit = 7 - (Math.mod(n,8)); 
                //calculate the octet that has in the target bit
                targetOctet = (bytesBeingUsed - 1) - (n >> bytesBeingUsed); 
                //the number of bits to shift by until we find the bit to compare for true or false
                shiftBits = (targetOctet * 8) + bit;
                //& is to set the same set of bits for testing
                //shift to the bit which will dictate true or false
                //Math.Pow(2, shiftBits) == 2 << (shiftBits+1)
                tBitVal = ((Integer)(2 << (shiftBits-1)) & pFullValue) >> shiftBits;
                if (tBitVal==1){
                    results.add(n);
                }
            }
            return results;
        } // testBits
        
    } //Bitset

    // we cant send ActivityWrapper and ReferenceHRGActivityWrapper back and forth so we made our own scaled down versions
    global class ActWrapper {
        public Task tsk{get;set;}
        public Event evnt{get;set;}
        public Boolean isEvent{get;set;}        /** Is this an event? If it is not an event, it is assumed to be a task. */  
        public Boolean isTask{get;set;}
        public String taskOrEvent{get;set;}
        public Boolean isNew{get;set;}  
        public String selectedTime{get;set;}
        public String javaDate{get;set;}            /** used to hold converted SFDC date to yyyy-mm-dd */
        public String javaDateCompl{get;set;}       /** used to hold converted SFDC date to yyyy-mm-dd */
        /** If this is associated with a Contact - the contact id. */
        public String activityContactId{get;set;}
        public string key{get;set;}
        public List<HRGWrapper> hrgActivity{get;set;}
        /** constructor */
        public ActWrapper(){
                hrgActivity = new List<HRGWrapper>();
        }      
        
    }
    
    global class HRGWrapper {
         public String recId{get;set;}
         public ReferenceHRGActivity__c activity{get;set;}
         public Boolean completed{get;set;}
         public Boolean isNew{get;set;}
         public Boolean isOnboarding{get;set;}
         public String dateFieldName{get;set;}
         public String notesFieldName{get;set;}
         public integer originalNotesSize{get;set;}
    }    
        
    /* translate javaDate to sfdc Date */
    public static Date convertJavaDate(String javaDate) {
        System.debug('**CMF ** convertingJavaDate, javaDate='+javaDate);
        Date sfdcDate;
        if (javaDate != null && javaDate.length() > 0) {
            List<String> splitDate = javaDate.split('-');       
            sfdcDate = Date.newInstance(Integer.valueOf(splitDate[0]), Integer.valueOf(splitDate[1]), Integer.valueOf(splitDate[2]));
            //Date sfdcDate = Date.newInstance(2015, 3, 20);        
        }
        System.debug('**CMF ** convertingJavaDate-'+javaDate+' to '+sfdcDate);
        return sfdcDate;
        
    } // convertJavaDate
    
    /* translate javaTime to sfdc Time 
    public static Time convertJavaTime(String javaTime) {
        System.debug('**CMF ** convertingJavaTime, javaTime='+javaTime);        
        List<String> splitTime = javaTime.split(':');       
        Time sfdcTime = Time.newInstance(Integer.valueOf(splitTime[0]), Integer.valueOf(splitTime[1]),0,0);
        //Time sfdcTime = Time.newInstance(9, 45, 0, 0);
        System.debug('**CMF ** convertingJavaTime-'+javaTime+' to '+sfdcTime);
        return sfdcTime;
        
    } // convertJavaDate
    */
    
} // HRGActivitiesMobilePageController