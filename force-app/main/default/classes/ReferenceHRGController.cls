/* 
 * Controller for logging the HRG Onboarding/Activity
 *
 * History
 * -------
 * 03/01/2013 Dan Carmen        Created
   10/01/2013 Dan Carmen        Added in check for PREMIER_PLAN_CODE_SET for mass update
   10/08/2013 Dan Carmen        Fix for contact being attached to all activity on mass create. Added error handling for saving/deleting activity
   10/24/2013 Dan Carmen        Added Manager to account team selection. Choice for deleting the activity.
   02/28/2014 Carrie Marciano   Added code to display open tasks that need to be associated with an HRG activity on the first screen and ability to delete SF activities 
                                that do not need HRG Activity associated to them.  Also added reference to standard controller for use in Salesforce1.  
   10/21/2014 Dan Carmen        Added DurationInMinutes to event query
   04/01/2015 Cindy Freeman     Removed HR Managers from getAccountTeamAccounts query to avoid View State error on page
   02/26/2015 Cindy Freeman     Added constructor so can be used with Mobile page, added indicator and modified code if called by Mobile page
   06/01/2015 Jacob Hinds       Limiting Contacts returned on Activity Picklist
   08/14/2015 Dan Carmen        Added extra debugging. Change to ensure ActivityDate is populated on activity.
   01/05/2015 Justin Stouffer   Fixed bug so child records get Onboarding End Date calculated. Added error if Health reason is > 254 characters.
   05/05/2016 Lynn Michels      changed the query getControlledOwnershipAccounts to filer by premier products so no lost Accounts are returned - case 21048917
   05/18/2016 Justin Stouffer   Added a way to sort the ExtraAccountslist and updated a few things to be compatible with changes to the HRG Mobile Page.
   08/03/2016 Jermaine Stukes	Added additional fieldset containing Onboarding % complete date fields.Used in checkOnboardingDates. 
   03/27/2017 Lynn Michels		Populate Related_Activity__c checkbox on the ReferenceHRGActivity records; case 23793971
   04/04/2017 Cindy Freeman		Added SetController to handle Client List that is too big to display on vf page    
   04/25/2017 Lynn Michels		Added changes to use Comments more effeciently for BU
   04/26/2017 Cindy Freeman		Added Order By to extraAccount queries 
   04/30/2018 Cindy Freeman		if comingFromMobile is true, set recsPerPage = 9999
   05/29/2018 Lynn Michels		Change paging functionality to use standardSetController with query
   09/23/2018 Cindy Freeman		Modified method that sets Onboarding Completed Date
   10/02/2018 Cindy Freeman		fix to accept Handbook date of null
   10/31/2018 Jake Hinds		Adding HROi to plan codes
   09/08/2020 Brandon Vidro     Removing HROi from plan codes - APR0110711	
   01/24/2024 Reetesh Pandey	Added Custom Label Premier_Products for premier products
 */
