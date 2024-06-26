/* 
* When updates from Opportunities trigger changes to the accounts
*
* History
* -------
09/06/2018 Dan Carmen        Created
12/20/2018 Cindy Freeman     Modified to handle if opp owner changed and it has specific referral partner, set acct owner = opty owner
02/05/2019 Cindy Freeman     Fix possible null pointer if HO description not in HO Dictionary
03/12/2019 Cindy Freeman     add to ProcessNotes and debug statements
06/25/2019 Brandon Vidro     Modified checkOpps to update Current_Prior_Method__c on Account
10/14/2019 Brandon Vidro     Added check for null values in checkOpps when updating Current_Prior_Methods__c on Account
05/29/2020 Dan Carmen        Updated so everything updates only once.
07/24/2020 Jake Hinds        Automation for Service Model Type
08/14/2020 Dan Carmen        Update to check multiple conditions for holdouts.
08/18/2020 Jake Hinds        Another update for Service Model Type
09/08/2020 Brandon Vidro     36882061 - Use Sales Cycle End Date instead of isClosed
10/07/2020 Manmeet Vaseer    Added ErrorLog to debug INC2475380 (Auto Hold Outs).
10/21/2020 Dan Carmen        Add Local_Competitors__c field to copy from Opp
10/26/2020 Dan Carmen        Added extra debugging
02/08/2021 Matt Fritschi		Extends SMB Channel Hold Out for created Opptys.
02/21/2021 Brandon Vidro     Create automatic crossover for HRS
05/18/2021 Carrie Marciano	Updated to use OppStage labels
05/21/2021 Karthik Pedditi	Updating Account owner when the owner is SMB Channel/SMB Virtual Channel.
06/08/2021 Jermaine Stukes	Add logic to update ASO/PEO Owner in occordance with APR0118366 - FY22 HR Services Segmentation
07/13/2021 Josh Cartwright	restructured checkCreatedOpp method 	
11/22/2022 Carrie Marciano	oppty renewal date, covert to month abbreviation map, update Account Workers Comp Renewal Date for P&C oppties
*/

