/* 
   If a line item is updated from external source, make sure the override flag is set. 
   
  History
  -------
  11/01/2011 Dan Carmen   Created
  12/22/2011 Dan Carmen   Added moving the Opportunity Status to sold.
  12/29/2011 Dan Carmen   Added update to Opportunity revenue, setup fee, and payroll units field if line item changes.
  02/02/2012 Dan Carmen   If a lineitem is inserted, if there's a non-default and default product on 
                          the same opportunity, remove the default product.
  08/29/2013 Cindy Freeman    If line item is added to MMS Opty, push product up to oppty.product_summary__c
  08/17/2015 Carrie Marciano Added calculations for multi-id opportunities to fields with number of Ids, and list of Ids to be passed to Onboarding Case
  01/27/2016 Cindy Freeman    changed this trigger to fire after delete so it will pick up changes for oppty Product Summary field.
  04/06/2016 Carrie Marciano added opptyIdsToMultiId to isDelete portion of code 
  08/12/2016 Carrie Marciano fixed the line "opptyIdsToSumProds.add(oli.OpportunityId);" to now be adding the opportunity.ID not the oli.id, moved this line to the
                             Trigger.isAfter section of the code instead of the Trigger.isBefore, commented out the "opptyIdsToMultiId.add(oli.OpportunityId);" line of code
                             in the else of Trigger.isBefore code
  08/08/2017 Dan Carmen    Updated AfterTrigger to process update and insert separately.  Resolved issue where Payroll unit wasn't being updated when new product added
  05/04/2018 Cindy Freeman   look for change in Non-Payroll Units checkbox to add to opptyIdsToSumProds
  05/29/2018 Cindy Freeman   add label to be able to skip trigger for product updates
  04/02/2018 Carrie Marciano  added call to ReferenceOpportunityProduct for population of ReferenceOpportunityProduct object used by Service Agreements
  08/23/2019 Jacob Hinds   adding method for exclude revenue
  09/04/2019 Dan Carmen     Add additional recursion checks
  07/28/2020 Dan Carmen     Save deleted opportunity line item ids to a separate table.
  11/21/2020 Carrie Marciano commenting out setting of INSERT_TRIGGER_PROCESSED, this was preventing oracle quotelines of more than 200 to update opptylines with data
  03/16/2021 Carrie Marciano removing MultiId functionality that was for Steelbrick - Oracle passes this thru field mappings
  03/26/2021 Jacob Hinds       Adding RJMethods call
  07/17/2023 Dan Carmen        Clean up code
  09/07/2023 Carrie Marciano	Removed any recursion checks, it was preventing CPQ from processing batches correctly and overwritting lines we excluded revenue on

 */

