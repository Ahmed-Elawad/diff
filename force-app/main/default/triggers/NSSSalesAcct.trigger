/* 
 *  A trigger for the NSS Sales Client object.
 *   
 * History
 * -------
   01/22/2015 Dan Carmen       created
   02/05/2016 Dan Carmen       Verify format of branch-client number
 
 */
trigger NSSSalesAcct on NSSSalesAcct__c (before insert, before update) {
   if (NSSSalesMethods.SKIP_TRIGGERS) {
      return;
   }

   // link these to clients and accounts
   Set<String> accountIdSet = new Set<String>();
   NSSSalesAcct__c[] checkAccountIdList = new NSSSalesAcct__c[]{};
   
   Map<String,List<NSSSalesAcct__c>> acctByBranchNbrMap = new Map<String,List<NSSSalesAcct__c>>();

   for (NSSSalesAcct__c nsa : Trigger.new) {
      if (Trigger.isBefore) {
      	NSSSalesAcct__c oldNsa = (Trigger.isUpdate ? Trigger.oldMap.get(nsa.Id) : null);
      	// if the account id changes, re-evaluate the record
      	if (oldNsa != null && nsa.AccountId__c != oldNsa.AccountId__c) {
      	   nsa.AccountIdChecked__c = false;
      	   nsa.AccountIdIsValid__c = false;
      	} // if (oldNsa
      	
         // force the format of the name field
         //nsa.Name = (Utilities.removeLeadingZero(nsa.OfficeNumber__c)+'-'+nsa.ClientNumber__c).toUpperCase();
         nsa.Name = AccountHelper.verifyAcctNbr(nsa.OfficeNumber__c+'-'+nsa.ClientNumber__c);
         // only process if not already linked
         if (!nsa.AccountIdChecked__c) {
         	if (String.isNotBlank(nsa.AccountId__c) && nsa.AccountId__c.startsWith(ObjectHelper.PREFIX_ACCOUNT)) {
               accountIdSet.add(nsa.AccountId__c);
               checkAccountIdList.add(nsa);
         	} else {
         		// if we get here we don't have a valid id so no further checking is required
         	   nsa.AccountIdChecked__c = true;
         	}
         } // if (!nsa.AccountIdChecked__c
         
         if (nsa.NSSSalesClient__c == null) {
            List<NSSSalesAcct__c> acctList = acctByBranchNbrMap.get(nsa.Name);
            if (acctList == null) {
               acctList = new List<NSSSalesAcct__c>();
               acctByBranchNbrMap.put(nsa.Name,acctList);
            }
            acctList.add(nsa);
         } // if (nsa.NSSSalesClient__c == null
      } // if (Trigger
   } // for (NSSSalesClient__c nsc
   
   if (!accountIdSet.isEmpty()) {
      NSSSalesMethods.checkAccountIdExists(checkAccountIdList, accountIdSet);
   }
   
   if (!acctByBranchNbrMap.isEmpty()) {
      NSSSalesMethods.handleNssSalesAccts(acctByBranchNbrMap);
   }

} // trigger NSSSalesAcct