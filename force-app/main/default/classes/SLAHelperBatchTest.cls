/* 
  Test methods for SLAHelperBatch
   
  History
  -------
  08/06/2018 Dan Carmen        Created
  10/02/2018 Dan Carmen          Add in a Stage History record
  05/02/2019 Dan Carmen          Change to fix an exception happening in prod.
  07/17/2019 Dan Carmen          Change to tune the SQL
  01/15/2023 Jaipal				 Made changes to assert System.assertEquals(true,checkOpp2a.Accept_Reminder_Deadline__c!=null instead of null
  02/03/2023 Dan Carmen          Force the Referral Triggers to fire
  01/30/2024 Dan Carmen          Commented out Opportunity handling. Can be deleted sometime in the future if not used.

*/
@isTest
private class SLAHelperBatchTest {
   
   @testSetup
   private static void setupData() {
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = SLAHelperBatch.CLASS_NAME, Active__c = true, BatchSize__c=100);
      insert abc; 
      CadenceUpdateTest.setupTestCadence();
   } // setupData
/* commented out 1/30/2024
   static testMethod void testOpps() {
      Referral_Partner__c refPart1 = new Referral_Partner__c(Name='Test Partner', Stage_Sales_Rep_needs_Approval__c='Pending');
      Referral_Partner__c refPart2 = new Referral_Partner__c(Name='Test Partner2', Stage_Sales_Rep_needs_Approval__c=null);
      Referral_Partner__c[] refParts = new Referral_Partner__c[]{refPart1,refPart2};
      insert refParts;
      
      // find some queue names
      String[] options = Label.Reassign_Component_Queues.split(';');
      System.assertEquals(true,options.size() >= 2);
      PartnerReferral__c partRef1 = new PartnerReferral__c(Company__c='Test Company1', Destination__c=options[0]);
      PartnerReferral__c partRef2 = new PartnerReferral__c(Company__c='Test Company2', Destination__c=null);
      PartnerReferral__c partRef3 = new PartnerReferral__c(Company__c='Test Company3', Destination__c=null);
      PartnerReferral__c[] partRefs = new PartnerReferral__c[]{partRef1,partRef2,partRef3};
      insert partRefs;
      
      Account acct1 = new Account(Name='Test Company1');
      Account acct2 = new Account(Name='Test Company2');
      Account acct3 = new Account(Name='Test Company3');
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
      
      // this one should hit the reminder code
      Opportunity opp1a = new Opportunity(Name='Opp1a', StageName='Pending', CloseDate=Date.today().addDays(7)
                                       ,AccountId=acct1.Id
                                       ,Accept_Deadline__c=Datetime.now().addMinutes(10)
                                       ,Accept_Reminder_Deadline__c=Datetime.now().addMinutes(-5));
      // this one should hit the deadline code
      Opportunity opp1b = new Opportunity(Name='Opp1b', StageName='Pending', CloseDate=Date.today().addDays(7)
                                       ,AccountId=acct1.Id
                                       ,Accept_Deadline__c=Datetime.now().addMinutes(-5)
                                       ,Accept_Reminder_Deadline__c=Datetime.now().addMinutes(-15));

      Opportunity opp2a = new Opportunity(Name='Opp2a', StageName='Pending', CloseDate=Date.today().addDays(7)
                                       ,AccountId=acct2.Id
                                       ,Accept_Deadline__c=Datetime.now().addMinutes(-5)
                                       ,Accept_Reminder_Deadline__c=Datetime.now().addMinutes(-15));
      Opportunity opp3 = new Opportunity(Name='Opp3', StageName='Pending', CloseDate=Date.today().addDays(7)
                                       ,AccountId=acct3.Id
                                       ,Accept_Deadline__c=Datetime.now().addMinutes(-5)
                                       ,Accept_Reminder_Deadline__c=Datetime.now().addMinutes(-15));
      Opportunity[] opps = new Opportunity[]{opp1a,opp1b,opp2a,opp3};
      insert opps;

      // set this opportunity so that it's not selected
      Test.setCreatedDate(opp3.Id, DateTime.now().addMonths(-6));
      
      Referral__c ref1a = new Referral__c(Name='Test ref1a', Referral_Partner__c=refPart1.Id, Account__c=acct1.Id, Selling_Opportunity__c=opp1a.Id);
      Referral__c ref1b = new Referral__c(Name='Test ref1b', Referral_Partner__c=refPart2.Id, Account__c=acct1.Id, Selling_Opportunity__c=opp1b.Id);
      Referral__c ref2a = new Referral__c(Name='Test ref2a', Referral_Partner__c=refPart1.Id, Account__c=acct2.Id, Selling_Opportunity__c=opp2a.Id);
      Referral__c ref3 = new Referral__c(Name='Test ref3', Referral_Partner__c=refPart1.Id, Account__c=acct3.Id, Selling_Opportunity__c=opp3.Id);
      Referral__c[] refs = new Referral__c[]{ref1a,ref1b,ref2a,ref3};
      insert refs;
      
      opp1a.ReferralLookup__c = ref1a.Id;
      opp1b.ReferralLookup__c = ref1b.Id;
      opp2a.ReferralLookup__c = ref2a.Id;
      opp3.ReferralLookup__c = ref3.Id;
      update opps;
      
      //SLAHelperBatch shb = new SLAHelperBatch();
      //shb.currentMode = SLAHelperBatch.MODE_OPPORTUNITY;
      
      Test.StartTest();
      SLAHelperBatch.scheduleBatch(SLAHelperBatch.MODE_OPPORTUNITY, true);
      Test.StopTest();
      
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name, Accept_Deadline__c, Accept_Reminder_Deadline__c
                                                                  ,ProcessNotes__c
                                                              From Opportunity
                                                             Where Id in :opps]);
      Opportunity checkOpp1a = oppMap.get(opp1a.Id);
      System.assertEquals(null,checkOpp1a.Accept_Reminder_Deadline__c);
      System.assertEquals(true,checkOpp1a.Accept_Deadline__c != null);
      System.assertEquals(true,checkOpp1a.ProcessNotes__c.contains('Hit the Accept Reminder Deadline'));
                                                             
      Opportunity checkOpp1b = oppMap.get(opp1b.Id);
      System.assertEquals(null,checkOpp1b.Accept_Reminder_Deadline__c);
      System.assertEquals(null,checkOpp1b.Accept_Deadline__c);
      System.assertEquals(false,checkOpp1b.ProcessNotes__c.contains('Stages are not equal, clearing Deadline fields'));
                                                             
      Opportunity checkOpp2a = oppMap.get(opp2a.Id);
     System.assertEquals(true,checkOpp2a.Accept_Reminder_Deadline__c!=null);
      System.assertEquals(null,checkOpp2a.Accept_Deadline__c);
      System.assertEquals(true,checkOpp2a.ProcessNotes__c.contains('Hit the Accept Deadline'));

      // nothing should have changed because this opp is outside the timeframe
      Opportunity checkOpp3 = oppMap.get(opp3.Id);
      System.assertEquals(opp3.Accept_Reminder_Deadline__c,checkOpp3.Accept_Reminder_Deadline__c);
      System.assertEquals(opp3.Accept_Deadline__c,checkOpp3.Accept_Deadline__c);
      //System.assertEquals(true,String.isBlank(checkOpp3.ProcessNotes__c));

   } // testOpps
  */
   static testMethod void testExpiration() {
      // get stage settings for a lead
      Stage_SLA__mdt leadStageMdt = [SELECT MasterLabel, DeveloperName, SAL_Minutes__c ,Expiration_Minutes__c, Stage__c  
                                      FROM Stage_SLA__mdt
                                     Where MasterLabel = :ObjectHelper.OBJECT_LEAD
                                     limit 1];
      Lead ld1 = new Lead(Company='LeadCompany1', LastName='LeadLast1', Lead_Stage__c=leadStageMdt.Stage__c);
      Lead ld2 = new Lead(Company='LeadCompany2', LastName='LeadLast2', Lead_Stage__c=leadStageMdt.Stage__c);
      Lead ld3 = new Lead(Company='LeadCompany3', LastName='LeadLast3', Lead_Stage__c=leadStageMdt.Stage__c);
      Lead ld4 = new Lead(Company='LeadCompany4', LastName='LeadLast4', Lead_Stage__c=leadStageMdt.Stage__c);
      // skip the lead triggers - not relevant for this testing
      LeadMethods.LEAD_BEFORE_EXECUTING=true;
      LeadMethods.LEAD_AFTER_EXECUTING=true;
      Lead[] lds = new Lead[]{ld1,ld2,ld3,ld4};
      insert lds;
      
      // get stage settings for a contact                                     
      Stage_SLA__mdt ctctStageMdt = [SELECT MasterLabel, DeveloperName, SAL_Minutes__c ,Expiration_Minutes__c, Stage__c  
                                      FROM Stage_SLA__mdt
                                     Where MasterLabel = :ObjectHelper.OBJECT_CONTACT
                                     limit 1];
      Account acct1 = new Account(Name='Account1');
      Account acct2 = new Account(Name='Account2');
      Account acct3 = new Account(Name='Account3');
      Account acct4 = new Account(Name='Account4');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      insert accts;
      
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='CtctLast1', Contact_Stage__c=ctctStageMdt.Stage__c);
      Contact ctct2 = new Contact(AccountId=acct2.Id, LastName='CtctLast2', Contact_Stage__c=ctctStageMdt.Stage__c);
      Contact ctct3 = new Contact(AccountId=acct3.Id, LastName='CtctLast3', Contact_Stage__c=ctctStageMdt.Stage__c);
      Contact ctct4 = new Contact(AccountId=acct4.Id, LastName='CtctLast4', Contact_Stage__c=ctctStageMdt.Stage__c);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;
      
      // need the referrals for the linkage
      Referral__c refLd1 = new Referral__c(Name='Test refLd1', SourceLead__c=ld1.Id);
      Referral__c refLd2 = new Referral__c(Name='Test refLd2', SourceLead__c=ld2.Id);
      Referral__c refLd3 = new Referral__c(Name='Test refLd3', SourceLead__c=ld3.Id);
      Referral__c refLd4 = new Referral__c(Name='Test refLd4', SourceLead__c=ld4.Id);
      Referral__c refCtct1 = new Referral__c(Name='Test refCtct1', Account__c=acct1.Id, SourceContact__c=ctct1.Id);
      Referral__c refCtct2 = new Referral__c(Name='Test refCtct2', Account__c=acct2.Id, SourceContact__c=ctct2.Id);
      Referral__c refCtct3 = new Referral__c(Name='Test refCtct3', Account__c=acct3.Id, SourceContact__c=ctct3.Id);
      Referral__c refCtct4 = new Referral__c(Name='Test refCtct4', Account__c=acct4.Id, SourceContact__c=ctct4.Id);
      ReferralTriggerActions.SKIP_TRIGGER=true;
      Referral__c[] refs = new Referral__c[]{refLd1,refLd2,refLd3,refLd4,refCtct1,refCtct2,refCtct3,refCtct4};
      insert refs;

      BusinessHours busHours = DG_LMF_Service.getBusinessHours('DEFAULT');
      DateTime expirationDT = BusinessHours.add(busHours.id , DateTime.now(), 17 * 60000);

      // create the stage history records so we have control of them.
      Stage_History__c stageHistLd1 = new Stage_History__c(Lead__c=ld1.Id, Expiration_Deadline__c=DateTime.now().addMinutes(-7), New_Stage__c=ld1.Lead_Stage__c);
      Stage_History__c stageHistLd2 = new Stage_History__c(Lead__c=ld2.Id, Expiration_Deadline__c=DateTime.now().addMinutes(7), New_Stage__c=ld2.Lead_Stage__c);
      Stage_History__c stageHistLd3 = new Stage_History__c(Lead__c=ld3.Id, Expiration_Deadline__c=expirationDT, SLA_Deadline__c=DateTime.now().addMinutes(-7), New_Stage__c=ld3.Lead_Stage__c);
      Stage_History__c stageHistLd4 = new Stage_History__c(Lead__c=ld4.Id, Expiration_Deadline__c=DateTime.now().addMinutes(4), SLA_Deadline__c=DateTime.now().addMinutes(-7), New_Stage__c=ld4.Lead_Stage__c);

      Stage_History__c stageHistCtct1 = new Stage_History__c(Contact__c=ctct1.Id, Expiration_Deadline__c=DateTime.now().addMinutes(-7), New_Stage__c=ctct1.Contact_Stage__c);
      Stage_History__c stageHistCtct2 = new Stage_History__c(Contact__c=ctct2.Id, Expiration_Deadline__c=DateTime.now().addMinutes(7), New_Stage__c=ctct2.Contact_Stage__c);
      Stage_History__c stageHistCtct3 = new Stage_History__c(Contact__c=ctct3.Id, Expiration_Deadline__c=expirationDT, SLA_Deadline__c=DateTime.now().addMinutes(-7), New_Stage__c=ctct3.Contact_Stage__c);
      Stage_History__c stageHistCtct4 = new Stage_History__c(Contact__c=ctct4.Id, Expiration_Deadline__c=DateTime.now().addMinutes(4), SLA_Deadline__c=DateTime.now().addMinutes(-7), New_Stage__c=ctct4.Contact_Stage__c);
      
      Stage_History__c[] histories = new Stage_History__c[]{stageHistLd1,stageHistLd2,stageHistLd3,stageHistLd4,stageHistCtct1,stageHistCtct2,stageHistCtct3,stageHistCtct4};
      insert histories;
      
      // verify that 2 of them are expired
      System.assertEquals(2, [select count() from Stage_History__c where Expired__c=true]);
      
      // for testing purposes so we can control the outcome
      SLAHelperBatch.TEST_SLA_MINUTES = 7;
      
      Test.StartTest();
      SLAHelperBatch.scheduleBatch(SLAHelperBatch.MODE_STAGE_HISTORY, true);
      Test.StopTest();
      
      // only 2 should be updated - the other 2 will not be touched.
      System.assertEquals(2, [select count() from Stage_History__c where Expired__c=true and Run_Expiration_Scheduled_Job__c=true]);
      
      Map<Id,Lead> leadMap = new Map<Id,Lead>([Select Id, Name, Lead_Stage__c, Recycle_Reason__c 
                                                    ,(Select Id
                                                            ,Expiration_Deadline__c
                                                            ,Expired__c
                                                            ,ExpirationProcessed__c
                                                            ,New_Stage__c
                                                            ,ProcessNotes__c
                                                            ,Run_Expiration_Scheduled_Job__c
                                                            ,SLA_Deadline__c
                                                            ,SLA_Reached__c
                                                            ,SLAProcessed__c
                                                        From Stage_History__r)
                                                 from Lead where Id in :lds]);
      Lead checkLd1 = leadMap.get(ld1.Id);
      System.assertEquals(SLAHelperBatch.LEAD_RECYCLE, checkLd1.Lead_Stage__c);
      System.assertEquals(SLAHelperBatch.LEAD_EXCEED_SLA, checkLd1.Recycle_Reason__c);
      Stage_History__c histLd1 = checkLd1.Stage_History__r[0];
      System.assertEquals(true,histLd1.Run_Expiration_Scheduled_Job__c);
      System.assertEquals(true,histLd1.ExpirationProcessed__c);
      System.assertEquals(true,histLd1.Expired__c);
      System.assertEquals(true,histLd1.ProcessNotes__c.contains('Expiring Record Changing Lead Status'));
      System.assertEquals(true,histLd1.SLAProcessed__c);

      Lead checkLd2 = leadMap.get(ld2.Id);
      System.assertEquals(leadStageMdt.Stage__c, checkLd2.Lead_Stage__c);
      System.assertEquals(null, checkLd2.Recycle_Reason__c);
      Stage_History__c histLd2 = checkLd2.Stage_History__r[0];
      System.assertEquals(false,histLd2.Run_Expiration_Scheduled_Job__c);
      System.assertEquals(false,histLd2.ExpirationProcessed__c);
      System.assertEquals(false,histLd2.Expired__c);

      Lead checkLd3 = leadMap.get(ld3.Id);
      System.assertEquals(leadStageMdt.Stage__c, checkLd3.Lead_Stage__c);
      System.assertEquals(null, checkLd3.Recycle_Reason__c);
      // should only be one stage history
      Stage_History__c histLd3 = checkLd3.Stage_History__r[0];
      System.assertEquals(false,histLd3.Run_Expiration_Scheduled_Job__c);
      System.assertEquals(false,histLd3.ExpirationProcessed__c);
      System.assertEquals(false,histLd3.Expired__c);
      System.assertEquals(true,histLd3.SLA_Deadline__c > DateTime.now());
      System.assertEquals(false,histLd3.SLAProcessed__c);
      System.assertEquals(true,histLd3.ProcessNotes__c.contains('Changing SLA Deadline from'));
            
      Lead checkLd4 = leadMap.get(ld4.Id);
      System.assertEquals(leadStageMdt.Stage__c, checkLd4.Lead_Stage__c);
      System.assertEquals(null, checkLd4.Recycle_Reason__c);
      // should only be one stage history
      Stage_History__c histLd4 = checkLd4.Stage_History__r[0];
      System.assertEquals(false,histLd4.Run_Expiration_Scheduled_Job__c);
      System.assertEquals(false,histLd4.ExpirationProcessed__c);
      System.assertEquals(false,histLd4.Expired__c);
      System.assertEquals(true,histLd4.SLA_Deadline__c != null);
      System.assertEquals(true,histLd4.ProcessNotes__c.contains('Clearing SLA Deadline of'));
      System.assertEquals(true,histLd4.SLAProcessed__c);
            
      Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id, Name, Contact_Stage__c, Recycle_Reason__c, NSSOwnership__c 
                                                          ,(Select Id
                                                            ,Expiration_Deadline__c
                                                            ,Expired__c
                                                            ,ExpirationProcessed__c
                                                            ,New_Stage__c
                                                            ,ProcessNotes__c
                                                            ,Run_Expiration_Scheduled_Job__c
                                                            ,SLA_Deadline__c
                                                            ,SLA_Reached__c
                                                            ,SLAProcessed__c
                                                        From Stage_History__r)
                                                       from Contact where Id in :ctcts]);
      Contact checkCtct1 = ctctMap.get(ctct1.Id);
      System.assertEquals(SLAHelperBatch.LEAD_RECYCLE, checkCtct1.Contact_Stage__c);
      System.assertEquals(SLAHelperBatch.LEAD_EXCEED_SLA, checkCtct1.Recycle_Reason__c);
      System.assertEquals(DoNotSyncCheck.MARKETO_SYNC_USER, checkCtct1.NSSOwnership__c);
      Stage_History__c histCtct1 = checkCtct1.Stage_History__r[0];
      System.assertEquals(true,histCtct1.Run_Expiration_Scheduled_Job__c);
      System.assertEquals(true,histCtct1.ExpirationProcessed__c);
      System.assertEquals(true,histCtct1.Expired__c);
      System.assertEquals(true,histCtct1.ProcessNotes__c.contains('Expiring Record Changing Contact Status'));

      Contact checkCtct2 = ctctMap.get(ctct2.Id);
      System.assertEquals(ctctStageMdt.Stage__c, checkCtct2.Contact_Stage__c);
      System.assertEquals(null, checkCtct2.Recycle_Reason__c);
      System.assertEquals(null, checkCtct2.NSSOwnership__c);
      Stage_History__c histCtct2 = checkCtct2.Stage_History__r[0];
      System.assertEquals(false,histCtct2.Run_Expiration_Scheduled_Job__c);
      System.assertEquals(false,histCtct2.ExpirationProcessed__c);
      System.assertEquals(false,histCtct2.Expired__c);

      Contact checkCtct3 = ctctMap.get(ctct3.Id);
      System.assertEquals(ctctStageMdt.Stage__c, checkCtct3.Contact_Stage__c);
      System.assertEquals(null, checkCtct3.Recycle_Reason__c);
      // should only be one stage history
      Stage_History__c histCtct3 = checkCtct3.Stage_History__r[0];
      System.assertEquals(false,histCtct3.Run_Expiration_Scheduled_Job__c);
      System.assertEquals(false,histCtct3.ExpirationProcessed__c);
      System.assertEquals(false,histCtct3.Expired__c);
      System.assertEquals(true,histCtct3.SLA_Deadline__c > DateTime.now());
      System.assertEquals(true,histCtct3.ProcessNotes__c.contains('Changing SLA Deadline from'));
      System.assertEquals(false,histCtct3.SLAProcessed__c);

      Contact checkCtct4 = ctctMap.get(ctct4.Id);
      System.assertEquals(ctctStageMdt.Stage__c, checkCtct4.Contact_Stage__c);
      System.assertEquals(null, checkCtct4.Recycle_Reason__c);
      // should only be one stage history
      Stage_History__c histCtct4 = checkCtct4.Stage_History__r[0];
      System.assertEquals(false,histCtct4.Run_Expiration_Scheduled_Job__c);
      System.assertEquals(false,histCtct4.ExpirationProcessed__c);
      System.assertEquals(false,histCtct4.Expired__c);
      System.assertEquals(true,histCtct4.SLA_Deadline__c != null);
      System.assertEquals(true,histCtct4.ProcessNotes__c.contains('Clearing SLA Deadline of'));
      System.assertEquals(true,histCtct4.SLAProcessed__c);

   } // testExpiration
      
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testSLAHelperBatch', new SLAHelperBatch());
   } // testScheduler

   static testMethod void testMisc() {
      Integer defaultMinutes = 2;
      Integer scheduledMinutes = SLAHelperBatch.getScheduleMinutes(defaultMinutes,SLAHelperBatch.BATCH);
      System.assertEquals(true, scheduledMinutes >= defaultMinutes);
   }
      
   static testMethod void testCadenceExpire() {
      Cadence__c cad = CadenceUpdateTest.getTestCadence();
       
      Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
      User uzer = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      CreateTestData.createSingleAandTwoCtsNoTrigs();
      Account acct1 = CreateTestData.getTestAcct1();
      Contact ct1 = acct1.Contacts[0];

      acct1.OwnerId = uzer.Id;
      acct1.SignificantContact__c = ct1.Id;
      update acct1;

      testCar.CadenceObject__c = acct1.Id;
      testCar.Cadence__c = cad.Id;
      testCar.Cadence_Owner__c = uzer.Id;
      // set this up as expired
      testCar.ExpirationDate__c = Datetime.now().addMinutes(-60);
      insert testCar;
      // verify the touchpoint was created
      Cadence_Touchpoint__c[] touchpoints = CadenceUpdateTest.getTouchpoints(cad.Id);
      System.assertEquals(1,touchpoints.size());
       
      System.debug('touchpoint='+touchpoints[0]);
      System.debug('car='+touchpoints[0].CarRecord__r);
      // verify the condition is met
      System.assertEquals(1,[select count() from Cadence_Touchpoint__c
                                           Where CarRecord__r.ExpirationDate__c < :Datetime.now()
                                             and CarRecord__r.Closed__c = false
                                             and CarRecord__r.StageHistory__c = null
                                             and IsLatestTouchpoint__c=true]);
       
      // run the batch, should close the CAR record
      Test.StartTest();
      SLAHelperBatch.scheduleBatch(SLAHelperBatch.MODE_CADENCE, true);
      Test.StopTest();

      touchpoints = CadenceUpdateTest.getTouchpoints(cad.Id);
      System.assertEquals(1,touchpoints.size());
      
      Cadence_Touchpoint__c tp = touchpoints[0];
      System.assertEquals(Date.today(), tp.Close_Date__c);
      System.assertEquals('Closed - Expired', tp.Status__c);
 
      System.assertEquals(true, tp.CarRecord__r.Closed__c);
      System.assertEquals(Date.today(), tp.CarRecord__r.Close_Date__c);
      System.assertEquals('Touchpoint Expired', tp.CarRecord__r.CloseReason__c);
      System.assertEquals('Closed', tp.CarRecord__r.Status__c);

   } // testCadenceExpire
   
   // test the expiration at the touchpoint level, instead of the CAR level
   static testMethod void testTouchpointExpire() {
      Cadence__c cad = CadenceUpdateTest.getTestCadence3();
      Referral_Account__c refAcct1 = new Referral_Account__c(Name='Test Ref Acct1', Referral_Source_Business_Type__c='Accounting Firm', End_Date__c=null, Referral_Type__c='Gold', Group__c=cad.CPARotation__c);
      ReferralAccountMethods.SKIP_TRIGGERS=true;
      insert refAcct1;
       
      Cadence_Assignment_Record__c car1 = new Cadence_Assignment_Record__c(CadenceObject__c=refAcct1.Id, Cadence__c=cad.Id);
      insert car1;

      // should be one returned
      Cadence_Touchpoint__c[] touchpoints = CadenceUpdateTest.getTouchpoints(cad.Id);
      System.assertEquals(1,touchpoints.size());

      Integer stepNbr = Integer.valueOf(touchpoints[0].Cadence_Touchpoint_Step__r.Step_Number__c);
      System.debug('testTouchpointExpire stepNbr='+stepNbr);
       
      touchpoints[0].ExpirationDate__c=Datetime.now().addMinutes(-1);
      update touchpoints[0];
       
      Test.StartTest();
      SLAHelperBatch.scheduleBatch(SLAHelperBatch.MODE_TP_EXPIRE, true);
      Test.StopTest();

      // should still be one active touchpoint.
      touchpoints = CadenceUpdateTest.getTouchpoints(cad.Id);
      System.debug('testTouchpointExpire touchpoints='+touchpoints);
      System.assertEquals(2,touchpoints.size());
       
      Boolean activeFound = false;
      Boolean closedFound = false;
      for (Cadence_Touchpoint__c tp : touchpoints) {
         if (tp.Close_Date__c == null) {
            activeFound = true;
         } else {
            closedFound = true;
         }
      } // for (Cadence_Touchpoint__c tp
      System.assertEquals(true,activeFound);
      System.assertEquals(true,closedFound);
      
   } // testTouchpointExpire
    
   static testMethod void testTouchpointSkip() {
      Cadence__c cad = CadenceUpdateTest.getTestCadence();
      Cadence__c updateCad = new Cadence__c(Id=cad.Id, Auto_Skip_Steps__c=true);
      update updateCad;
       
      Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
      User uzer = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      CreateTestData.createSingleAandTwoCtsNoTrigs();
      Account acct1 = CreateTestData.getTestAcct1();
      Contact ct1 = acct1.Contacts[0];

      testCar.CadenceObject__c = acct1.Id;
      testCar.Cadence__c = cad.Id;
      testCar.Cadence_Owner__c = uzer.Id;
      // set this up as expired
      testCar.ExpirationDate__c = Datetime.now().addMinutes(-60);
      insert testCar;
      // verify the touchpoint was created
      Cadence_Touchpoint__c[] touchpoints = CadenceUpdateTest.getTouchpoints(cad.Id);
      System.assertEquals(1,touchpoints.size());
      System.assertEquals(false,touchpoints[0].NoEmailEligibleContacts__c);
      System.assertEquals(1,touchpoints[0].Cadence_Touchpoint_Step__r.Step_Number__c);
       
      Cadence_Touchpoint__c updateTp = new Cadence_Touchpoint__c(Id=touchpoints[0].Id, NoEmailEligibleContacts__c=true, Due_Date__c=Datetime.now().addMinutes(-1));
      CadenceHelper.SKIP_TRIGGERS=true;
      update updateTp;
      CadenceHelper.SKIP_TRIGGERS=false;

      //System.debug('touchpoint='+touchpoints[0]);
      //System.debug('car='+touchpoints[0].CarRecord__r);
      // verify the condition is met
      System.assertEquals(1,[select count() from Cadence_Touchpoint__c
                                           Where Due_Date__c <= :Datetime.now()
                                             and Close_Date__c = null
                                             and NoEmailEligibleContacts__c = true
                                             and Cadence_Touchpoint_Step__r.Touchpoint_Type__c = 'Email'
                                             and Status__c = 'Open']);
       

      Test.StartTest();
      SLAHelperBatch.scheduleBatch(SLAHelperBatch.MODE_TP_SKIP, true);
      Test.StopTest();
       
      // verify we've moved to the next step
      System.assertEquals(1,[select count() from Cadence_Touchpoint__c
                                           Where Close_Date__c = null
                                             and Cadence_Touchpoint_Step__r.Step_Number__c = 2
                                             and Status__c = 'Open']);

   } // testTouchpointSkip
    
} // class SLAHelperBatchTest