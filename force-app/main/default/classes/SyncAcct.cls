/* 
 * Used to Sync the record type for Accounts with the Opportunity if one is MMS and the other is core.
 *
 * History
 * -------
 * 11/10/2016 Jermaine Stukes Created
 * 11/22/2016 Jermaine Stukes update logic
 * 02/14/2017 Cindy Freeman		modified logic to handle multiple opptys for same account
 * 
 */
public without sharing class SyncAcct {
    
    public static List<Opportunity> oppsToCheckRT = new List<Opportunity>();
    public static List<Id> oppIdsToCheckRT = new List<Id>();
    
    //Verify opportunity is assigned by NSS
    public static void checkAfterTrigger(List<Id> oppIds)
    {
            oppIdsToCheckRT = oppIds;
            handleOpptyRTCheck();
    }
    
    //Verify opportunity is assigned by NSS
/*    public static void checkAfterTrigger(Opportunity opp)
    {
        if(String.isNotBlank(opp.NSS_Source__c) && opp.OpportunityType__c == OpptyMethods.Opp_TYPE_PAY)
        {           
            oppIdsToCheckRT.add(opp.Id);
        } 
        if(!oppIdsToCheckRT.isEmpty())
        {
            handleOpptyRTCheck();
        }
    }*/
    
    //Check Account RT, update if necessary
    public static void handleOpptyRTCheck()
    {	Id lastAcctId = null;
        list<Account> AcctsToUpdate = new list<Account>();
        for (Opportunity opp : [Select Id 
                                ,RecordType.Name
                                ,Account.Use_Zip_Assignment_Rules__c
                                ,Account.Id
                                ,Account.RecordType.Name
                                ,Account.RecordTypeId
                                from Opportunity where Id in :oppIdsToCheckRT]) 
        {	Account acct = opp.Account;
        	if (acct != null && (lastAcctId == null || lastAcctId != acct.Id))            
            {	//Get Sales Org for Account and Opportunity to compare
                String oppSalesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(opp.RecordType.Name);
                String acctSalesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(acct.RecordType.Name);
                if (oppSalesOrg != acctSalesOrg) 
                {//Check Account Type
                    if(acct.RecordType.Name == Label.RT_Core_Account || acct.RecordType.Name== Label.RT_MMS_Account)
                    {
                        acct.RecordTypeId = getRecordTypeIdForSalesOrg(oppSalesOrg, ObjectHelper.OBJECT_ACCOUNT);
                        acct.Use_Zip_Assignment_Rules__c = true;
                        AcctsToUpdate.add(acct);
                    } // if (acct.RecordTypeName..
                } // if (oppSalesOrg...
            	if (lastAcctId == null)
        		{	lastAcctId = opp.Account.Id;	}
            } // if (acct != null && (lastAcctId...
        } // for
        if(!AcctsToUpdate.isEmpty()){
			update AcctsToUpdate;            
        }
    }
    //Grab Record Type information for Account
    public static Id getRecordTypeIdForSalesOrg(String salesOrg, String objectName) 
    {
        Id rtId = Null;
        //Grab all record types
        for (RecordType__c rt : RecordType__c.getAll().values()) 
        {
            //Verify rt matches parameter values
            if (rt.Sales_Org__c == salesOrg && rt.ObjectName__c == objectName) 
            {	//Grab record type information
                Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(rt.Name, rt.ObjectName__c);
                rtId = rtInfo.getRecordTypeId();
                break;
            }
        }
        return rtId;
    }
}