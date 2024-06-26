/* 
 *  CommissionAuditUpdate Test Class
 *   
 * History
 * -------
 * 04/13/2016 Jacob Hinds     Created
 */
@isTest
private class CommissionAuditUpdateTest {

    static testMethod void testUpdate() {
    	
    	Id caseRT = RecordTypeHelper.getRecordType('Sales CSA Support Cases Record Type', 'Case').getRecordTypeId();
    	
    	Case case1 = new Case(RecordTypeId=caseRT,Origin='CSA Submit Request',Type='CSA Inquiry');
    	Case case2 = new Case(RecordTypeId=caseRT,Origin='CSA Submit Request',Type='CSA Inquiry');
    	Case case3 = new Case(RecordTypeId=caseRT,Origin='CSA Submit Request',Type='CSA Inquiry');
		Case[] cases = new Case[]{case1,case2,case3};
		insert cases;
		
		CSA_Inquiries__c csa1 = new CSA_Inquiries__c(Case__c=case1.Id);
		CSA_Inquiries__c csa2 = new CSA_Inquiries__c(Case__c=case2.Id);
		CSA_Inquiries__c csa3 = new CSA_Inquiries__c(Case__c=case3.Id);
		CSA_Inquiries__c[] csas = new CSA_Inquiries__c[]{csa1,csa2,csa3};
		insert csas;
		
    	String csvString = 'CSA Inquiries ID,Approved/Reject Status,Reason Code,Corporate Comment,Case: Case ID,Case: Status,Case Comments\r\n';
    	csvString+=csa1.Id+',APPROVE,Change Of Owner,test test test,'+case1.Id+',Closed,testing\r\n';
    	csvString+=csa2.Id+',REJECT,Lost Client,tset tset tset,'+case2.Id+',Closed,testing\r\n';
    	csvString+=csa3.Id+',APPROVE,AICPA,tester,'+case3.Id+',Closed,testing\r\n';
        Blob csvBlob = Blob.valueOf(csvString);
        
        Referral__c rf1 = new Referral__c(Referral_Id__c = 'L07185080');
        Referral__c rf2 = new Referral__c(Referral_Id__c = 'L07185081');
        Referral__c rf3 = new Referral__c(Referral_Id__c = 'L07185082');
        Referral__c[] rfList = new Referral__c[]{rf1,rf2,rf3};
            insert rfList;
            
    	String csvString_Referral = 'MonthSaleReported__c,PendingRunOfPayroll__c,NbrOfEmployees__c,ActualRevenue__c,Disposition__c,BankLeadNotes__c,CommissionOverride__c,Referral_Id__c\r\n';
    	csvString_Referral+='10/29/2021,10/30/2021,1,1.222121,LOS,testing purpose10,TRUE,L07185080\r\n';
    	csvString_Referral+='10/29/2020,10/30/2020,2,2.222121,LOS,testing purpose10,FALSE,L07185081\r\n';
    	csvString_Referral+='10/29/2019,10/30/2019,3,3.222121,LOS,testing purpose10,TRUE,L07185082\r\n';
        Blob csvBlob_Referral = Blob.valueOf(csvString_Referral);

        
        Test.startTest();
        
        CommissionAuditUpdate controller = new CommissionAuditUpdate();
        controller.csvFileBody = csvBlob;
        controller.CSA_InquiriesMethod();
        
        CSA_Inquiries__c[] uCSAs = [SELECT Id,Approved_Reject_Status__c,Reason_Code__c,Corporate_Comment__c FROM CSA_Inquiries__c WHERE Id in :csas];
        System.debug('uCSAs = '+uCSAs);
		Case[] uCases = [SELECT Id,Status FROM Case WHERE Id in :cases];
		
		for(CSA_Inquiries__c csa: uCSAs){
			if(csa.Id == csa1.Id){
				System.assertEquals('APPROVE',csa.Approved_Reject_Status__c);
			}
			else if(csa.Id == csa2.Id){
				System.assertEquals('Lost Client',csa.Reason_Code__c);
			}
			else if(csa.Id == csa3.Id){
				System.assertEquals('tester',csa.Corporate_Comment__c);
			}
		}
		
		for(Case c:uCases){
			System.assertEquals(c.Status,'Closed');
		}
		
         CommissionAuditUpdate controller1 = new CommissionAuditUpdate();
        controller1.csvFileBody = csvBlob_Referral;
        controller1.ReferralsMethod();
        
        Referral__c[] rfcs = [SELECT id,MonthSaleReported__c,PendingRunOfPayroll__c,NbrOfEmployees__c,ActualRevenue__c,Disposition__c,BankLeadNotes__c,CommissionOverride__c,Referral_Id__c from Referral__c where id in :rfList];
	
        for(Referral__c rf: rfcs){
			if(rf.Id == rf1.Id){
				System.assertEquals(1,rf.NbrOfEmployees__c);
			}
			else if(rf.Id == rf2.Id){
				System.assertEquals('testing purpose10',rf.BankLeadNotes__c);
			}
			else if(rf.Id == rf3.Id){
				System.assertEquals('LOS',rf.Disposition__c);
			}
		}

        System.assertEquals(controller1.getReferralList.size(),3);

        //testing pagination
		System.assertEquals(controller.getTableRows.size(),3);
		controller.listSize = 2;
		controller.Next();
		System.assertEquals(controller.counter,2);
		System.assertEquals(controller.getDisableNext(),true);
		System.assertEquals(controller.getDisablePrevious(),false);
		controller.Previous();
		System.assertEquals(controller.counter,0);
		System.assertEquals(controller.getDisableNext(),false);
		System.assertEquals(controller.getDisablePrevious(),true);
		controller.End();
		System.assertEquals(controller.counter,2);
		System.assertEquals(controller.getPageSize(),3);
		controller.Beginning();
		System.assertEquals(controller.counter,0);
		System.assertEquals(controller.getCurrentCount(),1);
		System.assertEquals(controller.getPageSize(),2);        
		
		Test.stopTest();
    }
}