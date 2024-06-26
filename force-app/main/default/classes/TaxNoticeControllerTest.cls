/* 
  Test methods for TaxNoticeController
   
  History
  -------
  11/06/2017 Frank Lurz   Created
  
 */
@isTest
public class TaxNoticeControllerTest
{
    static testMethod void testinsert1()
    {
        TaxNoticeController tnc = new TaxNoticeController();
        tnc.cFS.Business_Name__c = 'Test';
        tnc.cFS.Submitter_is_Main_Contact__c = 'Yes';
        tnc.cFS.Federal_ID_Number_Submitted__c = '012345678';
        tnc.quicksave();
        List<Client_Field_Submission__c> cFSList = [Select id from Client_Field_Submission__c];
        system.assert(cFSList.size() == 1);
    }

    static testMethod void testinsert2()
    {
        TaxNoticeController tnc = new TaxNoticeController();
        tnc.cFS.Business_Name__c = 'Test';
        tnc.cFS.Main_Contact__c = FALSE;
        tnc.cFS.Main_Contact_Fax_Number__c = '(585)555-2151';
        tnc.cFS.Federal_ID_Number_Submitted__c = '012345678';
        tnc.cFS.Submitter_is_Main_Contact__c = 'No';
        tnc.quicksave();
        List<Client_Field_Submission__c> cFSList = [Select id from Client_Field_Submission__c];
        system.assert(cFSList.isEmpty());
    }
   
    static testMethod void testinsert3()
    {
        TaxNoticeController tnc = new TaxNoticeController();
        tnc.cFS.Business_Name__c = 'Test';
        tnc.cFS.Main_Contact__c = FALSE;
        tnc.cFS.Main_Contact_Fax_Number__c = '(585)555-2151';
        tnc.cFS.Federal_ID_Number_Submitted__c = '012345678';
        tnc.cFS.Submitter_is_Main_Contact__c = 'Yes';
        tnc.cFS.Notice_Type__c='Tax Lien/Levy/Warrant';
        tnc.cFS.Tax_Form__c='Corporate/Franchise/Sales & Use Tax';
        test.starttest();
        try{
        tnc.quicksave();
        } catch(exception e){}
        test.stoptest();
        List<Client_Field_Submission__c> cFSList = [Select id from Client_Field_Submission__c];
        system.assert(cFSList.isEmpty());
    }
    
    static testMethod void testinsert4()
    {
        TaxNoticeController tnc = new TaxNoticeController();
        tnc.cFS.Business_Name__c = 'Test';
        tnc.cFS.Main_Contact__c = FALSE;
        tnc.cFS.Main_Contact_Fax_Number__c = '(585)555-2151';
        tnc.cFS.Federal_ID_Number_Submitted__c = '012345678';
        tnc.cFS.Submitter_is_Main_Contact__c = 'Yes';
        tnc.cFS.Notice_Type__c='Zero-Due/Non-Filing/Other';
        tnc.cFS.Total_Amount_Due_per_Notice__c=100;
        test.starttest();
        try{
        tnc.quicksave();
        } catch(exception e){}
        test.stoptest();
        List<Client_Field_Submission__c> cFSList = [Select id from Client_Field_Submission__c];
        system.assert(cFSList.isEmpty());
    }
    
    
} // class TaxNoticeControllerTest