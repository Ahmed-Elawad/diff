/**
 * Test method Marketing Call Tracking methods
 * 
 * History
 * --------
 * 12/15/2016   Cindy Freeman   created
 * 02/07/2017   Cindy Freeman   added tests for new webform fields using mapping custom setting
 * 02/27/2017   Cindy Freeman   added tests for new Dialog Tech fields and functionality
   09/25/2017 Dan Carmen            Added handling for number fields
   01/15/2018  Cindy Freeman  modified to test for only Uppercase MarketingCallTracking_Mapping settings
   03/09/2018 Dan Carmen            Changes to account for Marketo vs Lead Loader descriptions
   06/21/2018 Rick Segura(DemandGen, Inc)  Added UnitTest 3-6 for Lead/Contact Product of Interest value update
   12/07/2018 Dan Carmen        Replace qbdialer__Call_Date_Time__c with CallDateTime__c
   11/04/2019 Dan Carmen            Remove reference to all ISDC fields
   12/29/2019 Cindy Freeman      added new test for matching MCT to Partner Referral and updating MCT
   11/30/2023 Dan Carmen            Remove unused Round Robin fields
   01/29/2024 Pujitha Madamanchi   added test for XeroId and PR link on MCT when createdby Marketo webhook
   06/10/2024 Pujitha Madamanchi    Set Status to Match Found when PR is found

 */
   
@isTest
public class MarketTrackingMethodsTest {

