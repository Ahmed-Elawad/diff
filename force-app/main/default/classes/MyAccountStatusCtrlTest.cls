/* 
* The test methods for the MyAccountStatusCtrl class.
*
* History
* -------
  01/11/2023 Jidesh         Created

*/
@isTest
public class MyAccountStatusCtrlTest {

    static testMethod void testLoadData() {
        Profile prof = [SELECT Id FROM Profile where name='CPA Customer Community Login User Clone' LIMIT 1];
        User otherAdmin = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true AND Id!=:UserInfo.getUserId() LIMIT 1];
        
        Referral_Account__c refAcc = new Referral_Account__c();
        refAcc.Name = 'Peo test';
        refAcc.MutualClientTier__c = 'Core';
        insert refAcc;
        
        System.debug('refAcc:'+refAcc);
        
        Account acc = new Account();
        acc.Name = 'Peo test';
        //acc.CPA_Name_Ref__r.Referral_Account__c = refAcc.Id;
        insert acc;
        
        
        Contact ctct = new Contact(AccountId=acc.id,
                                    FirstName = 'test',
                                    LastName = 'user',
                                    Email='testing@testingtestTest.com'); 
        insert ctct;
        
        Referral_Contact__c refCon = new Referral_Contact__c(Referral_Account__c = refAcc.Id, 
                                                             First_Name__c = 'test',
                                                             Last_Name__c = 'user',
                                                             Email__c = 'testing@testingtestTest.com',
                                                             Contact__c = ctct.Id,
                                                            Admin_CPA__c = false,
                                                            CPA_portal_shared__c = 'Yes');
        insert refCon;
        
        ctct.Mirror_Ref_Ctct__c = refCon.Id;
        Update ctct;
        
        
        Opportunity opp = new Opportunity(
            AccountId = acc.id,
            Name = 'Test Opty',
            CloseDate = System.today(),
            StageName = 'Proposal',
            Referral_Contact__c = refCon.Id,
            Date_Lead_Submitted__c = system.today(),
            Referral_Account__c = refAcc.Id,
            OpportunityType__c='Payroll'        
        );
        Insert opp;
        
        //Referral_Contact__c rCon = [Select id, Name, Referral_Account__c from Referral_Contact__c where id=:refCon.id limit 1];
        //System.debug('rCon:'+rCon);
        //acc.CPA_Name_Ref__c = refCon.Id;
        //acc.CPA_Name_Ref__r.Referral_Account__c = rCon.Referral_Account__c;
        //Update acc;
            
        Id vfpageUserId;
        system.runAs(otherAdmin){
            User testUser = new User(
                UserName = ctct.email,
                FirstName = ctct.FirstName,
                LastName =ctct.LastName,
                Alias = 'alias',
                email = ctct.Email,
                ContactId = ctct.id,
                ProfileId = prof.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickname = 'nickName',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Sales_Org__c = 'PAS'
            );
         
            insert testUser;
           
            vfpageUserId = testUser.Id;
            System.debug('vfpageUserId :'+vfpageUserId);
            //MyAccountStatusCtrl mstCtrl = new MyAccountStatusCtrl();
        }
        User vfPageUser = [SELECT id FROM User WHERE Id =:vfpageUserId LIMIT 1];
        system.runAs(vfPageUser){
            System.debug('vfPageUser :'+vfPageUser);
            MyAccountStatusCtrl mstCtrl = new MyAccountStatusCtrl();
            mstCtrl.displayImage('Signature');
            mstCtrl.displayImage('Elite');
            //mstCtrl.loadAcctInList(0,1);
            //mstCtrl.loadOppInList(0,1);
            mstCtrl.handleAcctIsNext();
            mstCtrl.handleOppIsNext();
            mstCtrl.acceptTermAndCondition = true;
            mstCtrl.hideModelPopup();
            mstCtrl.loadOppMoreResult();
            mstCtrl.loadAcctMoreResult();
            mstCtrl.redirectToReferClientPage();
          MyAccountStatusCtrl.AccountWrapper objAW = new MyAccountStatusCtrl.AccountWrapper();
            objAW.acctName = 'test';
            objAW.rcName = 'test';
            objAW.lastmodifiedDate = Date.today();
            //mstCtrl.AccountWrapper();
            //MyAccountStatusCtrl.AccountWrapper acctWrap = new MyAccountStatusCtrl.AccountWrapper();
            //Need to write asserts
        }
        List<Referral_Contact__c> refConResults = [Select id, name, Admin_CPA__c, Contact__c, CPA_Program_status__c,CPA_portal_shared__c from Referral_Contact__c];
        System.debug('refConResults:'+refConResults);
        System.assertEquals(1, refConResults.size());
        System.assertEquals(true, refConResults[0].Admin_CPA__c);
        
       
    }
    
   static testMethod void testdisplayImage() {
       
    }
}