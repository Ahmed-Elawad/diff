/* Before trigger on the Prospect_Ownership__c object
   
   History
   -------
   09/10/2014 Dan Carmen   Created
   01/08/2016 Dan Carmen      Set the supervisor when the opportunity is set
   06/17/2019 Dan Carmen      Add an after call to check for callback tasks after the PO is created
   
 */
trigger ProspectOwnershipBefore on Prospect_Ownership__c (before insert, before update, after insert) {

   Map<Id,Prospect_Ownership__c[]> poByNsrMap = new Map<Id,Prospect_Ownership__c[]>();
   // value = lead/contact/account id, value = po id
   Map<Id,Id[]> poIdByRecIdMap = new Map<Id,Id[]>();

   if (Trigger.isAfter) {
      ProspectOwnershipMethods.checkForCallbacks(Trigger.new, Trigger.oldMap);
   }

   if (Trigger.isBefore) {
       ProspectOwnershipMethods.MapDialSourceActionToPO(Trigger.new);
      ProspectOwnershipMethods.checkNextVerifyDate(Trigger.new, Trigger.oldMap);
   }

   for (Prospect_Ownership__c po : Trigger.new) {
      
   	Prospect_Ownership__c oldPo = (Trigger.isUpdate ? Trigger.oldMap.get(po.Id) : null);
   	if (Trigger.isBefore) {
         // if the ownership stage changes clear out the last verified date
         //if (String.isNotBlank(po.Ownership_Status__c) && oldPo != null && oldPo.Ownership_Status__c != po.Ownership_Status__c) {
         //   po.LastVerified__c = null;
         //}
         // set the NSR manager on setting the opportunity
         if (po.Opportunity__c != null && (oldPo == null || (oldPo != null && oldPo.Opportunity__c == null))) {
            Prospect_Ownership__c[] poList = poByNsrMap.get(po.NSR_Name__c);
            if (poList == null) {
               poList = new Prospect_Ownership__c[]{};
               poByNsrMap.put(po.NSR_Name__c, poList);
            }
            poList.add(po);
         } // if (po.Opportunity__c != null
   	}
   } // for (Prospect_Ownership__c po
   
   System.debug('ProspectOwnershipBefore trigger poByNsrMap='+poByNsrMap.size());
   if (!poByNsrMap.isEmpty()) {
      ProspectOwnershipMethods.setNsrSupervisor(poByNsrMap);
   }
} // trigger ProspectOwnershipBefore