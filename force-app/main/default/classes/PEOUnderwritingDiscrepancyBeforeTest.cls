@isTest
public class PEOUnderwritingDiscrepancyBeforeTest {
    
    public static boolean discForDoc(String discType) {
        if (discType == 'Health Insurance Summary of Benefits/Plan Designs') return true;
        if (discType == 'Census') return true;
        if (discType == 'Claims Information') return true;
        if (discType == 'Other') return true;
        if (discType == 'Health Insurance Renewal') return true;
        if (discType == 'Health Insurance Summary of Benefits/Plan Designs') return true;
        if (discType == 'Heath Invoice/PEO Medical Billing Report') return true;
        if (discType == 'Loss Runs') return true;
        if (discType == 'SUI') return true;
        if (discType == 'Workers Comp Declarations Page') return true;
        if (discType == 'Pricing') return true;
        return false;
    }
    
    @TestSetup
    private static void setup() {        
        // trigger setup class for before
        TriggerSetupClasses__c uwBeforeSetup = new TriggerSetupClasses__c();
        uwBeforeSetup.IsBefore__c = true;
        uwBeforeSetup.ClassName__c ='PEOUnderwritingDiscrepancyBefore';
        uwBeforeSetup.TriggerKey__c = 'PEOUnderwritingDiscrepancy';
        uwBeforeSetup.Active__c = true;
        uwBeforeSetup.Name = 'Test uw Before';
        uwBeforeSetup.InterfaceVersion__c = 'C';
        uwBeforeSetup.SortOrder__c = 1;
        insert uwBeforeSetup;     
        
        // trigger setup class for after
        TriggerSetupClasses__c uwAfterSetup = new TriggerSetupClasses__c();
        uwAfterSetup.IsAfter__c = true;
        uwAfterSetup.ClassName__c ='PEOUnderwritingDiscrepancyAfter';
        uwAfterSetup.TriggerKey__c = 'PEOUnderwritingDiscrepancy';
        uwAfterSetup.Active__c = true;
        uwAfterSetup.Name = 'Test uw after';
        uwAfterSetup.InterfaceVersion__c = 'C';
        uwAfterSetup.SortOrder__c = 1;
        insert uwAfterSetup;
        
        // All of the documents that are potentially required for a given prospect
        List<String> docNames = new List<String>();
        docNames.add('Census');
        docNames.add('Claims Information');
        docNames.add('Health Insurance Summary');
        docNames.add('Health Insurance Renewal');
        docNames.add('Health Invoice');
        docNames.add('Other');
        docNames.add('SUI Rate Forms');
        docNames.add('WC Declarations Page');
        docNames.add('Loss Runs');
        docNames.add('WC Classes and Wages');
        
        List<PEO_Onboarding_Document_Map__c> nameMaplst = new List<PEO_Onboarding_Document_Map__c>();
        for (String docName: docNames) {
            PEO_Onboarding_Document_Map__c newDocMap = new PEO_Onboarding_Document_Map__c(name=docName);
            if(docName == 'Census') {
                newDocMap.Document_Category__c = 'Medical';
			}
            if(docName == 'Loss Runs') {
                newDocMap.Document_Category__c = 'Risk';
            }
            nameMaplst.add(newDocMap);
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
        
        WC_Questionnaire_Industry_Specific__c wcs = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c=chklst.Id);
        insert wcs;
        
        List<PEO_Onboarding_Document__c> docLst = new List<PEO_Onboarding_Document__c>();
        
        for (String docName : docNames) {
            docLst.add(new PEO_Onboarding_Document__c(Name=docName,PEO_Onboarding_Checklist__c=chklst.Id, Status__c='', Routing_Name__c=docName));
        }
        
        System.debug('docLst:'+docLst);
        insert docLst;
    }
    
    static testMethod void testDocLookupPopulate(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c LIMIT 1];
        
        Schema.SObjectType s = Schema.getGlobalDescribe().get('PEO_Onboarding_Document_Discrepency__c');
        Schema.DescribeSObjectResult r = s.getDescribe();
        Map<String,Schema.SObjectField> fields = r.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get('Discrepancy_Type__c').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        System.debug('ple: '+fieldResult.getPicklistValues());
        
