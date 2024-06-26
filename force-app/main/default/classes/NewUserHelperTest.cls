/* Test methods for the NewUserHelper class
   
   History
   -------
   04/24/2024 Dan Carmen   Created
  
 */
@isTest
public class NewUserHelperTest {
    
    static testMethod void testRequests() {
       NewUserHelper.userRequestEmail='test@test.com';
       // queueable won't fire here because we're not setting up the Apex Batch Control record
       User usrReactivate = [Select Id, FirstName, LastName, Email, HR_Person_Id__c, Title, Department
                               from User where Job_Name__c=:UserHelper.JOB_REP and IsActive=false limit 1];
       User[] usrStandards = [Select Id, FirstName, LastName, Email, HR_Person_Id__c, Title, Department
                                from User where Job_Name__c=:UserHelper.JOB_REP and IsActive=true limit 3];
       User usrStandard = usrStandards[0];
       User usrChatter = usrStandards[1];
       User usrMirror = usrStandards[2];
       // create contact records to use in the request.
       Contact ctctInactive = new Contact(FirstName=usrReactivate.FirstName, LastName=usrReactivate.LastName, Title=usrReactivate.Title, Email=usrReactivate.Email
                                          ,Department=usrReactivate.Department, HR_Person_Id__c=usrReactivate.HR_Person_Id__c, User_Lookup__c=usrReactivate.Id);
       Contact ctctStandard = new Contact(FirstName=usrStandard.FirstName, LastName=usrStandard.LastName, Title=usrStandard.Title, Email=usrStandard.Email
                                          ,Department=usrStandard.Department, HR_Person_Id__c=usrStandard.HR_Person_Id__c, User_Lookup__c=usrStandard.Id);
       Contact ctctChatter = new Contact(FirstName=usrChatter.FirstName, LastName=usrChatter.LastName, Title=usrChatter.Title, Email=usrChatter.Email
                                          ,Department=usrChatter.Department, HR_Person_Id__c=usrChatter.HR_Person_Id__c, User_Lookup__c=usrChatter.Id);
       ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
       ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
       insert new Contact[]{ctctInactive,ctctStandard,ctctChatter};
           
       NewUserRequest__c req1 = new NewUserRequest__c(Requestor_Email__c='test@test.com', New_User_Email__c=ctctInactive.Email, Contact__c=ctctInactive.Id
                                                     ,Request_Type__c='Reactivate', SubmitRequest__c=true, Status__c='Pending', User__c=usrReactivate.Id);
       NewUserRequest__c req2 = new NewUserRequest__c(Requestor_Email__c='test@test.com', New_User_Email__c=ctctChatter.Email, Contact__c=ctctChatter.Id
                                                     ,Request_Type__c='Chatter Free User', SubmitRequest__c=true, Status__c='Pending'
                                                     ,User_to_Mirror__c=usrMirror.Id);
       NewUserRequest__c req3 = new NewUserRequest__c(Requestor_Email__c='test@test.com', New_User_Email__c=ctctStandard.Email, Contact__c=ctctStandard.Id
                                                     ,Request_Type__c='Standard User', SubmitRequest__c=true, Status__c='Pending', User__c=usrStandard.Id
                                                     ,User_to_Mirror__c=usrMirror.Id);
        
       insert new NewUserRequest__c[]{req1,req2,req3};
       String emailBody = NewUserHelper.emailBody;
        
       Assert.areEqual(0,[Select count() from NewUserRequest__c where SubmitRequest__c=true]);
       Assert.isTrue(emailBody.contains(req1.Id));
       Assert.isTrue(emailBody.contains(req2.Id));
       Assert.isTrue(emailBody.contains(req3.Id));
        
      Messaging.Inboundemail email = new Messaging.Inboundemail();
      email.subject = NewUserHelper.SUBJECT_REQUEST;
      email.plainTextBody = emailBody;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      NewUserEmailHandler nueh = new NewUserEmailHandler();
      nueh.handleInboundEmail(email, env);
      Assert.isTrue(NewUserEmailHandler.testIds.contains(req1.Id));
      Assert.isTrue(NewUserEmailHandler.testIds.contains(req2.Id));
      Assert.isTrue(NewUserEmailHandler.testIds.contains(req3.Id));
   } // testRequests
    
   static testMethod void testQueueableStandard() {
      NewUserHelper.userRequestEmail='test@test.com';
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='NewUserQueueable', Active__c=true);
      insert abc;
       
       User[] usrStandards = [Select Id, FirstName, LastName, Email, HR_Person_Id__c, Title, Department
                                    ,UserRoleId, ProfileId
                                from User where Job_Name__c=:UserHelper.JOB_REP and IsActive=true limit 2];
       User usrStandard = usrStandards[0];
       User usrMirror = usrStandards[1];
       // create contact records to use in the request.
       Contact ctctStandard = new Contact(FirstName=usrStandard.FirstName, LastName=usrStandard.LastName, Title=usrStandard.Title, Email=usrStandard.Email
                                          ,Department=usrStandard.Department, HR_Person_Id__c=usrStandard.HR_Person_Id__c, User_Lookup__c=usrStandard.Id);
       ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
       ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
       insert new Contact[]{ctctStandard};
           
