/* 
 * This trigger closes related ESR Cases when the event is deleted.
 *
 * History
 * -------
 * 07/17/2016 Jacob Hinds       Created
 * 03/02/2018 Cindy Freeman     when event is deleted and was linked to an opty, send to method to recalc number of events on opty
 *
 */
trigger EventCloseCase on Event (after delete) {
    /*
    // set of optys the need Number of Events recalced
    Set<Id> optyIdSet = new Set<Id>();
   
    Schema.RecordTypeInfo esrRT = RecordTypeHelper.getRecordType(Label.RT_ESR_Event,'Event');
    User ESRUser = [SELECT Id FROM User WHERE Name = :Label.ESR_User LIMIT 1];
    Id[] caseIDs = new Id[]{};
    Case[] cases = new Case[]{};
    for(Event e:System.Trigger.old){
        if(e.RecordTypeId == esrRt.getRecordTypeId() && e.WhatId != null && e.OwnerId == ESRUser.Id){
            caseIDs.add(e.WhatId);
        }
        
        String optyId = (String)e.WhatId;
        if (optyId != null && optyId.Left(3) == '006')
        {   optyIdSet.add(e.WhatId);      } 
        
    } // for
    
    if(!caseIds.isEmpty()){
        cases = [Select Id,Status FROM Case WHERE Id in :caseIds];
        for(Case c:cases){
            c.Status = 'Deleted/Rescheduled';
        }
        update cases;
    } // if(!caseIds...
    
    if (!optyIdSet.isEmpty())
    {    EventCheckType.procesOpty(optyIdSet);   }*/
    
}