/* Test methods for SandboxRequest and SandboxRequestEmailHandler
        
  
           
  History
  -------
  02/22/2024 Dan Carmen      Created
  05/16/2024 Dan Carmen      Fix resend method

 */
@isTest
public class SandboxRequestTest {

   @testSetup
   public static void setupData() {
      SandboxSetup__c sand1 = new SandboxSetup__c(Name='Sandbox1', Active__c=true, Description__c='Sandbox Number 1', EmailToSendRequests__c='test1@paychex.com');
      SandboxSetup__c sand2= new SandboxSetup__c(Name='Sandbox2', Active__c=true, Description__c='Sandbox Number 2', EmailToSendRequests__c='test2@paychex.com');
      insert new SandboxSetup__c[]{sand1,sand2};
          
      // select a user, but not the running user
      User userToMirror = [Select Id, Name from User where IsActive=true and Id != :UserInfo.getUserId() and Profile.Name='System Administrator' limit 1];
      SandboxProfileSetup__c prof1a = new SandboxProfileSetup__c(Name='System Admin', Description__c='System Admin', Active__c=true, ProfileName__c=null, RoleName__c=null
                                                                ,UserToMirror__c=userToMirror.Id, PermissionSetGroupList__c='A Bad Group Name'
                                                                ,PermissionSetList__c='NotAReal1,AlsoNotReal', SandboxSetup__c=sand1.Id);
      SandboxProfileSetup__c prof1b = new SandboxProfileSetup__c(Name='Sales Enablement', Description__c='Sales Enablement', Active__c=true, ProfileName__c='Sales Enablement'
                                                                ,RoleName__c='System Administrator',SandboxSetup__c=sand1.Id);
      SandboxProfileSetup__c prof2a = new SandboxProfileSetup__c(Name='System Admin', Description__c='System Admin', Active__c=true, ProfileName__c=null, RoleName__c=null
                                                                ,UserToMirror__c=userToMirror.Id, PermissionSetGroupList__c='A Bad Group Name'
                                                                ,PermissionSetList__c='NotAReal1,AlsoNotReal', SandboxSetup__c=sand2.Id);
      SandboxProfileSetup__c prof2b = new SandboxProfileSetup__c(Name='Sales Enablement', Description__c='Sales Enablement', Active__c=true, ProfileName__c='Sales Enablement'
                                                                ,RoleName__c='System Administrator',SandboxSetup__c=sand2.Id);
      insert new SandboxProfileSetup__c[]{prof1a,prof1b,prof2a,prof2b};
   } // setupData

