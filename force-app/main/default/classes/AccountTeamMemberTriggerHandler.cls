/* Granting delete access to the existing Team Member with same role
 
03/17/2022 Susmitha Somavarapu     Created   
05/15/2023 Pratik Das              APR0147362: Agency - Add Flock AM to Prospect Client Page:Methods involved:updateFlockAccountManager,updateReferenceHNBF,updateReferenceBeneTrac,queryReferenceHNBF,queryReferenceBeneTrac 
06/02/2023 Dan Carmen              Update quote to reduce number of queries


*/

public without sharing class AccountTeamMemberTriggerHandler {

 
 public void onAfterInsert(List<AccountTeamMember> triggerNew , Map<Id, AccountTeamMember> triggerNewMap){
    updateFlockAccountManager(triggerNewMap);
     // to Store the map of roles that set to delete in custom setting   
    Map<String , String> allowDeltRoles =new  Map<string, String>(); 
    // fecth custom setting roles which flagged to delete and store it for further use    
    for (AccountTeamMemberRoles__c atmr : AccountTeamMemberRoles__c.getAll().values()) {
       if (atmr.Allow_Delete__c) {
          allowDeltRoles.put(atmr.RoleName__c, atmr.RoleName__c); 
       }
    }
    
    //for (AccountTeamMemberRoles__c accounteamRolerec : [Select RoleName__c, Allow_Delete__c From AccountTeamMemberRoles__c where Allow_Delete__c = true ]) {
    //        allowDeltRoles.put(accounteamRolerec.RoleName__c, accounteamRolerec.RoleName__c); 
    //}
    // map of Account and respective roles 
    Map<id, map<String, String>> accountIdVsRoleToDelete = new Map<id, Map<String, String >>(); 
    set<String> roles = new set<string>(); 
    map<id, id > newAccountUser = new Map<id, Id>(); 
    for (AccountTeamMember accTeamMemRec : triggerNew) {
          
            // checking wether role is alredy stored in the map else creating map structe . 
             if (allowDeltRoles.get(accTeamMemRec.TeamMemberRole) != null ) {
                roles.add(accTeamMemRec.TeamMemberRole); 
                map<String, string> mapofRols = (accountIdVsRoleToDelete.containsKey(accTeamMemRec.AccountId) ? accountIdVsRoleToDelete.get(accTeamMemRec.AccountId) : new Map<String, string>());
                mapofRols.put(accTeamMemRec.TeamMemberRole, accTeamMemRec.TeamMemberRole);
                accountIdVsRoleToDelete.put(accTeamMemRec.AccountId, mapofRols); 
             }         
             newAccountUser.put(accTeamMemRec.id, accTeamMemRec.id) ; 
        } // for (AccountTeamMember accTeamMemRec : triggerNew
        List<AccountTeamMember> idsToDelete = new List<AccountTeamMember>(); 

     if (!accountIdVsRoleToDelete.isEmpty()) {
        // looping over the account team members for further check wethere roles alredy exisit , if yes storing in a list to delete 
        // checks if there's another ATM as the same role name as the one just added
        for (AccountTeamMember accTeamMemRec : [select id ,AccountId,TeamMemberRole,userid from AccountTeamMember where AccountId in :accountIdVsRoleToDelete.keySet() and TeamMemberRole in : roles  ]) {
            if (accountIdVsRoleToDelete.get(accTeamMemRec.AccountId).get(accTeamMemRec.TeamMemberRole) != null ) {
                if (newAccountUser.get(accTeamMemRec.id) == null ) {
                    idsToDelete.add(accTeamMemRec); 
                }
                
            }
        }
        /// deleting the members 
        delete idsToDelete; 
     } // if (!accountIdVsRoleToDelete.isEmpty
   } // onAfterInsert


   //FlockAccountManager update strated
   public static void updateFlockAccountManager(Map<Id, AccountTeamMember> mapAtmidAtm){

        //Map of Account id and ATM 
         Map<Id,AccountTeamMember> mapAccidATM=new Map<Id,AccountTeamMember>(); 

         for(Id key:mapAtmidAtm.keySet()){
            system.debug('MA'+mapAtmidAtm.get(key).AccountId);
            //We are checking the team role of ATM
            if(mapAtmidAtm.get(key).TeamMemberRole=='FLOCK Account Manager'){
                mapAccidATM.put(mapAtmidAtm.get(key).AccountId,mapAtmidAtm.get(key));
            }
            
         }//End of for
       if (!mapAccidATM.isEmpty()) {
         updateReferenceHNBF(mapAccidATM);
         updateReferenceBeneTrac(mapAccidATM);
       }
     }//End of updateFlockAccountManager

     //Reference Agency--update Start
     //Updating 'Flock_Account_Manager__c' field of 'Reference_HNBF__c' object
     public static void updateReferenceHNBF(Map<Id,AccountTeamMember> mapAccidATM){
        List<Reference_HNBF__c> lstReferenceHNBF=queryReferenceHNBF(mapAccidATM);
        //List to update for Reference Agency data 
        List<Reference_HNBF__c> lsttobeupdateReferenceHNBF=new List<Reference_HNBF__c>();

        if(lstReferenceHNBF!=null && !lstReferenceHNBF.isEmpty()){
            for(Reference_HNBF__c referenceHNBF:lstReferenceHNBF){
                system.debug('MA1'+'Agency'+referenceHNBF.id+'Case'+referenceHNBF.Case_Number__c);
                referenceHNBF.Flock_Account_Manager__c=mapAccidATM.get(referenceHNBF.Case_Number__r.Account.Id).UserId;
                lsttobeupdateReferenceHNBF.add(referenceHNBF);
            }
        }//End of If

        try{
            //update lsttobeupdateReferenceHNBF;
            DmlHelper.performDML2(lsttobeupdateReferenceHNBF, DmlHelper.DML_UPDATE, 'AccountTeamMemberTriggerHandler', 'updateReferenceHNBF', 'Update ReferenceAgency', false);
        }
        catch(Exception ex){

        }

     }

     //Querying 'Reference_HNBF__c' object data based on accountID 
     public static List<Reference_HNBF__c> queryReferenceHNBF(Map<Id,AccountTeamMember> mapAccidATM){
         return[Select id,Case_Number__c,Case_Number__r.Account.Id,Flock_Account_Manager__c from Reference_HNBF__c where Case_Number__r.Account.Id In:mapAccidATM.keySet() and Current_Step__c!='Onboarding Complete'];
     }
     //Reference Agency--update End


     //Reference BeneTrac Onboarding-- update Start
     //Updating 'Flock_Account_Manager__c' field of 'Reference_BeneTrac_Onboarding__c' object
     public static void updateReferenceBeneTrac(Map<Id,AccountTeamMember> mapAccidATM){
        List<Reference_BeneTrac_Onboarding__c> lstReferenceBeneTrac=queryReferenceBeneTrac(mapAccidATM);
        List<Reference_BeneTrac_Onboarding__c> lsttobeupdateReferenceBeneTrac=new List<Reference_BeneTrac_Onboarding__c>();

        if(lstReferenceBeneTrac!=null && !lstReferenceBeneTrac.isEmpty()){
            for(Reference_BeneTrac_Onboarding__c referenceBenetrac:lstReferenceBeneTrac){
                system.debug('MA2'+'ReferenceBenetrac'+referenceBenetrac.id+'Case'+referenceBenetrac.Case_Number__c);
                referenceBenetrac.Flock_Account_Manager__c=mapAccidATM.get(referenceBenetrac.Case_Number__r.Account.Id).UserId;
                lsttobeupdateReferenceBeneTrac.add(referenceBenetrac);
            }
        }//End of if

        try{
            //update lsttobeupdateReferenceBeneTrac;
            DmlHelper.performDML2(lsttobeupdateReferenceBeneTrac, DmlHelper.DML_UPDATE, 'AccountTeamMemberTriggerHandler', 'updateReferenceBeneTrac', 'Update ReferenceBeneTracOnboarding', false);
        }
        catch(Exception ex){

        }

     }

     //Querying 'Reference_BeneTrac_Onboarding__c' object data based on accountID 
     public static List<Reference_BeneTrac_Onboarding__c> queryReferenceBeneTrac(Map<Id,AccountTeamMember> mapAccidATM){
        return[Select id,Case_Number__c,Case_Number__r.Account.Id,Flock_Account_Manager__c from Reference_BeneTrac_Onboarding__c where Case_Number__r.Account.Id In:mapAccidATM.keySet()];
    }

    //Reference BeneTrac Onboarding--update End





}