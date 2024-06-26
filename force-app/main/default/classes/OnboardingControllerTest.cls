/* 
 * Test methods for OnboardingController.
 *
 * History
 * -------
 * 12/12/2016   Jermaine Stukes Created
 * 04/10/2017   Cindy Freeman   changed email of contact create so doesnt get caught by validation rule looking at paychex.com in email adddress 
 * 13/06/2017   Saketh          Updated to include Referral Contact wihle inserting Opportunities so that it passes the validation on Referral Contacts 
 * 11/01/2017   Jermaine Stukes Removed Clear Info Method
 * 01/28/2018   Cindy Freeman   added to deploy of controller
 * 08/20/2019   Jermaine Stukes Updated test methods for Doc Desk
 * 03/24/2020   Jake Hinds      Adding test for mms-aso pilot
 * 04/23/2020   Brandon Vidro   Added tests for Doc Desk - Pivot to SMB
 * 11/30/2020   Matt Fritschi   Added tests for Child NCP Form, NCO Form, and MPSC Forms
   05/19/2021   Dan Carmen      Updated to use Labels for opp stages 
   09/08/2022   Shilpa G		Added tests for Client Profile Updates
   11/14/2022   Eric Porter     Added tests for Client Profile Enhancement(testSaveChanges2 )
   05/22/2023   Dan Carmen      Updated Quote test to set the Data Set name based on the cafsl__Embedded_CPQ_Settings__c
   09/01/2023   Dan Carmen      More QTC fun
 * 2/20/2024    Priyanka 	    Multi id Submission , New Method cloneClientProfiletoChilds
 * 04/18/2024   Priyanka		APR0168490: Visier/HR Analytics HR Services Solution
 * 04/18/2024   Priyanka		APR0168880: Paychex Flex Enagage
 */
