/* 
 * Check to see if certain values change to update the Opportunity.
 *
 * History
 * -------
 * 06/28/2010 Dan Carmen   Created
 * 10/07/2010 Dan Carmen   Removed code checking for load complete flag.
 * 08/08/2013 Josh Cartwright - added code to change MMS Opportunties to MMS DSA Record Type
 * 08/14/2015 Jacob Hinds - added in a flag so the first run update doesn't run multiple times
 * 01/12/2016 Jacob Hinds - Adding in NCS_Name to oppty push
 * 02/19/2016 Josh Cartwright - added two status per Jessica H Case 20401969 prevent updates for Referred Started & Referred Commissioned
 * 03/06/2016 Cindy Freeman - removed Returning Lost Client update from RCP to the Opty
 * 06/22/2017 Frank Lurz - removed Total_Employees__c field per Fast Track Case #23041606
 * 02/19/2018 Jacob Hinds   INC1462722 Setting forecast category when status is set
 * 03/02/2018 Jacob Hinds   adding isactive for forecast category
 * 04/16/2018 Jacob Hinds	removing forecast category, now handled by oppty trigger
 * 09/17/2918 Jermaine Stukes  Updated rcp payroll run date logic to only update payroll oppty
   10/29/2018 Dan Carmen   Changed the StageName exclusions to be a label.
   04/09/2020 Dan Carmen   Remove call to AccountHelper for RecordType
   01/15/2021 Manmeet Vaseer   Added ErrorLog for INC2561269.
   05/17/2023 Dan Carmen    Add check for CEID and CAID
   05/17/2023 Susmitha Somavarapu  Added back removed updateCallerName method
   06/28/2023 Eric Porter           Added back updateImpSplsist method
   12/1/2023 Susmitha Somavarapu Added a new logic to create a new contact CallerName NotFound when it doesn't find the CallerName field value(APR0162106)
 */
