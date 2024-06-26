/* 
   If the Client Relationship Account Manager field changes on the Reference 401k-S125 object, update the Prospect-Client Team
   field/Role on the Account
   
  History
  -------
  02/20/2014 Frank Lurz   Created
  10/04/2016 Dan Carmen   Added call to SRRTransitionHelper
  04/09/2021 Manmeet Vaseer APR0116626 - New Object in SFDC for PEP Due Diligence Team 
  04/20/2023 Lalan Kumar    APR0147498 - Added call to new401kCTTcaseCreate
  11/15/2023 Eric Porter    APR0160473 remove new reference objects being created on every update. 
 */
trigger Reference401After on Reference_401k_S125__c (before insert, before update, after insert, after update) {
       
          
   //Schema.RecordTypeInfo refOnb401kConvrt = RecordTypeHelper.getRecordType('Service Onboarding 401k Conversions', 'Reference_401k_S125__c');
   //Schema.RecordTypeInfo refOnb401kLMNCrt = RecordTypeHelper.getRecordType('Service Onboarding 401k Large Market New Case', 'Reference_401k_S125__c');
   //Schema.RecordTypeInfo refOnbEPlanrt = RecordTypeHelper.getRecordType('Service Onboarding ePlan', 'Reference_401k_S125__c');
   //Schema.RecordTypeInfo refOnbRRSrt = RecordTypeHelper.getRecordType('Service Onboarding RRS', 'Reference_401k_S125__c');
   //Schema.RecordTypeInfo refOnbSEBSrt = RecordTypeHelper.getRecordType('Service Onboarding SEBS', 'Reference_401k_S125__c');      
       
   // Reference 401k/S125 records with Client Relationship Account Manager changes that may need to update the Account Team 
   set<id> CRAMtoUpdateAcctTeam = new set<id>(); 
   List<Reference_401k_S125__c> ref401kS125ForPEP = new List<Reference_401k_S125__c>();
     System.debug('ref401kS125ForPEP'+ ref401kS125ForPEP);
   for (Reference_401k_S125__c newRec: Trigger.new) {
      Reference_401k_S125__c oldRec = (Trigger.isUpdate ? Trigger.oldMap.get(newRec.id) : null);
      if (Trigger.isAfter) {
          if (newRec.Client_Relationship_Account_Manager__c != null 
              && (oldRec == null || newRec.Client_Relationship_Account_Manager__c != oldRec.Client_Relationship_Account_Manager__c)) {
                  CRAMtoUpdateAcctTeam.add(newRec.id);
          }
          
          // APR0116626
          if(newRec.PEP__c != null && (oldRec != null && oldRec.PEP__c == null))	{
              ref401kS125ForPEP.add(newRec);
          }
      } // if (Trigger.isAfter
      if (Trigger.isBefore) {
         SRRTransitionHelper.checkBeforeActions(newRec,oldRec);
          
      }
        
   } // for (Reference_401k_S125__c newRec
 
   if (Trigger.isAfter) {
      if(!CRAMtoUpdateAcctTeam.isEmpty()) Ref401UpdateAcctTeam.processCRAMAcctTeam(CRAMtoUpdateAcctTeam);
      if(!ref401kS125ForPEP.isEmpty()) RefPEPDueDiligenceMethods.createNewPEPRecs(ref401kS125ForPEP); // APR0116626
    /* APR0147498 - 401k - Create New Ref Ops - CTT New Case*/
      //  Reference401k_S125ObjectHandler.handleTrigger(trigger.newmap,trigger.oldMap);
   }
  
   if (Trigger.isBefore) {
      SRRTransitionHelper.processBeforeActions();
		

   

   }

   
} // trigger Reference401After