/* 
 * Methods to help with PicklistDetail__c queries
 *
 * History
 * -------
   04/10/2018 Mike Matonis       Created
   07/17/2018 Dan Carmen         Add additional fields to the queries

 */
public with sharing class PicklistDetailCalloutHelper {
	
	public static String sessionIdFromVFPage = getSessionIdFromVFPage();
	public static List<RecordType> activityRecordTypes = null;

	public static final Integer PICKLISTDATA_SIZE = PicklistDetail__c.PicklistData__c.getDescribe().getLength();
	public static final Integer PROCESS_NOTES_SIZE = PicklistDetail__c.ProcessNotes__c.getDescribe().getLength();

	public static String TASK_PICKLIST_FIELD_NAMES = Label.Create_Activity_Task_Picklists;
	public static String EVENT_PICKLIST_FIELD_NAMES = Label.Create_Activity_Event_Picklists;


	public static PicklistDetail__c[] getPicklistDetailsWithCallout(RecordType rt, Map<String, PicklistDetail__c> fieldToPicklistDetail){
      activityRecordTypes = new RecordType[]{rt};
		Map<String,PicklistDetailWrapper> wrapperMap = getPicklistDetailWrapperMap(fieldToPicklistDetail.values());

		try{
			attemptPicklistDetailCallouts(wrapperMap, sessionIdFromVFPage);
		}catch(Exception e){
			System.debug('Callout Error: ' + e);
			// TODO - mark all details with an error
		}

		PicklistDetail__c[] picklistDetailsToUpsert = new PicklistDetail__c[]{};
		for (PicklistDetailWrapper pkWrap : wrapperMap.values()) {
			picklistDetailsToUpsert.addAll(pkWrap.detailByFldMap.values());
		}

		return picklistDetailsToUpsert;
	}

   // create a map of PicklistDetailWrapper objects.
	private static Map<String,PicklistDetailWrapper> getPicklistDetailWrapperMap(PicklistDetail__c[] pkDetails) {

		Map<String,PicklistDetailWrapper> wrapperMap = new Map<String,PicklistDetailWrapper>();

		for (PicklistDetail__c pkDetail : pkDetails) {
			pkDetail.Process__c=false;
			PicklistDetailWrapper newWrapper = new PicklistDetailWrapper(pkDetail);
			PicklistDetailWrapper checkWrapper = wrapperMap.get(newWrapper.getKey());
			// wrappers are unique for an object-record type name combination
			if (checkWrapper != null) {
				checkWrapper.addDetail(pkDetail);
			} else {
				wrapperMap.put(newWrapper.getKey(), newWrapper);
			}
		} 

		return wrapperMap;
	} // getPicklistDetailWrapperMap


	public static void attemptPicklistDetailCallouts(Map<String,PicklistDetailWrapper> wrapperMap, String sessionId) {
	   // get a map where the key is just the record type name (wrapper map has a key <object><recordTypeName>)
		Map<String,PicklistDetailWrapper> recordTypeNameMap = createRecordTypeToWrapperMap(wrapperMap);
		setActivityRecordTypes(recordTypeNameMap.keySet());

      system.debug('attemptPicklistDetailCallouts activityRecordTypes='+activityRecordTypes.size());
		for (RecordType rt : activityRecordTypes) {
			PicklistDetailWrapper pkWrap = recordTypeNameMap.remove(rt.Name);
			if (pkWrap != null) {
				pkWrap.setRecordType(rt);
				System.debug('attemptPicklistDetailCallouts rt='+rt+' sessionId='+sessionId);
				// call the metadata api to get the actual data
				processRecord(pkWrap, sessionId);
			}
		} // for (RecordType rt

		setErrorOnPicklistDetailWrappers(recordTypeNameMap.values());
	} 


	private static void setErrorOnPicklistDetailWrappers(PicklistDetailWrapper[] pkDetailWrapper){
		for (PicklistDetailWrapper pkWrap : pkDetailWrapper) {
			pkWrap.setError(true,'Could not find RecordType for '+pkWrap.recordTypeName);
		}
	}

	private static void setActivityRecordTypes(Set<String> recordTypeNames){
		if(activityRecordTypes == null){
			activityRecordTypes = RecordTypeDataAccessor.getRecordTypesByNames(recordTypeNames);
		}
	}

   // Replaces the key (object-recordtypename) with just recordTypeName
	private static Map<String, PicklistDetailWrapper> createRecordTypeToWrapperMap(Map<String,PicklistDetailWrapper> wrapperMap){
		Map<String,PicklistDetailWrapper> recordTypeToWrapper = new Map<String,PicklistDetailWrapper>();
		for (PicklistDetailWrapper pkWrap : wrapperMap.values()) {
			recordTypeToWrapper.put(pkWrap.recordTypeName, pkWrap);
		}
		return recordTypeToWrapper;
	}

	private static void processRecord(PicklistDetailWrapper pkWrap, String sessionId) {
		pkWrap.setError(false, null);
		pkWrap.addToAllProcessNotes('Start picklist retrieval');
		SelectOptionWrapper[] options = PicklistDetailMetadataServiceCallout.getDependentPicklistOptionsCallout(pkWrap.objectName, pkWrap.fieldNames, pkWrap.rt.DeveloperName, null, sessionId);
		setPicklistData(pkWrap, options);
		pkWrap.addToAllProcessNotes('End picklist retrieval');
	} 

   // all picklist fields managed by the record type should be set here.
	private static void setPicklistData(PicklistDetailWrapper pkWrap, SelectOptionWrapper[] options) {

		Map<String,String[]> optionsByFldMap = new Map<String,String[]>();
		for (SelectOptionWrapper sow : options) {
			String[] pkOptions = (optionsByFldMap.containsKey(sow.picklistName) ? optionsByFldMap.get(sow.picklistName) : new String[]{});
			pkOptions.add(sow.label);
			optionsByFldMap.put(sow.picklistName, pkOptions);
		}
		
		// pull all of the values into a local map so we can find any not being set by the record type
		Map<String,PicklistDetail__c> localFldMap = pkWrap.detailByFldMap.clone();

		for (String picklistFld : optionsByFldMap.keySet()) {
			String[] pkOptions = optionsByFldMap.get(picklistFld);
			//PicklistDetail__c pkDetail = pkWrap.detailByFldMap.get(picklistFld);
         PicklistDetail__c pkDetail = localFldMap.remove(picklistFld);
			if (pkOptions != null && pkDetail != null) {
				pkDetail.NbrPicklistValues__c = pkOptions.size();
				pkDetail.Error__c=false;
				pkDetail.PicklistData__c = concatOptions(pkOptions).left(PICKLISTDATA_SIZE);
				pkDetail.ValuesLastUpdated__c = Datetime.now();
				addToProcessNotes(pkDetail,'Set '+pkOptions.size()+' picklist values');
			}
		} // for (String picklistFld
		
		if (!localFldMap.isEmpty()) {
		   // anything left here wasn't set by the record type - so we want to mark the PicklistDetail__c record accordingly
		   for (PicklistDetail__c pkDetail : localFldMap.values()) {
            pkDetail.NbrPicklistValues__c = 0;
            pkDetail.Error__c=false;
            pkDetail.PicklistData__c = null;
            pkDetail.ValuesLastUpdated__c = Datetime.now();
            addToProcessNotes(pkDetail,'No picklist values found for this field and record type!');
		   }
		} // if (!localFldMap.isEmpty
	} // setPicklistData



	public static String concatOptions(String[] options) {
		String returnVal = '';
		for (String option : options) {
			if (String.isNotBlank(returnVal)) {
				returnVal += PicklistHelper.TOKEN_KEY;
			}
			returnVal += option;
		}
		return returnVal;
	}  // concatOptions


	public static void addToProcessNotes(PicklistDetail__c pkDetail, String notesToAdd) {
		if (String.isNotBlank(notesToAdd)) {
			StringHelper.addNotesToField(pkDetail, 'ProcessNotes__c', PROCESS_NOTES_SIZE, notesToAdd, true);
		}
	} // addToProcessNotes


	public static String[] getActivityPicklistFields(RecordType rt){

		String[] fieldNames = new List<String>();
		if(rt.SobjectType == ObjectHelper.OBJECT_TASK){
			fieldNames.addAll(TASK_PICKLIST_FIELD_NAMES.split(','));
		}else if(rt.SobjectType == ObjectHelper.OBJECT_EVENT){
			fieldNames.addAll(EVENT_PICKLIST_FIELD_NAMES.split(','));
		}
		return fieldNames;
	}


	private static String getSessionIdFromVFPage(){
		if(sessionIdFromVFPage != null){
			return sessionIdFromVFPage;
		}else if(Test.isRunningTest()){
			return UserInfo.getUserId();
		}else{
			try{
				String content = Page.SessionIdVFPage.getContent().toString();
				return content.substring(content.indexOf(Label.Session_Id_VF_Page_Start) + Label.Session_Id_VF_Page_Start.length(), content.indexOf(Label.Session_Id_VF_Page_End));
			}catch(Exception e){
				return null;
			}
		}
	}


} // class PicklistDetailCalloutHelper