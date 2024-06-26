/**
 * This class contains unit tests for validating the ReferralContactValidation class.
 * 
 *
 * History
 * --------
 * 04/16/2013   Cindy Freeman   created
   08/38/2013   Dan Carmen      Modifications for Referral Contact Name field
 *
 */
 
@isTest
private class ReferralContactValidationTest {
    private static Integer testLimit = 100;
    
    static testMethod void refCtctTest1() {
        //User sa = [select id, isActive from User where Id = :UserInfo.getUserId() limit 1];
      ReferralObjectsSync.SKIP_SYNC = true;
        
        Schema.RecordTypeInfo hrsRefAcctRt = RecordTypeHelper.getRecordType('HRS Referral Source Record Type', 'Referral_Account__c');
        Schema.RecordTypeInfo hrsRefCtctRt = RecordTypeHelper.getRecordType('HRS Referral Record Type', 'Referral_Contact__c');
        
        Referral_Account__c refacct = new Referral_Account__c (name = 'Referral Account1'
                                ,RecordTypeId=hrsRefAcctRt.getRecordTypeId()
                                ,Referral_Type__c = 'Broker'
                                ,Zip_Postal_Code__c = '10000'
                                ,To_Be_Deleted__c = false);
        insert refacct;
                
        Referral_Contact__c refcon1 = new Referral_Contact__c(Name = 'First Ref Ctct1'
                                ,RecordTypeId=hrsRefCtctRt.getRecordTypeId()
                                ,Phone__c = '585-555-1212'
                                ,Email__c = 'fLast1@abc.com'
                                ,Referral_Type__c = '100 Broker'
                                ,Referral_Account__c = refacct.Id);
        insert refcon1;
        Referral_Contact__c refctct = [Select Id, To_Be_Deleted__c, Name from Referral_Contact__c where Id=:refcon1.Id];
        
        Test.startTest();
        refctct.To_Be_Deleted__c = true;
        //update refctct;     
        Database.SaveResult dsrA = Database.update(refctct, false);     
        System.assertEquals(dsrA.isSuccess(), true);    
        
        // reset flag for next test
        refctct.To_Be_Deleted__c = false;
        update refctct;
        Test.stopTest();
        
        // create prospect-client and link to referral contact
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name, CPA_Name_Ref__c, Broker_Name_ref__c, Banker_Name_ref__c from Account where name = 'Test Account2'];
        Contact c1 = [Select Id, Name, Referral_Contact__c from Contact where AccountId = :a1.Id and FirstName = 'First'];
        a1.CPA_Name_Ref__c = refctct.Id;
        a1.Broker_Name_ref__c = refctct.Id;
        a1.Banker_Name_ref__c = refctct.Id;
        update a1;      
        
        refctct.To_Be_Deleted__c = true;        
        Database.SaveResult dsrB = Database.update(refctct, false);     
        System.assertEquals(dsrB.isSuccess(), false);
        System.assertEquals(dsrB.getErrors()[0].getMessage(), 'Cannot be deleted due to related records');
                      
        a1.CPA_Name_Ref__c = null;
        a1.Broker_Name_ref__c = null;
        a1.Banker_Name_ref__c = null;
        update a1;
        
        // test with link to lead
        Id leedId = CreateTestData.createTestLead();
        Lead leed = [select Id, Name, Referral_Contact__c from Lead where id = :leedId];
        leed.Referral_Contact__c = refctct.Id;
        update leed;
        
        refctct.To_Be_Deleted__c = true;    
        Database.SaveResult dsrD = Database.update(refctct, false);     
        System.assertEquals(dsrD.isSuccess(), false);
        
        delete leed;    
        
        // test with link to Opportunity
        Id coreOptyId = CreateTestData.createTestCoreOptys(a1.Id, c1.Id);       
        Opportunity coreOpty = [Select Id, Internal_Referral__c, Referral_Contact__c from Opportunity where Id = :coreOptyId];
        coreOpty.Internal_Referral__c = refctct.Id;
        coreOpty.Referral_Contact__c = refctct.Id;      
        update coreOpty;
        refctct.To_Be_Deleted__c = true;        
        Database.SaveResult dsrE = Database.update(refctct, false);     
        System.assertEquals(false, dsrE.isSuccess());
        coreOpty.Internal_Referral__c = null;
        coreOpty.Referral_Contact__c = null;
        update coreOpty;
        
