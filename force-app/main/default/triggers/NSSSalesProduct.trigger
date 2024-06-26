/* 
 *  A trigger for the NSS Sales Product object.
 *   
 * History
 * -------
   01/16/2015 Dan Carmen       created
   02/05/2016 Dan Carmen       Verify format of branch-client number
   09/09/2016 Dan Carmen       Add product group field.
 
 */
trigger NSSSalesProduct on NSSSalesProduct__c (before insert, before update, after insert, after update) {
   if (NSSSalesMethods.SKIP_TRIGGERS) {
      return;
   }

   // the products where we need to look up the client records
   NSSSalesProduct__c[] findClientRecs = new NSSSalesProduct__c[]{};
   Set<String> clientNbrSet = new Set<String>();
   Set<String> salesRepPersonIdSet = new Set<String>();
   NSSSalesProduct__c[] findSalesRepRecs = new NSSSalesProduct__c[]{};
   
   // check the linkage to the account
   Id[] checkAccountLink = new Id[]{};
   
   for (NSSSalesProduct__c nsp : Trigger.new) {
   	if (Trigger.isBefore) {
         // format the branch-client number to be consistent
         //nsp.BranchClientNumber__c = (Utilities.removeLeadingZero(nsp.OfficeNumber__c)+'-'+nsp.ClientNumber__c).toUpperCase();
         nsp.BranchClientNumber__c = AccountHelper.verifyAcctNbr(nsp.OfficeNumber__c+'-'+nsp.ClientNumber__c);
         // force the format of the Name field
         nsp.Name = (String.IsNotBlank(nsp.ProductCode__c) ? nsp.ProductCode__c : nsp.ProductCodeDescription__c);
      
         if (String.isNotBlank(nsp.WinDiscountImport__c)) {
            String tempDiscount = Utilities.removeExtraChars(nsp.WinDiscountImport__c, Utilities.ALL_NUMBERS);
            try {
               nsp.WinDiscount__c = (String.isNotBlank(tempDiscount) ? Decimal.valueOf(tempDiscount) : null);
            } catch (Exception e) {
               // what should we do here?
               System.debug('NSSSalesProduct WinDiscount__c exception: '+e.getStackTraceString());
            }
         }
         
         
         ProductGroupMapping__c mapping = NSSSalesMethods.getMapping(nsp.Name);
         nsp.MatchedToMapping__c = (mapping != null);
         
         nsp.ProductType__c = (mapping != null ? mapping.ProductType__c : null);
         nsp.ProductGroup__c = (mapping != null ? mapping.Product_Group__c : null);
         
         if (nsp.NSSSalesClient__c == null) {
            findClientRecs.add(nsp);
            clientNbrSet.add(nsp.BranchClientNumber__c);
         }
      
         if (String.isNotBlank(nsp.SalesRepPersonId__c)) {
            salesRepPersonIdSet.add(nsp.SalesRepPersonId__c);
            findSalesRepRecs.add(nsp);
         }
         
         if (nsp.EvaluateProspectOwnership__c) {
            NSSSalesMethods.nssOppProductIdSet.add(nsp.Id);
            NSSSalesMethods.nssOppClientIdSet.add(nsp.NSSSalesClient__c);
            // change the flag back
            nsp.EvaluateProspectOwnership__c = false;
         }
   	} // if (Trigger.isBefore
   	if (Trigger.isAfter) {
   		if (Trigger.isInsert) {
   		   // check all product records for PO links
            NSSSalesMethods.nssOppProductIdSet.add(nsp.Id);
            NSSSalesMethods.nssOppClientIdSet.add(nsp.NSSSalesClient__c);
   		}
   	} // if (Trigger.isAfter
   } // for (NSSSalesProduct__c nsc

   if (!findClientRecs.isEmpty()) {
      NSSSalesMethods.findClientRecs(findClientRecs, clientNbrSet);
   }
   
   if (!findSalesRepRecs.isEmpty()) {
      NSSSalesMethods.findSalesReps(findSalesRepRecs, salesRepPersonIdSet);
   }
   
   if (Trigger.isAfter && !NSSSalesMethods.nssOppProductIdSet.isEmpty()) {
      NSSSalesMethods.checkOppLinks(NSSSalesMethods.nssOppClientIdSet, NSSSalesMethods.nssOppProductIdSet);
   }
} // trigger NSSSalesProduct