  @testSetup 
  static void setupTestData(){
    
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerSetup__c trigSetup1 = TriggerMethodsTest.createCustomSetting(null, 'LeadBefore', true, false, new String[]{'TrackRecordEntry'},setupClasses);
      TriggerSetup__c trigSetup2 = TriggerMethodsTest.createCustomSetting(null, 'LeadAfter', false, true, new String[]{'TrackRecordEntry'},setupClasses);

      TriggerSetup__c trigSetup3 = TriggerMethodsTest.createCustomSetting(null, 'ContactBefore', true, false, new String[]{'TrackRecordEntry'},setupClasses);
      TriggerSetup__c trigSetup4 = TriggerMethodsTest.createCustomSetting(null, 'ContactAfter', false, true, new String[]{'TrackRecordEntry'},setupClasses);
      insert setupClasses;

    // populate custom settings
    LeadLoaderConfig__c llc = new LeadLoaderConfig__c(Name='WEBLEAD',IsActive__c=true,CreateTracking__c=true, StoreOrginalData__c=true);   //IsNSSOwnership__c=true,LogWebleadFields__c=true,
                              //NSSSource__c='Inbound',QueueName__c='NSS Inbound Queue',WebServiceName__c='Lead Loader-WebLeads');
    insert llc;                                                                       
    ProcessNameMap__c pnm = new ProcessNameMap__c(Name='LL-Lead Loader',IsActive__c=true);
    insert pnm;

      List<MarketingCallTracking_Mapping__c> mctMapList = new List<MarketingCallTracking_Mapping__c>();
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='gclid',api_field_name__c='gclid__c'));                                        
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='GCLID',api_field_name__c='gclid__c'));                                        
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='adposition',api_field_name__c='webform_adposition__c'));                                        
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='ADPOSITION',api_field_name__c='webform_adposition__c'));                                        
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='keyword',api_field_name__c='keywords__c'));                                        
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='KEYWORD',api_field_name__c='keywords__c'));                                        
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='mm_campaign',api_field_name__c='webform_mm_campaign__c'));                                        
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='MM_CAMPAIGN',api_field_name__c='webform_mm_campaign__c'));                                                                              
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='Pricing',api_field_name__c='Pricing__c', FieldType__c=MarketTrackingMethods.TYPE_NUMBER));                                        
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='PRICING',api_field_name__c='Pricing__c', FieldType__c=MarketTrackingMethods.TYPE_NUMBER));                                        
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='UPPERCUSTOM3',api_field_name__c='MM_Custom3__c', FieldType__c=MarketTrackingMethods.TYPE_NUMBER)); 
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='salesPref_Payroll',api_field_name__c='ProdPayroll__c', FieldType__c=MarketTrackingMethods.TYPE_BOOLEAN));                                        
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='salesPref_HRServices',api_field_name__c='ProdHRServices__c', FieldType__c=MarketTrackingMethods.TYPE_BOOLEAN));                                        
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='SALESPREF_ACCOUNTINGLOANSPAYMENTS',api_field_name__c='ProdAccountingLoansPayments__c', FieldType__c=MarketTrackingMethods.TYPE_BOOLEAN, Field_Value__c='Accounting Loans Payments', Source__c='MCT')); 
      mctMapList.add(new MarketingCallTracking_Mapping__c(Name='SALESPREF_BUSINESSINSURANCE',api_field_name__c='ProdBusinessInsurance__c', FieldType__c=MarketTrackingMethods.TYPE_BOOLEAN, Field_Value__c='Business Insurance', Source__c='MCT')); 
    mctMapList.add(new MarketingCallTracking_Mapping__c(Name='SALESPREF_EMPLOYEEBENEFITS',api_field_name__c='ProdEmployeeBenefits__c', FieldType__c=MarketTrackingMethods.TYPE_BOOLEAN, Field_Value__c='Employee Benefits', Source__c='MCT')); 
    mctMapList.add(new MarketingCallTracking_Mapping__c(Name='SALESPREF_HIRINGONBOARDING',api_field_name__c='ProdHiringOnboarding__c', FieldType__c=MarketTrackingMethods.TYPE_BOOLEAN, Field_Value__c='Hiring Onboarding', Source__c='MCT')); 
    mctMapList.add(new MarketingCallTracking_Mapping__c(Name='SALESPREF_HRSERVICES',api_field_name__c='ProdHRServices__c', FieldType__c=MarketTrackingMethods.TYPE_BOOLEAN, Field_Value__c='HR Services', Source__c='MCT')); 
    mctMapList.add(new MarketingCallTracking_Mapping__c(Name='SALESPREF_PAYROLL',api_field_name__c='ProdPayroll__c', FieldType__c=MarketTrackingMethods.TYPE_BOOLEAN, Field_Value__c='Payroll', Source__c='MCT')); 
    mctMapList.add(new MarketingCallTracking_Mapping__c(Name='SALESPREF_PEO',api_field_name__c='ProdPEO__c', FieldType__c=MarketTrackingMethods.TYPE_BOOLEAN, Field_Value__c='PEO', Source__c='MCT')); 
    mctMapList.add(new MarketingCallTracking_Mapping__c(Name='SALESPREF_STARTUPSERVICES',api_field_name__c='ProdStartupServices__c', FieldType__c=MarketTrackingMethods.TYPE_BOOLEAN, Field_Value__c='Startup Services', Source__c='MCT')); 
    mctMapList.add(new MarketingCallTracking_Mapping__c(Name='SALESPREF_TIMEATTENDANCE',api_field_name__c='ProdTimeAttendance__c', FieldType__c=MarketTrackingMethods.TYPE_BOOLEAN, Field_Value__c='Time Attendance', Source__c='MCT')); 
        
                                              
      upsert mctMapList;
        

    User runUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' limit 1];
      System.runAs(runUser) {
           // create assignment group  
      Group grp1 = new Group(Name='RoundRobinTest Case Queue',Type='Queue');
        // this queue will not be associated with an assignment group
        Group grp2 = new Group(Name='RoundRobinTest Case Queue 2',Type='Queue');
        // this queue will be for leads
        Group grp3 = new Group(Name='RoundRobinTest Lead Queue',Type='Queue');
        
        Group grp4 = new Group(Name='RoundRobinTest Contact Queue',Type='Queue');
        Group grp5 = new Group(Name='RoundRobinTest Contact Off Queue',Type='Queue');
        Group grp6 = new Group(Name='RoundRobinTest Night/Weekend Queue',Type='Queue');
        
        Group grp7 = new Group(Name='RoundRobinTest Event Queue',Type='Queue');
        
        Group grp8 = new Group(Name='Virtual Sales Queue',Type='Queue');
        
        Group grp9 = new Group(Name='RoundRobinTest Oppty Queue',Type='Queue');
        Group[] grps = new Group[]{grp1,grp2,grp3,grp4,grp5,grp6,grp7,grp8,grp9};
        insert grps;
        
        // associate the queues with the objects
        QueueSobject[] qSobjects = new QueueSobject[]{};
        qSobjects.add(new QueueSobject(QueueId=grp1.Id,SobjectType='Case'));
        qSobjects.add(new QueueSobject(QueueId=grp2.Id,SobjectType='Case'));
        qSobjects.add(new QueueSobject(QueueId=grp3.Id,SobjectType='Lead'));
        qSobjects.add(new QueueSobject(QueueId=grp4.Id,SobjectType='Lead')); //SobjectType doesn't matter because nothing actually gets stored in the queue.
        qSobjects.add(new QueueSobject(QueueId=grp5.Id,SobjectType='Lead')); //SobjectType doesn't matter because nothing actually gets stored in the queue.
        qSobjects.add(new QueueSobject(QueueId=grp6.Id,SobjectType='Lead')); //SobjectType doesn't matter because nothing actually gets stored in the queue.
        qSobjects.add(new QueueSobject(QueueId=grp7.Id,SobjectType='Lead')); //SobjectType doesn't matter because nothing actually gets stored in the queue.
        qSobjects.add(new QueueSobject(QueueId=grp8.Id,SobjectType='Lead'));
        qSobjects.add(new QueueSobject(QueueId=grp9.Id,SobjectType='Lead')); //SobjectType doesn't matter because nothing actually gets stored in the queue.
        insert qSobjects;
        
        insert new BypassNSS__c(SetupOwnerId=UserInfo.getOrganizationId(), IsActive__c=true,Queue_Id__c=grp8.Id,Queue_Name__c=grp8.Name,Partner_Referral_Expiration_Duration__c=1,Holdout_Expiration__c=1);
        

         Assignment_Group_Name__c cagn = new Assignment_Group_Name__c(Name='RoundRobinTest Case Queue');
         Assignment_Group_Name__c lagn = new Assignment_Group_Name__c(Name='RoundRobinTest Lead Queue');
         Assignment_Group_Name__c coagn = new Assignment_Group_Name__c(Name='RoundRobinTest Contact Queue'); 
         Assignment_Group_Name__c cooagn = new Assignment_Group_Name__c(Name='RoundRobinTest Contact Off Queue');
         Assignment_Group_Name__c nwagn = new Assignment_Group_Name__c(Name='RoundRobinTest Night/Weekend Queue');
         Assignment_Group_Name__c eagn = new Assignment_Group_Name__c(Name='RoundRobinTest Event Queue');
         Assignment_Group_Name__c oagn = new Assignment_Group_Name__c(Name='RoundRobinTest Oppty Queue');
         Assignment_Group_Name__c[] agns = new Assignment_Group_Name__c[]{cagn,lagn,coagn,cooagn,nwagn,eagn,oagn};
         insert agns; 

         // insert a Queue record
         Assignment_Group_Queues__c cagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=cagn.Id, Name='RoundRobinTest Case Queue');
         Assignment_Group_Queues__c lagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=lagn.Id, Name='RoundRobinTest Lead Queue');
         Assignment_Group_Queues__c coagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=coagn.Id, Name='RoundRobinTest Contact Queue');
         Assignment_Group_Queues__c cooagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=cooagn.Id, Name='RoundRobinTest Contact Off Queue');
         Assignment_Group_Queues__c nwagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=nwagn.Id, Name='RoundRobinTest Night/Weekend Queue');
         Assignment_Group_Queues__c eagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=eagn.Id, Name='RoundRobinTest Event Queue');
         Assignment_Group_Queues__c oagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=oagn.Id, Name='RoundRobinTest Oppty Queue');
         Assignment_Group_Queues__c[] agqs = new Assignment_Group_Queues__c[]{cagq,lagq,coagq,cooagq,nwagq,eagq,oagq}; 
         insert agqs;
         
         // select users
         User[] users = [Select Id, Name from User where Profile.Name='System Administrator' 
                                                  and IsActive=true
                                                  and Assignment_Group_Active__c=true
                                                  and Id != :runUser.Id 
                                                  limit 3];
         system.debug('testUsers: '+users);
         DateTime rightNow = DateTime.now();
       
         // add as group members 
         Assignment_Groups__c[] ags = new Assignment_Groups__c[]{};
         Integer millisecond = 1;
         Integer skillSet = 1;
         for (User u : users) {
            Assignment_Groups__c cag = new Assignment_Groups__c(Active__c='True',Group_Name__c=cagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(cag);
            Assignment_Groups__c lag = new Assignment_Groups__c(Active__c='True',Group_Name__c=lagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(lag);
            Assignment_Groups__c coag = new Assignment_Groups__c(Active__c='True',Group_Name__c=coagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(coag);
            Assignment_Groups__c cooag = new Assignment_Groups__c(Active__c='True',Group_Name__c=cooagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(cooag);
            Assignment_Groups__c nwag = new Assignment_Groups__c(Active__c='True',Group_Name__c=nwagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(nwag);
            Assignment_Groups__c eag = new Assignment_Groups__c(Active__c='True',Group_Name__c=eagn.Id,User__c=u.Id, Millisecond__c=millisecond++,Skill_Set__c = 'Level '+skillSet);
             if(skillSet == 3){
               skillSet = 0;
             }
             skillSet++;
            ags.add(eag);
            Assignment_Groups__c oag = new Assignment_Groups__c(Active__c='True',Group_Name__c=oagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(oag);
         }
         insert ags;
      } // runAs
  } // setupTestData  

   static testMethod void myUnitTest1() {
  
    User leadLdrUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Name='Lead Loader' and IsActive=true and HR_Person_Id__c != null limit 1];    
    Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
    
    // populate custom settings
    //LeadLoaderConfig__c llc = new LeadLoaderConfig__c(Name='WEBLEAD',IsActive__c=true,CreateTracking__c=true);   //IsNSSOwnership__c=true,LogWebleadFields__c=true,
    //                          //NSSSource__c='Inbound',QueueName__c='NSS Inbound Queue',WebServiceName__c='Lead Loader-WebLeads');
    //insert llc;                                                                       
    //ProcessNameMap__c pnm = new ProcessNameMap__c(Name='LL-Lead Loader',IsActive__c=true);
    //insert pnm;
      
    
    Boolean ans = MarketTrackingMethods.checkOwnedBy('WEBLEAD');
    System.assertEquals(true, ans);
    
    Test.startTest();
    
    Lead leed;
    System.runAs(leadLdrUser) {
      //Boolean isLeadLoader = UserHelper.isLeadLoader(UserInfo.getName());
      //System.assertEquals(true, isLeadLoader);
      Lead ld1 = new Lead(Firstname = 'First'
                ,Lastname = 'Last Lead1'
                ,Company = 'Test Lead Company1'
                ,recordtypeId = leadCorert.getRecordTypeId()
                ,DataFlux_Id__c = null
                ,LeadGroupId__c = null
                ,OwnedBy__c = 'WEBLEAD'
                ,Products__c = '401K;Advantage Associate Office Leads;HR Services;PEO');
   /*   ld1.description = 'utm_source |^| Google\r';
      ld1.description += 'utm_medium |^| CPC\r'; 
      ld1.description += 'keyword |^| This is a TEST\r'; 
      ld1.description += 'mm_campaign |^| 4EFE303C35B53BB23DAED7ED512D0BF0\r'; 
      ld1.description += 'gclid |^| CJ2uuL277NACFcS4wAodm7ECnQ\r'; 
      ld1.description += 'original_referer |^| http://pages.paychex.com/hcm.html?mm_campaign=4EFE303C35B53BB23DAED7ED512D0BF0&%20keyword=hris%20pay\r'; 
      ld1.description += 'REDIRECT |^|\r'; 
      ld1.description += 'HTTP_REFERER |^|\r'; 
      ld1.description += 'IP_ADDRESS |^| 199.15.215.245\r'; 
      ld1.description += 'BROWSER_TYPE |^| Unknown\r'; 
      ld1.description += 'BROWSER_NAME |^| Unknown\r'; 
      ld1.description += 'BROWSER_VERSION |^| 0.0\r'; 
      ld1.description += 'EMAIL_SUBJECT |^| Paychex Super 8 Web Lead\r'; 
      ld1.description += 'DATESTAMP |^| 20161213104301\r';
      ld1.description += 'salesPref_Payroll |^| 1\r';
      ld1.description += 'salesPref_HRServices |^| \r';
      ld1.description += 'Pricing |^| 1234 \r';
      ld1.description += 'upperCustom3 |^| TESTing \r'; */
        
      insert ld1;              
      leed = ld1;      
   /*   List<Marketing_Call_Tracking__c> mctList = [select Id, Lead__c, Account__c, Contact__c, keywords__c, gclid__c 
                                                        ,ProdPayroll__c, ProdHRServices__c
                                                        ,Pricing__c
                                                      ,MM_Custom3__c
                                                    from Marketing_Call_Tracking__c
                                                   where Lead__c = :ld1.Id]; */
                                                   
      List<PartnerReferral__c> prRecs = [SELECT Id, Lead__c, Contact__c, isDeleted 
                        FROM PartnerReferral__c 
                        WHERE  Lead__c = :ld1.Id];
      system.debug('!!! prRecs.size(): ' + prRecs.size());  
      system.debug('!!! prRecs: ' + prRecs);  
      
      
      
   /*   System.assertEquals(1, mctList.size());
      System.assertEquals('This is a TEST', mctList.get(0).keywords__c);
      System.assertEquals('CJ2uuL277NACFcS4wAodm7ECnQ', mctList.get(0).gclid__c);
      System.assertEquals(true, mctList[0].ProdPayroll__c);
      System.assertEquals(false, mctList[0].ProdHRServices__c);
      System.assertEquals(1234,mctList[0].Pricing__c);
      System.assertEquals('TESTing', mctList[0].MM_Custom3__c); */
      
       Marketing_Call_Tracking__c mct1 = new Marketing_Call_Tracking__c(Lead__c = ld1.Id, Source__c = 'WEBLEAD', keywords__c='This is a TEST'
                                                                        ,gclid__c ='CJ2uuL277NACFcS4wAodm7ECnQ', Xero_Id__c='Test XERO Id');
       insert mct1;
         
       Marketing_Call_Tracking__c checkMCT = [Select Id, Partner_Referral__c, Xero_Id__c from Marketing_Call_Tracking__c where Id=: mct1.Id LIMIT 1];
       PartnerReferral__c checkPr1 = [Select Id, Xero_Id__c from PartnerReferral__c where Id=:prRecs[0].Id LIMIT 1];
       Assert.areEqual(checkPr1.Id, checkMCT.Partner_Referral__c);
       Assert.areEqual(checkPr1.Xero_Id__c, checkMCT.Xero_Id__c);
      
      //convert lead and create opty
      //CreateOppAndMeeting coam = new CreateOppAndMeeting();
      //coam.LeadToConvert = ld1;
      //Boolean convertAns = coam.handleLeadConvert();
      //System.assertEquals(true, convertAns);
      //mctList = [select Id, Lead__c, Account__c, Contact__c, keywords__c from Marketing_Call_Tracking__c
      //                      where Lead__c = :ld1.Id];
      //System.assertNotEquals(null, mctList.get(0).Account__c);
      //System.assertNotEquals(null, mctList.get(0).Contact__c);

    } // System.runAs
      
    // convert lead and create opty, call methods to update tracking record
    // list of results of lead converts
    Map<Id, List<Id>> dbConvertResultMap;          //  Map<LeadId, List<AccountId, ContactId>>
    // map of source contact id and selling opty ids, used to link Market Call Tracking rcd to opty 
    Map<Id, Id> optyCtCtMap = new Map<Id, Id>();
    
    LeadStatus convertStatus;
    convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
      
    Database.LeadConvert lc = new Database.LeadConvert();        
        lc.setLeadId(leed.Id);
        lc.setDoNotCreateOpportunity(true);
        lc.setOwnerId(UserInfo.getUserId());
    lc.setConvertedStatus(convertStatus.MasterLabel);
    
       Database.Leadconvertresult lcr = null;
       dbConvertResultMap = new Map<Id, List<Id>>();
          
       Id acctId;
       Id ctctId;
       try {
           lcr = Database.convertLead(lc);                 
         //converted lead ok, save the details for Marketing Call Tracking rcd 
        List<Id> tempList = new List<Id>();
        tempList.add(lcr.getAccountId());
      acctId = lcr.getAccountId();
      tempList.add(lcr.getContactId());
      ctctId = lcr.getContactId();
      dbConvertResultMap.put(lcr.getLeadId(),tempList);         
        } catch (DmlException de) {    // why did convert fail?
          System.assertEquals('abc', de.getDmlMessage(0));
        } // try
      
        //if (!dbConvertResultMap.isEmpty())
        MarketTrackingMethods.addAcctCt(dbConvertResultMap);  
        
    List<Marketing_Call_Tracking__c> mctList2 = [select Id, Lead__c, Account__c, Contact__c, keywords__c from Marketing_Call_Tracking__c
              where Lead__c = :leed.Id];
    System.assertEquals(acctId, mctList2.get(0).Account__c);
    System.assertEquals(ctctId, mctList2.get(0).Contact__c);
                                                                          
    //Id opptyId = CreateTestData.createTestCoreOptys (acctId, ctctId);
    Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,ObjectHelper.OBJECT_OPPTY);
    Opportunity oppty1 = new Opportunity(Name='Test Core Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acctId
                                         ,StageName='Pending'
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId()
                                         ,NSS_Source__c='Inbound');                                         
        insert oppty1;                                                 
        OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=ctctId, OpportunityId=oppty1.Id, IsPrimary=true);
        insert ocr1;
        
     optyCtCtMap.put(oppty1.Id, ctctId);
     //if (!optyCtCtMap.isEmpty())
      MarketTrackingMethods.linkOpty(optyCtCtMap);  
      
      Opportunity opty = [Select Id, keywords__c, Latest_Marketing_Call_Tracking__c,GCLID__c from Opportunity where id = :oppty1.Id];
      System.assertEquals('This is a TEST', opty.keywords__c);
      System.assertEquals('CJ2uuL277NACFcS4wAodm7ECnQ', opty.gclid__c);
      System.assertEquals(mctList2.get(0).Id, opty.Latest_Marketing_Call_Tracking__c);    
    Test.stopTest();
  
   } // myUnitTest1
  
 /*  static testMethod void testCtctCreation() {
  
    User leadLdrUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Name='Lead Loader' and IsActive=true and HR_Person_Id__c != null limit 1];    
    Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
    
    // populate custom settings
    //LeadLoaderConfig__c llc = new LeadLoaderConfig__c(Name='WEBLEAD',IsActive__c=true,CreateTracking__c=true);   //IsNSSOwnership__c=true,LogWebleadFields__c=true,
                              //NSSSource__c='Inbound',QueueName__c='NSS Inbound Queue',WebServiceName__c='Lead Loader-WebLeads');
    //insert llc;                                                                       
    //ProcessNameMap__c pnm = new ProcessNameMap__c(Name='LL-Lead Loader',IsActive__c=true);
    //insert pnm;
      
      Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        System.runAs(leadLdrUser) {
          
          Test.startTest();
          
          Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
          insert acct1;
          Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,OwnedBy__c = 'WEBLEAD'
                                ,Products__c = '401K;Advantage Associate Office Leads;HR Services;PEO');
      ctct1.description = 'utm_source |^| Google\r';
      ctct1.description += 'utm_medium |^| CPC\r'; 
      ctct1.description += 'keyword |^| This is a TEST\r'; 
      ctct1.description += 'mm_campaign |^| 4EFE303C35B53BB23DAED7ED512D0BF0\r'; 
      ctct1.description += 'gclid |^| CJ2uuL277NACFcS4wAodm7ECnQ\r'; 
      ctct1.description += 'original_referer |^| http://pages.paychex.com/hcm.html?mm_campaign=4EFE303C35B53BB23DAED7ED512D0BF0&%20keyword=hris%20pay\r'; 
      ctct1.description += 'REDIRECT |^|\r'; 
      ctct1.description += 'HTTP_REFERER |^|\r'; 
      ctct1.description += 'IP_ADDRESS |^| 199.15.215.245\r'; 
      ctct1.description += 'BROWSER_TYPE |^| Unknown\r'; 
      ctct1.description += 'BROWSER_NAME |^| Unknown\r'; 
      ctct1.description += 'BROWSER_VERSION |^| 0.0\r'; 
      ctct1.description += 'EMAIL_SUBJECT |^| Paychex Super 8 Web Lead\r'; 
      ctct1.description += 'DATESTAMP |^| 20161213104301\r';                                 
      ctct1.description += 'salesPref_Payroll |^| 0\r';
      ctct1.description += 'salesPref_HRServices |^| 1\r';
      ctct1.description += 'Pricing |^| 2345 \r';
            insert ctct1;                    
            
            List<Marketing_Call_Tracking__c> mctList2 = [select Id, Lead__c, Account__c, Contact__c, gclid__c, webform_mm_campaign__c
                                                        ,ProdPayroll__c, ProdHRServices__c
                                                        ,Pricing__c
                                   from Marketing_Call_Tracking__c
                             where Contact__c = :ctct1.Id];
      System.assertEquals(acct1.Id, mctList2.get(0).Account__c);
      System.assertEquals(ctct1.Id, mctList2.get(0).Contact__c);
      System.assertEquals('4EFE303C35B53BB23DAED7ED512D0BF0',mctList2.get(0).webform_mm_campaign__c);
      System.assertEquals('CJ2uuL277NACFcS4wAodm7ECnQ', mctList2.get(0).gclid__c); 
      System.assertEquals(false, mctList2[0].ProdPayroll__c);
      System.assertEquals(true, mctList2[0].ProdHRServices__c);
      System.assertEquals(2345, mctList2[0].Pricing__c);
      
      Contact ctct2 = new Contact(Firstname = 'Second'
                                ,Lastname = 'Last2'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'sLast2@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,OwnedBy__c = 'WEBLEAD');  
      insert ctct2;
      mctList2 = [select Id, Lead__c, Account__c, Contact__c, gclid__c, webform_mm_campaign__c from Marketing_Call_Tracking__c
                  where Contact__c = :ctct2.Id];
      System.assertEquals(TRUE, mctList2.isEmpty());                                                                             
        } // runAs
    
   } // testCtctCreation
   */

   static testMethod void dialogTechTest() {
    
      User dialogUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Name='DialogTech Mongoose' and IsActive=true limit 1];    
      
      //Schema.RecordTypeInfo taskNSSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.NSS_TASK, ObjectHelper.OBJECT_TASK);
      String taskNSSrtId = '01270000000UNPj'; 
    
      CreateTestData.createTestLeadMany();
      Id coreLeadId = CreateTestData.ld1.Id;
      Id coreLeadId2 = CreateTestData.ld2.Id;
      
      CreateTestData.createTestAandC();
      Account coreAcct = CreateTestData.acct1;
      Contact coreCtct = CreateTestData.ctct1;
      Account coreAcct2 = CreateTestData.acct2;
      Contact coreCtct2 = CreateTestData.ctct2;
      
      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;

      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();
      
      DS_Denali__DialSource_Action__c action3 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId(), DS_Denali__Phone__c='5553456789', DS_Denali__DialSource_Session__c=dsSession.Id, DS_Denali__Contact__c=coreCtct2.Id
                                              ,DS_Denali__Call_Ended__c=Datetime.now());
      DS_Denali__DialSource_Action__c action4 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId(), DS_Denali__Phone__c='5551234570', DS_Denali__DialSource_Session__c=dsSession.Id, DS_Denali__Lead__c=coreLeadId2
                                              ,DS_Denali__Call_Ended__c=Datetime.now());
      DS_Denali__DialSource_Action__c[] actions = new DS_Denali__DialSource_Action__c[]{action3,action4};
      insert actions;

      //Task coreLeadTask = new Task(recordTypeId = taskNSSrtId, Subject='coreLeadTask', Type='Inbound', WhatId=null, WhoId=coreLeadId, 
      //              ActivityDate=Date.today(), isdc_inbound_callerid__c='1234567',CallDateTime__c=DateTime.now());
      Task coreLeadTask2 = new Task(recordTypeId = taskNSSrtId, Subject='coreLeadTask2', Type='Inbound', WhatId=null, WhoId=coreLeadId2, 
                    ActivityDate=Date.today(), CallDateTime__c=DateTime.now(), DS_Denali__DialSource_Action__c=action3.Id);

      //Task coreCtctTask = new Task(recordTypeId = taskNSSrtId, Subject='coreCtctTask', Type='Inbound', WhatId=coreAcct.Id, WhoId=coreCtct.Id, 
      //              ActivityDate=Date.today(), isdc_inbound_callerid__c='5551212',CallDateTime__c=DateTime.now().addDays(-1));
      Task coreCtctTask2 = new Task(recordTypeId = taskNSSrtId, Subject='coreCtctTask2', Type='Inbound', WhatId=coreAcct2.Id, WhoId=coreCtct2.Id, 
                    ActivityDate=Date.today(), CallDateTime__c=DateTime.now().addDays(-1), DS_Denali__DialSource_Action__c=action4.Id);
    
      //Task[] tsks = new Task[]{coreLeadTask, coreLeadTask2, coreCtctTask, coreCtctTask2};
      Task[] tsks = new Task[]{coreLeadTask2, coreCtctTask2};
      TaskHelper.SKIP_TRIGGERS = true;
      insert tsks;
      
      //Id coreOptyId = CreateTestData.createTestCoreOptys(coreCtct.AccountId, coreCtct.Id);
      // create a core opportunity
      Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,ObjectHelper.OBJECT_OPPTY);
      Opportunity oppty1 = new Opportunity(Name='Test Core Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                     ,AccountId=coreCtct.AccountId
                                     ,NSS_Source__c = 'Inbound'
                                     ,StageName='Pending'
                                     ,CloseDate=Date.today().addDays(30)
                                     ,OwnerId=UserInfo.getUserId());
      insert oppty1;                                                 
      OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=coreCtct.Id, OpportunityId=oppty1.Id, IsPrimary=true);
      insert ocr1;

      //Id [] fixedSoslResults = new Id[]{coreLeadTask.Id, action3.Id, coreCtctTask.Id, action4.Id};
      Id [] fixedSoslResults = new Id[]{action3.Id, action4.Id};

      Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query

      Test.startTest();
            
      System.runAs(dialogUser) {
         //Marketing_Call_Tracking__c mctLead = new Marketing_Call_Tracking__c(MM_caller_number__c='123-4567',MM_Caller_State__c='NY',
         //                 MM_Call_Date__c=Date.today(), MM_Session_Keyword__c='paychex payroll',mm_custom1__c = '?mm_campaign=123campaign&gclid=123gclid');
         Marketing_Call_Tracking__c mctLead2 = new Marketing_Call_Tracking__c(MM_caller_number__c=action4.DS_Denali__Phone__c,MM_Caller_State__c='NY',
                          MM_Call_Date__c=Date.today(), MM_Session_Keyword__c='paychex payroll',mm_custom1__c = '?mm_campaign=123campaign&gclid=123gclid');

         //Marketing_Call_Tracking__c mctCtct = new Marketing_Call_Tracking__c(MM_caller_number__c='5551212',MM_Caller_State__c='NY',
         //                 MM_Call_Date__c=Date.today().addDays(-1), MM_Session_Keyword__c='small business payroll');
         Marketing_Call_Tracking__c mctCtct2 = new Marketing_Call_Tracking__c(MM_caller_number__c=action3.DS_Denali__Phone__c,MM_Caller_State__c='NY',
                          MM_Call_Date__c=Date.today().addDays(-1), MM_Session_Keyword__c='small business payroll');

         Marketing_Call_Tracking__c mctCtctNoMatch = new Marketing_Call_Tracking__c(MM_caller_number__c='1112223333',MM_Caller_State__c='NY',
                          MM_Call_Date__c=Date.today(), MM_Session_Keyword__c='will never have a match');
         //Marketing_Call_Tracking__c[] mctList = new Marketing_Call_Tracking__c[]{mctLead,mctLead2,mctCtct,mctCtct2,mctCtctNoMatch};
         Marketing_Call_Tracking__c[] mctList = new Marketing_Call_Tracking__c[]{mctLead2,mctCtct2,mctCtctNoMatch};
         insert mctList;
      
      } // runAs
    
      List<Marketing_Call_Tracking__c> mctAfterList = [Select Id, Account__c, Contact__c, Lead__c, MM_caller_number__c,Source__c, Status__c
                                                             ,webform_mm_campaign__c, gclid__c 
                                                             ,Inbound_Task_ID__c
                                                             ,Task_Call_Result__c
                                                         from Marketing_Call_Tracking__c
                            where CreatedDate = TODAY]; 
      System.assertEquals(3, mctAfterList.size());     
      
      Integer matchCount = 0;                       
    
      for (Marketing_Call_Tracking__c mct: mctAfterList) {
         if (mct.MM_caller_number__c == '123-4567') {
            System.assertEquals(mct.Lead__c, coreLeadId);  
            System.assertEquals('Dialog Tech', mct.Source__c);
            System.assertEquals('Match Found', mct.Status__c);
            System.assertEquals('123campaign', mct.webform_mm_campaign__c);
            System.assertEquals('123gclid',mct.gclid__c);
            matchCount++;
         } else if (mct.MM_caller_number__c == '5551212') {
            System.assertEquals(mct.Account__c, coreAcct.Id);
            System.assertEquals(mct.Contact__c, coreCtct.Id);           
            Opportunity coreOpty = [Select Id, Latest_Marketing_Call_Tracking__c from Opportunity where Id = :oppty1.Id];
            System.assertEquals(mct.Id, coreOpty.Latest_Marketing_Call_Tracking__c);
            matchCount++;
         } else if (mct.MM_caller_number__c == '111223333') {
            System.assertEquals('Pending', mct.Status__c);
            matchCount++;
         } else if (mct.MM_caller_number__c == action3.DS_Denali__Phone__c) {
            //System.assertEquals(coreLeadTask2.Id, mct.Inbound_Task_ID__c);
         } else if (mct.MM_caller_number__c == action3.DS_Denali__Phone__c) {
            System.assertEquals(coreCtctTask2.Id, mct.Inbound_Task_ID__c);
         }
      } // for
    
      // test Not Found after 3 attempts
      Marketing_Call_Tracking__c mctCtct2Test = [Select Id, Account__c, Contact__c, Lead__c, MM_caller_number__c,Source__c, Status__c, parse_custom1__c,
                Match_Attempts__c, match_to_task__c, mm_custom1__c, webform_mm_campaign__c, gclid__c  
                from Marketing_Call_Tracking__c
                            where MM_caller_number__c = '1112223333' limit 1];
      System.assertEquals(1, mctCtct2Test.Match_Attempts__c);
      
      mctCtct2Test.match_to_task__c = true;
      update mctCtct2Test;
      mctCtct2Test = [Select Id, Account__c, Contact__c, Lead__c, MM_caller_number__c,Source__c, Status__c, parse_custom1__c,
                Match_Attempts__c, match_to_task__c, webform_mm_campaign__c, gclid__c, mm_custom1__c
                from Marketing_Call_Tracking__c
                            where MM_caller_number__c = '1112223333' limit 1];
     System.assertEquals(2, mctCtct2Test.Match_Attempts__c);
     mctCtct2Test.match_to_task__c = true;
     update mctCtct2Test;
     mctCtct2Test = [Select Id, Account__c, Contact__c, Lead__c, MM_caller_number__c,Source__c, Status__c, parse_custom1__c,
                Match_Attempts__c, match_to_task__c, webform_mm_campaign__c, gclid__c, mm_custom1__c 
                from Marketing_Call_Tracking__c
                            where MM_caller_number__c = '1112223333' limit 1];
     System.assertEquals(3, mctCtct2Test.Match_Attempts__c);
     System.assertEquals('Not Found', mctCtct2Test.Status__c);
    Test.stopTest();
                        
  } // dialogTechTest

