/* 
 * Integration with FlexForward System
 *
 * History
 * -------
  05/29/2018 Jake Hinds         Created
  09/28/2023  Dan Carmen        Change for OP_WITH_INVALID_USER_TYPE_EXCEPTION
  04/04/2024 Susmitha Somavarapu Change an existing fields in SF/allow feed from Insite System into SF
  06/07/2024  Susmitha Somavarapu Commented out the createCase method since it's not actively called from Insite and SF(APR0171211).

*/

@istest
public class FFSServiceTest {
	//test createCase and getCaseDetail method
	static testMethod void testCreateGetComments(){
		Account acct1 = new Account(Name='test acct',BIS_ID__c = 12345,AccountNumber='123-456789');
		Account acct2 = new Account(Name='test acct2',BIS_ID__c = 54321,AccountNumber='987-654321');
		Account[] accts = new Account[]{acct1,acct2};
		insert accts;
		Contact ctct1 = new Contact(AccountId=acct1.Id,FirstName='test',LastName = 'ctct',Decision_Maker__c=true);
		Contact ctct2 = new Contact(AccountId=acct2.Id,FirstName='test2',LastName = 'ctct2',Decision_Maker__c=true);
		Contact[] ctcts = new Contact[]{ctct1,ctct2};
		insert ctcts;
		
		User u = [SELECT Id,email FROM user WHERE IsActive = true AND email!=null and Job_Name__c=:UserHelper.JOB_REP LIMIT 1];
		Group[] queues = [select Id,Name from Group where Type = 'Queue' AND (NAME = 'Data Integrity Queue' OR Name ='Preview CSR Supervisor') LIMIT 2];
        Id diq;
        Id pcsq;
        for(Group q:queues){
        	if(q.Name == 'Data Integrity Queue'){
        		diq = q.Id;
        	}
        	else if (q.Name == 'Preview CSR Supervisor'){
        		pcsq = q.Id;
        	}
        }
		
		Test.startTest();
        //BU no longer using createCase records logic, so commenting out the code based on this APR0171211-Sush
		/*FFSService.CaseRecord cr1 = new FFSService.CaseRecord();
		cr1.CaseId = '';
		cr1.BisID = String.valueOf(acct1.BIS_ID__c);
		cr1.ClientName = acct1.Name;
		cr1.ClientNumber = acct1.AccountNumber;
		cr1.FlexFirstRunDate = date.today();
		cr1.MigrationContactName = 'Tester Guy';
		cr1.Subject = 'Client Going Lost';
		cr1.GoingLostDescription = 'Too Expensive';
		cr1.CSRUsername = u.email.substringBefore('@').left(8);
		cr1.FlagName = '';
		cr1.FlagComments = '';
		cr1.Error = ''; 
		
		//this one should work on bisId alone
		FFSService.CaseRecord cr2 = new FFSService.CaseRecord();
		cr2.CaseId = '';
		cr2.BisID = String.valueOf(acct1.BIS_ID__c);
		cr2.ClientName = acct1.Name;
		cr2.ClientNumber = '';
		cr2.FlexFirstRunDate = date.today();
		cr2.MigrationContactName = '';
		cr2.Subject = 'Threshold Clean-up';
		cr2.GoingLostDescription = '';
		cr2.CSRUsername = '';
		cr2.FlagName = 'Test Flag';
		cr2.FlagComments = 'Test Comments';
		cr2.Error = '';
		
		//this one should work on accountnumber alone
		FFSService.CaseRecord cr3 = new FFSService.CaseRecord();
		cr3.CaseId = '';
		cr3.BisID = '';
		cr3.ClientName = acct1.Name;
		cr3.ClientNumber = acct1.AccountNumber;
		cr3.FlexFirstRunDate = date.today();
		cr3.MigrationContactName = '';
		cr3.Subject = 'Pre-Scrub Clean-up';
		cr3.GoingLostDescription = '';
		cr3.CSRUsername = u.email.substringBefore('@').left(8);
		cr3.FlagName = 'Test Flag';
		cr3.FlagComments = 'Test Comments';
		cr3.Error = '';
		
		//this one should be assigned to the preview csr queue
		FFSService.CaseRecord cr4 = new FFSService.CaseRecord();
		cr4.CaseId = '';
		cr4.BisID = '';
		cr4.ClientName = acct2.Name;
		cr4.ClientNumber = acct2.AccountNumber;
		cr4.FlexFirstRunDate = date.today();
		cr4.MigrationContactName = '';
		cr4.Subject = 'Pre-Scrub Clean-up';
		cr4.GoingLostDescription = '';
		cr4.CSRUsername = '';
		cr4.FlagName = 'Test Flag';
		cr4.FlagComments = 'Test Comments';
		cr4.Error = '';
		
		//this one should should return an error since no account was specified
		FFSService.CaseRecord cr5 = new FFSService.CaseRecord();
		cr5.CaseId = '';
		cr5.BisID = '';
		cr5.ClientName = acct2.Name;
		cr5.ClientNumber = '';
		cr5.FlexFirstRunDate = date.today();
		cr5.MigrationContactName = '';
		cr5.Subject = 'Client Going Lost';
		cr5.GoingLostDescription = '';
		cr5.CSRUsername = u.email.substringBefore('@').left(8);
		cr5.FlagName = 'Test Flag';
		cr5.FlagComments = 'Test Comments';
		cr5.Error = '';
		
		//this one should return an error since no subject was specified
		FFSService.CaseRecord cr6 = new FFSService.CaseRecord();
		cr6.CaseId = '';
		cr6.BisID = '';
		cr6.ClientName = acct2.Name;
		cr6.ClientNumber = acct2.AccountNumber;
		cr6.FlexFirstRunDate = date.today();
		cr6.MigrationContactName = '';
		cr6.Subject = '';
		cr6.GoingLostDescription = '';
		cr6.CSRUsername = '';
		cr6.FlagName = 'Test Flag';
		cr6.FlagComments = 'Test Comments';
		cr6.Error = '';
		
		FFSService.CaseRecord[] cases = new FFSService.CaseRecord[]{cr1,cr2,cr3,cr4,cr5,cr6};
		FFSService.CaseRecord[] updatedCases = FFSService.createCase(cases);
		
		system.debug('updatedCases: '+updatedCases);
		
		Id[] caseIds = new Id[]{};
		for(FFSService.CaseRecord cr : updatedCases){
			if(cr.CaseId!=''){
				caseIds.add(Id.valueOf(cr.CaseId));
			}
		}
		Case[] queriedCases = [SELECT Id,OwnerId,AccountId,ContactId FROM Case WHERE Id in :caseIds];
		Case case1 = queriedCases[0];
		Case case2 = queriedCases[1];
		Case case3 = queriedCases[2]; 
		Case case4 = queriedCases[3];
		System.assertEquals(u.Id,case1.OwnerId); //cr1
		System.assertEquals(diq,case2.OwnerId); //cr2
		System.assertEquals(u.Id,case3.OwnerId); //cr3
		System.assertEquals(pcsq,case4.OwnerId); //cr4
		System.assert(updatedCases[4].Error.contains('Could not find matching account')); //cr5
		System.assert(updatedCases[5].Error.contains('Invalid Subject')); //cr6
		
		CaseComment cc = new CaseComment(ParentId=case1.Id,CommentBody='Test Comment');
		insert cc;
		
		FFSService.CaseRecordStatus crs1 = new FFSService.CaseRecordStatus();
		crs1.CaseId=case1.Id;
		
		FFSService.CaseRecordStatus[] crsList = new FFSService.CaseRecordStatus[]{crs1};
		FFSService.CaseRecordStatus[] crsListReturned = FFSService.getCaseDetail(crsList);
		System.assertEquals(cc.CommentBody,crsListReturned[0].Comments[0]); 
		*/ //APR0171211-Sush
		Test.stopTest();
	}
    
