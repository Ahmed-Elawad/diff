/* 
 * Test methods for the ProcessChecker class
 *
 * History
 * -------
   01/14/2019 Dan Carmen   Created
   09/04/2020 Dan Carmen   Update code so it works properly.
   04/22/2021 Dan Carmen        Change launchBatch method

 */
@isTest
private class ProcessCheckerTest {

   @testSetup
   public static void setupData() {
      Apex_Batch_Control__c  abc = new Apex_Batch_Control__c(Name=ProcessChecker.CLASSNAME,Active__c=true, AdditionalEmails__c='dcarmen@paychex.com',BatchSize__c=10);
      insert abc;
   } // setupData


   static testMethod void testChecker() {
      PurgeControl__c purge1 = new PurgeControl__c(Name='Test1',ObjectAPIName__c='Account',IsActive__c=true, ProcessType__c='Data Check Only', DataCheckOnly__c=true
                                                  ,DateFieldToCheck__c='CreatedDate',NbrDaysToKeep__c=30, NextRunTime__c=DateTime.now()
                                                  ,AdditionalPurgeCriteria__c=null
                                                  ,ProcessCheckMinRecs__c=13, ProcessCheckMaxRecs__c=null, NextRunInterval__c=30
                                                  ,EmailBody__c=null, EmailNotification__c='dcarmen@paychex.com');
      
      PurgeControl__c purge2 = new PurgeControl__c(Name='Test2',ObjectAPIName__c='Contact',IsActive__c=true,  ProcessType__c='Data Check Only', DataCheckOnly__c=true
                                                  ,DateFieldToCheck__c='CreatedDate',NbrDaysToKeep__c=30, BatchSize__c=100, NextRunTime__c=DateTime.now()
                                                  ,AdditionalPurgeCriteria__c='LastName=\'TestLastA\''
                                                  ,ProcessCheckMinRecs__c=null, ProcessCheckMaxRecs__c=9, NextRunInterval__c=60
                                                  ,EmailBody__c=null, EmailNotification__c=null);

      PurgeControl__c purge3 = new PurgeControl__c(Name='Test3',ObjectAPIName__c='Lead',IsActive__c=true,  ProcessType__c='Data Check Only', DataCheckOnly__c=true
                                                  ,DateFieldToCheck__c='CreatedDate',NbrDaysToKeep__c=null, NbrMinutesToQuery__c=60, NextRunTime__c=DateTime.now()
                                                  ,AdditionalPurgeCriteria__c=null
                                                  ,ProcessCheckMinRecs__c=1, ProcessCheckMaxRecs__c=null, NextRunInterval__c=90
                                                  ,EmailBody__c=null, EmailNotification__c=null);

      PurgeControl__c purge4 = new PurgeControl__c(Name='Test4',ObjectAPIName__c='BadObject',IsActive__c=true,  ProcessType__c='Data Check Only', DataCheckOnly__c=true
                                                  ,DateFieldToCheck__c='CreatedDate',NbrDaysToKeep__c=30, NextRunTime__c=DateTime.now()
                                                  ,AdditionalPurgeCriteria__c=null
                                                  ,ProcessCheckMinRecs__c=null, ProcessCheckMaxRecs__c=null, NextRunInterval__c=300
                                                  ,EmailBody__c=null, EmailNotification__c=null);
      PurgeControl__c purge5 = new PurgeControl__c(Name='Test5',CheckApexClass__c='UserLicenseCheck',IsActive__c=true,  ProcessType__c='Data Check Only', DataCheckOnly__c=true
                                                  ,DateFieldToCheck__c='CreatedDate',NbrDaysToKeep__c=30, NextRunTime__c=DateTime.now()
                                                  ,AdditionalPurgeCriteria__c=null
                                                  ,ProcessCheckMinRecs__c=null, ProcessCheckMaxRecs__c=null, NextRunInterval__c=300
                                                  ,EmailBody__c=null, EmailNotification__c=null);
      PurgeControl__c purge6 = new PurgeControl__c(Name='Test6',CheckApexClass__c='BadClassName',IsActive__c=true,  ProcessType__c='Data Check Only', DataCheckOnly__c=true
                                                  ,DateFieldToCheck__c='CreatedDate',NbrDaysToKeep__c=30, NextRunTime__c=DateTime.now()
                                                  ,AdditionalPurgeCriteria__c=null
                                                  ,ProcessCheckMinRecs__c=null, ProcessCheckMaxRecs__c=null, NextRunInterval__c=300
                                                  ,EmailBody__c=null, EmailNotification__c=null);
      PurgeControl__c purge7 = new PurgeControl__c(Name='Test7',CheckApexClass__c=null,IsActive__c=true,  ProcessType__c='Data Check Only', DataCheckOnly__c=true
                                                  ,DateFieldToCheck__c='CreatedDate',NbrDaysToKeep__c=null, NextRunTime__c=DateTime.now()
                                                  ,AdditionalPurgeCriteria__c=null
                                                  ,ProcessCheckMinRecs__c=null, ProcessCheckMaxRecs__c=null, NextRunInterval__c=300
                                                  ,EmailBody__c=null, EmailNotification__c=null);

      PurgeControl__c[] purges = new PurgeControl__c[]{purge1,purge2,purge3, purge4, purge5, purge6, purge7};
      insert purges;
      
      // just to make sure the flag is being set correctly
      //System.assertEquals(purges.size(), [select count() from PurgeControl__c where ProcessCheckBatch__c=true]);
      
      // create records to count
      Account[] accts = new Account[]{};
      for (Integer cnt=0; cnt<10; cnt++) {
         accts.add(new Account(Name='Account'+cnt));
      }
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
        
      Contact[] ctcts = new Contact[]{};
      for (Account acct : accts) {
         ctcts.add(new Contact(AccountId=acct.Id, LastName='TestLastA', FirstName='TestFirstA'+ctcts.size()));
         ctcts.add(new Contact(AccountId=acct.Id, LastName='TestLastB', FirstName='TestFirstB'+ctcts.size()));
      } // for (Account acct
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      insert ctcts;

      ProcessChecker pc = new ProcessChecker();
      Test.startTest();      
      //Database.executeBatch(pc,purges.size());
      ProcessChecker.launchBatch();
      Test.stopTest();
      
      Map<Id,PurgeControl__c> pcMap = PurgeBatchTest.getPurgeControlMap();
      
      purge1 = pcMap.get(purge1.Id); 
      System.assertEquals(true,purge1.IsActive__c);
      System.assertEquals(false,purge1.MoreRecords__c);
      System.assertEquals(1,purge1.PurgeControlTrackers__r.size());
      System.assertEquals(10,purge1.PurgeControlTrackers__r[0].NbrFound__c);
      
      purge2 = pcMap.get(purge2.Id); 
      System.assertEquals(true,purge2.IsActive__c);
      System.assertEquals(false,purge2.MoreRecords__c);
      System.assertEquals(1,purge2.PurgeControlTrackers__r.size());
      System.assertEquals(10,purge2.PurgeControlTrackers__r[0].NbrFound__c);
      
      purge3 = pcMap.get(purge3.Id); 
      System.assertEquals(true,purge3.IsActive__c);
      System.assertEquals(false,purge3.MoreRecords__c);
      System.assertEquals(1,purge3.PurgeControlTrackers__r.size());
      System.assertEquals(0,purge3.PurgeControlTrackers__r[0].NbrFound__c);
      
      //System.assertEquals(true,pc.hasZeroRecordResult);
      
   } // testChecker
    
