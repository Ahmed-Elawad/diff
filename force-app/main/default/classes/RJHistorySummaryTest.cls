/* 
   TestMethods for RJHistorySummary class
   
  History
  -------
  08/03/2020 Dan Carmen   Created
  09/16/2020 Dan Carmen   Added RecordsAddedToday__c column
  06/25/2021 Dan Carmen   Fix failing test

 */
@isTest
public class RJHistorySummaryTest {
   static testMethod void testSummary() {
      Account acct1 = new Account(Name='Account1');
      Account acct2 = new Account(Name='Account2');
      Account acct3 = new Account(Name='Account3');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
       
      PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'Prod1','Prod2','Prod3'}, UserHelper.SO_CORE, null);
      Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, OpportunityType__c='Payroll', CloseDate=Date.today(), StageName='Pending');
      Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct2.Id, OpportunityType__c='Payroll', CloseDate=Date.today(), StageName='Pending');
      Opportunity opp3 = new Opportunity(Name='Opp3', AccountId=acct3.Id, OpportunityType__c='Payroll', CloseDate=Date.today(), StageName='Pending');
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert opps;
       
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opp1.Id, Quantity=1, PricebookEntryId=entries[0].Id, TotalPrice=100);
      OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opp2.Id, Quantity=1, PricebookEntryId=entries[1].Id, TotalPrice=200);
      OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId=opp3.Id, Quantity=1, PricebookEntryId=entries[2].Id, TotalPrice=300);
      OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2,oli3};
      OpptyLineItem.SKIP_TRIGGER=true;
      insert olis;
      
      opp1.StageName='Sold - Started';
      opp2.StageName='Sold - Started';
      update opps;
       
      RJHistorySummary.TASK_RTS=new String[]{RecordTypeHelper.CORE_TASK};
      Schema.RecordTypeInfo rtTask = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_TASK,'Task');
      Task tsk1 = new Task(WhatId=acct1.Id, RecordTypeId=rtTask.getRecordTypeId(), ActivityDate=Date.today(), Type='Test', Subject='Test', Status='Completed');
      Task tsk2 = new Task(WhatId=acct2.Id, RecordTypeId=rtTask.getRecordTypeId(), ActivityDate=Date.today(), Type='Test', Subject='Test', Status='Completed');
      Task tsk3 = new Task(WhatId=acct3.Id, RecordTypeId=rtTask.getRecordTypeId(), ActivityDate=Date.today(), Type='Test', Subject='Test');
      Task[] tsks = new Task[]{tsk1,tsk2,tsk3};
      TaskHelper.SKIP_TRIGGERS=true;
      insert tsks;
       
      RJHistorySummary.INIT_PRES_TYPES = new String[]{'Presentation - Initial'};
      Event evt1 = new Event(WhatId=acct1.Id, ActivityDateTime=Datetime.now(), DurationInMinutes=30, Type='Presentation - Initial');
      Event evt2 = new Event(WhatId=acct2.Id, ActivityDateTime=Datetime.now(), DurationInMinutes=30, Type='Presentation - Initial');
      Event evt3 = new Event(WhatId=acct3.Id, ActivityDateTime=Datetime.now(), DurationInMinutes=30, Type='Presentation - Initial');
      Event[] evnts = new Event[]{evt1,evt2,evt3};
      insert evnts;

      Test.startTest();
      RJHistorySummary rjhs = new RJHistorySummary();
      rjhs.execute(null);
      Test.stopTest();
       
      RJHistory__c[] hists = [Select Name, ObjectName__c, RunDate__c, RunStatus__c ,RecordsChangedToday__c, FiscalYearRecordCount__c, PeriodAmount__c, RecordsAddedToday__c from RJHistory__c];
      System.assertEquals(7,hists.size());
      Map<String,RJHistory__c> histMap = new Map<String,RJHistory__c>();
      for (RJHistory__c hist : hists) {
         histMap.put(hist.ObjectName__c, hist);
      }
      
      System.assertEquals(3,histMap.get('OPPORTUNITY').RecordsChangedToday__c);
      System.assertEquals(2,histMap.get('OPPORTUNITY').FiscalYearRecordCount__c);
      System.assertEquals(300,histMap.get('OPPORTUNITY').PeriodAmount__c);
      System.assertEquals(3,histMap.get('OPPORTUNITY').RecordsAddedToday__c);

      System.assertEquals(3,histMap.get('OPPORTUNITYLINEITEM').RecordsChangedToday__c);
      System.assertEquals(2,histMap.get('OPPORTUNITYLINEITEM').FiscalYearRecordCount__c);
      System.assertEquals(300,histMap.get('OPPORTUNITYLINEITEM').PeriodAmount__c);
      System.assertEquals(3,histMap.get('OPPORTUNITYLINEITEM').RecordsAddedToday__c);

      System.assertEquals(3,histMap.get('TASK').RecordsChangedToday__c);
      System.assertEquals(2,histMap.get('TASK').FiscalYearRecordCount__c);
      System.assertEquals(3,histMap.get('TASK').RecordsAddedToday__c);

      System.assertEquals(3,histMap.get('EVENT').RecordsChangedToday__c);
      System.assertEquals(3,histMap.get('EVENT').FiscalYearRecordCount__c);
      System.assertEquals(3,histMap.get('EVENT').RecordsAddedToday__c);

      System.assertEquals(3,histMap.get('ACCOUNT').RecordsAddedToday__c);

      System.assertEquals(0,histMap.get('CONTACT').RecordsAddedToday__c);
       
   } // testSummary
} // class RJHistorySummaryTest