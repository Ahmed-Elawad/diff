/*
   
  History
  -------
  02/01/2014 Justin Henderson   Created
  11/21/2018 Frank Lurz         This code can be retired/deleted per Case #30679020
  
 */
trigger HRS4SDiscChatterFeed on HRS_4S_Discrepancy__c (after insert){       
    list<HRS_4S_Discrepancy__c> HRS4SDiscList = [Select Id, 
                                                    Sales_Rep__c, 
                                                    FSS__c, 
                                                    Client_Name__c,
                                                    Reference_401k_S125__c
                                                    from HRS_4S_Discrepancy__c 
                                                    WHERE Id IN: Trigger.newMap.keySet()];
    HRS4SChatterPost.createHRS4SChatterPost(HRS4SDiscList);
}