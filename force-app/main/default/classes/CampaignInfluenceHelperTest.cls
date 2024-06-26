/* 
 * Test Methods for the CampaignInfluenceHelper class
 *
 * History
 * -------
   03/29/2018 Dan Carmen        Created
   03/02/2020 Dan Carmen        Add additional tracking for NSS Source and Referral Contact

 */
@isTest
private class CampaignInfluenceHelperTest {

   static testMethod void testCampaignInfluenceCreation() {
      // create a campaign
      Campaign camp1 = new Campaign(Name='Test Campaign',IsActive=true, StartDate=Date.today());
      insert camp1;
      
      Account acct1 = new Account(Name='Test Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct1;
      
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='TestLast');
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert ctct1;
       
      Referral_Account__c refAcct = new Referral_Account__c(Name='Ref Account');
      ReferralAccountMethods.SKIP_TRIGGERS=true;
      insert refAcct;
       
      Referral_Contact__c refCtct = new Referral_Contact__c(Name='Joe Contact', Referral_Account__c=refAcct.Id);
      insert refCtct;
      
      CampaignMember campMem1 = new CampaignMember(CampaignId=camp1.Id, ContactId=ctct1.Id);
      insert campMem1;
      
      Contact payxCtct = new Contact(LastName='PaychexEmp', HR_Person_Id__c='77');
      insert payxCtct;
      payxCtct = [Select Id, Name, LastName, HR_Person_Id__c from Contact where Id=:payxCtct.Id];
      
      Opportunity opp1 = new Opportunity(Name='TestOpp', AccountId=acct1.Id, CloseDate=Date.today().addDays(7), StageName='Pending'
                                        ,Referring_Employee__c=payxCtct.Id, LeadSource='TestLead', NSS_Source__c='Outbound'
                                        ,Referral_Contact__c=refCtct.Id);
      insert opp1;
      OpportunityContactRole ocr = new OpportunityContactRole(ContactId=ctct1.Id, OpportunityId=opp1.Id, IsPrimary=true, Role='Decision Maker');
      insert ocr;
      
      CampaignInfluenceModel cim = [Select Id, IsActive, ModelType, ModelDescription
                                      From CampaignInfluenceModel
                                     Where IsActive=true and IsDefaultModel=true limit 1];

      CampaignInfluence ci = new CampaignInfluence(OpportunityId=opp1.Id, ContactId=ctct1.Id, CampaignId=camp1.Id, ModelId=cim.Id);
      Test.startTest();
      insert ci;
      Test.stopTest();
      
      // campaign influence should have been created
      CampaignInfluence checkCi = [Select Id, CampaignId, ContactId, Influence, OpportunityId, RevenueShare
                                         ,CampaignCounter__c, NSS_Source__c, OrderOfInfluence__c 
                                         ,ReferralContactId__c, ReferralContactName__c
                                         ,ReferringEmployeeId__c, ReferringEmployeeName__c
                                From CampaignInfluence 
                               Where OpportunityId = :opp1.Id];
      System.assertEquals(1,checkCi.CampaignCounter__c);
      System.assertEquals(1,checkCi.OrderOfInfluence__c);
      System.assertEquals(payxCtct.Id, checkCi.ReferringEmployeeId__c);
      System.assertEquals(payxCtct.Name, checkCi.ReferringEmployeeName__c);
      System.assertEquals('Outbound',checkCi.NSS_Source__c);
      System.assertEquals(refCtct.Id, checkCi.ReferralContactId__c);
      System.assertEquals(refCtct.Name, checkCi.ReferralContactName__c);
      
   } // testCampaignInfluenceCreation
   
   
} // class CampaignInfluenceHelperTest