   static testMethod void testSubmission() {
      User runningUser = UserHelper.getRunningUser();
      Account acct = new Account(Name='Paychex Inc SA');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
       
      User[] testUsers = [Select Id, FirstName, LastName, Email, Title, Department, ProfileId, UserRoleId, HR_Person_Id__c
                            From User
                           Where IsActive=false
                             and Job_Name__c=:UserHelper.JOB_REP
                             and HR_Person_Id__c != null 
                           limit 2];
      User usr2 = testUsers[0];
      User usr3 = testUsers[1];
      System.debug('testSubmission usr2='+usr2.FirstName+' '+usr2.LastName+' usr3='+usr3.FirstName+' '+usr3.LastName);
      Contact ctct1 = new Contact(AccountId=acct.Id, FirstName='Test', LastName='Contact1', Title='Title', Department='Department', HR_Person_Id__c='1', Email='test1@testing.com');
      Contact ctct2 = new Contact(AccountId=acct.Id, FirstName=usr2.FirstName, LastName=usr2.LastName, Title='Title2', Department='Department2'
                                  , HR_Person_Id__c=usr2.HR_Person_Id__c, Email=usr2.Email);
      Contact ctct3 = new Contact(AccountId=acct.Id, FirstName=usr3.FirstName, LastName=usr3.LastName, Title='Title3', Department='Department3'
                                  , HR_Person_Id__c=usr3.HR_Person_Id__c, Email=usr3.Email);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
          
      SandboxRequest sr = new SandboxRequest();
      Assert.isFalse(sr.isGuestUser, 'Result is '+sr.isGuestUser);
      Assert.isTrue(sr.isSystemAdmin, 'Result is '+sr.isSystemAdmin);
      Assert.areEqual(2,sr.sandboxes.size());
      Assert.areEqual(3,sr.sandboxOptions.size());
      Assert.areEqual('Sandbox User Request',sr.blockTitle);
       
      SandboxSetup__c sandbx = sr.sandboxes[0];
      sr.sandboxOption=sr.sandboxes[0].Id;
      sr.usrRequest.RequestorEmail__c=ctct1.Email;
      sr.usrRequest.NbrOfUsers__c=2;
      Assert.areEqual(sr.stepName,'Step1');
      sr.setSelectedSandbox();
      // should stay at step1 because the email doesn't match up to a contact
      Assert.areEqual(sr.stepName,'Step1');
      // insert the contacts so it should pass
      insert new Contact[]{ctct1,ctct2,ctct3};
      sr.setSelectedSandbox();
      Assert.areEqual(sr.stepName,'Step2');
      Assert.areEqual('Sandbox1 User Request',sr.blockTitle);
      // there's one more setup than we entered because we add a "manual" row
      Assert.areEqual(3,sr.profileSetups.size());
      Assert.areEqual(4,sr.profileOptions.size());

      SandboxProfileSetup__c profSetup = sr.profileSetups[0];
      sr.profileOption=sr.profileSetups[0].Id;
      sr.setSelectedProfile();
      Assert.areEqual(sr.stepName,'Step3');
      Assert.areEqual(2,sr.requests.size());
       
      sr.requests[0].usrReq.SandboxUserEmail__c=ctct2.Email;
      sr.requests[1].usrReq.SandboxUserEmail__c=ctct3.Email;
      sr.verifyEmails();
      Assert.areEqual(sr.stepName,'Step4');
      sr.submitRequests();
      Assert.areEqual(sr.stepName,'Step1');

      SandboxRequest.EmailWrap eWrap = new SandboxRequest.EmailWrap();
      eWrap.requests = sr.requests;
      SandboxUserRequest__c req1 = eWrap.requests[0].usrReq;
      Assert.areEqual(ctct1.Id, req1.RequestorContact__c);
      Assert.areEqual(sandbx.Id, req1.SandboxSetup__c);
      Assert.areEqual(profSetup.Id, req1.SandboxProfileSetup__c);
      Assert.areEqual(ctct2.Id, req1.SandboxUserContact__c);
       
      SandboxUserRequest__c req2 = eWrap.requests[1].usrReq;
      Assert.areEqual(ctct1.Id, req2.RequestorContact__c);
      Assert.areEqual(sandbx.Id, req2.SandboxSetup__c);
      Assert.areEqual(profSetup.Id, req2.SandboxProfileSetup__c);
      Assert.areEqual(ctct3.Id, req2.SandboxUserContact__c);

      eWrap.returnEmail = 'test@paychex.com';
      String emailBody = json.serialize(eWrap).replace('number_Z','number')+SandboxRequest.emailTail;

      Messaging.Inboundemail email = new Messaging.Inboundemail();
      email.subject = SandboxRequest.requestSubject;
      email.plainTextBody = emailBody;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      SandboxRequestEmailHandler sreh = new SandboxRequestEmailHandler();
      System.runAs(runningUser) {
         sreh.handleInboundEmail(email, env);
      }
 
      User checkUsr2 = [Select Id, FirstName, LastName, Email, Title, Department
                              ,ProfileId, Profile.Name, UserRoleId, UserRole.Name
                              ,HR_Person_Id__c, IsActive
                          From User where Id=:usr2.Id];
      System.debug('testSubmission checkUsr2='+checkUsr2);
      Assert.isTrue(checkUsr2.IsActive);
      Assert.areEqual('Sales Enablement', checkUsr2.Profile.Name);
      Assert.areEqual('System Administrator', checkUsr2.UserRole.Name);
      Assert.areEqual(ctct2.Title, checkUsr2.Title);
      Assert.areEqual(ctct2.Department, checkUsr2.Department);
       
      User checkUsr3 = [Select Id, FirstName, LastName, Email, Title, Department
                              ,ProfileId, Profile.Name, UserRoleId, UserRole.Name
                              ,HR_Person_Id__c, IsActive
                          From User where Id=:usr3.Id];
      System.debug('testSubmission checkUsr3='+checkUsr3);
      Assert.isTrue(checkUsr3.IsActive);
      Assert.areEqual('Sales Enablement', checkUsr3.Profile.Name);
      Assert.areEqual('System Administrator', checkUsr3.UserRole.Name);
      Assert.areEqual(ctct3.Title, checkUsr3.Title);
      Assert.areEqual(ctct3.Department, checkUsr3.Department);

      SandboxRequest.ResponseDetail resp1 = new SandboxRequest.ResponseDetail();
      resp1.sur.RecordId__c=req1.Id;
      resp1.sur.Status__c=SandboxRequest.STATUS_SUCCESS;
      resp1.sur.SandboxName__c='testsandbox';
      resp1.sur.ProcessNotes__c='Response 1 Notes';

      SandboxRequest.ResponseDetail resp2 = new SandboxRequest.ResponseDetail();
      resp2.sur.RecordId__c=req2.Id;
      resp2.sur.Status__c=SandboxRequest.STATUS_SUCCESS;
      resp2.sur.SandboxName__c='testsandbox';
      resp2.sur.ProcessNotes__c='Response 2 Notes';
      
      SandboxRequest.ResponseWrap resp = new SandboxRequest.ResponseWrap();
      resp.responses = new SandboxRequest.ResponseDetail[]{resp1,resp2};
      String returnEmailBody = json.serialize(resp).replace('number_Z','number')+SandboxRequest.emailTail;

      Messaging.Inboundemail respEmail = new Messaging.Inboundemail();
      respEmail.subject = SandboxRequest.responseSubject;
      respEmail.plainTextBody = returnEmailBody;
      env = new Messaging.InboundEnvelope();
      sreh = new SandboxRequestEmailHandler();
      sreh.handleInboundEmail(respEmail, env);
      Map<Id,SandboxUserRequest__c> reqMap = new Map<Id,SandboxUserRequest__c>([Select Id, Name, Status__c, ProcessNotes__c
                                                                                  From SandboxUserRequest__c]);
      Assert.areEqual(2,reqMap.size());
      SandboxUserRequest__c check1 = reqMap.get(req1.Id);
      Assert.areEqual(SandboxRequest.STATUS_SUCCESS,check1.Status__c);
      Assert.areEqual('Response 1 Notes', check1.ProcessNotes__c);
       
      SandboxUserRequest__c check2 = reqMap.get(req2.Id);
      Assert.areEqual(SandboxRequest.STATUS_SUCCESS,check2.Status__c);
      Assert.areEqual('Response 2 Notes', check2.ProcessNotes__c);

      SandboxUserRequest__c resend1 = new SandboxUserRequest__c(Id=check1.Id, Resend__c=true);
      update resend1;
   } // testSubmission
    
