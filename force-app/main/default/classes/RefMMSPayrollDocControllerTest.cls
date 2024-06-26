/**
 * This class contains unit tests for validating the RefMMSPayrollDocController
 * 
 *
 * History
 * --------
 * 03/21/2013   Cindy Freeman   created
 * 12/8/2015    Lynn Michels    add tests for MPSCOnboardingDocuments.page
 * 03/25/2024 Carrie Marciano	CanBeDeleted old MPSC tech debt
 */

@isTest
private class RefMMSPayrollDocControllerTest {
    static testMethod void myUnitTest() {
        new RefMMSPayrollDocController();
        new MMSDocumentWrapper();
        new MPSCOnboardingController();
    }
/*
     static testMethod void refMMSPayControllerTest1() {
        // create test onboarding documents
        List<MMS_Onboarding_Documents__c> mmsOnbrdingDocs = new List<MMS_Onboarding_Documents__c>();
        MMS_Onboarding_Documents__c doc1 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Payroll Doc1'
                                                                            , Mandatory__c = true
                                                                            , MMS_Payroll_Document__c = true
                                                                            , Product_Category__c = 'Payroll' );
        mmsOnbrdingDocs.add(doc1);
        MMS_Onboarding_Documents__c doc2 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Taxpay Doc2'
                                                                            , Mandatory__c = false
                                                                            , MMS_Payroll_Document__c = true
                                                                            , Product_Category__c = 'TaxPay' );
        mmsOnbrdingDocs.add(doc2);
        MMS_Onboarding_Documents__c doc3 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Signature Doc3'
                                                                            , Mandatory__c = false
                                                                            , MMS_Payroll_Document__c = true
                                                                            , Product_Category__c = null );
        mmsOnbrdingDocs.add(doc3);
        insert mmsOnbrdingDocs;
            
        // create account, contact      
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name from Account where name = 'Test Account2'];
        Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
        List<Id> testOptyIds = new List<Id>();      
        // create and mark Sold MMS opty that will create Case and Reference Object and Onboarding Documents
        testOptyIds.add(CreateTestData.createTestMMSSoldOptys(a1.Id, ctct1.Id));                
        Date testDate = Date.valueOf(System.now()); 
        Reference_MMS_Payroll__c refmmsObj = new Reference_MMS_Payroll__c(Date_Client_Load_Received__c = testDate
                                                                        , Client_Load_Submission_Method__c ='Mid-Market Sales Tool'
                                                                        , Zero_Wage_Start__c = 'Yes'
                                                                        , Taxpay_Indicator__c = 'Yes'
                                                                        , New_Business_Indicator__c = 'Yes'
                                                                        , Opportunity_Name__c = testOptyIds.get(0)
                                                                        , Product_Summary__c = 'Payroll;TaxPay'
                                                                        );
        insert refmmsObj;
        Reference_MMS_Payroll_Documents__c[] mmsDocs = [SELECT Id, Document__c, Mandatory__c from Reference_MMS_Payroll_Documents__c
                                                        WHERE Reference_MMS_Payroll__c = :refmmsObj.Id];
        System.assertEquals(2, mmsDocs.size());
    
        Test.SetCurrentPageReference(Page.RefMMSDocuments);
        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refmmsObj);
        System.CurrentPageReference().getParameters().put('id',refmmsObj.Id);
        RefMMSPayrollDocController rc = new RefMMSPayrollDocController(sc);
        
        System.assertEquals(3, rc.mmsDocList.size());
        System.assertEquals(2, rc.refDocList.size());
        System.assertEquals(1, rc.newDocList.size());               
        
        // remove doc already added to list     
        rc.selectedId = rc.refDocList.get(1).docId;
        Id testId = rc.selectedId;                 
        rc.markSelected();
        System.assertEquals(1, rc.refDocList.size());
        for (MMSDocumentWrapper dw: rc.mmsDocList)
        {   if (dw.docId == testId)
            {   System.assertEquals('delete', dw.docRcdType);
                System.assertEquals('-None-', dw.doc.Received_State__c);
                System.assertEquals('Changes Pending', rc.pgMsg);
            }
        }                           
        System.assertEquals(2, rc.newDocList.size());
        
        // add removed doc back to list
        rc.selectedId = testId;
        rc.markSelected();
        System.assertEquals(2, rc.refDocList.size());
        for (MMSDocumentWrapper dw: rc.mmsDocList)
        {   if (dw.docId == testId)
            {   System.assertEquals('existing', dw.docRcdType);
                System.assertEquals('-None-', dw.doc.Received_State__c);
            }
        }
        
        // cancel changes and start over
        rc.cancelDocs();
        System.assertEquals(3, rc.mmsDocList.size());
        System.assertEquals(2, rc.refDocList.size());
        System.assertEquals(1, rc.newDocList.size());               
        System.assertEquals('', rc.pgMsg);
        System.assertEquals(false, rc.showMsg);        
        
        //////////        
        rc.selectedId = rc.newDocList.get(0).docId;
        testId = rc.selectedId;
        rc.markSelected();
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   if (dw.docId == testId)
            {   System.assertEquals(true, dw.selected);
                System.assertEquals('upsert', dw.docRcdType);
                System.assertEquals('-None-', dw.doc.Received_State__c);
            }
        } // for refDocList
        
        // get doc just made required and mark as delete
        rc.markSelected();        
        for (MMSDocumentWrapper dw: rc.mmsDocList)
        {   if (dw.docId == testId)
            {   System.assertEquals(false, dw.selected);
                System.assertEquals('NA', dw.docRcdType);
                System.assertEquals('-None-', dw.doc.Received_State__c);
            }
        } // for mmsDocList
        
        // take doc required and mark as received then add date        
        testId = rc.refDocList.get(1).docId;                               
        rc.refDocList.get(1).doc.Check_In_Date__c = System.now().date();
        rc.saveDate();
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   if (dw.docId == testId)
            {   System.assertEquals('Complete', dw.doc.Received_State__c);
                System.assertEquals('upsert', dw.docRcdType);
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg);              
            }
        } // for refDocList      
                
        // mark doc with discrepancy and a comment        
        rc.refDocList.get(1).doc.Received_State__c = 'Discrepancy';
        rc.refDocList.get(1).doc.Comments__c = 'new comment';
        rc.saveState();
        rc.saveComment();        
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   if (dw.docId == testId)
            {   System.assertEquals('Discrepancy', dw.doc.Received_State__c);
                System.assertEquals('new comment', dw.doc.Comments__c);
                System.assertEquals('upsert', dw.docRcdType);
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg);
            }
        } // for refDocList
        
        // add resolution date      
        rc.refDocList.get(1).doc.Discrepancy_Resolution_Date__c =  System.now().date()+7;
        rc.saveResolutionDate();
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   if (dw.docId == testId)
            {   System.assertEquals('Resolved', dw.doc.Received_State__c);
                System.assertNotEquals(null, dw.doc.Discrepancy_Resolution_Date__c);
                System.assertEquals('upsert', dw.docRcdType);
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg);
            }
        } // for refDocList

        // check sendEmail
        rc.sendEmail();
        System.assertEquals('Changes Pending. Please click Save before Send Email!',rc.pgMsg);
        System.assertEquals(true, rc.showMsg);
        System.assertEquals('N', rc.congaOK);
                
        // mark received but dont put on a date, then save to check error msg
        testId = rc.refDocList.get(0).docId;  
        rc.refDocList.get(0).doc.Check_In_Date__c = System.now().date();
        rc.saveDate();
        rc.refDocList.get(0).doc.Check_In_Date__c = null;
        rc.saveDocs();
        System.assertEquals(true, rc.pgMsg.contains('missing Check In Date'));
        System.assertEquals(true, rc.showMsg);
        
        // put received date and then save
        rc.refDocList.get(0).doc.Check_In_Date__c = System.now().date();
        rc.saveDate();
        rc.saveDocs();
        System.assertEquals(true, rc.pgMsg.contains('Successfully Saved'));
        System.assertEquals(true, rc.showMsg);
        System.assertEquals(3, rc.mmsDocList.size());
        System.assertEquals(2, rc.refDocList.size());
        System.assertEquals(1, rc.newDocList.size());

        // unselect received doc to check delete
        testId = rc.refDocList.get(1).docId;
        rc.selectedId = testId;
        rc.markSelected();
        System.assertEquals(false, rc.mmsDocList.get(1).selected);
        System.assertEquals('delete', rc.mmsDocList.get(1).docRcdType);     
        rc.saveDocs();
        System.assertEquals(true, rc.pgMsg.contains('Successfully Saved'));
        System.assertEquals(true, rc.showMsg);
        System.assertEquals(3, rc.mmsDocList.size());
        System.assertEquals(1, rc.refDocList.size());
        System.assertEquals(2, rc.newDocList.size());
                    
        // set then clear resolution date
        rc.refDocList.get(0).doc.Comments__c = 'hello';
        rc.saveComment();
        rc.refDocList.get(0).doc.Discrepancy_Resolution_Date__c =  System.now().date()+7;
        rc.saveResolutionDate();
        rc.saveDocs();
        System.assertEquals(true, rc.pgMsg.contains('Saved'));
        rc.refDocList.get(0).doc.Discrepancy_Resolution_Date__c =  null;
        rc.saveResolutionDate();                
        System.assertEquals('Discrepancy', rc.refDocList.get(0).doc.Received_State__c);
        System.assertEquals('Changes Pending', rc.pgMsg);
        rc.refDocList.get(0).doc.Check_In_Date__c =  System.now().date();
        rc.saveDocs();
        System.assertEquals(true, rc.pgMsg.contains('Saved'));
        // clear out date
        rc.refDocList.get(0).doc.Comments__c = 'good morning';
        rc.saveComment(); 
        rc.refDocList.get(0).doc.Check_In_Date__c = null;
        rc.saveDate();
        rc.saveDocs();
        System.assertEquals(true, rc.pgMsg.contains('Saved'));
        
        // check ResolveAll
        rc.refDocList.get(0).doc.Check_In_Date__c = System.now().date()-3;
        rc.refDocList.get(0).doc.Received_State__c = 'Discrepancy';         
        rc.resolveAll();
        System.assertEquals('Resolved', rc.refDocList.get(0).doc.Received_State__c);
        System.assertEquals(System.now().date(), rc.refDocList.get(0).doc.Discrepancy_Resolution_Date__c);
        System.assertEquals('Changes Pending', rc.pgMsg);
        System.assertEquals(true, rc.showMsg);          
        
    } // refMMSPayrollDocControllerTest
 
   
    //test MPSC Onboarding Documents page
/* LM 11/2017- MPSC Documents no longer in use as of 3/2017
    static testMethod void testMPSCOnboardingDocumentsNoProducts() {
        // create test onboarding documents
        List<MMS_Onboarding_Documents__c> mmsOnbrdingDocs = new List<MMS_Onboarding_Documents__c>();
        MMS_Onboarding_Documents__c doc1 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Payroll Doc1'
                                                                            , Mandatory_for_MPSC__c = true
                                                                            , MPSC_Onboarding_Document__c = true
                                                                            , Product_Category__c = 'Payroll' );
        mmsOnbrdingDocs.add(doc1);
        MMS_Onboarding_Documents__c doc2 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Taxpay Doc2'
                                                                            , Mandatory_for_MPSC__c = false
                                                                            , MPSC_Onboarding_Document__c = true
                                                                            , Product_Category__c = 'TaxPay' );
        mmsOnbrdingDocs.add(doc2);
        MMS_Onboarding_Documents__c doc3 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Signature Doc3'
                                                                            , Mandatory_for_MPSC__c = false
                                                                            , MPSC_Onboarding_Document__c = true
                                                                            , Product_Category__c = null );
        mmsOnbrdingDocs.add(doc3);
        insert mmsOnbrdingDocs;
            
        // create account, contact   
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name from Account where name = 'Test Account2'];
        Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
        List<Id> testOptyIds = new List<Id>();  
                                
        // create a Core Opportunity, mark it Sold - that will create Case and Reference Object and Onboarding Documents
        testOptyIds.add(CreateTestData.createTestCoreSoldOptys(a1.Id, ctct1.Id));   
        
        Reference_MPSC_Onboarding_Document__c[] refMPSCDoc = [SELECT Id, Document__c FROM Reference_MPSC_Onboarding_Document__c];
        //Only one Ref MPSC Onboaridng Document created bc only on document is mandatory.
        System.assertEquals(1, refMPSCDoc.size());
    
    }//end
    
    //test MPSC Onboarding Documents page
    
    static testMethod void testMPSCOnboardingDocumentsWithProducts()
    {
        // create test onboarding documents
        List<MMS_Onboarding_Documents__c> mmsOnbrdingDocs = new List<MMS_Onboarding_Documents__c>();
        MMS_Onboarding_Documents__c doc1 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Payroll Doc1'
                                                                            , Mandatory_for_MPSC__c = true
                                                                            , MPSC_Onboarding_Document__c = true
                                                                            , Product_Category__c = 'Payroll' );
        mmsOnbrdingDocs.add(doc1);
        MMS_Onboarding_Documents__c doc2 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Taxpay Doc2'
                                                                            , Mandatory_for_MPSC__c = false
                                                                            , MPSC_Onboarding_Document__c = true
                                                                            , Product_Category__c = 'TaxPay' );
        mmsOnbrdingDocs.add(doc2);
        MMS_Onboarding_Documents__c doc3 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Signature Doc3'
                                                                            , Mandatory_for_MPSC__c = false
                                                                            , MPSC_Onboarding_Document__c = true
                                                                            , Product_Category__c = null );
        mmsOnbrdingDocs.add(doc3);
        insert mmsOnbrdingDocs;
            
        // create account, contact   
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name from Account where name = 'Test Account2'];
        Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
        List<Id> testOptyIds = new List<Id>();  
        
        // create a Core Opportunity, mark it Sold - that will create Case and Reference Object and Onboarding Documents
        testOptyIds.add(CreateTestData.createTestCoreOptys(a1.Id, ctct1.Id)); 
        List<Opportunity> opps = [SELECT Id, OwnerId, Product_Summary__c FROM Opportunity WHERE AccountId =: a1.id]; 
        opps.get(0).Product_Summary__c = 'TaxPay;Payroll';
        opps.get(0).TotalOpportunityQuantity = 1;
        opps.get(0).Employees_Paid_Per_Payroll__c = 2;
        opps.get(0).Frequency__c = '1';
        opps.get(0).Amount = 100;
        opps.get(0).StageName = 'Sold';
        opps.get(0).Service_Location__c = 'Foxboro Branch 0008';
        opps.get(0).Prod_Payroll__c = true;
        update opps;
    
        Reference_MPSC_Onboarding_Document__c[] refMPSCDoc = [SELECT Id, Document__c, Received_State__c, Comments__c, 
                                                                Discrepancy_Resolution_Date__c, Check_In_Date__c
                                                                FROM Reference_MPSC_Onboarding_Document__c];
        System.assertEquals(2, refMPSCDoc.size());
        
        List<Reference_Core_Payroll__c> refCorePayroll = new List<Reference_Core_Payroll__c>();
        refCorePayroll = [SELECT Id, Sales_Rep__c FROM Reference_Core_Payroll__c];
        System.assertEquals(1, refCorePayroll.size());
        
        Test.SetCurrentPageReference(Page.MPSCOnboardingDocuments);
        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refCorePayroll.get(0));
        System.CurrentPageReference().getParameters().put('id',refCorePayroll.get(0).Id);
        RefMMSPayrollDocController rc = new RefMMSPayrollDocController(sc);
        
        System.assertEquals(3, rc.mmsDocList.size());  //all docs
        System.assertEquals(2, rc.refDocList.size());  //all docs attached to this ref core payroll object
        System.assertEquals(1, rc.newDocList.size());  //the docs not attached
        
        // remove doc already added to list     
        rc.selectedId = rc.refDocList.get(1).docId;
        Id testId = rc.selectedId;                 
        rc.markSelected(); //delete method
        System.assertEquals(1, rc.refDocList.size()); //after deletion, the refDocList now only has 1 document
        system.assertEquals(false, rc.isMMS);
        for (MMSDocumentWrapper dw: rc.mmsDocList)
        {   
            if (dw.docId == testId) //the document that was selected for deletion
            {   
                System.assertEquals('delete', dw.docRcdType);
                System.assertEquals('-None-', dw.MPSCdoc.Received_State__c);
                System.assertEquals('Changes Pending', rc.pgMsg);
            }
        }                           
        System.assertEquals(2, rc.newDocList.size());  //now there are 2 docs not attached
        
        // add removed doc back to list
        rc.selectedId = testId;
        rc.markSelected();
        System.assertEquals(2, rc.refDocList.size());
        for (MMSDocumentWrapper dw: rc.mmsDocList)
        {   
            if (dw.docId == testId)
            {   
                System.assertEquals('existing', dw.docRcdType);
                System.assertEquals('-None-', dw.MPSCdoc.Received_State__c);
            }
        }
        
        //add an additional document
        rc.selectedId = doc3.id;
        rc.markSelected();
        System.assertEquals(3, rc.refDocList.size());
        for (MMSDocumentWrapper dw: rc.mmsDocList)  //for each document attached to the ref core payroll object
        {   
            if (dw.docId == doc3.id)  //if it is the doc that was selected
            {   
                System.assertEquals('upsert', dw.docRcdType);
                System.assertEquals('-None-', dw.MPSCdoc.Received_State__c);
            }
        }
        
        //delete the doc just added
        rc.markSelected(); 
        for (MMSDocumentWrapper dw: rc.mmsDocList)  //for each document attached to the ref core payroll object
        {   
            if (dw.docId == doc3.id)  //if it is the doc that was selected
            {   
                System.assertEquals('NA', dw.docRcdType);
                System.assertEquals('-None-', dw.MPSCdoc.Received_State__c);
            }
        }
        
                
        //set Check in Date
        testId = rc.refDocList.get(1).docId;                               
        rc.refDocList.get(1).MPSCdoc.Check_In_Date__c = System.now().date();
        rc.saveDate();
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   
            if (dw.docId == testId)
            {   
                System.assertEquals('Complete', dw.MPSCdoc.Received_State__c);
                System.assertEquals('upsert', dw.docRcdType);
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg);              
            }
        }  
        
        //clear check in date
        rc.refDocList.get(1).MPSCdoc.Check_In_Date__c = null;
        rc.saveDate();
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   
            if (dw.docId == testId)
            {   
                System.assertEquals('-None-', dw.MPSCdoc.Received_State__c);
                System.assertEquals('upsert', dw.docRcdType);
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg);              
            }
        } 
        
        //add in a Comment                              
        rc.refDocList.get(1).MPSCdoc.Comments__c = 'Test Comment';
        rc.saveComment();
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   if (dw.docId == testId)
            {   
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg);              
            }
        }  
        //change comment
        rc.refDocList.get(1).MPSCdoc.Comments__c = 'Test Change Comment';
        rc.saveComment();
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   if (dw.docId == testId) 
            {   
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg);              
            }
        }  
        
        //change state to Discrepancy
        rc.refDocList.get(1).MPSCdoc.Received_State__c = 'Discrepancy';
        rc.saveState();
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   if (dw.docId == testId) 
            {   
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg);    
                System.assertEquals(true, rc.isDiscrepancy);
                System.assertEquals((ID)dw.salesRep, rc.salesRepId);
                System.assertEquals(dw.MPSCdoc.Reference_Core_Payroll_field__c, rc.refCorePayrollObject);           
            }
        } 
        
        //set the Discrepancy Resolution Date
        rc.refDocList.get(1).MPSCdoc.Discrepancy_Resolution_Date__c = System.now().date();
        rc.saveResolutionDate();
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   
            if (dw.docId == testId) 
            {   
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg);    
                System.assertEquals('Resolved', dw.MPSCdoc.Received_State__c);      
            }
        } 
     
        
        //clear the Discrepancy Resolution Date
       /* rc.refDocList.get(1).MPSCdoc.Discrepancy_Resolution_Date__c = null;
        rc.saveResolutionDate();
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   
            if (dw.docId == testId) 
            {   
                System.assertEquals('Discrepancy', dw.MPSCdoc.Received_State__c);
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg);      
            }
        }
        */
/*        
       rc.refDocList.get(1).MPSCdoc.Received_State__c = 'Discrepancy';
       rc.saveState();
        
        rc.resolveAll();
        for (MMSDocumentWrapper dw: rc.refDocList)
        {   
            if (dw.docId == testId) 
            {   
                System.assertEquals('Resolved', dw.MPSCdoc.Received_State__c);
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg); 
                System.assertEquals(System.today(), dw.MPSCdoc.Discrepancy_Resolution_Date__c);         
            }
        } 
     }
    
    @isTest(SeeAllData=true)  //needed to check chatter posts using ConnectAPI
    static void testMPSCOnboardingDocumentsSave()
    {
        // create test onboarding documents
        List<MMS_Onboarding_Documents__c> mmsOnbrdingDocs = new List<MMS_Onboarding_Documents__c>();
        MMS_Onboarding_Documents__c doc1 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Payroll Doc1'
                                                                            , Mandatory_for_MPSC__c = true
                                                                            , MPSC_Onboarding_Document__c = true
                                                                            , Product_Category__c = 'Payroll' );
        mmsOnbrdingDocs.add(doc1);
        MMS_Onboarding_Documents__c doc2 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Taxpay Doc2'
                                                                            , Mandatory_for_MPSC__c = false
                                                                            , MPSC_Onboarding_Document__c = true
                                                                            , Product_Category__c = 'TaxPay' );
        mmsOnbrdingDocs.add(doc2);
        insert mmsOnbrdingDocs;
            
        // create account, contact   
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name from Account where name = 'Test Account2'];
        Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
        List<Id> testOptyIds = new List<Id>();  
        
        // create a Core Opportunity, set the Product Summary on the Opp
        //mark it Sold - that will create Case and Reference Object and Onboarding Documents
        testOptyIds.add(CreateTestData.createTestCoreOptys(a1.Id, ctct1.Id)); 
        List<Opportunity> opps = [SELECT Id, OwnerId, Product_Summary__c FROM Opportunity WHERE AccountId =: a1.id]; 
        opps.get(0).Product_Summary__c = 'TaxPay;Payroll';
        opps.get(0).TotalOpportunityQuantity = 1;
        opps.get(0).Employees_Paid_Per_Payroll__c = 2;
        opps.get(0).Frequency__c = '1';
        opps.get(0).Amount = 100;
        opps.get(0).StageName = 'Sold';
        opps.get(0).Service_Location__c = 'Foxboro Branch 0008';
        opps.get(0).Prod_Payroll__c = true;
        update opps;
    
        List<Reference_Core_Payroll__c> refCorePayroll = new List<Reference_Core_Payroll__c>();
        refCorePayroll = [SELECT Id, Sales_Rep__c FROM Reference_Core_Payroll__c WHERE Opportunity_Lookup__c IN: opps];
        System.assertEquals(1, refCorePayroll.size());  
        Reference_MPSC_Onboarding_Document__c[] refMPSCDoc = [SELECT Id, Document__c, Received_State__c, Comments__c, 
                                                                Discrepancy_Resolution_Date__c, Check_In_Date__c
                                                                FROM Reference_MPSC_Onboarding_Document__c
                                                                WHERE Reference_Core_Payroll_field__c IN: refCorePayroll
                                                                AND Document__c =: 'Payroll Doc1'];
        //9 ref document objects being returned bc there are 7 mandatory docs when this class was created already in the org and I just added 2
        System.assertEquals(1, refMPSCDoc.size());
        
        Test.SetCurrentPageReference(Page.MPSCOnboardingDocuments);
        ApexPages.Standardcontroller sc = New ApexPages.StandardController(refCorePayroll.get(0));
        System.CurrentPageReference().getParameters().put('id',refCorePayroll.get(0).Id);
        RefMMSPayrollDocController rc = new RefMMSPayrollDocController(sc);
        
        // remove doc already added to list     
        rc.selectedId = refMPSCDoc.get(0).id;
        Id testId = rc.selectedId;     
                    
        refMPSCDoc.get(0).Comments__c = 'Test Change Comment';
        rc.saveComment(); 
        refMPSCDoc.get(0).Received_State__c = 'Discrepancy';
        rc.saveState(); 
        rc.saveDocs();
        
       for (MMSDocumentWrapper dw: rc.mmsDocList)
        {   
            if (dw.docId == testId)
            {   
                System.assertEquals(true, rc.pgMsg.contains('missing Check In Date.'));
            }
        }
        
        refMPSCDoc.get(0).Check_in_Date__c = System.now().date();
        rc.saveDate();
        rc.saveDocs();
        //check chatter post
        list<feedItem> coreFeedItem = [SELECT Id, Body FROM feedItem WHERE parentId =: refCorePayroll.get(0).id];
        for (MMSDocumentWrapper dw: rc.mmsDocList)
        {   
            if (dw.docId == testId)
            {   
                System.assertEquals(true, rc.pgMsg.contains('Successfully Saved'));
                System.assertEquals(true, coreFeedItem.get(0).body.contains('There is a discrepancy with one or more of the documents.'));
                System.assertEquals(true, coreFeedItem.get(0).body.contains(refMPSCDoc.get(0).Document__c));
                System.assertEquals(1,coreFeedItem.size());
            }
        }
        //add in a resolution date - should change state to resolved and save successfully
        refMPSCDoc.get(0).Discrepancy_Resolution_Date__c = System.now().date();
        rc.saveState(); 
        rc.saveDocs();
        for (MMSDocumentWrapper dw: rc.mmsDocList)
        {   
            if (dw.docId == testId)
            {   
                System.assertEquals(true, rc.pgMsg.contains('Successfully Saved'));
                System.assertEquals('Resolved', dw.MPSCdoc.Received_State__c);
                System.assertEquals('Changes Pending', rc.pgMsg);
                System.assertEquals(true, rc.showMsg); 
                System.assertEquals(System.today(), dw.MPSCdoc.Discrepancy_Resolution_Date__c); 
            }
        }
        //clear the date and there should be an error
        refMPSCDoc.get(0).Discrepancy_Resolution_Date__c = null;
        rc.saveState(); 
        rc.saveDocs();
        for (MMSDocumentWrapper dw: rc.mmsDocList)
        {   
            if (dw.docId == testId)
            {   
                System.assertEquals(true, rc.pgMsg.contains('missing Resolution Date.'));
            }
        }
        
        //need to do Save Docs
        //check chatter post
        //the database save
    }  LM 11/2017 - MPSC documents page no longer being used*/
}