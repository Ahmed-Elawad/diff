/**
 *
 * check for valid data and fill in some fields before record is inserted or updated
 * History
 * -------
 * 3/7/2012	Cindy Freeman	created
 *
 */
		
	
trigger ObjectRelationshipsBefore on Object_Relationships__c (before insert, before update) {
	 ObjectHelper oHelper = new ObjectHelper();
	 
	 // create lists of object names
	 List<String> listPriObjects = new List<String>();
	 List<String> listRelObjects = new List<String>();
	 
	 for (Object_Relationships__c orc: Trigger.new)
	 {	if (orc.Primary_Object_API_name__c != null)	 	
	 	{	listPriObjects.add(orc.Primary_Object_API_name__c);	}
	 	if (orc.Related_Object_API_name__c != null)
	 	{	listRelObjects.add(orc.Related_Object_API_name__c);	}
	 }
 
	 //get map of all objects in list
	 Map<String,Boolean> validPriObjects = oHelper.doObjectsExist(listPriObjects);
	 Map<String,Boolean> validRelObjects = oHelper.doObjectsExist(listRelObjects);
	 
	 //get schema list of all record types for primary and related objects by record type name
	 Map<String,Schema.RecordTypeInfo> rcdPriTypesbyName = new Map<String,Schema.RecordTypeInfo>();
	 RecordTypeHelper.getRecordTypesMap(listPriObjects,null,rcdPriTypesbyName);
	 Map<String,Schema.RecordTypeInfo> rcdRelTypesbyName = new Map<String,Schema.RecordTypeInfo>();
	 RecordTypeHelper.getRecordTypesMap(listRelObjects,null,rcdRelTypesbyName);
	 
	 //are object names and record types valid?
	 for (Integer i = 0; i < Trigger.new.size(); i++ )
	 {	Object_Relationships__c orc = Trigger.new[i];
	 	Boolean ans = validPriObjects.get(orc.Primary_Object_API_name__c);
	 	if (!ans)
	 	{	Trigger.new[i].Primary_Object_API_name__c.addError('invalid Primary Object, please check your spelling and try again');	}
	 	ans = validRelObjects.get(orc.Related_Object_API_name__c);
	 	if (!ans)
	 	{	Trigger.new[i].Related_Object_API_name__c.addError('invalid Related Object, please check your spelling and try again');	}
	 		 	
	 	if (orc.Primary_Object_Rcd_Type__c != null)
	 	{	if (!rcdPriTypesbyName.containsKey(orc.Primary_Object_Rcd_Type__c)) 
	 		{	Trigger.new[i].Primary_Object_Rcd_Type__c.addError('invalid record type, please check your spelling and try again');	}
	 		else
      		{	Trigger.new[i].Primary_Object_Rcd_Type_Id__c = rcdPriTypesbyName.get(orc.Primary_Object_Rcd_Type__c).getRecordTypeId();	}	
	 	}
	 	if (orc.Related_Object_Rcd_Type__c != null)
	 	{	if (!rcdRelTypesbyName.containsKey(orc.Related_Object_Rcd_Type__c)) 
	 		{	Trigger.new[i].Related_Object_Rcd_Type__c.addError('invalid record type, please check your spelling and try again');	}
	 		else
      		{	Trigger.new[i].Related_Object_Rcd_Type_Id__c = rcdRelTypesbyName.get(orc.Related_Object_Rcd_Type__c).getRecordTypeId();	}	
	 	}
	 	else	// fill in default record type
	 	{	orc.Related_Object_Rcd_Type__c = RecordTypeHelper.getDefaultRecordType(orc.Related_Object_API_name__c).getName();
	 		orc.Related_Object_Rcd_Type_Id__c = RecordTypeHelper.getDefaultRecordType(orc.Related_Object_API_name__c).getRecordTypeId();
	 	}
	 	
	 	if (orc.Primary_Object_Rcd_Type__c == null && orc.Oppty_Line_Item__c == null)
	 	{	Trigger.new[i].Primary_Object_Rcd_Type__c.addError('you must specify either the Primary Object record type or the Opportunity Line Item.');	}
	 		 	
	 }
	
	 // if any change is made to the object relationship object clear the cache so it can be refreshed.
	 for (String cacheKey : CreateRelatedObjects2.CACHE_KEY_SET) {
	    Cache.Org.remove(cacheKey);
	 }
} //ObjectRelationshipBefore