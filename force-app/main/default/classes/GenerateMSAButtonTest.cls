@isTest
public class GenerateMSAButtonTest {
@isTest
    public static void GenerateMSATest(){
        Account acc = new Account(Name='Test',Federal_ID_Number__c='123123');
        Insert acc;
        
        Contact con = new Contact(LastName = 'Test',AccountId = acc.Id);
        Insert con;
        
        Opportunity opp = new Opportunity(Name = 'Test',AccountId = acc.Id, CloseDate = Date.today(),StageName = 'Discovery');
        Insert opp;
        
        CSO_Tracking__c cso = new CSO_Tracking__c(Opportunity__c = opp.Id,AccountId__c = acc.Id);
        Insert cso;
        
        GenerateMSAButton.getTracking(opp.Id);
    }
}