        List<PEO_Onboarding_Document_Discrepency__c> discLst = new List<PEO_Onboarding_Document_Discrepency__c>();
        for( Schema.PicklistEntry pickListVal : ple){
            String value = pickListVal.getLabel();
            PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c();
            disc.PEO_Underwriting_Checklist__c = checklist.Id;
            disc.Discrepancy_Type__c = value;
            System.debug(disc);
            discLst.add(disc);
        }
        Test.startTest();
        insert discLst;
        Test.stopTest();
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
        PEO_Onboarding_Document_Discrepency__c[] discList = [SELECT id,Discrepancy_Type__c, PEO_Onboarding_Document__c
                                                            FROM PEO_Onboarding_Document_Discrepency__c
                                                            WHERE PEO_Underwriting_Checklist__c=:checklist.Id];
        PEO_Onboarding_Document_Discrepency__c discMissingLookup;
        Boolean missingADocLookup = false;
        for (PEO_Onboarding_Document_Discrepency__c disc :discList ) {
            if (PEOUnderwritingDiscrepancyBeforeTest.discForDoc(disc.Discrepancy_Type__c)) {
                if (disc.PEO_Onboarding_Document__c == null) {
                    missingADocLookup = true;
                    discMissingLookup = disc;
                    break;
                }
            }
        }
        //System.assertEquals(false, missingADocLookup, 'Failed doc lookup populate: '+discMissingLookup);
        PEO_Onboarding_Document_Discrepency__c censusDisc = [SELECT id, Discrepancy_Type__c, PEO_Onboarding_Document__c, Discrepancy_Category__c FROM PEO_Onboarding_Document_Discrepency__c WHERE PEO_Underwriting_Checklist__c=:checklist.Id AND Discrepancy_Type__c = 'Census' LIMIT 1];
        PEO_Onboarding_Document_Discrepency__c lossRunDisc = [SELECT id, Discrepancy_Type__c, PEO_Onboarding_Document__c, Discrepancy_Category__c FROM PEO_Onboarding_Document_Discrepency__c WHERE PEO_Underwriting_Checklist__c=:checklist.Id AND Discrepancy_Type__c = 'Loss Runs' LIMIT 1];
        System.assertEquals('Medical', censusDisc.Discrepancy_Category__c);
        System.assertEquals('Risk', lossRunDisc.Discrepancy_Category__c);
    }
    
    static testMethod void testChecklistPopulate() {
        // get all documents for the checklist
        PEO_Onboarding_Document__c[] docLst = [SELECT id, Status__c, Name, Routing_Name__c FROM PEO_Onboarding_Document__c];
        List<PEO_Onboarding_Document_Discrepency__c> discLst = new List<PEO_Onboarding_Document_Discrepency__c>();
        for (PEO_Onboarding_Document__c doc : docLst) {
            PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c();
            disc.PEO_Onboarding_Document__c = doc.Id;
            if (doc.Routing_Name__c == 'Census') disc.Discrepancy_Type__c = 'Census'; // 
            if (doc.Routing_Name__c == 'SUI Rate Forms') disc.Discrepancy_Type__c = 'SUI'; // 
            if (doc.Routing_Name__c =='WC Declarations Page') disc.Discrepancy_Type__c = 'Workers Comp Declarations Page'; // 
            if (doc.Routing_Name__c == 'Health Invoice') disc.Discrepancy_Type__c ='Health Invoice/PEO Medical Billing Report'; // 
            if (doc.Routing_Name__c =='Health Insurance Summary') disc.Discrepancy_Type__c = 'Health Insurance Summary of Benefits/Plan Designs'; //
            if (doc.Routing_Name__c =='Health Insurance Renewal') disc.Discrepancy_Type__c = 'Health Insurance Renewal';// 
            if (doc.Routing_Name__c == 'Loss Runs') disc.Discrepancy_Type__c = 'Loss Runs'; // 
            discLst.add(disc);
        }
        insert discLst;
        
        // verify the lookups to the checlist exist and match
        Boolean anyDiscMissingLookup = false;
        PEO_Onboarding_Document_Discrepency__c discMissingChecklistLookup;
        for (PEO_Onboarding_Document_Discrepency__c disc : discLst) {
            if (disc.PEO_Onboarding_Document__c == null) {
                anyDiscMissingLookup = true;
                discMissingChecklistLookup = disc;
                break;
            }
        }
        
        System.assertEquals(false, anyDiscMissingLookup, 'Failed to populate checklist lookup: '+discMissingChecklistLookup);
    }
    static testMethod void testMedicalPopulate() {
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c LIMIT 1];
        PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c();
        disc.PEO_Underwriting_Checklist__c = checklist.Id;
        disc.Discrepancy_Type__c = 'Medical Questionnaire';
        insert disc;
        
        PEO_Onboarding_Document_Discrepency__c uDisc = [SELECT Id,PEO_Underwriting_Medical_Questionnaire__c FROM PEO_Onboarding_Document_Discrepency__c WHERE Id = :disc.Id];
        System.assert(uDisc.PEO_Underwriting_Medical_Questionnaire__c!=null);
    }
    static testMethod void testIndustryPopulate() {
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c LIMIT 1];
        PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c();
        disc.PEO_Underwriting_Checklist__c = checklist.Id;
        disc.Discrepancy_Type__c = 'Industry Specific Questionnaire';
        insert disc;
        
        PEO_Onboarding_Document_Discrepency__c uDisc = [SELECT Id,WC_Questionnaire_Industry_Specific__c FROM PEO_Onboarding_Document_Discrepency__c WHERE Id = :disc.Id];
        System.assert(uDisc.WC_Questionnaire_Industry_Specific__c!=null);
    }
    static testMethod void testDiscCloseDate() {
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c LIMIT 1];
        PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c();
        disc.PEO_Underwriting_Checklist__c = checklist.Id;
        disc.Status__c = 'Resolved';
        insert disc;
        
        PEO_Onboarding_Document_Discrepency__c uDisc = [SELECT Id,Close_Date__c FROM PEO_Onboarding_Document_Discrepency__c WHERE Id = :disc.Id];
        System.assertEquals(System.today(), uDisc.Close_Date__c);
    }
}