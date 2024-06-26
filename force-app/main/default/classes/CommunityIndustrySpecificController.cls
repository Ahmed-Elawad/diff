/*
* Controller for workers comp component in community forms
* 
* History
* ----------------------------------------
* 08/20/2021	Ahmed Elawad	Created
* 02/01/2022	Ahmed Elawad	SFDC-10790 APR APR0131036: update saveIndustrySpecific() to update WQ on every save
*/ 

public without sharing class CommunityIndustrySpecificController {
	
    @AuraEnabled      
    public static CommunityMethods.IndustrySpecificWrap getIndustryDetails(String PEOchecklist, String peoIndustryTitle, String formName){
        return CommunityMethods.getIndustryDetails(PEOchecklist, peoIndustryTitle, formName, 'CommunityIndustrySpecificController');
    }
    
    @AuraEnabled
    public static string getIndustrySpecificStatus(String PEOchecklist) {
        return CommunityMethods.getIndustrySpecificStatus(PEOchecklist);
    }
    
    @AuraEnabled
    public static WC_Questionnaire_Industry_Specific__c saveIndustrySpecific(WC_Questionnaire_Industry_Specific__c IndustryRec, String formName){
        if(IndustryRec!=null){
            try{
                Datetime current = System.now(); 
                Date currDate = current.date();
                Time currTime = current.time();
                Datetime local = datetime.newinstance(currDate,currTime);
                //if(action == 'Save and Submit')IndustryRec.Peo_IndSpecific_formSubmissionTime__c = local;
                if(IndustryRec.Peo_IndSpecific_formStatus__c == 'Complete' && IndustryRec.Peo_IndSpecific_formSubmissionTime__c == null)IndustryRec.Peo_IndSpecific_formSubmissionTime__c = local;
                
                upsert IndustryRec;
                
                //SFDC-10790 APR APR0131036        
                Set<Id> checklistIDstoCreateIndWQs = new Set<Id>();
                checklistIDstoCreateIndWQs.add(IndustryRec.PEO_Underwriting_Checklist__c);                
                if (!checklistIDstoCreateIndWQs.isEmpty()) communityMethods.createIndSpecificWQFuture(checklistIDstoCreateIndWQs);
                
                return IndustryRec;
            }catch(Exception e){
                communityMethods.logCommunityError(e, 'saveIndustrySpecific', 'CommunityIndustrySpecificController',formName, new List<WC_Questionnaire_Industry_Specific__c>{IndustryRec});
                return null;
            }
        }
        return null;
    }
    
    @AuraEnabled
    public static List<string> getIndustryNames(String[] naicsCodes) {
        WC_NAICS_To_Industry_Map__c[] wcNaicsCodes = [SELECT ID, Name, PEO_Industry_Title__c, Industry_Name__c, Required_With_WC_FastPass__c FROM WC_NAICS_To_Industry_Map__c where Name IN :naicsCodes];
        
        List<String> industryNames = new List<String>();
        for(WC_NAICS_To_Industry_Map__c wcMap : wcNaicsCodes) {
            if(wcMap.PEO_Industry_Title__c != null && wcMap.PEO_Industry_Title__c != '' && !industryNames.contains(wcMap.PEO_Industry_Title__c)) {
                industryNames.add(wcMap.PEO_Industry_Title__c);
            }
        }
        
        return industryNames;
    }
    
}