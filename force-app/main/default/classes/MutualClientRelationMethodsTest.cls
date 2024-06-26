/**
 * History
 * -------------------------------------------------------------------
   04/05/2023 Vinay           Created.
   06/02/2023 Dan Carmen      Moved to TriggerInterface
   12/08/2023 Dan Carmen      Updated debug statements

 */
@isTest
public with sharing class MutualClientRelationMethodsTest {
    
   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false,new String[]{'MutualClientRelationMethods'});
      TriggerMethodsTest.saveSetupClasses();
   } // setupData
    
    public static MutualClientRltn__c[] getRltns() {
       MutualClientRltn__c[] rltns = [Select Id, Account__c, Verification_Action__c, RltnType__c
                                        ,ReferralAccount__c, ReferralContact__c, StartDate__c, EndDate__c
                                        ,ReferralSourceVerification__c
                                    From MutualClientRltn__c];
       return rltns;
    } // getRltns

    static testMethod void validateProspectClientUpdate() {
        Referral_Account__c refAcc1 = new Referral_Account__c(Name='Peo test1', MutualClientTier__c='Core');
        Referral_Account__c refAcc2 = new Referral_Account__c(Name='Peo test2', MutualClientTier__c='Core');
        ReferralAccountMethods.SKIP_TRIGGERS=true;
        insert new Referral_Account__c[]{refAcc1,refAcc2};

        Referral_Contact__c refCon1a = new Referral_Contact__c(Name='Test ContactOne', Referral_Account__c = refAcc1.Id, Email__c = 'testing111@testingtestTest.com');
        Referral_Contact__c refCon1b = new Referral_Contact__c(Name='Test ContactTwo', Referral_Account__c = refAcc1.Id, Email__c = 'testing222@testingtestTest.com');
        Referral_Contact__c refCon2a = new Referral_Contact__c(Name='Test ContactThree', Referral_Account__c = refAcc2.Id, Email__c = 'testing333@testingtestTest.com');
        insert new Referral_Contact__c[]{refCon1a,refCon1b,refCon2a};

        Test.startTest();
        Account acc1 = new Account(Name = 'Test Account1', CPA_Name_Ref__c = refCon1a.Id);
        Account acc2 = new Account(Name = 'Test Account2', CPA_Name_Ref__c = null);
        insert new Account[]{acc1,acc2};
            
        MutualClientRltn__c[] rltns = getRltns();
        
        // only one relation record created
        Assert.areEqual(1,rltns.size());
        Assert.areEqual(refCon1a.Id, rltns[0].ReferralContact__c);
        Assert.areEqual(refAcc1.Id, rltns[0].ReferralAccount__c);
        Assert.areEqual(MutualClientRelationMethods.RLTN_CPA, rltns[0].RltnType__c);
        Assert.areEqual(acc1.Id, rltns[0].Account__c);
        Assert.isNull(rltns[0].EndDate__c);
        
        //List<MutualClientRltn__c> relationRecord = [SELECT Id FROM MutualClientRltn__c WHERE EndDate__c = null AND Account__c =: acc.Id];
        //System.assertEquals(relationRecord.size(), 1, 'Relationship record created for the Account on insert !!');

        System.debug('validateProspectClientUpdate before changing cpas');
        TriggerMethods.clearVariables();
        acc1.CPA_Name_Ref__c = refCon1b.Id;
        acc2.CPA_Name_Ref__c = refCon2a.Id;
        update new Account[]{acc1,acc2};

        rltns = getRltns();
        
        Assert.areEqual(3,rltns.size());
        Boolean verify1aEnded=false;
        Boolean verify1bStarted=false;
        Boolean verify2aStarted=false;
        
        for (MutualClientRltn__c mcr : rltns) {
           if (mcr.ReferralContact__c == refCon1a.Id && mcr.Account__c == acc1.Id && mcr.EndDate__c != null) {
              verify1aEnded = true;
           } else if (mcr.ReferralContact__c == refCon1b.Id && mcr.Account__c == acc1.Id) {
              Assert.isNull(mcr.EndDate__c);
              Assert.areEqual(MutualClientRelationMethods.RLTN_CPA, mcr.RltnType__c);
              verify1bStarted=true;
           } else if (mcr.ReferralContact__c == refCon2a.Id && mcr.Account__c == acc2.Id) {
              Assert.isNull(mcr.EndDate__c);
              Assert.areEqual(MutualClientRelationMethods.RLTN_CPA, mcr.RltnType__c);
              verify2aStarted=true;
           }
        } // for (MutualClientRltn__c mcr
        
        Assert.isTrue(verify1aEnded);
        Assert.isTrue(verify1bStarted);
        Assert.isTrue(verify2aStarted);
        Test.stopTest();
        
        TriggerMethods.clearVariables();
        MutualClientRelationMethods.removeCPAFromAccount(acc2.Id);
        
        rltns = getRltns();
        Assert.areEqual(4,rltns.size());

        verify2aStarted=false;
        Boolean verify2aEnded=false;
        
        for (MutualClientRltn__c mcr : rltns) {
           if (mcr.ReferralContact__c == refCon2a.Id && mcr.Account__c == acc2.Id) {
              Assert.isNotNull(mcr.EndDate__c);
              Assert.areEqual(MutualClientRelationMethods.RLTN_CPA, mcr.RltnType__c);
              verify2aEnded=true;
           }   
        } // for (MutualClientRltn__c mcr : rltns
        Assert.isTrue(verify2aEnded);
        
        Account checkAcct1 = MutualClientRelationMethods.getAccountCPA(acc1.Id);
        Assert.areEqual(acc1.Id,checkAcct1.Id);
        Assert.areEqual(checkAcct1.CPA_Name_Ref__c, refCon1b.Id);

        // test failure
        Boolean handledException=false;
        Id fakeAcctId = '001000000123456789';
        try {
           MutualClientRelationMethods.getAccountCPA(fakeAcctId);
           Assert.isFalse(true, 'Should Not Get Here');
        } catch (Exception e) {
           handledException=true;
        }
        Assert.isTrue(handledException);
        
        String result = MutualClientRelationMethods.removeCPAFromAccount(fakeAcctId);
        Assert.areNotEqual('SUCCESS', result);
        
        String refAcctId = MutualClientRelationMethods.getReferralAccountId(refCon1b.Id);
        Assert.areEqual(refAcc1.Id, refAcctId);
        
        String userDetails = MutualClientRelationMethods.getUserDetalsAndRefOwnereAndARM(refAcc1.Id);
        System.debug('userDetails='+userDetails);
        Assert.isTrue(userDetails.contains(UserInfo.getUserId()));
        
        TriggerMethods.clearVariables();
        MutualClientRelationMethods.updateProspectAccount(acc2.Id, refCon2a.Id);
        
        rltns = getRltns();
        Assert.areEqual(5,rltns.size());

        verify2aStarted=false;
        verify2aEnded=false;
        
        for (MutualClientRltn__c mcr : rltns) {
           if (mcr.ReferralContact__c == refCon2a.Id && mcr.Account__c == acc2.Id && mcr.EndDate__c == null) {
              Assert.areEqual(MutualClientRelationMethods.RLTN_CPA, mcr.RltnType__c);
              verify2aStarted=true;
           } else if (mcr.ReferralContact__c == refCon2a.Id && mcr.Account__c == acc2.Id && mcr.EndDate__c != null) {
              verify2aEnded = true;
           }
        } // for (MutualClientRltn__c mcr : rltns
        
        //Should be 2 for these
        Assert.isTrue(verify2aStarted);
        Assert.isTrue(verify2aEnded);

        // should only be one of these right now
        MutualClientRltn__c mcr = [Select Id, Verification_Action__c, ReferralSourceVerificationDate__c
                                     From MutualClientRltn__c
                                    Where Account__c=:acc2.Id and EndDate__c = null limit 1];
        // clear these fields to see if the process populates them again
        mcr.Verification_Action__c = null;
        mcr.ReferralSourceVerificationDate__c = null;
        update mcr;

        MutualClientRelationMethods.handleMutualClientVerification(acc2.Id);
        mcr = [Select Id, Verification_Action__c, ReferralSourceVerificationDate__c
                                     From MutualClientRltn__c
                                    Where Account__c=:acc2.Id and EndDate__c = null limit 1];
        
        Assert.IsNotNull(mcr.Verification_Action__c);
        Assert.isNotNull(mcr.ReferralSourceVerificationDate__c);

    } // validateProspectClientUpdate
    
} // class MutualClientRelationMethodsTest