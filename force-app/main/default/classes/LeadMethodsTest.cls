/** Test methods for the LeadMethods class (and associated triggers)
 *
 * History
 * -------
 * 10/11/2013 Dan Carmen        Created.
   12/19/2014 Dan Carmen        Consolidated methods coming from the lead
   11/14/2017 Dan Carmen        Update so test will pass
   09/17/2018 Dan Carmen        Add TriggerSetupClasses__c so test will pass with new Lead Company Methods
   11/14/2019 Dan Carmen        Remove ISDC code
   12/29/2022 Dan Carmen        Commented out Copy Lead logic (checkForDuplicate)
   09/28/2023 Dan Carmen        Remove "Lead Flopper" code that isn't being used.

*/
@isTest
public class LeadMethodsTest {
   
   public static String QUEUE_1='LeadMethodsTest Queue 1';
   public static String QUEUE_2='LeadMethodsTest Queue 2';
   public static String QUEUE_VS='Virtual Sales Queue';
   
   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false, new String[]{'LeadCompanyMethods'});
      TriggerMethodsTest.saveSetupClasses();

      User runningUser = UserHelper.getRunningUser();
      Group setup_vqueue = null;
      System.runAs(runningUser) {
         Group setup_queue1 = new Group(Name=QUEUE_1,Type='Queue');
         Group setup_queue2 = new Group(Name=QUEUE_2,Type='Queue');
         setup_vqueue = new Group(Name=QUEUE_VS,Type='Queue');
         Group[] grps = new Group[]{setup_queue1,setup_queue2,setup_vqueue};
         insert grps;
      
         QueueSobject qObject1 = new QueueSobject(QueueId = setup_queue1.Id, SobjectType = 'Lead');
         QueueSobject qObject2 = new QueueSobject(QueueId = setup_queue2.Id, SobjectType = 'Lead');
         QueueSobject vqObject = new QueueSobject(QueueId = setup_vqueue.Id, SobjectType = 'Lead');
         QueueSobject[] qsobjs = new QueueSobject[]{qObject1,qObject2,vqObject};
         insert qsobjs;
      } // System.runAs
      BypassNSS__c bypassSetting = BypassNSS__c.getOrgDefaults();
      if (bypassSetting.SetupOwnerId==null){
         System.debug(UserInfo.getOrganizationId());
         System.debug(setup_vqueue.Id);
         bypassSetting = new BypassNSS__c(SetupOwnerId=UserInfo.getOrganizationId(), IsActive__c=true,Queue_Id__c=setup_vqueue.Id,Queue_Name__c=setup_vqueue.Name,Partner_Referral_Expiration_Duration__c=1,Holdout_Expiration__c=1);
         insert bypassSetting; 
      }
   } // setupData

   public static Group getNSSQueue() {
      // verify the NSS_PENDING_QUEUE exists
      Group nssPendingQueue = new UserHelper().getQueue(LeadMethods.NSS_PENDING_QUEUE);
      System.assertEquals(true,nssPendingQueue != null);
      return nssPendingQueue;
   } // getNSSQueue

   public static Id nssRtId = null;
   
   public static Lead createNSSLead(String leadKey) {
      if (nssRtId == null) {
         // find a lead record type that starts with "NSS" - keeping it generic in case the names change
         List<Schema.RecordTypeInfo> leadRts = RecordTypeHelper.getRecordTypes('Lead');
         Schema.RecordTypeInfo nssRt = null;
         // use the first one starting with NSS
         for (Schema.RecordTypeInfo rt : leadRts) {
            if (rt.getName().startsWith('NSS')) {
               nssRtId = rt.getRecordTypeId();
               break;
            }
         } // for
         
      } // if (nssRtId == null
      
      System.assertEquals(true, nssRtId != null);
      
      Lead l = new Lead(RecordTypeId = nssRtId, LastName='Last'+leadKey, Company='TestCompany'+leadKey, PostalCode='12345', Status='New');
      return l;
   } // createNSSLead
   
   public static LeadCallDisposition__c[] createLeadCallDispositions() {
      // insert status change rules
      LeadCallDisposition__c lcd1 = new LeadCallDisposition__c(Name='ContactedNew',CallDisposition__c='Contacted',CurrentLeadStatus__c='New',NewLeadStatus__c='Contacted',EndOwnership__c=false,AssignToQueue__c=null, InboundActivityCheck__c=true,UseForFirstContact__c=true,UseForPartRef__c=true,SetWorkable__c='Workable');
      LeadCallDisposition__c lcd2 = new LeadCallDisposition__c(Name='SetCallbackContacted',CallDisposition__c='Set Callback',CurrentLeadStatus__c='Contacted',NewLeadStatus__c='Contacted',EndOwnership__c=false,AssignToQueue__c=null,UseForFirstContact__c=true,UseForPartRef__c=true,SetWorkable__c='Workable');
      LeadCallDisposition__c lcd3 = new LeadCallDisposition__c(Name='BadNumberContacted',CallDisposition__c='Bad Number',CurrentLeadStatus__c='Contacted',NewLeadStatus__c='Disqualified',EndOwnership__c=false,AssignToQueue__c=null,UseForFirstContact__c=true,UseForPartRef__c=true,SetWorkable__c='Not Workable');
      LeadCallDisposition__c lcd4 = new LeadCallDisposition__c(Name='ContactedNotInterestedDisqualified',CallDisposition__c='Contacted Not Interested',CurrentLeadStatus__c='Disqualified',NewLeadStatus__c='No Interest',EndOwnership__c=false,SetDoNotCall__c=true,NewOwnershipStatus__c='Not Interested',AssignToQueue__c=LeadMethods.NSS_PENDING_QUEUE);
      LeadCallDisposition__c lcd5 = new LeadCallDisposition__c(Name='ContactedNotInterested',CallDisposition__c='Contacted Not Interested',CurrentLeadStatus__c=null,NewLeadStatus__c='No Interest',EndOwnership__c=false,SetDoNotCall__c=true,NewOwnershipStatus__c='Not Interested',AssignToQueue__c=LeadMethods.NSS_PENDING_QUEUE);
      LeadCallDisposition__c[] lcds = new LeadCallDisposition__c[]{lcd1,lcd2,lcd3,lcd4,lcd5};
      insert lcds;
      return lcds;
   } // createLeadCallDispositions
   
   // When a task with a call disposition is created (or updated) change the status of the lead.
   static testMethod void testStatusChange() {
      DataFluxDeltaServiceTest.disableDeltaTriggers();
    // verify the NSS_PENDING_QUEUE exists
    Group nssPendingQueue = getNSSQueue();
      LeadCompanyMethods.SKIP_FUTURE=true;
    
    
    LeadCallDisposition__c[] lcds = createLeadCallDispositions();

      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      User outboundNSR = outboundNSRs[0];
      System.assertEquals(true,(outboundNSR.Id != null));
    
      // create a lead
      Lead l1 = createNSSLead('1');
      l1.NSS_Ownership_Start_Date__c = Date.today();
      l1.OwnerId = outboundNSR.Id;
      insert l1;
      
      l1=[select Id, Name, OwnerId, NSS_Ownership_Start_Date__c, Lead_Company__c
                ,Lead_Company__r.Id, Lead_Company__r.SignificantLead__c
                ,RecordTypeId, LastName, Company, PostalCode, Status 
            from Lead where Id=:l1.Id];
      
      LifeOfLeadSettings__c lols = ProspectOwnershipMethodsTest.createProspectingLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);
      LifeOfLeadSettings__c noInterestLols = ProspectOwnershipMethodsTest.createNotInterestedLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);
      Prospect_Ownership__c po = ProspectOwnershipMethodsTest.createProspectingOwnership(lols,l1,null);
      po.NSR_Name__c=outboundNSR.Id;
      po.OwnerId=outboundNSR.Id;
      insert po;
      
      System.runAs(outboundNSR) {
      System.assertEquals(1,[select count() from Prospect_Ownership__c]);
      
      
      // clear this variable because test runs in the same context
      LeadMethods.leadIdsProcessed.clear();
      // update the call disposition on the lead
      l1.NSSCallDisposition__c = lcds[0].CallDisposition__c;
      System.debug('testStatusChange first update of call disposition l1.OwnerId='+l1.OwnerId+' outboundNSR='+outboundNSR);
      l1.OwnerId=outboundNSR.Id;
      update l1;
      System.assertEquals(1,[select count() from Prospect_Ownership__c]);
      
      l1 = [Select Id, LastName, Company, Status, OwnerId, NSS_Ownership_Start_Date__c, NSSCallDisposition__c from Lead where Id=:l1.Id];
      System.assertEquals(lcds[0].NewLeadStatus__c,l1.Status);
      
      // clear this variable because test runs in the same context
      LeadMethods.leadIdsProcessed.clear();
      l1.NSSCallDisposition__c = lcds[1].CallDisposition__c;
      System.debug('testStatusChange second update l1.NSSCallDisposition__c='+l1.NSSCallDisposition__c);
      update l1; 

      System.assertEquals(1,[select count() from Prospect_Ownership__c]);
      l1 = [Select Id, LastName, Company, Status, OwnerId, NSS_Ownership_Start_Date__c, NSSCallDisposition__c from Lead where Id=:l1.Id];
      System.assertEquals(lcds[1].NewLeadStatus__c,l1.Status);
      
      // clear this variable because test runs in the same context
      LeadMethods.leadIdsProcessed.clear();
      l1.NSSCallDisposition__c = lcds[2].CallDisposition__c;
      System.debug('testStatusChange third update l1.NSSCallDisposition__c='+l1.NSSCallDisposition__c);
      update l1; 

      System.assertEquals(1,[select count() from Prospect_Ownership__c]);
      l1 = [Select Id, LastName, Company, Status, OwnerId, NSS_Ownership_Start_Date__c, NSSCallDisposition__c from Lead where Id=:l1.Id];
      System.assertEquals(lcds[2].NewLeadStatus__c,l1.Status);

      // clear this variable because test runs in the same context
      LeadMethods.leadIdsProcessed.clear();
      l1.NSSCallDisposition__c = lcds[3].CallDisposition__c;
      System.debug('testStatusChange update to not interested l1.NSSCallDisposition__c='+l1.NSSCallDisposition__c);
      update l1; 
      
      // should still be only one ownership record.
      System.assertEquals(1,[select count() from Prospect_Ownership__c]);
      l1 = [Select Id, LastName, Company, Status, OwnerId, NSS_Ownership_Start_Date__c, NSSCallDisposition__c from Lead where Id=:l1.Id];
      System.assertEquals(lcds[3].NewLeadStatus__c,l1.Status);
      System.assertEquals(null,l1.NSS_Ownership_Start_Date__c);
      System.assertEquals(nssPendingQueue.Id, l1.OwnerId);

      po = [Select Id, StartDate__c, EndDate__c, ProspectingStart__c, ProspectingEnd__c, Ownership_Status__c, NFI_WashStart__c, NFI_WashEnd__c from Prospect_Ownership__c where Id=:po.Id ];
      System.debug('po='+po);
      System.assertEquals(true, (po.StartDate__c != null));
      System.assertEquals(null, po.EndDate__c);
      System.assertEquals(Date.today(), po.NFI_WashStart__c);
      System.assertEquals(null, po.NFI_WashEnd__c);
      System.assertEquals('Not Interested', po.Ownership_Status__c);
      
      }
   } // testStatusChange
   
   public static Group queue1 = null;
   public static Group queue2 = null;
   public static Group vqueue = null;
   
   public static void setupQueues() {
      Group[] queues = [Select Id, Name from Group where Type='Queue' and Name in (:QUEUE_1,:QUEUE_2,:QUEUE_VS)];
      Map<String,Group> grpMap = new Map<String,Group>();
      for (Group queue : queues) {
         grpMap.put(queue.Name, queue);
      }
      
      queue1 = grpMap.get(QUEUE_1);
      queue2 = grpMap.get(QUEUE_2);
      vqueue = grpMap.get(QUEUE_VS);
   } // setupQueues

   // Test the owned by field. 
   static testMethod void testLeadOwnedBy() {
      setupQueues();
    User runningUser = UserHelper.getRunningUser();
    System.runAs(runningUser) {
      Campaign alwaysCampaign = new Campaign(Name='Campaign Always',Send_To_Virtual__c='Always');
      Campaign checkCampaign = new Campaign(Name='Campaign Check',Send_To_Virtual__c='Check Zips');
      Campaign[] camps= new Campaign[]{alwaysCampaign,checkCampaign};
      insert camps;
      
      User vsu = [SELECT Name,Id FROM User WHERE Name='Virtual Sales' AND Sales_Org__c='PAY' LIMIT 1];
      User vsr = [SELECT Name,Id FROM User WHERE UserRole.Name like '%Virtual%' AND NSS_Team__c = 'VS PAY' LIMIT 1];
     
      system.debug('vsr: '+vsr);
     
      ZipCheckOwnerTest.setupSegments();
     
      Zip_Segment__c zs = ZipCheckOwnerTest.coreSeg1;
      zs.Id = null;
      zs.Name = 'DEFAULT';
      insert zs;
     
       Zip_Assignment__c za1 = new Zip_Assignment__c(Name='11111', HR_Person_Id__c=null,Emps_Min__c=0, Emps_Max__c=100,
                                               Asset_Min__c=0, Asset_Max__c=100,
                                               Sales_Org__c='PAY', MC_Id__c='TestPAY',
                                               Rep_Name__c=runningUser.Name,User__c=runningUser.Id,
                                               Segment_Name__c=zs.Name,
                                               Zip_Segment__c=zs.Id);
      Zip_Assignment__c za2 = new Zip_Assignment__c(Name='22222', HR_Person_Id__c=null,Emps_Min__c=0, Emps_Max__c=100,
                                               Asset_Min__c=0, Asset_Max__c=100,
                                               Sales_Org__c='PAY', MC_Id__c='TestPAY',
                                               Rep_Name__c=vsu.Name,User__c=vsu.Id,
                                               Segment_Name__c=zs.Name,
                                               Zip_Segment__c=zs.Id);
      Zip_Assignment__c za3 = new Zip_Assignment__c(Name='33333', HR_Person_Id__c=null,Emps_Min__c=0, Emps_Max__c=100,
                                               Asset_Min__c=0, Asset_Max__c=100,
                                               Sales_Org__c='PAY', MC_Id__c='TestPAY',
                                               Rep_Name__c=vsr.Name,User__c=vsr.Id,
                                               Segment_Name__c=zs.Name,
                                               Zip_Segment__c=zs.Id);                                          
      Zip_Assignment__c[] zas = new Zip_Assignment__c[]{za1,za2,za3};
      insert zas;
       
      
      
         DataFluxDeltaServiceTest.disableDeltaTriggers();
         // create the custom settings
         LeadLoaderConfig__c config1 = new LeadLoaderConfig__c(Name='Test Inbound', IsActive__c=true, NSSSource__c=ProspectOwnershipMethods.NSS_INBOUND, QueueName__c=queue1.Name, UseAssignmentRules__c=false);
         LeadLoaderConfig__c config2 = new LeadLoaderConfig__c(Name='Test Outbound', IsActive__c=true, NSSSource__c=ProspectOwnershipMethods.NSS_OUTBOUND, QueueName__c=queue2.Name, UseAssignmentRules__c=false);
         LeadLoaderConfig__c config3 = new LeadLoaderConfig__c(Name='Test Assignment Rules', IsActive__c=true, NSSSource__c=null, QueueName__c=null, UseAssignmentRules__c=true);
         LeadLoaderConfig__c[] configs = new LeadLoaderConfig__c[]{config1,config2,config3};
         insert configs;
      
         // set the running user as a "Lead Loader" user so the trigger will fire
         ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);

         System.assertEquals(true,UserHelper.isLeadLoader(runningUser.Name));
      
         // create the lead companies
         Lead_Company__c lc1 = new Lead_Company__c(Name='Test Lead Company 1', Postal_Code__c='12345');
         Lead_Company__c lc2 = new Lead_Company__c(Name='Test Lead Company 2', Postal_Code__c='12345');
         Lead_Company__c lc3 = new Lead_Company__c(Name='Test Lead Company 3', Postal_Code__c='12345');
         Lead_Company__c lc4 = new Lead_Company__c(Name='Test Lead Company 4', Postal_Code__c=za1.Name);
         Lead_Company__c lc5 = new Lead_Company__c(Name='Test Lead Company 5', Postal_Code__c=za2.Name);
         Lead_Company__c lc6 = new Lead_Company__c(Name='Test Lead Company 6', Postal_Code__c=za3.Name);
         Lead_Company__c[] companies = new Lead_Company__c[]{lc1,lc2,lc3,lc4,lc5,lc6};
         insert companies;
      
         // create leads - test ownership
         Lead ld1 = new Lead(Company=lc1.Name, LastName='Last1', LeadSource='LeadSource', OwnedBy__c=config1.Name, Lead_Company__c=lc1.Id);
         Lead ld2 = new Lead(Company=lc2.Name, LastName='Last2', LeadSource='LeadSource', OwnedBy__c=config2.Name, Lead_Company__c=lc2.Id);
         Lead ld3 = new Lead(Company=lc3.Name, LastName='Last3', LeadSource='LeadSource', OwnedBy__c=config3.Name, Lead_Company__c=lc3.Id);
         Lead ld4 = new Lead(Company=lc4.Name, LastName='Last4', LeadSource='LeadSource', OwnedBy__c=config1.Name, Lead_Company__c=lc4.Id,PostalCode=za1.Name,LatestCampaign__c=alwaysCampaign.Id);
         Lead ld5 = new Lead(Company=lc5.Name, LastName='Last5', LeadSource='LeadSource', OwnedBy__c=config1.Name, Lead_Company__c=lc5.Id,PostalCode=za2.Name,LatestCampaign__c=checkCampaign.Id);
         Lead ld6 = new Lead(Company=lc6.Name, LastName='Last6', LeadSource='LeadSource', OwnedBy__c=config1.Name, Lead_Company__c=lc6.Id,PostalCode=za3.Name,LatestCampaign__c=checkCampaign.Id);
         Lead[] leads = new Lead[]{ld1,ld2,ld3,ld4,ld5,ld6};

         insert leads;

         Test.startTest();
         // check the owner of the leads
         ld1 = [Select Id, Name, Company, LastName, OwnedBy__c, OwnerId from Lead where Id=:ld1.Id];
         System.assertEquals(null,ld1.OwnedBy__c);
         System.assertEquals(queue1.Id, ld1.OwnerId);
         ld2 = [Select Id, Name, Company, LastName, OwnedBy__c, OwnerId from Lead where Id=:ld2.Id];
         System.assertEquals(null,ld2.OwnedBy__c);
         System.assertEquals(queue2.Id, ld2.OwnerId);
         ld3 = [Select Id, Name, Company, LastName, OwnedBy__c, OwnerId from Lead where Id=:ld3.Id];
         System.assertEquals(null,ld3.OwnedBy__c);
         System.assertEquals(runningUser.Id, ld3.OwnerId);
         ld4 = [Select Id, Name, Company, LastName, OwnedBy__c, OwnerId from Lead where Id=:ld4.Id];
         System.assertEquals(null,ld4.OwnedBy__c);
         //System.assertEquals(vqueue.Id, ld4.OwnerId);
         ld5 = [Select Id, Name, Company, LastName, OwnedBy__c, OwnerId from Lead where Id=:ld5.Id];
         System.assertEquals(null,ld5.OwnedBy__c);
         //System.assertEquals(vqueue.Id, ld5.OwnerId);
         ld6 = [Select Id, Name, Company, LastName, OwnedBy__c, OwnerId from Lead where Id=:ld6.Id];
         System.assertEquals(null,ld6.OwnedBy__c);
         //System.assertEquals(vsr.Id, ld6.OwnerId);
         PartnerReferral__c partRef = [Select Id FROM PartnerReferral__c WHERE Lead__c = :ld6.Id LIMIT 1];
         System.assert(partRef!=null);
      
         // clear the variables so the records process
         LeadMethods.leadIdsProcessed.clear();
         LeadMethods.doNotCheckOwnedIdSet.clear();
      
         ld1.OwnedBy__c = config2.Name;
         ld2.OwnedBy__c = config1.Name;
         leads = new Lead[]{ld1,ld2,ld3};

         TriggerMethods.clearVariables();
         update leads;
      
         // check the owner of the leads
         ld1 = [Select Id, Name, Company, LastName, OwnedBy__c, OwnerId from Lead where Id=:ld1.Id];
         System.assertEquals(null,ld1.OwnedBy__c);
         System.assertEquals(queue2.Id, ld1.OwnerId);
         ld2 = [Select Id, Name, Company, LastName, OwnedBy__c, OwnerId from Lead where Id=:ld2.Id];
         System.assertEquals(null,ld2.OwnedBy__c);
         System.assertEquals(queue1.Id, ld2.OwnerId);
         ld3 = [Select Id, Name, Company, LastName, OwnedBy__c, OwnerId from Lead where Id=:ld3.Id];
         System.assertEquals(null,ld3.OwnedBy__c);
         System.assertEquals(runningUser.Id, ld3.OwnerId);
         
         Test.stopTest();
      } // System.runAs
   } // testLeadOwnedBy

   // Test the owned by field. 
   static testMethod void testLeadOwnedByWithMsg() {
      setupQueues();
      // set the running user as a "Lead Loader" user so the trigger will fire
      User runningUser = UserHelper.getRunningUser();
      
      System.runAs(runningUser) {
         DataFluxDeltaServiceTest.disableDeltaTriggers();

         ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);
      
         System.assertEquals(true,UserHelper.isLeadLoader(runningUser.Name));
      
         // create the lead companies
         Lead_Company__c lc1 = new Lead_Company__c(Name='Test Lead Company 1', Postal_Code__c='12345');
         insert lc1;
         Lead ld1 = new Lead(Company=lc1.Name, LastName='Last1', LeadSource='LeadSource', OwnedBy__c='Test Inbound', Lead_Company__c=lc1.Id);
         insert ld1;

         //WebServiceSettings__c webSetting = new WebServiceSettings__c(Name='Lead Loader Test',IsActive__c=true, EndPoint__c=ISDCMsgMock.MOCK_URL, MsgBody__c='TestMsgBody');
         //insert webSetting;

      } // System.runAs
   } // testLeadOwnedByWithMsg

    //Tests for setting the StrategicAccountPartner from the Referral Contact
    static testMethod void testStrategicAccountPartner()
    {
        Referral_Account__c refAcct = new Referral_Account__c(Name = 'Referral Account1'
                                                               ,RecordTypeId=RecordTypeHelper.getRecordType('Sales Channel Referral Account Record Type', 'Referral_Account__c').getRecordTypeId()
                                                               ,Referral_Type__c = '52 Bank Tier 2'
                                                               ,Zip_Postal_Code__c = '10000');
        insert refAcct;
        
        Referral_Contact__c refCtct = new Referral_Contact__c(Name = 'Ref Ctct'
                                                             ,Referral_Account__c = refAcct.Id);
        insert refCtct;
        
        Lead ld = new Lead(Company = 'Test Lead 1', LastName='Test Lead 1', LeadSource='Referral-Strategic Account', Referral_Contact__c=refCtct.Id);
        insert ld;
        
        Lead[] ld1 = [SELECT Id, Name, Referral_National_Account__c FROM Lead WHERE Id=:ld.Id];
        System.assertEquals(1, ld1.size());
        System.assertEquals(refAcct.Id, ld1[0].Referral_National_Account__c);
                                                              
        //Lead ld1
    }
        //Tests for setting the StrategicAccountPartner from the Referral Contact
    static testMethod void testhandleReferralOwnershipDriftLeads()
    {   
        User vsu = [SELECT Name,Id FROM User WHERE Name='Virtual Sales' AND Sales_Org__c='PAY' LIMIT 1];
        Lead ld = new Lead(Company = 'Test Lead 1', LastName='Test Lead 1', LeadSource='Referral-Strategic Account', OwnerId = Label.Drift_Chat_Queue_Id);
        insert ld;
        
        ld.OwnerId = vsu.Id;
        TriggerMethods.clearVariables();
        Test.startTest();
        update ld;
        test.stopTest();
        
        Lead[] ld1 = [SELECT Id FROM Lead WHERE Id=:ld.Id];
        System.assertEquals(1, ld1.size());
                                                              
        //Lead ld1
    } // testhandleReferralOwnershipDriftLeads
    
    static testMethod void testMisc() {
       Lead ld = new Lead(Company = 'Test Lead', LastName='LastName', FirstName='FirstName', Dialed__c=true);
       insert ld;
       
    } // testMisc

} // class LeadMethodsTest