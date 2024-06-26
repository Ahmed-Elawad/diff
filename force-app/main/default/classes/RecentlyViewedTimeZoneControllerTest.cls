/* 
 *  Test for RecentlyViewedTimeZoneController.
 *   
 * History
 * -------
 * 06/16/2016 Justin Stouffer Created
 */

@isTest
public class RecentlyViewedTimeZoneControllerTest {
    
    static testMethod void testNoZipOrPhone(){
		user u = [Select Id from user where isActive = TRUE and profile.name = 'System Administrator' Limit 1];
        system.runAs(u){        
            AreaCode__c testAC = new AreaCode__c(Name = '585', TimeZoneName__c = 'America/Los Angeles', TimeZoneAbbrev__c = 'PT');
            insert testAC;
            Zip_Code_Information__c testZCI = new Zip_Code_Information__c(Name = '14514', TimeZoneName__c = 'America/New York', TimeZoneAbbrev__c = 'ET');
            insert testZCI;
            account testAccount = new Account(Name='TimeZoneTestAccount', billingPostalCode='14514', shippingPostalCode ='14514', phone = '(585) 234-5678');
            insert testAccount;
            testAccount = [SELECT Name, ID, billingPostalCode, shippingPostalCode, phone FROM account where Name='TimeZoneTestAccount' LIMIT 1 FOR VIEW];
            contact testContact = new Contact(FirstName = 'TimeZone', LastName = 'TestContact', Accountid = testAccount.Id);
            insert testContact;
            testContact = [SELECT ID, FirstName, LastName, Accountid FROM contact where LastName = 'TestContact' LIMIT 1 FOR VIEW];
            recentlyViewedTimeZoneController rVTZC = new recentlyViewedTimeZoneController();
            system.assert(rVTZC.okToDisplay);
            testAccount.billingPostalCode = NULL;
            testAccount.shippingPostalCode = NULL;
            testAccount.phone = NULL;
            update testAccount;
            rVTZC = new recentlyViewedTimeZoneController();
            system.assert(!rVTZC.okToDisplay);
        }
    }
    
    static testMethod void testBasicFunction(){
		user u = [Select Id from user where isActive = TRUE and profile.name = 'System Administrator' Limit 1];
        system.runAs(u){
            AreaCode__c testAC = new AreaCode__c(Name = '585', TimeZoneName__c = 'America/Los Angeles', TimeZoneAbbrev__c = 'PT');
            insert testAC;
            Zip_Code_Information__c testZCI = new Zip_Code_Information__c(Name = '14514', TimeZoneName__c = 'America/New York', TimeZoneAbbrev__c = 'ET');
            insert testZCI;
            account testAccount = new Account(Name='TimeZoneTestAccount', billingPostalCode='14514', shippingPostalCode ='14514', phone = '(585) 234-5678');
            insert testAccount;
            testAccount = [SELECT Name, ID, billingPostalCode, shippingPostalCode, phone FROM account where Name='TimeZoneTestAccount' LIMIT 1 FOR VIEW];
            contact testContact = new Contact(FirstName = 'TimeZone', LastName = 'TestContact', Accountid = testAccount.Id);
            insert testContact;
            testContact = [SELECT ID, FirstName, LastName, Accountid FROM contact where LastName = 'TestContact' LIMIT 1 FOR VIEW];
            recentlyViewedTimeZoneController rVTZC = new recentlyViewedTimeZoneController();
            system.assertEquals(rVTZC.TimeZoneName, testZCI.TimeZoneName__c);
            system.assertEquals(rVTZC.TimeZoneAbbrv, testZCI.TimeZoneAbbrev__c);
            testAccount.billingPostalCode = NULL;
            update testAccount;
            rVTZC = new recentlyViewedTimeZoneController();
            system.assertEquals(rVTZC.TimeZoneName, testZCI.TimeZoneName__c);
            system.assertEquals(rVTZC.TimeZoneAbbrv, testZCI.TimeZoneAbbrev__c);
            testAccount.shippingPostalCode = NULL;
            update testAccount;
            rVTZC = new recentlyViewedTimeZoneController();
            system.assertEquals(rVTZC.TimeZoneName, testAC.TimeZoneName__c);
            system.assertEquals(rVTZC.TimeZoneAbbrv, testAC.TimeZoneAbbrev__c);
        }
    }
}