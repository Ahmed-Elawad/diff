/**
 * This class contains unit tests for validating the CreateRelatedObjects class
 * 
 *
 * History
 * --------
 * 03/21/2013   Cindy Freeman   created
 * 07/09/2013   Cindy Freeman   added test for duplicate prevention
 * 10/06/2013   Cindy Freeman   modified to test (ID) in constant and to use longer FilterCriteria field
 * 03/17/2014   Cindy Freeman   fixed test so field lengths match
   02/17/2016   Dan Carmen      reduced test limit due to long running test. 
   04/20/2016   Jacob Hinds     removing TAA Support Specialist field
   11/17/2047   Lynn Michels    try to fix CPU error
   12/04/2017   Cindy Freeman   reduce testLimit to 50 to fix CPU error 
   02/24/2020 Dan Carmen      Increment API to 48
 */
 
@isTest
private class CreateRelatedObjectsTest {
    private static Integer testLimit = 25;  //100;

    static testMethod void objRelTest1() {
                
        Object_Relationships__c orc1 = createObjectRelationships1();
        Object_Relationships__c orc2 = createObjectRelationships2();
         
        Set<String> optyRcdTypes = CreateRelatedObjects2.getObjRelOptyRcdTypes();
        System.assertEquals(1, optyRcdTypes.size());                    // both relationships are off Core Opty record type
        
        Schema.RecordTypeInfo coreCaseRt = RecordTypeHelper.getRecordType('Service Onboarding Core Payroll Case','Case');
        Schema.RecordTypeInfo mmsCaseRt = RecordTypeHelper.getRecordType('Service Onboarding MMS Payroll Case','Case');
            
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name from Account where name = 'Test Account2'];
        Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
        
        List<Id> testOptyIds = new List<Id>();
        
        // create opty that meets criteria and creates 2 cases
        testOptyIds.add(CreateTestData.createTestCoreOptys(a1.Id, ctct1.Id));       
        CreateTestData.createReferralAandC();        
        Referral_Contact__c refCt = [Select Id, Name from Referral_Contact__c where Last_Name__c = 'Ref Ctct1'];
        
        // create opty that doesnt meet filter criteria so no case is created
        testOptyIds.add(CreateTestData.createTestCoreOptys(a1.Id, ctct1.Id));

        // create opty that doesnt have object relationship defined
        testOptyIds.add(CreateTestData.createTestPEOOptys(a1.Id, ctct1.Id));
        System.debug('objRelTest1 after create test data');
        
        Opportunity[] testOptys = [Select Id, AccountId, Service_Location__c, OwnerId, CloseDate, StageName, Referral_Contact__c, Owner.ManagerId 
                                    from Opportunity where Id in :testOptyIds order by Id];
        System.debug('objRelTest1 number of testOptys='+testOptys.size());
        
        testOptys.get(0).Referral_Contact__c = refCt.Id;
        testOptys.get(0).StageName = 'Sold';
        testOptys.get(0).Service_Location__c = 'Foxboro Branch 0008';
        testOptys.get(0).Prod_Payroll__c = true;
        
        testOptys.get(1).Service_Location__c = 'Test Service Location';
        testOptys.get(1).StageName = 'Sold';
        testOptys.get(1).NSS_Rep__c = 'Joe NSS';
        testOptys.get(1).Prod_Payroll__c = true;
        
        testOptys.get(2).Service_Location__c = 'Buffalo Branch 0045';
        testOptys.get(2).StageName = 'Sold';
        
        Test.startTest();
        System.debug('objRelTest1 before update testOptys');
        update testOptys;
        System.debug('objRelTest1 after update testOptys');
        Test.stopTest();

        Case newCoreCase = [Select Id, RecordTypeId, AccountId, Service_Location__c, User__c, Opportunity__c, Origin, 
                            ContactId, Opportunity__r.CloseDate, Opportunity__r.OwnerId, X1099_Wages__c, Actual_Hours__c, Description                                              
                             from Case 
                            where Opportunity__c = :testOptyIds.get(0) 
                            and RecordTypeId = :coreCaseRt.getRecordTypeId()
                            and origin = 'New Business Test'];
        System.debug('objRelTest1 after selecting case');

