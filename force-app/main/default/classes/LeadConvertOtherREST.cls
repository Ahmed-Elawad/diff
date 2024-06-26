/* 
 *  Convert leads associated with a lead company
  
 * History
 * -------
 * 11/04/2014 Dan Carmen     created
 * 12/16/2016 Cindy Freeman	 added line to instantiate dbConvertResultMap in coam before converting extra leads
 *   
 */
@RestResource(urlMapping='/leadConvertOther/*')
global without sharing class LeadConvertOtherREST {
 
   @HttpPost
   global static void doPost(Id acctId, Id[] leadIds) {
      LeadCompanyMethods.CALCULATE_SIGNIFICANCE = false;
      AccountMethods.CALCULATE_SIGNIFICANCE = false;
      CheckDataGovernance.SKIP_DATA_GOVERNANCE = true;
      System.debug('LeadConvertOtherREST doPost acctId='+acctId+' leadIds='+leadIds);
      Contact[] ctctsToUpdate = new Contact[]{};
  	
      for (Id leadId : leadIds) {
         CreateOppAndMeeting coam = new CreateOppAndMeeting(UserHelper.SO_CORE);
         coam.dbConvertResultMap = new Map<Id, List<Id>>();
         Id ctctId = coam.convertExtraLead(acctId, leadId);
         System.debug('LeadConvertOtherREST doPost ctctId='+ctctId);
         if (ctctId != null) {
            // make sure the sales contact field is set
            ctctsToUpdate.add(new Contact(Id=ctctId, Sales_Contact__c=true));
            
         }
      } // for
      
      if (!ctctsToUpdate.isEmpty()) {
         Database.update(ctctsToUpdate,false);
      }
      LeadCompanyMethods.CALCULATE_SIGNIFICANCE = true;
      AccountMethods.CALCULATE_SIGNIFICANCE = true;
   } // doPost 

} // LeadConvertOtherREST