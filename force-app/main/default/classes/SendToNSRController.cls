/* 
 * History
 * ---------
 * 07/05/2016 Cindy Freeman		created
   10/03/2015 Dan Carmen         Add check for null value
 * 
 */
public without sharing class SendToNSRController {
	private Id inputId{get; set;}
	public Boolean isLead{get; set;}
	public Boolean isAccount{get; set;}
	public Boolean isContact{get; set;}
	private User runningUser;
    
    public SObject objToSend{get; set;}
    public String objToSendName{get; set;}					// lead, account or contact Name
    public String objLabel{get; set;}
    public Boolean hasError{get; set;}
	public Boolean beingWorked{get; set;}					// true if record already being worked
	public String workingNSR{get; set;}						//  NSR working this record	
	public String workedMsg{get; set;}						// part of msg record is being worked
    public String addComment{get; set;}	
    public Boolean showCancel{get; set;}
    public Boolean showReassign{get; set;}
    public Boolean showReturn{get; set;}
    public integer maxLength{get;set;}
    
	/** Default constructor
    */
    public SendToNSRController() {
      runningUser = [Select Id, Name, Cost_Center__c, Sales_Org__c, Profile.Name, UserRole.Name from User where Id = :UserInfo.getUserId()];
      maxLength = 255-(runningUser.name.length()+20); 
      inputId = System.currentPageReference().getParameters().get('sfdcId');
      hasError = isLead = isAccount = isContact = false;
      showReassign = showReturn = false;
      showCancel = true;
        
      String prefix = (inputId != null ? String.valueOf(inputId).left(3) : '');
        
      if (String.isBlank(prefix) || (prefix != ObjectHelper.PREFIX_LEAD && prefix != ObjectHelper.PREFIX_ACCOUNT && prefix != ObjectHelper.PREFIX_CONTACT))
      {	  ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Invalid ID.  How did you get here? Id='+inputId));	}
      else
	  {   if (prefix == ObjectHelper.PREFIX_LEAD)
	      {		isLead = true;
          		objLabel = 'Lead: ';
          }
	      else if (prefix == ObjectHelper.PREFIX_ACCOUNT)
	      {		isAccount = true;
          		objLabel = 'Prospect-Client:  ';
          }
	      else if (prefix == ObjectHelper.PREFIX_CONTACT)
	      {		isContact = true;
          		objLabel = 'Contact:  ';
          }  
         System.debug('SendToNSRController isLead='+isLead+' isAccount='+isAccount+' isContact='+isContact);
	      checkBeingWorked(inputId);
          if (beingWorked)
          {		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, workedMsg+' is already being worked by '+ workingNSR));	}
	      else if (!hasError)
	      {		setupNSROptions();	}     
      }  //else      
      
    } // default constructor 

    	/*  look to see if this record is already being worked by an NSR	*/
	public void checkBeingWorked(Id p_inputId) {		
		//SObject objToSend = new SObject();
		workedMsg = '';
        beingWorked = false;
		// check Assigned To NSR fields
		if (isLead)						
		{	Lead[] tempLead = [Select Id, Name, OwnerId, Owner.Name, AssignedToNSR__c, LeadSource, Date_Sent_to_NSS__c, RecordTypeId
                               from Lead where Id = :p_inputId];
			for (Lead leed: tempLead)
			{	objToSend = leed;
             	objToSendName = leed.Name;
				if (leed.AssignedToNSR__c == true)
				{	beingWorked = true;	
					workedMsg = 'This lead';
					workingNSR = leed.owner.Name;                 
                 	break;
				}
            } // for			       
		} // if (isLead)
		else if (isAccount)			
		{	System.debug('checkBeingWorked isAccount');
		   Account[] tempAcct = [Select Id, Name, OwnerId, Owner.Name, AssignedToNSR__c, Lead_Source__c, Date_Sent_to_NSS__c, RecordTypeId,
                                  (Select Id, Name, Date_Sent_to_NSS__c, SignificantContact__c, AccountId, Account.Name, Owner.Name, Owner.Job_Name__c, RecordTypeId
                                   from Contacts 
                                   where SignificantContact__c = true or Sales_Contact__c = true)
                                  from Account where Id = :p_inputId];
         	// also need to pull in contacts to find significant
			for (Account acct: tempAcct)
			{	System.debug('checkBeingWorked nbr ctcts='+acct.Contacts.size()+' acct.AssignedToNSR__c='+acct.AssignedToNSR__c);
			   if (acct.AssignedToNSR__c)
				{	Prospect_Ownership__c[] poList = [select Id, Ownership_Status__c, NSR_Name__c, NSR_Name__r.Name, Decision_Maker__r.Name from Prospect_Ownership__c 
												where Prospect_Client__c = :p_inputId and EndDate__c = null order by StartDate__c ASC]; 
					for (Prospect_Ownership__c po: poList) 
                    {	//if (po.Ownership_Status__c == 'Prospecting') }
                        	beingWorked = true;
							workingNSR = po.NSR_Name__r.Name;
							workedMsg = 'The significant contact, '+po.Decision_Maker__r.Name;
							break;
						// } 
					} // for (Prospect_Ownership__c po				
				} // if (acct.AssignedToNSR__c)
                // else
                if (!acct.AssignedToNSR__c || (acct.AssignedToNSR__c && beingWorked == false))
                {	Boolean foundSignif = false;
                    for (Contact ctct: acct.Contacts)
                	{	if (ctct.SignificantContact__c == true)
                    	{	foundSignif = true;	
                         	objToSend = ctct;                         
                         	objToSendName = acct.Name + ' - ' + ctct.Name;                       
                         	objLabel = 'Significant Contact: ';
                         	if (ctct.Owner.Job_Name__c == Label.JobNSR)
                         	{	beingWorked = true;	
								workingNSR = ctct.owner.Name;
								workedMsg = 'The significant contact, ' + ctct.Name;
                         	}
                        	break;
                        } // if (ctct.Significant)
                    } // for (Contact ctct...
                 	if (!foundSignif)
                    {	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You must create a contact on this prospect-client before you can send it to an NSR.'));
                    	hasError = true;
                    } // if (!foundSignif}
                }  // else
			} // for
		} // else if (isAccount)
		else								
		{	Contact[] tempCtct = [Select Id, Name, OwnerId, Owner.Name, Account.Name, AccountId, AssignedToNSR__c, LeadSource, Date_Sent_to_NSS__c, Owner.Job_Name__c, RecordTypeId 
                                  from Contact where Id = :p_inputId];
			for (Contact ct:tempCtct)
			{	objToSend = ct;
             	objToSendName = ct.Name;
             	if (ct.Owner.Job_Name__c == Label.JobNSR)
                {	beingWorked = true;	
					workingNSR = ct.owner.Name;
					workedMsg = 'This contact';
                }
                else if (ct.AssignedToNSR__c)
				{	Prospect_Ownership__c[] poList = [Select Id, Ownership_Status__c, NSR_Name__c, NSR_Name__r.Name from Prospect_Ownership__c 
												where Prospect_Client__c = :ct.AccountId and EndDate__c = null order by StartDate__c ASC];
					for (Prospect_Ownership__c po: poList)
                    {	//if (po.Ownership_Status__c == 'Prospecting') {
                        	beingWorked = true;
							workingNSR = po.NSR_Name__r.Name;
							workedMsg = 'This contact';
							break;
						// } 
					} // for (Prospect_Ownership__c po
				} // if (ct.AssignedToNSR__c)
			} // for (Contact ct
		} // else
        //objToSendName = String.valueOf(objToSend.get('Name'));
		return;
		
	} // checkBeingWorked
	
	// picklist of active NSRs
	public list<SelectOption> nsrOptions{get; set;}
    // NSR selected from list
    public String selectedNSRId{get; set;}    
	 
	/*  create list of possible NSRs to send this to
	*/
	public void setupNSROptions() {
		showReassign = true;
        nsrOptions = new List<SelectOption>();
      
      // populate the set of profile names
      UserHelper.isNSSOutboundProf(null);
      
		User[] userList = [Select Id, Name, FirstName, LastName, isActive, Profile.Name, UserRole.Name from User
							where isActive = true and Job_Name__c = :UserHelper.JOB_NSR and Profile.Name in :UserHelper.profsNSSOutboundSet
							order by LastName, FirstName];
         for (User usr : userList) {
            nsrOptions.add(new SelectOption(String.valueOf(usr.Id), usr.LastName+', '+usr.FirstName));             
         } // for (User	
         selectedNSRId = null;
   		return;
   } // setupNSRPicklist
    
   /* user hit Cancel, not used anymore, using javascript to close window instead */
   public PageReference cancel() {                
        PageReference returnPr = new PageReference('/'+(inputId != null ? inputId : ''));
        return returnPr;                // go back to where you started
     } // cancel

   /* user hit reassign To NSR */
   public void reassignToNsr() {                
        //changesSaved = true;
        if (selectedNSRId == null || selectedNSRID.length()==0)
        {	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'You must select an NSR or hit Cancel'));	
            return;
        }                                
        if (isLead)
        {	leadSendToNSR();	}
        else
        {	contactSendToNSR();	}
        createObjTracker();
        createTask();
        String selectedNSR;
        for (SelectOption so: nsrOptions)
        {	if (selectedNSRId == so.getValue())
        	{	selectedNSR = so.getLabel();	}
        } // for
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'This record been transferred to '+ selectedNSR));
        showCancel = showReassign = false;
        showReturn = true;
        return;
     } // reassignToNSR
	
    /* update Lead to NSR */
    public void leadSendToNSR() {
        Lead leed = (Lead)objToSend;
        leed.ownerId = selectedNSRId;
        leed.Date_Sent_to_NSS__c = System.today();
        update leed;
    } // leadSendToNSR
    
    /* update Contact to NSR, set significant contact on account */
    public void contactSendToNSR() {
        Contact ctct  = (Contact)objToSend;
        ctct.ownerId = selectedNSRId;
        ctct.Date_Sent_to_NSS__c = System.today();        
        update ctct;        
        Account updAcct = new Account(id=ctct.AccountId, SignificantContact__c = ctct.Id, Date_Sent_to_NSS__c = System.today());
        update updAcct;
    } // contactSentToNSR
    
    /* create an object tracker record for each record that is transferred to NSR */
    public void createObjTracker() {
        List<ObjectTracker__c> objTrackerList = new List<ObjectTracker__c>();
        ObjectTracker__c ot = new ObjectTracker__c();             	
        ot.User__c = runningUser.Id;
        ot.Receiving_User__c = selectedNSRId;
        if (isLead)
        {	ot.Lead__c = objToSend.Id;
         	ot.Action__c = 'Lead Sent to NSS';
        } // if(isLead)
        else
        {	Contact tempCt = (Contact)objToSend;
            ot.Account__c = tempCt.AccountId;
        	ot.Contact__c = objToSend.Id;
        	ot.Action__c = 'Contact Sent to NSS';
        } // else
        objTrackerList.add(ot);
        
        insert objTrackerList;
    } // createObjTracker

    /* create task for each record that is transferred to NSR */
    public void createTask() {
        //Id rtId = RecordTypeHelper.getDefaultRecordType('Task').getRecordTypeId();
        Id taskDefaultRcdTypeId;
        // get default record type from custom setting
      	SalesOrg__c salesOrg = SalesOrg__c.getInstance(runningUser.Sales_Org__c);  
        if (salesOrg == null) 
        {	String obj = (isLead ? 'Lead' : 'Contact');
            Id rcdTypeId = (Id)objToSend.get('RecordTypeId');        
        	Schema.RecordTypeInfo rtObj = RecordTypeHelper.getRecordTypeById(rcdTypeId, obj);         
           	String objSalesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(rtObj.getName());
         	salesOrg = SalesOrg__c.getInstance(objSalesOrg); 
        }
        //else
        //{	Schema.RecordTypeInfo rtTask = RecordTypeHelper.getRecordType(salesOrg.TaskRecordTypeName__c, 'Task'); 	
        //	taskDefaultRcdTypeId = rtTask.getRecordTypeId();
        //}
System.debug('**CMF ** salesOrg='+salesOrg);        
        Schema.RecordTypeInfo rtTask = RecordTypeHelper.getRecordType(salesOrg.TaskRecordTypeName__c, 'Task'); 	
     	taskDefaultRcdTypeId = rtTask.getRecordTypeId();
        
        List<Task> taskList = new List<Task>();
        String subj = 'Transfer to NSS by '+ RunningUser.Name + ' ' + addComment;
        Task t = new Task(ActivityDate=System.Today(),Subject=subj.left(255), RecordTypeId = taskDefaultRcdTypeId, Status = 'Completed');
        t.Lead_Source_WAR_Call_Type__c = (String)objToSend.get('LeadSource');	
        t.WhoId = objToSend.Id;
        t.OwnerId = selectedNSRId;
        taskList.add(t);
        
        //Database.DMLoptions dml = new Database.DMLOptions();
        //dml.EmailHeader.triggerUserEmail = true;
        //Database.insert(taskList, dml);
        insert taskList;        
     
    } // createTask
    
} // SendToNSRController