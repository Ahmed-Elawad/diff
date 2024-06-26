/* 
 * Test methods for the NSSMethods
 *
 * History
 * -------
 * 09/11/2014 Cindy Freeman     Created
 * 08/24/2015 Cindy Freeman		changed from using Utilities.PROF_NSS_CORE_HRS to hard coded NSS Outbound Rep
   06/25/2021 Dan Carmen        Fix Test Class, increment API version
   05/10/2022 Dan Carmen        Changed running user

 */
@isTest
private class NSSMethodsTest {

    static testMethod void myUnitTest() {
        Lead ld1 = new Lead(Firstname = 'Mary',Lastname = 'Lead1',Company = 'Test Account',Phone = '555-3333',MobilePhone = '111-1122', Other_Phone__c = '111-3434',PostalCode = '10000', Dialed__c = false);
        insert ld1;        
        Lead ld2 = new Lead(Firstname = 'John',Lastname = 'Lead2',Company = 'Test99 Account3',Phone = '555-3333',PostalCode = '10000', Dialed__c = false, DuplicatePhoneDT_HRS__c = date.today()-16);
        insert ld2;
        
        Id [] fixedSoslResults;
        Lead[] leadList = [Select Id, Name, DuplicatePhone_PAY__c, DuplicatePhoneDT_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_HRS__c,
                            NSS_WorkablePayroll__c, NSS_WorkableHRS__c, LatestCallTime__c from Lead where Id=:ld2.Id];
        fixedSoslResults = new Id[leadList.size()];                                             
        for (Lead ld: leadList)
        {   fixedSoslResults.add(ld.Id);    }                           
        Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query
            
        String otype = NSSMethods.getObjType(ld1.Id);
        System.assertEquals('Lead', otype);
        
        Set<Id> dialedIdsSet = new Set<Id>{ld1.Id};
        //User u = [Select Id, Name, NSS_Team__c from User where IsActive=true and Profile.Name= :Utilities.PROF_NSS_CORE_HRS limit 1];
        User u = [Select Id, Name, NSS_Team__c from User where IsActive=true and Profile.Name= 'NSS Outbound Rep' limit 1];
        u.NSS_Team__c = 'PAY';
        update u;
        
        User runnningUser = UserHelper.getRunningUser();
        System.runAs(runnningUser) {                           
            NSSMethods.checkDuplicatePhone(dialedIdsSet, u.Id);
            Lead updatedLead = [Select Id, Name, DuplicatePhone_PAY__c, DuplicatePhoneDT_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_HRS__c,
                            NSS_WorkablePayroll__c, NSS_WorkableHRS__c, LatestCallTime__c from Lead where Id=:ld2.Id];
            System.debug('updatedLead='+updatedLead);
            System.assertEquals(updatedLead.DuplicatePhone_PAY__c, true);
            System.assertNotEquals(updatedLead.DuplicatePhoneDT_PAY__c, null);
            System.assertNotEquals(null,updatedLead.LatestCallTime__c);  
  //        System.assertEquals(updatedLead.NSS_WorkablePayroll__c, false);
            System.assertEquals(updatedLead.DuplicatePhone_HRS__c, false);
            System.assertEquals(updatedLead.DuplicatePhoneDT_HRS__c, date.today()-16);
//          System.assertEquals(updatedLead.NSS_WorkableHRS__c, true);
            
        } // runAs
        
        
        
        Account acct1 = new Account (name = 'Test Account1',type = 'MMS Client', Phone = '111-1234',BillingPostalCode = '10000', Dialed__c = false);
        insert acct1;
        Contact con1 = new Contact(Firstname = 'Bill',Lastname = 'Contact1',Phone = '555-1212',AssistantPhone= '555-2323', HomePhone= '555-3434', MobilePhone='555-4545', OtherPhone='555-5656' ,AccountId=acct1.Id,Sales_Contact__c = true, Dialed__c = false);
        insert con1;
        
        Account acct2 = new Account (name = 'Test Account2',type = 'MMS Client', Phone='111-1234', BillingPostalCode = '10000',Bis_Id__c = 1234, 
             NumberOfEmployees = 5,Client_Status__c ='A',Dialed__c = false, DuplicatePhoneDT_HRS__c = date.today()-16);
        insert acct2;                
        Contact con2 = new Contact(Firstname = 'Mary',Lastname = 'Contact2',Phone = '555-1212',AccountId=acct2.Id,Sales_Contact__c = true, Dialed__c = false);
        insert con2;                            
        Contact con3 = new Contact(Firstname = 'Sue',Lastname = 'Contact3',Phone = '555-1212',AccountId=acct2.Id,Sales_Contact__c = true, Dialed__c = false);
        insert con3;
        
        Contact[] ctctList = [Select Id, Name, DuplicatePhone_PAY__c, DuplicatePhoneDT_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_HRS__c,
                            NSS_WorkablePayroll__c, NSS_WorkableHRS__c, LatestCallTime__c from Contact where Id = :con1.Id or Id = :con2.Id or Id = :con3.Id];
        fixedSoslResults = new Id[ctctList.size()];
        for (Contact ct: ctctList)
        {   fixedSoslResults.add(ct.Id);    }                           
        Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query
        dialedIdsSet = new Set<Id>{con1.Id};
        u.NSS_Team__c = 'HRS';
        update u;
        UserHelper.userMap.clear();

        NSSMethods.checkDuplicatePhone(dialedIdsSet, u.Id);
        Contact updatedCtct = [Select Id, Name, DuplicatePhone_PAY__c, DuplicatePhoneDT_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_HRS__c,
                            NSS_WorkablePayroll__c, NSS_WorkableHRS__c from Contact where Id = :con2.Id];                           
            
        System.assertEquals(updatedCtct.DuplicatePhone_HRS__c, true);
        System.assertNotEquals(updatedCtct.DuplicatePhoneDT_HRS__c, null);
//      System.assertEquals(updatedCtct.NSS_WorkableHRS__c, false);
        
        PaychexSettings__c payx = new PaychexSettings__c (
            Name = 'DuplicatePhoneLimit'
            ,IsActive__c=true
            ,Attribute1__c = '1');
        insert payx;
        
        Account[] acctList = [Select Id, Name, DuplicatePhone_PAY__c, DuplicatePhoneDT_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_HRS__c,
                            NSS_WorkablePayroll__c, NSS_WorkableHRS__c from Account where Id = :acct2.Id];
        fixedSoslResults = new Id[acctList.size()];
        for (Account a : acctList)
        {   fixedSoslResults.add(a.Id); }                           
        Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query
        dialedIdsSet = new Set<Id>{acct1.Id};
        u.NSS_Team__c = 'PAY';
        update u;
        UserHelper.userMap.clear();
                                            
        NSSMethods.checkDuplicatePhone(dialedIdsSet, u.Id);
        Account updatedAcct = [Select Id, Name, DuplicatePhone_PAY__c, DuplicatePhoneDT_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_HRS__c,
                            NSS_WorkablePayroll__c, NSS_WorkableHRS__c from Account where Id = :acct2.Id];                          
            
        System.assertEquals(updatedAcct.DuplicatePhone_HRS__c, false);
        System.assertEquals(updatedAcct.DuplicatePhoneDT_HRS__c, date.today()-16);
//      System.assertEquals(updatedAcct.NSS_WorkableHRS__c, true);          

        ErrorLog__c[] errLogs = [Select Id, Classname__c from ErrorLog__c where ClassName__c = 'NSSMethods'];
        System.assertEquals(errLogs.size(), 1);
        
          
    } // myUnitTest
    
}