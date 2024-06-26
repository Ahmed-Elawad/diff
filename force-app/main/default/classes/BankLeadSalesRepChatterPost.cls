/* 
 * creates chatter post on lead with @mention to Sales Rep, DSA, and DSM
 *
 * History
 * -------
 * 12/20/2013 Carrie Marciano   Created
   10/21/2014 Dan Carmen        Modified to remove a for loop
   11/09/2015 Dan Carmen        Modifications to use new Chatter methods.
 *
 */
public with sharing class BankLeadSalesRepChatterPost implements TriggerInterfaceC {

   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('BankLeadSalesRepChatterPost.handleTrigger p_recs='+p_recs.size()+' isBefore='+isBefore+' isAfter='+isAfter);
      Lead[] lds = (Lead[])p_recs;
      Boolean isSysAdmin = UserHelper.isRunningUserSystemAdmin();
      if (isAfter && isSysAdmin) {
         Schema.RecordTypeInfo leadPendingRT = RecordTypeHelper.getRecordType('Pending Leads', 'Lead');
         Lead[] bankLeads = new Lead[]{};
         for (Lead ld : lds) {
            if (oldMap == null && ld.RecordTypeId != leadPendingRT.getRecordTypeId() && String.isNotBlank(ld.LeadSource)
                     && isSysAdmin && ld.LeadSource.equals(Label.LeadSource_ReferralBank) && !ld.DoNotUseBankTriggerChatter__c) {
               bankLeads.add(ld);
             }
         } // for (Lead ld)
         System.debug('BankLeadSalesRepChatterPost.handleTrigger bankLeads='+bankLeads.size());
         if (!bankLeads.isEmpty()) {
            mentionTextPost(bankLeads);
         }
      } // if (isAfter
   } // handleTrigger
    
   // don't use the chatter message in test unless the flag is specifically set.
   public static Boolean ALLOW_CHATTER=!Test.isRunningTest();
   
   // makes a simple chatter text post to the specified user from the running user 
   public void mentionTextPost(List<Lead> bankLeads) {
      System.debug('mentionTextPost bankLeads='+bankLeads.size());
      Set<ID> leadOwnerIds = new Set<ID>();
      for (Lead lead: bankLeads) {
         leadOwnerIds.add(lead.OwnerId);
      }
      //get single occurence of each lead owner and their DSA and manger
      //List<User> leadOwners = [Select id, DSA_FSS__c, ManagerId from User where Id IN :leadOwnerIds];
      Map<Id,User> leadOwnerMap = new Map<Id,User>([Select id, DSA_FSS__c, ManagerId from User where Id IN :leadOwnerIds]);
       
      for (Lead lead : bankLeads) {
    	   User owner = leadOwnerMap.get(lead.OwnerId);
    	   if (ALLOW_CHATTER && owner != null) {
                
            Id[] userIds = new Id[]{owner.Id};
            if (owner.DSA_FSS__c != null) {
               userIds.add(owner.DSA_FSS__c);
            }
            if (owner.ManagerId != null){
               userIds.add(owner.ManagerId);
            }
            String postText = ' A new bank lead for ' + lead.FirstName + ' ' + lead.LastName + ' from ' + lead.Company + ' has been entered into Salesforce for you.  ';
            ChatterMentionPost.createChatterMentionPost(lead.Id, userIds, new String[]{postText}, true, false);

         } //endIf(lead.OwnerId == owner.id)
      } //endFor Lead lead : bankLeads
      
      ChatterMentionPost.postBatchFeedElements();
   } //mentionTextPost
   
} // class BankLeadSalesRepChatterPost