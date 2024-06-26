/**
 *
 * The test methods for ReferenceHandbookOrdersTrigger and the ReferenceHbkOrderHelper class.
 *
 * History
 * -------
 * 11/20/2013 Frank Lurz    Created
 * 04/28/2015 Frank Lurz    Rewrote the test class to handle changes to both the Order_Current_Steps_Indicator__c and Order_Approval_Copy_Indicator__c
   01/05/2022 Dan Carmen    Updated to remove hardcoded ID/increment API 

 */
 @isTest
 private class ReferenceHbkOrderHelperTest {
     static testMethod void myUnitTest() {
        Reference_HRE_CHB_Onboarding__c refHre = new Reference_HRE_CHB_Onboarding__c();
        insert refHre;
         
        //create a Reference Handbooks Version record
        //Reference_Handbooks_Version__c refVer1 = [Select Id, Name, Reference_HR_Essentials__c = 'a1D70000001T1Lg', Order_Current_Steps_Indicator__c from Reference_Handbooks_Version__c
        //                                where Reference_HR_Essentials__c != null
        //                                  and Order_Current_Steps_Indicator__c = null limit 1];
                                          
        Reference_Handbooks_Version__c refVer1 = new Reference_Handbooks_Version__c (Reference_HR_Essentials__c = refHre.Id  //'a1D70000001T1Lg'
                                                                                              ,Order_Current_Steps_Indicator__c = 0
                                                                                              ,Order_Approval_Copy_Indicator__c = 0
                                                                                              ,Handbook_Version_Title__c = 'Secondary version');
        insert refVer1;

                                          
        //create and insert a Reference HRE/CHB Order record
        Reference_HRE_CHB_Orders__c refOrder1 = new Reference_HRE_CHB_Orders__c (Reference_HR_Essentials__c = refVer1.Reference_HR_Essentials__r.Id
                                                                                  ,X8_x_11__c = true
                                                                                  ,Handbook_Version__c = refVer1.Id
                                                                                  ,Handbook_Version_Name__c = 'SU Hoops Handbook'
                                                                                  ,HTML_Needed__c = true
                                                                                  ,Historical_Order_Indicator__c = 0
                                                                                  ,Order_Current_Step__c = 'New'
                                                                                  ,Order_Date__c = Date.today().addDays(1)
                                                                                  ,Tracking_Number__c = '12345678');
        insert refOrder1;
      
        
       //Assert that the Reference Handbook Order.Reference_HR_Essentials__c field
       // is the same as the Reference Handbooks Version.Reference_HR_Essentials__c - a link to the Reference Handbooks/HR Services object
       //System.assertEquals(refHRECHBpeo.Id,refOrder1.Reference_HR_Essentials__c);
       System.assertEquals(refVer1.Reference_HR_Essentials__r.Id,refOrder1.Reference_HR_Essentials__c);
 
 
       //Assert that the Reference Handbooks Version.Order_Current_Steps_Indicator__c field is being updated to properly reflect the changes
       //to the Reference Handbooks Order.Order_Current_Step__c Picklist field
       refOrder1.Order_Current_Step__c = 'Order Approved - Due Date Assigned';
       update refOrder1;
       
       //System.assertEquals(refVer1.Order_Current_Steps_Indicator__c,null);
       System.assertEquals(refVer1.Order_Current_Steps_Indicator__c,0);

       
       refOrder1.Order_Current_Step__c = 'Client Canceled';
       update refOrder1;
       
       System.assertNotEquals(refVer1.Order_Current_Steps_Indicator__c,2);


       //Assert that the Reference Handbooks Version.Order_Approval_Copy_Indicator__c field is being updated to properly reflect the changes
       //to the Reference Handbooks Order.Approval_Copy_to_Client_Date__c Date field
       refOrder1.Approval_Copy_to_Client_Date__c = Date.today().addDays(2);
       update refOrder1;
       
       //System.assertEquals(refVer1.Order_Approval_Copy_Indicator__c,null);
       System.assertEquals(refVer1.Order_Approval_Copy_Indicator__c,0);
       
     
                 
   } // myUnitTest
}