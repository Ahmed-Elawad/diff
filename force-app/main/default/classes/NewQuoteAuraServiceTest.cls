/* 
 * New Oracle Quote button
 *
 * History
 * -------
 * 01/22/2021 Carrie Marciano	fixed Non-CPQUser test to ensure select of a non-cpq user
 */
@isTest
private class NewQuoteAuraServiceTest {
	
	/*@isTest static void saveNewQuoteTest_giveQuote_ReceiveQuoteWithId() {
		// create the source account
		Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
		Account acct = new Account(Name='Test Account0',recordtypeId = acctCorert.getRecordTypeId(),AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
		insert acct;

		// get the core record type - have to set the record type because of the Sales_Contact__c flag.
		Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');

		// create contacts
		Contact ctct1 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest1',Email='firstTest1@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
		insert ctct1;

		// create opportunities
		Opportunity opp1 = new Opportunity(Name='Test Opp1',CloseDate=Date.today().addDays(7),StageName='Sold',Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id);
		insert opp1;

		OpportunityContactRole role = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = ctct1.Id, IsPrimary = true);
		insert role;

		SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.Id, SBQQ__Status__c = 'Draft');

		Test.startTest();
		SBQQ__Quote__c newQuote = NewQuoteAuraService.saveNewQuote(quote);
		Test.stopTest();

		System.assertEquals(newQuote.Id != null, true, 'The newQuote was inserted');
		// Implement test code
	}*/
    
    @isTest static void CPQUser() {
        User cpqUser = [Select Id, Name from User where Profile.Name=:Utilities.PROF_MMS_SALES_SB and IsActive=true limit 1];     
        
        PermissionSet ps = new PermissionSet(Label='OracleCPQUser',Name='OracleCPQUser');
        insert ps;
        //query custom permission, cannot create in test
        CustomPermission cp = [SELECT Id,MasterLabel,DeveloperName FROM CustomPermission WHERE MasterLabel = 'OracleCPQUser' LIMIT 1];
        //assign custom permission to permission set
        SetupEntityAccess sea = new SetupEntityAccess(ParentId = ps.Id,SetupEntityId = cp.Id);
        insert sea;
        //assign permission set to user
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId=ps.Id,AssigneeId = cpqUser.Id);
        insert psa;
        
        System.runAs(cpqUser) {
        	NewQuoteAuraService.getUserInfo();
            System.assertEquals(true, NewQuoteAuraService.getUserInfo());
        } // System.runAs       
    }
    
    /*@isTest static void nonCPQUser() {   
        PermissionSet ps = new PermissionSet(Label='OracleCPQUser',Name='OracleCPQUser');
        insert ps;
        //query custom permission, cannot create in test
        CustomPermission cp = [SELECT Id,MasterLabel,DeveloperName FROM CustomPermission WHERE MasterLabel = 'OracleCPQUser' LIMIT 1];
        //assign custom permission to permission set
        SetupEntityAccess sea = new SetupEntityAccess(ParentId = ps.Id,SetupEntityId = cp.Id);
        insert sea;
        
        User nonCPQUser = [Select Id, Name from User where Profile.Name=:Utilities.PROF_MMS_SALES_SB and IsActive=true and Oracle_CPQ__c=false limit 1]; 
        
        if(nonCPQUser!=null){
           	System.runAs(nonCPQUser) {
        		NewQuoteAuraService.getUserInfo();
            	System.assertEquals(false, NewQuoteAuraService.getUserInfo());
        	} // System.runAs 
        }
               
    }*/
	
    /*@isTest static void getPickListValuesIntoList() {
    	NewQuoteAuraService.getPickListValuesIntoList();
      	system.assert(NewQuoteAuraService.getPickListValuesIntoList()!=null);
    }*/    
}