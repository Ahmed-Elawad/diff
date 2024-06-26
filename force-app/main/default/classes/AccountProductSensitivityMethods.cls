/* Class to modify the Account Product Sensitivity List on Account objects when 
 *
 * History
 * -------
   01/08/2020   Michael Karcz       Created
*/

public without sharing class AccountProductSensitivityMethods implements TriggerInterface2{
    // check all of the records as a group before cycling through them individually
    public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
        if (recs != null && !recs.isEmpty()) {
            //should run on Account Product Sensitivities Insert/Update
            if (isAfter && recs[0].getSObjectType() == Account_Product_Sensitivities__c.sObjectType) {
                checkRecords(recs,oldMap,recs[0].getSObjectType());
            }
        } // if (recs != null && !recs.isEmpty
    } // triggerCheckAllFirst
    
    // check each record individually
    public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
       
    // see if there are any actions that need to take place at the end of the trigger.
    public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
    
    public void checkRecords(sObject[] sobjs, Map<Id,sobject> oldMap, Schema.SObjectType objName){
        
        //Get Account Ids
        List<Id> acctIdList = new List<Id>();
        for(Sobject sobj : sobjs) {
            acctIdList.add((Id)sobj.get('Prospect_Client__c'));
        }
        
        AcctSensitivityQueueable.checkLaunchQueueable(acctIdList);
		
        /**
        //Get actual Accounts
        Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, Name, SensitivityList__c FROM Account WHERE Id IN :acctIdList]);

        List<Account> acctsToUpdate = new List<Account>();

        //Get custom setting objects
        Map<String, Account_Product_Sensitivity__c> apsMap = new Map<String, Account_Product_Sensitivity__c>();
        for(Account_Product_Sensitivity__c aps : Account_Product_Sensitivity__c.getAll().values()) {
            apsMap.put(aps.Sensitivity_API_Name__c, aps);
            
        }

        //Figure out what Sensitivities are needed in the banner and update accordingly
        //Loop through each object being updated
        for(Sobject sobj:sobjs){
            Account acct = acctMap.get((Id)sobj.get('Prospect_Client__c'));
            //Loop through each field in the custom setting
            for(String apsFieldName : apsMap.keySet()) {
                String listItem = apsMap.get(apsFieldName).List_Name__c;
                //If the field on the Account Product Sensitivity object is checked (the account needs the sensitivity in the list)
                if((boolean)sobj.get(apsFieldName)) {
                    //If the list does not contain this value
                    if(!acct.SensitivityList__c.contains(listItem)) {
                        acct.SensitivityList__c += String.isblank(acct.SensitivityList__c) ? listItem : ',' + listItem; //add a comma if there's something already in the list
                    }
                }//if(sobj.get(apsFieldName))
                //If the field on the Account Product Sensitivity object is NOT checked (the account does not need the sensitivity in the list)
                else {
                    //If the sensitivity is already in the list (we need to remove it)
                    if(acct.SensitivityList__c.contains(listItem)) {
                        //If the sensitivity has a comma before it
                        if(acct.SensitivityList__c.contains(','+listItem)) {
                            acct.SensitivityList__c = acct.SensitivityList__c.remove(','+listItem);
                        }
                        //If the sensitivity doesn't have a comma before it but has a comma after it
                        else if(acct.SensitivityList__c.contains(listItem+',')) {
                            acct.SensitivityList__c = acct.SensitivityList__c.remove(listItem+',');
                        }
                        else {
                            acct.SensitivityList__c = acct.SensitivityList__c.remove(listItem);
                        }
                    }//if(acct.SensitivityList__c...)
                }//else
            }//for(String apsFieldName...)
            acctsToUpdate.add(acct);
        }//for (Sobject sobj:sobjs)

        if(!acctsToUpdate.isEmpty()){
            system.debug('AccountProductSensitivity acctsToUpdate starting Queuable');
            AccountProductSensitivityQueueable apsq = new AccountProductSensitivityQueueable(acctsToUpdate);
            System.enqueueJob(apsq);
        }
		**/
    }//checkrecords()
}