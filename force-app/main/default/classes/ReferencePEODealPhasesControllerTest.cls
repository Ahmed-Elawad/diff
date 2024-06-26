/**
 * 12/08/2016   Lynn Michels    Created
 */
@isTest
private class ReferencePEODealPhasesControllerTest {

    static testMethod void testAllGreen() {
        Reference_PEO__c refPEO = new Reference_PEO__c();
        insert refPEO;
        
        date t = date.today();
        date afterToday = t.addDays(-3); 
        
        Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
        System.CurrentPageReference().getParameters().put('id',refPEO.Id);
        ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
        
        system.assertEquals('#AFAFAF',controller.initialSetupCircleColor); 
        system.assertEquals('gray',controller.initialSetupColor);
        system.assertEquals('gray',controller.empDataRecdColor);
        system.assertEquals('gray',controller.workCompColor);
        system.assertEquals('gray',controller.benefitsSetupColor);
        system.assertEquals('gray',controller.eeLoadColor);
        system.assertEquals('gray',controller.eeOnboardingColor);
        system.assertEquals('gray',controller.medUVApprovalColor);
        system.assertEquals('gray',controller.medUVApprovalColor);
        system.assertEquals('gray',controller.approvedPassColor);
        system.assertEquals('gray',controller.setupCompleteColor);
        
        refPEO.Client_Shell_Creation__c = t;
        refPEO.Onbrdg_Spreadsheet_Rec__c = t;
        refPEO.WC_Underwriting_Review_Complete__c = t;
        refPEO.Benefits_ER_Contribution_Loaded__c = t;
        refPEO.Onbrdg_Spsheet_Review_and_EE_Load__c = t;
        refPEO.Onboarding_Open__c = t;
        refPEO.Onboarding_Complete__c = t;
        refPEO.Final_Medical_Approval_Milestone__c = t;
        refPEO.HRIS_Approved_Pass_to_New_Biz__c = t;
        
        refPEO.EE_Verification_and_QC__c = t;
        refPEO.Management_Hold_Removed_Date__c = t;
        refPEO.Ready_to_Process_Payroll2__c = t;
        refPEO.Actual_Payroll_Process__c = t;
        
        update refPEO;
        controller = new ReferencePEODealPhasesController(sc);
        system.assertEquals('#2F9F1F',controller.initialSetupCircleColor);
        system.assertEquals('green',controller.initialSetupColor);
        system.assertEquals('green',controller.empDataRecdColor);
        system.assertEquals('green',controller.workCompColor);
        system.assertEquals('green',controller.benefitsSetupColor);
        system.assertEquals('green',controller.eeLoadColor);
        system.assertEquals('green',controller.eeOnboardingColor);
        system.assertEquals('green',controller.medUVApprovalColor);
        system.assertEquals('green',controller.medUVApprovalColor);
        system.assertEquals('green',controller.approvedPassColor);
        system.assertEquals('green',controller.setupCompleteColor);
        
        system.assertEquals('green',controller.payrollConversionSetupColor);
        system.assertEquals('green',controller.eeVerificationColor);
        system.assertEquals('green',controller.holdsRemovedColor);
        system.assertEquals('green',controller.readyToRunColor);
        system.assertEquals('green',controller.payrollProcessingColor);
        system.assertEquals('green',controller.processingCompleteColor);
    }//end testAllGreen
        
/**********************************************************/
        static testMethod void testInitialSetup() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( Client_Shell_Creation_Target__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('#FFD933',controller.initialSetupCircleColor);
            
            refPEO.Client_Shell_Creation_Target__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('#DF281D',controller.initialSetupCircleColor);
        
    }
    
    static testMethod void testEmpDataRecd() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( Client_Shell_Creation__c = t,
                                                            Onbrdg_Spreadsheet_Rec_Target__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.empDataRecdColor);
            
