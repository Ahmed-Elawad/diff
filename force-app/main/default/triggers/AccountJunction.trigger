/*
 History
 -------
  03/22/2017 Cindy Freeman      created
  07/29/2017 Cindy Freeman      modified to be able to skip code if needed
  08/02/2017 Cindy Freeman      added checkBeforeJunction to look for Push Parent to Child flag
  01/03/2020 Dan Carmen       Move logic to AccountJunctionMethods

*/


trigger AccountJunction on Account_Junction__c (after insert, before update, after update, before delete) {
   new AccountJunctionMethods().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
   /*
    //if (!AccountJunctionMethods.SKIP_JUNCTION_TRIGGERS)
    //{
        if (Trigger.isBefore && Trigger.isUpdate)
        {   for (Account_Junction__c newJ: Trigger.new)
            {   Account_Junction__c oldJ = Trigger.oldMap.get(newJ.id);
                AccountJunctionMethods.checkBeforeJunction(newJ, oldJ, Trigger.isInsert, Trigger.isDelete);
            } // for
        } // if (before && update)
                        
        if (Trigger.isDelete)
        {   for (Account_Junction__c oldJ: Trigger.old)
            {   AccountJunctionMethods.checkAfterJunction(null, oldJ, Trigger.isInsert, Trigger.isDelete);  }
        }
        else
        {   for (Account_Junction__c junc: Trigger.new) {
                Account_Junction__c oldJ = (Trigger.isUpdate ? Trigger.oldMap.get(junc.id) : null);
                AccountJunctionMethods.checkAfterJunction(junc, oldJ, Trigger.isInsert, Trigger.isDelete);              
            } // for
        }
        
        AccountJunctionMethods.processAfterJunction();
        
    //} // if (!AccountJunctoinMethods.SKIP_JUNCTION_TRIGGERS)
    */
} // AccountJunction