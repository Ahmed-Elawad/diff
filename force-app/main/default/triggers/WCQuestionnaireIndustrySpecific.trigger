/* Trigger for WC Questionnaire Industry Specific object
*
*   HISTORY
*  ---------
*   08/12/2021  Matt Fritschi     Created
*	11/01/2021	Matt Fritschi	Runs on after update.
*	02/14/2022	Ahmed Elawad	Added After delete trigger
*/
trigger WCQuestionnaireIndustrySpecific on WC_Questionnaire_Industry_Specific__c (before insert, before update, after insert,after update, after delete) {
    System.debug('MGF WCQuestionnaireIndustrySpecific Trigger.isAfter='+Trigger.isAfter+' Trigger.IsInsert='+Trigger.IsInsert+' Trigger.IsDelete='+Trigger.IsDelete);
    //if(Trigger.isBefore && Trigger.IsInsert){}
    
    if(Trigger.isAfter && Trigger.IsInsert){
        TriggerMethods.checkBeforeLoop('WCQuestionnaireIndustrySpecific', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
    }
    
    //else if(Trigger.isBefore && Trigger.IsUpdate){}
    else if(Trigger.isAfter && Trigger.IsUpdate){
        TriggerMethods.checkBeforeLoop('WCQuestionnaireIndustrySpecific', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
    }
    else if(Trigger.isAfter && Trigger.IsDelete){
        System.debug('In is after and delete');
        TriggerMethods.checkBeforeLoop('WCQuestionnaireIndustrySpecific', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter); // DeleteAfter
        //PeoWCIndSpecificDeleteAfter afterDeleteHandler = new PeoWCIndSpecificDeleteAfter();
        //afterDeleteHandler.handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
    }
}