/**
 * Test method for SoarEmailHandler and SOARHelper
 * 
 * History
 * --------
 * 10/01/2013   Cindy Freeman   created
 * 01/06/2014  Cindy Freeman  modified for new logic
 * 08/12/2015  Cindy Freeman  modified for holdout logic
 * 03/22/2016  Cindy Freeman  added check of DSA and Manager on referral
 * 05/17/2016  Cindy Freeman  added new SOAR email fields, region and Soar Id
 * 06/05/2016  Cindy Freeman  added test of plain text email body
 * 06/18/2016  Cindy Freeman  changed soar_Id to just soarid 
 * 06/30/2016  Cindy Freeman  added check of referral.ZipSegment
 * 07/21/2016  Josh Cartwright  added test 2b for new Preview - Additional custom setting
 * 03/08/2017  Cindy Freeman  changed to use PEO Steelbrick profile
 * 06/28/2017  Cindy Freeman  added tests for PartnerReferral creation
 * 10/25/2017  Cindy Freeman  added test for fixNotes method
 * 03/05/2019  Cindy Freeman  added test for Processed field on partner referral
 * 03/26/2019  Cindy Freeman  updated test for new error handling code
   07/08/2019  Dan Carmen     Change for Core Sales profile move
   09/10/2020  Brandon Vidro  Change to userVirtual query for APR0110504
   07/12/2022  Carrie Marciano removed hard coded client numbers to prevent failing on validation
   07/25/2022  Carrie Marciano bumped api version
   08/01/2023  Carrie Marciano removed assert that is no longer needed
 */
 
@isTest
public class SOAREmailHandlerTest {

   @testSetup
   public static void setupData() {
      User testRunningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
      Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP);
      insert payxAcct;
      payxEmp = new Contact(FirstName=testRunningUser.FirstName, LastName=testRunningUser.LastName
                         ,AccountId=payxAcct.Id, HR_Person_Id__c=testRunningUser.HR_Person_Id__c, Email=testRunningUser.Email);      
      insert payxEmp;
      
