/* 
  Set CSSR Segment Checkbox on accounts when payroll has been running for a year
  *** LEAVE THIS AT API 44 OR BELOW FOR ACCOUNT TEAM MEMBER QUIRKS ***
   
  History
  -------
   06/20/2018     Jake Hinds  Created
   03/27/2023     Bindu Madhavi   New segment with Current Clients start date greater than 6 months
*/
global with sharing class AccountCurrentClientBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
   
   public static final String CLASS_NAME='AccountCurrentClientBatch';
   
   public static Integer NUM_DAYS_AS_CLIENT=Integer.valueOf(Label.ClientDaysForFarmer);
   public static Integer CLIENT_LIMIT_DAYS = Integer.valueOf(Label.ClientDaysforMicroSegment);
   
   public Date targetDate = Date.today().addDays(-NUM_DAYS_AS_CLIENT);
   public Date clientLimitDate = Date.today().addDays(-CLIENT_LIMIT_DAYS);
    
   public static String MODE_CSSR='CSSR';
   public static String MODE_ATM='ATM';
   
   global JobHelper jh = new JobHelper(CLASS_NAME);
   global Account[] accts;
   global Set<Id> recTypeIdSet = null;
   //global Id mmsRTId;
   global Date todayDate = System.today();

   // The time the process started. 
   global DateTime startTime;
   // messages that occur during the process.
   global String processNotes = '';
    
   global String mode=MODE_CSSR;
    
   global AccountCurrentClientBatch() {
      system.debug('in constructor');
      if(recTypeIdSet==null){
         recTypeIdSet = new Set<Id>();
         //mmsRTId = RecordTypeHelper.getRecordType('MMS Account Record Type','Account').getRecordTypeId();
         // since both segments use the same date date criteria, initially we'll try using the same fields 
         // if things change down the line, we can add in another field at that time. 
         Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
         recTypeIdSet.add(byNameMap.get(RecordTypeHelper.CORE_ACCOUNT).getRecordTypeId());
         recTypeIdSet.add(byNameMap.get(RecordTypeHelper.MMS_ACCOUNT).getRecordTypeId());
         System.debug('AccountCurrentClientBatch recTypeIdSet='+recTypeIdSet);
         
      }
   } // MMSCSSRBatch
    
   // The total number of accts found.
   global Integer numberAccts = 0;
    
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      if (mode == MODE_ATM) {
         numberAccts = 0;
         String[] fields = new String[]{'User.IsActive'};
         String query = ObjectHelper.getSOQLQuery('AccountTeamMember', fields, true, true, false, false, true);
         String abcName = CLASS_NAME+MODE_ATM;
         Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(abcName);
         Integer nbrDays = (abc != null && abc.Check_Days__c != null ? Integer.valueOf(abc.Check_Days__c) : 3);
         DateTime checkTime = Datetime.now().addDays(-nbrDays);
         query += ' where CreatedDate >= :checkTime and CreatorIsSysAdmin__c=false ';
         return Database.getQueryLocator(query);
      }
      //Date targetDate = Date.today().addDays(-NUM_DAYS_AS_CLIENT);
      //Date clientLimitDate = Date.today().addDays(-CLIENT_LIMIT_DAYS);
      system.debug('starting Batch process recTypeIdSet='+recTypeIdSet.size()+' targetDate='+targetDate+' clientLimitDate='+clientLimitDate);
      //return Database.getQueryLocator([SELECT Id FROM Account WHERE Client_Start_Date__c<:targetDate AND CurrentClient__c = true AND RecordTypeId =:mmsRTId AND CSSR_Segment__c=false]);
      return Database.getQueryLocator([SELECT Id, Client_Start_Date__c FROM Account 
                                       WHERE CurrentClient__c = true AND RecordTypeId in :recTypeIdSet AND ((Client_Start_Date__c<:targetDate AND  CSSR_Segment__c=false)
                                       OR (Client_Start_Date__c <= :clientLimitDate AND Clientfor6Months__c = false))]);
   } // start

   global void execute(SchedulableContext sc) {
      system.debug('Batch Process scheduled');
      launchBatch(MODE_CSSR);
   } // execute
    
   global static void launchBatch(String mode) {
      AccountCurrentClientBatch accb = new AccountCurrentClientBatch();
      accb.mode = mode;
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
      // we want to keep a small batch because of row locks
      Integer batchSize = (abc != null ? Integer.valueOf(abc.BatchSize__c) : 500);
      database.executeBatch(accb, batchSize);
      
    } // launchBatch

   
   global void execute(Database.BatchableContext BC, List<SObject> scope) {
      numberAccts += scope.size();
      if (mode == MODE_CSSR) {
         handleCSSR((Account[])scope);
      } else if (mode == MODE_ATM) {
         handleATMs((AccountTeamMember[])scope);
      }
                
   } // execute
    
   global void handleATMs(AccountTeamMember[] atms) {
      AccountTeamMember[] newAtms = new AccountTeamMember[]{};
      for (AccountTeamMember atm : atms) {
          if (atm.User.IsActive) {
             AccountTeamMember newAtm = atm.clone(false);
             newAtms.add(newAtm);
          }
      } // for (AccountTeamMember atm : atms)
      Database.delete(atms,false);
      Database.insert(newAtms);
   } // handleATMs
    
   global void handleCSSR(Account[] accts) {
      system.debug('handleCSSR accts='+accts.size());
      List<Account> updateAccts = new List<Account>();
      for (Account acct: accts) { 
         if(acct.Client_Start_Date__c < clientLimitDate){              
         	 acct.Clientfor6Months__c=true;
             acct.Use_Zip_Assignment_Rules__c = true;
         }
         if(acct.Client_Start_Date__c < targetDate){   
             acct.CSSR_Segment__c=true;
         	 acct.Clientfor6Months__c=true;
             acct.Use_Zip_Assignment_Rules__c = true;
         }         
         updateAccts.add(acct);
      }
      if (!updateAccts.isEmpty()) {
         DmlHelper.performDML2(updateAccts, DmlHelper.DML_UPDATE, 'AccountCurrentClientBatch', 'handleCSSR', 'updateAccts', true);
      }
        
   } // handleCSSR
   
   global void finish(Database.BatchableContext BC) {
      String message = '\nMode='+mode+' Total Recs Processed: '+ numberAccts+' ';
      message += '\n\n'+processNotes;
      system.debug('message:'+message);
      jh.completeJob(bc, 'AccountCurrentClientBatch process', message);
      if (mode == MODE_CSSR && !Test.isRunningTest()) {
          launchBatch(MODE_ATM);
      }
   } // finish 
    
} // AccountCurrentClientBatch