/*
  * Test Methods for the customLinks_Controller class.
  * History
  * -------
  * 11/15/2012 Cindy Freeman        Created.
  * 
  */

@IsTest(SeeAllData=true)

  private class CustomLinks_controllerTest {

    static testMethod void myUnitTest() {
        
        // get users to call this page
        UserRole brokerRole = [Select Id, Name from UserRole
            where Name = 'HRS 4S Sales Broker Representative I' limit 1];           
        User brokerUser = [Select Id, UserRoleID from User 
            where HR_Person_Id__c != null and IsActive = true and UserRoleID = :brokerRole.Id limit 1];
            
        UserRole defaultRole = [Select Id, Name from UserRole
            where Name = 'HRS 4S Premier Support Representative' limit 1];                       
        User defaultUser = [Select Id, UserRoleID from User 
            where HR_Person_Id__c != null and IsActive = true and UserRoleId = :defaultRole.Id limit 1];
            
        System.runAs(defaultUser)
        {   Map<String, custom_links__c> allLinks = custom_links__c.getAll();
            System.assertNotEquals(0, allLinks.size());        
            List<String> defaultUrls = new List<String>();
            List<String> defaultLabels = new List<String>();
            for (custom_links__c c: allLinks.values())
            {   if (c.roleId__c == null)
                {   defaultUrls.add(c.link_url__c); 
                    defaultLabels.add(c.link_label__c);
                }
            }            
            CustomLinks_Controller clc = new CustomLinks_Controller();
            System.assertEquals(defaultUrls.size(),clc.custLinks.size());
        }
            
        System.runAs(brokerUser)
        {   Map<String, custom_links__c> allLinks = custom_links__c.getAll();
            List<String> brokerUrls = new List<String>();
            List<String> brokerLabels = new List<String>();
            for (custom_links__c c: allLinks.values())
            {   if (c.roleId__c == brokerUser.UserRoleID)
                {   brokerUrls.add(c.link_url__c);  
                    brokerLabels.add(c.link_label__c);
                }
            }            
            CustomLinks_Controller clc = new CustomLinks_Controller();
            System.assertEquals(brokerUrls.size(),clc.custLinks.size());
        }
               
    } 

}