/* 
	Unit tests for Reference PEP Due Diligence.
	Req: https://wiki.paychex.com/display/CP/APR0116626+-+New+Object+in+SFDC+for+PEP+Due+Diligence+Team

   
	History
	-------
	04/09/2021 Manmeet Vaseer   Created

 */
@isTest
public class RefPEPDueDiligenceMethodsTest {
    
    /*
     * Populate Submission_Docs_Received_in_Good_Order__c date only when all other
     * dates are populated on Reference_PEP_Due_Diligence__c.
     * 
     * Uses RefPEPDueDiligenceTrigger.
     */
    static testMethod void testSubmissionDocsReceivedInGoodOrderPopulated()
    {
        Reference_PEP_Due_Diligence__c newPepRec = new Reference_PEP_Due_Diligence__c(Adoption_Agreement__c=System.today(),
					Summary_Plan_Description__c=System.today(), Basic_Plan_Document__c=System.today(), Census__c=System.today(),
                    Participant_Summary__c=System.today(), Authorization_Letter__c=System.today());
        insert newPepRec;
        
        Map<Id, Reference_PEP_Due_Diligence__c> refPepMap = new Map<Id, Reference_PEP_Due_Diligence__c>([SELECT Id, Submission_Docs_Received_in_Good_Order__c FROM Reference_PEP_Due_Diligence__c]);
        newPepRec = refPepMap.get(newPepRec.Id);
        
        System.assertNotEquals(null, newPepRec, 'PEP Due Diligence record should not be null.');
        System.assertNotEquals(null, newPepRec.Submission_Docs_Received_in_Good_Order__c, 'Submission_Docs_Received_in_Good_Order__c should not be null.');
    }

    /*
     * Do not populate Submission_Docs_Received_in_Good_Order__c date if any/all of the
     * dates are not populated on Reference_PEP_Due_Diligence__c.
     * 
     * Uses RefPEPDueDiligenceTrigger.
     */
    static testMethod void testSubmissionDocsReceivedInGoodOrderNotPopulated()
    {
        Reference_PEP_Due_Diligence__c newPepRec = new Reference_PEP_Due_Diligence__c(Adoption_Agreement__c=System.today(),
					Summary_Plan_Description__c=System.today(), Basic_Plan_Document__c=System.today(), Census__c=null,
                    Participant_Summary__c=System.today(), Authorization_Letter__c=System.today());
        insert newPepRec;
        
        Map<Id, Reference_PEP_Due_Diligence__c> refPepMap = new Map<Id, Reference_PEP_Due_Diligence__c>([SELECT Id, Submission_Docs_Received_in_Good_Order__c FROM Reference_PEP_Due_Diligence__c]);
        newPepRec = refPepMap.get(newPepRec.Id);
        
        System.assertNotEquals(null, newPepRec, 'PEP Due Diligence record should not be null.');
        System.assertEquals(null, newPepRec.Submission_Docs_Received_in_Good_Order__c, 'Submission_Docs_Received_in_Good_Order__c should be null.');
    }
    
   /*
     * Populate Reference_401k_S125__c Anti_Cutback_Review_Complete__c and Risk_Assessment_Complete__c date only when 
     * Anti_Cutback_Result__c/Risk_Assessment_Result__c value is 'Pass' on Reference_PEP_Due_Diligence__c.
     * 
     * The RefPEPDueDiligenceTrigger trigger should automatically set Reference_401k_S125__c Anti_Cutback_Review_Complete__c and Risk_Assessment_Complete__c dates.
     */
    static testMethod void testAntiCutbackRiskAssessmentPopulated()
    {
        Reference_401k_S125__c newRef401kS125 = new Reference_401k_S125__c();
        insert newRef401kS125;

        Reference_PEP_Due_Diligence__c newPepRec = new Reference_PEP_Due_Diligence__c(Anti_Cutback_Review_Complete__c=System.today(),
					Risk_Assessment_Complete__c=System.today(), Anti_Cutback_Result__c='Pass', Risk_Assessment_Result__c='Pass',
                    Reference_401k_S125__c=newRef401kS125.Id, X1st_Communication_Sent_to_Prior_RK__c=System.today());
        insert newPepRec;
        
        List<Reference_PEP_Due_Diligence__c> newPepRecs = new List<Reference_PEP_Due_Diligence__c>();
        newPepRecs.add(newPepRec);
        
      //  RefPEPDueDiligenceMethods.handleBefore(newPepRecs, null);
      //  RefPEPDueDiligenceMethods.handleAfter(newPepRecs, null);
        
        Map<Id, Reference_401k_S125__c> ref401kMap = new Map<Id, Reference_401k_S125__c>([SELECT Id, Name, Anti_Cutback_Review_Complete__c, Risk_Assessment_Complete__c, Prior_RK_Contacted_for_PEP_Risk_Assess__c FROM Reference_401k_S125__c]);
        newRef401kS125 = ref401kMap.get(newRef401kS125.Id);
        System.assertNotEquals(null, newRef401kS125.Anti_Cutback_Review_Complete__c, 'Ref401kS125 Anti_Cutback_Review_Complete__c should not be null.');
        System.assertNotEquals(null, newRef401kS125.Risk_Assessment_Complete__c, 'Ref401kS125 Risk_Assessment_Complete__c should not be null.');
        System.assertNotEquals(null, newRef401kS125.Prior_RK_Contacted_for_PEP_Risk_Assess__c, 'Ref401kS125 Prior_RK_Contacted_for_PEP_Risk_Assess__c should not be null.');
    }

