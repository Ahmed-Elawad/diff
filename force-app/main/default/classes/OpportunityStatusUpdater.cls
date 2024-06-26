/* 

  History
  -------
  03/24/2022 Dan Carmen          Cleaned up code, consolidated classes

 */
public with sharing class OpportunityStatusUpdater {


	public static Opportunity updateOpportunityStatusWithNewActivity(SObject activity){
		Opportunity opp = getOpportunityForActivity(activity);

		if(opp != null){

			Opportunity_Status_Update__mdt stageUpdateMD = getOpportunityUpdateMetadata(opp.RecordTypeId, activity);

			if(stageUpdateMD != null){
				opp = updateOpportunityStatus(opp, stageUpdateMD);
			}

		}

		return opp;
	} // updateOpportunityStatusWithNewActivity

	private static Opportunity updateOpportunityStatus(Opportunity opp, Opportunity_Status_Update__mdt stageUpdateMD){

		String newStageName = stageUpdateMD.Status__c;
		Decimal newStageProbability = getProbabilityForStage(newStageName);

		if(opp.Probability < newStageProbability){
			opp.StageName = newStageName;
			opp.Probability = newStageProbability;
			update opp;
		}

		return opp;
	} // updateOpportunityStatus

    private static Opportunity getOpportunityForActivity(SObject activity){
        Opportunity retVal = null;
        Id whatId = (Id) activity.get('WhatId');
        if (whatId != null && ((String)whatId).startsWith(ObjectHelper.PREFIX_OPPTY)) {
           List<Opportunity> oppForActivity = new OpportunityDA().getOpportunityById(whatId);
           if(!oppForActivity.isEmpty()){
        	   retVal = oppForActivity[0];
           }
       }
        return retVal;

    } // getOpportunityForActivity

    private static Opportunity_Status_Update__mdt getOpportunityUpdateMetadata(Id recordTypeId, SObject activity){
        Opportunity_Status_Update__mdt returnVal = null;
    	String activityType = (String) activity.get('Type');
        List<Opportunity_Status_Update__mdt> stageUpdatesMD = queryOpportunityUpdateMetadata(recordTypeId, activityType);
        if(!stageUpdatesMD.isEmpty()){
        	returnVal = stageUpdatesMD[0];
        }

        return returnVal;
    } // getOpportunityUpdateMetadata

    public static List<Opportunity_Status_Update__mdt> queryOpportunityUpdateMetadata(Id recordTypeId, String activityType){
        return [
            SELECT Id, Label, Status__c, RecordTypeId__c, Activity_Type__c
            FROM Opportunity_Status_Update__mdt
            WHERE Activity_Type__c = :activityType AND RecordTypeId__c = :recordTypeId
        ];
    } // queryOpportunityUpdateMetadata

	public static Map<String,Decimal> stageProbMap=null;

	public static void checkStageObjects(){
		if(stageProbMap == null){
            stageProbMap = new Map<String,Decimal>();
			OpportunityStage[] oppStageObjects =  [SELECT DefaultProbability, MasterLabel 
                                  FROM OpportunityStage
                                 WHERE IsActive = TRUE];
            for (OpportunityStage stage : oppStageObjects) {
               stageProbMap.put(stage.MasterLabel, stage.DefaultProbability);
            }
		}
	} // checkStageObjects

    public static Decimal getProbabilityForStage(String stage){
    	checkStageObjects();
        Decimal retValue = stageProbMap.get(stage);
    	return retValue;
    } // getProbabilityForStage



}