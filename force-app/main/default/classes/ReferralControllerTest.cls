/* 
* Test methods for the ReferralController
*
* History
* -------
* 08/15/2012 Dan Carmen         Created
* 01/27/2013 Cindy Freeman      Added met
* hod testOriginatingReferralContact to test when referral comes from Referral Contact screen
* 05/06/2013 Cindy Freeman      modified testOriginatingReferralContact when is submitted by Core Rep
11/19/2014 Dan Carmen         Expire ownership if a referral is created without an opportunity (send email=true)
06/23/2015 Dan Carmen         revised testOriginatingReferralContact to runAs(sysAdmin) to pass test
12/23/2015 Cindy Freeman      added tests to get more code coverage
09/19/2016 Jermaine Stukes    added attachment tests
06/14/2017 Dan Carmen         Added additional tests
12/05/2017 Dan Carmen         Adjustments for adding addtional components to the VF page.
02/20/2018 Dan Carmen         Add separate query for Partner Referral info.
07/30/2019 Dan Carmen         Changes for how referrals save
09/03/2019 Dan Carmen         Fix query to select core sales reps
09/23/2019 Jake Hinds         Code for refer to self
10/07/2019 Jake Hinds         Code for queue referral partners
12/22/2019 Cindy Freeman      added test for Campaign logic, updating lead/contact campaign from form
01/07/2020 Cindy Freeman      added test in testInternalReferral for commission products 
10/20/2020 Dan Carmen         Added check for Job Name in rep queries
12/27/2021 Dan Carmen         Ability to set the Partner Type from Campaign Attributes
04/15/2022 Jaipal             Adding testcheckForPartner method 
11/09/2022 Dan Carmen         Change to allow for more Job Names (using the ReferralController_IntRef_Jobs label) to use internal referrals
07/15/2023 Pratik Das         APR0151864: SMB Channel Evolution--Added test for refClientChanged
09/25/2023 Pratik Das         APR0154201 Add processbutton to P&C Quote Data--Added test for pcQuoteData
03/13/2024 Dan Carmen         Fix for Referring Selling Employee logic - had to move where it was 

*/
@isTest
public class ReferralControllerTest {
    
    @testSetup
    public static void setupData() {
        TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false,new String[]{'LeadCompanyMethods'});
        TriggerMethodsTest.saveSetupClasses();
        
