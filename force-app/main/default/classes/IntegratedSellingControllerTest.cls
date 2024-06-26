/* 
 * Test methods for the IntegratedSellingControllerTest.
 *
 * History
 * -------
 * 09/27/2018 Lynn Michels        Created.
 *
 */
@isTest
private class IntegratedSellingControllerTest {
	
	@testSetup
   static void setupData() {
   	//create referral partners for integrated selling
   	List<Referral_Partner__c> refPartners = new List<Referral_Partner__c>();
    refPartners.add(new Referral_Partner__c(Name='MMS',Partner_Type__c=ReferralController.REF_INTSELL,Sort_Order__c=20,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true));
    refPartners.add(new Referral_Partner__c(Name='PAS',Partner_Type__c=ReferralController.REF_INTSELL,Sort_Order__c=20,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true));
    refPartners.add(new Referral_Partner__c(Name='PAY',Partner_Type__c=ReferralController.REF_INTSELL,Sort_Order__c=20,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true));
   	insert refPartners;
   	
    //set up RecordType custom setting
    RecordType__c[] recordTypes = new RecordType__c[]{}; 
	//PEO
	recordTypes.add(new RecordType__c(Name=Label.PEO_Opportunity_Record_Type,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=Label.PEO_Opportunity_Record_Type, Sales_Org__c=UserHelper.SO_PEO_ASO));
    //MMS
    recordTypes.add(new RecordType__c(Name=Label.MMS_Opportunity_Record_Type,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=Label.MMS_Opportunity_Record_Type, Sales_Org__c=UserHelper.SO_MMS));
    //CORE
    recordTypes.add(new RecordType__c(Name=Label.PAY_Opportunity_Record_Type,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=Label.PAY_Opportunity_Record_Type, Sales_Org__c=UserHelper.SO_CORE));
    insert recordTypes;

   } // setupData 
    
    static testMethod void getAcctOppsTestWithExistingReferrals() {
    	CreateTestData.createSingleAandTwoCts();
    	List<Account> accountList= [SELECT Id FROM Account];
    system.debug('LM accountList '+accountList);
    	List<Contact> contactList = [SELECT Id FROM Contact];
    system.debug('LM cotactList '+contactList); 
    	//create Core opp and attach it to a referral
    	CreateTestData.createTestCoreOptys(accountList[0].id, contactList[0].id);
    	List<Opportunity> coreOppList = [SELECT Id, OwnerId, AccountId FROM Opportunity WHERE RecordType.Name = 'Core Opportunity Record Type'];
   		Referral__c referral = new Referral__c(Name='TestReferral-Core', Selling_Opportunity__c = coreOppList[0].id);
    	insert referral;
    	
    	//create an mms opp
    	CreateTestData.createTestMMSSoldOptys(accountList[0].id, contactList[0].id);
    	
    	List<Opportunity> opps = IntegratedSellingController.getAcctOpps(accountList[0].id);
    	system.assertEquals(2, opps.size());
    	
  		//process the opportunities and ensure the data is created properly
    	IntegratedSellingController.processOpportunities(opps);
    	//verify one referral join is created and there are 2 referrals
    	
    	List<Referral__c> referralList = [SELECT Id, Selling_Opportunity__c, Account__c, OwnerId, User__c, Status__c FROM Referral__c];
    	system.assertEquals(2, referralList.size());
    	
    	List<Referral__c> referralMMS = [SELECT Id, Referral_Partner__r.Name FROM Referral__c WHERE Referral_Partner__r.Name = 'MMS'];
    	List<Referral__c> referralPAY = [SELECT Id, Referral_Partner__r.Name FROM Referral__c WHERE Referral_Partner__r.Name = 'PAY'];
    	
    	List<ReferralJoin__c> referralJoin = [SELECT Id, PAS_Referral__c,MMS_Referral__c, Core_Referral__c FROM ReferralJoin__c];
    	system.assertEquals(1, referralJoin.size());
    	system.assertEquals(null, referralJoin[0].PAS_Referral__c);
    	system.assertEquals(referralMMS[0].id,  referralJoin[0].MMS_Referral__c);
    	system.assertEquals(referralPAY[0].id,  referralJoin[0].Core_Referral__c);
    		
    }// getAcctOppsTest
    
    static testMethod void getOppsTestNoExistingReferrals() {
    	CreateTestData.createSingleAandTwoCts();
    	List<Account> accountList= [SELECT Id FROM Account];
    system.debug('LM accountList '+accountList);
    	List<Contact> contactList = [SELECT Id FROM Contact];
    system.debug('LM cotactList '+contactList); 
    	CreateTestData.createTestCoreOptys(accountList[0].id, contactList[0].id);
    	CreateTestData.createTestPEOOptys(accountList[0].id, contactList[0].id);
    	List<Opportunity> oppList = [SELECT Id FROM Opportunity];
    system.debug('LM oppList '+oppList); 
    	List<Opportunity> opps = IntegratedSellingController.getOpps(oppList[0].id);
    	system.assertEquals(2, opps.size());
    	
    	IntegratedSellingController.processOpportunities(opps);
    	List<ReferralJoin__c> referralJoin = [SELECT Id FROM ReferralJoin__c];
    	List<Referral__c> referralList = [SELECT Id, Selling_Opportunity__c, Account__c, OwnerId, User__c, Status__c, Referral_Partner__c FROM Referral__c];
    	system.assertEquals(2, referralList.size());
    	system.assertEquals(1, referralJoin.size());
    	
    }// getOppsTest
}