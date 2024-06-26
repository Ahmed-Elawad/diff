/**
 * The test methods for the ReferenceHRECHBAfter trigger, and the ReferenceHRECHBHelper class.
   SeeAllData=true because of chatter post as part of test.
 *
 * History
 * ------- 
 * 11/20/2013 Frank Lurz    Created 
 * 04/26/2015 Frank Lurz    Removed references to the Reference Handbooks Order / Reference_HRE_CHB_Orders__c object
   07/08/2015 Dan Carmen    Added case creation so it won't depend on organization data.
   03/14/2017 Frank Lurz    Replaced "HRS Sales" profiles with "HRS Sales - SB"  (Happy Pi Day)
   06/14/2021 Dan Carmen    Incremented API version, changed SeeAllData to false.

*/
 @isTest(SeeAllData=false)
 private class ReferenceHRECHBHelperTest {
     static testMethod void myUnitTest() {
         
        Schema.RecordTypeInfo RefHRECHBobRt = RecordTypeHelper.getRecordType('Reference HRE/CHB Onboarding', 'Reference_HRE_CHB_Onboarding__c');
        Schema.RecordTypeInfo RefHRECHBhsRt = RecordTypeHelper.getRecordType('Handbook Support HR Solutions Ref Object', 'Reference_HRE_CHB_Onboarding__c');  
 
        //create Account and Contact records via the createTestAandC method in the CreateTestData test class
        CreateTestData.createTestAandC();
        Account testAccount1 = [select Id, Name, AccountNumber from Account where name = 'Test Account1'];
        Contact testContact1 = [select Id, Name, Email from Contact where AccountId = :testAccount1.Id and FirstName = 'First'];  
        Contact testContact2 = [select Id, Name, Email from Contact where AccountId = :testAccount1.Id and FirstName = 'Second'];

        // create a case
        Schema.RecordTypeInfo caseRt = RecordTypeHelper.getRecordType('Service Support Handbook HRE/CHB', 'Case');
        Case caseHS1 = new Case(OwnerId=UserInfo.getUserId(), AccountId=testAccount1.Id, ContactId=testContact1.Id, RecordTypeId=caseRt.getRecordTypeId());
        System.debug('caseHS1='+caseHS1);
        insert caseHS1;

        //create User records
        User userHB1 = [Select Id, Name, Email from User
                     where profile.Name = 'HR Essentials'
                      and Email != null
                      and IsActive = true limit 1];

        User user1 = [Select Id, Name, Email from User
                   where profile.Name = 'HRS PEO-ASO Sales - SB'
                    and Email != null
                    and IsActive = true limit 1];

        User user2 = [Select Id, Name, Email from User
                   where profile.Name = 'HRS Sales Administration - SB'
                    and Email != null
                    and IsActive = true limit 1];

        User user3 = [Select Id, Name, Email from User
                   where profile.Name = 'HRS Sales Manager - SB'
                    and Email != null
                    and IsActive = true limit 1];
                    
        //create test case
        //Case caseHS1 = [Select Id from Case
        //             where RecordType.Name = 'Service Support HRE/CHB' limit 1];                   
                    
                
        //create and insert a Completed Reference Handbooks/HR Services HR Services record with the Onboarding record type, along with related States and Version reference records
        Reference_HRE_CHB_Onboarding__c refHRECHBob1 = new Reference_HRE_CHB_Onboarding__c (recordtypeid = RefHRECHBobRt.getRecordTypeId()
                                                                                       ,Account_Lookup__c = testAccount1.Id
                                                                                       //,Parent_Case__c = caseOB1.Id
                                                                                       ,Product_Type__c = 'HRE'
                                                                                       ,DBA_Name__c = 'dba The TEST Account'
                                                                                       ,District__c = 12
                                                                                       ,Sales_Rep__c = user1.Id
                                                                                       ,FSS__c = user2.Id
                                                                                       ,DSM__c = user3.Id
                                                                                       ,First_Billing_Month_Date__c = Date.today().addDays(10)
                                                                                       ,Contract_Received_Date__c = Date.today().addDays(15)
                                                                                       ,Set_Up_Complete_Date__c = Date.today().addDays(20)
                                                                                       ,Secondary_Contact_Name__c = testContact2.Id
                                                                                       ,Secondary_Contact_Time_Zone__c = 'EST'
                                                                                       ,Non_reviewable_Policy__c = true
                                                                                       ,Approval_Copy_to_Client_Date__c = Date.today().addDays(25)
                                                                                       ,All_Versions_Printed_Date__c = Date.today().addDays(30)
                                                                                       ,Multiple_Versions__c = true
                                                                                       ,Word_Doc_Changes__c = 'abcdefghijklmnopqrstuvwxyz');
        insert refHRECHBob1;
        
        //Update refHRECHBob1 Current Step to Onboarding Complete.
        refHRECHBob1.Current_Step__c = 'Onboarding Complete'; 
        update refHRECHBob1;
      
        //create and insert a Reference HRE/CHB State record
        Reference_HRE_CHB_State__c refStateob1 = new Reference_HRE_CHB_State__c (Reference_HR_Essentials__c = refHRECHBob1.Id
                                                                              ,State__c = 'NY'
                                                                              ,Employee_Count__c = 44);
        insert refStateob1;
        
        //create and insert a Reference Handbooks Version record
        Reference_Handbooks_Version__c refVer1 = new Reference_Handbooks_Version__c (Reference_HR_Essentials__c = refHRECHBob1.Id
                                                                                  ,Handbook_Version_Last_Modification_Date__c = Date.today()
                                                                                  ,Handbook_Version_Title__c = 'NY Book');
        insert refVer1;
         
        //create and insert a new Reference Handbooks/HR Services record with Handbook Support record type  CINDY"S code field ***, but WITHOUT related States and Version reference records
        Reference_HRE_CHB_Onboarding__c RefHRECHBhs1 = new Reference_HRE_CHB_Onboarding__c (Current_Step__c = 'New'
                                                                                           ,recordtypeid = RefHRECHBhsRt.getRecordTypeId()
                                                                                           ,Account_Lookup__c = testAccount1.Id
                                                                                           ,Primary_Contact_Name__c = testContact1.Id
                                                                                           ,Product_Type__c = 'EMS'
                                                                                           ,Parent_Case__c = caseHS1.Id
                                                                                           );
        insert RefHRECHBhs1;
         
        // verify the Reference HRE/CHB State and Reference Handbooks Version records were created
        List<Reference_HRE_CHB_Onboarding__c> RefHRECHBhs2 = [Select Id, Non_reviewable_Policy__c,Account_Lookup__c,Product_Type__c
                                                               ,(Select Reference_HR_Essentials__c, Employee_Count__c, State__c From Reference_HR_Essentials_States__r)
                                                               ,(Select Reference_HR_Essentials__c,Handbook_Version_Last_Modification_Date__c,Handbook_Version_Title__c From Reference_Handbooks_Versions__r)
                                                              from Reference_HRE_CHB_Onboarding__c where Id=:RefHRECHBhs1.Id];
        
        //Assert that the expected fields were copied over to the new Reference Object. 
        System.assertEquals(RefHRECHBob1.Non_reviewable_Policy__c,RefHRECHBhs2[0].Non_reviewable_Policy__c);
                
        //Assert that any Handbook State(s) were recreated for the new Reference Object.
        System.assertEquals(refStateob1.State__c,RefHRECHBhs2[0].Reference_HR_Essentials_States__r[0].State__c);
         
        //Assert that any Handbook Version(s) were recreated for the new Reference Object.
        System.assertEquals(refVer1.Handbook_Version_Title__c,RefHRECHBhs2[0].Reference_Handbooks_Versions__r[0].Handbook_Version_Title__c);
        
        //adding code to cover the  chatterMentionPost  code recently added to the ReferenceHRECHBAfter trigger
        System.assertNotEquals(RefHRECHBhs1.Interview_Completed_Date__c, Date.today());
        System.assertNotEquals(RefHRECHBhs1.Contract_Clean_Date__c, Date.today() - 150);
        RefHRECHBhs1.Interview_Completed_Date__c = Date.today();
        RefHRECHBhs1.Contract_Clean_Date__c = Date.today() - 150;
        RefHRECHBhs1.Sales_Rep__c = user1.Id;
        RefHRECHBhs1.DSM__c = user2.Id;
        RefHRECHBhs1.FSS__c = user3.Id;
        ChatterMentionPost.posted = TRUE;

        update RefHRECHBhs1;

        RefHRECHBhs1.All_Versions_Printed__c = True;       
        RefHRECHBhs1.All_Versions_Printed_Date__c = Date.today();
        //ChatterMentionPost.posted = TRUE;
        update RefHRECHBhs1;

        
        
   } // myUnitTest
}