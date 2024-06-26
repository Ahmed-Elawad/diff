/* Test Class for Reference PEO Medical UW Object
*
*   HISTORY
*  ---------
*   02/22/2018  Jacob Hinds     Created
*   11/05/2018  Jermaine Stukes Added testRespondHours()
*   04/20/2020  Manmeet Vaseer  Modified testSLA() and testSync() for SFDC-3072.
*
*
*/
@isTest
private class ReferencePEOMedicalUWMethodsTest {

    static testMethod void testCheckForExistingPEOUW() {
        Id peoRT = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity').getRecordTypeId();
        Opportunity oppty = new Opportunity(Name='test',CloseDate=date.today(),RecordTypeId=peoRT,StageName='Pending');
        insert oppty;
        
        Reference_PEO_Medical_UW__c uw = new Reference_PEO_Medical_UW__c(Opportunity__c = oppty.Id);
        insert uw;
        
        try{
            Reference_PEO_Medical_UW__c uw2 = new Reference_PEO_Medical_UW__c(Opportunity__c = oppty.Id);
            insert uw2;
        }
        catch(DMLException e){
            system.debug('testCheckForExistingPEOUW error:'+e);
            for (Integer i = 0; i < e.getNumDml(); i++) {
                system.assert(e.getDmlMessage(i).contains('A Reference PEO UW record already exists on the related opportunity'));
            }
        }
    }
    static testMethod void testSLA() {
        Id peoRT = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity').getRecordTypeId();
        Opportunity oppty = new Opportunity(Name='test',CloseDate=date.today(),RecordTypeId=peoRT,StageName='Pending');
        insert oppty;
        
        DateTime slaStartDate = DateTime.newInstance(2018,2,22,8,0,0);  //Thursday
        DateTime approvalDate = DateTime.newInstance(2018,2,22,10,0,0);
        Reference_PEO_Medical_UW__c uw = new Reference_PEO_Medical_UW__c(Opportunity__c = oppty.Id,Date_Submitted__c=slaStartDate,
                                                Date_Submitted_to_UW__c=slaStartDate,Deal_100_Complete__c=slaStartDate,UW_SLA__c = '48 (2 Business Days)',Approval_Date__c=approvalDate);
        insert uw;
        
        Test.startTest();
        Reference_PEO_Medical_UW__c newUw = [SELECT Date_Submitted__c,Response_Target_Timeframe__c,Date_Submitted_to_UW__c,Deal_100_Complete__c,Approval_Timeframe__c,UW_SLA__c, Approval_Due__c FROM Reference_PEO_Medical_UW__c WHERE id=:uw.Id];
        /*
         * To test, ReferencePEOMedicalUWMethods.processResponseTargetSLA() is called by trigger.
         * 
         * Business Hours for 'PEO 24' are 12:00AM - 12:00AM (EST), which is total of 24 working hours for a Rep.
         * slaStartDate/Date_Submitted__c = Thursday, 02/22/2018 08:00:00 AM (EST) i.e. Thursday, 02/22/2018 01:00:00 PM (GMT)
         * The reponse time is hard coded to 24 hours in processResponseTargetSLA(). 
         * The business hours is set to 24 hours in Salesforce for 'PEO 24' and the respose time is 24 hours so it will take 24/24=1 business day to respond.
         * That will equate Response_Target_Timeframe__c to Monday, 02/23/2018 08:00:00 AM (EST)
         * and Monday, 02/23/2018 01:00:00 PM (GMT) i.e. +5 hours for GMT (non daylight saving time)
         * 
         * DateTime.newInstance - Contstruct time in EST but returns time in GMT.
         */
        system.assertEquals(DateTime.newInstance(2018,2,23,8,0,0),newUw.Response_Target_Timeframe__c);
        
        /*
         * Deal_100_Complete__c is when the deal was completed and Approval_Date__c when the deal was approved. Basically, Start and End dates for a deal.
         * Approval_Due__c = The date when the task supposed to be completed i.e. Deal_100_Complete__c+SLA
         * 
         * UW_SLA__c is '48 (2 Business Days)'. 
         * That is, the due date (Approval_Due__c: 02/24/2018 08:00:00 AM (EST)) for this SLA is 2 business day from Deal_100_Complete__c (02/22/2018 08:00:00 AM (EST)).
		*/        
        system.assertEquals('Inside SLA',newUw.Approval_Timeframe__c);
		system.assertNotEquals(null, newUw.Approval_Due__c, 'Approval Due should not be null after inserting.');
		system.assertEquals(DateTime.newInstance(2018,2,26,8,0,0), newUw.Approval_Due__c, 'Approval Due should be within 2 business days.');
        
        newUw.Approval_Date__c = DateTime.newInstance(2018,3,15,8,0,0);
        newUw.UW_SLA__c = '120 (5 Business Days)';
        update newUw;
        
        /*
         * To test, ReferencePEOMedicalUWMethods.processApprovalTimeframeSLA() is called by ReferencePEOMedicalUWTrigger trigger.
         * 
         * Difference between a deal start date (Deal_100_Complete__c: 2018,2,22,8,0,0) and the deal end date (Approval_Date__c: 2018,3,15,8,0,0) is 503 hours.
         * But the UW_SLA__c is '120 (5 Business Days)'.
         * So, 503 > 120, which means that the request was completed Outside SLA (or due date i.e. Approval_Due__c: 2018-02-27 08:00:00)
         */ 
        newUw = [SELECT Date_Submitted__c,Response_Target_Timeframe__c,Date_Submitted_to_UW__c,Deal_100_Complete__c,Approval_Timeframe__c, Approval_Due__c FROM Reference_PEO_Medical_UW__c WHERE id=:uw.Id];
        system.assertEquals('Outside SLA',newUw.Approval_Timeframe__c);
		system.assertNotEquals(null, newUw.Approval_Due__c, 'Approval Due should not be null after updating.');
		system.assertEquals(DateTime.newInstance(2018,3,1,8,0,0), newUw.Approval_Due__c, 'Approval Due is more than 5 business days.');
       
        Test.stopTest();
    }
    static testMethod void testRespondHours() {
        Id peoRT = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity').getRecordTypeId();
        Opportunity oppty = new Opportunity(Name='test',CloseDate=date.today(),RecordTypeId=peoRT,StageName='Pending');
        insert oppty;
        Reference_PEO_Medical_UW__c uw = new Reference_PEO_Medical_UW__c(Opportunity__c = oppty.Id);
        insert uw;
        Test.startTest();
        Reference_PEO_Medical_UW__c newUw = [SELECT Date_Submitted__c, Agency_Response_Time__c, Response_Target_Timeframe__c,Date_Submitted_to_UW__c,Approval_Timeframe__c,Approval_Due__c FROM Reference_PEO_Medical_UW__c WHERE id=:uw.Id];        
        system.assertEquals(Null,newUw.Agency_Response_Time__c);
        newUw.Date_Submitted_to_Agency__c = DateTime.newInstance(2018,11,01,8,0,0);
        newUw.Date_Response_from_Agency__c = DateTime.newInstance(2018,11,01,8,0,0);
        update newUw;
        
        newUw = [SELECT Agency_Response_Time__c FROM Reference_PEO_Medical_UW__c WHERE id=:uw.Id];
        system.assertNotEquals(Null, newUw.Agency_Response_Time__c);
        
        Test.stopTest();
    }
    static testMethod void testSync(){
        Id peoRT = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity').getRecordTypeId();
        Opportunity oppty = new Opportunity(Name='test',CloseDate=date.today(),RecordTypeId=peoRT,StageName='Pending');
        insert oppty;
        
        Reference_PEO_Medical_UW__c uw = new Reference_PEO_Medical_UW__c(Opportunity__c = oppty.Id,FE_Completed_Date__c=system.today(),
                                                Approved_Rate_Band_UW__c='1',Kaiser_Band_if_dual_quote__c = '2',PEO_Carrier_Location__c='texas',
                                                Underwriter__c=UserInfo.getUserId(),Approval_Reason__c='Approved or something',EPO_HMO_ACO_Approved_Rate_Band__c='6');
        insert uw;
        test.startTest();
        
        Reference_PEO__c peo = new Reference_PEO__c(Opportunity__c = oppty.Id);
        insert peo;
        
        Reference_PEO__c uPeo = [SELECT Id,Final_Rate_Band__c,Final_Approval_Date__c,Final_Medical_Approval_2__c,Kaiser_Rate_Band_if_applic__c,
                                    Medical_Carrier__c,Initial_Medical_UW__c,Initial_Medical_UW_Approval__c,EPO_HMO_ACO_Rate_Band__c FROM Reference_PEO__c WHERE Id=:peo.Id LIMIT 1];
                                    
        system.assertEquals(uw.FE_Completed_Date__c,uPeo.Final_Approval_Date__c);
        system.assertEquals(uw.Approved_Rate_Band_UW__c,String.valueOf(uPeo.Final_Rate_Band__c));
        system.assertEquals(uw.Kaiser_Band_if_dual_quote__c,uPeo.Kaiser_Rate_Band_if_applic__c);
        system.assertEquals(uw.PEO_Carrier_Location__c,uPeo.Medical_Carrier__c);
        system.assertEquals(uw.Underwriter__c,uPeo.Initial_Medical_UW__c);
        system.assertEquals(uw.EPO_HMO_ACO_Approved_Rate_Band__c,uPeo.EPO_HMO_ACO_Rate_Band__c);
        system.assertEquals('Approved',uPeo.Initial_Medical_UW_Approval__c);
        
        Reference_PEO_Medical_UW__c uUW = [SELECT Id,Ref_Peo__c FROM Reference_PEO_Medical_UW__c WHERE Id=:uw.Id LIMIT 1];
        system.assertEquals(uPeo.Id,uUW.Ref_Peo__c);
        Test.stopTest();
    }
}