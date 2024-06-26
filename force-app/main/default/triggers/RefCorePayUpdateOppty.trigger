/* 
 * Check to see if certain values change to update the Opportunity.
 *
 * History
 * -------
 * 06/28/2010 Dan Carmen   Created
 * 10/07/2010 Dan Carmen   Removed code checking for load complete flag.
 * 12/2/2015  Lynn Michels  Added after insert for Reference Core Payroll to create MPSC Onboarding documents when created.
   03/06/2016 Cindy Freeman Removed check of Returning Lost Client, it no longer is pushed to the oppty
   05/17/2023 Dan Carmen    Add check for CEID and CAID
   06/19/2023 Eric Porter   Add back in updateImpSplsist code for Insite SMB work
   04/10/2024  Carrie Marciano    Removed code related to old MPSC Process

*/
trigger RefCorePayUpdateOppty on Reference_Core_Payroll__c (after insert, after update) {

   /** Keep track of all of the opportunity ids. Use a Map so we can put multiple times without worrying about dups. **/
   Map<Id,Id> allOpptyIds = new Map<Id,Id>();

   /** Client Load Received is changed to true. */
   Reference_Core_Payroll__c[] loadReceived = new Reference_Core_Payroll__c[]{};
   /** Payroll run date populated. */
   Reference_Core_Payroll__c[] runDate = new Reference_Core_Payroll__c[]{};
   /** New Prospect-Client number changes. */
   Reference_Core_Payroll__c[] cltNbr = new Reference_Core_Payroll__c[]{};
   /** Other Field updates occur. */
   Reference_Core_Payroll__c[] otherUpdates = new Reference_Core_Payroll__c[]{};
   Set<Id> updateImpSplsist = new set<id>(); 
   if (Trigger.isInsert)
   {
        //RefMMSPayrollHelper.createMPSCOnboardingDocs(Trigger.new); 
        for (Reference_Core_Payroll__c newRcp : Trigger.new) {
          if (newRcp.CallerName__c != null ) {
            updateImpSplsist.add(newRcp.id);
          } 
        }
   }

else{
   for ( Reference_Core_Payroll__c newRcp: Trigger.new) {
      // make sure there's an opportunity id
      if (newRcp.Opportunity_Lookup__c != null) {
         // get the old record
         Reference_Core_Payroll__c oldRcp = (Reference_Core_Payroll__c)Trigger.oldMap.get(newRcp.Id);
         // Client Load Received is changed to true.
         if (newRcp.Client_Load_Received__c && !oldRcp.Client_Load_Received__c) {
            loadReceived.add(newRcp);
            allOpptyIds.put(newRcp.Opportunity_Lookup__c, newRcp.Opportunity_Lookup__c);
         } // if

        // Payroll run date populated
         if ((newRcp.Payroll_Run_Date__c != null) && (oldRcp.Payroll_Run_Date__c == null)) {
            runDate.add(newRcp);
            allOpptyIds.put(newRcp.Opportunity_Lookup__c, newRcp.Opportunity_Lookup__c);
         } // if
         
         // If any of these fields change, update
         if (//(newRcp.Returning_Lost_Client__c != oldRcp.Returning_Lost_Client__c) ||
             (newRcp.Number_of_Employees__c != null && (newRcp.Number_of_Employees__c != oldRcp.Number_of_Employees__c)) || 
             (newRcp.Frequency__c != null && (newRcp.Frequency__c != oldRcp.Frequency__c)) || 
             (newRcp.Discount_Type__c != null && (newRcp.Discount_Type__c != oldRcp.Discount_Type__c)) || 
             (newRcp.Discount_Percentage__c != null && (newRcp.Discount_Percentage__c != oldRcp.Discount_Percentage__c)) || 
             (newRcp.Discount_Period__c != null && (newRcp.Discount_Period__c != oldRcp.Discount_Period__c)) || 
             (newRcp.Discount2_Type__c != null && (newRcp.Discount2_Type__c != oldRcp.Discount2_Type__c)) || 
             (newRcp.Discount2_Period__c != null && (newRcp.Discount2_Period__c != oldRcp.Discount2_Period__c)) || 
             (newRcp.Discount2_Percentage__c != null && (newRcp.Discount2_Percentage__c != oldRcp.Discount2_Percentage__c)) || 
             (newRcp.Multi_Frequency__c != oldRcp.Multi_Frequency__c) || 
             (newRcp.Change_of_Ownership__c != oldRcp.Change_of_Ownership__c) || 
             (newRcp.Add_l_ID_Added__c != oldRcp.Add_l_ID_Added__c) || 
             (newRcp.Other_Credit__c != oldRcp.Other_Credit__c) || 
             (newRcp.Other_Credit_Reason__c != null && (newRcp.Other_Credit_Reason__c != oldRcp.Other_Credit_Reason__c)) || 
             (newRcp.NCS_Verified__c != oldRcp.NCS_Verified__c)||
             (newRcp.Opportunity_Lookup__r.NCS_Name__c == null || (newRcp.NCS_Name__c != oldRcp.NCS_Name__c))
            ) {
            otherUpdates.add(newRcp);
            allOpptyIds.put(newRcp.Opportunity_Lookup__c, newRcp.Opportunity_Lookup__c);
         } // if
 
         
         // New Prospect-Client Number changes
         if (((newRcp.New_Prospect_Client_Number__c != null) && (newRcp.New_Prospect_Client_Number__c != oldRcp.New_Prospect_Client_Number__c))
             || (newRcp.CEID__c != null && (newRcp.CEID__c != oldRcp.CEID__c))
             || (newRcp.CAID__c != null && (newRcp.CAID__c != oldRcp.CAID__c))
             ) {
            cltNbr.add(newRcp);
         } // if
         
      } // if (newRcp.Opportunity_Lookup__c != null
      if (newRcp.CallerName__c != trigger.oldMap.get(newRcp.id).CallerName__c) {
        updateImpSplsist.add(newRcp.id);
      } 
   } // for
   
   if (!allOpptyIds.isEmpty() || !cltNbr.isEmpty()) {
      RefCorePayUpdateOppty.processStatusChanges(allOpptyIds,loadReceived,otherUpdates,runDate,cltNbr);
   }
   if (!updateImpSplsist.isEmpty()) {
    RefCorePayUpdateOppty.updateImpSplsist(updateImpSplsist);
     
  }
}

} // trigger RefCorePayUpdateOppty