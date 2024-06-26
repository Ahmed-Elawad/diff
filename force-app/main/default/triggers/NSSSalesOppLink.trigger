/* 
 *  A trigger for the NSS Sales Opp Link object.
 *   
 * History
 * -------
   02/04/2015 Dan Carmen       created
 
 */
trigger NSSSalesOppLink on NSSSalesOppLink__c (after insert, after update) {

   // do nothing if this flag is set
   if (NSSSalesMethods.SKIP_TRIGGERS || NSSSalesMethods.SKIP_SALES_OPP_LINK_TRIGGER) {
      return;
   }
   
   Set<Id> productIdSet = new Set<Id>();
   
   for (NSSSalesOppLink__c link : Trigger.new) {
      productIdSet.add(link.NSSSalesProduct__c);
   } // for
   
   if (!productIdSet.isEmpty()) {
      NSSSalesMethods.compileLinkInformation(productIdSet);
   }
} // trigger NSSSalesOppLink