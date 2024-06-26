/*
*
*   HISTORY
*  ---------
*   05/29/2018 Jake Hinds   Created
*   3/20/2024  Carrie Marciano    CanBeDeleted old MPSC tech debt
*
*/
@isTest
private class IdeaMethodsTest {
    static testMethod void myUnitTest() {
        new IdeaMethods();
    }
/*
    static testMethod void testManager() {
        User u = [Select Id,ManagerId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Id mpscZoneId = [SELECT Id from Community WHERE Name = 'All MPSC/Enterprise' LIMIT 1].Id;
        Idea i = new Idea(CommunityId = mpscZoneId,Title='Test',Body='Test');
        insert i;
        Test.startTest();
        Idea uI = [SELECT CSS_Manager_Sponsor__c FROM Idea WHERE Id = :i.Id];
        system.assertEquals(u.ManagerId,uI.CSS_Manager_Sponsor__c);
        Test.stopTest();
    }
    
    static testMethod void testCaseCreation(){
        User u = [Select Id,ManagerId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Id mpscZoneId = [SELECT Id from Community WHERE Name = 'All MPSC/Enterprise' LIMIT 1].Id;
        Idea i = new Idea(CommunityId = mpscZoneId,Title='Test',Body='Test',Categories='test');
        insert i;
        
        Test.startTest();
        i.Status = 'Submitted to Strategy Team for Review';
        update i;
        
        Case c = [SELECT Id,Description,Idea__c,Sales_Org__c,Subject FROM Case WHERE Idea__c = :i.Id LIMIT 1];
        system.assertEquals(i.Body,c.Description);
        system.assertEquals(i.Title,c.Subject);
        system.assertEquals(i.Categories,c.Sales_Org__c);
        Test.stopTest();
        
        Idea uI = [SELECT Case__c FROM Idea WHERE Id = :i.Id];
        system.assertEquals(c.Id,uI.Case__c);
    }
   */ 
}