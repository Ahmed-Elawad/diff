/**
 * Test method for WebFALeadEmailHandler and WebFALeadHelper
 * 
 * History
 * --------
 * 05/22/2013   Cindy Freeman   created
 * 12/10/2013   Justin Stouffer Changed scope to allow the CreateZipRUles method to be used in the WebBankLeadHelperTest
 * 11/08/2021	Jermaine Stukes	Removed references to external wholesaler owner fields
 */
@isTest
public class WebFALeadEmailHandlerTest {

    static testMethod void myUnitTest() {
        SOAREmailHandlerTest.createZipRules();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
 
        // setup the data for the email
        email.subject = 'Test FA Referrals';
        email.fromname = 'FirstName LastName';
        env.fromAddress = 'someaddress@email.com';
 
        // populate email body
        String test1 = '<note>\r <firstname>Virgil</firstname>\r <lastname>Meads</lastname>\r <company>Meads Consultants</company>\r <email>virgil@meadconsultants.com</email>';
        test1 += '<phone>585-222-0011</phone>\r <street>10 Main St</street>\r <city>Anytown</city>\r <state>NY</state>\r <zip>14514</zip>';
        test1 += '<calltype>National Advertising Search</calltype> \r<comments> This is a test</comments>\r </note>';               
        email.plainTextBody = test1;
        
        // call Helper class directly to check parsing then process list creating new referral account and contact       
        WebFAleadHelper.FAlead fa = new WebFAleadHelper.FAlead();
        fa = WebFAleadHelper.parseXml(email.plainTextBody);
        
        System.assertEquals(fa.firstName, 'Virgil');
        System.assertEquals(fa.lastName, 'Meads');
        System.assertEquals(fa.fullName, 'Virgil Meads');
        System.assertEquals(fa.company, 'Meads Consultants');
        System.assertEquals(fa.email, 'virgil@meadconsultants.com');
        System.assertEquals(fa.phone, '585-222-0011');
        System.assertEquals(fa.squishedPhone, '5852220011');
        System.assertEquals(fa.street, '10 Main St');
        System.assertEquals(fa.city, 'Anytown');
        System.assertEquals(fa.state, 'NY');
        System.assertEquals(fa.zip, '14514');
        System.assertEquals(fa.comments, 'This is a test');
        System.assertEquals(fa.calltype, 'National Advertising Search');
        
        List<WebFAleadHelper.FAlead> FAlist = new List<WebFAleadHelper.FAlead>();
        FAlist.add(fa);
        WebFAleadHelper.processFAlead(FAlist);
               
        Referral_Account__c refAcct1 = [SELECT Id, Name, Zip_Postal_Code__c, HRS_Account_Owner__c, 
                Internal_Wholesaler_Account_Owner__c FROM Referral_Account__c WHERE Name = 'Meads Consultants'];
        System.assertEquals('14514', refAcct1.Zip_Postal_Code__c);        

        Referral_Contact__c refCtct1 = [SELECT Id, Name, Last_Name__c, Email__c,
                (SELECT Id, WhatId, Subject, Lead_Source_WAR_Call_Type__c FROM Tasks)
                 FROM Referral_Contact__c WHERE Referral_Account__c = :refAcct1.Id];
        System.assertEquals('Virgil Meads',refCtct1.Name);
        for (Task tsk: refCtct1.Tasks)
        {   System.assertEquals('National Advertising Search', tsk.Lead_Source_WAR_Call_Type__c);   }

        //////////////////
        // existing referral account, create new contact, check task owner
        /*refAcct1.External_Wholesaler_Account_Owner__c = refAcct1.HRS_Account_Owner__c;
        update refAcct1;*/
        
        Messaging.InboundEmail email2 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();
 
        // setup the data for the email
        email2.subject = 'Test FA Referrals';
        email2.fromname = 'FirstName LastName';
        env2.fromAddress = 'someaddress@email.com';
 
        // populate email body
        String test2 = '<note><firstname>Sally </firstname>\r <lastname>Meads</lastname>\r <company>Meads Consultants</company>\r <email>sally@meadconsultants.com</email>';
        test2 += '<phone>585-222-0022</phone>\r <street>10 Main St</street>\r <city>Anytown</city>\r <state>NY</state>\r <zip>14514</zip>';
        test2 += '<calltype>National Advertising Search</calltype> \r<comments> This is a test</comments>\r </note>';    
        test2 += '\n\n\nThe information contained in this message may be privileged, confidential and protected from disclosure.';   
        email2.plainTextBody = test2;

        WebFALeadEmailHandler emailHndlr2 = new WebFALeadEmailHandler();
        emailHndlr2.handleInboundEmail(email2, env2);
        
        Referral_Contact__c refCtct2 = [SELECT Id, Name, Last_Name__c, Email__c,
                (SELECT Id, WhatId, Subject, OwnerId FROM Tasks)
                 FROM Referral_Contact__c WHERE Name = 'Sally Meads' AND Referral_Account__c = :refAcct1.Id];
        System.assertEquals('sally@meadconsultants.com',refCtct2.Email__c);
        /*for (Task tsk: refCtct2.Tasks)
        {   System.assertEquals(refAcct1.External_Wholesaler_Account_Owner__c, tsk.OwnerId);    }*/
        
        //////////////////
        // existing referral account, existing referral contact but update phone
        Messaging.InboundEmail email3 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env3 = new Messaging.InboundEnvelope();
 
        // setup the data for the email
        email3.subject = 'Test FA Referrals';
        email3.fromname = 'FirstName LastName';
        env3.fromAddress = 'someaddress@email.com';
 
        // populate email body
        String test3 = '<note><firstname>S </firstname>\r <lastname>Meads</lastname>\r <company>Meads Consultants</company>\r <email>sally@meadconsultants.com</email>';
        test3 += '<phone>585-111-1122</phone>\r <street>10 Main St</street>\r <city>Anytown</city>\r <state>NY</state>\r <zip>14514</zip>';
        test3 += '<calltype>National Advertising Search</calltype> \r<comments> This is a test</comments>\r </note>';       
        email3.plainTextBody = test3;

        WebFALeadEmailHandler emailHndlr3 = new WebFALeadEmailHandler();
        emailHndlr3.handleInboundEmail(email3, env3);
        
        Referral_Contact__c refCtct3 = [SELECT Id, Name, Last_Name__c, Email__c, Phone__c FROM Referral_Contact__c WHERE Name = 'Sally Meads' AND Referral_Account__c = :refAcct1.Id];
        System.assertEquals('585-111-1122',refCtct3.Phone__c);

        //////////////////
        // existing referral account, create new contact, check task owner
        refAcct1.Internal_Wholesaler_Account_Owner__c = refAcct1.HRS_Account_Owner__c;
        update refAcct1;
        
        Messaging.InboundEmail email4 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env4 = new Messaging.InboundEnvelope();
 
        // setup the data for the email
        email4.subject = 'Test FA Referrals';
        email4.fromname = 'FirstName LastName';
        env4.fromAddress = 'someaddress@email.com';
 
        // populate email body
        String test4 = '<note><firstname>John </firstname>\r <lastname>Smith</lastname>\r <company>Meads Consultants</company>\r <email>john@meadconsultantsBAD</email>';
        test4 += '<phone>585-111-1234</phone>\r <street>10 Main St</street>\r <city>Anytown</city>\r <state>NY</state>\r <zip>14514</zip>';
        test4 += '<calltype>National Advertising Search</calltype> \r<comments> This is a test</comments>\r </note>';       
        email4.plainTextBody = test4;

        WebFALeadEmailHandler emailHndlr4 = new WebFALeadEmailHandler();
        emailHndlr4.handleInboundEmail(email4, env4);
                
        Referral_Contact__c refCtct4 = [SELECT Id, Name, Last_Name__c, Email__c,
                (SELECT Id, WhatId, Subject, OwnerId FROM Tasks)
                 FROM Referral_Contact__c WHERE Name = 'John Smith' AND Referral_Account__c = :refAcct1.Id];
		System.assertEquals(null, refCtct4.Email__c);                 
        for (Task tsk: refCtct4.Tasks)
        {   System.assertEquals(refAcct1.Internal_Wholesaler_Account_Owner__c, tsk.OwnerId);    }
    
        //////////////////
        // missing company information
        Messaging.InboundEmail email5 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env5 = new Messaging.InboundEnvelope();
 
        // setup the data for the email
        email5.subject = 'Test FA Referrals';
        email5.fromname = 'FirstName LastName';
        env5.fromAddress = 'someaddress@email.com';
 
        // populate email body
        String test5 = '<note><firstname>John </firstname>\r <lastname>Smith</lastname>\r <email>john@meadconsultants.com</email>';
        test5 += '<phone>585-111-1234</phone>\r <street>10 Main St</street>\r <city>Anytown</city>\r <state>NY</state>\r <zip>14514</zip>';
        test5 += '<calltype>National Advertising Search</calltype> \r<comments> This is a test</comments>\r </note>';       
        email5.plainTextBody = test5;

        WebFALeadEmailHandler emailHndlr5 = new WebFALeadEmailHandler();
        try {
            emailHndlr5.handleInboundEmail(email5, env5);
        }
        catch (Exception fae) {
            System.assertEquals(fae.getMessage(), 'missing company');
        }
        
        
    }

/*
  public static void createZipRules() {
      // select test users
      User uCore = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      User uCore2 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :uCore.Id limit 1];
      User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS limit 1];
      User uHrs = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_401 limit 1];
      User uPeo = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO limit 1];
      User uHnb = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_HNB limit 1];
      
      // verify the unassigned users exist
      User unassignedCore = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c=:ZipAssignment.UNASSIGNED_CORE_PERSON_ID limit 1];
      User unassignedMMS = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c=:ZipAssignment.UNASSIGNED_MMS_PERSON_ID limit 1];
      
      // create Zip Assignment records
      Zip_Assignment__c za1 = new Zip_Assignment__c(Name='14514',HR_Person_Id__c=uCore.HR_Person_Id__c
                                                   ,User__c=uCore.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=uCore.Sales_Org__c, MC_Id__c='TestCore', Segment_Name__c='Test Core');
      Zip_Assignment__c za2 = new Zip_Assignment__c(Name='14515',HR_Person_Id__c=uCore.HR_Person_Id__c
                                                   ,User__c=uCore.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=uCore.Sales_Org__c, MC_Id__c='TestCore', Segment_Name__c='Test Core');
      Zip_Assignment__c za3 = new Zip_Assignment__c(Name='14514',HR_Person_Id__c=uMms.HR_Person_Id__c
                                                   ,User__c=uMms.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=uMms.Sales_Org__c, MC_Id__c='TestMms', Segment_Name__c='Test MMS');
      Zip_Assignment__c za4 = new Zip_Assignment__c(Name='14514',HR_Person_Id__c=uHrs.HR_Person_Id__c
                                                   ,User__c=uHrs.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=uHrs.Sales_Org__c, MC_Id__c='Test401', Segment_Name__c='Test 401');
      Zip_Assignment__c za5 = new Zip_Assignment__c(Name='14514',HR_Person_Id__c=uPeo.HR_Person_Id__c
                                                   ,User__c=uPeo.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=uPeo.Sales_Org__c, MC_Id__c='TestPeo', Segment_Name__c='Test PEO');
      Zip_Assignment__c za6 = new Zip_Assignment__c(Name='14514',HR_Person_Id__c=uHnb.HR_Person_Id__c
                                                   ,User__c=uHnb.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=uHnb.Sales_Org__c, MC_Id__c='TestHnb', Segment_Name__c='Test HNB');
      Zip_Assignment__c za7 = new Zip_Assignment__c(Name='14516',HR_Person_Id__c=null
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=UserHelper.SO_CORE, MC_Id__c='TestCore', Segment_Name__c='Test Core');
      Zip_Assignment__c za8 = new Zip_Assignment__c(Name='14516',HR_Person_Id__c=null
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=UserHelper.SO_MMS, MC_Id__c='TestMms', Segment_Name__c='Test MMS');
      Zip_Assignment__c za9 = new Zip_Assignment__c(Name='14516',HR_Person_Id__c=null
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=UserHelper.SO_401, MC_Id__c='Test401', Segment_Name__c='Test 401');
      Zip_Assignment__c[] zas = new Zip_Assignment__c[]{za1,za2,za3,za4,za5,za6,za7,za8,za9};
      insert zas;       
  }
*/
} // WebFALeadEmailHandlerTest