   static testMethod void testNewWithPermSets() {
      User runningUser = UserHelper.getRunningUser();
      Account acct = new Account(Name='Paychex Inc SA');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
       
      SandboxProfileSetup__c prof1 = [Select Id, Name, Description__c, Active__c, ProfileName__c, RoleName__c
                                            ,UserToMirror__c, PermissionSetGroupList__c, PermissionSetList__c
                                        From SandboxProfileSetup__c
                                       Where Name='System Admin' limit 1];
      /*
      User[] testUsers = [Select Id, FirstName, LastName, Email, Title, Department, ProfileId, UserRoleId, HR_Person_Id__c
                                ,Profile.Name, UserRole.Name
                            From User
                           Where IsActive=false
                             and Job_Name__c=:UserHelper.JOB_REP
                             and HR_Person_Id__c != null 
                           limit 1];
      User usr2 = testUsers[0];
      System.debug('testSubmission usr2='+usr2.FirstName+' '+usr2.LastName);
      */
      Contact ctct1 = new Contact(AccountId=acct.Id, FirstName='Sammy', LastName='Contact1', Title='Title', Department='Department', HR_Person_Id__c='1', Email='test1@testing.com');
      Contact ctct2 = new Contact(AccountId=acct.Id, FirstName='Laura', LastName='Contact2', Title='Title', Department='Department', HR_Person_Id__c='8675309', Email='test2@testing.com');
      //Contact ctct2 = new Contact(AccountId=acct.Id, FirstName=usr2.FirstName, LastName=usr2.LastName, Title='Title2', Department='Department2'
      //                            , HR_Person_Id__c=usr2.HR_Person_Id__c, Email=usr2.Email);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert new Contact[]{ctct1,ctct2};
          
      SandboxRequest sr = new SandboxRequest();
      Assert.isFalse(sr.isGuestUser, 'Result is '+sr.isGuestUser);
      Assert.isTrue(sr.isSystemAdmin, 'Result is '+sr.isSystemAdmin);
      Assert.areEqual(2,sr.sandboxes.size());
      Assert.areEqual(3,sr.sandboxOptions.size());
      Assert.areEqual('Sandbox User Request',sr.blockTitle);
       
      SandboxSetup__c sandbx = sr.sandboxes[0];
      sr.sandboxOption=sr.sandboxes[0].Id;
      sr.usrRequest.RequestorEmail__c=ctct1.Email;
      sr.usrRequest.NbrOfUsers__c=1;
      sr.setSelectedSandbox();
      Assert.areEqual(sr.stepName,'Step2');
      Assert.areEqual('Sandbox1 User Request',sr.blockTitle);
      // there's one more profile setup than we entered because we add a "manual" row
      Assert.areEqual(3,sr.profileSetups.size());
      Assert.areEqual(4,sr.profileOptions.size());

      sr.profileOption=prof1.Id;
      sr.setSelectedProfile();
      Assert.areEqual(sr.stepName,'Step3');
      Assert.areEqual(1,sr.requests.size());
       
      sr.requests[0].usrReq.SandboxUserEmail__c=ctct2.Email;
      sr.verifyEmails();
      Assert.areEqual(sr.stepName,'Step4');
      sr.submitRequests();
      Assert.areEqual(sr.stepName,'Step1');

      SandboxRequest.EmailWrap eWrap = sr.testEWrap;
      Assert.areEqual(1,eWrap.requests.size());
      SandboxUserRequest__c req1 = eWrap.requests[0].usrReq;
      Assert.areEqual(ctct1.Id, req1.RequestorContact__c);
      Assert.areEqual(sandbx.Id, req1.SandboxSetup__c);
      Assert.areEqual(prof1.Id, req1.SandboxProfileSetup__c);
      Assert.areEqual(ctct2.Id, req1.SandboxUserContact__c);
      Assert.areEqual(1,eWrap.setupMap.size());
      Assert.areEqual(1,eWrap.userToMirrorMap.size());
       

      eWrap.returnEmail = 'test@paychex.com';
      String emailBody = json.serialize(eWrap).replace('number_Z','number')+SandboxRequest.emailTail;

      Messaging.Inboundemail email = new Messaging.Inboundemail();
      email.subject = SandboxRequest.requestSubject;
      email.plainTextBody = emailBody;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      SandboxRequestEmailHandler sreh = new SandboxRequestEmailHandler();
      System.runAs(runningUser) {
         sreh.handleInboundEmail(email, env);
      }
 
      User checkUsr2 = [Select Id, FirstName, LastName, Email, Title, Department
                              ,ProfileId, Profile.Name, UserRoleId, UserRole.Name
                              ,HR_Person_Id__c, IsActive
                          From User where HR_Person_Id__c=:ctct2.HR_Person_Id__c];
      System.debug('testSubmission checkUsr2='+checkUsr2);
      Assert.isTrue(checkUsr2.IsActive);
      Assert.areEqual('System Administrator', checkUsr2.Profile.Name);
      Assert.areEqual('System Administrator', checkUsr2.UserRole.Name);
      Assert.areEqual(ctct2.Title, checkUsr2.Title);
      Assert.areEqual(ctct2.Department, checkUsr2.Department);
       

      SandboxRequest.ResponseDetail resp1 = new SandboxRequest.ResponseDetail();
      resp1.sur.RecordId__c=req1.Id;
      resp1.sur.Status__c=SandboxRequest.STATUS_SUCCESS;
      resp1.sur.SandboxName__c='testsandbox';
      resp1.sur.ProcessNotes__c='Response 1 Notes';
      
      SandboxRequest.ResponseWrap resp = new SandboxRequest.ResponseWrap();
      resp.responses = new SandboxRequest.ResponseDetail[]{resp1};
      String returnEmailBody = json.serialize(resp).replace('number_Z','number')+SandboxRequest.emailTail;

      Messaging.Inboundemail respEmail = new Messaging.Inboundemail();
      respEmail.subject = SandboxRequest.responseSubject;
      respEmail.plainTextBody = returnEmailBody;
      env = new Messaging.InboundEnvelope();
      sreh = new SandboxRequestEmailHandler();
      sreh.handleInboundEmail(respEmail, env);
      Map<Id,SandboxUserRequest__c> reqMap = new Map<Id,SandboxUserRequest__c>([Select Id, Name, Status__c, ProcessNotes__c
                                                                                  From SandboxUserRequest__c]);
      Assert.areEqual(1,reqMap.size());
      SandboxUserRequest__c check1 = reqMap.get(req1.Id);
      Assert.areEqual(SandboxRequest.STATUS_SUCCESS,check1.Status__c);
      Assert.areEqual('Response 1 Notes', check1.ProcessNotes__c);
       
   } // testNewWithPermSets
    