public without sharing class ReferenceHRGController {

   public String currentStep{get;set;}
   
   public Boolean promptForAccount{get;set;}
   
   public User curUser{get;private set;}
   
   public Boolean okayToProceed{get;set;}
   
   private Id acctId = null;
   private String acctType = null;      // used in checkOnboardingDates
  
   public String deleteKey{get;set;}
   
   public Boolean comingFromMobile{get; set;}

   //public Boolean showOpenActivityList{get;set;}
   
   public ReferenceHRGController(ApexPages.StandardController controller) {
      // get the current user
      curUser = [Select Id, Name, Email, Profile.Name from User where Id = :UserInfo.getUserId()];
      comingFromMobile = false;
      recsPerPage = 50;
      recIdCounter = 0;
      // the Id of the Account should be passed in here. If not, cannot proceed
      //Id acctId = System.currentPageReference().getParameters().get('acctId');
      //setInteractionTypeStep();
      setAskForWhatTheyDidStep();
      
      // initialize the selectedActivity property
      //selectedActivity = new ActivityWrapper();
      
      acctId = System.currentPageReference().getParameters().get('acctId');
      acctId = (acctId != null ? acctId : controller.getRecord().id);
      
      promptForAccount = !queryAcct(acctId);
      if (promptForAccount) {
         currentStep = 'Prompt For Account';
      }
      // default to an event
      //selectedActivity.taskOrEvent = 'Event';
      if (promptForAccount) {
        // use the account lookup to get the account
         refHRG = new Reference_HRG__c();
      } else {
         setRefHRG();
         //CLM Update 
         checkForActivityToConfirm();
      }
      /*
      if (acct == null) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A valid Prospect-Client was not found! Unable to proceed'));
         okayToProceed = false;
         return;
      }
      */

      okayToProceed = true;
      savePerformed = false;    
      
   } // ReferenceHRGController
  
  /** No argument constructor. */
   public ReferenceHRGController() {
      // get the current user
      curUser = [Select Id, Name, Email, Profile.Name from User where Id = :UserInfo.getUserId()];
      comingFromMobile = false; 
      recsPerPage=50;
      recIdCounter = 0;
      // the Id of the Account should be passed in here. If not, cannot proceed
      //Id acctId = System.currentPageReference().getParameters().get('acctId');
      //setInteractionTypeStep();
      setAskForWhatTheyDidStep();
      
      // initialize the selectedActivity property
      //selectedActivity = new ActivityWrapper();
      
      acctId = System.currentPageReference().getParameters().get('acctId');
      promptForAccount = !queryAcct(acctId);
      if (promptForAccount) {
         currentStep = 'Prompt For Account';
      }
      // default to an event
      //selectedActivity.taskOrEvent = 'Event';
      if (promptForAccount) {
        // use the account lookup to get the account
         refHRG = new Reference_HRG__c();
      } else {
         setRefHRG();
         //CLM Update 
         checkForActivityToConfirm();
      }
      /*
      if (acct == null) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A valid Prospect-Client was not found! Unable to proceed'));
         okayToProceed = false;
         return;
      }
      */
      
      okayToProceed = true;
      savePerformed = false;      
      
   } // ReferenceHRGController
   
   
   /** AccountID arguments constructor, used by mobile page */
   public ReferenceHRGController(Id p_accountId) {
      // get the current user
      curUser = [Select Id, Name, Email, Profile.Name from User where Id = :UserInfo.getUserId()];
      comingFromMobile = false;                 //cmf
      recsPerPage=100;
      recIdCounter = 0;
      // the Id of the Account should be passed in here. If not, cannot proceed
      //Id acctId = System.currentPageReference().getParameters().get('acctId');
      //setInteractionTypeStep();
      setAskForWhatTheyDidStep();      
      // initialize the selectedActivity property
      //selectedActivity = new ActivityWrapper();      
      acctId = p_accountId;
     
      promptForAccount = !queryAcct(acctId);
      if (promptForAccount) {
         currentStep = 'Prompt For Account';
      }
      // default to an event
      //selectedActivity.taskOrEvent = 'Event';
      if (promptForAccount) {
        // use the account lookup to get the account
         refHRG = new Reference_HRG__c();
      } else {
         setRefHRG();
         //CLM Update 
         checkForActivityToConfirm();
      }
            
      okayToProceed = true;
      savePerformed = false;
            
   } // ReferenceHRGController
   
   
   
   /** If the form has to query for the account, it will call this method. */
   public void setAccount() {
    acctId = (refHRG != null ? refHRG.Account__c : null);
    setAccount(acctId);
   } // setAccount

   public void setAccount(Id acctId) {
      currentStep = 'Prompt For Account';
      // reset variable just in case
      savePerformed = false;
      promptForAccount = !queryAcct(acctId);
      if (!promptForAccount) {

         setAskForWhatTheyDidStep();
         setRefHRG();
      }
   } // setAccount
   
   //public void setInteractionTypeStep() {
   //   currentStep = 'Interaction Type';
   //} // setInteractionTypeStep
   
   public void setAskForWhatTheyDidStep() {
    setWhatDidYouDoStep();
   } // setAskForWhatTheyDidStep
   
   public void setWhatDidYouDoStep() {
    if (currentStep == STEP_ACCOUNT_HEALTH) {
        // reset the account health
        acct.Premier_Account_Health__c = oldAcctHealthValue;
    }
      currentStep = 'What Did You Do';
   } // setWhatDidYouDoStep
   

    public Boolean isUserIdSet {get;set;} //is the user set to use in the query?
	public ClientListController clc {get;set;}
	
    public void setUserId(){
   		clc = new ClientListController();
        currentStep = 'Choose HRG';
      
        //if the user is an area manager and they chose Client Base, we need a list of HRGs to choose from
       if(clc.isAreaManager && logActivitySelection == LOG_CLIENTS){
        	isUserIdSet = false;
        	clc.getHrgsFromAccounts(acct.Id);  //setting isAreaManager in ClientListController.cls
        }
        //else, proceed as before, using the curUser ID for the acctQuery
        else{
        	UserIdToUseForClientList = curUser.id;
        	isUserIdSet = true;
        	setupExtraAccountsList();
        }   
   } // setUserId
   
   public String hrgName {get;set;}
   map<id, String> hrgNames = new map<id,String>();
   public String hrg{get;set;} //the hrg selected on the page
   public id userIdToUseForClientList; //used to query the list for the selected HRG
   
   //when an hrg is selected, set userIdToUseForClientList to selected HRG so that HRG's client list is queried
    public void setCurUserToHrg(){
    	if(String.isNotBlank(hrg)){
    		userIdToUseForClientList = hrg;
    		hrgName = hrgNames.get(hrg);
    	}
    	
    	isUserIdSet = true;


    	setupExtraAccountsList();
    }//end setCurUserToHrg
     
   public String blockTitle{get;set;} 
   public void setVerifyActivityStep() {
      if (checkForActivityToConfirm()) {
         // setup log activity radio button options
         setupLogActivityOptions();
         
         currentStep = 'Verify Activity';
         system.debug('currentStep ' +currentStep);
      }//end if curUser 
   } // setVerifyActivityStep
   
   public ActivityWrapper selectedActivity{get;set;}
  
   public static String LOG_THIS='thisRecord';
   public static String LOG_CONTROLLED='controlledOwnership';
   public static String LOG_CLIENTS='clientBase';
      
   public String logActivitySelection{get;set;}
   
   public List<SelectOption> logActivityOptions{get;set;}
   
   public void setupLogActivityOptions() {
      logActivityOptions = new List<SelectOption>();
      logActivityOptions.add(new SelectOption(LOG_THIS,'Only This Prospect-Client-'+acct.Name));
      logActivitySelection = LOG_THIS;
      if (isControlledOwnership) {
         logActivityOptions.add(new SelectOption(LOG_CONTROLLED, 'Controlled Ownership Relationship'));
      }
      logActivityOptions.add(new SelectOption(LOG_CLIENTS, 'My Client Base'));
   } // setupLogActivityOptions
   
   public void selectHrgActivity() {
      //String activityId = System.currentPageReference().getParameters().get('activityId');
      String actionType = System.currentPageReference().getParameters().get('actionType');
      String activityKey = System.currentPageReference().getParameters().get('activityKey');
      String hrgActivityId = System.currentPageReference().getParameters().get('hrgActivityId');
      String hrgRecId = System.currentPageReference().getParameters().get('hrgRecId');
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'actionType='+actionType+' activityKey='+activityKey+' hrgActivityId='+hrgActivityId));
      
      if (actionType != null && actionType == 'deleteFromVerify' && activityKey != null && hrgActivityId != null) {
         ActivityWrapper aw = activityToSaveMap.get(activityKey);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'aw='+aw));
         if (aw != null) {
            // search through the activity for a matching id
            ReferenceHRGActivityWrapper haw = aw.removeActivity(hrgActivityId);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'haw='+haw));
            if (haw != null) {
               aw.addToDescription('\nRemoved '+haw.activity.Type__c+': '+haw.label+' on '+Date.today().format());
               delete haw.activity;
               if (aw.isEvent) {
                  update aw.evnt;
               } else if (aw.isTask) {
                  update aw.tsk;
               }
            } // if (haw != null
         } // if (aw != null
      } // if (actionType != null && activtyType == 'deleteFromVerify
   } // selectHrgActivity
   
   public PageReference deleteSalesforceActivity() {
      System.debug('deleteKey= '+deleteKey);        
      if (deleteKey != null) {
         ActivityWrapper aw = activityToSaveMap.get(deleteKey);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'aw='+aw));
         if (aw != null) {
            if (aw.isEvent) {
                  delete aw.evnt;
               } else if (aw.isTask) {
                  delete aw.tsk;
               }         
         } // if (aw != null         
      } //
      if(comingFromMobile){
          return Null;
      }
      else{
          PageReference pageRef = new PageReference(ApexPages.currentPage().getURL());
          System.debug('pageRef= '+ApexPages.currentPage().getURL()); 
          pageRef.getParameters().put('acctId',acctId); 
          pageRef.setRedirect(true);
          return pageRef;
      }
   } // deleteSalesforceActivity
   
   
   /*
   public void saveOpenActivity() {
    List<ActivityWrapper> saveActivity = new List<ActivityWrapper>();
    saveActivity.add(selectedActivity);
      if (executeSave(saveActivity)) {
         setAccount();
      } // if (executeSave
   } // saveOpenActivity
   */
   
   /** Was the onboarding completed? */
   public Boolean showOnboarding{get;set;}
   
   public Boolean onboardingIsComplete{get;private set;}

   /** Toggle the showOnboarding setting
    */
   public void toggleOnboarding() {
      showOnboarding = !showOnboarding; 
   } // toggleOnboarding
   
   public Boolean showClientConcerns{get;set;}
   
   public void toggleShowClientConcerns() {
      showClientConcerns = !showClientConcerns;
   } // toggleShowClientConcerns
   
   public Boolean showSetupIssues{get;set;}
   
   public void toggleShowSetupIssues() {
      showSetupIssues = !showSetupIssues;
   } // toggleShowSetupIssues
   
   public Boolean showProductUtilization{get;set;}
   
   public void toggleShowProductUtilization() {
      showProductUtilization = !showProductUtilization;
   } // toggleShowProductUtilization
   
   public void setRefHRG() {
      refHRG = getRefHRG(acct.Id);
      // if onboarding isn't complete default to onboarding activity
      System.debug('refHRG.Collapse_Onboarding__c='+refHRG.Collapse_Onboarding__c);
      onboardingIsComplete = (refHRG.Collapse_Onboarding__c != null && refHRG.Collapse_Onboarding__c);
      showOnboarding = !onboardingIsComplete;
      showClientConcerns = false;
      showSetupIssues = false;
      showProductUtilization = false;
      refHRG.DateofLastVisit__c = Date.today();
      
      //setupHrgActivity();      
      getOpenHRGActivity(refHRG.Id);

      // Set the information from the reference object
      for (ReferenceHrgActivityWrapper haw : onboardingActivityList) {          
         haw.setHRGActivity(refHRG);
      }
      for (ReferenceHrgActivityWrapper haw : onboardingConcernsList) {
         haw.setHRGActivity(refHRG);
      }
      for (ReferenceHrgActivityWrapper haw : onboardingSetupList) {
         haw.setHRGActivity(refHRG);
      }
      
   } // setRefHRG
   
   public Account acct{get;set;}
   
   public Reference_HRG__c refHRG{get;set;}
   
   public static String RT_EVENT='2008-09 Premier Service Event Record Type';
   public static String RT_TASK='2008-09 Premier Service Provider Task Record Type';
   
   /** Is this part of a controlled ownership relationship? */
   public Boolean isControlledOwnership{get;set;}

   /** The plan codes that identify the premier products. */
    public static Set<String> PREMIER_PLAN_CODE_SET = new Set<String>(System.Label.Premier_Products.split(';'));//new Set<String>{'884', '793', '1010', '1005', '1029'};
        																//Commenting out per APR0110711
        																/*,'HROI PEO','HROI TA 401k'};
       																	//,'HROI EPLI',
   																		//'HROI WC','HROI EAP','HROI ISM','HROI FSA','HROI HAS','HROI Vision',
   																		'HROI Dental','HROI Medical','HROI GL','HROI TAA'};*/
   
   /** Get the Account, it's contacts and activities
       Only select open activities. We will select all of the activity that is open and the associated HRG activity.
       An activity is open if date activity completed is blank and meeting not held is not selected.
    */
   public boolean queryAcct(Id acctId) {
      acct = null;
      System.debug('queryAcct acctId='+acctId);
      
      try {
         acct = [Select Id, Name, AccountNumber, Bis_ID__c, Type
                       ,Premier__c, Premier_Account_Health__c, HR_Solutions_Account_Health_Updated__c
                       ,ParentId
                      ,(Select Id, Name, Phone, Email, Title from Contacts limit 999)
                       ,(Select Id, TeamMemberRole, UserId
                           From AccountTeamMembers
                          Where TeamMemberRole in (:ZipCheckOwner.AT_401K, :ZipCheckOwner.AT_HRG, :ZipCheckOwner.AT_HRM))
                       // select the asset with the latest start date that does not have a cancel date
                       ,(Select Id, Start_Date__c, Product_Plan_Code__c
                           From Assets
                          Where Plan_Cancel_Date__c = null
                           order by Start_Date__c asc)
                   from Account
                  Where Id = :acctId];
                  
         Event[] events = [Select Id, ActivityDate
                              ,ActivityDateTime
                              ,DurationInMinutes
                              ,OwnerId
                              ,Activity__c
                              ,Activity_Source__c
                              ,Description, Client_Summary__c
                              ,Date_Activity_Completed__c
                              ,HRG_Activity_Type__c
                              ,Meeting_Not_Held__c
                              ,Reason_Canceled__c, WhoId
                              ,Subject, Type 
                          from Event 
                         Where RecordType.Name=:RT_EVENT
                           and AccountId = :acctId
                           and Meeting_Not_Held__c = false
                           and Date_Activity_Completed__c = null
                           and ActivityDate != null
                          order by ActivityDate desc
                          limit 20];
         Task[] tasks = [Select Id, ActivityDate,OwnerId,Activity__c
                              ,Activity_Source__c
                              ,Description, Client_Summary__c
                              ,Date_Activity_Completed__c
                              ,HRG_Activity_Type__c
                              ,IsClosed
                              ,Meeting_Not_Held__c
                              ,Reason_Canceled__c, WhoId
                              ,Status, Subject, Type
                          from Task
                         Where RecordType.Name=:RT_TASK
                           and AccountId = :acctId
                           and Meeting_Not_Held__c = false
                           and Date_Activity_Completed__c = null
                           and ActivityDate != null
                          order by ActivityDate desc
                          limit 20];

         isControlledOwnership = acct.ParentId != null;
         
         // if it doesn't have a parent, check if it has any children
         if (!isControlledOwnership) {
            isControlledOwnership = ([Select count() from Account where ParentId = :acct.Id limit 1] > 0);
         }
         
         setupActivityInfo(events,tasks);
         setupContactSelectionList();
      } catch (Exception e) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error selecting data for account '+acctId+'!'));
         System.debug('queryAcct exception: '+e);
         System.debug('queryAcct '+e.getMessage()+'; '+e.getStackTraceString());
      }
      if (acct != null)
      {  acctType = acct.Type;  }
          
      return (acct != null);
   } // queryAcct
   
   /** is the Health Update date populated? */
    public Boolean hasHealthUpdate {
        get {return (acct!=null && acct.HR_Solutions_Account_Health_Updated__c!=null);  }
    }
    
   /** Are there records in the open activity list? */
   public Boolean hasOpenActivityList {
      get {return (openActivityList != null && !openActivityList.isEmpty()); }
   } // hasOpenActivityList
   
   public List<ActivityWrapper> openActivityList{get;set;}
   
   public List<ActivityWrapper> sortedOpenActivityList{get;set;}
   
   /** A map of the open activity, by id, for easy reference later. */
   private Map<String,ActivityWrapper> openActivityById = new Map<String,ActivityWrapper>();
   
   /** A map of the open activity by key (date-event/task). */
   private Map<String,ActivityWrapper> openActivityByKeyMap = new Map<String,ActivityWrapper>();

   /** Setup the open activity. */
   public void setupActivityInfo(Event[] events, Task[] tasks) {
      System.debug('setupActivityInfo');
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupActivityInfo'));

      openActivityList = new List<ActivityWrapper>();
      openActivityById.clear();
      openActivityByKeyMap.clear();
      
      // keep track of all of the activity ids. Use a String because we will be querying a string field on the HRG Activity
      //String[] activityIds = new String[]{}; 
      
      if (events != null && !events.isEmpty()) {
         System.debug('setupActivityInfo hasEvents');
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupActivityInfo nbr events='+acct.Events.size()));
         for (Event activity : events) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupActivityInfo open event id='+activity.Id));
            ActivityWrapper aw = new ActivityWrapper(activity);
            openActivityList.add(aw);
            openActivityById.put(activity.Id,aw);
            // used so we can format the output
            DateTime activityDateTime = DateTime.newInstance(activity.ActivityDate, TEMP_TIME);
            aw.key = activityDateTime.format('yyyyMMDD')+'Event';
            openActivityByKeyMap.put(aw.key,aw);
            //activityIds.add(activity.Id);
         } // for (Event
      } // if (acct != null && acct.Events != null

      if (tasks != null && !tasks.isEmpty()) {
         System.debug('setupActivityInfo hasTasks');
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupActivityInfo nbr tasks='+acct.Tasks.size()));
         for (Task activity : tasks) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupActivityInfo open task id='+activity.Id));
            ActivityWrapper aw = new ActivityWrapper(activity);
            openActivityList.add(aw);
            openActivityById.put(activity.Id,aw);
            // used so we can format the output
            DateTime activityDateTime = DateTime.newInstance(activity.ActivityDate, TEMP_TIME);
            aw.key = activityDateTime.format('yyyyMMDD')+'Task';
            openActivityByKeyMap.put(aw.key,aw);
            //activityIds.add(activity.Id);
         } // for (Task activit
      } // if (acct != null && acct.Tasks != null
      
      //sorts the open activities by date for display on HRG Activity page 
      sortedOpenActivityList = new List<ActivityWrapper>();
      sortedOpenActivityList.addAll(openActivityList);
      sortedOpenActivityList.sort();
      
      System.debug('setupActivityInfo openActivityByKeyMap.size='+openActivityByKeyMap.size()+' openActivityList.size='+openActivityList.size()+' hasOpenActivityList='+hasOpenActivityList);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupActivityInfo openActivityByKeyMap.size='+openActivityByKeyMap.size()+' openActivityList.size='+openActivityList.size()+' hasOpenActivityList='+hasOpenActivityList));
   } // setupActivityInfo
   
   /** The names of the fields from the fieldsets that are date fields. */
   //private List<String> dateFieldNames = new List<String>();
   
   /** The names of the date fields just for the onboarding fields. */ 
   private List<String> onboardingDateFieldNames = new List<String>();
    
   // The fields used to populate End date. 
   public List<Schema.FieldSetMember> getOnboardCompleteDates() 
   {
      return Schema.SObjectType.Reference_HRG__c.FieldSets.Onboarding_Complete_Dates.getFields();
   } // getOnboardingFields
    
    /** Set of date fields used to calculate Onboarding % complete. */ 
    private Set<String> onboardingCompleteDates = new Set<String>();
    
    //Populate onboardingCompleteDates set
    public void getCompleteDateFields()
    {
        List<Schema.FieldSetMember> onboardingDates = Schema.SObjectType.Reference_HRG__c.FieldSets.Onboarding_Complete_Dates.getFields();
        if (acctType == 'PEO Client')
        {	onboardingDates = Schema.SObjectType.Reference_HRG__c.FieldSets.Onboarding_Complete_Dates.getFields();	}
        else
        {	onboardingDates = Schema.SObjectType.Reference_HRG__c.FieldSets.Onboarding_Complete_Dates_ASO.getFields();	}            
    	for (Schema.FieldSetMember oneDate : onboardingDates) 
        {	onboardingCompleteDates.add(oneDate.getFieldPath());	} 
        System.debug('ReferenceHRGController.getCompletedDateFields size='+onboardingCompleteDates.size());
    }
   
   private Map<String,ReferenceHrgActivityWrapper> hrgOnboardingActivityMap = new Map<String,ReferenceHrgActivityWrapper>();

   public String buildQueryWithFieldset(String activityType, List<Schema.FieldSetMember> checkfields, List<ReferenceHrgActivityWrapper> activityList, Boolean saveDateField) {
    String query = '';
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'activityType='+activityType+' checkfields='+checkfields));
      if (checkfields != null && !checkfields.isEmpty()) {

         // it is assumed that the note field will follow the date field in the fieldset.
         // keep track of the previous one - to add the notes field to the date
         ReferenceHrgActivityWrapper prevHaw = null;

         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'activityType='+activityType+' in if statement numberRecs='+checkfields.size()));
         for (Schema.FieldSetMember f : checkfields) {
            query += f.getFieldPath() + ', ';
            //if (isOnboarding && f.getType() == Schema.DisplayType.Date) {
            //  dateFieldNames.add(f.getFieldPath());
            
            // if this is onboarding, create activity wrapper
            if (activityList != null) {
               if (f.getType() == Schema.DisplayType.Date) {
                      if (saveDateField) {
                          // save the field names for the onboarding date fields so we can check later if they're all populated.
                          onboardingDateFieldNames.add(f.getFieldPath());
                      }
                  ReferenceHrgActivityWrapper haw = new ReferenceHrgActivityWrapper(String.valueOf(recIdCounter++),activityType,f.getLabel(),f.getFieldPath());
                  haw.activity.Assigned_to__c = curUser.Id;
                  prevHaw = haw;
                  activityList.add(haw);
                  // store in a map for easy reference later
                  hrgOnboardingActivityMap.put(haw.label,haw);
               } else if (f.getType() == Schema.DisplayType.TextArea && prevHaw != null) {
                  // add the notes field
                  prevHaw.addNoteInfo(f.getFieldPath());
               } // if (f.getType()
            } // if (onboardingActivityList
            //} // if (isOnboarding && f.getType()
         } // for (Schema
      } // if (checkFields)
      return query;
   } // buildQueryWithFieldset
   
   /** The fields for the onboarding section. */
   public List<Schema.FieldSetMember> getOnboardingFields() {
      return Schema.SObjectType.Reference_HRG__c.FieldSets.Onboarding_Fields.getFields();
   } // getOnboardingFields
   
   /** The fields for the onboarding client concerns section. */
   public List<Schema.FieldSetMember> getClientConcernFields() {
      return Schema.SObjectType.Reference_HRG__c.fieldSets.Client_Concerns.getFields();
   } // getClientConcernFields
   
   /** The fields for the onboarding setup issues section. */
   public List<Schema.FieldSetMember> getSetupIssueFields() {
      return Schema.SObjectType.Reference_HRG__c.fieldSets.Setup_Issues.getFields();
   } // getSetupIssueFields
   
   /** The fields used for product utilization. */
   public List<Schema.FieldSetMember> getProductFields() {
      return Schema.SObjectType.Reference_HRG__c.fieldSets.ProductFields.getFields();
   } // getProductFields
   
   public static String TYPE_ONBOARDING='Onboarding';
   public static String TYPE_ONBOARDING_CONCERNS='Onboarding Concerns';
   public static String TYPE_ONBOARDING_ISSUES='Onboarding Setup Issues';
   
   public static Set<String> ONBOARDING_TYPES = new Set<String>{TYPE_ONBOARDING,TYPE_ONBOARDING_CONCERNS,TYPE_ONBOARDING_ISSUES};

   public List<ReferenceHrgActivityWrapper> onboardingActivityList{get;set;}
   public List<ReferenceHrgActivityWrapper> onboardingConcernsList{get;set;}
   public List<ReferenceHrgActivityWrapper> onboardingSetupList{get;set;}
   
   /** The original values for the product utilization fields if not empty. Used to compare if any changes were made. */
   private Map<String,String> productOriginalValues = new Map<String,String>();
   
   /** Get the reference object based on the account id.
    */ 
   public Reference_HRG__c getRefHRG(Id acctId) {
    Reference_HRG__c tempRefHRG = null;
    // build the query
    String query = 'Select ';

      // initialize all of the lists
      onboardingActivityList = new List<ReferenceHrgActivityWrapper>();
      onboardingConcernsList = new List<ReferenceHrgActivityWrapper>();
      onboardingSetupList = new List<ReferenceHrgActivityWrapper>();

    // get the fields from the field sets
      query += buildQueryWithFieldset(TYPE_ONBOARDING,getOnboardingFields(),onboardingActivityList,true);
      query += buildQueryWithFieldset(TYPE_ONBOARDING_CONCERNS,getClientConcernFields(),onboardingConcernsList,false);
      query += buildQueryWithFieldset(TYPE_ONBOARDING_ISSUES,getSetupIssueFields(),onboardingSetupList,false);
      query += buildQueryWithFieldset('Product Fields',getProductFields(),null,false);

      query += 'Id, Name, Account__c, BIS_ID__c, Branch_Client_Number__c, Case_Lookup__c, DateofLastVisit__c, HRG__c';
      query += ',Client_Concern_Count__c,Setup_Issue_Count__c, OwnerId, HRS_Account_Owner__c';
      query += ',Expected_Onboarding_End_Date__c,Onboarding_End_Date__c,Onboarding_Start_Date__c';
      query += ',Onboarding_Completed__c,ProductUtilization__c, Collapse_Onboarding__c ';
      query += ',Open_Activities__c, Sales_Rep_Attended_CC_Meeting__c ';
//      query += ',(Select Id,Activity__c,Activity_Date__c,Activity_Type__c,Closed__c,Complete_Date__c,Notes__c ';
//      query += '  From Reference_HRG_Activities__r order by createdDate desc) ';
      query += ' From Reference_HRG__c Where Account__c = \''+acctId+'\' or Case_Lookup__r.AccountId = \''+acctId+'\' order by createdDate desc limit 1';

      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'query='+query));
      Reference_HRG__c[] refs = Database.query(query);
   
      if (refs.isEmpty()) {
         // create a new one - default the onboarding start to today
         tempRefHRG = new Reference_HRG__c(Account__c=acctId, Onboarding_Start_Date__c=findPlanStartDate(acct));
         
         //if (acct != null && acct.Assets != null && !acct.Assets.isEmpty()) {
         //   tempRefHRG.Onboarding_Start_Date__c = acct.Assets[0].Start_Date__c;
         //}
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getRefHRG creating new'));
      } else {
         tempRefHRG = refs[0];
         
         // save the original sales rep cc meeting value, if not null
         if (String.isNotBlank(tempRefHRG.Sales_Rep_Attended_CC_Meeting__c)) {
            productOriginalValues.put('Sales_Rep_Attended_CC_Meeting__c',tempRefHRG.Sales_Rep_Attended_CC_Meeting__c);
         }
         
         // set the original values from the product fields
         for (Schema.FieldSetMember f : getProductFields()) {
            String value = (String)tempRefHRG.get(f.getFieldPath());
            if (String.isNotBlank(value)) {
               productOriginalValues.put(f.getFieldPath(),value);
            }
         } // for
        
         //Integer nbrActivities = (refHRG.Reference_HRG_Activities__r != null ? refHRG.Reference_HRG_Activities__r.size() : -1);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getRefHRG found existing'));
      }
      //setExistingActivity(refHRG);
    return tempRefHRG;
   } // getRefHRG
   
   public Date findPlanStartDate(Account acct) {
       Asset asst = findPremierAsset(acct);
       Date dt = (asst != null ? asst.Start_Date__c : Date.today());
       return dt;
   } // findPlanStartDate
   
   /** Find and return the first premier asset. */
   public Asset findPremierAsset(Account acct) {
      system.debug ('findPremierAssets acct Id' +acct.id);
      Asset foundAsset = null;
       if (acct != null && acct.Assets != null && !acct.Assets.isEmpty()) {
          for (Asset asst : acct.Assets) {
             //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'findPlanStartDate asst.Product_Plan_Code__c='+asst.Product_Plan_Code__c));
             if (PREMIER_PLAN_CODE_SET.contains(asst.Product_Plan_Code__c)) {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'findPlanStartDate found Asset!'));
                foundAsset = asst;
                break;
             }
          }
       } // if (acct
      return foundAsset;
   } // findPremierAsset
   
   public List<ReferenceHrgActivityWrapper> pendingHrgActivityList{
      get { 
         List<ReferenceHrgActivityWrapper> tempList = new List<ReferenceHrgActivityWrapper>();
         if (hasOpenActivityList) {
            for (ActivityWrapper aw : openActivityList) {
               tempList.addAll(aw.originalHrgActivity);
            } // for (ActivityWrapper
         } // if (hasOpenActivityList
         return tempList;
        
      } // pendingHrgActivityList
     
   } // pendingHrgActivityList
   
   /** If there is any open activity, we will select it and associate it with the task/event.
    */
   public void getOpenHRGActivity(Id refHrgId) {
      ongoingActivityList = new List<ReferenceHrgActivityWrapper>();
      //pendingHrgActivityList = new List<ReferenceHrgActivityWrapper>();
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getOpenHRGActivity hasOpenActivityList='+hasOpenActivityList));
      // get the ids of the open activity (if any)
      if (hasOpenActivityList) {
         for (ReferenceHRGActivity__c[] activities : [Select Id
                                                         ,Account__c
                                                         ,Activity__c
                                                         ,Activity_Date__c
                                                         ,Activity_Type__c
                                                         ,ActivityId__c
                                                         ,Assigned_to__c
                                                         ,Closed__c
                                                         ,Complete_Date__c
                                                         ,First_Activity_Date__c
                                                         ,Notes__c
                                                      	 ,Onsite_Meeting_Attendees__c
                                                         ,Reference_HRG__c
                                                         ,TaskOrEvent__c
                                                         ,Type__c
                                                     From ReferenceHRGActivity__c
                                                    Where Reference_HRG__c = :refHrgId
                                                      //and Activity_Type__c != :HEALTH_CHANGE
                                                      and ActivityId__c in :openActivityById.keySet()
                                                      and (Closed__c = false 
                                                           or Activity_Type__c in :ONBOARDING_TYPES)
                                                     order by Activity_Date__c]) {
                                                        
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getOpenHRGActivity found records:'+activities.size()));           
            for (ReferenceHRGActivity__c activity : activities) {
                // add the pending HRG activity under the open task or event 
                ActivityWrapper aw = openActivityById.get(activity.ActivityId__c);
                if (aw != null) {
                   ReferenceHrgActivityWrapper haw = new ReferenceHrgActivityWrapper(String.valueOf(recIdCounter++),activity);
                   aw.addHRGActivity(haw);
                   //pendingHrgActivityList.add(haw);
                   // see if this is onboarding activity - if so, set the date and notes fields so they can be saved
                   ReferenceHrgActivityWrapper checkHaw = hrgOnboardingActivityMap.get(haw.label);
                   System.debug('**CMF ** getOpenHRGActivity haw label='+haw.label+' checkHaw='+checkHaw);
                   if (checkHaw != null) {
                      haw.isOnboarding = true;
                      haw.dateFieldName = checkHaw.dateFieldName;
                      haw.notesFieldName = checkHaw.notesFieldName;
                   }
                } // if (aw != null
                
                /*
               // if this is onboarding activity
               if (ONBOARDING_TYPES.contains(activity.Activity_Type__c)) {
                  String key = activity.Activity_Type__c+'-'+activity.Activity__c;
                  ReferenceHrgActivityWrapper haw = hrgOnboardingActivityMap.get(key);
                  if (haw != null) {
                     haw.activityMatches(activity);
                  }
               } else {
                   // open activity - add to ongoing activity list
                  ongoingActivityList.add(new ReferenceHrgActivityWrapper(String.valueOf(recIdCounter++),activity));
               }
               */
            } // for (ReferenceHRGActivity__c activity
          
         } // for (ReferenceHRGActivity__c[] activities
         
         // save original values
         for (ActivityWrapper aw : openActivityList) {
            if (aw.hasHrgActivity) {
                aw.originalHrgActivity.addAll(aw.hrgActivity);
            }        
         } // for        
      } // if (hasOpenActivityList
   } // getOpenHRGActivity
   
   
   
   /** Is there a contact picklist? */
   public Boolean hasContactSelections{
      get {return (contactSelections != null && !contactSelections.isEmpty()); }
   } // hasContactSelection
   
   public List<SelectOption> contactSelections{get;set;}
   
   /** If there are any contacts, setup a picklist of the contacts. */
   public void setupContactSelectionList() {
      System.debug('setupContactSelectionList');
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'In setupContactSelectionList'));
      contactSelections = new List<SelectOption>();
      // make sure there's at least one contact
      if (acct != null && acct.Contacts != null && !acct.Contacts.isEmpty()) {
        System.debug('setupContactSelectionList has contacts');
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'In setupContactSelectionList has contacts'));
        contactSelections.add(new SelectOption('None','---Choose A Contact---'));
        for (Contact ctct : acct.Contacts) {
            String contactName = ctct.Name+(ctct.Title != null ? '-'+ctct.Title : '')/*+ (ctct.Phone != null ? '-'+ctct.Phone : '') + (ctct.Email != null ? '-'+ctct.Email : '')*/;
            contactSelections.add(new SelectOption(ctct.Id,contactName));
        } // for (Contact ctct
      } // if (acct != null
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'In setupContactSelectionList contactSelections.size='+contactSelections.size()));
   } // setupContactSelectionList
   
   public Boolean hasOngoingActivityList{
      get {return (ongoingActivityList != null && !ongoingActivityList.isEmpty()); }
   }
   /** The list displayed to the user containing the ongoing activity. */
   public List<ReferenceHrgActivityWrapper> ongoingActivityList{get;set;}
   
   public Integer nbrNewOngoingActivities{get;set;}
   
   public pagereference addOngoingActivity() {
      if (nbrNewOngoingActivities != null && nbrNewOngoingActivities > 0) {
        // new list so we can add new records to the "top" of the list
        //List<ReferenceHRGActivity__c> newRecs = new List<ReferenceHRGActivity__c>();
        List<ReferenceHrgActivityWrapper> newRecs = new List<ReferenceHrgActivityWrapper>();
        
         for (Integer cnt=0; cnt<nbrNewOngoingActivities; cnt++) {
            ReferenceHRGActivity__c activity = new ReferenceHRGActivity__c(Activity_Date__c=refHRG.DateofLastVisit__c, Account__c=acct.Id, Assigned_to__c=curUser.Id);
            //newRecs.add(activity);
            newRecs.add(new ReferenceHrgActivityWrapper(String.valueOf(recIdCounter++),activity));
         }
         //newRecs.addAll(ongoingActivityList);
         //ongoingActivityList = newRecs;
         
         newRecs.addAll(ongoingActivityList);
         ongoingActivityList = newRecs;
      } // if (nbrNewOnboarding != null
      nbrNewOngoingActivities = null;
      return null;
   } // addNewOnboarding
   
   /** Cancel from the page. Return to the previous page if you can.
    */
   public PageReference cancel() {
      PageReference returnPr = new PageReference('/'+(acct != null ? acct.Id : ''));
      return returnPr;
   } // cancel

   /** The number of activities to confirm. */
   public Integer nbrActivityToConfirm{
      get {return (activityToConfirm != null ? activityToConfirm.size() : 0); }
   }
   
   /** The activity that the user entered that we need to confirm. */
   public List<ReferenceHrgActivityWrapper> activityToConfirm{get;set;}
   
   private Boolean allOkay = true;
   
   /** Were changes made that need to be saved on the Reference object? */
   public Boolean refHrgChanged{get;set;}
   
   /** Get all of the activity that will be saved to confirm with the user. If there's no activity, ask if they 
       still want to save the task/event when there's no new activity. */
   public Boolean checkForActivityToConfirm() {
      activityToConfirm = new List<ReferenceHrgActivityWrapper>();
      // to make sure everything is okay
      activityToSaveMap.clear();
    
      // add all open activity to the map
      if (openActivityByKeyMap != null) {
         for (String key : openActivityByKeyMap.keySet()) {
            // reset the activity - in case went backwards and forwards
            ActivityWrapper aw = openActivityByKeyMap.get(key);
            aw.resetActivity();
            activityToSaveMap.put(key,aw);
         }
      } // if (openActivityByKeyMap
    
      allOkay = true;

      // reference object never saved, or changes made to it, or account health change not saved
      refHrgChanged = (refHRG.Id == null || isTheRefHrgUpdated(refHRG) || (acctHealthActivity != null && acctHealthActivity.Id == null));
    
      checkList(activityToConfirm,onboardingActivityList);
      checkList(activityToConfirm,onboardingConcernsList);
      checkList(activityToConfirm,onboardingSetupList);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkForActivityToConfirm ongoingActivityList='+ongoingActivityList.size()));
      checkList(activityToConfirm,ongoingActivityList);
      checkList(activityToConfirm,pendingHrgActivityList);
      
      // make sure something is logged
      //if (activityList.length() > 0) {
      //   activityList = 'HRG Activity logged on '+Date.today().format()+':'+activityList;
      //}
      //if (allOkay && !activityToConfirm.isEmpty())
      if (allOkay && !activityToSaveMap.isEmpty()) {
         setupActivityToSave();
      }

      //selectedActivity.addToDescription(activityList);
      return allOkay;
   } // getActivityToConfirm

   public Boolean checkRefHRGOwnership(Reference_HRG__c refHRG) {
      Boolean changed = false;
      // look to see if the users exist on the account team.
      Id hrgUserId = null;
      Id hrsSalesRepId = null;
      if (acct.AccountTeamMembers != null && !acct.AccountTeamMembers.isEmpty()) {
         for (AccountTeamMember atm : acct.AccountTeamMembers) {
            if (atm.TeamMemberRole == ZipCheckOwner.AT_401K) {
               hrsSalesRepId = atm.UserId;
            } else if (atm.TeamMemberRole == ZipCheckOwner.AT_HRG) {
               hrgUserId = atm.UserId;
            }
         } // for (AccountTeamMember
         
         // check that the HRG on the account is the record owner
         if (hrgUserId != null && hrgUserId != refHRG.OwnerId) {
            refHRG.OwnerId = hrgUserId;
            changed = true;
         } // if
         
         if (hrsSalesRepId != null && hrsSalesRepId != refHRG.HRS_Account_Owner__c) {
            refHRG.HRS_Account_Owner__c = hrsSalesRepId;
            changed = true;
         }
      } // if (acct.AccountTeamMembers
      
    return changed;
   } // checkRefHRGOwnership
   
   public void setupActivityToSave() {
      // setup into a sorted list
      List<String> sortedKeys = new List<String>();
      sortedKeys.addAll(activityToSaveMap.keySet());
      sortedKeys.sort();
    
      activityToSaveList = new List<ActivityWrapper>();
      for (Integer cnt=sortedKeys.size()-1; cnt>=0; cnt--) {
         String key = sortedKeys[cnt];
      //}
      //for (String key : sortedKeys) {
         ActivityWrapper aw = activityToSaveMap.get(key);
         // build the activity description
         //String activityDescription = 'HRG Activity logged on '+Date.today().format()+': ';
        
         // log any new activity
         Boolean hasExisting = false;
         String activityDescription = '';
         String activityHRGActivityType = '';
         Boolean typeHasChanged;
         Boolean notesHaveChanged;
         if (aw.hasHrgActivity) {
            for (ReferenceHRGActivityWrapper haw : aw.hrgActivity) {
            	typeHasChanged = false;
         		notesHaveChanged = false;
         	
         		if(haw.originalType != haw.activity.Type__c){
         			typeHasChanged = true;
         		}
         		if (haw.originalNotesSize != haw.getNotesSize()){ 
         			notesHaveChanged = true;
         			//haw.originalNotesSize = haw.getNotesSize();
         		}
  
				if (haw.activity.Id == null){
            		activityDescription += '\n'+haw.activity.Type__c+': '+haw.label + (!String.isBlank(haw.activity.Notes__c) ? '\nNotes: ' + haw.activity.Notes__c : '')+'\n';
                  	activityHRGActivityType += haw.activity.Type__c +': ' + haw.activity.Activity__c +'\n'; 
                } else {
               		if(typeHasChanged && !notesHaveChanged){
               			activityDescription += '\n'+haw.activity.Type__c+': '+haw.label+ '\nType has changed from ' +haw.originalType+ ' to ' +haw.activity.Type__c +'\n'; 
               		}//end type change 	
               		else if (typeHasChanged && notesHaveChanged){
               			activityDescription += '\n'+haw.activity.Type__c+': '+haw.label+ '\nType has changed from ' +haw.originalType+ ' to ' +haw.activity.Type__c; 
               			activityDescription += '\nNotes have been added: '+ haw.activity.Notes__c+'\n';
               		}//end both changed
               		else if (!typeHasChanged && notesHaveChanged){
               			activityDescription += '\n'+haw.activity.Type__c+': '+haw.label+'\nNotes have been added: '+ haw.activity.Notes__c +'\n';
               		}  //end notes have changed
                  hasExisting = true;
               }//end else
            } // for
         } // if (aw.hasHrgActivity
          
         // make sure there's something new
         if (!String.isBlank(activityDescription)) {
         	//if the HRG activity is updated - LM
         	if(hasExisting && (typeHasChanged || notesHaveChanged)){
         		activityDescription = '\n'+'HRG Activity updated on '+Date.today().format()+': '+activityDescription;
         	}
            else{
            	activityDescription = '\n'+'HRG Activity '+(hasExisting ? 'added' : 'logged')+' on '+Date.today().format()+': '+activityDescription;
            }
         } // 
         // make sure there's something new
         if (!String.isBlank(activityHRGActivityType)) {
            activityHRGActivityType = '\n' + activityHRGActivityType;
         } // 
         aw.addToHRGActivityType(activityHRGActivityType);        
         aw.addToDescription(activityDescription);
         activityToSaveList.add(aw);
      } // for
   } // setupActivityToSave
   
   public List<ActivityWrapper> activityToSaveList{get;set;}
   
   private Map<String,ActivityWrapper> activityToSaveMap = new Map<String,ActivityWrapper>();
   
   /** Is there activity to save? */
   public Boolean hasActivityToSave{
      get {return (activityToSaveMap != null && !activityToSaveMap.isEmpty()); }
   } // hasActivityToSave
   
   // used to create a new dateTime from the activity date so we can format the output of the date. 
   private Time TEMP_TIME = Time.newInstance(9, 0, 0, 0);
   
   public static String ACTIVITY_SOURCE='ReferenceHRGController';
   public static String ACTIVITY_SOURCE_MOBILE='MobileHRGController';
   
   /** Check each record in the list for any changes. */   
   private void checkList(List<ReferenceHrgActivityWrapper> activityToConfirm, List<ReferenceHrgActivityWrapper> checkList) {
      
      for (ReferenceHrgActivityWrapper haw : checkList) {
        //System.debug('checkList recId='+haw.recId+' haw.activity.Type__c='+haw.activity.Type__c+' haw.activity.Activity__c='+haw.activity.Activity__c);
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkList recId='+haw.recId+' haw.activity.Type__c='+haw.activity.Type__c+' haw.activity.Activity__c='+haw.activity.Activity__c+' hasChangesToSave='+haw.hasChangesToSave()));
        // the type field will be the key for if we're logging activity
        //if (!String.isBlank(haw.activity.Type__c)) {
        // are there any changes to save?
        if (haw.hasChangesToSave()) {
            Boolean thisOkay = true;
            // make sure required fields have values
            if (haw.activity.Activity_Date__c == null) {
               haw.activity.Activity_Date__c.addError('Date Must Be Selected!');
               thisOkay = false;
            }
            if (String.isBlank(haw.activity.Activity__c)) {
               haw.activity.Activity__c.addError('Must Select an Activity!');
               thisOkay = false;
            }
            if (String.isBlank(haw.activity.Type__c)) {
               haw.activity.Type__c.addError('Must Select a Type!');
               thisOkay = false;
            }
            if(String.isBlank(haw.activity.Onsite_Meeting_Attendees__c) && (haw.activity.Type__c == 'Onsite-One Way' || haw.activity.Type__c == 'Onsite-Two Way')) {
                haw.activity.Onsite_Meeting_Attendees__c.addError('Onsite Meeting Attendees cannot be blank!');
                thisOkay = false;
            }
      
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkList recId='+haw.recId+' haw.activity.Type__c='+haw.activity.Type__c+' haw.activity.Activity__c='+haw.activity.Activity__c+' thisOkay='+thisOkay));
            if (thisOkay) {
               activityToConfirm.add(haw);
               // used so we can format the output
               DateTime activityDateTime = DateTime.newInstance(haw.activity.Activity_Date__c, TEMP_TIME);
               String key = activityDateTime.format('yyyyMMDD')+(haw.isEvent ? 'Event' : 'Task');
               //String key = (haw.isEvent ? 'Event' : 'Task')+haw.activity.Activity_Date__c;
               ActivityWrapper aw = activityToSaveMap.get(key);
               // see if there is open activity that we can add this to
               //if (aw == null) {
               //   aw = openActivityByKeyMap.get(key);
               //   if (aw != null) {
               //      activityToSaveMap.put(key,aw);
               //   }
               //} // if (aw == null
               
               if (aw == null) {
                  aw = new ActivityWrapper();
                  String subject = acct.Name+'-HRG '+(haw.isEvent ? 'Event' : 'Task')+' Activity';
                  Date dateActivityCompleted = (haw.activity.Activity_Date__c <= Date.today() ? haw.activity.Activity_Date__c : null);
                  if (haw.isEvent) {
                     Schema.RecordTypeInfo eventRT = RecordTypeHelper.getRecordType(RT_EVENT,'Event');
                     Event thisEvent = new Event(WhatId = acct.Id
                                       ,Subject=subject
                                       ,Type=haw.activity.Type__c
                                       ,Date_Activity_Completed__c=dateActivityCompleted
                                       ,ActivityDate=activityDateTime.date(), ActivityDateTime=activityDateTime, DurationInMinutes=60
                                       ,Activity_Source__c=(comingFromMobile?ACTIVITY_SOURCE_MOBILE:ACTIVITY_SOURCE)
                                       ,RecordTypeId=eventRT.getRecordTypeId());
                     aw.setEvent(thisEvent);
                  } else {
                     Schema.RecordTypeInfo taskRT = RecordTypeHelper.getRecordType(RT_TASK,'Task');
                     // default the task to not started
                     Task thisTask = new Task(WhatId = acct.Id
                                 ,Subject=subject
                                 ,Type=haw.activity.Type__c
                                 ,Date_Activity_Completed__c=dateActivityCompleted
                                 ,ActivityDate=haw.activity.Activity_Date__c
                                 ,Activity_Source__c=(comingFromMobile?ACTIVITY_SOURCE_MOBILE:ACTIVITY_SOURCE)
                                 ,RecordTypeId=taskRT.getRecordTypeId(), Status='Not Started');
                     aw.setTask(thisTask);
                  }
                  aw.key = key;
                  activityToSaveMap.put(key,aw);
			} // if (aw == null
               aw.addHRGActivity(haw);
              
            } else {
               allOkay = false;
            }
        } // if (!String.isBlank   
      } // for
   } // checkList
   
   
   /** Are we staying on the Reference HRG page after the save, or returning to the client? */
   public Boolean saveAndNewActivity{get;set;}
      
   public PageReference saveAndNewActivity() {
      saveAndNewActivity = true;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveAndNewActivity saveAndNewActivity='+saveAndNewActivity));
      return performSave();
   } // quickSave
   
   public PageReference saveAndReturnToAcct() {
      saveAndNewActivity = false;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveAndReturnToAcct saveAndNewActivity='+saveAndNewActivity));
      return performSave();
   } // save
   
   // keep track of the closed activity that is saved
   private List<ActivityWrapper> closedActivity;
   
   private static Boolean savePerformed = false;
   
   //public Boolean savePerformed{get;private set;}
   
   /** perform the save routine.
    */
   public PageReference performSave() {
   	system.debug('PerformSave ' +savePerformed);
       if (!savePerformed) {
         savePerformed = true;

    closedActivity = new List<ActivityWrapper>(); 
    system.debug ('activityToSaveList '+activityToSaveList);
      if (executeSave(activityToSaveList)) {

         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'performSave executeSave is successful'));
        // if there's closed activity and we're logging against more than one account record - go to the next screen to
        // ask what they want to log against.
        if (!closedActivity.isEmpty() && !String.isBlank(logActivitySelection) && logActivitySelection != LOG_THIS ) {
            //setupExtraAccountsList();
            setUserId();
        } else {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'performSave going to finish save'));
            return finishSave();
        }
      } else {
         savePerformed = false;
      } // if (executeSave
      }
      return null;
   } // performSave
   
   public PageReference finishSave() {
      if (comingFromMobile) {               
          return null;              
      }
      if (saveAndNewActivity) {
         // reenter the form
         setAccount(acctId);
         checkForActivityToConfirm();
      } else {
         // return to the original record
         return cancel();
      }
      return null;
   } // finishSave


   /** Save all of the data.
       Check the tasks/events. 
          If date activity completed filled out, complete the HRG activity.
          If meeting not held selected, delete (or don't insert) the HRG activity.
          If neither, save the activity and leave open. Do not update the reference object with this activity.
       Save the tasks/events
       Save the reference object if changed.
       Save the HRG activity.
    */
   private Boolean executeSave(List<ActivityWrapper> p_activityToSaveList) {
    
      Boolean okay = true;
      // if we need to delete activity  
      ReferenceHRGActivity__c[] hrgActivityToDelete = new ReferenceHRGActivity__c[]{};
      // the activity we are saving
      ReferenceHRGActivity__c[] hrgActivityToSave = new ReferenceHRGActivity__c[]{};
      
      // The tasks to save. 
      List<Task> tasksToSave = new List<Task>();
      List<Task> tasksToDelete = new List<Task>();
      
      // The events to save. 
      List<Event> eventsToSave = new List<Event>();
      List<Event> eventsToDelete = new List<Event>();
   
      // if there's no id we'll start off with it changed.
      Boolean refHRGChanged = (refHRG.Id == null);
      
      Boolean refHRGIsNew = refHRGChanged;
      
      if (checkRefHRGOwnership(refHRG)) {
         refHRGChanged = true;
      }

      if (refHRGIsNew) {
        // save it to get the id if new
         insert refHRG;
         refHRGChanged = false;
      }
      
      /*
      if (refHRG.Onboarding_Start_Date__c == null) {
         refHRG.Onboarding_Start_Date__c = refHRG.DateofLastVisit__c;
         refHRGChanged = true;
      }
      */
            
      if (p_activityToSaveList != null) {
         // go through all of the activity and see what needs to be done
         for (ActivityWrapper aw : p_activityToSaveList) {
            // make sure there is hrg activity to save
            if (aw.hasHrgActivity) {
               if (aw.activityIsComplete && !aw.clientSummaryFilled()) {
                   okay = aw.logClientSummaryError('Client Summary is required when the Activity is completed');
               } // if (aw.activityIsComplete
            
               if (aw.meetingNotHeld && !aw.reasonCancelledFilled()) {
                  okay = aw.logReasonCanceledError('Must have a Reason Cancelled if Meeting Not Held');
               }
            
               if (okay) {
                  aw.setWhoId();

                  if (aw.isEvent) {
                     // in case the activity date changes - make sure the datetime matches.
                     //aw.evnt.ActivityDateTime = DateTime.newInstance(aw.evnt.ActivityDate, TEMP_TIME);
                     aw.setActivityDateTime();
                     aw.evnt.DurationInMinutes = 60;        // cmf
                     eventsToSave.add(aw.evnt);
                  } else if (aw.isTask) {
                     // if the date activity completed is filled out, complete the task.
                     if (aw.tsk.Date_Activity_Completed__c != null || aw.tsk.Meeting_Not_Held__c) {
                        aw.tsk.Status = 'Completed';
                     }
                     tasksToSave.add(aw.tsk);
                  } // if (aw.isEvent
               } // if (okay
            } else {
               if (aw.isEvent && aw.evnt.Id != null && aw.evnt.Activity_Source__c==ACTIVITY_SOURCE) {
                  eventsToDelete.add(aw.evnt);
               } else if (aw.isTask && aw.tsk.Id != null && aw.tsk.Activity_Source__c==ACTIVITY_SOURCE) {
                  tasksToDelete.add(aw.tsk);
               }
            } // if (aw.hasHrgActivity
         
         } // for (ActivityWrapper aw
      } // if (p_activityToSaveList != null)

      // save the activities if all okay
      if (okay) {
         if (!eventsToSave.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(eventsToSave,false);
            if (!checkUpsertResults(results, eventsToSave)) {
               okay = false;
            }
         } // if
        
         if (okay && !tasksToSave.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(tasksToSave,false);
            if (!checkUpsertResults(results, tasksToSave)) {
               okay = false;
            }
         } // if (okay && !tasksToSave.isEmpty
         
         if (okay && !eventsToDelete.isEmpty()) {
            Database.DeleteResult[] results = Database.delete(eventsToDelete,false);
            // todo - do we care if a delete fails?
         }
         if (okay && !tasksToDelete.isEmpty()) {
            Database.DeleteResult[] results = Database.delete(tasksToDelete,false);
            // todo - do we care if a delete fails?
         }
      } // if (okay
      
      if (okay && (p_activityToSaveList != null)) {
         for (ActivityWrapper aw : p_activityToSaveList) {
            Id activityId = aw.activityId;
            Boolean meetingNotHeld = aw.meetingNotHeld;
            Boolean activityIsComplete = aw.activityIsComplete;
            Date activityDate = (aw.isEvent ? aw.evnt.ActivityDate : (aw.isTask ? aw.tsk.ActivityDate : Date.today()));
            
            // add completed activity in case we need to add to more records
            if (activityIsComplete) {
                closedActivity.add(aw);
            }
            
            if (aw.hasHrgActivity) {
               for (ReferenceHRGActivityWrapper haw : aw.hrgActivity) {
                 haw.verifyFields();
                   if (meetingNotHeld) {
                      // delete activity that has been previously saved
                      if (haw.activity.id != null) {
                         hrgActivityToDelete.add(haw.activity);
                      }
                   } else {
                      // make sure the activity id is set
                      haw.activity.ActivityId__c = activityId;
                      haw.activity.TaskOrEvent__c = aw.taskOrEvent;
                      
                      if (haw.activity.Account__c == null) {
                        haw.activity.Account__c = acct.Id;
                      }
                      if (haw.activity.Reference_HRG__c == null) {
                        haw.activity.Reference_HRG__c = refHRG.Id;
                      }
                      // make sure the date matches the task/event. This should only be needed if updating open activity
                      haw.activity.Activity_Date__c = activityDate;
                   
                      if (activityIsComplete) {
                       haw.activity.Complete_Date__c = haw.activity.Activity_Date__c;
                       haw.activity.Closed__c = true;
                       haw.completed = true;
                    
                       // only update the onboarding activity when closed and not already closed
                        if (haw.isOnboarding) {
                           // see if the reference object is updated because of this activity. It may not update if they are only logging activity with no new notes.
                           if (haw.updateRefHrg(refHRG)) {
                              refHRGChanged = true;
                           }
                        } // if (haw.isOnboarding
                      } // if (activityIsComplete
                   
                     hrgActivityToSave.add(haw.activity);
                   } // if (meetingNotHeld
                
               } // for (ReferenceHRGActivityWrapper hag
            } // if (aw.hasHrgActivity
         } // for (ActivityWrapper
         
      } // if (okay
      
      // update the reference object with any changes.
      if (okay && isTheRefHrgUpdated(/*activityToConfirm,*/ refHRG)) {
         refHRGChanged = true;
      }
      // check if the onboarding is now complete
      if (okay && checkOnboardingDates(refHRG, refHRGIsNew, onboardingDateFieldNames)) {
         refHRGChanged = true;
      }
      if (okay && refHRGChanged) {
        // todo - verify successful!
         update refHRG;
      }
      
      if (okay && !hrgActivityToSave.isEmpty()) {   
         upsert hrgActivityToSave;
      }
      
      if (okay && !hrgActivityToDelete.isEmpty()) {
         delete hrgActivityToDelete;
      }

      // in case the reference HRG object didn't already exist - save the account health change activity when it does exist. 
      checkSaveAcctHealthActivity();

      return okay;
   } // executeSave
   
   public Boolean checkUpsertResults(Database.UpsertResult[] results, SObject[] recs) {
      Boolean allOkay = true;
      for (Integer cnt=0; cnt<results.size(); cnt++) {
         Database.UpsertResult result = results[cnt];
         if (!result.isSuccess()) {
            String errorStr = '';
            for (Database.Error err : result.getErrors()) {
               errorStr += err.getMessage();
            }
            recs[cnt].addError(errorStr);
            allOkay = false;
         }
      } // for (Integer cnt=0
      return allOkay;
   } // checkUpsertResults
   
   /** See if any of the activity to save is directly against the reference object. A true is returned if the refHRG object was updated.
    */
   public Boolean isTheRefHrgUpdated(/*List<ReferenceHrgActivityWrapper> activityToConfirm,*/ Reference_HRG__c refHRG) {
      Boolean changed = false;
      
      // check the sales rep field
      changed = valueChanged(productOriginalValues.get('Sales_Rep_Attended_CC_Meeting__c'), refHRG.Sales_Rep_Attended_CC_Meeting__c);
      
      /*
      for (ReferenceHrgActivityWrapper haw : activityToConfirm) {
        if (haw.isOnboarding) {
            // see if the reference object is updated because of this activity. It may not update if they are only logging activity with no new notes.
           if (haw.updateRefHrg(refHRG)) {
              changed = true;
              break;
           }
           
        } // if (haw.isOnboarding
      } // for (ReferenceHrgActivityWrapper
      */
      // check the product fields if no onboarding changes 
      if (!changed) {
         for (Schema.FieldSetMember f : getProductFields()) {
            if (valueChanged(productOriginalValues.get(f.getFieldPath()),(String)refHRG.get(f.getFieldPath()))) {
               changed = true;
               break;
            }
            /*
            String originalValue = productOriginalValues.get(f.getFieldPath());
            originalValue = (String.isBlank(originalValue) ? 'NULL' : originalValue);
            String curValue = (String)refHRG.get(f.getFieldPath());
            curValue = (String.isBlank(curValue) ? 'NULL' : curValue);
            if (originalValue != curValue) {
               changed = true;
               break;
            }
            */
         } // for
        
      }
      return changed;
   } // isTheRefHrgUpdated
   
   /** Did the value change? */
   public Boolean valueChanged(String p_originalValue, String p_curValue) {
      String originalValue = (String.isBlank(p_originalValue) ? 'NULL' : p_originalValue);
      String curValue = (String.isBlank(p_curValue) ? 'NULL' : p_curValue);
      return (originalValue != curValue);
   } // valueChanged
   
   /** Check the onboarding start and end dates. If not already populated - see if it can be populated because all of the activities are complete.
    */
   public Boolean checkOnboardingDates(Reference_HRG__c refHRG, Boolean refHRGIsNew, List<String> onboardingDateFieldNames) {
       
      //Update onboardingCompleteDates set
      getCompleteDateFields();
      //date after which PEO Handbook needs to be included in check
      Date handbookDate = Date.newInstance(2018, 10, 15);
      // if daysBetween is negative then onboarding start date is after the handbook date
	  Boolean includeHandbook = (refHRG.Onboarding_Start_Date__c != null && refHRG.Onboarding_Start_Date__c.daysBetween(handbookDate) < 0 ? true : false);      	  
      Boolean dateChanged = false;  
       
      if (refHRG.Onboarding_End_Date__c == null) {
         Date maxDate = null;
         Date minDate = null;
         // only need to loop through the process until 1 date field is not populated.
         Boolean allComplete = true;
         for (String fieldName : onboardingDateFieldNames) 
         {
             if(onboardingCompleteDates.contains(fieldName))
             {	 // only check Handbook field if is PEO account type
	             if (acctType == 'PEO Client' && fieldName == 'PEO_Handbook__c' && includeHandbook && refHRG.get(fieldName) == null) {
                     allComplete = false;
                     // if not new don't need to finish - if it's new we need to find a start date
                     if (!refHRGIsNew) {
                         break;
                     }
                 } else if (refHRG.get(fieldName) == null) {     // && fieldName != 'PEO_New_Client_Meeting__c'
                     allComplete = false;
                     // if not new don't need to finish - if it's new we need to find a start date
                     if (!refHRGIsNew) {
                         break;
                     }
                 } else {
                     Date checkDate = (Date)refHRG.get(fieldName);
                     if (maxDate == null || maxDate < checkDate) {
                         maxDate = checkDate;
                     }
                     if (minDate == null || minDate > checkDate) {
                         minDate = checkDate;
                     }
                 } // else
             }
         } // for (String fieldName

         if (refHRGIsNew && minDate != null && refHRG.Onboarding_Start_Date__c == null) {
            refHRG.Onboarding_Start_Date__c = minDate;
            dateChanged = true;
         }
         if (allComplete) {
            refHRG.Onboarding_End_Date__c = maxDate;
            dateChanged = true;
         }
      } // if (refHRG.Onboarding_End_Date__c
      return dateChanged;
   } // checkOnboardingDates

   public String oldAcctHealthValue{get;set;}
      
   public ReferenceHRGActivity__c acctHealthActivity{get;set;}
   
   public static final String STEP_ACCOUNT_HEALTH='Account Health';
   
   public static String HEALTH_CHANGE = 'Account Health Change';
   /** Change the mode to set the account health.
    */
   public void changeAccountHealth() {
      currentStep = STEP_ACCOUNT_HEALTH;
      selectAcct();
      oldAcctHealthValue = acct.Premier_Account_Health__c;

      acctHealthActivity = new ReferenceHRGActivity__c(Activity_Type__c = HEALTH_CHANGE, Account__c=acct.Id, Assigned_to__c=curUser.Id);
   } // changeAccountHealth
   
   /** Save the account health changes and return back to the main record. */
   public void setAccountHealth() {
    
      // see if the value changed
      if (acct.Premier_Account_Health__c != oldAcctHealthValue) {
         // a comment must be entered to continue!
         if (String.isBlank(acctHealthActivity.Notes__c)) {
            acctHealthActivity.Notes__c.addError('A Reason for Change must be entered!');
            return;
         }
         else if(acctHealthActivity.Notes__c.length() > 254){
            acctHealthActivity.Notes__c.addError('Reason for Change cannot exceed 255 characters! You have used ' + acctHealthActivity.Notes__c.length() + '.');
            return;  
         }

         acctHealthActivity.Activity__c = healthValue(oldAcctHealthValue)+' to '+healthValue(acct.Premier_Account_Health__c);
         acctHealthActivity.Activity_Date__c = Date.today();
         acctHealthActivity.First_Activity_Date__c = Date.today();
         acctHealthActivity.Complete_Date__c = Date.today();
         acctHealthActivity.Closed__c = true;

         // update the account
         update acct;
         // reselect the account - to recalc the formula field
         selectAcct();

         // save the activity - always save even if no change?
         checkSaveAcctHealthActivity();

      } // if (acct.Premier_Account_Health__c != oldAcctHealthValue

      setWhatDidYouDoStep();
      
   } // setAccountHealth
   
   
   public void selectAcct() {
      // reselect the account - to recalc the formula field
      acct = [Select Id, Name, AccountNumber, Bis_ID__C, Type
                    ,Premier__c, Premier_Account_Health__c, HR_Solutions_Account_Health_Updated__c
                from Account
               Where Id = :acct.Id];
   } // selectAcct
   
   public void checkSaveAcctHealthActivity() {
      if (acctHealthActivity != null && acctHealthActivity.Id == null && refHRG != null && refHRG.Id != null) {
         acctHealthActivity.Reference_HRG__c = refHRG.Id;
         insert acctHealthActivity;
         acctHealthActivity = null;
      }
   } // checkSaveAcctHealthActivity
   
   private String healthValue(String checkValue) {
      return (String.isBlank(checkValue) ? 'None' : checkValue);
   } // healthValue
   
   public Integer recIdCounter{get;private set;}

   public Boolean selectAllOption{get;set;}
   
   //select all clients per page
  public void changeSelectAllOption() {
      for (AcctWrapper aw : extraAcctsList) {
         aw.selected = selectAllOption;
      }
     system.debug('changeSelectAllOption ' +extraAcctsList.size());
   } // changeSelectAllOption
   
   
   
  
  //select ALL clients button
   public pageReference selectAllClients() {
   	system.debug ('selectAllClients IN');
	//loop through all of the records and put the ids in a set
   	// make sure we start at the beginning
   	extraAccountsSet.first();
   	Boolean firstLoop = true;
   	do {
   	   if (!firstLoop) {
   	      extraAccountsSet.next();
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'selectAllClients not the first loop using next()'));
   	   }
         firstLoop = false;
   	   Account[] accts = (List<Account>) extraAccountsSet.getRecords();
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'selectAllClients accts='+accts.size()+' extraAcctSelectedSet='+extraAcctSelectedSet.size()));
            for(Account a : accts)
            {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'selectAllClients adding accountid='+a.id));
                extraAcctSelectedSet.add(a.id);
            }
   	      
   	} while (extraAccountsSet.getHasNext());
   	
   	//save function used when "Save Additional Activity" button is clicked
   	return saveAdditionalActivity2();
	} // end selectAllClients
   
   
   //this holds the account list PER PAGE
   public List<AcctWrapper> extraAcctsList{	//get;set;}
   	 get {
         if (extraAcctsList == null && extraAccountsSet != null) {
            extraAcctsList = new List<AcctWrapper>();
            List<Account> recs = (List<Account>) extraAccountsSet.getRecords();
            for (Account rec : recs) {
               AcctWrapper aw = new AcctWrapper(rec);
               extraAcctsList.add(aw);
            } // for
			System.debug('**CMF ** here at get extraAcctsList, extraAcctsList size='+extraAcctsList.size());            
			recheckExtraSelected(extraAcctsList);
         } // if (AcctWrapper == null
         return extraAcctsList;
      } // get
      private set;
   }
      
