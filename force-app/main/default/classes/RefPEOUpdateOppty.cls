/* 
 * Update the Opportunity if certain criteria occur.
 *
 * History
 * -------
 * 10/11/2011 Dan Carmen   Created
 * 08/16/2013 Dan Carmen   Added handling in for Sold - Submitted (rather than Sold: Submitted)
 * 05/04/2017 Saketh Mysa  Updated Opportunity Stage from 'Sold - Run' to 'Sold - Started'.
 *                         Updated 'Sold: Started' condition to execute if StageName != 'Sold - Submitted'
 *
 * 01/04/2017 Cindy Freeman     modifed to Not change status of PEO opty if the Status contains 'Sold' when Pass to New Loads was checked
 * 05/08/2018 Frank Lurz   Commented out Opportunity updates per Fast Track Case 28594622
 */
public without sharing class RefPEOUpdateOppty {
   public static void processOpptys(Set<Id> opptyIds
                                   ,Reference_PEO__c[] updateToSoldSub
                                   ,Reference_PEO__c[] updateToSoldRun) {
                                    
      // retrieve the opportunities
      Map<Id,Opportunity> opptys = new Map<Id,Opportunity>([Select Id
                                                                  ,StageName
                                                                  ,CloseDate
                                                              from Opportunity
                                                             where Id in :opptyIds]);
      System.debug('RefPEOUPdateOppty - Nbr opptys='+opptys.size());
      // if no records returned, do nothing
      if (opptys.isEmpty()) {
         return;
      }
      
      // the records that will be updated. Use a map to prevent duplicates from being entered.
      Map<Id,Opportunity> updateOpptys = new Map<Id,Opportunity>();
      
      for (Reference_PEO__c rec : updateToSoldSub) {
         Opportunity oppty = opptys.get(rec.Opportunity__c);
         System.debug('looking for oppty: oppty='+oppty);
         if (oppty != null && !oppty.StageName.contains('Sold'))  {
            oppty.StageName = 'Sold - Submitted';
            updateOpptys.put(oppty.Id, oppty);
         }
      } // for
      
      /***  FL commented out this code on 5/8/18 per Fast Track Case 28594622  ***/
      /***for (Reference_PEO__c rec : updateToSoldRun) {
         Opportunity oppty = opptys.get(rec.Opportunity__c);
         if (oppty != null && oppty.StageName != 'Sold - Started') {
            oppty.StageName = 'Sold - Started';
            updateOpptys.put(oppty.Id, oppty);
         }
      } // for***/

      /***  FL commented out this code on 5/8/18 per Fast Track Case 28594622  ***/
      /***if (!updateOpptys.isEmpty()) {
         update updateOpptys.values();
      }***/
      //SObjectHelper soh = new SObjectHelper();
      //soh.saveRecords(updateOpptys.values(), null, null);
   } // processOpptys
   
} // class RefPEOUpdateOppty