	static testMethod void testUpdateAccount(){
		Account acct1 = new Account(Name='test acct',BIS_ID__c = 12345,AccountNumber='123-456789');
		Account acct2 = new Account(Name='test acct2',BIS_ID__c = 54321,AccountNumber='987-654321');
		Account[] accts = new Account[]{acct1,acct2};
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
	
		User testUsers = new User(FirstName = '',
		LastName = 'Testing',
		Username = 'testUserDA@email.com',
		Email = 'noelle@paychex.com',
		Alias = 'test',
		CommunityNickname = 'testUserDA',
		TimeZoneSidKey = 'America/New_York',
		LocaleSidKey = 'sq_AL',
		EmailEncodingKey = 'UTF-8',
		ProfileId = p.Id,
		LanguageLocaleKey = 'en_US',
		Phone = '123-456-7891',
		Title = 'Test Title',
		SenderEmail = 'test@email.com',
		IsActive = true,
		Sales_Org__c = 'PAY',
		HR_Person_Id__c = '123456');
		insert testUsers;
		insert accts;
		Contact ctct1 = new Contact(AccountId=acct1.Id,FirstName='noelle',LastName = 'Roth',Decision_Maker__c=true, Email='noelle@paychex.com',HR_Person_Id__c ='12356'  );
		Contact ctct2 = new Contact(AccountId=acct2.Id,FirstName='test2',LastName = 'ctct2',Decision_Maker__c=true, HR_Person_Id__c ='254');
		Contact ctct3 = new Contact(FirstName='CallerName',LastName = 'NotFound', User_Lookup__c = testUsers.Id,HR_Person_Id__c ='15268' );
		Contact[] ctcts = new Contact[]{ctct1,ctct2, ctct3};
		insert ctcts;		
        	
        Case cs = new Case(AccountId=acct1.Id);
        insert cs;
        Reference_Core_Payroll__c rcp = new Reference_Core_Payroll__c(Case_Lookup__c= cs.Id);
        insert rcp;
		
		Test.startTest();
		//this one should find account from BISId
		FFSService.AccountRecord ar1 = new FFSService.AccountRecord();
		ar1.BisID = String.ValueOf(acct1.BIS_ID__c);
		ar1.ClientName = acct1.Name;
		ar1.ClientNumber = '123-456789';
		ar1.MigrationAnalyst = 'test analyst';
		ar1.FlexFirstScheduledRunDate = date.today();
		ar1.OriginalClientRequestedStartDate = date.today();
		ar1.MigrationChannel = 'test channel';
		ar1.LastActivityDescription = 'test description';
		ar1.ActivityDate = date.today();
		ar1.projectManager = 'noelle';
		ar1.projectManagerEmail = 'noelle@paychex.com';
		ar1.TAAICEmail = 'noelle@paychex.com';
		ar1.TAAICName = 'Testing';
		ar1.Error = '';
        
        
        
      
		
		//this one should find account from account number
		FFSService.AccountRecord ar2 = new FFSService.AccountRecord();
		ar2.BisID = '';
		ar2.ClientName = acct2.Name;
		ar2.ClientNumber = acct2.AccountNumber;
		ar2.MigrationAnalyst = 'test analyst';
		ar2.FlexFirstScheduledRunDate = date.today();
		ar2.OriginalClientRequestedStartDate = date.today();
		ar2.MigrationChannel = 'test channel';
		ar2.LastActivityDescription = 'test description';
		ar2.ActivityDate = date.today();
		ar1.projectManager = 'noelle Roth';		
		ar2.Error = '';
		ar2.TAAICEmail = 'noelle2222@paychex.com';
		ar2.TAAICName = 'Testing 1';
        
		//this one should return an error since no bis/client number was specified
		FFSService.AccountRecord ar3 = new FFSService.AccountRecord();
		ar3.BisID = '';
		ar3.ClientName = acct2.Name;
		ar3.ClientNumber = '';
		ar3.MigrationAnalyst = 'test analyst';
		ar3.FlexFirstScheduledRunDate = date.today();
		ar3.OriginalClientRequestedStartDate = date.today();
		ar3.MigrationChannel = 'test channel';
		ar3.LastActivityDescription = 'test description';
		ar3.ActivityDate = date.today();
		ar3.Error = '';
       
		
		FFSService.AccountRecord[] ars = new FFSService.AccountRecord[]{ar1,ar2,ar3};
		FFSService.AccountRecord[] updatedAccts = FFSService.updateAccount(ars);
		
		Id[] acctIds = new Id[]{acct1.Id,acct2.Id};
		Account[] queriedAccts = [SELECT Id,Activity_Date__c,Flex_First_Scheduled_Run_Date__c,Original_Client_Requested_Start_Date__c,
									Migration_Channel__c,Last_Activity__c,Migration_Analyst__c FROM Account WHERE Id in:acctIds];
		
	/*	Account uA1 = queriedAccts[0]; //ar1
		system.assertEquals(ar1.MigrationAnalyst,uA1.Migration_Analyst__c);
		system.assertEquals(ar1.MigrationChannel,uA1.Migration_Channel__c);
		system.assertEquals(ar1.LastActivityDescription,uA1.Last_Activity__c);
		Account uA2 = queriedAccts[1]; //ar2
		system.assertEquals(ar2.FlexFirstScheduledRunDate,uA2.Flex_First_Scheduled_Run_Date__c);
		system.assertEquals(ar2.OriginalClientRequestedStartDate,uA2.Original_Client_Requested_Start_Date__c);
		system.assertEquals(ar2.ActivityDate,uA2.Activity_Date__c);
		system.assert(updatedAccts[2].Error.contains('Could not find matching account')); //ar3
		*/
		Test.stopTest();
	}
    
