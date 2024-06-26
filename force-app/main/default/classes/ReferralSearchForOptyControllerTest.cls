/* 
 * Test methods for the ReferralSearchForOptyController
 *
 * History
 * -------
 * 12/21/2015 Cindy Freeman   Created
 * 03/28/2016 Cindy Freeman   Added , Always_Check_Send_Email__c=false
   11/16/2017 Dan Carmen      Change so test can pass (too many SOQL queries)
 *
 */
@isTest
private class ReferralSearchForOptyControllerTest {

    static testMethod void testnoOriginatingId() {
        User runningUser = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        // test if no referral id
        System.runAs(runningUser)
        {   ReferralSearchForOptyController rc = new ReferralSearchForOptyController();
            System.assertEquals(true,ApexPages.hasMessages());
            ApexPages.Message msg = ApexPages.getMessages().get(0);
            System.assertEquals(true,msg.getDetail().startsWith('Missing Referral Id.'));               
        } // runAs
        
    } // testnoOriginatingId
    
    static testMethod void testAllPieces() {
       OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
       ZipCheckOwner.SKIP_TRIGGERS=true;
        // create a,c,opty
        // create referral with optys
        // search, get 2 optys back, pick old opty, update referral?        
        User runningUser = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        setupRefPartners();
        Referral_Partner__c refPart = refPartnerMap.get('PAY'); //[Select Id, Name from Referral_Partner__c where Name = 'PAY'];
        
        CreateTestData.createTestAandC();
        Account acct = CreateTestData.acct1; //[Select Id, Name from Account where Name = 'Test Account1'];
        Contact ctct = CreateTestData.ctct1; // [Select Id, Name from Contact where Name = 'First Last1'];
        CreateTestData.createTestCoreOptys(acct.Id, ctct.Id);           
        Opportunity origOpty = CreateTestData.oppty1; //[Select Id, Name, StageName, Payroll_Platform__c from Opportunity where Name = 'Test Core Opporty'];
        origOpty.Name = 'Orig Core Opporty';
        origOpty.Payroll_Platform__c = 'PAY';
        update origOpty;
        
        // create selling opty to link to referral
        CreateTestData.createTestCoreSoldOptys (acct.Id,ctct.Id);
        Opportunity sellingOpty = CreateTestData.oppty1;   //[Select Id, Name, StageName, Payroll_Platform__c
                                    //,Owner.Id,Owner.Name,Owner.DSA_FSS__c,Owner.DSA_FSS__r.Id 
                                    //from Opportunity where Name = 'Test Core Opporty'];
        sellingOpty.Payroll_Platform__c = 'PAY';
        update sellingOpty;
        // create referring opty
        Opportunity referringOpty = new Opportunity();
        referringOpty.AccountId = acct.Id;
        referringOpty.Name = 'Test Core Opty-Referral';
        referringOpty.StageName = 'Referred';
        referringOpty.Payroll_Platform__c = 'PAY';
        referringOpty.CloseDate=Date.today().addDays(30);
        insert referringOpty;
        
        
        Test.StartTest();
        
        Referral__c ref = new Referral__c();
        ref.Name='Test Account1-PAY';
        ref.SourceContact__c=ctct.Id;
        ref.Account__c=acct.Id;
        ref.Commission_Products__c='Payroll';
        ref.Status__c='Approved';
        ref.Started_From__c ='Contact';
        ref.Referring_Opportunity__c = referringOpty.Id;
        ref.Referring_User__c = runningUser.Id;
        ref.Selling_Opportunity__c = sellingOpty.Id;
        ref.User__c= runningUser.Id;
        ref.Referral_Partner__c = refPart.Id;
        insert ref;
        ref = [Select Id, Name, Account__r.Id from Referral__c where Id = :ref.Id];
        System.assertEquals(acct.Id, ref.Account__r.Id);
                
        Test.SetCurrentPageReference(Page.ReferralSearchForOpty);
        System.CurrentPageReference().getParameters().put('Id',ref.Id);
        ReferralSearchForOptyController rc = new ReferralSearchForOptyController();          
        System.assertEquals(ref.Name, rc.ref.Name);
        System.assertEquals(acct.Id, rc.ref.Account__r.Id);
        System.assertEquals(1, rc.allRefList.size());
        System.assertEquals(2, rc.oppWrapList.size());
        System.assertEquals(false, rc.selectAll);
        System.assertEquals(false, rc.allDone);
        
        // cancel url but dont go there
        PageReference returnUrl = rc.cancel();
        System.assertEquals(true,(returnUrl.getUrl().contains(ref.Id)));
         
        // hit submit and check err
        rc.submit();
        System.assertEquals(true,ApexPages.hasMessages());
        ApexPages.Message msg = ApexPages.getMessages().get(0);
        System.assertEquals(true,msg.getDetail().startsWith('If you are not changing the opportunity'));
        
        // deselect all optys and check err
        rc.oppWrapList[0].selected = false;
        rc.oppWrapList[1].selected = false;
        rc.submit();
        System.assertEquals(true,ApexPages.hasMessages());
        msg = ApexPages.getMessages().get(1);
        System.assertEquals(true,msg.getDetail().contains('Only 1 opportunity can be selected'));
        
        
        // select other opty and hit submit, all changed? plus msg
        if (rc.oppWrapList[0].opp.Id == sellingOpty.Id)
        {   rc.oppWrapList[0].selected = false;
            rc.oppWrapList[1].selected = true;
        }
        else
        {   rc.oppWrapList[0].selected = true;
            rc.oppWrapList[1].selected = false;
        }
        rc.submit();
        //System.assertEquals(true,ApexPages.hasMessages());
        //msg = ApexPages.getMessages().get(1);
        //System.assertEquals(true,msg.getDetail().startsWith('Referral updated'));
        ref = [Select Id, Name, Account__r.Id, Selling_Opportunity__r.Id, Status__c from Referral__c where Id = :ref.Id];
        System.assertEquals(origOpty.Id, ref.Selling_Opportunity__r.Id);
        System.assertEquals('Approved',ref.Status__c);
        
        sellingOpty = [Select Id, Name, StageName from Opportunity where Id = :sellingOpty.Id];
        System.assertEquals('Referral Duplicate',sellingOpty.StageName);
        
        System.assertEquals(true, rc.allDone);
        Test.StopTest();       
    } // testAllPieces
    
