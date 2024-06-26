/**
 * Test method for ClientReferencesMethods
 * 
 * History
 * --------
 * 03/02/2018 Cindy Freeman     modified for new ClientReference trigger and methods
 * 03/08/2018 Cindy Freeman     modified test for Contact with 1 name
   12/21/2022 Dan Carmen        Changed TriggerInterface, use SF Duplicate Management

*/

@isTest
private class ClientReferencesMethodsTest {
   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('ClientReferencesAfter', false, true, false, false,new String[]{'ClientReferencesMethods'});
      TriggerMethodsTest.saveSetupClasses();
   } // setupData

	
    static testMethod void myUnitTest1() {
 		
 		Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25
                                ,BIS_Id__c = 1001001);
        insert acct1;
        //User eram = [Select Id, Title from User where Title = 'Manager, Enterprise Relationship' and isActive = true limit 1];
        User eram = [Select Id, Title from User where Profile.Name = 'Enterprise Service Rep' and isActive = true limit 1];
        AccountTeamMember atm = new AccountTeamMember(UserId=eram.Id, TeamMemberRole='Enterprise Client Support Representative', AccountId=acct1.Id); 
        insert atm;
        
        Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,Sales_Contact__c = true);
       insert ctct1;
 		   	
	   ClientReferencesMethods crm = new ClientReferencesMethods();
 	      	
 	   Client_Reference__c cref = new Client_Reference__c(Bis_Id__c = 1001001,
 	   								Primary_Contact__c = 'First Last1',Primary_Contact_Email__c='fLast1@abc.com');
 	   insert cref;
 	   
 	   cref = [Select Id, Account__c, Contact__c, ERAM__c from Client_Reference__c where Id = :cref.Id];
 	   System.assertEquals(cref.Account__c, acct1.Id);
 	   System.assertEquals(cref.Contact__c, ctct1.Id);
 	   System.assertEquals(cref.ERAM__c, eram.Id);
       
    } // myUnitTest1
    
    static testMethod void myUnitTest2() {
 		
 		Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25
                                ,BIS_Id__c = 1001001);
        insert acct1;
              
	   ClientReferencesMethods crm = new ClientReferencesMethods();
 	      	
 	   Client_Reference__c cref = new Client_Reference__c(Bis_Id__c = 1001001,
 	   								Primary_Contact__c = 'First', Primary_Contact_Email__c='fLast1@abc.com');
 	   insert cref;
 	   
 	   cref = [Select Id, Account__c, Contact__c, ERAM__c from Client_Reference__c where Id = :cref.Id];
 	   System.assertEquals(cref.Account__c, acct1.Id);
        
       Contact ctct1 = [select Id, FirstName, LastName from Contact where FirstName = 'First' and LastName = 'First']; 
 	   System.assertEquals(cref.Contact__c, ctct1.Id); 	   
       
    } // myUnitTest2
    
     static testMethod void myUnitTest3() {
 		
 		Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25
                                ,BIS_Id__c = 1001001);
        insert acct1;
       
        Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,Sales_Contact__c = true);
       insert ctct1;
 		   	
	   ClientReferencesMethods crm = new ClientReferencesMethods();
 	      	
 	   Client_Reference__c cref = new Client_Reference__c(Bis_Id__c = 1001001,
 	   								Primary_Contact__c = 'First Last1',Primary_Contact_Email__c='fLast1@abc.com');
 	   insert cref;
 	   
 	   cref = [Select Id, Account__c, Contact__c, ERAM__c from Client_Reference__c where Id = :cref.Id];
 	   System.assertEquals(cref.Account__c, acct1.Id);
 	   System.assertEquals(cref.Contact__c, ctct1.Id);
       
    } // myUnitTest3
 
     static testMethod void myUnitTest4() {
 		
 		Schema.RecordTypeInfo acctMMSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctMMSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctMMSrt.getRecordTypeId()
                                ,type = 'Payroll'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25
                                ,BIS_Id__c = 1001001);
        insert acct1;
       
        Contact ctct1 = new Contact(Firstname = 'F'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctMMSrt.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,Sales_Contact__c = true);
       insert ctct1;
 		   	
	   ClientReferencesMethods crm = new ClientReferencesMethods();
 	      	
 	   Client_Reference__c cref = new Client_Reference__c(Bis_Id__c = 1001001,
 	   								Primary_Contact__c = 'First Last1',Primary_Contact_Email__c='fLast1@abc.com');
 	   insert cref;
 	   
 	   cref = [Select Id, Account__c, Contact__c, ERAM__c from Client_Reference__c where Id = :cref.Id];
 	   System.assertEquals(cref.Account__c, acct1.Id);
 	   System.assertEquals(cref.Contact__c, ctct1.Id);
       
    } // myUnitTest4
    
}