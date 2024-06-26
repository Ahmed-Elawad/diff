/* 
 * Controller for transferring a Case to another group.
 *
 * History
 * -------
 * 03/21/2011 Dan Carmen        Created.
   06/22/2011 Dan Carmen        Add field copy ability
   09/09/2011 Dan Carmen        Added IsActive flag.
   09/21/2011 Dan Carmen        Added ability to move attachments if present.
   01/13/2012 Cindy Freeman     Expanded ability to move attachments to reference object instead of to the case
   04/30/2012 John Callan       Added ability to automatically assign the case to the safety rep on the account.
   04/02/2013 Dan Carmen        Added logic to capture an error on newCase save
   08/28/2013 Dan Carmen        Modification to testCaseTransferSafetyRep so it won't fail because of data.
   09/09/2020 Brandon Vidro     APR0109489 - populate Premier_Concern_1__c on transferred Case
 *
 */ 
public without sharing class CaseTransferController {

   public Boolean hasCurCase{
      get {
         return curCase != null;
      }
   } // hasCurCase
      
   public Case curCase{get;set;}
   
   public User curUser{get;private set;}
   
   /** Default constructor.
    */
   public CaseTransferController(ApexPages.StandardController stdController) {
      curUser = [Select Id, Name, Profile.Name from User where Id = :UserInfo.getUserId()];
      
      //Case testCase = (Case)stdController.getRecord();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'testCase='+testCase+' subject='+testCase.Subject));
      
      // the Id of the Case should be passed in here. If not, cannot proceed
      Id caseId = System.currentPageReference().getParameters().get('id');

      curCase = getCase(caseId);
      if (curCase == null) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No Case record was found! One must be passed into this form in order to proceed.'));
         return;
      }
      setRoutings();
      // if no routings cannot proceed
      if (routings.size() == 0) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No Transfer options were setup for the '+curCase.RecordType.Name+' record type and '+curUser.Profile.Name+' profile! Cannot proceed.'));
         curCase = null;
         return;
      }
      setDepartmentOptions();
   } // CaseTransferController

   public Case newCase{get;set;}
   
   private Case getCase(Id caseId) {
      Case c = null;
      attaches = null;
      if (caseId != null) {
         try {
            c = [Select Id
                       ,ContactId
                       ,Contact.Name
                       ,Contact.Email
                       ,AccountId
                       ,Account.Name
                       ,Referral_Contact__c
                       ,Referral_Contact__r.Name
                       ,RecordTypeId
                       ,RecordType.Name
                       ,Subject
                       ,Description
                       ,Premier_Concern_1__c
                       ,(Select Id
                               ,CommentBody
                           from CaseComments
                          order by LastModifiedDate ASC)
                       ,(SELECT Id, Name, ParentId
                               ,ContentType,BodyLength
                           FROM Attachments
                          order BY Name)
                   from Case
                  where Id = :caseId];
         } catch (Exception e) {
            // do nothing - allow a null value to be returned
         } // try
         
         if (c != null && c.Attachments != null && !c.Attachments.isEmpty()) {
            attaches = new List<AttachWrapper>();
            for (Attachment att : c.Attachments) {
               AttachWrapper aw = new AttachWrapper();
               aw.selected = false;
               aw.attach = att;
               attaches.add(aw);
            } // for
         } // if (c != null
      } // if (caseId != null
      return c;
   } // getCase
   
   /** Does this case have attachments? */
   public Boolean hasAttachments{
      get {return (attaches != null && !attaches.isEmpty()); }
   } // hasAttachments

   public List<AttachWrapper> attaches{get;set;}
   
   /** Wrapper to tell if an attachment is selected to move to the new case. */
   public class AttachWrapper{
      public Boolean selected{get;set;}
      public Attachment attach{get;set;}
   } // AttachWrapper
   
   private List<Case_Transfer_Routing__c> routings = null;
   
   public void setRoutings() {
      routings = [Select Id
                        ,Allow_Active_Assignment_Rules__c
                        ,Allow_Transfer_to_User__c
                        ,Department__c
                        ,Field_Set_Name__c
                        ,From_Profiles__c
                        ,From_Record_Type_Name__c
                        ,IsActive__c
                        ,Queue_Name__c
                        ,Record_Type_Name__c
                        ,Sub_Department_Name__c
                        ,Reference_Object_name__c
                        ,Case_Lookup_field_name__c
                        ,Default_User_Transferred_to__c
                        ,(Select Id, Dest_Field_API_Name__c
                                ,Dest_Field_Value__c
                                ,IsActive__c
                                ,Source_Field_API_Name__c
                                ,Source_Object_API_Name__c
                            from Case_Transfer_Field_Copies__r
                           where IsActive__c = true)
                    from Case_Transfer_Routing__c
                   where From_Record_Type_Name__c = :curCase.RecordType.Name
                     and IsActive__c = true
                    order by Department__c];
      // filter on profile name
      for (Integer cnt = 0; cnt < routings.size(); cnt++) {
         Case_Transfer_Routing__c ctr = routings.get(cnt);
         // if there are profiles listed, and the user's profile is not in the list, do not include the routing.
         if (ctr.From_Profiles__c != null && 
             ctr.From_Profiles__c.length() > 0 && 
             !ctr.From_Profiles__c.contains(curUser.Profile.Name)) {
            routings.remove(cnt);
            cnt--;
         } // if()
      } // for (Integer cnt
   } // getRoutings

   public String departmentOption{get;set;}
   
   public List<SelectOption> departmentOptions{get;private set;}
   
   private void setDepartmentOptions() {
      selectedRouting = null;

      departmentOptions = new List<SelectOption>();
      String prevDept = '';
      for (Case_Transfer_Routing__c routing : routings) {
         if (routing.Department__c != prevDept) {
            departmentOptions.add(new SelectOption(routing.Department__c, routing.Department__c));
            // default to the first department
            if (prevDept == '') {
               departmentOption = routing.Department__c;
            }
            prevDept = routing.Department__c;
         } // if
      } // for (Case_Transfer_Routing__c
      selectDepartment();
   } // setDepartmentOptions
   
   /*
   public List<SelectOption> getDepartmentOptions() {
      selectedRouting = null;
      List<SelectOption> options = new List<SelectOption>();
      options.add(new SelectOption('--Select a Department--','--Select a Department--'));
      String prevDept = '';
      List<Case_Transfer_Routing__c> routings = getRoutings();
      for (Case_Transfer_Routing__c routing : routings) {
         if (routing.Department__c != prevDept) {
            options.add(new SelectOption(routing.Department__c, routing.Department__c));
            prevDept = routing.Department__c;
         } // if
      } // for (Case_Transfer_Routing__c
      return options;
   } // getDepartmentOptions
   */
   
   public String groupOption{get;set;} 

   public List<SelectOption> groupOptions{get;private set;}
   
   /** When a department changes.
    */
   public PageReference selectDepartment() {
      groupOptions = new List<SelectOption>();
      selectedRouting = null;
      groupOption = null;
      for (Case_Transfer_Routing__c routing : routings) {
         if (routing.Department__c == departmentOption) {
            groupOptions.add(new SelectOption(routing.Sub_Department_Name__c, routing.Sub_Department_Name__c));
            if (groupOption == null) {
               // default first found
               groupOption = routing.Sub_Department_Name__c;
            }
         } // if
      } // for (Case_Transfer_Routing__c
      selectGroup();
      return null;
   } // selectDepartment
   
   /** When a group changes.
    */
   public PageReference selectGroup() {
      selectedRouting = null;
      for (Case_Transfer_Routing__c routing : routings) {
         if (routing.Department__c == departmentOption &&
             routing.Sub_Department_Name__c == groupOption) {
            System.debug('routing found for '+departmentOption+' and '+groupOption);
            selectedRouting = routing;
            setNewCase();
            break;
         } // if
      } // for (Case_Transfer_Routing__c
      return null;
   } // selectGroup
   
   /** Setup the new Case object and prompt for additional information (if needed)
    */
   private void setNewCase() {
      // if newCase doesn't exist, only create it once.
      if (newCase == null) {
         newCase = new Case();
         if (curCase != null) {
            newCase.AccountId = curCase.AccountId;
            newCase.Account = curCase.Account;
            newCase.ContactId = curCase.ContactId;
            newCase.Contact = curCase.Contact;
            newCase.Referral_Contact__c = curCase.Referral_Contact__c;
            newCase.Referral_Contact__r = curCase.Referral_Contact__r;
            newCase.ParentId = curCase.Id;
            newCase.Subject = curCase.Subject;
            newCase.Description = curCase.Description;
            newCase.Premier_Concern_1__c = curCase.Premier_Concern_1__c;
            // if description is blank, check case comments and use the first one.
            if (newCase.Description == null && curCase.CaseComments.size() > 0) {
               newCase.Description = curCase.CaseComments.get(0).CommentBody;
            }
         } // if (curCase != null
         newCase.Origin = 'External Department Transfer';
         newCase.Status = 'New';
      } // if (newCase == null

      if (selectedRouting.Record_Type_Name__c != null) {
         Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(selectedRouting.Record_Type_Name__c,'Case');
         if (rt != null) {
            newCase.RecordTypeId = rt.getRecordTypeId();
         }
      } // if (selectedRouting

      // verify queue exists
      queue = new UserHelper().getQueue(selectedRouting.Queue_Name__c);
      setXferOptions();

   } // setNewCase
   
   /** Is the record type okay.
    */
   public Boolean recordTypeOkay{
      get {
         return newCase.RecordTypeId != null;
      }
   } // recordTypeOkay
   
   private Group queue = null;
   
   /** Does the queue exist for this to be transferred to?
    */
   public Boolean queueExists {
      get {
         //return true;
         return queue != null;
      }
   } // queueExists
   
   private List<SelectOption> xferOptions = null;
   
   private void setXferOptions() {
      newCase.User__c = null;
      xferToOption = null;
      xferOptions = new List<SelectOption>();
      if (selectedRouting.Allow_Active_Assignment_Rules__c) {
         xferToOption = 'assignRule';
         xferOptions.add(new SelectOption('assignRule','Use Active Assignment Rules'));
      }
      if (queueExists) {
         // default to queue option if no option currently selected
         if (xferToOption == null) {
            xferToOption = 'queue';
         }
         xferOptions.add(new SelectOption('queue','Assign to queue: '+selectedRouting.Queue_Name__c));
      }
      if (selectedRouting.Allow_Transfer_to_User__c) {
         if (xferToOption == null) {
            // if no option selected, default to user option
            xferToOption = 'user';
            
            //Find the default user to assign the case to if it is indicated in the routing
            if(selectedRouting.Default_User_Transferred_to__c != null){
               newCase.User__c = findDefaultCaseOwnerId();
               System.debug('newCase.User__c='+newCase.User__c);
            }
         }
         
         xferOptions.add(new SelectOption('user','Assign to a User'));
      }
      if (xferOptions.size() == 0) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No valid Transfer Option exist! Please verify the Transfer Routing setup to proceed.'));
      }
      //changeXferOption();
   } // setXferOptions

   public Boolean hasMultipleXferOptions{
      get {
         return (getNbrOptions() > 1);
      }
   } // hasMultipleXferOptions
   
   public Integer getNbrOptions() {
      return (getXferOptions() == null ? 0 : getXferOptions().size());
   } // getNbrOptions
   
   public String xferToOption{get;set;}
   
   public List<SelectOption> getXferOptions() {
      return xferOptions;
   } // getXferOptions

   /** Change the transfer option currently selected.
    */
   public PageReference changeXferOption() {
      newCase.User__c = null;
      //if (xferToOption == 'queue' && queueExists) {
      //     useRoundRobin = true;
      //}
      return null;
   } // changeXferOption
   
   /** Is a group selected.
    */
   public Boolean okayToTransfer {
     get{ 
        return (xferToOption != null);
     }
   } // okayToTransfer
   
   public PageReference transferCase() {
      // set the owner
      if (xferToOption == 'queue' && queueExists) {
         newCase.OwnerId = queue.Id;
      } else if (xferToOption == 'user') {
         if (newCase.User__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A user must be entered to proceed!'));
            return null;
         }
         newCase.OwnerId = newCase.User__c;
      }
      Database.DMLOptions dmo = new Database.DMLOptions();
      if (xferToOption == 'assignRule') {
         // If using active assignment rules
         dmo.assignmentRuleHeader.useDefaultRule=true;
      }
      // If assigning to a user, set email notification
      //dmo.EmailHeader.triggerAutoResponseEmail = (xferToOption == 'user');
      newCase.External_Department_Transfer__c = selectedRouting.Department__c;
      
      // check for setting field values
      if (!checkCopyFieldValues()) {
         return null;
      }
      
      // save case - check for save error
      try {
         Database.SaveResult sr = database.insert(newCase, dmo);
         if (!sr.isSuccess()) {
            String errorMsg = 'Error Saving Case: ';
            for (Database.Error err : sr.getErrors()) {
               errorMsg += err.getMessage();
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMsg));
            return null;
            
         } // if (!sr.isSuccess
      } catch (Exception e) {
         ApexPages.addMessages(e);
         return null;
      }
      
      // if attachments - see if moving them
      if (hasAttachments) {
         //Attachment[] delete
         // get the ids of the Attachments to move
         Id[] attachIds = new Id[]{};
         for (AttachWrapper aw : attaches) {
            if (aw.selected) {
               attachIds.add(aw.attach.Id);
            }
         }
         // if there are records selected
         if (!attachIds.isEmpty()) {
            //if attachment is going to reference object find ref obj id else use caseId
            String attach_parentId = null;
            String soqlstmt = null;
            if (selectedRouting.Reference_Object_Name__c == Null || selectedRouting.Case_Lookup_field_name__c == Null)
            {   attach_parentid = newCase.Id;  }
            else
            {
              try {
                soqlstmt = 'Select Id from ' + selectedRouting.Reference_Object_Name__c + ' where ' + selectedRouting.Case_Lookup_field_name__c + ' = \'' + newCase.Id + '\'';
                Sobject s = Database.query(soqlstmt);               
                attach_parentId = s.Id;
              }
              catch (Exception e) {
                // no reference object found, use case
                attach_parentid = newCase.Id;
              }
            }   //if has reference object       
            AttachmentMove.moveAttachments(attachIds,attach_parentId);
         }
      } // if (hasAttachments
      
      /* keeping this here just for reference for now 
      // if transfer to a user, send an email
      if (curCase.ContactId != null && curCase.Contact.Email != null) {
         EmailTemplate et = [Select Id, Name, DeveloperName from EmailTemplate where DeveloperName='Dan_Test_Template'];

         //New instance of a single email message  
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
         // Who you are sending the email to  
         mail.setTargetObjectId(curCase.ContactId);  

         // The email template ID used for the email  
         mail.setTemplateId(et.Id);  

         //mail.setWhatId(newCase.id);      
         mail.setBccSender(false);  
         mail.setUseSignature(false);  
         //mail.setReplyTo('recruiting@acme.com');  
         //mail.setSenderDisplayName('HR Recruiting');  
         mail.setSaveAsActivity(true);    
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
      }
      /**/
      // return to original case
      PageReference casePage = new PageReference('/'+curCase.Id);
      casePage.setRedirect(true);               
      return casePage;
   } // transferCase
   
   /*
   Dest_Field_API_Name__c
                                ,Dest_Field_Value__c
                                ,Source_Field_API_Name__c
                                ,Source_Object_API_Name__c
                                */
                                
   public Boolean checkCopyFieldValues() {
      Boolean allOkay = true;
      if (selectedRouting.Case_Transfer_Field_Copies__r != null && !selectedRouting.Case_Transfer_Field_Copies__r.isEmpty()) {
         for (Case_Transfer_Field_Copy__c ctfc : selectedRouting.Case_Transfer_Field_Copies__r) {
            // verify the destination field exists
            if (checkField('Case', ctfc.Dest_Field_API_Name__c)) {
               // a map of fields to copy from original case to new case - to allow for query
               Map<String,String> caseCopyMap = new Map<String,String>();
               if (ctfc.Dest_Field_Value__c != null) {
                  newCase.put(ctfc.Dest_Field_API_Name__c,ctfc.Dest_Field_Value__c);
               } else if (ctfc.Source_Object_API_Name__c != null && ctfc.Source_Field_API_Name__c != null) {
                  // only support copying from Case initially
                  if (ctfc.Source_Object_API_Name__c == 'Case') {
                     if (checkField(ctfc.Source_Object_API_Name__c,ctfc.Source_Field_API_Name__c)) {
                        // store the fields in a Map to build one query
                        caseCopyMap.put(ctfc.Source_Field_API_Name__c,ctfc.Dest_Field_API_Name__c);
                     } else {
                        allOkay = false;
                     }
                  }
                  if (!caseCopyMap.isEmpty()) {
                     copyCaseFields(caseCopyMap,'Case',curCase.Id);
                  }
               } // if (ctfc.Dest_Field_Value__c
               
            } else {
               allOkay = false;
            }
         } // for (Case_Transfer_Field_Copy__c
      } // if
      return allOkay;
   } // checkCopyFieldValues
   
   private SObjectHelper soHelper = new SObjectHelper();

   /** Check if a field exists. Log an error if it does not.
    */   
   public Boolean checkField(String objectApiName, String fieldApiName) {
      if (!soHelper.checkField(objectApiName, fieldApiName)) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The field '+fieldApiName+' does not exist on the '+objectApiName+' object. Fix this record in the Transfer table before proceeding.'));
         return false;
      }
      return true;
   } // checkField
   
   public Boolean copyCaseFields(Map<String,String> caseCopyMap, String objectName, Id id) {
      // build a query
      String query = 'Select Id ';
      for (String key : caseCopyMap.keySet()) {
         query += ','+key;
      }
      query += ' FROM '+objectName+' where id=\''+id+'\' ';
      try {
         SObject so = Database.query(query);
         for (String key : caseCopyMap.keySet()) {
            newCase.put(caseCopyMap.get(key), so.get(key));
         }
      } catch (Exception e) {
         ApexPages.addMessages(e);
         return false;
      }
      return true;
   } // copyCaseFields
   
   public User xferUser{get;set;}
   
   public Case_Transfer_Routing__c selectedRouting{get;set;}
   
   public Boolean showSafetyTransferFields {
      get {
         return (selectedRouting != null && selectedRouting.Field_Set_Name__c == 'Safety_Transfer_Fields');
      }
   } // showFSTransferFields
   
   private Id findDefaultCaseOwnerId() {
      // check to make sure Default_User_Transferred_to__c and AccountId are both populated
      if (selectedRouting.Default_User_Transferred_to__c != null && curCase.AccountId != null) {
         // verify that the field exists on the Account
         ObjectHelper oh = new ObjectHelper();
         if (!oh.checkField('Account', selectedRouting.Default_User_Transferred_to__c)) {
            // cannot proceed if the field doesn't exist
            return null;
         }
         // build a query 
         String query = 'Select ' + selectedRouting.Default_User_Transferred_to__c +' From Account Where Id =\'' + curCase.AccountId+'\'';
         // execute the query - should always return a result as long as there's an AccountId 
         Account acct = Database.query(query);
         // get the Id from the result
         if(acct.get(selectedRouting.Default_User_Transferred_to__c) != null){
            String checkId = String.valueOf(acct.get(selectedRouting.Default_User_Transferred_to__c));
            // see if it's an account or contact id
            String ctctPrefix = Contact.sObjectType.getDescribe().getKeyPrefix();
            String userPrefix = User.sObjectType.getDescribe().getKeyPrefix();
            if (checkId != null && checkId.startsWith(ctctPrefix)) {
               // if starts with the Contact prefix, select the Contact to get the HR_Person_Id__c. HR_Person_Id__c is unique on the Contact records.
               // since we have the Id should alway return a value
               Contact ctct = [Select c.HR_Person_Id__c From Contact c Where Id = :checkId];
               System.debug('ctct='+ctct);
               // might not be a User for the person id, so be sure to handle that. Also could be more than one for a person id. Assume to take the first one.
               try {
                  User u = [Select u.Id  From User u Where u.HR_Person_Id__c = :ctct.HR_Person_Id__c and u.IsActive = true Limit 1];
                  System.debug('u='+u);
                  return u.Id;
               } catch (Exception e) {
                  // do nothing here if an exception occurs - we'll just assume did not find a valid value
                  System.debug('Could not select a User! '+e);
               }
            } else if (checkId != null && checkId.startsWith(userPrefix)) {
               // if user prefix, no further work is required - return this Id
               return checkId;
            }
         }//if(acct.get(selectedRouting.Default_User_Transferred_to__c) != null){
      } // if (selectedRouting
      return null;    
   } // findDefaultCaseOwnerId   
         
} // class CaseTransferController