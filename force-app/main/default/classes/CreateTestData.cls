/*
 * class to create basic test data to be used anywhere
 * feel free to add fields you need but be careful removing any data as it may cause problems with other test classes
 * History
 * -------
 * 03/20/2013   Cindy Freeman   create
   08/28/2013   Dan Carmen      Set as @isTest so it doesn't apply to code count.
   10/07/2013   Cindy Freeman  added methods for testing MMS onboarding
   03/11/2016   Dan Carmen      keep created test data as static variables
   10/16/2017   Dan Carmen      Update call for paychex company
   12/04/2017   Cindy Freeman modifed cretaeTestPEOOpptys for new record type name
   12/07/2017  Jermaine Stukes Added method for Cases
   02/06/2018   Dan Carmen      Adjustments for paychex contact logic.
   05/19/2021   Dan Carmen      Updated to use labels for StageName
   07/21/2022   Dan Carmen      Updated createTestAandC method
   05/16/2023   Eric Porter     Removed References to Primary_Competition__c

*/
 @isTest
public class CreateTestData {

   public static Lead ld1=null;
   public static Lead ld2=null;
   public static Lead ld3=null;
   
   // create just 1 test lead
   public static Id createTestLead() {
      Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
      
      ld1 = new Lead(Firstname = 'First'
                        ,Lastname = 'Last Lead1'
                        ,Company = 'Test Lead Company1'
                        ,recordtypeId = leadCorert.getRecordTypeId()
                        ,DataFlux_Id__c = null
                                ,LeadGroupId__c = null);
      insert ld1;
      
      return ld1.Id;                            
   } // createTestLead

   /* create multiple Leads returning just their Ids
   */
   public static List<Id> createTestLeadMany() {
      Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
      List<Lead> insertLeadList = new List<Lead>();
        ld1 = new Lead(Firstname = 'Mary'
                                ,Lastname = 'Lead1'
                                ,Company = 'Test Account11'
                                ,recordtypeId = leadCorert.getRecordTypeId()
                                ,Phone = '555-3333'
                                ,Email = 'mary@account11.com'
                                ,Street = '10 Main St'
                                ,City = 'Rochester'
                                ,State = 'NY'
                                ,PostalCode = '10000'
                                ,NSS_Prospect_ID__c = '12345'
                                ,DataFlux_Id__c = null
                                ,LeadGroupId__c = null);
        insertLeadList.add(ld1);
        ld2 = new Lead(Firstname = 'John'
                                ,Lastname = 'Lead2'
                                ,Company = 'Test Account22'
                                ,recordtypeId = leadCorert.getRecordTypeId()
                                ,Phone = '555-4444'
                                ,Email = 'john@account22.com'
                                ,Street = '20 Maple Ave'
                                ,City = 'Rochester'
                                ,State = 'NY'
                                ,PostalCode = '10101'
                                ,NSS_Prospect_ID__c = '54321'
                                ,DataFlux_Id__c = null
                                ,LeadGroupId__c = null);
        insertLeadList.add(ld2);
        ld3 = new Lead(Firstname = 'Tommy'
                                ,Lastname = 'Lead3'
                                ,Company = 'Test Account33'
                                ,recordtypeId = leadCorert.getRecordTypeId()
                                ,Phone = '555-5656'
                                ,Email = 'tom@account33.com'
                                ,Street = '313 Brookline Dr'
                                ,City = 'Rochester'
                                ,State = 'NY'
                                ,PostalCode = '10101'
                                ,NSS_Prospect_ID__c = '54321'
                                ,DataFlux_Id__c = null
                                ,LeadGroupId__c = null);
        insertLeadList.add(ld3);
        insert insertLeadList;                
        List<Id> leadIds = new List<Id>();
        for (Lead l: insertLeadList)
        {   leadIds.add(l.Id);   }
        return leadIds;
        
   } // createTestLeadMany
        
