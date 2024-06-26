/** Test Methods for the TaskHelper class
 *
 * History
 * -------
 * 08/28/2014 Dan Carmen        Created.
   10/11/2014 Dan Carmen        Added more logic to set campaign info
   11/06/2014 Dan Carmen        Add in logic to set LeadSource
   11/19/2014 Dan Carmen        Additional logic for setting the call disposition
   02/20/2015 Dan Carmen        Callback on PO record, only process NSS tasks if owned by NSR
   03/16/2015 Dan Carmen        Change to handle opportunities created at the exact same time
   03/26/2015 Dan Carmen        Logic to not set latest campaign if was already set within a specified period of time.
   04/30/2015 Dan Carmen        Change day range to check for created date. Opened up the search for opportunities to base it 
                                    off of the NSS Source.
   02/09/2016 Lynn Michels      Add method to test chatter post on Reference Online Services object when Task is completed 
   09/21/2016 Jacob Hinds       Method for linkPartnerReferral method 
   02/02/2017 Jacob Hinds       Additional coverage for the above addition 
   03/29/2017 Dan Carmen        Added ability to search for leads/contacts/acounts on orphaned tasks
   05/02/2017 Jacob Hinds       Updates to testlinkPartnerReferral
   06/12/2017 Dan Carmen         Add logic for inbound calls to create partner referral and referral
   07/13/2017 Jacob Hinds     Updates to testlinkPartnerReferral
   12/27/2017 Dan Carmen        Adjust code for checking for existing partner referral
   08/14/2018 Dan Carmen        Adjust for recursion - check the disposition also.
   12/10/2018 Dan Carmen        Replace qbdialer__Call_Date_Time__c with CallDateTime__c
   02/12/2019 Dan Carmen        Additional Callback changes
   11/25/2019 Cindy Freeman     add test to call Disposition on master Partner Referral 
   04/09/2020 Dan Carmen        Changed to use CreateTestData for contact record type.
   03/22/2021 Brandon Vidro     Added test for creating orphan record for Drift chats
   06/14/2021 Pujitha Madamanchi Added Campaign Source Type
   10/20/2021 Pujitha Madamanchi Added testPartRefeason()
   12/03/2021 Dan Carmen           Fix so a Task will only update a touchpoint once
   11/01/2023 Jaipal            Added testupdateTaskStatus
   01/02/2024 Pujitha Madamanchi   Remove timeframe check to populate latestCampaign
*/
@isTest
private class TaskHelperTest {
   
   @testSetup
   public static void setupData() {
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerSetup__c trigSetup1 = TriggerMethodsTest.createCustomSetting(null, 'TaskAfter', false, true, new String[]{'TaskHelper'},setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;
      LeadCallDisposition__c lcd1a = new LeadCallDisposition__c(Name='Contacted',CallDisposition__c='Contacted',CurrentLeadStatus__c=null,NewLeadStatus__c='Contacted',EndOwnership__c=false,AssignToQueue__c=null, InboundActivityCheck__c=true,UseForFirstContact__c=true,UseForPartRef__c=true,SetWorkable__c='Workable');
      LeadCallDisposition__c lcd3a = new LeadCallDisposition__c(Name='BadNumber',CallDisposition__c='Bad Number',CurrentLeadStatus__c=null,NewLeadStatus__c='Disqualified',EndOwnership__c=false,AssignToQueue__c=null,UseForFirstContact__c=true,UseForPartRef__c=true,SetWorkable__c='Not Workable');
      LeadCallDisposition__c lcd4a = new LeadCallDisposition__c(Name='EndCadence',CallDisposition__c='End Cadence',CurrentLeadStatus__c=null,NewLeadStatus__c='Disqualified',EndOwnership__c=false,AssignToQueue__c=null,UseForFirstContact__c=true,UseForPartRef__c=true,SetWorkable__c='Not Workable',CadenceCloseCAR__c='LCD End Cadence',CadenceEndTouchpoint__c=true, MarketingStage__c='Reject');
      LeadCallDisposition__c lcd4b = new LeadCallDisposition__c(Name='EndTouchpoint',CallDisposition__c='End Touchpoint',CurrentLeadStatus__c=null,NewLeadStatus__c='Disqualified',EndOwnership__c=false,AssignToQueue__c=null,UseForFirstContact__c=true,UseForPartRef__c=true,SetWorkable__c='Not Workable',CadenceCloseCAR__c=null,CadenceEndTouchpoint__c=true);
      LeadCallDisposition__c[] lcds = new LeadCallDisposition__c[]{lcd1a,lcd3a,lcd4a,lcd4b};
      insert lcds;

   } // setupData

   static testMethod void testAddCampaign() {
      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true, StartDate=Date.today(), ACD_Name__c='ACDTest1', LeadSource__c='LeadSource1',Source_Type__c='Inbound Call');
      Campaign camp2 = new Campaign(Name='Campaign2', IsActive=true, StartDate=Date.today(), ACD_Name__c='ACDTest2', LeadSource__c='LeadSource2',Source_Type__c='Inbound Call');
      Campaign camp3 = new Campaign(Name='Campaign3', IsActive=true, StartDate=Date.today(), LeadSource__c='LeadSource3', CallListName__c='TestList3',Source_Type__c='Inbound Call');
      Campaign camp4 = new Campaign(Name='Campaign4', IsActive=true, StartDate=Date.today(), LeadSource__c='LeadSource4', CallListName__c='TestList4',Source_Type__c='Inbound Call');
      Campaign camp5 = new Campaign(Name='Campaign5', IsActive=true, StartDate=Date.today(), LeadSource__c='LeadSource5', CallListName__c='TestList5',Source_Type__c='Inbound Call');
      Campaign camp6 = new Campaign(Name='Campaign6', IsActive=true, StartDate=Date.today(), ACD_Name__c='ACDTest6', LeadSource__c=null);
      
      Campaign[] camps = new Campaign[]{camp1,camp2,camp3,camp4,camp5,camp6};
      insert camps;
      System.debug('camps='+camps);
      
//      ISDCListName__c list3 = new ISDCListName__c(Name='TestList3',Campaign__c=camp3.Id);
//      ISDCListName__c list4 = new ISDCListName__c(Name='TestList4',Campaign__c=camp4.Id);
//      ISDCListName__c list5 = new ISDCListName__c(Name='TestList5',Campaign__c=camp5.Id);
//      ISDCListName__c[] lists = new ISDCListName__c[]{list3,list4,list5};
//      insert lists;
      
      Lead l1 = new Lead(LastName='TestLast1', Company='Test Lead Company1', PostalCode='14624');
      Lead l2 = new Lead(LastName='TestLast2', Company='Test Lead Company2', PostalCode='14624');
      Lead l3 = new Lead(LastName='TestLast3', Company='Test Lead Company3', PostalCode='14624');
      Lead l4 = new Lead(LastName='TestLast4', Company='Test Lead Company4', PostalCode='14624',LeadSource='OriginalLeadSource4');
      Lead l5 = new Lead(LastName='TestLast5', Company='Test Lead Company5', PostalCode='14624');
      Lead l6 = new Lead(LastName='TestLast6', Company='Test Lead Company6', PostalCode='14624');
      Lead[] leads = new Lead[]{l1,l2,l3,l4,l5,l6};
      insert leads;
      
      Account acct1 = new Account(Name='Test Account 1');
      Account acct2 = new Account(Name='Test Account 2');
      Account acct3 = new Account(Name='Test Account 3');
      Account acct4 = new Account(Name='Test Account 4');
      Account acct5 = new Account(Name='Test Account 5');
      Account acct6 = new Account(Name='Test Account 6');
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5,acct6};
      insert accts;
      
      Schema.Recordtypeinfo ctctRt = CreateTestData.getDefaultSalesContactRT();

      //Contact c1 = new Contact(AccountId=acct1.Id, LastName='CtctTestLast1');
      //Contact c2 = new Contact(AccountId=acct1.Id, LastName='CtctTestLast2');
      Contact c3 = new Contact(AccountId=acct1.Id, RecordTypeId=ctctRt.getRecordTypeId(), LastName='CtctTestLast3');
      Contact c4 = new Contact(AccountId=acct1.Id, LastName='CtctTestLast4');
      Contact c5 = new Contact(AccountId=acct2.Id, RecordTypeId=ctctRt.getRecordTypeId(), LastName='CtctTestLast5');
      Contact c6 = new Contact(AccountId=acct3.Id, RecordTypeId=ctctRt.getRecordTypeId(), LastName='CtctTestLast6');
      Contact c7 = new Contact(AccountId=acct4.Id, RecordTypeId=ctctRt.getRecordTypeId(), LastName='CtctTestLast7');
      Contact c8 = new Contact(AccountId=acct5.Id, RecordTypeId=ctctRt.getRecordTypeId(), LastName='CtctTestLast8');
      Contact c9 = new Contact(AccountId=acct6.Id, RecordTypeId=ctctRt.getRecordTypeId(), LastName='CtctTestLast9');
      Contact[] ctcts = new Contact[]{c3,c4,c5,c6,c7,c8,c9};
      insert ctcts;
      
