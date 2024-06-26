//Test class for ContactOverviewController
// ***8/15/2016 Josh Cartwright Created 
@isTest()
Private Class ContactOverviewControllerTest{

//Create test accounts	
   public static Account Acct1 = createTestAcct('acct1');   	

//variables for contacts 	
   public static Contact cntct1;   	
   public static Contact cntct2;
   public static Contact[] cntcts; 

   
//variables for PO records
	public static Prospect_Ownership__c PO1;
	public static Prospect_Ownership__c PO2;   
    public static Prospect_Ownership__c [] Pos; 
	
//variable for User 
   public static User rep1;


//variable for custom setting 

	public static ProductSensitivityFields__c PS1;
	public static ProductSensitivityFields__c PS2; 
	public static ProductSensitivityFields__c [] PSs; 
	
//variable for oppty
	public static opportunity o1; 
	public static opportunity o2; 
	public static opportunity [] os; 
	
//variables for OpportunityContactRole
	public static OpportunityContactRole OCR1; 
	public static OpportunityContactRole OCR2; 
	public static OpportunityContactRole []OCRs; 	
	
	

//set up and insert accounts, contacts, Prospect ownership records 
   public static void setupData() {
   	UserHelperTest.selectDsaAndReps(); 
	rep1 = UserHelperTest.v_reps[0]; 
   	insert Acct1;  

   	cntct1 = createTestCntct(acct1.id, rep1.Id, 'cntct1', 'lName1');   	
   	cntct2  = createTestCntct(acct1.id, rep1.id, 'cntct2', 'lName1');
   	cntcts = new Contact []{cntct1, cntct2};
   	insert cntcts; 
   	
//set up user for PO ownership 
  	
   	PO1 = createTestPO (acct1.id, rep1.id); 
   	PO2 = createTestPO (acct1.id, rep1.id); 
   	
   	POs = new Prospect_Ownership__c []{PO1, PO2};
   	insert POs; 
   	
//set up custom setting data    	
	PS1 = createPS ('Sensitivity_401_k__c', '401k','Sensitivity_401_k__c');
	PS2 = createPS ('Sensitivity_FSA__c', 'FSA','Sensitivity_FSA__c');
   	PSs = new ProductSensitivityFields__c[]{PS1,PS2}; 
   	insert PSs; 
   	
   	
//set up oppty 

	o1 = createopty(acct1.id); 
	o2 = createopty(acct1.id); 
	os = new opportunity []{o1,o2}; 
	insert os; 
	
//set up opportunitycontactrole 

	OCR1 = createOCR (cntct1.id, o1.id); 
	OCR2 = createOCR (cntct1.id, o1.id);
	OCRs = new OpportunityContactRole []{OCR1, OCR2}; 
	insert OCRs;  
   	
   } // setupStndData	
   
 //run test  
   static testMethod void runTest(){
  	setupData();
  	cntct1.Sensitivity_401_k__c	 =true;
	cntct1.Sensitivity_FSA__c	=true; 
	update cntct1; 
  	
  	ApexPages.currentPage().getParameters().put('id',cntct1.id);
	
	ContactOverviewController coc = new ContactOverviewController(new ApexPages.StandardController(cntct1)); 
	
	system.assertequals(coc.numPORecs, 2); 	
	system.assert(coc.sensitivities !='');
	system.assert(coc.hasSensitivities);
	system.assert(!coc.isReferral);
	system.assert(coc.isSignificantCntct);
	system.assertequals(coc.numOpty, 2);
	
   }//runTest
	
	static Account createTestAcct(String acctName){
        return new Account	(name = acctName                                   
                                        ,ShippingStreet = '911 Panorama Trail South'
                                        ,ShippingCity = 'Rochester'
                                        ,ShippingState = 'NY'
                                        ,ShippingPostalCode = '14586');
                                        
    } //createTestAcct   
    static Contact createTestCntct(id acctId, id cOwnerId, String cFName,  String cLName){
        return new Contact(FirstName = cFName
        								,LastName = cLNAme	                                       
                                        ,AccountId = acctId
                                        ,OwnerId = cOwnerId
                                        ,MailingStreet = '123'
                                        ,MailingCity = 'Rochester'
                                        ,MailingState = 'NY'
                                        ,MailingPostalCode = '14514'
                                        ,MailingCountry = 'US');
    }//createTestRefCntct


	static Prospect_Ownership__c createTestPO (id acctId, id NSRName){
		return new Prospect_Ownership__c (Prospect_Client__c =acctID
											,NSR_Name__c = NSRName
											,NSS_Source__c = 'Inbound'
											,StartDate__c = Date.today()); 
	}//Prospect_Ownership__c createTestPO 
	
	static ProductSensitivityFields__c createPS (string Name, string label, string FieldName ){
		return new ProductSensitivityFields__c (Name = name
									, OnContact__c =true
									, Label__c = label
									, FieldName__c = FieldName
										);
		
	} //createPS
	
	static Opportunity createopty (id account){
		return new Opportunity (AccountId = account
								, Name = 'payroll opty'
								, StageName = 'Pending'
								, CloseDate = Date.today().addDays(+1));
	}//createopty
	
	static OpportunityContactRole createOCR (id contact, id optyID){
		return new OpportunityContactRole (contactID = contact
											, OpportunityId = optyID);
										
		
	}//OpportunityContactRole

}//ContactOverViewControllerTest