@isTest
public class PEOUnderwritingDiscrepancyAfterTest {
    private boolean checkDiscForChecklist(String value) {
        if (value == '401K Questionnaire') return true;
        if (value == 'Covid Questionnaire') return true;
        if (value == 'Workers Comp Questionnaire') return true;
        if (value == 'EPLI Questionnaire') return true;
        if (value == 'PEO Information Sheet') return true;
        if (value == 'Medical Questionnaire') return true;
        return false;
    }
    @TestSetup
    private static void setup() {
        TriggerSetupClasses__c uwAfterSetup = new TriggerSetupClasses__c();
        uwAfterSetup.IsAfter__c = true;
        uwAfterSetup.ClassName__c ='PEOUnderwritingDiscrepancyAfter';
        uwAfterSetup.TriggerKey__c = 'PEOUnderwritingDiscrepancy';
        uwAfterSetup.Active__c = true;
        uwAfterSetup.Name = 'Test uw after';
        uwAfterSetup.InterfaceVersion__c = 'C';
        uwAfterSetup.SortOrder__c = 1;
        insert uwAfterSetup;
        
        TriggerSetupClasses__c uwBeforeSetup = new TriggerSetupClasses__c();
        uwBeforeSetup.IsBefore__c = true;
        uwBeforeSetup.ClassName__c ='PEOUnderwritingDiscrepancyBefore';
        uwBeforeSetup.TriggerKey__c = 'PEOUnderwritingDiscrepancy';
        uwBeforeSetup.Active__c = true;
        uwBeforeSetup.Name = 'Test uw Before';
        uwBeforeSetup.InterfaceVersion__c = 'C';
        uwBeforeSetup.SortOrder__c = 1;
        insert uwBeforeSetup;     
        
        List<String> docNames = new List<String>();
        docNames.add('Census');
        docNames.add('Claims Information');
        docNames.add('Health Insurance Renewal');
        docNames.add('Health Insurance Summary');
        docNames.add('Other');
        docNames.add('SUI Rate Forms');
        docNames.add('WC Declarations Page');
        docNames.add('Loss Runs');
        
        List<PEO_Onboarding_Document_Map__c> nameMaplst = new List<PEO_Onboarding_Document_Map__c>();
        for (String docName: docNames) {
            nameMaplst.add(new PEO_Onboarding_Document_Map__c(name=docName));   
        }
        insert nameMaplst;
        
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ClientSpaceLocationQueueableTest 1', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, ShippingStreet = 'Billling Street', 
                                    ShippingPostalCode='1234', ShippingState='NY', ShippingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='', agentsync__ID_FEIN__c='Test1');
        insert acctA;
        
