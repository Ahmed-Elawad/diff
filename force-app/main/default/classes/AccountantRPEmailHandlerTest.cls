/*  
 *  Requirements: https://wiki.paychex.com/display/CP/APR0108928+-+CPA+Contact+Me+Form+Automation
 * 
 * History
 * --------
   01/29/2021 Manmeet Vaseer    Created.
   12/21/2022 Dan Carmen        Clean up code, use SF Duplicate Management.
   03/10/2023   Pujitha Madamanchi  Drupal Form for Payoll Acquisition
   03/11/2024 Dan Carmen        Add ability to mark a record as purge since it seems to be not valid.

 */
@IsTest
public class AccountantRPEmailHandlerTest {

  @IsTest
    static void testBlankEmail(){
        messaging.Inboundemail email = new messaging.Inboundemail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        AccountantReferralPartnerEmailHandler obj = new AccountantReferralPartnerEmailHandler();
        obj.handleInboundEmail(email, env);

        System.assertNotEquals(null,obj.partRef);
        System.assertEquals('CPA',obj.partRef.Source__c);
        System.assertEquals(false,obj.partRef.Processed__c);
        System.assertEquals('Invalid ContactMe XML message in the email body: ',obj.partRef.Comments__c);        
    }
    
  @IsTest
    static void testInvalidPayload(){
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<ContactMe></ContactMe>';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        AccountantReferralPartnerEmailHandler obj = new AccountantReferralPartnerEmailHandler();
        obj.handleInboundEmail(email, env);
        
        System.assertNotEquals(null,obj.partRef);
        System.assertEquals('CPA',obj.partRef.Source__c);
        System.assertEquals(false,obj.partRef.Processed__c);
        System.assertEquals('ContactMe Payload is Empty.',obj.partRef.Comments__c);        
    } // testInvalidPayload
    
  @IsTest
    static void testMissingFormUrlTag(){
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<ContactMe><CompanyName>ABC Inc.</CompanyName>' + 
            '<FirstName>Jay</FirstName><LastName>Smith</LastName><Email>jay.smith@abc.com</Email>' + 
            '<Phone>945-333-2574</Phone><ZipCode>34565</ZipCode>' + 
            '<ProductsOfInterest><item>Payroll</item><item>Benefits</item><item>Retirement Services</item></ProductsOfInterest>' + 
            '<Comments>This is a sample.</Comments></ContactMe>';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        AccountantReferralPartnerEmailHandler obj = new AccountantReferralPartnerEmailHandler();
        obj.handleInboundEmail(email, env);
        
        System.assertNotEquals(null,obj.partRef);
        System.assertEquals('CPA',obj.partRef.Source__c);
        System.assertEquals(false,obj.partRef.Processed__c);
        System.assertEquals('Invalid Form URL. Form URL is required.',obj.partRef.Comments__c);        
    } 
    
  @IsTest
    static void testValidPayload(){
        ReferralObjectsSync.SKIP_SYNC=false;
        
        Campaign camp = new Campaign(Name='Unit Testing', Originator__c='Marketing', LeadSource__c='Jigsaw', Form_URL__c='http://paychex.com/form', IsActive=true);
        insert camp;
        
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<ContactMe><CompanyName>ABC Inc.</CompanyName>' + 
            '<FirstName>Jay</FirstName><LastName>Smith</LastName><Email>jay.smith@abc.com</Email>' + 
            '<Phone>945-333-2574</Phone><ZipCode>34565</ZipCode>' + 
            '<ProductsOfInterest><item>Payroll</item><item>Benefits</item><item>Retirement Services</item></ProductsOfInterest>' + 
            '<Comments>This is a sample.</Comments><FormURL>http://paychex.com/form</FormURL></ContactMe>';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        AccountantReferralPartnerEmailHandler obj = new AccountantReferralPartnerEmailHandler();
        obj.handleInboundEmail(email, env);

        System.assertNotEquals(null,obj.partRef,'Partner Referral is null.');
        System.assertEquals('CPA',obj.partRef.Source__c);
        System.assertEquals(true,obj.partRef.Processed__c);
        System.assertEquals('Successful',obj.partRef.Comments__c);
                        
        PartnerReferral__c[] partRefs = [SELECT Id, Account__c, Contact__c FROM PartnerReferral__c WHERE Id=:obj.partRef.Id];
        System.assertEquals(1,partRefs.size());
    PartnerReferral__c partRef = partRefs.get(0);
        System.assertNotEquals(null,partRef,'Partner Referral is null.');

        Referral_Account__c[] refAccts = [SELECT Id, Account__c, Zip_Postal_Code__c, Phone__c FROM Referral_Account__c WHERE CreatedDate = TODAY];
        System.assertEquals(1,refAccts.size(), 'No Referral Account is found.');
    Referral_Account__c refAcct = refAccts.get(0);
        System.assertNotEquals(null,refAcct,'Referral Account is null.');
        System.assertEquals('34565',refAcct.Zip_Postal_Code__c, 'Invalid Referral Contact Zip_Postal_Code__c.');
        
        Referral_Contact__c[] refContacts = [SELECT Id, LatestCampaign__c, Name, First_Name__c, Last_Name__c, Phone__c, Email__c, Product_of_Interest__c FROM Referral_Contact__c WHERE CreatedDate = TODAY];
        System.assertEquals(1,refContacts.size(), 'No Referral Contact is found.');
    Referral_Contact__c refCont = refContacts.get(0);
        System.assertNotEquals(null,refCont,'Referral Contact is null.');
        System.assertEquals(camp.Id,refCont.LatestCampaign__c, 'Invalid Referral Contact LatestCampaign__c.');
        System.assertEquals('jay.smith@abc.com',refCont.Email__c, 'Invalid Referral Contact Email__c.');
        System.assertEquals('945-333-2574',refCont.Phone__c, 'Invalid Referral Contact Phone__c.');
        System.assertEquals('Payroll;Benefits;Retirement Services',refCont.Product_of_Interest__c, 'Referral Contact Product_of_Interest__c is null.');
    } // testValidPayload  
    
