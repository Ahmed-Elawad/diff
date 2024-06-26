/**
 * Test Class for Record Reassignment Controller
 *
 ** History
 * -------
 * 05/19/2017 Jacob Hinds        Created.
 */
@isTest
private class RecordReassignmentControllerTest {

    static testMethod void testReassignment() {
        
        Account acct = new Account(Name='test');
        insert acct;
        Contact ctct = new Contact(FirstName='Test',LastName='Contact',AccountId=acct.Id);
        insert ctct;
        Lead ld = new Lead(LastName='Lead',Company='testland');
        insert ld;
        Opportunity oppty = new Opportunity(Name ='Test',StageName='New',CloseDate=Date.today());
        insert oppty;
        //insert only with lead so lead gets owner synced first.  This is the only object that can be owned by a queue.
        Referral__c ref = new Referral__c(SourceLead__c = ld.Id);
        insert ref;
        
        Group ibQueue = [SELECT Id,Name FROM Group WHERE Type='Queue' AND Name='NSS Inbound Queue' LIMIT 1];
        
        User testUser = [SELECT Id FROM User WHERE Id!=:UserInfo.getUserId() AND isActive=true AND Profile.Name='System Administrator' LIMIT 1];
        
        insert new NSSTeamMap__c(Name = 'Inbound',Available_Queues__c='NSS Inbound Queue;NSS Outbound Queue');
        
        Test.startTest();
        
        //test to see if it found the referral from lead
        PageReference rrcURL = new PageReference('/apex/RecordReassignment?objId='+ld.id);
        Test.setCurrentPage(rrcURL);
        RecordReassignmentController rrc = new RecordReassignmentController();
        system.assert(rrc.objectToUpdate!=null);
        //test to see the available queues made it
        rrc.runningUser.NSS_Team__c = 'Inbound';
        List<SelectOption> queueOptions = rrc.getQueueOptions();
        system.assert(queueOptions.size()>0);
        //choose a queue, save, check owner
        rrc.selectedQueue = ibQueue.Name;
        rrc.save();
        ref = [SELECT Id,OwnerId FROM Referral__c WHERE Id=:ref.Id];
        system.assertEquals(ibQueue.Id,ref.OwnerId);
        
        //new test with contact
        ref.SourceContact__c = ctct.Id;
        ref.Account__c = acct.Id;
        update ref;
        rrcURL = new PageReference('/apex/RecordReassignment?objId='+ctct.id);
        Test.setCurrentPage(rrcURL);
        rrc = new RecordReassignmentController();
        system.assert(rrc.objectToUpdate!=null);
        //choose a user, save, check owner
        rrc.selectedUser.Referring_User__c = testUser.Id;
        rrc.save();
        ref = [SELECT Id,OwnerId FROM Referral__c WHERE Id=:ref.Id];
        system.assertEquals(testUser.Id,ref.OwnerId);
        
        //test with account + multiple referrals
        Referral__c ref2 = new Referral__c(SourceLead__c = ld.Id,SourceContact__c = ctct.Id,Account__c = acct.Id);
        insert ref2;
        rrcURL = new PageReference('/apex/RecordReassignment?objId='+acct.id);
        Test.setCurrentPage(rrcURL);
        rrc = new RecordReassignmentController();
        system.assertEquals(true,rrc.multipleReferrals);
        //select one of the referral options
        ReferralWrapper wrap1 = rrc.wraps[0];
        wrap1.selected = true;
        rrc.storeSelectedReferral();
        system.assertEquals(wrap1.ref.Id,rrc.objectToUpdate.Id);
        //select the other referral option
        ReferralWrapper wrap2 = rrc.wraps[1];
        wrap2.selected = true;
        rrc.storeSelectedReferral();
        system.assertEquals(wrap2.ref.Id,rrc.objectToUpdate.Id);
        //deselect the selected option
        wrap2.selected = false;
        rrc.storeSelectedReferral();
        system.assert(rrc.objectToUpdate == null);
        
        //test with oppty. oppty isn't attached to referral so it won't bring anything back in the query
        rrcURL = new PageReference('/apex/RecordReassignment?objId='+oppty.id);
        Test.setCurrentPage(rrcURL);
        rrc = new RecordReassignmentController();
        system.assert(rrc.objectToUpdate==null);
        system.assertEquals(false,rrc.multipleReferrals);
        Test.stopTest();
        
    }
}