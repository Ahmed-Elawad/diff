/*
  * This new process will dynamically create a new related record and link it back to the primary record.  For example, it can create 
  * a case record for an opportunity or a reference object record for a case.  The object relationships are defined in the 
  * Object Relationships object.  The fields that are populated upon creation of the related object are defined in multiple 
  * Object Relationships Fields records.  
  * 
  * Opportunity records are sent to the CreateRelatedObjects class by the OpptyCheckStatus trigger when an opportunity 
  * is updated to “Sold” or “Sold:” and has an Object Relationship defined. All new case records are sent to this class by the CaseAfter trigger. 
  *  
  * History
  * --------
  * 03/15/2013 Cindy Freeman    created
  * 07/09/2013 Cindy Freeman    added static method to return set of primary object record types for Opportunities
  *                             added check if processing optys and opty already has a case, skip that opty
  * 08/12/2013 Cindy Freeman    changed class to without sharing so running user can see cases within a queue thus preventing duplicates
  * 09/23/2013 Cindy Freeman    modified to allow ID type in constant field
  * 10/06/2013 Cindy Freeman    modified to use longer FilterCriteria field, handle related object with no record types
  * 08/26/2015 Jacob Hinds    added in an avoid assignment rules checkbox to allow the owner of a created case to stay as the primary object owner and not get routed through assignment rules.
    02/24/2020 Dan Carmen      Increment API to 48
    03/30/2020 Josh Cartwright  adding debugging for INC2940365 
   */