  @IsTest
    static void testWithoutCampaign(){
        ReferralObjectsSync.SKIP_SYNC=false;
        // test matching to existing
        Referral_Account__c refAcct = new Referral_Account__c(Name='ABC Inc.', NameForDuplicateManagement__c='ABC Inc.', Zip_Postal_Code__c='34565');
        insert refAcct;
        refAcct = [Select Id, Name, Account__c, Zip_Postal_Code__c from Referral_Account__c where Id=:refAcct.Id ];
        System.assertNotEquals(null, refAcct.Account__c);
        Referral_Contact__c refCtct = new Referral_Contact__c(Referral_Account__c=refAcct.Id, Name='Jay Smith', First_Name__c='Jay', Last_Name__c='Smith', Email__c='jay.smith@abc.com', Phone__c='945-333-2574');
        insert refCtct;
        refCtct = [Select Id, Name, Contact__c, First_Name__c, Last_Name__c, Email__c, Phone__c, Referral_Account__c
                         ,Contact__r.AccountId
                     From Referral_Contact__c where Id=:refCtct.Id];
        System.assertNotEquals(null, refCtct.Contact__c);
        
        
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<ContactMe><CompanyName>ABC Inc.</CompanyName>' + 
            '<FirstName>Jay</FirstName><LastName>Smith</LastName><Email>jay.smith@abc.com</Email>' + 
            '<Phone>945-333-2574</Phone><ZipCode>34565</ZipCode>' + 
            '<ProductsOfInterest><item>Payroll</item><item>Benefits</item><item>Retirement Services</item></ProductsOfInterest>' + 
            '<Comments>This is a sample.</Comments><FormURL>http://paychex.com/form</FormURL></ContactMe>';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        AccountantReferralPartnerEmailHandler obj = new AccountantReferralPartnerEmailHandler();
        obj.handleInboundEmail(email, env);
        System.debug('obj.partRef.Comments__c::'+obj.partRef.Comments__c);
        System.assertNotEquals(null,obj.partRef,'Partner Referral is null.');
        System.assertEquals('CPA',obj.partRef.Source__c, 'CPA');
        System.assertEquals(false,obj.partRef.Processed__c, 'Partner Referral Processed should be false.');
        Boolean success = obj.partRef.Comments__c.contains('No Campaign found for Form URL: ') ? true : false;
        System.assertEquals(true,success, 'No Campaign found for Form URL: ');
        System.assertEquals(refCtct.Contact__c, obj.partRef.Contact__c);
        System.assertEquals(refCtct.Contact__r.AccountId, obj.partRef.Account__c);
    } // testWithoutCampaign   
    
