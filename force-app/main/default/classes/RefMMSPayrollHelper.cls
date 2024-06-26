/*  
   After insert of a new MMS reference object, attach mandatory documents along with documents needed based on the product summary field
 *   
 * History
 * -------
 * 05/31/2013 Cindy Freeman     created
 * 12/2/2015  Lynn Michels		adding functionality for MPSC Onboarding Documents  
 * 03/25/2024 Carrie Marciano	CanBeDeleted old MPSC tech debt
 *
 */

public with sharing class RefMMSPayrollHelper {
    public RefMMSPayrollHelper(){}
/*
	//MMS
	private static List<MMS_Onboarding_Documents__c> mandatoryDocs;							// all MMS Onboarding Docs that are checked as mandatory
	private static Map<String, List<MMS_Onboarding_Documents__c>> productDocs;				// string = product with list of required docs
	private static List<Reference_MMS_Payroll_Documents__c> createRefDocs;					// list of Ref MMS Payroll Docs to be inserted
	//MPSC
	private static List<MMS_Onboarding_Documents__c> mandatoryMPSCDocs;							
	private static Map<String, List<MMS_Onboarding_Documents__c>> productMPSCDocs;	
	private static List<Reference_MPSC_Onboarding_Document__c> createRefMPSCDocs;	//list of Ref MPSC Onboarding Docs to be inserted - LM
	
	public static void createOnboardingDocs(Reference_MMS_Payroll__c[] refMMSList) {
		buildDocLists();
		populateCreateDocs(refMMSList);
		if (!createRefDocs.isEmpty())
		{	insert createRefDocs;		}
	} // createOnboardingDocs
	
	//added for MPSC Onboarding docs
	public static void createMPSCOnboardingDocs(Reference_Core_Payroll__c[] refCoreList) {
		system.debug('LM - testing Helper');
		buildDocLists();
		createRefMPSCDocObject(refCoreList);
		if (!createRefMPSCDocs.isEmpty())
		{	
			insert createRefMPSCDocs;		
		}
	} // end createMPSCOnboardingDocs
*/	

	/* build list of mandatory docs and map of product to docs
	*/
/*	
	private static void buildDocLists() {
		//retreiving all of the documents
		List<MMS_Onboarding_Documents__c> allDocs = [SELECT Id, Document_Name__c, Mandatory__c, Product_Category__c,
													MMS_Payroll_Document__c, MPSC_Onboarding_Document__c, //LM - added to sort MMS vs MPSC docs
													Mandatory_for_MPSC__c  //added for MPSC mandatory documents
													from MMS_Onboarding_Documents__c ORDER BY Mandatory__c];
		mandatoryDocs = new List<MMS_Onboarding_Documents__c>();													
		productDocs = new Map<String, List<MMS_Onboarding_Documents__c>>();	
		
		mandatoryMPSCDocs = new List<MMS_Onboarding_Documents__c>();													
		productMPSCDocs = new Map<String, List<MMS_Onboarding_Documents__c>>();													
		//for each document, see if it is mandatory, put into appropriate Lists based on MMS or MPSC
		for (MMS_Onboarding_Documents__c doc: allDocs)
		{	
			//MPSC
			if(doc.Mandatory_for_MPSC__c)
			{
				system.debug('LM - test mandatory');
				mandatoryMPSCDocs.add(doc);
			}
			if(doc.Product_Category__c != null)
			{
				if(doc.MPSC_Onboarding_Document__c)
				{
					List<String> categories = doc.Product_Category__c.split(';');   //put the categories into a list
					for (String c: categories)										//loop through each cateogry
					{	c = c.trim();												//trim whitespace from beginning and end
						List<MMS_Onboarding_Documents__c> MPSCDocs = ProductMPSCDocs.get(c); //get the list of documents for that category
						if (MPSCDocs == null)										//if the list of docs is empty, create a new list
						{	
							MPSCDocs = new List<MMS_Onboarding_Documents__c>();
							ProductMPSCDocs.put(c, MPSCDocs);						//populate the map with the category and the list of docs		
						}
						MPSCDocs.add(doc);											//add the document to the list
					} // for cateories
				}//end if MPSC_Onboarding_Document__c
			}//end if
			
			
			//MMS
			if (doc.Mandatory__c)
			{	mandatoryDocs.add(doc);	}
			if (doc.Product_Category__c != null)
			{	
				if(doc.MMS_Payroll_Document__c)
				{
					List<String> prods = doc.Product_Category__c.split(';');
					for (String p: prods)
					{	p = p.trim();
						List<MMS_Onboarding_Documents__c> listDocs = ProductDocs.get(p);
						if (listDocs == Null)
						{	listDocs = new List<MMS_Onboarding_Documents__c>();
							ProductDocs.put(p, listDocs);					
						}
						listDocs.add(doc);					
					} // for prods
				}// end ifMMS_Payroll_Document__c
			} // if product_category!=null					
		} // for
		
		return;
	} // buildDocLists
	
	//create Reference_MPSC_Onboarding_Document__c objects for each document releated to this Ref Core Payroll object
	private static void createRefMPSCDocObject(Reference_Core_Payroll__c[] allCorePayroll)
	{
		Set<Id> tempDocIds;								
		createRefMPSCDocs = new List<Reference_MPSC_Onboarding_Document__c>();  //list of Ref MPSC objects to create
		
		for (Reference_Core_Payroll__c refCore: allCorePayroll)  //for each Core payroll object,  
		{	
			tempDocIds = new Set<Id>();
			if (!mandatoryMPSCDocs.isEmpty())
			{	
				system.debug('LM - mandatory doc' + mandatoryMPSCDocs );
				for (MMS_Onboarding_Documents__c doc: mandatoryMPSCDocs)  //for each mandatory document, create a ref MPSC doc object
				{	
					Reference_MPSC_Onboarding_Document__c newDoc = new Reference_MPSC_Onboarding_Document__c();
					newDoc.Reference_Core_Payroll_field__c = refCore.Id;
					newDoc.MMS_Onboarding_Documents__c = doc.Id;
					newDoc.Document__c = doc.Document_Name__c;
					newDoc.Mandatory__c = true;
					createRefMPSCDocs.add(newDoc);	  //add new ref MPSC doc object to the list to insert						
					tempDocIds.add(doc.Id);				//add the doc id to the temp set of doc ids								
				} // for mandatoryDocs
			} // !mandatoryDocs.isEmpty
			//make ref MPSC Onboarding Document Objects for the products that were added without mandatory documents
			if (refCore.Product_Summary__c != null)
			{	
				list<String> categories = refCore.Product_Summary__c.split(';');  //create a list of the categories
				for (String c : categories)
				{	
					c = c.trim();	
					if (productMPSCDocs.containsKey(c))	//if the map already contains the category, get the list of documents			
					{	
						List<MMS_Onboarding_Documents__c> docs = productMPSCDocs.get(c);
						system.debug('LM - ' + docs );
						for (MMS_Onboarding_Documents__c doc : docs)  //for each doc, see if it is in the list of leftover docs
						{	
							if (!tempDocIds.contains(doc.Id))		  //if the id is not in the list, the ref object has not been created yet
							{	
								Reference_MPSC_Onboarding_Document__c newDoc = new Reference_MPSC_Onboarding_Document__c();
								newDoc.Reference_Core_Payroll_field__c = refCore.Id;
								newDoc.MMS_Onboarding_Documents__c = doc.Id;
								newDoc.Document__c = doc.Document_Name__c;
								newDoc.Mandatory__c = false;
								createRefMPSCDocs.add(newDoc);				
								tempDocIds.add(doc.Id);																
							} // !tempDocsIds.contains							
						} // for docs
					} // !docs.isEmpty
				} // for categories
			} // if product_Summary__c != null
		} // for refCore
		
	} // createRefMPSCDocs 

	/* read thru trigger records to decide which documents are needed for each reference MMS record
	 */
/*	
	private static void populateCreateDocs(Reference_MMS_Payroll__c[] allrefMMS) {
		Set<Id> tempDocIds;												//	set of docs being added for each ref obj to make sure we don't create dup rcds
		createRefDocs = new List<Reference_MMS_Payroll_Documents__c>();
		for (Reference_MMS_Payroll__c refMMS: allrefMMS)
		{	tempDocIds = new Set<Id>();
			if (!mandatoryDocs.isEmpty())
			{	for (MMS_Onboarding_Documents__c manDoc: mandatoryDocs)
				{	Reference_MMS_Payroll_Documents__c newDoc = new Reference_MMS_Payroll_Documents__c();
					newDoc.Reference_MMS_Payroll__c = refMMS.Id;
					newDoc.MMS_Onboarding_Documents__c = manDoc.Id;
					newDoc.Document__c = manDoc.Document_Name__c;
					newDoc.Mandatory__c = true;
					createRefDocs.add(newDoc);							
					tempDocIds.add(manDoc.Id);										
				} // for mandatoryDocs
			} // !mandatoryDocs.isEmpty
			if (refMMS.Product_Summary__c != null)
			{	list<String> prodSumm = refMMS.Product_Summary__c.split(';');
				for (String prod:prodSumm)
				{	prod = prod.trim();	
					if (productDocs.containsKey(prod))				
					{	List<MMS_Onboarding_Documents__c> docs = productDocs.get(prod);
						for (MMS_Onboarding_Documents__c doc : docs)
						{	if (!tempDocIds.contains(doc.Id))								// making sure didnt already create this onboarding doc
							{	Reference_MMS_Payroll_Documents__c newDoc = new Reference_MMS_Payroll_Documents__c();
								newDoc.Reference_MMS_Payroll__c = refMMS.Id;
								newDoc.MMS_Onboarding_Documents__c = doc.Id;
								newDoc.Document__c = doc.Document_Name__c;
								newDoc.Mandatory__c = false;
								createRefDocs.add(newDoc);				
								tempDocIds.add(doc.Id);																
							} // !tempDocsIds.contains							
						} // for docs
					} // !docs.isEmpty
				} // for prod:prodSumm
			} // if product_Summary__c != null
		} // for refMMS
		
	} // populateCreateDocs
*/
}