@isTest
public class OnboardingControllerTest {
 @testSetup
    Static void setupData() {
        Object_Relationships__c objr = new Object_Relationships__c(Primary_Object_API_name__c='Case',
                                     Primary_Object_Rcd_Type__c='Sales CTT',
                                     Related_Object_API_name__c='Reference_CTT__c',
                                     Related_Object_Rcd_Type__c='Master',
                                     IsActive__c=true);
      insert objr;
                                     
      Object_Relationships_Fields__c field1 = new Object_Relationships_Fields__c(Object_Relationships__c=objr.Id,
                                             Primary_Field_API_name__c='Id',
                                             Primary_Object_API_name__c='Case',
                                             Related_Field_API_name__c='Case__c',
                                             Related_Object_API_name__c='Reference_CTT__c');
        
        Object_Relationships_Fields__c field2 = new Object_Relationships_Fields__c(Object_Relationships__c=objr.Id,
                                                                                   Primary_Field_API_name__c='OwnerId',
                                                                                   Primary_Object_API_name__c='Case',
                                                                                   Related_Field_API_name__c='OwnerId',
                                                                                   Related_Object_API_name__c='Reference_CTT__c');
        
        Object_Relationships_Fields__c field3 = new Object_Relationships_Fields__c(Object_Relationships__c=objr.Id,
                                                                                   Primary_Field_API_name__c='Opportunity__c',
                                                                                   Primary_Object_API_name__c='Case',
                                                                                   Related_Field_API_name__c='Opportunity__c',
                                                                                   Related_Object_API_name__c='Reference_CTT__c');
        
        Object_Relationships_Fields__c field4 = new Object_Relationships_Fields__c(Object_Relationships__c=objr.Id,
                                                                                   Primary_Field_API_name__c='Sales_Rep__c',
                                                                                   Primary_Object_API_name__c='Case',
                                                                                   Related_Field_API_name__c='Sales_Rep__c',
                                                                                   Related_Object_API_name__c='Reference_CTT__c');
        
      Object_Relationships_Fields__c[] objFields = new Object_Relationships_Fields__c[]{field1,field2,field3,field4};
      insert objFields;      
        
        
        
        Account acctA = new Account(Name = 'testAccountA', AccountNumber = '8-00081234',NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST');
        insert acctA;
        User largeMarket = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        User smallMarket = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        AccountTeamMember LargeTM = new AccountTeamMember(TeamMemberRole = 'Large Market 401(k) Partner', AccountId = acctA.id, UserId = largeMarket.Id);
        AccountTeamMember SmallTM = new AccountTeamMember(TeamMemberRole = 'Small Market 401(k)/FSA Partner', AccountId = acctA.id, UserId = smallMarket.Id);
        insert LargeTM;
        insert SmallTM;
        Contact c1_a1 = new Contact(FirstName='Test Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@whoknows.com', HasOptedOutOfEmail=false);
        insert c1_a1;
        Referral_Account__c ra = new Referral_Account__c(name='Test Ref Acct', Street_Address_1__c='12 ABC Street', City__c='City', State_Province__c='NY', Zip_Postal_Code__c='14612', Referral_Source_Business_Type__c='Financial Services');
        insert ra;
        system.debug('**CLM BankLeadSalesRepChatterPostTest - insert RefAcct '+ ra.Id);
        Referral_Contact__c r1 = new Referral_Contact__c(name='Test1',Referral_Id__c='Dan1', Phone__c='7161234569',Referral_Account__c=ra.Id);
        insert r1;
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,StageName='Open'
                                             ,Referral_Contact__c=r1.id
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30)
                                             ,New_or_Existing_Business__c = 'New');
        insert opptyA;
        OracleQuoteTriggerPayxHelperTest.setupOracleSetting();
        Client_Profile_Clone__c customCloneProfile = new Client_Profile_Clone__c();
        customCloneProfile.Name='Test Profile';
        customCloneProfile.Sales_Division__c='ASO';
        customCloneProfile.Sales_Org__c='TAA';
        upsert customCloneProfile;
    } // setupData
    public static Opportunity getTestOppty(){
        Opportunity returnOpp = [Select name,AccountId, Employees_Paid_Per_Payroll__c, Account.Name, id,RecordTypeId from opportunity where name='testOpptyA' limit 1];
        return returnOpp;
    }
    public static Contact getTestContact(){
        Contact returnContact = [Select name, id, Email from Contact where FirstName='Test Contact' limit 1];
        return returnContact;
    }
    static testMethod void testPOP(){
        Opportunity opptyA = getTestOppty();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        test.startTest();
        OnboardingController newOnboarding = new OnboardingController();
        //Test HR Solutions-Flex
        newOnboarding.onboardingRecord.Product__c = 'HR Solutions-Flex';
        
        //Test POP
        newOnboarding.onboardingRecord.Pop__c = true;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.popValid());
        newOnboarding.onboardingRecord.Dental__c = true;
        newOnboarding.onboardingRecord.Group_Term_Life__c = true;
        newOnboarding.onboardingRecord.Short_Term_Disability__c = true;
        newOnboarding.onboardingRecord.Core_Medical__c = true;
        newOnboarding.onboardingRecord.Vision__c = true;
        newOnboarding.onboardingRecord.Accidental_Death__c = true;
        newOnboarding.onboardingRecord.Long_Term_Disability__c = true;
        System.assertEquals(true, newOnboarding.popValid());
        test.stopTest();   
    }
    static testMethod void testOnboarding(){
        Contact c1_a1 = getTestContact();
        Opportunity opptyA = getTestOppty();
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        OnboardingController newOnboarding = new OnboardingController();
        //Test HR Solutions-Flex
        newOnboarding.onboardingRecord.Product__c = 'HR Solutions-Flex';
        newOnboarding.onboardingRecord.Add_Onboarding__c = True;
        System.assertEquals(false, newOnboarding.onboardingValid());
        newOnboarding.onboardingRecord.Onboarding_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Accounts_Payable_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Anticipated_Start_Date__c = Date.today();
        System.assertEquals(true, newOnboarding.onboardingValid());
        test.stopTest();
    }
    static testMethod void testFlex(){
        User largeMarket = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        User smallMarket = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        Contact c1_a1 = getTestContact();
        Opportunity opptyA = getTestOppty();
        opptyA.Employees_Paid_Per_Payroll__c = 51;
        update opptyA;
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        OnboardingController newOnboarding = new OnboardingController();
        
        newOnboarding.onboardingType = 'HR Solutions';
        newOnboarding.onboardingRecord.Authorize_Officer__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Company_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Preferred_Contact_Method__c = 'Phone';
        newOnboarding.onboardingRecord.Best_Call_Time__c = '10pm';
        newOnboarding.onboardingRecord.Pop__c  = false;
        newOnboarding.onboardingRecord.Add_Onboarding__c = false;
        newOnboarding.onboardingRecord.HRE_Decision_Factors__c = 'Safety';
        newOnboarding.onboardingRecord.New_Existing__c = 'Existing Paychex Client';
        newOnboarding.onboardingRecord.Previous_Platform__c = 'Core';
        newOnboarding.onboardingRecord.Authorized_Officer_Title__c = 'Test';
        newOnboarding.onboardingRecord.Authorized_Officer_Phone__c = '1234567890';
        newOnboarding.onboardingRecord.Authorized_Officer_Email__c = 'c1a1@whoknows.com';
        newOnboarding.onboardingRecord.Authorized_Off_is_HR_Contact__c = 'Yes';
        newOnboarding.onboardingRecord.Contact_Notes__c = 'Notes';
        newOnboarding.onboardingRecord.Top_3_HR_Needs_Why__c = 'Needs';
        newOnboarding.onboardingRecord.Client_Company_IDs__c = 'ABC123';
        newOnboarding.onboardingRecord.Industry__c = 'Test';
        newOnboarding.onboardingRecord.How_long_a_client__c = '5';
        newOnboarding.onboardingRecord.Employee_Headcount_Status__c = 'Stable';
        newOnboarding.onboardingRecord.Other_Paychex_products_in_use__c = 'Prod1';
        newOnboarding.onboardingRecord.Client_Success_Meeting_Next_Step__c = 'Step1';
        newOnboarding.onboardingRecord.Client_Success_Meeting_Date_Time__c = Date.Today()+10;
        newOnboarding.onboardingRecord.Employee_Headcount_In_Other_States__c = '5698256';
        newOnboarding.onboardingRecord.Multi_Id_Submission__c='No';
        //Validation test
        newOnboarding.onboardingRecord.Product__c = 'HR Solutions-Flex';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.HR_Genralist__c  = largeMarket.id;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.HRS_Sales_Rep__c = largeMarket.id;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.MultiBillingOption__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Flex_Multi_Debit__c = 'Single Debit';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Run_Date__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.First_Check_Date__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.MultiProdServiceCenter__c = '940 Rochester';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord); 
        test.stopTest();
    }
    static testMethod void testNonPayroll(){
        test.startTest();
        User largeMarket = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        User smallMarket = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        Contact c1_a1 = getTestContact();
        Opportunity opptyA = getTestOppty();
        
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.onboardingType = 'HR Solutions';
        newOnboarding.onboardingRecord.Authorize_Officer__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Company_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Preferred_Contact_Method__c = 'Phone';
        newOnboarding.onboardingRecord.Best_Call_Time__c = '10pm';
        newOnboarding.onboardingRecord.Pop__c  = false;
        newOnboarding.onboardingRecord.Add_Onboarding__c = false;
        newOnboarding.onboardingRecord.New_Existing__c = 'New Client';
        newOnboarding.onboardingRecord.HRE_Decision_Factors__c = 'Safety';
        newOnboarding.onboardingRecord.Authorized_Officer_Title__c = 'Test';
        newOnboarding.onboardingRecord.Authorized_Officer_Phone__c = '1234567890';
        newOnboarding.onboardingRecord.Authorized_Officer_Email__c = 'c1a1@whoknows.com';
        newOnboarding.onboardingRecord.Authorized_Off_is_HR_Contact__c = 'Yes';
        newOnboarding.onboardingRecord.Contact_Notes__c = 'Notes';
        newOnboarding.onboardingRecord.Top_3_HR_Needs_Why__c = 'Needs';
        newOnboarding.onboardingRecord.Client_Company_IDs__c = 'ABC123';
        newOnboarding.onboardingRecord.Industry__c = 'Test';
        newOnboarding.onboardingRecord.How_long_a_client__c = '5';
        newOnboarding.onboardingRecord.Employee_Headcount_Status__c = 'Stable';
        newOnboarding.onboardingRecord.Other_Paychex_products_in_use__c = 'Prod1';
        newOnboarding.onboardingRecord.Client_Success_Meeting_Next_Step__c = 'Step1';
        newOnboarding.onboardingRecord.Client_Success_Meeting_Date_Time__c = Date.Today()+10;
        newOnboarding.onboardingRecord.Employee_Headcount_In_Other_States__c = '5698256';
        newOnboarding.onboardingRecord.Multi_Id_Submission__c='No';
        //Validation test
        newOnboarding.onboardingRecord.Product__c = 'HR Solutions for Non-Payroll';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.HR_Genralist__c  = largeMarket.id;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.HRS_Sales_Rep__c = largeMarket.id;
        newOnboarding.Validate();
        newOnboarding.onboardingRecord.Date_Business_Formed__c = Date.valueOf('2001-12-12');
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Run_Date__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);  
        test.stopTest();
    }
    static testMethod void testHandbooks(){
        User largeMarket = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        User smallMarket = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        Contact c1_a1 = getTestContact();
        Opportunity opptyA = getTestOppty();
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.onboardingType = 'HR Solutions';
        newOnboarding.onboardingRecord.Authorize_Officer__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Company_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Preferred_Contact_Method__c = 'Phone';
        newOnboarding.onboardingRecord.Best_Call_Time__c = '10pm';
        newOnboarding.onboardingRecord.Pop__c  = false;
        newOnboarding.onboardingRecord.Add_Onboarding__c = false;
        newOnboarding.onboardingRecord.New_Existing__c = 'New Client';
        newOnboarding.onboardingRecord.HRE_Decision_Factors__c = 'Safety';
        newOnboarding.onboardingRecord.Authorized_Officer_Title__c = 'Test';
        newOnboarding.onboardingRecord.Authorized_Officer_Phone__c = '1234567890';
        newOnboarding.onboardingRecord.Authorized_Officer_Email__c = 'c1a1@whoknows.com';
        newOnboarding.onboardingRecord.Authorized_Off_is_HR_Contact__c = 'Yes';
        newOnboarding.onboardingRecord.Contact_Notes__c = 'Notes';
        newOnboarding.onboardingRecord.Top_3_HR_Needs_Why__c = 'Needs';
        newOnboarding.onboardingRecord.Client_Company_IDs__c = 'ABC123';
        newOnboarding.onboardingRecord.Industry__c = 'Test';
        newOnboarding.onboardingRecord.How_long_a_client__c = '5';
        newOnboarding.onboardingRecord.Employee_Headcount_Status__c = 'Stable';
        newOnboarding.onboardingRecord.Other_Paychex_products_in_use__c = 'Prod1';
        newOnboarding.onboardingRecord.Client_Success_Meeting_Next_Step__c = 'Step1';
        newOnboarding.onboardingRecord.Client_Success_Meeting_Date_Time__c = Date.Today()+10;
        newOnboarding.onboardingRecord.Employee_Headcount_In_Other_States__c = '5698256';
        newOnboarding.onboardingRecord.Multi_Id_Submission__c='No';
        //Validation test
        newOnboarding.onboardingRecord.Product__c = 'Custom Employee Handbook';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.PayrollProcessed__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Date_Business_Formed__c = Date.valueOf('2001-12-12');
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Tax_Exempt__c = false;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord); 
        newOnboarding.onboardingRecord.Handbook_Format__c = 'Printed';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord); 
        newOnboarding.onboardingRecord.Tax_Exempt__c = true;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord); 
        newOnboarding.onboardingRecord.Tax_Exempt_Id__c = '111111';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord); 
        test.stopTest();
    }
    static testMethod void testHRE(){
        User largeMarket = [Select Id, Name,Email from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        User smallMarket = [Select Id, Name,Email from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        Contact c1_a1 = getTestContact();
        Opportunity opptyA = getTestOppty();
        test.startTest();
         //Priyanka Added for HR Analytics
        Pricebook2 standardPB = setupPricebookAndMap(false);
        opptyA.Pricebook2Id = standardPB.Id;
        update opptyA;
        PriceBookEntry pbe = [Select Id, PriceBook2Id from PriceBookEntry where PriceBook2Id =:standardPB.Id limit 1];
        Product2 oppProductE = New Product2(Name = 'HR Analytics Test',
                                            PayrollFrequency__c = 'Weekly',
                                            ProductCode = 'ASO', 
                                            IsActive = true); 
        Product2 oppProductF = New Product2(Name = 'Paychex Flex PEO',
                                            PayrollFrequency__c = 'Weekly',
                                            ProductCode = 'ASO', 
                                            IsActive = true);
        insert new List<Product2>{oppProductF, oppProductE};
            
        OpportunityLineItem Oli5 = new OpportunityLineItem(Product2Id = oppProductE.Id, 
                                                           OpportunityId = opptyA.Id, Quantity = 1,
                                                           TotalPrice = 100, PricebookEntryId = pbe.Id);
           OpportunityLineItem Oli6 = new OpportunityLineItem(	Product2Id = oppProductE.Id, 
                                                           OpportunityId = opptyA.Id, Quantity = 1,
                                                           TotalPrice = 100, PricebookEntryId = pbe.Id);
        insert new List<OpportunityLineItem>{Oli5, Oli6};
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.onboardingType = 'HR Solutions';
        newOnboarding.onboardingRecord.Authorize_Officer__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Company_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Preferred_Contact_Method__c = 'Email';
        newOnboarding.onboardingRecord.Best_Call_Time__c = '10pm';
        newOnboarding.onboardingRecord.Pop__c  = false;
        newOnboarding.onboardingRecord.Add_Onboarding__c = false;
        newOnboarding.onboardingRecord.New_Existing__c = 'New Client';
        newOnboarding.onboardingRecord.HRE_Decision_Factors__c = 'Safety';
        newOnboarding.onboardingRecord.Authorized_Officer_Title__c = 'Test';
        newOnboarding.onboardingRecord.Authorized_Officer_Phone__c = '1234567890';
        newOnboarding.onboardingRecord.Authorized_Officer_Email__c = 'c1a1@whoknows.com';
        newOnboarding.onboardingRecord.Authorized_Off_is_HR_Contact__c = 'Yes';
        newOnboarding.onboardingRecord.Contact_Notes__c = 'Notes';
        newOnboarding.onboardingRecord.Top_3_HR_Needs_Why__c = 'Needs';
        newOnboarding.onboardingRecord.Client_Company_IDs__c = 'ABC123';
        newOnboarding.onboardingRecord.Industry__c = 'Test';
        newOnboarding.onboardingRecord.How_long_a_client__c = '5';
        newOnboarding.onboardingRecord.Employee_Headcount_Status__c = 'Stable';
        newOnboarding.onboardingRecord.Other_Paychex_products_in_use__c = 'Prod1';
        newOnboarding.onboardingRecord.Client_Success_Meeting_Next_Step__c = 'Step1';
        newOnboarding.onboardingRecord.Client_Success_Meeting_Date_Time__c = Date.Today()+10;
        newOnboarding.onboardingRecord.Employee_Headcount_In_Other_States__c = '5698256';
        newOnboarding.onboardingRecord.Multi_Id_Submission__c='No';
        newOnboarding.onboardingRecord.Alternative_Email__c = largeMarket.Email;
        //Validation test
        newOnboarding.onboardingRecord.Product__c = 'Paychex HR Essentials';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.HR_Admin__c = c1_a1.id;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.HRE_Reason_Selected__c = 'Test Reasons';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord); 
        newOnboarding.onboardingRecord.PayrollProcessed__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Date_Business_Formed__c = Date.valueOf('2001-12-12');
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord); 
        newOnboarding.onboardingRecord.HRE_Existing__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord); 
        newOnboarding.onboardingRecord.HRE_Existing_Safety_Manual__c = 'True';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord); 
        newOnboarding.onboardingRecord.HRE_Paychex_created_existing_safety__c = 'True';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord); 
        
         newOnboarding.onboardingRecord.Multi_State__c = 'Yes';
        newOnboarding.onboardingRecord.Sales_Parent__c= opptyA.AccountId;
         newOnboarding.onboardingRecord.MultiBillingOption__c='true';
        newOnboarding.onboardingRecord.HR_Sites__c='FL';
        newOnboarding.onboardingRecord.Employee_Headcount_In_Other_States__c='test';
        newOnboarding.onboardingRecord.Authorized_Off_is_HR_Contact__c = 'No';
        newOnboarding.onboardingRecord.HR_Contact_Name__c = 'Test' ;   
        newOnboarding.onboardingRecord.HR_Contact_Title__c = 'Testse' ;   
        newOnboarding.onboardingRecord.HR_Contact_Phone__c = '1234567890' ;           
        newOnboarding.onboardingRecord.Handbook_Format__c = 'Printed';
        newOnboarding.onboardingRecord.Tax_Exempt__c = false;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord); 
        
         newOnboarding.onboardingRecord.Tax_Exempt__c = true;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord); 
        
       // newOnboarding.onboardingRecord.HR_Contact_Name__c = 'Test' ;        
        newOnboarding.hasHRAnalytics=true;
        newOnboarding.onboardingRecord.Invoice_Email_Address__c = 'Test' ;
        newOnboarding.onboardingRecord.HR_Analytics_Contact__c = 'Test' ;
        newOnboarding.onboardingRecord.HR_Analytics_Contact_Email__c='test@gmail.com';
        newOnboarding.onboardingRecord.HR_Analytics_billing__c = 'False' ;
        newOnboarding.onboardingRecord.Bank_Account_Form__C = '00161121' ;
        newOnboarding.hasFlexEnagage=true;
        newOnboarding.onboardingRecord.Flex_Engage_Invoice_Email__c='test@test.com';
        newOnboarding.onboardingRecord.Flex_Engage_Contact__c='test';
        newOnboarding.onboardingRecord.Flex_Engage_Contact_Email__c='test@test.com';
        newOnboarding.onboardingRecord.Flex_Engage_Service_Start_Date__c=System.today();               
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord); 
        newOnboarding.onboardingRecord.Tax_Exempt__c = true;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord); 
        newOnboarding.onboardingRecord.Tax_Exempt_Id__c = '111111';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord); 
        newOnboarding.EmailValidation();
        newOnboarding.emailFSS();  
        test.stopTest();
    }
    static testMethod void testEmailFSS(){
        User largeMarket = [Select Id, Name, Email from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        Contact c1_a1 = getTestContact();
        Opportunity opptyA = getTestOppty();
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        //User testUser = [Select Id, email from User where IsActive=true and email != null limit 1];
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.onboardingType = 'HR Solutions';
        newOnboarding.onboardingRecord.Product__c = 'HR Solutions-Flex';
        newOnboarding.onboardingRecord.Alternative_Email__c = Label.ASO_SP_Email;
        newOnboarding.onboardingRecord.Add_Onboarding__c = True;
        newOnboarding.onboardingRecord.Onboarding_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Accounts_Payable_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Anticipated_Start_Date__c = Date.today();
        newOnboarding.onboardingRecord.Alternative_Email__c = largeMarket.Email;
        //Check Email
        newOnboarding.EmailValidation();
        System.assertEquals(false, newOnboarding.InvalidEmail);
        newOnboarding.emailFSS();
        System.assertEquals(true, newOnboarding.onboardingRecord.FSS_Email_Sent__c);
        test.stopTest();
    }
    static testMethod void testSharepointUpload(){
        User largeMarket = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        Contact c1_a1 = getTestContact();
        //Contact c2_a1 = new Contact(FirstName='Client',LastName='Transition', Email=Label.Onboarding_SMB_CTT_Email);
        //insert c2_a1;
        Opportunity opptyA = getTestOppty();
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.onboardingRecord.Product__c = 'HR Solutions-Flex';
        newOnboarding.onboardingRecord.Add_Onboarding__c = True;
        newOnboarding.onboardingRecord.Onboarding_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.HR_Genralist__c = largeMarket.Id;
        newOnboarding.onboardingRecord.New_Branch__c = '8';
        newOnboarding.onboardingRecord.Accounts_Payable_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Anticipated_Start_Date__c = Date.today();
        newOnboarding.onboardingRecord.Run_Date__c = Date.Today()+30;
        
        //Test FSSChange Method
        newOnboarding.FSSChanges();
        System.assertEquals(true, newOnboarding.fssValid);
        
        Attachment attach=new Attachment();     
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=opptyA.id;
        insert attach;
        newOnboarding.SharePointUpload();
        System.assertEquals(date.today(), newOnboarding.onboardingRecord.SubmissionDate__c);
        newOnboarding.UpdateInformationFSS();
        System.assertEquals(true, newOnboarding.fssUpdate);
        test.stopTest();
    }
    static testMethod void testgetContact(){
        Contact c1_a1 = getTestContact();
        Opportunity opptyA = getTestOppty();
        OpportunityContactRole newOCR = new OpportunityContactRole(isPrimary = true, opportunityId = opptyA.Id, contactId = c1_a1.Id);
        insert newOCR;
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.getContacts();
        newOnboarding.updateContacts();
        System.assertEquals(newOnboarding.onboardingRecord.Company_Contact__c, c1_a1.Id);
        test.stopTest();
    }
    
    static testMethod void testgetOptInOptOut(){
        Opportunity opptyA = getTestOppty();
        Reference_Opportunity_Product__c refOppProduct = new Reference_Opportunity_Product__c(Opportunity__c=opptyA.Id, Flex_Enterprise__c = True, Express_Payroll__c = True, Paychex_Flex_Pro__c = True, Flex_Select__c = true, ASO__c = true);
        insert refOppProduct;
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        test.startTest();
        OnboardingController newOnboarding = new OnboardingController();        
        newOnboarding.getOptInOptOut();
        newOnboarding.getGlOptions();
        system.assertEquals(true, newOnboarding.hasEnterprise);
        system.assertEquals(true, newOnboarding.hasSelect);
        system.assertEquals(true, newOnboarding.hasPro);
        system.assertEquals(true, newOnboarding.hasExpressPayroll);
        system.assertEquals(true, newOnboarding.hasAso);
        test.stopTest();
    }

    static testMethod void testGetDocDeskContacts(){
        Contact c1_a1 = getTestContact();
        Account acctA = new Account(Name = 'testAccountA', AccountNumber = '8-00081234',NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address');
        insert acctA;
        c1_a1.AccountId = acctA.Id;
        update c1_a1;
        Opportunity opptyA = getTestOppty();
        opptyA.AccountId = acctA.Id;
        update opptyA;
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.selectedAuthorizedContact = c1_a1.Id;
        newOnboarding.selectedPayrollContact = c1_a1.Id;
        newOnboarding.getDocDeskContacts();
        newOnboarding.getSelectedAuthorizedDocDeskContact();
        newOnboarding.getSelectedPayrollDocDeskContact();
		system.assertEquals(newOnboarding.onboardingRecord.Authorized_Officer_Email__c, c1_a1.Email);
        test.stopTest();
    }
    
   /*
    static testMethod void testValidateDocDesk(){
        Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,'Opportunity');
        Contact c1_a1 = getTestContact();
        Opportunity opptyA = getTestOppty();
        opptyA.RecordTypeId = mmsOpptyRt.getRecordTypeId();
        opptyA.Payroll_Platform__c = 'MMS';
        opptyA.LeadSource = 'Cold Call';
        opptyA.Payroll_Current_Prior_Method__c = 'ADP';
        opptyA.Service_Location__c = 'Akron Branch 0049';
        
        update opptyA;
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.onboardingRecord.IrsIsDelivery__c = 'No';
        newOnboarding.onboardingRecord.Irs_Address__c = 'Test Address';
        newOnboarding.onboardingRecord.PreAssignedClientNum__c = 'Yes';
        newOnboarding.onboardingRecord.PreAssignedId__c = '11111';
        newOnboarding.onboardingRecord.Combo__c = 'Yes';
        newOnboarding.onboardingRecord.NumComboIds__c = 5;
        newOnboarding.onboardingRecord.RelationWithAddAccount__c = 'Yes';
        newOnboarding.onboardingRecord.RelatedAccountId__c = opptyA.AccountId;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.ReadyChex__c = 'ReadyChex';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.GL__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Workers_Compensation__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Skylight__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.First_Check_Date__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.ChangeOfEntity__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.PriorWagesLoaded__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Promotions__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Business_Structure__c = 'LLC';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.BankDocumentation__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.PeriodEndDate__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Anticipated_Start_Date__c = Date.Today();
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Authorize_Officer__c = c1_a1.Id;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.StateProcessedIn__c = 'New York - NY';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.PriceLock3Year__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        //newOnboarding.onboardingRecord.DiscountOffered__c = 'Yes'; 
        //newOnboarding.Validate();
        //System.assertEquals(true, newOnboarding.validRecord);
        newOnboarding.hasFlextime = true; 
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Multi_Id_Submission__c = 'Yes';
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Taxed_as_S_Corp__c = true;
        newOnboarding.onboardingRecord.Business_Structure__c = 'LLP';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        System.assertEquals(false, newOnboarding.onboardingRecord.Taxed_as_S_Corp__c);
        newOnboarding.onboardingRecord.PreAssignedClientNum__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        System.assertEquals('', newOnboarding.onboardingRecord.PreAssignedId__c);*/
        /*newOnboarding.onboardingRecord.Flextime_Timeclock__c = 'Yes';
        newOnboarding.onboardingRecord.Flextime_TAA__c = 'No';
        newOnboarding.onboardingRecord.NumFlexId__c = 2;
        newOnboarding.onboardingRecord.Flextime_Date__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        newOnboarding.hasEsr = true; 
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.ESR_educationInstitution__c = 'Yes';
        newOnboarding.onboardingRecord.ESR_selfInsuredPlan__c = 'No';
        newOnboarding.onboardingRecord.ESR_UnionEmps__c = 'No';
        newOnboarding.onboardingRecord.ESR_PriorMedRenewalDate__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);*/
    //}
    
    /*static testMethod void testFSSEmailDD(){
        Opportunity opptyA = getTestOppty();
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        OnboardingController newOnboarding = new OnboardingController();
        User testUser = [Select Id, email from User where IsActive=true limit 1];
        newOnboarding.onboardingRecord.Alternative_Email__c = testUser.Email;
        newOnboarding.onboardingRecord.PreAssignedClientNum__c = 'Yes';
        newOnboarding.onboardingRecord.PreAssignedId__c = '11111';
        newOnboarding.onboardingRecord.Combo__c = 'Yes';
        newOnboarding.onboardingRecord.NumComboIds__c = 5;
        newOnboarding.onboardingRecord.RelationWithAddAccount__c = 'Yes';
        newOnboarding.onboardingRecord.RelatedAccountId__c = opptyA.AccountId;
        newOnboarding.emailFSSDD();
        System.assertEquals(true, newOnboarding.onboardingRecord.FSS_Email_Sent__c);
    }*/
    
    /*static testMethod void testDocDeskProductsQuote(){
        Pricebook2 standardPB = setupPricebookAndMap(false);
        List<Product2> productList = new List<Product2>();
        List<Account> acctList = new List<Account>();
        List<SBQQ__QuoteLineGroup__c> quoteLineGroupList = new List<SBQQ__QuoteLineGroup__c>();
        List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        
        Product2 quoteProductA = New Product2(Name = 'HR Solutions', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductA);
        Product2 quoteProductB = New Product2(Name = 'HR Solutions - ASO', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductB);
        Product2 quoteProductC = New Product2(Name = 'Paychex Flex Enterprise', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductC);
        Product2 quoteProductD = New Product2(Name = 'ESR', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductD);
        Product2 quoteProductE = New Product2(Name = 'Flex Time', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductE);
        insert productList;
        
        PriceBookEntry pbe = [Select Id, PriceBook2Id from PriceBookEntry where PriceBook2Id =:standardPB.Id limit 1];
        Opportunity opptyA = getTestOppty();
        opptyA.Pricebook2Id = standardPB.Id;
        opptyA.Payroll_Platform__c = 'PAY';
        opptyA.Payroll_Unit__c = true;
        opptyA.Payroll_Units__c = 5;
        update opptyA;
        
        
        //New Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = opptyA.AccountId;
        quote.SBQQ__Opportunity2__c = opptyA.Id;
        quote.SBQQ__Primary__c = true;
        quote.Quote_Name__c = 'TestQuote';
        quote.Multi_ID__c = true;
        quote.SBQQ__LineItemsGrouped__c = true;
        quote.SBQQ__PricebookId__c = standardPB.Id;
        quote.SBQQ__PriceBook__c = standardPB.Id;
        quote.Used_Steelbrick__c = 'Oracle Error';
        quote.Used_Steelbrick_Because__c = 'TEST';
        insert quote;

        //New Quote Line Items
        
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(SBQQ__Product__c = quoteProductA.Id, PayrollFrequency__c = 'Weekly', SBQQ__Quote__c = quote.Id);
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Product__c = quoteProductB.Id, PayrollFrequency__c = 'Weekly', SBQQ__Quote__c = quote.Id);
        SBQQ__QuoteLine__c quoteLine3 = new SBQQ__QuoteLine__c(SBQQ__Product__c = quoteProductC.Id, PayrollFrequency__c = 'Weekly', SBQQ__Quote__c = quote.Id);
        SBQQ__QuoteLine__c quoteLine4 = new SBQQ__QuoteLine__c(SBQQ__Product__c = quoteProductD.Id, PayrollFrequency__c = 'Weekly', SBQQ__Quote__c = quote.Id);
        SBQQ__QuoteLine__c quoteLine5 = new SBQQ__QuoteLine__c(SBQQ__Product__c = quoteProductE.Id, PayrollFrequency__c = 'Weekly', SBQQ__Quote__c = quote.Id);
        quoteLineList.add(quoteLine1);
        quoteLineList.add(quoteLine2);
        quoteLineList.add(quoteLine3);
        quoteLineList.add(quoteLine4);
        quoteLineList.add(quoteLine5);
        insert quoteLineList;
        
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        OnboardingController newOnboarding = new OnboardingController();
        System.assert(newOnboarding.hasEsr);
        
    }*/
    static testMethod void testDocDeskProductsNoQuote(){
        Pricebook2 standardPB = setupPricebookAndMap(false);
        List<Product2> productList = new List<Product2>();
        List<Account> acctList = new List<Account>();
        //List<SBQQ__QuoteLineGroup__c> quoteLineGroupList = new List<SBQQ__QuoteLineGroup__c>();
        //List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        
        Product2 oppProductA = New Product2(Name = 'HR Solutions', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(oppProductA);
        Product2 oppProductB = New Product2(Name = 'HR Solutions - ASO', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(oppProductB);
        Product2 oppProductC = New Product2(Name = 'Paychex Flex Enterprise', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(oppProductC);
        Product2 oppProductD = New Product2(Name = 'ESR', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(oppProductD);
        Product2 oppProductE = New Product2(Name = 'Flex Time', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(oppProductE);
        insert productList;
        
        PriceBookEntry pbe = [Select Id, PriceBook2Id from PriceBookEntry where PriceBook2Id =:standardPB.Id limit 1];
        Opportunity opptyA = getTestOppty();
        opptyA.Pricebook2Id = standardPB.Id;
        opptyA.Payroll_Platform__c = 'PAY';
        opptyA.Payroll_Unit__c = true;
        opptyA.Payroll_Units__c = 5;
        update opptyA;

        OpportunityLineItem Oli1 = new OpportunityLineItem(Product2Id = oppProductA.Id, OpportunityId = opptyA.Id, Quantity = 1, TotalPrice = 100, PricebookEntryId = pbe.Id);
        OpportunityLineItem Oli2 = new OpportunityLineItem(Product2Id = oppProductB.Id, OpportunityId = opptyA.Id, Quantity = 1, TotalPrice = 100, PricebookEntryId = pbe.Id);
        OpportunityLineItem Oli3 = new OpportunityLineItem(Product2Id = oppProductC.Id, OpportunityId = opptyA.Id, Quantity = 1, TotalPrice = 100, PricebookEntryId = pbe.Id);
        OpportunityLineItem Oli4 = new OpportunityLineItem(Product2Id = oppProductD.Id, OpportunityId = opptyA.Id, Quantity = 1, TotalPrice = 100, PricebookEntryId = pbe.Id);
        OpportunityLineItem Oli5 = new OpportunityLineItem(Product2Id = oppProductE.Id, OpportunityId = opptyA.Id, Quantity = 1, TotalPrice = 100, PricebookEntryId = pbe.Id);
        oliList.add(Oli1);
        oliList.add(Oli2);
        oliList.add(Oli3);
        oliList.add(Oli4);
        oliList.add(Oli5);
        insert oliList;
        
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        OnboardingController newOnboarding = new OnboardingController();
            
            
    }
    static testMethod void testOnboardingMisc(){
        Contact c1_a1 = getTestContact();
        Opportunity opptyA = getTestOppty();
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        OnboardingController newOnboarding = new OnboardingController();
        List<SelectOption> optionList = new List<SelectOption>();
        //Test getBoolOption()
        optionList.addAll(newOnboarding.getBoolOption());
        System.assert(optionList.size() > 0);
        //Test saveSummary()
        newOnboarding.saveSummary();
        List<Attachment> attachList = [Select Id from Attachment where ParentId =:opptyA.Id];
        System.assert(attachList.size() > 0);
        test.stopTest();

    }
    public static Pricebook2 setupPricebookAndMap(Boolean createPkg) {
    // create the products
      String[] prodNames = new String[]{'ProductHelperTest1','ProductHelperTest2','ProductHelperTest3'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'TestSalesOrg', null);
      PricebookEntry entry = entries.get(0);
      Pricebook2 pb = entry.Pricebook2;
      pb.Sales_Org__c='TestSalesOrg';
      
    
      System.debug('setupPricebookAndMap pricebook id='+pb.Id);
      
      Integer nbr = [Select count() from Product_Pricebook_Map__c
                               where Sales_Org__c in ('TestSalesOrg')
                                 and Pricebook_Id__c != null
                               ];
      System.assertEquals(1,nbr);
      //Product2 p1 = new Product2(Name='ProductHelperTest1',ProductCode='ProductHelperTest1',Unit_Type__c='Widget',Sales_Org__c=ppm1.Sales_Org__c, Default_Units_to_Employees__c=true, IsActive=true,Is_Payroll_Unit__c=false,Is_Non_Payroll_Unit__c=false);
      //Product2 p2 = new Product2(Name='ProductHelperTest2',ProductCode='ProductHelperTest2',Unit_Type__c='Widget',Sales_Org__c=ppm1.Sales_Org__c, Default_Units_to_Employees__c=false,IsActive=true,Is_Payroll_Unit__c=false,Is_Non_Payroll_Unit__c=false);
      //Product2[] prods = new Product2[]{p1,p2};
      //if (createPkg) {
      //   Product2 p3 = new Product2(Name='ProductHelperTest3',ProductCode='ProductHelperTest3',Unit_Type__c='Widget',Sales_Org__c=ppm1.Sales_Org__c, Is_Package__c=true, Default_Units_to_Employees__c=true, IsActive=true,Is_Payroll_Unit__c=false,Is_Non_Payroll_Unit__c=false);
      //     prods.add(p3);
      //}
      //insert prods;
      if (createPkg) {
         Product2 p1 = entries.get(0).Product2;
         Product2 p2 = entries.get(1).Product2;
         Product2 p3 = entries.get(2).Product2;
         p3.Is_Package__c = true;
         p3.Default_Units_to_Employees__c = true;
         p1.Default_Units_to_Employees__c = true;
         update p1;
         update p3;
         
         Product_Parent_Child_Link__c prodLink1 = new Product_Parent_Child_Link__c(Parent_Product_Code__c=p3.ProductCode
                                                                                  ,Child_Product_Code__c=p1.ProductCode
                                                                                  ,Included_in_Parent_Price__c=true);
         Product_Parent_Child_Link__c prodLink2 = new Product_Parent_Child_Link__c(Parent_Product_Code__c=p3.ProductCode
                                                                                  ,Child_Product_Code__c=p2.ProductCode);
         Product_Parent_Child_Link__c[] links = new Product_Parent_Child_Link__c[]{prodLink1,prodLink2};
         insert links;
         
         // add pricing
         Product_Pricing__c pp1 = new Product_Pricing__c(Name=p1.ProductCode,Low_Value__c=1, High_Value__c=5, Amount__c=5, Pricing_Type__c='Cumulative Rate Per Unit', Sales_Org__c='TestSalesOrg', Setup_Fee__c=100, Discount_Free_Months_Allowed__c=3,Discount_Pct_Allowed__c=50);
         Product_Pricing__c pp2 = new Product_Pricing__c(Name=p1.ProductCode,Low_Value__c=6, High_Value__c=99, Amount__c=7, Pricing_Type__c='Cumulative Rate Per Unit', Sales_Org__c='TestSalesOrg');
         Product_Pricing__c pp3 = new Product_Pricing__c(Name=p3.ProductCode,Low_Value__c=1, High_Value__c=99, Amount__c=3, Pricing_Type__c='Cumulative Rate Per Unit', Sales_Org__c='TestSalesOrg', Setup_Fee__c=50, Discount_Free_Months_Allowed__c=6,Discount_Pct_Allowed__c=75);
         Product_Pricing__c[] pricings = new Product_Pricing__c[]{pp1,pp2,pp3};
         insert pricings;
      }
      
      return pb;
   } // setupPricebookAndMap
    
   static testMethod void testMMSASOPilot(){
        Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,'Opportunity');
        User mmsRep = [SELECT ID FROM User WHERE IsActive = true AND Profile.Name = 'MMS Sales - SB' LIMIT 1];
        
        
        PermissionSet ps = new PermissionSet(Label='test permission set1',Name='test_permission_set1');
        insert ps;
        //query custom permission, cannot create in test
    CustomPermission cp = [SELECT Id,MasterLabel,DeveloperName FROM CustomPermission WHERE MasterLabel = 'MMS-ASO Pilot' LIMIT 1];
        //assign custom permission to permission set
        SetupEntityAccess sea = new SetupEntityAccess(ParentId = ps.Id,SetupEntityId = cp.Id);
        insert sea;
        //assign permission set to user
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId=ps.Id,AssigneeId = mmsRep.Id);
        insert psa; 
        
        test.startTest();
        System.runAs(mmsRep){
            Account acct = new Account(Name='test');
            insert acct;
            Contact ctct = new Contact(FirstName = 'test',LastName='contact',accountId = acct.Id);
            insert ctct;
            Opportunity oppty = new Opportunity(
                Name='test opp',
                CloseDate = date.today(),
                StageName = Label.OppStage_Qualified,
                RecordTypeId = mmsOpptyRt.getRecordTypeId(),
                Payroll_Platform__c = 'MMS',
                LeadSource = 'Cold Call',
                Payroll_Current_Prior_Method__c = 'ADP',
                Service_Location__c = 'Akron Branch 0049',
                OwnerId = mmsRep.Id);
            insert oppty;
            //Set Current Page to new reference
            PageReference pageRef = new PageReference('/apex/Onboarding?id='+oppty.Id);
            test.setCurrentPageReference(pageRef);
            OnboardingController newOnboarding = new OnboardingController();
            system.assertEquals('HR Solutions',newOnboarding.onboardingType);
        }
        test.stopTest();
    }
    
    static testMethod void testOracleQuote(){
        
        Account acctA = new Account(Name = 'testAccountA', AccountNumber = Null, NumberOfEmployees = 60);
        insert acctA;
        Contact c1_a1 = new Contact(FirstName='Test Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@paychex.com', HasOptedOutOfEmail=false);
        insert c1_a1;
        
        List<Product2> productList = new List<Product2>();
        List<Account> acctList = new List<Account>();
        List<cafsl__Oracle_Quote_Line_Item__c> oracleQuoteLineList = new List<cafsl__Oracle_Quote_Line_Item__c>();
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        
        Product2 quoteProductA = New Product2(Name = 'HR Solutions', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductA);
        Product2 quoteProductB = New Product2(Name = 'HR Solutions - ASO', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductB);
        Product2 quoteProductC = New Product2(Name = 'Paychex Flex Enterprise', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductC);
        Product2 quoteProductD = New Product2(Name = 'ESR', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductD);
        Product2 quoteProductE = New Product2(Name = 'Flex Time', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductE);
        insert productList;
        
        Id spricebookId = Test.getStandardPricebookId();
        System.debug('***CLM*** spricebookId: ' + spricebookId);
     
        PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductA.Id, UnitPrice=5.00, isActive=true, UseStandardPrice=false);
        PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductB.Id, UnitPrice=7.00, isActive=true, UseStandardPrice=false);
        PricebookEntry spbe3 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductC.Id, UnitPrice=5.00, isActive=true, UseStandardPrice=false);
        PricebookEntry spbe4 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductD.Id, UnitPrice=7.00, isActive=true, UseStandardPrice=false);
        PricebookEntry spbe5 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductE.Id, UnitPrice=5.00, isActive=true, UseStandardPrice=false);
        PricebookEntry[] spbes = new PricebookEntry[]{spbe1,spbe2,spbe3,spbe4,spbe5};
        insert spbes;
        
        PriceBookEntry[] pbe = [Select Id, Pricebook2Id, Product2Id, UnitPrice, Product2.Name, Pricebook2.Name from PricebookEntry where Id in :spbes];
        
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,StageName='Sold'
                                             ,CloseDate=Date.today().addDays(30)
                                             ,Pricebook2Id = spricebookId
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,Payroll_Platform__c = 'PAY'
                                             ,Payroll_Unit__c = true
                                             ,Payroll_Units__c = 5);        
        insert opptyA;
        
        //oracle field mappings
        cafsl__Field_Mapping__c qFieldMapping1 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote to Opportunity', cafsl__Source__c='multi_id__c', cafsl__Target__c='multi_id_client__c');
        cafsl__Field_Mapping__c qFieldMapping2 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote to Opportunity', cafsl__Source__c='multiple_pay_frequencies__c', cafsl__Target__c='multi_frequency__c');
        cafsl__Field_Mapping__c qFieldMapping3 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote to Opportunity', cafsl__Source__c='number_of_related_accounts__c', cafsl__Target__c='number_of_ids__c');
        cafsl__Field_Mapping__c qlFieldMapping1 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='discount_percent__c', cafsl__Target__c='discount_percent__c');
        cafsl__Field_Mapping__c qlFieldMapping2 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='customer_price_unit__c', cafsl__Target__c='unitprice');
        cafsl__Field_Mapping__c qlFieldMapping3 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='cafsl__quantity__c', cafsl__Target__c='quantity');
        cafsl__Field_Mapping__c qlFieldMapping4 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='cafsl__cpq_external_id__c', cafsl__Target__c='cpq_external_id__c');
        cafsl__Field_Mapping__c qlFieldMapping5 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='cafsl__sales_price__c', cafsl__Target__c='oracle_sales_price__c');
        cafsl__Field_Mapping__c[] fMappings = new cafsl__Field_Mapping__c[]{qFieldMapping1,qFieldMapping2,qFieldMapping3,qlFieldMapping1,qlFieldMapping2,qlFieldMapping3,qlFieldMapping4,qlFieldMapping5};
        insert fMappings;
        
        cafsl__Field_Mapping__c[] newFMappings = [SELECT Id, Name, cafsl__Type__c, cafsl__Source__c, cafsl__Target__c FROM cafsl__Field_Mapping__c];
        System.debug('newFMappings='+newFMappings);
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        
        //New Quote
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opptyA.AccountId;
        quote.cafsl__Opportunity__c = opptyA.Id;
        //quote.cafsl__Syncing__c = true;
        quote.Name = 'TestQuote';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        quote.Multi_ID__c = false;
        quote.cafsl__Pricebook_Id__c = spricebookId;
        quote.cafsl__CPQ_External_Id__c='12345678';
        insert quote;

        cafsl__Oracle_Quote__c newQuote = [SELECT Id, Name, cafsl__CPQ_External_Id__c, Approver__c FROM cafsl__Oracle_Quote__c WHERE Id=:quote.Id];
        System.debug('newQuote='+newQuote);
        
        //New Quote Line Items       
        System.debug('quoteProductA='+quoteProductA);
        System.debug('cafsl__Oracle_Quote__c.Id='+quote.Id);
        cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductA.Id, cafsl__Pricebook_Entry__c = spbe1.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5, customer_price_unit__c=4.00, cafsl__External_Id__c=1, cafsl__CPQ_External_Id__c='12345678-1', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        cafsl__Oracle_Quote_Line_Item__c quoteLine2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductB.Id, cafsl__Pricebook_Entry__c = spbe2.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=6, customer_price_unit__c=4.00, cafsl__External_Id__c=2, cafsl__CPQ_External_Id__c='12345678-2', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        cafsl__Oracle_Quote_Line_Item__c quoteLine3 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductC.Id, cafsl__Pricebook_Entry__c = spbe3.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=7, customer_price_unit__c=4.00, cafsl__External_Id__c=3, cafsl__CPQ_External_Id__c='12345678-3', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        cafsl__Oracle_Quote_Line_Item__c quoteLine4 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductD.Id, cafsl__Pricebook_Entry__c = spbe4.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=8, customer_price_unit__c=4.00, cafsl__External_Id__c=4, cafsl__CPQ_External_Id__c='12345678-4', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        cafsl__Oracle_Quote_Line_Item__c quoteLine5 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductE.Id, cafsl__Pricebook_Entry__c = spbe5.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=9, customer_price_unit__c=4.00, cafsl__External_Id__c=5, cafsl__CPQ_External_Id__c='12345678-5', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        
        oracleQuoteLineList.add(quoteLine1);
        oracleQuoteLineList.add(quoteLine2);
        oracleQuoteLineList.add(quoteLine3);
        oracleQuoteLineList.add(quoteLine4);
        oracleQuoteLineList.add(quoteLine5);
        insert oracleQuoteLineList;
        
        //mark quote primary
        opptyA.Primary_Oracle_Quote__c=quote.id;
        update opptyA;
        //quote.cafsl__Syncing__c = true;
        //update quote;
        
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        OnboardingController newOnboarding = new OnboardingController();
        System.assertEquals(newOnboarding.onboardingOpp.Id, opptyA.Id);
        System.assert(newOnboarding.hasEsr);  
        System.assert(newOnboarding.hasFlextime); 
    }
    static testMethod void testSubmitNCP(){
        Opportunity opptyA = getTestOppty();
        Contact c1_a1 = new Contact(FirstName='Client',LastName='Transition', Email=Label.Onboarding_SMB_CTT_Email);
        insert c1_a1;
       	Reference_CTT__c refCTT = new Reference_CTT__c(Status__c = 'Submitted to CTT', Ready_To_Be_Worked__c = true, Opportunity__c = opptyA.Id);
        insert refCTT;
        
        
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        User testUser = [Select Id, email from User where IsActive=true and email != null limit 1];
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.submitNCP();
        //System.assertEquals(true, newOnboarding.emailSent);
        test.stopTest();
    }
    
    static testmethod void testclonedchildprofiles(){
        Opportunity opptyA = getTestOppty();
					opptyA.Reason_Won__c='No Reason given' ;
        			opptyA.OpportunityType__c='Adjustment';
        update opptyA;
        
        Contact c1_a1 = getTestContact();
        User largeMarket = [Select Id, Name, Email from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
		test.startTest();
        Id spricebookId = Test.getStandardPricebookId();
        Opportunity opptyB = new Opportunity(Name='testOpptychild1', RecordTypeId=opptyA.RecordTypeId
                                             ,AccountId=opptyA.AccountId
                                              ,Primary_Opportunity__c=opptyA.Id
                                             ,StageName='Proposal'
                                             ,CloseDate=Date.today().addDays(30)
                                             ,Pricebook2Id = spricebookId
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,Payroll_Platform__c = 'PAY'
                                             ,Payroll_Unit__c = true
                                             ,Payroll_Units__c = 5);
        insert opptyB;
        
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.onboardingType = 'HR Solutions';
        newOnboarding.onboardingRecord.Product__c = 'HR Solutions-Flex';
        newOnboarding.onboardingRecord.Add_Onboarding__c = True;
        newOnboarding.onboardingRecord.Onboarding_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Accounts_Payable_Contact__c = c1_a1.Id;
        newOnboarding.onboardingRecord.Anticipated_Start_Date__c = Date.today();
        newOnboarding.onboardingRecord.Alternative_Email__c = largeMarket.Email;
         newOnboarding.onboardingRecord.New_Branch__c = '8';
        newOnboarding.onboardingRecord.New_Existing__c ='Existing Paychex Client';
        String[] profiles = Label.Onboarding_Profiles_who_must_also_own_the_Record.split(',');
       // System.debug('profiles = '+profiles);
        User testUser = [Select Id, email from User where IsActive=true and Profile.Name = :profiles[0] limit 1];
        
        if(testUser != null)
        {            
        testUser.Sales_Division_Override__c='ASO';
        testUser.Sales_Org__c='TAA';            
        update testUser;        
            System.runAs(testUser)
            {               
                newOnboarding.emailFSS();
            } 
        }
        newOnboarding.verifyList(new List<Boolean>{newOnboarding.onboardingRecord.Add_Onboarding__c});
        newOnboarding.onboardingRecord.PESS_Background_Screening__c=True;
        newOnboarding.pessValid();
        test.stopTest();
    }
    
    static testMethod void testduplicatePageRedirect(){
        Opportunity opptyA = getTestOppty();
        Contact c1_a1 = new Contact(FirstName='Client',LastName='Transition', Email=Label.Onboarding_SMB_CTT_Email);
        insert c1_a1;
       	Reference_CTT__c refCTT = new Reference_CTT__c(Status__c = 'Submitted to CTT', Ready_To_Be_Worked__c = true, Opportunity__c = opptyA.Id);
        insert refCTT;
        
        
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        User testUser = [Select Id, email from User where IsActive=true and email != null limit 1];
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.duplicatePageRedirect();
        //System.assertEquals(true, newOnboarding.emailSent);
        test.stopTest();
    }
    static testMethod void testSaveChanges2(){
        Opportunity opptyA = getTestOppty();
        Contact c1_a1 = new Contact(FirstName='Client',LastName='Transition', Email=Label.Onboarding_SMB_CTT_Email);
        insert c1_a1;
       	Reference_CTT__c refCTT = new Reference_CTT__c(Status__c = 'Submitted to CTT', Ready_To_Be_Worked__c = true, Opportunity__c = opptyA.Id);
        insert refCTT;
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        User testUser = [Select Id, email from User where IsActive=true and email != null limit 1];
        OnboardingController newOnboarding = new OnboardingController();
           newOnboarding.attachBody= EncodingUtil.base64Decode('test 123'); 
        	newOnboarding.attachName='testfile';
        newOnboarding.saveChanges2();
        PageReference testPage = ApexPages.currentPage();
        System.assertEquals(testPage,pageRef,'Did not Return to current page');
        Test.stopTest();
    }
    static testMethod void testCreateCase(){
        Opportunity opptyA = getTestOppty();
        Contact c1_a1 = new Contact(FirstName='Client',LastName='Transition', Email=Label.Onboarding_SMB_CTT_Email);
        insert c1_a1;
       	Reference_CTT__c refCTT = new Reference_CTT__c(Status__c = 'Submitted to CTT', Ready_To_Be_Worked__c = true, Opportunity__c = opptyA.Id);
        insert refCTT;
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        User testUser = [Select Id, email from User where IsActive=true and email != null limit 1];
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.createCase();
        Test.stopTest();
    }
    
    static testMethod void testduplicatePageCancelRedirect(){
        Opportunity opptyA = getTestOppty();
        Contact c1_a1 = new Contact(FirstName='Client',LastName='Transition', Email=Label.Onboarding_SMB_CTT_Email);
        insert c1_a1;
       	Reference_CTT__c refCTT = new Reference_CTT__c(Status__c = 'Submitted to CTT', Ready_To_Be_Worked__c = true, Opportunity__c = opptyA.Id);
        insert refCTT;
        
        
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        User testUser = [Select Id, email from User where IsActive=true and email != null limit 1];
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.duplicatePageCancelRedirect();
        newOnboarding.redirect();
        //System.assertEquals(true, newOnboarding.emailSent);
        test.stopTest();
    }

    
    static testMethod void testsubmitUpdateChatterPost(){
        Opportunity opptyA = getTestOppty();
        Contact c1_a1 = new Contact(FirstName='Client',LastName='Transition', Email=Label.Onboarding_SMB_CTT_Email);
        insert c1_a1;
       	Reference_CTT__c refCTT = new Reference_CTT__c(Status__c = 'Submitted to CTT', Ready_To_Be_Worked__c = true, Opportunity__c = opptyA.Id);
        insert refCTT;
        Reference_CTT__c refCTT1 = new Reference_CTT__c(Status__c = 'Submitted to CTT', Ready_To_Be_Worked__c = true, Opportunity__c = opptyA.Id);
        insert refCTT1;
        
        
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        User testUser = [Select Id, email from User where IsActive=true and email != null limit 1];
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.submitUpdateChatterPost();
        //System.assertEquals(true, newOnboarding.emailSent);
        test.stopTest();
    }
    static testMethod void testChildNCP(){
        
        Contact c1_a1 = new Contact(FirstName='Client',LastName='Transition', Email=Label.Onboarding_SMB_CTT_Email);
        insert c1_a1;
        Opportunity opptyA = getTestOppty();
        //test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        User testUser = [Select Id, email from User where IsActive=true and email != null limit 1];
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.getPreAssignedClientNumOptions();
        newOnboarding.getIrsIsDeliveryOptions();
        newOnboarding.getPayOnDemandOptions();
        newOnboarding.getAuthorizedOffOptions();
        newOnboarding.getDBAOptions();
        newOnboarding.submitNCP();
        //System.assertEquals(true, newOnboarding.emailSent);
        
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        Account acctB = new Account(Name = 'testAccountB', AccountNumber = '8-00081235',NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address');
        insert acctB;
        Opportunity opptyB = new Opportunity(Name='testOpptyB', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                             ,AccountId=acctB.id
                                             ,StageName='Sold'
                                             ,CloseDate=Date.today().addDays(30)
                                             ,Pricebook2Id = Test.getStandardPricebookId()
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,Payroll_Platform__c = 'PAY'
                                             ,Payroll_Unit__c = true
                                             ,Payroll_Units__c = 5);
        insert opptyB;
        
        Onboarding_Tool__c parentOnboardingRec = [SELECT Id, Name, PreAssignedClientNum__c, IrsIsDelivery__c, EmpsToLoad__c, PreAssignedId__c FROM Onboarding_Tool__c WHERE Opportunity_Id__c = :opptyA.Id LIMIT 1];
        parentOnboardingRec.PreAssignedClientNum__c = 'Yes';
        parentOnboardingRec.IrsIsDelivery__c = 'No';
        parentOnboardingRec.EmpsToLoad__c = 5;
        parentOnboardingRec.PreAssignedId__c = '1234';
        parentOnboardingRec.ReadyChex__c = 'Decline Both';
        parentOnboardingRec.GL__c = 'Decline Both';
        parentOnboardingRec.Skylight__c = 'Decline Both';
        parentOnboardingRec.Pay_Demand__c = 'Decline';
        //parentOnboardingRec.Irs_Address__c = '';
        parentOnboardingRec.PriorWagesLoaded__c = 'No';
        parentOnboardingRec.Run_Date__c = System.today();
        parentOnboardingRec.First_Check_Date__c = System.today();
        parentOnboardingRec.PeriodEndDate__c = System.today();
        parentOnboardingRec.StateProcessedIn__c = 'New York - NY';
        parentOnboardingRec.Business_Structure__c = 'LLC';
        parentOnboardingRec.Taxed_as_S_Corp__c = false;
        //parentOnboardingRec.PeriodEndDate__c = 'Decline Both';
        //parentOnboardingRec.PeriodEndDate__c = 'Decline Both';
        
        update parentOnboardingRec;
        
        System.debug('testChildNCP before inserting childOnboardingRec');
        Onboarding_Tool__c childOnboardingRec = new Onboarding_Tool__c(Opportunity_Id__c = opptyB.Id, Parent_Onboarding_Record__c = parentOnboardingRec.Id, Is_Child__c=true);
        insert childOnboardingRec;
        
        PageReference childOnboardingPageRef = new PageReference('/apex/Onboarding?id='+opptyB.Id);
        test.setCurrentPageReference(childOnboardingPageRef);
        OnboardingController childOnboardingController = new OnboardingController();
        
        System.assertEquals(childOnboardingController.parentOnboardingRecord.Id, parentOnboardingRec.Id);
        System.assertEquals(childOnboardingController.parentOnboardingOpp.Id, opptyA.Id);
        System.assertEquals(childOnboardingController.isChildOnboardingRec, true);
        System.assertEquals(childOnboardingController.hasParent, true);
        //System.debug('testChildNCP onboardingRecord='+childOnboardingController.onboardingRecord);
        //System.debug('testChildNCP onboardingOpp='+childOnboardingController.onboardingOpp);
        childOnboardingController.onboardingRecord.Use_Parent_Data__c = true;
        childOnboardingController.applyParentData();
		System.assertEquals(parentOnboardingRec.PreAssignedClientNum__c, childOnboardingController.onboardingRecord.PreAssignedClientNum__c);
        System.assertEquals(parentOnboardingRec.IrsIsDelivery__c, childOnboardingController.onboardingRecord.IrsIsDelivery__c);
        System.assertEquals(null, childOnboardingController.onboardingRecord.EmpsToLoad__c);
        System.assertEquals(parentOnboardingRec.PreAssignedId__c, childOnboardingController.onboardingRecord.PreAssignedId__c);
        
        childOnboardingController.onboardingRecord.Use_Parent_Data__c = false;
        childOnboardingController.applyParentData();
        System.assertEquals('No', childOnboardingController.onboardingRecord.PreAssignedClientNum__c);
        System.assertEquals(null, childOnboardingController.onboardingRecord.IrsIsDelivery__c);
        System.assertEquals(null, childOnboardingController.onboardingRecord.EmpsToLoad__c);
        System.assertEquals(null, childOnboardingController.onboardingRecord.PreAssignedId__c);
        //test.stopTest();
    }
    
    static testMethod void testValidateNCOForm(){
        Pricebook2 standardPB = setupPricebookAndMap(false);
        List<Product2> productList = new List<Product2>();
        List<Account> acctList = new List<Account>();
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        
        Product2 quoteProductA = New Product2(Name = 'Some Payroll', PayrollFrequency__c = 'Weekly', ProductCode = 'PAY', IsActive = true, Product_Group__c = 'Payroll');
        productList.add(quoteProductA);
        Product2 quoteProductB = New Product2(Name = 'Some 401k', PayrollFrequency__c = 'Weekly', ProductCode = 'HRS', IsActive = true, Product_Group__c= 'Retirement');
        productList.add(quoteProductB);
        insert productList;
        
        PriceBookEntry pbe = [Select Id, PriceBook2Id from PriceBookEntry where PriceBook2Id =:standardPB.Id limit 1];
        
        Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,'Opportunity');
        //Contact c1_a1 = getTestContact();
        Contact c1_a1 = new Contact(FirstName='Test Contact',LastName='Contact 1', DoNotCall=false, Email='c1a1@paychex.com', HasOptedOutOfEmail=false);
        insert c1_a1;
        Opportunity opptyA = getTestOppty();
        opptyA.RecordTypeId = mmsOpptyRt.getRecordTypeId();
        opptyA.Payroll_Units__c = 1;
        opptyA.Payroll_Platform__c = 'MMS';
        opptyA.LeadSource = 'Cold Call';
        opptyA.Payroll_Current_Prior_Method__c = 'ADP';
        opptyA.Service_Location__c = 'Akron Branch 0049';
        opptyA.First_Payroll_Delivery_Method__c = 'Mail';
        opptyA.Pricebook2Id = standardPB.Id;
        opptyA.Payroll_Current_Prior_Method__c = 'ADP';
        opptyA.Number_of_Ids__c = 1;
        
        update opptyA;
        
        opptyA.StageName = 'Sold';
        update opptyA;
        
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.typeSelected = true;
        newOnboarding.onboardingRecord.Form_Type__c = 'NCO';
        newOnboarding.hasEnterprise = true;
        newOnboarding.has401kProduct = true;
        newOnboarding.hasPayrollProduct = true;
            
        newOnboarding.onboardingRecord.Skylight__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Pay_Demand__c = 'Decline';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.GL__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.ReadyChex__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorize_Officer__c = c1_a1.Id;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorized_Officer_Title__c = 'Test';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorized_Officer_Phone__c = '1234567890';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorized_Officer_Email__c = 'test@email.com';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorized_Off_is_Payroll_Contact__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
 
        newOnboarding.onboardingRecord.Spanish_Speaking_Needs__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Does_Client_Use_DBA__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
  
        newOnboarding.onboardingRecord.PriorWagesLoaded__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.RelationWithAddAccount__c = 'NO';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Combo__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);

                
        newOnboarding.onboardingRecord.Multi_Id_Submission__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);

		newOnboarding.onboardingRecord.IrsIsDelivery__c = 'No';
        newOnboarding.onboardingRecord.Irs_Address__c = 'Test Address';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);

		newOnboarding.onboardingRecord.Business_Structure__c = 'LLC';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Taxed_as_S_Corp__c = true;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Run_Date__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.First_Check_Date__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.PeriodEndDate__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        
        newOnboarding.onboardingRecord.Ongoing_Call_Day_of_the_Week__c = 'Monday';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Ongoing_Check_Day_of_the_Week__c = 'Monday';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Ongoing_Pay_Period_End_Date__c = 'Monday';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Ongoing_Delivery__c = 'Mail';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.EmpsToLoad__c = 5;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Does_Company_Need_1099s__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.NumOf1099s__c = 5;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.StateProcessedIn__c = 'New York - NY';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Client_Require_Instructions__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Workers_Compensation__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.ReadyChex__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Multi_Id_Submission__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Combo__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Workers_Comp_Policy__c = 'No';
        newOnboarding.onboardingRecord.X401_k_Plan_Start_Date__c = Date.today().addDays(7);
        newOnboarding.onboardingRecord.NumComboIds__c = 1;
        newOnboarding.onboardingRecord.NumMultiIds__c = 1;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
         
        newOnboarding.onboardingRecord.NumComboIds__c = 1;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);

        newOnboarding.onboardingRecord.NumMultiIds__c = 1;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.GL__c = 'GL Service';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Accounting_Software__c = 'Excel';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Accounting_Software__c = 'Other Software';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Accounting_Software__c = 'Other_Accounting_Software__c';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorized_Off_is_Payroll_Contact__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Does_Client_Use_DBA__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.DBA_Name_On_Checks_And_Reports__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Workers_Comp_Policy__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Insurance_Carrier__c = 'Test';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Workers_Comp_Expiration_Date__c = System.Date.today();
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
    }
    
    static testMethod void testValidateMPSCForm(){
        
        Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,'Opportunity');
        Contact c1_a1 = getTestContact();
        Opportunity opptyA = getTestOppty();
        opptyA.RecordTypeId = mmsOpptyRt.getRecordTypeId();
        opptyA.Payroll_Units__c = 1;
        opptyA.Payroll_Platform__c = 'MMS';
        opptyA.LeadSource = 'Cold Call';
        opptyA.Payroll_Current_Prior_Method__c = 'ADP';
        opptyA.Service_Location__c = 'Akron Branch 0049';
        opptyA.First_Payroll_Delivery_Method__c = 'Mail';
        opptyA.Number_of_Ids__c = 1;
        
        update opptyA;
        
        opptyA.StageName = Label.OppStage_Sold;
        update opptyA;
        
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        OnboardingController newOnboarding = new OnboardingController();
        newOnboarding.typeSelected = true;
        newOnboarding.onboardingRecord.Form_Type__c = 'MPSC';
        newOnboarding.hasEnterprise = true;     
        //'', '', '', '', '', '', '', '', '', '', 
            //    '', '', '', '', 'onboardingRecord.', '',''    
        newOnboarding.onboardingRecord.GL__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Skylight__c = 'Decline Both';
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Workers_Compensation__c = 'Decline Both';
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.ReadyChex__c = 'Decline Both';
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Training__c = 'Recorded WebEx';
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Pay_Demand__c = 'Decline';
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.PriorWagesLoaded__c = 'Yes';
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Business_Structure__c = 'LLC';
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Taxed_as_S_Corp__c = true;
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Run_Date__c = Date.Today()+30;
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.First_Check_Date__c = Date.Today()+30;
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.PeriodEndDate__c = Date.Today()+30;
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Does_Company_Need_1099s__c = 'Yes';
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.NumOf1099s__c = 5;
       // newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.EmpsToLoad__c = 5;
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorize_Officer__c = c1_a1.Id;
        //newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorized_Officer_Title__c = 'Test';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorized_Officer_Phone__c = '1234567890';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorized_Officer_Email__c = 'test@email.com';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.PayrollContact__c = c1_a1.Id;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.PayrollContact_Title__c = 'Test';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.PayrollContact_Phone__c = '1234567890';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.PayrollContact_Email__c = 'test@email.com';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.StateProcessedIn__c = 'New York - NY';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.PriceLock3Year__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.PreAssignedClientNum__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Combo__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.NumComboIds__c = 1;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Multi_Id_Submission__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.NumMultiIds__c = 1;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.PreAssignedClientNum__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.PreAssignedId__c = '1234';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.GL__c = 'GL Service';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Accounting_Software__c = 'Excel';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Accounting_Software__c = 'Other Software';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Accounting_Software__c = 'Other_Accounting_Software__c';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.IrsIsDelivery__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
		
        newOnboarding.onboardingRecord.Irs_Address__c = 'Test Address';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Business_Structure__c = 'LLP';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        System.assertEquals(false, newOnboarding.onboardingRecord.Taxed_as_S_Corp__c);
        
        newOnboarding.onboardingRecord.PreAssignedClientNum__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
		System.assertEquals('', newOnboarding.onboardingRecord.PreAssignedId__c);
        
        newOnboarding.onboardingRecord.RelationWithAddAccount__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.RelatedAccountId__c = opptyA.AccountId;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        /*
        newOnboarding.onboardingRecord.Ongoing_Call_Day_of_the_Week__c = 'Monday';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Ongoing_Check_Day_of_the_Week__c = 'Monday';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Ongoing_Pay_Period_End_Date__c = 'Monday';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Ongoing_Delivery__c = 'Mail';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.GL__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.ReadyChex__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorize_Officer__c = c1_a1.Id;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        
        
        newOnboarding.onboardingRecord.Authorized_Off_is_Payroll_Contact__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
 
        newOnboarding.onboardingRecord.Spanish_Speaking_Needs__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Does_Client_Use_DBA__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
  
        
        
        newOnboarding.onboardingRecord.RelationWithAddAccount__c = 'NO';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Combo__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);

                
        newOnboarding.onboardingRecord.Multi_Id_Submission__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);

		newOnboarding.onboardingRecord.IrsIsDelivery__c = 'No';
        newOnboarding.onboardingRecord.Irs_Address__c = 'Test Address';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);

		
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        newOnboarding.onboardingRecord.Client_Require_Instructions__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Workers_Comp_Policy__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Combo__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.NumComboIds__c = 1;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Multi_Id_Submission__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.NumMultiIds__c = 1;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.GL__c = 'GL Service';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        
        
        newOnboarding.onboardingRecord.Accounting_Software__c = 'Other Software';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Accounting_Software__c = 'Other_Accounting_Software__c';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Authorized_Off_is_Payroll_Contact__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Does_Client_Use_DBA__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Workers_Comp_Policy__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Insurance_Carrier__c = 'Test';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Workers_Comp_Expiration_Date__c = System.Date.today();
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        
        /*
        newOnboarding.onboardingRecord.PreAssignedClientNum__c = 'Yes';
        newOnboarding.onboardingRecord.PreAssignedId__c = '11111';
        newOnboarding.onboardingRecord.Combo__c = 'Yes';
        newOnboarding.onboardingRecord.NumComboIds__c = 5;
        newOnboarding.onboardingRecord.RelationWithAddAccount__c = 'Yes';
        newOnboarding.onboardingRecord.RelatedAccountId__c = opptyA.AccountId;
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.ReadyChex__c = 'ReadyChex';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.GL__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Workers_Compensation__c = 'Decline Both';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        
        newOnboarding.onboardingRecord.ChangeOfEntity__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.PriorWagesLoaded__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Promotions__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.BankDocumentation__c = 'Yes';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        newOnboarding.onboardingRecord.Anticipated_Start_Date__c = Date.Today();
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        
        
        
        //newOnboarding.onboardingRecord.DiscountOffered__c = 'Yes'; 
        //newOnboarding.Validate();
        //System.assertEquals(true, newOnboarding.validRecord);
        newOnboarding.hasFlextime = true; 
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Multi_Id_Submission__c = 'Yes';
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.Taxed_as_S_Corp__c = true;
        newOnboarding.onboardingRecord.Business_Structure__c = 'LLP';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        System.assertEquals(false, newOnboarding.onboardingRecord.Taxed_as_S_Corp__c);
        newOnboarding.onboardingRecord.PreAssignedClientNum__c = 'No';
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        System.assertEquals('', newOnboarding.onboardingRecord.PreAssignedId__c);
        /*newOnboarding.onboardingRecord.Flextime_Timeclock__c = 'Yes';
        newOnboarding.onboardingRecord.Flextime_TAA__c = 'No';
        newOnboarding.onboardingRecord.NumFlexId__c = 2;
        newOnboarding.onboardingRecord.Flextime_Date__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
        newOnboarding.hasEsr = true; 
        newOnboarding.Validate();
        System.assertEquals(false, newOnboarding.validRecord);
        newOnboarding.onboardingRecord.ESR_educationInstitution__c = 'Yes';
        newOnboarding.onboardingRecord.ESR_selfInsuredPlan__c = 'No';
        newOnboarding.onboardingRecord.ESR_UnionEmps__c = 'No';
        newOnboarding.onboardingRecord.ESR_PriorMedRenewalDate__c = Date.Today()+30;
        newOnboarding.Validate();
        System.assertEquals(true, newOnboarding.validRecord);
 */
        
    }
    
    static testMethod void testCheckUserAccess(){
        Opportunity opptyA = getTestOppty();
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        String[] profiles = Label.Onboarding_Profiles_who_must_also_own_the_Record.split(',');
        System.debug('profiles = '+profiles);
        User testUser = [Select Id, email from User where IsActive=true and Profile.Name = :profiles[0] limit 1];
        OpportunityTeamMember otm = new OpportunityTeamMember(UserId=testUser.Id, OpportunityId=opptyA.Id);
        insert otm;
        if(testUser != null)
        {
            System.runAs(testUser)
            {
                OnboardingController newOnboarding = new OnboardingController();
                System.assertEquals(true, newOnboarding.hasAccess);
            } 
        }
        test.stopTest();
    }
    
    static testMethod void testClearDBAField(){
        Opportunity opptyA = getTestOppty();
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        OnboardingController newOnboarding = new OnboardingController();
		newOnboarding.onboardingRecord.Does_Client_Use_DBA__c = 'Yes';
        newOnboarding.onboardingOpp.Account.DBA__c = 'Test2';
        newOnboarding.onboardingRecord.DBA_Name_on_Checks_and_Reports__c = 'Yes';
        
        newOnboarding.onboardingRecord.Does_Client_Use_DBA__c = 'No';
        newOnboarding.clearDBAField();
        System.assertEquals('TEST', newOnboarding.onboardingOpp.Account.DBA__c);
        System.assertEquals(null, newOnboarding.onboardingRecord.DBA_Name_on_Checks_and_Reports__c);
        test.stopTest();
    }
    
    static testMethod void testFormSelection(){
        Opportunity opptyA = getTestOppty();
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        OnboardingController newOnboarding = new OnboardingController();
		newOnboarding.onboardingRecord.Form_Type__c = 'NCO';
        newOnboarding.continueClicked();
        
        System.assertEquals(true, newOnboarding.typeSelected);
        System.assertEquals('NCO', newOnboarding.onboardingRecord.Form_Type__c);
        test.stopTest();
    }
    
    static testMethod void testSLADate(){
        Opportunity opptyA = getTestOppty();
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/Onboarding?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        OnboardingController newOnboarding = new OnboardingController();
		newOnboarding.onboardingRecord.Run_Date__c = System.Date.Today() + 1;
        newOnboarding.onboardingOpp.New_or_Existing_Business__c = 'Existing';
        newOnboarding.checkRunDate();
        System.assertEquals(false, newOnboarding.existingBusinessRunDateOkay);
        
        newOnboarding.onboardingRecord.Run_Date__c = System.Date.Today() + 10;
        newOnboarding.checkRunDate();
        System.assertEquals(true, newOnboarding.existingBusinessRunDateOkay);
        
        newOnboarding.onboardingRecord.Run_Date__c = System.Date.Today() + 1;
        newOnboarding.onboardingOpp.New_or_Existing_Business__c = 'New';
        newOnboarding.checkRunDate();
        System.assertEquals(false, newOnboarding.newBusinessRunDateOkay);
        
        newOnboarding.onboardingRecord.Run_Date__c = System.Date.Today() + 10;
        newOnboarding.checkRunDate();
        System.assertEquals(true, newOnboarding.newBusinessRunDateOkay);
        
        newOnboarding.onboardingRecord.Run_Date__c = null;
        newOnboarding.checkRunDate();
        System.assertEquals(true, newOnboarding.newBusinessRunDateOkay);
        System.assertEquals(true, newOnboarding.existingBusinessRunDateOkay);
        test.stopTest();
    } // testSLADate
    
    static testMethod void addAdditonalContactsTest(){
        String emailText = '';
        test.startTest();
        Onboarding_Tool__c onboardingRecord = new Onboarding_Tool__c();
        onboardingRecord.Contact_Name_1__c = 'Test';
        onboardingRecord.Contact_Name_2__c = 'Test';
        onboardingRecord.Contact_Name_3__c = 'Test';
        onboardingRecord.Contact_Name_4__c = 'Test';
        onboardingRecord.Contact_Name_5__c = 'Test';
        onboardingRecord.Contact_Name_6__c = 'Test';
        onboardingRecord.Contact_Name_7__c = 'Test';
        onboardingRecord.Contact_Name_8__c = 'Test';
        onboardingRecord.Contact_Name_9__c = 'Test';
        onboardingRecord.Contact_Name_10__c = 'Test';
        onboardingRecord.Contact_Name_11__c = 'Test';
        onboardingRecord.Contact_Name_12__c = 'Test';
        onboardingRecord.Contact_Name_13__c = 'Test';
        onboardingRecord.Contact_Name_14__c = 'Test';
        onboardingRecord.Contact_Name_15__c = 'Test';
        onboardingRecord.Contact_Name_16__c = 'Test';
        onboardingRecord.Contact_Name_17__c = 'Test';
        onboardingRecord.Contact_Name_18__c = 'Test';
        onboardingRecord.Contact_Name_19__c = 'Test';
        onboardingRecord.Contact_Name_20__c = 'Test';
        
        onboardingRecord.Contact_Email_1__c = 'Test@test.com';
        onboardingRecord.Contact_Email_2__c = 'Test@test.com';
        onboardingRecord.Contact_Email_3__c = 'Test@test.com';
        onboardingRecord.Contact_Email_4__c = 'Test@test.com';
        onboardingRecord.Contact_Email_5__c = 'Test@test.com';
        onboardingRecord.Contact_Email_6__c = 'Test@test.com';
        onboardingRecord.Contact_Email_7__c = 'Test@test.com';
        onboardingRecord.Contact_Email_8__c = 'Test@test.com';
        onboardingRecord.Contact_Email_9__c = 'Test@test.com';
        onboardingRecord.Contact_Email_10__c = 'Test@test.com';
        onboardingRecord.Contact_Email_11__c = 'Test@test.com';
        onboardingRecord.Contact_Email_12__c = 'Test@test.com';
        onboardingRecord.Contact_Email_13__c = 'Test@test.com';
        onboardingRecord.Contact_Email_14__c = 'Test@test.com';
        onboardingRecord.Contact_Email_15__c = 'Test@test.com';
        onboardingRecord.Contact_Email_16__c = 'Test@test.com';
        onboardingRecord.Contact_Email_17__c = 'Test@test.com';
        onboardingRecord.Contact_Email_18__c = 'Test@test.com';
        onboardingRecord.Contact_Email_19__c = 'Test@test.com';
        onboardingRecord.Contact_Email_10__c = 'Test@test.com';
        String str = OnboardingController.addAdditonalContacts(emailText, onboardingRecord);
        system.assert(str.contains('Addtional Contacts'));
        test.stopTest();
        
    }
    
    static testMethod void testCreateOnboarding() {
       Account acct = new Account(Name='Test Account');
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert acct;
        
       Opportunity opp = new Opportunity(Name='Test Opp', CloseDate=Date.today().addDays(7), StageName='Pending', AccountId=acct.Id);
       OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
       insert opp;
        
       CSO_Tracking__c tracker = new CSO_Tracking__c(Name=acct.Name, AccountId__c=acct.Id, Opportunity__c=opp.Id);
       CsoMethods.SKIP_TRIGGERS=true;
       insert tracker;
        
       //CSO_Tracking__c trackerToUpdate, Opportunity oppty, String accountId, String accountName, Boolean isParent,Boolean isMulti,String parentOnboarding
       String onboardingId = OnboardingController.createOnboardingRecord(tracker, opp, null, acct.Name, true, false, null);
       Assert.areEqual(onboardingId, tracker.Onboarding_Tool__c);
    } // testCreateOnboarding
    
    static testMethod void testMisc() {
       CSO_Tracking__c tracker = new CSO_Tracking__c();
       insert tracker;
        
       OnboardingController.updateTrackerValidation(tracker, true);
       tracker = [Select Id, SSTValidated__c from CSO_Tracking__c where Id=:tracker.Id];
       Assert.isTrue(tracker.SSTValidated__c);
        
       Account acct = new Account(Name='Test Account');
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert acct;

       Contact ctct = new Contact(AccountId=acct.Id, FirstName='First', LastName='Last');
       insert ctct;
        
       Onboarding_Tool__c onboard = new Onboarding_Tool__c(AccountId__c=acct.Id);
       insert onboard;
        
       OnboardingController.updateAuthOfficer(onboard.Id, ctct.Id);
       
       OnboardingController controller = new OnboardingController(true);
       controller.x401kProductList = 'Test';
       controller.emailAddress = 'Email';
       controller.newExist = 'New';
       controller.noFSSEmail = 'No';
       controller.hasExistingTAA = true;
       controller.displayMessages = true;
    } // testMisc
    
} // class OnboardingControllerTest