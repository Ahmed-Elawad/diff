/** FARequestForm
  The purpose of the form is to submit a request to the FSM team to update Financial Advisor information within salesforce

   12/20/2022 Bindu Madhavi   Created

 */
public without sharing class FARequestFormAuraController {
    @auraEnabled

    public static Id createCase(Financial_Advisor_Request_Form__c FARF){
        try{
            //System.debug(FARF);
            String UserEmail = UserInfo.getUserEmail();
            String FAAdvisorType = FARF.Advisor_Type__c;
            String FAFirstName = FARF.FA_First_Name__c;
            String FALastName = FARF.FA_Last_Name__c;
            String FAAddress = FARF.FA_Address__c;
            String FACity = FARF.FA_City__c;
            String FAState = FARF.FA_State__c;
            String FAZipcode = FARF.FA_Zipcode__c;
            String FAEmail = FARF.FA_Email__c;
            String FAPhone = FARF.FA_Phone_Number__c;
            String CRDNumber = FARF.CRD_Number__c;
            String ParentBDName = FARF.Parent_Broker_Dealer_Firm__c;
            String BRepID = FARF.Broker_Rep_ID__c;
            String BBranchID = FARF.Broker_Branch_ID__c;
            String CompensationType = FARF.Compensation_Type__c;
            String BDFirmName = FARF.Broker_Dealer_Firm_Name__c;
            String BDCrd = FARF.Broker_Dealer_CRD__c;
            String Notes = FARF.Notes__c;
            String FADetails = FAAdvisorType + '-'+ FAFirstName + ' '+ FALastName + '\n'+ FAAddress + 
                                     '\n'+ FACity + ','+ FAState + ' '+ FAZipcode + '\n' + FAEmail + '\n'+ FAPhone +
                                 '\n CRD Number: '+ CRDNumber;
            
            List<Contact> lstContact = new List<Contact>();
            
            if(UserEmail != '' && UserEmail != Null){
                lstContact = [Select Id,firstName,LastName,Email from Contact where Email =: userEmail LIMIT 1];
            }
            Id caseRT = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service_Support_401k_S125_Case').getRecordTypeId();
            Id queueId = [select Id,Name from Group where  Type = 'Queue' AND NAME = 'HRS 4S FA Support – Case Work'].Id;
            
            Case objFACase = new Case();
            if(caseRT != null){
                objFACase.RecordTypeId = caseRT;
            }
            if(queueId != null){                
                objFACase.OwnerId = queueId;
            }
            if(!lstContact.isEmpty()){
                objFACase.Contact_Name__c = lstContact[0].Id;
                objFACase.ContactId = lstContact[0].Id;
            }
            
            objFACase.Origin = 'Email';
            objFACase.Priority = 'High';
            objFACase.Subject = FAAdvisorType +' - '+ FAFirstName +' '+ FALastName;
            
            if(FAAdvisorType == 'Financial Advisor') {
                objFACase.Description = FADetails + '\n Broker Rep ID:' + BRepID + '\n Broker Branch ID:'+ BBranchID +
                                 '\n Compensation Type: '+ CompensationType + '\n Broker Dealer Firm Name: '+ BDFirmName +
                    			 '\n Broker Dealer CRD: ' + BDCrd +'\n Parent Broker Dealer Firm: '+ ParentBDName + '\n Notes: '+ Notes;
            }
            else {
                 objFACase.Description = FADetails + '\n Parent Broker Dealer Firm:' + ParentBDName + '\n Notes: '+ Notes;
            }
                                    
            objFACase.Status = 'New';
            objFACase.Product__c = '401k';
            objFACase.Reason = 'Request/Action Needed';
            objFACase.Reassign_Category_1__c = 'Financial Advisor Firm';
            objFACase.Reassign_Category_2__c = 'Setup';
            objFACase.Disposition_1__c = 'Administrator';
            objFACase.Disposition_2__c = 'Paychex Sales-Pre';
            objFACase.HRS4SCategory1__c = 'Ops-Elite Partner Support';
            objFACase.HRS4SCategory2__c = 'Misc';
            Insert objFACase;
            
            // Insert Case Comments
            CaseComment c = new CaseComment();
            c.CommentBody = FADetails;
            
            c.ParentId = objFACase.Id;
            Insert c;
            return objFACase.Id;
        }
        catch(exception e){
            return null;
        }
        
    }
}