    static testmethod void testgetUpdatedAccounts() {
        Datetime dtime1 = Datetime.newInstance(2020, 4, 24, 9, 0, 0);
        Datetime dtime2 = Datetime.newInstance(2020, 4, 25, 10, 0, 0);
        Datetime dtime3 = Datetime.newInstance(2020, 4, 26, 11, 0, 0);
        Datetime dtime4 = Datetime.newInstance(2020, 4, 27, 9, 0, 0);
        Datetime dtime5 = Datetime.newInstance(2020, 4, 28, 9, 0, 0);
        Account acct1 = new Account(Name='test acct1',BIS_ID__c = 12345,AccountNumber='123-456789', Type='Advantage', Main_Owner_Changed_Date__c=dtime1); //Should be returned
        Account acct2 = new Account(Name='test acct2',BIS_ID__c = 22345,AccountNumber='223-456789', Type='Preview', Main_Owner_Changed_Date__c=dtime2); //Should be returned
        Account acct3 = new Account(Name='test acct3',BIS_ID__c = 32345,AccountNumber='323-456789', Type='Test', Main_Owner_Changed_Date__c=dtime3); //Should not be returned
        Account acct4 = new Account(Name='test acct4',BIS_ID__c = 42345,AccountNumber='423-456789', Type='Test', Main_Owner_Changed_Date__c=dtime4); //Should not be returned
        Account acct5 = new Account(Name='test acct5',BIS_ID__c = 52345,AccountNumber='523-456789', Type='Advantage', Main_Owner_Changed_Date__c=dtime5); //Should not be returned
        
        Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5};
        insert accts;
		Contact ctct3 = new Contact(FirstName='CallerName',LastName = 'NotFound');
		Contact[] ctcts = new Contact[]{ ctct3};
        