public without sharing class CreateRelatedObjects2 {

    public static Map<Id, Object_Relationships__c[]> mapRelatedObjs = new Map<Id, Object_Relationships__c[]>();             // id is Primary_Object_Rcd_Type_Id__c
    public static List<SObject> listSObjs = new List<SObject>();
    public static Map<Id,Id> opptyCtctMap = new Map<Id,Id>();
       
   public static final String KEY_OPPTY_RT_SET='CreateRelatedObjects2RtSetOpportunity';
   
   public static Set<String> CACHE_KEY_SET=new Set<String>{KEY_OPPTY_RT_SET};
   
   public static Boolean CACHE_IN_USE = (Label.Cache_In_Use=='Y');
       
   private static Set<String> optyRcdTypesSet = null;   

   // return opty record types that have relationship defined, reduces queries in OpptyAfter trigger
   public static Set<String> getObjRelOptyRcdTypes() {
      if (optyRcdTypesSet == null) {

         Object cacheObj = (!Utilities.SKIP_CACHE ? Cache.Org.get(KEY_OPPTY_RT_SET) : null);
         System.debug('getObjRelOptyRcdTypes cacheObj='+(cacheObj != null));
      
         //Set<String> optyRcdTypesSet;
         if (cacheObj != null) {
            optyRcdTypesSet = (Set<String>)cacheObj;
         } else {
            optyRcdTypesSet = retrieveOpptyRecTypes();
            if (!Utilities.SKIP_CACHE && CACHE_IN_USE) {
               Cache.Org.put(KEY_OPPTY_RT_SET,optyRcdTypesSet);
            }
         }
      } //
       /*
        if (optyRcdTypesSet == null)
        {   optyRcdTypesSet = new Set<String>();
            List<Object_Relationships__c> listRelObj = [select Id, Primary_Object_Rcd_Type_Id__c
                                               from Object_Relationships__c
                                               where IsActive__c = true
                                               and Primary_Object_API_name__c = 'Opportunity'];
            for (Object_Relationships__c orc: listRelObj)
            {  optyRcdTypesSet.add(orc.Primary_Object_Rcd_Type_Id__c);  }
        }  
        */ 
        return optyRcdTypesSet;
    } // getObjRelOptyRcdTypes       

   private static Set<String> retrieveOpptyRecTypes() {
      Set<String> v_optyRcdTypesSet = new Set<String>();
      for (Object_Relationships__c objRel : [select Id, Primary_Object_Rcd_Type_Id__c
                                               from Object_Relationships__c
                                               where IsActive__c = true
                                               and Primary_Object_API_name__c = :ObjectHelper.OBJECT_OPPTY
                                               and Primary_Object_Rcd_Type_Id__c != null]) {
         v_optyRcdTypesSet.add(objRel.Primary_Object_Rcd_Type_Id__c); 
      } // for (Object_Relationships__c listRelObj
      return v_optyRcdTypesSet;
   } // retrieveOpptyRecTypes      
       
          
    public static void processSObjects(String objName, SObject[] triggerRcds) {
                
        SObjectHelper soHelper = new SObjectHelper();
        Map<String, List<Sobject>> mapRcdsInsert = new Map<String, List<SObject>>();    // list of rcds to be inserted by object
        Map<String, List<Sobject>> mapRcdsInsertWithoutAR = new Map<String, List<SObject>>();  //list of rcds that will not use assignment rules to be inserted by object
        Map<Id, Set<Id>> mapFoundCases = new Map<Id, Set<Id>>();                        // list of existing cases by opportunity ids, only used if objName = Opportunity 
        
        // gather incoming record types  
        Set<Id> setTrigRcdTypeIds = new Set<Id>();        
        for (SObject trig : triggerRcds)
        {   setTrigRcdTypeIds.add((Id)trig.get('RecordTypeId'));    }                
        mapRelatedObjs = getRelationships(setTrigRcdTypeIds);
        // is there anything to do?
        if (mapRelatedObjs.size() == 0)
        {   System.debug('**CMF ** createRelatedObj nothing to do!');
            return; }

        // create list of trigger record ids that need related object created
        List<Id> listTrigIds = New List<Id>();
        for (SObject trig : triggerRcds)
        {   if (mapRelatedObjs.containsKey((Id)trig.get('RecordTypeId')))
            {   listTrigIds.add(trig.Id);   }
        }

        // create set of existing cases for each opportunity
        if (objName == 'Opportunity')
        {   mapFoundCases = getKases(listTrigIds);  }
        
        // map contact ids to the opportunity ids
        opptyCtctMap = getContactIds(listTrigIds);
      
        // build and run query to get all fields needed for related object and filter criteria
        List<SObject> sObjs = buildSOQL(objName, listTrigIds);
        System.debug('**CMF ** returnrcds from buildSOQL size='+sObjs.size());
        
        Id svPrimaryRcdTypeId = null;       
        Object_Relationships__c[] listsvObjRel = null;
        String svObject = null;
        Database.DMLOptions dmo = new Database.DMLOptions(); 
        Database.DMLOptions dmoWithoutAR = new Database.DMLOptions();
        system.debug('jc sObjs' +sObjs); 
        for (SObject so : sObjs)
        {   // if first time thru or primary recordtype changes get new object relationships                     
             system.debug('jc svPrimaryRcdTypeId' +svPrimaryRcdTypeId); 

            if (svPrimaryRcdTypeId  == null || svPrimaryRcdTypeId != so.get('RecordTypeId'))
            {   svPrimaryRcdTypeId = (String)so.get('RecordTypeId');
              system.debug('jc svPrimaryRcdTypeId' +svPrimaryRcdTypeId); 

                listsvObjRel = mapRelatedObjs.get(svPrimaryRcdTypeId);              			

            }
          
             system.debug('jc listsvObjRel.size' + (listsvObjRel!=null ? listsvObjRel.size() : -1)); 

            for (Object_Relationships__c svObjRel: listsvObjRel)
            {   // if working on opportunties, check to see if is opty already has a case of related object record type so we don't create dups
                if (objName == 'Opportunity')
                {   Set<Id> setCases = mapFoundCases.get(so.Id);
                 system.debug('jc setCases  ' +setCases ); 
                 system.debug('jc svObjRel.Related_Object_Rcd_Type_Id__c ' +svObjRel.Related_Object_Rcd_Type_Id__c); 
                 
                 system.debug('jc setCases.contains(svObjRel.Related_Object_Rcd_Type_Id__c ' + ((setCases != null) && setCases.contains(svObjRel.Related_Object_Rcd_Type_Id__c))); 

                    if (setCases != null && setCases.contains(svObjRel.Related_Object_Rcd_Type_Id__c))
                    {   continue;   }                   
                }
                System.debug('**CMF ** related rcd type='+svObjRel.Related_Object_Rcd_Type__c);             
                svObject = svObjRel.Related_Object_API_name__c;     // save name of related object being created
                Boolean meetFilter = checkFilter(svObjRel, so);
                System.debug('**CMF ** meetFilter='+meetFilter);
                if (!meetFilter)
                {   continue;   }
            
                system.debug('aar: '+svObjRel.Avoid_Assignment_Rules__c);
                if (!Test.isRunningTest() && !svObjRel.Avoid_Assignment_Rules__c) {  
                    dmo.assignmentRuleHeader.useDefaultRule=true; 
                    dmo.EmailHeader.TriggerUserEmail=true;
                    dmo.optAllOrNone=true;                                // stop if any record has errors
                    SObject newRelObj = buildRelObj(svObjRel, so);              
                    List<SObject> tempList = mapRcdsInsert.get(svObject);
                    if (tempList == null)
                    {   tempList = new List<SObject>();
                        mapRcdsInsert.put(svObject, tempList);
                    }
                    tempList.add(newRelObj);
                    System.debug('**CMF ** newRelObj='+newRelObj); 
                }
                else{
                    dmoWithoutAR.assignmentRuleHeader.useDefaultRule=false; 
                    dmoWithoutAR.optAllOrNone=true;                                // stop if any record has errors
                    SObject newRelObj = buildRelObj(svObjRel, so);              
                    List<SObject> tempList = mapRcdsInsertWithoutAR.get(svObject);
                    if (tempList == null)
                    {   tempList = new List<SObject>();
                        mapRcdsInsertWithoutAR.put(svObject, tempList);
                    }
                    tempList.add(newRelObj);
                    System.debug('**CMF ** newRelObj='+newRelObj); 
                }
            
            } // for(Object_Relationships__c svObjRel)
        } // for(SObject so
                    
          
        Set<String> setObjInsert = mapRcdsInsert.keySet();
        for (String obj : setObjInsert)
        {     List<SObject> insertList = mapRcdsInsert.get(obj);
              System.debug('**CMF ** inserting records, size='+insertList.size());
              try {                                
                database.insert(insertList, dmo);
              }
              catch (Exception e) {
                System.debug('**CMF ** insert exception='+e.getMessage());
                throw e;
              }
        } // for setObjInsert
        
        Set<String> setObjInsertWithoutAR = mapRcdsInsertWithoutAR.keySet();
        for (String obj : setObjInsertWithoutAR)
        {     List<SObject> insertListWithoutAR = mapRcdsInsertWithoutAR.get(obj);
              System.debug('**CMF ** inserting records, size='+insertListWithoutAR.size());
              
              for(SObject so: insertListWithoutAR){
                system.debug(so.getOptions());
              }
              try {                                
                database.insert(insertListWithoutAR,dmoWithoutAR);
              }
              catch (Exception e) {
                System.debug('**CMF ** insert exception='+e.getMessage());
                throw e;
              }
        } // for setObjInsert
        
        return;
        
    } // processSObjects


    // check if trigger record meets any filter criteria defined in Object Relationship Field records
    private static Boolean checkFilter(Object_Relationships__c svObjRel, SObject so)
    {   Boolean meetFilter = true;      
        for (Object_Relationships_Fields__c orf: svObjRel.Object_Relationships_Fields__r)
        {   if (orf.isFilter__c)
            {   Set<String> critValues = new Set<String>(); 
                List<String> critList = new List<String>();
                critList = orf.FilterCriteria__c.split(',');
                for (String crit : critList)
                {   critValues.add(crit.trim()); }                                                
                String trigValue = null;
                if (orf.Primary_Object_API_name__c == svObjRel.Primary_Object_API_name__c)              
                {   trigValue = (String)so.get(orf.Primary_Field_API_name__c);    }
                else    // this is used when filter data on object related to primary object (ex-Case.Opportunity__r.Service_Location__c) 
                {   String s = orf.Primary_Relationship_API_name__c == null ? orf.Primary_Object_API_name__c : orf.Primary_Relationship_API_name__c.replace('__c','__r');
                    SObject a = (SObject)so.getSObject(s);
                    if (a != null)
                    {   if (orf.Primary_Field_API_name__c.contains('.'))                                
                        {   SObject b =(SObject)a.getSObject(orf.Primary_Field_API_name__c.substringBefore('.'));
                            if  (b != null)
                            {   trigValue = (String)b.get(orf.Primary_Field_API_name__c.substringAfter('.'));   }
                        }
                        else                                                              
                        {   trigValue = (String)a.get(orf.Primary_Field_API_name__c);   }
                    } // a!=null
                } // else                
                trigValue = (trigValue == null ? trigValue : trigValue.trim());                                
                if (critValues.size() == 1)
                {   if (critValues.contains('null'))
                    {   if (trigValue != null)
                        {   meetFilter = false; }
                    }
                    else if (critValues.contains('not null'))
                    {   if (trigValue == null || trigValue.length() == 0)
                        {   meetFilter = false;  }
                    }
                    else if (!critValues.contains(trigValue))
                    {   meetFilter = false;  }
                }
                else
                {   if (!critValues.contains(trigValue))
                    {   meetFilter = false; }
                }
            } // isFilter__c
        } // for orf     
           
        return meetFilter;
    } // checkFilter
    
    
    // build related object
    private static SObject buildRelObj(Object_Relationships__c svObjRel, SObject so)
    {   // create related object
        Schema.SObjectType relatedType = Schema.getGlobalDescribe().get(svObjRel.Related_Object_API_name__c);       
        SObject newRelObj = relatedType.newSObject();           

        // set record type
        //if (svObjRel.Related_Object_Rcd_Type_Id__c != null)        
        if (svObjRel.Related_Object_Rcd_Type__c != 'Master')
        {   newRelObj.put('RecordTypeId', svObjRel.Related_Object_Rcd_Type_Id__c);  }
            
        // if creating case from opportunity fill in contactId
        if (svObjRel.Primary_Object_API_name__c == 'Opportunity' && svObjRel.Related_Object_API_name__c == 'Case')
        {   newRelObj.put('ContactId', opptyCtctMap.get(so.Id));    }

        // populate any other fields
        for (Object_Relationships_Fields__c orf : svObjRel.Object_Relationships_Fields__r)
        {   if (!orf.IsFilter__c)
            {   if (orf.Field_Constant__c != null)
                {   if (orf.Primary_Field_type__c == 'BOOLEAN')
                    {   newRelObj.put(orf.Related_Field_API_name__c, Boolean.valueOf(orf.Field_Constant__c));   }
                    else if (orf.Primary_Field_type__c == 'STRING')
                    {   newRelObj.put(orf.Related_Field_API_name__c, String.valueOf(orf.Field_Constant__c));    }
                    else if (orf.Primary_Field_type__c == 'DOUBLE')
                    {   newRelObj.put(orf.Related_Field_API_name__c, Decimal.valueOf(orf.Field_Constant__c));  }
                    else if (orf.Primary_Field_type__c == 'ID')
                    {   newRelObj.put(orf.Related_Field_API_name__c, ID.valueOf(orf.Field_Constant__c));  }
                } // if field_constant 
                else if (orf.Queue_Id__c != null)                                                           // move queue id
                {    newRelObj.put(orf.Related_Field_API_name__c, orf.Queue_Id__c);     }           
                else if (orf.Primary_Object_API_name__c == svObjRel.Primary_Object_API_name__c)             // moving primary object data into related object
                //  {   newRelObj.put(orf.Related_Field_API_name__c, so.get(orf.Primary_Field_API_name__c));    }
                {   if (orf.Primary_Field_API_name__c.contains('.'))                                        // originally put in for owner.managerid into dsm__c
                    {   SObject b =(SObject)so.getSObject(orf.Primary_Field_API_name__c.substringBefore('.'));
                        if  (b != null)
                        {   newRelObj.put(orf.Related_Field_API_name__c, b.get(orf.Primary_Field_API_name__c.substringAfter('.'))); }
                    }                    
                    else                                                              
                    {   newRelObj.put(orf.Related_Field_API_name__c, so.get(orf.Primary_Field_API_name__c)); }
                }                                 
                else                                                                                        // move primary related object data (ex-Case.Account.Id) into related object
                {   String s = orf.Primary_Relationship_API_name__c == null ? orf.Primary_Object_API_name__c : orf.Primary_Relationship_API_name__c.replace('__c','__r');
                    SObject a = (SObject)so.getSObject(s);
                    if (a != null)
                    {   if (orf.Primary_Field_API_name__c.contains('.'))                                        // originally put in for owner.managerid into dsm__c
                        {   SObject b =(SObject)a.getSObject(orf.Primary_Field_API_name__c.substringBefore('.'));
                            if  (b != null)
                            {   newRelObj.put(orf.Related_Field_API_name__c, b.get(orf.Primary_Field_API_name__c.substringAfter('.'))); }
                        }
                        else                                                              
                        {   newRelObj.put(orf.Related_Field_API_name__c, a.get(orf.Primary_Field_API_name__c)); }
                    } // a!=null
                } // else
            } // !IsFilter__c            
        } // for object_relationships_fields__c
        
        return newRelObj;
    } // buildRelObj
    
    
   // currently assumes you are using the record type id of primary object and not the opportunity line item to determine related object being created
   private static Map<Id, Object_Relationships__c[]> getRelationships(Set<Id> setRcdTypeIds)
   {    List<Object_Relationships__c> listRelObj = [select Id
                                                        , Primary_Object_API_name__c
                                                        , Primary_Object_Rcd_Type_Id__c
                                                        , Primary_Object_Rcd_Type__c
                                                        , Related_Object_API_name__c
                                                        , Related_Object_Rcd_Type_Id__c
                                                        , Related_Object_Rcd_Type__c
                                                        , Avoid_Assignment_Rules__c
                                                        , (select Id 
                                                            , Primary_Field_Object__c
                                                            , Primary_Field__c
                                                            , Primary_Field_API_name__c
                                                            , Primary_Field_type__c
                                                            , Primary_Object_API_name__c
                                                            , Primary_Relationship_API_name__c
                                                            , Related_Field__c
                                                            , Related_Field_API_name__c
                                                            , Field_Constant__c
                                                            , Queue__c
                                                            , Queue_Id__c 
                                                            , IsFilter__c
                                                            , FilterCriteria__c                                                          
                                                            from Object_Relationships_Fields__r)
                                                        from Object_Relationships__c
                                                        where IsActive__c = true
                                                        and Primary_Object_Rcd_Type_Id__c in :setRcdTypeIds];
                                                        
        Map<Id, Object_Relationships__c[]> tempMap = new Map<Id, Object_Relationships__c[]>();
        for (Object_Relationships__c orc: listRelObj)
        {   List<Object_Relationships__c> listORC = tempMap.get(orc.Primary_Object_Rcd_Type_Id__c);     // need list incase 1 primary creates >1 related
            if (listORC == Null)
            {   listORC = new List<Object_Relationships__c>();
                tempMap.put(orc.Primary_Object_Rcd_Type_Id__c, listORC);
            }
            listORC.add(orc);    
        }
        
        return tempMap;
        
   } // getAllRelationships  

   // build and run query pulling in all fields for all record types of primary object
   private static List<SObject> buildSOQL (String obj, List<Id> objIds) {
        Set<String> soqlFlds = new Set<String>();
        
        // read thru relationship map to get field relationships
        Set<Id> tempRcdTypeId = mapRelatedObjs.keySet();
        for (Id rtId : tempRcdTypeId)
        {   Object_Relationships__c[] listOrc = mapRelatedObjs.get(rtId);
            for (Object_Relationships__c  orc: listOrc)
            {   for (Object_Relationships_Fields__c orf: orc.Object_Relationships_Fields__r)
                {   if (orf.Field_Constant__c == null && orf.Queue_Id__c == null)
                    {   if (orc.Primary_Object_API_name__c == orf.Primary_Object_API_name__c && orf.Primary_Relationship_API_name__c == null)
                        {   soqlFlds.add(orf.Primary_Field_API_name__c.toUpperCase());    }
                        if (orc.Primary_Object_API_name__c != orf.Primary_Object_API_name__c && orf.Primary_Relationship_API_name__c == null)
                        {   soqlFlds.add(orf.Primary_Object_API_name__c.toUpperCase() + '.' + orf.Primary_Field_API_name__c.toUpperCase());     }       
                        if (orf.Primary_Relationship_API_name__c != null)
                        {   String s = orf.Primary_Relationship_API_name__c.replace('__c','__r');       
                            soqlFlds.add(s.toUpperCase() + '.' + orf.Primary_Field_API_name__c.toUpperCase());  
                        }
                    } // if Field_Constant__c                   
                } // for orf
            } // for orc
        } // for rtId
                
        String soqlstmt = 'Select RecordType.Name, RecordTypeId, ';        
        for (String sfld : soqlFlds)
        {   soqlstmt = soqlstmt + sfld + ',';   }
        soqlstmt = soqlstmt.subString(0, soqlstmt.Length() -1);
        soqlstmt = soqlstmt + ' From ' + obj + ' Where Id in :objIds order by RecordTypeId';
        System.debug('**CMF ** soqlstmt='+soqlstmt);
        SObject[] returnRecords;
        try {
            returnRecords = Database.query(soqlstmt);
            // System.debug('**CMF ** returnRecords size='+returnRecords.size());          
        }        
        catch (QueryException e1) {
            System.debug('**CMF ** bad soql statement='+soqlstmt +', '+e1.getMessage());
/*            Process_Log__c log = new Process_Log__c(Process_Name__c = 'CreateRelatedObjects'
                                                    , Status__c = 'Failure'
                                                    , Short_Note__c = 'built bad soql'
                                                    , Notes__c = e1.getMessage());
            insert log;
*/            
            throw e1;       // throwing this exception will roll back log rcd insert!           
        }        
        return returnRecords;                                                            
   } // buildSOQL


    // define my own exception so we have something to throw back
    public class InsertException extends Exception {}


    //  Methods to get contacts for Opportunity to Case process 
   /** Attempt to retrieve the contact ids for the opportunities. */
   private static Map<Id,Id> getContactIds(Id[] opptyIds) {
      Map<Id,Id> tempOpptyCtctMap = new Map<Id,Id>();   
      // check for a primary contact      
      findContactIds(opptyIds,tempOpptyCtctMap);
      return tempOpptyCtctMap;
   } // getContactIds
   
   /** Search through the results and attempt to match up to incoming list.  */
   private static void findContactIds(Id[] opptyIds, Map<Id,Id> tempOpptyCtctMap) {
      List<OpportunityContactRole> ocrs = queryContactIds(opptyIds);
      for (OpportunityContactRole ocr : ocrs) {
         // only put in the first contact found for each opportunity
         if (!tempOpptyCtctMap.containsKey(ocr.OpportunityId)) {
            tempOpptyCtctMap.put(ocr.OpportunityId,ocr.ContactId);            
         }
      } // for (OpportunityContactRole ocr
   } // findContactIds

   /* Perform the query to retrieve the contact ids.  */
   private static List<OpportunityContactRole> queryContactIds(Id[] opptyIds) {
      // ordering by OpportunityId Asc - keeps all of the same opportunities together.
      // ordering by IsPrimary desc - lists the true before false.
      List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>([Select Id, ContactId, OpportunityId, IsPrimary from OpportunityContactRole
                                        where OpportunityId IN :opptyIds
                                        order by OpportunityId asc, IsPrimary desc]);                              
      return ocrs;
   } // queryContactIds
 
   private static Map<Id, Set<Id>> getKases(Id[] trigIds) {
      List<Case> listKases = [Select Id, RecordTypeId, Opportunity__c from Case 
                                where Opportunity__c in :trigIds
                                order by Opportunity__c];
      Map<Id, Set<Id>> tempMap = new Map<Id, Set<Id>>();                // getting set of existing case record types by opportunity id
      for (Case kase:listKases)
      {   Set<Id> kaseRTs = tempMap.get(kase.Opportunity__c);
          if (kaseRTs == null)
          {   kaseRTs = new Set<Id>();
              tempMap.put(kase.Opportunity__c,kaseRTs);
          }
          kaseRts.add(kase.RecordTypeId);
      }
      
      return tempMap;
      
   } // getKases
    
 
}