        System.assertEquals(orc1.Related_Object_Rcd_Type_Id__c, newCoreCase.RecordTypeId);
        System.assertEquals(testOptys.get(0).AccountId, newCoreCase.AccountId);
        System.assertEquals(testOptys.get(0).Service_Location__c, newCoreCase.Service_Location__c);
        System.assertEquals(testOptys.get(0).Owner.ManagerId, newCoreCase.User__c);
        System.assertEquals(testOptys.get(0).Id, newCoreCase.Opportunity__c);
        System.assertEquals('New Business Test', newCoreCase.Origin);
        System.assertEquals(12.5, newCoreCase.Actual_Hours__c);
        System.assertEquals(true, newCoreCase.X1099_Wages__c);
            
        Case newMMSCase = [select Id, RecordTypeId, Opportunity__c 
                                from Case 
                                where Opportunity__c = :testOptyIds.get(0)
                                and RecordTypeId = :mmsCaseRt.getRecordTypeId()];
        System.assertNotEquals(null, newMMSCase);
            
        Case[] newCoreCase2 = [Select Id, RecordTypeId, AccountId from Case 
                            where Opportunity__c = :testOptyIds.get(1) and Origin = 'New Business Test'];
        System.assertEquals(0, newCoreCase2.size());

        Case[] newPeoCase = [Select Id, RecordTypeId, AccountId from Case 
                            where Opportunity__c = :testOptyIds.get(2)];
        System.assertEquals(0, newPeoCase.size()); 
                
        System.debug('objRelTest1 before delete newMMSCase');
        // change opty back to pending then back to sold to be sure doesnt create duplicate cases
        delete newMMSCase;
        Opportunity opty0 = [select id, StageName from Opportunity where id = :testOptyIds.get(0)];
        opty0.StageName = 'Pending';
        System.debug('objRelTest1 before update opty0 - 1');
        update opty0;
        opty0.StageName = 'Sold';
        System.debug('objRelTest1 before update opty0 - 2');
        update opty0;
        Case[] coreCase = [Select Id, RecordTypeId, AccountId, Opportunity__c from Case where Opportunity__c = :testOptyIds.get(0)];
        System.assertEquals(2, coreCase.size());
        
    } // objRelTest1
