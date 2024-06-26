/* 
 * Test methods for the OpptyStatusHistory class
 *
 * History
 * -------
   06/07/2017 Dan Carmen   Created
   04/23/2018 Dan Carmen      Change to log even closed statuses
   02/25/2019 Dan Carmen      Update API version to 45

 */
@isTest
private class OpptyStatusHistoryTest {

   @testSetup
   public static void setupTestData() {
      TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createCustomSetting(null, 'OpptyAfter', false, true, new String[]{'OpptyStatusHistory'}, classes);
      insert classes;
   } // setupTestData

   static testMethod void testStatusChange() {
      Account acct = new Account(Name='Test Acct');
      insert acct;
      Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acct.Id, CloseDate=Date.today().addDays(7));
      opp.StageName=Label.OpptyPendingDefault;
      insert opp;
      
      OpptyStatusHistory__c[] histories = [Select Id, StageName__c, StartDate__c, EndDate__c from OpptyStatusHistory__c where Opportunity__c=:opp.Id order by StartDate__c desc];
      System.assertEquals(1,histories.size());
      System.assertEquals(opp.StageName, histories[0].StageName__c);
      System.assertEquals(true, histories[0].StartDate__c != null);
      System.assertEquals(null, histories[0].EndDate__c);
      
      OpptyStatusHistory.oppIdsProcessed.clear();
      OpportunityStage[] nextStages = [select Id, MasterLabel, ApiName, DefaultProbability, IsActive, IsClosed, IsWon from OpportunityStage where IsClosed=false and DefaultProbability > 60 and IsActive=true];
      opp.StageName = nextStages[0].MasterLabel;
      update opp;

      histories = [Select Id, StageName__c, StartDate__c, EndDate__c from OpptyStatusHistory__c where Opportunity__c=:opp.Id order by StartDate__c desc];
      
      System.assertEquals(2,histories.size());
      Boolean status1Found = false;
      Boolean status2Found = false;
      for (OpptyStatusHistory__c history : histories) {
         if (opp.StageName == history.StageName__c) {
            status1Found = true;
            System.assertEquals(true, history.StartDate__c != null);
            System.assertEquals(null, history.EndDate__c);
         } else if (Label.OpptyPendingDefault == history.StageName__c) {
            status2Found = true;
            System.assertEquals(true, history.StartDate__c != null);
            System.assertEquals(true, history.EndDate__c != null);
         }
      } // for (OpptyStatusHistory__c history
      
      System.assertEquals(true, status1Found);
      System.assertEquals(true, status2Found);

      OpptyStatusHistory.oppIdsProcessed.clear();
      OpportunityStage[] finalStages = [select Id, MasterLabel, ApiName, DefaultProbability, IsActive, IsClosed, IsWon from OpportunityStage where IsClosed=true and IsWon=true and DefaultProbability = 100 and IsActive=true];
      opp.StageName = finalStages[0].MasterLabel;
      update opp;

      histories = [Select Id, StageName__c, StartDate__c, EndDate__c from OpptyStatusHistory__c where Opportunity__c=:opp.Id order by StartDate__c desc];

      System.assertEquals(3,histories.size());
      status1Found = false;
      status2Found = false;
      Boolean status3Found = false;
      for (OpptyStatusHistory__c history : histories) {
         if (nextStages[0].MasterLabel == history.StageName__c) {
            status1Found = true;
            System.assertEquals(true, history.StartDate__c != null);
            System.assertEquals(true, history.EndDate__c != null);
         } else if (Label.OpptyPendingDefault == history.StageName__c) {
            status2Found = true;
            System.assertEquals(true, history.StartDate__c != null);
            System.assertEquals(true, history.EndDate__c != null);
         } else if (finalStages[0].MasterLabel == history.StageName__c) {
            status3Found = true;
            System.assertEquals(true, history.StartDate__c != null);
            System.assertEquals(true, history.EndDate__c != null);
         }
      } // for (OpptyStatusHistory__c history
      
      System.assertEquals(true, status1Found);
      System.assertEquals(true, status2Found);
      System.assertEquals(true, status3Found);


   } // testStatusChange
   
   static testMethod void testMisc() {
      OpptyStatusHistory osh = new OpptyStatusHistory();
      osh.checkAllBeforeTrigger(null,null);
      osh.checkBeforeTrigger(null,null);
      osh.processBeforeTriggerActions();
      
      
   } // testMisc
   
} // class OpptyStatusHistoryTest