   /*
     * Do not populate Reference_401k_S125__c Anti_Cutback_Review_Complete__c and Risk_Assessment_Complete__c date only when 
     * Anti_Cutback_Result__c/Risk_Assessment_Result__c value is not 'Pass' on Reference_PEP_Due_Diligence__c.
     * 
     * The RefPEPDueDiligenceTrigger trigger should automatically set Reference_401k_S125__c Anti_Cutback_Review_Complete__c and Risk_Assessment_Complete__c dates.
     */
    static testMethod void testAntiCutbackRiskAssessmentNotPopulated()
    {
        Reference_401k_S125__c newRef401kS125 = new Reference_401k_S125__c();
        insert newRef401kS125;

        Reference_PEP_Due_Diligence__c newPepRec = new Reference_PEP_Due_Diligence__c(Anti_Cutback_Review_Complete__c=System.today(),
					Risk_Assessment_Complete__c=System.today(), Anti_Cutback_Result__c=null, Risk_Assessment_Result__c=null,
                    Reference_401k_S125__c=newRef401kS125.Id, X1st_Communication_Sent_to_Prior_RK__c=null);
        insert newPepRec;
        
        List<Reference_PEP_Due_Diligence__c> newPepRecs = new List<Reference_PEP_Due_Diligence__c>();
        newPepRecs.add(newPepRec);
        
       // RefPEPDueDiligenceMethods.handleBefore(newPepRecs, null);
       // RefPEPDueDiligenceMethods.handleAfter(newPepRecs, null);
        
        Map<Id, Reference_401k_S125__c> ref401kMap = new Map<Id, Reference_401k_S125__c>([SELECT Id, Name, Anti_Cutback_Review_Complete__c, Risk_Assessment_Complete__c, Prior_RK_Contacted_for_PEP_Risk_Assess__c FROM Reference_401k_S125__c]);
        newRef401kS125 = ref401kMap.get(newRef401kS125.Id);
        System.assertEquals(null, newRef401kS125.Anti_Cutback_Review_Complete__c, 'Ref401kS125 Anti_Cutback_Review_Complete__c should be null.');
        System.assertEquals(null, newRef401kS125.Risk_Assessment_Complete__c, 'Ref401kS125 Risk_Assessment_Complete__c should be null.');
        System.assertEquals(null, newRef401kS125.Prior_RK_Contacted_for_PEP_Risk_Assess__c, 'Ref401kS125 Prior_RK_Contacted_for_PEP_Risk_Assess__c should be null.');
    }
    
    /*
     * Test a valid scenario where Ref 401k/S125 object record is 'Service Onboarding 401k Conversions' record type.
     * And, PEP field of Ref 401k/S125 object record is populated with some value.
     * 
     * The Reference401After trigger should automatically create a new PEP Due Diligence object record and attach it to the Ref 401k/S125 object record.
     */
    static testMethod void testCreateNewForConversionsRecType() {
        Schema.RecordTypeInfo refOnb401kConvrt = RecordTypeHelper.getRecordType('Service Onboarding 401k Conversions', 'Reference_401k_S125__c');
        Schema.RecordTypeInfo refOnb401kLMNCrt = RecordTypeHelper.getRecordType('Service Onboarding 401k Large Market New Case', 'Reference_401k_S125__c');
       
        List<Reference_401k_S125__c> refList = new List<Reference_401k_S125__c>();
        
        Reference_401k_S125__c newRef401kS125 = new Reference_401k_S125__c(RecordTypeId=refOnb401kConvrt.getRecordTypeId(), PEP__c='3(38) Mesirow');
        refList.add(newRef401kS125);
        
        newRef401kS125 = new Reference_401k_S125__c(RecordTypeId=refOnb401kLMNCrt.getRecordTypeId(), PEP__c='3(38) Mesirow');
        refList.add(newRef401kS125);
        
        insert refList;
        RefPEPDueDiligenceMethods.createNewPEPRecs(refList);
        
        List<Reference_PEP_Due_Diligence__c> pepRecCreated = [SELECT Reference_401k_S125__c FROM Reference_PEP_Due_Diligence__c];
        System.assertEquals(1, pepRecCreated.size(), 'Exactly one PEP Due Diligence object record should have been created');
        System.assertEquals(refList[0].Id, pepRecCreated[0].Reference_401k_S125__c, 'New PEP Due Diligence object record is not attached to correct Ref 401k/S125 object record.');        
    }
    
    
}