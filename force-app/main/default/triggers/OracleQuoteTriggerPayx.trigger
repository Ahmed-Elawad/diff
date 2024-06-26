/** Set Primary Quote Lookup on Opportunity when Quote is marked Primary. Workaround for Oracle bug mapping to lookup fields
*
* History 
* -------
03/18/2020 Justin Stouffer    Created
06/15/2020 Carrie Marciano    using for Status updates from CPQ Quote that are not driven by quoteline updates
06/14/2022 Jermaine Stukes    Added CSO Methods Eligibility Check
10/16/2023 Pratik Das         APR0116247: Remove the ability to Delete Oracle Quotes
10/26/2023 Dan Carmen         Update call to handleAfterQuoteUpdate

*/ 
trigger OracleQuoteTriggerPayx on cafsl__Oracle_Quote__c (before delete,after insert, after update) {
    system.debug('OracleQuoteTriggerPayx beginning');
    map<id,cafsl__Oracle_Quote__c> OpptyIdtoQuoteMap = new map<id,cafsl__Oracle_Quote__c>();
    List<cafsl__Oracle_Quote__c> quoteList = new List<cafsl__Oracle_Quote__c>();
    
    //APR0116247: Remove the ability to Delete Oracle Quotes--Start
    List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
    String profileName = lstProfile[0].Name;
    if(Trigger.isDelete){
        for (cafsl__Oracle_Quote__c oQuote: Trigger.old) {
            if(profileName!=Utilities.PROF_SYS_ADMIN && profileName!='Sales Enablement'){
                Trigger.oldMap.get(oQuote.Id).addError(oQuote.Name+' Cannot be deleted by '+ profileName+' Please contact System Administrator');
            }
            
        } 
    }
    //APR0116247: Remove the ability to Delete Oracle Quotes--End
    else{
        for (cafsl__Oracle_Quote__c oQuote: Trigger.new) {
            
            system.debug('OracleQuoteTriggerPayx oQuote.Name: '+oQuote.Name+' oQuote.cafsl__Syncing__c: '+oQuote.cafsl__Syncing__c+' oQuote.cafsl__Opportunity__c: '+oQuote.cafsl__Opportunity__c); 
            if (oQuote.cafsl__Syncing__c==TRUE &&  oQuote.cafsl__Opportunity__c != NULL){
                OpptyIdtoQuoteMap.put(oQuote.cafsl__Opportunity__c,oQuote);
                system.debug('OracleQuoteTriggerPayx OpptyIdtoQuoteMap: '+OpptyIdtoQuoteMap);
                quoteList.add(oQuote);
            }
        }
        if(!OpptyIdtoQuoteMap.isEmpty()){
            OracleQuoteTriggerPayxHelper.processOpptys(OpptyIdtoQuoteMap);
            system.debug('OracleQuoteTriggerPayx after call to helper class'); 
            
        }
        if(!quoteList.isEmpty()){
            CsoMethods.handleAfterQuoteUpdate(quoteList);
        }
        
    }
    
} // trigger OracleQuoteTriggerPayx