/*
    // test bulk create of related objects
    static testMethod void objRelTest2() {
        Id coreOpptyRt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Core Opportunity Record Type').getRecordTypeId(); 
        //Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        Object_Relationships__c orc1 = createObjectRelationships1();
            
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name from Account where name = 'Test Account2'];
        Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
        
        List<Opportunity> newOptys = new List<Opportunity> ();
        
        for (Integer i = 1; i<= testLimit; i++) {
            Opportunity newOpty = new Opportunity(Name='Test Core Oppty'+i
                                       //  ,RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,RecordTypeId=coreOpptyRt
                                         ,AccountId=a1.Id
                                         ,StageName='Pending'
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
            newOptys.add(newOpty);
        }
        insert newOptys;
        
        List<Id> optyIds = new List<Id>();
        for (Opportunity newo:newOptys) {
          optyIds.add(newo.Id);  
        }
        
        System.assertEquals(testLimit, optyIds.size());
        
        for (Opportunity opty: newOPtys) {
            opty.TotalOpportunityQuantity = 1;
            opty.Employees_Paid_Per_Payroll__c = 2;
            opty.Frequency__c = '1';
            opty.Amount = 100;
            opty.StageName = 'Sold';
            opty.Service_Location__c = 'Foxboro Branch 0008';
            opty.Prod_Payroll__c = true;            
        }
        
        Test.startTest();
        update newOptys;
        Test.stopTest();
        
        List<Case> newCases = [Select Id, Opportunity__c from Case where Opportunity__c in :optyIds and origin = 'New Business Test'];
        System.assertEquals(testLimit, newCases.size());
            
    } // objRelTest2
       
    */
    static Object_Relationships__c createObjectRelationships1() {
        Id coreCaseRt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Core Opportunity Record Type').getRecordTypeId();
       // Schema.RecordTypeInfo coreCaseRt = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity');
        Group goodQ = [Select Id, Name, Type from Group where Type = 'Queue' limit 1];
        // insert Object relationship Opportunity to Case
        Object_Relationships__c temporc1 = new Object_Relationships__c(Primary_Object_API_name__c = 'Opportunity'
                                                                    , Primary_Object_Rcd_Type__c = 'Core Opportunity Record Type'
                                                                   // , Primary_Object_Rcd_Type_Id__c = coreCaseRt.getRecordTypeId()
                                                                    , Primary_Object_Rcd_Type_Id__c = coreCaseRt
                                                                    , Related_Object_API_name__c = 'Case'
                                                                    , Related_Object_Rcd_Type__c = 'Service Onboarding Core Payroll Case'
                                                                    , IsActive__c = true);
        insert temporc1;
        Object_Relationships__c orc1 = [Select Id, Primary_Object_API_name__c, Primary_Object_Rcd_Type__c, Primary_Object_Rcd_Type_Id__c,
                                        Related_Object_API_name__c, Related_Object_Rcd_Type__c, Related_Object_Rcd_Type_Id__c
                                        from Object_Relationships__c where Id = :temporc1.Id];
                                        
        List<Object_Relationships_Fields__c> listOptyorfs = new List<Object_Relationships_Fields__c>();     
        Object_Relationships_Fields__c orf1 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_Field_API_name__c = 'AccountId'
                                                        , Related_Field_API_name__c = 'AccountId');
        listOptyorfs.add(orf1);
        Object_Relationships_Fields__c orf2 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_Field_API_name__c = 'Service_Location__c'
                                                        , Related_Field_API_name__c = 'Service_Location__c');
        listOptyorfs.add(orf2);    
        Object_Relationships_Fields__c orf3 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_Field_API_name__c = 'Owner.ManagerId'
                                                        , Related_Field_API_name__c = 'User__c');
        listOptyorfs.add(orf3);    
        Object_Relationships_Fields__c orf4 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_Field_API_name__c = 'Id'
                                                        , Related_Field_API_name__c = 'Opportunity__c');
        listOptyorfs.add(orf4);    
        Object_Relationships_Fields__c orf5 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Field_Constant__c = 'New Business Test'
                                                        , Related_Field_API_name__c = 'Origin');
        listOptyorfs.add(orf5);    
        //Object_Relationships_Fields__c orf6 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
        //                                              , Queue__c = goodQ.Name
        //                                              , Related_Field_API_name__c = 'OwnerId');
        //listOptyorfs.add(orf6); 
        Object_Relationships_Fields__c orf7 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Field_Constant__c = 'True'
                                                        , Related_Field_API_name__c = 'X1099_Wages__c');
        listOptyorfs.add(orf7);    
        Object_Relationships_Fields__c orf8 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Field_Constant__c = '12.5'
                                                        , Related_Field_API_name__c = 'Actual_Hours__c');
        listOptyorfs.add(orf8);    
        Account payxAcct = CreateTestData.createPaychexEmp();
        List<Contact> payxEmpList = payxAcct.Contacts;
        Object_Relationships_Fields__c orf8c = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Field_Constant__c = '(ID)'+payxEmpList.get(0).Id
                                                        , Related_Field_API_name__c = 'Alternate_Contact__c');
        listOptyorfs.add(orf8c);
        Object_Relationships_Fields__c orf9 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_Field_API_name__c = 'Paychex_Payroll_Specialist_Name__c'
                                                        , Primary_Object_API_name__c = 'Account'
                                                        , Related_Field_API_name__c = 'Bank_Name__c');
                                                        
        listOptyorfs.add(orf9);    
        Object_Relationships_Fields__c orf10 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_Field_API_name__c = 'Name'
                                                        , Primary_Object_API_name__c = 'Referral_Contact__c'
                                                        , Primary_Relationship_API_name__c = 'Referral_Contact__c'
                                                        , Related_Field_API_name__c = 'Description');
        listOptyorfs.add(orf10);     
        Object_Relationships_Fields__c orf11 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_Field_API_name__c = 'Service_Location__c'
                                                        , isFilter__c = true
                                                        , FilterCriteria__c = 'Foxboro Branch 0008,Buffalo Branch 0045');
        listOptyorfs.add(orf11);    
        Object_Relationships_Fields__c orf12 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_Field_API_name__c = 'BillingPostalCode'
                                                        , Primary_Object_API_name__c = 'Account'
                                                        , isFilter__c = true
                                                        , FilterCriteria__c = '10000');
        listOptyorfs.add(orf12); 
        Object_Relationships_Fields__c orf13 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_Field_API_name__c = 'Stagename'
                                                        , isFilter__c = true
                                                        , FilterCriteria__c = 'not null');
        listOptyorfs.add(orf13);    
        Object_Relationships_Fields__c orf14 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_Field_API_name__c = 'NSS_Rep__c'
                                                        , isFilter__c = true
                                                        , FilterCriteria__c = 'null');
        listOptyorfs.add(orf14);    
                 
        insert listOptyorfs;
        Object_Relationships_Fields__c[] newORFs = [select Id, Primary_Field_API_name__c, Field_Constant__c, isFilter__c from Object_Relationships_Fields__c];
        System.assertEquals(14, newORFs.size());
        
        return orc1;
    } // createObjectRelationships1

    static Object_Relationships__c createObjectRelationships2() {
            
        Schema.RecordTypeInfo coreCaseRt = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity');
        // cretae 2nd relationship still Core Oppty to a different Case
        Object_Relationships__c temporc2 = new Object_Relationships__c(Primary_Object_API_name__c = 'Opportunity'
                                                                    , Primary_Object_Rcd_Type__c = 'Core Opportunity Record Type'
                                                                    , Primary_Object_Rcd_Type_Id__c = coreCaseRt.getRecordTypeId()
                                                                    , Related_Object_API_name__c = 'Case'
                                                                    , Related_Object_Rcd_Type__c = 'Service Onboarding MMS Payroll Case'
                                                                    , IsActive__c = true);
        insert temporc2;
        Object_Relationships__c orc2 = [Select Id, Primary_Object_API_name__c, Primary_Object_Rcd_Type__c, Primary_Object_Rcd_Type_Id__c,
                                        Related_Object_API_name__c, Related_Object_Rcd_Type__c, Related_Object_Rcd_Type_Id__c
                                        from Object_Relationships__c where Id = :temporc2.Id];
                                        
        List<Object_Relationships_Fields__c> list2Optyorfs = new List<Object_Relationships_Fields__c>();     
        Object_Relationships_Fields__c orf21 = new Object_Relationships_Fields__c(Object_Relationships__c = orc2.Id
                                                        , Primary_Field_API_name__c = 'AccountId'
                                                        , Related_Field_API_name__c = 'AccountId');
        list2Optyorfs.add(orf21);
        Object_Relationships_Fields__c orf22 = new Object_Relationships_Fields__c(Object_Relationships__c = orc2.Id
                                                        , Primary_Field_API_name__c = 'Id'
                                                        , Related_Field_API_name__c = 'Opportunity__c');
        list2Optyorfs.add(orf22);
        Object_Relationships_Fields__c orf23 = new Object_Relationships_Fields__c(Object_Relationships__c = orc2.Id
                                                        , Field_Constant__c = 'Test Case'
                                                        , Related_Field_API_name__c = 'Subject');
        list2Optyorfs.add(orf23);
        Object_Relationships_Fields__c orf24 = new Object_Relationships_Fields__c(Object_Relationships__c = orc2.Id
                                                        , Primary_Field_API_name__c = 'BillingPostalCode'
                                                        , Primary_Object_API_name__c = 'Account'
                                                        , isFilter__c = true
                                                        , FilterCriteria__c = 'not null');
        list2Optyorfs.add(orf24);            
        insert list2Optyorfs;

        Object_Relationships_Fields__c[] newORFs = [select Id, Primary_Field_API_name__c, Field_Constant__c, isFilter__c 
                        from Object_Relationships_Fields__c where Object_Relationships__c = :orc2.Id];
        System.assertEquals(4, newORFs.size());
        
        return orc2;
        
    } // createObjectRelationships2    

} // class CreateRelatedObjectsTest