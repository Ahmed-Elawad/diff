/* 
 * Update the Opportunity if certain criteria occur.
 *
 * History
 * -------
 * 04/12/2013  Frank Lurz   Created using Dan's code
 *
 */
public without sharing class RefHRECHBUpdateOppty {
   public static void processOpptys(Set<Id> opptyIds
                                   ,Reference_HRE_CHB_Onboarding__c[] updateToSoldSub
                                   ,Reference_HRE_CHB_Onboarding__c[] updateToSoldRun) {
                                    
            // retrieve the opportunities
      Map<Id,Opportunity> opptys = new Map<Id,Opportunity>([Select Id
                                                                  ,StageName
                                                                  ,CloseDate
                                                              from Opportunity
                                                             where Id in :opptyIds]);
      System.debug('Nbr opptys='+opptys.size());
      // if no records returned, do nothing
      if (opptys.isEmpty()) {
         return;
      }
      
      // the records that will be updated. Use a map to prevent duplicates from being entered.
      Map<Id,Opportunity> updateOpptys = new Map<Id,Opportunity>();
      
      for (Reference_HRE_CHB_Onboarding__c rec : updateToSoldSub) {
         Opportunity oppty = opptys.get(rec.Opportunity__c);
         System.debug('looking for oppty: oppty='+oppty);
         if (oppty != null && oppty.StageName != 'Sold: Submitted') {
            oppty.StageName = 'Sold: Submitted';
            updateOpptys.put(oppty.Id, oppty);
         }
      } // for
      
      for (Reference_HRE_CHB_Onboarding__c rec : updateToSoldRun) {
         Opportunity oppty = opptys.get(rec.Opportunity__c);
         if (oppty != null && oppty.StageName != 'Sold - Run') {
            oppty.StageName = 'Sold - Run';
            updateOpptys.put(oppty.Id, oppty);
         }
      } // for

      SObjectHelper soh = new SObjectHelper();
      soh.saveRecords(updateOpptys.values(), null, null);
   } // processOpptys
   
} // class RefHRECHBUpdateOppty