/* 
 * Test methods for the IncidentCaseUtilities class
 *
 * History
 * -------
   11/13/2017 Dan Carmen   Clean up code

 */
@isTest
public class TestTriggers {
    public static testMethod void otherTest(){
        TriggerHelper.hasAlreadyExecutedCreateMassIncidentCases();
        TriggerHelper.setAlreadyExecutedCreateMassIncidentCases();
    }   


   static testMethod void testCreateMassIncidentCases2() {
        
      Account aAccount = new Account();
      aAccount.name = 'test';
      insert aAccount;
        
      //Set up Test Data
      Case testcase = new Case();
      //testCase.AccountId = [SELECT Id from account where name = 'Mass Incident'].Id;
      testCase.accountid = aAccount.id;
      testCase.Status = 'New';
      testCase.Origin = 'Phone';
      testCase.Mass_Create_Indicator__c = 'Bis Id'; 
      testCase.bis_id_file__c = '648774';
        
      insert testCase;
        
      Test.startTest();
      List<String> insertedCaseIdList = new List<String>();
      insertedCaseIdList.add(testCase.id);
      IncidentCaseUtilities.createMassIncidentCases(insertedCaseIdList);
        
      Test.stopTest();
   } // testCreateMassIncidentCases2


   static testMethod void testBadBisId() {
        
      Account aAccount = new Account();
      aAccount.name = 'test';
      insert aAccount;
        
      //Set up Test Data
      Case testcase = new Case();
      //testCase.AccountId = [SELECT Id from account where name = 'Mass Incident'].Id;
      testCase.accountid = aAccount.id;
      testCase.Status = 'New';
      testCase.Origin = 'Phone';
      testCase.Mass_Create_Indicator__c = 'Bis Id'; 
      testCase.bis_id_file__c = 'BadBisId';
        
      insert testCase;

      Test.startTest();
        
      List<String> insertedCaseIdList = new List<String>();
      insertedCaseIdList.add(testCase.id);
      IncidentCaseUtilities.createMassIncidentCases(insertedCaseIdList);
        
      Test.stopTest();
   } // testBadBisId


