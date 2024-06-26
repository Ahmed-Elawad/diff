/* 
 * Batch process to update the picklist values.
 *
 * History
 * -------
   04/10/2018 Mike Matonis       Created
   07/17/2018 Dan Carmen         Add additional fields to the queries

 */
global class PicklistDetailUpdateBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
   
   public static String CLASS_NAME='PicklistDetailUpdateBatch';
	
	// default query for the batch
	global String query = 'SELECT Id, Name, DeveloperName, SObjectType FROM RecordType WHERE SObjectType = \'Task\' OR SObjectType = \'Event\'';
	
	// the number of record types processed in the batch
	global Integer nbrRecordTypes = 0;
	// the number of picklist detail records updated
	global Integer nbrPicklistDetails = 0;
   // messages that occur during the process.
   global String processNotes = '';

	global String[] recordTypesToAnalyze = null;
	global Set<String> recordTypeNameSet = null;
	
   global JobHelper jh = new JobHelper(CLASS_NAME);

   global PicklistDetailUpdateBatch() {
   }

	global PicklistDetailUpdateBatch(String query) {
		this.query = query;
	}

   // so we can pass in the query we want used in this batch process
	global PicklistDetailUpdateBatch(String query, String[] recordTypesToAnalyze) {
		this.query = query;
		this.recordTypesToAnalyze = recordTypesToAnalyze;
		//System.debug('PicklistDetailUpdateBatch query='+query);
      //System.debug('PicklistDetailUpdateBatch recordTypesToAnalyze='+recordTypesToAnalyze);
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
      jh.setStarted();
      processNotes = 'query='+query;
      processNotes += '\n recordTypesToAnalyze='+recordTypesToAnalyze;
      if (recordTypesToAnalyze != null && !recordTypesToAnalyze.isEmpty()) {
         recordTypeNameSet = new Set<String>();
         recordTypeNameSet.addAll(recordTypesToAnalyze);
      }
      processNotes += '\nrecordTypeNameSet='+(recordTypeNameSet != null ? recordTypeNameSet.size() : -1);
      System.debug('processNotes='+processNotes);
		return Database.getQueryLocator(query);
	} // start

   global void execute(Database.BatchableContext BC, List<sObject> scope) {
      nbrRecordTypes += scope.size();
	   updatePicklistDetailsFromCallout((List<RecordType>) scope);
	}
	
	global void updateNotFound() {
      PicklistDetail__c[] notFoundRecs = [Select Id, Developer_Name__c, Error__c, NbrPicklistValues__c, PicklistData__c
                                                   ,Process__c, ProcessNotes__c, RecordTypeId__c, ValuesLastUpdated__c
                                               From PicklistDetail__c
                                              Where Developer_Name__c in :recordTypeNameSet];
      for (PicklistDetail__c pd : notFoundRecs) {
         pd.Error__c=true;
         pd.NbrPicklistValues__c=null;
         pd.PicklistData__c=null;
         pd.Process__c=false;
         pd.RecordTypeId__c=null;
         pd.ValuesLastUpdated__c=Datetime.now();
         PicklistDetailCalloutHelper.addToProcessNotes(pd,'Could not find RecordType info for this!');
      }
      PicklistHelperDataAccessor.upsertPicklistDetails(notFoundRecs);
	} // updateNotFound
	
	global void finish(Database.BatchableContext BC) {
	   String message = '\nRecord Types processed: '+ nbrRecordTypes+' ';
      message += '\nNbr PicklistDetail__c records upserted: '+nbrPicklistDetails;
      message += '\nrecordTypeNameSet='+(recordTypeNameSet != null ? recordTypeNameSet.size() : -1);
      if (recordTypeNameSet != null && !recordTypeNameSet.isEmpty()) {
         message += '\n';
         for (String recordTypeName : recordTypeNameSet) {
            message+= '\nCould not update '+recordTypeName;
         }
         updateNotFound();
      } // if (recordTypeNameSet != null
      message += '\n\n'+processNotes;
      system.debug('message:'+message);
      jh.completeJob(bc, 'PicklistDetailUpdateBatch process', message);
	} // finish

	private void updatePicklistDetailsFromCallout(RecordType[] recordTypes){
		PicklistDetailCalloutHelper.activityRecordTypes = recordTypes;
		System.debug('updatePicklistDetailsFromCallout recordTypes='+recordTypes);
		Map<String, PicklistDetail__c[]> rtDevNameToPkDetails = getRTtoPicklistDetailMap(recordTypes);
      System.debug('updatePicklistDetailsFromCallout rtDevNameToPkDetails='+rtDevNameToPkDetails.size());
      
		PicklistDetail__c[] pkDetailsToUpsert = new List<PicklistDetail__c>();
		for(RecordType rt : recordTypes){
         if (recordTypeNameSet != null) {
            recordTypeNameSet.remove(rt.DeveloperName);
         }
			PicklistDetail__c[] existingPkDetails = rtDevNameToPkDetails.get(rt.DeveloperName) != null ? rtDevNameToPkDetails.get(rt.DeveloperName) : new PicklistDetail__c[]{};
			// get the names of the picklist fields we'll be using.
			String[] picklistFieldNames = PicklistDetailCalloutHelper.getActivityPicklistFields(rt);
			// get a map of all of the picklist detail fields, the key is the field name.
			// new records will be created if one for the field does not already exist.
			Map<String, PicklistDetail__c> fieldToPicklistDetail = PicklistHelper.getFieldsToPicklistDetailRecords(rt, picklistFieldNames, existingPkDetails);

         PicklistDetail__c[] changedDetails = PicklistDetailCalloutHelper.getPicklistDetailsWithCallout(rt, fieldToPicklistDetail);
         processNotes += '\nRecordType='+rt.Name+' existing details='+existingPkDetails.size()+' total changed='+changedDetails.size();
			pkDetailsToUpsert.addAll(changedDetails);
		}

      nbrPicklistDetails += pkDetailsToUpsert.size();
		PicklistHelperDataAccessor.upsertPicklistDetails(pkDetailsToUpsert);
	} // updatePicklistDetailsFromCallout

   // create a map of the record types by the developer name - existing records
	private Map<String, PicklistDetail__c[]> getRTtoPicklistDetailMap(RecordType[] recordTypes){
		String[] recordTypeDeveloperNames = getDeveloperNamesFromRecordTypes(recordTypes);
		PicklistDetail__c[] picklistDetails = PicklistHelperDataAccessor.getPicklistDetailsFromRTDeveloperNames(recordTypeDeveloperNames);
		Map<String, PicklistDetail__c[]> developerNameToPicklistDetails = getDeveloperNameToPicklistDetails(picklistDetails);
		return developerNameToPicklistDetails;
	} // getRTtoPicklistDetailMap

   // return a list of all of the developer names of the record types
	private String[] getDeveloperNamesFromRecordTypes(RecordType[] recordTypes){
		String[] recordTypesToAnalyze = new String[]{};
        for (RecordType rt : recordTypes) {
            recordTypesToAnalyze.add(rt.DeveloperName);
        }
        return recordTypesToAnalyze;
	} // getDeveloperNamesFromRecordTypes


	private Map<String, PicklistDetail__c[]> getDeveloperNameToPicklistDetails(PicklistDetail__c[] picklistDetails){

		Map<String, PicklistDetail__c[]> devNameToPkDetails = new Map<String, PicklistDetail__c[]>();
		for(PicklistDetail__c pkDetail : picklistDetails){
			if(devNameToPkDetails.containsKey(pkDetail.Developer_Name__c)){
				devNameToPkDetails.get(pkDetail.Developer_Name__c).add(pkDetail);
			}else{
				devNameToPkDetails.put(pkDetail.Developer_Name__c, new PicklistDetail__c[]{pkDetail});
			}
		}
		return devNameToPkDetails;
	} // getDeveloperNameToPicklistDetails
	
} // class PicklistDetailUpdateBatch