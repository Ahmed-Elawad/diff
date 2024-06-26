/*
 * Helper class for the Reference_HRE_CHB_Onboarding object 
 *
 * History
 * ------- 
 * 10/17/2013 Frank Lurz       created  
 * 09/15/2014 Frank Lurz       added fields for the hk-0005 replacement effort
 * 02/18/2015 Frank Lurz       changed the 'HRE/CHB HR Services Advisor' queue to 'Handbook Production Queue' 
 * 04/20/2015 Frank Lurz       remove the copying of Reference Handbook Order records from the ReferenceHRECHBStates method
 * 04/20/2015 Frank Lurz       changed profile.name == 'HR Essentials' to profile.name == 'PROFILE NAME' to force all owner assignments to the queue,
 *                             but leave the logic in place to assign to specific Users in case the BU changes their mind 
    07/06/2020  Jacob Hinds         Added without sharing per PMD
 *
 */  

public without sharing class ReferenceHRECHBHelper {

    public static void ReferenceHRECHBStates(list<Reference_HRE_CHB_Onboarding__c> InputReferenceHRE_CHBs){
            Id caseQueueID = [Select Id,(Select Queue.Id From QueueSobjects where SobjectType = 'Case' Limit 1)
                                 from Group where Name = 'Handbook Production Queue' and Type = 'Queue' Limit 1].QueueSobjects[0].Queue.Id;
            list<Reference_HRE_CHB_State__c> stateList = new list<Reference_HRE_CHB_State__c>();
            list<Reference_Handbooks_Version__c> HversionList = new list<Reference_Handbooks_Version__c>();
       /*   list<Reference_HRE_CHB_Orders__c> HOrderList = new list<Reference_HRE_CHB_Orders__c>();   */
            list<Reference_HRE_CHB_Onboarding__c> inputRefToUpdate = new list<Reference_HRE_CHB_Onboarding__c>();
            list<case> casesToUpdate = new list<case>();
            set<id> inputRefIds = new set<id>();
   
            system.debug('***FLurz*** - Start Processing');               
            
            for(Reference_HRE_CHB_Onboarding__c InputReferenceHRE_CHB : InputReferenceHRE_CHBs){
                inputRefIds.add(InputReferenceHRE_CHB.id);      
                List<Reference_HRE_CHB_Onboarding__c> refHREList = [Select Account_Lookup__c,
                                                                    Parent_Case__r.OwnerId,
                                                                    Parent_Case__r.Owner.isActive,
                                                                    Parent_Case__r.Owner.profile.Name,
                                                                    Parent_Case__r.Type,
                                                                    (Select Reference_HR_Essentials__c, 
                                                                    Employee_Count__c, 
                                                                    State__c From Reference_HR_Essentials_States__r),
                                                                    (Select Reference_HR_Essentials__c, 
                                                                    Handbook_Version_Last_Modification_Date__c, 
                                                                    Handbook_Version_Title__c,
                                                                    Word_Doc_Changes__c,
                                                                    Word_Doc_Changes_Indicator__c,
                                                                    Attention_To__c,
                                                                    Street_Address__c,
                                                                    Suite_Number__c,
                                                                    City__c,
                                                                    State_Province__c,
                                                                    Zip_Code__c,
                                                                    File_Number__c From Reference_Handbooks_Versions__r)
                                                                    From Reference_HRE_CHB_Onboarding__c 
                                                                    Where Account_Lookup__c = :InputReferenceHRE_CHB.Account_Lookup__c 
                                                                    And Id != :InputReferenceHRE_CHB.Id  
                                                                    And Current_Step__c IN ('Onboarding Complete' , 'Completed')
                                                                    Order by CreatedDate DESC 
                                                                    Limit 1];
                                                                    
            system.debug('***FLurz 1st time*** - refHREList ' + refHREList); 
             
                if(!refHREList.isEmpty()){   
                    for (Reference_HRE_CHB_State__c s : refHREList[0].Reference_HR_Essentials_States__r){
                        Reference_HRE_CHB_State__c newState = new Reference_HRE_CHB_State__c(Reference_HR_Essentials__c = InputReferenceHRE_CHB.id,
                                                                                             State__c = s.State__c,
                                                                                             Employee_Count__c = s.Employee_Count__c);      
                        stateList.add(newState);   
                    }
                    /* BEGINNING OF adding new code for copying/creating versions */
                    system.debug('***FLurz*** - refHREList ' + refHREList); 
                    for (Reference_Handbooks_Version__c v : refHREList[0].Reference_Handbooks_Versions__r){
                        Reference_Handbooks_Version__c newHVersion = new Reference_Handbooks_Version__c(Reference_HR_Essentials__c = InputReferenceHRE_CHB.id,
                                                                                        Handbook_Version_Last_Modification_Date__c = v.Handbook_Version_Last_Modification_Date__c,
                                                                                                         Handbook_Version_Title__c = v.Handbook_Version_Title__c,
                                                                                                               Word_Doc_Changes__c = v.Word_Doc_Changes__c,
                                                                                                     Word_Doc_Changes_Indicator__c = v.Word_Doc_Changes_Indicator__c,
                                                                                                                   Attention_To__c = v.Attention_To__c,
                                                                                                                 Street_Address__c = v.Street_Address__c,
                                                                                                                   Suite_Number__c = v.Suite_Number__c,
                                                                                                                           City__c = v.City__c,
                                                                                                                 State_Province__c = v.State_Province__c,
                                                                                                                       Zip_Code__c = v.Zip_Code__c,
                                                                                                                    File_Number__c = v.File_Number__c);            
                        HversionList.add(newHVersion);   
                    }

                    if(refHREList[0].parent_case__r.owner.profile.name == 'PROFILE NAME' && refHREList[0].parent_case__r.owner.isActive){
                        casesToUpdate.add(new Case(id = InputReferenceHRE_CHB.parent_case__c, ownerId = refHREList[0].parent_case__r.ownerId));
                    }
                    else{
                        casesToUpdate.add(new Case(id = InputReferenceHRE_CHB.parent_case__c, ownerId = caseQueueID));  
                    }         
                }
                else{
                   system.debug('*<>* FLurz *<>* - Second of the assign Case Owner to the caseQueueID');
                   casesToUpdate.add(new Case(id = InputReferenceHRE_CHB.parent_case__c, ownerId = caseQueueID));
                }// set Case.Owner to queue when a completed Reference_HRE_CHB_Onboarding__c record is NOT found
            }
            for(Reference_HRE_CHB_Onboarding__c InputReferenceHRE_CHB:[Select Account_Lookup__c,
                                                                        Parent_Case__c, 
                                                                        Product_Type__c,
                                                                        District__c,
                                                                        Sales_Rep__c,
                                                                        FSS__c,
                                                                        DSM__c,                                 
                                                                        First_Billing_Month_Date__c,
                                                                        Contract_Received_Date__c, 
                                                                        Set_Up_Complete_Date__c,
                                                                        Secondary_Contact_Name__c,
                                                                        Secondary_Contact_Time_Zone__c,
                                                                        Non_reviewable_Policy__c,
                                                                        Approval_Copy_to_Client_Date__c,
                                                                        All_Versions_Printed_Date__c,
                                                                        Word_Doc_Changes__c,
                                                                        Multiple_Versions__c
                                                                        From Reference_HRE_CHB_Onboarding__c 
                                                                        Where id in :inputRefIds]){ /*This must be done or the records will be 
                                                                                                     locked and prevent updating. */
                inputRefToUpDate.add(ReferenceHRECHBToUpdate(InputReferenceHRE_CHB));                                                               
            }
            if (!inputRefToUpdate.isEmpty()){
                update inputRefToUpdate;
            }
            system.debug('***FLurz*** - stateList ' + stateList);
            if (!stateList.isEmpty()){    
                insert stateList;
            }
            system.debug('***FLurz*** - HversionList ' + HversionList); 
            if (!HversionList.isEmpty()){    
                insert HversionList;
            }

            if (!casesToUpdate.isEmpty()){    
                update casesToUpdate;
            }                    
        }
        
    private static Reference_HRE_CHB_Onboarding__c ReferenceHRECHBToUpdate(Reference_HRE_CHB_Onboarding__c InputReferenceHRE_CHB){  
            List<Reference_HRE_CHB_Onboarding__c> refHREList = [Select Account_Lookup__c, 
                                                                    Product_Type__c,
                                                                    District__c,
                                                                    Sales_Rep__c,
                                                                    FSS__c,
                                                                    DSM__c,                                 
                                                                    First_Billing_Month_Date__c,
                                                                    Contract_Received_Date__c, 
                                                                    Set_Up_Complete_Date__c,
                                                                    Secondary_Contact_Name__c,
                                                                    Secondary_Contact_Time_Zone__c,
                                                                    Non_reviewable_Policy__c,
                                                                    Approval_Copy_to_Client_Date__c,
                                                                    All_Versions_Printed_Date__c,
                                                                    Word_Doc_Changes__c,
                                                                    Multiple_Versions__c
                                                                    From Reference_HRE_CHB_Onboarding__c 
                                                                    Where Account_Lookup__c = :InputReferenceHRE_CHB.Account_Lookup__c 
                                                                    And Id != :InputReferenceHRE_CHB.Id  
                                                                    And Current_Step__c IN ('Onboarding Complete' , 'Completed')
                                                                    Order by CreatedDate DESC 
                                                                    Limit 1];
                                                                    
            system.debug('***FLurz - ReferenceHRECHBToUpdate*** - refHREList ' + refHREList);  
            if(!refHREList.isEmpty()){
                InputReferenceHRE_CHB.Product_Type__c = refHREList[0].Product_Type__c;
                InputReferenceHRE_CHB.District__c = refHREList[0].District__c;
                InputReferenceHRE_CHB.Sales_Rep__c = refHREList[0].Sales_Rep__c;
                InputReferenceHRE_CHB.FSS__c = refHREList[0].FSS__c;
                InputReferenceHRE_CHB.DSM__c = refHREList[0].DSM__c;
                InputReferenceHRE_CHB.First_Billing_Month_Date__c = refHREList[0].First_Billing_Month_Date__c;
                InputReferenceHRE_CHB.Contract_Received_Date__c = refHREList[0].Contract_Received_Date__c;     
                InputReferenceHRE_CHB.Set_Up_Complete_Date__c = refHREList[0].Set_Up_Complete_Date__c;
                InputReferenceHRE_CHB.Secondary_Contact_Name__c = refHREList[0].Secondary_Contact_Name__c;
                InputReferenceHRE_CHB.Secondary_Contact_Time_Zone__c = refHREList[0].Secondary_Contact_Time_Zone__c;
                InputReferenceHRE_CHB.Non_reviewable_Policy__c = refHREList[0].Non_reviewable_Policy__c;
                InputReferenceHRE_CHB.Approval_Copy_to_Client_Date__c = refHREList[0].Approval_Copy_to_Client_Date__c;
                InputReferenceHRE_CHB.All_Versions_Printed_Date__c = refHREList[0].All_Versions_Printed_Date__c;     
                InputReferenceHRE_CHB.Word_Doc_Changes__c = refHREList[0].Word_Doc_Changes__c;
                InputReferenceHRE_CHB.Multiple_Versions__c = refHREList[0].Multiple_Versions__c;
                                                 
            }
            return InputReferenceHRE_CHB; 
    }
}// class ReferenceHRECHBHelper