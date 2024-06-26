/* 
 * Test class to get test coverage. 
 *
 * History
 * -------
   01/03/2023 Dan Carmen   No longer needed, removed all code - CanBeDeleted

 */
@isTest
public class LicenseSummaryTest {
    @testSetup
    public static void setup(){
        License_Summary_Info__c setting = new License_Summary_Info__c();
        setting.Name = 'License Summary Data';
        setting.Last_refreshed_Date__c = '3/21/2024, 11:16:34 AM EDT';
        insert setting;
        List<User_License__c> userLicenses = new List<User_License__c>();
        User_License__c usl1 = new User_License__c(
        						Name = 'Unassigned Cost centers');
        userLicenses.add(usl1);
        User_License__c usl2 = new User_License__c(
            					Name = '401K OPS');
        userLicenses.add(usl2);
        insert userLicenses;
        List<Cost_Center__c> costCenters = new List<Cost_Center__c>();
        Cost_Center__c costCen1= new Cost_Center__c(Name = '0000-Community Users',User_License__c = userLicenses[0].Id);
        costCenters.add(costCen1);
        Cost_Center__c costCen2= new Cost_Center__c(Name = '0000-Ungrouped', User_License__c = userLicenses[1].Id);
        costCenters.add(costCen2);
        insert costCenters;
        
    }
    static testMethod void testLoad() {
        new LicenseSummaryController(); 
        List<User_License__c> userLicenses = new List<User_License__c>();
        userLicenses = Database.query('Select Id, Name, Above_Or_Under_Budget__c, BU_Budgeted_License__c, IT_Budgeted_License__c, License_Allocated__c, Total_Licenses__c from User_License__c');
        Assert.areEqual(2, userLicenses.size()); //check for User License count
    } // testLoad
    static testMethod void testgetLicenseInfo() {
        List<Account> Accs = new List<Account>();
        //Creating accounts for test
        Account acc = new Account();
        acc.Name = 'Peo test';
        acc.ShippingState = 'Texas';
        //acc.Referral_National_Account__c = refAcc.Id;
        Accs.add(acc);
        Account acc2 = new Account();
        acc2.Name = 'Peo test2';
        acc2.ShippingState = 'Texas';
        Accs.add(acc2);
        insert Accs;
        
        //Creating contacts for test
        List<Contact> Conts = new List<Contact>();
        Contact c = new Contact(AccountId=acc.id,
                               FirstName = 'test',
                               LastName = 'contact',
                               Email='testing@testing.com');
        Conts.add(c);
        Contact c2 = new Contact(AccountId=acc2.id,
                               FirstName = 'test',
                               LastName = 'contact2',
                               Email='testing2@testing.com');
        Conts.add(c2);
        insert Conts;
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone'];
        User communityUsr = new User(
            UserName = c.email,
            FirstName = c.FirstName,
            LastName = c.LastName,
            Alias = 'alias',
            email = c.Email,
            ContactId = c.id,
            Cost_Center__c = '0000',
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'nickName',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'PAS'
        );
        insert communityUsr;
        LicenseSummaryController lsc = new LicenseSummaryController(); 
        lsc.getLicenseInfo();
        List<User_License__c> userLicenses = new List<User_License__c>();
        userLicenses = Database.query('Select Id, Name, Above_Or_Under_Budget__c, BU_Budgeted_License__c, IT_Budgeted_License__c, License_Allocated__c, Total_Licenses__c from User_License__c');
        Assert.isNotNull(userLicenses.size());
    } // testgetLicenseInfo
    
    static testMethod void testNavgation() {
        LicenseSummaryController lsc = new LicenseSummaryController(); 
        lsc.search();
        lsc.clear();
        lsc.FirstPage();
        lsc.next();
        lsc.LastPage();
        lsc.viewuserLicenses();
    }
} // class LicenseSummaryTest