/*  static testMethod void multiLeadEntry() {
  
    User leadLdrUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Name='Lead Loader' and IsActive=true and HR_Person_Id__c != null limit 1];    
    Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
    Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
    Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
    
    // populate custom settings
    //LeadLoaderConfig__c llc = new LeadLoaderConfig__c(Name='WEBLEAD',IsActive__c=true,CreateTracking__c=true);   //IsNSSOwnership__c=true,LogWebleadFields__c=true,
                              //NSSSource__c='Inbound',QueueName__c='NSS Inbound Queue',WebServiceName__c='Lead Loader-WebLeads');
    //insert llc;                                                                       
    //ProcessNameMap__c pnm = new ProcessNameMap__c(Name='LL-Lead Loader',IsActive__c=true);
    //insert pnm;
      
    
    Boolean ans = MarketTrackingMethods.checkOwnedBy('WEBLEAD');
    System.assertEquals(true, ans);
    
    Lead leed;
    System.runAs(leadLdrUser) {
      //Boolean isLeadLoader = UserHelper.isLeadLoader(UserInfo.getName());
      //System.assertEquals(true, isLeadLoader);
      
     Test.startTest(); 
      
      
  list<sobject> lstRecs = new list<sobject>();
  list<contact> lstContacts = new list<contact>();

  Lead ld1 = new Lead(Firstname = 'mctTest1 add/remove'
                ,Lastname = 'Last Lead1'
                ,Company = 'Test Lead Company1'
                ,recordtypeId = leadCorert.getRecordTypeId()
                ,DataFlux_Id__c = null
                ,LeadGroupId__c = null
                ,OwnedBy__c = 'WEBLEAD'
                ,Products__c = '401K;Advantage Associate Office Leads;HR Services;PEO'
                   );
      ld1.description = 'utm_source |^| Google\r';
      ld1.description += 'utm_medium |^| CPC\r'; 
      ld1.description += 'keyword |^| This is a TEST\r'; 
      ld1.description += 'mm_campaign |^| 4EFE303C35B53BB23DAED7ED512D0BF0\r'; 
      ld1.description += 'gclid |^| CJ2uuL277NACFcS4wAodm7ECnQ\r'; 
      ld1.description += 'original_referer |^| http://pages.paychex.com/hcm.html?mm_campaign=4EFE303C35B53BB23DAED7ED512D0BF0&%20keyword=hris%20pay\r'; 
      ld1.description += 'REDIRECT |^|\r'; 
      ld1.description += 'HTTP_REFERER |^|\r'; 
      ld1.description += 'IP_ADDRESS |^| 199.15.215.245\r'; 
      ld1.description += 'BROWSER_TYPE |^| Unknown\r'; 
      ld1.description += 'BROWSER_NAME |^| Unknown\r'; 
      ld1.description += 'BROWSER_VERSION |^| 0.0\r'; 
      ld1.description += 'EMAIL_SUBJECT |^| Paychex Super 8 Web Lead\r'; 
      ld1.description += 'DATESTAMP |^| 20161213104301\r';
      ld1.description += 'salesPref_Payroll |^| 1\r';
      ld1.description += 'salesPref_HRServices |^| \r';
      ld1.description += 'Pricing |^| 1234 \r';
      ld1.description += 'upperCustom3 |^| TESTing \r';
        
  

  Lead ld2 = new Lead(Firstname = 'mctTest2 add'
                ,Lastname = 'Last Lead2'
                ,Company = 'Test Lead Company2'
                ,recordtypeId = leadCorert.getRecordTypeId()
                ,DataFlux_Id__c = null
                ,LeadGroupId__c = null
                ,OwnedBy__c = 'WEBLEAD'
                   );
      ld2.description = 'utm_source |^| Google\r';
      ld2.description += 'utm_medium |^| CPC\r'; 
      ld2.description += 'keyword |^| This is a TEST\r'; 
      ld2.description += 'mm_campaign |^| 4EFE303C35B53BB23DAED7ED512D0BF0\r'; 
      ld2.description += 'gclid |^| CJ2uuL277NACFcS4wAodm7ECnQ\r'; 
      ld2.description += 'original_referer |^| http://pages.paychex.com/hcm.html?mm_campaign=4EFE303C35B53BB23DAED7ED512D0BF0&%20keyword=hris%20pay\r'; 
      ld2.description += 'REDIRECT |^|\r'; 
      ld2.description += 'HTTP_REFERER |^|\r'; 
      ld2.description += 'IP_ADDRESS |^| 199.15.215.245\r'; 
      ld2.description += 'BROWSER_TYPE |^| Unknown\r'; 
      ld2.description += 'BROWSER_NAME |^| Unknown\r'; 
      ld2.description += 'BROWSER_VERSION |^| 0.0\r'; 
      ld2.description += 'EMAIL_SUBJECT |^| Paychex Super 8 Web Lead\r'; 
      ld2.description += 'DATESTAMP |^| 20161213104301\r';
      ld2.description += 'salesPref_Payroll |^| 1\r';
      ld2.description += 'salesPref_HRServices |^| 1\r';
      ld2.description += 'Pricing |^| 1234 \r';
      ld2.description += 'upperCustom3 |^| TESTing \r';
        
      

  Lead ld3 = new Lead(Firstname = 'mctTest3 remove'
                ,Lastname = 'Last Lead3'
                ,Company = 'Test Lead Company3'
                ,recordtypeId = leadCorert.getRecordTypeId()
                ,DataFlux_Id__c = null
                ,LeadGroupId__c = null
                ,OwnedBy__c = 'WEBLEAD'
                ,Products__c = 'PEO;Payroll'
                   );
      ld3.description = 'utm_source |^| Google\r';
      ld3.description += 'utm_medium |^| CPC\r'; 
      ld3.description += 'keyword |^| This is a TEST\r'; 
      ld3.description += 'mm_campaign |^| 4EFE303C35B53BB23DAED7ED512D0BF0\r'; 
      ld3.description += 'gclid |^| CJ2uuL277NACFcS4wAodm7ECnQ\r'; 
      ld3.description += 'original_referer |^| http://pages.paychex.com/hcm.html?mm_campaign=4EFE303C35B53BB23DAED7ED512D0BF0&%20keyword=hris%20pay\r'; 
      ld3.description += 'REDIRECT |^|\r'; 
      ld3.description += 'HTTP_REFERER |^|\r'; 
      ld3.description += 'IP_ADDRESS |^| 199.15.215.245\r'; 
      ld3.description += 'BROWSER_TYPE |^| Unknown\r'; 
      ld3.description += 'BROWSER_NAME |^| Unknown\r'; 
      ld3.description += 'BROWSER_VERSION |^| 0.0\r'; 
      ld3.description += 'EMAIL_SUBJECT |^| Paychex Super 8 Web Lead\r'; 
      ld3.description += 'DATESTAMP |^| 20161213104301\r';
      ld3.description += 'salesPref_Payroll |^| \r';
      ld3.description += 'salesPref_HRServices |^| \r';
      ld3.description += 'Pricing |^| 1234 \r';
      ld3.description += 'upperCustom3 |^| TESTing \r';
    
    lstRecs.add(ld1);
    lstRecs.add(ld2);  
    lstRecs.add(ld3); 
        
    
    insert lstRecs; 
    
    Test.stopTest();
  
    list<id> leadIds = new list<id>();
    leadIds.add(ld1.Id);
    leadIds.add(ld2.Id);
    leadIds.add(ld3.Id);
    
      map<id, Lead> vldLeads = new map<id, lead>([select Id, Products__c from Lead where Id IN :leadIds]);
      
      system.debug('!!! vldLeads.get(ld1.Id).Products__c: ' + vldLeads.get(ld1.Id).Products__c);
      system.debug('!!! vldLeads.get(ld2.Id).Products__c: ' + vldLeads.get(ld2.Id).Products__c);
      system.debug('!!! vldLeads.get(ld3.Id).Products__c: ' + vldLeads.get(ld3.Id).Products__c);
      
      Lead chkLd1 = vldLeads.get(ld1.Id);
      System.assert(chkLd1.Products__c.contains('Payroll') && 
        chkLd1.Products__c.countMatches(';')==2, 'MCT Lead 1 POI value incorrect. products='+chkLd1.Products__c);
        
      Lead chkLd2 = vldLeads.get(ld2.Id);
      System.assert(chkLd2.Products__c.contains('Payroll') && 
        chkLd2.Products__c.contains('HR Services') && 
        chkLd2.Products__c.countMatches(';')==1, 'MCT Lead 2 POI value incorrect. products='+chkLd2.Products__c);
        
      System.assert(String.isBlank(vldLeads.get(ld3.Id).Products__c), 'MCT Lead 3 POI value incorrect.');
      
     
    } // System.runAs
          
  
  
   } // multiLeadEntry
   */

 /*  static testMethod void multiContactEntry() {
  
    User leadLdrUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Name='Lead Loader' and IsActive=true and HR_Person_Id__c != null limit 1];    
    Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
    Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
    Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
    
    // populate custom settings
    //LeadLoaderConfig__c llc = new LeadLoaderConfig__c(Name='WEBLEAD',IsActive__c=true,CreateTracking__c=true);   //IsNSSOwnership__c=true,LogWebleadFields__c=true,
                              //NSSSource__c='Inbound',QueueName__c='NSS Inbound Queue',WebServiceName__c='Lead Loader-WebLeads');
    //insert llc;                                                                       
    //ProcessNameMap__c pnm = new ProcessNameMap__c(Name='LL-Lead Loader',IsActive__c=true);
    //insert pnm;
      
    
    Boolean ans = MarketTrackingMethods.checkOwnedBy('WEBLEAD');
    System.assertEquals(true, ans);
    
    
    
    Lead leed;
    System.runAs(leadLdrUser) {
      //Boolean isLeadLoader = UserHelper.isLeadLoader(UserInfo.getName());
      //System.assertEquals(true, isLeadLoader);
      
      
      
      
  list<sobject> lstRecs = new list<sobject>();
  
  Test.startTest();
  
      
  
  Account acct1 = new Account (name = 'MCT Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
          insert acct1;
          
  Contact ctct1 = new Contact(Firstname = 'MCT test contact 1 add remove'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,OwnedBy__c = 'WEBLEAD'
                                ,Products__c = '401K;Advantage Associate Office Leads;HR Services;PEO');
      ctct1.description = 'utm_source |^| Google\r';
      ctct1.description += 'utm_medium |^| CPC\r'; 
      ctct1.description += 'keyword |^| This is a TEST\r'; 
      ctct1.description += 'mm_campaign |^| 4EFE303C35B53BB23DAED7ED512D0BF0\r'; 
      ctct1.description += 'gclid |^| CJ2uuL277NACFcS4wAodm7ECnQ\r'; 
      ctct1.description += 'original_referer |^| http://pages.paychex.com/hcm.html?mm_campaign=4EFE303C35B53BB23DAED7ED512D0BF0&%20keyword=hris%20pay\r'; 
      ctct1.description += 'REDIRECT |^|\r'; 
      ctct1.description += 'HTTP_REFERER |^|\r'; 
      ctct1.description += 'IP_ADDRESS |^| 199.15.215.245\r'; 
      ctct1.description += 'BROWSER_TYPE |^| Unknown\r'; 
      ctct1.description += 'BROWSER_NAME |^| Unknown\r'; 
      ctct1.description += 'BROWSER_VERSION |^| 0.0\r'; 
      ctct1.description += 'EMAIL_SUBJECT |^| Paychex Super 8 Web Lead\r'; 
      ctct1.description += 'DATESTAMP |^| 20161213104301\r';                                 
      ctct1.description += 'salesPref_Payroll |^| 1\r';
      ctct1.description += 'salesPref_HRServices |^| 1\r';
      ctct1.description += 'Pricing |^| 2345 \r';
      
      

  Contact ctct2 = new Contact(Firstname = 'MCT test contact 2 add'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,OwnedBy__c = 'WEBLEAD');
      ctct2.description = 'utm_source |^| Google\r';
      ctct2.description += 'utm_medium |^| CPC\r'; 
      ctct2.description += 'keyword |^| This is a TEST\r'; 
      ctct2.description += 'mm_campaign |^| 4EFE303C35B53BB23DAED7ED512D0BF0\r'; 
      ctct2.description += 'gclid |^| CJ2uuL277NACFcS4wAodm7ECnQ\r'; 
      ctct2.description += 'original_referer |^| http://pages.paychex.com/hcm.html?mm_campaign=4EFE303C35B53BB23DAED7ED512D0BF0&%20keyword=hris%20pay\r'; 
      ctct2.description += 'REDIRECT |^|\r'; 
      ctct2.description += 'HTTP_REFERER |^|\r'; 
      ctct2.description += 'IP_ADDRESS |^| 199.15.215.245\r'; 
      ctct2.description += 'BROWSER_TYPE |^| Unknown\r'; 
      ctct2.description += 'BROWSER_NAME |^| Unknown\r'; 
      ctct2.description += 'BROWSER_VERSION |^| 0.0\r'; 
      ctct2.description += 'EMAIL_SUBJECT |^| Paychex Super 8 Web Lead\r'; 
      ctct2.description += 'DATESTAMP |^| 20161213104301\r';                                 
      ctct2.description += 'salesPref_Payroll |^| 1\r';
      ctct2.description += 'salesPref_HRServices |^| 1\r';
      ctct2.description += 'Pricing |^| 2345 \r';
      

  Contact ctct3 = new Contact(Firstname = 'MCT test contact 3 remove'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,OwnedBy__c = 'WEBLEAD'
                                ,Products__c = 'PEO');
    
      ctct3.description = 'utm_source |^| Google\r';
      ctct3.description += 'utm_medium |^| CPC\r'; 
      ctct3.description += 'keyword |^| This is a TEST\r'; 
      ctct3.description += 'mm_campaign |^| 4EFE303C35B53BB23DAED7ED512D0BF0\r'; 
      ctct3.description += 'gclid |^| CJ2uuL277NACFcS4wAodm7ECnQ\r'; 
      ctct3.description += 'original_referer |^| http://pages.paychex.com/hcm.html?mm_campaign=4EFE303C35B53BB23DAED7ED512D0BF0&%20keyword=hris%20pay\r'; 
      ctct3.description += 'REDIRECT |^|\r'; 
      ctct3.description += 'HTTP_REFERER |^|\r'; 
      ctct3.description += 'IP_ADDRESS |^| 199.15.215.245\r'; 
      ctct3.description += 'BROWSER_TYPE |^| Unknown\r'; 
      ctct3.description += 'BROWSER_NAME |^| Unknown\r'; 
      ctct3.description += 'BROWSER_VERSION |^| 0.0\r'; 
      ctct3.description += 'EMAIL_SUBJECT |^| Paychex Super 8 Web Lead\r'; 
      ctct3.description += 'DATESTAMP |^| 20161213104301\r';                                 
      ctct3.description += 'salesPref_Payroll |^| \r';
      ctct3.description += 'salesPref_HRServices |^| \r';
      ctct3.description += 'Pricing |^| 2345 \r';
    
    
    lstRecs.add(ctct1);
    lstRecs.add(ctct2);
    lstRecs.add(ctct3);    
    
    insert lstRecs; 
    
    Test.stopTest();
    
    
    list<id> contIds = new list<id>();
    contIds.add(ctct1.Id);
    contIds.add(ctct2.Id);
    contIds.add(ctct3.Id);
    
                       
      map<id, Contact> vldContacts = new map<id, contact>([select Id, Products__c from Contact where Id IN :contIds]);
      
      List<PartnerReferral__c> prRecs = [SELECT Id, Lead__c, Contact__c, isDeleted 
                        FROM PartnerReferral__c 
                        WHERE Contact__c IN :contIds];
      system.debug('!!! prRecs.size(): ' + prRecs.size());  
      system.debug('!!! prRecs: ' + prRecs);  
      
      
      List<Marketing_Call_Tracking__c> mctList2 = [select Id,  Contact__c, Lead__c
                                   from Marketing_Call_Tracking__c
                             where Contact__c IN :contIds];
      system.debug('!!! mctList2.size(): ' + mctList2.size());  
            
      system.debug('!!! vldContacts.get(ctct1.Id).Products__c: ' + vldContacts.get(ctct1.Id).Products__c);
      system.debug('!!! vldContacts.get(ctct2.Id).Products__c: ' + vldContacts.get(ctct2.Id).Products__c);
      system.debug('!!! vldContacts.get(ctct3.Id).Products__c: ' + vldContacts.get(ctct3.Id).Products__c);
      
      
      
      System.assert(vldContacts.get(ctct1.Id).Products__c.contains('Payroll') && 
        vldContacts.get(ctct1.Id).Products__c.contains('HR Services') && 
        vldContacts.get(ctct1.Id).Products__c.countMatches(';')==3, 'MCT Contact 1 POI value incorrect.');
     
      System.assert(vldContacts.get(ctct2.Id).Products__c.contains('Payroll') && 
        vldContacts.get(ctct2.Id).Products__c.contains('HR Services') && 
        vldContacts.get(ctct2.Id).Products__c.countMatches(';')==1, 'MCT Contact 2 POI value incorrect.');
     
      System.assert(String.isBlank(vldContacts.get(ctct3.Id).Products__c), 'MCT Lead 3 POI value incorrect.');
     
      
     
    } // System.runAs
          
  
  
   } // multiContactEntry
   
   */
   static testMethod void testMatchtoPartRef() {

       // create DialSource Action 
        TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
        TriggerMethodsTest.createCustomSetting('TaskAfter', false, true, new String[]{'TaskHelper'},setupClasses, TriggerMethods.INTERFACE_B);
        insert setupClasses;
        
        Id leadId = CreateTestData.createTestLead();
        Lead newLead = new Lead(id = leadId, phone = '(585) 555-1111', MobilePhone='(585) 555-1112',Other_Phone__c='(585) 555-1113');
        update newLead;
        
        DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c();
        dsSession.Name = '96349f93-43da-47ad-b3d9-0ba81d605ec5 - 5d19f78a19c297001a87';
        dsSession.DS_Denali__Session_Date__c = system.now();
        insert dsSession;       
                
        Schema.RecordTypeInfo dsActionrt = RecordTypeHelper.getRecordType('Inbound', 'DS_Denali__DialSource_Action__c');        
        DS_Denali__DialSource_Action__c dsAction = new DS_Denali__DialSource_Action__c();        
        dsAction.DS_Denali__Date__c = system.today();
        dsAction.DS_Denali__Lead__c = leadId;
        dsAction.DS_Denali__Subject__c = 'Inbound Call';
        dsAction.DS_Denali__Call_Disposition__c = 'Inbound Call';
        dsAction.recordtypeId = dsActionrt.getRecordTypeId();
        dsAction.DS_Denali__Call_Campaign__c = '*Inbound*';
        dsAction.DS_Denali__DialSource_Session__c =dsSession.Id;
        dsAction.DS_Denali__Phone__c = '5855551111';
        dsAction.DS_Denali__Inbound_DNIS_Name__c = 'Branch 28';
        dsAction.DS_Denali__Inbound_DNIS__c = '15853049497';
        insert dsAction;
        
        User testUsr = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_NSS limit 1]; // and Job_Name__c=:UserHelper.JOB_REP limit 1];
        Task tsk1 = new Task(OwnerId=testUsr.Id, ActivityDate=Date.today(), WhoId=leadId, 
                                Subject='Inbound Call', DS_Denali__DialSource_Action__c =dsAction.Id);
        insert tsk1;
        
        // inserting the task creates the partner referral and referral
        Task leadTask = [Select Id, WhatId, WhoId, Subject from Task where whoId = :leadId];
        System.assertNotEquals(null, leadTask);
        System.assertEquals('Inbound Call',leadTask.Subject);
        PartnerReferral__c leadPR = [Select Id, Account__c, Contact__c, Lead__c, Source__c,Disposition__c, Referral__c, ActivityId__c
                                    from PartnerReferral__c where Lead__c = :leadId];
        System.assertNotEquals(null, leadPR);
        System.assertEquals('Inbound Call', leadPR.Source__c);
        System.assertEquals(tsk1.Id, leadPR.ActivityId__c);
        /*
        // create DialogTech Call and match to a Lead, this creates Marketing Call Tracking
        TriggerSetupClasses__c[] setupClasses2 = new TriggerSetupClasses__c[]{};
        TriggerSetup__c trigSetup1 = TriggerMethodsTest.createCustomSetting(null, 'DialogTechCallAfter', false, true, new String[]{'DialogTech_Helper'},setupClasses, TriggerMethods.INTERFACE_B);
        insert setupClasses2;
        DialogTech_Helper.TEST_PROCESS_NOW = true;
        */
        // you must give the test the sosl results
      List<Id> fixedSoslResults = new List<Id>();
      Lead[] ldList = [select Id, phone, MobilePhone, Other_Phone__c from Lead];
      for (Lead ld :ldList)
      {  fixedSoslResults.add(ld.Id);  }
      Test.setFixedSearchResults(fixedSoslResults);         
        
       //Commented the below object record creation as part of uninstalling DialogTech managed package
      //IBP__Ifbyphone_Call__c dtCall1 = new IBP__Ifbyphone_Call__c(Name='Test1', IBP__CallerID__c='5855551111', IBP__SessionID__c='1', IBP__DateAdded__c=System.now(), IBP__ST_GCLID__c='Googleclick');
      //insert dtCall1;
        // manually creating MCT coz cant get trigger to work in test
        Marketing_Call_Tracking__c newMCT = new Marketing_Call_Tracking__c();
        //newMCT.DialogTech_Call__c = dtCall1.Id;
        newMCT.Lead__c = leadID;
        newMCT.MM_Call_Date__c = system.now();
        newMCT.MM_caller_number__c = '5855551111';
        newMCT.Inbound_Task_ID__c = leadTask.Id;
        insert newMCT;
        
      Marketing_Call_Tracking__c updatedMCT = [Select Id, Lead__c, MM_Call_Date__c, MM_caller_number__c, Partner_Referral__c from Marketing_Call_Tracking__c];
      System.assertNotEquals(null, updatedMCT);
      System.assertEquals(leadId, updatedMCT.Lead__c);
      System.assertEquals(leadPR.Id, updatedMCT.Partner_Referral__c);
     
     
   }

}// MarketTrackingMethodsTest