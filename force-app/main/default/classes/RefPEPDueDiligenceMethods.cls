/* 
	Used in Trigger for the Reference PEP Due Diligence	
	Req: https://wiki.paychex.com/display/CP/APR0116626+-+New+Object+in+SFDC+for+PEP+Due+Diligence+Team

   
	History
	-------
	04/07/2021 Manmeet Vaseer   Created
	12/06/2021 Carrie Marciano	Fixed default owner, created label allowing quick flexiblity to change without deploying code

 */
public class RefPEPDueDiligenceMethods {
    public static Boolean SKIP_TRIGGER = false;
    
    static Set<Id> ref401kIds = new Set<Id>();        

    public static void handleTrigger(Reference_PEP_Due_Diligence__c[] newRecs, Map<Id,Reference_PEP_Due_Diligence__c> oldMap) {
        System.debug('RefPEPDueDiligenceMethods.handleTrigger SKIP_TRIGGER='+SKIP_TRIGGER);
        if (SKIP_TRIGGER) {
            return;           
        }
        
        if (Trigger.isBefore) {
            handleBefore(newRecs, oldMap);
        }
        
        if (Trigger.isAfter) {
            handleAfter(newRecs, oldMap);
        }
        
    }
    
    public static void handleBefore(Reference_PEP_Due_Diligence__c[] newRecs, Map<Id,Reference_PEP_Due_Diligence__c> oldMap)	{
        //User defaultOwner = [SELECT Id FROM User WHERE alias = 'lchia' AND isActive = true LIMIT 1]; 
        
        for(Reference_PEP_Due_Diligence__c rec : newRecs)	{
           if(Trigger.isInsert) 
               //rec.OwnerId = defaultOwner.Id;
               rec.OwnerId = label.RefPEPDueDiligence_Owner;
            ref401kIds.add(rec.Reference_401k_S125__c); // used in handleAfter in the query
            
            /*
             * Populate Submission_Docs_Received_in_Good_Order__c date only when all other
             * dates are populated on Reference_PEP_Due_Diligence__c.
             */
            if(rec.Submission_Docs_Received_in_Good_Order__c == null)	{
                if(rec.Adoption_Agreement__c != null && rec.Summary_Plan_Description__c != null && 
                   rec.Basic_Plan_Document__c != null && rec.Census__c != null &&
                   rec.Participant_Summary__c != null && rec.Authorization_Letter__c != null) {
                       rec.Submission_Docs_Received_in_Good_Order__c = System.today();
                   }
            }
            
            if(rec.Risk_Assess_Docs_Received_in_Good_Order__c == null)	{
                if(rec.YTD_Activity_Current_Year__c != null && rec.YTD_Activity_Prior_Full_Year__c != null &&
                   rec.IRS_Determ_Opinion_Or_Advisory_Letter__c != null && rec.YTD_Activity_Current_Year__c != null &&
                   rec.ADP_ACP_Test__c != null && rec.Top_Heavy_Test_Determination_Year__c != null &&
                   rec.Top_Heavy_Test_Prior_Year__c != null && rec.Loan_Information__c != null)	{
                   		rec.Risk_Assess_Docs_Received_in_Good_Order__c = System.today();
                }
            }
        }
    }
    
    public static void handleAfter(Reference_PEP_Due_Diligence__c[] newRecs, Map<Id,Reference_PEP_Due_Diligence__c> oldMap)	{
        Map<Id, Reference_401k_S125__c> ref401kMap = new Map<Id, Reference_401k_S125__c>([SELECT Id, Name, Anti_Cutback_Review_Complete__c, Risk_Assessment_Complete__c, Prior_RK_Contacted_for_PEP_Risk_Assess__c FROM Reference_401k_S125__c WHERE Id IN :ref401kIds]);
        
        List<Reference_401k_S125__c> ref401kUpdates = new List<Reference_401k_S125__c>();

        for(Reference_PEP_Due_Diligence__c rec : newRecs)	{
            Boolean ref401AlreadyAdded = false;
            
            Reference_401k_S125__c ref401k = ref401kMap.get(rec.Reference_401k_S125__c);
             
            if(ref401k != null)	{
                // Set Reference_401k_S125__c.Anti_Cutback_Review_Complete__c only if the value of Reference_PEP_Due_Diligence__c.Anti_Cutback_Result__c is Pass.
                if(rec.Anti_Cutback_Result__c == 'Pass')	{
                    ref401k.Anti_Cutback_Review_Complete__c = rec.Anti_Cutback_Review_Complete__c;
                    ref401kUpdates.add(ref401k);
                    ref401AlreadyAdded = true;
                }
                
                // Set Reference_401k_S125__c.Risk_Assessment_Complete__c only if the value of Reference_PEP_Due_Diligence__c.Risk_Assessment_Result__c is Pass.
                if(rec.Risk_Assessment_Result__c == 'Pass')	{
                    ref401k.Risk_Assessment_Complete__c = rec.Risk_Assessment_Complete__c;                
                    if(!ref401AlreadyAdded) ref401kUpdates.add(ref401k);
                    ref401AlreadyAdded = true;
                }
                
                // Set Reference_401k_S125__c.Prior_RK_Contacted_for_PEP_Risk_Assess__c only if the value of Reference_PEP_Due_Diligence__c.X1st_Communication_Sent_to_Prior_RK__c is not null.
                if(rec.X1st_Communication_Sent_to_Prior_RK__c != null)	{
                    ref401k.Prior_RK_Contacted_for_PEP_Risk_Assess__c = rec.X1st_Communication_Sent_to_Prior_RK__c;                
                    if(!ref401AlreadyAdded) ref401kUpdates.add(ref401k);
                    ref401AlreadyAdded = true;
                }
            }
            else {
                System.debug('Warning: No Ref401kS125 record found for PEP Due Diligence record: ' + rec.Id);
            }
        }        
        
        if(!ref401kUpdates.isEmpty()) {
            update ref401kUpdates;
        }
    }    
    
    public static void createNewPEPRecs(List<Reference_401k_S125__c> refRecs)	{
        Schema.RecordTypeInfo refOnb401kConvrt = RecordTypeHelper.getRecordType('Service Onboarding 401k Conversions', 'Reference_401k_S125__c');
		List<Reference_PEP_Due_Diligence__c> newPEPRecs = new List<Reference_PEP_Due_Diligence__c>();
        
        for(Reference_401k_S125__c refRec : refRecs)	{
            if(refRec.recordTypeId == refOnb401kConvrt.getRecordTypeId()) {
        		newPEPRecs.add(new Reference_PEP_Due_Diligence__c(Reference_401k_S125__c = refRec.Id));
            }
        }
        
        if(!newPEPRecs.isEmpty())	{
            insert newPEPRecs;
        }
    }
}