public Set<id> returnAcctsWithProducts = new Set<id>();
public String areaManager {get;set;}   
   /** If we're logging the related activity against more than one account, select the accounts to log against.
    */
   public Boolean setupExtraAccountsList() {
    Boolean okay = true;
    currentStep = 'Additional Logging';
    
    extraAcctsList = new List<AcctWrapper>(); 
    
   Account[] accts = null;
    String query = null;
      if (!String.isBlank(logActivitySelection) && logActivitySelection == LOG_CONTROLLED) {
         accts = getControlledOwnershipAccountsForList(); //***LM
      } else if (!String.isBlank(logActivitySelection) && logActivitySelection == LOG_CLIENTS) {
         accts = getAccountTeamAccountsForList(UserIdToUseForClientList); //LM query for the specified selection
      }//end else if LOG_CLIENTS
      
    // collect a set of accounts to remove from the query
     if(!accts.isEmpty()){
     	system.debug('LM accts count '+accts.size());  
     	for (Account acct : accts) {
         // make sure there is at least 1 active premier product.
        if (findPremierAsset(acct) != null) {
           returnAcctsWithProducts.add(acct.id);      
        }
      } // for (Account acct 
     }//end if
      system.debug('LM returnAcctsWithProducts count '+returnAcctsWithProducts.size());   
          
      //create new query with new account set
      query = 'SELECT Id, Name, ParentId, Parent.Name, AccountNumber, HR_Manager__r.name FROM Account ';
      query += 'WHERE Id IN :returnAcctsWithProducts' ;
      query += ' ORDER BY HR_Manager__r.name, Name ';
 
      setExtraAccountsSetController(query);

      return okay;
   } // setupExtraAccountsList
   
   //full query used AFTER accounts have been selected
   public Account[] getAcctQuery() {
    String query = 'Select Id, Name,ParentId,Parent.Name, AccountNumber ';
    query += ',(Select ';
    query += buildQueryWithFieldset(TYPE_ONBOARDING,getOnboardingFields(),null,false);
      query += buildQueryWithFieldset(TYPE_ONBOARDING_CONCERNS,getClientConcernFields(),null,false);
      query += buildQueryWithFieldset(TYPE_ONBOARDING_ISSUES,getSetupIssueFields(),null,false);
      query += ' Id, Name, Account__c,Onboarding_End_Date__c, Onboarding_Start_Date__c from Reference_HRG__r order by createdDate desc limit 1) ';
      query += ',(Select Id, Product_Plan_Code__c,Start_Date__c From Assets where Plan_Cancel_Date__c=null order by Start_Date__c asc)';
      query += ' From Account ';
      query += 'WHERE Id IN: extraAcctSelectedSet';
      
      Account[] accts = (Account[])Database.query(query);
      return accts;
   }


   //query to get accounts for Controlled Ownership
   //LM changed to return a list
   	public List<Account> getControlledOwnershipAccountsForList() {
 		system.debug('getControlledOwnershipAccountsForList');           
      //simple query to return accounts for selection
      //String query = 'Select Id, Name, ParentId,Parent.Name, AccountNumber, ';
      String query = 'Select Id, ParentId, ';
      query += '(SELECT Id, Product_Plan_Code__c,Start_Date__c, Plan_Cancel_Date__c FROM Assets WHERE Plan_Cancel_Date__c = null)';
      query += ' From Account ';
      query += 'Where (ParentId = \''+acct.Id+'\'';
      if (acct.ParentId != null) {
         query += ' or (ParentId != null and ParentId = \''+acct.ParentId+'\') ';
         query += ' or Id = \''+acct.ParentId+'\' ';
      }
      query += ') and Id != \''+acct.Id+'\' '; 
      query += ' order by Name';
      
      Account[] accts = (Account[])Database.query(query);
      return accts;
          
   } // getControlledOwnershipAccounts
   
   
   //query to get Accounts where user is on the Prospect-Client Team as an HRG or HRM
   //LM changed to return a list
   public List<Account> getAccountTeamAccountsForList(Id uId) {
  		system.debug('getAccountTeamAccountsForList');
      	//simple query to return accounts for selection
      	//List<Account> accounts = [SELECT Id, Name, ParentId, AccountNumber,
      	List<Account> accounts = [SELECT Id, 
                (SELECT Id, Product_Plan_Code__c,Start_Date__c FROM Assets WHERE Plan_Cancel_Date__c = null)
                FROM Account
                WHERE Id IN (Select AccountId
                             From AccountTeamMember
                             Where ((TeamMemberRole = :ZipCheckOwner.AT_HRG)
                             or (TeamMemberRole = :ZipCheckOwner.AT_HRM))
                              and UserId = :uId)
                AND Id !=: acctId
                ORDER BY Name];	
       system.debug('***BWV***: ' + accounts);
     return accounts;
             
   } // getAccountTeamAccounts
  
  public ApexPages.StandardSetController extraAccountsSet{get;set;}
  public Integer recsPerPage{get; set;}
  
   
  //extraAccounts is the query for all accounts
  public void setExtraAccountsSetController(String query) {
      extraAccountsSet = null;
      extraAcctsList = null;
      extraAccountsSet = new ApexPages.StandardSetController(Database.getQueryLocator(query));
	 	System.debug('**CMF ** here at setExtraAccountsSetController, query='+query); 
     	if (comingFromMobile)
     	{	recsPerPage = 2000;	}
  system.debug('setExtraAccountsSetController recsPerPage '+recsPerPage);
    extraAccountsSet.setPageSize(recsPerPage);    //sets how many records per page should be returned
   } // setExtraAccountsSetController
   
   /** Goto the next page of records. */
   public void next() {
      addExtraSelected(extraAcctsList);
      extraAcctsList = null;
      extraAccountsSet.next();
      selectAllOption = false;
   } // next

   /** Goto the previous page of records. */
   public void previous() { 
      addExtraSelected(extraAcctsList); 
      extraAcctsList = null;
      extraAccountsSet.previous(); 
      selectAllOption = false; 
   } // previous    

   /** Goto the next page of records. */
   public void firstPage() {
      addExtraSelected(extraAcctsList);
      extraAcctsList = null;
      extraAccountsSet.first();
      selectAllOption = false;
   } // next

   /** Goto the previous page of records. */
   public void lastPage() {
      addExtraSelected(extraAcctsList);  
      extraAcctsList = null;
      extraAccountsSet.last();
      selectAllOption = false;  
   } // previous 
   
   

   /** The total number of pages available. */
   public Integer numOfPages {
      get {
         if (numOfPages == null) {
            
            numOfPages = 1;
            if (extraAccountsSet != null) {
               decimal result = Decimal.valueOf(extraAccountsSet.getResultSize()) / Decimal.valueOf(extraAccountsSet.getPageSize());
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'numOfPages resultsize='+ownershipRecs.getResultSize()+' pageSize='+ownershipRecs.getPageSize()+' result='+result));
               numOfPages = (result.round(System.RoundingMode.CEILING)).intValue();
            }
         } // if (numOfPages
         return numOfPages;
      } // get
      private set;
   } // numOfPages
  
  public Set<Id> extraAcctSelectedSet = new Set<Id>();
  
  /* add-remove AcctWrappers to selected map */
  public void addExtraSelected(List<ReferenceHRGController.AcctWrapper> displayedAccts){
  	for (AcctWrapper aw : displayedAccts){	  
  		if (aw.selected && !extraAcctSelectedSet.contains(aw.acct.Id)) 
  		  {    
  			extraAcctSelectedSet.add(aw.acct.Id);	
			   System.debug('**CMF ** here at addExtraSelected adding to map '+aw.acct.Name);  	  	  	  
  	  	  }
  	  	   if (!aw.selected && extraAcctSelectedSet.contains(aw.acct.Id))
  	  	  {	   
  	  	  	extraAcctSelectedSet.remove(aw.acct.Id);		
			System.debug('**CMF ** here at addExtraSelected removing from map '+aw.acct.Name);  	  	  	  
  	  	  }
  	  } // for
  } // addExtraSelected
  
  /* recheck selected AcctWrapper when going between pages */
  public void recheckExtraSelected(List<ReferenceHRGController.AcctWrapper> displayedAccts){
		for (AcctWrapper aw : displayedAccts){
			if (extraAcctSelectedSet.contains(aw.acct.Id)){
				aw.selected = true;	  
				System.debug('**CMF ** here at recheckExtraSelected reselecting '+aw.acct.Name);  	  	  
  	  	  }
  	  }
  } // recheckExtraSelected
       
  
   public class AcctWrapper implements Comparable {
      public AcctWrapper(Account p_acct) {
         acct = p_acct;
         // default everything to selected?
         selected = false;
      } // AcctWrapper
      
      public Boolean selected{get;set;}
      public Account acct{get;set;}
      
      // is this a child account in a controlled hierarchy?
      public Boolean isChildAcct{
         get {return (acct != null && acct.ParentId != null);}
      }
      
      //Make it alphabetically sortable by Account Name
      public Integer compareTo(Object compareTo){
        AcctWrapper AcctWrapper = (AcctWrapper) compareTo;
        if (acct.Name == AcctWrapper.acct.Name) return 0;
        if (acct.Name > AcctWrapper.acct.Name) return 1;
        return -1;        
      }
   } // class AcctWrapper
   
   private static Boolean saveInProgress = false;
   
   public PageReference saveAdditionalActivity() {
		if (!saveInProgress) {
	        //one last check of display Accts to add-remove from selected Set
	         addExtraSelected(extraAcctsList);	   //populate extraAcctSelectedSet	
	         return saveAdditionalActivity2();
         }
        
      return null;
   } // saveAdditionalActivity
   
   //called straight from selectallclients to bypass the addExtraSelected()
   public PageReference saveAdditionalActivity2() {
		Boolean okay=true;
        saveInProgress = true;
         // make sure at least one additional was selected
        AcctWrapper[] selectedAccts = new AcctWrapper[]{};
        if (!extraAcctSelectedSet.isEmpty()){  //this can be populated from selectAllclients or addExtraSelected() in saveAdditionalActivity()
        	List<Account> selectedAccountsList = getAcctQuery();
        	for (Account acct : selectedAccountsList) {
               selectedAccts.add(new AcctWrapper(acct));
        	}
        }
system.debug('saveAdditionalActivity2 selectedAccts ' +selectedAccts);
        okay = processAdditionalActivity(selectedAccts);  
   		if (okay) {
            return finishSave();
         }
         saveInProgress = false;
    
      	return null;
   } // saveAdditionalActivity2
   
   public Boolean processAdditionalActivity(AcctWrapper[] selectedAccts) {  
      Boolean okay = true;
      // make sure reference object exists for each
      Reference_HRG__c[] upsertRefHRGs = new Reference_HRG__c[]{};
      Task[] newTasks = new Task[]{};
      Event[] newEvents = new Event[]{};
      
      // the records we are creating
      ActivityWrapper[] activityWraps = new ActivityWrapper[]{};
      
      for (AcctWrapper acctWrap : selectedAccts) {
         // check if the reference object exists
         Reference_HRG__c refHRG = (acctWrap.acct.Reference_HRG__r != null && !acctWrap.acct.Reference_HRG__r.isEmpty() ? acctWrap.acct.Reference_HRG__r[0] : null);
         refHrgChanged = false;
         Boolean refHRGIsNew = false;
         if (refHRG == null) {
            refHRG = new Reference_HRG__c(Account__c=acctWrap.acct.Id, Onboarding_Start_Date__c=findPlanStartDate(acctWrap.acct));
            refHrgChanged = true;
            refHRGIsNew = true;
         }
         // loop through the closed activity, creating all of the needed records
         system.debug('closedActivity ' +closedActivity);
         for (ActivityWrapper closedAw : closedActivity) {
            ActivityWrapper newAw = new ActivityWrapper();
            activityWraps.add(newAw);
            newAw.refHrg = refHRG;
            if (closedAw.isEvent) {
                Event newEvent = closedAw.evnt.clone(false,true);
                newEvent.Related_Activity__c = TRUE; // acctWrap.isChildAcct;
                newEvent.WhatId = acctWrap.acct.Id;
                newEvent.WhoId = null;
               newAw.setEvent(newEvent);
               newEvents.add(newEvent);
            } else {
                Task newTask = closedAw.tsk.clone(false,true);
               newTask.Related_Activity__c = TRUE; // acctWrap.isChildAcct;
                newTask.WhatId = acctWrap.acct.Id;
                newTask.WhoId = null;
                newAw.setTask(newTask);
                newTasks.add(newTask);
            }
            Boolean hasOnboardingActivity = false;
  system.debug('closedAw.hrgActivity' +closedAw.hrgActivity);
            // loop through the reference HRG activity and clone that
            if (closedAw.hasHrgActivity) {
               for (ReferenceHrgActivityWrapper closedHaw : closedAw.hrgActivity) {
                if (closedHaw.isOnboarding)
                {   hasOnboardingActivity = true;   }
                ReferenceHRGActivity__c refAct = closedHaw.activity.clone(false,true);
                refAct.Account__c = acctWrap.acct.Id;
                  ReferenceHrgActivityWrapper newHaw = new ReferenceHrgActivityWrapper(String.valueOf(recIdCounter++),refAct);
                  // setup fields so the reference object can be updated if onboarding activity
                  newHaw.completed = true;
                  newHaw.dateFieldName = closedHaw.dateFieldName;
                  newHaw.notesFieldName = closedHaw.notesFieldName;
                  newHaw.originalNotesSize = 0;
                  newHaw.activity.Related_Activity__c = TRUE; //LM added 3/29/2017
                  newAw.addHRGActivity(newHaw);
                  if (newHaw.updateRefHrg(refHRG)) {
                     refHrgChanged = true;
                  }
               } // for (ReferenceHrgActivityWrapper closedHaw
               if(hasOnboardingActivity && checkOnboardingDates(refHRG, refHRGIsNew, onboardingDateFieldNames)) {
                  refHRGChanged = true;
               }    
            } // if (closedAw.hasHrgActivit
            
         } // for (ActivityWrapper closedAw
         if (refHrgChanged) {
            upsertRefHRGs.add(refHRG);
         }
      } // for
      
      // save all of the data
      if (!upsertRefHRGs.isEmpty()) {
         upsert upsertRefHRGs;
      }
      
      if (!newTasks.isEmpty()) {
         insert newTasks;
      }
      
      if (!newEvents.isEmpty()) {
         insert newEvents;
      }
      
      // loop through again for the HRG activity objects
      ReferenceHRGActivity__c[] newRefAct = new ReferenceHRGActivity__c[]{};
      for (ActivityWrapper aw : activityWraps) {
         if (aw.hasHrgActivity) {
            for (ReferenceHRGActivityWrapper haw : aw.hrgActivity) {
               // make sure the activity id is set
               haw.activity.ActivityId__c = aw.activityId;
               haw.activity.Reference_HRG__c = aw.refHrg.Id;
               newRefAct.add(haw.activity);
            } // for (ReferenceHRGActivityWrapper haw
            
         } // if (aw.hasHrgActivity
      } // for (ActivityWrapper
      
      if (!newRefAct.isEmpty()) {
         insert newRefAct;
      }
      return okay;
   } // processAdditionalActivity
   
} // class ReferenceHRGController