      populatePayxSetting();
      createPartners();
      createZipRules();
      populateSoarProductMappings();
   } // setupData

   private static User runningUser;
   private static Contact payxEmp;

   private static void setupTest() {
    // select a user to run as - make sure we get one with a person id
      //runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
      //Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP);
      //insert payxAcct;
      //payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName
      //                   ,AccountId=payxAcct.Id, HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
      //insert payxEmp;
      
      payxEmp = [Select Id, FirstName, LastName, AccountId, HR_Person_Id__c, Email from Contact where Account.Name = :UserHelper.PAYCHEX_COMP limit 1];
      runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c = :payxEmp.HR_Person_Id__c limit 1];
   } // setupTest

   static testMethod void testBlankEmail(){
      // clear setting for this test
      try {
         delete [Select Id from PaychexSettings__c where Name='SoarForwardErrorEmail'];
      } catch (Exception e) {
         // do nothing here.
      }

        Boolean testPassed = false;
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        SOAREmailHandler sEH = new SOAREmailHandler();
        try{
            sEH.handleInboundEmail(email, env);
        }
        catch(SOAREmailHandler.SOARException ex)
        {   testPassed = true;  }     // sends email instead of throwing error coz email body is empty
        System.assertEquals(false, testPassed);
        
    } //testBlankEmail
    
    static testMethod void testBadXML(){
        populatePayxSetting();
        Boolean testPassed = false;
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.htmlBody = '<SoarInformation><junk></SoarInformation>';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        SOAREmailHandler sEH = new SOAREmailHandler();
        try{
            sEH.handleInboundEmail(email, env);
        }
        catch(SOAREmailHandler.SOARException ex)
        {   testPassed = true;  }     // sends email instead of throwing error coz email body is empty
        System.assertEquals(false, testPassed);
        
    } //testBadXML
    
    
   // test error handling with XMLparsing
   @isTest(SeeAllData=false)
   static void myUnitTest1() {
   
      setupTest();
      //createZipRules();
      //createPartners();
      //populatePayxSetting();
      //populateSoarProductMappings();
      
      System.runAs(runningUser) {
         messaging.Inboundemail email = new messaging.Inboundemail();
         email.htmlBody = '<SoarInformation>';

         // populate email body with bad personID
         email.htmlBody += addXML('EEEmail',runningUser.Email);
         email.htmlBody += addXML('PersonID','101010');
         email.htmlBody += addXML('ID',null);
         email.htmlBody += addXML('BIS',null);
         email.htmlBody += addXML('CostCenter','0027');
         email.htmlBody += addXML('ClientNumber',null);
         email.htmlBody += addXML('CompanyName','Test Method New Company Client Name');
         email.htmlBody += addXML('Address','1270 Creekbend Lane');
         email.htmlBody += addXML('City','Webster');
         email.htmlBody += addXML('State','NY');
         email.htmlBody += addXML('ZipCode','10019');
         email.htmlBody += addXML('EmployeeCount','36');
         email.htmlBody += addXML('Product','New Client');
         email.htmlBody += addXML('FirstName','First');
         email.htmlBody += addXML('LastName>','Last');
         email.htmlBody += addXML('PhoneNumber','585-222-3434');
         email.htmlBody += addXML('Platform','None');
         email.htmlBody += addXML('AddOnClient','No');
         email.htmlBody += addXML('AdvClient','No');
         email.htmlBody += addXML('Notes','Big Notes');
         email.htmlBody += addXML('SOARID','10');
         email.htmlBody += addXML('Region','1');
         email.htmlBody += '</SoarInformation>\r\nThe information contained';
        
         Boolean testPassed = false;
         try
         { 
           Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
           SOAREmailHandler sEH = new SOAREmailHandler();
           sEH.handleInboundEmail(email, env); 
         }
         catch (Exception e)
         {   testPassed = true;  }     // sends email instead of throwing error due to parsing error
         System.assertEquals(false,testPassed);
     
     PartnerReferral__c[] partRefList = [Select Id, Comments__c from PartnerReferral__c where createdDate = Today];
     System.assertEquals(1,partRefList.size());
System.debug('**partRef='+partRefList.get(0));          
     System.assertEquals(true, partRefList.get(0).Comments__c.contains('Unable to Parse XML'));
     
      } // System.runAs
    } // myUnitTest1
   
    // test good parsing of plain text
    @isTest(SeeAllData=false)
    static void myUnitTest1a() {
      setupTest();
      //createPartners();
      //createZipRules();
      //populateSoarProductMappings();
      
      System.runAs(runningUser) {        
         Messaging.InboundEmail email = new Messaging.InboundEmail() ;
         Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
 
         // setup the data for the email
         email.subject = 'Test SOAR Referrals';
         email.fromname = 'FirstName LastName';
         env.fromAddress = 'someaddress@email.com';
                
         // populate plain text email body
         String test1 = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ payxEmp.HR_Person_Id__c+'</PersonID>\r';
         test1 += '<ID></ID>\r <BIS></BIS>\r <CostCenter>0027</CostCenter>\r';
         test1 += '<ClientNumber></ClientNumber>\r <CompanyName>Test Method New Company Client Name</CompanyName>\r <Address>1270 Creekbend Lane</Address>\r';
         test1 += '<City>Webster</City>\r <State>NY</State>\r <ZipCode>14625</ZipCode>\r <EmployeeCount>36</EmployeeCount>\r <Product>New Client</Product>\r';
         test1 += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
         test1 += '<Platform>None</Platform><AddOnClient>No</AddOnClient><AdvClient>No</AdvClient>';
         test1 += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
         email.plainTextBody = test1;
        
         // call Helper class directly to check parsing then process list creating new account and contact       
         SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
         //Test.startTest();        
         sr = SOARHelper.parseXml(email.plainTextBody);
         
         System.assertEquals(sr.id.length(), 0);
         System.assertEquals(sr.EEEmail, runningUser.Email);
         System.assertEquals(sr.personId, payxEmp.HR_Person_Id__c);
         System.assertEquals(sr.bis.length(), 0);
         System.assertEquals(sr.currClient,'No');
         System.assertEquals(sr.costCenter, '0027');
         System.assertEquals(sr.clientNumber.length(), 0);
         System.assertEquals(sr.firstName, 'Jeff');
         System.assertEquals(sr.lastName, 'Elliott');
         System.assertEquals(sr.fullName, 'Jeff Elliott');
         System.assertEquals(sr.companyName, 'Test Method New Company Client Name');
         System.assertEquals(sr.employeeCount, '36');
         System.assertEquals(sr.phoneNumber, '585-222-3434');
         System.assertEquals(sr.squishedPhone, '5852223434');
         System.assertEquals(sr.address, '1270 Creekbend Lane');
         System.assertEquals(sr.city, 'Webster');
         System.assertEquals(sr.state, 'NY');
         System.assertEquals(sr.zipCode, ZIP1);
         System.assertEquals(sr.product, 'New Client');
         System.assertEquals(sr.notes, 'Big Notes email address');
         System.assertEquals(sr.soarId, 10);
         System.assertEquals(sr.Region, 1);
                  
         SOAREmailHandler sEH = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env); 
         
      } // System.runAs(runningUser
   } // myUnitTest1a       

    // create new account, contact, referral for core New Client using valid zipcode
    //   send 2nd referral for different product
   @isTest(SeeAllData=false)
   static void myUnitTest2() {
      setupTest();
      //createPartners();
      //createZipRules();
      //ZipCheckOwnerTest.setupZipsAndSegments(true);
      //populateSoarProductMappings();
      
      System.runAs(runningUser) {        
         messaging.Inboundemail email = new messaging.Inboundemail();
         email.htmlBody = '<SoarInformation>';
         
         email.htmlBody += addXML('EEEmail',runningUser.Email);
         email.htmlBody += addXML('PersonID',payxEmp.HR_Person_Id__c);
         email.htmlBody += addXML('ID','');
         email.htmlBody += addXML('BIS','');
         email.htmlBody += addXML('CostCenter','0027');
         email.htmlBody += addXML('ClientNumber','');
         email.htmlBody += addXML('CompanyName','Test_Method_New_Company_Client_Name');
         email.htmlBody += addXML('Address','1270 Creekbend Lane');
         email.htmlBody += addXML('City','Webster');
         email.htmlBody += addXML('State','NY');
         email.htmlBody += addXML('ZipCode','14625');
         email.htmlBody += addXML('EmployeeCount','36');
         email.htmlBody += addXML('Product','New Client');
         email.htmlBody += addXML('FirstName','Jeff');
         email.htmlBody += addXML('LastName','Elliott');
         email.htmlBody += addXML('PhoneNumber','585-222-3434');
         email.htmlBody += addXML('Platform','None');
         email.htmlBody += addXML('AddOnClient','No');
         email.htmlBody += addXML('AdvClient','No');
         email.htmlBody += addXML('Notes','Big Notes'); 
         email.htmlBody += addXML('Region','1');        
         email.htmlBody += addXML('FederalID','123456789');
         email.htmlBody += '</SoarInformation>\r\nThe information contained';
         Test.StartTest();         
         Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env); 
         Test.StopTest();
         Account newAcct = [Select Id, Name, Phone, BillingPostalCode, OwnerId, AccountNumber, NumberOfEmployees, X401k_Assets__c
                                  ,RecordType.Name, Federal_ID_Number__c
                                  ,(Select Id, Name, RecordTypeId, OwnerId, SOAR_Region__c from Opportunities) from Account 
                     where Name = 'Test Method New Company Client Name'];
         System.assertEquals('123456789',newAcct.Federal_ID_Number__c);
         System.assertEquals(ZIP1, newAcct.BillingPostalCode);         
         
         //Zip_Assignment__c z = [select Id, Name, User__r.Id from Zip_Assignment__c where Name = :ZIP1 and Sales_Org__c=:UserHelper.SO_CORE limit 1];         
         //System.assertEquals(z.User__r.Id, newAcct.OwnerId);
         SoarProductMapping__c unknownSPM = SoarProductMapping__c.getInstance('Prod17');
         User unknownUser = [Select Id, FirstName, LastName, HR_Person_Id__c from User where HR_Person_Id__c = :unknownSPM.Default_Rep_HR_Person_ID__c and isActive = true limit 1];
         //System.assertEquals(unknownUser.Id, newAcct.OwnerId);

         Contact newCtct = [Select firstName, lastName, Email from Contact where AccountId = :newAcct.Id];
         System.assertEquals('Elliott', newCtct.LastName);
         System.assertEquals(1,newAcct.Opportunities.size());
      
         for (Opportunity opty: newAcct.Opportunities)
         {  System.assertEquals('Test Method New Company Client Name-PAY',opty.Name);            
            //System.assertEquals(newAcct.OwnerId, opty.OwnerId);
            System.assertEquals(1, opty.SOAR_Region__c);
         }
         Referral__c newRef = [Select Id, Selling_opportunity__r.Id, Account__r.Id, ReferFromContact__r.Id, 
                        SourceContact__r.Id from Referral__c where Account__r.Id = :newAcct.Id];
         System.assertEquals(payxEmp.Id, newRef.ReferFromContact__r.Id);                        

         // ********* create 2nd referral same prospect, same contact lastname and phone, different product
         newAcct.AccountNumber = '123-4567';
         update newAcct;      
         
         messaging.Inboundemail email2 = new messaging.Inboundemail();
         email2.htmlBody = '<SoarInformation>';        
         email2.htmlBody += addXML('EEEmail',runningUser.Email);
         email2.htmlBody += addXML('PersonID',runningUser.HR_Person_Id__c);
         email2.htmlBody += addXML('ID',newAcct.Id);
         email2.htmlBody += addXML('BIS','456-456');
         email2.htmlBody += addXML('CostCenter','123');
         email2.htmlBody += addXML('ClientNumber','');
         email2.htmlBody += addXML('CompanyName','Test Method New Company Client Name');
         email2.htmlBody += addXML('Address','');
         email2.htmlBody += addXML('City','');
         email2.htmlBody += addXML('State','');
         email2.htmlBody += addXML('ZipCode','14625');
         email2.htmlBody += addXML('EmployeeCount','36');
         email2.htmlBody += addXML('Product','401(k)');
         email2.htmlBody += addXML('FirstName','J');
         email2.htmlBody += addXML('LastName','Elliott');
         email2.htmlBody += addXML('PhoneNumber','585-222-3434');
         email2.htmlBody += addXML('Platform','None');
         email2.htmlBody += addXML('AddOnClient','No');
         email2.htmlBody += addXML('AdvClient','No');
         email2.htmlBody += addXML('Notes','Big Notes');
         email2.htmlBody += addXML('SOARID','10');
         email2.htmlBody += addXML('Region','1');
         email2.htmlBody += addXML('ContactEmail','sam@whocares.com');
         email2.htmlBody += '</SoarInformation>\r\nThe information contained';
         
         Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH2 = new SOAREmailHandler();
         sEH2.handleInboundEmail(email2, env2); 
         
         Referral__c[] refList = [Select Id, Selling_opportunity__r.Id, Account__r.Id, ReferFromContact__r.Id, 
                        SourceContact__r.Id from Referral__c where Account__r.Id = :newAcct.Id];
         System.assertEquals(2, refList.size());

      } // System.runAs(runningUser
   } // myUnitTest2

    // create new account, contact, referral for core New Client using valid zipcode
   //    send 2nd referral for addon client
   @isTest(SeeAllData=false)
   static void myUnitTest2a() {
      setupTest();
      //createPartners();
      //createZipRules();
      //populateSoarProductMappings();

      System.runAs(runningUser) {        
         messaging.Inboundemail email = new messaging.Inboundemail();
         email.htmlBody = '<SOARINFORMATION>';

         // ********* create referral, prospect, contact lastname and phone, Insurance to create HNBF opty coz not Advantage
         email.htmlBody += addXML('EEEmail',runningUser.Email);
         email.htmlBody += addXML('PersonID',payxEmp.HR_Person_Id__c);
         email.htmlBody += addXML('ID','');
         email.htmlBody += addXML('BIS','');
         email.htmlBody += addXML('CostCenter','0027');
         email.htmlBody += addXML('ClientNumber','');
         email.htmlBody += addXML('CompanyName','Test Method New Company Client Name');
         email.htmlBody += addXML('Address','1270 Creekbend Lane');
         email.htmlBody += addXML('City','Anytown');
         email.htmlBody += addXML('State','NY');
         email.htmlBody += addXML('ZipCode','14625');
         email.htmlBody += addXML('EmployeeCount','99');
         //email.htmlBody += addXML('Product','Health Insurance');
         email.htmlBody += addXML('Product','New Client');
         email.htmlBody += addXML('FirstName','J');
         email.htmlBody += addXML('LastName','Elliott');
         email.htmlBody += addXML('PhoneNumber','585-222-3434');
         email.htmlBody += addXML('Platform','None');
         email.htmlBody += addXML('AddOnClient','No');
         email.htmlBody += addXML('AdvClient','No');
         email.htmlBody += addXML('Notes','Big Notes');
         email.htmlBody += addXML('SOARID','10');
         email.htmlBody += addXML('Region','1');
         email.htmlBody += '</SOARINFORMATION>\r\nThe information contained';
         
         Test.startTest();
         Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env); 
         
         Account newAcct = [Select Id, Name, Phone, BillingPostalCode, OwnerId, AccountNumber, NumberOfEmployees, X401k_Assets__c
                                  ,RecordType.Name,(Select Id, Name, RecordTypeId, OwnerId from Opportunities) from Account 
                                where Name = 'Test Method New Company Client Name'];
         
         Referral__c[] refList =  [Select Id, Selling_opportunity__r.Id, Selling_opportunity__r.Name, Account__r.Id, ReferFromContact__r.Id, 
                        SourceContact__r.Id,ZipSegment__c from Referral__c where Account__r.Id = :newAcct.Id];  // and Selling_opportunity__r.Name Like '%HNBF%'];
         System.assertEquals(1, refList.size());
         //System.assertEquals('TESTHNBF1',refList.get(0).ZipSegment__c);
         
         // ********* create 4th referral for AddOn client
         messaging.Inboundemail email2 = new messaging.Inboundemail();
         email2.htmlBody = '<SoarInformation>';        
         email2.htmlBody += addXML('EEEmail',runningUser.Email);
         email2.htmlBody += addXML('PersonID',runningUser.HR_Person_Id__c);
         email2.htmlBody += addXML('ID',newAcct.Id);
         email2.htmlBody += addXML('BIS','123-123');
         email2.htmlBody += addXML('CostCenter','123');
         email2.htmlBody += addXML('ClientNumber','');
         email2.htmlBody += addXML('CompanyName','Test Method AddOn Company Client Name');
         email2.htmlBody += addXML('Address','745 West 50th St');
         email2.htmlBody += addXML('City','Anytown');
         email2.htmlBody += addXML('State','NY');
         email2.htmlBody += addXML('ZipCode','14625');
         email2.htmlBody += addXML('EmployeeCount','3');
         email2.htmlBody += addXML('Product','New Client');
         email2.htmlBody += addXML('FirstName','S');
         email2.htmlBody += addXML('LastName','Smith');
         email2.htmlBody += addXML('PhoneNumber','585-222-4545');
         email2.htmlBody += addXML('Platform','None');
         email2.htmlBody += addXML('AddOnClient','Yes');
         email2.htmlBody += addXML('AdvClient','No');
         email2.htmlBody += addXML('Notes','Big Notes');
         email2.htmlBody += addXML('SOARID','10');
         email2.htmlBody += addXML('Region','1');
         email2.htmlBody += '</SoarInformation>\r\nThe information contained';
         
         Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH2 = new SOAREmailHandler();
         sEH2.handleInboundEmail(email2, env2);                         
         
         Account addonAcct = [Select Id, Name, Phone, BillingPostalCode, OwnerId, AccountNumber, (Select Id, Name, RecordTypeId, OwnerId from Opportunities) from Account 
                     where Name = 'Test Method AddOn Company Client Name'];
         //System.assertEquals(addonAcct.OwnerId, newAcct.OwnerId);                      
         refList = [Select Id, Selling_opportunity__r.Id, Account__r.Id, ReferFromContact__r.Id, 
               User__r.Id, SourceContact__r.Id, SellingLeadSource__c from Referral__c where Account__r.Id = :addonAcct.Id];
         System.assertEquals(1, refList.size());
         //System.assertEquals(refList.get(0).User__r.Id, addonAcct.OwnerId);
         System.assertEquals(Label.LeadSource_Internal_SOAR_Id, refList.get(0).SellingLeadSource__c); 
          
         Test.stopTest();
      } // System.runAs(runningUser
   } // myUnitTest2a

   // send in referral creating new account, make it Preview Client, then send in AddOn referral to be assigned to Chrissy Joshlin   
   //JC 7/21/2016      
   @isTest(SeeAllData=false) 
