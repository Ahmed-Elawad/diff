/* Test for reassigning Accounts owned by inactive users.
   
  History
  -------
  02/08/2021 Matt Fritschi	Created
  05/18/2021 Carrie Marciano   Changed to use OppStage Labels
  02/04/2022 Dan Carmen     Add check for user lookup on contact if status changes
  11/01/2023 Dan Carmen     Change call to checkUserLookups

*/

@isTest
public class InactiveUserAccountQueueableTest {
    
    public static String SOLD_STARTED=Label.OppStage_Sold_Started;
    public static String NOT_SOLD=Label.OppStage_Lost;
    
    static testmethod void testSMBChannelOpportunity() {
        
        User[] smbChannelRep = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true and Sales_Division__c = 'SMB Channel' and (not title like '%Inbound%') and (not title like 'Virtual%') and (not title like '%Micro%') limit 2];
        Map<Id, User> userMap = new Map<Id, User>();
        
        userMap.put(smbChannelRep[0].Id, smbChannelRep[0]);
        userMap.put(smbChannelRep[1].Id, smbChannelRep[1]);
        
        List<Account> acctList = new List<Account>();
        Account acct1 = new Account(OwnerId = smbChannelRep[0].Id, Name = 'Test Account 1', Hold_Out__c=true, Permanent_Hold_Out_Description__c='ADMIN', Hold_Out_Expiration__c=System.Date.Today() + 1, Use_Zip_Assignment_Rules__c = false, Type='Lost Client');
        acctList.add(acct1);
        Account acct2 = new Account(OwnerId = smbChannelRep[1].Id, Name = 'Test Account 2', Hold_Out__c=true, Permanent_Hold_Out_Description__c='ADMIN', Hold_Out_Expiration__c=System.Date.Today() + 1, Use_Zip_Assignment_Rules__c = false);
        acctList.add(acct2);
        insert acctList;
        
        List<Opportunity> opptyList = new List<Opportunity>();
        Opportunity smbChannelOppty1 = new Opportunity(Name='Test oppty 1', Type = 'Payroll', StageName = SOLD_STARTED, CloseDate=System.Date.today(), AccountId=acct1.Id);
        opptyList.add(smbChannelOppty1);
        Opportunity smbChannelOppty2 = new Opportunity(Name='Test oppty 2', Type = 'Payroll', StageName = NOT_SOLD, CloseDate=System.Date.today(), AccountId=acct2.Id);
        opptyList.add(smbChannelOppty2);
        insert opptyList;
        
        Test.startTest();        
        System.enqueueJob(new InactiveUserAccountQueueable(userMap, new Set<Id>()));
        Test.stopTest();
        
        acct1 = [SELECT OwnerId, Name, Hold_Out__c, Permanent_Hold_Out_Description__c, Hold_Out_Expiration__c, Use_Zip_Assignment_Rules__c FROM Account WHERE Id = :acct1.Id];
        System.assertEquals(acct1.Hold_Out__c, false);
        System.assertEquals(acct1.Permanent_Hold_Out_Description__c, null);
        System.assertEquals(acct1.Hold_Out_Expiration__c, null);

        acct2 = [SELECT OwnerId, Name, Hold_Out__c, Permanent_Hold_Out_Description__c, Hold_Out_Expiration__c, Use_Zip_Assignment_Rules__c FROM Account WHERE Id = :acct2.Id];
        System.assertEquals(acct2.Hold_Out__c, false);
        System.assertEquals(acct2.Permanent_Hold_Out_Description__c, null);
        System.assertEquals(acct2.Hold_Out_Expiration__c, null);
    }
    
    
    static testmethod void testUserTitle() {
        
        User smbChannelRep = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true and (Title LIKE '%Inbound%' or Title LIKE 'Virtual%' or Title LIKE '%Micro%') limit 1];
        Map<Id, User> userMap = new Map<Id, User>();
        userMap.put(smbChannelRep.Id, smbChannelRep);
        
        Account acct = new Account(OwnerId = smbChannelRep.Id, Name = 'Test Account', Hold_Out__c=true, Permanent_Hold_Out_Description__c='ADMIN', Hold_Out_Expiration__c=System.Date.Today() + 1, Use_Zip_Assignment_Rules__c = false);
        insert acct;
        
        Opportunity soldOppty = new Opportunity(Name='Test oppty 1', Type = 'Payroll', StageName = SOLD_STARTED, CloseDate=System.Date.today(), AccountId=acct.Id);
        insert soldOppty;
        
        Test.startTest();        
        System.enqueueJob(new InactiveUserAccountQueueable(userMap, new Set<Id>()));
        Test.stopTest();
        
        acct = [SELECT OwnerId, Name, Hold_Out__c, Permanent_Hold_Out_Description__c, Hold_Out_Expiration__c, Use_Zip_Assignment_Rules__c FROM Account WHERE Id = :acct.Id];
        System.assertEquals(acct.Hold_Out__c, false);
        System.assertEquals(acct.Permanent_Hold_Out_Description__c, null);
        System.assertEquals(acct.Hold_Out_Expiration__c, null);
    } // testUserTitle
    
    static testMethod void testUserLookup() {
        User[] users = [Select Id, Name, LastName, HR_Person_Id__c from User where Job_Name__c=:UserHelper.JOB_REP and IsActive=true and HR_Person_Id__c != null limit 3];
        Contact[] ctcts = new Contact[]{};
        Set<String> personIdSet = new Set<String>();
        for (User usr : users) {
           ctcts.add(new Contact(LastName=usr.LastName, HR_Person_Id__c = usr.HR_Person_Id__c));
           personIdSet.add(usr.HR_Person_Id__c);
        } // for (User usr : users
        ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
        ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
        insert ctcts;
        
        Test.startTest();        
        System.enqueueJob(new InactiveUserAccountQueueable(new Map<Id, User>(), personIdSet));
        Test.stopTest();
        
        ctcts = [Select id, Name, User_Lookup__c from Contact where Id in :ctcts];
        for (Contact ctct : ctcts) {
            System.assertNotEquals(null,ctct.User_Lookup__c);
        }

    } // testUserLookup
    
    
} // class InactiveUserAccountQueueableTest