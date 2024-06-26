/**
 * Tests CaseAccountManager.cls
 *
 * 11/06/2015 Lynn Michels created
   11/23/2020 Dan Carmen   Increment API, remove user  
 
 */
@isTest
private class CaseAccountManagerTest {

    static testMethod void populateAccountManagerFromTeam() 
    {
        Account account = new Account(Name='TestAccount'); 
        insert account;
        
        Contact contact = new Contact(	FirstName = 'George',
        								LastName = 'Contact',
        								AccountId = account.id);  
        insert contact;
        
        User u = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
        
        AccountTeamMember atm = new AccountTeamMember(UserId = u.id,
        											AccountId = account.id,
        											TeamMemberRole = 'HRS Client Relationship Account Manager');
        insert atm;
        
        Schema.RecordTypeInfo HRSDiscrepencyRT = RecordTypeHelper.getRecordType('HRS 4S LDPS Discrepancy', 'Case'); 
        Case c = new Case (AccountId = account.id,
        					RecordTypeId = HRSDiscrepencyRT.getRecordTypeId(),
        					Status = 'New'); 
        insert c;
        				
        List<Case> cases = [SELECT Id, Account_Manager__c FROM Case];				
        System.assertEquals(u.Name, cases[0].Account_Manager__c);
    }
    
    static testMethod void populateAccountManagerFrom401KRep()
    {
        Account account = new Account(Name='TestAccount'); 
        insert account;
        
        //Platinum Rep on an Account is a Contact 
        Contact contact = new Contact(	FirstName = 'George',
        								LastName = 'Contact',
        								AccountId = account.id);  
        insert contact;
        
      	account.Platinum_Rep_401K__c = contact.id;
        update account;
        
        Schema.RecordTypeInfo HRSDiscrepencyRT = RecordTypeHelper.getRecordType('HRS 4S LDPS Discrepancy', 'Case'); 
        Case c = new Case (AccountId = account.id,
        					RecordTypeId = HRSDiscrepencyRT.getRecordTypeId(),
        					Status = 'New'); 
        insert c; 
    }
    
    static testMethod void populateAccountManagerHaving401KRepAndTeamMembers()
    {
        Account account = new Account(Name='TestAccount'); 
        insert account;
        
        //Platinum Rep on an Account is a Contact 
        Contact contact = new Contact(	FirstName = 'George',
        								LastName = 'Contact',
        								AccountId = account.id);  
        insert contact;
        
      	account.Platinum_Rep_401K__c = contact.id;
        update account;
        
        User u = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
        
        AccountTeamMember atm = new AccountTeamMember(UserId = u.id,
        											AccountId = account.id,
        											TeamMemberRole = 'HRS Client Relationship Account Manager');
        insert atm;
        
        Schema.RecordTypeInfo HRSDiscrepencyRT = RecordTypeHelper.getRecordType('HRS 4S LDPS Discrepancy', 'Case'); 
        Case c = new Case (AccountId = account.id,
        					RecordTypeId = HRSDiscrepencyRT.getRecordTypeId(),
        					Status = 'New'); 
        insert c;
        				
        List<Case> cases = [SELECT Id, Account_Manager__c FROM Case];				
        System.assertEquals('George Contact', cases[0].Account_Manager__c);
    }
    
     static testMethod void populateAccountManagerOnTwoCases()
    {
        Account account = new Account(Name='TestAccount'); 
        insert account;
        
        //Platinum Rep on an Account is a Contact 
        Contact contact = new Contact(	FirstName = 'George',
        								LastName = 'Contact',
        								AccountId = account.id);  
        insert contact;
        
      	account.Platinum_Rep_401K__c = contact.id;
        update account;
        
        User u = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
        
        AccountTeamMember atm = new AccountTeamMember(UserId = u.id,
        											AccountId = account.id,
        											TeamMemberRole = 'HRS Client Relationship Account Manager');
        insert atm;
        
        Schema.RecordTypeInfo HRSDiscrepencyRT = RecordTypeHelper.getRecordType('HRS 4S LDPS Discrepancy', 'Case'); 
        //create two cases
        List<Case> cases = new List<Case>();
        cases.add( new Case (AccountId = account.id,
        					RecordTypeId = HRSDiscrepencyRT.getRecordTypeId(),
        					Status = 'New')); 
        cases.add( new Case (AccountId = account.id,
        					RecordTypeId = HRSDiscrepencyRT.getRecordTypeId(),
        					Status = 'New')); 
        insert cases;
        
        List<Case> allCases = [SELECT Id, Account_Manager__c FROM Case];				
        System.assertEquals('George Contact', allCases[0].Account_Manager__c);
        System.assertEquals('George Contact', allCases[1].Account_Manager__c);
        System.assertEquals(2, allCases.size());
    }
    
    static testMethod void cannotPopulateAccountManager()
    {
        Account account = new Account(Name='TestAccount'); 
        insert account;
        
        //Platinum Rep on an Account is a Contact 
        Contact contact = new Contact(	FirstName = 'George',
        								LastName = 'Contact',
        								AccountId = account.id);  
        insert contact;
    
    	Schema.RecordTypeInfo HRSDiscrepencyRT = RecordTypeHelper.getRecordType('HRS 4S LDPS Discrepancy', 'Case'); 
        Case c = new Case (AccountId = account.id,
        					RecordTypeId = HRSDiscrepencyRT.getRecordTypeId(),
        					Status = 'New'); 
        insert c;
        				
        List<Case> cases = [SELECT Id, Account_Manager__c FROM Case];				
        System.assertEquals(null, cases[0].Account_Manager__c);
    }
    
    static testMethod void populateAccountManagerWithoutCorrectTeamRolePopulated()
    {
        Account account = new Account(Name='TestAccount'); 
        insert account;
        
        //Platinum Rep on an Account is a Contact 
        Contact contact = new Contact(	FirstName = 'George',
        								LastName = 'Contact',
        								AccountId = account.id);  
        insert contact;
        
        User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
        User u = users[0];
        User u2 = users[1];

        List<AccountTeamMember> atms = new List<AccountTeamMember>();
        atms.add(new AccountTeamMember(UserId = u.id,
        											AccountId = account.id,
        											TeamMemberRole = 'Account Manager'));
        atms.add(new AccountTeamMember(UserId = u2.id,
        											AccountId = account.id,
        											TeamMemberRole = 'Sales'));											
        insert atms;
        
        Schema.RecordTypeInfo HRSDiscrepencyRT = RecordTypeHelper.getRecordType('HRS 4S LDPS Discrepancy', 'Case'); 
        Case c = new Case (AccountId = account.id,
        					RecordTypeId = HRSDiscrepencyRT.getRecordTypeId(),
        					Status = 'New'); 
        insert c;
        				
        List<Case> cases = [SELECT Id, Account_Manager__c FROM Case];				
        System.assertEquals(null, cases[0].Account_Manager__c);
    }
}