   public static Map<String,Referral_Partner__c> refPartnerMap = null;
    
   private static Referral_Partner__c[] setupRefPartners() {
      UserHelperTest.setupSalesOrgSetting();
      
      // make sure there are no existing records
      if (!Utilities.isTestSiloed()) {
      //if ([Select count() from Referral_Partner__c] > 0) {
         Database.Delete([Select Id from Referral_Partner__c],true);
      }
      refPartnerMap = new Map<String,Referral_Partner__c>();
      Referral_Partner__c[] partners = new Referral_Partner__c[]{};
      for (String salesOrg : UserHelper.DIVISION_LIST) {
         Referral_Partner__c rp = new Referral_Partner__c(Name=salesOrg,Partner_Type__c=ReferralController.REF_INTERNAL,Sort_Order__c=partners.size()+1,Ref_To_Type__c='Contact',CreateRefOpp__c=true,UseApprovalProcess__c=true, IsActive__c=true, Always_Check_Send_Email__c=false);
         partners.add(rp);
         refPartnerMap.put(rp.Name,rp);
      }
    
      Referral_Partner__c rp20 = new Referral_Partner__c(Name='Test20',Partner_Type__c=ReferralController.REF_EXTERNAL,Sort_Order__c=20,Ref_To_Type__c='Referral Contact',CreateRefOpp__c=false, IsActive__c=true, Always_Check_Send_Email__c=false);
      refPartnerMap.put(rp20.Name,rp20);
      Referral_Partner__c rp21 = new Referral_Partner__c(Name='Test21',Partner_Type__c=ReferralController.REF_EXTERNAL,Sort_Order__c=21,Ref_To_Type__c='Referral Contact',CreateRefOpp__c=false, IsActive__c=true, Always_Check_Send_Email__c=false);
      refPartnerMap.put(rp21.Name,rp21);
      partners.add(rp20);
      partners.add(rp21);
    
      insert partners;
      return partners;
   } // setupRefPartners
       
}