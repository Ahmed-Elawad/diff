/* Request access to a sandbox
        
  
           
  History
  -------
  02/16/2024 Dan Carmen      Created
  05/16/2024 Dan Carmen      Fix resend method

 */
public without sharing class SandboxRequest {
   public static final String CLASSNAME='SandboxRequest';
   public SandboxRequest() {
      setup();
   } // SandboxRequest
    
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      if (isBefore) {
         handleTriggerBefore((SandboxUserRequest__c[])recs, (Map<Id,SandboxUserRequest__c>)oldMap);
      } else if (isAfter) {
         handleTriggerAfter((SandboxUserRequest__c[])recs, (Map<Id,SandboxUserRequest__c>)oldMap);
      }
   } // handleTrigger
    
   public static void handleTriggerBefore(SandboxUserRequest__c[] recs, Map<Id,SandboxUserRequest__c> oldMap) {
      resendIds.clear();
      for (SandboxUserRequest__c rec : recs) {
         // reset the flag
         if (rec.Resend__c && rec.Id != null) {
            resendIds.add(rec.Id);
            rec.Resend__c = false;
         }
      }
   } // handleTriggerBefore

   public static Id[] resendIds = new Id[]{};
   public static void handleTriggerAfter(SandboxUserRequest__c[] recs, Map<Id,SandboxUserRequest__c> oldMap) {
      SandboxUserRequest__c[] resendRecs = new SandboxUserRequest__c[]{};
      // for all the records we have to retrieve
      Id[] ctctIds = new Id[]{};
      Id[] sandboxIds = new Id[]{};
      Set<Id> profileIds = new Set<Id>();
      
      for (SandboxUserRequest__c rec : recs) {
         SandboxUserRequest__c oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         if (resendIds.contains(rec.Id)) {
            resendRecs.add(rec);
            if (rec.SandboxUserContact__c != null) {
               ctctIds.add(rec.SandboxUserContact__c);
            }
            if (rec.SandboxSetup__c != null && !sandboxIds.contains(rec.SandboxSetup__c)) {
               sandboxIds.add(rec.SandboxSetup__c);
            }
            if (rec.SandboxProfileSetup__c != null) {
               profileIds.add(rec.SandboxProfileSetup__c);
            }
         } // if (oldRec != null && oldRec.Resend__c
      } // for (SandboxUserRequest__c rec
       
      System.debug('handleTriggerAfter resendRecs='+resendRecs.size()+' sandboxIds='+sandboxIds.size());
      if (sandboxIds.size() > 1) {
         recs[0].addError('Can only resend for one sandbox at a time!');
         return;
      }
      if (!resendRecs.isEmpty()) {
         handleResend(resendRecs,ctctIds,sandboxIds,profileIds);
      }
   } // handleTriggerAfter
    
   public static void handleResend(SandboxUserRequest__c[] resendRecs, Id[] ctctIds,Id[] sandboxIds, Set<Id> profileIds) {
      System.debug('handleResend resendRecs='+resendRecs.size()+' ctctIds='+ctctIds.size()+' sandboxIds='+sandboxIds.size());
      // resend a user request to a sandbox.
      // create an instance of the class
      SandboxRequest sr = new SandboxRequest();
	  sr.usrRequest.SandboxSetup__c = sandboxIds[0];
	  SandboxSetup__c sandbox = sr.getSelectedSandbox();
	  System.debug('handleResend sandbox='+sandbox);
      sr.setupProfiles();
	  Contact[] ctcts = (!ctctIds.isEmpty() ? sr.getContacts(new String[]{}, ctctIds) : new Contact[]{});
	  Map<Id,Contact> ctctMap = new Map<Id,Contact>(ctcts);
	  Id[] userIdsToMirror = new Id[]{};
	  EmailWrap eWrap = new EmailWrap();
	  for (SandboxUserRequest__c sur : resendRecs) {
         RequestWrap rWrap = new RequestWrap();
         rWrap.usrReq = sur;
         rWrap.ctct = (sur.SandboxUserContact__c != null ? ctctMap.get(sur.SandboxUserContact__c) : null);
	     eWrap.requests.add(rWrap);
	     SandboxProfileSetup__c sps = (sur.SandboxProfileSetup__c != null ? sr.profSetupMap.get(sur.SandboxProfileSetup__c) : null);
		 if (sps != null) {
		    eWrap.setupMap.put(sps.Id, sps);
			if (sps.UserToMirror__c != null) {
		       userIdsToMirror.add(sps.UserToMirror__c);
			}
	     } // if (sps != null
	  } // for (SandboxUserRequest__c
	  eWrap.userToMirrorMap = (!userIdsToMirror.isEmpty() ? sr.getUserToMirror(userIdsToMirror) : new Map<Id,User>());
	  SandboxRequest.emailRequests(sandbox, eWrap);
   } // handleResend


   public User runningUser{get;set;}
   // Is this a guest user?
   public Boolean isGuestUser {get;set;}
   public Boolean isSystemAdmin {get;set;}
   public SandboxUserRequest__c usrRequest {get;set;}
   // for entering multiple user requests
    
   public String blockTitle{
      get{
         //String sandboxName='Sandbox';
         String prefix=SandboxSetup__c.getSObjectType().getDescribe().getKeyPrefix();
         // make sure the value in the field is actually an id.
         Id recId = (String.isNotBlank(sandboxOption) && sandboxOption.startsWith(prefix) ? Id.valueOf(sandboxOption) : null);
         String sandboxName = (recId != null && sandboxMap != null && sandboxMap.containsKey(recId) ? sandboxMap.get(recId).Name : 'Sandbox');
         String title=sandboxName+' User Request';
         return title;
      }
   } // blockTitle
   
   public void setup() {
      //canWeProceed = true;
      runningUser = UserHelper.getRunningUser();
      isSystemAdmin = UserHelper.isRunningUserSystemAdmin();
      isGuestUser = UserHelper.isRunningUserGuest();
      usrRequest = new SandboxUserRequest__c();
      setupSandboxes();
      stepName='Step1';
   } // setRunningUser
    
   public SandboxSetup__c[] sandboxes {get;set;}
   public Map<Id,SandboxSetup__c> sandboxMap = new Map<Id,SandboxSetup__c>();
   public SelectOption[] sandboxOptions{get;set;}
   public String sandboxOption{get;set;}
    
   public SandboxProfileSetup__c[] profileSetups{get;set;}
   public Map<Id,SandboxProfileSetup__c> profSetupMap = new Map<Id,SandboxProfileSetup__c>();
   public SelectOption[] profileOptions{get;set;}
   public String profileOption{get;set;}

   public String stepName{get;set;}
   public void setupSandboxes() {
      sandboxOptions = new SelectOption[]{};
      sandboxMap.clear();
      sandboxes = [Select Id, Name, Description__c, EmailToSendRequests__c
                     From SandboxSetup__c
                    Where Active__c=true
                   order by SortOrder__c ASC nulls last, Name ASC];
      sandboxOptions.add(new SelectOption('Select a Sandbox','Select a Sandbox'));
      for (SandboxSetup__c sandbox : sandboxes) {
         sandboxOptions.add(new SelectOption(sandbox.Id, sandbox.Name));
         sandboxMap.put(sandbox.Id,sandbox);
      }
   } // setupSandboxes
    
   public SandboxSetup__c getSelectedSandbox() {
     SandboxSetup__c sandbox = (usrRequest.SandboxSetup__c != null && sandboxMap != null ? sandboxMap.get(usrRequest.SandboxSetup__c) : null);
     System.debug('getSelectedSandbox usrRequest.SandboxSetup__c='+usrRequest.SandboxSetup__c+' sandboxMap='+sandboxMap.size()+' sandbox='+(sandbox != null));
     return sandbox;
   } // getSelectedSandbox
    
   public void setupProfiles() {
      SandboxSetup__c sandbox = getSelectedSandbox();
      System.debug('setupProfiles sandbox='+sandbox);
      if (sandbox != null) {
         profileSetups = [Select Id, Name, ApprovalNeeded__c, DelegatedAdminGroup__c, Description__c
                             ,ProfileName__c, RoleName__c
                             ,PermissionSetList__c, PermissionSetGroupList__c
                             ,UserToMirror__c, SandboxSetup__c
                         From SandboxProfileSetup__c
                        Where Active__c=true
                          and SandboxSetup__c = :sandbox.Id
                        order by Name];
      } else {
         profileSetups = new SandboxProfileSetup__c[]{};
      }
      
      profileOptions = new SelectOption[]{};
      profSetupMap.clear();
      profileOptions.add(new SelectOption('Select a Profile','Select a Profile'));
      for (SandboxProfileSetup__c profSetup : profileSetups) {
         profileOptions.add(new SelectOption(profSetup.Id, profSetup.Name));
         profSetupMap.put(profSetup.Id,profSetup);
      }
      profileSetups.add(new SandboxProfileSetup__c(Name='Enter Manually',Description__c='You must manually enter the name of the Profile and Role'));
      profileOptions.add(new SelectOption('Enter Manually','Enter Manually'));
   } // setupProfiles
    
    public Boolean manualRoleProfile{
        get {return profileOption == 'Enter Manually';}
    } // manualRoleProfile
    
   public PageReference setSelectedSandbox() {
      System.debug('setSelectedSandbox sandboxOption='+sandboxOption);
      if (sandboxOption == 'Select a Sandbox') {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please select a sandbox'));
      } else if (sandboxOption != 'Select a Sandbox') {
         usrRequest.SandboxSetup__c = sandboxOption;
         Integer nbrRecs = null;
         try {
            nbrRecs = Integer.valueOf(usrRequest.NbrOfUsers__c);
         } catch (Exception e) {}
         // verify the email
         Contact[] ctcts = getContacts(new String[]{usrRequest.RequestorEmail__c},null);
         Boolean okay = (ctcts.size() == 1);
         if (!okay) {
            usrRequest.RequestorEmail__c.addError('A valid employee record could not be found');
         } else {
            usrRequest.RequestorContact__c = ctcts[0].Id;
         }
         if (nbrRecs == null || nbrRecs <1 || nbrRecs > 100) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Must enter a number between 1 and 100 for the Number of Users'));
            okay = false;
         }
         if (okay) {
            setupProfiles();
            stepName='Step2';
         }
      } // if (sandboxOption
      return null;
   } // setSelectedSandbox
    
   public Contact[] getContacts(String[] emails, Id[] ctctIds) {
      ctctIds = (ctctIds == null ? new Id[]{} : ctctIds);
      Contact[] ctcts = [Select Id, Name, FirstName, LastName, HR_Person_Id__c
                               ,Department, Paychex_Cost_Center__c, Phone, Email
                               ,Hire_Date__c, Paychex_Physical_Location__c, Paychex_Rep_Code__c
                               ,TempFirstName__c, TempLastName__c, TempDepartment__c
                               ,Payroll_Employee_Number__c
                               ,AccountId, Prefered_Name__c, Supervisor_Person_Id__c, Title 
                           from Contact
                          Where HR_Person_Id__c != null
                            and Date_of_Employee_Termination__c = null
                            and (Email in :emails or Id in :ctctIds)
                          order by LastName, FirstName];
      return ctcts;
   } // getContacts
    
   public PageReference setSelectedProfile() {
      usrRequest.SandboxProfileSetup__c=null;
      System.debug('setSelectedProfile profileOption='+profileOption);
      if (profileOption == 'Enter Manually') {
         if (String.isNotBlank(usrRequest.ProfileName__c) && String.isNotBlank(usrRequest.RoleName__c)) {
            setupRequests();
         }
      } else if (profileOption != 'Select a Profile') {
         usrRequest.ProfileName__c=null;
         usrRequest.RoleName__c=null;
         usrRequest.SandboxProfileSetup__c=profileOption;
         setupRequests();
      }
      return null;
   } // setSelectedProfile
    
   public SandboxProfileSetup__c getProfSetup() {
      SandboxProfileSetup__c profSetup = (usrRequest.SandboxProfileSetup__c != null && profSetupMap != null ? profSetupMap.get(usrRequest.SandboxProfileSetup__c) : null);
      System.debug('getProfSetup usrRequest.SandboxProfileSetup__c='+usrRequest.SandboxProfileSetup__c+' profSetupMap='+profSetupMap.size()+' profSetup='+(profSetup != null));
      return profSetup;
   } // getProfSetup
    
   public RequestWrap[] requests{get;set;}
    
   public void setupRequests() {
      stepName='Step3';
      requests = new RequestWrap[]{};
      Integer nbrRecs = Integer.valueOf(usrRequest.NbrOfUsers__c);
      
      for (Integer cnt=0; cnt<nbrRecs; cnt++) {
         RequestWrap req = new RequestWrap();
         req.usrReq = new SandboxUserRequest__c();
         requests.add(req);
      }
   } // setupRequests
   
   public PageReference restart() {
      stepName='Step1';
      usrRequest = new SandboxUserRequest__c();
      sandboxOption=null;
      profileOption=null;
      return null;
   } // restart
    
   public PageReference verifyEmails() {
     String[] emails = new String[]{};
     Map<String,RequestWrap> requestMap = new Map<String,RequestWrap>();
     for (RequestWrap request : requests) {
         if (requestMap.containsKey(request.usrReq.SandboxUserEmail__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The email '+request.usrReq.SandboxUserEmail__c+' was entered more than once!'));
         } else {
            requestMap.put(request.usrReq.SandboxUserEmail__c, request);
         }
     } // for (SandboxUserRequest__c usrRequest
     System.debug('verifyEmails requests='+requests.size()+' requestMap='+requestMap.size());
     // if we don't have any duplicates
     if (requestMap.size() == requests.size()) {
        // query the contacts
         if (checkContacts(requestMap)) {
            stepName = 'Step4';
         }
     }
     return null;
   } // verifyEmails
    
   public Boolean checkContacts(Map<String,RequestWrap> requestMap) {
      Boolean okay = true;
      String[] emails = new String[]{};
      emails.addAll(requestMap.keySet());
      Contact[] ctcts = getContacts(emails,null);
      /*
      Contact[] ctcts = [Select Id, Name, FirstName, LastName, Title
                               ,HR_Person_Id__c, Department, Email, Prefered_Name__c, Supervisor_Person_Id__c
                               ,Paychex_Cost_Center__c, Hire_Date__c, Payroll_Employee_Number__c
                               ,Paychex_Rep_Code__c, Phone, Date_of_Employee_Termination__c
                               ,MailingStreet, MailingCity, MailingState, MailingPostalCode
                           From Contact
                          Where HR_Person_Id__c != null
                            and Email in :requestMap.keySet()
                          order by LastName, FirstName]; 
      */
      System.debug('checkContacts requestMap='+requestMap.size()+' ctcts='+ctcts.size());
      for (Contact ctct : ctcts) {
         RequestWrap request = requestMap.remove(ctct.Email);
         if (request != null) {
            request.ctct = ctct;
         }
      }
      okay = (requestMap.isEmpty());
      System.debug('checkContacts okay='+okay);
      for (RequestWrap request : requestMap.values()) {
         request.usrReq.SandboxUserEmail__c.addError('Could not find an employee contact record for this email!');
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Could not find an employee contact record for '+request.usrReq.SandboxUserEmail__c));
      }
      return okay; 
   } // checkContacts
    
   public class RequestWrap {
      public SandboxUserRequest__c usrReq{get;set;}
      public Contact ctct{get;set;}
      // this field is only used at the destination sandbox to keep everything together.
      public User usr{get;set;}
   } // RequestWrap
    
   public class EmailWrap {
      public RequestWrap[] requests = new RequestWrap[]{};
      public Map<Id,SandboxProfileSetup__c> setupMap = new Map<Id,SandboxProfileSetup__c>();
      public Map<Id,User> userToMirrorMap = new Map<Id,User>();
      public String returnEmail;
   } // class EmailWrap
    
   // fields to copy from a mirrored user
   //             for (Schema.FieldSetMember fsm : Schema.SObjectType.User.fieldSets.CopyFromMirrorFlds.getFields()) {
   public String[] copyFields = new String[]{};
       
    public Map<Id,User> getUserToMirror(Id[] userIds) {
       list<string> excludedPermsList = label.PermissionSetExclusions.split(','); 
       Set<String> fldSet = new Set<String>();
       DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.CopyFromMirrorFlds, '', fldSet);
       // build the list to pass to the sandbox to copy
       Set<String> copyFldSet = new Set<String>();
       copyFldSet.addAll(fldSet);
       copyFldSet.remove('ProfileId');
       copyFldSet.remove('UserRoleId');
       copyFields.addAll(copyFldSet);
       
       DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.SandboxCopyQuery, '', fldSet);
       String query = DmlHelper.buildQueryFromSet(fldSet,'');
       String subQuery = ',(Select Id, PermissionSetId, PermissionSet.Label, PermissionSetGroupId, PermissionSetGroup.MasterLabel '+
                                  ' from PermissionSetAssignments '+
                                 ' Where PermissionSet.IsOwnedByProfile = false '+
                                  '  and PermissionSet.label not in: excludedPermsList)';
       query += subQuery+' From User where Id=:userIds';
       User[] users = Database.query(query);
       Map<Id,User> userMap = new Map<Id,User>(users);
       return userMap;
    } // getUserToMirror
    
   // make this a public variable for testing purposes
   public EmailWrap testEWrap;
    
   public PageReference submitRequests() {
      SandboxSetup__c sandbox = getSelectedSandbox();
      EmailWrap eWrap = new EmailWrap();
      if (Test.isRunningTest()) {
         testEWrap = eWrap;
      }
      SandboxProfileSetup__c profSetup = getProfSetup();
      if (profSetup != null && profSetup.Id != null) {
         eWrap.setupMap.put(profSetup.Id, profSetup);
      }
      Id userId = ((profSetup != null && profSetup.UserToMirror__c != null) ? profSetup.UserToMirror__c : null);
      eWrap.userToMirrorMap = (userId != null ? getUserToMirror(new Id[]{userId}) : new Map<Id,User>());
      User usr = (userId != null ? eWrap.userToMirrorMap.get(userId) : null);
      //setProfPermInfo(eWrap);
      SandboxUserRequest__c[] saveReqs = new SandboxUserRequest__c[]{};
      for (RequestWrap req : requests) {
         //ctcts.add(req.ctct);
         req.usrReq.RequestorEmail__c = usrRequest.RequestorEmail__c;
         req.usrReq.RequestorContact__c = usrRequest.RequestorContact__c;
         req.usrReq.SandboxSetup__c = usrRequest.SandboxSetup__c;
         req.usrReq.SandboxUserContact__c = req.ctct.Id;
         req.usrReq.SandboxProfileSetup__c = usrRequest.SandboxProfileSetup__c;
         req.usrReq.ProfileName__c = (usr != null && usr.ProfileId != null ? usr.Profile.Name 
                                        : (profSetup != null && String.isNotBlank(profSetup.ProfileName__c) ? profSetup.ProfileName__c : usrRequest.ProfileName__c));
         req.usrReq.RoleName__c = (usr != null && usr.UserRoleId != null ? usr.UserRole.Name 
                                   : (profSetup != null && String.isNotBlank(profSetup.RoleName__c) ? profSetup.RoleName__c : usrRequest.RoleName__c));
         req.usrReq.NbrOfUsers__c = usrRequest.NbrOfUsers__c;
         req.usrReq.UserToMirror__c = profSetup.UserToMirror__c;
         eWrap.requests.add(req);
         saveReqs.add(req.usrReq);
         //req.profSetup = profSetup;
      } // for (RequestWrap req : requests
      DmlHelper.performDML2(saveReqs, DmlHelper.DML_INSERT, CLASSNAME, 'submitRequests', 'Insert new requests', true);
      emailRequests(sandbox, eWrap);
      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Sandbox Requests successfully submitted!'));
      restart();
      return null;
   } // submitRequests
    