            refPEO.Onbrdg_Spreadsheet_Rec_Target__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.empDataRecdColor);
    }// end Employee Data Received
    
    static testMethod void testWorkCompUWReview() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( Onbrdg_Spreadsheet_Rec__c = t,
                                                            WC_Underwriting_Review_Target__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.workCompColor);
            
            refPEO.WC_Underwriting_Review_Target__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.workCompColor);
    }// end WorkComp UW Review
    
     static testMethod void testBenefitsSetup() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( WC_Underwriting_Review_Complete__c = t,
                                                            Benefits_ER_Contribution_Loaded_Target__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.benefitsSetupColor);
            
            refPEO.Benefits_ER_Contribution_Loaded_Target__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.benefitsSetupColor);
    }// end Benefits Setup
    
    static testMethod void testEEloadWCSetup() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( Benefits_ER_Contribution_Loaded__c = t,
                                                            Onbrdg_Spsheet_Review_and_EE_Load_Target__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.eeLoadColor);
            
            refPEO.Onbrdg_Spsheet_Review_and_EE_Load_Target__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.eeLoadColor);
    }// end EE load WC Setup
    
    static testMethod void testEEOnboarding() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( Onbrdg_Spsheet_Review_and_EE_Load__c = t,
                                                            Onboarding_Open_Target__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.eeOnboardingColor);
            
            refPEO.Onboarding_Open_Target__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.eeOnboardingColor);
    }// end EE Onboarding
    
     static testMethod void testOnboardingComplete() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( Onboarding_Open__c = t,
                                                            Onboarding_Complete_Target__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.onboardingCompleteColor);
            
            refPEO.Onboarding_Complete_Target__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.onboardingCompleteColor);
    }// end Onboarding Complete
    
    static testMethod void testMedUWApproval() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( Onboarding_Complete__c = t,
                                                            Final_Medical_Approval_Target_Milestone__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.medUVApprovalColor);
            
            refPEO.Final_Medical_Approval_Target_Milestone__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.medUVApprovalColor);
    }// end Med UW Approval
    
    static testMethod void testApprovedPasstoNewLoads() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( Final_Medical_Approval_Milestone__c = t,
                                                            HRIS_Approved_Target_Pass_to_New_Biz__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.approvedPassColor);
            
            refPEO.HRIS_Approved_Target_Pass_to_New_Biz__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.approvedPassColor);
    }// end Approved Pass to New Loads
    
    static testMethod void testEEVerificationQC() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( HRIS_Approved_Pass_to_New_Biz__c = t,
                                                            EE_Verification_and_QC_Target__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.eeVerificationColor);
            
            refPEO.EE_Verification_and_QC_Target__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.eeVerificationColor);
    }// end EE Verification & QC
    
    static testMethod void testHoldsRemoved() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( EE_Verification_and_QC__c = t,
                                                            Management_Hold_Target__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.holdsRemovedColor);
            
            refPEO.Management_Hold_Target__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.holdsRemovedColor);
    }// end Holds Removed
    
    static testMethod void testReadytoRun() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( Management_Hold_Removed_Date__c = t,
                                                            Ready_to_Process_Payroll_Target__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.readyToRunColor);
            
            refPEO.Ready_to_Process_Payroll_Target__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.readyToRunColor);
    }// end Ready to Run
    
    static testMethod void testPayrollProcessing() {
            date t = date.today();
            date afterToday = t.addDays(-3); 
        
            Reference_PEO__c refPEO = new Reference_PEO__c( Ready_to_Process_Payroll2__c = t,
                                                            Actual_Payroll_Process_Target__c = t);
            insert refPEO;
        
            Test.SetCurrentPageReference(Page.ReferencePEODealPhases);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(refPEO);
            System.CurrentPageReference().getParameters().put('id',refPEO.Id);
            ReferencePEODealPhasesController controller = new ReferencePEODealPhasesController(sc);
      
            system.assertEquals('yellow',controller.payrollProcessingColor);
            
            refPEO.Actual_Payroll_Process_Target__c = afterToday;
            update refPEO;
            controller = new ReferencePEODealPhasesController(sc);
            system.assertEquals('red',controller.payrollProcessingColor);
    }// end Payroll Processing
    static testMethod void testReferencePEOUpdate() {
    
            Case c=new Case();
            insert c;
            Account acc=new Account();
            acc.name='Test';
            insert acc;
            date t = date.today();
            date afterToday = t.addDays(-3); 
            RecordType rt=[select id from recordtype where name ='PEO Client Risk Assessment' and sobjectType='Reference_PEO__c'];
            Reference_PEO__c refPEO = new Reference_PEO__c(Account_lookup__c =acc.id,Status__c ='New', Current_Step__c ='New',Ready_to_Process_Payroll2__c = t,
                                                           Parent_Case__c =c.id,Actual_Payroll_Process_Target__c = t,recordtypeId=rt.id);
            insert refPEO;
        
            
            Test.startTest();
            refPEO.Actual_Payroll_Process_Target__c = afterToday;
            refPEO.Current_Step__c='Completed';
            refPEO.Complex_Client__c =true;
            refPEO.Status__c ='In Progress';
            update refPEO;
            Test.StopTest();
            
    }// end Payroll Processing    
    
}