public with sharing class OpptyUpdateAcct implements TriggerInterface2 {
    //public static Set<Id> oppIdOwnerChgSet = new Set<Id>();
    public static String[] ACCT_TYPES_FOR_HOLDOUTS = Label.OppTypeAccountHoldout.split(',');
    
    public static Map<String,Schema.RecordTypeInfo> rtByName =  Opportunity.getSobjectType().getDescribe().getRecordTypeInfosByName();
    public static Id asoId = rtByName.get('ASO Opportunity Record Type').getRecordTypeId();
    public static Id asoFSSId = rtByName.get('ASO Opportunity FSS Record Type').getRecordTypeId();
    public static id coreId = rtByName.get('Core Opportunity Record Type').getRecordTypeId();
    public static id coreDSAId = rtByName.get('Core Opportunity DSA Record Type').getRecordTypeId();
    public static id coreVirtualId = rtByName.get('Core Virtual Sales').getRecordTypeId();
    public static id mmsId = rtByName.get('MMS Opportunity Record Type').getRecordTypeId();
    public static id mmsDsaId = rtByName.get('MMS Opportunity (DSA) Record Type').getRecordTypeId();
    public static id pcId = rtByName.get('PC Opportunity Record Type').getRecordTypeId();
    public static id pcDsaId = rtByName.get('PC Opportunity DSA Record Type').getRecordTypeId();                                               
    //public static id prismPeoFssId = rtByName.get('Prism PEO Opportunity FSS Record Type').getRecordTypeId();
    //public static id prismPeoId = rtByName.get('Prism PEO Opportunity Record Type').getRecordTypeId();
    
    public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
        System.debug('OpptyUpdateAcct.triggerCheckAllFirst recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
        if (isAfter) {
            Map<Id,String> prevStageMap = new Map<Id,String>();
            Set<Id> oppIdSet = new Set<Id>();
            Set<Id> acctIdSet = new Set<Id>();
            Set<Id> oppIdOwnerChgSet = new Set<Id>();
            Set<Id> insertedOppIdSet = new Set<Id>();
            
            ErrorLog__c log = new ErrorLog__c(ClassName__c='OpptyUpdateAcct',MethodName__c='triggerCheckAllFirst', CodeKey__c='LOG_DATA');
            
            Opportunity[] opps = (Opportunity[])recs;
            Map<Id,Opportunity> oldOppMap = (Map<Id,Opportunity>)oldMap;
            for (Opportunity opp : opps) {
                log.ObjectId__c=opp.Id;
                log.ObjectAPIName__c='Opportunity';
                
                Opportunity oldOpp = (oldOppMap != null ? oldOppMap.get(opp.Id) : null);
                String logMsg = 'triggerCheckAllFirst oldOpp.StageName=' +(oldOpp != null ? oldOpp.StageName : 'Insert')+', opp.StageName='+opp.StageName;
                System.debug(logMsg); 
                ErrorLog.addToDescription(log,logMsg);             
                if (opp.AccountId != null && String.isNotBlank(opp.OpportunityType__c) 
                    && (oldOpp == null || opp.StageName != oldOpp.StageName)) {     
                        oppIdSet.add(opp.Id);
                        acctIdSet.add(opp.AccountId);
                        if (oldOpp != null) {
                            prevStageMap.put(opp.Id, oldOpp.StageName);
                        }
                } // if (stageName changed..)
                
                //If P&C opportunity and Renewal Date is updated need to update account Workers Comp Renewal Date
                if((opp.RecordTypeId == pcId || opp.RecordTypeId == pcDsaId) && opp.OpportunityType__c=='Workers Comp' 
                    && opp.Renewal_Date__c != null && (oldOpp == null || opp.Renewal_Date__c != oldOpp.Renewal_Date__c)){
                    oppIdSet.add(opp.Id);
                    acctIdSet.add(opp.AccountId);
                    System.debug('OpptyUpdateAcct.triggerCheckAllFirst added P&C oppty to oppIdSet');   
                }
                
                ErrorLog.addToDescription(log,'opp.AccountId=' + opp.AccountId +', opp.ReferralLookup__c=' + opp.ReferralLookup__c +', has oldOpp: ' + (oldOpp!=null) +', opp.OwnerId: ' + opp.OwnerId 
                                          +', oldOpp.OwnerId=' + (oldOpp==null?'null':oldOpp.OwnerId));
                ErrorLog.addToDescription(log, 'opp.OpportunityType__c=' + opp.OpportunityType__c + ', Label.OppTypeAccountHoldout=' + Label.OppTypeAccountHoldout);
                // capture opps that are inserts with lookup to referral record OR where the owner changed
                if (opp.AccountId != null && opp.ReferralLookup__c != null && (oldOpp == null || opp.OwnerId != oldOpp.OwnerId)) {
                    acctIdSet.add(opp.AccountId);
                    oppIdOwnerChgSet.add(opp.Id);
                    ErrorLog.addToDescription(log, opp.Id + ' oppId is added to oppIdOwnerChgSet.');
                } 
                if (oldOpp == null && opp.AccountId != null && String.isNotBlank(opp.OpportunityType__c) && ACCT_TYPES_FOR_HOLDOUTS.contains(opp.OpportunityType__c)) {
                    // if an opportunity is created by a rep with a sales division of... and the owner is different, set a hold out. 
                    acctIdSet.add(opp.AccountId);
                    insertedOppIdSet.add(opp.Id);
                    ErrorLog.addToDescription(log, opp.Id + ' oppId is added to insertedOppIdSet.');
                }
                
            } // for (Opportunity opp : opps
            String logMsg = 'OpptyUpdateAcct.triggerCheckAllFirst oppIdSet=' +oppIdSet.size()+' acctIdSet='+acctIdSet.size()+' oppIdOwnerChgSet='+oppIdOwnerChgSet.size()+' insertedOppIdSet='+insertedOppIdSet.size();
            System.debug(logMsg);
            ErrorLog.addToDescription(log,logMsg);
            ErrorLog.saveLog(log);
            
            checkAcctAttributes(oppIdSet, acctIdSet, prevStageMap, oppIdOwnerChgSet, insertedOppIdSet);
        } // if (isAfter
    } // triggerCheckAllFirst
    
    // check each record individually
    public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
    
    // see if there are any actions that need to take place at the end of the trigger.
    public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
    
    // for testing purposes, to process the records now instead of the future context
    public static Boolean TEST_PROCESS_NOW=false;
    
    public static void checkAcctAttributes(Set<Id> oppIdSet, Set<Id> acctIdSet, Map<Id,String> prevStageMap, Set<Id> oppIdOwnerChgSet, Set<Id> insertedOppIdSet) {
        if (!acctIdSet.isEmpty()) {
            if (TEST_PROCESS_NOW || System.isFuture() || System.isBatch()) {
                processAcctAttributesNow(oppIdSet, acctIdSet, prevStageMap, oppIdOwnerChgSet, insertedOppIdSet);
            } else {
                processAcctAttributesFuture(oppIdSet, acctIdSet, prevStageMap, oppIdOwnerChgSet, insertedOppIdSet);
            }
        }
    } // checkAcctAttributes
    
    
    public static void processAcctAttributesFuture(Set<Id> oppIdSet, Set<Id> acctIdSet, Map<Id,String> prevStageMap, Set<Id> oppIdOwnerChgSet, Set<Id> insertedOppIdSet) {
        processAcctAttributesNow(oppIdSet, acctIdSet, prevStageMap, oppIdOwnerChgSet, insertedOppIdSet);
    }
    
    public static Set<String> PAY_OPP_TYPES = new Set<String>(Label.OppTypes_PAY.split(',')); 
    public static Set<String> HRS_OPP_TYPES = new Set<String>(Label.OppTypes_HRS.split(',')); 
    
    public static void processAcctAttributesNow(Set<Id> oppIdSet, Set<Id> acctIdSet, Map<Id,String> prevStageMap, Set<Id> oppIdOwnerChgSet, Set<Id> insertedOppIdSet) {
        ErrorLog__c log = new ErrorLog__c(ClassName__c='OpptyUpdateAcct',MethodName__c='processAcctAttributesNow', CodeKey__c='LOG_DATA');
        String logMsg = 'processAcctAttributesNow number oppIdSet='+oppIdSet.size()+' acctIdSet='+acctIdSet.size()+' oppIdOwnerChgSet='+oppIdOwnerChgSet.size()+' insertedOppIdSet='+insertedOppIdSet.size();
        ErrorLog.addToDescription(log,logMsg);
        
        System.debug(logMsg);
        System.debug('processAcctAttributesNow PAY_OPP_TYPES='+PAY_OPP_TYPES+' HRS_OPP_TYPES='+HRS_OPP_TYPES);
        
        Account[] acctsToUpdate = new Account[]{};
            Map<Id,Account> acctUpdateMap = new Map<Id,Account>();
        Transfer_Request__c[] newCrossovers = new Transfer_Request__c[]{};
            
        Set<Id> allOppIdSet = new Set<Id>();
        allOppIdSet.addAll(oppIdSet);
        allOppIdSet.addAll(oppIdOwnerChgSet);
        allOppIdSet.addAll(insertedOppIdSet);
        
        
        Map<String,HoldOut_Dictionary__c> bySalesDivisionMap = new Map<String,HoldOut_Dictionary__c>();
        if (!insertedOppIdSet.isEmpty()) {
            logMsg = 'Adding to bySalesDivisionMap: ';
            // store in a map for easy lookup later
            for (HoldOut_Dictionary__c hod : HoldOut_Dictionary__c.getAll().values()) {
                if (String.isNotBlank(hod.SalesDivisionsToSet__c)) {
                    String[] salesDivs = hod.SalesDivisionsToSet__c.split(',');
                    for (String salesDiv : salesDivs) {
                        logMsg += salesDiv+', ';
                        bySalesDivisionMap.put(salesDiv, hod);
                    }
                } // if (String.isNotBlank(hod.SalesDivisionsToSet__c
                if (String.isNotBlank(hod.ProductGroupSelected__c)) {
                    String[] ProductGroups = hod.ProductGroupSelected__c.split(',');
                    for (String pgs : ProductGroups) {
                        logMsg += pgs+', ';
                        bySalesDivisionMap.put(pgs, hod);
                    } 
                } // if (String.isNotBlank(hod.ProductGroupSelected__c
            } // for (HoldOut_Dictionary__c hod
            ErrorLog.addToDescription(log,logMsg);
        } // if (!insertedOppIdSet.isEmpty
        
        
        if (!allOppIdSet.isEmpty() && !acctIdSet.isEmpty()) {
            Account[] accts = [Select Id
                               ,Current_Non_Payroll_Client__c
                               ,CurrentClient__c
                               ,Current_Prior_Method__c
                               ,First_Run_Date__c, HRS_Hold_Out__c ,HRS_Hold_Out_Expiration__c ,HRS_Account_Owner__c  
                               ,Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c
                               ,HRSOppCreatedDate__c, HRSOppNSSSource__c, HRSOppStatus__c, HRSOppDateNotSold__c,Owner.Sales_Division__c
                               ,isChild__c
                               ,LatestHRSOpp__c
                               ,LatestPayrollOpp__c
                               ,Local_Competitors__c
                               ,Name
                               ,NumberOfEmployees
                               ,OpportunityTypes__c
                               ,OwnerId
                               ,PayOppCreatedDate__c, PayOppNSSSource__c, PayOppStatus__c, PayOppDateNotSold__c
                               ,Premier_PBS_Hold_Out__c, Premier_PBS_Hold_Out_Expiration__c , Premier_PBS_Account_Owner__c 
                               ,ProcessNotes__c
                               ,Service_Model_Type__c
                               ,Target_Field__c  
                               ,Work_Comp_Renewal_Date__c
                               ,(Select Id, Name, StageName, CloseDate, OwnerId, Owner.Name, Owner.HR_Services_Partner__c, Owner.Sales_Division__c, Owner.Job_Name__c,
                                        account.Owner.Sales_Division__c,Owner.District_Name__c,
                                        Account.ownerId,
                                        account.Owner.Name
                                       ,AdditionalProductsOfInterest__c
                                       ,CreatedDate
                                       ,EvaluateProductGroup__c
                                       ,IsClosed
                                       ,IsLatestOpp__c
                                       ,Local_Competitors__c
                                       ,NSS_Source__c
                                       ,OpportunityType__c
                                       ,Payroll_Current_Prior_Method__c
                                       ,Probability
                                       ,ProductGroupsSelected__c
                                       ,RecordType.Name
                                       ,RecordType.Id
                                       ,RecordTypeId
                                       ,ReferralLookup__c
                                       ,ReferralLookup__r.Referral_Partner__c, ReferralLookup__r.Referral_Partner__r.Name, ReferralLookup__r.Referral_Partner__r.Permanent_Hold_Out_Description__c
                                       ,Referring_Employee__c
                                       ,Referring_Employee__r.User_Lookup__c
                                       ,Service_Location__c
                                       ,Sales_Cycle_End_Date__c
                                 	   ,Renewal_Date__c	
                                   From Opportunities
                                  Where Id in :allOppIdSet
                                     or IsClosed = false
                                   order by CreatedDate desc)
                               From Account
                               Where Id in :acctIdSet];
            ErrorLog.addToDescription(log,'Number of accts='+accts.size());
            for (Account acct : accts) {
                checkOpps(acct, oppIdSet, acctUpdateMap, prevStageMap, oppIdOwnerChgSet, insertedOppIdSet, bySalesDivisionMap, newCrossovers, log);
            } // for (Account acct
        } // if (!oppIdSet.isEmpty())
        
        ZipCheckOwner.SKIP_TRIGGERS=true;
        DmlHelper.performDML2(acctUpdateMap.values(), DmlHelper.DML_UPDATE, 'OpptyUpdateAcct', 'processAcctAttributesNow', 'updating accounts', false);
        ZipCheckOwner.SKIP_TRIGGERS=false;
        DmlHelper.performDML2(newCrossovers, DmlHelper.DML_INSERT, 'OpptyUpdateAcct', 'processAcctAttributesNow', 'insert crossover record', false);
        ErrorLog.checkSave();
        
    } // processAcctAttributesNow
    
   public static String[] oppOwnerDistricts = Label.OpportunityOwnerDistrict.split(',');
    
   public static void checkOpps(Account acct, Set<Id> oppIdSet, Map<Id,Account> acctUpdateMap, Map<Id,String> prevStageMap, Set<Id> oppIdOwnerChgSet, Set<Id> insertedOppIdSet
                                                  , Map<String,HoldOut_Dictionary__c> bySalesDivisionMap, Transfer_Request__c[] newCrossovers, ErrorLog__c log) {
      Boolean acctChanged = false;
      Set<String> oppTypeSet = new Set<String>();
      Boolean hasMMSOpps = false;
      Boolean hasOpenMMSOpps = false;
      Boolean hasMPSCOpp = false;
      Boolean hasSoldPAYASOMMSOpp = false;
      Integer oppRenewal = 0;
      String  oppMonth = ''; 
                                                      
      Set<Id> serviceModelRTs = new Set<id>{coreId, coreDSAId, coreVirtualId, mmsId, mmsDsaId,asoId,asoFSSId};
      //Set<id> recordTypeIds = new Set<id>{coreId, coreDSAId, coreVirtualId, mmsId, mmsDsaId, prismPeoFssId, prismPeoId};
      Set<id> recordTypeIds = new Set<id>{coreId, coreDSAId, coreVirtualId, mmsId, mmsDsaId};
      List<String> smtTriggerList = new List<String>();
      
      Map<Integer, String> dateMap = new Map<Integer,String>();
      List<String> months = new String[]{'JAN','FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'};
      for(Integer i=1; i<13; i++) {
         dateMap.put(i,months.get(i-1));
      } //for(Integer i=1) 
                                                      
	  //ErrorLog__c log = new ErrorLog__c(ClassName__c='OpptyUpdateAcct',MethodName__c='checkOpps', CodeKey__c='LOG_DATA');          
      ErrorLog.addToDescription(log,'checkOpps acct='+acct.name+' opps='+acct.Opportunities.size());
      //ErrorLog.saveLog(log)    ;                                                      
      System.debug('checkOpps acct='+acct.name+' opps='+acct.Opportunities.size());      
                                                      
      for (Opportunity opp : acct.Opportunities) {
         if (log.ObjectId__c == null) {
            log.ObjectId__c=opp.Id;
            log.ObjectAPIName__c='Opportunity';
         }
          
         if (opp.Sales_Cycle_End_Date__c == null && String.isNotBlank(opp.OpportunityType__c)) {
            // this is to be able to set a list of opportunity types on the account
            oppTypeSet.add(opp.OpportunityType__c);
            ErrorLog.addToDescription(log, opp.OpportunityType__c + ' is added to oppTypeSet');
         }
         if (opp.RecordTypeId == mmsId || opp.RecordTypeId == mmsDsaId) {
            hasMMSOpps = true;
            hasOpenMMSOpps = (hasOpenMMSOpps || !opp.isClosed);
         }
         if(String.isNotBlank(opp.Service_Location__c) && opp.Service_Location__c.startsWith('MPSC') && serviceModelRTs.contains(opp.RecordTypeId)){
             hasMPSCOpp = true;
             smtTriggerList.add('disqualifying NCO SMT Opportunity: '+opp.Id);
         }
         if(opp.Probability >= 80 && serviceModelRTs.contains(opp.RecordTypeId)){
             smtTriggerList.add('hasSoldPayasommsOpp: '+opp.Id);
              hasSoldPAYASOMMSOpp = true;
         }
         
         String oldStage = prevStageMap.get(opp.Id);
          
         if (oppIdSet.contains(opp.Id) && (String.isBlank(oldStage) || opp.IsLatestOpp__c)) {
            Date notSoldDate = null;
            if (opp.StageName == Label.OppStage_Lost && (String.isBlank(oldStage) || opp.StageName != oldStage)) {
               notSoldDate = Date.today();
            }
            System.debug('checkOpps opp='+opp.Name+' type='+opp.OpportunityType__c);
            
            if (PAY_OPP_TYPES.contains(opp.OpportunityType__c)) { // == OPP_TYPE_PAY) {
               System.debug('checkOpps setting pay info');
               acct.LatestPayrollOpp__c = opp.Id;
               acct.PayOppCreatedDate__c = opp.CreatedDate;
               acct.PayOppNSSSource__c = opp.NSS_Source__c;
               acct.PayOppStatus__c = opp.StageName;
               acct.PayOppDateNotSold__c = notSoldDate;
               acctChanged = true;
            } else if (HRS_OPP_TYPES.contains(opp.OpportunityType__c)) { // == OPP_TYPE_HRS) {
               System.debug('checkOpps setting hrs info');
               acct.LatestHRSOpp__c = opp.Id;
               acct.HRSOppCreatedDate__c = opp.CreatedDate;
               acct.HRSOppNSSSource__c = opp.NSS_Source__c;
               acct.HRSOppStatus__c = opp.StageName;
               acct.HRSOppDateNotSold__c = notSoldDate;
               acctChanged = true;
            } 
            if (recordTypeIds.contains(opp.RecordTypeId)) {
               if(opp.Payroll_Current_Prior_Method__c != null || String.isNotBlank(opp.Local_Competitors__c)) {
                   acct.Current_Prior_Method__c = opp.Payroll_Current_Prior_Method__c;
                   acct.Local_Competitors__c = opp.Local_Competitors__c;
               }
               acctChanged = true;
            }
             
         } // if (oppIdSet.contains(opp.Id)
         
         System.debug('checkOpps opp.Renewal_Date__c: '+opp.Renewal_Date__c);
         //P&C opportunity Renewal Date will populate the Workers Comp Renewal Date on the related account 
         if ((opp.RecordTypeId == pcId || opp.RecordTypeId == pcDsaId) && opp.Renewal_Date__c != null && opp.OpportunityType__c=='Workers Comp'){
          	oppRenewal = (opp.Renewal_Date__c).month();
	        oppMonth = dateMap.get(oppRenewal);
	        acct.Work_Comp_Renewal_Date__c = oppMonth;  
            acctChanged = true;
            ErrorLog.addToDescription(log,'acct.Work_Comp_Renewal_Date__c='+acct.Work_Comp_Renewal_Date__c);
         } 
          
         String logMsg = 'opp='+opp.Id+', opp.ReferralLookup__c='+(opp.ReferralLookup__c!=null);
         if (opp.ReferralLookup__c != null) {
            logMsg += (', opp.ReferralLookup__r.Referral_Partner__c='+(opp.ReferralLookup__r.Referral_Partner__c!=null)+', Permanent_Hold_Out_Description__c: ' + opp.ReferralLookup__r.Referral_Partner__r.Permanent_Hold_Out_Description__c);
         }
         
         
		 ErrorLog.addToDescription(log, logMsg);
          
         Boolean holdOutSet = false;
         Boolean inOwnerChgSet = oppIdOwnerChgSet.contains(opp.Id);
         Boolean inInsertedOppIdSet = insertedOppIdSet.contains(opp.Id);
         ErrorLog.addToDescription(log, 'checkOpps inOwnerChgSet='+inOwnerChgSet+' inInsertedOppIdSet='+inInsertedOppIdSet);
          
         if (inOwnerChgSet && opp.ReferralLookup__c != null && opp.ReferralLookup__r.Referral_Partner__c != null && String.isNotBlank(opp.ReferralLookup__r.Referral_Partner__r.Permanent_Hold_Out_Description__c)) {
             holdOutSet = checkOppHoldOut(acct,opp,log);
             ErrorLog.addToDescription(log, 'oppIdOwnerChgSet holdOutSet='+holdOutSet+', acctChanged='+acctChanged);
             acctChanged = acctChanged || holdOutSet;
         }
         if (inInsertedOppIdSet) {
            Boolean checkCreated = checkCreatedOpp(acct,opp,bySalesDivisionMap, newCrossovers, log, holdOutSet);
            ErrorLog.addToDescription(log, 'insertedOppIdSet checkCreated='+checkCreated+', acctChanged='+acctChanged);
            acctChanged = (checkCreated || acctChanged);
         }
      } // for (Opportunity opp
      if (!smtTriggerList.isEmpty()){
         String msgs = String.join(smtTriggerList,', ');
         StringHelper.addToProcessNotes(acct,msgs);
     }
      if(hasSoldPAYASOMMSOpp && !hasMPSCOpp && string.isBlank(acct.Service_Model_Type__c)){
           acct.Service_Model_Type__c = 'NCO';
           acctChanged = true;
           ErrorLog.addToDescription(log, 'Service_Model_Type__c=' + acct.Service_Model_Type__c);
       }
      else if(hasSoldPAYASOMMSOpp && hasMPSCOpp && string.isBlank(acct.Service_Model_Type__c)){
           acct.Service_Model_Type__c = 'MPSC';
           acctChanged = true;
           ErrorLog.addToDescription(log, 'Service_Model_Type__c=' + acct.Service_Model_Type__c);          
      }
      
      if (hasMMSOpps && !hasOpenMMSOpps && acct.Target_Field__c != null) {
         acct.Target_Field__c = null;
         acctChanged = true;
         ErrorLog.addToDescription(log, 'Target_Field__c is set to null');
      }
      
      ErrorLog.addToDescription(log, 'before oppTypeSet check acctChanged=' + acctChanged);
      String acctOppTypes = null;
      if (!oppTypeSet.isEmpty()) {
         String[] oppTypeList = new String[]{};
         oppTypeList.addAll(oppTypeSet);
         oppTypeList.sort();
         acctOppTypes = String.join(oppTypeList,';');
      }
                                                      
      ErrorLog.addToDescription(log, 'checkOpps acct.OpportunityTypes__c='+acct.OpportunityTypes__c+' acctOppTypes='+acctOppTypes);
      System.debug('checkOpps acct.OpportunityTypes__c='+acct.OpportunityTypes__c+' acctOppTypes='+acctOppTypes);
      if (acct.OpportunityTypes__c != acctOppTypes) {
         acct.OpportunityTypes__c = acctOppTypes;
         acctChanged = true;
      }
      
   	  ErrorLog.addToDescription(log, 'end of checkOpps acctChanged=' + acctChanged);
      if (acctChanged) {
         acctUpdateMap.put(acct.Id,acct);
      }

	  ErrorLog.saveLog(log);                                                      
   } // checkOpps
    
    public static Boolean checkCreatedOpp(Account acct, Opportunity opp, Map<String,HoldOut_Dictionary__c> bySalesDivisionMap, Transfer_Request__c[] newCrossovers, ErrorLog__c log, boolean holdOutSet) {
        Boolean acctChanged = false;
        Boolean crossoverCreated = false;
        
        HoldOut_Dictionary__c hod = bySalesDivisionMap.get(opp.Owner.Sales_Division__c);
        if (hod != null) {
            //keep a default value of 90 days
            Integer nbrDays = (hod.InitialNbrDays__c != null ? Integer.valueOf(hod.InitialNbrDays__c) : 90);
            ErrorLog.addToDescription(log, 'checkCreatedOpp opp.OwnerId=' + opp.OwnerId + ', acct.OwnerId=' + acct.OwnerId + ', acct.Hold_Out__c=' + acct.Hold_Out__c 
                                      + ', opp.Owner.Sales_Division__c=' + opp.Owner.Sales_Division__c + ', opp.Owner.Job_Name__c=' + opp.Owner.Job_Name__c);
            if (opp.Owner != null && !acct.Hold_Out__c
                //&& String.isNotBlank(opp.Owner.Sales_Division__c) 
                && opp.Owner.Job_Name__c == UserHelper.JOB_REP
                // && bySalesDivisionMap.containsKey(opp.Owner.Sales_Division__c) 
                // && !holdOutSet 
                && opp.Owner.Sales_Division__c != Label.VirtRetSalesDivision
               ) {
                   createTransferRequest(acct, opp, getKeys(opp), bySalesDivisionMap, newCrossovers,log, acctChanged, crossoverCreated);
                   crossoverCreated = true;
               }
            
            //If the Account already has the SMB Channel hold out on it, set date to whichever is farther away: the current hold out date, or the 90 day hold out date.
            if(opp.OwnerId == acct.OwnerId && opp.Owner != null && String.isNotBlank(opp.Owner.Sales_Division__c) && acct.Hold_Out__c 
               && bySalesDivisionMap.containsKey(opp.Owner.Sales_Division__c) && acct.Permanent_Hold_Out_Description__c != null && acct.Permanent_Hold_Out_Description__c == 'Not Sold Opportunity' 
               && (opp.Owner.Sales_Division__c.contains('SMB') && opp.Owner.Sales_Division__c.contains('Channel')))
            {
                if(acct.Hold_Out_Expiration__c < Date.today().addDays(nbrDays))
                {
                    acct.Hold_Out_Expiration__c = Date.today().addDays(nbrDays);
                    acct.Permanent_Hold_Out_Description__c = hod.Name;
                    StringHelper.addToProcessNotes(acct,'checkCreatedOpp Hold Out Set to '+acct.Hold_Out_Expiration__c);
                    acctChanged = true;
                }
            }
        } // if (hod != null
        //Added per APR0113398 - Virtual Retirement Crossover Automation
         system.debug('OpportunityVirtRetSalesDivision ' + opp.Owner.Sales_Division__c );
        if (opp.Owner.Sales_Division__c == Label.VirtRetSalesDivision /*&& acct.First_Run_Date__c >= Date.today().addDays(-nbrDays) && acct.First_Run_Date__c <= Date.today().addDays(nbrDays) */
            && opp.Referring_Employee__r.User_Lookup__c != opp.OwnerId
            && String.isNotBlank(opp.Owner.Sales_Division__c) 
            && opp.Owner.Job_Name__c == UserHelper.JOB_REP
            && bySalesDivisionMap.containsKey(opp.Owner.Sales_Division__c)) {
                system.debug('OpportunityVirtRetSalesDivisioninsideif ' + opp.Owner.Sales_Division__c );
                createTransferRequest(acct, opp, getKeys(opp), bySalesDivisionMap, newCrossovers,log, acctChanged, crossoverCreated);
            }
        //addedbysana
        Boolean distInOppOwnerDistricts = (String.isNotBlank(opp.Owner.District_Name__c ) && oppOwnerDistricts.contains(opp.Owner.District_Name__c ));
        Boolean distInSalesDivMap = (String.isNotBlank(opp.Owner.District_Name__c ) && bySalesDivisionMap.containsKey(opp.Owner.District_Name__c));
        system.debug('checkCreatedOpp OpportunityOwnerDistrict=' + opp.Owner.District_Name__c +' distInOppOwnerDistricts='+distInOppOwnerDistricts+' distInSalesDivMap='+distInSalesDivMap);
        //system.debug('opp.Referring_Employee__r.User_Lookup__c != opp.OwnerId '+(opp.Referring_Employee__r != null && opp.Referring_Employee__r.User_Lookup__c != opp.OwnerId));
        //system.debug('opp.Owner.Job_Name__c == UserHelper.JOB_REP '+(opp.Owner.Job_Name__c == UserHelper.JOB_REP));
        if( distInOppOwnerDistricts && distInSalesDivMap){
            String[] keys = new String[]{opp.Owner.District_Name__c};
            createTransferRequest(acct, opp, keys, bySalesDivisionMap, newCrossovers,log, acctChanged, crossoverCreated);
            system.debug('OpportunityOwnerDistrictinsideif ' + opp.Owner.District_Name__c );
        }
        //Update PEO-ASO Owner, add holdout and create chatter message
        if(opp.OpportunityType__c == 'Payroll' && opp.OwnerId == acct.OwnerId && opp.Owner.HR_Services_Partner__c != null && !acct.CurrentClient__c){
            if(!acct.Premier_PBS_Hold_Out__c || (acct.Premier_PBS_Account_Owner__c != opp.Owner.HR_Services_Partner__c && acct.PEO_ASO_Permanent_Hold_Out_Description__c == Label.Account_HR_Partnership_Holdout_Reason)){
                acct.Premier_PBS_Account_Owner__c = opp.Owner.HR_Services_Partner__c;
                acct.Premier_PBS_Hold_Out__c = true;
                acct.PEO_ASO_Permanent_Hold_Out_Description__c = Label.Account_HR_Partnership_Holdout_Reason;
                acctChanged = true;
                //Create Chatter
                if(acct.NumberOfEmployees >= 10){
                    String[] userList = new String[]{opp.Owner.HR_Services_Partner__c};
                        String cMessage = 'Your payroll partner has just created an Opportunity with 10+ employees and you have been assigned as the Payx PEO-ASO Account Owner on '
                        +acct.Name+'. This is not an Integrated Selling or Internal Referral lead, simply a notification. Contact your partner for more details.';
                    ChatterMentionPost.createChatterMentionPost(acct.Id,userList,cMessage);
                    ChatterMentionPost.checkPostFeedElements();
                }
            }
        }
        return acctChanged;
    } // checkCreatedOpp
    
   public static String[] getKeys(Opportunity opp) {
      String[] keys = null;
      // on a created opp, opp.ProductGroupsSelected__c isn't necessarily populated yet so we'll also look at the AdditionalProductsOfInterest__c field.
      if (String.isNotBlank(opp.ProductGroupsSelected__c)) {
         keys = opp.ProductGroupsSelected__c.split(',');
      } else if (opp.EvaluateProductGroup__c && String.IsNotBlank(opp.AdditionalProductsOfInterest__c)) {
         // remove all of the spaces
         String productsOfInterest = opp.AdditionalProductsOfInterest__c.replaceAll( '\\s+', '');                
         keys = productsOfInterest.split(',');
      } else {
         keys = new String[]{opp.Owner.Sales_Division__c};
      }
      return keys;
   } // getKeys
    
    public static void createTransferRequest(Account acct, Opportunity opp, String[] keys, Map<String,HoldOut_Dictionary__c> bySalesDivisionMap, Transfer_Request__c[] newCrossovers, ErrorLog__c log, boolean acctChanged, boolean crossoverCreated) {
        if(crossoverCreated) {
            return;
        }
        system.debug('@@createTransferRequestcalled');
        //acct.First_Run_Date__c >= Date.today().addDays(-nbrDays) && acct.First_Run_Date__c <= Date.today().addDays(nbrDays)
        Transfer_Request__c[] updateRequests = new Transfer_Request__c[]{};
            
            // todo - new field CreatedByKey__c that will store either sales division or product group, so we can identify the one we're looking for
            // todo - new Field SalesOrg__c that will store the sales org 
            // look for existing transfer requests
            // 90 days is arbitrary - we might want to store number of days somewhere else to make is customizable
        Datetime dateCheck = Datetime.now().addDays(-90);
        Transfer_Request__c[] existingRequests = [Select Id, Account__c, Status__c, CreatedByKey__c, ProcessCreatedBy__c, SalesOrg__c
                                                  ,Owner_Field__c
                                                  From Transfer_Request__c
                                                  Where Account__c=:acct.Id
                                                  and ProcessCreatedBy__c='OpptyUpdateAcct'
                                                  and CreatedDate > :dateCheck
                                                  and CreatedByKey__c != null];
        Map<String,Transfer_Request__c> existingRequestMap = new Map<String,Transfer_Request__c>();
        for (Transfer_Request__c tr : existingRequests) {
            existingRequestMap.put(tr.CreatedByKey__c, tr);
        }
        //if the ProductGroupsSelected__c has a value then we'd use that instead of the sales division
        //String[] keys = getKeys(opp);
        //String[] keys = label.OpportunityOwnerDistrict.split(',').contains(opp.Owner.District__c)? opp.Owner.District__c :(String.isNotBlank(opp.ProductGroupsSelected__c) ? opp.ProductGroupsSelected__c.split(',') : String.isNotBlank(opp.Owner.Sales_Division__c) ? new String[]{opp.Owner.Sales_Division__c} : new String[]{opp.Owner.District__c});
        System.debug('createTransferRequest ProductGroupsSelected__c='+opp.ProductGroupsSelected__c+' AdditionalProductsOfInterest__c='+opp.AdditionalProductsOfInterest__c+' Evaluate='+opp.EvaluateProductGroup__c);
        
        for (String key : keys) {
            // remove it so we know it already exists
            Transfer_Request__c existingRequest = existingRequestMap.remove(key);
            System.debug('createTransferRequest key='+key+' existingRequest='+(existingRequest != null));
            if (existingRequest != null && existingRequest.Status__c != CrossoverRequestController.STATUS_APPROVED) {
                // make sure it's active
                existingRequest.Status__c = CrossoverRequestController.STATUS_APPROVED;
                updateRequests.add(existingRequest);
            } else if (existingRequest == null) {
                // create a new one
                HoldOut_Dictionary__c hod = bySalesDivisionMap.get(key);
                String salesOrg = (hod != null && String.isNotBlank(hod.Sales_Org__c) ? hod.Sales_Org__c : UserHelper.SO_CORE);
                HoldOut_ExpirationDates__c hoexDate = (hod != null ? HoldOut_ExpirationDates__c.getInstance(salesOrg) : null);
                ErrorLog.addToDescription(log, 'checkCreatedOpp key='+key+' hod='+(hod!=null)+' hoexDate='+(hoexDate != null));
                if (hod != null && hoexDate != null) {
                    //if (hoexDate == null || opp.ProductGroupsSelected__c.split(',').contains(key)) {
                        // this one should always exist
                    //    hoexDate = HoldOut_ExpirationDates__c.getInstance(UserHelper.SO_PAY);
                    //}
                    // keep a default value of 90 days
                    Integer nbrDays = (hod.InitialNbrDays__c != null ? Integer.valueOf(hod.InitialNbrDays__c) : 90);
                    ErrorLog.addToDescription(log, 'checkCreatedOpp hod='+hod.Name+' nbrDays='+nbrDays);
                    
                    // create a crossover record for tracking purposes.
                    if(!((Boolean)acct.get(hoexDate.Account_Hold_Out__c) == true && (acct.get(hoexDate.HoldOutReasonFld__c)=='Strategic Account Team' || acct.Ischild__c == true) && acct.First_Run_Date__c >= Date.today().addDays(-nbrDays) && acct.First_Run_Date__c <= Date.today().addDays(nbrDays))){ //addedbysana
                        
                        Transfer_Request__c tr = new Transfer_Request__c(Account__c=acct.Id);
                        tr.Auto_Approved__c = true;
                        tr.Auto_Approve_Date__c = Date.today();
                        tr.Status__c = CrossoverRequestController.STATUS_APPROVED;
                        tr.Hold_Out_Reason__c = hod.Name;
                        tr.ProcessCreatedBy__c='OpptyUpdateAcct';
                        tr.CreatedByKey__c=key;//addedbysana
                        // so we have the information if we need to remove the holdout later
                        tr.SalesOrg__c=(hoexDate != null ? hoexDate.Name : hod.Sales_Org__c);
                        
                        if (hoexDate != null) { 
                            tr.Original_Owner__c = (String.isNotBlank(hoexDate.Account_Owner__c) ? (Id)acct.get(hoexDate.Account_Owner__c) : acct.OwnerId);
                            tr.Owner_Field__c = hoexDate.Account_Owner__c;
                            
                            acct.put(hoexDate.Account_Owner__c,opp.OwnerId);
                            acct.put(hoexDate.Account_Hold_Out__c, true);
                            acct.put(hoexDate.Account_Hold_Out_Date__c, Date.today().addDays(nbrDays));
                            acct.put(hoexDate.HoldOutReasonFld__c, hod.Name);
                            
                            StringHelper.addToProcessNotes(acct,'checkCreatedOpp set '+hoexDate.Account_Hold_Out__c+' to '+hod.Name+' and '+hoexDate.Account_Owner__c+' to '+opp.OwnerId);
                            ErrorLog.addToDescription(log, 'checkCreatedOpp set '+hoexDate.Account_Hold_Out__c+' to '+hod.Name+' and '+hoexDate.Account_Owner__c+' to '+opp.OwnerId);
                            tr.Comments__c = hod.Name;
                            tr.Status__c = 'Approved';
                            newCrossovers.add(tr);
                            acctChanged = true;
                            crossoverCreated = true;
                        } else {
                            System.debug('createTransferRequest Could not find HoldOut_ExpirationDates__c');
                        }
                    }
                } // if (hod != null
            } // if (existingRequest == null
        } // for (String key : keys
        // if there are any left, we can remove the holdout and cancel the request
        if (!existingRequestMap.isEmpty()) {
            for (Transfer_Request__c tr : existingRequestMap.values()) {
                HoldOut_ExpirationDates__c hoexDate = String.isNotBlank(tr.SalesOrg__c) ? HoldOut_ExpirationDates__c.getInstance(tr.SalesOrg__c) : null;
                if (hoexDate != null) {
                    // remove the account holdout
                    acct.put(hoexDate.Account_Hold_Out__c, false);
                    acct.put(hoexDate.Account_Hold_Out_Date__c, null);
                    acct.put(hoexDate.HoldOutReasonFld__c, null);
                    acctChanged = true;
                } // if (hoex != null
                // cancel the request - keep it for tracking purposes
                tr.Status__c = 'Canceled';
                updateRequests.add(tr);
                
            } // for (Transfer_Request__c tr : existingRequestMap
        } // if (!existingRequestMap.isEmpty
        
        if (!updateRequests.isEmpty()) {
            DmlHelper.performDML2(updateRequests, DmlHelper.DML_UPDATE, 'OpptyUpdateAcct', 'createTransferRequest', 'Update Crossovers', true);
        }
    } // createTransferRequest
   
    public static Boolean checkOppHoldOut(Account acct, Opportunity opp, ErrorLog__c log ) {
        
        Boolean acctChanged = false;
        // new hold out. 
        String permHoldOutDesc = (opp.ReferralLookup__r.Referral_Partner__c != null ? opp.ReferralLookup__r.Referral_Partner__r.Permanent_Hold_Out_Description__c : null);
        ErrorLog.addToDescription(log, 'checkOppHoldOut permHoldOutDesc=' + permHoldOutDesc);
        if (String.isBlank(permHoldOutDesc)) {
            ErrorLog.addToDescription(log, 'checkOppHoldOut return false');
            return false;
        }
        
        ErrorLog.addToDescription(log, 'checkOppHoldOut acct.Hold_Out='+acct.Hold_Out__c+' reason='+acct.Permanent_Hold_Out_Description__c);
        // if there's a current holdout, can it be overwritted?
        if (acct.Hold_Out__c && String.isNotBlank(acct.Permanent_Hold_Out_Description__c)) {
            HoldOut_Dictionary__c hod = HoldOut_Dictionary__c.getInstance(acct.Permanent_Hold_Out_Description__c);
            if (hod != null && hod.Permanent__c) {
                System.debug('OpptyUpdateAcct.checkHoldOutReasonNow acct has Hold Out so not pushing opty owner');
                ErrorLog.addToDescription(log, 'OpptyUpdateAcct.checkHoldOutReasonNow acct has Hold Out so not pushing opty owner');
                return false;
            }
        }
        
        ErrorLog.addToDescription(log, 'permHoldOutDesc='+permHoldOutDesc);       
        if (String.isNotBlank(permHoldOutDesc)) {
            HoldOut_Dictionary__c hod = HoldOut_Dictionary__c.getInstance(permHoldOutDesc);
            if (hod != null && hod.Use_Opty_Owner__c) {
                String notes = 'OpptyUpdateAcct updated owner from Opp to '+opp.Owner.Name+' due to '+permHoldOutDesc;
                acct.OwnerId=opp.OwnerId;
                acct.Hold_Out__c = true;
                Integer nbrDays = (hod.InitialNbrDays__c != null ? Integer.valueOf(hod.InitialNbrDays__c) : 30);
                if (nbrDays > 0) {
                    acct.Hold_Out_Expiration__c = Date.today().addDays(nbrDays);
                    notes += (', expiration='+acct.Hold_Out_Expiration__c);
                }
                acct.Permanent_Hold_Out_Description__c=permHoldOutDesc;
                StringHelper.addToProcessNotes(acct,notes);
                acctChanged=true;
                ErrorLog.addToDescription(log, notes);
            } // if (hod != null && hod.Use_Opty_Owner__c
        } /// if (String.isNotBlank(permHoldOutDesc
        
        ErrorLog.addToDescription(log, 'acctChanged: ' + acctChanged);
        return acctChanged;
    } // checkOppHoldOut  
    
} // class OpptyUpdateAcct