   // so we only have to change the record type in one place.
   public static Schema.RecordTypeInfo defaultSalesContactRT = null;
   public static Schema.RecordTypeInfo getDefaultSalesContactRT() {
      if (defaultSalesContactRT == null) {
         // todo - this will have to be changed to the new record type when we get it.
         defaultSalesContactRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
      }
      return defaultSalesContactRT;
   } // getDefaultSalesContactRT
    
   public static Schema.RecordTypeInfo defaultProspectAcctRT = null;
   public static Schema.RecordTypeInfo getDefaultProspectAcctRT() {
      if (defaultProspectAcctRT == null) {
         // todo - this will have to be changed to the new record type when we get it.
         defaultProspectAcctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
      }
      return defaultProspectAcctRT;
   } // getDefaultProspectAcctRT
   
    public static void createTestAandC () {
        Schema.RecordTypeInfo acctCorert = getDefaultProspectAcctRT();
        Schema.RecordTypeInfo ctctCorert = getDefaultSalesContactRT();
        
        acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        acct2 = new Account (name = 'Test Account2'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '99-7654321'
                                ,ParentId = acct1.Id
                                ,Do_Not_Call__c = false
                                ,Email_Opt_Out__c = false
                                ,AnnualRevenue = 25);
        acct3 = new Account (name = 'Test Prospect1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Prospect'
                                ,BillingPostalCode = '10000');
        Account[] accts = new Account[]{acct1,acct2,acct3};
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert accts;
        ZipCheckOwner.SKIP_TRIGGERS=false;
        
        ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
        ctct1a = new Contact(Firstname = 'Second'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-2323'
                                ,Email = 'sLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
 
        ctct2 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last4'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast4@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct2.Id);
        
        ctct3 = new Contact(Firstname = 'First'
                                ,Lastname = 'Prospect1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fProspect1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct3.Id);
        Contact[] ctcts = new Contact[]{ctct1,ctct1a,ctct2,ctct3};
        ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
        ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
        insert ctcts;
        ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
        ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
        
        acct1.SignificantContact__c = ctct1.Id;
        acct2.SignificantContact__c = ctct2.Id;
        acct3.SignificantContact__c = ctct3.id;
        update accts;
        
        Asset asst1 = new Asset(Name='Asset1',AccountId=acct1.Id,Product_Plan_Code__c='Test1', Bundle_Code__c='Test');
        Asset asst2 = new Asset(Name='Asset2',AccountId=acct1.Id,Product_Plan_Code__c='Test2');
        Asset asst3 = new Asset(Name='Asset3',AccountId=acct2.Id,Product_Plan_Code__c='Test3');
        Asset[] assts = new Asset[]{asst1,asst2,asst3};
        insert assts;
 
    } // createTestAandC
    
    public static Account getTestAcct1() {
       if (acct1 == null) {
          acct1= getTestAcct('Test Account1');
       }
       return acct1;
    } // getTestAcct1
    
    public static Account getTestAcct2() {
       if (acct2 == null) {
          acct2= getTestAcct('Test Account2');
       }
       return acct2;
    } // getTestAcct2
    
    public static Account getTestAcct(String acctName) {
       Account acct = null;
       try {
            acct = [Select Id, name,OwnerId,recordtypeId,type,AccountNumber
                                   ,NumberOfEmployees,Frequency__c,Current_Prior_Method__c
                                   ,ShippingStreet,BillingStreet,ShippingCity,BillingCity,ShippingState,BillingState
                                   ,ShippingPostalCode,BillingPostalCode
                                   ,ParentId,Do_Not_Call__c,Email_Opt_Out__c,AnnualRevenue
                                   ,SignificantContact__c
                            ,(Select Id, OwnerId, Firstname,Lastname,recordtypeId,Phone,Email
                                    ,DoNotCall,HasOptedOutOfEmail,AccountId 
                                From Contacts)
                        from Account
                       Where Name=:acctName
                       limit 1];
          System.debug('getTestAcct acct='+acct.Name+' contacts='+acct.Contacts.size());
       } catch (Exception e) {}
       return acct;
    } // getTestAcct

    public static Account acct1=null;
    public static Account acct2=null;
    public static Account acct3=null;
    
    public static Contact ctct1=null;
    public static Contact ctct1a=null;
    public static Contact ctct2=null;
    public static Contact ctct3=null;

    public static void createSingleAandTwoCtsNoTrigs() {
      ZipCheckOwner.SKIP_TRIGGERS=true;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      createSingleAandTwoCts();
    } // createSingleAandTwoCtsNoTrigs

    public static void createSingleAandTwoCts () {
        Schema.RecordTypeInfo acctCorert = getDefaultProspectAcctRT();
        Schema.RecordTypeInfo ctctCorert = getDefaultSalesContactRT();
        
        acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = false
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = false
                                ,AnnualRevenue = 25);
        insert acct1;
        ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
        ctct1a = new Contact(Firstname = 'Second'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-2323'
                                ,Email = 'sLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
        Contact[] ctcts = new Contact[]{ctct1,ctct1a};
        insert ctcts;
        acct1 = null;
        acct1 = getTestAcct1();
    } // createSingleAand2Cts

    public static void createReferralAandC () {
        
        Schema.RecordTypeInfo hrsRefAcctRt = RecordTypeHelper.getRecordType('HRS Referral Source Record Type', ObjectHelper.OBJECT_REF_ACCOUNT);
        Schema.RecordTypeInfo hrsRefCtctRt = RecordTypeHelper.getRecordType('HRS Referral Record Type', ObjectHelper.OBJECT_REF_CONTACT);
         
        Referral_Account__c refacct1 = new Referral_Account__c (name = 'Referral Account1'
                                ,RecordTypeId=hrsRefAcctRt.getRecordTypeId()
                                ,Referral_Type__c = 'Broker'
                                ,Zip_Postal_Code__c = '10000');
        insert refacct1;
        // use the Name field for the Referral_Contact__c - a trigger will parse out to first and last name fields.
        Referral_Contact__c refcon1 = new Referral_Contact__c(Name = 'First Ref Ctct1'
                                ,RecordTypeId=hrsRefCtctRt.getRecordTypeId()
                                ,Phone__c = '585-555-1212'
                                ,Email__c = 'fLast1@abc.com'
                                ,Referral_Type__c = '100 Broker'
                                ,Referral_Account__c = refacct1.Id);
        insert refcon1;
        
    } // createReferralAandC
    
    public static void createAccountandCases()
    {
      Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '11-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        Contact con1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
        insert con1;

        Schema.RecordTypeInfo hrsRT = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Case case1 = new Case (recordtypeId = hrsRT.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.valueOf('2015-10-01 00:00:00') 
                               ,Product__c = '401K'
                               ,contactId = con1.Id);
        Case case2 = new Case (recordtypeId = hrsRT.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.valueOf('2016-10-01 00:00:00') 
                               ,Product__c = '401K'
                               ,contactId = con1.Id);
        Case case3 = new Case (recordtypeId = hrsRT.getRecordTypeId()
                               ,status = 'Closed'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.valueOf('2017-10-01 00:00:00') 
                               ,ClosedDate = dateTime.valueOf('2017-10-18 00:00:00') 
                               ,Product__c = '401K'
                               ,contactId = con1.Id);
        Case case4 = new Case (recordtypeId = hrsRT.getRecordTypeId()
                               ,status = 'Closed'
                               ,CreatedDate = dateTime.valueOf('2017-10-01 00:00:00') 
                               ,ClosedDate = dateTime.valueOf('2017-10-30 00:00:00') 
                               ,origin = 'Email'
                               ,Product__c = '401K'
                               ,contactId = con1.Id);
        Case case5 = new Case (recordtypeId = hrsRT.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.valueOf('2015-10-01 00:00:00') 
                               ,Product__c = '401K'
                               ,contactId = con1.Id);
        Case[] caseList = new Case[]{case1,case2,case3,case4,case5};
        insert caseList;                        
    }//createAccountandCases
    public static Opportunity oppty1;
    public static OpportunityContactRole ocr1;

    public static Id createTestCoreOptys (ID acctId, ID ctctId) {
        
        // create a core opportunity
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,ObjectHelper.OBJECT_OPPTY);
        oppty1 = new Opportunity(Name='Test Core Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acctId
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
        insert oppty1;                                                 
        ocr1 = new OpportunityContactRole(ContactId=ctctId, OpportunityId=oppty1.Id, IsPrimary=true);
        insert ocr1;
        
        return oppty1.Id;
    
    } // createTestOptys

    
    public static ID createTestCoreSoldOptys (ID acctId, ID ctctId) {
        
        // create a core opportunity and update it to Sold status
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,ObjectHelper.OBJECT_OPPTY);
        oppty1 = new Opportunity(Name='Test Core Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=acctId
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
        insert oppty1;                                                 
        ocr1 = new OpportunityContactRole(ContactId=ctctId, OpportunityId=oppty1.Id, IsPrimary=true);
        insert ocr1;
        
        oppty1.TotalOpportunityQuantity = 1;
        oppty1.Employees_Paid_Per_Payroll__c = 2;
        oppty1.Frequency__c = '1';
        oppty1.Amount = 100;
        oppty1.StageName = 'Sold';
        oppty1.Service_Location__c = 'Foxboro Branch 0008';
        oppty1.Prod_Payroll__c = true;

        update oppty1;
        
        return oppty1.Id;
                
    } // createTestOptys

   public static ID createTestPEOOptys (ID acctId, ID ctctID) {
      
        // create a PEO opportunity
        Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,ObjectHelper.OBJECT_OPPTY);
        if (peoOpptyRt == null)
        {   peoOpptyRt = RecordTypeHelper.getRecordType('PEO Opportunity Record Type',ObjectHelper.OBJECT_OPPTY); }
        oppty1 = new Opportunity(Name='Test Acccount1 PEO Opporty', RecordTypeId=peoOpptyRt.getRecordTypeId()
                               ,AccountId=acctId
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
      insert oppty1;
      ocr1 = new OpportunityContactRole(ContactId=ctctId, OpportunityId=oppty1.Id, IsPrimary=true);
      insert ocr1;
      
      return oppty1.Id;    
   } // createTestPEOOptys

    public static ID createTestPEOSoldOptys (ID acctId, ID ctctID) {
        
        // create a PEO opportunity and update it to SOld
        Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,ObjectHelper.OBJECT_OPPTY);
        if (peoOpptyRt == null)        
        {   peoOpptyRt = RecordTypeHelper.getRecordType('PEO Opportunity Record Type',ObjectHelper.OBJECT_OPPTY); }
        oppty1 = new Opportunity(Name='Test Acccount1 PEO Opporty', RecordTypeId=peoOpptyRt.getRecordTypeId()
                                         ,AccountId=acctId
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
        insert oppty1;
        ocr1 = new OpportunityContactRole(ContactId=ctctId, OpportunityId=oppty1.Id, IsPrimary=true);
        insert ocr1;
        
        
        oppty1.StageName = 'Sold';
        oppty1.Service_Location__c = OpportunityCreateCase.PEO_SERVICE_CENTER;
        update oppty1;
        
        return oppty1.Id;
        
    } // createTestPEOOptys
    
   public static ID createTestMMSSoldOptys (ID acctId, ID ctctId) {
      
      // create a mms opportunity with Sold status
        Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,ObjectHelper.OBJECT_OPPTY);
        oppty1 = new Opportunity(Name='Test MMS Opporty', RecordTypeId=mmsOpptyRt.getRecordTypeId(),AccountId=acctId
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId()
                                         ,LeadSource = 'Cold Call'
                                         ,Payroll_Current_Prior_Method__c = 'ADP');
                                         //,Primary_Competition__c = 'ADP Payforce');
      insert oppty1;                                                 
      ocr1 = new OpportunityContactRole(ContactId=ctctId, OpportunityId=oppty1.Id, IsPrimary=true);
      insert ocr1;
      
      oppty1.TotalOpportunityQuantity = 1;
      oppty1.Employees_Paid_Per_Payroll__c = 2;
      oppty1.Frequency__c = '1';
      oppty1.Payroll_Units__c = 5;
      oppty1.Amount = 100;
      oppty1.StageName = Label.OppStage_Sold;
      oppty1.Service_Location__c = 'Albany Hub 415';
      oppty1.Prod_Payroll__c = true;
      oppty1.Product_Summary__c = 'Payroll;TaxPay;';

      update oppty1;
      
      return oppty1.Id;
            
   } // createMMSSoldOptys
 
    public static void closeCoreCase (ID kaseId) {
        Case kase = [Select Id, Status from Case where Id = :kaseId];
        kase.Status = 'Completed';
        update kase;
        
    } // closeCoreCase
    
    public static void closePEOCase (ID kaseId) {
        Case kase = [Select Id, Status from Case where Id = :kaseId];
        kase.Status = 'Solved';
        update kase;
        
    } // closePEOCase
 
   public static Account createPaychexEmp () {
        ContactFormatPaychexEmpsTest.checkSetupData();
        Schema.RecordTypeInfo ctctSArt = RecordTypeHelper.getRecordType('Paychex Employee', ObjectHelper.OBJECT_CONTACT);
        
        acct1 = ContactFormatPaychexEmps.getParentAcct();
        
        Contact con1 = new Contact(Firstname = 'Joe'
                                ,Lastname = 'Paychex'
                                ,recordtypeId = ctctSArt.getRecordTypeId()
                                ,HR_Person_Id__c = '123456'
                                ,Email = 'joe@paychex.com'
                                ,AccountId=acct1.Id);
        insert con1;
        
        Account payEmp = [select Id, Name, (select Id, Name, Email from Contacts) from Account where Name = :UserHelper.PAYCHEX_COMP limit 1];
        //Account payEmp = [select Id, Name, (select Id, Name, Email from Contacts) from Account where Id in (Select AccountId from Contact where Email='joe@paychex.com')];
      return payEmp;
       
   } // createPaychexEmp
   
   public static Object_Relationships__c createRelatedObjectsCase () {
     //Group goodQ = [Select Id, Name, Type from Group where Type = 'Queue' limit 1];
       // insert Object relationship Case to Reference MMS
      Object_Relationships__c temporc1 = new Object_Relationships__c(Primary_Object_API_name__c = 'Case'
                                    , Primary_Object_Rcd_Type__c = 'Service Onboarding MMS Payroll Case'
                                    , Related_Object_API_name__c = 'Reference_MMS_Payroll__c'
                                    , Related_Object_Rcd_Type__c = 'Reference Onboarding MMS Payroll'
                                    , IsActive__c = true);
      insert temporc1;
      Object_Relationships__c orc1 = [Select Id, Primary_Object_API_name__c, Primary_Object_Rcd_Type__c, Primary_Object_Rcd_Type_Id__c,
                      Related_Object_API_name__c, Related_Object_Rcd_Type__c, Related_Object_Rcd_Type_Id__c
                      from Object_Relationships__c where Id = :temporc1.Id];
                      
    Object_Relationships_Fields__c orf1 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                              , Primary_Field_API_name__c = 'Id'
                              , Related_Field_API_name__c = 'Case_Number__c');
      insert orf1;
      Object_Relationships_Fields__c orf2 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                              , Primary_Field_API_name__c = 'OwnerId'
                              , Related_Field_API_name__c = 'OwnerId');
      insert orf2;
      
      
      Object_Relationships__c newRel = [Select Primary_Object_API_name__c, Related_Object_API_name__c, 
                        (Select Id, Primary_Field_API_name__c, Related_Field_API_name__c 
                         from Object_Relationships_Fields__r )                         
                        from Object_Relationships__c
                        where Id = :orc1.Id];
      return newRel;
      
    } // createRelatedObjectsCase
} // CreateTestData