   static testMethod void testNextTime() {
      PurgeControl__c purge1 = new PurgeControl__c(Name='Test1',BusinessHoursOnly__c=false,IsActive__c=true, NextRunInterval__c=null, NextRunDays__c=null, TimeOfDayToRun__c=null);
      Time checkTime = Time.newInstance(8, 15, 0, 0);
      purge1.TimeOfDayToRun__c = checkTime;
      ProcessChecker procCheck = new ProcessChecker();
      ProcessChecker.setNextRunTime(purge1);
      System.assertEquals(Date.today().addDays(1), purge1.NextRunTime__c.date());
      System.assertEquals(checkTime, purge1.NextRunTime__c.time());
       
      purge1.TimeOfDayToRun__c = null;
      purge1.NextRunInterval__c = 60;
      purge1.BusinessHoursOnly__c = false;
       
      ProcessChecker.setNextRunTime(purge1);
      System.assertEquals(Datetime.now().addMinutes(60), purge1.NextRunTime__c);
       
      purge1.BusinessHoursOnly__c = true;
      ProcessChecker.setNextRunTime(purge1);
      // because we have to account for business days, we can't necessarily know the exact time in the test. Add 1 minute to account for difference in seconds.
      System.assertEquals(true, Datetime.now().addMinutes(60) <= purge1.NextRunTime__c.addMinutes(1), 'Check time '+Datetime.now().addMinutes(60)+' NextRunTime='+purge1.NextRunTime__c);
      
      // test the day.
      purge1.BusinessHoursOnly__c = false;
      purge1.TimeOfDayToRun__c = checkTime;
       
      String dayOfWeek = Datetime.now().addDays(3).format('EEEE');
      System.debug('testNextTime dayOfWeek='+dayOfWeek);
      purge1.DaysToRun__c = dayOfWeek;

      ProcessChecker.setNextRunTime(purge1);
      System.assertEquals(Date.today().addDays(3), purge1.NextRunTime__c.date());
      System.assertEquals(checkTime, purge1.NextRunTime__c.time());

      purge1.NextRunDays__c=8;
      purge1.DaysToRun__c = null;
      purge1.TimeOfDayToRun__c = checkTime;
      purge1.NextRunInterval__c = null;
       
      ProcessChecker.setNextRunTime(purge1);
      System.assertEquals(Date.today().addDays(8), purge1.NextRunTime__c.date());
      System.assertEquals(checkTime, purge1.NextRunTime__c.time());
       
       
   } // testNextTime
   
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testProcessChecker', new ProcessChecker());
   } // testScheduler
   

} // class ProcessCheckerTest