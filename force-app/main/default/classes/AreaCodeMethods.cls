/* 
 * Methods for working with area codes. 
   Tests are in the ZipCodeInformationTest class.
 *
 * History
 * -------
 * 09/17/2013 Dan Carmen   Created
   03/30/2015 Dan Carmen   Trigger modification
 *
 */
public with sharing class AreaCodeMethods {

   public static void findTimeZones(Set<Id> areaCodeIdSet) {
   	
      // select the area codes
      Map<Id,AreaCode__c> areaCodeMap = new Map<Id,AreaCode__c>([Select Id, Name, State__c, TimeZoneName__c, TimeZoneAbbrev__c from AreaCode__c where Id in :areaCodeIdSet]);
      System.debug('findTimeZones areaCodeMap size='+areaCodeMap.size());
       
   	AggregateResult[] timeZoneResults = [SELECT count(Id) nbrZips, Zip_Code_Information__r.TimeZoneName__c timeZoneName, Zip_Code_Information__r.TimeZoneAbbrev__c timeZoneAbbrev, AreaCode__c 
   	                                      FROM AreaCodeLink__c
   	                                     Where AreaCode__c in :areaCodeIdSet
   	                                     group by Zip_Code_Information__r.TimeZoneName__c, Zip_Code_Information__r.TimeZoneAbbrev__c, AreaCode__c
   	                                     order by AreaCode__c, count(id) desc];

      // keep track on the records that were changed
      Map<Id,AreaCode__c> changedAreaCodeMap = new Map<Id,AreaCode__c>();
      
      // only take the first one for an area code   	                                     
      Id prevAreaCodeId = null;
      for (AggregateResult ar : timeZoneResults) {
         Id thisAreaCodeId = (Id)ar.get('AreaCode__c');
         // only take the first one
         if (thisAreaCodeId != prevAreaCodeId) {
            prevAreaCodeId = thisAreaCodeId;
            AreaCode__c ac = areaCodeMap.get(thisAreaCodeId);
            if (ac != null) {
               String timeZoneName = (String)ar.get('timeZoneName');
               String timeZoneAbbrev = (String)ar.get('timeZoneAbbrev');
               System.debug('findTimeZones timeZoneName='+timeZoneName+' timeZoneAbbrev='+timeZoneAbbrev);
               
               if (ac.TimeZoneName__c != timeZoneName || ac.TimeZoneAbbrev__c != timeZoneAbbrev) {
                  ac.TimeZoneName__c = timeZoneName;
                  ac.TimeZoneAbbrev__c = timeZoneAbbrev;
                  changedAreaCodeMap.put(ac.Id, ac);
               }
            } // if (ac != null 
         } // if
      } // for (AggregateResult ar

      AggregateResult[] stateResults = [SELECT count(Id) nbrZips, Zip_Code_Information__r.State__c state, AreaCode__c 
                                            FROM AreaCodeLink__c
                                           Where AreaCode__c in :areaCodeIdSet
                                           group by Zip_Code_Information__r.State__c, AreaCode__c
                                           order by AreaCode__c, count(id) desc];

      // compile the state(s) first, then compare to the area code record (in case there are multiple states)
      Map<Id,String> stateMapById = new Map<Id,String>();
      for (AggregateResult ar : stateResults) {
         Id thisAreaCodeId = (Id)ar.get('AreaCode__c');
         String stateValue = stateMapById.get(thisAreaCodeId);
         if (String.isNotBlank(stateValue)) {
            stateValue += ';'; 
         } else {
         	stateValue = '';
         }
         stateValue += (String)ar.get('state');
         System.debug('findTimeZones thisAreaCodeId='+thisAreaCodeId+' stateValue='+stateValue);
         stateMapById.put(thisAreaCodeId,stateValue);
      } // for (AggregateResult ar

      // compare the old values with the new.
      for (AreaCode__c ac : areaCodeMap.values()) {
      	String stateValue = stateMapById.get(ac.Id);
         System.debug('findTimeZones ac.Id='+ac.Id+' ac.State__c='+ac.State__c+' stateValue='+stateValue);
      	if (ac.State__c != stateValue) {
      	   ac.State__c = stateValue;
            changedAreaCodeMap.put(ac.Id, ac);
      	}
      } // for (AreaCode__c
      
      System.debug('findTimeZones number of changed changedAreaCodeMap='+changedAreaCodeMap.size());
      // update the changes
      if (!changedAreaCodeMap.isEmpty()) {
         update changedAreaCodeMap.values();
      }
   } // findTimeZones
} // class AreaCodeMethods