//get the email from the current system that the responses would go to    
//EmailServicesAddress[] addr = [Select Id, DeveloperName, LocalPart, EmailDomainName from EmailServicesAddress where IsActive=true and Function.FunctionName='SandUser'];
//System.debug('addr='+addr);
    
   public static final String emailTail='<ThisIsTheEnd>';
   public static final String requestSubject='SandboxRequest';
   public static final String responseSubject='SandboxResponse';
    
   public static void emailRequests(SandboxSetup__c sandbox, EmailWrap eWrap) {
      System.debug('emailRequests sandbox='+sandbox+' reqs='+eWrap.requests.size());
      if (sandbox != null && String.isNotBlank(sandbox.EmailToSendRequests__c)) {
         eWrap.returnEmail = getReturnEmail();
         String emailBody = json.serialize(eWrap).replace('number_Z','number')+emailTail;
         Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
         emailToSend.setSaveAsActivity(false);
         emailToSend.setToAddresses(new String[]{sandbox.EmailToSendRequests__c});
         emailToSend.setSubject(requestSubject);
         emailToSend.setPlainTextBody(emailBody);
         Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emailToSend}, false);

      }
   } // emailRequests
    
   public static String SERVICE_NAME=Label.SandboxRequest_EmailService;
    
   public static String getReturnEmail() {
      String email=null;
      //get the email from the current system that the responses would go to    
      EmailServicesAddress[] addrs = [Select Id, DeveloperName, LocalPart, EmailDomainName from EmailServicesAddress where IsActive=true and Function.FunctionName=:SERVICE_NAME];
      email = (!addrs.isEmpty() ? (addrs[0].LocalPart+'@'+addrs[0].EmailDomainName) : null);
      System.debug('getReturnEmail email='+email);
      return email;
   } // getReturnEmail
    
   public class ResponseWrap {
      public ResponseDetail[] responses;
   } // class ResponseWrap
    
   public class ResponseDetail {
      public SandboxUserRequest__c sur = new SandboxUserRequest__c();
      //public Id recId;
      //public String sandboxName;
      //public String status;
      //public String processNotes;
      //public String delegateGrp;
      //public String delegateGrpDetail;
   } // class ResponseDetail
    
   public static void handleEmailRequest(String emailBody) {
      EmailWrap eWrap =  (EmailWrap)json.deserialize(emailBody, EmailWrap.class);
      System.debug('handleEmailRequest eWrap='+eWrap.requests.size()+' returnEmail='+eWrap.returnEmail);
      ResponseDetail[] responses = processEmailRequests(eWrap);
      emailResponse(eWrap,responses);
      /*
      if (String.isNotBlank(eWrap.returnEmail)) {
         // send the responses back
         ResponseWrap resp = new ResponseWrap();
         resp.responses = responses;
         String returnEmailBody = json.serialize(resp).replace('number_Z','number')+emailTail;
         Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
         emailToSend.setSaveAsActivity(false);
         emailToSend.setToAddresses(new String[]{eWrap.returnEmail});
         emailToSend.setSubject(responseSubject);
         emailToSend.setPlainTextBody(returnEmailBody);
         Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emailToSend}, false);

      }
      */
   } // handleEmailRequest
    
   // for testing purposes only
   public static Boolean emailSent=false;
    
   public static void emailResponse(EmailWrap eWrap, ResponseDetail[] responses) {
      if (String.isNotBlank(eWrap.returnEmail)) {
         // send the responses back
         ResponseWrap resp = new ResponseWrap();
         resp.responses = responses;
         String returnEmailBody = json.serialize(resp).replace('number_Z','number')+emailTail;
         Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
         emailToSend.setSaveAsActivity(false);
         emailToSend.setToAddresses(new String[]{eWrap.returnEmail});
         emailToSend.setSubject(responseSubject);
         emailToSend.setPlainTextBody(returnEmailBody);
         Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emailToSend}, false);
         emailSent=true;
      }
   } // emailResponse
    
   public static final String PERMSET='PermSet';
   public static final String PERMGRP='PermGrp';
    
   public static ResponseDetail[] processEmailRequests(EmailWrap eWrap) {
      // collect all the person ids to get the existing users
      Set<String> profileNameSet = new Set<String>();
      Set<String> roleNameSet = new Set<String>();
      Set<String> permSetNames = new Set<String>();
      Set<String> permGrpNames = new Set<String>();
      Map<String,RequestWrap> byPersonIdMap = new Map<String,RequestWrap>();
      Map<String,Set<String>> permSetNameMap = new Map<String,Set<String>>();
      Map<String,RequestWrap[]> byDelegated;
       
      // collect all of the permission set info
      for (SandboxProfileSetup__c profSetup : eWrap.setupMap.values()) {
         if (String.isNotBlank(profSetup.PermissionSetList__c)) {
            Set<String> permSets = new Set<String>(profSetup.PermissionSetList__c.split(','));
            permSetNames.addAll(permSets);
            permSetNameMap.put(PERMSET+profSetup.Id, permSets);
         }
         if (String.isNotBlank(profSetup.PermissionSetGroupList__c)) {
            Set<String> permGrps = new Set<String>(profSetup.PermissionSetGroupList__c.split(','));
            permGrpNames.addAll(permGrps);
            permSetNameMap.put(PERMGRP+profSetup.Id, permGrps);
         }
      } // for (SandboxProfileSetup__c profSetup
       
      for (User usr : eWrap.userToMirrorMap.values()) {
         Set<String> permSets = new Set<String>();
         Set<String> permGrps = new Set<String>();
         for (PermissionSetAssignment psa : usr.PermissionSetAssignments) {
            if (psa.PermissionSetId != null) {
               permSets.add(psa.PermissionSet.Label);
            } else if (psa.PermissionSetGroupId != null) {
               permGrps.add(psa.PermissionSetGroup.MasterLabel);
            }
          
         } // for (PermissionSetAssignment psa
         if (!permSets.isEmpty()) {
            permSetNames.addAll(permSets);
            permSetNameMap.put(PERMSET+usr.Id, permSets);
         }
         if (!permGrps.isEmpty()) {
            permGrpNames.addAll(permGrps);
            permSetNameMap.put(PERMGRP+usr.Id, permGrps);
         }
      } // for (User usr : eWrap.userToMirrorMap
      
      // collect all of the profile and role info
      for (RequestWrap req : eWrap.requests) {
         if (req.ctct != null && String.isNotBlank(req.ctct.HR_Person_Id__c)) {
            byPersonIdMap.put(req.ctct.HR_Person_Id__c, req);
         }
         if (String.isNotBlank(req.usrReq.ProfileName__c)) {
            profileNameSet.add(req.usrReq.ProfileName__c);
         }
         if (String.isNotBlank(req.usrReq.RoleName__c)) {
            roleNameSet.add(req.usrReq.RoleName__c);
         }
      } // for (RequestWrap req : reqs
       
      Profile[] profs = [Select Id, Name from Profile where Name in :profileNameSet];
      Map<String,Profile> profMap = new Map<String,Profile>();
      for (Profile prof : profs) {
         profMap.put(prof.Name,prof);
      }
      UserRole[] roles = [Select Id, Name from UserRole where Name in :roleNameSet];
      Map<String,UserRole> roleMap = new Map<String,UserRole>();
      for (UserRole role : roles) {
         roleMap.put(role.Name, role);
      }
      // to keep track of the permission sets we don't find in this environment
      Map<String,String[]> notFoundMap = new Map<String,String[]>();
      Map<String,Set<Id>> permIdByNameMap = getPermSetIdMap(permSetNameMap, permSetNames, permGrpNames, notFoundMap);
       
      System.debug('processEmailRequests reqs='+eWrap.requests.size()+' profileNameSet='+profileNameSet.size()+' profs='+profs.size()+' roleNameSet='+roleNameSet.size()+' roles='+roles.size());
      Map<String,User> userMap = ContactFormatPaychexEmps.getUsersByPersonId(byPersonIdMap.keySet());
      System.debug('processEmailRequests byPersonIdMap='+byPersonIdMap.size()+' userMap='+userMap.size());
       
      ResponseDetail[] requestResponses = new ResponseDetail[]{};
      User[] updateUsers = new User[]{};
      User[] insertUsers = new User[]{};
          
      // determine which sandbox instance we're using
      String instanceName = Utilities.checkForProduction();
      instanceName = (String.IsBlank(instanceName) ? 'Production' : instanceName);
       
      PermissionSetAssignment[] newPsas = new PermissionSetAssignment[]{};
      Map<String,RequestWrap[]> delAdminMap = new Map<String,RequestWrap[]>();
          
      System.debug('processEmailRequests requests='+eWrap.requests.size());
      for (RequestWrap req : eWrap.requests) {
         System.debug('processEmailRequests in loop');
         ResponseDetail resp = new ResponseDetail();
         System.debug('processEmailRequests created resp req.usrReq='+req.usrReq);
         System.debug('processEmailRequests resp='+resp);
         System.debug('processEmailRequests resp.sur='+resp.sur);
         resp.sur.RecordId__c = req.usrReq.Id;
         System.debug('processEmailRequests before instanceName');
         resp.sur.SandboxName__c = instanceName;
         System.debug('processEmailRequests before add to requestResponses');
         //resp.recId=req.usrReq.Id;
         //resp.sandboxName=instanceName;
         requestResponses.add(resp);
         System.debug('processEmailRequests added to responses');
         String profName = req.usrReq.ProfileName__c;
         System.debug('processEmailRequests profName='+profName);
         Profile prof = (String.isNotBlank(profName) ? profMap.get(profName) : null);
         System.debug('processEmailRequests prof='+(prof != null));
         String notes = 'Searching for profile '+profName+'......'+(prof != null ? 'Found!' : 'Not Found!');
         String roleName = req.usrReq.RoleName__c;
         System.debug('processEmailRequests roleName='+roleName);
         UserRole role = (String.isNotBlank(roleName) ? roleMap.get(roleName) : null);
         System.debug('processEmailRequests role='+(role != null));
         notes += '\nSearching for role '+roleName+'......'+(role != null ? 'Found!' : 'Not Found!');
         resp.sur.ProcessNotes__c=notes;
         //resp.ProcessNotes=notes;
         SandboxProfileSetup__c profSetup = (req.usrReq.SandboxProfileSetup__c != null ? eWrap.setupMap.get(req.usrReq.SandboxProfileSetup__c) : null);
         System.debug('processEmailRequests profSetup='+profSetup);
         // store the users who need to be connected to a delegated admin.
         if (profSetup != null && String.isNotBlank(profSetup.DelegatedAdminGroup__c)) {
            RequestWrap[] wraps = (delAdminMap.containsKey(profSetup.DelegatedAdminGroup__c) ? delAdminMap.get(profSetup.DelegatedAdminGroup__c) : new RequestWrap[]{});
            wraps.add(req);
            delAdminMap.put(profSetup.DelegatedAdminGroup__c,wraps);
         }
         System.debug('processEmailRequests prof='+(prof != null ? prof.Name : 'NotFound')+' role='+(role != null ? role.Name : 'NotFound'));
         if (prof != null && role != null) {
            Set<Id> permSetIds = new Set<Id>();
            Set<Id> permGrpIds = new Set<Id>();
            getPermSets(permSetIds, permGrpIds, req, permIdByNameMap);
            User copyUser = (req.usrReq.UserToMirror__c != null ? eWrap.userToMirrorMap.get(req.usrReq.UserToMirror__c) : null);
            handleRequest(req, resp, userMap.get(req.ctct.HR_Person_Id__c), prof, role, updateUsers, insertUsers, copyUser, permSetIds, permGrpIds, newPsas);
         } else {
            resp.sur.Status__c=STATUS_ERROR;
         }
      } // for (RequestWrap req : reqs
      System.debug('processEmailRequests updateUsers='+updateUsers.size()+' insertUsers='+insertUsers.size()+' newPsas='+newPsas.size()+' delAdminMap='+delAdminMap.size());
      if (!updateUsers.isEmpty()) {
         //Database.SaveResult[] results = Database.update(updateUsers,false);
         Database.update(updateUsers);
      }
      if (!insertUsers.isEmpty()) {
         Database.SaveResult[] results = Database.insert(insertUsers,false);
         System.debug('processEmailRequests insertUsers results='+results);
      }
      for (PermissionSetAssignment psa : newPsas) {
         if (psa.Assignee.Id != null) {
            psa.AssigneeId = psa.Assignee.Id;
            psa.Assignee = null;
         }
      }
      if (!newPsas.isEmpty()) {
         Database.SaveResult[] results = Database.insert(newPsas,false);
         System.debug('processEmailRequests newPsas results='+results);
      }
      // look for delegated admin
      if (!delAdminMap.isEmpty()) {
         SetupDelgAdmin sda = new SetupDelgAdmin(eWrap, delAdminMap);
         System.enqueueJob(sda);

      }
      System.debug('processEmailReponses requestResponses='+requestResponses);
      return requestResponses;
   } // processEmailRequests
    
   public static void getPermSets(Set<Id> permSetIds, Set<Id> permGrpIds, RequestWrap req, Map<String,Set<Id>> permIdByNameMap) {
      System.debug('getPermSets req.usrReq.SandboxProfileSetup__c='+req.usrReq.SandboxProfileSetup__c);
      if (req.usrReq.SandboxProfileSetup__c != null) {
         if (permIdByNameMap.containsKey(PERMSET+req.usrReq.SandboxProfileSetup__c)) {
            permSetIds.addAll(permIdByNameMap.get(PERMSET+req.usrReq.SandboxProfileSetup__c));
         }
         if (permIdByNameMap.containsKey(PERMGRP+req.usrReq.SandboxProfileSetup__c)) {
            permGrpIds.addAll(permIdByNameMap.get(PERMGRP+req.usrReq.SandboxProfileSetup__c));
         }
      } // if (req.usrReq.SandboxProfileSetup__c != null
      System.debug('getPermSets req.usrReq.UserToMirror__c='+req.usrReq.UserToMirror__c);
      if (req.usrReq.UserToMirror__c != null) {
         if (permIdByNameMap.containsKey(PERMSET+req.usrReq.UserToMirror__c)) {
            permSetIds.addAll(permIdByNameMap.get(PERMSET+req.usrReq.UserToMirror__c));
         }
         if (permIdByNameMap.containsKey(PERMGRP+req.usrReq.UserToMirror__c)) {
            permGrpIds.addAll(permIdByNameMap.get(PERMGRP+req.usrReq.UserToMirror__c));
         }
      } // if (req.usrReq.UserToMirror__c != null
      System.debug('getPermSets permSetIds='+permSetIds.size()+' permGrpIds='+permGrpIds.size());
   } // getPermSets
    
   // get a map of the permission set/group ids
   public static Map<String,Set<Id>> getPermSetIdMap(Map<String,Set<String>> permSetNameMap, Set<String> permSetNames, Set<String> permGrpNames, Map<String,String[]> notFoundMap) {
      Map<String,Set<Id>> returnMap = new Map<String,Set<Id>>();
      PermissionSet[] permSets = (!permSetNames.isEmpty() ? [Select Id, Label from PermissionSet where Label in :permSetNames] : new PermissionSet[]{});
      PermissionSetGroup[] permGrps = (!permGrpNames.isEmpty() ? [Select Id, MasterLabel from PermissionSetGroup where MasterLabel in :permGrpNames] : new PermissionSetGroup[]{});
      System.debug('getPermSetIdMap permSetNameMap='+permSetNameMap.size()+' permSetNames='+permSetNames.size()+' permSets='+permSets.size()+' permGrpNames='+permGrpNames.size()+' permGrps='+permGrps.size());
      Map<String,Id> permIdByNameMap = new Map<String,Id>();
      for (PermissionSet permSet : permSets) {
         permIdByNameMap.put(permSet.Label, permSet.Id);
      }
      for (PermissionSetGroup grp : permGrps) {
         permIdByNameMap.put(grp.MasterLabel, grp.Id);
      }
      for (String key : permSetNameMap.keySet()) {
         Set<String> permSet = permSetNameMap.get(key);
         System.debug('getPermSetIdMap key='+key+' permSet='+permSet);
         if (permSet != null) {
            Set<Id> permIdSet = new Set<Id>();
            String[] notFound = new String[]{};
            for (String permName : permSet) {
               if (permIdByNameMap.containsKey(permName)) {
                  permIdSet.add(permIdByNameMap.get(permName));
               } else {
                  notFound.add(permName);
               }
            } // for (String permName
            returnMap.put(key,permIdSet);
            notFoundMap.put(key,notFound);
         }
      } // for (String key : permSetNameMap.keySet
      System.debug('getPermSetIdMap returnMap='+returnMap.size()+' notFoundMap='+notFoundMap.size());
      return returnMap;
   } // getPermSetIdMap
    
   public static final String STATUS_SUCCESS='Success';
   public static final String STATUS_ERROR='Error';
    
   public static void handleRequest(RequestWrap req, ResponseDetail resp, User usr, Profile prof, UserRole role
                                   ,User[] updateUsers, User[] insertUsers, User copyUsr
                                   ,Set<Id> permSetIds, Set<Id> permGrpIds, PermissionSetAssignment[] newPsas) {
      String[] notes = new String[]{'Existing user record found='+(usr != null)};
      System.debug('handleRequest usr='+(usr != null ? usr.FirstName+' '+usr.LastName : 'Not Found'));
      if (usr != null) {
         Boolean changed = false;
         // compare the current attributes
         if (!usr.IsActive) {
            usr.IsActive=true;
            notes.add('Changed user to Active');
         }
         if (usr.Email != req.ctct.Email) {
            notes.add('Changed email from '+usr.Email+' to '+req.ctct.Email);
            usr.Email = req.ctct.Email;
         }
         if (usr.ProfileId != prof.Id) {
            notes.add('Changed profile from '+usr.Profile.Name+' to '+prof.Name);
            usr.ProfileId = prof.Id;
         }
         if (usr.UserRoleId != role.Id) {
            notes.add('Changed role from '+usr.UserRole.Name+' to '+role.Name);
            usr.UserRoleId = role.Id;
         }
         if (String.isNotBlank(req.ctct.Title) && usr.Title != req.ctct.Title) {
            notes.add('Changed Title from '+usr.Title+' to '+req.ctct.Title);
            usr.Title = req.ctct.Title;
         }
         if (String.isNotBlank(req.ctct.Department) && usr.Department != req.ctct.Department) {
            notes.add('Changed Department from '+usr.Department+' to '+req.ctct.Department);
            usr.Department = req.ctct.Department;
         }
         if (notes.size() > 1) {
            updateUsers.add(usr);
         } else {
            notes.add('No Changes made to existing user');
         }
      } else {
         notes.add('Creating a new user with Profile='+prof.Name+' and Role='+role.Name);
         // create a new user
         NewUserExtension nue = new NewUserExtension();
         nue.newUser.Email = req.ctct.Email;
         nue.createUserFromContact(nue.newUser,req.ctct);
         nue.newUser.Sales_Org__c='Paychex';
         nue.newUser.ProfileId = prof.Id;
         nue.newUser.UserRoleId = role.Id;
         nue.newUser.Creation_Type__c='SandboxRequest';
         new AddUserController().setDefaultLocale(nue.newUser);
         usr = nue.newUser;
         System.debug('handleRequest usr='+usr);
         insertUsers.add(nue.newUser);
      } // if (usr != null
      req.usr = usr;
      if (usr != null) {
         for (Id permSetId : permSetIds) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId=permSetId, Assignee=usr);
            newPsas.add(psa);
         }
         for (Id permGrpId : permGrpIds) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetGroupId=permGrpId, Assignee=usr);
            newPsas.add(psa);
         }
         notes.add('Permission Set Assignments='+newPsas.size());
      } // if (usr != null
      //resp.processNotes += ('\n'+String.join(notes,'\n')); 
      resp.sur.ProcessNotes__c += ('\n'+String.join(notes,'\n')); 
      System.debug('handleRequest usr='+(usr != null)+' newPsas='+newPsas.size());
      resp.sur.Status__c=STATUS_SUCCESS;
   } // handleRequest
    
   // handle the response back from the sandbox after the setup
   public static void handleEmailResponse(String emailBody) {
      ResponseWrap response =  (ResponseWrap)json.deserialize(emailBody, ResponseWrap.class);
      SandboxUserRequest__c[] updateRecs = new SandboxUserRequest__c[]{};
      for (ResponseDetail detail : response.responses) {
         SandboxUserRequest__c rec = detail.sur;
         rec.Id = rec.RecordId__c;
             //new SandboxUserRequest__c(Id=detail.recId, Status__c=detail.status, ProcessNotes__c=detail.processNotes);
        updateRecs.add(rec);
      }
      System.debug('handleEmailResponse response='+response.responses.size()+' updateRecs='+updateRecs.size());
      DmlHelper.performDML2(updateRecs, DmlHelper.DML_UPDATE, CLASSNAME, 'handleResponse', 'Update responses', true);

   } // handleEmailResponse

   // for testing purposes only
   public static Integer testNbrCallouts = 0;
   public static String QUEUEABLE_NAME='SandboxRequestQueueable';

   public class SetupDelgAdmin implements Queueable,Database.AllowsCallouts {
      public EmailWrap eWrap;
      public Map<String,RequestWrap[]> delAdminMap;
      public ResponseDetail[] responses = new ResponseDetail[]{};
       
      public SetupDelgAdmin(EmailWrap p_eWrap, Map<String,RequestWrap[]> p_delAdminMap) {
         eWrap = p_eWrap;
         delAdminMap = p_delAdminMap;
      } // SetupDelgAdmin
      
      public void execute(QueueableContext context) {
         Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(QUEUEABLE_NAME);
         // how many callouts can we do in a transaction?
         Integer maxCallouts = (abc != null && abc.BatchSize__c != null ? abc.BatchSize__c.intValue() : 20);
         String[] adminNames = new String[]{};
         adminNames.addAll(delAdminMap.keySet());
         Integer nbrCallouts = 0;
         for (String adminName : adminNames) {
            // remove from the map because we're processing them.
            RequestWrap[] reqs = delAdminMap.remove(adminName);
            if (reqs != null && !reqs.isEmpty()) {
               String groupId = DelegatedAdminSetup.getDelegateGroupId(adminName);
               nbrCallouts++;
               while (!reqs.isEmpty() && nbrCallouts < maxCallouts) {
                  // remove them from the list so we know they're processed
                  RequestWrap req = reqs.remove(0);
                  ResponseDetail resp = new ResponseDetail();
                  responses.add(resp);
                  resp.sur.RecordId__c = req.usrReq.Id;
                  resp.sur.DelegatedGroup__c = adminName;
                  if (String.isBlank(groupId)) {
                     // if the group wasn't found
                     resp.sur.DelegatedGroupDetail__c = 'Could not find '+adminName;
                  } else if (req.usr == null || req.usr.Id == null) {
                     resp.sur.DelegatedGroupDetail__c = 'No active user record found';
                  } else {
                     resp.sur.DelegatedGroupDetail__c = DelegatedAdminSetup.addToDelegateGroup(groupId, req.usr.Id);
                     nbrCallouts++;
                  }
               } // while
               System.debug('execute reqs='+reqs.size()+' nbrCallouts='+nbrCallouts+' maxCallouts='+maxCallouts);
               if (!reqs.isEmpty()) {
                  delAdminMap.put(adminName, reqs);
               }
            } // if (reqs != null
            // if we reached our max number then respawn.
            if (nbrCallouts >= maxCallouts) {
               break;
            }
         } // for (String adminName 
         testNbrCallouts = nbrCallouts;
         if (!delAdminMap.isEmpty()) {
            SetupDelgAdmin sda = new SetupDelgAdmin(eWrap, delAdminMap);
            sda.responses = responses;
            System.enqueueJob(sda);
         } else {
            // email the results back
            SandboxRequest.emailResponse(eWrap,responses);
         }
      } // execute
       

   } // SetupDelgAdmin
        
} // class SandboxRequest