      acct1.SignificantContact__c = c3.Id;
      update acct1;
      
      User[] nsrs = ProspectOwnershipMethodsTest.getOutboundNSRs(2);
      User nsr1 = nsrs[0];
      
      // inserted individually so that time stamp is slightly different.
      Opportunity opp1 = new Opportunity(AccountId=acct3.Id, Name='Test Opp 1', CloseDate=Date.today(), StageName='Pending', NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      //insert opp1;
      Opportunity opp2 = new Opportunity(AccountId=acct4.Id, Name='Test Opp 2', CloseDate=Date.today(), StageName='Pending', NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      //insert opp2;
      Opportunity opp3 = new Opportunity(AccountId=acct4.Id, Name='Test Opp 3', CloseDate=Date.today(), StageName='Pending', NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      //insert opp3;
      Opportunity opp4 = new Opportunity(AccountId=acct4.Id, Name='Test Opp 4', CloseDate=Date.today(), StageName='Pending', NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      //insert opp4;
      Opportunity opp5 = new Opportunity(AccountId=acct5.Id, Name='Test Opp 5', CloseDate=Date.today(), StageName='Pending', NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      //insert opp5;
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4,opp5};
      insert opps;
      
      OpportunityTeamMember otm1 = new OpportunityTeamMember(OpportunityId=opp1.Id, UserId=nsr1.Id,TeamMemberRole='Test');
      OpportunityTeamMember otm2 = new OpportunityTeamMember(OpportunityId=opp2.Id, UserId=nsr1.Id,TeamMemberRole='Test');
      OpportunityTeamMember otm3 = new OpportunityTeamMember(OpportunityId=opp3.Id, UserId=nsr1.Id,TeamMemberRole='Test');
      OpportunityTeamMember otm4 = new OpportunityTeamMember(OpportunityId=opp4.Id, UserId=nsr1.Id,TeamMemberRole='Test');
      OpportunityTeamMember otm5 = new OpportunityTeamMember(OpportunityId=opp5.Id, UserId=nsr1.Id,TeamMemberRole='Test');
      OpportunityTeamMember[] otms = new OpportunityTeamMember[]{otm1,otm2,otm3,otm4,otm5};
      insert otms;
      
      
      Id nssTaskRtId = TaskHelper.getNSSTaskRecordTypeId();

      Schema.RecordTypeInfo rtOutbound = CallCenterHelper.getOutboundRt();

      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      DS_Denali__DialSource_Action__c actionA = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Inbound_DNIS_Name__c=camp1.ACD_Name__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id);
      DS_Denali__DialSource_Action__c actionB = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Inbound_DNIS_Name__c=camp2.ACD_Name__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id);
      DS_Denali__DialSource_Action__c actionF = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Inbound_DNIS_Name__c=camp6.ACD_Name__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id);

      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Call_Campaign__c=camp3.CallListName__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id);
      DS_Denali__DialSource_Action__c action2 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Call_Campaign__c=camp3.CallListName__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id);
      DS_Denali__DialSource_Action__c action3 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Call_Campaign__c=camp4.CallListName__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id);
      DS_Denali__DialSource_Action__c action4 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Call_Campaign__c=camp4.CallListName__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id);
      DS_Denali__DialSource_Action__c action5 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Call_Campaign__c=camp4.CallListName__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id);
      DS_Denali__DialSource_Action__c action6 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Call_Campaign__c=camp5.CallListName__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id);
      DS_Denali__DialSource_Action__c[] actions = new DS_Denali__DialSource_Action__c[]{actionA,actionB,actionF,action1,action2,action3,action4,action5,action6};
      insert actions;


      // set to 60 minutes for testing purposes minutes x seconds * milliseconds
      TaskHelper.MAX_DIFF = 60*60*1000;
      // take this out of this test
      TaskHelper.DATE_RANGE = -1;
      

      Task[] tasks = new Task[]{};
      tasks.add(new Task(Subject='Task1',OwnerId=nsr1.Id, WhoId=l1.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionA.Id, RecordTypeId=nssTaskRtId));
      tasks.add(new Task(Subject='Task2',OwnerId=nsr1.Id, WhoId=l2.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionA.Id, RecordTypeId=nssTaskRtId));
      tasks.add(new Task(Subject='Task3',OwnerId=nsr1.Id, WhoId=l3.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionB.Id, RecordTypeId=nssTaskRtId));
      tasks.add(new Task(Subject='Task4',OwnerId=nsr1.Id, WhoId=c3.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionB.Id, RecordTypeId=nssTaskRtId));

      tasks.add(new Task(Subject='Task5',OwnerId=nsr1.Id, WhoId=l4.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action1.Id, RecordTypeId=nssTaskRtId, CallDateTime__c=DateTime.now().addMinutes(2)));
      tasks.add(new Task(Subject='Task6',OwnerId=nsr1.Id, WhoId=c5.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action2.Id, RecordTypeId=nssTaskRtId, CallDateTime__c=DateTime.now().addMinutes(3)));
      tasks.add(new Task(Subject='Task7',OwnerId=nsr1.Id, WhatId=acct3.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action3.Id, RecordTypeId=nssTaskRtId, CallDateTime__c=DateTime.now().addMinutes(4)));
      tasks.add(new Task(Subject='Task8',OwnerId=nsr1.Id, WhatId=acct4.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action4.Id, RecordTypeId=nssTaskRtId, CallDateTime__c=DateTime.now().addMinutes(5)));
      tasks.add(new Task(Subject='Task9',OwnerId=nsr1.Id, WhatId=acct4.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action5.Id, RecordTypeId=nssTaskRtId, CallDateTime__c=DateTime.now().addMinutes(7)));

      // this should be outside the time frame so shouldn't attach to the opportunity
      tasks.add(new Task(Subject='Task10',OwnerId=nsr1.Id, WhoId=l5.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action6.Id, RecordTypeId=nssTaskRtId, CallDateTime__c=DateTime.now().addHours(12)));
      tasks.add(new Task(Subject='Task11',OwnerId=nsr1.Id, WhatId=acct5.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action6.Id, RecordTypeId=nssTaskRtId, CallDateTime__c=DateTime.now().addHours(12)));
      
      // will add the campaign but there will not be a lead source
      tasks.add(new Task(Subject='Task12',OwnerId=nsr1.Id, WhoId=l6.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionF.Id, RecordTypeId=nssTaskRtId));
      tasks.add(new Task(Subject='Task13',OwnerId=nsr1.Id, WhoId=c9.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionF.Id, RecordTypeId=nssTaskRtId));
      insert tasks;

      CampaignMember[] campMembers = [Select Id, CampaignId from CampaignMember];
      Map<Id, Integer> campMemberCntMap = new Map<Id, Integer>();
      for (CampaignMember campMember : campMembers) {
         Integer nbrRecs = (campMemberCntMap.containsKey(campMember.CampaignId) ? campMemberCntMap.get(campMember.CampaignId) : 0);
         nbrRecs++;
         campMemberCntMap.put(campMember.CampaignId, nbrRecs);
      }
      
      // should be a campaign member created for each task, unique on an account
      System.assertEquals(2, campMemberCntMap.get(camp1.Id)); //[Select count() from CampaignMember where CampaignId=:camp1.Id]);
      System.assertEquals(2, campMemberCntMap.get(camp2.Id)); //[Select count() from CampaignMember where CampaignId=:camp2.Id]);
      System.assertEquals(2, campMemberCntMap.get(camp3.Id)); //[Select count() from CampaignMember where CampaignId=:camp3.Id]);
      System.assertEquals(2, campMemberCntMap.get(camp4.Id)); //[Select count() from CampaignMember where CampaignId=:camp4.Id]);
      
      System.assertEquals(2, campMemberCntMap.get(camp5.Id)); //[select count() from CampaignMember where CampaignId=:camp5.Id]);

      Map<Id, Lead> leadMap = new Map<Id,Lead>([Select Id, Name, LatestCampaign__c, LeadSource from Lead]);
      
      l1 = leadMap.get(l1.Id);
      System.debug('testAddCampaign l1='+l1);
      System.assertEquals(camp1.Id, l1.LatestCampaign__c);
      System.assertEquals(camp1.LeadSource__c, l1.LeadSource);
      
      l2 = leadMap.get(l2.Id);
      System.debug('testAddCampaign l2='+l2);
      System.assertEquals(camp1.Id, l2.LatestCampaign__c);
      System.assertEquals(camp1.LeadSource__c, l2.LeadSource);
      
      l3 = leadMap.get(l3.Id);
      System.debug('testAddCampaign l3='+l3);
      System.assertEquals(camp2.Id, l3.LatestCampaign__c);
      System.assertEquals(camp2.LeadSource__c, l3.LeadSource);
      
      l4 = leadMap.get(l4.Id);
      System.debug('testAddCampaign l4='+l4);
      System.assertEquals(camp3.Id, l4.LatestCampaign__c);
      System.assertEquals('OriginalLeadSource4', l4.LeadSource);

      l6 = leadMap.get(l6.Id);
      System.debug('testAddCampaign l6='+l6);
      //System.assertEquals(camp3.Id, l4.LatestCampaign__c);
      System.assertEquals(null, l6.LeadSource);
      
      Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id, Name, AccountId, LatestCampaign__c, LeadSource from Contact]);
      //System.assertEquals(0,[select count() from Contact where Id=:c1.Id and LatestCampaign__c=:camp1.Id and LeadSource=:camp1.LeadSource__c]);
      //System.assertEquals(0,[select count() from Contact where Id=:c2.Id and LatestCampaign__c=:camp1.Id and LeadSource=:camp1.LeadSource__c]);
      c3 = ctctMap.get(c3.Id);
      System.debug('testAddCampaign c3='+c3);
      System.assertEquals(camp2.Id, c3.LatestCampaign__c);
      System.assertEquals(camp2.LeadSource__c, c3.LeadSource);

      c4 = ctctMap.get(c4.Id);
      System.debug('testAddCampaign c4='+c4);
      System.assertEquals(null, c4.LatestCampaign__c);
      //System.assertEquals(camp2.LeadSource__c, c4.LeadSource);

      c5 = ctctMap.get(c5.Id);
      System.debug('testAddCampaign c5='+c5);
      System.assertEquals(camp3.Id, c5.LatestCampaign__c);
      System.assertEquals(camp3.LeadSource__c, c5.LeadSource);

      c6 = ctctMap.get(c6.Id);
      System.debug('testAddCampaign c6='+c6);
      System.assertEquals(camp4.Id, c6.LatestCampaign__c);
      System.assertEquals(camp4.LeadSource__c, c6.LeadSource);

      c7 = ctctMap.get(c7.Id);
      System.debug('testAddCampaign c7='+c7);
      System.assertEquals(camp4.Id, c7.LatestCampaign__c);
      System.assertEquals(camp4.LeadSource__c, c7.LeadSource);

      c9 = ctctMap.get(c9.Id);
      System.debug('testAddCampaign c9='+c9);
      //System.assertEquals(camp4.Id, c9.LatestCampaign__c);
      System.assertEquals(null, c9.LeadSource);

      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, AccountId, Campaign__c, LeadSource from Opportunity]);
      opp1 = oppMap.get(opp1.Id);
      System.assertEquals(camp4.Id, opp1.Campaign__c);
      System.assertEquals(camp4.LeadSource__c, opp1.LeadSource);

      opp5 = oppMap.get(opp5.Id);
      System.assertEquals(null, opp5.Campaign__c);
      //System.assertEquals(camp4.LeadSource__c, opp1.LeadSource);
      
      Integer nbrAcct4Opps = 0;
      for (Opportunity opp : oppMap.values()) {
         if (opp.AccountId == acct4.Id && opp.Campaign__c == camp4.Id) {
            nbrAcct4Opps++;
         }
      }
      System.assertEquals(true, nbrAcct4Opps>0); 

      // add a lead source to the campaign
      camp6.LeadSource__c = 'LeadSource6';
      update camp6;
      
      //LeadCallDisposition__c[] callDispositions = LeadMethodsTest.createLeadCallDispositions();

      // since they're attached to the same campaign, shouldn't trigger the latest campaign trigger and instead hit a different part of the code
      // to check the lead source
      tasks = new Task[]{};
      for (LeadCallDisposition__c lcd : LeadCallDisposition__c.getAll().values()) {
         tasks.add(new Task(OwnerId=nsr1.Id, WhoId=l6.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionF.Id, Status='Completed', CallType=TaskHelper.CT_OUTBOUND, RecordTypeId=nssTaskRtId, CallDisposition=lcd.Name));
         tasks.add(new Task(OwnerId=nsr1.Id, WhoId=c9.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionF.Id, Status='Completed', CallType=TaskHelper.CT_INBOUND, RecordTypeId=nssTaskRtId, CallDisposition=lcd.Name));
      }
      TaskHelper.clearVariables();
      Test.startTest();
      insert tasks;
      Test.stopTest();
      
      l6 = [Select Id, LeadSource from Lead where Id=:l6.Id];
      System.assertEquals(camp6.LeadSource__c,l6.LeadSource);
      c9 = [Select Id, Name, LeadSource from Contact where Id=:c9.Id];
      System.assertEquals(camp6.LeadSource__c,c9.LeadSource);
      

   } // testAddCampaign

   static testMethod void testPoCallback() {
      // create account
      Account acct1 = new Account(Name='Test acct1');
      Account acct2 = new Account(Name='Test acct2');
      Account[] accts = new Account[]{acct1,acct2};
      insert accts;
      
      // create contacts
      Contact ctct1 = new Contact(LastName='TestCtct1', AccountId=acct1.Id);
      Contact ctct2 = new Contact(LastName='TestCtct2', AccountId=acct2.Id);
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      insert ctcts;
      
      // create lead
      Lead ld1 = new Lead(LastName='TestLead1', Company='Company1');
      Lead ld2 = new Lead(LastName='TestLead2', Company='Company2');
      Lead[] leads = new Lead[]{ld1,ld2};
      insert leads;
      
      // retrieve NSRs
      User[] nsrs = ProspectOwnershipMethodsTest.getOutboundNSRs(2);
      User nsr1 = nsrs[0];
      User nsr2 = nsrs[1];
      
      // create ownership records
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Prospect_Client__c=acct1.Id, Decision_Maker__c=ctct1.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=nsr1.Id);

      Prospect_Ownership__c po2 = new Prospect_Ownership__c(Prospect_Client__c=acct2.Id, Decision_Maker__c=ctct2.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=nsr2.Id);

      Prospect_Ownership__c po3 = new Prospect_Ownership__c(Lead__c=ld1.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=nsr1.Id);

      Prospect_Ownership__c po4 = new Prospect_Ownership__c(Lead__c=ld2.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,LockoutStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,NSR_Name__c=nsr2.Id);
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2,po3,po4};
      insert pos;

      Id nssTaskRtId = TaskHelper.getNSSTaskRecordTypeId();

      // create callback tasks
      Task tsk1 = new Task(RecordTypeId=nssTaskRtId, Subject='test1', Type=TaskHelper.CT_CALLBACK,OwnerId=nsr1.Id, WhoId=ctct1.Id, ReminderDateTime=DateTime.now().addDays(3));
      // this one shouldn't do anything because the task owner doesn't match the ownership record
      Task tsk2 = new Task(RecordTypeId=nssTaskRtId, Subject='test2', Type=TaskHelper.CT_CALLBACK,OwnerId=nsr1.Id, WhatId=acct2.Id, ReminderDateTime=DateTime.now().addDays(3));
      // this should work
      Task tsk3 = new Task(RecordTypeId=nssTaskRtId, Subject='test3', Type=TaskHelper.CT_CALLBACK,OwnerId=nsr1.Id, WhoId=ld1.Id, ReminderDateTime=DateTime.now().addDays(3));
      // this shouldn't do anything because the ownership is in lockout
      Task tsk4 = new Task(RecordTypeId=nssTaskRtId, Subject='test4', Type=TaskHelper.CT_CALLBACK,OwnerId=nsr2.Id, WhoId=ld2.Id, ReminderDateTime=DateTime.now().addDays(3));
      Task[] tsks = new Task[]{tsk1,tsk2,tsk3,tsk4};
      Test.startTest();
      TaskHelper.SKIP_PO_FUTURE = false;
      insert tsks;
      Test.stopTest();

      TaskHelper.SKIP_PO_FUTURE = true;
      
      // should be 2 PO Callback records created
      System.assertEquals(2,[select count() from ProspectOwnershipCallback__c]);
      
      // change po4 to prospecting, update tsk4 so it triggers again.
      po4.LockoutStart__c = null;
      po4.ProspectingStart__c = Date.today().addDays(-5);
      po4.Ownership_Status__c = ProspectOwnershipMethods.STAGE_PROSPECTING;
      update po4;
      
      TaskHelper.handledTaskIdMap.clear();
      tsk4.ReminderDateTime = DateTime.now().addDays(4);
      System.debug('testPoCallback updating tasks');
      TaskHelper.clearVariables();
      update tsk4;

      // should now be 3 PO Callback records created
      System.assertEquals(3,[select count() from ProspectOwnershipCallback__c]);
      
      System.debug('testPoCallback deleting tasks');
      TaskHelper.clearVariables();
      delete tsks;
      // callbacks should be deleted
      System.assertEquals(0,[select count() from ProspectOwnershipCallback__c]);
      
   } // testPoCallback

   // check that the latest campaign/opp campaign isn't overwritten if a task comes in within a 
   static testMethod void testLatestCampaignTime() {
      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true, StartDate=Date.today(), ACD_Name__c='ACDTest1', LeadSource__c='LeadSource1',Source_Type__c='Inbound Call');
      Campaign camp2 = new Campaign(Name='Campaign2', IsActive=true, StartDate=Date.today(), ACD_Name__c='ACDTest2', LeadSource__c='LeadSource2',Source_Type__c='Inbound Call');
      Campaign[] camps = new Campaign[]{camp1,camp2};
      insert camps;
      
      Account acct1 = new Account(Name='Test Account 1');
      Account acct2 = new Account(Name='Test Account 2');
      Account[] accts = new Account[]{acct1,acct2};
      insert accts;
      
      Schema.Recordtypeinfo ctctRt = CreateTestData.getDefaultSalesContactRT();
      
      Contact c1 = new Contact(AccountId=acct1.Id, RecordTypeId=ctctRt.getRecordTypeId(), LastName='CtctTestLast1', Sales_Contact__c=true, LatestCampaign__c=camp1.Id);
      Contact c2 = new Contact(AccountId=acct2.Id, RecordTypeId=ctctRt.getRecordTypeId(), LastName='CtctTestLast2', Sales_Contact__c=true, LatestCampaign__c=camp1.Id);
      Contact[] ctcts = new Contact[]{c1,c2};
      insert ctcts;
      
      acct1.SignificantContact__c = c1.Id;
      acct2.SignificantContact__c = c2.Id;
      update accts;
      
      // verify latest campaign date is filled in
      System.assertEquals(2,[Select count() from Contact where Id in :ctcts and LatestCampaignDate__c != null]);
      
      // verify significant contact is set.
      System.assertEquals(1,[select count() from Account where Id=:acct1.Id and SignificantContact__c=:c1.Id]);
      System.assertEquals(1,[select count() from Account where Id=:acct2.Id and SignificantContact__c=:c2.Id]);
      
      User[] nsrs = ProspectOwnershipMethodsTest.getOutboundNSRs(2);
      User nsr1 = nsrs[0];
      
      // inserted individually so that time stamp is slightly different.
      Opportunity opp1 = new Opportunity(AccountId=acct1.Id, Name='Test Opp 1', CloseDate=Date.today(), StageName='Pending', LeadSource='Opp1Source', NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      Opportunity opp2 = new Opportunity(AccountId=acct2.Id, Name='Test Opp 2', CloseDate=Date.today(), StageName='Pending', LeadSource='Opp2Source', NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      Opportunity[] opps = new Opportunity[]{opp1,opp2};
      insert opps;
      
      OpportunityTeamMember otm1 = new OpportunityTeamMember(OpportunityId=opp1.Id, UserId=nsr1.Id,TeamMemberRole='Test');
      OpportunityTeamMember otm2 = new OpportunityTeamMember(OpportunityId=opp2.Id, UserId=nsr1.Id,TeamMemberRole='Test');
      OpportunityTeamMember[] otms = new OpportunityTeamMember[]{otm1,otm2};
      insert otms;
      
      Schema.RecordTypeInfo rtOutbound = CallCenterHelper.getOutboundRt();

      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      DS_Denali__DialSource_Action__c actionA = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Inbound_DNIS_Name__c=camp2.ACD_Name__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id);
      insert actionA;

      Id nssTaskRtId = TaskHelper.getNSSTaskRecordTypeId();

      // set to 300 minutes for testing purposes minutes x seconds * milliseconds
      TaskHelper.MAX_DIFF = 300*60*1000;
      // date range is in hours
      TaskHelper.DATE_RANGE = 2;
      TaskHelper.CALL_HOURS_OFFSET = 4;

      Task[] tasks = new Task[]{};
      tasks.add(new Task(OwnerId=nsr1.Id, WhoId=c1.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionA.Id, RecordTypeId=nssTaskRtId, CallDateTime__c=DateTime.now().addMinutes(2)));
      tasks.add(new Task(OwnerId=nsr1.Id, WhatId=acct2.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionA.Id, RecordTypeId=nssTaskRtId, CallDateTime__c=DateTime.now().addHours(1)));
      insert tasks;

      // nothing should change on the contacts/opps because they fall within the time frame.
      // still attached to the same campaign
      //As we removed the time frame to set latestCampaign, both should be attached to the new campaign
      System.assertEquals(2,[Select count() from Contact where Id in :ctcts and LatestCampaign__c=:camp2.Id]);
      // opps don't have a campaign set
      //System.assertEquals(2,[Select count() from Opportunity where Id in :opps and Campaign__c=null]);

      TaskHelper.clearVariables();

      /* This scenario is no longer valid as we've removed the timeframe to set latestcampaign
      // these tasks should fall outside the time frame, so the records should update
      Task[] tasks2 = new Task[]{};
      tasks2.add(new Task(OwnerId=nsr1.Id, WhoId=c1.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionA.Id, RecordTypeId=nssTaskRtId, CallDateTime__c=DateTime.now().addHours(3)));
      tasks2.add(new Task(OwnerId=nsr1.Id, WhatId=acct2.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=actionA.Id, RecordTypeId=nssTaskRtId, CallDateTime__c=DateTime.now().addHours(3)));
      insert tasks2;
      
      // should update to the second campaign
      System.assertEquals(2,[Select count() from Contact where Id in :ctcts and LatestCampaign__c=:camp2.Id]);
      // opps have a campaign set
      System.assertEquals(2,[Select count() from Opportunity where Id in :opps and Campaign__c=:camp2.Id]); 
      */

   } // testLatestCampaignTime

   @isTest(SeeAllData=false)  //needed to check chatter posts using ConnectAPI
   static void testChatterPostOnClosedTask() {
      TaskHelper.getNSSTaskRecordTypeId();
      ID mspOnboardingTaskRtId = TaskHelper.mSPOnboardingTaskRtId;
      
      ID MMSTaskRecordTypeRTId  = RecordTypeHelper.getRecordType('MMS Task Record Type', 'Task').getRecordTypeId();
      ID serviceOnboardingMSPRefObjectRTId  = RecordTypeHelper.getRecordType('Service Onboarding MSP Ref Object', 'Reference_HRO__c').getRecordTypeId();
      ID serviceOnboardingMSPAddOnModuleRefObjectRTId  = RecordTypeHelper.getRecordType('Service Onboarding MSP Add On Module Ref Object', 'Reference_HRO__c').getRecordTypeId();
        
        Reference_HRO__c refOnlineServ = new Reference_HRO__c(RecordTypeId = serviceOnboardingMSPRefObjectRTId);
        insert refOnlineServ;
        
        Task t_wrongRT = new Task(RecordTypeId = MMSTaskRecordTypeRTId,
                        WhatId = refOnlineServ.id,
                        Subject = 'Wrong Task Record Type ',
                        Status = 'Not Started');
        insert t_wrongRT;
        
        System.assertEquals(0,ChatterMentionPost.feedItemsToPostSize);
        //List<feedItem> refFeedItem;
        //refFeedItem = [SELECT Id, Body FROM feedItem WHERE parentId =: refOnlineServ.id];
        //System.assertEquals(0, refFeedItem.size());
        
        t_wrongRT.Status = 'Completed';
        update t_wrongRT;
        //wrong record type - should not post to chatter
        System.assertEquals(0,ChatterMentionPost.feedItemsToPostSize);
        //refFeedItem = [SELECT Id, Body FROM feedItem WHERE parentId =: refOnlineServ.id];
        //System.assertEquals(0, refFeedItem.size());
        
        Task t = new Task(RecordTypeId = mspOnboardingTaskRtId,
                        WhatId = refOnlineServ.id,
                        Subject = 'Subject Test',
                        Status = 'Not Started');
        insert t;
        System.assertEquals(0,ChatterMentionPost.feedItemsToPostSize);
        //refFeedItem = [SELECT Id, Body FROM feedItem WHERE parentId =: refOnlineServ.id];
        //System.assertEquals(0, refFeedItem.size());

        t.Status = 'Completed';
        update t;
        
        System.assertEquals(1,ChatterMentionPost.feedItemsToPostSize);
        //refFeedItem = [SELECT Id, Body FROM feedItem WHERE parentId =: refOnlineServ.id];
        //System.assertEquals(1, refFeedItem.size());
        //System.assertEquals(true, refFeedItem[0].Body.contains('Task "Subject Test" has been completed.')); 

   }// end testChatterPostOnClosedTask

    @isTest
    static void testlinkPartnerReferral(){
        User runningUser = UserHelper.getRunningUser();
        
        Account acct = new Account(Name='test');
        Account acct2 = new Account(Name='test');
        Account[] accts = new Account[]{acct,acct2};
        ZipCheckOwner.SKIP_TRIGGERS = true;
        insert accts;
        
        Contact ctct = new Contact(LastName='testCtct',AccountId=acct.Id);
        Contact ctct2 = new Contact(LastName='testCtct2',AccountId=acct.Id);
        Contact ctct3 = new Contact(LastName='testCtct3',AccountId=acct2.Id);
        Contact[] ctcts = new Contact[]{ctct,ctct2,ctct3};
        ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
        ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
        insert ctcts;
        
        lead ld = new lead (LastName = 'L', Company = 'Company');
        lead ld2 = new lead (LastName = 'L2', Company = 'C2'); 
        lead[] leads = new lead []{ld,ld2};
        LeadMethods.LEAD_BEFORE_EXECUTING = true;
        LeadMethods.LEAD_AFTER_EXECUTING = true;
        insert leads; 
        
        // we want this to become the master partner referral - put in a fake id so it will 
        PartnerReferral__c partRef1 = new PartnerReferral__c(LastName__c='partRef1',Account__c = acct.Id, Contact__c = ctct.id, Source__c = ReferralController.PART_REF_SOURCE_NAME);
        PartnerReferral__c partRef3 = new PartnerReferral__c(LastName__c='partRef3',Account__c = acct2.Id, Contact__c = ctct3.id);
        PartnerReferral__c partRef4 = new PartnerReferral__c(LastName__c='partRef4',Lead__c = ld.id);  
        PartnerReferral__c[] ldPartRefs = new PartnerReferral__c[]{partRef1,partRef3,partRef4};      
        insert ldPartRefs;
        
        // the master partner referrals should be older.
        Test.setCreatedDate(partRef1.Id,DateTime.now().addHours(-1));
        Test.setCreatedDate(partRef4.Id,DateTime.now().addHours(-2));
        
        PartnerReferral__c partRef2 = new PartnerReferral__c(LastName__c='partRef2',Account__c = acct.Id, Contact__c = ctct2.id,Master_Partner_Referral__c = partRef1.Id);
        // populating the ActivityId__c so it comes back as something to link to. Using ld2.Id because we want to use a real id.
        PartnerReferral__c partRef5 = new PartnerReferral__c(LastName__c='partRef5',Lead__c = ld2.id, ActivityId__c=ld2.Id, Master_Partner_Referral__c= partRef4.id);    
        PartnerReferral__c[] partRefs = new PartnerReferral__c[]{partRef2, partRef5};
        insert partRefs;
        
        //string[] callDispositions = Label.First_Contact.split(',');
        
        string callDisp = 'Contacted';     
        
        test.startTest();
        
        // should create a new one (won't match because it's an inbound task and the ones previously created are not)
        Task t1 = new Task(WhoId = ctct2.Id,Subject='Task1', CallType=TaskHelper.CT_INBOUND,Type='Call',CallDisposition='Test');
        insert t1;
        //PartnerReferral__c pRef1 = [SELECT Id,First_Call_Attempted__c,First_Contact_Made__c,Master_Partner_Referral__c FROM PartnerReferral__c WHERE Contact__c =:ctct.Id LIMIT 1];
        PartnerReferral__c pRef1 = [SELECT Id,LastName__c,First_Call_Attempted__c,First_Contact_Made__c,Master_Partner_Referral__c FROM PartnerReferral__c WHERE ActivityId__c=:t1.Id LIMIT 1];
        System.debug('testlinkPartnerReferral pRef1='+pRef1);
        system.assertNotEquals(null,pRef1.First_Call_Attempted__c);
        system.assertEquals(null,pRef1.First_Contact_Made__c);
        PartnerReferral__c pRef2 = [SELECT Id,LastName__c,First_Call_Attempted__c,First_Contact_Made__c,Master_Partner_Referral__c FROM PartnerReferral__c WHERE Id=:partRef2.Id LIMIT 1];
        System.debug('testlinkPartnerReferral pRef2='+pRef2);
        system.assertEquals(null,pRef2.First_Call_Attempted__c);
        system.assertEquals(null,pRef2.First_Contact_Made__c);
        
        Task t2 = new Task(WhoId = ctct3.Id,Subject='Task2', CallDateTime__c = system.now(),CallType=TaskHelper.CT_INBOUND,Type='Call',CallDisposition= callDisp);
        insert t2;
        PartnerReferral__c pRef3 = [SELECT Id,LastName__c,First_Call_Attempted__c,First_Contact_Made__c,Disposition__c,Master_Partner_Referral__c FROM PartnerReferral__c WHERE ActivityId__c=:t2.Id LIMIT 1];
        System.debug('testlinkPartnerReferral pRef3='+pRef3);
        system.assertEquals(t2.CallDateTime__c,pRef3.First_Call_Attempted__c);
        system.assertEquals(t2.CallDateTime__c,pRef3.First_Contact_Made__c);
        System.assertEquals(t2.CallDisposition, pRef3.Disposition__c);
        
        task t3 = new Task (whoId = ld2.id, Subject='Task3', CallDateTime__c = system.now(),CallType=TaskHelper.CT_INBOUND,Type='Call',CallDisposition= callDisp); 
        insert t3; 
        PartnerReferral__c pRef4 = [SELECT Id,LastName__c,First_Call_Attempted__c,First_Contact_Made__c,Master_Partner_Referral__c, Master_Partner_Referral__r.First_Contact_Made__c, Master_Partner_Referral__r.Disposition__c FROM PartnerReferral__c WHERE ActivityId__c=:t3.Id LIMIT 1];
        System.debug('testlinkPartnerReferral pRef4='+pRef4);
        system.assertEquals (t3.CallDateTime__c,pRef4.First_Contact_Made__c); 
        system.assertEquals (t3.CallDateTime__c,pRef4.Master_Partner_Referral__r.First_Contact_Made__c); 
        System.assertEquals(t3.CallDisposition, pRef4.Master_Partner_Referral__r.Disposition__c);
        
        Opportunity opp = new Opportunity(Name='test',StageName='Pre-Qualified',CloseDate = system.today(),AccountId = acct.Id);
        insert opp;
        Referral__c ref = new Referral__c(SourceContact__c = ctct.Id,Account__c= acct.Id,Selling_Opportunity__c = opp.Id,  PartnerReferral__c=partRef1.Id);
        insert ref;
        
        // so we reuse this partner referral
        partRef1.Referral__c = ref.Id;
        partRef1.ActivityId__c=null;
        partRef1.Source__c = ReferralController.PART_REF_SOURCE_NAME;
        update partRef1;
        
        task t4 = new Task (whoId = ctct.id, Subject='Task4', CallDateTime__c = system.now(),CallType=TaskHelper.CT_INBOUND,Type='Call',WhatId = opp.Id, CallDisposition=callDisp);
        System.debug('testlinkPartnerReferral insert task4'); 
        insert t4;
        Referral__c uRef = [SELECT Id,First_Call_Attempted__c FROM Referral__c WHERE Id = :ref.Id];
        system.assertEquals(t4.CallDateTime__c,uRef.First_Call_Attempted__c);
        
        
    } // testlinkPartnerReferral

   static testMethod void testLinkTask() {
      Account acct = new Account(Name='Account 1', Phone='5551234567');
      insert acct;
      Contact ctct = new Contact(AccountId=acct.Id, LastName='LastName', Phone='5552345678');
      insert ctct;
      Lead ld = new Lead(Company='Test Company', LastName='TestLast', Phone='5553456789');
      insert ld;
      
      //Task tsk1 = (CallDateTime__c = system.now(), )
   } // testLinkTask

   static testMethod void testInboundCalls() {
      
      User testUsr = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Job_Name__c=:UserHelper.JOB_REP limit 1];
      
      Lead ld = new Lead(OwnerId=testUsr.Id, Company='Lead Company', PostalCode='12345', LastName='LeadLast', Phone='(585) 123-4576');
      insert ld;
      
      Account acct = new Account(Name='Test Account', ShippingPostalCode='23456');
      insert acct;
      Contact ctct = new Contact(OwnerId=testUsr.Id, Hold_Out__c=true, AccountId=acct.Id, LastName='ContactLast', Phone='(585) 456-7890');
      insert ctct;
      
      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true, StartDate=Date.today(), ACD_Name__c='ACDTest1', LeadSource__c='LeadSource1',Source_Type__c='Inbound Call');
      insert camp1;
      
      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();
      System.debug('testInboundCalls rtInbound='+rtInbound);

      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c=camp1.ACD_Name__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,InboundCallerId__c=ld.Phone);
      DS_Denali__DialSource_Action__c action2 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c=camp1.ACD_Name__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,InboundCallerId__c=ctct.Phone);
      DS_Denali__DialSource_Action__c[] actions = new DS_Denali__DialSource_Action__c[]{action1,action2};
      insert actions;
       
      Map<Id,DS_Denali__DialSource_Action__c> actionMap = new Map<Id,DS_Denali__DialSource_Action__c>([Select Id, RecordTypeId from DS_Denali__DialSource_Action__c]);
      System.assertEquals(rtInbound.getRecordTypeId(), actionMap.get(action1.Id).RecordTypeId);
      System.assertEquals(rtInbound.getRecordTypeId(), actionMap.get(action2.Id).RecordTypeId);

      Task tsk1 = new Task(OwnerId=testUsr.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action1.Id, WhoId=ld.Id);
      Task tsk2 = new Task(OwnerId=testUsr.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action2.Id, WhoId=ctct.Id);
      Task[] tsks = new Task[]{tsk1,tsk2};
      
      Test.startTest();
      insert tsks;
      Test.stopTest();
      
      PartnerReferral__c partRef1 = [Select Id, Name, Account__c, Contact__c, Lead__c, Company__c, ZipPostalCode__c, LastName__c, Phone__c, Campaign__c, LeadSource__c, Source__c, Referral__c from PartnerReferral__c where Lead__c=:ld.Id];
      System.assertEquals(ld.Company, partRef1.Company__c);
      System.assertEquals(ld.PostalCode, partRef1.ZipPostalCode__c);
      System.assertEquals(ld.LastName, partRef1.LastName__c);
      System.assertEquals(ld.Phone, partRef1.Phone__c);
      System.assertEquals(camp1.Id, partRef1.Campaign__c);
      System.assertEquals(camp1.LeadSource__c, partRef1.LeadSource__c);
      System.assertEquals(TaskHelper.PART_REF_SOURCE_NAME, partRef1.Source__c);
      System.assertEquals(true, partRef1.Referral__c != null);

      Referral__c ref1 = [Select Id, OwnerId, Name, Account__c, NbrOfEmployees__c, Campaign__c, SourceContact__c, SourceLead__c
                                ,ReferralEntry__c, SellingLeadSource__c
                                ,User__c, acd_name__c, ActivityId__c, PartnerReferral__c, Referral_Id__c
                            from Referral__c
                           Where PartnerReferral__c=:partRef1.Id];
      
      System.assertEquals(ld.Id, ref1.SourceLead__c);
      System.assertEquals(camp1.Id, ref1.Campaign__c);
      System.assertEquals(camp1.LeadSource__c, ref1.SellingLeadSource__c);
      System.assertEquals(partRef1.Source__c, ref1.ReferralEntry__c);
      System.assertEquals(partRef1.Referral__c, ref1.Id);
      System.assertEquals(tsk1.Id, ref1.ActivityId__c);
      System.assertEquals(action1.DS_Denali__Inbound_DNIS_Name__c, ref1.acd_name__c);
      System.assertEquals(testUsr.Id, ref1.OwnerId);
      System.assertEquals(testUsr.Id, ref1.User__c);

      PartnerReferral__c partRef2 = [Select Id, Name, Account__c, Contact__c, Lead__c, Company__c, ZipPostalCode__c, LastName__c, Phone__c, Campaign__c, LeadSource__c, Source__c, Referral__c from PartnerReferral__c where Contact__c=:ctct.Id];
      System.assertEquals(acct.Name, partRef2.Company__c);
      System.assertEquals(acct.ShippingPostalCode, partRef2.ZipPostalCode__c);
      System.assertEquals(ctct.LastName, partRef2.LastName__c);
      System.assertEquals(ctct.Phone, partRef2.Phone__c);
      System.assertEquals(camp1.Id, partRef2.Campaign__c);
      System.assertEquals(camp1.LeadSource__c, partRef2.LeadSource__c);
      System.assertEquals(TaskHelper.PART_REF_SOURCE_NAME, partRef2.Source__c);
      System.assertEquals(true, partRef2.Referral__c != null);

      Referral__c ref2 = [Select Id, OwnerId, Name, Account__c, NbrOfEmployees__c, Campaign__c, SourceContact__c, SourceLead__c
                                ,ReferralEntry__c, SellingLeadSource__c
                                ,User__c, acd_name__c, ActivityId__c, PartnerReferral__c, Referral_Id__c
                            from Referral__c
                           Where PartnerReferral__c=:partRef2.Id];
      
      System.assertEquals(ctct.Id, ref2.SourceContact__c);
      System.assertEquals(camp1.Id, ref2.Campaign__c);
      System.assertEquals(camp1.LeadSource__c, ref2.SellingLeadSource__c);
      System.assertEquals(partRef2.Source__c, ref2.ReferralEntry__c);
      System.assertEquals(partRef2.Referral__c, ref2.Id);
      System.assertEquals(tsk2.Id, ref2.ActivityId__c);
      System.assertEquals(action2.DS_Denali__Inbound_DNIS_Name__c, ref2.acd_name__c);
      System.assertEquals(testUsr.Id, ref2.OwnerId);
      System.assertEquals(testUsr.Id, ref2.User__c);


   } // testInboundCalls

   static testMethod void testInboundExisting() {
      User testUsr = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Job_Name__c=:UserHelper.JOB_REP limit 1];
      
      Lead ld = new Lead(OwnerId=testUsr.Id, Company='Lead Company', PostalCode='12345', LastName='LeadLast', Phone='(585) 123-4576');
      Lead ld2 = new Lead(OwnerId=testUsr.Id, Company='Lead Company2', PostalCode='23456', LastName='LeadLast2', Phone='(585) 234-5678');
      Lead[] lds = new Lead[]{ld,ld2};
      insert lds;
      
      PartnerReferral__c partRef = new PartnerReferral__c(Lead__c=ld.Id, Company__c=ld.Company, Source__c=ReferralController.PART_REF_SOURCE_NAME);
      insert partRef;
      
      Referral__c ref = new Referral__c(PartnerReferral__c=partRef.Id, SourceLead__c=ld.Id);
      Referral__c ref2 = new Referral__c(SourceLead__c=ld2.Id);
      Referral__c[] refs = new Referral__c[]{ref,ref2};
      insert refs;
      
      partRef.Referral__c = ref.Id;
      update partRef;
      
      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true, StartDate=Date.today(), ACD_Name__c='ACDTest1', LeadSource__c='LeadSource1',Source_Type__c='Inbound Call');
      insert camp1;
      
      // verify 1 partner referral and referral
      System.assertEquals(1,[select count() from PartnerReferral__c where Lead__c=:ld.Id]);
      System.assertEquals(1,[select count() from Referral__c where SourceLead__c=:ld.Id]);
      


      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();

      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c=camp1.ACD_Name__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,InboundCallerId__c=ld.Phone);
      DS_Denali__DialSource_Action__c action2 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c=camp1.ACD_Name__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,InboundCallerId__c=ld2.Phone);
      DS_Denali__DialSource_Action__c[] actions = new DS_Denali__DialSource_Action__c[]{action1,action2};
      insert actions;

      Task tsk1 = new Task(OwnerId=testUsr.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action1.Id, WhoId=ld.Id, CallDisposition='Contacted' );
      Task tsk2 = new Task(OwnerId=testUsr.Id, ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action2.Id, WhoId=ld2.Id, CallDisposition='Bad Number' );
      Task[] tsks = new Task[]{tsk1,tsk2};
      
      Test.startTest();
      insert tsks;
      Test.stopTest();

      // should still be just one partner referral
      PartnerReferral__c partRef1 = [Select Id, Name, Account__c, Contact__c, Lead__c, Company__c, ZipPostalCode__c, LastName__c, Phone__c, Campaign__c, LeadSource__c, Source__c, Referral__c, Disposition__c from PartnerReferral__c where Lead__c=:ld.Id];
      System.assertEquals(ld.Company, partRef1.Company__c);
      System.assertEquals(camp1.Id, partRef1.Campaign__c);
      System.assertEquals(camp1.LeadSource__c, partRef1.LeadSource__c);
      System.assertEquals(tsk1.CallDisposition, partRef1.Disposition__c);
      
      //System.assertEquals(true, (String.isNotBlank(partRef1.Source__c) && partRef1.Source__c.startsWith('Inbound-')));
      //System.assertEquals(true, partRef1.Referral__c != null);

      Referral__c ref1 = [Select Id, OwnerId, Name, Account__c, NbrOfEmployees__c, Campaign__c, SourceContact__c, SourceLead__c
                                ,ReferralEntry__c, SellingLeadSource__c
                                ,User__c, acd_name__c, ActivityId__c, PartnerReferral__c, Referral_Id__c
                            from Referral__c
                           Where SourceLead__c=:ld.Id];
      System.assertEquals(camp1.Id, ref1.Campaign__c);
      System.assertEquals(camp1.LeadSource__c, ref1.SellingLeadSource__c);
      
      // should now be a partner referral for ld2
      PartnerReferral__c partRef2 = [Select Id, Name, Account__c, Contact__c, Lead__c, Company__c, ZipPostalCode__c, LastName__c, Phone__c, Campaign__c, LeadSource__c, Source__c, Referral__c, Disposition__c from PartnerReferral__c where Lead__c=:ld2.Id];
      System.assertEquals(ld2.Company, partRef2.Company__c);
      System.assertEquals(camp1.Id, partRef2.Campaign__c);
      System.assertEquals(camp1.LeadSource__c, partRef2.LeadSource__c);
      System.assertEquals(ref2.Id, partRef2.Referral__c);
      System.assertEquals(tsk1.CallDisposition, partRef1.Disposition__c);

      ref2 = [Select Id, OwnerId, Name, Account__c, NbrOfEmployees__c, Campaign__c, SourceContact__c, SourceLead__c
                                ,ReferralEntry__c, SellingLeadSource__c
                                ,User__c, acd_name__c, ActivityId__c, PartnerReferral__c, Referral_Id__c
                            from Referral__c
                           Where SourceLead__c=:ld2.Id];
      System.assertEquals(partRef2.Id, ref2.PartnerReferral__c);
      System.assertEquals(camp1.Id, ref2.Campaign__c);
      System.assertEquals(camp1.LeadSource__c, ref2.SellingLeadSource__c);

   } // testInboundExisting
