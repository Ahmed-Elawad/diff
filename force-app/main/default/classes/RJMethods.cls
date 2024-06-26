/** Methods for communicating with RJDB

* History
* -------
02/15/2021 Jake Hinds       Created
04/15/2021 Dan Carmen       Remove extra debug statements
11/12/2021 Dan Carmen       Cleaned up code
02/24/2022 Dan Carmen       Removed logging to ProcessNotes
07/17/2023 Dan Carmen       Remove extra debug statements

*/

public without sharing class RJMethods implements TriggerInterfaceC{
   public static Set<String> RAN_SET=new Set<String>();
    
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      TriggerMethods.objectTypeName = (recs != null && !recs.isEmpty() ? recs[0].getSObjectType().getDescribe().getName() : null);
      Boolean okayToRun = TriggerMethods.objectTypeName != null && !RAN_SET.contains(TriggerMethods.objectTypeName);
      system.debug('RJMethods.handleTrigger isBefore='+isBefore+' objectTypeName='+TriggerMethods.objectTypeName+' okayToRun='+okayToRun+' recs='+recs.size());
      if (okayToRun) {
         if (isBefore) {
            checkOACFieldChange(recs,oldMap);
            // so only runs once in a transaction
            // 12/1/2021 - I think other things will handle recursion so taking this out for now. 
            //RAN_SET.add(TriggerMethods.objectTypeName);
         } // if (isBefore
      } // if (okayToRun
   } // handleTrigger

   public static void checkOACFieldChange(SObject[] recs,Map<Id,SObject> oldMap){
        
      //get describe of first element in trigger list to get field set from.
      DateTime now = system.now();
      Schema.DescribeSObjectResult objDescribe = recs[0].getSObjectType().getDescribe();
      Map<String, Schema.FieldSet> fsMap = objDescribe.fieldSets.getMap();
      Schema.FieldSet oacFieldSet = fsMap.get('OAC_Fields');
      
      //Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
      //Boolean hasProcessNotes = fieldMap.containsKey('ProcessNotes__c');
       
      system.debug('RJMethods has oacFieldSet='+(oacFieldSet != null));
      // if there isn't a field set we're not going to track changes
      if (oacFieldSet != null) {
         for (SObject rec : recs) {
            Sobject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
            // if there's not currently a date or an insert or a corresponding field changed
            Boolean changed = (rec.get('OAC_Change_Date__c') == null || (oldRec != null ? TriggerMethods.checkForFldChange(rec,oldRec,oacFieldSet) : true));
            //System.debug('RJMethods changed='+changed);
            if (changed) {
               try {
                  //system.debug('RJMethods field change found setting OAC_Change_Date, is insert='+(oldRec == null));
                  rec.put('OAC_Change_Date__c',now);
               } catch(Exception e) {
                  Errorlog.logError('RJMethods', 'checkOACFieldChange', 'put oac field', rec.Id, e,null,false);
               }
            } // if (changed
            //if (hasProcessNotes) {
            //   StringHelper.addToProcessNotes(rec,'RJMethods changed='+changed);
            //}
         } // for (SObject rec : recs
         //check for any save errors
         ErrorLog.checkSave();
      } // if (oacFieldSet != null
   } // checkOACFieldChange
    
} // class RJMethods