/* 
 * If the owner of the reference MMS record changes, update Case owner and Account.MMS_AS__c
 * Called from trigger ReferenceMMSPayrollAfter
 *
 * History
 * -------
 * 08/29/2013 Cindy Freeman   Created
 * 11/27/3013 Cindy Freeman	  added method to update AccountNumber, MyPaychex_com_Client and MyPaychex_com_Start_Date
 *
 */

public with sharing class ReferenceMMSUpdate {

	public static void processMMSOwner(Id[] mmstoUpdateAcct) {
		List<Id> caseIds = new List<Id>();							// temp list of case ids, used to query
		List<Id> acctIds = new List<Id>();							// temp list of account ids, used to query
		List<Id> userIds = new List<Id>();							// temp list of owner(user) ids, used to query

		Reference_MMS_Payroll__c[] mmsList = [Select Id, Case_Number__c, OwnerId, HRG__c, HRO_Onboarding__c, MMS_MAM_NAM__c 
	    									from Reference_MMS_Payroll__c where Id in :mmstoUpdateAcct];
		
		
		Map<Id, String> mapOwnertoHR = new Map<Id, String>();		//	owner(user).Id -> hr person id
		Map<String, Id> mapHRtoCtct = new Map<String, Id>();		//  hr person id -> contact.Id
		
		for (Reference_MMS_Payroll__c mms : mmsList)
		{	//mapOwnertoHR.put(mms.OwnerId, mms.Owner__r.HR_Person_Id__c);
			userIds.add(mms.OwnerId);	
			caseIds.add(mms.Case_Number__c);
		}
		
		// gather related users, cases and accounts
		Map<Id, User> mapUsers = new Map<Id, User>([Select Id, HR_Person_Id__c from User where Id in :userIds]);
		for (User u : mapUsers.values())
		{	mapOwnertoHR.put(u.Id, u.HR_Person_Id__c);	}
		Map<Id, Case> mapCases = new Map<Id, Case>([Select Id, OwnerId, AccountId from Case where Id in :caseIds]);
		for (Case c : mapCases.values())
		{	acctIds.add(c.AccountId);	}
		Map<Id, Account> mapAccts = new Map<Id, Account>([Select Id, MMS_AS__c, HR_Generalist__c,
															HRO_Implementation_Coordinator__c,
															MMS_MAM_NAM__c from Account where Id in :acctIds]);
		
		// get contact record based on mms owner HR_Person_id
		Contact[] ctcts = [Select Id, HR_Person_Id__c from Contact where HR_Person_Id__c in :mapOwnertoHR.values()];	
		for (Contact ct : ctcts)
		{	mapHRtoCtct.put(ct.HR_Person_Id__c, ct.Id);	}
		                                                    
	    Case[] updateCases = new Case[]{};
	    Account[] updateAccts = new Account[]{};
	    Reference_MMS_Payroll__c[] updateRefMMS = new Reference_MMS_Payroll__c[]{};
	    
	    for (Reference_MMS_Payroll__c mms : mmsList)
	    {	Case c = mapCases.get(mms.Case_Number__c);
	    	if (c != null)
	    	{	c.OwnerId = mms.OwnerId;
	    		updateCases.add(c);
	    		Account a = mapAccts.get(c.AccountId);
	    		if (a != Null)
	    		{	Id ctId = mapHRtoCtct.get(mapOwnertoHR.get(mms.OwnerId));
	    			a.MMS_AS__c = ctId;
	    			updateAccts.add(a);
	    			mms.HRG__c = a.HR_Generalist__c;
	    			mms.HRO_Onboarding__c = a.HRO_Implementation_Coordinator__c;
	    			mms.MMS_MAM_NAM__c = a.MMS_MAM_NAM__c;
	    			updateRefMMS.add(mms);
	    		} // if a!=Null
	    	} // if c!=Null
	    } // for mms
	    
	    if (!updateCases.isEmpty())
	    {	update updateCases;	}
	    
	    if (!updateAccts.isEmpty())
	    {	update updateAccts;	}
	    
	    if (!updateRefMMS.IsEmpty())
	    {	update updateRefMMs;	}

	} // processMMSOwner


	public static void processMMSAccount(Id[] mmstoUpdateAcct) {
		List<Id> acctIds = new List<Id>();							// temp list of account ids, used to query
		List<Account> acctUpdates = new List<Account>();			// list of accounts to update
		
		Reference_MMS_Payroll__c[] mmsList = [Select Id, Case_Number__c, Case_Number__r.AccountId, OwnerId, 
						 					Assigned_Prospect_Client_Number__c, MyPaychex_com_Client__c, MyPaychex_com_Start_Date__c 
	    									from Reference_MMS_Payroll__c where Id in :mmstoUpdateAcct];

		for (Reference_MMS_Payroll__c mms: mmsList)
		{	acctIds.add(mms.Case_Number__r.AccountId);	}
		
		Map<Id, Account> mapAccts = new Map<Id, Account>([Select Id, AccountNumber, MyPaychex_com_Client__c, myPaychex_com_Start_Date__c 
							from Account where Id in :acctIds]);
		Boolean acctUp;
		for (Reference_MMS_Payroll__c mms: mmsList)
		{	acctUp = false;
			Account acct = mapAccts.get(mms.Case_Number__r.AccountId);
			if (mms.Assigned_Prospect_Client_Number__c != null && acct.AccountNumber == null)
			{	acct.AccountNumber = mms.Assigned_Prospect_Client_Number__c;
				acctUp = true;
			} // if Assigned_Prospect_Client_Number__c
			if (mms.MyPaychex_com_Client__c != null && mms.MyPaychex_com_Client__c != acct.MyPaychex_com_Client__c)
			{	acct.MyPaychex_com_Client__c = mms.MyPaychex_com_Client__c;
				acct.MyPaychex_com_Start_Date__c = mms.MyPaychex_com_Start_Date__c;
				acctUp = true;
			} // if MyPaychex_com_Client__c
			if (acctUp)
			{	acctUpdates.add(acct);	}
		} // for
		
		if (!acctUpdates.isEmpty())
		{	update acctUpdates;	}
	
	} // processMMSAccount



} // ReferenceMMSUpdate