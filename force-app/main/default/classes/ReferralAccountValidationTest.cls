/**
 * This class contains unit tests for validating the ReferralAccountValidation class.
 * 
 *
 * History
 * --------
 * 04/16/2013	Cindy Freeman	created
   08/23/2016  Dan Carmen     Updated version number
   04/12/2022 Dan Carmen      Increment API

 */

@isTest
private class ReferralAccountValidationTest {
    private static Integer testLimit = 200;
    
    static testMethod void refAcctTest1() {
        Schema.RecordTypeInfo hrsRefAcctRt = RecordTypeHelper.getRecordType('HRS Referral Source Record Type', 'Referral_Account__c');
		Schema.RecordTypeInfo hrsRefCtctRt = RecordTypeHelper.getRecordType('HRS Referral Record Type', 'Referral_Contact__c');
		
        Referral_Account__c refacct1 = new Referral_Account__c (name = 'Referral Account1'
        						,RecordTypeId=hrsRefAcctRt.getRecordTypeId()
                                ,Referral_Type__c = 'Broker'
                                ,Zip_Postal_Code__c = '10000'
                                ,To_Be_Deleted__c = false);
        insert refacct1;
        
		refacct1.To_Be_Deleted__c = true;
		update refacct1;       
		
		refacct1 = [Select Id, To_Be_Deleted__c from Referral_Account__c where name = 'Referral Account1'];
		System.assertEquals(true, refacct1.To_Be_Deleted__c);
		
		// reset To_Be_Deleted__c
		refacct1.To_Be_Deleted__c = false;
		update refacct1;		
		
		// add referral contact to block To_Be_Deleted__c
		Referral_Contact__c refcon1 = new Referral_Contact__c(Name='First RefCtct1'
                                ,RecordTypeId=hrsRefCtctRt.getRecordTypeId()
                                ,Phone__c = '585-555-1212'
                                ,Email__c = 'fLast1@abc.com'
                                ,Referral_Type__c = '100 Broker'
                                ,Referral_Account__c = refacct1.Id);
        insert refcon1;
		
		refacct1.To_Be_Deleted__c = true;

		Database.SaveResult dsrA = Database.update(refacct1, false);		
		System.assertEquals(dsrA.isSuccess(), false);	
    	
    	// delete referral contact
    	delete refcon1;
    	
    	// create opty and link to referral account
    	CreateTestData.createTestAandC();
    	Account a1 = [select Id, Name from Account where name = 'Test Account2'];
        Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
    	Id coreOptyId = CreateTestData.createTestCoreOptys(a1.Id, ctct1.Id);
    	
    	Opportunity coreOpty = [Select Id, Name, Referral_Account__c from Opportunity where id = :coreOptyId];
    	coreOpty.Referral_Account__c = refacct1.Id;
    	
    	update coreOpty;
    	
    	// try to delete referral account again, should fail
		refacct1.To_Be_Deleted__c = true;
		Database.SaveResult dsrB = Database.update(refacct1, false);		
		System.assertEquals(dsrB.isSuccess(), false);	

		// delete opportunity
		delete coreOpty;

		// create event and link to referral account
		datetime myDateTime = datetime.now();
		Event ev = new Event(WhatId = refacct1.Id, ActivityDateTime = myDateTime, Type = 'Meeting', DurationInMinutes=60);
		insert ev;		
		// try to delete referral account again, should fail
		refacct1.To_Be_Deleted__c = true;
		Database.SaveResult dsrC = Database.update(refacct1, false);		
		System.assertEquals(dsrC.isSuccess(), false);	
		
		delete ev;
		
		// create task and link to referral account
		date myDate = date.today();
		Task tsk = new Task(WhatId = refacct1.Id, ActivityDate =  myDate, Subject = 'Meeting', Status='Not Started');
		insert tsk;
		// try to delete referral account again, should fail
		refacct1.To_Be_Deleted__c = true;
		Database.SaveResult dsrD = Database.update(refacct1, false);		
		System.assertEquals(dsrD.isSuccess(), false);
		System.assertEquals(true,dsrD.getErrors()[0].getMessage().startsWith('Cannot be deleted due to'));
    	
		        
    } // refAcctTest1
    
   // test bulk update of referral accounts
    static testMethod void refAcctTest2() {
		Schema.RecordTypeInfo hrsRefAcctRt = RecordTypeHelper.getRecordType('HRS Referral Source Record Type', 'Referral_Account__c');
		Schema.RecordTypeInfo hrsRefCtctRt = RecordTypeHelper.getRecordType('HRS Referral Record Type', 'Referral_Contact__c');
		// bypass the sync code for this test.
		ReferralObjectsSync.SKIP_SYNC = true;
        List<Referral_Account__c> newRefAccts = new List<Referral_Account__c> ();
        
        for (Integer i = 1; i<= testLimit; i++) {
        	Referral_Account__c newRefAcct = new Referral_Account__c(name = 'Referral Account'+i
        										,RecordTypeId=hrsRefAcctRt.getRecordTypeId()
                                				,Referral_Type__c = 'Broker'
                                				,Zip_Postal_Code__c = '10000'
                                				,To_Be_Deleted__c = false);
            newRefAccts.add(newRefAcct);
        }
        insert newRefAccts;
        List<Id> newRefAcctIds = new List<Id>();
        for (Referral_Account__c ra: newRefAccts)
        {	newRefAcctIds.add(ra.Id);	}
        
        List<Referral_Contact__c> newRefCtcts = new List<Referral_Contact__c>();
        
        for (Integer i = 1; i<= (testLimit/2); i++)
        {	Referral_Contact__c newRC = new Referral_Contact__c(Name='First RefCtct1'+i
                                ,RecordTypeId=hrsRefCtctRt.getRecordTypeId()
                                ,Phone__c = '585-555-1212'
                                ,Email__c = 'fLast1@abc.com'
                                ,Referral_Type__c = '100 Broker'
                                ,Referral_Account__c = newRefAcctIds.get(i));
            newRefCtcts.add(newRC);
        }
        insert newRefCtcts;

        List<Referral_Account__c> deletedRefAccts = [select Id, Name, (select Id from Referral_Contacts__r)
        							 from Referral_Account__c where Id in :newRefAcctIds];        							 
        for (Referral_Account__c ra: deletedRefAccts)
        {	ra.To_Be_Deleted__c = true;		
        	Referral_Contact__c[] refCtctList = ra.Referral_Contacts__r;
        }
        
        Database.SaveResult[] dsrList = Database.update(deletedRefAccts, false);
        Integer goodcnt = 0;
        Integer badcnt = 0;
        for (Database.SaveResult dsr:dsrList)
        {	if (dsr.isSuccess())
        	{	goodcnt++;	}
        	else
        	{	badcnt++;	}
        }
        System.assertEquals((testLimit/2), goodcnt);
        System.assertEquals((testLimit/2), badcnt);
        	        
    } // refAcctTest2
      
}