        @IsTest
    static void testValidPayload2(){
        ReferralObjectsSync.SKIP_SYNC=false;
        
        Campaign camp = new Campaign(Name='Unit Testing', Originator__c='Marketing', LeadSource__c='Jigsaw', Form_URL__c='http://paychex.com/Payrollform', IsActive=true, Target_Audience__c='Payroll Acquisition');
        insert camp;
        
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<ContactMe><CompanyName>ABC Inc.</CompanyName>' + 
            '<FirstName>Jay</FirstName><LastName>Smith</LastName><Email>jay.smith@abc.com</Email>' + 
            '<Phone>945-333-2574</Phone><ZipCode>34565</ZipCode>' + 
            '<ProductsOfInterest><item>Payroll</item><item>Benefits</item><item>Retirement Services</item></ProductsOfInterest>' + 
            '<Comments>This is a sample.</Comments><FormURL>http://paychex.com/Payrollform</FormURL></ContactMe>';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        AccountantReferralPartnerEmailHandler obj = new AccountantReferralPartnerEmailHandler();
        obj.handleInboundEmail(email, env);

        System.assertNotEquals(null,obj.partRef,'Partner Referral is null.');
        System.assertEquals('CPA',obj.partRef.Source__c);
        System.assertEquals(true,obj.partRef.Processed__c);
        System.assertEquals('Successful',obj.partRef.Comments__c);
                        
        PartnerReferral__c[] partRefs = [SELECT Id, Account__c, Contact__c FROM PartnerReferral__c WHERE Id=:obj.partRef.Id];
        System.assertEquals(1,partRefs.size());
    PartnerReferral__c partRef = partRefs.get(0);
        System.assertNotEquals(null,partRef,'Partner Referral is null.');

        Referral_Account__c[] refAccts = [SELECT Id, Account__c, Zip_Postal_Code__c, Phone__c, Referral_Source_Business_Type__c, Hold_Out_Reason__c, Hold_Out__c  FROM Referral_Account__c WHERE CreatedDate = TODAY];
        System.assertEquals(1,refAccts.size(), 'No Referral Account is found.');
    Referral_Account__c refAcct = refAccts.get(0);
        System.assertNotEquals(null,refAcct,'Referral Account is null.');
        System.assertEquals('34565',refAcct.Zip_Postal_Code__c, 'Invalid Referral Contact Zip_Postal_Code__c.');
        Assert.areEqual('Payroll Company',refAcct.Referral_Source_Business_Type__c);
        Assert.isTrue(refAcct.Hold_Out__c);
        
        Referral_Contact__c[] refContacts = [SELECT Id, LatestCampaign__c, Name, First_Name__c, Last_Name__c, Phone__c, Email__c, Product_of_Interest__c FROM Referral_Contact__c WHERE CreatedDate = TODAY];
        System.assertEquals(1,refContacts.size(), 'No Referral Contact is found.');
    Referral_Contact__c refCont = refContacts.get(0);
        System.assertNotEquals(null,refCont,'Referral Contact is null.');
        System.assertEquals(camp.Id,refCont.LatestCampaign__c, 'Invalid Referral Contact LatestCampaign__c.');
        System.assertEquals('jay.smith@abc.com',refCont.Email__c, 'Invalid Referral Contact Email__c.');
        System.assertEquals('945-333-2574',refCont.Phone__c, 'Invalid Referral Contact Phone__c.');
        System.assertEquals('Payroll;Benefits;Retirement Services',refCont.Product_of_Interest__c, 'Referral Contact Product_of_Interest__c is null.');
    } // testValidPayload2 
    
    static testMethod void testBadValues() {
       AccountantReferralPartnerEmailHandler.testFlds = new String[]{'Email__c'};
       AccountantReferralPartnerEmailHandler.testValues = new String[]{'paychex.tst','sample.com'};
       PartnerReferral__c partRef = new PartnerReferral__c(Email__c='joe@paychex.tst');
       AccountantReferralPartnerEmailHandler.checkForTest(partRef);
       Assert.isTrue(partRef.PurgeRecord__c);
       Assert.isTrue(partRef.Processed__c);
       Assert.isTrue(partRef.Comments__c.contains('PurgeRecord marked true due'),'Comments: '+partRef.Comments__c);
        
       partRef = new PartnerReferral__c(Email__c='goodemail@paychex.com'); 
       AccountantReferralPartnerEmailHandler.checkForTest(partRef);
       Assert.isFalse(partRef.PurgeRecord__c);
       Assert.isFalse(partRef.Processed__c);
       Assert.isNull(partRef.Comments__c,'Comments: '+partRef.Comments__c);


    } // testBadValues
    
} // class AccountantRPEmailHandlerTest