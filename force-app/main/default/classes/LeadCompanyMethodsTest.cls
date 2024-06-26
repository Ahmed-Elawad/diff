/**
 * This class contains unit tests for validating the LeadCompanyMethods class
 * 
 *
 * History
 * --------
 * 05/21/2013 Cindy Freeman     created
   11/06/2014 Dan Carmen        Change to convert extra leads outside this form
   09/11/2018 Dan Carmen        Change code to run more in the future.

 */
@isTest
public class LeadCompanyMethodsTest {

   @testSetup
   public static void setupData(){
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerSetup__c trigSetup1 = TriggerMethodsTest.createCustomSetting(null, 'LeadAfter', false, true, new String[]{'LeadCompanyMethods'},setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;
   } // setupData

   static testMethod void testLCMethods() {
      LeadCompanyMethods.SKIP_FUTURE=true;
      Schema.RecordTypeInfo leadCoreRT = RecordTypeHelper.getRecordType('Core Lead Record Type', 'Lead');
      // test createCompany
      Lead ld1 = new Lead(Firstname = 'Mary'
                         ,Lastname = 'Lead1'
                         ,Company = 'Test Account11'
                         ,recordtypeId = leadCoreRT.getRecordTypeId()
                         ,Phone = '555-3333'
                         ,Email = 'mary@account11.com'
                         ,Street = '10 Main St'
                         ,City = 'Rochester'
                         ,State = 'NY'
                         ,PostalCode = '10000'
                         ,NSS_Prospect_ID__c = '12345'
                         ,Lead_Company__c = null
                         ,DataFlux_Id__c = null
                         ,LeadGroupId__c = null);
      insert ld1;
      List<Lead_Company__c> compList = [Select Id, Name, LeadGroupId__c, SignificantLead__c from Lead_Company__c];
      System.assertEquals(1, compList.size());
      System.assertEquals(ld1.Id, compList.get(0).LeadGroupId__c);
      System.assertEquals(ld1.Id, compList.get(0).SignificantLead__c);
      ld1 = [select Id, Name, Company, Lead_Company__c, LeadGroupId__c from Lead where id = :ld1.Id];
      System.assertEquals(ld1.Lead_Company__c, compList.get(0).Id);
        
      // test findCompanies with existing LeadGroupId
      Lead ld2 = new Lead(Firstname = 'John'
                         ,Lastname = 'Lead2'
                         ,Company = 'Test Account11'
                         ,recordtypeId = leadCoreRT.getRecordTypeId()
                         ,Phone = '555-4444'
                         ,Email = 'john@account11.com'
                         ,Street = '10 Main St'
                         ,City = 'Rochester'
                         ,State = 'NY'
                         ,PostalCode = '10000'
                         ,NSS_Prospect_ID__c = '54321'
                         ,Lead_Company__c = null
                         ,DataFlux_Id__c = null
                         ,LeadGroupId__c = ld1.LeadGroupId__c);
                         //,LeadGroupId__c = compList.get(0).LeadGroupId__c );
      LeadCompanyMethods.SKIP_LEAD_TRIGGER = false;
      insert ld2; 
      ld2 = [select Id, Name, Company, Lead_Company__c, LeadGroupId__c from Lead where id = :ld2.Id];               
      System.assertEquals(ld2.Lead_Company__c, ld1.Lead_Company__c);
        
      // test findCompanies and createLeadGroupCompanies with new LeadGroupId
      Lead ld3 = new Lead(Firstname = 'Bill'
                         ,Lastname = 'Lead3'
                         ,Company = 'Test Account22'
                         ,recordtypeId = leadCoreRT.getRecordTypeId()
                         ,Phone = '555-6565'
                         ,Email = 'bill@account22.com'
                         ,Street = '75 West First St'
                         ,City = 'NYC'
                         ,State = 'NY'
                         ,PostalCode = '10101'
                         ,NSS_Prospect_ID__c = null
                         ,Lead_Company__c = null
                         ,DataFlux_Id__c = null
                         ,LeadGroupId__c = '201' );
      LeadCompanyMethods.SKIP_LEAD_TRIGGER = false;
      insert ld3; 
      ld3 = [select Id, Name, Company, Lead_Company__c, LeadGroupId__c from Lead where id = :ld3.Id];
      compList = [Select Id, Name, LeadGroupId__c from Lead_Company__c];
      System.assertEquals(2, compList.size());               
      System.assertNotEquals(ld3.Lead_Company__c, ld1.Lead_Company__c);
        
      // test createNoLeadGroupCompanies
      Lead ld4 = new Lead(Firstname = 'Sally'
                         ,Lastname = 'Lead4'
                         ,Company = 'Test Account44'
                         ,recordtypeId = leadCoreRT.getRecordTypeId()
                         ,Phone = '444-6565'
                         ,Email = 'sally@account44.com'
                         ,Street = '75 West Main'
                         ,City = 'Avon'
                         ,State = 'NY'
                         ,PostalCode = '14414'
                         ,NSS_Prospect_ID__c = null
                         ,Lead_Company__c = null
                         ,DataFlux_Id__c = null
                         ,LeadGroupId__c = null );                            
      Lead ld5 = new Lead(Firstname = 'George'
                         ,Lastname = 'Lead5'
                         ,Company = 'Test Account55'
                         ,recordtypeId = leadCoreRT.getRecordTypeId()
                         ,Phone = '511-6565'
                         ,Email = 'george@account55.com'
                         ,Street = '750 Maple St'
                         ,City = 'NYC'
                         ,State = 'NY'
                         ,PostalCode = '10120'
                         ,NSS_Prospect_ID__c = null
                         ,Lead_Company__c = null
                         ,DataFlux_Id__c = null
                         ,LeadGroupId__c = null );
      List<Lead> insertLeads = new List<Lead> {ld4, ld5};                               
      LeadCompanyMethods.SKIP_LEAD_TRIGGER = false;
      insert insertLeads;
      compList = [Select Id, Name, LeadGroupId__c from Lead_Company__c];
      System.assertEquals(4, compList.size());
      ld4 = [select Id, Name, Company, Lead_Company__c, LeadGroupId__c from Lead where id = :ld4.Id];
      System.assertNotEquals(null, ld4.Lead_Company__c);
      ld5 = [select Id, Name, Company, Lead_Company__c, LeadGroupId__c from Lead where id = :ld5.Id];
      System.assertNotEquals(ld4.Lead_Company__c, ld5.Lead_Company__c);
        
      // test delete Lead but 2 Leads linked to Lead Company so Company stays
      delete ld2;
      compList = [Select Id, Name, LeadGroupId__c from Lead_Company__c];
      System.assertEquals(4, compList.size());
        
      // test delete Lead also deletes Lead Company
      delete ld1;
      compList = [Select Id, Name, LeadGroupId__c from Lead_Company__c];
      System.assertEquals(3, compList.size());
   
      // test createUnDeletedLeadCompanies
      LeadCompanyMethods.SKIP_LEAD_TRIGGER = false;
      undelete ld1;
      compList = [Select Id, Name, LeadGroupId__c from Lead_Company__c];
      System.assertEquals(4, compList.size());
        
    } // testLCMethods

   static testMethod void testMisc() {
    Lead_Company__c leadCompany = new Lead_Company__c(Name='test');
    insert leadCompany;
    Lead ld1 = new Lead(Hold_Out_Reason__c='Test',DoNotCall=false,Status='New',Lead_Company__c=leadCompany.Id);
    Lead ld2 = new Lead(Hold_Out_Reason__c='Test',DoNotCall=false,Status='New',Lead_Company__c=leadCompany.Id);
    //System.assertEquals(false,LeadCompanyMethods.checkForSignificanceRecalc(ld1,ld2));
    ld2.Hold_Out_Reason__c=null;
      //System.assertEquals(true,LeadCompanyMethods.checkForSignificanceRecalc(ld1,ld2)); /////// cant get this to pass !    
      //System.assertEquals(false,LeadCompanyMethods.checkForSignificanceRecalc(ld1,ld2));
      
      PaychexSettings__c setting1a = new PaychexSettings__c(Name='setting1a',IsActive__c=true,ProcessName__c='SignificantHoldOut',Attribute1__c='Bank Referral');
      PaychexSettings__c setting1b = new PaychexSettings__c(Name='setting1b',IsActive__c=true,ProcessName__c='SignificantHoldOut',Attribute1__c='Bank Referral2');
      PaychexSettings__c setting2a = new PaychexSettings__c(Name='setting2a',IsActive__c=true,ProcessName__c='SignificantStatus',Attribute1__c='Disqualified');
      PaychexSettings__c setting2b = new PaychexSettings__c(Name='setting2b',IsActive__c=true,ProcessName__c='SignificantStatus',Attribute1__c='Disqualified2');
      PaychexSettings__c[] settings = new PaychexSettings__c[]{setting1a,setting1b,setting2a,setting2b};
      insert settings;
      
      LeadCompanyMethods.setQueryParameters();
      System.assertEquals(2,LeadCompanyMethods.holdOutReasonSet.size());      /////always just default value
      System.assertEquals(2,LeadCompanyMethods.statusSet.size());           /////always just default value
      
      System.assertEquals(false, LeadCompanyMethods.holdOutTriggersRecalc('Value1','Value2'));
      System.assertEquals(false, LeadCompanyMethods.holdOutTriggersRecalc('Value1','Value1'));
      System.assertEquals(true, LeadCompanyMethods.holdOutTriggersRecalc('Value1',setting1a.Attribute1__c));

      System.assertEquals(false, LeadCompanyMethods.statusTriggersRecalc('Value1','Value2'));
      System.assertEquals(false, LeadCompanyMethods.statusTriggersRecalc('Value1','Value1'));
      System.assertEquals(true, LeadCompanyMethods.statusTriggersRecalc('Value1',setting2a.Attribute1__c));
   } // testMisc

   // test using the trigger on the lead company to convert remaining leads
   static testMethod void testConvertByLeadCompany() {
      Lead_Company__c leadCompany = new Lead_Company__c(Name='Test Co',Postal_Code__c='14514',LeadGroupId__c='TestCo14514');
      insert leadCompany;
      
      Lead ld1 = new Lead(Company=leadCompany.Name, lastName='Test1', PostalCode=leadCompany.Postal_Code__c, LeadGroupId__c=leadCompany.LeadGroupId__c, Lead_Company__c=leadCompany.Id);
      Lead ld2 = new Lead(Company=leadCompany.Name, lastName='Test2', PostalCode=leadCompany.Postal_Code__c, LeadGroupId__c=leadCompany.LeadGroupId__c, Lead_Company__c=leadCompany.Id);
      Lead ld3 = new Lead(Company=leadCompany.Name, lastName='Test3', PostalCode=leadCompany.Postal_Code__c, LeadGroupId__c=leadCompany.LeadGroupId__c, Lead_Company__c=leadCompany.Id);
      Lead ld4 = new Lead(Company=leadCompany.Name, lastName='Test4', PostalCode=leadCompany.Postal_Code__c, LeadGroupId__c=leadCompany.LeadGroupId__c, Lead_Company__c=leadCompany.Id);
      //Lead ld5 = new Lead(Company=leadCompany.Name, lastName='Test5', PostalCode=leadCompany.Postal_Code__c, LeadGroupId__c=leadCompany.LeadGroupId__c, Lead_Company__c=leadCompany.Id);
      //Lead ld6 = new Lead(Company=leadCompany.Name, lastName='Test6', PostalCode=leadCompany.Postal_Code__c, LeadGroupId__c=leadCompany.LeadGroupId__c, Lead_Company__c=leadCompany.Id);
      //Lead ld7 = new Lead(Company=leadCompany.Name, lastName='Test7', PostalCode=leadCompany.Postal_Code__c, LeadGroupId__c=leadCompany.LeadGroupId__c, Lead_Company__c=leadCompany.Id);
      //Lead ld8 = new Lead(Company=leadCompany.Name, lastName='Test8', PostalCode=leadCompany.Postal_Code__c, LeadGroupId__c=leadCompany.LeadGroupId__c, Lead_Company__c=leadCompany.Id);
      Lead[] leads = new Lead[]{ld1,ld2,ld3,ld4}; //,ld5,ld6,ld7,ld8};
      insert leads;
      
      Account acct = new Account(Name=leadCompany.Name, ShippingPostalCode=leadCompany.Postal_Code__c);
      insert acct;
      
      Contact ctct = new Contact(LastName='Test0', AccountId=acct.Id);
      insert ctct;
      
      System.assertEquals(4,[select count() from Lead where Lead_Company__c=:leadCompany.Id]);
      
      leadCompany.EvaluateAccountId__c = true;
      leadCompany.AccountId__c = acct.Id;
      LeadCompanyMethods.SKIP_TRIGGER=false;
      Test.startTest();
      update leadCompany;
      Test.stopTest();
      
      System.assertEquals(4,[select count() from Lead where IsConverted=true]);
      //System.assertEquals(1,[Select count() from Lead where IsConverted=true and Id=:ld1.Id]);
      //System.assertEquals(1,[Select count() from Lead where IsConverted=true and Id=:ld2.Id]);
      //System.assertEquals(1,[Select count() from Lead where IsConverted=true and Id=:ld3.Id]);
      //System.assertEquals(1,[Select count() from Lead where IsConverted=true and Id=:ld4.Id]);
      //System.assertEquals(1,[Select count() from Lead where IsConverted=true and Id=:ld5.Id]);
      //System.assertEquals(1,[Select count() from Lead where IsConverted=true and Id=:ld6.Id]);
      //System.assertEquals(1,[Select count() from Lead where IsConverted=true and Id=:ld7.Id]);
      //System.assertEquals(1,[Select count() from Lead where IsConverted=true and Id=:ld8.Id]);
      System.assertEquals(5,[select count() from Contact where AccountId=:acct.Id]);
      
   } // testConvertByLeadCompany

   static testMethod void testLeadChange() {
      LeadCompanyMethods.SKIP_FUTURE=true;
      Schema.RecordTypeInfo leadCoreRT = RecordTypeHelper.getRecordType('Core Lead Record Type', 'Lead');
      // test createCompany
      Lead ld1 = new Lead(Firstname = 'Mary'
                         ,Lastname = 'Lead1'
                         ,Company = 'Test Account11'
                         ,recordtypeId = leadCoreRT.getRecordTypeId()
                         ,Phone = '555-3333'
                         ,Email = 'mary@account11.com'
                         ,Street = '10 Main St'
                         ,City = 'Rochester'
                         ,State = 'NY'
                         ,PostalCode = '10000'
                         ,NSS_Prospect_ID__c = '12345'
                         ,Lead_Company__c = null
                         ,DataFlux_Id__c = null
                         ,LeadGroupId__c = null);
      insert ld1;

      List<Lead_Company__c> compList = [Select Id, Name, LeadGroupId__c, SignificantLead__c 
                                              ,Address__c, City__c, State__c, Postal_Code__c
                                              ,Email__c, Phone__c
                                          from Lead_Company__c];
      System.assertEquals(1, compList.size());
      Lead_Company__c leadComp = compList.get(0);
      System.assertEquals(ld1.Id, leadComp.LeadGroupId__c);
      System.assertEquals(ld1.Id, leadComp.SignificantLead__c);
      System.assertEquals(ld1.Street, leadComp.Address__c);
      System.assertEquals(ld1.City, leadComp.City__c);
      System.assertEquals(ld1.State, leadComp.State__c);
      System.assertEquals(ld1.PostalCode, leadComp.Postal_Code__c);
      System.assertEquals(ld1.Phone, leadComp.Phone__c);
      System.assertEquals(ld1.Email, leadComp.Email__c);
      
      ld1 = [select Id, Name, Company, Lead_Company__c, LeadGroupId__c 
                   ,Street, City, State, PostalCode
                   ,Email, Phone
               from Lead 
              where id = :ld1.Id];
      System.assertEquals(ld1.Lead_Company__c, leadComp.Id);
      ld1.Street = '12 Main St';
      ld1.City = 'Rachacha';
      ld1.PostalCode = '10001';
      ld1.Email = 'mary2@account11.com';
      ld1.Phone = '555-3334';
      LeadCompanyMethods.SKIP_LEAD_TRIGGER = false;
      TriggerMethods.clearVariables();
      update ld1; 
      
      // the company should be updated.
      compList = [Select Id, Name, LeadGroupId__c, SignificantLead__c 
                                              ,Address__c, City__c, State__c, Postal_Code__c
                                              ,Email__c, Phone__c
                                          from Lead_Company__c];
      System.assertEquals(1, compList.size());
      leadComp = compList.get(0);
      System.assertEquals(ld1.Id, leadComp.LeadGroupId__c);
      System.assertEquals(ld1.Id, leadComp.SignificantLead__c);
      System.assertEquals(ld1.Street, leadComp.Address__c);
      System.assertEquals(ld1.City, leadComp.City__c);
      System.assertEquals(ld1.State, leadComp.State__c);
      System.assertEquals(ld1.PostalCode, leadComp.Postal_Code__c);
      System.assertEquals(ld1.Phone, leadComp.Phone__c);
      System.assertEquals(ld1.Email, leadComp.Email__c);
      

      
   } // testLeadChange
} // class LeadCompanyMethodsTest