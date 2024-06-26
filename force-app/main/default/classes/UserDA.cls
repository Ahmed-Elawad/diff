public with sharing class UserDA implements UserDAInterface {
    public List<User> getAllActiveUsersByNameSearch(String searchName) {
        try {
            String searchParam = '%' + searchName + '%';
            return [
                    SELECT Id,
                            Name,
                            Phone,
                            Title,
                            SenderEmail,
                            HR_Person_Id__c
                    FROM User
                    WHERE IsActive = true
                    AND Name LIKE :searchParam
                    ORDER BY Name
                    LIMIT 100
            ];
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    }

    public List<User> getAllActiveUsers() {
        try {
            return [
                    SELECT Id,
                            Name,
                            Phone,
                            Title,
                            SenderEmail,
                            ContactId
                    FROM User
                    WHERE IsActive = true
                    ORDER BY Name
                    LIMIT 100
            ];
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    }
}