public without sharing class RefCorePayUpdateOppty {
   
   public static void processStatusChanges(Map<Id,Id> allOpptyIds
                                          ,Reference_Core_Payroll__c[] loadReceived
                                          ,Reference_Core_Payroll__c[] otherUpdates
                                          ,Reference_Core_Payroll__c[] runDate
                                          ,Reference_Core_Payroll__c[] cltNbr
                                          ) {
      processOpptys(allOpptyIds,loadReceived,otherUpdates,runDate);
      processCltNbr(cltNbr);
   } // processStatusChanges

   public static Set<String> EXCLUDE_STAGES_SET = new Set<String>(Label.RefCorePay_ExcludeStages.split(','));

   /** Update the Opportunities on the records based on the flags that changed.
    */
   private static void processOpptys(Map<Id,Id> allOpptyIds
                                          ,Reference_Core_Payroll__c[] loadReceived
                                          ,Reference_Core_Payroll__c[] otherUpdates
                                          ,Reference_Core_Payroll__c[] runDate) {
                                              
	  ErrorLog__c log = new ErrorLog__c(ClassName__c='RefCorePayUpdateOppty',MethodName__c='processOpptys', CodeKey__c='LOG_DATA');
                                              
      // if no opportunities, do not need to do anything.
      if (allOpptyIds.isEmpty()) {
		 ErrorLog.addToDescription(log, 'No Opportunities to process.');
		 ErrorLog.saveLog(log);
         return;
      } 

      if(allOpptyIds.values().size() == 1)	{
          log.ObjectId__c = allOpptyIds.values()[0];
          log.ObjectAPIName__c = 'Opportunity';
      }

      Map<Id,Reference_Core_Payroll__c> rcps = new Map<Id,Reference_Core_Payroll__c>();
      
      // retrieve the opportunities
      Map<Id,Opportunity> opptys = new Map<Id,Opportunity>([Select Id
                                                                  ,Employees_Paid_Per_Payroll__c
                                                                  ,Frequency__c
                                                                  ,StageName
                                                                  ,Returning_Lost_Client__c
                                                                  ,Total_Employees__c
                                                                  ,NCS_Approved__c
                                                                  ,NCS_Name__c
                                                                  ,CloseDate
                                                                  ,WIN_Check__c
                                                                  ,WIN__c
                                                                  ,Discount_Period__c
                                                                  ,Discount2_Type__c
                                                                  ,Discount2_Period__c
                                                                  ,Discount2_Percentage__c
                                                                  ,Multi_Frequency__c
                                                                  ,Change_of_Ownership__c
                                                                  ,Add_l_ID_added__c
                                                                  ,OpportunityType__c
                                                                  ,Other_credit__c
                                                                  ,Other_credit_reason__c                                                                 
                                                                  ,RecordType.name
                                                              from Opportunity
                                                             where Id in :allOpptyIds.values()
                                                             and StageName not in :EXCLUDE_STAGES_SET]);
                                                             //and StageName != 'Sold - Started'
                                                             //and StageName != 'Referred Started'  //jc 2/19/16
                                                             //and StageName != 'Referred Commissioned' // jc 2/19/16
                                                             //and StageName != 'Sold - Commissioned']);
     /* Map<String,String> forecastCategoryByOppStage = new Map<String,String>();
      List<OpportunityStage> oppStages = [SELECT MasterLabel,ForecastCategory,ForecastCategoryName FROM OpportunityStage WHERE IsActive = true];
      if(oppStages!=null){
          for(OpportunityStage os: oppStages){
             forecastCategoryByOppStage.put(os.MasterLabel,os.ForecastCategoryName);
          }
      }*/
      
      String MMSDSAOpp = Label.MMS_Opportunity_DSA_Record_Type;
      String MMSOpp = Label.MMS_Opportunity_Record_Type;
      for (Reference_Core_Payroll__c rcp : loadReceived) {
		 ErrorLog.addToDescription(log, 'rcp.Opportunity_Lookup__c: ' + rcp.Opportunity_Lookup__c);
         Opportunity oppty = opptys.get(rcp.Opportunity_Lookup__c);
         if (oppty != null) {
		 	ErrorLog.addToDescription(log, 'oppty.Id: ' + oppty.Id);
            rcps.put(rcp.Id, rcp);
            String logMsg = 'oppty.RecordType.Name: ' + oppty.RecordType.Name + ', MMSDSAOpp: ' + MMSDSAOpp + ', MMSOpp: ' + MMSOpp;
		 	ErrorLog.addToDescription(log, logMsg);            
            if(oppty.RecordType.Name != MMSDSAOpp && oppty.RecordType.Name != MMSOpp){
            	oppty.StageName = 'Sold - Submitted';
		 		ErrorLog.addToDescription(log, 'oppty.StageName: ' + oppty.StageName);            
            }
            /*
            if(forecastCategoryByOppStage.containsKey(oppty.StageName)){
                oppty.ForecastCategoryName = forecastCategoryByOppStage.get(oppty.StageName);
                system.debug('processOpptys for load recieved, updated forecast to: '+oppty.ForecastCategoryName);
            }*/
            // change to record type to Opportunity DSA Record Type, CORE to CORE DSA, MMS to MMS DSA   
            String rtName = ( oppty.RecordType.Name == OpportunityCreateCase.RT_OPPTY_MMS ? OpportunityCreateCase.RT_OPPTY_MMS_DSA
                               : (oppty.RecordType.Name == OpportunityCreateCase.RT_OPPTY_CORE ? OpportunityCreateCase.RT_OPPTY_CORE_DSA : null));
            Schema.RecordTypeInfo rt = (rtName != null ? RecordTypeHelper.getRecordType(rtName, 'Opportunity') : null);
            if (rt != null) {
               oppty.RecordTypeId = rt.getRecordTypeId();
            }
         }
      } // for 

      for (Reference_Core_Payroll__c rcp : otherUpdates) {
         Opportunity oppty = opptys.get(rcp.Opportunity_Lookup__c);
         if (oppty != null) {
            System.debug('processOpptys in for loop oppty.Id='+oppty.Id+' oppty.Frequency__c='+oppty.Frequency__c+' rcp.Frequency__c='+rcp.Frequency__c);
            rcps.put(rcp.Id, rcp);
            //oppty.Returning_Lost_Client__c = rcp.Returning_Lost_Client__c;
            //oppty.Employees_Paid_Per_Payroll__c = rcp.Number_of_Employees__c != null ? rcp.Number_of_Employees__c : oppty.Total_Employees__c;
            if((rcp.Number_of_Employees__c != null) && (rcp.Number_of_Employees__c != 0)){
                Oppty.Employees_Paid_Per_Payroll__c = rcp.Number_of_Employees__c;
            }
            //oppty.Frequency__c = rcp.Frequency__c != null ? rcp.Frequency__c : oppty.Frequency__c;
            oppty.Frequency__c = String.IsNotBlank(rcp.Frequency__c) ? rcp.Frequency__c : oppty.Frequency__c;
            oppty.WIN_Check__c = rcp.Discount_Type__c != null ? rcp.Discount_Type__c : oppty.WIN_Check__c;
            oppty.WIN__c = rcp.Discount_Percentage__c != null ? rcp.Discount_Percentage__c : oppty.WIN__c;
            oppty.Discount_Period__c = rcp.Discount_Period__c != null ? rcp.Discount_Period__c : oppty.Discount_Period__c;
            oppty.Discount2_Type__c = rcp.Discount2_Type__c != null ? rcp.Discount2_Type__c : oppty.Discount2_Type__c;
            oppty.Discount2_Period__c = rcp.Discount2_Period__c != null ? rcp.Discount2_Period__c : oppty.Discount2_Period__c;
            oppty.Discount2_Percentage__c = rcp.Discount2_Percentage__c != null ? rcp.Discount2_Percentage__c : oppty.Discount2_Percentage__c;
            oppty.Multi_Frequency__c = rcp.Multi_Frequency__c;
            oppty.Change_of_Ownership__c = rcp.Change_of_Ownership__c;
            oppty.Add_l_ID_added__c = rcp.Add_l_ID_Added__c;
            oppty.Other_credit__c = rcp.Other_Credit__c;
            oppty.Other_credit_reason__c = rcp.Other_Credit_Reason__c != null ? rcp.Other_Credit_Reason__c : oppty.Other_credit_reason__c;
            oppty.NCS_Approved__c = rcp.NCS_Verified__c;
            oppty.NCS_Name__c = rcp.NCS_Name__c;
         }
   } // for 

      for (Reference_Core_Payroll__c rcp : runDate) {
		 ErrorLog.addToDescription(log, 'rcp.Opportunity_Lookup__c: ' + rcp.Opportunity_Lookup__c);
         Opportunity oppty = opptys.get(rcp.Opportunity_Lookup__c);      
         if (oppty != null) {
		 	ErrorLog.addToDescription(log, 'oppty.Id: ' + oppty.Id);
            rcps.put(rcp.Id, rcp);
            String logMsg = 'oppty.RecordType.Name: ' + oppty.RecordType.Name + ', MMSDSAOpp: ' + MMSDSAOpp + ', MMSOpp: ' + MMSOpp;
		 	ErrorLog.addToDescription(log, logMsg);            
            if(oppty.RecordType.Name != MMSDSAOpp && oppty.RecordType.Name != MMSOpp){
                oppty.StageName = 'Sold - Started';
 		 		ErrorLog.addToDescription(log, 'oppty.StageName: ' + oppty.StageName);            
            }
            /*
            if(forecastCategoryByOppStage.containsKey(oppty.StageName)){
                oppty.ForecastCategoryName = forecastCategoryByOppStage.get(oppty.StageName);
                system.debug('processOpptys for run date, updated forecast to: '+oppty.ForecastCategoryName);
            }*/
            if(oppty.OpportunityType__c == 'Payroll' && oppty.RecordType.Name != MMSDSAOpp && oppty.RecordType.Name != MMSOpp)
            {
                oppty.CloseDate = rcp.Payroll_Run_Date__c;
            }
         }
      } // for 

      try {
         update opptys.values();
      } catch (Exception e) {
         // if only one record, mark the reference core payroll as an error.
         if (opptys.values().size() == 1) {
            String msg = 'Error while attempting to update the Opportunity: ';
            String errorMsg = e.getMessage();
            if (errorMsg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') > 0) {
               errorMsg = errorMsg.subString(errorMsg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,')+34);                
            }
            msg += errorMsg;

            for (Reference_Core_Payroll__c rcp : rcps.values()) {
               if (rcp.Opportunity_Lookup__c == opptys.values().get(0).Id) {
                  rcp.addError(msg);
               }    
            } // for
             
 		 	ErrorLog.addToDescription(log, 'Exception: ' + msg);
         } // if (opptys.values          
      } // try

	  ErrorLog.saveLog(log);
   } // processOpptys
   
   private static void processCltNbr(Reference_Core_Payroll__c[] cltNbr) {
      // if no records do not need to do anything
      if (cltNbr.isEmpty()) {
         return;
      }
      List<Id> caseIds = new List<Id>();
      // gather all of the case ids
      for (Reference_Core_Payroll__c rcp : cltNbr) {
         caseIds.add(rcp.Case_Lookup__c);
      }
      // retrieve all of the cases
      Map<Id,Case> cases = New Map<Id,Case>([Select Id
                                                   ,AccountId
                                                   ,Account.Id
                                                   ,Account.Bis_ID__c
                                                   ,Account.AccountNumber
                                                   ,Account.Paychex_CEID__c
                                                   ,Account.Paychex_CAID__c
                                               from case
                                              where Id in :caseIds]);
      // the Accounts that would be updated.
      List<Account> updateAccts = new List<Account>();
      for (Reference_Core_Payroll__c rcp : cltNbr) {
         Case c = cases.get(rcp.Case_Lookup__c);
         // only update if no BIS Id
         Account acct = c.Account;
         if (acct != null) {
            Boolean changed = false;
            if (acct.Bis_ID__c == null && String.isNotBlank(rcp.New_Prospect_Client_Number__c)) {
               acct.AccountNumber = rcp.New_Prospect_Client_Number__c;
               changed = true;
            }
            if (String.isBlank(acct.Paychex_CEID__c) && String.isNotBlank(rcp.CEID__c)) {
               acct.Paychex_CEID__c = rcp.CEID__c;
               changed = true;
            }
            if (String.isBlank(acct.Paychex_CAID__c) && String.isNotBlank(rcp.CAID__c)) {
               acct.Paychex_CAID__c = rcp.CAID__c;
               changed = true;
            }
            if (changed) {
               updateAccts.add(acct);
            }
         }
         //if ((c.AccountId != null) && (c.Account.Bis_ID__c == null)) {
         //   Account acct = new Account(Id = c.Account.Id, AccountNumber = rcp.New_Prospect_Client_Number__c);
         //   updateAccts.add(acct);
         //}
      } // for
      
      if (!updateAccts.isEmpty()) {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         DmlHelper.performDML(updateAccts, DmlHelper.DML_UPDATE, 'RefCorePayUpdateOppty', 'processCltNbr', 'updating Accounts', true);
         ZipCheckOwner.SKIP_TRIGGERS=false;
      }
   } // processCltNbr
   // Identify the Contact based on Caller Name, and update the Caller name (LK Contact ) , if contact not found update Caller Name Not found contact ot contact lk 
   public static void updateCallerName(Map<Id, String > callerNameUpdateMap, List<Reference_Core_Payroll__c> refCoreValuse ){
    List<Contact> contactList = [SELECT id, name FROM contact WHERE name IN :callerNameUpdateMap.values() or name = 'CallerName NotFound'  ORDER BY lastmodifieddate ];
    List<Contact>  noColContact =  new List<Contact>();
    map<String, id> nameVSContId = new Map<String, id>();
    for (contact contacRec : contactList) {
      if (contacRec.name == 'CallerName NotFound') {
         noColContact.add(contacRec);
      }{
         nameVSContId.put(contacRec.Name, contacRec.Id);               
      }
    }
    System.debug('var car' +  'entyr ' +  nameVSContId + ' vvv ' + noColContact + 'rr' + refCoreValuse);
    for ( Reference_Core_Payroll__c newRcp: refCoreValuse) {
      if (newRcp.Caller_Name__c == null ){
         newRcp.CallerName__c = null ;        
      }
      else if (nameVSContId.containsKey(newRcp.Caller_Name__c)) {
        newRcp.CallerName__c = nameVSContId.get(newRcp.Caller_Name__c);  
        }
      else {
         if (noColContact.size() > 0) {
            newRcp.CallerName__c = noColContact[0].id;                        
         }
       }
    }
  }	//sush
  public static void updateiSCompletedClientAuditItems(List<Reference_Core_Payroll__c> rcps){
    for(Reference_Core_Payroll__c rcp:rcps){
      if(rcp.IS_Completed_open_Client_Audit_Items__c == 'Yes'){
        rcp.New_Load_Audit_Date__c = System.today();
      }
    }
  }
  public static void updateImpSplsist(Set<Id> updateImpSplsist ){
   List<Account> acctsTOUpdate =new List<Account>();
   for (Reference_Core_Payroll__c rcpRec : [ select id,Case_Lookup__r.Account.id,CallerName__c  from Reference_Core_Payroll__c where id in:updateImpSplsist ]) {
     acctsTOUpdate.add(new Account(id = rcpRec.Case_Lookup__r.Account.id , MMS_AS__c = rcpRec.CallerName__c));
   }
   ZipCheckOwner.SKIP_TRIGGERS = true;
   OpptyMethods.Skip_Oppty_Triggers = true;
   CSOMethods.SKIP_TRIGGERS = true;
   CadenceHelper.SKIP_TRIGGERS = true;
   update acctsTOUpdate; 
   ZipCheckOwner.SKIP_TRIGGERS = true;
   OpptyMethods.Skip_Oppty_Triggers = true;
   CSOMethods.SKIP_TRIGGERS = true;
   CadenceHelper.SKIP_TRIGGERS = true;

 }    
} // RefCorePayUpdateOppty