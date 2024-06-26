/* 
 * Test methods for the DG_OpportunityAcceptDeadline class. This is normally triggered from a Process Builder.
 *
 * History
 * -------
   08/10/2018 Dan Carmen         Created
   10/02/2018 Dan Carmen       Add in a Stage History record
   01/30/2024 Dan Carmen          Comment out logic for setting the SLA date fields
   
 */
@isTest
private class DG_OpportunityAcceptDeadlineTest {
    
   static testMethod void testNothing() {
      DG_OpportunityAcceptDeadline.updateAcceptReminderDeadline(new Opportunity[]{});
      DG_OpportunityAcceptDeadline.checkStageHistorySave();
      DG_OpportunityAcceptDeadline.checkDeadline(new Opportunity[]{},new Opportunity[]{});
   }
    
/* commented out 1/30/2024
   @testSetup
   public static void setup(){
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createCustomSetting(null, 'OpptyBefore', true, false, new String[]{'DG_LMF_Service'},setupClasses, TriggerMethods.INTERFACE_B);
      TriggerMethodsTest.createCustomSetting(null, 'OpptyAfter', false, true, new String[]{'DG_LMF_Service'},setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;
   }
   
   static testMethod void testOpps() {
      // get an opportunity record so we can test
      Stage_SLA__mdt opptyStageMdt = [SELECT MasterLabel, DeveloperName, SAL_Minutes__c ,Expiration_Minutes__c, Stage__c  
                                      FROM Stage_SLA__mdt
                                     Where MasterLabel = :ObjectHelper.OBJECT_OPPTY
                                     limit 1];
                                     
      Referral_Partner__c refPart = new Referral_Partner__c(Name='TestPartner',Partner_Type__c='TestPartner',IsActive__c=true,Stage_Sales_Rep_needs_Approval__c=opptyStageMdt.Stage__c);
      insert refPart;
 


      Account acct1 = new Account(Name='Test Account1');
      Account acct2 = new Account(Name='Test Account2');
      Account acct3 = new Account(Name='Test Account3');
      Account[] accts = new Account[]{acct1,acct2,acct3};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      Referral__c ref1 = new Referral__c(Name='Ref1', Account__c=acct1.Id, Referral_Partner__c=refPart.Id);
      Referral__c ref2 = new Referral__c(Name='Ref2', Account__c=acct2.Id, Referral_Partner__c=refPart.Id);
      Referral__c ref3 = new Referral__c(Name='Ref3', Account__c=acct3.Id, Referral_Partner__c=refPart.Id);
      Referral__c[] refs = new Referral__c[]{ref1,ref2,ref3};
      insert refs;
      
      BusinessHours busHours = DG_LMF_Service.getBusinessHours('Default');
      // make sure this returns a value otherwise the test will fail
      System.assertEquals(true, busHours != null);
      
      Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, StageName=opptyStageMdt.Stage__c, CloseDate=Date.today().addDays(7)
                                      , Accept_Deadline__c=null, Accept_Reminder_Deadline__c=null, ProcessNotes__c=null
                                      , ReferralLookup__c = ref1.Id );
      Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct2.Id, StageName=opptyStageMdt.Stage__c, CloseDate=Date.today().addDays(7)
                                      , Accept_Deadline__c=null, Accept_Reminder_Deadline__c=null, ProcessNotes__c=null
                                      , ReferralLookup__c = ref2.Id );
      Opportunity opp3 = new Opportunity(Name='Opp3', AccountId=acct3.Id, StageName='Random Stage Name', CloseDate=Date.today().addDays(7)
                                      , Accept_Deadline__c=null, Accept_Reminder_Deadline__c=null, AcceptDeadlineRecalc__c=true, ProcessNotes__c=null
                                      , ReferralLookup__c = ref3.Id );
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
      // triggers aren't relevant to this testing
      OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      insert opps;
      
      //DG_OpportunityAcceptDeadline.updateAcceptReminderDeadline(opps);
      
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name,Accept_Deadline__c,Accept_Reminder_Deadline__c
                                                                  ,AcceptDeadlineRecalc__c, ProcessNotes__c
                                                                  ,(Select Id, New_Stage__c, ProcessNotes__c
                                                                          ,SLAMinutes__c, SLA_Deadline__c
                                                                          ,ExpirationMinutes__c, Expiration_Deadline__c
                                                                      From Stage_Histories__r)
                                                              From Opportunity
                                                             Where Id in :opps ]);
      Opportunity checkOpp1 = oppMap.get(opp1.Id);
      System.assertNotEquals(null, checkOpp1.Accept_Deadline__c);
      System.assertNotEquals(null, checkOpp1.Accept_Reminder_Deadline__c);
      System.assertEquals(false, checkOpp1.AcceptDeadlineRecalc__c);
      System.assertEquals(true, checkOpp1.ProcessNotes__c.contains('Found SLA information for Stage'));
      System.assertEquals(true, checkOpp1.ProcessNotes__c.contains('Updated Reminder Deadline to'));
      System.assertEquals(true, checkOpp1.ProcessNotes__c.contains('Updated Accept Deadline to'));
      System.assertEquals(1,checkOpp1.Stage_Histories__r.size());
      
      Opportunity checkOpp2 = oppMap.get(opp2.Id);
      System.assertNotEquals(null, checkOpp2.Accept_Deadline__c);
      System.assertNotEquals(null, checkOpp2.Accept_Reminder_Deadline__c);
      System.assertEquals(false, checkOpp2.AcceptDeadlineRecalc__c);
      System.assertEquals(true, checkOpp2.ProcessNotes__c.contains('Found SLA information for Stage'));
      System.assertEquals(true, checkOpp2.ProcessNotes__c.contains('Updated Reminder Deadline to'));
      System.assertEquals(true, checkOpp2.ProcessNotes__c.contains('Updated Accept Deadline to'));
      System.assertEquals(1,checkOpp2.Stage_Histories__r.size());
      
      Opportunity checkOpp3 = oppMap.get(opp3.Id);
      System.assertEquals(null, checkOpp3.Accept_Deadline__c);
      System.assertEquals(null, checkOpp3.Accept_Reminder_Deadline__c);
      System.assertEquals(false, checkOpp3.AcceptDeadlineRecalc__c);
      //System.assertEquals(true, checkOpp3.ProcessNotes__c.contains('Could not find SLA information for Stage'));
      System.assertEquals(0,checkOpp3.Stage_Histories__r.size());

   } // testOpps
   */
} // class DG_OpportunityAcceptDeadlineTest