static void myUnitTest2b(){
  setupTest();
      //createPartners();
      //createZipRules();
      //populateSoarProductMappings();

      System.runAs(runningUser) {        
         messaging.Inboundemail email = new messaging.Inboundemail();
         email.htmlBody = '<SoarInformation>';

         // ********* create referral, prospect, contact lastname and phone
         email.htmlBody += addXML('EEEmail',runningUser.Email);
         email.htmlBody += addXML('PersonID',payxEmp.HR_Person_Id__c);
         email.htmlBody += addXML('ID','');
         email.htmlBody += addXML('BIS','');
         email.htmlBody += addXML('CostCenter','0027');
         email.htmlBody += addXML('ClientNumber','');
         email.htmlBody += addXML('CompanyName','Test Method New Company Client Name');
         email.htmlBody += addXML('Address','1270 Creekbend Lane');
         email.htmlBody += addXML('City','Anytown');
         email.htmlBody += addXML('State','NY');
         email.htmlBody += addXML('ZipCode','14625');
         email.htmlBody += addXML('EmployeeCount','99');
         email.htmlBody += addXML('Product','New Client');
         email.htmlBody += addXML('FirstName','J');
         email.htmlBody += addXML('LastName','Elliott');
         email.htmlBody += addXML('PhoneNumber','585-222-3434');
         email.htmlBody += addXML('Platform','None');
         email.htmlBody += addXML('AddOnClient','No');
         email.htmlBody += addXML('AdvClient','No');
         email.htmlBody += addXML('Notes','Big Notes');
         email.htmlBody += addXML('SOARID','10');
         email.htmlBody += addXML('Region','1');
         email.htmlBody += '</SoarInformation>\r\nThe information contained';
         
         Test.startTest();
         Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env); 
         
         Account newAcct = [Select Id, Name, Phone, BillingPostalCode, OwnerId, type, AccountNumber, NumberOfEmployees, X401k_Assets__c
                                  ,RecordType.Name,(Select Id, Name, RecordTypeId, OwnerId from Opportunities) from Account 
                                where Name = 'Test Method New Company Client Name'];

         
         Referral__c[] refList =  [Select Id, Selling_opportunity__r.Id, Selling_opportunity__r.Name, Account__r.Id, ReferFromContact__r.Id, 
                        SourceContact__r.Id,ZipSegment__c from Referral__c where Account__r.Id = :newAcct.Id and Selling_opportunity__r.Name Like '%MMS%'];
         System.assertEquals(1, refList.size());
         
         newAcct.type ='Preview Client';
     update newAcct;                
         
         // ********* create referral for AddOn preview client
         messaging.Inboundemail email2 = new messaging.Inboundemail();
         email2.htmlBody = '<SoarInformation>';        
         email2.htmlBody += addXML('EEEmail',runningUser.Email);
         email2.htmlBody += addXML('PersonID',runningUser.HR_Person_Id__c);
         email2.htmlBody += addXML('ID',newAcct.Id);
         email2.htmlBody += addXML('BIS','123-123');
         email2.htmlBody += addXML('CostCenter','123');
         email2.htmlBody += addXML('ClientNumber','');
         email2.htmlBody += addXML('CompanyName','Test Method Preview AddOn Company Client Name');
         email2.htmlBody += addXML('Address','500 East 50th St');
         email2.htmlBody += addXML('City','ThisTown');
         email2.htmlBody += addXML('State','NY');
         email2.htmlBody += addXML('ZipCode','14625');
         email2.htmlBody += addXML('EmployeeCount','3');
         email2.htmlBody += addXML('Product','New Client');
         email2.htmlBody += addXML('FirstName','S');
         email2.htmlBody += addXML('LastName','Smith');
         email2.htmlBody += addXML('PhoneNumber','585-222-4545');
         email2.htmlBody += addXML('Platform','None');
         email2.htmlBody += addXML('AddOnClient','Yes');
         email2.htmlBody += addXML('AdvClient','No');
         email2.htmlBody += addXML('Notes','Big Notes');
         email2.htmlBody += addXML('SOARID','10');
         email2.htmlBody += addXML('Region','1');
         email2.htmlBody += '</SoarInformation>\r\nThe information contained';
         
         Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH2 = new SOAREmailHandler();
         sEH2.handleInboundEmail(email2, env2);                         
         
         Account addonAcct = [Select Id, Name, Phone, BillingPostalCode, OwnerId, AccountNumber, (Select Id, Name, RecordTypeId, OwnerId from Opportunities) from Account 
                     where Name = 'Test Method Preview AddOn Company Client Name'];
         System.assertNotEquals(null, addonAcct);
         refList = [Select Id, Selling_opportunity__r.Id, selling_opportunity__r.Ownerid, selling_opportunity__r.Owner.HR_Person_Id__c,Account__r.Id, ReferFromContact__r.Id, 
               User__r.Id, SourceContact__r.Id, SellingLeadSource__c from Referral__c where Account__r.Id = :addonAcct.Id];     
         System.assertEquals(1, refList.size());      
         SoarProductMapping__c spm = [Select Id, Name, Default_Rep_HR_Person_ID__c from SoarProductMapping__c where Name = 'Prod16'];       
         System.assertEquals(refList.get(0).selling_opportunity__r.Owner.HR_Person_Id__c, spm.Default_Rep_HR_Person_ID__c);
          
         Test.stopTest();

      }//System.runAs(runningUser)
}//test 2b
   //end JC 7/21/2016
   
   @isTest(SeeAllData=false)
   static void myUnitTest3() { 
      setupTest();
      //createPartners();
      //createZipRules();
      //populateSoarProductMappings();

      User[] users = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS limit 3];
      Schema.RecordTypeInfo acctMMSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
      
      Account currClient = new Account(Name='Test Account', Bis_ID__c=123, OwnerId=users[0].Id,HNBF_Account_Owner__c=users[1].Id
                                     ,HRS_Account_Owner__c = users[2].Id, BillingPostalCode=ZIP1
                                     ,RecordTypeId = acctMMSrt.getRecordTypeId(), AccountNumber='17-1234' );
      insert currClient;
      DateTime futureDate = System.Now() + 180;
      Date newDate = Date.newInstance(futureDate.year(), futureDate.month(), futureDate.day());
      currClient.HRS_Hold_Out__c=true;
      currClient.HRS_Hold_Out_Expiration__c = newDate;
      update currClient;

      System.runAs(runningUser) {        
        
         // ************ sending referral for existing prospect-client ****************
         
         currClient = [Select Id, Name, AccountNumber, Bis_ID__c, HNBF_Account_Owner__r.Id, HRS_Account_Owner__r.Id, BillingPostalCode from Account 
                        where Id = :currClient.Id];                       
         String[] brclno = currClient.AccountNumber.split('-');
         
         messaging.Inboundemail email = new messaging.Inboundemail();
         email.htmlBody = '<SoarInformation>';        
         email.htmlBody += addXML('EEEmail',runningUser.Email);
         email.htmlBody += addXML('PersonID',runningUser.HR_Person_Id__c);
         email.htmlBody += addXML('ID',currClient.Id);
         email.htmlBody += addXML('BIS',String.valueOf(currClient.Bis_ID__c));
         email.htmlBody += addXML('CostCenter',brclno.get(0));
         email.htmlBody += addXML('ClientNumber',brclno.get(1));
         email.htmlBody += addXML('CompanyName',currClient.Name);
         email.htmlBody += addXML('Address','');
         email.htmlBody += addXML('City','');
         email.htmlBody += addXML('State','');
         email.htmlBody += addXML('ZipCode',currClient.BillingPostalCode);
         email.htmlBody += addXML('EmployeeCount','16');
         email.htmlBody += addXML('Product','401(k)');
         email.htmlBody += addXML('FirstName','Testing');
         email.htmlBody += addXML('LastName','Testing');
         email.htmlBody += addXML('PhoneNumber','585-222-4343');
         email.htmlBody += addXML('Platform','None');
         email.htmlBody += addXML('AddOnClient','No');
         email.htmlBody += addXML('AdvClient','No');
         email.htmlBody += addXML('Notes','Big Notes');
         //email.htmlBody += addXML('SOARID','10');
         //email.htmlBody += addXML('Region','1');
         email.htmlBody += '</SoarInformation>\r\nThe information contained';
         
         Test.startTest();
         Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env); 
                  
         Referral__c newRef = [Select Id, Selling_opportunity__r.Id, Account__r.Id, ReferFromContact__r.Id, 
                        SourceContact__r.Id, User__r.Id, DSA__r.Id, DSM__r.Id, SellingLeadSource__c
                        from Referral__c where Account__r.Id = :currClient.Id and Referral_Source__c = 'SOAR'];
         System.assertEquals(currClient.HRS_Account_Owner__r.Id, newRef.User__r.Id);                        
         // be sure set dsa and dsm and LeadSource correctly on referral
         User u = [Select Id, ManagerId, DSA_FSS__r.Id from User where id = :currClient.HRS_Account_Owner__r.Id];
         System.assertEquals(u.ManagerId, newRef.DSM__r.Id);
         System.assertEquals(u.DSA_FSS__r.Id, newRef.DSA__r.Id); 
         System.assertEquals(Label.LeadSource_Internal_SOAR_Prod, newRef.SellingLeadSource__c);
         // be sure created new contact
         Contact ct = [Select Id, FirstName, LastName from Contact where AccountId = :currClient.Id 
                  and CreatedDate = Today limit 1];    
         System.assertEquals('Testing',ct.FirstName);
         System.assertEquals('Testing',ct.LastName);
      
       PartnerReferral__c partRef = [Select Id, Account__c, Contact__c, Referral__c, Comments__c, Processed__c 
                       from PartnerReferral__c where CreatedDate = TODAY limit 1];
       System.assertEquals(currClient.Id, partRef.Account__c);
       System.assertEquals(ct.Id, partRef.Contact__c);
       System.assertEquals(newRef.Id, partRef.Referral__c);
       System.assertEquals('Successful', partRef.Comments__c);
       System.assertEquals(true, partRef.Processed__c);
       
         // process duplicate referral
         Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH2 = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env2); 
            
         Referral__c[] refList = [Select Id, Name, Selling_Opportunity__r.Id, ReferFromContact__r.Id, Contact__r.Id, Account__r.Id, Status__c
                        from Referral__c where Account__r.Id = :currClient.Id and Referral_Source__c = 'SOAR'];
         System.assertEquals(2, refList.size());
         Boolean goodRef = false;
         Boolean dupRef = false;
         for (Referral__c ref: refList)
         {  goodRef = (ref.Status__c == 'Referral Sent' ? true : goodRef);
            dupRef = (ref.Status__c == 'SOAR Duplicate' ? true : dupRef);
         }
         System.assertEquals(true, goodRef && dupRef);
      
      
         Test.StopTest();
      } // System.runAs   
                    
   } // myUnitTest3

   // create new account, contact, opty with zip code not in table so assigns to MMS Unknown Rep 
   //   create MMS based on platform  
   @isTest(SeeAllData=false)
   static void myUnitTest4() {  
      setupTest();
      //createPartners();
      //createZipRules();
      //populateSoarProductMappings();
       
      Schema.RecordTypeInfo optyMMSrt = RecordTypeHelper.getRecordType('MMS Opportunity Record Type', 'Opportunity');
      System.runAs(runningUser) {       
         messaging.Inboundemail email = new messaging.Inboundemail();
         email.htmlBody = '<SoarInformation>';

         // ********* create referral, prospect, contact lastname and phone, Insurance to create HNBF opty coz not Advantage
         email.htmlBody += addXML('EEEmail',runningUser.Email);
         email.htmlBody += addXML('PersonID',runningUser.HR_Person_Id__c);
         email.htmlBody += addXML('ID','');
         email.htmlBody += addXML('BIS','');
         email.htmlBody += addXML('CostCenter','0407');
         email.htmlBody += addXML('ClientNumber','');
         email.htmlBody += addXML('CompanyName','Test Method New Company Client Name');
         email.htmlBody += addXML('Address','1270 Creekbend Lane');
         email.htmlBody += addXML('City','Anytown');
         email.htmlBody += addXML('State','NY');
         email.htmlBody += addXML('ZipCode','00010');
         email.htmlBody += addXML('EmployeeCount','100');
         email.htmlBody += addXML('Product','New Client');
         email.htmlBody += addXML('FirstName','Jeff');
         email.htmlBody += addXML('LastName','Testing');
         email.htmlBody += addXML('PhoneNumber','585-222-3434');
         email.htmlBody += addXML('Platform','MMS - 50+ EE\'s');
         email.htmlBody += addXML('AddOnClient','No');
         email.htmlBody += addXML('AdvClient','No');
         email.htmlBody += addXML('Notes','Big Notes');
         email.htmlBody += addXML('SOARID','10');
         email.htmlBody += addXML('Region','1');
         email.htmlBody += '</SoarInformation>\r\nThe information contained';
         
         Test.startTest();
         Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env); 
        
         Account newAcct = [Select Id, RecordTypeId, Name, Phone, BillingPostalCode, Owner.Id, Owner.Name, Owner.HR_Person_Id__c, AccountNumber,
                        (Select Id, Name, RecordTypeId, OwnerId from Opportunities) from Account 
                        where Name = 'Test Method New Company Client Name'];
         Schema.RecordTypeInfo acctRT = RecordTypeHelper.getRecordTypeById(newAcct.RecordTypeId, 'Account');
         System.assertEquals(true, acctRT.getName().startsWith('MMS'));  
         SoarProductMapping__c spm = [Select Id, Name, Default_Rep_HR_Person_ID__c from SoarProductMapping__c where Name = 'Prod12'];       
         System.assertEquals(spm.Default_Rep_HR_Person_ID__c, newAcct.Owner.HR_Person_Id__c);
                                 
         Referral__c newRef = [Select Id, Selling_opportunity__r.Id, Account__r.Id, ReferFromContact__r.Id, 
                        SourceContact__r.Id, User__r.Id, User__r.Job_Name__c, DSA__c, DSM__c  
                        from Referral__c]; // where Account__r.Id = :newAcct.Id and Referral_Source__c = 'SOAR'];
         User mmsUser = [Select Id, Name, HR_Person_Id__c, DSA_FSS__r.Id, ManagerId from User where HR_Person_Id__c = :spm.Default_Rep_HR_Person_ID__c and IsActive = true];                        
         System.assertEquals(mmsUser.Id, newRef.User__r.Id);      
         System.assertEquals(mmsUser.DSA_FSS__r.Id, newRef.DSA__c);
         System.assertEquals(null, newRef.DSM__c);
             
         for (Opportunity opty: newAcct.Opportunities)
         {  Schema.RecordTypeInfo currOptyrt = RecordTypeHelper.getRecordTypeById(opty.RecordTypeId, 'Opportunity');          
            System.assertEquals(mmsUser.Id, opty.OwnerId);
            System.assertEquals(true, currOptyrt.getName().contains('MMS'));
            System.assertEquals('Test Method New Company Client Name-MMS',opty.Name);
         }                 
                     
         Test.StopTest();           
      } // System.runAs                 
   } // myUnitTest4
  

   // set up and test open zipcode which uses DSA opty owner
   //   then send AddOn referral
   @isTest(SeeAllData=false)
   static void myUnitTest5() { 
      setupTest();
      //createPartners();
      //createZipRules();
      //populateSoarProductMappings();

      User dsaUser = [select Id, Name, Job_Name__c, HR_Person_Id__c, Cost_Center__c, Profile.Name from User 
                     where Cost_Center__c != null 
                     and Profile.Name in :Utilities.DSA_PROFS
                     and Sales_Org__c = :UserHelper.SO_MMS and IsActive=true and Job_Name__c=:UserHelper.JOB_DSA limit 1];
                     
      Org_Unit__c district = new Org_Unit__c(Name='10',Sales_Org__c=UserHelper.SO_MMS, Org_Type__c=OrgUnitMethods.TYPE_DISTRICT);
      insert district;
      
      Org_Unit_User_Link__c ouul = new Org_Unit_User_Link__c(Org_Unit__c=district.Id, User__c=dsaUser.Id);
      insert ouul;
      
      Zip_Segment__c zipSeg = new Zip_Segment__c(Name='DEFAULT',Emps_Min__c=0, Emps_Max__c=99999, Sales_Org__c=UserHelper.SO_MMS);
      insert zipSeg;

      ZipTerritory__c territory = new ZipTerritory__c(District__c=district.Id, Name='Open Territory', Rep_Name__c='Open Territory', Zip_Segment__c=zipSeg.Id);
      insert territory;

      Zip_Assignment__c openZip = new Zip_Assignment__c(Name='12345', Rep_Name__c='OPEN', Sales_Org__c=UserHelper.SO_MMS, Zip_Segment__c=zipSeg.Id
                                     ,District__c=district.Id, ZipTerritory__c=territory.Id );
      insert openZip;
      openZip = [Select Id, Name, Rep_Name__c, Sales_Org__c, User__c, User__r.Name, User__r.HR_Person_Id__c from Zip_Assignment__c where Id = :openZip.Id];
      System.assertEquals(UserHelper.UNASSIGNED_MMS_PERSON_ID, openZip.User__r.HR_Person_Id__c);
      
      //Zip_Assignment__c openZip = [Select id, name, Rep_Name__c,Sales_Org__c,User__r.Name, User__r.Id, 
      //               Organization_Structure__r.Cost_Center__c 
      //               from Zip_Assignment__c where Rep_Name__c = 'OPEN' and Sales_Org__c = 'MMS' limit 1];
     
      System.runAs(runningUser) {
         messaging.Inboundemail email = new messaging.Inboundemail();
         email.htmlBody = '<SoarInformation>';

         // ********* create referral, prospect, contact lastname and phone, Insurance to create HNBF opty coz not Advantage
         email.htmlBody += addXML('EEEmail',runningUser.Email);
         email.htmlBody += addXML('PersonID',runningUser.HR_Person_Id__c);
         email.htmlBody += addXML('ID','');
         email.htmlBody += addXML('BIS','');
         email.htmlBody += addXML('CostCenter',dsaUser.Cost_Center__c);
         email.htmlBody += addXML('ClientNumber','');
         email.htmlBody += addXML('CompanyName','Test Method New Company Client Name');
         email.htmlBody += addXML('Address','1270 Creekbend Lane');
         email.htmlBody += addXML('City','Anytown');
         email.htmlBody += addXML('State','NY');
         email.htmlBody += addXML('ZipCode',openZip.Name);
         email.htmlBody += addXML('EmployeeCount','99');
         email.htmlBody += addXML('Product','New Client');
         email.htmlBody += addXML('FirstName','Jeff');
         email.htmlBody += addXML('LastName','Testing');
         email.htmlBody += addXML('PhoneNumber','585-222-3434');
         email.htmlBody += addXML('Platform','None');
         email.htmlBody += addXML('AddOnClient','No');
         email.htmlBody += addXML('AdvClient','No');
         email.htmlBody += addXML('Notes','Big Notes');
         email.htmlBody += addXML('SOARID','10');
         email.htmlBody += addXML('Region','1');
         email.htmlBody += '</SoarInformation>\r\nThe information contained';
         
         Test.startTest();
         Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env); 
         
         Account newAcct = [Select Id, RecordTypeId, Name, Phone, BillingPostalCode, Owner.Id, Owner.Name, AccountNumber, 
                     (Select Id, Name, RecordTypeId, OwnerId from Opportunities) from Account 
                     where Name = 'Test Method New Company Client Name']; 
         System.assertEquals(openZip.Name, newAcct.BillingPostalCode);
         
         SoarProductMapping__c spm = [Select Id, Name, Default_Rep_HR_Person_ID__c from SoarProductMapping__c where Name = 'Prod12'];
         User mmsUser = [Select Id, Name, HR_Person_Id__c from User where HR_Person_Id__c = :spm.Default_Rep_HR_Person_ID__c and IsActive = true];  
         System.assertEquals(mmsUser.Id, newAcct.OwnerId);         
                                 
         Referral__c newRef = [Select Id, DSM__c, Selling_opportunity__r.Id, Account__r.Id, ReferFromContact__r.Id, 
                        SourceContact__r.Id, User__r.Id, User__r.Job_Name__c from Referral__c where Account__r.Id = :newAcct.Id and Referral_Source__c = 'SOAR'];
     //System.assertEquals(null, newRef.DSM__c);                        
         //for (Opportunity opty: newAcct.Opportunities)
         //{  System.assertEquals(mmsUser.Id, opty.OwnerId);  }  

         Test.StopTest();           
      } // System.runAs              
   } // myUnitTest5
 
   // test Advantage for Virtual Sales  
   //
   @isTest(SeeAllData=false)
   static void myUnitTest6() { 
      setupTest();
      //createPartners();
      //createZipRules();
      //populateSoarProductMappings();

      User virtualUser = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where Name = 'Virtual Sales' and IsActive=true limit 1];
      //SoarProductMapping__c spm = [Select Id, Name, Default_Rep_HR_Person_ID__c from SoarProductMapping__c where Name = 'Prod11'];
      //User virtualUser = [Select Id, Name, HR_Person_Id__c from User where HR_Person_Id__c = :spm.Default_Rep_HR_Person_ID__c and IsActive = true]; 
       
      System.runAs(runningUser) {
         messaging.Inboundemail email = new messaging.Inboundemail();
         email.htmlBody = '<SoarInformation>';

         // ********* create referral, prospect, contact lastname and phone, Insurance to create HNBF opty coz not Advantage
         email.htmlBody += addXML('EEEmail',runningUser.Email);
         email.htmlBody += addXML('PersonID',payxEmp.HR_Person_Id__c);
         email.htmlBody += addXML('ID','');
         email.htmlBody += addXML('BIS','');
         email.htmlBody += addXML('CostCenter','0027');
         email.htmlBody += addXML('ClientNumber','');
         email.htmlBody += addXML('CompanyName','Test Method New Company Client Name');
         email.htmlBody += addXML('Address','1270 Creekbend Lane');
         email.htmlBody += addXML('City','Anytown');
         email.htmlBody += addXML('State','NY');
         email.htmlBody += addXML('ZipCode','14625');
         email.htmlBody += addXML('EmployeeCount','36');
         email.htmlBody += addXML('Product','New Client');
         email.htmlBody += addXML('FirstName','Jeff');
         email.htmlBody += addXML('LastName','Testing');
         email.htmlBody += addXML('PhoneNumber','585-222-3434');
         email.htmlBody += addXML('Platform','Advantage');
         email.htmlBody += addXML('AddOnClient','No');
         email.htmlBody += addXML('AdvClient','No');
         email.htmlBody += addXML('Notes','Big Notes');
         email.htmlBody += addXML('SOARID','10');
         email.htmlBody += addXML('Region','1');
         email.htmlBody += '</SoarInformation>\r\nThe information contained';
         
         Test.startTest();
         Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env); 
               
         Account newAcct = [Select Id, Name, Phone, BillingPostalCode, OwnerId, AccountNumber, (Select Id, Name, RecordTypeId, OwnerId from Opportunities) from Account 
                     where Name = 'Test Method New Company Client Name'];
         //System.assertEquals(coreUser.Id, newAcct.OwnerId);
      
         for (Opportunity opty: newAcct.Opportunities)
         {  System.assertEquals('Test Method New Company Client Name-PAY',opty.Name);  
           // System.assertEquals(virtualUser.Id, opty.OwnerId);
         }
       
      } // System.runAs
   } // myUnitTest6 

   // test ASO/PEO platform for PAS
   @isTest(SeeAllData=false)
   static void myUnitTest7() { 
      setupTest();
      //createPartners();
      //createZipRules();
      //populateSoarProductMappings();
      
      System.runAs(runningUser) {
         messaging.Inboundemail email = new messaging.Inboundemail();
         email.htmlBody = '<SoarInformation>';
         
         email.htmlBody += addXML('EEEmail',runningUser.Email);
         email.htmlBody += addXML('PersonID',payxEmp.HR_Person_Id__c);
         email.htmlBody += addXML('ID','');
         email.htmlBody += addXML('BIS','');
         email.htmlBody += addXML('CostCenter','0027');
         email.htmlBody += addXML('ClientNumber','');
         email.htmlBody += addXML('CompanyName','Test Method New Company Client Name');
         email.htmlBody += addXML('Address','1270 Creekbend Lane');
         email.htmlBody += addXML('City','Anytown');
         email.htmlBody += addXML('State','NY');
         email.htmlBody += addXML('ZipCode','14625');
         email.htmlBody += addXML('EmployeeCount','36');
         email.htmlBody += addXML('Product','New Client');
         email.htmlBody += addXML('FirstName','Jeff');
         email.htmlBody += addXML('LastName','Testing');
         email.htmlBody += addXML('PhoneNumber','585-222-3434');
         email.htmlBody += addXML('Platform','ASO/PEO');
         email.htmlBody += addXML('AddOnClient','No');
         email.htmlBody += addXML('AdvClient','No');
         email.htmlBody += addXML('Notes','Big Notes');
         email.htmlBody += addXML('SOARID','10');
         email.htmlBody += addXML('Region','1');
         email.htmlBody += '</SoarInformation>\r\nThe information contained';
         
         Test.startTest();
         Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env); 
            
         Account newAcct = [Select Id, Name, Phone, BillingPostalCode, OwnerId, AccountNumber, Premier_PBS_Account_Owner__r.Id,
                     (Select Id, Name, RecordTypeId, OwnerId from Opportunities) from Account 
                     where Name = 'Test Method New Company Client Name'];     
         for (Opportunity opty: newAcct.Opportunities)
         {  Schema.RecordTypeInfo currOptyrt = RecordTypeHelper.getRecordTypeById(opty.RecordTypeId, 'Opportunity');
            System.debug('currOptyrt='+currOptyrt);
         //   System.assertEquals(true, currOptyrt.getName().contains('ASO'));                   
            //System.assertEquals(newAcct.Premier_PBS_Account_Owner__r.Id, opty.OwnerId);
         }

      } // System.runAs
   } // myUnitTest7 

   // test no existing account and production not New Client
   // create account, then test using default Rep on SoarProductMapping
   @isTest(SeeAllData=false)
   static void myUnitTest8() { 
      setupTest();
      //createPartners();
      //createZipRules();
      //populateSoarProductMappings();
      SoarProductMapping__c spm = [Select Id, Name, Default_Rep_HR_Person_ID__c from SoarProductMapping__c where Name = 'Prod15'];
       
      System.runAs(runningUser) {
         messaging.Inboundemail email = new messaging.Inboundemail();
         email.htmlBody = '<SoarInformation>';
         
         email.htmlBody += addXML('EEEmail',runningUser.Email);
         email.htmlBody += addXML('PersonID',payxEmp.HR_Person_Id__c);
         email.htmlBody += addXML('ID','');
         email.htmlBody += addXML('BIS','');
         email.htmlBody += addXML('CostCenter','0027');
         email.htmlBody += addXML('ClientNumber','');
         email.htmlBody += addXML('CompanyName','Test Account');
         email.htmlBody += addXML('Address','1270 Creekbend Lane');
         email.htmlBody += addXML('City','Anytown');
         email.htmlBody += addXML('State','NY');
         email.htmlBody += addXML('ZipCode','14625');
         email.htmlBody += addXML('EmployeeCount','36');
         email.htmlBody += addXML('Product','ESR');
         email.htmlBody += addXML('FirstName','Jeff');
         email.htmlBody += addXML('LastName','Testing');
         email.htmlBody += addXML('PhoneNumber','585-222-3434');
         email.htmlBody += addXML('Platform','Unknown');
         email.htmlBody += addXML('AddOnClient','No');
         email.htmlBody += addXML('AdvClient','No');
         email.htmlBody += addXML('Notes','Big Notes');
         email.htmlBody += addXML('SOARID','10');
         email.htmlBody += addXML('Region','1');
         email.htmlBody += '</SoarInformation>\r\nThe information contained';
         
         Test.startTest();
         Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
         SOAREmailHandler sEH = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env); 

         PartnerReferral__c[] partRefList = [Select Id, Comments__c from PartnerReferral__c where createdDate = Today];
         System.assertEquals(1,partRefList.size());
         System.debug('**partRef='+partRefList.get(0));          
         System.assertEquals(true, partRefList.get(0).Comments__c.contains('Missing account ID'));
          
         User[] users = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS limit 3];
         Schema.RecordTypeInfo acctMMSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);      
         Account currClient = new Account(Name='Test Account', Bis_ID__c=123, OwnerId=users[0].Id,HNBF_Account_Owner__c=users[1].Id
                                     ,HRS_Account_Owner__c = users[2].Id, BillingPostalCode=ZIP1
                                     ,RecordTypeId = acctMMSrt.getRecordTypeId(), AccountNumber='17-1234' );
         insert currClient;
          
         email = new messaging.Inboundemail();
         email.htmlBody = '<SoarInformation>';
         
         email.htmlBody += addXML('EEEmail',runningUser.Email);
         email.htmlBody += addXML('PersonID',payxEmp.HR_Person_Id__c);
         email.htmlBody += addXML('ID',(String)currClient.Id);
         email.htmlBody += addXML('BIS','');
         email.htmlBody += addXML('CostCenter','0027');
         email.htmlBody += addXML('ClientNumber','');
         email.htmlBody += addXML('CompanyName','Test Account');
         email.htmlBody += addXML('Address','1270 Creekbend Lane');
         email.htmlBody += addXML('City','Anytown');
         email.htmlBody += addXML('State','NY');
         email.htmlBody += addXML('ZipCode','14625');
         email.htmlBody += addXML('EmployeeCount','36');
         email.htmlBody += addXML('Product','ESR');
         email.htmlBody += addXML('FirstName','Jeff');
         email.htmlBody += addXML('LastName','Testing');
         email.htmlBody += addXML('PhoneNumber','585-222-3434');
         email.htmlBody += addXML('Platform','Unknown');
         email.htmlBody += addXML('AddOnClient','No');
         email.htmlBody += addXML('AdvClient','No');
         email.htmlBody += addXML('Notes','Big Notes');
         email.htmlBody += addXML('SOARID','10');
         email.htmlBody += addXML('Region','1');
         email.htmlBody += '</SoarInformation>\r\nThe information contained';
         
         env = new Messaging.InboundEnvelope();
         sEH = new SOAREmailHandler();
         sEH.handleInboundEmail(email, env); 
        
         Account newAcct = [Select Id, Name, Phone, BillingPostalCode, OwnerId, AccountNumber, Premier_PBS_Account_Owner__r.Id,
                     (Select Id, Name, RecordTypeId, OwnerId, Owner.HR_Person_ID__c from Opportunities) from Account 
                     where Name = 'Test Account'];     
         for (Opportunity opty: newAcct.Opportunities)
         {  Schema.RecordTypeInfo currOptyrt = RecordTypeHelper.getRecordTypeById(opty.RecordTypeId, 'Opportunity');
            System.assertEquals(true, currOptyrt.getName().contains('HNBF'));            
            System.assertEquals(spm.Default_Rep_HR_Person_ID__c, opty.Owner.HR_Person_ID__c);
         }

      } // System.runAs
   } // myUnitTest8
      
  public static final String ZIP1='14625';
  public static final String ZIP2='99916';
  public static final String ZIP3='99915';
 
  public static void createZipRules() {

      // select test users
      User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.CORE_PROFS limit 2];
      User uCore = users[0];
      User uCore2 = users[1];
      User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS and Profile.Name =:Utilities.PROF_MMS_SALES_SB limit 1];
      User uHrs = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_401 and Profile.Name =:Utilities.PROF_HRS_401K limit 1];
      User uPeo = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO and Profile.Name =:Utilities.PROF_HRS_PEO_ASO_SB limit 1];
      User uHnb = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_HNB and Profile.Name =:Utilities.PROF_HNBF_SALES_REP limit 1];
      User uVirtual = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where Name = 'Virtual Sales' and IsActive=true limit 1];
      
      // verify the unassigned users exist
      User unassignedCore = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c=:UserHelper.UNASSIGNED_CORE_PERSON_ID limit 1];
      User unassignedMMS = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c=:UserHelper.UNASSIGNED_MMS_PERSON_ID limit 1];
 
      ZipCheckOwnerTest.setupSegments();
      Zip_Segment__c advSegment = new Zip_Segment__c(Name='TESTADV1',Sales_Org__c='ADV',Emps_Min__c=0, Emps_Max__c=99999999);
      insert advSegment;
      
      // create Zip Assignment records
      Zip_Assignment__c za1 = new Zip_Assignment__c(Name=ZIP1,HR_Person_Id__c=uCore.HR_Person_Id__c
                                                   ,User__c=uCore.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=50
                                                   ,Asset_Min__c=0, Asset_Max__c=0
                                                   ,Sales_Org__c=uCore.Sales_Org__c, MC_Id__c='TestCore'
                                                   ,Segment_Name__c=ZipCheckOwnerTest.coreSeg1.Name, Zip_Segment__c=ZipCheckOwnerTest.coreSeg1.Id);
      Zip_Assignment__c za2 = new Zip_Assignment__c(Name=ZIP3,HR_Person_Id__c=uCore.HR_Person_Id__c
                                                   ,User__c=uCore.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=50
                                                   ,Asset_Min__c=0, Asset_Max__c=0
                                                   ,Sales_Org__c=uCore.Sales_Org__c, MC_Id__c='TestCore'
                                                   ,Segment_Name__c=ZipCheckOwnerTest.coreSeg1.Name, Zip_Segment__c=ZipCheckOwnerTest.coreSeg1.Id);
      Zip_Assignment__c za3 = new Zip_Assignment__c(Name=ZIP1,HR_Person_Id__c=uMms.HR_Person_Id__c
                                                   ,User__c=uMms.Id
                                                   ,Emps_Min__c=50, Emps_Max__c=1000
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=uMms.Sales_Org__c, MC_Id__c='TestMms'
                                                   ,Segment_Name__c=ZipCheckOwnerTest.mmsSeg2.Name, Zip_Segment__c=ZipCheckOwnerTest.mmsSeg2.Id);
      Zip_Assignment__c za4 = new Zip_Assignment__c(Name=ZIP1,HR_Person_Id__c=uHrs.HR_Person_Id__c
                                                   ,User__c=uHrs.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=99
                                                   ,Asset_Min__c=0, Asset_Max__c=1000
                                                   ,Sales_Org__c=uHrs.Sales_Org__c, MC_Id__c='Test401'
                                                   ,Segment_Name__c=ZipCheckOwnerTest.hrsSeg1.Name, Zip_Segment__c=ZipCheckOwnerTest.hrsSeg1.Id);
      Zip_Assignment__c za5 = new Zip_Assignment__c(Name=ZIP1,HR_Person_Id__c=uPeo.HR_Person_Id__c
                                                   ,User__c=uPeo.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=uPeo.Sales_Org__c, MC_Id__c='TestPeo'
                                                   ,Segment_Name__c=ZipCheckOwnerTest.pasSeg1.Name, Zip_Segment__c=ZipCheckOwnerTest.pasSeg1.Id);
      Zip_Assignment__c za6 = new Zip_Assignment__c(Name=ZIP1,HR_Person_Id__c=uHnb.HR_Person_Id__c
                                                   ,User__c=uHnb.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=uHnb.Sales_Org__c, MC_Id__c='TestHnb'
                                                   ,Segment_Name__c=ZipCheckOwnerTest.hnbSeg1.Name, Zip_Segment__c=ZipCheckOwnerTest.hnbSeg1.Id);
                                                   
      Zip_Assignment__c za7 = new Zip_Assignment__c(Name=ZIP2,HR_Person_Id__c=null
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=UserHelper.SO_CORE, MC_Id__c='TestCore'
                                                   ,Segment_Name__c=ZipCheckOwnerTest.coreSeg1.Name, Zip_Segment__c=ZipCheckOwnerTest.coreSeg1.Id);
      Zip_Assignment__c za8 = new Zip_Assignment__c(Name=ZIP2,HR_Person_Id__c=null
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=UserHelper.SO_MMS, MC_Id__c='TestMms'
                                                   ,Segment_Name__c=ZipCheckOwnerTest.mmsSeg2.Name, Zip_Segment__c=ZipCheckOwnerTest.mmsSeg2.Id);
      Zip_Assignment__c za9 = new Zip_Assignment__c(Name=ZIP2,HR_Person_Id__c=null
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Asset_Min__c=0, Asset_Max__c=100
                                                   ,Sales_Org__c=UserHelper.SO_401, MC_Id__c='Test401'
                                                   ,Segment_Name__c=ZipCheckOwnerTest.hrsSeg1.Name, Zip_Segment__c=ZipCheckOwnerTest.hrsSeg1.Id);
      Zip_Assignment__c za10 = new Zip_Assignment__c(Name=ZIP1,HR_Person_Id__c=uVirtual.HR_Person_Id__c
                                                   ,User__c=uVirtual.Id
                                                   ,Emps_Min__c=0, Emps_Max__c=50
                                                   ,Asset_Min__c=0, Asset_Max__c=0
                                                   ,Sales_Org__c=UserHelper.SO_ADV, MC_Id__c='TestAdv'
                                                   ,Segment_Name__c=advSegment.Name, Zip_Segment__c=advSegment.Id);
      Zip_Assignment__c[] zas = new Zip_Assignment__c[]{za1,za2,za3,za4,za5,za6,za7,za8,za9,za10};
      insert zas;       
  } // createZipRules
  

    
  private static void createPartners() {
   // create referral partner records
   Referral_Partner__c paypart = new Referral_Partner__c(Name = UserHelper.SO_CORE,CreateRefOpp__c=False, Partner_Type__c=SOARHelper.PARTNER_SOAR,
                              Selling_Opp_RecordTypeId__c='012500000000n4LAAQ',Sort_Order__c=10);   //,Use_Contact__c=True);
   Referral_Partner__c mmspart = new Referral_Partner__c(Name = UserHelper.SO_MMS,CreateRefOpp__c=False, Partner_Type__c=SOARHelper.PARTNER_SOAR,
                              Selling_Opp_RecordTypeId__c='012300000000hQQAAY',Sort_Order__c=20);   //,Use_Contact__c=True);
   Referral_Partner__c hnbfpart = new Referral_Partner__c(Name = UserHelper.SO_HNB,CreateRefOpp__c=False, Partner_Type__c=SOARHelper.PARTNER_SOAR,
                              Selling_Opp_RecordTypeId__c='01270000000Q5O2AAK',Sort_Order__c=50);   //,Use_Contact__c=True);
   Referral_Partner__c paspart = new Referral_Partner__c(Name = UserHelper.SO_PEO_ASO,CreateRefOpp__c=False, Partner_Type__c=SOARHelper.PARTNER_SOAR,
                              Selling_Opp_RecordTypeId__c='012500000000n4VAAQ',Sort_Order__c=40);   //,Use_Contact__c=True);
   Referral_Partner__c hrspart = new Referral_Partner__c(Name = UserHelper.SO_401,CreateRefOpp__c=False, Partner_Type__c=SOARHelper.PARTNER_SOAR,
                              Selling_Opp_RecordTypeId__c='012500000000n4QAAQ',Sort_Order__c=30);   //,Use_Contact__c=True);
   Referral_Partner__c[] refpartList = new Referral_Partner__c[]{paypart,mmspart,hnbfpart,paspart,hrspart};
   insert refpartList;
   
  } // createPartners
 
  /** populate setting used to determine if email needs to be forwarded
   */
  
   public static void populatePayxSetting() { 
        PaychexSettings__c payx = new PaychexSettings__c (
            Name = 'SoarForwardErrorEmail'
            ,IsActive__c=true
            ,Attribute1__c = 'dcarmen@paychex.com; someone@paychex.com');
        upsert payx;
        return;
        
    } // populatePayxSetting  
 
  /** populate setting for Soar Product Mappings
   */
   public static void populateSoarProductMappings() {
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();
        SoarProductMapping__c spm = new SoarProductMapping__c(Name='Prod01',AdvClient__c=true, Emp_Count_Min__c=0,Emp_Count_Max__c=49,
                                        Product__c='New Client',Sales_Org__c='PAY');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod02',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,
                                        Product__c='New Client',Sales_Org__c='PAY'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod03',AdvClient__c=true, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,
                                        Product__c='New Client',Sales_Org__c='MMS'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod04',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,
                                        Product__c='New Client',Sales_Org__c='MMS'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod05',AdvClient__c=false, 
                                        Product__c='New Client',Sales_Org__c='MMS',Platform__c='MMS - 50+Ees'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod06',AdvClient__c=false, 
                                        Product__c='New Client',Sales_Org__c='PAS',Platform__c='ASO/PEO'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod07',AdvClient__c=false, 
                                        Product__c='401(k)',Sales_Org__c='HRS'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod08',AdvClient__c=false, 
                                        Product__c='Check Signing',Sales_Org__c='PAY');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod09',AdvClient__c=false, 
                                        Product__c='Health Insurance',Sales_Org__c='HNBF'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod10',AdvClient__c=false, 
                                        Product__c='Health Reimbursement Account',Sales_Org__c='HRS',ZipSegment__c='SMALL_MARKET'); 
        spmList.add(spm);
        User virtualUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name LIKE 'Core Zone Administration%' 
                            and UserRole.Name like 'VIRTUAL SALES%' and IsActive = true limit 1];
        spm = new SoarProductMapping__c(Name='Prod11',Default_Rep__c=virtualUser.Name, Default_Rep_HR_Person_ID__c=virtualUser.HR_Person_ID__c,
                                        Product__c='Unknown Rep',Sales_Org__c='ADV'); 
        spmList.add(spm);   
        User mmsUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'MMS Sales ZSA%' 
                            and UserRole.Name = 'MMS VP' and IsActive = true limit 1];
        spm = new SoarProductMapping__c(Name='Prod12',Default_Rep__c=mmsUser.Name, Default_Rep_HR_Person_ID__c=mmsUser.HR_Person_ID__c,
                                        Product__c='Unknown Rep',Sales_Org__c='MMS',Exclude_DSM__c=true); 
        spmList.add(spm);   
        spm = new SoarProductMapping__c(Name='Prod13',AdvClient__c=false,
                                        Product__c='New Client',Sales_Org__c='ADV',Platform__c='Advantage'); 
        spmList.add(spm);
        User hnbfUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'HNBF Sales Admin%' 
                            and IsActive = true limit 1];
        spm = new SoarProductMapping__c(Name='Prod14',Default_Rep__c=mmsUser.Name, Default_Rep_HR_Person_ID__c=hnbfUser.HR_Person_ID__c,
                                        Product__c='Unknown Rep',Sales_Org__c='HNBF'); 
        spmList.add(spm);
        User hnbfUser2 = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'HNBF Sales Admin%' 
                            and IsActive = true and Id != :hnbfUser.Id limit 1];
        spm = new SoarProductMapping__c(Name='Prod15',Default_Rep__c=hnbfUser2.Name, Default_Rep_HR_Person_ID__c=hnbfUser2.HR_Person_ID__c,
                                        Product__c='ESR',Sales_Org__c='HNBF'); 
        spmList.add(spm);
        User mmsAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'MMS Sales ZSA - SB%' 
                            and IsActive = true and Id != :mmsUser.Id limit 1];        
        spm = new SoarProductMapping__c(Name='Prod16',Default_Rep__c=mmsAdminUser.Name, Default_Rep_HR_Person_ID__c=mmsAdminUser.HR_Person_ID__c,
                                        Product__c='Flex Add On (Current Preview Client)',Sales_Org__c='MMS'); 
        spmList.add(spm);
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,
                                        Product__c='Unknown Rep',Sales_Org__c='PAY'); 
        spmList.add(spm);
           
        upsert spmList;
        return;
                
   } // populateSoarProductMappings
 
    static string addXML(string tag, string content){
        return '<' + tag + '>' + content + '</' + tag + '>\r\n';
    }
    
} // class SOAREmailHandlerTest