        System.debug('MAK in Test, accts: ' + accts);
        
       // needs to be fixed
        Test.startTest();
        
        FFSService.AccountInformation[] ars1 = FFSService.getUpdatedAccounts('04/25/2020 09:00 AM', '04/26/2020 11:00 AM'); //should return a count of one
        FFSService.AccountInformation[] ars2 = FFSService.getUpdatedAccounts('04/23/2020 09:00 AM', '04/25/2020 10:00 AM'); //should return a count of two
        FFSService.AccountInformation[] ars3 = FFSService.getUpdatedAccounts('04/233/2020 09:00 AM', '04/25/2020 10:00 AM'); //should return null
        FFSService.AccountInformation[] ars4 = FFSService.getUpdatedAccounts('04/23/2020 09:00 AM', '04/255/2020 10:00 AM'); //should return null
     
        System.assertEquals(1, ars1.size());
        System.assertEquals(2, ars2.size());
        System.assertEquals(null, ars3);
        System.assertEquals(null, ars4);
        
        Test.stopTest();
        
    }
    
    static testMethod void testRefCorePayrollRecord(){
		Account acct1 = new Account(Name='test acct',BIS_ID__c = 12345,AccountNumber='123-456789');
		Account acct2 = new Account(Name='test acct2',BIS_ID__c = 54321,AccountNumber='987-654321');
		Account[] accts = new Account[]{acct1,acct2};
		insert accts;
		Contact ctct1 = new Contact(AccountId=acct1.Id,FirstName='test',LastName = 'ctct',Decision_Maker__c=true, email = 'noelg@g.com',HR_Person_Id__c = '1233' );
		Contact ctct2 = new Contact(AccountId=acct2.Id,FirstName='test2',LastName = 'ctct2',Decision_Maker__c=true,email = 'noelg1@g.com',HR_Person_Id__c = '12331' );
		Contact ctct3 = new Contact(FirstName='CallerName',LastName = 'NotFound');
		Contact[] ctcts = new Contact[]{ctct1,ctct2, ctct3};
		insert ctcts;
        Case cs = new Case(AccountId=acct1.Id);
        insert cs;
		Opportunity opp = new Opportunity(Name ='Test', AccountId = acct2.Id, StageName = 'Qualified',CloseDate = System.Today() );
		insert opp;
	

        Reference_Core_Payroll__c rcp = new Reference_Core_Payroll__c(Case_Lookup__c= cs.Id,Current_Step__c ='Case Submission',New_Prospect_Client_Number__c='123-456789',Opportunity_Lookup__c = opp.Id,Proposed_Run_Date__c = system.Today() - 1 );
        
		insert rcp;

		Reference_Core_Payroll__c rcp2 = new Reference_Core_Payroll__c(Case_Lookup__c= cs.Id,Current_Step__c ='Case Submission',New_Prospect_Client_Number__c='123-456789',Opportunity_Lookup__c = opp.Id,Proposed_Run_Date__c = system.Today() - 1 );
        
		insert rcp2;
		
		Test.startTest();
		//this one should find account from BISId
		FFSService.RefCorePayrollRecord ar1 = new FFSService.RefCorePayrollRecord();
		ar1.BisID = String.ValueOf(acct1.BIS_ID__c);		
		ar1.ClientName = acct1.Name;
		ar1.ClientNumber = '123-456789';
		ar1.initialContactDate = System.today(); //Initial_Client_Contact_Date__c
		ar1.dateClientLoadComplete = System.today(); //Date_Client_Load_Complete__c
		ar1.clientLoadComplete = True; //Client_Load_Complete__c
		ar1.iSCompletedClientAuditItems = ''; //IS_Completed_open_Client_Audit_Items__c picklist
		ar1.newLoadAuditDate = System.today(); //New_Load_Audit_Date__c
		ar1.payrollRunDate = System.today(); //Payroll_Run_Date__c
		ar1.postFrstPyrlVerifDate = System.today(); //Post_First_Payroll_Verification_Date__c
		ar1.rescheduledRunReason = ''; //Rescheduled_Run_Reason__c picklist
		ar1.orgnlProposedRunDate = System.today(); //Original_Proposed_Run_Date__c
		ar1.proposedRunDate = System.today() +10; //Proposed_Run_Date__c
		ar1.clientNeverRanReason = 'Financial'; //Client_Never_Ran_Reason__c picklist
		ar1.clientNeverRan = True; //Client_Never_Ran__c
		ar1.Error = '';
		ar1.clientReadyforTransition = System.today();
		ar1.callerName = 'Noelle L Roth';
		ar1.dateClientLoadReceived = System.today();
		ar1.loaderName = 'Bob Smith';
		ar1.commissionDate = System.today();
		ar1.mpscAccountHealthNotes = 'Test Note data';
		ar1.iSCompletedClientAuditItems = 'Yes';
		ar1.rescheduledRunReason = 'Unable to Balance';
		ar1.callerEmail = 'noelg@g.com';
		ar1.intakeStatus = 'Rejected';
		ar1.rejectionReasonCode = 'Other'; 
		FFSService.RefCorePayrollRecord[] ars = new FFSService.RefCorePayrollRecord[]{ar1};
		FFSService.RefCorePayrollRecord[] updatedRefCorePayrollRecord = FFSService.updaterefCorePayRoll(ars);
		
		Test.stopTest();
	}
    
    static testMethod void testRefCorePayrollRecord2(){
		Account acct1 = new Account(Name='test acct',BIS_ID__c = 12345,AccountNumber='123-456789');
		Account acct2 = new Account(Name='test acct2',BIS_ID__c = 54321,AccountNumber='987-654321');
		Account[] accts = new Account[]{acct1,acct2};
		insert accts;

		Contact ctct1 = new Contact(AccountId=acct1.Id,FirstName='noelle',LastName = 'Roth',Decision_Maker__c=true, Email='noelle@paychex.com',HR_Person_Id__c ='9856' );
		Contact ctct2 = new Contact(AccountId=acct2.Id,FirstName='test2',LastName = 'ctct2',Decision_Maker__c=true,HR_Person_Id__c ='8545' );
		Contact ctct3 = new Contact(FirstName='CallerName',LastName = 'NotFound');
		Contact[] ctcts = new Contact[]{ctct1,ctct2, ctct3 };
		insert ctcts;
        Case cs = new Case(AccountId=acct1.Id);
        insert cs;
		Opportunity opp = new Opportunity(Name ='Test', AccountId = acct2.Id, StageName = 'Qualified',CloseDate = System.Today() );
		insert opp;
		Id recordTypeId = Schema.SObjectType.Reference_Core_Payroll__c.getRecordTypeInfosByName().get('Reference Onboarding Core Payroll').getRecordTypeId();


        Reference_Core_Payroll__c rcp = new Reference_Core_Payroll__c(Case_Lookup__c= cs.Id,Current_Step__c ='Case Submission',New_Prospect_Client_Number__c='123-456789',recordTypeId = recordTypeId );
        insert rcp;
		Reference_Core_Payroll__c rcp2 = new Reference_Core_Payroll__c(Case_Lookup__c= cs.Id,Current_Step__c ='Case Submission',New_Prospect_Client_Number__c='987-654321', recordTypeId = recordTypeId , Opportunity_Lookup__c = opp.Id);
        insert rcp2;
		Test.startTest();
		FFSService.RefCorePayrollRecord ar2 = new FFSService.RefCorePayrollRecord();
		ar2.BisID = String.ValueOf(acct2.BIS_ID__c);		

		ar2.ClientName = acct1.Name;
		ar2.ClientNumber = '987-654321';
		ar2.initialContactDate = System.today(); //Initial_Client_Contact_Date__c
		ar2.dateClientLoadComplete = System.today(); //Date_Client_Load_Complete__c
		ar2.clientLoadComplete = True; //Client_Load_Complete__c
		ar2.iSCompletedClientAuditItems = ''; //IS_Completed_open_Client_Audit_Items__c picklist
		ar2.newLoadAuditDate = System.today(); //New_Load_Audit_Date__c
		ar2.payrollRunDate = System.today(); //Payroll_Run_Date__c
		ar2.postFrstPyrlVerifDate = System.today(); //Post_First_Payroll_Verification_Date__c
		ar2.rescheduledRunReason = ''; //Rescheduled_Run_Reason__c picklist
		ar2.orgnlProposedRunDate = System.today(); //Original_Proposed_Run_Date__c
		ar2.proposedRunDate = System.today(); //Proposed_Run_Date__c
		ar2.clientNeverRanReason = ''; //Client_Never_Ran_Reason__c picklist
		ar2.clientNeverRan = false ; //Client_Never_Ran__c
		ar2.Error = '';
		ar2.clientReadyforTransition = System.today();
		ar2.callerName = 'Noelle L Roth';
		ar2.dateClientLoadReceived = System.today();
		ar2.loaderName = 'Bob Smith';
		ar2.commissionDate = System.today();
		ar2.mpscAccountHealthNotes = 'Test Note data';
		ar2.iSCompletedClientAuditItems = 'Yes';
		ar2.rescheduledRunReason = 'Unable to Balance';
		ar2.opptyId = opp.Id;
		ar2.intakeStatus = 'Submission accepted-ready for assignment';
		FFSService.RefCorePayrollRecord[] ars2 = new FFSService.RefCorePayrollRecord[]{ar2};
		FFSService.RefCorePayrollRecord[] updatedRefCorePayrollRecord2 = FFSService.updaterefCorePayRoll(ars2);
		Test.stopTest();

	}

	static testMethod void testRefCorePayrollRecordWithRCp(){
		Account acct1 = new Account(Name='test acct',BIS_ID__c = 12345,AccountNumber='123-456789');
		Account acct2 = new Account(Name='test acct2',BIS_ID__c = 54321,AccountNumber='987-654321');
		Account[] accts = new Account[]{acct1,acct2};
		insert accts;
		Contact ctct1 = new Contact(AccountId=acct1.Id,FirstName='test',LastName = 'ctct',Decision_Maker__c=true, email = 'noelg@g.com',HR_Person_Id__c = '1233' );
		Contact ctct2 = new Contact(AccountId=acct2.Id,FirstName='test2',LastName = 'ctct2',Decision_Maker__c=true,email = 'noelg1@g.com',HR_Person_Id__c = '12331' );
		Contact ctct3 = new Contact(FirstName='CallerName',LastName = 'NotFound');
		Contact[] ctcts = new Contact[]{ctct1,ctct2, ctct3};
		insert ctcts;
        Case cs = new Case(AccountId=acct1.Id);
        insert cs;
		Opportunity opp = new Opportunity(Name ='Test', AccountId = acct2.Id, StageName = 'Qualified',CloseDate = System.Today() );
		insert opp;

		
		Test.startTest();
		//this one should find account from BISId
		FFSService.RefCorePayrollRecord ar1 = new FFSService.RefCorePayrollRecord();
		ar1.BisID = String.ValueOf(acct1.BIS_ID__c);		
		ar1.ClientName = acct1.Name;
		ar1.ClientNumber = '123-456789';
		ar1.initialContactDate = System.today(); //Initial_Client_Contact_Date__c
		ar1.dateClientLoadComplete = System.today(); //Date_Client_Load_Complete__c
		ar1.clientLoadComplete = True; //Client_Load_Complete__c
		ar1.iSCompletedClientAuditItems = ''; //IS_Completed_open_Client_Audit_Items__c picklist
		ar1.newLoadAuditDate = System.today(); //New_Load_Audit_Date__c
		ar1.payrollRunDate = System.today(); //Payroll_Run_Date__c
		ar1.postFrstPyrlVerifDate = System.today(); //Post_First_Payroll_Verification_Date__c
		ar1.rescheduledRunReason = ''; //Rescheduled_Run_Reason__c picklist
		ar1.orgnlProposedRunDate = System.today(); //Original_Proposed_Run_Date__c
		ar1.proposedRunDate = System.today() +10; //Proposed_Run_Date__c
		ar1.clientNeverRanReason = 'Financial'; //Client_Never_Ran_Reason__c picklist
		ar1.clientNeverRan = True; //Client_Never_Ran__c
		ar1.Error = '';
		ar1.clientReadyforTransition = System.today();
		ar1.callerName = 'Noelle L Roth';
		ar1.dateClientLoadReceived = System.today();
		ar1.loaderName = 'Bob Smith';
		ar1.commissionDate = System.today();
		ar1.mpscAccountHealthNotes = 'Test Note data';
		ar1.iSCompletedClientAuditItems = 'Yes';
		ar1.rescheduledRunReason = 'Unable to Balance';
		ar1.callerEmail = 'noelg@g.com';
		ar1.intakeStatus = 'Rejected';
		ar1.rejectionReasonCode = 'Other'; 
		FFSService.RefCorePayrollRecord[] ars = new FFSService.RefCorePayrollRecord[]{ar1};
		FFSService.RefCorePayrollRecord[] updatedRefCorePayrollRecord = FFSService.updaterefCorePayRoll(ars);

		Test.stopTest();
	}

       static testMethod void testgetCaseDetails(){
		Account acct1 = new Account(Name='test acct',BIS_ID__c = 12345,AccountNumber='123-456789');
		Account acct2 = new Account(Name='test acct2',BIS_ID__c = 54321,AccountNumber='987-654321');
		Account[] accts = new Account[]{acct1,acct2};
		insert accts;
		Contact ctct1 = new Contact(AccountId=acct1.Id,FirstName='test',LastName = 'ctct',Decision_Maker__c=true, email = 'noelg@g.com',HR_Person_Id__c = '1233' );
		Contact ctct2 = new Contact(AccountId=acct2.Id,FirstName='test2',LastName = 'ctct2',Decision_Maker__c=true,email = 'noelg1@g.com',HR_Person_Id__c = '12331' );
		Contact ctct3 = new Contact(FirstName='CallerName',LastName = 'NotFound');
		Contact[] ctcts = new Contact[]{ctct1,ctct2, ctct3};
		insert ctcts;
        Case cs = new Case(AccountId=acct1.Id);
        insert cs;
		Opportunity opp = new Opportunity(Name ='Test', AccountId = acct2.Id, StageName = 'Qualified',CloseDate = System.Today() );
		insert opp;
		caseComment cm = new casecomment(CommentBody = 'test com', parentid = cs.id); 
		insert cm; 

		
		Test.startTest();
		
		FFSService.CaseRecordStatus getCasR = new FFSService.CaseRecordStatus();
		getCasR.CaseId = cs.id; 
		
		FFSService.CaseRecordStatus[] getCasL = new FFSService.CaseRecordStatus[]{getCasR};
		FFSService.CaseRecordStatus[] getCaseReccord = FFSService.getCaseDetail(getCasL);

		
		Test.stopTest();
	}

}