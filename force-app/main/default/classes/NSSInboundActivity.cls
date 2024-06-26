/* 
 * Controller for the NSS Inbound Activity Page
 *
 * History
 * -------
 * 03/30/2015 Dan Carmen            Created
   12/11/2018 Dan Carmen            Replace qbdialer__Call_Date_Time__c with CallDateTime__c

 */
public with sharing class NSSInboundActivity {

   // the user running the form
   public User runningUser{get;private set;}
   // the user for whom we're running the form (if running as a supervisor or above)
   public User nssSalesUser{get; set;} 
   public Boolean promptForUser {get;private set;}
   // used to prompt for the user to enter audits for (if not an NSR)
   public NSSAudit__c askForUser {get; set;}


   public NSSInboundActivity() {
      runningUser = UserHelper.getRunningUser();
      askForUser = new NSSAudit__c(NSR_Name__c = runningUser.Id);
      // this is so for testing we can change the date.
      askForUser.Run_Submit_Date__c = Date.today();
      
      nssSalesUser = runningUser;
      
      // if not an NSR, open up the prompt for a user. The user will have to be in the role hierarchy to allow to proceed.
      promptForUser = (runningUser.Job_Name__c != UserHelper.JOB_NSR);
      
      setup();
      queryData();
   } // NSSInboundActivity
   
   public List<SelectOption> callDispositionOptions{get;set;}
   public String selectedDispositionFilter{get;set;}
   
   public Set<String> validCallDispositionSet = new Set<String>();
   
   public Id nssTaskRecordTypeId = TaskHelper.getNSSTaskRecordTypeId();
   
   public static final String OPTION_ALL='All';
   
   public void setup() {
      // get the call dispositions we will look for
   	if (validCallDispositionSet.isEmpty()) {
   		selectedDispositionFilter = OPTION_ALL;
   		callDispositionOptions = new List<SelectOption>();
   		callDispositionOptions.add(new SelectOption(OPTION_ALL,OPTION_ALL));
   		
   	   for (LeadCallDisposition__c lcd : LeadCallDisposition__c.getAll().values()) {
   	      if (lcd.InboundActivityCheck__c) {
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setup lcd.CallDisposition__c='+lcd.CallDisposition__c));
   	         validCallDispositionSet.add(lcd.CallDisposition__c);
               callDispositionOptions.add(new SelectOption(lcd.CallDisposition__c,lcd.CallDisposition__c));
   	      }
   	   } // for (LeadCallDisposition__c
   	} // if (validCallDispositionSet
   } // setup
   
   public void queryData() {
   	DateTime refStartDate = DateTime.newInstance(askForUser.Run_Submit_Date__c.addDays(-1), Time.newInstance(1,1,1,1));
      DateTime refEndDate = DateTime.newInstance(askForUser.Run_Submit_Date__c.addDays(1), Time.newInstance(23,59,59,1));
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'queryData refStartDate='+refStartDate+' refEndDate='+refEndDate));
      
      Set<String> dispositionFilterSet = new Set<String>();
      if (selectedDispositionFilter != null && selectedDispositionFilter != OPTION_ALL) {
         dispositionFilterSet.add(selectedDispositionFilter);
      } else {
         dispositionFilterSet.addAll(validCallDispositionSet);
      }
      // query the tasks based on the nssSalesUser
      Task[] tasks = [Select Id, OwnerId, CallDisposition, CallType, CreatedDate
                            ,WhoId, WhatId, AccountId, ActivityDate
                            ,CallDateTime__c
                        From Task
                       Where RecordTypeId = :nssTaskRecordTypeId
                         and OwnerId = :askForUser.NSR_Name__c
                         and CallDisposition in :dispositionFilterSet
                         and ActivityDate = :askForUser.Run_Submit_Date__c
                         and (WhoId != null or AccountId != null)
                         and AccountId not in (Select Account__c 
                                                 From Referral__c
                                                Where OwnerId = :askForUser.NSR_Name__c
                                                  and CreatedDate >= :refStartDate
                                                  and CreatedDate <= :refEndDate)
                       order by createdDate
                     ];
      displayList = new List<TaskWrapper>();
      for (Task tsk : tasks) {
         displayList.add(new TaskWrapper(tsk));
      }
   } // queryData
   
   public Boolean hasDisplayList{
      get {return displayList != null && !displayList.isEmpty();} // get
   } // hasDisplayList
   
   public List<TaskWrapper> displayList{get;set;}
   
   public class TaskWrapper {
   	public Task tsk{get;set;}
      public TaskWrapper(Task p_tsk) {
         tsk = p_tsk;
      }
   } // class TaskWrapper
   
   
} // class NSSInboundActivity