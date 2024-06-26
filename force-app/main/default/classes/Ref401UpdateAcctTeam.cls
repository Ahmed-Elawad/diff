/* 
 *  If the Client Relationship Account Manager field of a Reference 401k/S125 record changes, add the User to the Account Team Role of HRS Client Relationship Account Manager 
 *  Called from trigger = Reference401After
 *
 *  History
 *  -------
 *  02/28/2014 Frank Lurz      Created
 *
 */

public with sharing class Ref401UpdateAcctTeam {

    public static void processCRAMAcctTeam(set<id> ref401IdSet) {       
          
        Schema.RecordTypeInfo refOnb401kConvrt = RecordTypeHelper.getRecordType('Service Onboarding 401k Conversions', 'Reference_401k_S125__c');
        Schema.RecordTypeInfo refOnb401kLMNCrt = RecordTypeHelper.getRecordType('Service Onboarding 401k Large Market New Case', 'Reference_401k_S125__c');
        Schema.RecordTypeInfo refOnbEPlanrt = RecordTypeHelper.getRecordType('Service Onboarding ePlan', 'Reference_401k_S125__c');
        Schema.RecordTypeInfo refOnbRRSrt = RecordTypeHelper.getRecordType('Service Onboarding RRS', 'Reference_401k_S125__c');
        Schema.RecordTypeInfo refOnbSEBSrt = RecordTypeHelper.getRecordType('Service Onboarding SEBS', 'Reference_401k_S125__c');                       
         
        // any Account Team Members that need to be inserted
        List<AccountTeamMember> insertATMs = new List<AccountTeamMember>();
        
        List<Reference_401k_S125__c> ref401List = [Select Id, 
                                                    recordtypeid,
                                                    Current_Step__c,
                                                    Case_Lookup__r.Account.ID, 
                                                    Client_Relationship_Account_Manager__r.isActive,
                                                    Client_Relationship_Account_Manager__c 
                                                    from Reference_401k_S125__c  
                                                    where Id in :ref401IdSet];
        
        for (Reference_401k_S125__c ref401 : ref401List) {
                   
            if (ref401.Client_Relationship_Account_Manager__r.isActive
                && (  (ref401.recordtypeid == refOnb401kConvrt.getRecordTypeId() && ref401.Current_Step__c != 'Lost During Onboarding' && ref401.Current_Step__c != '(7 of 8) Conversion Complete - Waiting on Historical Data' && ref401.Current_Step__c != '(8 of 8) Conversion Complete ') ||
                      (ref401.recordtypeid == refOnb401kLMNCrt.getRecordTypeId() && ref401.Current_Step__c != 'Lost During Onboarding' && ref401.Current_Step__c != '(4 of 4) Onboarding Complete') ||
                      (ref401.recordtypeid == refOnbEPlanrt.getRecordTypeId() && ref401.Current_Step__c != 'Lost During Onboarding' && ref401.Current_Step__c != '(4 of 4) Conversion Complete') ||
                      (ref401.recordtypeid == refOnbRRSrt.getRecordTypeId() && ref401.Current_Step__c != 'Lost During Onboarding' && ref401.Current_Step__c != '(4 of 4) Conversion Complete') ||
                      (ref401.recordtypeid == refOnbSEBSrt.getRecordTypeId() && ref401.Current_Step__c != 'Lost During Onboarding' && ref401.Current_Step__c != '(4 of 4) Conversion Complete')
                 )                
               )
            {
                insertATMs.add(new AccountTeamMember(AccountId = ref401.Case_Lookup__r.Account.Id
                                                     ,UserId = ref401.Client_Relationship_Account_Manager__c
                                                     ,TeamMemberRole = 'HRS Client Relationship Account Manager'));
            }         

        } // for Reference_401k_S125__c ref401
    
    
        // insert AccountTeamMembers if necessary        
        system.debug('***FLURZ***' + insertATMs);
        if (!insertATMs.isEmpty()){
           insert insertATMs;
        }

    } // processCRAMAcctTeam 

} // Ref401UpdateAcctTeam