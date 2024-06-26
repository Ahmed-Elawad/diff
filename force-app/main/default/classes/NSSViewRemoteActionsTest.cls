/*  
 * Test methods for the NSSViewRemoteActions class
 * 
 * History
 * -------
   01/25/2017 Dan Carmen   Created

   
 */
@isTest 
private class NSSViewRemoteActionsTest {

   @testSetup
   public static void setupData(){
      LeadCompanyMethodsTest.setupData();
   } // setupData

   public static void setupRefPartners() {
      UserHelperTest.setupSalesOrgSetting();
      // make sure there are no existing records
      if ([Select count() from Referral_Partner__c] > 0) {
         Database.Delete([Select Id from Referral_Partner__c],true);
      }
      Referral_Partner__c[] partners = new Referral_Partner__c[]{};
      for (String salesOrg : UserHelper.DIVISION_LIST) {
         Referral_Partner__c rp = new Referral_Partner__c(Name=salesOrg,Partner_Type__c=ReferralController.REF_NSS,Sort_Order__c=partners.size()+1,Ref_To_Type__c='User',CreateRefOpp__c=false,UseApprovalProcess__c=false, IsActive__c=true, Always_Check_Send_Email__c=false);
         partners.add(rp);
      }
    
      insert partners;

   } // setupRefPartners
   
   static testMethod void testGetReferralPartners() {
      setupRefPartners();
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      NSSViewRemoteActions.ReferralPartner[] refPartners = NSSViewRemoteActions.getReferralPartners(acct.Id, 'true');
      
   } // testGetReferralPartners

   static testMethod void testGetOpps() {
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      Opportunity opp1 = new Opportunity(Name='Test Opp1', AccountId=acct.Id, CloseDate=Date.today(), StageName='Pending');
      Opportunity opp2 = new Opportunity(Name='Test Opp2', AccountId=acct.Id, CloseDate=Date.today(), StageName='Pending');
      Opportunity opp3 = new Opportunity(Name='Test Opp3', AccountId=acct.Id, CloseDate=Date.today(), StageName='Pending');
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
      insert opps;
      
      NSSViewRemoteActions.OppWrapper[] oppWraps = NSSViewRemoteActions.getOpps(acct.Id);
      System.assertEquals(opps.size(), oppWraps.size());
   } // testGetOpps

   static testMethod void testGetAssets() {
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      Asset asst1 = new Asset(Name='Asset 1', AccountId=acct.Id, Start_Date__c=Date.today().addDays(-30), Plan_Cancel_Date__c=null);
      Asset asst2 = new Asset(Name='Asset 2', AccountId=acct.Id, Start_Date__c=Date.today().addDays(-30), Plan_Cancel_Date__c=null);
      Asset asst3 = new Asset(Name='Asset 3', AccountId=acct.Id, Start_Date__c=Date.today().addDays(-30), Plan_Cancel_Date__c=null);
      Asset asst4 = new Asset(Name='Asset 4', AccountId=acct.Id, Start_Date__c=Date.today().addDays(-30), Plan_Cancel_Date__c=Date.today());
      Asset asst5 = new Asset(Name='Asset 5', AccountId=acct.Id, Start_Date__c=Date.today().addDays(-30), Plan_Cancel_Date__c=Date.today());
      Asset[] assets = new Asset[]{asst1,asst2,asst3,asst4,asst5};
      insert assets;
      
      NSSViewRemoteActions.AssetWrapper[] activeProds = NSSViewRemoteActions.getAssets(acct.Id, 'Active');
      System.assertEquals(3,activeProds.size());

      NSSViewRemoteActions.AssetWrapper[] inactiveProds = NSSViewRemoteActions.getAssets(acct.Id, 'Inactive');
      System.assertEquals(2,inactiveProds.size());
   } // testGetAssets
   
   static testMethod void testGetOtherCtcts_ctct() {
      NSSViewRemoteActions.MORE_VALUE=2;
      
      Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
      Schema.RecordTypeInfo rtCtct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');

      Account acct = new Account(Name='Test Acct', RecordTypeId=rtAcct.getRecordTypeId());
      insert acct;

      Contact ctct1 = new Contact(AccountId=acct.Id, LastName='Last1', Sales_Contact__c=true, RecordTypeId=rtCtct.getRecordTypeId());
      Contact ctct2 = new Contact(AccountId=acct.Id, LastName='Last2', Sales_Contact__c=true, RecordTypeId=rtCtct.getRecordTypeId());
      Contact ctct3 = new Contact(AccountId=acct.Id, LastName='Last3', Sales_Contact__c=true, RecordTypeId=rtCtct.getRecordTypeId());
      Contact ctct4 = new Contact(AccountId=acct.Id, LastName='Last4', Sales_Contact__c=true, RecordTypeId=rtCtct.getRecordTypeId());
      Contact ctct5 = new Contact(AccountId=acct.Id, LastName='Last5', Sales_Contact__c=true, RecordTypeId=rtCtct.getRecordTypeId());
      Contact ctct6 = new Contact(AccountId=acct.Id, LastName='Last6', Sales_Contact__c=true, RecordTypeId=rtCtct.getRecordTypeId());
      Contact ctct7 = new Contact(AccountId=acct.Id, LastName='Last7', Sales_Contact__c=true, RecordTypeId=rtCtct.getRecordTypeId());
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4,ctct5,ctct6,ctct7};
      insert ctcts;
      
