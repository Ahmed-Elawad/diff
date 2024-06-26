/* 
 * Test methods for the ReferralController
 *
 * History
 * -------
 * 01/27/2013 Cindy Freeman		Created
 * 03/26/2017 Cindy Freeman		modified to use Employees__c field instead of NumberOfEmployees
   01/10/2020 Dan Carmen         Update test, increment API version
   
 */
@isTest
private class FAReferralControllerTest {

   static testMethod void testBasics() {
   		createTestData();
   		Referral_Contact__c refctct = [select Name, Id from Referral_Contact__c where Name = 'John RefAccount1'];
   		
		User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
         	Test.SetCurrentPageReference(Page.FAReferral);
         	System.CurrentPageReference().getParameters().put('refcontactId',refctct.Id);
         	FAReferralController rc = new FAReferralController();
         	
         	System.assertEquals('STEPpreSearch', rc.currentStep);
         	System.assertEquals(false, rc.oktoCreate);
         	System.assertEquals(false, rc.isError);
         	
         	System.assertEquals('Test RefAccount', rc.refAcct.Name);
         	System.assertEquals('John RefAccount1', rc.refCtct.Name);
         	
         	// run search with no criteria
         	rc.searchAcct = '';
         	rc.searchZip = '';
         	rc.searchName = '';
         	rc.searchEmail = '';
         	rc.searchPhone = '';
         	rc.runSearch();
         	System.assertEquals(0, rc.rcdcnt);
         	// should be an error message
         	System.assertEquals(true,ApexPages.hasMessages());
         	ApexPages.Message msg = ApexPages.getMessages().get(0);
 	        System.assertEquals('Please enter data to search',msg.getDetail() );
         	System.assertEquals(false, rc.okToCreate);
         	
         	String returnUrl = rc.cancel().getUrl();
            System.assertEquals(true,returnUrl.contains(refctct.Id));
         	
         	rc.returnToSearch();
         	System.assertEquals('STEPsearch', rc.currentStep);
         	
      	} // System.runAs
   } // testBasics
   
   static testMethod void testAcctSearch() {   		
   		Id [] fixedSoslResults;
   		User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        
        System.runAs(u) {
        	createTestData();
        	Referral_Contact__c refctct = [select Name, Id from Referral_Contact__c where Name = 'John RefAccount1'];
        	
         	Test.SetCurrentPageReference(Page.FAReferral);
         	System.CurrentPageReference().getParameters().put('refcontactId',refctct.Id);
         	FAReferralController rc = new FAReferralController();
         	
         	rc.searchZip = '10000';
         	rc.runSearch();
         	// should be an error message
         	System.assertEquals(true,ApexPages.hasMessages());
         	ApexPages.Message msg = ApexPages.getMessages().get(0);
 	        System.assertEquals('You must enter an Account name along with the zipcode.',msg.getDetail() );

			// find 2 accounts with this name
	   		Account[] acctList = [Select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode from Account 
	        						where name like 'Test%' and BillingPostalCode = '10000'];
			fixedSoslResults = new Id[acctList.size()];        		        						
    	   	for (Account a: acctList)
       		{	fixedSoslResults.add(a.Id);	}    			         	
    		Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query
    		
         	rc.searchAcct = 'Test';
         	rc.searchZip = '';
	        rc.runSearch();            	
    		System.assertEquals(2, rc.resultList.size());
    		
    		// find 1 lead with this name
    		rc.searchZip = '';
    		Lead[] leadList = [Select Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone from Lead 
    							where company like 'Test%'];    							
    		fixedSoslResults = new Id[leadList.size()];
    		for (Lead l: leadList)
    		{	fixedSoslResults.add(l.Id);	}
    		Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query
    		
    		rc.searchAcct = 'Test';
         	rc.searchZip = '10000';
    		rc.runSearch();
    		System.assertEquals(1, rc.resultList.size());
    		
    		// test sorting
    		rc.sortField = 'nameField';
    		rc.sortRecords();
    		System.assertEquals('asc', rc.sortDir);
    		System.assertEquals(1,rc.resultList.size());
    		    		   
    		rc.sortField = 'companyField';
    		rc.sortRecords();
    		System.assertEquals('desc', rc.sortDir);
    		System.assertEquals(1,rc.resultList.size());
    		
      	} // System.runAs
   } // testAcctSearch

   static testMethod void testPersonSearch() {   		
   		Id [] fixedSoslResults;
   		User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        
        System.runAs(u) {
        	createTestData();
        	Referral_Contact__c refctct = [select Name, Id from Referral_Contact__c where Name = 'John RefAccount1'];
      	
         	Test.SetCurrentPageReference(Page.FAReferral);
         	System.CurrentPageReference().getParameters().put('refcontactId',refctct.Id);
         	FAReferralController rc = new FAReferralController();
         	
			// find 1 contact with this data
	   		Contact[] ctctList = [Select Id, FirstName, LastName, Name, AccountId, Account.Name, Account.BillingCity, Account.BillingPostalCode, Email, Phone from Contact
	   								WHERE Name like 'Mary%' AND EMAIL = 'mary@account2.com' AND PHONE = '555-1212']; 	   								  
			fixedSoslResults = new Id[ctctList.size()];        		        						
    	   	for (Contact ct: ctctList)
       		{	fixedSoslResults.add(ct.Id);	}    			         		   				
    		Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query
    		
    		// search based on Name, Email, Phone
    		rc.searchAcct = '';
    		rc.searchZip = '';
         	rc.searchName = 'Mary';
         	rc.searchEmail = 'mary@account2.com';
	        rc.searchPhone = '555-1212';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());
    		 
 			rc.selectedId = ctctList.get(0).Id;
			rc.selectedObj = 'Contact';
			rc.selectedStep = 'refer';
			
			PageReference intRefPage = Page.Referral;
			String returnUrl = rc.nextStep().getUrl();
			System.assertEquals(true,returnUrl.contains(ctctList.get(0).Id));			        		   		    		     	
      	} // System.runAs
   } // testPersonSearch
   
   static testMethod void testPersonSearch2() {   		
   		Id [] fixedSoslResults;
   		User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        
        System.runAs(u) {
        	createTestData();
        	Referral_Contact__c refctct = [select Name, Id from Referral_Contact__c where Name = 'John RefAccount1'];
      	
         	Test.SetCurrentPageReference(Page.FAReferral);
         	System.CurrentPageReference().getParameters().put('refcontactId',refctct.Id);
         	FAReferralController rc = new FAReferralController();
         	
			// find 1 lead with this data
	   		Lead[] leadList = [Select Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone from Lead 
    							where company like 'Test%'];
    		fixedSoslResults = new Id[leadList.size()];
    		for (Lead l: leadList)
    		{	fixedSoslResults.add(l.Id);	}
    		Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query    		
    		
    		// search based on Name, Email, Phone all combinations
    		rc.searchAcct = '';
    		rc.searchZip = '';
         	rc.searchName = 'Mary';
         	rc.searchEmail = 'mary@account3.com';
	        rc.searchPhone = '555-3333';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());
    		
    		rc.searchName = 'Mary';
         	rc.searchEmail = 'mary@account3.com';
	        rc.searchPhone = '';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());
    		 
    		rc.searchName = 'Mary';
         	rc.searchEmail = '';
	        rc.searchPhone = '555-3333';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());

    		rc.searchName = 'Mary';
         	rc.searchEmail = '';
	        rc.searchPhone = '';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());

    		rc.searchName = '';
         	rc.searchEmail = 'mary@account3.com';
	        rc.searchPhone = '555-3333';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());

    		rc.searchName = '';
         	rc.searchEmail = 'mary@account3.com';
	        rc.searchPhone = '';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());

    		rc.searchName = '';
         	rc.searchEmail = '';
	        rc.searchPhone = '555-3333';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());
        } // runAs
   } // testPersonSearch2        
    
   static testMethod void testPersonSearch3() {   		
   		Id [] fixedSoslResults;
   		User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        
        System.runAs(u) {
        	createTestData();
        	Referral_Contact__c refctct = [select Name, Id from Referral_Contact__c where Name = 'John RefAccount1'];
      	
         	Test.SetCurrentPageReference(Page.FAReferral);
         	System.CurrentPageReference().getParameters().put('refcontactId',refctct.Id);
         	FAReferralController rc = new FAReferralController();
         	    		
    		// find 1 contact with this data
	   		Contact[] ctctList = [Select Id, FirstName, LastName, Name, AccountId, Account.Name, Account.BillingCity, Account.BillingPostalCode, Email, Phone from Contact
	   								WHERE Name = 'Mary Contact2'];
			fixedSoslResults = new Id[ctctList.size()];	   								
    	   	for (Contact ct: ctctList)
       		{	fixedSoslResults.add(ct.Id);	}
    		Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query    		
    		
    		// search based on Name, Email, Phone all combinations
    		rc.searchAcct = '';
    		rc.searchZip = '';
         	rc.searchName = 'Mary';
         	rc.searchEmail = 'mary@account2.com';
	        rc.searchPhone = '555-1212';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());
    		
    		rc.searchName = 'Mary';
         	rc.searchEmail = 'mary@account2.com';
	        rc.searchPhone = '';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());
    		 
    		rc.searchName = 'Mary';
         	rc.searchEmail = '';
	        rc.searchPhone = '555-1212';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());

    		rc.searchName = 'Mary';
         	rc.searchEmail = '';
	        rc.searchPhone = '';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());

    		rc.searchName = '';
         	rc.searchEmail = 'mary@account2.com';
	        rc.searchPhone = '555-1212';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());

    		rc.searchName = '';
         	rc.searchEmail = 'mary@account2.com';
	        rc.searchPhone = '';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());

    		rc.searchName = '';
         	rc.searchEmail = '';
	        rc.searchPhone = '555-1212';
	        rc.runSearch();            	
    		System.assertEquals(1, rc.resultList.size());
      	} // System.runAs
   } // testPersonSearch3
   
   static testMethod void testConvertLead() {   		
   		Id [] fixedSoslResults;
   		User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        
        System.runAs(u) {
        	createTestData();
        	Referral_Contact__c refctct = [select Name, Id from Referral_Contact__c where Name = 'John RefAccount1'];
      	
         	Test.SetCurrentPageReference(Page.FAReferral);
         	System.CurrentPageReference().getParameters().put('refcontactId',refctct.Id);
         	FAReferralController rc = new FAReferralController();
         	
    		// find 1 lead with this name
    		rc.searchZip = '';
    		Lead[] leadList = [Select Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone from Lead 
    							where company like 'Test%'];    							
    		fixedSoslResults = new Id[leadList.size()];
    		for (Lead l: leadList)
    		{	fixedSoslResults.add(l.Id);	}
    		Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query
    		
    		rc.searchAcct = 'Test Account3';
    		rc.searchZip = '';
    		rc.searchName = '';
    		rc.searchEmail = '';
    		rc.searchPhone = '';
    		rc.runSearch();
    		System.assertEquals(1, rc.resultList.size());

			rc.selectedId = leadList.get(0).Id;
			rc.selectedObj = 'Lead';
			rc.selectedStep = 'refer';
			
			PageReference intRefPage = Page.Referral;
			String returnUrl = rc.nextStep().getUrl();
            
			Lead convertLead = [Select Id, Name, IsConverted from Lead WHERE Id = :LeadList.get(0).Id];
			System.assertEquals(true, convertLead.IsConverted);
			
			Account[] newAcct = [Select Id, Name, (Select Id, Name from Contacts) from Account WHERE Name = 'Test Account3'];
			System.assertEquals(1, newAcct.size());
			System.assertEquals(1, newAcct.get(0).Contacts.size());
			
			System.assertEquals(true,returnUrl.contains(newAcct.get(0).Contacts.get(0).Id));			    		   		    		     	
      	} // System.runAs
   } // testConvertLead

  static testMethod void testCreateContact() {   		
   		Id [] fixedSoslResults;
   		User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        
        System.runAs(u) {
        	createTestData();
        	Referral_Contact__c refctct = [select Name, Id from Referral_Contact__c where Name = 'John RefAccount1'];
      	
         	Test.SetCurrentPageReference(Page.FAReferral);
         	System.CurrentPageReference().getParameters().put('refcontactId',refctct.Id);
         	FAReferralController rc = new FAReferralController();
         	
    		// find 1 lead with this name
    		rc.searchZip = '';
    		Lead[] leadList = [Select Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone from Lead 
    							where company like 'Test%'];    							
    		fixedSoslResults = new Id[leadList.size()];
    		for (Lead l: leadList)
    		{	fixedSoslResults.add(l.Id);	}
    		Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query
    		
    		rc.searchAcct = 'Test';
    		rc.runSearch();
    		System.assertEquals(1, rc.resultList.size());

			// want to create new contact for this account
			rc.selectedId = leadList.get(0).Id;
			rc.selectedObj = 'Lead';
			rc.selectedStep = 'createCt';
			
			rc.nextStep();            
			Lead convertLead = [Select Id, Name, IsConverted from Lead WHERE Id = :LeadList.get(0).Id];
			System.assertEquals(true, convertLead.IsConverted);
			
			Account[] newAcct = [Select Id, Name, (Select Id, Name, AccountId from Contacts) from Account WHERE Name = 'Test Account3'];
			Contact newCT = newAcct.get(0).Contacts.get(0);
			System.assertEquals(1, newAcct.get(0).Contacts.size());
						
			System.assertEquals(newAcct.get(0).Id, rc.newAcct.Id);
			System.assertEquals(newCt.AccountId, rc.newCt.AccountId);
			System.assertEquals(true, rc.canEditAcct);
			System.assertEquals('STEPcreateCT', rc.currentSTEP);

			// fill in new contact fields, save then go to referral page
			rc.newAcct.BillingStreet = '10 Main Street';
			rc.newCT.FirstName = 'Peter';
			rc.newCT.LastName = 'Smith';
			String returnUrl = rc.saveRcds().getUrl();
			
			Contact createdCT = [Select Id, Name, MailingStreet, MailingCity, MailingState, MailingPostalCode from Contact where AccountId = :newAcct.get(0).Id and LastName = 'Smith'];
			System.assertEquals(true,returnUrl.contains(createdCT.Id));
			System.assertEquals('10 Main Street', createdCT.MailingStreet);
			System.assertEquals('Rochester', createdCT.MailingCity);
			System.assertEquals('NY', createdCT.MailingState);
			System.assertEquals('10000', createdCT.MailingPostalCode);
      	} // System.runAs
   } // testConvertLead

   static testMethod void testCreateAcctandContact() {   		
     AccountJunctionMethodsTest.setupCustomSettings();
     Id [] fixedSoslResults;
   		User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        
        System.runAs(u) {
        	createTestData();
        	Referral_Contact__c refctct = [select Name, Id from Referral_Contact__c where Name = 'John RefAccount1'];
      	
         	Test.SetCurrentPageReference(Page.FAReferral);
         	System.CurrentPageReference().getParameters().put('refcontactId',refctct.Id);
         	FAReferralController rc = new FAReferralController();
    		
    		// search based on Phone
    		rc.searchAcct = '';
    		rc.searchZip = '';
         	rc.searchName = '';
         	rc.searchEmail = '';
	        rc.searchPhone = '555-0101';
	        rc.runSearch();            	
    		System.assertEquals(0, rc.resultList.size());
    		
    		System.assertEquals(true,ApexPages.hasMessages());
         	ApexPages.Message msg = ApexPages.getMessages().get(0);
 	        System.assertEquals('No records found, please edit your search data.',msg.getDetail() );
 			System.assertEquals(true, rc.okToCreate);
 			
 			// click button to create new account and contact
 			rc.createAandC();
 			
 			// fill in new account and contact fields, save then go to referral page
 			rc.newAcct.Name = 'Test Account9';
 			rc.newAcct.BillingStreet = '10 Main Street';
 			rc.newAcct.BillingCity = 'Anytown';
			rc.newAcct.BillingState = 'NY';
			rc.newAcct.BillingPostalCode = '12345';
			//rc.newAcct.NumberOfEmployees = 99;
			rc.newAcct.Employees__c = 99;
			rc.newCT.FirstName = 'NewGuy';
			rc.newCT.LastName = 'Smith';
			rc.newCt.Email = 'newguy@account9.com';
			rc.newCt.Phone = '555-0101';
			
			String returnUrl = rc.saveRcds().getUrl();
			
			Account createdAcct = [Select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, NumberOfEmployees from Account
									WHERE Name = 'Test Account9'];
			Contact createdCT = [Select Id, Name, MailingStreet, MailingCity, MailingState, MailingPostalCode from Contact where AccountId = :createdAcct.Id];
			System.assertEquals(99, createdAcct.NumberOfEmployees);
			System.assertEquals('NY', createdAcct.BillingState);
			System.assertEquals('NewGuy Smith', createdCt.Name);
			System.assertEquals('10 Main Street', createdCT.MailingStreet);
			System.assertEquals('Anytown', createdCT.MailingCity);
			System.assertEquals('NY', createdCT.MailingState);
			System.assertEquals('12345', createdCT.MailingPostalCode);
			
			System.assertEquals(true,returnUrl.contains(createdCT.Id));
						    		   		    		     	
      	} // System.runAs
   } // testSelectContact

   static testMethod void testSearchLimit() {   		
   		Id [] fixedSoslResults;
   		User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        
        System.runAs(u) {
        	createTestData();
        	Referral_Contact__c refctct = [select Name, Id from Referral_Contact__c where Name = 'John RefAccount1'];
        	
         	Test.SetCurrentPageReference(Page.FAReferral);
         	System.CurrentPageReference().getParameters().put('refcontactId',refctct.Id);
         	FAReferralController rc = new FAReferralController();
         	
         	rc.searchAcct = 'Lead Account*';
         	rc.searchZip = '';
		
    		// find many leads with this name
    		Lead[] leadList = [Select Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone from Lead 
    							where company like 'Lead Account%'];    							
    		fixedSoslResults = new Id[leadList.size()];
    		for (Lead l: leadList)
    		{	fixedSoslResults.add(l.Id);	}
    		Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query
    		
    		rc.runSearch();
    		System.assertEquals(true,ApexPages.hasMessages());
         	ApexPages.Message msg = ApexPages.getMessages().get(0);
 	        System.assertEquals(true,msg.getDetail().contains('Please add criteria to limit your search'));
        } // runAs
   } // testSearchLimit   
   
   private static void createTestData () {
   
   		Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('HRS Referral Source Record Type', 'Referral_Account__c');	
   		Referral_Account__c refacct = new Referral_Account__c (Name ='Test RefAccount'
   								,RecordTypeId = rt.getRecordTypeId()
   								,Street_Address_1__c = '10 Main Street'
   								,City__c = 'Rochester'
   								,State_Province__c = 'NY'
   								,Zip_Postal_Code__c = '10000'
   								,Referral_Source_Business_Type__c = 'Other');
   		insert refacct;
   		rt = RecordTypeHelper.getRecordType('HRS Referral Record Type', 'Referral_Contact__c');
   		Referral_Contact__c refctct = new Referral_Contact__c (Name = 'John RefAccount1'
   								,Phone__c = '555-9999'
   								,Referral_Account__c = refacct.Id
   								,RecordTypeId = rt.getRecordTypeId());
   		insert refctct;   								
   								
        Account acct1 = new Account (name = 'Test Account1'
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000');
        insert acct1;
        Contact con1 = new Contact(Firstname = 'Bill'
                                ,Lastname = 'Contact1'
                                ,Phone = '555-1212'
                                ,Email='bill@account1.com'
                                ,AccountId=acct1.Id
                                ,Sales_Contact__c = true);
        insert con1;
        
        Account acct2 = new Account (name = 'Test Account2'
                                ,type = 'MMS Client'
                                ,BillingStreet = '10 Main Street'
                                ,BillingCity = 'Rochester'
                                ,BillingState = 'NY'
                                ,BillingPostalCode = '10000'
                                ,Bis_Id__c = 1234);
        insert acct2;
                
        Contact con2 = new Contact(Firstname = 'Mary'
                                ,Lastname = 'Contact2'
                                ,Phone = '555-1212'
                                ,Email = 'mary@account2.com'
                                ,AccountId=acct2.Id
                                ,Sales_Contact__c = true);
        insert con2;
        
        Lead ld1 = new Lead(Firstname = 'Mary'
                                ,Lastname = 'Lead1'
                                ,Company = 'Test Account3'
                                ,Phone = '555-3333'
                                ,Email = 'mary@account3.com'
                                ,City = 'Rochester'
                                ,State = 'NY'
                                ,PostalCode = '10000');
        insert ld1;        

		List <Lead> newLeads = new List<Lead>(); 
 		for (integer i = 0; i < 110; i++) 
        {
            Lead newLd;
            newLd = ld1.clone(false);            
            newLd.FirstName = 'Lead';
            newLd.LastName = 'Limit' +i
            ;
            newLd.Company = 'Lead Account' +i;
            newLeads.add(newLd);     
        }
        insert newLeads;      
   } // createTestData
}