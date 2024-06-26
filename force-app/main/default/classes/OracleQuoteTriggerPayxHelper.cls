/** Set Primary Quote Lookup on Opportunity when Quote is marked Primary. Workaround for Oracle bug mapping to lookup fields
 *
 * History 
 * -------
   3/18/2020 Justin Stouffer    Created
   6/15/2020 Carrie Marciano    using for Status updates from CPQ Quote that are not driven by quoteline updates
  10/09/2020 Jake Hinds   Adding without sharing per PMD
 */ 
public without sharing class OracleQuoteTriggerPayxHelper {

    public static void processOpptys(map<id,cafsl__Oracle_Quote__c> OpptyIdtoQuoteMap){  
        set<id> oQuoteIds = new set<id>();
        Set<String> oracleQuoteStatusSalesOrg = new Set<String>(Label.OracleQuoteStatusSalesOrg.split(','));
        //Set<String> oracleQuoteStatusRecordTypes = new Set<String>(Label.OracleQuoteStatusRecordTypes.split(','));
        Set<String> oracleQuoteRecordTypes = new Set<String>(Label.OracleQuoteRecordTypes.split(',')); 
        
        For(cafsl__Oracle_Quote__c oQUote : OpptyIdtoQuoteMap.values()){
            oQuoteIds.add(oQuote.id);
            system.debug('processOpptys oQuoteIds: '+oQuoteIds);
        }
        
        Map<String,String> statusMap = new Map<String,String>();
        for (OracleQuoteStatusOpptyStatus__mdt statusMapping : [Select MasterLabel, Label, Oracle_Quote_Status__c, Opportunity_Status__c
                                                                 from OracleQuoteStatusOpptyStatus__mdt]) {
             statusMap.put(statusMapping.Oracle_Quote_Status__c,statusMapping.Opportunity_Status__c);
        }
                                                                         
        list<opportunity> opptysToUpdate = [select id, 
                                            Primary_Oracle_Quote__c, 
                                            Primary_Oracle_Quote_Status__c,
                                            RecordTypeId,
                                            OwnerId,
                                            Owner.Sales_Org__c,
                                            Owner.Sales_Division__c
                                            from 
                                            Opportunity 
                                            where ID in :OpptyIdtoQuoteMap.keySet()];
        system.debug('processOpptys opptysToUpdate: '+opptysToUpdate);
        If(!opptysToUpdate.isEmpty()){
            for (opportunity oppty: opptysToUpdate){
                Opportunity originalOppty = oppty;
                system.debug('processOpptys originalOppty.Primary_Oracle_Quote__c: '+originalOppty.Primary_Oracle_Quote__c+' originalOppty.Primary_Oracle_Quote_Status__c: '+originalOppty.Primary_Oracle_Quote_Status__c);
                oppty.Primary_Oracle_Quote__c = OpptyIdtoQuoteMap.get(oppty.id).id;
                oppty.Primary_Oracle_Quote_Status__c = OpptyIdtoQuoteMap.get(oppty.id).Status__c;
                system.debug('processOpptys oppty.Primary_Oracle_Quote__c: '+oppty.Primary_Oracle_Quote__c+' oppty.Primary_Oracle_Quote_Status__c: '+oppty.Primary_Oracle_Quote_Status__c);
                
                if(oppty.Primary_Oracle_Quote_Status__c != null
                   //&& oppty.Primary_Oracle_Quote_Status__c != originalOppty.Primary_Oracle_Quote_Status__c 
                   && oracleQuoteStatusSalesOrg.contains(originalOppty.Owner.Sales_Org__c) 
                   && oracleQuoteRecordTypes.contains(originalOppty.RecordTypeId)
                   && originalOppty.Owner.Sales_Division__c != 'RSR'
                   && statusMap.containsKey(oppty.Primary_Oracle_Quote_Status__c)){                 
                       if(statusMap.containsKey(oppty.Primary_Oracle_Quote_Status__c)){
                           oppty.StageName = statusMap.get(oppty.Primary_Oracle_Quote_Status__c);
                           system.debug('processOpptys HRS quote updates oppty.StageName: '+oppty.StageName);
                       } 
                }
            }
            update opptysToUpdate;
            system.debug('processOpptys after update opptysToUpdate');
        }             
    }  
}