/** 
 * The test methods for the ReferenceMMSPayroll before and after triggers, and ReferenceMMSUpdate class.
 *
 * History
 * -------
 * 09/09/2013 Cindy Freeman	  Created
 * 11/27/2013 Cindy Freeman	  Added check of other account field updates (processMMSAccount)
   09/16/2016 Dan Carmen        Added in check for null person id
 *
 */
@isTest
private class ReferenceMMSUpdateTest {

    static testMethod void myUnitTest() {
       User u1 = [Select Id, HR_Person_Id__c from User where Id != :UserInfo.getUserId() 
       				and IsActive=true and Profile.Name='System Administrator' and HR_Person_Id__c != null limit 1];
       User u1HRG = [Select Id, HR_Person_Id__c from User where Id != :UserInfo.getUserId() 
       					and IsActive=true and Profile.Name='System Administrator' and HR_Person_Id__c != null and id != :u1.Id limit 1];
       User u1HRO = [Select Id, HR_Person_Id__c from User where Id != :UserInfo.getUserId() 
       					and IsActive=true and Profile.Name='System Administrator' and HR_Person_Id__c != null and id != :u1.Id and id != :u1HRG.Id  limit 1];
	   User u1MAM = [Select Id, HR_Person_Id__c from User where Id != :UserInfo.getUserId() 
	   					and IsActive=true and Profile.Name='System Administrator' and HR_Person_Id__c != null and id != :u1.Id and id != :u1HRG.Id and id != :u1HRO.Id limit 1];
       Group g1 = [Select Id from Group where Group.Name like 'MMS % - New Load Queue'  limit 1];
      
       // create Paychex contact rcd
       Schema.RecordTypeInfo acctSArt = RecordTypeHelper.getRecordType('System Administration Account', 'Account');
       Schema.RecordTypeInfo ctctSArt = RecordTypeHelper.getRecordType('Paychex Employee', 'Contact');        
       Account acct1 = new Account (name = 'Paychex Inc SA'
                                ,recordtypeId = acctSArt.getRecordTypeId()
                                ,type = 'Partner'
                                ,BillingPostalCode = '10000');
       insert acct1;
       Contact con1 = new Contact(Firstname = 'Joe'
                                ,Lastname = 'Paychex'
                                ,recordtypeId = ctctSArt.getRecordTypeId()
                                ,HR_Person_Id__c = u1.HR_Person_Id__c
                                ,AccountId=acct1.Id);
       insert con1;
       Contact con1HRG = new Contact(Firstname = 'HRG'
                                ,Lastname = 'Paychex'
                                ,recordtypeId = ctctSArt.getRecordTypeId()
                                ,HR_Person_Id__c = u1HRG.HR_Person_Id__c
                                ,AccountId=acct1.Id);
       insert con1HRG;
       Contact con1MAM = new Contact(Firstname = 'MAM'
                                ,Lastname = 'Paychex'
                                ,recordtypeId = ctctSArt.getRecordTypeId()
                                ,HR_Person_Id__c = u1MAM.HR_Person_Id__c
                                ,AccountId=acct1.Id);
       insert con1MAM;
       
       // create account
       Schema.RecordTypeInfo acctMMSrt = RecordTypeHelper.getRecordType('MMS Account Record Type', 'Account');
       Account acct2 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctMMSrt.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                //,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25
                                ,HR_Generalist__c = con1HRG.Id
                                ,HRO_Implementation_Coordinator__c = u1HRO.Id
                                ,MMS_MAM_NAM__c = con1MAM.Id);
       insert acct2;
        
       Object_Relationships__c objRelationship = CreateTestData.createRelatedObjectsCase();
       Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('Service Onboarding MMS Payroll Case', 'Case');
       // create a case - reference object should automatically be created by the trigger
       Case c = new Case(OwnerId = g1.Id, RecordTypeId = rt.getRecordTypeId(), AccountId = acct2.Id);
       insert c;      
       Reference_MMS_Payroll__c refmms = [Select Id, OwnerId, Case_Number__c from Reference_MMS_Payroll__c where Case_Number__c = :c.Id];
       System.assertEquals(g1.Id,refmms.OwnerId);
      
       // change ref obj owner from queue to user, case owner should change, acct.mms_as__c set to contact
       refmms.OwnerId = u1.Id;
       // change other fields to update account
       refmms.Assigned_Prospect_Client_Number__c = '400-1234';			// check validation rule: Assigned_Prospect_Client_Nbr_vaid_loc for valid values
       refmms.MyPaychex_com_Client__c = 'SSO Legacy';
       refmms.MyPaychex_com_Start_Date__c = System.today();
       
       Test.startTest();      
       update refmms;
       Test.stopTest();      
       c = [Select Id, OwnerId from Case where Id = :refmms.Case_Number__c];
       System.assertEquals(u1.Id,c.OwnerId);
       Account acct = [Select Id, MMS_AS__c, AccountNumber, MyPaychex_com_Client__c, MyPaychex_com_Start_Date__c from Account where Id = :acct2.Id];
       System.assertEquals(con1.Id, acct.MMS_AS__c);
       System.assertEquals(refmms.Assigned_Prospect_Client_Number__c, acct.AccountNumber);
       System.assertEquals(refmms.MyPaychex_com_Client__c, acct.MyPaychex_com_Client__c);
       System.assertEquals(refmms.MyPaychex_com_Start_Date__c, acct.MyPaychex_com_Start_Date__c);
              
       Reference_MMS_Payroll__c refmms2 = [Select Id, OwnerId, Case_Number__c, HRG__c, HRO_Onboarding__c, MMS_MAM_NAM__c
       										 from Reference_MMS_Payroll__c where Case_Number__c = :c.Id];
	   System.assertEquals(refmms2.HRG__c, con1HRG.Id);
	   System.assertEquals(refmms2.HRO_Onboarding__c, u1HRO.Id);
	   System.assertEquals(refmms2.MMS_MAM_NAM__c, con1MAM.Id);		       										 
 
    } // myUnitTest
}