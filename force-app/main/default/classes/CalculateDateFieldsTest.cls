/* 
 * Test class for CalculateDateFields.cls and CalculateBusinessHours.cls
 * Looks for updates to specific fields that will calculate a new date/time value for another field on Reference PEO.
 * 
 * History
 * -------
 * 12/27/2017 Lynn Michels   Created
 * 08/30/2018 Frank Lurz     Changes for Case 29499656
 *
 */
 
@isTest
private class CalculateDateFieldsTest {
   
   @testSetup
   static void setupData() {
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerSetup__c trigSetup = TriggerMethodsTest.createCustomSetting(null, 'ReferencePEOUpdate', false, true, new String[]{'CalculateDateFields'}, setupClasses);
      insert setupClasses;
   } // setupData
   
    static testMethod void ClearSenttoWCUWTime() {
        Reference_PEO__c peo = new Reference_PEO__c();
        insert peo;
        
        peo.Sent_to_WC_UW_Time__c = datetime.newInstance(2017, 9, 14, 12, 30, 0);
        update peo;
        
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, WC_UW_Complete_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        DateTime WCUWCompleteTargetTime = DateTime.newInstance(2017, 9, 14, 16, 30, 0); //4 WC UW Complete Target Time
        system.assertEquals(WCUWCompleteTargetTime, peoList[0].WC_UW_Complete_Target_Time__c);
        
        peo.Sent_to_WC_UW_Time__c = null;
        update peo;
        
        peoList = [SELECT Id, WC_UW_Complete_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(null, peoList[0].WC_UW_Complete_Target_Time__c);
    }// ClearSenttoWCUWTime
    
    static testMethod void ClearWCUWCompleteTime() {
      
        Reference_PEO__c peo = new Reference_PEO__c();
        insert peo;
        peo.WC_UW_Complete_Time__c = datetime.newInstance(2017, 9, 14, 8, 30, 0); //2 Payroll Shell (W) Target Time
                                                                                  //4 ER Benefits Setup (W) Target Time
        update peo;
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, Payroll_Shell_W_Target_Time__c,
                    ER_Benefits_Setup_W_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
                    
        DateTime NewPayrollShellWTargetTime = DateTime.newInstance(2017, 9, 14, 12, 30, 0);
        DateTime NewERBenefitsSetupWTargetTime = DateTime.newInstance(2017, 9, 14, 12, 30, 0);
        system.assertEquals(NewPayrollShellWTargetTime, peoList[0].Payroll_Shell_W_Target_Time__c);
        system.assertEquals(NewERBenefitsSetupWTargetTime, peoList[0].ER_Benefits_Setup_W_Target_Time__c);
         
        peo.WC_UW_Complete_Time__c = null;
        update peo;
        
        peoList = [SELECT Id, Payroll_Shell_W_Target_Time__c,
                    ER_Benefits_Setup_W_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(null, peoList[0].Payroll_Shell_W_Target_Time__c);
        system.assertEquals(null, peoList[0].ER_Benefits_Setup_W_Target_Time__c); 
    }// ClearWCUWCompleteTime
    
     static testMethod void ClearPasstoNewLoadsDateTime() {
      
        Reference_PEO__c peo = new Reference_PEO__c();
        insert peo;
        peo.Pass_to_New_Loads_Date_Time__c = datetime.newInstance(2017, 9, 14, 13, 00, 0);//4 Payroll Shell (P) Target Time
                                                                                          //4 WC Loaded Target Time
                                                                                          //2 EE Verification Target Time
        update peo;
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, Payroll_Shell_P_Target_Time__c,
                    WC_Loaded_Target_Time__c,
                    EE_Verification_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];

        DateTime NewPayrollShellPTargetTime = DateTime.newInstance(2017, 9, 14, 17, 00, 0);
        DateTime NewWCLoadedTargetTime = DateTime.newInstance(2017, 9, 14, 17, 00, 0);
        DateTime NewEEVerificationTargetTime = DateTime.newInstance(2017, 9, 14, 15, 00, 0);
        system.assertEquals(NewPayrollShellPTargetTime, peoList[0].Payroll_Shell_P_Target_Time__c);
        system.assertEquals(NewWCLoadedTargetTime, peoList[0].WC_Loaded_Target_Time__c);
        system.assertEquals(NewEEVerificationTargetTime, peoList[0].EE_Verification_Target_Time__c);
         
        peo.Pass_to_New_Loads_Date_Time__c = null;
        update peo;
        
        peoList = [SELECT Id, Payroll_Shell_P_Target_Time__c,
                    WC_Loaded_Target_Time__c,
                    EE_Verification_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(null, peoList[0].Payroll_Shell_P_Target_Time__c);
        system.assertEquals(null, peoList[0].WC_Loaded_Target_Time__c);
        system.assertEquals(null, peoList[0].EE_Verification_Target_Time__c); 
    }// ClearPasstoNewLoadsDateTime
    
    static testMethod void ClearEEsLoadedTime() {
      
        Reference_PEO__c peo = new Reference_PEO__c();
        insert peo;
        peo.EEs_Loaded_Time__c = datetime.newInstance(2017, 9, 14, 12, 30, 0);  //8 ER Benefits Setup (P) Target Time
        update peo;
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, ER_Benefits_Setup_P_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
                    
        DateTime NewERBenefitsSetupPTargetTime = DateTime.newInstance(2017, 9, 15, 11, 30, 0);
        system.assertEquals(NewERBenefitsSetupPTargetTime, peoList[0].ER_Benefits_Setup_P_Target_Time__c);
         
        peo.EEs_Loaded_Time__c = null;
        update peo;
        
        peoList = [SELECT Id, ER_Benefits_Setup_P_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(null, peoList[0].ER_Benefits_Setup_P_Target_Time__c);
    }// ClearEEsLoadedTime
    
    static testMethod void ClearReadyforSEDITime() {
      
        Reference_PEO__c peo = new Reference_PEO__c();
        insert peo;
        peo.Ready_for_SEDI_Time__c = datetime.newInstance(2017, 9, 15, 1, 30, 0); //4 SEDI Complete Target Time
        update peo;
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, SEDI_Complete_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
                    
        DateTime NewReadyforSEDITime = DateTime.newInstance(2017, 9, 15, 12, 00, 0);
        system.assertEquals(NewReadyforSEDITime, peoList[0].SEDI_Complete_Target_Time__c);
         
        peo.Ready_for_SEDI_Time__c = null;
        update peo;
        
        peoList = [SELECT Id, SEDI_Complete_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(null, peoList[0].SEDI_Complete_Target_Time__c);
    }// ClearReadyforSEDITime
    
    static testMethod void ClearWCLoadedTime() {
      
        Reference_PEO__c peo = new Reference_PEO__c();
        insert peo;
        peo.WC_Loaded_Time__c = datetime.newInstance(2017, 9, 15, 12, 30, 0); //4 Ees Loaded Target Time
        update peo;
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, Ees_Loaded_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
                    
        DateTime NewEesLoadedTargetTime = DateTime.newInstance(2017, 9, 15, 16, 30, 0);
        system.assertEquals(NewEesLoadedTargetTime, peoList[0].Ees_Loaded_Target_Time__c);
         
        peo.WC_Loaded_Time__c = null;
        update peo;
        
        peoList = [SELECT Id, Ees_Loaded_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(null, peoList[0].Ees_Loaded_Target_Time__c);
    }// ClearWCLoadedTime
    
     static testMethod void ClearSEDICompleteTime() {
      
        Reference_PEO__c peo = new Reference_PEO__c();
        insert peo;
        peo.SEDI_Complete_Time__c = datetime.newInstance(2017, 9, 15, 16, 30, 0); //4 Set to Pending Target Time
        update peo;
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, Set_to_Pending_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
                    
        DateTime NewSettoPendingTargetTime = DateTime.newInstance(2017, 9, 18, 11, 30, 0);
        system.assertEquals(NewSettoPendingTargetTime, peoList[0].Set_to_Pending_Target_Time__c);
         
        peo.SEDI_Complete_Time__c = null;
        update peo;
        
        peoList = [SELECT Id, Set_to_Pending_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(null, peoList[0].Set_to_Pending_Target_Time__c);
    }// ClearSEDICompleteTime
    
    static testMethod void ClearSenttoMedUWTime() {
      
        Reference_PEO__c peo = new Reference_PEO__c();
        insert peo;
        peo.Sent_to_Med_UW_Time__c = datetime.newInstance(2017, 9, 13, 14, 45, 0); //4 MED UW Target Time
        update peo;
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, MED_UW_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
                    
        DateTime NewMEDUWTargetTime = DateTime.newInstance(2017, 9, 14, 9, 45, 0);
        system.assertEquals(NewMEDUWTargetTime, peoList[0].MED_UW_Target_Time__c);
         
        peo.Sent_to_Med_UW_Time__c = null;
        update peo;
        
        peoList = [SELECT Id, MED_UW_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(null, peoList[0].MED_UW_Target_Time__c);
    }// ClearSenttoMedUWTime
    
    static testMethod void ClearOnbrdgHRISApprovedTime() {
        Reference_PEO__c peo = new Reference_PEO__c();
        insert peo;
        peo.Onbrdg_HRIS_Approved_Time__c = datetime.newInstance(2017, 9, 13, 9, 15, 0);//6 Final Enrollment Target Time
        update peo;
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, Final_Enrollment_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
                    
        DateTime NewFinalEnrollmentTargetTime = DateTime.newInstance(2017, 9, 13, 15, 15, 0);
        system.assertEquals(NewFinalEnrollmentTargetTime, peoList[0].Final_Enrollment_Target_Time__c);
         
        peo.Onbrdg_HRIS_Approved_Time__c = null;
        update peo;
        
        peoList = [SELECT Id, Final_Enrollment_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(null, peoList[0].Final_Enrollment_Target_Time__c);
    }// ClearOnbrdgHRISApprovedTime

    static testMethod void ClearMedUWTime() {
        Reference_PEO__c peo = new Reference_PEO__c();
        insert peo;
        peo.Final_Approval_Date__c = date.newInstance(2017, 9, 13); 
        //Populating Final Approval Date will populate the Med UW Time from a workflow rule. 
        //and will calculate Pass to NB Target Time with Med UW Time + 2 business Hours.
        update peo;
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, Pass_to_NB_Target_Time__c, Med_UW_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
                    
        system.assertNotEquals(null, peoList[0].Pass_to_NB_Target_Time__c);
        system.assertNotEquals(null, peoList[0].Med_UW_Time__c);
         
        peo.Final_Approval_Date__c = null;
        update peo;
        
        peoList = [SELECT Id, Pass_to_NB_Target_Time__c, Med_UW_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(null, peoList[0].Pass_to_NB_Target_Time__c);
        system.assertEquals(null, peoList[0].Med_UW_Time__c);
    }// ClearMedUWTime

    static testMethod void ClearEEVerificationTime() {
       // there's a workflow clearing out the EE_Verification_Time__c if EE_Verification__c is null
       // setting this date for the field isn't cleared out!
        Reference_PEO__c peo = new Reference_PEO__c(EE_Verification__c=Date.today());
        insert peo;
        
        peo.EE_Verification_Time__c = datetime.newInstance(2017, 9, 13, 12, 30, 0); //2 Mgmt Hold Removed Target Ti
        update peo;
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, Mgmt_Hold_Removed_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
                    
        DateTime NewMgmtHoldRemovedTargetTime = DateTime.newInstance(2017, 9, 13, 14, 30, 0);
        system.assertEquals(NewMgmtHoldRemovedTargetTime, peoList[0].Mgmt_Hold_Removed_Target_Time__c);
         
        peo.EE_Verification_Time__c = null;
        update peo;
        
        peoList = [SELECT Id, Mgmt_Hold_Removed_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(null, peoList[0].Mgmt_Hold_Removed_Target_Time__c);
    }// ClearEEVerificationTime

    static testMethod void checkForUpdatesOnOneRecord() {
        // this is because of a workflow that's clearing out EE_Verification_Time__c 
        Reference_PEO__c peo = new Reference_PEO__c(EE_Verification__c=Date.today());
        insert peo;
        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
               peoList = [SELECT Id, WC_UW_Complete_Target_Time__c,
                    Payroll_Shell_W_Target_Time__c,
                    ER_Benefits_Setup_W_Target_Time__c ,
                    Payroll_Shell_P_Target_Time__c,
                    WC_Loaded_Target_Time__c,
                    EE_Verification_Target_Time__c,
                    ER_Benefits_Setup_P_Target_Time__c,
                    SEDI_Complete_Target_Time__c,
                    Ees_Loaded_Target_Time__c,
                    Set_to_Pending_Target_Time__c,
                    MED_UW_Target_Time__c,
                    Final_Enrollment_Target_Time__c,
                    Pass_to_NB_Target_Time__c,
                    Mgmt_Hold_Removed_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        system.assertEquals(peoList[0].WC_UW_Complete_Target_Time__c, null);
        system.assertEquals(peoList[0].Payroll_Shell_W_Target_Time__c, null);
        system.assertEquals(peoList[0].ER_Benefits_Setup_W_Target_Time__c, null);
        system.assertEquals(peoList[0].Payroll_Shell_P_Target_Time__c, null);
        system.assertEquals(peoList[0].WC_Loaded_Target_Time__c, null);
        system.assertEquals(peoList[0].EE_Verification_Target_Time__c, null);
        system.assertEquals(peoList[0].ER_Benefits_Setup_P_Target_Time__c, null);
        system.assertEquals(peoList[0].SEDI_Complete_Target_Time__c, null);
        system.assertEquals(peoList[0].Ees_Loaded_Target_Time__c, null);
        system.assertEquals(peoList[0].Set_to_Pending_Target_Time__c, null);
        system.assertEquals(peoList[0].MED_UW_Target_Time__c, null);
        system.assertEquals(peoList[0].Final_Enrollment_Target_Time__c, null);
        system.assertEquals(peoList[0].Pass_to_NB_Target_Time__c, null);
        system.assertEquals(peoList[0].Mgmt_Hold_Removed_Target_Time__c, null);
        
        peo.Sent_to_WC_UW_Time__c = datetime.newInstance(2017, 9, 14, 12, 30, 0); //4 WC UW Complete Target Time
        peo.WC_UW_Complete_Time__c = datetime.newInstance(2017, 9, 14, 8, 30, 0); //4 Payroll Shell (W) Target Time
                                                                                  //4 ER Benefits Setup (W) Target Time
        peo.Pass_to_New_Loads_Date_Time__c = datetime.newInstance(2017, 9, 14, 13, 00, 0);//4 Payroll Shell (P) Target Time
                                                                                          //4 WC Loaded Target Time
                                                                                          //2 EE Verification Target Time
        peo.EEs_Loaded_Time__c = datetime.newInstance(2017, 9, 14, 12, 30, 0);  //8 ER Benefits Setup (P) Target Time
        peo.Ready_for_SEDI_Time__c = datetime.newInstance(2017, 9, 15, 1, 30, 0); //4 SEDI Complete Target Time
        peo.WC_Loaded_Time__c = datetime.newInstance(2017, 9, 15, 12, 30, 0); //4 Ees Loaded Target Time
        peo.SEDI_Complete_Time__c = datetime.newInstance(2017, 9, 15, 16, 30, 0); //4 Set to Pending Target Time
        peo.Sent_to_Med_UW_Time__c = datetime.newInstance(2017, 9, 13, 14, 45, 0); //4 MED UW Target Time
        peo.Onbrdg_HRIS_Approved_Time__c = datetime.newInstance(2017, 9, 13, 9, 15, 0);//6 Final Enrollment Target Time
        peo.Med_UW_Time__c = datetime.newInstance(2017, 9, 13, 12, 30, 0); //2 Pass to NB Target Time
        peo.EE_Verification_Time__c = datetime.newInstance(2017, 9, 13, 12, 30, 0); //2 Mgmt Hold Removed Target Time
        update peo;
        
        peoList = [SELECT Id, WC_UW_Complete_Target_Time__c,
                    Payroll_Shell_W_Target_Time__c,
                    ER_Benefits_Setup_W_Target_Time__c ,
                    Payroll_Shell_P_Target_Time__c,
                    WC_Loaded_Target_Time__c,
                    EE_Verification_Target_Time__c,
                    ER_Benefits_Setup_P_Target_Time__c,
                    SEDI_Complete_Target_Time__c,
                    Ees_Loaded_Target_Time__c,
                    Set_to_Pending_Target_Time__c,
                    MED_UW_Target_Time__c,
                    Final_Enrollment_Target_Time__c,
                    Pass_to_NB_Target_Time__c,
                    Mgmt_Hold_Removed_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];

        DateTime NewWCUWCompleteTargetTime = DateTime.newInstance(2017, 9, 14, 16, 30, 0);
        DateTime NewPayrollShellWTargetTime = DateTime.newInstance(2017, 9, 14, 12, 30, 0);
        DateTime NewERBenefitsSetupWTargetTime = DateTime.newInstance(2017, 9, 14, 12, 30, 0);
        DateTime NewPayrollShellPTargetTime = DateTime.newInstance(2017, 9, 14, 17, 00, 0);
        DateTime NewWCLoadedTargetTime = DateTime.newInstance(2017, 9, 14, 17, 00, 0);
        DateTime NewEEVerificationTargetTime = DateTime.newInstance(2017, 9, 14, 15, 00, 0);
        DateTime NewERBenefitsSetupPTargetTime = DateTime.newInstance(2017, 9, 15, 11, 30, 0);
        DateTime NewSEDICompleteTargetTime = DateTime.newInstance(2017, 9, 15, 12, 00, 0);
        DateTime NewEesLoadedTargetTime = DateTime.newInstance(2017, 9, 15, 16, 30, 0);
        DateTime NewSettoPendingTargetTime = DateTime.newInstance(2017, 9, 18, 11, 30, 0);
        DateTime NewMEDUWTargetTime = DateTime.newInstance(2017, 9, 14, 9, 45, 0);
        DateTime NewFinalEnrollmentTargetTime = DateTime.newInstance(2017, 9, 13, 15, 15, 0);
        DateTime NewPasstoNBTargetTime = DateTime.newInstance(2017, 9, 13, 14, 30, 0);
        DateTime NewMgmtHoldRemovedTargetTime = DateTime.newInstance(2017, 9, 13, 14, 30, 0);

        system.assertEquals(NewWCUWCompleteTargetTime, peoList[0].WC_UW_Complete_Target_Time__c);
        system.assertEquals(NewPayrollShellWTargetTime, peoList[0].Payroll_Shell_W_Target_Time__c);
        system.assertEquals(NewERBenefitsSetupWTargetTime, peoList[0].ER_Benefits_Setup_W_Target_Time__c);
        system.assertEquals(NewPayrollShellPTargetTime, peoList[0].Payroll_Shell_P_Target_Time__c);
        system.assertEquals(NewWCLoadedTargetTime, peoList[0].WC_Loaded_Target_Time__c);
        system.assertEquals(NewEEVerificationTargetTime, peoList[0].EE_Verification_Target_Time__c);
        system.assertEquals(NewERBenefitsSetupPTargetTime, peoList[0].ER_Benefits_Setup_P_Target_Time__c);
        system.assertEquals(NewSEDICompleteTargetTime, peoList[0].SEDI_Complete_Target_Time__c);
        system.assertEquals(NewEesLoadedTargetTime, peoList[0].Ees_Loaded_Target_Time__c);
        system.assertEquals(NewSettoPendingTargetTime, peoList[0].Set_to_Pending_Target_Time__c);
        system.assertEquals(NewMEDUWTargetTime, peoList[0].MED_UW_Target_Time__c);
        system.assertEquals(NewFinalEnrollmentTargetTime, peoList[0].Final_Enrollment_Target_Time__c);
        system.assertEquals(NewPasstoNBTargetTime, peoList[0].Pass_to_NB_Target_Time__c);
        system.assertEquals(NewMgmtHoldRemovedTargetTime, peoList[0].Mgmt_Hold_Removed_Target_Time__c);
        
        
        peo.Sent_to_WC_UW_Time__c = datetime.newInstance(2017, 12, 22, 16, 30, 0);
        update peo;
        peoList = [SELECT Id, WC_UW_Complete_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id =: peo.id];
        DateTime UpdatedWCUWCompleteTargetTime = DateTime.newInstance(2017, 12, 25, 11, 30, 0);
        system.assertEquals(UpdatedWCUWCompleteTargetTime, peoList[0].WC_UW_Complete_Target_Time__c);
    }//end checkForUpdatesOnOneRecord

    static testMethod void checkForUpdatesOnMultipleRecords() {
        list<Reference_PEO__c> insertPeoList = new list<Reference_PEO__c>();
        Reference_PEO__c peo = new Reference_PEO__c();
        insertPeoList.add(peo);
        Reference_PEO__c peo2 = new Reference_PEO__c();
        insertPeoList.add(peo2);
        insert insertPeoList;
System.debug(LoggingLevel.Info, 'LM insertPEOList ' +insertPeoList);        
        list<Reference_PEO__c> peoList = new list<Reference_PEO__c>();
        peoList = [SELECT Id, WC_UW_Complete_Target_Time__c, Payroll_Shell_W_Target_Time__c,
                    ER_Benefits_Setup_W_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id in: insertPeoList];
        system.assertEquals(peoList[0].WC_UW_Complete_Target_Time__c, null);
        system.assertEquals(peoList[0].Payroll_Shell_W_Target_Time__c, null);
        system.assertEquals(peoList[0].ER_Benefits_Setup_W_Target_Time__c, null);
        system.assertEquals(peoList[1].WC_UW_Complete_Target_Time__c, null);
        system.assertEquals(peoList[1].Payroll_Shell_W_Target_Time__c, null);
        system.assertEquals(peoList[1].ER_Benefits_Setup_W_Target_Time__c, null);
        
        
        peo.Sent_to_WC_UW_Time__c = datetime.newInstance(2017, 8, 15, 9, 30, 0);
        peo.WC_UW_Complete_Time__c = datetime.newInstance(2017, 9, 15, 9, 30, 0);
        
        peo2.Sent_to_WC_UW_Time__c = datetime.newInstance(2017, 10, 15, 8, 30, 0);
        peo2.WC_UW_Complete_Time__c = datetime.newInstance(2017, 11, 15, 8, 30, 0);
 System.debug(LoggingLevel.Info, 'LM insertPEOList ' +insertPeoList);
        update insertPeoList;
        
        peoList = [SELECT Id, WC_UW_Complete_Target_Time__c, Payroll_Shell_W_Target_Time__c,
                    ER_Benefits_Setup_W_Target_Time__c
                    FROM Reference_PEO__c
                    WHERE id in: insertPeoList];
        DateTime PeoWCUWCompleteTargetTime = DateTime.newInstance(2017, 8, 15, 13, 30, 0);
        DateTime PeoPayrollShellWTargetTime = DateTime.newInstance(2017, 9, 15, 13, 30, 0);
        DateTime PeoERBenefitsSetupWTargetTime = DateTime.newInstance(2017, 9, 15, 13, 30, 0);
        
        DateTime Peo2WCUWCompleteTargetTime = DateTime.newInstance(2017, 10, 16, 12, 00, 0);
        DateTime Peo2PayrollShellWTargetTime = DateTime.newInstance(2017, 11, 15, 12, 30, 0);
        DateTime Peo2ERBenefitsSetupWTargetTime = DateTime.newInstance(2017, 11, 15, 12, 30, 0);
        
        system.assertEquals(PeoWCUWCompleteTargetTime, peoList[0].WC_UW_Complete_Target_Time__c);
        system.assertEquals(PeoPayrollShellWTargetTime, peoList[0].Payroll_Shell_W_Target_Time__c);
        system.assertEquals(PeoERBenefitsSetupWTargetTime, peoList[0].ER_Benefits_Setup_W_Target_Time__c);
        system.assertEquals(Peo2WCUWCompleteTargetTime, peoList[1].WC_UW_Complete_Target_Time__c);
        system.assertEquals(Peo2PayrollShellWTargetTime, peoList[1].Payroll_Shell_W_Target_Time__c);
        system.assertEquals(Peo2ERBenefitsSetupWTargetTime, peoList[1].ER_Benefits_Setup_W_Target_Time__c);   
    }//end checkForUpdatesOnMultipleRecords
    
    //for code coverage
    static testMethod void testMisc() {     
            CalculateDateFields cdf = new CalculateDateFields();
            cdf.checkAllBeforeTrigger(null, null); 
            cdf.checkAllAfterTrigger(null, null);
            cdf.checkBeforeTrigger(null, null);
            cdf.processBeforeTriggerActions(); 
                       
    }//end testMisc

} // CalculateDateFieldsTest