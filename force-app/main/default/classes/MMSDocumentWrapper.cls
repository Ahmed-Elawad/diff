/* 
 * Wrapper for the Reference MMS Onboarding Documents. This is a separate class from the RefMMSPayrollDocController because this
   has to be defined as global when it implements the Comparable interface and we didn't want to set the whole
   controller to global.
 *
 * History
 * -------
 * 06/07/2013 Cindy Freeman   Created
 * 12/2015    Lynn Michels    Added functionality for MPSC Documents
 * 3/20/2024  Carrie Marciano    CanBeDeleted old MPSC tech debt
 *
 */
global with sharing class MMSDocumentWrapper /*implements Comparable*/ {
    public MMSDocumentWrapper(){}
/*
	public Reference_MMS_Payroll_Documents__c doc {get; set;}
	public Reference_MPSC_Onboarding_Document__c MPSCdoc {get; set;}
	public String docRcdType {get; set;}						// used in controller, values=new, existing, delete, NA
	public Boolean selected{get;set;}							// did user select this doc?
	public Integer origCommentSize {get; set;}					// used to determine if comment changed
	public Date origDate {get; set;}							// used to determine if Check_In_date changed
	public String origRcvState {get; set;}						// used to determine if Received_State changed
	public Date origResolutionDate {get; set;}					// used to determine if Discrepancy_Resolution_date changed
	public String docId {get; set;}								// id of MMS_Onboarding_Documents__c for this doc
	public Boolean isMMS {get;set;}
	public ID salesRep {get;set;}
	
	// valid received states used to make sure check_in_date is populated
	public static Set<String> RCVD_STATE_SET = new Set<String>{'Complete','Discrepancy','Resolved'};	
	
	
/*	
	public Boolean isChanged {
 		get {
 			Boolean isChnged = false;
 			//MPSC
 			if(doc == null)
 			{
	 			if (docRcdType == 'existing' && MPSCdoc.Comments__c != null && origCommentSize != MPSCdoc.Comments__c.length())
	 			{	isChnged = true;	}
	 			if (docRcdType == 'existing' && (origDate != MPSCdoc.Check_In_Date__c) || (origDate != null && MPSCdoc.Check_In_Date__c == null))
	 			{	isChnged = true;	}
	 			if (docRcdType == 'existing' && (origResolutionDate != MPSCdoc.Discrepancy_Resolution_Date__c) || (origResolutionDate != null && MPSCdoc.Discrepancy_Resolution_Date__c == null))
	 			{	isChnged = true;	}
	 			if (docRcdType == 'existing' && (origRcvState != MPSCdoc.Received_State__c) || (origRcvState != null && MPSCdoc.Received_State__c == null))
	 			{	isChnged = true;	}
 			}
 			//MMS
 			else
 			{
	 			if (docRcdType == 'existing' && doc.Comments__c != null && origCommentSize != doc.Comments__c.length())
	 			{	isChnged = true;	}
	 			if (docRcdType == 'existing' && (origDate != doc.Check_In_Date__c) || (origDate != null && doc.Check_In_Date__c == null))
	 			{	isChnged = true;	}
	 			if (docRcdType == 'existing' && (origResolutionDate != doc.Discrepancy_Resolution_Date__c) || (origResolutionDate != null && doc.Discrepancy_Resolution_Date__c == null))
	 			{	isChnged = true;	}
	 			if (docRcdType == 'existing' && (origRcvState != doc.Received_State__c) || (origRcvState != null && doc.Received_State__c == null))
	 			{	isChnged = true;	}
 			}
			return isChnged;
 		} // get 			
 	} // isChanged
 	
 	
    //MMS
	//constructor when pass in existing mmsDocument   
    public MMSDocumentWrapper(Reference_MMS_Payroll_Documents__c mmsDoc) {
    	doc = mmsDoc;    	
    	docRcdType = 'existing';								
 		selected = true;							
 		origCommentSize = (mmsDoc.Comments__c != null ? mmsDoc.Comments__c.length() : 0);	 				
		origDate = mmsDoc.Check_In_Date__c;
		origRcvState = mmsDoc.Received_State__c;
		origResolutionDate = mmsDoc.Discrepancy_Resolution_Date__c;		
 		docId = mmsDoc.MMS_Onboarding_Documents__c;
 		isMMS = true;
 		//System.debug('**CMF ** wrapper constructor mmsDoc '+doc.Document__c); 
   	} // MMSDocumentWrapper for MMS documents
   	 
    // constructor when pass in Onboarding Document not yet linked to this reference obj
    public MMSDocumentWrapper(Reference_MMS_Payroll__c mmsRef, MMS_Onboarding_Documents__c mmsDoc) {
    	doc = new Reference_MMS_Payroll_Documents__c();
    	doc.MMS_Onboarding_Documents__c = mmsDoc.Id;
    	doc.Reference_MMS_Payroll__c = mmsRef.Id;
    	doc.Document__c = mmsDoc.Document_Name__c;    	
    	docRcdType = 'NA';								
 		selected = false;								
		origCommentSize = 0;
		origDate = null;
		origRcvState = null;
		origResolutionDate = null;
 		docId = mmsDoc.Id;
 		isMMS = true;
		//System.debug('**CMF ** wrapper constructor mmsRef,mmsDoc '+mmsDoc.Document_Name__c); 		
   	} // MMSDocumentWrapper for MMS documents
   	
    //MPSC
    //constructor when pass in existing mmsDocument
    public MMSDocumentWrapper(Reference_MPSC_Onboarding_Document__c mmsDoc) {
    	MPSCdoc = mmsDoc;    	
    	docRcdType = 'existing';								
 		selected = true;							
 		origCommentSize = (mmsDoc.Comments__c != null ? mmsDoc.Comments__c.length() : 0);	 				
		origDate = mmsDoc.Check_In_Date__c;
		origRcvState = mmsDoc.Received_State__c;
		origResolutionDate = mmsDoc.Discrepancy_Resolution_Date__c;		
 		docId = mmsDoc.MMS_Onboarding_Documents__c;
 		isMMS = false;
 		salesRep = mmsDoc.Ref_Core_Payroll_Sales_Rep__c;
   	} // MMSDocumentWrapper for MPSC documents
    
    //constructor when pass in Onboarding Document not yet linked to this reference obj
    public MMSDocumentWrapper(Reference_Core_Payroll__c mmsRef, MMS_Onboarding_Documents__c mmsDoc) {
    	MPSCdoc = new Reference_MPSC_Onboarding_Document__c();
    	MPSCdoc.MMS_Onboarding_Documents__c = mmsDoc.Id;
    	MPSCdoc.Reference_Core_Payroll_field__c = mmsRef.Id;
    	MPSCdoc.Document__c = mmsDoc.Document_Name__c;     	
    	docRcdType = 'NA';								
 		selected = false;								
		origCommentSize = 0;
		origDate = null;
		origRcvState = null;
		origResolutionDate = null;
 		docId = mmsDoc.Id;
 		isMMS = false;
 		salesRep = mmsRef.Sales_Rep__c;
   	} // MMSDocumentWrapper for MPSC documents
    
    
    global Integer compareTo(Object objectToCompareTo) {
 	    if (objectToCompareTo != null) {
     	    MMSDocumentWrapper compareDw = (MMSDocumentWrapper)objectToCompareTo;
     	    //MPSC
     	    if(doc == null)
     	    {
	        	if (MPSCdoc.Document__c != null && compareDw.MPSCdoc.Document__c != null) {
	            	return MPSCdoc.Document__c.compareTo(compareDw.MPSCdoc.Document__c);
	         	}
     	    }
     	    //MMS
     	    else
     	    {
	         	if (doc.Document__c != null && compareDw.doc.Document__c != null) {
	            	return doc.Document__c.compareTo(compareDw.doc.Document__c);
	         	}
     	    }
      }
      return -1;
   } // compareTo
    
*/
}