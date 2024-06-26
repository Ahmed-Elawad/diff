/* TRigger for the OpportunityContactRoleChangeEvent object.
   
  History
  -------
  03/18/2013 Lalan Kumar     Created

*/

trigger OpportunityContactRoleTrigger on OpportunityContactRoleChangeEvent (after insert) {
	Set<String> ocrIDs = new Set<String>();
    
    for(OpportunityContactRoleChangeEvent e : trigger.new){
        EventBus.ChangeEventHeader changeEventHeader = e.ChangeEventHeader;
        //Checking if the if the record is created or updated
        if(changeEventHeader.changetype == 'CREATE' || changeEventHeader.changetype == 'UPDATE'){
            if(!changeEventHeader.getRecordIds().IsEmpty()){
               List <String> recordIds = changeEventHeader.getRecordIds();
               ocrIDs.addAll(recordIds); 
            }
                
        }
        
    }
    //Call the Handler class method and pass the OpportunityContactRole IDsv
    if(!ocrIDs.IsEmpty()){
        opptyContactRoleHandler.updateOppPhoneandConsentToText(ocrIDs);
    } 
        
}