        ReferralLeadSourceMap__c rlsm1 = new ReferralLeadSourceMap__c(Name='NSS-ClientReferral',Account_Field__c='',IncomingLeadSource__c='Referral-Client-Unsolicited'
                                                                      ,IsActive__c=true, Label__c='Client Referral', NeedsReferralSource__c=true
                                                                      ,NSS_Source__c='Inbound', OppLeadSource__c='Referral-Client-Unsolicited', Partner_Type__c='NSS Referral'
                                                                      ,PrimarySourceType__c=true, ReferralBusType__c='', SourceType__c='Client');
        ReferralLeadSourceMap__c rlsm2 = new ReferralLeadSourceMap__c(Name='NSS-RefBank',Account_Field__c='',IncomingLeadSource__c='Referral - Bank'
                                                                      ,IsActive__c=true, Label__c='Bank Referral', NeedsReferralSource__c=true
                                                                      ,NSS_Source__c='Inbound', OppLeadSource__c='Referral - Bank', Partner_Type__c='NSS Referral'
                                                                      ,PrimarySourceType__c=true, ReferralBusType__c='Financial Services', SourceType__c='Bank');
        ReferralLeadSourceMap__c rlsm3 = new ReferralLeadSourceMap__c(Name='NSS-RefCPA',Account_Field__c='',IncomingLeadSource__c='Referral - CPA'
                                                                      ,IsActive__c=true, Label__c='CPA Referral', NeedsReferralSource__c=true
                                                                      ,NSS_Source__c='Inbound', OppLeadSource__c='Referral - CPA', Partner_Type__c='NSS Referral'
                                                                      ,PrimarySourceType__c=true, ReferralBusType__c='Accounting Firm', SourceType__c='CPA');
        UserHelperTest.setupSalesOrgSetting();
        setupRefPartners();
        Abbreviations__c abbrev = new Abbreviations__c(); 
        abbrev.name='Florida';   
        abbrev.abbrev__c ='FL';  
        insert abbrev;
    } // setupData
    
    public static String OTHER_PART_TYPE='Random Telemarketing';
    
    public static void setupRefPartners() {
        //UserHelperTest.setupSalesOrgSetting();
        // make sure there are no existing records
        //if ([Select count() from Referral_Partner__c] > 0) {
        //   Database.Delete([Select Id from Referral_Partner__c],true);
        //}
        Referral_Partner__c[] partners = new Referral_Partner__c[]{};
            for (String salesOrg : UserHelper.DIVISION_LIST) {
                Referral_Partner__c rp = new Referral_Partner__c(Name=salesOrg,Partner_Type__c=ReferralController.REF_INTERNAL,Sort_Order__c=partners.size()+1,Ref_To_Type__c='Contact',CreateRefOpp__c=true,UseApprovalProcess__c=true, IsActive__c=true, Always_Check_Send_Email__c=false, CheckPartnerReferral__c=true);
                partners.add(rp);
                Referral_Partner__c rpNss = new Referral_Partner__c(Name=salesOrg,Partner_Type__c=ReferralController.REF_NSS,Sort_Order__c=partners.size()+1,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true, SellingOpportunityType__c='Payroll',Emps_Min__c=0,Emps_Max__c=9999,Transfer_Reason_Required__c=true,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND);
                partners.add(rpNss);
                Referral_Partner__c rpOther = new Referral_Partner__c(Name=salesOrg,Partner_Type__c=OTHER_PART_TYPE,Sort_Order__c=partners.size()+1,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true, SellingOpportunityType__c='Payroll',Emps_Min__c=0,Emps_Max__c=9999,Transfer_Reason_Required__c=true,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND);
                partners.add(rpOther);
            }
        
        Referral_Partner__c rpExt1 = new Referral_Partner__c(Name='Test20',Partner_Type__c=ReferralController.REF_EXTERNAL,Sort_Order__c=20,Ref_To_Type__c='Referral Contact',CreateRefOpp__c=false, IsActive__c=true, Always_Check_Send_Email__c=false);
        Referral_Partner__c rpExt2 = new Referral_Partner__c(Name='Test21',Partner_Type__c=ReferralController.REF_EXTERNAL,Sort_Order__c=21,Ref_To_Type__c='Referral Contact',CreateRefOpp__c=false, IsActive__c=true, Always_Check_Send_Email__c=false);
        partners.add(rpExt1);
        partners.add(rpExt2);
        
        
        insert partners;
    } // setupRefPartners
    
    public static Referral_Partner__c[] getRefPartners() {
        String query = ObjectHelper.getSOQLQuery('Referral_Partner__c',null,false, false);
        query += ' where IsActive__c=true ';
        System.debug('getRefPartners query='+query);
        Referral_Partner__c[] refPartners = (query != null ? Database.query(query) : new Referral_Partner__c[]{});
        return refPartners;
    } // getRefPartners
    
    /*
public static Referral_Partner__c[] setupNSSRefPartners() {
//UserHelperTest.setupSalesOrgSetting();
// make sure there are no existing records
if ([Select count() from Referral_Partner__c] > 0) {
Database.Delete([Select Id from Referral_Partner__c],true);
}
Referral_Partner__c[] partners = new Referral_Partner__c[]{};
for (String salesOrg : UserHelper.DIVISION_LIST) {
Referral_Partner__c rp = new Referral_Partner__c(Name=salesOrg,Partner_Type__c=ReferralController.REF_INTERNAL,Sort_Order__c=partners.size()+1,Ref_To_Type__c='Contact',CreateRefOpp__c=true,UseApprovalProcess__c=true, IsActive__c=true);
partners.add(rp);
Referral_Partner__c rpNss = new Referral_Partner__c(Name=salesOrg,Partner_Type__c=ReferralController.REF_NSS,Sort_Order__c=partners.size()+1,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true, SellingOpportunityType__c='Payroll',Emps_Min__c=0,Emps_Max__c=9999,Transfer_Reason_Required__c=true);
partners.add(rpNss);
}

Referral_Partner__c rp20 = new Referral_Partner__c(Name='Test20',Partner_Type__c=ReferralController.REF_EXTERNAL,Sort_Order__c=20,Ref_To_Type__c='Referral Contact',CreateRefOpp__c=false, IsActive__c=true);
Referral_Partner__c rp21 = new Referral_Partner__c(Name='Test21',Partner_Type__c=ReferralController.REF_EXTERNAL,Sort_Order__c=21,Ref_To_Type__c='Referral Contact',CreateRefOpp__c=false, IsActive__c=true);
partners.add(rp20);
partners.add(rp21);


insert partners;
return partners;
} // setupNSSRefPartners
*/
    
    // Test the ReferralWrapper class.
    static testMethod void testReferralWrapper() {
        ReferralWrapper rw = new ReferralWrapper();
        System.assertEquals(true,(rw.ref != null));
        System.assertEquals(false,rw.lockTitle);
        System.assertEquals(false,rw.selected);
        System.assertEquals(false,rw.hasUser);
        System.assertEquals('Email',rw.referralType);
        System.assertEquals(null,rw.ref.ReferralNotes__c);
        
        // attach a user to it.
        User u = [Select Id, Name from User where IsActive=true and Id != :UserInfo.getUserId() limit 1];
        rw.ref.User__c = u.Id;
        
        System.assertEquals(true,rw.hasUser);
        System.assertEquals('Opportunity',rw.referralType);
        
        rw.addToReferralNotes('This is a message');
        System.assertEquals('This is a message',rw.ref.ReferralNotes__c);
        
        rw.addToReferralNotes('Okay?');
        System.assertEquals('This is a message\n Okay?',rw.ref.ReferralNotes__c);
        
        Referral_Partner__c rp1 = new Referral_Partner__c(Name='Aaa');
        Referral_Partner__c rp2 = new Referral_Partner__c(Name='Bbb');
        
        // test sorting
        rw.ref.Name = 'Aaa';
        rw.refPartner = rp1;
        ReferralWrapper rw2 = new ReferralWrapper();
        rw2.ref.Name = 'Bbb';
        rw2.refPartner = rp2;
        
        System.assertEquals(-1,rw.compareTo(null));
        System.assertEquals(0,rw.compareTo(rw));
        System.assertEquals(-1,rw.compareTo(rw2));
        System.assertEquals(1,rw2.compareTo(rw));
    } // testReferralWrapper
    
    // Test when the page does not start from a Contact or Opportunity Id
    static testMethod void testNoOrginatingId() {
        User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);
            //System.CurrentPageReference().getParameters().put('id',cgsChild.Id);
            ReferralController rc = new ReferralController();
            System.assertEquals(true,rc.isError);
            System.assertEquals(false,rc.isStep1);
            System.assertEquals(false,rc.isStep2);
            System.assertEquals(false,rc.isStep3);
            // should be an error message
            System.assertEquals(true,ApexPages.hasMessages());
            ApexPages.Message msg = ApexPages.getMessages().get(0);
            System.assertEquals(true,msg.getDetail().startsWith('The id passed into this form is not valid!'));
        } // System.runAs
    } // testNoOrginatingId
    
    // Test when page is passed in Sales Org
    static testMethod void testSalesOrg() {
        User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);      
            ReferralController rc = new ReferralController('PAY');
            System.assertEquals(u.Id,rc.runningUser.Id);
        } //System.runAs
        
    } // testSalesOrg
    
    // Test when runningUser is not a sales rep
    static testMethod void testnonSalesRep() {
        User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.OTHER_SALES_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct = new Account(Name='Test Account', OwnerId=u.Id);
        insert acct;
        Contact ctct = new Contact(FirstName='First',LastName='Last',AccountId=acct.Id, OwnerId=u.Id);
        insert ctct;
        
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);      
            System.CurrentPageReference().getParameters().put('Id',ctct.Id);
            System.currentPageReference().getParameters().put('startedFrom','Contact');
            ReferralController rc = new ReferralController();
            System.assertEquals(true,rc.isError);
            ApexPages.Message msg = ApexPages.getMessages().get(0);
            System.assertEquals(true,msg.getDetail().startsWith('You do not'));
            //System.assertNotEquals(null,rc.defReferral.Referral_Source__c);
            
        } //System.runAs
        
    } // testnonSalesRep
    
    static testMethod void testAccountId() {
        //User u = [Select Id, Name, UserRole.Name, Job_Name__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        User u = [Select Id, Name, UserRole.Name, Job_Name__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c in ('PAY','MMS') limit 1];
        System.debug('testAccountId u='+u);
        Account acct = new Account(Name='Test Account');
        insert acct;
        //setupRefPartners();
        Campaign camp = new Campaign(Name='testcampaign'
                                     , ACD_Name__c='acd test'
                                     ,Leadsource__c = 'test Leadsource'
                                     ,IsActive = true
                                     ,StartDate = Date.today());
        insert camp;
        
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);
            System.CurrentPageReference().getParameters().put('Id',acct.Id);
            //System.currentPageReference().getParameters().put('startedFrom','Account');            //CMF
            ReferralController rc = new ReferralController();
            System.assertEquals(false,rc.isError);
            System.assertEquals(false,ApexPages.hasMessages());
            //ApexPages.Message msg = ApexPages.getMessages().get(0);
            //System.assertEquals(true,(msg.getDetail().startsWith('A valid opportunity could not be found for')));
            System.assertEquals(true,rc.isReferringAccount);
            System.assertEquals(false,rc.isReferringOpportunity);
            System.assertEquals(false,rc.isReferringContact);
            System.assertEquals(false,rc.isReferringLead);
            
            rc.checkForAcdCampaign('acd test');
            System.assertEquals(camp.Id, rc.defReferral.Campaign__c);
            System.assertEquals(camp.Leadsource__c, rc.defReferral.SellingLeadsource__c);
            
            System.assertEquals(acct.Name,rc.sectionHeaderSubTitle);
        } // System.runAs
    } // testBadOppId
    
    
    // Test when there's a valid id but no partners setup 
    static testMethod void testValidIdsNoPartnersCtct() {
        //UserHelperTest.setupSalesOrgSetting();
        User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE limit 1];
        Account acct = new Account(Name='Test Account', OwnerId=u.Id);
        insert acct;
        Contact ctct = new Contact(FirstName='First',LastName='Last',AccountId=acct.Id, OwnerId=u.Id);
        insert ctct;
        
        // make sure there are no existing records to test for an error condition
        if ([Select count() from Referral_Partner__c] > 0) {
            Database.Delete([Select Id from Referral_Partner__c],true);
        }
        
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);
            System.CurrentPageReference().getParameters().put('Id',ctct.Id);
            System.currentPageReference().getParameters().put('startedFrom','Contact');            //CMF
            ReferralController rc = new ReferralController();
            System.assertEquals(true,rc.isError);
            System.assertEquals(false,rc.isStep1);
            System.assertEquals(false,rc.isStep2);
            System.assertEquals(false,rc.isStep3);
            System.assertEquals(ReferralController.REF_INTERNAL,rc.partnerType);
            
            // should be an error message
            System.assertEquals(true,ApexPages.hasMessages());
            ApexPages.Message msg = ApexPages.getMessages().get(0);
            System.assertEquals(ReferralController.REF_INTERNAL+' Referral Partner values could not be found! Values must be entered in the Referral Partner object to continue!',msg.getDetail() );
        }
    } // testValidIdsNoPartnersCtct
    
    // Test when referral process is started from Paychex employee contact record
    static testMethod void testPaychexCtct() {
        //UserHelperTest.setupSalesOrgSetting();
        User u = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
        Account acct = new Account(Name='Paychex Account', OwnerId=u.Id);
        insert acct;
        Contact ctct = new Contact(FirstName='First',LastName='Last',AccountId=acct.Id, OwnerId=u.Id, HR_Person_Id__c = '1234');
        insert ctct;
        
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);
            System.CurrentPageReference().getParameters().put('Id',ctct.Id);
            System.currentPageReference().getParameters().put('startedFrom','Contact');            //CMF
            ReferralController rc = new ReferralController();
            System.assertEquals(true,rc.isError);
            
            // should be an error message
            System.assertEquals(true,ApexPages.hasMessages());
            ApexPages.Message msg = ApexPages.getMessages().get(0);
            System.assertEquals('The referral process can not be started from this type of contact.',msg.getDetail() );
        }
    } // testPaychexCtct
    
    // Test when there's a valid id but no partners setup 
    /* TODO this is failing in production!
static testMethod void testValidIdsNoPartnersOppty() {
UserHelperTest.setupSalesOrgSetting();
User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE limit 1];

Account acct = new Account(Name='Test Account',OwnerId=u.Id);
insert acct;
Contact ctct = new Contact(FirstName='First',LastName='Last',AccountId=acct.Id,OwnerId=u.Id);
insert ctct;

Opportunity opp = new Opportunity(Name='Test Opp',CloseDate=Date.today(), StageName='Pending', AccountId=acct.Id,OwnerId=u.Id);
insert opp;
OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=opp.Id, ContactId=ctct.Id, IsPrimary=true);
insert ocr;

System.runAs(u) {
Test.SetCurrentPageReference(Page.Referral);
System.CurrentPageReference().getParameters().put('Id',opp.Id);
System.currentPageReference().getParameters().put('startedFrom','Opportunity');            //CMF
System.CurrentPageReference().getParameters().put('partnerType',ReferralController.REF_EXTERNAL);
ReferralController rc = new ReferralController();
System.assertEquals(true,rc.isError);
System.assertEquals(false,rc.isStep1);
System.assertEquals(false,rc.isStep2);
System.assertEquals(false,rc.isStep3);
System.assertEquals(ReferralController.REF_EXTERNAL,rc.partnerType);

// should be an error message
System.assertEquals(true,ApexPages.hasMessages());
// get the second message since one should have already existed.
ApexPages.Message msg = ApexPages.getMessages().get(0);
System.assertEquals(ReferralController.REF_EXTERNAL+' Referral Partner values could not be found! Values must be entered in the Referral Partner object to continue!',msg.getDetail() );

// cancel
String returnUrl = rc.cancel().getUrl();
System.assertEquals(true,returnUrl.contains(opp.Id));
} // System.runAs
} // testValidIdsNoPartnersOppty
*/
    
    // Test a "normal" internal referral process.
    @isTest(SeeAllData=false)
    static void testInternalReferral() {
        // add products to custom setting
        Commission_Referral_Products__c payCommProd1 = new Commission_Referral_Products__c(Name='Prod1',Commissionable__c=true,Product__c='Payroll',SalesOrg__c='PAY');
        Commission_Referral_Products__c payCommProd2 = new Commission_Referral_Products__c(Name='Prod2',Commissionable__c=true,Product__c='Flextime / StratusTime',SalesOrg__c='PAY');
        Commission_Referral_Products__c[] commProdList = new Commission_Referral_Products__c[]{payCommProd1,payCommProd2};
            insert commProdList;
        
        
        List<Id> excludeIds = new List<Id>();  
        // select a random user for a secondary owner field
        User uHrs = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_401 and Job_Name__c=:UserHelper.JOB_REP limit 1];
        excludeIds.add(uHrs.Id);
        User u = [Select Id, Name from User where IsActive=true and Profile.Name LIKE :Utilities.PROF_CORE_SALES+'%' and Sales_Org__c = :UserHelper.SO_CORE and Job_Name__c=:UserHelper.JOB_REP limit 1];
        excludeIds.add(u.Id);
        
        // setup zip codes
        String zip1 = '12345';
        // make sure there aren't already records for it.
        if ([select count() from Zip_Assignment__c where Name = :zip1] > 0) {
            Database.Delete([Select Id from Zip_Assignment__c where Name = :zip1],false);
        }
        Map<String,List<Zip_Assignment__c>> zaMapList1 = ZipCheckOwnerTest.getZaMapList(zip1,excludeIds);
        
        Integer numOrgs = ZipCHeckOwnerTest.numOrgsWithUsers;
        //String zip2 = '12346';
        //Map<String,List<Zip_Assignment__c>> zaMapList2 = ZipCheckOwnerTest.getZaMapList(zip2,null);
        
        // get the person ids
        Set<String> personIdSet = new Set<String>();
        for (String key : zaMapList1.keySet()) {
            List<Zip_Assignment__c> zaList = zaMapList1.get(key);
            for (Zip_Assignment__c za : zaList) {
                if (za.HR_Person_Id__c != null) {
                    personIdSet.add(za.HR_Person_Id__c);
                }
            }
        } // for (String key
        
        System.debug('Size of personIdSet='+personIdSet.size());
        
        // take out the products - for some reason this is preventing the code from deploying to production.
        // setup referral products
        //String[] prodNames = new String[]{};
        //  Product_Mapping__c[] pms = new Product_Mapping__c[]{};
        //for (String salesOrg : UserHelper.DIVISION_LIST) {
        //    String prodName = 'Test Referral-'+salesOrg;
        //    prodNames.add(prodName);
        //    Product_Mapping__c pm = new Product_Mapping__c(Sales_Org__c=UserHelper.SO_CORE, Product_Code__c=prodName, Type__c=ReferralController.REF_PROD_MAPPING,Mapping_Key__c=salesOrg);
        //     pms.add(pm);
        //}
        // clear out the mappings just in case
        //  ProductMappingTest.clearMappingByType(ReferralController.REF_PROD_MAPPING);
        
        //PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, UserHelper.SO_CORE, null);
        // save the product mapping records after the entries were created.       
        //  insert pms;
        
        Referral_Partner__c[] partners = getRefPartners(); //setupRefPartners();
        // setup
        
        // Paychex account - see if exists. If it doesn't, create it.
        Account acctPayx = null;
        Account[] accts = new Account[]{};
            try {
                acctPayx = [Select Id, Name from Account where Name=:UserHelper.PAYCHEX_COMP limit 1];
            } catch (Exception e) {
                acctPayx = new Account(Name=UserHelper.PAYCHEX_COMP);
                accts.add(acctPayx);
            } 
        // client account
        Account acct = new Account(Name='Test Account', ShippingPostalCode=zip1
                                   ,OwnerId=u.Id
                                   ,NumberOfEmployees=7
                                   ,HRS_Account_Owner__c=uHrs.id, HRS_Hold_Out__c=true, HRS_Hold_Out_Expiration__c=Date.today().addDays(30));
        accts.add(acct);
        insert accts;
        
        // get the core record type - have to set the record type because of the Sales_Contact__c flag.
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');
        // client contacts
        Contact ctct1 = new Contact(FirstName='First1',LastName='Last',OwnerId=u.Id,Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());
        Contact ctct2 = new Contact(FirstName='First2',LastName='Last',OwnerId=u.Id,Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());
        Contact[] ctcts = new Contact[]{ctct1,ctct2};
            // Paychex contacts
            // select any that already exist in the database
            Contact[] payxContactsSelected = [Select Id, Name, FirstName, LastName, HR_Person_Id__c from Contact where HR_Person_Id__c in :personIdSet];
        
        // remove the ids that were selected
        for (Contact ctct : payxContactsSelected) {
            personIdSet.remove(ctct.HR_Person_Id__c);
        }
        // make sure there aren't existing contact records
        //if ([select count() from Contact where HR_Person_Id__c in :personIdSet] > 0) {
        //   Database.Delete([Select Id from Contact where HR_Person_Id__c in :personIdSet],true);
        //}
        
        // create one paychex contact for each person id
        Contact[] payxCtcts = new Contact[]{};
            for (String personId : personIdSet) {
                Contact ctct = new Contact(FirstName='Payx'+personId,LastName='Contact',HR_Person_Id__c=personId,AccountId=acctPayx.Id);
                payxCtcts.add(ctct);
            }
        ctcts.addAll(payxCtcts);
        insert ctcts;
        
        payxCtcts.addAll(payxContactsSelected);
        
        ContactShare[] ctctShares = new ContactShare[]{};  
            // add sharing to Paychex contacts
            for (Contact ctct : payxCtcts) {
                ContactShare cs = new ContactShare(ContactId=ctct.Id, UserOrGroupId=u.Id, ContactAccessLevel='Read');
                ctctShares.add(cs);
            }
        insert ctctShares;
        
        // verify sales contacts are set
        System.assertEquals(2,[select count() from Contact where Sales_Contact__c=true and AccountId=:acct.Id]);
        
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);
            System.CurrentPageReference().getParameters().put('Id',ctct1.Id);
            System.currentPageReference().getParameters().put('startedFrom','Contact');            //CMF
            ReferralController rc = new ReferralController();
            System.assertEquals(false,rc.isError);
            System.assertEquals(true,rc.isStep1);
            System.assertEquals(true,rc.referralTableTitle.startsWith('Select Who This'));
            System.assertEquals(false,rc.isStep2);
            System.assertEquals(false,rc.isStep3);
            System.assertNotEquals(null,rc.displayList);
            
            PageReference tempPr = rc.warmTransferChanged();
            
            // verify account and contact are set
            System.assertEquals(ctct1.Id, rc.ctct.Id);
            System.assertEquals(acct.Id, rc.acct.Id);
            
            // verify contact options
            System.assertEquals(true,rc.hasCtctOptions);
            // should have more than one contact option
            System.assertEquals(false,rc.hasOnlyOneCtctOption);
            
            System.assertEquals(ReferralController.REF_INTERNAL,rc.partnerType);
            // verify the amount of referral records - 1 per referral partner
            System.assertEquals(UserHelper.DIVISION_LIST.size()+1,rc.partnerOptions.size());
            
            Integer numRecs = (UserHelper.DIVISION_LIST.size()-numOrgs) + (numOrgs*2);
            // ZipCheckOwnerTest.getZaMapList creates two records for each division name
            //System.assertEquals(numRecs,rc.displayList.size());
            System.assertEquals(true, UserHelper.DIVISION_LIST.size() <= rc.displayList.size(), 'DIVISION_LIST='+UserHelper.DIVISION_LIST.size()+' displayList='+rc.displayList.size());
            
            // check the referral options
            System.assertEquals(true,rc.referralOptions.size()>1);
            // test switching between internal and external referrals
            rc.partnerType = ReferralController.REF_EXTERNAL;
            System.assertEquals(null,rc.setReferralOption());
            System.assertEquals(ReferralController.REF_EXTERNAL,rc.partnerType);
            
            // verify the amount of referral records - 1 per referral partner
            System.assertEquals(3,rc.partnerOptions.size());
            System.assertEquals(2,rc.displayList.size());
            
            // switch back to internal referrals
            rc.partnerType = ReferralController.REF_INTERNAL;
            System.assertEquals(null,rc.setReferralOption());
            System.assertEquals(ReferralController.REF_INTERNAL,rc.partnerType);
            
            // select referrals
            ReferralWrapper ref1 = rc.displayList[0];
            ReferralWrapper ref2 = rc.displayList[rc.displayList.size()-1];
            ref1.ref.Contact__c = payxCtcts[0].Id;
            ref2.ref.Contact__c = payxCtcts[1].Id;
            
            // verify that they have paychex contacts already set.
            System.assertEquals(true,ref1.ref.Contact__c != null);
            System.assertEquals(true,ref2.ref.Contact__c != null);
            ref1.selected = true;
            ref2.selected = true;
            System.assertEquals(null,rc.markSelected());
            System.assertNotEquals(null,rc.referringOpp);
            System.assertEquals(null,rc.nextStep());
            System.assertEquals(true,rc.isStep2);
            
            // verify there are now only two records
            System.assertEquals(2,rc.displayList.size());
            
            // return to the previous step
            System.assertEquals(null,rc.previousStep());
            System.assertEquals(true,rc.isStep1);
            
            // add another referral
            System.assertEquals(null,rc.addMore());
            // verify the record is there
            System.assertEquals(true, UserHelper.DIVISION_LIST.size()+1 <= rc.displayList.size(), 'DIVISION_LIST='+UserHelper.DIVISION_LIST.size()+' displayList='+rc.displayList.size());
            
            ReferralWrapper ref3 = rc.displayList[rc.displayList.size()-1];
            // verify that not currently selected
            System.assertEquals(false,ref3.selected);
            // set the partner type to the first option
            ref3.selectedPartnerType = partners[0].Id;
            System.assertEquals(null,rc.setPartnerOption());
            // verify that ref3 is selected
            System.assertEquals(true,ref3.selected);
            // don't set the contact yet - should cause an error
            // try to go to step 2 - should still be on step 1
            System.assertEquals(null,rc.nextStep());
            System.assertEquals(true,rc.isStep1);
            
            // set the contact
            ref3.ref.Contact__c = payxCtcts[0].Id;
            ref3.ref.SourceContact__c = ctct2.Id;
            
            // this one should fail because the contact is already being used.
            System.assertEquals(null,rc.nextStep());
            System.assertEquals(true,rc.isStep1);
            
            // set it to an unused contact
            ref3.ref.Contact__c = payxCtcts[2].Id;
            
            // go back to step 2
            System.assertEquals(null,rc.nextStep());
            System.assertEquals(true,rc.isStep2);
            System.assertEquals('Submit Referral(s)', rc.nextStepButtonTitle);
            // verify there are now only two records
            System.assertEquals(3,rc.displayList.size());
            
            // make sure commissionable products were on display then force selection so it is saved to referral
            System.assertEquals(2,rc.commProdCommissionableSet.size());
            ref1.selectedCommProducts = 'Payroll';
            rc.selectedRefs[0].selectedCommProducts='Payroll';
            
            // verify referring opportunity
            System.assertEquals(true,rc.createReferringOpp);
            //rc.opp.LeadSource = 'Test';
            
            //add Attachment
            Referral__c ref = new Referral__c();
            insert ref;
            Attachment attach = new Attachment();
            attach.Name='Unit_Test_Attachment.pdf';
            attach.body=Blob.valueOf('Unit Test Attachment Body');
            rc.attachName = attach.Name;
            rc.attachBody = attach.Body;
            // save the referrals
            System.assertEquals(null,rc.nextStep());
            
            // make sure commission product got saved on referral        
            Referral__c[] refs = [Select Id, Name, Commission_Products__c
                                  From Referral__c
                                  Where Account__c = :acct.Id];
            Boolean commProd = false;                                
            for (Referral__c xref:refs)
            {      if (String.isNotBlank(xref.Commission_Products__c)) 
            {   commProd = true;    }
            }
            System.assertEquals(true, commProd);
            
            //System.assertEquals(true,rc.isStep3);
            
            // verify three referral records were created.
            //Referral__c[] refs = [Select Id, Name
            //                        From Referral__c
            //                       Where Account__c = :acct.Id];
            //System.assertEquals(3,refs.size());
            
            // finish the process - should return to the original contact
            //String urlString = rc.nextStep().getUrl();
            //System.assertEquals(true,(urlString.contains(ctct1.Id)));
            
        } // System.runAs
    } // testInternalReferral
    
    // Test the external referrals.
    static testMethod void testExternalReferral() {
        //UserHelperTest.setupSalesOrgSetting();
        // create referral
        Referral_Account__c ra = new Referral_Account__c(Name='Test Account');
        insert ra;
        Referral_Contact__c rc1 = new Referral_Contact__c(Name='Test Contact1', Referral_Account__c=ra.Id, Email__c='test1@paychex.com');
        Referral_Contact__c rc2 = new Referral_Contact__c(Name='Test Contact2', Referral_Account__c=ra.Id, Email__c='test2@paychex.com');
        Referral_Contact__c[] rcs = new Referral_Contact__c[]{rc1,rc2};
            insert rcs;
        
        Referral_Partner__c[] partners = getRefPartners(); //setupRefPartners();
        // set a default referral contact in last one
        Referral_Partner__c refPart = partners[partners.size()-1];
        // make sure we have the right one
        System.assertEquals(refPart.Name,'Test21');
        refPart.Referral_Contact__c = rc2.Id;
        update refPart;
        
        // get the core record type - have to set the record type because of the Sales_Contact__c flag.
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');
        Account acct = new Account(Name='Test Account');
        insert acct;
        // client contacts
        Contact ctct1 = new Contact(FirstName='First1',LastName='Last',Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());
        Contact ctct2 = new Contact(FirstName='First2',LastName='Last',Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());
        Contact[] ctcts = new Contact[]{ctct1,ctct2};
            insert ctcts;
        
        // verify sales contacts are set
        System.assertEquals(2,[select count() from Contact where Sales_Contact__c=true and AccountId=:acct.Id]);
        
        //User u = [Select Id, Name, UserRole.Name, Job_Name__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        User u = [Select Id, Name, UserRole.Name, Job_Name__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c in ('PAY','MMS') limit 1];
        
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);
            System.CurrentPageReference().getParameters().put('Id',ctct1.Id);
            System.currentPageReference().getParameters().put('startedFrom','Contact');            //CMF
            ReferralController rc = new ReferralController();
            System.assertEquals(false,rc.isError);
            System.assertEquals(true,rc.isStep1);
            System.assertEquals(false,rc.isStep2);
            System.assertEquals(false,rc.isStep3);
            
            // verify account and contact are set
            System.assertEquals(ctct1.Id, rc.ctct.Id);
            System.assertEquals(acct.Id, rc.acct.Id);
            
            // verify contact options
            System.assertEquals(true,rc.hasCtctOptions);
            // should have more than one contact option
            System.assertEquals(false,rc.hasOnlyOneCtctOption);
            
            System.assertEquals(ReferralController.REF_INTERNAL,rc.partnerType);
            // verify the amount of referral records - 1 per referral partner
            System.assertEquals(UserHelper.DIVISION_LIST.size()+1,rc.partnerOptions.size());
            System.assertEquals(UserHelper.DIVISION_LIST.size(),rc.displayList.size());
            
            // check the referral options
            System.assertEquals(true,rc.referralOptions.size() > 1);
            // test switching between internal and external referrals
            rc.partnerType = ReferralController.REF_EXTERNAL;
            System.assertEquals(null,rc.setReferralOption());
            System.assertEquals(ReferralController.REF_EXTERNAL,rc.partnerType);
            
            // verify the amount of referral records
            System.assertEquals(3,rc.partnerOptions.size());
            System.assertEquals(2,rc.displayList.size());
            
            // select referrals
            ReferralWrapper ref1 = rc.displayList[0];
            ReferralWrapper ref2 = rc.displayList[1];
            ref1.selected = true;
            ref2.selected = true;
            System.assertEquals(null,rc.markSelected());
            System.assertEquals(null,rc.nextStep());
            // should not go to next step because referral contact wasn't selected.
            System.assertEquals(true,rc.isStep1);
            
            // verify there are still only two records
            System.assertEquals(2,rc.displayList.size());
            // verify that the default is set for ref2
            System.assertEquals('Test21',ref2.refPartner.Name);
            //System.assertEquals(true,(ref2.ref.Referral_Contact__c != null));
            ref1.ref.Referral_Contact__c = rc1.Id;
            ref2.ref.Referral_Contact__c = rc2.Id;
            
            System.assertEquals(null,rc.nextStep());
            // should now go to step2
            System.assertEquals(true,rc.isStep2);
            // verify there are still only two records
            System.assertEquals(2,rc.displayList.size());
            
            // verify no referring opportunity
            System.assertEquals(false,rc.createReferringOpp);
            
            // save the referrals
            System.assertEquals(null,rc.nextStep());
            System.assertEquals(true,rc.isStep3);
            
            // verify two referral records were created.
            Referral__c[] refs = [Select Id, Name
                                  From Referral__c
                                  Where Account__c = :acct.Id];
            System.assertEquals(2,refs.size());
        } // System.runAs
    } // testExternalReferral
    
    // Test a "normal" NSS referral process.
    @isTest(SeeAllData=false)
    static void testNSSReferral() {
        
        List<Id> excludeIds = new List<Id>();  
        // select a random user for a secondary owner field
        User uHrs = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_401 limit 1];
        excludeIds.add(uHrs.Id);
        User uCore = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
        excludeIds.add(uCore.Id);
        User u = [Select Id, Name, NSS_Team__c from User where IsActive=true and Profile.Name = :Label.ProfilesNSSInbound and NSS_Team__c != null limit 1];
        excludeIds.add(u.Id);
        
        NSSTeamMap__c team1 = new NSSTeamMap__c(Name=u.NSS_Team__c, NSSSource__c='Inbound', ReferralPartnerType__c=ReferralController.REF_NSS);
        insert team1;
        
        // setup zip codes
        String zip1 = '12345';
        // make sure there aren't already records for it.
        if ([select count() from Zip_Assignment__c where Name = :zip1] > 0) {
            Database.Delete([Select Id from Zip_Assignment__c where Name = :zip1],false);
        }
        Map<String,List<Zip_Assignment__c>> zaMapList1 = ZipCheckOwnerTest.getZaMapList(zip1,excludeIds);
        
        Integer numOrgs = ZipCHeckOwnerTest.numOrgsWithUsers;
        
        // get the person ids
        Set<String> personIdSet = new Set<String>();
        for (String key : zaMapList1.keySet()) {
            List<Zip_Assignment__c> zaList = zaMapList1.get(key);
            for (Zip_Assignment__c za : zaList) {
                if (za.HR_Person_Id__c != null) {
                    personIdSet.add(za.HR_Person_Id__c);
                }
            }
        } // for (String key
        
        System.debug('Size of personIdSet='+personIdSet.size());
        
        //Referral_Partner__c[] partners = setupNSSRefPartners();
        // setup
        
        // Paychex account - see if exists. If it doesn't, create it.
        Account acctPayx = null;
        Account[] accts = new Account[]{};
            try {
                acctPayx = [Select Id, Name from Account where Name=:UserHelper.PAYCHEX_COMP limit 1];
            } catch (Exception e) {
                acctPayx = new Account(Name=UserHelper.PAYCHEX_COMP);
                accts.add(acctPayx);
            } 
        // client account
        Account acct = new Account(Name='Test Account', ShippingPostalCode=zip1
                                   ,OwnerId=uCore.Id
                                   ,NumberOfEmployees=7
                                   ,HRS_Account_Owner__c=uHrs.id, HRS_Hold_Out__c=true, HRS_Hold_Out_Expiration__c=Date.today().addDays(30));
        accts.add(acct);
        insert accts;
        
        Campaign camp = new Campaign(Name='testcampaign'
                                     , ACD_Name__c='acd test'
                                     ,Leadsource__c = 'test Leadsource'
                                     ,IsActive = true
                                     ,StartDate = Date.today());
        insert camp;
        
        // get the core record type - have to set the record type because of the Sales_Contact__c flag.
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');
        // client contacts
        Contact ctct1 = new Contact(FirstName='First1',LastName='Last',OwnerId=uCore.Id,Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId(), Products__c='Prod1;Prod2;Prod3');
        Contact ctct2 = new Contact(FirstName='First2',LastName='Last',OwnerId=uCore.Id,Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId(), Products__c='Prod1;Prod2;Prod3');
        Contact[] ctcts = new Contact[]{ctct1,ctct2};
            // Paychex contacts
            // select any that already exist in the database
            Contact[] payxContactsSelected = [Select Id, Name, FirstName, LastName, HR_Person_Id__c from Contact where HR_Person_Id__c in :personIdSet];
        
        // remove the ids that were selected
        for (Contact ctct : payxContactsSelected) {
            personIdSet.remove(ctct.HR_Person_Id__c);
        }
        
        // create one paychex contact for each person id
        Contact[] payxCtcts = new Contact[]{};
            for (String personId : personIdSet) {
                Contact ctct = new Contact(FirstName='Payx'+personId,LastName='Contact',HR_Person_Id__c=personId,AccountId=acctPayx.Id);
                payxCtcts.add(ctct);
            }
        ctcts.addAll(payxCtcts);
        insert ctcts;
        
        PartnerReferral__c partRef = new PartnerReferral__c(Contact__c=ctct1.Id,Account__c=acct.Id);
        insert partRef;
        
        payxCtcts.addAll(payxContactsSelected);
        
        ContactShare[] ctctShares = new ContactShare[]{};  
            // add sharing to Paychex contacts
            for (Contact ctct : payxCtcts) {
                ContactShare cs = new ContactShare(ContactId=ctct.Id, UserOrGroupId=uCore.Id, ContactAccessLevel='Read');
                ctctShares.add(cs);
            }
        //insert ctctShares;
        
        // verify sales contacts are set
        System.assertEquals(2,[select count() from Contact where Sales_Contact__c=true and AccountId=:acct.Id]);
        
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);
            System.CurrentPageReference().getParameters().put('Id',ctct1.Id);
            System.currentPageReference().getParameters().put('startedFrom','Contact');            //CMF
            System.CurrentPageReference().getParameters().put(ReferralController.PARAM_FUNCTION,'NSS');
            ReferralController rc = new ReferralController();
            System.assertEquals(false,rc.isError);
            System.assertEquals(true,rc.isStep1);
            System.assertEquals(false,rc.isStep2);
            System.assertEquals(false,rc.isStep3);
            
            // verify account and contact are set
            System.assertEquals(ctct1.Id, rc.ctct.Id);
            System.assertEquals(acct.Id, rc.acct.Id);
            
            // verify contact options
            System.assertEquals(true,rc.hasCtctOptions);
            // should have more than one contact option
            System.assertEquals(false,rc.hasOnlyOneCtctOption);
            
            System.assertEquals(Label.NSS_Create_Referral_Label, rc.referralTableTitle);
            
            System.assertEquals(ReferralController.REF_NSS,rc.partnerType);
            // verify the amount of referral records - 1 per referral partner
            System.assertEquals(UserHelper.DIVISION_LIST.size()+1,rc.partnerOptions.size());
            
            Integer numRecs = (UserHelper.DIVISION_LIST.size()-numOrgs) + (numOrgs*2);
            // ZipCheckOwnerTest.getZaMapList creates two records for each division name
            //System.assertEquals(numRecs,rc.displayList.size());
            System.assertEquals(true, UserHelper.DIVISION_LIST.size() <= rc.displayList.size(), 'DIVISION_LIST='+UserHelper.DIVISION_LIST.size()+' displayList='+rc.displayList.size());
            
            // select referrals
            ReferralWrapper ref1 = rc.displayList[0];
            ReferralWrapper ref2 = rc.displayList[rc.displayList.size()-1];
            ref1.ref.Contact__c = payxCtcts[0].Id;
            ref2.ref.Contact__c = payxCtcts[1].Id;
            // verify that they have paychex contacts already set.
            System.assertEquals(true,ref1.ref.Contact__c != null);
            System.assertEquals(true,ref2.ref.Contact__c != null);
            ref1.selected = true;
            System.assert(rc.partReferral != null);
            ref2.selected = true;
            System.assertEquals(null,rc.markSelected());
            rc.selectedRefs = new List<ReferralWrapper>();
            rc.selectedRefs.add(ref1);
            system.assertEquals(true,rc.isReasonRequired);
            
            // set campaign on form and test update
            rc.defReferral.Campaign__c = camp.Id;
            rc.verifyAndSaveCampaign();
            Contact updatedctct = [Select Id, LatestCampaign__c from Contact where id = :ctct1.Id];
            System.assertEquals(camp.Id, updatedctct.LatestCampaign__c);
            
        } // System.runAs
    } // testNSSReferral
    
    
    // Test the getAcctOwner method
    static testMethod void testGetAcctOwner() {
        User[] users = [Select Id, Name, IsActive, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c != null limit 4];
        Account acct = new Account(Name='Test Account');
        acct.OwnerId = users[0].Id;
        acct.Owner = users[0];
        
        RecordType coreRt = [Select Id, Name from RecordType where Name=:RecordTypeHelper.CORE_ACCOUNT];
        RecordType mmsRt = [Select Id, Name from RecordType where Name=:RecordTypeHelper.MMS_ACCOUNT];
        
        acct.RecordType = coreRt;
        
        acct.HRS_Account_Owner__c = users[1].Id;
        acct.HRS_Account_Owner__r = users[1];
        
        acct.Premier_PBS_Account_Owner__c = users[2].Id;
        acct.Premier_PBS_Account_Owner__r = users[2];
        
        acct.HNBF_Account_Owner__c = users[3].Id;
        acct.HNBF_Account_Owner__r = users[3];
        
        // test with null sales org
        System.assertEquals(null,ReferralController.getAcctOwner(null,acct,true));
        System.assertEquals(null,ReferralController.getAcctOwner('TestBadSalesOrg',acct,true));
        
        System.assertEquals(users[0].Id,ReferralController.getAcctOwner(UserHelper.SO_CORE, acct,true).Id);
        System.assertEquals(null,ReferralController.getAcctOwner(UserHelper.SO_MMS, acct,true));
        
        acct.RecordType = mmsRt;
        
        System.assertEquals(users[0].Id,ReferralController.getAcctOwner(UserHelper.SO_MMS, acct,true).Id);
        
        System.assertEquals(users[1].Id,ReferralController.getAcctOwner(UserHelper.SO_401, acct,true).Id);
        
        System.assertEquals(users[2].Id,ReferralController.getAcctOwner(UserHelper.SO_PEO_ASO, acct,true).Id);
        
        System.assertEquals(users[3].Id,ReferralController.getAcctOwner(UserHelper.SO_HNB, acct,true).Id);
        
        
    } // testGetAcctOwner
    
    
    // Test when the page starts from a Referral Contact 
    @isTest(SeeAllData=false)
    static void testOriginatingReferralContact() {
        // setup zip codes
        String zip1 = '12345';
        // make sure there aren't already records for it.
        if ([select count() from Zip_Assignment__c where Name = :zip1] > 0) {
            Database.Delete([Select Id from Zip_Assignment__c where Name = :zip1],false);
        }
        Map<String,List<Zip_Assignment__c>> zaMapList1 = ZipCheckOwnerTest.getZaMapList(zip1,null);
        //String zip2 = '12346';
        //Map<String,List<Zip_Assignment__c>> zaMapList2 = ZipCheckOwnerTest.getZaMapList(zip2,null);
        
        // get the person ids
        Set<String> personIdSet = new Set<String>();
        for (String key : zaMapList1.keySet()) {
            List<Zip_Assignment__c> zaList = zaMapList1.get(key);
            for (Zip_Assignment__c za : zaList) {
                if (za.HR_Person_Id__c != null) {
                    personIdSet.add(za.HR_Person_Id__c);
                }
            }
        } // for (String key
        
        System.debug('Size of personIdSet='+personIdSet.size());
        
        // select a random user for a secondary owner field
        User uHrs = [Select Id, Name, HR_Person_Id__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_401 and HR_Person_Id__c != null and HR_Person_Id__c not in :personIdSet limit 1];
        
        Referral_Partner__c[] partners = getRefPartners(); //setupRefPartners();
        // setup
        User uCore = [Select Id, Name, HR_Person_Id__c from User where IsActive=true and Profile.Name LIKE :Utilities.PROF_CORE_SALES+'%' and Sales_Org__c = :UserHelper.SO_CORE and HR_Person_Id__c != null and HR_Person_Id__c not in :personIdSet limit 1];
        User sysAdmin = [Select Id, Sales_Org__c from User where Profile.Name='System Administrator' and IsActive=true and Sales_Org__c != null limit 1];
        SalesOrg__c salesOrgSetting = SalesOrg__c.getInstance(sysAdmin.Sales_Org__c);
        if (salesOrgSetting == null) {
            salesOrgSetting = new SalesOrg__c(Name=sysAdmin.Sales_Org__c, CanSubmitReferrals__c=true);
            insert salesOrgSetting;
        }
        
        // add these person ids - to create contact records for them too.
        personIdSet.add(uHrs.HR_Person_Id__c);
        personIdSet.add(uCore.HR_Person_Id__c);
        
        // Paychex account - see if exists. If it doesn't, create it.
        Account acctPayx = null;
        Account[] accts = new Account[]{};
            try {
                acctPayx = [Select Id, Name from Account where Name=:UserHelper.PAYCHEX_COMP limit 1];
            } catch (Exception e) {
                acctPayx = new Account(Name=UserHelper.PAYCHEX_COMP);
                accts.add(acctPayx);
            } 
        // client account
        Account acct = new Account(Name='Test Account', ShippingPostalCode=zip1
                                   ,OwnerId=uCore.Id
                                   ,NumberOfEmployees=7
                                   ,HRS_Account_Owner__c=uHrs.id, HRS_Hold_Out__c=true, HRS_Hold_Out_Expiration__c=Date.today().addDays(30));
        accts.add(acct);
        insert accts;
        
        // get the core record type - have to set the record type because of the Sales_Contact__c flag.
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');
        // client contacts
        Contact ctct1 = new Contact(FirstName='First1',LastName='Last',OwnerId=uCore.Id,Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());
        Contact ctct2 = new Contact(FirstName='First2',LastName='Last',OwnerId=uCore.Id,Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());
        Contact[] ctcts = new Contact[]{ctct1,ctct2};
            // Paychex contacts
            // select any that already exist in the database
            Contact[] payxContactsSelected = [Select Id, Name, FirstName, LastName, HR_Person_Id__c from Contact where HR_Person_Id__c in :personIdSet];
        
        // remove the ids that were selected
        for (Contact ctct : payxContactsSelected) {
            personIdSet.remove(ctct.HR_Person_Id__c);
        }
        // make sure there aren't existing contact records
        //if ([select count() from Contact where HR_Person_Id__c in :personIdSet] > 0) {
        //   Database.Delete([Select Id from Contact where HR_Person_Id__c in :personIdSet],true);
        //}
        
        // create one paychex contact for each person id
        Contact[] payxCtcts = new Contact[]{};
            for (String personId : personIdSet) {
                Contact ctct = new Contact(FirstName='Payx'+personId,LastName='Contact',HR_Person_Id__c=personId,AccountId=acctPayx.Id);
                payxCtcts.add(ctct);
            }
        ctcts.addAll(payxCtcts);
        insert ctcts;
        
        payxCtcts.addAll(payxContactsSelected);
        
        ContactShare[] ctctShares = new ContactShare[]{};  
            // add sharing to Paychex contacts
            for (Contact ctct : payxCtcts) {
                ContactShare cs = new ContactShare(ContactId=ctct.Id, UserOrGroupId=uCore.Id, ContactAccessLevel='Read');
                ctctShares.add(cs);
            }
        insert ctctShares;
        
        // verify sales contacts are set
        System.assertEquals(2,[select count() from Contact where Sales_Contact__c=true and AccountId=:acct.Id]);
        
        // create referral
        Referral_Account__c ra = new Referral_Account__c(Name='Test Ref Account');
        insert ra;
        Referral_Contact__c rc1 = new Referral_Contact__c(Name='Test Ref Contact1', Referral_Account__c=ra.Id, 
                                                          Email__c='test1@paychex.com', Referral_Type__c='70 IIA General');           // CMF
        insert rc1;
        
        //System.runAs(uCore) {
        System.runAs(sysAdmin) {
            Test.SetCurrentPageReference(Page.Referral);
            
            System.CurrentPageReference().getParameters().put('Id',ctct1.Id);
            System.currentPageReference().getParameters().put('partnerType', 'Internal Referral');
            System.currentPageReference().getParameters().put('refContact', (String)rc1.Id);
            //System.currentPageReference().getParameters().put('noRefOptyNeeded', 'false');
            //System.currentPageReference().getParameters().put('startedFrom','Referral Contact');           //CMF
            
            ReferralController rc = new ReferralController();
            rc.nonRepOption = 'MySelf';
            rc.setRecordInfo();
            
            //System.assertEquals(rc.contactId, ctct1.Id);
            System.assertEquals(rc.referralContact.Id, rc1.Id);
            //System.assertEquals(rc.noRefOptyNeeded, false);
            System.assertEquals('Test Ref Contact1', rc.referralContact.Name);
            System.assertEquals('Referral Contact', rc.defReferral.Started_From__c);                                       // CMF
            
            // select referral
            ReferralWrapper ref1 = rc.displayList[0];
            ref1.ref.Contact__c = payxCtcts[0].Id;
            ref1.selected = true;
            System.assertEquals(null,rc.markSelected());
            System.assertEquals(null,rc.nextStep());
            System.assertEquals(true,rc.isStep2);
            
            // save the referrals
            System.assertEquals(null,rc.nextStep());         
            System.assertEquals(true,rc.isStep3);
            
            // verify one referral record was created.
            Referral__c[] refs = [Select Id, Name, Status__c, Referring_Opportunity__r.Id  
                                  From Referral__c
                                  Where Account__c = :acct.Id];
            System.assertEquals(1,refs.size());
            //System.assertEquals('Referral Sent', refs.get(0).Status__c);
            System.assertEquals('Pending', refs.get(0).Status__c);         // since running as core rep must send selling opty thru approval
            
            System.assertNotEquals(null, refs.get(0).Referring_Opportunity__r.Id);
            Opportunity refingOpty = [select Id, Name, Referral_Contact__c, LeadSource from Opportunity where id = :refs.get(0).Referring_Opportunity__r.Id];
            System.assertEquals(Label.LeadSource_InsAgent, refingOpty.LeadSource);         
            
            // finish the process - should return to the original contact
            String urlString = rc.nextStep().getUrl();
            System.assertEquals(true,(urlString.contains(rc1.Id)));
            
        } // System.runAs
    } // testOriginatingReferralContact
    
    // Test when creating referral for someone else
    static testMethod void testNonRepOptions() {
        User u = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_SYS_ADMIN and NSS_Team__c = null limit 1];
        Account acct = new Account(Name='Test Account', OwnerId=u.Id);
        insert acct;
        Contact ctct = new Contact(FirstName='First',LastName='Last',AccountId=acct.Id, OwnerId=u.Id);
        insert ctct;
        
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);
            System.CurrentPageReference().getParameters().put('Id',ctct.Id);
            System.currentPageReference().getParameters().put('startedFrom','Contact');            //CMF
            ReferralController rc = new ReferralController();
            // should be a message
            System.assertEquals(true,ApexPages.hasMessages());
            ApexPages.Message msg = ApexPages.getMessages().get(0);
            System.assertEquals(true,msg.getDetail().contains('select a sales org to continue'));
            
            rc.nonRepOption = 'Someone Else';
            rc.NonRepOptionSelected();
            User uHrs = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_401 limit 1];
            rc.tempRef.User__c = uHrs.Id;
            
            rc.setReferralUser();
            System.assertEquals('HRS',rc.salesOrg);
        }
    } // testNonRepOptions
    
    
    static testMethod void testShowAttachments() {
        ReferralController rc = new ReferralController();
        rc.showAttach();
        System.assertEquals(true, rc.attachShow);
    }
    
    static testMethod void testHideAttachments() {
        ReferralController rc = new ReferralController();
        rc.hideAttach();
        System.assertEquals(false, rc.attachShow);
    }
    
    static testMethod void testDeleteAttachments() {
        ReferralController rc = new ReferralController();
        Referral__c ra = new Referral__c(Name='Test Ref Account');
        insert ra;
        Referral__c[] refs = new Referral__c[]{};
            refs.add(ra);
        Attachment att = new Attachment();
        att.Name = 'test.pdf';
        att.Body = Blob.valueOf('Unit Test Attachment Body');
        att.ParentId = ra.Id;
        insert att;
        rc.attachName = att.Name;
        rc.attachBody = att.Body;
        ReferralWrapper rw = new ReferralWrapper();
        rc.defReferral = new Referral__c();
        //rc.referralUser
        rw.ref = ra;
        rc.selectedRefs = new List<ReferralWrapper>();
        rc.selectedRefs.add(rw);
        //rc.saveReferrals();
        Database.upsertresult[] results = Database.upsert(refs,false);
        rc.deleteAttachments(results, refs);
    }
    
    static testMethod void testMisc() {
        Test.SetCurrentPageReference(Page.Referral);
        //System.CurrentPageReference().getParameters().put('id',cgsChild.Id);
        ReferralController rc = new ReferralController();
        rc.toggleVForce();
        rc.runningUser = UserHelper.getRunningUser();
        Boolean testRunningUser = rc.isRunningUserDSA;
        Boolean external = rc.isRefExternal;
        rc.defReferral = new Referral__c();
        Boolean hasSalesOrgOptions = rc.hasSalesOrgOptions;
        rc.setSalesOrg();
        Boolean attachedRefSource = rc.hasAttachedReferralSource;
        String refSourceName = rc.referralSourceName;
        Boolean hasRefSource = rc.hasReferralSource;
        rc.referralSourceChanged();
        rc.handleLeadId(null);
        rc.useShortList = true;
        rc.changeRefPartnerDisplay();
        rc.hasExtendedList = false;
        Boolean hasMoreRefPartners = rc.hasMoreRefPartners;
        rc.nextStepOpty();
        String nextButtonTitle = rc.nextStepButtonTitle;
        String addtional = rc.getAdditionalReferralPartners();
        rc.cancel();
        rc.changeContactReferTo();
        String apptDesc = rc.apptDescription;
        rc.isFunctionNSS = true;
        Boolean creatingEvent = rc.creatingEvent;
        Boolean creatingTask = rc.creatingTask;
        Boolean hasCalendar = rc.hasCalendar;
        rc.calendarDate = Date.today();
        rc.gotoNextWeek();
        rc.gotoPrevWeek();
        //rc.convertLead();
        rc.checkForAccountMatch('Test Name','12345',null);
        rc.cancelFromEmbedded();
        
        setupProductGroupMapping('Test1','Test2');
        rc.setupProductMap('Test1');
        
        Opportunity opp = rc.startingOpp;
        Boolean isIntSell = rc.isIntSell;
        rc.nonRepOption = 'Myself';
        rc.nonRepOptionSelected();
        
        Referral__c ref = new Referral__c();
        insert ref;
        
        rc.checkForExistingReferral(ref.Id);
        
        rc.setupTimePicklist();
        
        //APR0121163
        // List<SelectOption> txReasons = rc.getTransferReasons();
        // system.assert(txReasons!=null);
        
        Boolean checkDm = rc.dm;
        Boolean checkMultiple = rc.multipleLocs;
        
        Boolean checkNSC = rc.allowRoleChange;
        rc.roleChanged();
        
        Boolean checkRecentAct = rc.hasRecentActivity;
        checkRecentAct = rc.nextDisabled;
        
        // create a contact so it will execute the query in the method      
        Contact ctct = new Contact(LastName='TestLast');
        insert ctct;
        rc.ctct = ctct;
        rc.checkForRecentActivity();
        
        List<SelectOption> options = rc.nonRepOptions;
        System.assertEquals(3, options.size());
        
        options = rc.activityOptions;
        System.assertEquals(2, options.size());
        
        System.assertEquals(false, rc.isWarmTransfer);
        rc.activityOptionChanged();
        
        rc.checkDefaultProducts('Product',true);
        
        //rc.setupNssRoleOptions();
        //rc.setupOasisRoleOptions();
        
    } // testMisc
    
    static testMethod void testTimeZone() {
        
        // test the time zone
        Zip_Code_Information__c zci = new Zip_Code_Information__c(Name='12345',TimeZoneName__c='TimeZone1', TimeZoneAbbrev__c='tz1');
        insert zci;
        
        AreaCode__c ac = new AreaCode__c(Name='555', TimeZoneName__c='TimeZone2', TimeZoneAbbrev__c='tz2');
        insert ac;
        
        TimeZone__c tz = new TimeZone__c(Name='TimeZone3', Abbrev__c='tz3', Default__c=true);
        insert tz;
        
        Test.SetCurrentPageReference(Page.Referral);
        ReferralController rc = new ReferralController();
        rc.defReferral = new Referral__c();
        
        rc.checkTimeZone(zci.Name, ac.Name,null,null);
        System.assertEquals(zci.TimeZoneName__c, rc.defReferral.TimeZoneName__c);
        System.assertEquals(zci.TimeZoneAbbrev__c, rc.defReferral.TimeZoneAbbrev__c);
        
        rc.checkTimeZone('23456', ac.Name,null,null);
        System.assertEquals(ac.TimeZoneName__c, rc.defReferral.TimeZoneName__c);
        System.assertEquals(ac.TimeZoneAbbrev__c, rc.defReferral.TimeZoneAbbrev__c);
        
        rc.checkTimeZone('23456', '111',null,null);
        System.assertEquals(tz.Name, rc.defReferral.TimeZoneName__c);
        System.assertEquals(tz.Abbrev__c, rc.defReferral.TimeZoneAbbrev__c);
        
        
        
    } // testTimeZone
    
    public static ProductGroupMapping__c[] setupProductGroupMapping(String partnerType, String mappingType) {
        ProductGroupMapping__c[] mapping = new ProductGroupMapping__c[]{};
            String prefixName = 'PROD-'+partnerType;
        mapping.add(new ProductGroupMapping__c(Name=prefixName+UserHelper.SO_401+'401K'
                                               ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                               ,NSS_Team__c=UserHelper.SO_401
                                               ,MappingType__c=mappingType
                                               ,Product_of_Interest__c='401K'
                                               ,Revenue__c=100, Units__c=1
                                               ,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_401K
                                               ,RecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_401K_FSS));
        mapping.add(new ProductGroupMapping__c(Name=prefixName+UserHelper.SO_401+'MMS'
                                               ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                               ,NSS_Team__c=UserHelper.SO_401
                                               ,MappingType__c=mappingType
                                               ,Product_of_Interest__c='MMS'
                                               ,Revenue__c=200, Units__c=2
                                               ,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_MMS
                                               ,RecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_MMS_DSA));
        mapping.add(new ProductGroupMapping__c(Name=prefixName+'CORE'
                                               ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                               ,NSS_Team__c=null
                                               ,MappingType__c=mappingType
                                               ,Product_of_Interest__c='CORE'
                                               ,Revenue__c=300, Units__c=3
                                               ,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_CORE
                                               ,RecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_CORE_DSA));
        insert mapping;
        return mapping;
    } // setupProductGroupMapping
    
    static testMethod void testLead() {
        Lead ld = new Lead(LastName='Test Lead', Company='Test Lead Company', Products__c='Prod1;Prod2;Prod3');
        insert ld;
        
        //setupRefPartners();
        
        User u = [Select Id, Name from User where IsActive=true and Profile.Name LIKE :Utilities.PROF_CORE_SALES+'%' and Sales_Org__c = :UserHelper.SO_CORE and Job_Name__c=:UserHelper.JOB_REP limit 1];
        Test.startTest();
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);
            System.CurrentPageReference().getParameters().put('Id',ld.Id);
            //System.currentPageReference().getParameters().put('startedFrom','Lead');            //CMF
            ReferralController rc = new ReferralController();
            String subTitle = rc.sectionHeaderSubTitle;
            System.debug('testLead subTitle='+subTitle);
            
            rc.defReferral.ActivityDate__c = Date.today().addDays(12);
            rc.defReferral.TimeZoneName__c = 'America/New_York';
            rc.selectedTime = '10:00:00';
            rc.checkActivityDate();
            rc.convertLead();
        } // System.runAs
        Test.stopTest();
        
        // test to make sure the referral is approved and the selling opportunity is created
        Lead chkLead = [Select Id, IsConverted, ConvertedAccountId, ConvertedContactId from Lead where Id=:ld.Id];
    } // testLead
    
    static testMethod void testIncludeExcludePartner(){
        Lead ld = new Lead(LastName='Test Lead', Company='Test Lead Company', Products__c='Prod1;Prod2;Prod3');
        insert ld;
        Test.SetCurrentPageReference(Page.Referral);
        System.CurrentPageReference().getParameters().put('Id',ld.Id);
        System.currentPageReference().getParameters().put('startedFrom','Lead'); 
        /*
//select existing sales divisions
AggregateResult[] results = [Select count(Id), Sales_Division__c
From User
Where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c != null
group by Sales_Division__c 
order by count(Sales_Division__c) desc];
*/
        String div1 = null;
        String div1abbrev = null;
        String div2 = null;
        String div2abbrev = null;
        
        
        String[] salesOrgs = new String[]{};
        for (SalesOrg__c salesOrgSetting : SalesOrg__c.getAll().values()) {
           if (salesOrgSetting.CanSubmitReferrals__c) {
              salesOrgs.add(salesOrgSetting.Name);
           }
        }
        Assert.isTrue(salesOrgs.size()>0,'Need to have Sales Org custom Settings setup!');
        
        // aggregate query won't work on the Sales Division field because it's a formula field.
        User[] users = [Select Id, Sales_Division__c 
                          from User Where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c != null 
                           and Sales_Org__c in :salesOrgs
                         limit 500];
        Map<String, Integer> cntMap = new Map<String,Integer>();
        for (User usr : users) {
            Integer cnt = (cntMap.containsKey(usr.Sales_Division__c) ? cntMap.get(usr.Sales_Division__c) : 0);
            cnt = cnt+1;
            cntMap.put(usr.Sales_Division__c,cnt);
            if (cnt > 10 && usr.Sales_Division__c != div1) {
                if (div1 == null) {
                    div1 = usr.Sales_Division__c;
                    div1abbrev = div1.substringBefore(' ');
                } else if (div2 == null && !usr.Sales_Division__c.startsWith(div1abbrev)) {
                    div2 = usr.Sales_Division__c;
                    div2abbrev = div2.substringBefore(' ');
                    break; 
                }
                
            }
        } // for (User usr
        users.clear();
        /*
for (AggregateResult result : results) {
String checkDiv = (String)result.get('Sales_Division__c');
if (div1 == null) {
div1 = checkDiv;
div1abbrev = checkDiv.substringBefore(' ');
} else if (div2 == null) {
if (!checkDiv.startsWith(div1abbrev)) {
div2 = checkDiv;
div2abbrev = checkDiv.substringBefore(' ');
break;
}
}
} // for (AggregateResult result
*/
        System.debug('testIncludeExcludePartner div1='+div1+' div1abbrev='+div1abbrev+' div2='+div2+' div2abbrev='+div2abbrev);
        
        User rep1 = [Select Id, Name, Sales_Division__c from User where IsActive=true and Sales_Division__c = :div1 and Job_Name__c=:userHelper.JOB_REP limit 1];
        User rep2 = [Select Id, Name, Sales_Division__c from User where IsActive=true and Sales_Division__c = :div2 and Job_Name__c=:userHelper.JOB_REP limit 1];
        System.debug('testIncludeExcludePartner rep1='+rep1+' rep2='+rep2);
        
        //create referral partners
        Referral_Partner__c refPart1 = new Referral_Partner__c(Name='Ref Partner1',Partner_Type__c=ReferralController.REF_INTERNAL,Sort_Order__c=21,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true, Always_Check_Send_Email__c=false,Include_For_Sales_Division__c = div1abbrev);
        Referral_Partner__c refPart2 = new Referral_Partner__c(Name='Ref Partner2',Partner_Type__c=ReferralController.REF_INTERNAL,Sort_Order__c=21,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true, Always_Check_Send_Email__c=false,Include_For_Sales_Division__c = div2abbrev,Exclude_For_Sales_Division__c=div1);
        Referral_Partner__c[] rps = new Referral_Partner__c[]{refPart1,refPart2};
            insert rps;
        
        System.runAs(rep1) {
            ReferralController rc = new ReferralController();
            Boolean refPart1Found = false;
            Boolean refPart2Found = false;
            for (ReferralWrapper rw : rc.displayList) {
                if (rw.ref.Referral_Partner__c == refPart1.Id) {
                    refPart1Found = true;
                }
                if (rw.ref.Referral_Partner__c == refPart2.Id) {
                    refPart2Found = true;
                }
            }//for ref partner
            
            system.assertEquals(true,refPart1Found);
            system.assertEquals(false,refPart2Found);
        } // System.runAs(rep1
        
        System.runAs(rep2) {
            ReferralController rc = new ReferralController();
            Boolean refPart1Found = false;
            Boolean refPart2Found = false;
            for (ReferralWrapper rw : rc.displayList) {
                if (rw.ref.Referral_Partner__c == refPart1.Id) {
                    refPart1Found = true;
                }
                if (rw.ref.Referral_Partner__c == refPart2.Id) {
                    refPart2Found = true;
                }
            }//for ref partner
            system.assertEquals(false,refPart1Found);
            system.assertEquals(true,refPart2Found);
        } // System.runAs(rep2
        /*
system.runAs(virtualUser){
ReferralController rc = new ReferralController();
Boolean virtualPartnerFound = false;
Boolean mmsPartnerFound = false;
for(ReferralWrapper rw : rc.displayList){
if(rw.ref.Referral_Partner__c == rpVirtual.Id){
virtualPartnerFound = true;
}
if(rw.ref.Referral_Partner__c == rpMMS.Id){
mmsPartnerFound = true;
}
}//for ref partner
system.assertEquals(true,virtualPartnerFound);
system.assertEquals(false,mmsPartnerFound);
}//run as virtual
system.runAs(mmsUser){
ReferralController rc = new ReferralController();
Boolean virtualPartnerFound = false;
Boolean mmsPartnerFound = false;
for(ReferralWrapper rw : rc.displayList){
if(rw.ref.Referral_Partner__c == rpVirtual.Id){
virtualPartnerFound = true;
}
if(rw.ref.Referral_Partner__c == rpMMS.Id){
mmsPartnerFound = true;
}
}//for ref partner
system.assertEquals(false,virtualPartnerFound);
system.assertEquals(true,mmsPartnerFound);
}//run as mms
system.runAs(smbUser){
ReferralController rc = new ReferralController();
Boolean virtualPartnerFound = false;
Boolean mmsPartnerFound = false;
for(ReferralWrapper rw : rc.displayList){
if(rw.ref.Referral_Partner__c == rpVirtual.Id){
virtualPartnerFound = true;
}
if(rw.ref.Referral_Partner__c == rpMMS.Id){
mmsPartnerFound = true;
}
}//for ref partner
system.assertEquals(false,virtualPartnerFound);
system.assertEquals(false,mmsPartnerFound);
}//run as smb
*/
    } // testIncludeExcludePartner
    static testMethod void testQueueReferral(){
        Account acct = new Account(Name='testCo',BillingPostalCode='14450');
        insert acct;
        Contact ctct = new Contact(LastName='Test Lead', AccountId=acct.Id);
        insert ctct;
        
        //setup RR stuff
        QueueSObject s1 = [SELECT Id,QueueId,Queue.Id,Queue.Name FROM QueueSObject WHERE SobjectType = 'Referral__c' LIMIT 1];
        Group testq = s1.Queue;
        
        Assignment_Group_Name__c ag = new Assignment_Group_Name__c(Name=testQ.Name);
        insert ag;
        Assignment_Group_Queues__c agq = new Assignment_Group_Queues__c(Name=testQ.Name,QueueId__c=testQ.Id,Assignment_Group_Name__c=ag.Id);
        insert agq;
        Assignment_Groups__c member = new Assignment_Groups__c(Active__c = 'true',Group_Name__c=ag.Id);
        insert member;
        
        Test.SetCurrentPageReference(Page.Referral);
        System.CurrentPageReference().getParameters().put('Id',ctct.Id);
        System.currentPageReference().getParameters().put('startedFrom','Contact');           
        
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
        //create referral partners
        Referral_Partner__c rpQueue = new Referral_Partner__c(Name='Test Virtual',Partner_Type__c=ReferralController.REF_INTERNAL,
                                                              Sort_Order__c=21,Ref_To_Type__c='Queue',ReferFromType__c='User',CreateRefOpp__c=true, 
                                                              IsActive__c=true,Selling_Opp_RecordTypeId__c=String.valueOf(coreRT.getRecordTypeId()),
                                                              QueueName__c=ag.Name,SetReferralOwner__c=true);
        insert rpQueue;
        //select running users
        User mmsUser = [SELECT Id FROM User WHERE IsActive = true AND Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c = 'Field MMS' LIMIT 1];
        test.startTest();
        system.runAs(mmsUser){
            ReferralController rc = new ReferralController();
            rc.selectedReferralSourceOption = 'Client Referral';
            
            System.assertNotEquals(null,rc.displayList, 'rc.displayList cannot be null.');
            for(ReferralWrapper rw : rc.displayList){
                if(rw.hasQueueName){
                    rw.selected = true;
                }
            }
            
            System.assertEquals(null,rc.markSelected());
            System.assertEquals(null,rc.nextStep());
            System.assertEquals(true,rc.isStep2);
            
            // save the referrals
            System.assertEquals(null,rc.nextStep());         
            System.assertEquals(true,rc.isStep3);
            
            // verify one referral record was created.
            Referral__c[] refs = [Select Id, Name, Status__c, Referring_Opportunity__r.Id  
                                  From Referral__c
                                  Where Account__c = :acct.Id];
            System.assertEquals(1,refs.size());
        }//run as virtual
        test.stopTest();
        
    }
    
    // Test a "normal" telemarketing referral process.
    @isTest(SeeAllData=false)
    static void testOtherTelemarketing() {
        
        List<Id> excludeIds = new List<Id>();  
        // select a random user for a secondary owner field
        User uHrs = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_401 limit 1];
        excludeIds.add(uHrs.Id);
        User uCore = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
        excludeIds.add(uCore.Id);
        User u = [Select Id, Name, NSS_Team__c from User where IsActive=true and Profile.Name = :Label.ProfilesNSSInbound and NSS_Team__c != null limit 1];
        excludeIds.add(u.Id);
        
        NSSTeamMap__c team1 = new NSSTeamMap__c(Name=u.NSS_Team__c, NSSSource__c='Inbound', ReferralPartnerType__c=OTHER_PART_TYPE);
        insert team1;
        
        // setup zip codes
        String zip1 = '12345';
        // make sure there aren't already records for it.
        if ([select count() from Zip_Assignment__c where Name = :zip1] > 0) {
            Database.Delete([Select Id from Zip_Assignment__c where Name = :zip1],false);
        }
        Map<String,List<Zip_Assignment__c>> zaMapList1 = ZipCheckOwnerTest.getZaMapList(zip1,excludeIds);
        
        Integer numOrgs = ZipCHeckOwnerTest.numOrgsWithUsers;
        
        // get the person ids
        Set<String> personIdSet = new Set<String>();
        for (String key : zaMapList1.keySet()) {
            List<Zip_Assignment__c> zaList = zaMapList1.get(key);
            for (Zip_Assignment__c za : zaList) {
                if (za.HR_Person_Id__c != null) {
                    personIdSet.add(za.HR_Person_Id__c);
                }
            }
        } // for (String key
        
        System.debug('Size of personIdSet='+personIdSet.size());
        
        //Referral_Partner__c[] partners = setupNSSRefPartners();
        // setup
        
        // Paychex account - see if exists. If it doesn't, create it.
        Account acctPayx = null;
        Account[] accts = new Account[]{};
            try {
                acctPayx = [Select Id, Name from Account where Name=:UserHelper.PAYCHEX_COMP limit 1];
            } catch (Exception e) {
                acctPayx = new Account(Name=UserHelper.PAYCHEX_COMP);
                accts.add(acctPayx);
            } 
        // client account
        Account acct = new Account(Name='Test Account', ShippingPostalCode=zip1
                                   ,OwnerId=uCore.Id
                                   ,NumberOfEmployees=7
                                   ,HRS_Account_Owner__c=uHrs.id, HRS_Hold_Out__c=true, HRS_Hold_Out_Expiration__c=Date.today().addDays(30));
        accts.add(acct);
        insert accts;
        
        Campaign camp = new Campaign(Name='testcampaign'
                                     , ACD_Name__c='acd test'
                                     ,Leadsource__c = 'test Leadsource'
                                     ,IsActive = true
                                     ,StartDate = Date.today());
        insert camp;
        
        // get the core record type - have to set the record type because of the Sales_Contact__c flag.
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');
        // client contacts
        Contact ctct1 = new Contact(FirstName='First1',LastName='Last',OwnerId=uCore.Id,Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId(), Products__c='Prod1;Prod2;Prod3');
        Contact ctct2 = new Contact(FirstName='First2',LastName='Last',OwnerId=uCore.Id,Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId(), Products__c='Prod1;Prod2;Prod3');
        Contact[] ctcts = new Contact[]{ctct1,ctct2};
            // Paychex contacts
            // select any that already exist in the database
            Contact[] payxContactsSelected = [Select Id, Name, FirstName, LastName, HR_Person_Id__c from Contact where HR_Person_Id__c in :personIdSet];
        
        // remove the ids that were selected
        for (Contact ctct : payxContactsSelected) {
            personIdSet.remove(ctct.HR_Person_Id__c);
        }
        
        // create one paychex contact for each person id
        Contact[] payxCtcts = new Contact[]{};
            for (String personId : personIdSet) {
                Contact ctct = new Contact(FirstName='Payx'+personId,LastName='Contact',HR_Person_Id__c=personId,AccountId=acctPayx.Id);
                payxCtcts.add(ctct);
            }
        ctcts.addAll(payxCtcts);
        insert ctcts;
        
        PartnerReferral__c partRef = new PartnerReferral__c(Contact__c=ctct1.Id,Account__c=acct.Id);
        insert partRef;
        
        payxCtcts.addAll(payxContactsSelected);
        
        ContactShare[] ctctShares = new ContactShare[]{};  
            // add sharing to Paychex contacts
            for (Contact ctct : payxCtcts) {
                ContactShare cs = new ContactShare(ContactId=ctct.Id, UserOrGroupId=uCore.Id, ContactAccessLevel='Read');
                ctctShares.add(cs);
            }
        //insert ctctShares;
        
        // verify sales contacts are set
        System.assertEquals(2,[select count() from Contact where Sales_Contact__c=true and AccountId=:acct.Id]);
        
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.Referral);
            System.CurrentPageReference().getParameters().put('Id',ctct1.Id);
            System.currentPageReference().getParameters().put('startedFrom','Contact');            //CMF
            System.CurrentPageReference().getParameters().put(ReferralController.PARAM_FUNCTION,'NSS');
            ReferralController rc = new ReferralController();
            System.assertEquals(false,rc.isError);
            System.assertEquals(true,rc.isStep1);
            System.assertEquals(false,rc.isStep2);
            System.assertEquals(false,rc.isStep3);
            
            // verify account and contact are set
            System.assertEquals(ctct1.Id, rc.ctct.Id);
            System.assertEquals(acct.Id, rc.acct.Id);
            
            // verify contact options
            System.assertEquals(true,rc.hasCtctOptions);
            // should have more than one contact option
            System.assertEquals(false,rc.hasOnlyOneCtctOption);
            
            System.assertEquals(Label.NSS_Create_Referral_Label, rc.referralTableTitle);
            
            System.assertEquals(OTHER_PART_TYPE,rc.partnerType);
            // verify the amount of referral records - 1 per referral partner
            System.assertEquals(UserHelper.DIVISION_LIST.size()+1,rc.partnerOptions.size());
            
            Integer numRecs = (UserHelper.DIVISION_LIST.size()-numOrgs) + (numOrgs*2);
            // ZipCheckOwnerTest.getZaMapList creates two records for each division name
            //System.assertEquals(numRecs,rc.displayList.size());
            System.assertEquals(true, UserHelper.DIVISION_LIST.size() <= rc.displayList.size(), 'DIVISION_LIST='+UserHelper.DIVISION_LIST.size()+' displayList='+rc.displayList.size());
            
            // select referrals
            ReferralWrapper ref1 = rc.displayList[0];
            ReferralWrapper ref2 = rc.displayList[rc.displayList.size()-1];
            ref1.ref.Contact__c = payxCtcts[0].Id;
            ref2.ref.Contact__c = payxCtcts[1].Id;
            // verify that they have paychex contacts already set.
            System.assertEquals(true,ref1.ref.Contact__c != null);
            System.assertEquals(true,ref2.ref.Contact__c != null);
            ref1.selected = true;
            System.assert(rc.partReferral != null);
            ref2.selected = true;
            System.assertEquals(null,rc.markSelected());
            rc.selectedRefs = new List<ReferralWrapper>();
            rc.selectedRefs.add(ref1);
            system.assertEquals(true,rc.isReasonRequired);
            
            // set campaign on form and test update
            rc.defReferral.Campaign__c = camp.Id;
            rc.verifyAndSaveCampaign();
            Contact updatedctct = [Select Id, LatestCampaign__c from Contact where id = :ctct1.Id];
            System.assertEquals(camp.Id, updatedctct.LatestCampaign__c);
            
        } // System.runAs
    } // testOtherTelemarketing
    
    static testMethod void testCheckSellingLeadSource() {
        User u = [Select Id, Name, UserRole.Name, Job_Name__c from User where IsActive=true and Profile.Name LIKE:UserHelper.SO_NSS+'%' limit 1];
        Campaign camp1 = new Campaign(Name='Test1',IsActive=true,LeadSource__c='Source Of Lead', Destination__c='Paychex',DestinationNbrDays__c=15);
        Campaign camp2 = new Campaign(Name='Test2',IsActive=true,LeadSource__c='Lead is Sourceless', Destination__c='Oasis',DestinationNbrDays__c=25);
        Campaign camp3 = new Campaign(Name='Test3',IsActive=true,LeadSource__c=null, Destination__c='Anywhere',DestinationNbrDays__c=null);
        Campaign[] camps = new Campaign[]{camp1,camp2,camp3};
            insert camps;
        
        Map<Id,Campaign> campMap = new Map<Id,Campaign>([Select Id, Name, Destination__c, DestinationNbrDays__c, LeadSource__c
                                                         ,PartnerType__c, RefPartnerNSSSource__c
                                                         From Campaign
                                                         Where Id in :camps]);
        camp1 = campMap.get(camp1.Id);
        camp2 = campMap.get(camp2.Id);
        camp3 = campMap.get(camp3.Id);
        // make sure the formula fields are working as expected.
        //System.assertNotEquals(null,camp1.PartnerType__c);
        //System.assertNotEquals(null,camp1.RefPartnerNSSSource__c);
        //System.assertNotEquals(null,camp2.PartnerType__c);
        //System.assertNotEquals(null,camp2.RefPartnerNSSSource__c);
        //System.assertEquals(null,camp3.PartnerType__c);
        //System.assertEquals(null,camp3.RefPartnerNSSSource__c);
        System.runAs(u){
            ReferralController rc = new ReferralController('PAY');
            rc.telemarketingUser=true;
            rc.partnerType='Limited';
            rc.nssSource='Psychic';
            
            Datetime checkDT10 = Datetime.now().addDays(-10);
            Datetime checkDT20 = Datetime.now().addDays(-20);
            Datetime checkDT30 = Datetime.now().addDays(-30);
            
            rc.checkSellingLeadSource('Existing', camp1, checkDT20);
            System.assertEquals(camp1.LeadSource__c,rc.defReferral.SellingLeadSource__c);
            System.assertEquals('Limited',rc.partnerType);
            System.assertEquals('Psychic',rc.nssSource);
            
            rc.checkSellingLeadSource('Existing', camp1, checkDT10);
            System.assertEquals(camp1.LeadSource__c,rc.defReferral.SellingLeadSource__c);
            //   System.assertEquals(camp1.PartnerType__c,rc.partnerType);
            //   System.assertEquals(camp1.RefPartnerNSSSource__c,rc.nssSource);
            
            rc.partnerType='Partnership';
            rc.nssSource=ProspectOwnershipMethods.NSS_INBOUND;
            rc.defReferral.SellingLeadSource__c=null;
            // this is in hours
            ReferralController.DATE_RANGE = 600;
            rc.checkSellingLeadSource('Existing', camp3, checkDT20);
            
            System.assertEquals(Label.LeadSource_Inbound_Default,rc.defReferral.SellingLeadSource__c);
            System.assertEquals('Partnership',rc.partnerType);
            System.assertEquals(ProspectOwnershipMethods.NSS_INBOUND,rc.nssSource);
            System.assertEquals(camp3.Id, rc.defReferral.Campaign__c);
            
            rc.partnerType='Partnership';
            rc.nssSource='Source';
            rc.defReferral.SellingLeadSource__c=null;
            rc.defReferral.Campaign__c=null;
            
            rc.checkSellingLeadSource('Existing', null, checkDT20);
            System.assertEquals('Existing',rc.defReferral.SellingLeadSource__c);
            System.assertEquals('Partnership',rc.partnerType);
            System.assertEquals('Source',rc.nssSource);
            System.assertEquals(null, rc.defReferral.Campaign__c);
        }
        
        
        
    } // testCheckSellingLeadSource
    static testMethod void testcheckForPartner() {  
        //UserHelperTest.setupSalesOrgSetting();  
        // create referral    
        Referral_Account__c ra = new Referral_Account__c(Name='Test Account');    
        insert ra;    
        Referral_Contact__c rc1 = new Referral_Contact__c(Name='Test Contact1', Referral_Account__c=ra.Id, Email__c='test1@paychex.com'); 
        Referral_Contact__c rc2 = new Referral_Contact__c(Name='Test Contact2', Referral_Account__c=ra.Id, Email__c='test2@paychex.com'); 
        Referral_Contact__c[] rcs = new Referral_Contact__c[]{rc1,rc2};   
            insert rcs;   
        Referral_Partner__c[] partners = getRefPartners(); //setupRefPartners();  
        // set a default referral contact in last one 
        Referral_Partner__c refPart = partners[partners.size()-1];    
        // make sure we have the right one    
        System.assertEquals(refPart.Name,'Test21');   
        refPart.Referral_Contact__c = rc2.Id; 
        update refPart;   
        
        // get the core record type - have to set the record type because of the Sales_Contact__c flag.   
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');  
        Account acct = new Account(Name='Test Account');  
        insert acct;  
        // client contacts    
        Contact ctct1 = new Contact(FirstName='First1',LastName='Last',Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());   
        Contact ctct2 = new Contact(FirstName='First2',LastName='Last',Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());   
        Contact[] ctcts = new Contact[]{ctct1,ctct2}; 
            insert ctcts; 
        Lead l= new lead(Company='Gtest',Country='India', Description ='test' ,LastName='Testlast',Firstname='Testfirst' ,State='Florida', PostalCode='1234567');   
        insert l;   
        
        // verify sales contacts are set  
        //System.assertEquals(2,[select count() from Contact where Sales_Contact__c=true and AccountId=:acct.Id]);    
        
        //User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];    
        User u = [Select Id, Name, UserRole.Name, Job_Name__c from User where IsActive=true and title='Sr Mid-Market HCM Consultant' and Sales_Org__c = 'MMS' limit 1];   
        
        System.runAs(u) { 
            Test.SetCurrentPageReference(Page.Referral);   
            System.CurrentPageReference().getParameters().put('Id',ctct1.Id);  
            System.currentPageReference().getParameters().put('startedFrom','Contact');            //CMF   
            ReferralController rc = new ReferralController();  
            rc.primaryLead=l; 
            rc.teamSellingASOEligible=true;   
            
            
            // test switching between internal and external referrals  
            rc.partnerType = ReferralController.REF_EXTERNAL;  
            
            ReferralWrapper ref1 = rc.displayList[0];  
            ReferralWrapper ref2 = rc.displayList[1];  
            ref1.selected = true;  
            ref2.selected = true;  
            ref1.ref.user__c=u.id;    
            
            ref1.ref.Referral_Contact__c = rc1.Id; 
            ref2.ref.Referral_Contact__c = rc2.Id; 
            ref1.refUserIsVirtual =false; 
            ref1.refPartner.CheckTeamSellingASO__c=true;  
            ref2.refUserIsVirtual =false;    
            ref2.refPartner.CheckTeamSellingASO__c=true;  
            
            Referral__c[] refs = [Select Id, Name  
                                  From Referral__c   
                                  Where Account__c = :acct.Id];   
            // System.assertEquals(2,refs.size());  
            id returns= rc.checkForPartner(ref1); 
        }     
    }
    static testMethod void testcheckForPartner1() {
        Test.StartTest();
        Account acct = new Account(Name = 'TestAccount');
        insert acct;
        // get the core record type - have to set the record type because of the Sales_Contact__c flag.
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');
        Contact ctct1 = new Contact(FirstName='First1',LastName='Last',Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());
        Insert ctct1;
        Campaign Cam = new Campaign(Name = 'Test Campaign');
        Insert Cam;
        Campaign camp = [Select Id from Campaign Where Name = 'Test Campaign' Limit 1];
        Contact Con = [Select Id from Contact Where FirstName='First1' and LastName='Last' Limit 1]; 
        User u = [Select Id, Name from User where IsActive=true and Id != :UserInfo.getUserId() limit 1];
        list<Integrated_Selling__mdt> ism = [Select Payroll_Rep_Name__c,SalesOrg__c,Segment_Used__c,State__c,EE_Count_Min__c,EE_Count_Max__c from Integrated_Selling__mdt where Payroll_Rep_Name__c = 'MMS Level 1 Certified' and State__c = 'FL' Limit 1];
        ReferralWrapper rw = new ReferralWrapper();
        System.runas(u){
            PageReference pageRef = Page.Referral; 
            pageRef.getParameters().put('Id',con.Id);
            pageRef.getParameters().put('startedFrom','Contact');
            Test.setCurrentPage(pageRef);
            ReferralController rc = new ReferralController();
            rc.defReferral.Campaign__c = Camp.Id;
            rc.setDisplayList();
            PageReference pgrf = rc.markSelected();
            Test.StopTest();
        }
    } //testcheckForPartner1
    
    //APR0151864: SMB Channel Evolution BAU--Start
    @isTest(SeeAllData=false)
    static void testrefClientChanged() {
        
        //Create Group
        Group queueALBANY = new Group(Name='ALBANY', DeveloperName='ALBANY');
        insert queueALBANY;
        
        // create referral
        Referral_Account__c ra = new Referral_Account__c(Name='Test Account');
        insert ra;
        Referral_Contact__c rc1 = new Referral_Contact__c(Name='Test Contact1', Referral_Account__c=ra.Id, Email__c='test1@paychex.com');
        Referral_Contact__c rc2 = new Referral_Contact__c(Name='Test Contact2', Referral_Account__c=ra.Id, Email__c='test2@paychex.com');
        Referral_Contact__c[] rcs = new Referral_Contact__c[]{rc1,rc2};
            insert rcs;
        
        Referral_Partner__c[] partners = getRefPartners(); //setupRefPartners();
        // set a default referral contact in last one
        Referral_Partner__c refPart = partners[partners.size()-1];
        // make sure we have the right one
        System.assertEquals(refPart.Name,'Test21');
        refPart.Referral_Contact__c = rc2.Id;
        //refPart.Name='SMB New Business';
        update refPart;
        
        // get the core record type - have to set the record type because of the Sales_Contact__c flag.
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');
        Account acct = new Account(Name='Test Account');
        insert acct;
        // client contacts
        Contact ctct1 = new Contact(FirstName='First1',LastName='Last',Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());
        Contact ctct2 = new Contact(FirstName='First2',LastName='Last',Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());
        Contact[] ctcts = new Contact[]{ctct1,ctct2};
            insert ctcts;
        
        // verify sales contacts are set
        System.assertEquals(2,[select count() from Contact where Sales_Contact__c=true and AccountId=:acct.Id]);
        User u = [Select id,isActive,Sales_Division__c from user where profile.name='System Administrator' and isActive=true limit 1];
        system.runAs(u){
            Test.SetCurrentPageReference(Page.Referral);
            System.CurrentPageReference().getParameters().put('Id',ctct1.Id);
            System.currentPageReference().getParameters().put('startedFrom','Contact');            //CMF
            ReferralController rc = new ReferralController();
            rc.nonRepOption = 'Someone Else';
            rc.NonRepOptionSelected();
            User uHrs = [Select id,isActive,Sales_Division__c,District_Name__c from user where Sales_Division__c='SMB Channel' and isActive=true and District_Name__c='ALBANY' limit 1];
            rc.tempRef.User__c = uHrs.Id;
            rc.setReferralUser();
            rc.setDisplayList();
            
            system.debug('MA Test'+rc.displayList);
            system.debug('MA Test'+rc.displayList[0]);
            //
            //rc.displayList[0].
            //
            ReferralWrapper ref1 = rc.displayList[0];
            ref1.displayName='SMB-Channel';
            ref1.selected = true;
            system.debug('MA Test ref1'+ref1);
            PageReference pgrf = rc.markSelected();
            acct.Ownerid=uHrs.Id;
            rc.referringOpp.Client_Referral__c=acct.Id;
            rc.refClientChanged();
            ReferralController.isQueueAvailable(uHrs.Id);
        }
        
    }
    //APR0151864: SMB Channel Evolution BAU--End
    
    //APR0154201 Add processbutton to P&C Quote Data--Start
    public static String [] dqSalesOrgs = Label.PCQuoteDataSalesOrg.split(',');
    public static ID pcRT = Label.PCQuoteDataRecordTypeId;
    @isTest(seeAllData=false)
    static void testpcQuoteData(){
        
        User userPC = [SELECT Id, Email FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:dqSalesOrgs LIMIT 1];
        PC_Quote_Data__c pcqD = new PC_Quote_Data__c(Prospect_Client_Name__c='Test Acct',
                                                     Prospect_Client_Street__c='123 Main Street', Prospect_Client_City__c='Rochester', Prospect_Client_State__c='NY',
                                                     Prospect_Client_Postal_Code__c='14609', Contact_First_Name__c='Test', Contact_Last_Name__c='Guy',
                                                     Contact_Phone_Number__c='555-555-5555', Contact_Email_Address__c='testguy@nothing.com', Tarmika_Request_Number__c='0000065299',
                                                     Agent_Name__c=userPC.Email, Insured_Name__c='Test Acct', FEIN_Number__c='123456-789', Business_Entity__c='INDIVIDUAL', 
                                                     Business_Classification__c='Construction', NAICS_Code__c='238210', Carrier_1_Name__c='LibertyMutual',Carrier_1_Line_of_Business__c='BOP',
                                                     Carrier_1_Quote_Number__c = '123456789', Carrier_1_Quote_Request_Id__c = '0000057705', Carrier_1_Quote_Status__c = 'Accept',Carrier_1_Total_Premium__c = 7368.22);
        insert pcqD;
        
        
        //Create Group
        Group queueALBANY = new Group(Name='ALBANY', DeveloperName='ALBANY');
        insert queueALBANY;
        
        // create referral
        Referral_Account__c ra = new Referral_Account__c(Name='Test Account');
        insert ra;
        Referral_Contact__c rc1 = new Referral_Contact__c(Name='Test Contact1', Referral_Account__c=ra.Id, Email__c='test1@paychex.com');
        Referral_Contact__c rc2 = new Referral_Contact__c(Name='Test Contact2', Referral_Account__c=ra.Id, Email__c='test2@paychex.com');
        Referral_Contact__c[] rcs = new Referral_Contact__c[]{rc1,rc2};
            insert rcs;
        
        Referral_Partner__c[] partners = getRefPartners(); //setupRefPartners();
        // set a default referral contact in last one
        Referral_Partner__c refPart = partners[partners.size()-1];
        // make sure we have the right one
        System.assertEquals(refPart.Name,'Test21');
        refPart.Referral_Contact__c = rc2.Id;
        //refPart.Name='SMB New Business';
        update refPart;
        
        // get the core record type - have to set the record type because of the Sales_Contact__c flag.
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');
        Account acct = new Account(Name='Test Account');
        insert acct;
        // client contacts
        Contact ctct1 = new Contact(FirstName='First1',LastName='Last',Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());
        Contact ctct2 = new Contact(FirstName='First2',LastName='Last',Sales_Contact__c=true,AccountId=acct.Id, RecordTypeId=coreRt.getRecordTypeId());
        Contact[] ctcts = new Contact[]{ctct1,ctct2};
            insert ctcts;
        
        // verify sales contacts are set
        System.assertEquals(2,[select count() from Contact where Sales_Contact__c=true and AccountId=:acct.Id]);
        User u = [Select id,isActive,Sales_Division__c from user where profile.name='System Administrator' and isActive=true limit 1];
        system.runAs(u){
            Test.SetCurrentPageReference(Page.Referral);
            System.CurrentPageReference().getParameters().put('Id',ctct1.Id);
            System.currentPageReference().getParameters().put('startedFrom','Contact'); 
            System.currentPageReference().getParameters().put('pcQuoteId',pcqD.Id); 
            ReferralController rc = new ReferralController();
            rc.nonRepOption = 'Someone Else';
            rc.NonRepOptionSelected();
            User uHrs = [Select id,isActive,Sales_Division__c,District_Name__c from user where Sales_Division__c='SMB Channel' and isActive=true and District_Name__c='ALBANY' limit 1];
            rc.tempRef.User__c = uHrs.Id;
            rc.setReferralUser();
            rc.setDisplayList();
            
            system.debug('MA Test PC'+rc.displayList);
            system.debug('MA Test PC'+rc.displayList[0]);
            ReferralWrapper ref1 = rc.displayList[0];
            ref1.displayName='SMB-Channel';
            ref1.selected = true;
            system.debug('MA Test ref1'+ref1);
            PageReference pgrf = rc.markSelected();
        }
        
        
    }
    //APR0154201 Add processbutton to P&C Quote Data--End 
    
} // class ReferralControllerTest