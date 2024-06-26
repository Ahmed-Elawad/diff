/**
 * This class contains unit tests for validating the CaseServiceNow class.
 * 
 *
 * History
 * --------
 * 02/17/2020 Jacob Hinds       Created  
 * 05/18/2021 Carrie Marciano updated StageNames with OppStage labels
 * 06/16/2023 Lalan Kumar       Added method testScheduleBatch and MODE_OpptyStatus line
   12/22/2023 Dan Carmen         Change how opp is being saved - probability isn't setting correctly

 */
 
@isTest
public class OpptyAutoCloseBatchTest {
    static testMethod void autoCloseBatchTest() {
        Account acct = new Account(Name='test acct');
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert acct;
        Map <String,Schema.RecordTypeInfo> rtMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName();

    	Opportunity opp = new Opportunity(Name='test Opp',AccountId=acct.Id,StageName=Label.OppStage_Qualified,CloseDate = date.today().addDays(80),Auto_Close_Date__c=date.today());
        OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
        insert opp;
        insert new Apex_Batch_Control__c(Name=OpptyAutoCloseBatch.CLASS_NAME,Active__c=true,Check_Days__c = 365);
        test.startTest();
        OpptyAutoCloseBatch oac = new OpptyAutoCloseBatch();
        Integer batchSize = 500;
        database.executeBatch(oac, batchSize);
        //OpptyAutoCloseBatch.launchBatch(OpptyAutoCloseBatch.MODE_OpptyStatus);
        test.stopTest();
        Opportunity uOpp = [SELECT Id,StageName,Reason_Not_Sold__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        system.assertEquals(Label.OppStage_Lost,uOpp.StageName);
        system.assertEquals(Label.Auto_Close_Stage,uOpp.Reason_Not_Sold__c);
    } // autoCloseBatchTest
    
    static testMethod void testTermedRep() {
       Date checkDate = Date.today().addDays(-100);
       User termUsr = [Select Id, Name, Termination_Date__c from User where IsActive=false and Job_Name__c=:UserHelper.JOB_REP and Termination_Date__c != null and Termination_Date__c < :checkDate limit 1];
       System.debug('testTermedRep termUsr='+termUsr);
       Account acct = new Account(Name='test acct');
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert acct;
       Opportunity opp1 = new Opportunity(Name='test Opp1',AccountId=acct.Id,OwnerId=termUsr.Id,StageName=Label.OppStage_Qualified,CloseDate = date.today().addDays(80)
                                          ,NSS_Source__c='Outbound',Auto_Close_Date__c=null);
       Opportunity opp2 = new Opportunity(Name='test Opp2',AccountId=acct.Id,OwnerId=termUsr.Id,StageName=Label.OppStage_Qualified,CloseDate = date.today().addDays(80)
                                          ,NSS_Source__c='Inbound',Auto_Close_Date__c=null);
       Opportunity opp3 = new Opportunity(Name='test Opp3',AccountId=acct.Id,OwnerId=termUsr.Id,StageName=Label.OppStage_Qualified,CloseDate = date.today().addDays(80)
                                          ,NSS_Source__c=null,Auto_Close_Date__c=null);
       OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
       insert new Opportunity[]{opp1,opp2,opp3};
       insert new Apex_Batch_Control__c(Name=OpptyAutoCloseBatch.CLASS_NAME+OpptyAutoCloseBatch.MODE_OpptyStatus,Active__c=true,Check_Days__c = 100);
        test.startTest();
        OpptyAutoCloseBatch.launchBatch(OpptyAutoCloseBatch.MODE_OpptyStatus);
        test.stopTest();
       Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, StageName,Reason_Not_Sold__c
                                                               From Opportunity]);
       opp1 = oppMap.get(opp1.Id);
       Assert.areEqual(Label.OppStage_Lost,opp1.StageName);
       Assert.areEqual(Label.Oppty_Auto_Close,opp1.Reason_Not_Sold__c);

       opp2 = oppMap.get(opp2.Id);
       Assert.areEqual(Label.OppStage_Qualified,opp2.StageName);
       Assert.isNull(opp2.Reason_Not_Sold__c);

       opp3 = oppMap.get(opp1.Id);
       Assert.areEqual(Label.OppStage_Lost,opp1.StageName);
       Assert.areEqual(Label.Oppty_Auto_Close,opp1.Reason_Not_Sold__c);
    } // testTermedRep

    static testMethod void testScheduler() {
      insert new Apex_Batch_Control__c(Name=OpptyAutoCloseBatch.CLASS_NAME,Active__c=true,Check_Days__c = 365);
      TestHelper.testScheduler('OpptyAutoCloseBatch', new OpptyAutoCloseBatch());
   	} // testScheduler
    
      static testMethod void testScheduleBatch() {
      TestHelper.testScheduler(OpptyAutoCloseBatch.CLASS_NAME, new OpptyAutoCloseBatch());
   }
 
} // OpptyAutoCloseBatchTest