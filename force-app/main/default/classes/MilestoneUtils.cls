/*
* Class to close case milestones automatically
* This will run from an Before Update Trigger
* Contains the logic for MPSC implementation where the combination of status and recordType will determine when to close the case milestone
* Test Class:  MilestoneUtilsTest
*
* History
* -------
* 04/30/2024 Omar Hernandez     created 
*/

public class MilestoneUtils {
     //Milestone Names
    static final String FORM_SUBMISSION_TIME = 'Form Submission Time';
    static final String RESOLUTION_TIME = 'Resolution Time';
    static final String TIME_FOR_APPROVAL = 'Time for Approval';

    public static void completeMilestone(List<Id> caseIds, String milestoneName, DateTime complDate) {  
        System.debug('OHM - completeMilestone');
        List<CaseMilestone> cmsToUpdate = [SELECT Id, completionDate FROM CaseMilestone cm 
                                            WHERE caseId in :caseIds AND cm.MilestoneType.Name=:milestoneName AND completionDate = null];
        System.debug('OHM 4 - cmsToUpdate: '+ JSON.serializePretty(cmsToUpdate));
        if (cmsToUpdate.isEmpty() == false){
            for (CaseMilestone cm : cmsToUpdate){
                cm.completionDate = complDate;
            }
        update cmsToUpdate;
        }
    }
    //Main Logic to identify the cases to update
    public static void completeMPSCMilestones(List<Case> casesList){
        
        //Filter the cases with specific recortype names 
        List<id> toUpdateSubmissionList = new List<id>();
        List<id> toUpdateResolutionList = new List<id>();
        List<id> toUpdateApprovalList = new List<id>();

        //Get Record type Ids
        Id recordTypeIdMulti =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Multi_Product_Service_Case').getRecordTypeId();
        Id recordTypeIdTAA =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service_Support_TAA_Case').getRecordTypeId();
        Id recordTypeIdSTM =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service_Support_STM_Case').getRecordTypeId();
        Id recordTypeIdPAC =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service_Support_PAC_Case').getRecordTypeId();

        System.debug('OHM - completeMPSCMilestones');
        for(Case c : casesList) {
            // Cases for Submission
            System.debug('OHM - 1 - Inside For');
            System.debug('OHM - 1 - Record type Developer Name: ' + c.RecordType.DeveloperName);
            System.debug('OHM - 1 - Record type Id: ' + c.RecordTypeId);
            System.debug('OHM - 1 - Status: ' + c.Status);
            System.debug('OHM - 1 - Type: ' + c.Type);
            System.debug('OHM - 1 - Sub Type: ' + c.Sub_Type__c);
            if ((c.RecordTypeId == recordTypeIdMulti) && (c.Status == 'Submitted') &&
                    (
                        (c.Type == 'Amended Returns' && c.Sub_Type__c == 'Late Original') ||
                        (c.Type == 'Amended Returns' && c.Sub_Type__c == 'PQA')  ||
                        (c.Type == 'BCIS' && c.Sub_Type__c == 'Converter')  ||
                        (c.Type == 'BCIS' && c.Sub_Type__c == 'Custom Reporting')  ||
                        (c.Type == 'BCIS' && c.Sub_Type__c == 'Integration')  ||
                        c.Type == 'Loss' || c.Type == 'MPSC Client Training' 
                        //|| c.Type == 'Taxpay Adjustments'
                    )
            ){
                 // Add the case to the list to be updated
                 System.debug('OHM - 2 - Inside Submission');
                 toUpdateSubmissionList.add(c.Id);
             } 
            // Cases for Resolution
            if(((c.Status == 'Closed'||c.Status == 'Closed-Rejected'||c.Status == 'Cancelled') &&
                    ((c.RecordTypeId == recordTypeIdMulti) && 
                        (
                            (c.Type == 'Amended Returns' && c.Sub_Type__c == 'Escalation') ||
                            (c.Type == 'Amended Returns' && c.Sub_Type__c == 'Late Original') ||
                            (c.Type == 'Amended Returns' && c.Sub_Type__c == 'PQA')  ||
                            (c.Type == 'BCIS' && c.Sub_Type__c == 'Converter')  ||
                            (c.Type == 'BCIS' && c.Sub_Type__c == 'Custom Reporting')  ||
                            (c.Type == 'BCIS' && c.Sub_Type__c == 'Integration')  ||
                            c.Type == 'Service Help' 
                            //|| c.Type == 'Taxpay Adjustments' 
                        )
                    ) 
                       
                ) ||
                ((c.RecordTypeId == recordTypeIdTAA || c.RecordTypeId == recordTypeIdSTM) && (c.RecordTypeId == recordTypeIdPAC ) &&
                        (c.Status == 'Closed'||c.Status == 'Order Denied'||c.Status == 'Solved'))||
                ((c.RecordTypeId == recordTypeIdPAC )&& c.Status == 'Complete' )
            )
            {
                System.debug('OHM - 3 - Inside Resolution');
                toUpdateResolutionList.add(c.Id);
            }
            // Cases for Approval
            if((c.RecordTypeId == recordTypeIdMulti) &&
                    (c.Type == 'Loss' && (c.Status == 'Approved/Ready'||c.Status == 'Denied'))
                   // ||(c.Type == 'Taxpay Adjustments' && (c.Status == 'In Progress'||c.Status == 'Closed'||c.Status == 'Closed-Rejected'||c.Status == 'Cancelled')) 
            ) {
                System.debug('OHM - 4 - Inside Approval');
                toUpdateApprovalList.add(c.Id);
            }

        }

        //Close Case Milestones
        DateTime completionDate = System.now(); 
        if (!toUpdateSubmissionList.isEmpty()){
            completeMilestone(toUpdateSubmissionList, FORM_SUBMISSION_TIME, completionDate);
        }
        if (!toUpdateResolutionList.isEmpty()){
            completeMilestone(toUpdateResolutionList, RESOLUTION_TIME, completionDate);
        }
        if (!toUpdateApprovalList.isEmpty()){
            completeMilestone(toUpdateApprovalList, TIME_FOR_APPROVAL, completionDate);
        }

    }
}