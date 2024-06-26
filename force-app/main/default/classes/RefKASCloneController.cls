/*
* Controller for ReferenceKASClone.page - clone Reference KAS and its case
*
* 03/14/2018 Lynn Michels Created
*
*
*/
public with sharing class RefKASCloneController {
	
	private final SObject parent{get;set;}  //represents the record we start from
	public Reference_KAS__c originalReference;   //represents the casted object
	public Case originalCase;
	public Case clonedCase{get;set;}
	public Reference_KAS__c clonedReference{get;set;}
	public boolean displayMessages{get;set;}
	public boolean displayErrorMessage{get;set;}
	public boolean confirmClone{get;set;}
	public boolean success{get;set;}
	
	public RefKASCloneController(ApexPages.StandardController controller){
	system.debug('RefKASCloneController ENTER');	
		//get the record we are starting from in sObject form and cast it as a Reference KAS record
		parent = controller.getRecord();
	system.debug('RefKASCloneController kas Id '+parent);
		//using the Reference KAS id, get the fields that are editable
		String creatableReferenceFields = ObjectHelper.getCreatableFields('Reference_KAS__c','id=\''+parent.id+'\'');
	system.debug('RefKASCloneController creatableReferenceFields '+creatableReferenceFields);
		//query the reference record to get the field values
        originalReference = (Reference_KAS__c)Database.query(creatableReferenceFields);
    
        //query for case from fields pulled back from Reference_KAS query
        originalCase = [SELECT OwnerId, AccountId, ContactId, ParentId, Service_Location__c,
        					Origin, Reason, Subject, Description, RecordTypeId FROM Case WHERE Id =: originalReference.Case_Lookup__c]; 
        confirmClone = true;
        success = false;					
	}

	//Clone the case and reference kas records
	public void cloneRecords(){
		confirmClone = false;
		success = false;
		clonedCase = new Case();
        clonedCase = originalCase.clone(false, true); //clone original case, get new ID 
        clonedCase.AccountId = null;
        clonedCase.ContactId = null;
        clonedCase.Type = 'System'; //this is being set so Object Relationships do not create another reference kas record
        
        //Clone reference KAS
        clonedReference = new Reference_KAS__c();
        clonedReference = originalReference.clone();
	}//end cloneRecords
	
     //insert the records and create a confirmation message
     public void processClone(){
 
        //make sure the user populated the account and contact on the vf page
        if(clonedCase.AccountId != null || clonedCase.ContactId != null){
	        try{
	        	insert clonedCase;
	        	clonedReference.Case_Lookup__c = clonedCase.id;
	        	insert clonedReference;
	  			success = true;
	  			string chatterMessage = 'A Service Support KAS Case and Reference KAS have been created: ';
	            string caseLink = '<a href="/'+clonedCase.Id+'" target="_blank"><b><font face="verdana" color="blue">New Service Suppport Case</font></b></a></br>';
	            string refLink = '<a href="/'+clonedReference.Id+'" target="_blank"><b><font face="verdana" color="blue">New Reference KAS</font></b></a>';
	            
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, chatterMessage+caseLink+refLink)); 
	            displayMessages = true;
        	}//end try
        	catch(Exception e){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'There was an error cloning the records. '+e.getMessage())); 
        		system.debug('processClone exception '+e.getStackTraceString());
        	}//end catch
        }//end if
     	else{
	        	success = false;
	        	string chatterMessage = 'Please populate the Prospect Client and Contact fields.';
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, chatterMessage)); 
	            displayErrorMessage = true;
		}//end else
		
	}//end processClone
}//end RefKASCloneController