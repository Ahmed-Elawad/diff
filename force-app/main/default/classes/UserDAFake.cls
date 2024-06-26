@IsTest
public with sharing class UserDAFake implements UserDAInterface {
    private Boolean causeException = false;

    public Integer GetUserByNameCallCount { get; private set; }
    public Integer GetAllUsersCallCount { get; private set; }

    public UserDAFake(Boolean causeException) {
        this.causeException = causeException;

        GetUserByNameCallCount = 0;
        GetAllUsersCallCount = 0;
    }

    public List<User> getAllActiveUsersByNameSearch(String searchName) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        GetUserByNameCallCount++;
        return new List<User>();
    }

    public List<User> getAllActiveUsers() {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        GetAllUsersCallCount++;
        return new List<User>();
    }
}