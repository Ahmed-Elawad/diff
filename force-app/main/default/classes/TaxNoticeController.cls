/*

07/06/2020  Jacob Hinds         Added without sharing per PMD
*/

public without sharing class TaxNoticeController {

    public Client_Field_Submission__c cFS {get;set;}
    public Boolean display {get;set;}
	public Boolean totalDueRequired {get;set;}
	
    public TaxNoticeController() {
        cFS = new Client_Field_Submission__c();
        display = TRUE; 
		totalDueRequired=false;	
    }
  
    public PageReference quicksave() {
    
        Boolean okay = true;
        If (cFS.Submitter_is_Main_Contact__c == 'No') {
             if (String.isBlank(cFS.Main_Contact_Name__c)) {
                okay = false;}
             if (String.isBlank(cFS.Main_Contact_Email__c)) {
                okay = false; }
             if (String.isBlank(cFS.Main_Contact_Phone_Number__c)) {
                okay = false; }                
        }

      if (!okay) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'If you specify that you are not the main point of contact, then please enter the Main Contact Name, Email Address and Phone Number'));
         return null;
      }
      else if(cFS.Total_Amount_Due_per_Notice__c==null&&(cFS.Notice_Type__c=='Tax Lien/Levy/Warrant'||cFS.Notice_Type__c=='Balance Due Notice (includes Estimated/Proposed Assessments)')){
		 ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Total Amount Due per Notice is required'));
         return null;
        }
        else if(cFS.Total_Amount_Due_per_Notice__c!=null&&cFS.Total_Amount_Due_per_Notice__c>0&&(cFS.Notice_Type__c=='Zero-Due/Non-Filing/Other'||cFS.Notice_Type__c=='Overpayment Issue')){
		 ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Total Amount Due should be blank if Notice Type selected equals Overpayment or Zero-Due/Non-Filing/Other'));
         return null;
        }
      
          else if(cFS.Tax_Form__c=='Corporate/Franchise/Sales & Use Tax')
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please work directly with the agency as this is not a Tax Type supported by Paychex'));

     else
     try{
        insert cFS;
        display = False;

     }
     catch(Exception ex){
        ApexPages.addMessages(ex);
     }
        return null;
    }

}