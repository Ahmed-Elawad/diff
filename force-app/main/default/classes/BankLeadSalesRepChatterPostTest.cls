/* Test methods for the BankLeadSalesRepChatterPost class
   
  History
  -------
   01/06/2014 Carrie Marciano   Created
   10/21/2014 Dan Carmen        Modified to remove a for loop
   11/06/2014 Dan Carmen        Changed LeadSource reference
   11/09/2015 Dan Carmen        Modifications to use new Chatter methods.
   03/15/2024 Dan Carmen        Remove reference to TriggerFlags__c
  
 */
@isTest(SeeAllData=false)
private class BankLeadSalesRepChatterPostTest{
    
   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false, new String[]{'BankLeadSalesRepChatterPost'});
      TriggerMethodsTest.saveSetupClasses();
   } // setupData
    
   static testMethod void testData() {
      BankLeadSalesRepChatterPost.ALLOW_CHATTER = true;
       
      Id[] extraUserIds = new Id[]{};
    	
      user u1 = [Select Id, Name, DSA_FSS__c, ManagerId, FirstName, LastName from User where HR_Person_Id__c != null and IsActive=true and DSA_FSS__c != null and ManagerId != null and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      extraUserIds.add(u1.DSA_FSS__c);
      extraUserIds.add(u1.ManagerId);
      system.debug('**CLM BankLeadSalesRepChatterPostTest - User'+ u1.Id);

      //user u2 = [Select Id, Name, DSA_FSS__c, ManagerId, FirstName, LastName from User where HR_Person_Id__c != null and IsActive=true and DSA_FSS__c != null and ManagerId = null and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      //system.debug('**CLM BankLeadSalesRepChatterPostTest - User'+ u2.Id);
      user u3 = [Select Id, Name, DSA_FSS__c, ManagerId, FirstName, LastName from User where HR_Person_Id__c != null and IsActive=true and DSA_FSS__c = null and ManagerId != null and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      extraUserIds.add(u3.ManagerId);
      system.debug('**CLM BankLeadSalesRepChatterPostTest - User'+ u3.Id);
      
      user u4 = [Select Id, Name, DSA_FSS__c, ManagerId, FirstName, LastName from User where HR_Person_Id__c =:UserHelper.UNASSIGNED_CORE_PERSON_ID and IsActive=true and DSA_FSS__c = null and ManagerId = null limit 1];
      system.debug('**CLM BankLeadSalesRepChatterPostTest - User'+ u4.Id);

      Referral_Account__c ra = new Referral_Account__c(name='Test Ref Acct', Street_Address_1__c='12 ABC Street', City__c='City', State_Province__c='NY', Zip_Postal_Code__c='14612', Referral_Source_Business_Type__c='Financial Services');
      insert ra;
      system.debug('**CLM BankLeadSalesRepChatterPostTest - insert RefAcct '+ ra.Id);
      Referral_Contact__c r1 = new Referral_Contact__c(name='Test1',Referral_Id__c='Dan1', Phone__c='7161234569',Referral_Account__c=ra.Id);
      insert r1;
        
      system.debug('**CLM BankLeadSalesRepChatterPostTest - insert RefCont'+ r1.Id);
      Lead l1 = new Lead(OwnerId=u1.Id, FirstName='Steve', LastName='Test1',Company='Test1 Co',LeadSource=Label.LeadSource_ReferralBank,Referral_Contact__c=r1.Id);
      //Lead l2 = new Lead(OwnerId=u2.Id, FirstName='Steve', LastName='Test2',Company='Test2 Co',LeadSource=Label.LeadSource_ReferralBank,Referral_Contact__c=r1.Id);
      Lead l3 = new Lead(OwnerId=u3.Id, FirstName='Steve', LastName='Test3',Company='Test3 Co',LeadSource=Label.LeadSource_ReferralBank,Referral_Contact__c=r1.Id);
      Lead l4 = new Lead(OwnerId=u4.Id, FirstName='Steve', LastName='Test4',Company='Test4 Co',LeadSource=Label.LeadSource_ReferralBank,Referral_Contact__c=r1.Id);
      //Lead[] leads = new Lead[]{l1,l2,l3,l4};
      Lead[] leads = new Lead[]{l1,l3,l4};
      insert leads;

      System.debug('testData feedItemsToPostSize='+ChatterMentionPost.feedItemsToPostSize);
      // one post for each lead should be posted.
      Assert.areEqual(3,ChatterMentionPost.feedItemsToPostSize);
    }//test method
    
}// class BankLeadSalesRepChatterPostTest