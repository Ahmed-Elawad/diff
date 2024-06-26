/* Test Method for UpdateOppFieldsQueueable
*
*History
*----------------
* 
*   03/01/2023 Jaipal      Created
   

*/
@isTest
public class UpdateOppFieldsQueueableTest 
{
    static testMethod void TestList1() 
    {
        
        
        Referral_Account__c ra = new Referral_Account__c(Name = 'Test');
        ra.Name ='Test';
        
        insert ra;
        Opportunity opp = new Opportunity(Name = 'Test1', StageName = label.OppStage_Won, CloseDate= date.parse('12/27/2009'), Referral_Account__c = ra.Id, LeadSource = 'Referral-CPA' );
        insert opp;
        ra.Hosted_Client__c= true;
        update ra;
        String refAcctId = ra.Id;
        system.assertEquals(true, ra.Hosted_Client__c);
       UpdateOppFieldsQueueable uofq = new UpdateOppFieldsQueueable(refAcctId);
        Test.startTest();
        System.enqueueJob(uofq);
        Test.stopTest();
      //  system.assertEquals(Label.Approved_Quote_Exception_Reason, opp.Approved_Quote_Exception_Reason__c);
      //  system.assertEquals(true, opp.Approved_Quotes_Exception__c);
        
    }
}