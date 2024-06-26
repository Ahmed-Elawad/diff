/*
 History
 -------
  02/26/2017 Cindy Freeman      created
                                look for opty
                                update Opty Latest MCT lookup
                                save MCT
  12/29/2019 Cindy Freeman      send to checkAfterMCT to populate partner referral lookup    
  01/29/2024 Pujitha Madamanchi Remove for loop and call helper directly                          
*/

trigger MarketingCallTrackingAfter on Marketing_Call_Tracking__c (after insert, after update) {
   
   /*   for (Marketing_Call_Tracking__c mct: Trigger.new) 
    {       Marketing_Call_Tracking__c oldMCT = (Trigger.isUpdate ? Trigger.oldMap.get(mct.id) : null);
            if (!MarketTrackingMethods.mctIdsProcessedPartRef.contains(mct.Id))
            {   MarketTrackingMethods.checkAfterMCT(mct, oldMCT);   }   
    } */
  
  MarketTrackingMethods.processAfterMCT(Trigger.new, Trigger.oldMap);
  
  // Added by Rick Segura (DemandGen, Inc.) on 2018-06-20
  if(trigger.isAfter && trigger.isInsert)  MarketTrackingMethods.update_LC_ProductOfInterest(trigger.new);  
}