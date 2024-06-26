/* 
 * Test methods for the ApprovalProcessController.
 *
 * History
 * -------
 * 06/30/2016 Jermaine Stukes Created
 *
 */
@isTest
public class ApprovalProcessControllerTest 
{
    static testMethod void testGetRefList()
    {
        ApprovalProcessController apc = new ApprovalProcessController();
        //Create Join
        ReferralJoin__c testJoin = new ReferralJoin__c();
        Insert(testJoin);
        //Add Join to referral
        Referral__c testReferral = new Referral__c(name = 'test');
        testReferral.ReferralJoin__c = testJoin.Id;
        insert testReferral;
        apc.referraljoinId = testJoin.Id;
        apc.referralId = testReferral.Id;
        list<Referral__c> testList = new list<Referral__c>();
        testList = apc.getRefList();
        System.assertEquals(true, apc.referralId == testReferral.Id);
        System.assertEquals(true, testList != Null);
       
    }
    static testMethod void testGetAttachment()
    {
        ApprovalProcessController apc = new ApprovalProcessController();
        Referral__c ra = new Referral__c(Name='Test Ref Account');
        insert ra;
        Attachment att = new Attachment();
        att.Name = 'test.pdf';
        att.Body = Blob.valueOf('Unit Test Attachment Body');
        att.ParentId = ra.Id;
        insert att;
        apc.referralId = ra.Id;
        apc.getAttachment();
        System.assertEquals(true, apc.refAttachment != Null);
    }
    static testMethod void testMisc()
    {
        
        Referral__c testReferral = new Referral__c(name = 'test');
        insert testReferral;
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
		app.setObjectId(testReferral.Id);
        ApprovalProcessController apc = new ApprovalProcessController();
        apc.referralId = testReferral.Id;
        apc.getrepLink();
        System.assertEquals(true, apc.dsaLink != '');
    }
}