/* 

  History
  -------
  03/22/2022 Dan Carmen          Cleaned up code

 */
public with sharing class ActivityRelatedListAuraService {
	
	@AuraEnabled
	public static DataEnvelope getOpenActivities(String recordId) {

		List<ActivityDA.ActivityCombined> activities = ActivityDA.getOpenActivities(recordId);

		DataEnvelope envelope = new DataEnvelope(activities);
		return envelope;
	} // getOpenActivities


	public class DataEnvelope{

		@AuraEnabled
		public List<ActivityDA.ActivityCombined> activities {get; set;}

		public DataEnvelope(List<ActivityDA.ActivityCombined> activities){
			this.activities = activities;
		}

	}
} // class ActivityRelatedListAuraService