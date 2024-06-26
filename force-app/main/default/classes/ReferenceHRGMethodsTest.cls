/* 
  Test methods for the ReferenceHRGMethods class.
   
  History
  -------
  08/02/2013 Dan Carmen   Created
  04/19/2016 Jacob Hinds  Update owner of onboarding record when account HRG changes.
   
 */
@isTest
private class ReferenceHRGMethodsTest {

   static testMethod void testRefHRGUpdate() {
   	// grab a bunch of users
   	User[] users = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' limit 6];
   	
   	Account acct = new Account(Name='Test Acct');
   	insert acct;
   	
      // test the ownership update
      Reference_HRG__c ref1 = new Reference_HRG__c(Account__c=acct.Id, OwnerId = users[0].Id, HRS_Account_Owner__c=users[1].Id
                                     ,Onboarding_Start_Date__c=Date.today());
      insert ref1;
      
      ReferenceHRGMethods.RefHrgUsers rhu1 = new ReferenceHRGMethods.RefHrgUsers();
      rhu1.accountId = ref1.Account__c;
      rhu1.ownerId = users[2].Id;
      rhu1.hrsSalesRepId = users[3].Id;
      
      ReferenceHRGMethods.RefHrgUsers[] rhus = new ReferenceHRGMethods.RefHrgUsers[]{rhu1};
      ReferenceHRGMethods.checkReferenceHrgs(rhus);
      
      ref1 = [Select Id, Account__c, OwnerId, HRS_Account_Owner__c from Reference_HRG__c where Id=:ref1.Id];
      System.assertEquals(ref1.OwnerId, users[2].Id);
      System.assertEquals(ref1.HRS_Account_Owner__c, users[3].Id);
   } // testRefHRGUpdate
   
   static testMethod void testUpdateSurveyDate() {
      // create an account
      Account acct = new Account(Name='Test acct');
      insert acct;
      
      // create the reference object 
      Reference_HRG__c ref1 = new Reference_HRG__c(Account__c=acct.Id, Onboarding_Start_Date__c=Date.today());
      insert ref1;
      ref1 = [Select Id, Account__c, NCSurveyCase__c, NCSurveyDate__c from Reference_HRG__c where Id = :ref1.Id];
      System.assertEquals(null,ref1.NCSurveyCase__c);
      System.assertEquals(null,ref1.NCSurveyDate__c);
      
      // get the record type id
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(ReferenceHRGMethods.RT_PREMIER_SURVEY, 'Case');
      // create a survey alert case
      Case c1 = new Case(AccountId = acct.Id, Origin=ReferenceHRGMethods.SURVEY_CASE_ORIGIN, RecordTypeId = rt.getRecordTypeId());
      insert c1;
      
      // reference object should be updated
      ref1 = [Select Id, Account__c, NCSurveyCase__c, NCSurveyDate__c from Reference_HRG__c where Id = :ref1.Id];
      System.assertEquals(c1.Id,ref1.NCSurveyCase__c);
      System.assertEquals(Date.today(),ref1.NCSurveyDate__c);

   } // testUpdateSurveyDate
   static testMethod void testUpdateHRG() {
   	User[] users = [Select Id, FirstName, LastName, HR_Person_Id__c from User where IsActive=true and Profile.Name='System Administrator' limit 2];
      // create an account
      Account acct = new Account(Name='Test acct');
      insert acct;
     
      Contact ctct2 = new Contact(FirstName=users[1].FirstName,LastName=users[1].LastName,HR_Person_Id__c=users[1].HR_Person_Id__c, User_Lookup__c=users[1].id);
      insert ctct2;
     
      Test.startTest();
    
	      // create the reference object 
	      Reference_HRG__c ref1 = new Reference_HRG__c(Account__c=acct.Id, Onboarding_Start_Date__c=Date.today(),OwnerId = users[0].id);
	      insert ref1;
	      ref1 = [Select Id, Account__c, OwnerId from Reference_HRG__c where Id = :ref1.Id];
	      System.assertEquals(users[0].Id,ref1.OwnerId);

		  //update hrg on the account
		  acct.HR_Generalist__c = ctct2.Id;
		  update acct;
		  
	      // reference object should be updated
	      Reference_HRG__c ref2 = [Select Id, Account__c, OwnerId from Reference_HRG__c where Id = :ref1.Id];
	      System.assertEquals(users[1].Id,ref2.OwnerId);
      Test.stopTest();
      

   } // testUpdateSurveyDate
   
} // class ReferenceHRGMethodsTest