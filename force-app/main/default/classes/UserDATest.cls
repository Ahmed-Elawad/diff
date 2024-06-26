@IsTest
private class UserDATest {
    @TestSetup
    static void setup() {
        List<User> testUsers = new List<User>{
                new User(FirstName = 'Test',
                        LastName = 'UserDA',
                        Username = 'testUserDA@email.com',
                        Email = 'test@email.com',
                        Alias = 'test',
                        CommunityNickname = 'testUserDA',
                        TimeZoneSidKey = 'America/New_York',
                        LocaleSidKey = 'sq_AL',
                        EmailEncodingKey = 'UTF-8',
                        ProfileId = '00e0g0000010D3TAAU',
                        LanguageLocaleKey = 'en_US',
                        Phone = '123-456-7891',
                        Title = 'Test Title',
                        SenderEmail = 'test@email.com',
                        IsActive = true,
                        Sales_Org__c = 'PAY',
                        HR_Person_Id__c = '123456'),
                new User(FirstName = 'UserDA',
                        LastName = 'Person',
                        Username = 'testUserDA2@email.com',
                        Email = 'test@email.com',
                        Alias = 'test',
                        CommunityNickname = 'testUserDA2',
                        TimeZoneSidKey = 'America/New_York',
                        LocaleSidKey = 'sq_AL',
                        EmailEncodingKey = 'UTF-8',
                        ProfileId = '00e0g0000010D3TAAU',
                        LanguageLocaleKey = 'en_US',
                        Phone = '122-456-7891',
                        Title = 'Some Title',
                        SenderEmail = 'email@email.com',
                        IsActive = true,
                        Sales_Org__c = 'PAY',
                        HR_Person_Id__c = '654321'),
                new User(FirstName = 'Non',
                        LastName = 'Match',
                        Username = 'testUserDA3@email.com',
                        Email = 'test@email.com',
                        Alias = 'test',
                        CommunityNickname = 'testUserDA3',
                        TimeZoneSidKey = 'America/New_York',
                        LocaleSidKey = 'sq_AL',
                        EmailEncodingKey = 'UTF-8',
                        ProfileId = '00e0g0000010D3TAAU',
                        LanguageLocaleKey = 'en_US',
                        Phone = '122-456-7891',
                        Title = 'Some Title',
                        SenderEmail = 'email3@email.com',
                        IsActive = true,
                        Sales_Org__c = 'PAY',
                        HR_Person_Id__c = '754321'),
                new User(FirstName = 'Test',
                        LastName = 'Match',
                        Username = 'testUserDA4@email.com',
                        Email = 'test@email.com',
                        Alias = 'test',
                        CommunityNickname = 'testUserDA4',
                        TimeZoneSidKey = 'America/New_York',
                        LocaleSidKey = 'sq_AL',
                        EmailEncodingKey = 'UTF-8',
                        ProfileId = '00e0g0000010D3TAAU',
                        LanguageLocaleKey = 'en_US',
                        Phone = '122-456-7891',
                        Title = 'Some Title',
                        SenderEmail = 'email3@email.com',
                        IsActive = false,
                        Sales_Org__c = 'PAY',
                        HR_Person_Id__c = '754321')
        };

        insert testUsers;
    }

    @IsTest
    static void getAllActiveUsersByNameSearch_givenSearchParam_returnsOnlyActiveRecordsWithNameLikeSearchParam() {
        UserDA testDA = new UserDA();

        Test.startTest();
        List<User> returnedUsers = testDA.getAllActiveUsersByNameSearch('UserDA');
        Test.stopTest();

        System.assertEquals(2, returnedUsers.size());
    }

    @IsTest
    static void getAllActiveUsers_returnsOnlyActiveUsersWithALimitOfOneHundred() {
        UserDA testDA = new UserDA();

        Test.startTest();
        List<User> returnedUsers = testDA.getAllActiveUsers();
        Test.stopTest();

        System.assert(returnedUsers.size() <= 100);
    }
}