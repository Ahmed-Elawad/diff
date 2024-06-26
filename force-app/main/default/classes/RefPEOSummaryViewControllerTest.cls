/**
 * 07/07/2016 Lynn Michels		created
 * 05/04/2017 Carrie Marciano	Added SB to end of profile names
 */
@isTest
private class RefPEOSummaryViewControllerTest {

	//make sure the correct field set displays for a user not Sales or HRG
    static testMethod void testAnyUser() {
	    Reference_PEO__c rp = new Reference_PEO__c();
	    insert rp;
	    Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
	    ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(rp);
	    System.CurrentPageReference().getParameters().put('id',rp.Id);
	    RefPEOSummaryViewController refSummaryController = new RefPEOSummaryViewController(sc1);
	      
	    system.assert(rp.id != null);
	    refSummaryController.fieldList();
	    refSummaryController.getFieldSetFields();
	    system.assertEquals('HRG_Summary_Set', refSummaryController.fieldSet);
    } 
    
    //make sure the correct fields display for HRG user
     static testMethod void testHRGUser() {
     	Profile p = [SELECT Id FROM Profile WHERE Name='HRS Sales Manager - SB'];
      	User u = new User(Alias = 'hrguser', Email='hrguser@testorg.com',
				      	EmailEncodingKey='UTF-8', LastName='Hrg', LanguageLocaleKey='en_US',
				      	LocaleSidKey='en_US', ProfileId = p.Id,Sales_Org__c='HRS',
				      	TimeZoneSidKey='America/Los_Angeles', UserName='hrguser@testorg.com');
     	Reference_PEO__c rp = new Reference_PEO__c();
      	insert rp;
     	System.runAs(u){
    		
      		Test.SetCurrentPageReference(Page.RefPEOSummaryView);
      		ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(rp);
      		System.CurrentPageReference().getParameters().put('id',rp.Id);
      		RefPEOSummaryViewController refSummaryController = new RefPEOSummaryViewController(sc1);
       		system.assert(rp.id != null);
       		refSummaryController.getFieldSetFields();
      	 	system.assertEquals('Sales_Summary_Set', refSummaryController.fieldSet);
     	}//end runAs
    } //end testHRGUser
    
    //make sure correct fields display for Sales user
    static testMethod void testSalesUser() {
     	Profile p = [SELECT Id FROM Profile WHERE Name='2008-09 HRS Premier Support Rep'];
      	User u = new User(Alias = 'salesa', Email='salesabc@testorg.com',
				      	EmailEncodingKey='UTF-8', LastName='salesabc', LanguageLocaleKey='en_US',
				      	LocaleSidKey='en_US', ProfileId = p.Id, EmployeeNumber = '12345', Sales_Org__c='HRS Premier',
				      	TimeZoneSidKey='America/Los_Angeles', UserName='salesabc@testorg.com');
		Reference_PEO__c rp = new Reference_PEO__c();
      	insert rp;
      				      	
     	System.runAs(u){
    		
      		Test.SetCurrentPageReference(Page.RefPEOSummaryView);
      		ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(rp);
      		System.CurrentPageReference().getParameters().put('id',rp.Id);
      		RefPEOSummaryViewController refSummaryController = new RefPEOSummaryViewController(sc1);
       		system.assert(rp != null);
       		refSummaryController.getFieldSetFields();
      	 	system.assertEquals('HRG_Summary_Set', refSummaryController.fieldSet);
     	}//end runAs
    } //end testSalesUser
    
    //ensure the discrepencies are being found
    static testMethod void testWithDiscrepencies() {
     	Profile p = [SELECT Id FROM Profile WHERE Name='2008-09 HRS Premier Support Rep'];
      	User u = new User(Alias = 'salesd', Email='salesdef@testorg.com',
				      	EmailEncodingKey='UTF-8', LastName='salesdef', LanguageLocaleKey='en_US',
				      	LocaleSidKey='en_US', ProfileId = p.Id, EmployeeNumber = '67891', Sales_Org__c='HRS Premier',
				      	TimeZoneSidKey='America/Los_Angeles', UserName='salesdef@testorg.com');
		Reference_PEO__c rp = new Reference_PEO__c();
      	insert rp;		      	
	
	      Reference_PEO_Discrepancy__c disc1 = new Reference_PEO_Discrepancy__c();
	      disc1.Reference_PEO__c = rp.Id;
	      disc1.Discrepancy_Area__c = 'Test1';
	      disc1.Discrepancy_Type__c = 'Test Type 1';
	      disc1.Discrepancy_Sub_Type__c = 'Test Sub Type 1';
	      disc1.HoldPayrollWillNotRun__c = true;
	      disc1.NonHoldPayrollWillRun__c = true;
	      disc1.Additional_Information__c = 'This is additional information';
	      insert disc1;
	
	      Reference_PEO_Discrepancy__c disc2 = new Reference_PEO_Discrepancy__c();
	      disc2.Reference_PEO__c = rp.Id;
	      disc2.Discrepancy_Area__c = 'Test2';
	      disc2.Discrepancy_Type__c = 'Test Type 2';
	      disc2.Discrepancy_Sub_Type__c = 'Test Sub Type 2';
	      disc2.HoldPayrollWillNotRun__c = false;
	      disc2.NonHoldPayrollWillRun__c = false;
	      disc2.Additional_Information__c = 'This is more additional information';
	      insert disc2;
      
     	System.runAs(u){
      		Test.SetCurrentPageReference(Page.RefPEOSummaryView);
      		ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(rp);
      		System.CurrentPageReference().getParameters().put('id',rp.Id);
      		RefPEOSummaryViewController refSummaryController = new RefPEOSummaryViewController(sc1);
       		system.assert(rp.id != null);
       		       system.debug('peo' + rp.id);
       		       system.assertEquals(rp.id, refSummaryController.refPEO.id);
       		
       		refSummaryController.getFieldSetFields();
      	 	system.assertEquals('HRG_Summary_Set', refSummaryController.fieldSet);
      	 	
      	 	List<Reference_PEO_Discrepancy__c> discrepList =  new List<Reference_PEO_Discrepancy__c>();
      	 	discrepList = refSummaryController.getPeoDiscrepancies();
      	 	system.assertEquals(2, discrepList.size()); 	
     	}//end runAs
    } //end testWithDiscrepencies
 
}