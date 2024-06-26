/*
 *    Retrieves the user's deleted events, prospect/clients, referral accounts, contacts, referral contacts
 
    07/06/2020  Jacob Hinds         Added without sharing per PMD
 *
 */

@RestResource(urlMapping='/deletedItems/*')
global without sharing class DeletedItems
{
    @HttpGet
    global static Item getDeletedItems()
    {
        Item it = new Item();
        DateTime modifiedDate = null;
    
        try
        {
            String modifiedDate_str = '';
            if (RestContext.request != null)
            {
                modifiedDate_str = RestContext.request.params.get('date');
                modifiedDate = getModifiedDate(modifiedDate_str);
            }
        }
        catch(Exception e)
        {
            //if there is an error, return empty 
            it.errors.add(new Error('param', e.getMessage()));
            return it;
        }
        
        return getItems(modifiedDate);
    }
    
    global static DateTime getModifiedDate(String modifiedDate)
    {
        if (!String.isBlank(modifiedDate))
        {
            //convert the UTC date to something parseable by the valueOf() method
            modifiedDate = modifiedDate.replaceAll('T', ' ').substringBefore('.');
        }
        else
        {
            return null;
        }
        
        return DateTime.valueOfGmt(modifiedDate);
    }
    
    global static Item getItems(DateTime modifiedDate)
    {
        Item it = new Item();
    
        try
        {
            for (Event e : [SELECT Id, LastModifiedDate FROM Event WHERE IsDeleted = true AND LastModifiedDate >=: modifiedDate AND OwnerId =: UserInfo.getUserId() ALL ROWS])
            {
                it.results.add(new Result('Event', e.Id, e.LastModifiedDate));
            }
        }
        catch (Exception e)
        {
            it.errors.add(new Error('Event', e.getMessage()));
        }

        try
        {
            for (Account e : [SELECT Id, LastModifiedDate FROM Account WHERE IsDeleted = true AND LastModifiedDate >=: modifiedDate AND OwnerId =: UserInfo.getUserId() ALL ROWS])
            {
                it.results.add(new Result('Account', e.Id, e.LastModifiedDate));
            }
        }
        catch (Exception e)
        {
            it.errors.add(new Error('Account', e.getMessage()));
        }
        
        try
        {
            for (Referral_Account__c e : [SELECT Id, LastModifiedDate FROM Referral_Account__c WHERE IsDeleted = true AND LastModifiedDate >=: modifiedDate AND OwnerId =: UserInfo.getUserId() ALL ROWS])
            {
                it.results.add(new Result('Referral_Account__c', e.Id, e.LastModifiedDate));
            }
        }
        catch (Exception e)
        {
            it.errors.add(new Error('Referral_Account__c', e.getMessage()));
        }
        
        try
        {
            for (Contact e : [SELECT Id, LastModifiedDate FROM Contact WHERE IsDeleted = true AND LastModifiedDate >=: modifiedDate AND OwnerId =: UserInfo.getUserId() ALL ROWS])
            {
                it.results.add(new Result('Contact', e.Id, e.LastModifiedDate));
            }
        }
        catch (Exception e)
        {
            it.errors.add(new Error('Contact', e.getMessage()));
        }
        
        try
        {
            for (Referral_Contact__c e : [SELECT Id, LastModifiedDate FROM Referral_Contact__c WHERE IsDeleted = true AND LastModifiedDate >=: modifiedDate AND OwnerId =: UserInfo.getUserId() ALL ROWS])
            {
                it.results.add(new Result('Referral_Contact__c', e.Id, e.LastModifiedDate));
            }
        }
        catch (Exception e)
        {
            it.errors.add(new Error('Referral_Contact__c', e.getMessage()));
        }
        
        return it;
    }
    
    global class Item
    {
        List<Result> results = new List<Result>();
        List<Error> errors = new List<Error>();
    }
    
    global class Result
    {
        String objectType = '';
        String id = '';
        DateTime modifiedDate = null;
        
        global Result(String objectType, String id, DateTime modifiedDate)
        {
            this.objectType = objectType;
            this.id = id;
            this.modifiedDate = modifiedDate;
        }
    }
    
    global class Error
    {
        String objectType = '';
        String message = '';
        
        global Error(String objectType, String message)
        {
            this.objectType = objectType;
            this.message = message;
        }
    }
    
    @isTest
    global static void test_invokePOJO()
    {
        Error e = new Error('', '');
    }
    
    @isTest
    global static void test_noDate()
    {
        Account a = new Account(Name = 'Name');
        insert a;
        delete a;
        
        Test.startTest();
        Item it = getDeletedItems();
        Test.stopTest();
        
        System.assertEquals(1, it.results.size());
        System.assertEquals(a.Id, it.results[0].id);
        System.assertEquals(0, it.errors.size());
    }
    
    @isTest
    global static void test_getModifiedDate()
    {
        DateTime result1 = getModifiedDate('');
        System.assertEquals(null, result1);
        
        DateTime result2 = getModifiedDate('2013-05-27T18:36:40.000Z');
        System.assertEquals(DateTime.newInstanceGmt(2013,5,27,18,36,40), result2);
    }
    
    @isTest
    global static void test_AccountNoDate()
    {
        Account a = new Account(Name = 'Name');
        insert a;
        delete a;
        
        DateTime dt = null;
        
        Test.startTest();
        Item it = getItems(dt);
        Test.stopTest();
        
        System.assertEquals(1, it.results.size());
        System.assertEquals(a.Id, it.results[0].id);
        System.assertEquals(0, it.errors.size());
    }
    
    @isTest
    global static void test_deletedEvent()
    {
        Account a = new Account(Name = 'Name');
        insert a;
        
        Event e = new Event(WhatId = a.Id, StartDateTime = DateTime.now(), EndDateTime = DateTime.now().addHours(2));
        insert e;
        
        DateTime dt = DateTime.now().addMinutes(-1);
        
        Item it1 = getItems(dt);
        System.assertEquals(0, it1.results.size());
        System.assertEquals(0, it1.errors.size());
        
        delete e;
        Event[] events = [SELECT Id, LastModifiedDate FROM Event WHERE Id =: e.Id ALL ROWS];
        
        Item it2 = getItems(dt);
        System.assertEquals(0, it2.errors.size());
        System.assertEquals(1, it2.results.size());
        System.assertEquals('Event', it2.results[0].objectType);
        System.assertEquals(events[0].Id, it2.results[0].id);
        System.assertEquals(events[0].LastModifiedDate, it2.results[0].modifiedDate);
    }
    
    @isTest
    global static void test_deletedAccount()
    {
        Account a = new Account(Name = 'Name');
        insert a;
        
        DateTime dt = DateTime.now().addMinutes(-1);
        
        Item it1 = getItems(dt);
        System.assertEquals(0, it1.results.size());
        System.assertEquals(0, it1.errors.size());
        
        delete a;
        Account[] accts = [SELECT Id, LastModifiedDate FROM Account WHERE Id =: a.Id ALL ROWS];
        
        Item it2 = getItems(dt);
        System.assertEquals(0, it2.errors.size());
        System.assertEquals(1, it2.results.size());
        System.assertEquals('Account', it2.results[0].objectType);
        System.assertEquals(accts[0].Id, it2.results[0].id);
        System.assertEquals(accts[0].LastModifiedDate, it2.results[0].modifiedDate);
    }
        
    @isTest
    global static void test_deletedContact()
    {
        Account a = new Account(Name = 'Name');
        insert a;
        
        Contact c = new Contact(LastName = 'LastName', AccountId = a.Id);
        insert c;
        
        DateTime dt = DateTime.now().addMinutes(-1);
        
        Item it1 = getItems(dt);
        System.assertEquals(0, it1.errors.size());
        System.assertEquals(0, it1.results.size());
        
        delete c;
        Contact[] contacts = [SELECT Id, LastModifiedDate FROM Contact WHERE Id =: c.Id ALL ROWS];
        
        Item it2 = getItems(dt);
        System.assertEquals(0, it2.errors.size());
        System.assertEquals(1, it2.results.size());
        System.assertEquals('Contact', it2.results[0].objectType);
        System.assertEquals(contacts[0].Id, it2.results[0].id);
        System.assertEquals(contacts[0].LastModifiedDate, it2.results[0].modifiedDate);
    }
    
    @isTest
    global static void test_deletedReferralAccount()
    {
        Referral_Account__c a = new Referral_Account__c(Name = 'Name', Referral_Source_Business_Type__c = 'Broker', Street_Address_1__c = '123 Main St', City__c = 'city', State_Province__c = 'il', Zip_Postal_Code__c = '60606');
        insert a;
        
        DateTime dt = DateTime.now();
        
        Item it1 = getItems(dt);
        System.assertEquals(0, it1.results.size());
        System.assertEquals(0, it1.errors.size());
        
        delete a;
        Referral_Account__c[] accts = [SELECT Id, LastModifiedDate FROM Referral_Account__c WHERE Id =: a.Id ALL ROWS];
        
        Item it2 = getItems(dt);
        System.assertEquals(0, it2.errors.size());
        System.assertEquals(1, it2.results.size());
        System.assertEquals('Referral_Account__c', it2.results[0].objectType);
        System.assertEquals(accts[0].Id, it2.results[0].id);
        System.assertEquals(accts[0].LastModifiedDate, it2.results[0].modifiedDate);
    }
    
    @isTest
    global static void test_deletedReferralContact()
    {
        Referral_Account__c a = new Referral_Account__c(Name = 'Name', Referral_Source_Business_Type__c = 'Broker', Street_Address_1__c = '123 Main St', City__c = 'city', State_Province__c = 'il', Zip_Postal_Code__c = '60606');
        insert a;
        
        Referral_Contact__c c = new Referral_Contact__c(Name = 'LastName', Referral_Account__c = a.Id, Phone__c = '1233454567');
        insert c;
        
        DateTime dt = DateTime.now().addMinutes(-1);
        
        Item it1 = getItems(dt);
        System.assertEquals(0, it1.errors.size());
        System.assertEquals(0, it1.results.size());
        
        delete c;
        Referral_Contact__c[] contacts = [SELECT Id, LastModifiedDate FROM Referral_Contact__c WHERE Id =: c.Id ALL ROWS];
        
        Item it2 = getItems(dt);
        System.assertEquals(0, it2.errors.size());
        System.assertEquals(1, it2.results.size());
        System.assertEquals('Referral_Contact__c', it2.results[0].objectType);
        System.assertEquals(contacts[0].Id, it2.results[0].id);
        System.assertEquals(contacts[0].LastModifiedDate, it2.results[0].modifiedDate);
    }
    
    @isTest
    global static void test_multiple()
    {
        Account a = new Account(Name = 'Name');
        insert a;
        
        Contact c = new Contact(LastName = 'LastName', AccountId = a.Id);
        insert c;
        
        DateTime dt = DateTime.now().addMinutes(-1);
        
        Item it1 = getItems(dt);
        System.assertEquals(0, it1.errors.size());
        System.assertEquals(0, it1.results.size());
        
        delete c;
        delete a;
        
        Item it2 = getItems(dt);
        System.assertEquals(0, it2.errors.size());
        System.assertEquals(2, it2.results.size());
    }
}