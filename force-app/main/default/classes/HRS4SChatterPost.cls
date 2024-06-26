/*
   
  History
  -------
  02/01/2014 Justin Henderson   Created
  11/04/2015 Dan Carmen         Modified to use a different createChatterMentionPost method
  11/21/2018 Frank Lurz         This code can be retired/deleted per Case #30679020
  
 */

public with sharing class HRS4SChatterPost {

   public static final String MSG_PART1 = 'Client ';
   public static final String MSG_PART2 = ' currently has an open discrepancy that needs to be resolved.';

   public static void createHRS4SChatterPost(list<HRS_4S_Discrepancy__c> hrs4SDiscList){
      list<HRS_4S_Discrepancy__c> hrs4SDiscListToUpdate = new list<HRS_4S_Discrepancy__c>();
      for (HRS_4S_Discrepancy__c disc: hrs4SDiscList){
         /***if (disc.FSS__c == NULL && disc.Sales_Rep__c != NULL){
            disc.FSS__c = [Select DSA_FSS__c from user where Id = :disc.Sales_Rep__c Limit 1].DSA_FSS__c;
            if (disc.FSS__c != NULL){
               hrs4SDiscListToUpdate.add(disc);
            }
         } // if (disc.FSS__c == NULL
            
         Id[] mentionIds = new Id[]{};
         if (disc.Sales_Rep__c != null) {
            mentionIds.add(disc.Sales_Rep__c);
         }
         if (disc.FSS__c != null) {
            mentionIds.add(disc.FSS__c);
         }
         // only do a post if there are mentions.
         if (!mentionIds.isEmpty()) {
            string body = MSG_PART1+disc.Client_Name__c+MSG_PART2;
            ChatterMentionPost.createChatterMentionPost(disc.id, mentionIds, body);
         } ***/
         //ChatterMentionPost.createChatterMentionPost(disc.id, disc.Sales_Rep__c, disc.FSS__c, body, name, body2);            
      } // for (HRS_4S_Discrepancy__c disc
      if (!hrs4SDiscListToUpdate.isEmpty()){
         ///system.debug('JRH *** hrs4SDiscListToUpdate ' + hrs4SDiscListToUpdate);
         ///update hrs4SDiscListToUpdate;
      }
   } // createHRS4SChatterPost

}//HRS4SChatterPost