   static testMethod void testCreateMassIncidentCases1() {
        
      Account[] accts = new Account[]{};
      Account aAccount = new Account(Name='Main Account');
      accts.add(aAccount);
      
      // create other accounts
      accts.add(new Account(Name='Test 648774', Bis_Id__c=648774));
      accts.add(new Account(Name='Test 677848', Bis_Id__c=677848));
      accts.add(new Account(Name='Test 1646021', Bis_Id__c=1646021));
      accts.add(new Account(Name='Test 1652867', Bis_Id__c=1652867));
      accts.add(new Account(Name='Test 1650362', Bis_Id__c=1650362));
      accts.add(new Account(Name='Test 177979', Bis_Id__c=177979));
      accts.add(new Account(Name='Test 1785291', Bis_Id__c=1785291));
      accts.add(new Account(Name='Test 1785345', Bis_Id__c=1785345));
      accts.add(new Account(Name='Test 1785360', Bis_Id__c=1785360));
      accts.add(new Account(Name='Test 1642583', Bis_Id__c=1642583));
      insert accts;
       
      //Set up Test Data
      Case testcase = new Case();
      //testCase.AccountId = [SELECT Id from account where name = 'Mass Incident'].Id;
      testCase.accountid = aAccount.id;
      testCase.Status = 'New';
      testCase.Origin = 'Phone';
      testCase.Mass_Create_Indicator__c = 'Bis ID'; 
      testCase.bis_id_file__c = '648774, 677848, 1646021, 1652867, 1650362, 177979, 1785291, 1785345, 1785360, 1642583';

      insert testCase;
        
      casecomment cc = new casecomment();
      cc.parentid=testcase.id;
      cc.commentbody = 'testing';
      insert cc;

      // set this to 4 to hit the rest of the code
      IncidentCaseUtilities.collectionSize = 4;
      
      Test.startTest();
      IncidentCaseUtilities.massCreateIncidentCases(testCase.id);
      Test.stopTest();
      
      // should be 1 case created for each bis id
      System.assertEquals(10,[select count() from Case where ParentId=:testCase.Id]);
   } // testCreateMassIncidentCases1
        /*
        +'1651063 170066 1693377 1651085 1651133 1651148 1652868 1655587 1656889 1659051 1659174 648774 677848 1646021 '
        +'1652867 1650362 177979 1785291 1785345 1785360 1642583 1651063 170066 1693377 1651085 1651133 1651148 1652868 '
        +'1655587 1656889 1659051 1659174 648774 677848 1646021 1652867 1650362 177979 1785291 1785345 1785360 1642583 '
        +'1651063 170066 1693377 1651085 1651133 1651148 1652868 1655587 1656889 1659051 1659174 648774 677848 1646021 '
        +'1652867 1650362 177979 1785291 1785345 1785360 1642583 1651063 170066 1693377 1651085 1651133 1651148 1652868 '
        +'1655587 1656889 1659051 1659174 648774 677848 1646021 1652867 1650362 177979 1785291 1785345 1785360 1642583 1651063 '
        +'170066 1693377 1651085 1651133 1651148 1652868 1655587 1656889 1659051 1659174 648774 677848 1646021 1652867 1650362 '
        +'177979 1785291 1785345 1785360 1642583 1651063 170066 1693377 1651085 1651133 1651148 1652868 1655587 1656889 1659051 '
        +'1659174 648774 677848 1646021 1652867 1650362 177979 1785291 1785345 1785360 1642583 1651063 170066 1693377 1651085 1651133 '
        +'1651148 1652868 1655587 1656889 1659051 1659174 648774 677848 1646021 1652867 1650362 177979 1785291 1785345 1785360 1642583 '
        +'1651063 170066 1693377 1651085 1651133 1651148 1652868 1655587 1656889 1659051 1659174 648774 677848 1646021 1652867 1650362 '
        +'177979 1785291 1785345 1785360 1642583 1651063 170066 1693377 1651085 1651133 1651148 1652868 1655587 1656889 1659051 1659174 '
        +'648774 677848 1646021 1652867 1650362 177979 1785291 1785345 1785360 1642583 1651063 170066 1693377 1651085 1651133 1651148 '
        +'1652868 1655587 1656889 1659051 1659174 648774 677848 1646021 1652867 1650362 177979 1785291 1785345 1785360 1642583 1651063 '
        +'170066 1693377 1651085 1651133 1651148 1652868 1655587 1656889 1659051 1659174 648774 677848 1646021 1652867 1650362 177979 '
        +'1785291 1785345 1785360 1642583 1651063 170066 1693377 1651085 1651133 1651148 1652868 1655587 1656889 1659051 1659174 648774 '
        +'677848 1646021 1652867 1650362 177979 1785291 1785345 1785360 1642583 1651063 170066 1693377 1651085 1651133 1651148 1652868 '
        +'1655587 1656889 1659051 1659174 648774 677848 1646021 1652867 1650362 177979 1785291 1785345 1785360 1642583 1651063 170066 '
        +'1693377 1651085 1651133 1651148 1652868 1655587 1656889 1659051 1659174 648774 677848 1646021 1652867 1650362 177979 1785291 '
        +'1785345 1785360 1642583 1651063 170066 1693377 1651085 1651133 1651148 1652868 1655587 1656889 1659051 1659174 648774 677848 '
        +'1646021 1652867 1650362 177979 1785291 1785345 1785360 1642583 1651063 170066 1693377 1651085 1651133 1651148 1652868 1655587 '
        +'1656889 1659051 1659174 648774 677848 1646021 1652867 1650362 1979 1785291 1785345 1785360 1642583 1651063 170066 1693377 1651085 '
        +'1651133 1651148 1652868 1655587 1656889 1659051 1659174';
        */

/*
    static testMethod void testRelated401KCases() 
    {
      Id caseRecordType = [SELECT Id, Name FROM RecordType WHERE Name='Service Support 401k/S125 Case' and IsActive = TRUE AND SobjectType = 'Case' LIMIT 1][0].id;
      Account acc = new account(name = 'TestN');
      insert acc;
      Contact con = new contact(accountId = acc.id, lastname='lasttest', firstname='firsttest');
      insert con;

      Case parentCase = new case(accountId = acc.id, Mass_Create_Indicator__c = 'Bis ID', RecordTypeId = caseRecordType ,contactId = con.id, status = 'New', type = 'Help Request', origin = 'Email', subject = 'Testing subject');
      insert parentCase;

      Case childCase = new case(accountId = acc.id, RecordTypeId = caseRecordType , contactId = con.id, status = 'New',ParentId= parentCase.id, type = 'Help Request', origin = 'Email', subject = 'Testing subject');
      insert childCase;
      
      parentCase.status = 'Solved';
      update parentCase;
    }
*/

} // class TestTriggers