      System.assertEquals(7,[select count() from Contact where AccountId=:acct.Id and Sales_Contact__c=true]);
      
      // call with a bad object id to create an exception
      NSSViewRemoteActions.CtctWrapper[] ctctWraps = NSSViewRemoteActions.getOtherCtcts(ObjectHelper.OBJECT_ACCOUNT, 'badid', ctct1.Id, null, '5'); 
      System.assertEquals(0,ctctWraps.size());

      ctctWraps = NSSViewRemoteActions.getOtherCtcts(ObjectHelper.OBJECT_ACCOUNT, acct.Id, ctct1.Id, null, '5'); 
      // should only return the "MORE_VALUE" plus the initial count.
      System.assertEquals(2,ctctWraps.size());
      verifyCtctNotMatched(ctct1.Id, ctctWraps);

      // should return a total of 4 records
      ctctWraps = NSSViewRemoteActions.getOtherCtcts(ObjectHelper.OBJECT_ACCOUNT, acct.Id, ctct1.Id, '2', '5');
      System.assertEquals(4,ctctWraps.size());
      verifyCtctNotMatched(ctct1.Id, ctctWraps);

      // even though there are more records, should only return a maximum of 5
      ctctWraps = NSSViewRemoteActions.getOtherCtcts(ObjectHelper.OBJECT_ACCOUNT, acct.Id, ctct1.Id, '4', '5');
      System.assertEquals(5,ctctWraps.size());
      verifyCtctNotMatched(ctct1.Id, ctctWraps);

   } // testGetOtherCtcts_ctct
   
   static testMethod void testGetOtherCtcts_lead() {
      NSSViewRemoteActions.MORE_VALUE=2;
      LeadCompanyMethods.SKIP_FUTURE=true;
      
      Lead ld1 = new Lead(LastName='Last1', Company='Test Company', Street='123 Any St', City='Somecity',State='NY', PostalCode='12345');
      insert ld1;
      ld1 = [Select Id, Name, LastName, Company, Street, City, State, PostalCode, Lead_Company__c, LeadGroupId__c from Lead where Id=:ld1.Id];
      System.assertEquals(true, (ld1.Lead_Company__c != null));
      System.assertEquals(true, (ld1.LeadGroupId__c != null));

      Lead ld2 = new Lead(LastName='Last2', Company='Test Company', Street='123 Any St', City='Somecity',State='NY', PostalCode='12345', Lead_Company__c=ld1.Lead_Company__c, LeadGroupId__c=ld1.LeadGroupId__c);
      Lead ld3 = new Lead(LastName='Last3', Company='Test Company', Street='123 Any St', City='Somecity',State='NY', PostalCode='12345', Lead_Company__c=ld1.Lead_Company__c, LeadGroupId__c=ld1.LeadGroupId__c);
      Lead ld4 = new Lead(LastName='Last4', Company='Test Company', Street='123 Any St', City='Somecity',State='NY', PostalCode='12345', Lead_Company__c=ld1.Lead_Company__c, LeadGroupId__c=ld1.LeadGroupId__c);
      Lead ld5 = new Lead(LastName='Last5', Company='Test Company', Street='123 Any St', City='Somecity',State='NY', PostalCode='12345', Lead_Company__c=ld1.Lead_Company__c, LeadGroupId__c=ld1.LeadGroupId__c);
      Lead[] leads = new Lead[]{ld2,ld3,ld4,ld5};
      insert leads;

      // call with a bad id to create an exception
      NSSViewRemoteActions.CtctWrapper[] ctctWraps = NSSViewRemoteActions.getOtherCtcts(ObjectHelper.OBJECT_LEAD, 'badId', ld1.Id, null, '4'); 
      System.assertEquals(0,ctctWraps.size());

      ctctWraps = NSSViewRemoteActions.getOtherCtcts(ObjectHelper.OBJECT_LEAD, ld1.Lead_Company__c, ld1.Id, null, '4'); 
      // should only return the "MORE_VALUE" plus the initial count.
      System.assertEquals(2,ctctWraps.size());
      verifyCtctNotMatched(ld1.Id, ctctWraps);
      
   } // testGetOtherCtcts_lead
   
   public static Boolean verifyCtctNotMatched(Id checkId, NSSViewRemoteActions.CtctWrapper[] ctctWraps) {
      Boolean notMatched = true;
      for (NSSViewRemoteActions.CtctWrapper ctctWrap : ctctWraps) {
         if (ctctWrap.Id == checkId) {
            notMatched = false;
            break;
         }
      } // for
      System.assertEquals(true, notMatched);
      return (notMatched == true);
   } // verifyCtctNotMatched
   
} // class NSSViewRemoteActionsTest