       // setting CurrentIsNewUser__c so it will reuse the user record we connected.
       NewUserRequest__c req1 = new NewUserRequest__c(Requestor_Email__c='test@test.com', New_User_Email__c=ctctStandard.Email, Contact__c=ctctStandard.Id
                                                     ,Request_Type__c='Standard User', SubmitRequest__c=true, Status__c='Pending', User__c=usrStandard.Id
                                                     ,User_to_Mirror__c=usrMirror.Id, CurrentIsNewUser__c=true);
        
       insert new NewUserRequest__c[]{req1};
       String emailBody = NewUserHelper.emailBody;
        
       Assert.areEqual(0,[Select count() from NewUserRequest__c where SubmitRequest__c=true]);
       Assert.isTrue(emailBody.contains(req1.Id));
        
      Messaging.Inboundemail email = new Messaging.Inboundemail();
      email.subject = NewUserHelper.SUBJECT_REQUEST;
      email.plainTextBody = emailBody;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      NewUserEmailHandler nueh = new NewUserEmailHandler();
      Test.startTest();
      nueh.handleInboundEmail(email, env);
      Test.stopTest();
      Assert.isTrue(NewUserEmailHandler.testIds.contains(req1.Id));
      
      User checkUser = [Select Id, Name, UserRoleId, ProfileId, LastModifiedDate from User where Id=:usrStandard.Id];
      Assert.areEqual(usrMirror.ProfileId, checkUser.ProfileId);
      Assert.areEqual(usrMirror.UserRoleId, checkUser.UserRoleId);
      Datetime checkTime = Datetime.now().addMinutes(-5);
      Assert.isTrue(checkUser.LastModifiedDate > checkTime, 'checkUser LastModifiedDate='+checkUser.LastModifiedDate+' checkTime='+checkTime);
      
   } // testQueueableStandard
    
   static testMethod void testQueueableReactivate() {
      NewUserHelper.userRequestEmail='test@test.com';
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='NewUserQueueable', Active__c=true);
      insert abc;
       // queueable won't fire here because we're not setting up the Apex Batch Control record
       User usrReactivate = [Select Id, FirstName, LastName, Email, HR_Person_Id__c, Title, Department
                               from User where Job_Name__c=:UserHelper.JOB_REP and IsActive=false limit 1];
           
       NewUserRequest__c req1 = new NewUserRequest__c(Requestor_Email__c='test@test.com', New_User_Email__c=usrReactivate.Email
                                                     ,Request_Type__c='Reactivate', SubmitRequest__c=true, Status__c='Pending', User__c=usrReactivate.Id);
       insert new NewUserRequest__c[]{req1};
       String emailBody = NewUserHelper.emailBody;
        
       Assert.areEqual(0,[Select count() from NewUserRequest__c where SubmitRequest__c=true]);
       Assert.isTrue(emailBody.contains(req1.Id));
        
      Messaging.Inboundemail email = new Messaging.Inboundemail();
      email.subject = NewUserHelper.SUBJECT_REQUEST;
      email.plainTextBody = emailBody;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      NewUserEmailHandler nueh = new NewUserEmailHandler();
      Test.startTest();
      nueh.handleInboundEmail(email, env);
      Test.stopTest();
      Assert.isTrue(NewUserEmailHandler.testIds.contains(req1.Id));
        
      User checkUser = [Select Id, IsActive, Name, UserRoleId, ProfileId, LastModifiedDate from User where Id=:usrReactivate.Id];
      Assert.isTrue(checkUser.IsActive);
      Datetime checkTime = Datetime.now().addMinutes(-5);
      Assert.isTrue(checkUser.LastModifiedDate > checkTime, 'checkUser LastModifiedDate='+checkUser.LastModifiedDate+' checkTime='+checkTime);

      // test saving the request through the email service
      NewUserHelper.ReqWrap rWrap = new NewUserHelper.ReqWrap();
      rWrap.req = new NewUserRequest__c(Id=req1.Id);
      rWrap.req.Status__c = 'Complete';
      rWrap.req.ProcessNotes__c = 'These Are Process Notes';
      rWrap.newLicenseRequests = new Manage_Package_License__c[]{};
      // so we can test the save of this record
      Manage_Package_License__c addLicense = new Manage_Package_License__c();                    
      addLicense.User_Name__c = UserInfo.getUserId();
      addLicense.Request_Status__c = 'Submitted for Approval';
      addLicense.Requestor__c = UserInfo.getUserId();
      addLicense.Package_Name__c = 'Test Package';
      addLicense.Requested_Date__c = System.NOW();
      addLicense.Effective_Date__c = System.NOW();
      addLicense.OwnerId = UserInfo.getUserId();
      addLicense.Request_Type__c = 'Reactivate';
      rWrap.newLicenseRequests.add(addLicense);
       
      emailBody = json.serialize(rWrap).replace('number_Z','number')+NewUserHelper.emailTail;
      email = new Messaging.Inboundemail();
      email.subject = NewUserHelper.SUBJECT_SAVE;
      email.plainTextBody = emailBody;
      env = new Messaging.InboundEnvelope();
      nueh = new NewUserEmailHandler();
      nueh.handleInboundEmail(email, env);
       
      NewUserRequest__c checkReq = [Select Id, Status__c, ProcessNotes__c from NewUserRequest__c where Id=:req1.Id];
      Assert.areEqual('Complete',checkReq.Status__c);
      Assert.areEqual('These Are Process Notes',checkReq.ProcessNotes__c);
      Assert.areEqual(1,[Select count() from Manage_Package_License__c]);
   } // testQueueableReactivate
    
} // NewUserHelperTest