/** Test Methods for RAT


 * History
 * -------
   04/27/2020 Jake Hinds       Created
   05/26/2020 Jake Hinds       Adding method for duplicate check

*/
@isTest
public class ReferralAccountTeamMethodsTest {
    static testMethod void testUpdateReferralAccount() {
        User[] users = [SELECT ID FROM User WHERE Sales_Org__c = 'MMS' AND isActive = true LIMIT 2];
        Referral_Account__c refAcct1 = new Referral_Account__c(Name='Insert Test');
        Referral_Account__c refAcct2 = new Referral_Account__c(Name='Update Test');
        Referral_Account__c refAcct3 = new Referral_Account__c(Name='Delete Test');
        Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2,refAcct3};
        ReferralAccountMethods.SKIP_TRIGGERS=true;
        insert refAccts;
        Referral_Account_Team__c ratForAcct2 = new Referral_Account_Team__c(Referral_Account__c = refAcct2.Id,Team_Member_Name__c=users[0].Id);
        Referral_Account_Team__c ratForAcct3 = new Referral_Account_Team__c(Referral_Account__c = refAcct3.Id,Team_Member_Name__c=users[0].Id);
        insert new Referral_Account_Team__c[]{ratForAcct2,ratForAcct3};
        // reset the flags
        refAcct2.DedicatedRepChanged__c=false;
        refAcct3.DedicatedRepChanged__c=false;
        update new Referral_Account__c[]{refAcct2,refAcct3};
        
        Test.startTest();
        Referral_Account_Team__c ratForAcct1 = new Referral_Account_Team__c(Referral_Account__c = refAcct1.Id,Team_Member_Name__c=users[0].Id);
        insert ratForAcct1;
        ratForAcct2.Team_Member_Name__c= users[1].Id;
        update ratForAcct2;
        delete ratForAcct3;
        Test.stopTest();
        
        Referral_Account__c uRefAcct1 = [SELECT Id,DedicatedRepChanged__c from Referral_Account__c WHERE Id=:refAcct1.Id LIMIT 1];
        system.assertEquals(true,uRefAcct1.DedicatedRepChanged__c);
        
        Referral_Account__c uRefAcct2 = [SELECT Id,DedicatedRepChanged__c from Referral_Account__c WHERE Id=:refAcct2.Id LIMIT 1];
        system.assertEquals(true,uRefAcct2.DedicatedRepChanged__c);
        
        Referral_Account__c uRefAcct3 = [SELECT Id,DedicatedRepChanged__c from Referral_Account__c WHERE Id=:refAcct3.Id LIMIT 1];
        system.assertEquals(true,uRefAcct3.DedicatedRepChanged__c);
        
    }
    static testMethod void testDuplicate() {
        User[] hnbReps = [SELECT id FROM User WHERE isActive = true AND Sales_Org__c = 'HNBF' LIMIT 2];
        Referral_Account__c refAcct1 = new Referral_Account__c(Name='RA Test');
        ReferralAccountMethods.SKIP_TRIGGERS=true;
        insert refAcct1;
        Referral_Account_Team__c rat1ForRefAcct1 = new Referral_Account_Team__c(Referral_Account__c = refAcct1.Id,Team_Member_Name__c=hnbReps[0].Id);
        insert rat1ForRefAcct1;
        
        Test.startTest();
        Referral_Account_Team__c rat2ForRefAcct1 = new Referral_Account_Team__c(Referral_Account__c = refAcct1.Id,Team_Member_Name__c=hnbReps[1].Id);
        try{
            insert rat2ForRefAcct1;
            System.assertEquals(1,2,'We should not get here!');
        }
        catch (Exception e){
            system.assert(e.getMessage().contains('already exists'));
        }
        Test.stopTest();
    } // testDuplicate
    
    static testMethod void testDuplicate2() {
        User[] hnbReps = [SELECT id FROM User WHERE isActive = true AND Sales_Org__c = 'HNBF' LIMIT 2];
        Referral_Account__c refAcct1 = new Referral_Account__c(Name='RA Test');
        ReferralAccountMethods.SKIP_TRIGGERS=true;
        insert refAcct1;
        Referral_Account_Team__c rat1ForRefAcct1 = new Referral_Account_Team__c(Referral_Account__c = refAcct1.Id,Team_Member_Name__c=hnbReps[0].Id);
        Referral_Account_Team__c rat1ForRefAcct2 = new Referral_Account_Team__c(Referral_Account__c = refAcct1.Id,Team_Member_Name__c=hnbReps[1].Id);
        try {
            insert new Referral_Account_Team__c[]{rat1ForRefAcct1,rat1ForRefAcct2};
            System.assertEquals(1,2,'Should not get here');
        } catch (Exception e) {
            System.assertEquals(true,e.getMessage().contains('in the insert list more than once'));
        }
        
        insert rat1ForRefAcct1;
        // try to add the same person
        Referral_Account_Team__c rat2ForRefAcct1 = new Referral_Account_Team__c(Referral_Account__c = refAcct1.Id,Team_Member_Name__c=hnbReps[0].Id);
        try{
            insert rat2ForRefAcct1;
            System.assertEquals(1,2,'We should not get here!');
        }
        catch (Exception e){
            system.assert(e.getMessage().contains('already exists'));
        }
    } // testDuplicate2
    

} // class ReferralAccountTeamMethodsTest