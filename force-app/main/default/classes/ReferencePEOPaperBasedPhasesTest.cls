/**
 * 06/16/2017	Lynn Michels	Created
 */
@isTest
private class ReferencePEOPaperBasedPhasesTest {

        static testMethod void testInitialSetup() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.initialSetupColor); 
     		refPEO.Client_Shell_Creation_Target__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.initialSetupColor);
         	
         	refPEO.Client_Shell_Creation_Target__c = beforeToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.initialSetupColor);
            
            refPEO.Client_Shell_Creation_Target__c = afterToday;
     		refPEO.Onbrdg_Spreadsheet_Rec__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		system.assertEquals('greenOutline',controller.initialSetupColor);     
        }
        
         static testMethod void testEmpDataRecd() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.empDataRecdColor);
     		refPEO.Client_Shell_Creation__c = t;
     		refPEO.Onbrdg_Spreadsheet_Rec_Target__c = afterToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('greenOutline',controller.empDataRecdColor);
     		system.assertEquals('green',controller.initialSetupColor); 
     		
     		refPEO.Onbrdg_Spreadsheet_Rec_Target__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.empDataRecdColor);
         	
         	refPEO.Onbrdg_Spreadsheet_Rec_Target__c = beforeToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.empDataRecdColor);
        }//testEmpDataRecd
        
        static testMethod void testworkComp() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.workCompColor);
     		 
     		refPEO.Client_Shell_Creation__c = t;
     		refPEO.Onbrdg_Spreadsheet_Rec__c = t;
     		refPEO.WC_Underwriting_Review_Target__c = afterToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('green',controller.empDataRecdColor); 
     		system.assertEquals('greenOutline',controller.workCompColor); 
     		
     		refPEO.WC_Underwriting_Review_Target__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.workCompColor);
         	
         	refPEO.WC_Underwriting_Review_Target__c = beforeToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.workCompColor);
        }//testworkComp
        
        static testMethod void testnepReceived() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.nepReceivedColor);
     		 
     		refPEO.Client_Shell_Creation__c = t;
     		refPEO.Onbrdg_Spreadsheet_Rec__c = t;
     		refPEO.WC_Underwriting_Review_Complete__c = t;
     		refPEO.NEP_Submission_Approved_Target__c = afterToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('greenOutline',controller.nepReceivedColor); 
     		system.assertEquals('green',controller.workCompColor); 
     		
     		refPEO.NEP_Submission_Approved_Target__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.nepReceivedColor);
         	
         	refPEO.NEP_Submission_Approved_Target__c = beforeToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.nepReceivedColor);
        }//testnepReceived
        
         static testMethod void testMedApproval() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.medUWApprovalColor);
     		 
     		refPEO.Client_Shell_Creation__c = t;
     		refPEO.Onbrdg_Spreadsheet_Rec__c = t;
     		refPEO.WC_Underwriting_Review_Complete__c = t;
     		refPEO.NEP_Submission_Approved__c = t;
     		refPEO.Final_Medical_Approval_Target_Milestone__c = afterToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('green',controller.nepReceivedColor); 
     		system.assertEquals('greenOutline',controller.medUWApprovalColor); 
     		
     		refPEO.Final_Medical_Approval_Target_Milestone__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.medUWApprovalColor);
         	
         	refPEO.Final_Medical_Approval_Target_Milestone__c = beforeToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.medUWApprovalColor);
        }//testMedApproval
        
         static testMethod void testCompleteSubmission() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.completeSubmissionColor);
     		 
     		refPEO.Client_Shell_Creation__c = t;
     		refPEO.Onbrdg_Spreadsheet_Rec__c = t;
     		refPEO.WC_Underwriting_Review_Complete__c = t;
     		refPEO.NEP_Submission_Approved__c = t;
     		refPEO.Final_Medical_Approval_Milestone__c = t;
     		refPEO.Complete_Deal_Submission_Target__c = afterToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('green',controller.medUWApprovalColor); 
     		system.assertEquals('greenOutline',controller.completeSubmissionColor); 
     		
     		refPEO.Complete_Deal_Submission_Target__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.completeSubmissionColor);
         	
         	refPEO.Complete_Deal_Submission_Target__c = beforeToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.completeSubmissionColor);
        }//testCompleteSubmission
        
        static testMethod void testPassToNewLoads() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.passToNewLoadsColor);
     		 
     		refPEO.Client_Shell_Creation__c = t;
     		refPEO.Onbrdg_Spreadsheet_Rec__c = t;
     		refPEO.WC_Underwriting_Review_Complete__c = t;
     		refPEO.NEP_Submission_Approved__c = t;
     		refPEO.Final_Medical_Approval_Milestone__c = t;
     		refPEO.Complete_Deal_Submission__c = t;
     		refPEO.Pass_to_New_Biz_Target__c = afterToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('green',controller.completeSubmissionColor); 
     		system.assertEquals('greenOutline',controller.passToNewLoadsColor); 
     		
     		refPEO.Pass_to_New_Biz_Target__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.passToNewLoadsColor);
         	
         	refPEO.Pass_to_New_Biz_Target__c = beforeToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.passToNewLoadsColor);
        }//testPassToNewLoads
        
        static testMethod void testInitialSetupComplete() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('#AFAFAF',controller.setupCompleteCircleColor);
     		 
     		refPEO.Client_Shell_Creation__c = t;
     		refPEO.Onbrdg_Spreadsheet_Rec__c = t;
     		refPEO.WC_Underwriting_Review_Complete__c = t;
     		refPEO.NEP_Submission_Approved__c = t;
     		refPEO.Final_Medical_Approval_Milestone__c = t;
     		refPEO.Complete_Deal_Submission__c = t;
     		refPEO.Pass_to_New_Biz__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('#2F9F1F',controller.setupCompleteCircleColor); 
     		system.assertEquals('green',controller.passToNewLoadsColor); 
        }//testInitialSetupComplete
        
	/*Test Payroll Conversion Phase Milestones */
	 static testMethod void testPayrollConversionSetup() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('#AFAFAF',controller.payrollConversionSetupCircleColor);
     		 
     		refPEO.Pass_to_New_Biz__c = t;
     		refPEO.WC_Setup__c = t;
     		
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('#2F9F1F',controller.payrollConversionSetupCircleColor); 
        }//testPayrollConversionSetup
        
         static testMethod void testWCSetup() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.wcSetupColor);
     		 
     		refPEO.Pass_to_New_Biz__c = t;
     		refPEO.WC_Setup_Target__c = afterToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('greenOutline',controller.wcSetupColor);  
     		
     		refPEO.WC_Setup_Target__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.wcSetupColor);
         	
         	refPEO.WC_Setup_Target__c = beforeToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.wcSetupColor);
        }//testWCSetup
        
        static testMethod void testEeLoad() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.eeLoadColor);
     		 
     		refPEO.Pass_to_New_Biz__c = t;
     		refPEO.WC_Setup__c = t;
     		refPEO.Employee_Load_Complete_Target__c = afterToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('greenOutline',controller.eeLoadColor);
     		system.assertEquals('green',controller.wcSetupColor);
     		
     		refPEO.Employee_Load_Complete_Target__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.eeLoadColor);
         	
         	refPEO.Employee_Load_Complete_Target__c = beforeToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.eeLoadColor);
        }//testEeLoad
        
         static testMethod void testBenefitsSetup() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.benefitsSetupColor);
     		 
     		refPEO.Pass_to_New_Biz__c = t;
     		refPEO.Employee_Load_Complete__c = t;
     		refPEO.Benefits_ER_Contribution_Loaded_Target__c = afterToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('green',controller.eeLoadColor); 
     		system.assertEquals('greenOutline',controller.benefitsSetupColor);
     		
     		refPEO.Benefits_ER_Contribution_Loaded_Target__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.benefitsSetupColor);
         	
         	refPEO.Benefits_ER_Contribution_Loaded_Target__c = beforeToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.benefitsSetupColor);
        }//testBenefitsSetup
        
        static testMethod void testReadyToRun() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.benefitsSetupColor);
     		 
     		refPEO.Pass_to_New_Biz__c = t;
     		refPEO.Employee_Load_Complete__c = t;
     		refPEO.Benefits_ER_Contribution_Loaded__c = t;
     		refPEO.Ready_to_Process_Payroll_Target__c = afterToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('green',controller.benefitsSetupColor); 
     		system.assertEquals('greenOutline',controller.readyToRunColor);
     		
     		refPEO.Ready_to_Process_Payroll_Target__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.readyToRunColor);
         	
         	refPEO.Ready_to_Process_Payroll_Target__c = beforeToday; 
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.readyToRunColor);
        }//testReadytoRun
        
         static testMethod void testPayrollProcessing() {
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.payrollProcessingColor);
     		 
     		refPEO.Pass_to_New_Biz__c = t;
     		refPEO.Employee_Load_Complete__c = t;
     		refPEO.Benefits_ER_Contribution_Loaded__c = t;
     		refPEO.Ready_to_Process_Payroll2__c = t;
     		refPEO.Actual_Payroll_Process_Target__c = afterToday;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('green',controller.readyToRunColor); 
     		system.assertEquals('greenOutline',controller.payrollProcessingColor);
     		
     		refPEO.Actual_Payroll_Process_Target__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
         	system.assertEquals('yellow',controller.payrollProcessingColor);
         	
         	refPEO.Actual_Payroll_Process_Target__c = beforeToday; 
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
            system.assertEquals('red',controller.payrollProcessingColor);
        }//testPayrollProcessing
        
        static testMethod void test1stPayrollComplete() { 
	        date t = date.today();
	        date afterToday = t.addDays(3); 
	        date beforeToday = t.addDays(-3); 
        
        	Reference_PEO__c refPEO = new Reference_PEO__c( );
        	insert refPEO;
	        Test.SetCurrentPageReference(Page.ReferencePEOPaperBasedPhases);
	        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
	        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
	        ReferencePEOPaperBasedPhasesController controller = new ReferencePEOPaperBasedPhasesController(sc);
      
     		system.assertEquals('gray',controller.processingCompleteColor);
     		  
     		refPEO.Pass_to_New_Biz__c = t;
     		refPEO.Employee_Load_Complete__c = t;
     		refPEO.Benefits_ER_Contribution_Loaded__c = t;
     		refPEO.Ready_to_Process_Payroll2__c = t;
			refPEO.Actual_Payroll_Process__c = t;
     		update refPEO;
     		controller = new ReferencePEOPaperBasedPhasesController(sc);
     		
     		system.assertEquals('green',controller.processingCompleteColor); 
     		
        }//test1stPayrollComplete
}