trigger OpptyLineItem on OpportunityLineItem (before insert, before update, before delete, after insert, after update, after delete) {
   System.debug('OpptyLineItem SKIP_TRIGGER='+OpptyLineItem.SKIP_TRIGGER+' INSERT PROCESSED='+OpptyLineItem.INSERT_TRIGGER_PROCESSED+' UPDATE_PROCESSED='+OpptyLineItem.UPDATE_TRIGGER_PROCESSED);
   if (OpptyLineItem.SKIP_TRIGGER || Label.OptyLineItem_SkipTrigger == 'Y') {
      return;
   }

   if ((Trigger.isInsert && OpptyLineItem.INSERT_TRIGGER_PROCESSED)
       || (Trigger.isUpdate && OpptyLineItem.UPDATE_TRIGGER_PROCESSED)) {
      return;
   }
   /* we cannot do any kind of recursion due to the way CPQ sends lines over to us, recurrsion prevents subsequent batches of lines from being processed
   if (Trigger.isInsert && Trigger.isAfter) {
      //OpptyLineItem.INSERT_TRIGGER_PROCESSED=true;
   } else if (Trigger.isUpdate && Trigger.isAfter) {
      //OpptyLineItem.UPDATE_TRIGGER_PROCESSED=true;
   }
   */

   System.debug('OpptyLineItem isBefore='+Trigger.isBefore+' isAfter='+Trigger.isAfter+' isInsert='+Trigger.isInsert+' isUpdate='+Trigger.isUpdate+' isDelete='+Trigger.isDelete);    
   // opportunities to update to Sold - Commissioned
   Set<Id> opptyIdsToSold = new Set<Id>();
   // opportunities to re-calculate setup fee, payroll units, and revenue fields
   Set<Id> opptyIdsToSumProds = new Set<Id>();
   // Opportunities to check the line items (for default/non-default)
   Set<Id> opptyIdsCheckDef = new Set<Id>();
   // Opportunities to Update referrals based on Evaluate Product Of Interest (for default/non-default)
   Set<Id> OpptysToEvaluatePOI = new Set<Id>();
   // Opportunities to append product family to product_summary on opportunity
   Set<Id> opptyIdsToAppendProds = new Set<Id>();
   // Opportunites to update Reference Opportunity Product object
   Set<Id> opptyIdsToRefOpptyProduct = new Set<Id>();
   // records that were deleted - log the ids to use in RJDB
   DeletedId__c[] deletedRecs = new DeletedId__c[]{};
   
   System.debug('***CLM*** inside OpptyLineItem trigger');
   if (Trigger.isDelete) {      
      System.debug('OpptyLineItem isDelete Trigger.Old='+Trigger.Old.size());
      for (OpportunityLineItem oli : Trigger.Old) {
         if (Trigger.isAfter) { 
             OpptysToEvaluatePOI.add(oli.OpportunityId);
             opptyIdsToSumProds.add(oli.OpportunityId);
             opptyIdsToAppendProds.add(oli.OpportunityId);
             opptyIdsToRefOpptyProduct.add(oli.OpportunityId);
             //System.debug('***CLM*** isDelete added to opptyIdsToRefOpptyProduct: ' + opptyIdsToRefOpptyProduct.size());
             if (oli.Id != null) {
                deletedRecs.add(new DeletedId__c(SFDC_ID__c=oli.Id, ObjectName__c='OpportunityLineItem'));
             }
             System.debug('Calling from After Delete');
         }   
      }
   } else {
      System.debug('OpptyLineItem Trigger.New='+Trigger.New.size());
      if (Trigger.isBefore) {
         System.debug('OpptyLineItem trigger isBefore'); 
         OpptyLineItem.checkAllOlisBefore(Trigger.new, Trigger.oldMap);
         RJMethods.checkOACFieldChange(Trigger.new,Trigger.oldMap);
      } else {
         for (OpportunityLineItem oli : Trigger.New) {
            //System.debug('OpptyLineItem trigger isAfter oli: '+oli.ProductCode);
            if (Trigger.isInsert) {
               opptyIdsCheckDef.add(oli.OpportunityId);
               OpptysToEvaluatePOI.add(oli.OpportunityId);
               opptyIdsToSumProds.add(oli.OpportunityId);
               opptyIdsToAppendProds.add(oli.OpportunityId);            
            } else if (Trigger.isUpdate) {
               // see if any values have changed.
               OpportunityLineItem old_oli = Trigger.oldMap.get(oli.Id);
               if ((old_oli.Setup_Fee__c != oli.Setup_Fee__c) ||
                   (old_oli.TotalPrice != oli.TotalPrice) ||
                   (old_oli.Payroll_Unit__c != oli.Payroll_Unit__c) ||                   
                   (old_oli.Non_Payroll_Unit__c != oli.Non_Payroll_Unit__c)
                  ) {
                  opptyIdsToSumProds.add(oli.OpportunityId);
               }
            }
          opptyIdsToRefOpptyProduct.add(oli.OpportunityId);   
		  //System.debug('OpptyLineItem opptyIdsToRefOpptyProduct: '+opptyIdsToRefOpptyProduct.size());	
             
         } // for
      } // if (Trigger.isAfter
   } // if (Trigger.isDelete
   
   System.debug('OpptyLineItem opptyIdsCheckDef='+opptyIdsCheckDef.size()+' opptyIdsToSold='+opptyIdsToSold.size()+' opptyIdsToSumProds='+opptyIdsToSumProds.size()+' opptyIdsToAppendProds='+opptyIdsToAppendProds);

   if (!opptyIdsCheckDef.isEmpty() || !opptyIdsToSold.isEmpty() || !opptyIdsToSumProds.isEmpty() || !opptyIdsToAppendProds.isEmpty()) {
      OpptyLineItem.processLineItems(opptyIdsCheckDef, opptyIdsToSold,opptyIdsToSumProds,opptyIdsToAppendProds); 
   }
   System.debug('OpptyLineItem opptyIdsToRefOpptyProduct='+opptyIdsToRefOpptyProduct.size()+' OpptysToEvaluatePOI='+OpptysToEvaluatePOI.size()+' deletedRecs='+deletedRecs.size());
   if (!opptyIdsToRefOpptyProduct.isEmpty()) {
      ReferenceOpportunityProduct.processLineItems(opptyIdsToRefOpptyProduct);  
   }
     
   if (!OpptysToEvaluatePOI.isEmpty()) {
          OpptyProducts.EvaluateProductOfInterest(OpptysToEvaluatePOI);
   }

    if (!deletedRecs.isEmpty()) {
      DmlHelper.performDML2(deletedRecs, DmlHelper.DML_INSERT, 'OpptyLineItem', 'Trigger', 'Insert Deleted Id recs', true);
   }
} // trigger OpptyLineItem