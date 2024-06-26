/* 
   Test methods for the ReferenceHbkObjManageOwnership class and triggers associated with the Reference objects.
   
  History
  -------
  09/16/2014 Frank Lurz     Created.
 
 */
@isTest
private class ReferenceHbkObjManageOwnershipTest {
   static testMethod void myUnitTest() {

     Schema.RecordTypeInfo CaseHRECHBobRt = RecordTypeHelper.getRecordType('Service Onboarding HRE/CHB', 'Case');
     Schema.RecordTypeInfo CaseHRECHBhssRt = RecordTypeHelper.getRecordType('Service Support Handbook HRE/CHB', 'Case');  
     Schema.RecordTypeInfo CaseHRECHBssRt = RecordTypeHelper.getRecordType('Service Support HRE/CHB', 'Case');  
     Schema.RecordTypeInfo RefASOssRt = RecordTypeHelper.getRecordType('Service Support Handbook HR Solutions', 'Case');
     Schema.RecordTypeInfo RefPEOssRt = RecordTypeHelper.getRecordType('Service Support Handbook PEO', 'Case');  


     Schema.RecordTypeInfo RefHRECHBobRt = RecordTypeHelper.getRecordType('Reference HRE/CHB Onboarding', 'Reference_HRE_CHB_Onboarding__c');
     Schema.RecordTypeInfo RefHRECHBhsRt = RecordTypeHelper.getRecordType('Handbook Support HRE/CHB Ref Object', 'Reference_HRE_CHB_Onboarding__c');  
     Schema.RecordTypeInfo RefHRECHBasRt = RecordTypeHelper.getRecordType('Handbook Support HR Solutions Ref Object', 'Reference_HRE_CHB_Onboarding__c');
     Schema.RecordTypeInfo RefHRECHBpeRt = RecordTypeHelper.getRecordType('Handbook Support PEO Ref Object', 'Reference_HRE_CHB_Onboarding__c');  

  



     //create User records
     User userHRG1 = [Select Id, Name, Email from User
            where profile.Name = '2008-09 HRS Premier Support Rep'
             and Email != null
             and IsActive = true limit 1];


     User userHB1 = [Select Id, Name, Email from User
            where profile.Name = 'HR Essentials'
             and Email != null
             and IsActive = true limit 1];



     //create Handbook Onboarding Case record
       Case caseOB1 = new Case (recordtypeId = CaseHRECHBobRt.getRecordTypeId()
                  ,Status = 'New'
                  ,Origin = 'Manual Entry'
                  ,Product__c = 'Handbooks'
                  ,Subject = 'Handbooks Onboarding'
      //            ,Contact = testContact1.Id
                  ,Description = 'description'
                  ,OwnerId = userHRG1.Id);
        insert caseOB1;

      //// caseList.add(caseOB1);



     //create and insert a Completed Reference Handbooks/HR Services HR Services record with the Onboarding record type, along with related Orders, States and Version reference records
     Reference_HRE_CHB_Onboarding__c refHRECHBob1 = new Reference_HRE_CHB_Onboarding__c (recordtypeid = RefHRECHBobRt.getRecordTypeId()
                                                                                    //,Account_Lookup__c = testAccount1.Id
                                                                                    ,Parent_Case__c = caseOB1.Id
                                                                                    ,OwnerID = userHRG1.Id                                                                                    ,Product_Type__c = 'HRE'
                                                                                    ,DBA_Name__c = 'dba The TEST Account'
                                                                                    ,District__c = 12
                                                                                    //,Sales_Rep__c = user1.Id
                                                                                    //,FSS__c = user2.Id
                                                                                    //,DSM__c = user3.Id
                                                                                    ,First_Billing_Month_Date__c = Date.today().addDays(10)
                                                                                    ,Contract_Received_Date__c = Date.today().addDays(15)
                                                                                    ,Set_Up_Complete_Date__c = Date.today().addDays(20)
                                                                                    ,Secondary_Contact_Time_Zone__c = 'EST'
                                                                                    ,Non_reviewable_Policy__c = true
                                                                                    ,Approval_Copy_to_Client_Date__c = Date.today().addDays(25)
                                                                                    ,All_Versions_Printed_Date__c = Date.today().addDays(30)
                                                                                    ,Multiple_Versions__c = true
                                                                                    ,Word_Doc_Changes__c = 'abcdefghijklmnopqrstuvwxyz');
        insert refHRECHBob1;



        //create and insert a Reference HRE/CHB Order record
        Reference_HRE_CHB_Orders__c refOrder1 = new Reference_HRE_CHB_Orders__c (Reference_HR_Essentials__c = refHRECHBob1.Id
                                                                                  ,X8_x_11__c = true
                                                                                  ,X8_x_11_Options__c = 'Black Tape'
                                                                                  ,Approval_Needed__c = true
                                                                                  ,Art__c = 'Logo'
                                                                                  ,Binder_Printing_Notes__c = 'where am the binder printing notes???'
                                                                                  ,Binder_Quantity__c = 44
                                                                                  ,Client_Approved_to_Print_Date__c = Date.today().addDays(30)
                                                                                  ,Client_Name_to_be_Printed_on_Binder__c = 'James Boeheim'
                                                                                  ,Date_Sent_to_Vendor__c = Date.today().addDays(31)
                                                                                  ,Discard_Binders__c = true
                                                                                  ,Distribution_Received_Date__c = Date.today().addDays(29)
                                                                                  ,Handbook_Version_Name__c = 'SU Hoops Handbook'
                                                                                  ,HTML_Needed__c = true
                                                                                  ,Inserts_Quantity__c = 44
                                                                                  ,Order_Date__c = Date.today().addDays(1)
                                                                                  ,Order_Ship_Date__c = Date.today().addDays(32)
                                                                                  ,Order_Type__c = 'Printed - English'
                                                                                  ,Outside_Color__c = 'Orange'
                                                                                  ,OwnerID = userHRG1.Id
                                                                                  ,Print_Order_ID__c = '1234567'
                                                                                  ,Quote_Amount__c = 100
                                                                                  ,Quote_Approved_Date__c = Date.today().addDays(15)
                                                                                  ,Quote_Sent_to_Client_Date__c = Date.today().addDays(10)
                                                                                  ,Returned_from_Translator_Date__c = Date.today().addDays(20)
                                                                                  ,Send_to_Translator__c = true
                                                                                  ,Send_to_Translator_Date__c = Date.today().addDays(17)
                                                                                  ,Sent_to_Print__c = true
                                                                                  ,Sent_to_Print_Date__c = Date.today().addDays(22)
                                                                                  ,Ship_Binder_W_O_Text__c = true
                                                                                  ,Shipping_Order_ID__c = 'a1b2c3d4'
                                                                                  ,Spanish_Invoice_Number__c = 'Uno'
                                                                                  ,Spanish_Transaction_Cancelled__c = true
                                                                                  ,Tab_Color__c = 'Blue'
                                                                                  ,Template__c = 'Block'
                                                                                  ,Tracking_Number__c = 'SU is No 1');
        insert refOrder1;

        //change the Owner from the HRG User to the Handbooks User
        refHRECHBob1.OwnerId = userHB1.Id;
        update refHRECHBob1;
        
        
        //Assert that the         
        System.assertEquals(refOrder1.Owner,refHRECHBob1.Owner);        



   }


   
} // class ReferenceHbkObjManageOwnershipTest