        //test with link to Case
        Schema.RecordTypeInfo coreCaseRt = RecordTypeHelper.getRecordType('Service Onboarding Core Payroll Case', 'Case');
        Case coreCase = new Case(RecordTypeId = coreCaseRt.getRecordTypeId()
                                    ,origin = 'New Business'
                                    ,contactId = c1.Id
                                    ,status = 'New'
                                    ,Referral_Contact__c = refctct.Id);
        insert coreCase;
        refctct.To_Be_Deleted__c = true;    
        Database.SaveResult dsrF = Database.update(refctct, false);     
        System.assertEquals(false, dsrF.isSuccess());
        delete coreCase;
        
                   
    } // refCtctTest1   

    static testMethod void refCtctTest1b() {
        //User sa = [select id, isActive from User where Id = :UserInfo.getUserId() limit 1];
        ReferralObjectsSync.SKIP_SYNC = true;
        Account payxAcct = CreateTestData.createPaychexEmp();
        
        Schema.RecordTypeInfo hrsRefAcctRt = RecordTypeHelper.getRecordType('HRS Referral Source Record Type', 'Referral_Account__c');
        Schema.RecordTypeInfo hrsRefCtctRt = RecordTypeHelper.getRecordType('HRS Referral Record Type', 'Referral_Contact__c');
        
        Referral_Account__c refacct = new Referral_Account__c (name = 'Referral Account1'
                                ,RecordTypeId=hrsRefAcctRt.getRecordTypeId()
                                ,Referral_Type__c = 'Broker'
                                ,Zip_Postal_Code__c = '10000'
                                ,To_Be_Deleted__c = false);
        insert refacct;
                
        Referral_Contact__c refcon1 = new Referral_Contact__c(Name = 'First Ref Ctct1'
                                ,RecordTypeId=hrsRefCtctRt.getRecordTypeId()
                                ,Phone__c = '585-555-1212'
                                ,Email__c = 'fLast1@abc.com'
                                ,Referral_Type__c = '100 Broker'
                                ,Referral_Account__c = refacct.Id);
        insert refcon1;
        Referral_Contact__c refctct = [Select Id, To_Be_Deleted__c, Name from Referral_Contact__c where Id=:refcon1.Id];
      
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name, CPA_Name_Ref__c, Broker_Name_ref__c, Banker_Name_ref__c from Account where name = 'Test Account2'];
        Contact c1 = [Select Id, Name, Referral_Contact__c from Contact where AccountId = :a1.Id and FirstName = 'First'];
  

        //test with link to Referral
        List<Contact> payxEmpList = payxAcct.Contacts;
         
        Referral__c refrl = new Referral__c(Name = 'Referral-999'
                                            ,Contact__c = payxEmpList.get(0).Id
                                            //,Referring_Opportunity__c = coreOpty.Id
                                            ,Referral_Contact__c = refctct.Id
                                            ,Account__c = a1.Id                                         
                                            ,SourceContact__c = c1.Id
                                            ,status__c = 'Pending');
        insert refrl;
        refctct.To_Be_Deleted__c = true;    
        Database.SaveResult dsrG = Database.update(refctct, false);     
        System.assertEquals(dsrG.isSuccess(), false);
        delete refrl;
        
        //test with link to activities
        // create event 
        datetime myDateTime = datetime.now();
        Event ev = new Event(WhatId = refctct.Id, ActivityDateTime = myDateTime, Type = 'Meeting', DurationInMinutes=60);
        insert ev;      
        refctct.To_Be_Deleted__c = true;
        Database.SaveResult dsrH = Database.update(refctct, false);     
        System.assertEquals(dsrH.isSuccess(), false);       
        delete ev;
        
        // create task
        date myDate = date.today();
        Task tsk = new Task(WhatId = refctct.Id, ActivityDate =  myDate, Subject = 'Meeting', Status='Not Started');
        insert tsk;
        refctct.To_Be_Deleted__c = true;
        Database.SaveResult dsrI = Database.update(refctct, false);     
        System.assertEquals(dsrI.isSuccess(), false);
                                            
    } // refCtctTest1b 

   // test bulk update of referral contacts
   static testMethod void refCtctTest2() {
      ReferralObjectsSync.SKIP_SYNC = true;
        Schema.RecordTypeInfo hrsRefAcctRt = RecordTypeHelper.getRecordType('HRS Referral Source Record Type', 'Referral_Account__c');
        Schema.RecordTypeInfo hrsRefCtctRt = RecordTypeHelper.getRecordType('HRS Referral Record Type', 'Referral_Contact__c');
        
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
        {   newRefAcctIds.add(ra.Id);   }
        
        List<Referral_Contact__c> newRefCtcts = new List<Referral_Contact__c>();
        
        for (Integer i = 1; i<= testLimit; i++)
        {   Referral_Contact__c newRC = new Referral_Contact__c(Name = 'First LastName'+i
                                ,RecordTypeId=hrsRefCtctRt.getRecordTypeId()
                                ,Phone__c = '585-555-1212'
                                ,Email__c = 'fLast1@abc.com'
                                ,Referral_Type__c = '100 Broker'
                                ,Referral_Account__c = newRefAcctIds.get(i-1));
            newRefCtcts.add(newRC);
        }
        insert newRefCtcts;
        List<Id> newRefCtctIds = new List<Id>();
        for (Referral_Contact__c rc: newRefCtcts)
        {   newRefCtctIds.add(rc.Id);   }
        
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType('Core Account Record Type', 'Account');
        List<Account> newAccts = new List<Account>();
        for (Integer i = 1; i <= (testLimit/2); i++) {
            Account acct1 = new Account (name = 'Test Account'+i
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567');
            if (math.mod(i,3) == 0) 
            {   acct1.CPA_Name_Ref__c = newRefCtctIds.get(i-1); }
            else if (math.mod(i,2) == 0)
            {   acct1.Broker_Name_ref__c = newRefCtctIds.get(i-1);  }
            else
            {   acct1.Banker_Name_ref__c = newRefCtctIds.get(i-1);  }
            newAccts.add(acct1);
        }
        insert newAccts;
                                         
        for (Referral_Contact__c rc: newRefCtcts)
        {   rc.To_Be_Deleted__c = true;     }
        
        Database.SaveResult[] dsrList = Database.update(newRefCtcts, false);
        Integer goodcnt = 0;
        Integer badcnt = 0;
        for (Database.SaveResult dsr:dsrList)
        {   if (dsr.isSuccess())
            {   goodcnt++;  }
            else
            {   badcnt++;   }
        }
        System.assertEquals((testLimit/2), goodcnt);
        System.assertEquals((testLimit/2), badcnt);
                    
    } // refAcctTest2

} // class ReferralContactValidationTest