    static testMethod void testDelegatedGrps() {
       User[] usrs = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
       User usr1 = usrs[0];
       User usr2 = usrs[1];
       String jobName='All Sales';
       String jobNameId='02f0g000000CfQsAAK';
       DelegatedAdminSetup.testGroupId=jobNameId;
       DelegatedAdminSetup.useTestGrpId=true;
        
       SandboxRequest.EmailWrap eWrap = new SandboxRequest.EmailWrap();
       eWrap.returnEmail = 'test@testing.com';
        
       SandboxRequest.RequestWrap rWrap1 = new SandboxRequest.RequestWrap();
       rWrap1.usrReq = new SandboxUserRequest__c();
       rWrap1.usr = usr1;
       SandboxRequest.RequestWrap rWrap2 = new SandboxRequest.RequestWrap();
       rWrap2.usrReq = new SandboxUserRequest__c();
       rWrap2.usr = usr2;
       SandboxRequest.RequestWrap[] rWraps = new SandboxRequest.RequestWrap[]{rWrap1,rWrap2};
          
       Map<String,SandboxRequest.RequestWrap[]> reqWrapMap = new Map<String,SandboxRequest.RequestWrap[]>();
       reqWrapMap.put(jobName,rWraps);
        
       DelegatedAdminSetup.testGrpMemberMsg='Added to Group Successfully';
       Test.startTest();
       SandboxRequest.SetupDelgAdmin sda = new SandboxRequest.SetupDelgAdmin(eWrap,reqWrapMap);
       System.enqueueJob(sda);
       Test.stopTest();
       Assert.isTrue(SandboxRequest.emailSent);
       Assert.areEqual(3,SandboxRequest.testNbrCallouts);
    } // testDelegatedGrps
    
} // class SandboxRequestTest