        PEO_Onboarding_Checklist__c chklst = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctA.Id, Medical_Benefits_Underwriting_Requested__c='Yes');
        Insert chklst;
        
        PEO_Onboarding_Medical_Questionnaire__c medQs = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=chklst.Id);
        insert medQs;
        
        List<PEO_Onboarding_Document__c> docLst = new List<PEO_Onboarding_Document__c>();
        
        for (String docName : docNames) {
            docLst.add(new PEO_Onboarding_Document__c(Name=docName,PEO_Onboarding_Checklist__c=chklst.Id, Status__c='', Routing_Name__c=docName));
        }
        System.debug('docLst:'+docLst);
        insert docLst;
    }
    
    static testMethod void testDocStatusUpdate(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c LIMIT 1];
        
        Schema.SObjectType s = Schema.getGlobalDescribe().get('PEO_Onboarding_Document_Discrepency__c');
        Schema.DescribeSObjectResult r = s.getDescribe();
        Map<String,Schema.SObjectField> fields = r.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get('Discrepancy_Type__c').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<PEO_Onboarding_Document_Discrepency__c> discLst = new List<PEO_Onboarding_Document_Discrepency__c>();
        
        for( Schema.PicklistEntry pickListVal : ple){
            String value = pickListVal.getLabel();
            PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c();
            disc.PEO_Underwriting_Checklist__c = checklist.Id;
            disc.Discrepancy_Type__c = value;
            discLst.add(disc);
        }
        
        insert discLst;

        PEO_Onboarding_Document__c[] docLst = [SELECT id, Status__c, Name, Routing_Name__c FROM PEO_Onboarding_Document__c];
        PEO_Onboarding_Document__c failedDoc;
        Boolean atleastOneDocDoesNotHaveAnUpdatedStatus = false;
        
        for (PEO_Onboarding_Document__c doc : docLst) {
            if (doc.Status__c != 'Discrepancy') {
                atleastOneDocDoesNotHaveAnUpdatedStatus = true;
                failedDoc = doc;
                break;
            }
        }
        
        //System.assertEquals(false,atleastOneDocDoesNotHaveAnUpdatedStatus, 'Doc statuses did not update accordingly: '+ failedDoc);
        
        PEO_Onboarding_Document_Discrepency__c disc = [SELECT Id, Status__c, PEO_Underwriting_Checklist__c FROM PEO_Onboarding_Document_Discrepency__c 
                                                       WHERE Discrepancy_Type__c='Census' LIMIT 1];
        disc.Status__c = 'Resolved';
        update disc;
        
        PEO_Onboarding_Document__c censusDoc = [SELECT Id, Status__c FROM PEO_Onboarding_Document__c LIMIT 1];
        System.assertEquals(censusDoc.Status__c,'Submitted by Prospect');
    }
    
    static testMethod void testDiscrepancyCountUpdateNoParent(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c LIMIT 1];
        
        PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c(PEO_Underwriting_Checklist__c=checklist.Id, Discrepancy_Category__c='Medical', Status__c='Open');
        PEO_Onboarding_Document_Discrepency__c disc2 = new PEO_Onboarding_Document_Discrepency__c(PEO_Underwriting_Checklist__c=checklist.Id, Discrepancy_Category__c='Medical', Status__c='Open');
        PEO_Onboarding_Document_Discrepency__c disc3 = new PEO_Onboarding_Document_Discrepency__c(PEO_Underwriting_Checklist__c=checklist.Id, Discrepancy_Category__c='Risk', Status__c='Open');
        List<PEO_Onboarding_Document_Discrepency__c> discList = new List<PEO_Onboarding_Document_Discrepency__c>();
        discList.add(disc);
        discList.add(disc2);
        discList.add(disc3);
        insert discList;
        
        checklist = [SELECT Id, Name, Number_of_Open_Medical_Discrepancies__c, Number_of_Open_Risk_Discrepancies__c FROM PEO_Onboarding_Checklist__c WHERE Id = :checklist.Id];
        System.assertEquals(2, checklist.Number_of_Open_Medical_Discrepancies__c);
        System.assertEquals(1, checklist.Number_of_Open_Risk_Discrepancies__c);
        
        disc2.Status__c = 'Resolved';
        update disc2;
            
        checklist = [SELECT Id, Name, Number_of_Open_Medical_Discrepancies__c, Number_of_Open_Risk_Discrepancies__c FROM PEO_Onboarding_Checklist__c WHERE Id = :checklist.Id];
        System.assertEquals(1, checklist.Number_of_Open_Medical_Discrepancies__c);
        
        disc3.Status__c = 'Resolved';
        update disc3;
        
        checklist = [SELECT Id, Name, Number_of_Open_Medical_Discrepancies__c, Number_of_Open_Risk_Discrepancies__c FROM PEO_Onboarding_Checklist__c WHERE Id = :checklist.Id];
        System.assertEquals(0, checklist.Number_of_Open_Risk_Discrepancies__c);
    }
    
    static testMethod void testDiscrepancyCountUpdateWithParent(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c LIMIT 1];
        PEO_Onboarding_Checklist__c childChecklist = new PEO_Onboarding_Checklist__c(Parent_PEO_Checklist__c=checklist.Id);
        insert childChecklist;
        
        PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c(PEO_Underwriting_Checklist__c=childChecklist.Id, Discrepancy_Category__c='Medical', Status__c='Open');
        PEO_Onboarding_Document_Discrepency__c disc2 = new PEO_Onboarding_Document_Discrepency__c(PEO_Underwriting_Checklist__c=childChecklist.Id, Discrepancy_Category__c='Medical', Status__c='Open');
        PEO_Onboarding_Document_Discrepency__c disc3 = new PEO_Onboarding_Document_Discrepency__c(PEO_Underwriting_Checklist__c=childChecklist.Id, Discrepancy_Category__c='Risk', Status__c='Open');
        List<PEO_Onboarding_Document_Discrepency__c> discList = new List<PEO_Onboarding_Document_Discrepency__c>();
        discList.add(disc);
        discList.add(disc2);
        discList.add(disc3);
        insert discList;
        
        checklist = [SELECT Id, Name, Number_of_Open_Medical_Discrepancies__c, Number_of_Open_Risk_Discrepancies__c FROM PEO_Onboarding_Checklist__c WHERE Id = :checklist.Id];
        System.assertEquals(2, checklist.Number_of_Open_Medical_Discrepancies__c);
        System.assertEquals(1, checklist.Number_of_Open_Risk_Discrepancies__c);
        
        disc2.Status__c = 'Resolved';
        update disc2;
            
        checklist = [SELECT Id, Name, Number_of_Open_Medical_Discrepancies__c, Number_of_Open_Risk_Discrepancies__c FROM PEO_Onboarding_Checklist__c WHERE Id = :checklist.Id];
        System.assertEquals(1, checklist.Number_of_Open_Medical_Discrepancies__c);
        
        disc3.Status__c = 'Resolved';
        update disc3;
        
        checklist = [SELECT Id, Name, Number_of_Open_Medical_Discrepancies__c, Number_of_Open_Risk_Discrepancies__c FROM PEO_Onboarding_Checklist__c WHERE Id = :checklist.Id];
        System.assertEquals(0, checklist.Number_of_Open_Risk_Discrepancies__c);
        
        disc2.Status__c = 'Open';
        update disc2;
            
        checklist = [SELECT Id, Name, Number_of_Open_Medical_Discrepancies__c, Number_of_Open_Risk_Discrepancies__c FROM PEO_Onboarding_Checklist__c WHERE Id = :checklist.Id];
        System.assertEquals(2, checklist.Number_of_Open_Medical_Discrepancies__c);
    }
    
    /*
    static testMethod void testChatterMessageOnNewComment(){
        list<id> atMentionIdList = new list<id>();
        // get the running user ID and add them to list set
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c LIMIT 1];
        
        Schema.SObjectType s = Schema.getGlobalDescribe().get('PEO_Onboarding_Document_Discrepency__c');
        Schema.DescribeSObjectResult r = s.getDescribe();
        Map<String,Schema.SObjectField> fields = r.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get('Discrepancy_Type__c').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<PEO_Onboarding_Document_Discrepency__c> discLst = new List<PEO_Onboarding_Document_Discrepency__c>();
        
        for( Schema.PicklistEntry pickListVal : ple){
            String value = pickListVal.getLabel();
            PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c();
            disc.PEO_Underwriting_Checklist__c = checklist.Id;
            disc.Discrepancy_Type__c = value;
            discLst.add(disc);
            break;
        }
        
        insert discLst;
        
        PEO_Onboarding_Document_Discrepency__c disc = [SELECT Id, Prospect_Comments__c FROM PEO_Onboarding_Document_Discrepency__c limit 1];
        disc.Prospect_Comments__c = 'Test new comment';
        update disc;
          
        system.assertEquals(PEOUnderwritingDiscrepancyAfter.SENT_CHATTER,true);
    }*/
    
}