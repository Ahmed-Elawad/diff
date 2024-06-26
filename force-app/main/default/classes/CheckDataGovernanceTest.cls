/* 
   Test methods for the CheckDataGovernance class.
   
  History
  -------
  04/24/2014 Swarna Mohan       Created
  06/01/2014 Dan Carmen         Rewrite to be more flexible
  03/15/2015 Dan Carmen         Attach the contact to an account
  10/27/2017 Dan Carmen         Add additional testing.
  03/05/2018 Dan Carmen         Add additional debugging
  03/06/2018 Dan Carmen         Made the test class public so it can be called from outside
  10/15/2019 Dan Carmen         Update to use TriggerMethods.clearVariables
  10/12/2020 Dan Carmen         Add DGType__c field for ability to override the user settings
  12/14/2020 Dan Carmen       Fix for not handling ONLY_IF_NULL for accounts
  05/10/2024 Dan Carmen       Add check for not updating fields to null on the account
  05/31/2024 Dan Carmen       Add check for PEO Clients - set to only update if null
   
     
 */

@isTest(seeAllData=false)
public class CheckDataGovernanceTest {
	
	@testSetup
   public static void setupDataGovernance() {
      DataGovernanceJobs__c[] dgJobs = new DataGovernanceJobs__c[]{};
      dgJobs.add(new DataGovernanceJobs__c(Name=UserHelper.JOB_NSR, IsActive__c=true));
      insert dgJobs;
   	
      DataGovernance__c[] dgs = new DataGovernance__c[]{};
      dgs.add(new DataGovernance__c(Name='setting01',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='FirstName'));
      dgs.add(new DataGovernance__c(Name='setting02',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='LastName'));
      dgs.add(new DataGovernance__c(Name='setting03',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='Email'));
      dgs.add(new DataGovernance__c(Name='setting04',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='Phone'));
      dgs.add(new DataGovernance__c(Name='setting05',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='Street'));
      dgs.add(new DataGovernance__c(Name='setting06',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='City'));
      dgs.add(new DataGovernance__c(Name='setting07',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='State'));
      dgs.add(new DataGovernance__c(Name='setting08',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='PostalCode'));
      // bad field for testing purposes
      dgs.add(new DataGovernance__c(Name='setting08b',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='ThisIsABadField'));
      // nochange
      dgs.add(new DataGovernance__c(Name='setting08c',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_CHANGE,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='LeadSource'));
      dgs.add(new DataGovernance__c(Name='setting08d',IsActive__c=true,UserType__c=UserHelper.JOB_NSR,Type__c=CheckDataGovernance.NO_CHANGE,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='LeadSource'));
      dgs.add(new DataGovernance__c(Name='setting08e',IsActive__c=true,UserType__c=UserHelper.JOB_NSR,Type__c=CheckDataGovernance.NO_CHANGE,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='OwnerId'));
      dgs.add(new DataGovernance__c(Name='setting08f',IsActive__c=true,UserType__c=UserHelper.JOB_NSR,Type__c=CheckDataGovernance.NO_CHANGE,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='Status'));


      dgs.add(new DataGovernance__c(Name='setting09',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='FirstName'));
      dgs.add(new DataGovernance__c(Name='setting10',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='LastName'));
      dgs.add(new DataGovernance__c(Name='setting11',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='Email'));
      dgs.add(new DataGovernance__c(Name='setting12',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='Phone'));
      dgs.add(new DataGovernance__c(Name='setting13',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='MailingStreet'));
      dgs.add(new DataGovernance__c(Name='setting14',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='MailingCity'));
      dgs.add(new DataGovernance__c(Name='setting15',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='MailingState'));
      dgs.add(new DataGovernance__c(Name='setting16',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='MailingPostalCode'));
      // bad field for testing purposes
      dgs.add(new DataGovernance__c(Name='setting16b',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='ThisIsABadField'));
      dgs.add(new DataGovernance__c(Name='setting16c',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ONLY_IF_NULL,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='LeadSource'));
      dgs.add(new DataGovernance__c(Name='setting16d',IsActive__c=true,UserType__c=UserHelper.JOB_NSR,Type__c=CheckDataGovernance.NO_CHANGE,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='LeadSource'));
      dgs.add(new DataGovernance__c(Name='setting16e',IsActive__c=true,UserType__c=UserHelper.JOB_NSR,Type__c=CheckDataGovernance.NO_CHANGE,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='OwnerId'));
      dgs.add(new DataGovernance__c(Name='setting16f',IsActive__c=true,UserType__c=UserHelper.JOB_NSR,Type__c=CheckDataGovernance.NO_CHANGE,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='Status'));

      dgs.add(new DataGovernance__c(Name='setting17',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='BillingCity'));
      dgs.add(new DataGovernance__c(Name='setting18',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='BillingState'));
      dgs.add(new DataGovernance__c(Name='setting19',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='BillingPostalCode'));
      dgs.add(new DataGovernance__c(Name='setting20',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='ShippingCity'));
      dgs.add(new DataGovernance__c(Name='setting21',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='ShippingState'));
      dgs.add(new DataGovernance__c(Name='setting22',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='ShippingPostalCode'));
      dgs.add(new DataGovernance__c(Name='setting23',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='NumberOfEmployees'));
      dgs.add(new DataGovernance__c(Name='setting24',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='X401k_Assets__c'));
      dgs.add(new DataGovernance__c(Name='setting25',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Phone'));
      // bad field for testing purposes
      dgs.add(new DataGovernance__c(Name='setting25b',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='ThisIsABadField'));

      dgs.add(new DataGovernance__c(Name='setting26',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Federal_ID_Number__c'));
      dgs.add(new DataGovernance__c(Name='setting27',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_LOST_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Fed_Id_Name__c'));

      dgs.add(new DataGovernance__c(Name='setting28',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_CUR_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='BillingCity'));
      dgs.add(new DataGovernance__c(Name='setting29',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_CUR_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='BillingState'));
      dgs.add(new DataGovernance__c(Name='setting30',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_CUR_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='BillingPostalCode'));
      dgs.add(new DataGovernance__c(Name='setting31',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_CUR_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='ShippingCity'));
      dgs.add(new DataGovernance__c(Name='setting32',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_CUR_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='ShippingState'));
      dgs.add(new DataGovernance__c(Name='setting33',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_CUR_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='ShippingPostalCode'));
      dgs.add(new DataGovernance__c(Name='setting34',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_CUR_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='NumberOfEmployees'));
      dgs.add(new DataGovernance__c(Name='setting35',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_CUR_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='X401k_Assets__c'));
      dgs.add(new DataGovernance__c(Name='setting36',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_CUR_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Phone'));
      // bad field for testing purposes
      dgs.add(new DataGovernance__c(Name='setting37',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ACCT_CUR_NO_CHNG,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='ThisIsABadField'));

      dgs.add(new DataGovernance__c(Name='setting37c',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.NO_CHANGE,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Lead_Source__c'));
      dgs.add(new DataGovernance__c(Name='setting37d',IsActive__c=true,UserType__c=UserHelper.JOB_NSR,Type__c=CheckDataGovernance.NO_CHANGE,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Lead_Source__c'));
      dgs.add(new DataGovernance__c(Name='setting37e',IsActive__c=true,UserType__c=UserHelper.JOB_NSR,Type__c=CheckDataGovernance.NO_CHANGE,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='OwnerId'));
      dgs.add(new DataGovernance__c(Name='setting37f',IsActive__c=true,UserType__c=UserHelper.JOB_NSR,Type__c=CheckDataGovernance.NO_CHANGE,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Status'));

      dgs.add(new DataGovernance__c(Name='settingAppend1',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.FIELD_APPEND,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='Description'));
      dgs.add(new DataGovernance__c(Name='settingAppend2',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.FIELD_APPEND,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='Description'));
      dgs.add(new DataGovernance__c(Name='settingAppend3',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.FIELD_APPEND,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Description'));

      dgs.add(new DataGovernance__c(Name='settingOnlyNull1',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.ONLY_IF_NULL,ObjectName__c=ObjectHelper.OBJECT_LEAD,FieldName__c='PostalCode'));

      dgs.add(new DataGovernance__c(Name='profiledAcct1',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Name'));
      dgs.add(new DataGovernance__c(Name='profiledAcct2',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Phone'));
      dgs.add(new DataGovernance__c(Name='profiledAcct3',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='NumberOfEmployees'));
      dgs.add(new DataGovernance__c(Name='profiledAcct4',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Email__c'));

      dgs.add(new DataGovernance__c(Name='profiledCtct1',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='FirstName'));
      dgs.add(new DataGovernance__c(Name='profiledCtct2',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='LastName'));
      dgs.add(new DataGovernance__c(Name='profiledCtct3',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='Title'));
      dgs.add(new DataGovernance__c(Name='profiledCtct4',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='Phone'));
      dgs.add(new DataGovernance__c(Name='profiledCtct5',IsActive__c=true,UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='Email'));

      dgs.add(new DataGovernance__c(Name='settingAcct5a',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_ENT_CLT,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Name'));
      dgs.add(new DataGovernance__c(Name='settingAcct5b',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_ENT_CLT,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='LegalAddress__Street__s'));
      dgs.add(new DataGovernance__c(Name='settingAcct5c',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_ENT_CLT,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='LegalAddress__City__s'));
      dgs.add(new DataGovernance__c(Name='settingAcct5d',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_ENT_CLT,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='LegalAddress__StateCode__s'));
      dgs.add(new DataGovernance__c(Name='settingAcct5e',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.ACCT_ENT_CLT,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='LegalAddress__PostalCode__s'));
       
      dgs.add(new DataGovernance__c(Name='settingAcct6a',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.NO_NULL,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='Phone'));

      dgs.add(new DataGovernance__c(Name='settingAcctPeo1',IsActive__c=true,UserType__c=CheckDataGovernance.SFDC_DATA,Type__c=CheckDataGovernance.PEO_CLIENT,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,FieldName__c='First_Run_Date__c'));

   	insert dgs;
   } // setupDataGovernance
   
   public static void resetDataGovernance() {
      CheckDataGovernance.SKIP_DATA_GOVERNANCE = false;
      CheckDataGovernance.idsProcessed.clear();
      UserHelper.currentRunningUserId = null;
   } // resetDataGovernance
   
   public static Integer NBR_RECS=500;
   public static Integer NBR_ACCTS=25;
   public static Integer CTCTS_PER_ACCT=10;
   
   
   static testmethod void testlead() {
      CacheManager.SKIP_CACHE=true;
      
      // so the trigger fires.
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);

      Lead ld = new Lead(Company='Test Co', LeadSource='Original Lead Source', Description='desc1');
      insert ld;
      ld = [Select Id, LastName, Company, LeadSource, FirstName, Phone, Description, PostalCode from Lead where Id=:ld.Id];
      System.assertEquals(UserHelper.UNKNOWN,ld.LastName);
      System.assertEquals(null,ld.PostalCode);
      
      ld.FirstName='FirstName';
      ld.LeadSource = 'Lead Source';
      ld.Phone = '(555) 123-4567';
      ld.Description = 'desc2';
      ld.PostalCode='14624';
      
      System.debug('testlead update 1');
      resetDataGovernance();
      TriggerMethods.clearVariables();
      update ld;
      
      ld = [Select Id, LastName, Company, FirstName, LeadSource, Phone, Description, PostalCode from Lead where Id=:ld.Id];
      System.assertEquals('FirstName',ld.FirstName);
      System.assertEquals('Original Lead Source',ld.LeadSource);
      System.assertEquals('(555) 123-4567', ld.Phone);
      System.assertEquals('desc2\ndesc1', ld.Description);
      System.assertEquals('14624',ld.PostalCode);
      
      // update data
      ld.FirstName='FirstName2';
      ld.LeadSource='Lead Source2';
      ld.Phone = null;
      ld.Email = 'testlead@test.com';
      ld.PostalCode = '14514';
      // have to reset the flag
      resetDataGovernance();
      System.debug('testlead update 2');
      TriggerMethods.clearVariables();
      update ld;
      
      ld = [Select Id, LastName, Company, FirstName, LeadSource, Phone, Email, Description, PostalCode from Lead where Id=:ld.Id];
      System.assertEquals('FirstName2',ld.FirstName);
      System.assertEquals('Original Lead Source',ld.LeadSource);  // should not update
      System.assertEquals('(555) 123-4567', ld.Phone);   // should not update to null
      System.assertEquals('testlead@test.com', ld.Email);
      System.assertEquals('14624',ld.PostalCode);
      
      // so we can make sure it will not fire if it doesn't need to.
      delete pnm;
      // should let any update go through
      ld.FirstName='FirstName3';
      ld.LeadSource='Lead Source3';
      ld.Phone = null;
      ld.Email = 'testlead2@test.com';
      ld.PostalCode = '14626';
      
      // have to reset the flag
      resetDataGovernance();
      System.debug('testlead update 3');
      TriggerMethods.clearVariables();
      update ld;
      
      ld = [Select Id, LastName, Company, FirstName, LeadSource, Phone, Email, Description, PostalCode from Lead where Id=:ld.Id];
      System.assertEquals('FirstName3',ld.FirstName);
      System.assertEquals('Lead Source3',ld.LeadSource);  
      System.assertEquals(null, ld.Phone);   
      System.assertEquals('testlead2@test.com', ld.Email);
      System.assertEquals('14626',ld.PostalCode);

   } // testlead
   
   // test using the DGType__c field
   static testmethod void testlead2() {
      CacheManager.SKIP_CACHE=true;
      
      // so the trigger fires.
      //User runningUser = UserHelper.getRunningUser();
      //ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);

      Lead ld = new Lead(Company='Test Co', LastName=UserHelper.UNKNOWN, LeadSource='Original Lead Source', Description='desc1');
      insert ld;
      ld = [Select Id, LastName, Company, LeadSource, FirstName, Phone, Description, PostalCode from Lead where Id=:ld.Id];
      System.assertEquals(UserHelper.UNKNOWN,ld.LastName);
      System.assertEquals(null,ld.PostalCode);
      
      ld.FirstName='FirstName';
      ld.LeadSource = 'Lead Source';
      ld.Phone = '(555) 123-4567';
      ld.Description = 'desc2';
      ld.PostalCode='14624';
      ld.DGType__c = CheckDataGovernance.LEAD_LOADER;
      
      System.debug('testlead update 1');
      resetDataGovernance();
      TriggerMethods.clearVariables();
      update ld;
      
      ld = [Select Id, LastName, Company, FirstName, LeadSource, Phone, Description, PostalCode, DGType__c from Lead where Id=:ld.Id];
      System.assertEquals('FirstName',ld.FirstName);
      System.assertEquals('Original Lead Source',ld.LeadSource);
      System.assertEquals('(555) 123-4567', ld.Phone);
      System.assertEquals('desc2\ndesc1', ld.Description);
      System.assertEquals('14624',ld.PostalCode);
      System.assertEquals(null,ld.DGType__c);
      
      // update data
      ld.FirstName='FirstName2';
      ld.LeadSource='Lead Source2';
      ld.Phone = null;
      ld.Email = 'testlead@test.com';
      ld.PostalCode = '14514';
      ld.DGType__c = CheckDataGovernance.LEAD_LOADER;
      // have to reset the flag
      resetDataGovernance();
      System.debug('testlead update 2');
      TriggerMethods.clearVariables();
      update ld;
      
      ld = [Select Id, LastName, Company, FirstName, LeadSource, Phone, Email, Description, PostalCode, DGType__c from Lead where Id=:ld.Id];
      System.assertEquals('FirstName2',ld.FirstName);
      System.assertEquals('Original Lead Source',ld.LeadSource);  // should not update
      System.assertEquals('(555) 123-4567', ld.Phone);   // should not update to null
      System.assertEquals('testlead@test.com', ld.Email);
      System.assertEquals('14624',ld.PostalCode);
      System.assertEquals(null,ld.DGType__c);
      
      // so we can make sure it will not fire if it doesn't need to.
      //delete pnm;
      // should let any update go through
      ld.FirstName='FirstName3';
      ld.LeadSource='Lead Source3';
      ld.Phone = null;
      ld.Email = 'testlead2@test.com';
      ld.PostalCode = '14626';
      
      // have to reset the flag
      resetDataGovernance();
      System.debug('testlead update 3');
      TriggerMethods.clearVariables();
      update ld;
      
      ld = [Select Id, LastName, Company, FirstName, LeadSource, Phone, Email, Description, PostalCode from Lead where Id=:ld.Id];
      System.assertEquals('FirstName3',ld.FirstName);
      System.assertEquals('Lead Source3',ld.LeadSource);  
      System.assertEquals(null, ld.Phone);   
      System.assertEquals('testlead2@test.com', ld.Email);
      System.assertEquals('14626',ld.PostalCode);

   } // testlead2
   
   static testmethod void testContact() {
      
      // so the trigger fires.
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);

      Account acct = new Account(Name='Test Acct');
      insert acct;

      Contact ctct = new Contact(AccountId=acct.Id,FirstName='FirstName', LeadSource='Lead Source');
      insert ctct;
      ctct = [Select Id, FirstName, LastName from Contact where Id=:ctct.Id];
      System.assertEquals(UserHelper.UNKNOWN,ctct.LastName);

      ctct.FirstName='FirstName';
      ctct.LeadSource = 'Lead Source';
      ctct.Phone = '(555) 123-4567';
      resetDataGovernance();
      update ctct;
      
      ctct = [Select Id, LastName, FirstName, LeadSource, Phone from Contact where Id=:ctct.Id];
      System.assertEquals('FirstName',ctct.FirstName);
      System.assertEquals('Lead Source',ctct.LeadSource);
      System.assertEquals('(555) 123-4567', ctct.Phone);
      
      // update data
      ctct.FirstName='FirstName2';
      ctct.LeadSource='Lead Source2';
      ctct.Phone = null;
      ctct.Email = 'testlead@test.com';
      // have to reset the flag
      resetDataGovernance();
      update ctct;
      
      ctct = [Select Id, LastName, FirstName, LeadSource, Phone, Email from Contact where Id=:ctct.Id];
      System.assertEquals('FirstName2',ctct.FirstName);
      System.assertEquals('Lead Source',ctct.LeadSource);  // should not update
      System.assertEquals('(555) 123-4567', ctct.Phone);   // should not update to null
      System.assertEquals('testlead@test.com', ctct.Email);
      
      ctct.LeadSource = 'Lead Source 2a';
      // if we don't clear the idsProcessed array this shouldn't trigger the data governance rules
      update ctct;
      ctct = [Select Id, LastName, FirstName, LeadSource, Phone, Email from Contact where Id=:ctct.Id];
      System.assertEquals('Lead Source 2a',ctct.LeadSource);  // should update
      
      CheckDataGovernance.SKIP_DATA_GOVERNANCE = true;
      ctct.LeadSource = 'Lead Source 2b';
      // we should be skipping the data governance rules
      update ctct;
      ctct = [Select Id, LastName, FirstName, LeadSource, Phone, Email from Contact where Id=:ctct.Id];
      System.assertEquals('Lead Source 2b',ctct.LeadSource);  // should update

      // so we can make sure it will not fire if it doesn't need to.
      delete pnm;
      // should let any update go through
      ctct.FirstName='FirstName3';
      ctct.LeadSource='Lead Source3';
      ctct.Phone = null;
      ctct.Email = 'testlead2@test.com';
      // have to reset the flag
      resetDataGovernance();
      update ctct;
      
      ctct = [Select Id, LastName, FirstName, LeadSource, Phone, Email from Contact where Id=:ctct.Id];
      System.assertEquals('FirstName3',ctct.FirstName);
      System.assertEquals('Lead Source3',ctct.LeadSource);  
      System.assertEquals(null, ctct.Phone);   
      System.assertEquals('testlead2@test.com', ctct.Email);
      
   } // testContact

   static testMethod void testAccount() {
      
      // so the trigger fires.
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);

      // current client
      Account acct1 = new Account(Name='Test Account1', BIS_Id__c=1, Lost_Date__c=null, BillingCity='ThisCity',BillingState='ThisState',BillingPostalCode='Zip',Fed_Id_Name__c='Test Account1', Lead_Source__c='LeadSource1'
                                  ,Phone='(555) 123-4567');
      // lost client
      Account acct2 = new Account(Name='Test Account2', BIS_Id__c=2, Lost_Date__c=Date.today(), BillingCity='ThisCity',BillingState='ThisState',BillingPostalCode='Zip',Fed_Id_Name__c='Test Account2', Lead_Source__c='LeadSource1');
      // prospect
      Account acct3 = new Account(Name='Test Account3', BIS_Id__c=null, Lost_Date__c=null, BillingCity='ThisCity',BillingState='ThisState',BillingPostalCode='Zip',Fed_Id_Name__c='Test Account3', Lead_Source__c='LeadSource1'
                                 ,Phone='(555) 123-4567');
      Date firstRunDate = Date.today().addDays(-4);
      Account acct4 = new Account(Name='Test Account4', BIS_Id__c=4, Lost_Date__c=null, BillingCity='ThisCity',BillingState='ThisState',BillingPostalCode='Zip',Fed_Id_Name__c='Test Account3', Lead_Source__c='LeadSource1'
                                  ,Type='PEO Client', First_Run_Date__c=firstRunDate
                                 ,Phone='(555) 123-4567');
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      insert accts;
      
      acct1.BillingCity='ThisCity2';
      acct1.Fed_Id_Name__c='Test Account Number 1';
      acct1.Lead_Source__c='LeadSource2';
      acct2.BillingCity='ThisCity2';
      acct2.Fed_Id_Name__c='Test Account Number 2';
      acct2.Lead_Source__c='LeadSource2';
      acct3.BillingCity='ThisCity2';
      acct3.Fed_Id_Name__c='Test Account Number 3';
      acct3.Lead_Source__c='LeadSource2';
      Date newFirstRun = Date.today().addDays(-2);
      acct4.First_Run_Date__c = newFirstRun;
      System.debug('testAccount update 1');
      // have to reset the flag
      resetDataGovernance();
      update accts;
      
      
      Map<Id,Account> acctMap = getAcctMap();
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals('ThisCity',acct1.BillingCity);
      System.assertEquals('Test Account Number 1',acct1.Fed_Id_Name__c);
      System.assertEquals('LeadSource1',acct1.Lead_Source__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals('ThisCity2',acct2.BillingCity);
      System.assertEquals('Test Account2',acct2.Fed_Id_Name__c);
      System.assertEquals('LeadSource1',acct1.Lead_Source__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals('ThisCity2',acct3.BillingCity);
      System.assertEquals('Test Account Number 3',acct3.Fed_Id_Name__c);
      System.assertEquals('LeadSource1',acct1.Lead_Source__c);
      acct4 = acctMap.get(acct4.Id);
      Assert.areEqual(newFirstRun,acct4.First_Run_Date__c);
      
      // test as sfdc data
      delete pnm;
      pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_SFDC,runningUser.Name);
      
      acct2.BillingCity='ThisCity3';
      acct1.Lead_Source__c='LeadSource3';
      acct1.Phone = null;
      acct3.Phone = '(555) 234-5678';
      acct4.First_Run_Date__c = Date.today();
      
      // have to reset the flag
      resetDataGovernance();
      System.debug('testAccount update 2');
      update new Account[]{acct1,acct2,acct3,acct4};
      acctMap = getAcctMap();
      acct2 = acctMap.get(acct2.Id);
      Assert.areEqual('ThisCity2',acct2.BillingCity);
      acct1 = acctMap.get(acct1.Id);
      Assert.areEqual('LeadSource3',acct1.Lead_Source__c);
      // phone number should not have updated to null
      Assert.areEqual('(555) 123-4567', acct1.Phone);
      acct3 = acctMap.get(acct3.Id);
      // phone number should have updated
      Assert.areEqual('(555) 234-5678', acct3.Phone);
      acct4 = acctMap.get(acct4.Id);
      // should not have changed
      Assert.areEqual(newFirstRun, acct4.First_Run_Date__c);

      delete pnm;
      
      // make sure the update happens here
      acct2.BillingCity='ThisCity4';
      acct1.Lead_Source__c='LeadSource4';
      acct1.Phone = null;
      acct3.Phone = '(555) 345-6789';
      acct4.First_Run_Date__c = Date.today();

      // have to reset the flag
      resetDataGovernance();
      System.debug('testAccount update 3');
      update new Account[]{acct1,acct2,acct3,acct4};
      acctMap = getAcctMap();
      acct2 = acctMap.get(acct2.Id);
      Assert.areEqual('ThisCity4',acct2.BillingCity);
      acct1 = acctMap.get(acct1.Id);
      Assert.areEqual('LeadSource4',acct1.Lead_Source__c);
      Assert.isNull(acct1.Phone);
      acct3 = acctMap.get(acct3.Id);
      // phone number should have updated
      Assert.areEqual('(555) 345-6789', acct3.Phone);
      acct4 = acctMap.get(acct4.Id);
      // should have changed
      Assert.areEqual(Date.today(), acct4.First_Run_Date__c);

      
   } // testAccount
   
   public static Map<Id,Account> getAcctMap() {
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, BIS_Id__c, Lost_Date__c, BillingCity, BillingState
                                                           ,BillingPostalCode, Fed_Id_Name__c, Lead_Source__c
                                                           ,Phone, Type, First_Run_Date__c
                                                       from Account]);
      return acctMap;
   } // getAcctMap
   
   /*
   static testMethod void testBulkLeads() {
      setupDataGovernance();
      
      // so the trigger fires.
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);

      Lead[] leads = new Lead[]{};
      for (Integer cnt=0; cnt<NBR_RECS; cnt++) {
         leads.add(new Lead(LastName='Lead'+cnt, Company='Lead Company'+cnt, LeadSource='LeadSource1', PostalCode='14614'));
      }
      insert leads;
      
      for (Lead ld : leads) {
         ld.LeadSource = 'LeadSource2';
      }
      resetDataGovernance();
      update leads;
      
      // the lead source shouldn't have changed
      System.assertEquals(NBR_RECS,[select count() from Lead where LeadSource='LeadSource1']);
      System.assertEquals(0,[select count() from Lead where LeadSource='LeadSource2']);

   } // testBulkLeads
   */
   
   static testMethod void testTwoContacts() {
      
      // so the trigger fires.
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);
      
      Account acct = new Account(Name='Test Account');
      insert acct;
      
      Contact ctct1 = new Contact(AccountId=acct.Id,LastName='TestContact1', LeadSource='leadSource1');
      Contact ctct2 = new Contact(AccountId=acct.Id,LastName='TestContact2' );
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      insert ctcts;
      
      ctct1.LeadSource = 'LeadSource2';
      ctct2.LeadSource = 'LeadSource2';
      
      resetDataGovernance();
      System.debug('testTwoContacts contact update before');
      update ctcts;
      System.debug('testTwoContacts contact update after');

      System.assertEquals(1,[select count() from Contact where LeadSource='LeadSource2']);
   } // testTwoContacts
   
   /*
   static testMethod void testBulkContacts() {
      setupDataGovernance();
      
      // so the trigger fires.
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);
      
      Account[] accts = new Account[]{};
      for (Integer cnt=0; cnt<NBR_ACCTS; cnt++) {
         accts.add(new Account(Name='Test Account '+cnt));
      }
      insert accts;
      
      Contact[] ctcts = new Contact[]{};
      for (Account acct : accts) {
         for (Integer cnt=0; cnt<CTCTS_PER_ACCT; cnt++) {
            ctcts.add(new Contact(AccountId=acct.Id, FirstName=acct.Name, LastName='Contact'+cnt, LeadSource='LeadSource1'));
         } // for (Integer
         // create one contact without a lead source
         ctcts.add(new Contact(AccountId=acct.Id, FirstName=acct.Name, LastName='Contact'+CTCTS_PER_ACCT));
      } // for (Account acct
      
      insert ctcts;s
      
      for (Contact ctct : ctcts) {
         ctct.LeadSource = 'LeadSource2';
      }

      resetDataGovernance();
      update ctcts;
      
      // the contacts without a lead source should have allowed the lead source update - 1 contact per account
      System.assertEquals(NBR_ACCTS,[select count() from Contact where LeadSource='LeadSource2']);
      // the contacts with an existing lead source should not have allowed the change to occur
      System.assertEquals(NBR_ACCTS*CTCTS_PER_ACCT,[select count() from Contact where LeadSource='LeadSource1']);
   } // testBulkContacts
  */

   static testMethod void testProfiled() {
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);
      
      Account acct = new Account(Name='Test Account', Phone='(585) 555-1234', Email__c='testemail@test.com', Profiled__c=true);
      insert acct;
      
      Contact ctct = new Contact(AccountId=acct.Id, FirstName='TestFirst', LastName='TestLast', Title='Dog Walker', Email='contacttest@test.com', Phone='(585) 222-2345', Profiled__c=true);
      insert ctct;
      
      resetDataGovernance();      
      acct.Name='Wrong Name';
      acct.Phone='(111) 222-3333';
      acct.Email__c='differentemail@test.com';
      update acct;
      
      ctct.FirstName='WrongFirst';
      ctct.Title='POTUS';
      ctct.Email='wrongctctemail@test.com';
      ctct.Phone='(222) 222-2222';
      update ctct;
      
      acct = [Select Id, Name, Phone, Email__c, Profiled__c from Account where Id=:acct.Id];
      System.assertEquals(true, acct.Profiled__c);
      System.assertEquals('Test Account',acct.Name);
      System.assertEquals('(585) 555-1234',acct.Phone);
      System.assertEquals('testemail@test.com',acct.Email__c);
      
      ctct = [Select id, FirstName, LastName, Title, Email, Phone, Profiled__c from Contact where Id=:ctct.id];
      System.assertEquals(true, ctct.Profiled__c);
      System.assertEquals('TestLast', ctct.LastName);
      System.assertEquals('Dog Walker', ctct.Title);
      System.assertEquals('contacttest@test.com', ctct.Email);
      System.assertEquals('(585) 222-2345', ctct.Phone);
     
      delete pnm;
      resetDataGovernance();      
      ctct.LastName='DifferentLast';
      ctct.Title='DifferentTitle';
      update ctct;

      ctct = [Select id, FirstName, LastName, Title, Email, Phone, Profiled__c from Contact where Id=:ctct.id];
      System.assertEquals(true, ctct.Profiled__c);
      System.assertEquals('DifferentLast', ctct.LastName);
      System.assertEquals('DifferentTitle', ctct.Title);

   } // testProfiled
  
   static testMethod void testEnterpriseClient() {
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_SFDC,runningUser.Name);

      Account acct1 = new Account(Name='Test Account1', Phone='(585) 555-1234', Email__c='testemail@test.com', LegalAddress__Street__s='123 Main St', LegalAddress__City__s='Rochester'
                                   ,LegalAddress__StateCode__s='NY', LegalAddress__PostalCode__s='14624', LegalAddress__CountryCode__s='US'
                                   ,ClientRegistrationStatus__c = CsoMethods.TYPE_CLIENT);
      Account acct2 = new Account(Name='Test Account3', Phone='(585) 555-1234', Email__c='testemail@test.com', LegalAddress__Street__s='123 South Ave', LegalAddress__City__s='Rochester'
                                   ,LegalAddress__StateCode__s='NY', LegalAddress__PostalCode__s='14624', LegalAddress__CountryCode__s='US'
                                   ,ClientRegistrationStatus__c = null);
      insert new Account[]{acct1, acct2};

      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, Phone, Email__c, LegalAddress__Street__s, LegalAddress__City__s
                                                           ,LegalAddress__StateCode__s, LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
                                                       From Account]);
      Account checkAcct1 = acctMap.get(acct1.Id);
      Assert.areEqual(acct1.Name, checkAcct1.Name);
      Assert.areEqual(acct1.LegalAddress__Street__s, checkAcct1.LegalAddress__Street__s);
      Assert.areEqual(acct1.LegalAddress__City__s, checkAcct1.LegalAddress__City__s);
      Assert.areEqual(acct1.LegalAddress__StateCode__s, checkAcct1.LegalAddress__StateCode__s);
      Assert.areEqual(acct1.LegalAddress__PostalCode__s, checkAcct1.LegalAddress__PostalCode__s);
      Assert.areEqual(acct1.LegalAddress__CountryCode__s, checkAcct1.LegalAddress__CountryCode__s);
       
      Account checkAcct2 = acctMap.get(acct2.Id);
      Assert.areEqual(acct2.Name, checkAcct2.Name);
      Assert.areEqual(acct2.LegalAddress__Street__s, checkAcct2.LegalAddress__Street__s);
      Assert.areEqual(acct2.LegalAddress__City__s, checkAcct2.LegalAddress__City__s);
      Assert.areEqual(acct2.LegalAddress__StateCode__s, checkAcct2.LegalAddress__StateCode__s);
      Assert.areEqual(acct2.LegalAddress__PostalCode__s, checkAcct2.LegalAddress__PostalCode__s);
      Assert.areEqual(acct2.LegalAddress__CountryCode__s, checkAcct2.LegalAddress__CountryCode__s);
       

      checkAcct1.LegalAddress__Street__s = '234 Main St';
      checkAcct1.LegalAddress__City__s = 'Rachacha';
      checkAcct1.LegalAddress__PostalCode__s = '14625';

      checkAcct2.LegalAddress__Street__s = '234 South Ave';
      checkAcct2.LegalAddress__City__s = 'Rachacha';
      checkAcct2.LegalAddress__PostalCode__s = '14625';
       
      resetDataGovernance();      
      ZipCheckOwner.SKIP_TRIGGERS=false;
      update new Account[]{checkAcct1,checkAcct2};
      
      acctMap = new Map<Id,Account>([Select Id, Name, Phone, Email__c, LegalAddress__Street__s, LegalAddress__City__s
                                                           ,LegalAddress__StateCode__s, LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
                                                       From Account]);
      // this one shouldn't change
      checkAcct1 = acctMap.get(acct1.Id);
      Assert.areEqual(acct1.Name, checkAcct1.Name);
      Assert.areEqual(acct1.LegalAddress__Street__s, checkAcct1.LegalAddress__Street__s);
      Assert.areEqual(acct1.LegalAddress__City__s, checkAcct1.LegalAddress__City__s);
      Assert.areEqual(acct1.LegalAddress__StateCode__s, checkAcct1.LegalAddress__StateCode__s);
      Assert.areEqual(acct1.LegalAddress__PostalCode__s, checkAcct1.LegalAddress__PostalCode__s);
      Assert.areEqual(acct1.LegalAddress__CountryCode__s, checkAcct1.LegalAddress__CountryCode__s);
       
      // this one should update
      checkAcct2 = acctMap.get(acct2.Id);
      Assert.areEqual(acct2.Name, checkAcct2.Name);
      Assert.areEqual('234 South Ave', checkAcct2.LegalAddress__Street__s);
      Assert.areEqual('Rachacha', checkAcct2.LegalAddress__City__s);
      Assert.areEqual(acct2.LegalAddress__StateCode__s, checkAcct2.LegalAddress__StateCode__s);
      Assert.areEqual('14625', checkAcct2.LegalAddress__PostalCode__s);
      Assert.areEqual(acct2.LegalAddress__CountryCode__s, checkAcct2.LegalAddress__CountryCode__s);

   } // testEnterpriseClient
  
 } // class CheckDataGovernanceTest