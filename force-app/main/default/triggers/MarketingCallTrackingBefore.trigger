/*
 History
 -------
  02/26/2017 Cindy Freeman      created
  Mongoose pushed in MCT
  SOSL to find task
  update MCT with task ID
  if Lead task, update MCT lead 
  if Ctct task, update MCT contact, 
  01/29/2024 Pujitha Madamanchi Remove for loop and call helper directly   
  
*/

trigger MarketingCallTrackingBefore on Marketing_Call_Tracking__c (before insert, before update) {
   
    /*for (Marketing_Call_Tracking__c mct: Trigger.new) 
    {   Marketing_Call_Tracking__c oldMCT = (Trigger.isUpdate ? Trigger.oldMap.get(mct.id) : null);
        MarketTrackingMethods.checkBeforeMCT(mct, oldMCT);  
    }*/
    
    MarketTrackingMethods.processBeforeMCT(Trigger.new, Trigger.oldMap);
         
}