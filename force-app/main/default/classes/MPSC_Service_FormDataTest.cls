@IsTest
public class MPSC_Service_FormDataTest {
    @isTest
    public static void getMetadataTest(){
        //Id caseID=MPSC_TestDataFactory.getCaseMetadataTest();
        //Id caseIDforelse=MPSC_TestDataFactory.getCaseMetadataelseTest();
        Account accObj = new Account();
        accObj.name = 'test Acc';
        accObj.Bis_ID__c =1235677;
        accObj.AccountNumber ='1-345678';
        insert accObj;
        Id getRecordTypeID=Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Multi-Product Service Case').getRecordTypeId();
        Case c=new Case();
        c.Type='Loss';
        c.Sub_type__c='NA';
        c.Status='Approved/Ready';
        c.RecordTypeId=getRecordTypeID;
        c.Is_Created_by_Mid_Market_Flow__c= true;
        c.AccountId=accObj.Id;
        insert c;
        Case caseLossSubmitted=new Case();
        caseLossSubmitted.Type='Loss';
        caseLossSubmitted.Status='Submitted';
        caseLossSubmitted.RecordTypeId=getRecordTypeID;
        caseLossSubmitted.Is_Created_by_Mid_Market_Flow__c= true;
        caseLossSubmitted.AccountId=accObj.Id;
        insert caseLossSubmitted;
        Reference_MPSC_Service_Submission__c rmp=new Reference_MPSC_Service_Submission__c();
        rmp.Case__c=caseLossSubmitted.Id;
        insert rmp;
        Test.startTest();
            MPSC_Service_FormData.getMetadata(c.Id);
            MPSC_Service_FormData.getMetadata(caseLossSubmitted.Id);
        Test.stopTest();
    }/*
    public static void getMetadataTestelse(){
        Id caseIDforelse=MPSC_TestDataFactory.getCaseMetadataelseTest();
        
        Test.startTest();
       
            MPSC_Service_FormData.getMetadata(caseIDforelse);
        Test.stopTest();
    }*/
}