/* 
 *  A trigger for the NSS Sales Client object.
 *   
 * History
 * -------
   01/16/2015 Dan Carmen       created
   02/05/2016 Dan Carmen       Verify format of branch-client number
 
 */
trigger NSSSalesClient on NSSSalesClient__c (before insert, before update, after insert, after update) {
   if (NSSSalesMethods.SKIP_TRIGGERS) {
      return;
   }

   Id[] nssSalesToLinkToAcctIds = new Id[]{};
   Map<String,List<NSSSalesClient__c>> checkForDupMap = new Map<String,List<NSSSalesClient__c>>();

   for (NSSSalesClient__c nsc : Trigger.new) {
   	if (Trigger.isBefore) {
         // force the format of the name field
         //nsc.Name = (Utilities.removeLeadingZero(nsc.OfficeNumber__c)+'-'+nsc.ClientNumber__c).toUpperCase();
         nsc.Name = AccountHelper.verifyAcctNbr(nsc.OfficeNumber__c+'-'+nsc.ClientNumber__c);
         nsc.ZipCode__c = ZipCodeInformation.format5DigitZip(nsc.ZipCode__c);
         
         if (!nsc.CheckedForDupe__c) {
         	List<NSSSalesClient__c> clientList = checkForDupMap.get(nsc.Name);
         	if (clientList == null) {
         	   clientList = new List<NSSSalesClient__c>();
         	   checkForDupMap.put(nsc.Name,clientList);
         	}
            clientList.add(nsc);
            nsc.CheckedForDupe__c = true;
         } // if (!nsc.CheckedForDupe__c
         
   	} else if (Trigger.isAfter) {
   	   nssSalesToLinkToAcctIds.add(nsc.Id);
   	} // if (Trigger
   } // for (NSSSalesClient__c nsc
   
   if (!checkForDupMap.isEmpty()) {
      NSSSalesMethods.checkForDuplicates(checkForDupMap);
   }
   
   if (!nssSalesToLinkToAcctIds.isEmpty()) {
      NSSSalesMethods.findAccountRecords(nssSalesToLinkToAcctIds);
   }
   
} // trigger NSSSalesClient