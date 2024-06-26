/* 
  Test Methods for Data Dictionary
   
  History
  -------
  03/08/2021 Dan Carmen           Created
  01/06/2022 Dan Carmen           Add NotifyAllChanges__c

 */
@isTest
public class DataDictionaryTest {

   static testMethod void testDictionary() {
      // for the notification to be sent
      DataDictionaryNotify__c ddn = new DataDictionaryNotify__c(Name='Dan',Active__c=true,EmailsToNotify__c='dcarmen@paychex.com');
      insert ddn;
      
      // the object we're setting up
      DataDictionaryObject__c ddo = new DataDictionaryObject__c(Name='Data Dictionary Object',Active__c=true,NotifyAllChanges__c='Dan',NotifyNewField__c='Dan',ObjectAPIName__c='DataDictionaryObject__c', CountRecords__c=true);
      insert ddo;
       
      // setup fields - include a bad field to mark deleted.
      Data_Dictionary__c dd1 = new Data_Dictionary__c(Name='DataDictionaryObject__c.Name', DataDictionaryObject__c=ddo.Id, API_Name__c='Name', Field_Label__c='Data Dictionary Object Name', Data_Type__c='STRING', Length__c=80, Domain__c='DataDictionaryObject__c');
      Data_Dictionary__c dd2 = new Data_Dictionary__c(Name='DataDictionaryObject__c.Active__c', DataDictionaryObject__c=ddo.Id, API_Name__c='Active__c', Field_Label__c='Active?', Data_Type__c='BOOLEAN', Length__c=0, Domain__c='DataDictionaryObject__c');
      // this should be marked as deleted
      Data_Dictionary__c dd3 = new Data_Dictionary__c(Name='DataDictionaryObject__c.BadField__c', DataDictionaryObject__c=ddo.Id, API_Name__c='BadField__c', Field_Label__c='Bad Field', Data_Type__c='BOOLEAN', Length__c=0, Domain__c='DataDictionaryObject__c');
      // the length field should get updated
      Data_Dictionary__c dd4 = new Data_Dictionary__c(Name='DataDictionaryObject__c.ProcessNotes__c', DataDictionaryObject__c=ddo.Id, API_Name__c='ProcessNotes__c', Field_Label__c='Process Notes', Data_Type__c='TEXTAREA', Length__c=100, Domain__c='DataDictionaryObject__c');
      Data_Dictionary__c[] dds = new Data_Dictionary__c[]{dd1,dd2,dd3,dd4};
      insert dds;
       
      Test.setMock(HttpCalloutMock.class, new DataDictionaryMock()); 
      
      Test.startTest();
      DataDictionaryBatch ddb = new DataDictionaryBatch();
      Database.executeBatch(ddb, 1);
      Test.stopTest();
       
      Map<Id,Data_Dictionary__c> ddMap = new Map<Id,Data_Dictionary__c>([Select Id, Name, DataDictionaryObject__c, API_Name__c, Field_Label__c, Data_Type__c, Length__c
                                                                               ,Deleted_Date__c
                                                                           From Data_Dictionary__c]);
      dd3 = ddMap.get(dd3.Id);
      // make sure delete is marked
      System.assertEquals(Date.today(), dd3.Deleted_Date__c);
      dd4 = ddMap.get(dd4.Id);
      Integer processNotesLength = DataDictionaryObject__c.ProcessNotes__c.getDescribe().getLength();
      // make sure existing record is updated
      System.assertNotEquals(100,dd4.Length__c);
      System.assertEquals(processNotesLength,dd4.Length__c);
      
      Data_Dictionary__c ddNotify = null;
      // look for the notify field
      for (Data_Dictionary__c dd : ddMap.values()) {
         if (dd.API_Name__c == 'NotifyNewField__c') {
            ddNotify = dd;
            break;
         }
      } // for (Data_Dictionary__c dd
      // make sure record is inserted
      System.assertNotEquals(null, ddNotify);
      Integer notifyLength = DataDictionaryObject__c.NotifyNewField__c.getDescribe().getLength();
      System.assertEquals(notifyLength,ddNotify.Length__c);
       
      ddo = [Select Id, Name, EarliestCount__c, LatestCount__c
                   ,(Select Id, Count__c, CountDate__c from DataDictionaryCounts__r)
               From DataDictionaryObject__c
              where Id=:ddo.Id];
      System.assertEquals(1,ddo.DataDictionaryCounts__r.size());
      System.assertEquals(1,ddo.DataDictionaryCounts__r[0].Count__c);
      System.assertEquals(Date.today(), ddo.DataDictionaryCounts__r[0].CountDate__c);
      System.assertEquals(ddo.DataDictionaryCounts__r[0].Id, ddo.EarliestCount__c);
      System.assertEquals(ddo.DataDictionaryCounts__r[0].Id, ddo.LatestCount__c);
       
   } // testDictionaryNew
    
    static testMethod void testSchedule() {
        TestHelper.testScheduler('DataDictionaryTest', new DataDictionaryBatch());
    }
    
} // class DataDictionaryTest