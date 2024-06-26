@IsTest
public class MidMarketCreateCaseFlowHandlerTest {
	@isTest
    public static void caseAssgnmntRules_test(){
        Id getRecordTypeID=Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Multi-Product Service Case').getRecordTypeId();
        Case c=new Case();
        c.Type='Loss';
        c.Status='Approved/Ready';
        c.RecordTypeId=getRecordTypeID;
        c.Is_Created_by_Mid_Market_Flow__c= true;
        insert c;
        MidMarketCreateCaseFlowHandler.caseAssgnmntRules(new List<case>{c});
        MidMarketMenuLwcController.getMenuMetaData();
    }
}