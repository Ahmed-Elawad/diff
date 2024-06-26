/* 
 * History
 * -------
 * 01/11/2023 Pratik Das       Created
 * 12/27/2023 Shilpa G	       APR0149726: Updated method validateHNBFEDICase to allow case creation at 'Back From New Case' step and moved error messages to custom labels.
 * 
*/

public with sharing class EDIController {
    public EDIController() {
        system.debug('MA');
    }

    //getting the data from the record for dropdown
    @AuraEnabled(cacheable=true)
    public static List<Sobject> fetchDropdownData(String recordId,String objApiName){
        List<Sobject> dropDownData=new List<Sobject>();
        system.debug('MA1'+recordId);
        system.debug('MA2'+objApiName);
        try {
            if(objApiName=='Reference_HNBF__c'){
                dropDownData=fetchCaseCategory();
            }
            else{
                //Write Logic for BenAdmin (future purpose) 
            }
            
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());
        }

        return dropDownData;
    }//End fetchDropdownData

    //Fetching the data from custom setting 'Case Category Picklist Mapping' 
    @AuraEnabled(cacheable=true)
    public static List<Case_category__c>  fetchCaseCategory(){
        List<Case_category__c> caseCategory = new List<Case_category__c>();
        caseCategory=Case_category__c.getall().values();
        return caseCategory;
    }

    //Checking the validation logic for EDI case
    @AuraEnabled
    public static String validateRecords(String recordId,String objApiName,String selectedOption){
        String validationMessage='';
        try {
            if(objApiName=='Reference_HNBF__c'){
                validationMessage=validateHNBFEDICase(recordId,selectedOption);
            }
            else{
                //Write Logic for BenAdmin (future purpose)
            }
            
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());
        }
        return validationMessage;
    }//End


    //Validation For HNBF
    @AuraEnabled
    public static String validateHNBFEDICase(String recordId,String selectedOption){
        String validateHNBFMessage='';
        try {
            // List<Reference_HNBF__c> lstHNBF=new List<Reference_HNBF__c>();
            // lstHNBF=[Select id,Policy_Type_Total_of_EEs__c,Flock__c,Current_Step__c,Prospect_Client_Name__c,Client_Contact__c from Reference_HNBF__c where Id=:recordId limit 1];
            List<Reference_HNBF__c> lstHNBF=queryReferenceHNBF(recordId);
            if(lstHNBF!=null && !lstHNBF.isEmpty()){
                //Carrier Connection- EDI
                if(selectedOption=='Carrier Connection- EDI' && (lstHNBF[0].Policy_Type_Total_of_EEs__c<100 || lstHNBF[0].Flock__c!=true)){
                    validateHNBFMessage='Client must have 100+ apps to be eligible for EDI evaluation and the Flock indicator has be checked to create EDI case';
                }
                //ENI//Cobra
                else if((selectedOption=='ENI' || selectedOption=='Cobra') && (lstHNBF[0].Current_Step__c!=Label.AllowEDICaseCreation || lstHNBF[0].Flock__c!=true)){ 
                    validateHNBFMessage=Label.EDICaseCreateError_ENI_Cobra;    
                }
                //Telehealth
                else if(selectedOption=='Telehealth' && lstHNBF[0].Current_Step__c!=Label.AllowEDICaseCreation){
                    validateHNBFMessage=Label.EDICaseCreateError_Telehealth;
                }
                else{
                    //Write Case creation logic
                    //validateHNBFMessage='Case Creation is in Progress';
                    validateHNBFMessage=createCase(lstHNBF[0].Prospect_Client_Name__c,lstHNBF[0].Client_Contact__c,selectedOption,lstHNBF[0]);
                }
                    
            }//End of outer if 
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return validateHNBFMessage;
    }//End


    //Case creation for HNBF
    public static String createCase(String prospectClientName,Id contactId,String selectedOption,Reference_HNBF__c refHNBF){
        String caseNumber='';
        //getting the account Id from the prospectClientName
        //List<Account> lstAccount=[Select id from  Account where Name=:prospectClientName limit 1];
        List<Account> lstAccount=queryAccount(prospectClientName);
        if(lstAccount!=null && !lstAccount.isEmpty()){
            
            //Assignment Rule activation
            //Fetching the assignment rules on case [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
            AssignmentRule AR = new AssignmentRule();
            AR=fetchAssignmentRuleForCase();
            //Creating the DMLOptions for "Assign using active assignment rules" checkbox
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;

            //Creating case
            Case newCase=new Case();
            newCase.AccountId=lstAccount[0].id;
            newCase.Origin='Internal Request';
            newCase.Originator_Type__c='Internal';
            //newCase.Team__c='EDI'; //BeneTrac_Case_Sponsor_required	BeneTrac Sponsor ID	Sponsor is Required
            newCase.BeneTrac_Category_1__c='Flock Client Setup';
            //newCase.Subject='Sample Flock Client-EDI Setup Request';
            newCase.Subject='EDI Setup Requested - '+selectedOption;
            //newCase.Description='List All Carriers here';
            //newCase.RecordTypeId='0128I000000L44J';//Recordtype: EDI
            //newCase.RecordTypeId='0128I000000L44Y';//Recordtype: EDI Record Type
            newCase.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('EDI_Record_Type').getRecordTypeId();
            newCase.Category__c=selectedOption;
            newCase.ContactId=contactId;
            newCase.setOptions(dmlOpts);
            insert newCase;
            system.debug('Inserted Case Id = '+newCase.Id);
            //List<Case> lstCase=[Select CaseNumber from  Case where Id=:newCase.Id limit 1];
            List<Case> lstCase=queryCase(newCase.Id);
            String referenceEDI=createReferenceEDI(newCase.Id,refHNBF);
            caseNumber='Case Created successfully.Case Number is: '+lstCase[0].CaseNumber+referenceEDI;
        }
        return caseNumber;
    }//End

    //Reference EDI creation for HNBF
    public static String createReferenceEDI(Id caseId,Reference_HNBF__c refHNBF){

        String referenceEDI='';
        //creating reference EDI data 
        Reference_EDI__c refEDI=new Reference_EDI__c();
        // if(refHNBF.Owner!=null){
        //     refEDI.Owner=refHNBF.Owner;
        // }
        if(refHNBF.IC_Rep_Assigned__c!=null){
            refEDI.IC_Rep_Assigned__c=refHNBF.IC_Rep_Assigned__c;
        }
        if(refHNBF.IC_Supervisor__c!=null){
            refEDI.IC_Supervisor__c=refHNBF.IC_Supervisor__c;
        }
        if(refHNBF.Flock__c!=null){
            refEDI.Flock__c=refHNBF.Flock__c;
        }
        if(refHNBF.Region__c!=null){
            refEDI.Region__c=refHNBF.Region__c;
        }
        if(refHNBF.Prospect_Client_Name__c!=null){
            refEDI.Prospect_Client_Name__c=refHNBF.Prospect_Client_Name__c;
        }
        if(refHNBF.BIS_ID__c!=null){
            refEDI.BIS_ID__c=refHNBF.BIS_ID__c;
        }
        if(refHNBF.Branch_Client_Number__c!=null){
            refEDI.Branch_Client_Number__c=refHNBF.Branch_Client_Number__c;
        }
        if(refHNBF.Parent_ID__c!=null){
            refEDI.Parent_ID__c=refHNBF.Parent_ID__c;
        }
        if(refHNBF.Payroll_Platform__c!=null){
            refEDI.Payroll_Platform__c=refHNBF.Payroll_Platform__c;
        }
        if(refHNBF.Name!=null){
            //refEDI.Reference_HNBF__c=refHNBF.Name;
            refEDI.Reference_HNBF__c=refHNBF.id;
        }
        if(refHNBF.HNBF_Opportunity__c!=null){
            refEDI.HNBF_Opportunity__c=refHNBF.HNBF_Opportunity__c;
        }
        if(refHNBF.Current_Step_Details__c!=null){
            refEDI.Current_Step_Details__c=refHNBF.Current_Step_Details__c;
        }
        if(refHNBF.Cancel_Reason__c!=null){
            refEDI.Cancel_Reason__c=refHNBF.Cancel_Reason__c;
        }
        // if(refHNBF.Case_Age_Excluding_Weekends__c!=null){
        //     refEDI.Case_Age_Excluding_Weekends__c=refHNBF.Case_Age_Excluding_Weekends__c;
        // }
        if(caseId!=null){
            refEDI.Case_Number__c=caseId;
        }

        //Added extra fields--Start
        if(refHNBF.Account_Manager__c!=null){
            refEDI.Account_Manager__c=refHNBF.Account_Manager__c;
        }
        if(refHNBF.Client_Size__c!=null){
            refEDI.Client_Size__c=refHNBF.Client_Size__c;    
        }
        if(refHNBF.Open_Enrollment_OE_Start_Date__c!=null){
            refEDI.Open_Enrollment_OE_Start_Date__c=refHNBF.Open_Enrollment_OE_Start_Date__c; 
        }
        if(refHNBF.Open_Enrollment_OE_End_Date__c!=null){
            refEDI.Open_Enrollment_OE_End_Date__c=refHNBF.Open_Enrollment_OE_End_Date__c; 
        }
        refEDI.EDI_Current_Step__c='New';
        //Added extra fields--End
        try{
            insert refEDI;
            //referenceEDI=' EDI Number is: '+refEDI.Id;
            List<Reference_EDI__c> lstEDI=queryReferenceEDI(refEDI.Id);
            referenceEDI=' EDI Number is: '+lstEDI[0].Name;
            updateReferenceHNBFPolicyType(refEDI.Id,refHNBF,lstEDI[0].Name);

        }
        
        catch(Exception ex){

        }

        return referenceEDI;


    }//End


    //Reference HNBF Policy Type update with the EDI id
    public static void updateReferenceHNBFPolicyType(Id referenceEDIId,Reference_HNBF__c refHNBF,String referenceEDIName){
        List<Reference_HNBF_Policy_Type__c> lstPolicyType=new List<Reference_HNBF_Policy_Type__c>();
        for(Reference_HNBF_Policy_Type__c policyType:refHNBF.Reference_HNBF_Apps__r){
            system.debug('MA'+policyType.Name);
            policyType.Reference_EDI__c=referenceEDIId;
            if(policyType.Reference_EDIs__c!=null){
                policyType.Reference_EDIs__c=policyType.Reference_EDIs__c+','+referenceEDIName;
            }
            else{
                policyType.Reference_EDIs__c=referenceEDIName;
            }
            
            lstPolicyType.add(policyType);
        }

        if(!lstPolicyType.isEmpty()){
            try{
                update lstPolicyType;
            }
            catch(Exception ex){

            }
        }

    }


    //Query Reference_HNBF__c
    public static List<Reference_HNBF__c>  queryReferenceHNBF(String recordId){
        //return [Select id,Policy_Type_Total_of_EEs__c,Flock__c,Current_Step__c,Prospect_Client_Name__c,Client_Contact__c from Reference_HNBF__c where Id=:recordId limit 1];
        //return [Select id,Policy_Type_Total_of_EEs__c,Flock__c,Current_Step__c,Prospect_Client_Name__c,Client_Contact__c,IC_Rep_Assigned__c,IC_Supervisor__c,Region__c,BIS_ID__c,Branch_Client_Number__c,Parent_ID__c,Payroll_Platform__c,Name,HNBF_Opportunity__c,Current_Step_Details__c,Cancel_Reason__c,Case_Age_Excluding_Weekends__c from Reference_HNBF__c where Id=:recordId limit 1];
        return [Select id,Policy_Type_Total_of_EEs__c,Flock__c,Current_Step__c,Prospect_Client_Name__c,Client_Contact__c,IC_Rep_Assigned__c,IC_Supervisor__c,Region__c,BIS_ID__c,Branch_Client_Number__c,Parent_ID__c,Payroll_Platform__c,Name,HNBF_Opportunity__c,Current_Step_Details__c,Cancel_Reason__c,Case_Age_Excluding_Weekends__c,Account_Manager__c,Client_Size__c,Open_Enrollment_OE_Start_Date__c,Open_Enrollment_OE_End_Date__c,(Select id,Reference_EDI__c,Name,Reference_EDIs__c from Reference_HNBF_Apps__r) from Reference_HNBF__c where Id=:recordId limit 1];
    }//End
    //Query Account
    public static List<Account>  queryAccount(String prospectClientName){
        return [Select id from  Account where Name=:prospectClientName limit 1];
    }//End

    //Query Case
    public static List<Case>  queryCase(Id caseId){
        return [Select CaseNumber from  Case where Id=:caseId limit 1];
    }//End

    //Assignment Rule activation
    public static AssignmentRule fetchAssignmentRuleForCase(){
        return [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
    }

    //Query EDI
    public static List<Reference_EDI__c> queryReferenceEDI(Id ediId){
        return [select Name from Reference_EDI__c where Id=:ediId limit 1];
    }



}