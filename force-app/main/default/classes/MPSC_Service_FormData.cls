public class MPSC_Service_FormData {

    @AuraEnabled
    public static String getMetadata(Id recordID) {

            
        
            Case c = [SELECT Id, Type, Status, CaseNumber, Account.Bis_ID__c, Account.AccountNumber, Account.Name, RecordType.Name, Sub_Type__c FROM Case WHERE Id = :recordID AND RecordType.Name = 'Multi-Product Service Case'];
            
            if (c.Status == 'New' || (c.Status == 'Approved/Ready' && c.Type == 'Loss')) {
                List<Mid_Market_Service_Submission_Form__mdt> mdtRecList = [
                    SELECT Description__c, Icon_Name__c, URL__c 
                    FROM Mid_Market_Service_Submission_Form__mdt 
                    WHERE Type__c = :c.Type AND Subtype__c = :c.Sub_Type__c
                ];
                
                if (!mdtRecList.isEmpty()) {
                    Mid_Market_Service_Submission_Form__mdt mdtRec = mdtRecList[0]; // Assuming one record
                    String caseNumber=c.CaseNumber;
                    String BISID=String.valueOf(c.Account.Bis_ID__c);
                    
                    if(caseNumber==null){
                        caseNumber='';
                    }
                    if(BISID==null){
                        BISID='';
                    }
                    if (mdtRec.URL__c != null && mdtRec.URL__c != '') {
                        // Safely extract account information for PayxOfficeId and PayxClientId
                        
                        String accountNumber = c.Account.AccountNumber;
                        String PayxOfficeId = '';
                        String PayxClientId = '';
    
                        if(String.isNotBlank(accountNumber)&&accountNumber.contains('-')){
                             PayxOfficeId = accountNumber.substring(0, accountNumber.indexOf('-'));
                             PayxClientId = accountNumber.substring(accountNumber.indexOf('-') + 1);
                        }    
                            // Construct the detail URL
                            String detailUrl = mdtRec.URL__c 
                                + '?caseId=' + c.Id 
                                + '&caseNumber=' + caseNumber 
                                + '&BISID=' + BISID 
                                + '&PayxOfficeId=' + PayxOfficeId 
                                + '&PayxClientId=' + PayxClientId 
                                + '&PayxClientName=' + EncodingUtil.urlEncode(c.Account.Name, 'UTF-8') // Encode the client name
                                + '&newSubmission=1';
    
                            // Encode the full URL
                            return detailUrl;
                    }
                }
            } else {
                List<Reference_MPSC_Service_Submission__c> referenceRec = [
                    SELECT Id 
                    FROM Reference_MPSC_Service_Submission__c 
                    WHERE Case__c = :c.Id
                ];
    
                if (!referenceRec.isEmpty()) {
                    return referenceRec[0].Id; // Return the reference record ID if it exists
                }
            }
		
        return null; // If no valid data is found
    }
}