/*
   static testMethod void testBadAcdName() {
      TaskHelper.LOG_EXCEPTIONS = true;
      User testUsr = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Job_Name__c=:UserHelper.JOB_REP limit 1];
      
      Lead ld = new Lead(OwnerId=testUsr.Id, Company='Lead Company', PostalCode='12345', LastName='LeadLast', Phone='(585) 123-4576');
      Lead[] lds = new Lead[]{ld};
      insert lds;
      
      Task tsk1 = new Task(OwnerId=testUsr.Id, ActivityDate=Date.today(), isdc_acd_name__c='BadAcdName', WhoId=ld.Id, isdc_inbound_callerid__c=ld.Phone );
      Task[] tsks = new Task[]{tsk1};
      
      insert tsks;
      
      System.assertEquals(1,[select count() from NSSCallException__c where Name='BadAcdName']);
      
      Task tsk2 = new Task(OwnerId=testUsr.Id, ActivityDate=Date.today(), isdc_acd_name__c='BadAcdName', WhoId=ld.Id, isdc_inbound_callerid__c=ld.Phone );
      insert tsk2;

      System.assertEquals(1,[select count() from NSSCallException__c where Name='BadAcdName']);

   } // testBadAcdName

   static testMethod void testOrphanCall() {
      Task tsk1 = new Task(ActivityDate=Date.today(), Subject='Test Task', CallDateTime__c=DateTime.now(), isdc_inbound_callerid__c='(585) 555-1234');
      Test.startTest();
      insert tsk1;
      Test.stopTest();
      
      TaskOrphanCall__c orphan = [Select Id, Name, CallDateTIme__c, MissedCall__c, TaskId__c, Phone__c from TaskOrphanCall__c where TaskId__c=:tsk1.Id];
      System.assertEquals(false, orphan.MissedCall__c);
      TaskHelper.clearVariables();
      tsk1.Subject='Missed Call';
      update tsk1;
      
      orphan = [Select Id, Name, CallDateTIme__c, MissedCall__c, TaskId__c, Phone__c from TaskOrphanCall__c where TaskId__c=:tsk1.Id];
      System.assertEquals(true, orphan.MissedCall__c);
   } // testOrphanCall
*/

   static testMethod void testMultiplePartnerRefs() {
      Lead ld = new Lead(Company='Company', LastName='LastName', Phone='(585) 123-4576');
      insert ld;

      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true, StartDate=Date.today(), ACD_Name__c='ACDTest1', LeadSource__c='LeadSource1',Source_Type__c='Inbound Call');
      insert camp1;

      Schema.RecordTypeInfo rtOutbound = CallCenterHelper.getInboundRt();

      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Inbound_DNIS_Name__c=camp1.ACD_Name__c
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,InboundCallerId__c=ld.Phone);
      DS_Denali__DialSource_Action__c[] actions = new DS_Denali__DialSource_Action__c[]{action1};
      insert actions;

      //TaskHelper.validDispositionSet = new Set<String>{'Disposition1','Disposition2'};
      Task tsk = new Task(WhoId=ld.Id, ActivityDate=Date.today(),Subject='This is a test task');
      insert tsk;
      
      PartnerReferral__c partRef1 = new PartnerReferral__c(Lead__c=ld.Id);
      // the code should select this one to use.
      PartnerReferral__c partRef2 = new PartnerReferral__c(Lead__c=ld.Id, ActivityId__c=tsk.Id);
      PartnerReferral__c partRef3 = new PartnerReferral__c(Lead__c=ld.Id);
      PartnerReferral__c[] partRefs = new PartnerReferral__c[]{partRef1,partRef2,partRef3};
      insert partRefs;
      
      Test.setCreatedDate(partRef2.Id,DateTime.now().addHours(-1));
      Test.setCreatedDate(partRef3.Id,DateTime.now().addHours(-2));
      
      TaskHelper.CALL_HOURS_OFFSET = 3;
      
      tsk.DS_Denali__DialSource_Action__c=action1.Id;
      tsk.CallDisposition='Contacted';
      Test.startTest();
      update tsk;
      Test.stopTest();
      // make sure there is only one partner referral with the activity it
      System.assertEquals(1,[select count() from PartnerReferral__c where ActivityId__c=:tsk.Id]);
      // should still be only 3 partner referrals
      System.assertEquals(3,[select count() from PartnerReferral__c]);
      
      PartnerReferral__c checkPartRef2 = [Select Id, ActivityId__c, Campaign__c, CampaignId__c, Disposition__c, LeadSource__c from PartnerReferral__c where id=:partRef2.Id];
      System.assertEquals(tsk.Id, checkPartRef2.ActivityId__c);
      System.assertEquals(camp1.Id, checkPartRef2.Campaign__c);
      System.assertEquals(camp1.Id, checkPartRef2.CampaignId__c);
      System.assertEquals(tsk.CallDisposition, checkPartRef2.Disposition__c);
      System.assertEquals(camp1.LeadSource__c, checkPartRef2.LeadSource__c);
      
   } // testMultiplePartnerRefs

   static testMethod void testDenaliCallback() {
      // skip some of the trigger calls
      ZipCheckOwner.SKIP_TRIGGERS = true;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
 
      Account acct1 = new Account(Name='Acct1');
      insert acct1;
      Contact ctct1 = new Contact(LastName='Ctct1', AccountId=acct1.Id); 
      Contact ctct2 = new Contact(LastName='Ctct2', AccountId=acct1.Id);
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      insert ctcts;
      
      Lead ld1 = new Lead(LastName='Lead1', Company='Lead Company1');
      insert ld1;
      
      Task tsk1 = new Task(Subject='Callback1', WhoId=ctct1.Id, WhatId=acct1.Id, ActivityDate=Date.today().addDays(2), ReminderDateTime=Datetime.now().addDays(2), Type=null);
      Task tsk2 = new Task(Subject='Callback2', WhoId=ld1.Id, ActivityDate=Date.today().addDays(3), ReminderDateTime=Datetime.now().addDays(3), Type=null);
      Task[] tsks = new Task[]{tsk1,tsk2};
      insert tsks;
      
      acct1 = [Select Id, Name, DS_Denali__Next_Call_DS__c from Account where Id=:acct1.Id];
      System.assertEquals(tsk1.ReminderDateTime, acct1.DS_Denali__Next_Call_DS__c);
      
      ctct1 = [Select id, Name, DS_Denali__Next_Call_DS__c from Contact where Id=:ctct1.Id];
      System.assertEquals(tsk1.ReminderDateTime, ctct1.DS_Denali__Next_Call_DS__c);

      ctct2 = [Select id, Name, DS_Denali__Next_Call_DS__c from Contact where Id=:ctct2.Id];
      System.assertEquals(null , ctct2.DS_Denali__Next_Call_DS__c);
      
      ld1 = [Select Id, name, DS_Denali__Next_Call_DS__c from Lead where Id=:ld1.Id];
      System.assertEquals(tsk2.ReminderDateTime, ld1.DS_Denali__Next_Call_DS__c);
      
      // if you delete the task should remove the callback date
      delete tsk2;
      
      ld1 = [Select Id, name, DS_Denali__Next_Call_DS__c from Lead where Id=:ld1.Id];
      System.assertEquals(null, ld1.DS_Denali__Next_Call_DS__c);
      
      
      
   } // testDenaliCallback

   static testMethod void checkMisc() {
      TaskHelper th = new TaskHelper();
      th.triggerCheckActions(false,true);
      
   } // checkMisc

   static testMethod void testPartRefAttributes() {
      Group testQueue = new Group(Name='TestQueue',Type='Queue');
      insert testQueue;
      
      QueueSobject qObject1 = new QueueSobject(QueueId = testQueue.Id, SobjectType = 'Lead');
      QueueSobject qObject2 = new QueueSobject(QueueId = testQueue.Id, SobjectType = 'Referral__c');
      QueueSobject[] insertQObjects = new QueueSobject[]{qObject1,qObject2};
      insert insertQObjects;
      User runningUser = UserHelper.getRunningUser();
      System.runAs(runningUser) {
      LeadCallDisposition__c lcd = LeadMethods.findCallDisposition('Bad Number',null);
      System.assertNotEquals(null,lcd);
      
      lcd.AssignToQueue__c = testQueue.Name;
      update lcd;
       
      Lead ld = new Lead(Company='Company', LastName='LastName', Phone='(585) 123-4576');
      insert ld;

      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true, StartDate=Date.today(), ACD_Name__c='ACDTest1', LeadSource__c='LeadSource1', Source_Type__c='Inbound Call');
      insert camp1;

      Task tsk = new Task(WhoId=ld.Id, ActivityDate=Date.today(),Subject='This is a test task');
      insert tsk;
      
      PartnerReferral__c partRef = new PartnerReferral__c(Lead__c=ld.Id, ActivityId__c=tsk.Id);
      insert partRef;
      
      Referral__c ref = new Referral__c(Name='Test Referral', SourceLead__c=ld.Id, PartnerReferral__c=partRef.Id);
      insert ref;
      
      partRef.Referral__c=ref.Id;
      update partRef;
      
      tsk.CallType = 'Inbound';
      tsk.CallDisposition='Bad Number';
      Test.startTest();
      update tsk;
      Test.stopTest();
      
      partRef = [Select Id, Disposition__c, First_Call_Attempted__c, First_Contact_Made__c, Workable__c 
                   From PartnerReferral__c Where Id=:partRef.Id];
      System.debug('testPartRefAttributes partRef='+partRef);
      
      ref = [Select Id, OwnerId from Referral__c where Id=:ref.Id];
      System.assertEquals(testQueue.Id, ref.OwnerId);
      }
   } // testPartRefAttributes

   static testMethod void testCadence() {
      LeadCallDisposition__c lcd1 = LeadCallDisposition__c.getInstance('EndCadence');
      LeadCallDisposition__c lcd2 = LeadCallDisposition__c.getInstance('EndTouchpoint');
      System.assertNotEquals(null,lcd1);
      System.assertNotEquals(null,lcd2);
      
      CadenceUpdateTest.setupTestCadence();
      Cadence__c testCadence = CadenceUpdateTest.getTestCadence2();

      User usr = [Select Id, name, profile.Name, email, IsActive, User_Cadence_Type__c from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
       
      testCadence.Cadence_Type__c = usr.User_Cadence_Type__c;
      update testCadence;
      
      CreateTestData.createSingleAandTwoCtsNoTrigs();
      Account acct = CreateTestData.getTestAcct1();
      Contact ctct = acct.Contacts[0];
      acct.OwnerId=usr.Id;
      acct.SignificantContact__c=ctct.Id;
      update acct;
      ctct.OwnerId=usr.Id;
      update ctct;
      
      Lead ld = new Lead(LastName='Lead1', FirstName='Test', Company='Test Company', PostalCode='12345', OwnerId=usr.Id);
      insert ld;
      Cadence_Assignment_Record__c testCar1 = new Cadence_Assignment_Record__c(CadenceObject__c = ld.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c testCar2 = new Cadence_Assignment_Record__c(CadenceObject__c = ctct.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c[] cars = new Cadence_Assignment_Record__c[]{testCar1,testCar2};

      System.runAs(usr) {
         insert cars;
         Cadence_Touchpoint__c[] touchpoints = CadenceUpdateTest.getTouchpoints(testCadence.Id);
         // make sure the touchpoints were created
         System.assertEquals(2,touchpoints.size());
         
         Task tsk1 = new Task(WhoId=ld.Id, OwnerId=usr.Id, Subject='Task1', ActivityDate=Date.today().addDays(-1), Status='Completed', CallDisposition=lcd1.CallDisposition__c);
         Task tsk2 = new Task(WhoId=ctct.Id, OwnerId=usr.Id, Subject='Task2', ActivityDate=Date.today().addDays(-2), Status='Completed', CallDisposition=lcd2.CallDisposition__c);
         Task[] tasks = new Task[]{tsk1,tsk2};
         Test.startTest();
         insert tasks;
         Test.stopTest();
         
         touchpoints = CadenceUpdateTest.getTouchpoints(testCadence.Id);
         // make sure the touchpoints were created (when the one is closed it should open the next one)
         System.assertEquals(3,touchpoints.size());
         
         Boolean tp1Tested=false;
         Boolean tp2Tested=false;
         Boolean tp3Tested=false;
         for (Cadence_Touchpoint__c tp : touchpoints) {
            if (tp.CarRecord__r.LeadId__c == ld.Id) {
               tp1Tested=true;
               System.assertEquals(true,tp.CarRecord__r.Closed__c);
               System.assertEquals(true,tp.CarRecord__r.Rep_Closed__c);
               System.assertEquals(lcd1.CadenceCloseCAR__c,tp.CarRecord__r.CloseReason__c);
               System.assertEquals(tsk1.ActivityDate,tp.CarRecord__r.Close_Date__c);
               System.assertEquals('Closed',tp.CarRecord__r.Status__c);
            } else if (tp.CarRecord__r.AccountId__c == acct.Id && tp.Status__c=='Open') {
               // this should be the new one opened due to the first one closing
               tp2Tested=true;
               
            } else if (tp.CarRecord__r.AccountId__c == acct.Id && tp.Status__c=='Closed') {
               tp3Tested=true;
               System.assertEquals(tsk2.ActivityDate,tp.Close_Date__c);
            }
         } // for (Cadence_Touchpoint__c tp
         System.assertEquals(true,tp1Tested);
         System.assertEquals(true,tp2Tested);
         System.assertEquals(true,tp3Tested);
         
         Lead checkLd = [Select Id, Name, Lead_Stage__c, Reject_Reason__c, Recycle_Reason__c from Lead where Id=:ld.Id];
         System.assertEquals(lcd1.MarketingStage__c, checkLd.Lead_Stage__c);
         System.assertEquals(lcd1.CadenceCloseCAR__c, checkLd.Reject_Reason__c);
          
      } // System.runAs
   } // testCadence
    
   static testMethod void testCreateOrphanDrift() {
        Task tsk1 = new Task(Subject=Label.Drift_Task_Subject, Type=Label.TrackRecord_Chat);
        //, CallDateTime__c = system.now()
        Test.startTest();
        insert tsk1;
        Test.stopTest();
        Integer nbrOrphanRecs = [select count() from TaskOrphanCall__c where TaskId__c =:tsk1.Id];
        System.assertEquals(1, nbrOrphanRecs);        
   } // testCreateOrphanDrift
    
    static testMethod void testupdateTaskStatus() {
        Task tsk1 = new Task(Subject=Label.Outgoing_Text, Type= 'Call', Status = 'Open');
        //, CallDateTime__c = system.now()
        
        insert tsk1;
        
        tsk1.Type = 'Text';
        TaskHelper.clearVariables();
        Test.startTest();
        Update tsk1;
        Test.stopTest();
     //   System.assertEquals('Completed', tsk1.Status);
               
   } // testupdateTaskStatus
    
} //  class TaskHelperTest