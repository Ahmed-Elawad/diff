/**
 * Test method for ClientReferenceRequest visual force page
 * 
 * History
 * --------
 * 03/12/2018  Cindy Freeman  modifed for new ClientReferenceRequest vf page
   04/17/2020  Dan Carmen     Modified to use CreateTestData

 */
@isTest
private class ClientReferenceRequestControllerTest {

  
    static testMethod void myUnitTest1() {
        Schema.RecordTypeInfo acctRt = CreateTestData.getDefaultProspectAcctRT();
        Schema.RecordTypeInfo ctctRt = CreateTestData.getDefaultSalesContactRT();        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctRt.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '20000',BillingState = 'PA'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25
                                ,BIS_Id__c = 1001001);
         insert acct1;       
         Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctRt.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,Sales_Contact__c = true);
        insert ctct1;
        Id optyId = CreateTestData.createTestCoreOptys (acct1.Id, ctct1.Id);        
        Client_Reference__c cref = new Client_Reference__c(Bis_Id__c = 1001001,VoC_Indicator__c='Out for Reference',
                                    Primary_Contact__c = 'First Last1',Primary_Contact_Email__c='fLast1@abc.com');
        insert cref;                  
        Client_References_Selected__c crs = new Client_References_Selected__c(Client_Reference__c = cref.Id
                                                                              ,Account__c = acct1.Id
                                                                              ,Contact__c = ctct1.Id
                                                                              ,Opportunity__c = optyId
                                                                              ,Status__c = 'Approved');
        insert crs;
   
        Account acct2 = new Account (name = 'Test Account2'
                                ,recordtypeId = acctRt.getRecordTypeId()
                                ,type = 'Core Client',NumberofEmployees=10
                                ,BillingPostalCode = '10000', BillingState = 'NY'
                                ,AccountNumber = '83-1234123'
                                ,Do_Not_Call__c = true,Email_Opt_Out__c = true
                                ,Phone = '555-3434'
                                ,X401_k__c = true, FSA__c = true, SimpleIRA__c = true, Flex_Hiring__c='Flex Hiring'
                                ,AnnualRevenue = 25
                                ,BIS_Id__c = 2002002);
         insert acct2;       
         Contact ctct2 = new Contact(Firstname = 'Second'
                                ,Lastname = 'Last2'
                                ,recordtypeId = ctctRt.getRecordTypeId()
                                ,Phone = '585-555-3434'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct2.Id
                                ,Sales_Contact__c = true);
        insert ctct2;                
        Client_Reference__c cref2 = new Client_Reference__c(Bis_Id__c = 2002002,VoC_Indicator__c='Available',Account__c = acct2.Id,Contact__c = ctct2.Id,
                                    Primary_Contact__c = 'Second Last2',Primary_Contact_Email__c='sLast2@abc.com',Business_Type_1__c='BusType1');
        insert cref2;                  
        
        
        User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.ClientReferenceRequest);
            System.CurrentPageReference().getParameters().put('optyId',optyId);
            ClientReferenceRequestController crrCntlr = new ClientReferenceRequestController();
            
            // constructor tests
            System.assertNotEquals(null, crrCntlr.limitWarning);
            System.assertEquals(crrCntlr.currentStep, 'initialLoad');           
            // custom setting System.assertNotEquals(1,crrCntlr.acctTypeOptions.size());
            System.assertNotEquals(1,crrCntlr.benetracOptions.size());
            System.assertNotEquals(1,crrCntlr.taaOptions.size());
            System.assertNotEquals(1,crrCntlr.glOptions.size());
            System.assertNotEquals(1,crrCntlr.strategicAcctOptions.size());
            System.assertNotEquals(1,crrCntlr.acctSftwrOptions.size());
            System.assertNotEquals(1,crrCntlr.flexHiringOptions.size());
            
            // search test
            crrCntlr.filterFSA = true;
            crrCntlr.filterSimpleIRA = true;
            crrCntlr.selectedFlexHiring = new List<String>();
            crrCntlr.selectedFlexHiring.add('Flex Hiring');             
            crrCntlr.filterPreviewtoFlex = crrCntlr.filterHROnline = crrCntlr.filterLabor = crrCntlr.filterJobCosting = crrCntlr.filterCertPayroll = false;
            crrCntlr.filterX401k = crrCntlr.filterMedical = crrCntlr.filterPOP = crrCntlr.filterWCPS = crrCntlr.filterMultiId = false;
            crrCntlr.runSearch();
            
            System.assertEquals(1, crrCntlr.crRequest.Number_Found__c);
            
            // select 1st result
            crrCntlr.resultList.get(0).selected = true;
            crrCntlr.markSelected();
            System.assertEquals(1, crrCntlr.selectedCount);
            
            // unselect result
            crrCntlr.resultList.get(0).selected = false;
            crrCntlr.unmarkSelected();
            System.assertEquals(0, crrCntlr.selectedCount);
            
            // reset search
            crrCntlr.resetFilter();
            System.assertEquals(0, crrCntlr.displayedClientRefSet.size());
            System.assertEquals(false, crrCntlr.filterFSA);
            System.assertEquals(false, crrCntlr.filterCertPayroll);
            System.assertEquals(null, crrCntlr.zip);
            System.assertEquals(true, crrCntlr.selectedFlexHiring.isEmpty());
            
            // create 2 more client refs to test
            Account acct3 = new Account (name = 'Test Account3'
                                ,recordtypeId = acctRt.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '10000', BillingState = 'NY'
                                //,AccountNumber = '84-1234124'
                                ,Do_Not_Call__c = true,Email_Opt_Out__c = true
                                ,Phone = '555-4545'
                                ,X401_k__c = true, FSA__c = true, SimpleIRA__c = true, Flex_Hiring__c='Flex Hiring'
                                ,AnnualRevenue = 25
                                ,BIS_Id__c = 3003003);
            insert acct3;       
            Contact ctct3 = new Contact(Firstname = 'Third'
                                ,Lastname = 'Last3'
                                ,recordtypeId = ctctRt.getRecordTypeId()
                                ,Phone = '585-555-4545'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct3.Id
                                ,Sales_Contact__c = true);
            insert ctct3;                
            Client_Reference__c cref3 = new Client_Reference__c(Bis_Id__c = 3003003,VoC_Indicator__c='Available',Account__c = acct3.Id,Contact__c = ctct3.Id,
                                    Primary_Contact__c = 'Third Last3',Primary_Contact_Email__c='sLast3@abc.com');
            insert cref3;      
            Account acct4 = new Account (name = 'Test Account4'
                                ,recordtypeId = acctRt.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '20000', BillingState = 'PA'
                                //,AccountNumber = '85-1234125'
                                ,Do_Not_Call__c = true,Email_Opt_Out__c = true
                                ,Phone = '555-5656'
                                ,X401_k__c = true, FSA__c = true, SimpleIRA__c = true, Flex_Hiring__c='Flex Hiring'
                                ,AnnualRevenue = 25
                                ,BIS_Id__c = 4004004);
            insert acct4;       
            Contact ctct4 = new Contact(Firstname = 'Fourth'
                                ,Lastname = 'Last4'
                                ,recordtypeId = ctctRt.getRecordTypeId()
                                ,Phone = '585-555-5656'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct4.Id
                                ,Sales_Contact__c = true);
            insert ctct4;                
            Client_Reference__c cref4 = new Client_Reference__c(Bis_Id__c = 4004004,VoC_Indicator__c='Available',Account__c = acct4.Id,Contact__c = ctct4.Id,
                                    Primary_Contact__c = 'Fourth Last4',Primary_Contact_Email__c='sLast4@abc.com');
            insert cref4;      
        
            // search test again
            crrCntlr.filterFSA = true;
            crrCntlr.filterSimpleIRA = true;
            crrCntlr.selectedFlexHiring = new List<String>();
            crrCntlr.selectedFlexHiring.add('Flex Hiring');
            crrCntlr.filterPreviewtoFlex = crrCntlr.filterHROnline = crrCntlr.filterLabor = crrCntlr.filterJobCosting = crrCntlr.filterCertPayroll = false;
            crrCntlr.filterX401k = crrCntlr.filterMedical = crrCntlr.filterPOP = crrCntlr.filterWCPS = crrCntlr.filterMultiId = false;
            crrCntlr.state = 'NY,PA';
            crrCntlr.runSearch();
                
            System.assertEquals(3, crrCntlr.crRequest.Number_Found__c);
            
            crrCntlr.resultList.get(0).selected = true;
            crrCntlr.markSelected();
            crrCntlr.resultList.get(1).selected = true;
            crrCntlr.markSelected();
            //crrCntlr.resultList.get(2).selected = true;
            //crrCntlr.markSelected();
            //System.assertNotEquals(null, crrCntlr.limitWarning);
            //crrCntlr.resultList.get(2).selected = false;
            //crrCntlr.unmarkSelected();
            //System.assertEquals(2, crrCntlr.selectedCount);
            
            crrCntlr.returnToOpty();
            ProcessInstance[] piList = [SELECT Id, TargetObjectId, 
                        (SELECT Id, StepStatus, Comments FROM Steps) 
                                  FROM ProcessInstance // Where targetObjectID in :rejectedIdCRSMap.keySet() and Status != 'Rejected'
                                  ORDER BY ElapsedTimeInMinutes Desc];  
            System.assertEquals(2,piList.size());
                                
        }
                
    } // myUnitTest1
    
} // ClientReferenceRequestController