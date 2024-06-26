@IsTest
private class EventAttendeeSearchAuraServiceTest {
    @IsTest
    static void getAllActiveUsers_givenNullSearchParam_callsGetAllActiveUsers() {
        UserDAFake fakeUserDA = new UserDAFake(false);

        Test.startTest();
        EventAttendeeSearchAuraService.UserDADI = fakeUserDA;

        List<User> returnUsers = EventAttendeeSearchAuraService.getAllActiveUsers(null);
        Test.stopTest();

        System.assertEquals(1, fakeUserDA.GetAllUsersCallCount, String.format('Should have called getAllActiveUsers once, but called it {0} times', new List<String>{
                String.valueOf(fakeUserDA.GetAllUsersCallCount)
        }));

        System.assertEquals(0, fakeUserDA.GetUserByNameCallCount, String.format('Should not have called getAllActiveUsersByName, but called it {0} times', new List<String>{
                String.valueOf(fakeUserDA.GetUserByNameCallCount)
        }));

    }

    @IsTest
    static void getAllActiveUsers_givenSearchParam_callsGetAllActiveUsersByNameSearch() {
        UserDAFake fakeUserDA = new UserDAFake(false);

        Test.startTest();
        EventAttendeeSearchAuraService.UserDADI = fakeUserDA;

        List<User> returnUsers = EventAttendeeSearchAuraService.getAllActiveUsers('Test Name');
        Test.stopTest();

        System.assertEquals(1, fakeUserDA.GetUserByNameCallCount, String.format('Should have called getAllActiveUsersByName once, but called it {0} times', new List<String>{
                String.valueOf(fakeUserDA.GetUserByNameCallCount)
        }));

        System.assertEquals(0, fakeUserDA.GetAllUsersCallCount, String.format('Should not have called getAllActiveUsers, but called it {0} times', new List<String>{
                String.valueOf(fakeUserDA.GetAllUsersCallCount)
        }));
    }

    @IsTest
    static void getAllActiveUsers_givenAnException_ThrowsAuraHandledException() {
        UserDAFake fakeUserDA = new UserDAFake(true);

        Test.startTest();
        try {
            EventAttendeeSearchAuraService.UserDADI = fakeUserDA;

            EventAttendeeSearchAuraService.getAllActiveUsers(null);

            System.assert(false, 'Should have caught exception and thrown AuraHandledException but did not');
        } catch (AuraHandledException ex) {
            System.assert(true);
        }
        Test.stopTest();
    }

}