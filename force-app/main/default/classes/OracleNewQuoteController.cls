/* 
History
--------
used to validate fields are populated on the opportunity prior to allowing a new Oracle quote to be created

04/26/2020 Carrie Marciano  created 
  10/09/2020 Jake Hinds   Adding without sharing per PMD
  05/18/2021 Carrie Marciano changed to use Label.OppStage_Lost	

*/  


public without sharing class OracleNewQuoteController {
    
    /* Opportunity Fields to be validated */
    /*public Boolean hasNextStep {get; set;}
    public Boolean hasPrimComp {get; set;}
    public Boolean hasPayCurPriorMeth {get; set;}
    public String OppStatus {get; set;}
    public Integer Probability {get; set;}
    public Id OppRecType {get; set;} */
    public Boolean okayToProceed{get;private set;}
    public static String NOT_SOLD=Label.OppStage_Lost;
    public Id opptyId = null;  
    
    public OracleNewQuoteController(ApexPages.StandardController stdController){
        opptyId = System.currentPageReference().getParameters().get('Id');
        system.debug('OracleNewQuoteController opptyId: '+opptyId);
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'OracleNewQuoteController opptyId: '+opptyId));
      
        okayToProceed = (checkOpportunity(opptyId));
        System.debug('OracleNewQuoteController okayToProceed='+okayToProceed);     
        
    }
    
    public pageReference checkRedirect(){
        if(okayToProceed){
             PageReference OracleNew = Page.cafsl__EmbeddedTransaction; 
             OracleNew.getParameters().put('id',opptyId);
             OracleNew.setRedirect(True);
             System.debug('checkRedirect after redirect to cafsl__EmbeddedTransaction'); 
             return OracleNew;
        }
        return null;
    }
        
    public Boolean checkOpportunity(Id opptyId) {
      System.debug('inside checkOpportunity opptyId passed in: '+opptyId);
      Boolean okay = true;
      String message;  
      
      Opportunity oppty = null;
      try {
         oppty = [Select Id, Name
                       ,RecordTypeId
                       ,StageName
                       ,Probability
                       ,NextStep    
                       ,Payroll_Current_Prior_Method__c
                       //,Primary_Competition__c
                       ,Primary_Competitor__c
                       ,Pricebook2Id
                       ,OwnerId
                       ,Owner.Sales_Org__c
                   From Opportunity
                  Where Id = :opptyId];
      } catch (Exception e) {
         // log an error
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A valid Opportunity was not found. Cannot proceed!'));
      } 
      
      Set<String> oracleQuotePricebooks = new Set<String>(Label.OracleQuotePricebookId.split(','));
      Set<String> oracleQuoteRecordTypes = new Set<String>(Label.OracleQuoteRecordTypes.split(','));  
      if (oppty != null) {
          System.debug('inside checkOpportunity oppty != null RecordTypeId: '+oppty.RecordTypeId);

          //Pricebook check - must be FLEX or HRS-PEO-ASO SB
          // select the pricebooks
          if(!oracleQuotePricebooks.contains(oppty.Pricebook2Id)){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You cannot create a quote with current pricebook, please choose correct pricebook.'));
             okay = false; 
             System.debug('checkOpportunity invalid pricebookId: '+oppty.Pricebook2Id); 
          }
          //Recordtype check - should only be rep recordtype, not DSA/FSS recordtype
          else if(oppty.RecordTypeId == null || !oracleQuoteRecordTypes.contains(oppty.RecordTypeId)){
              ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You cannot create a quote on opportunity of this Recordtype.'));
              okay = false;
              System.debug('checkOpportunity invalid RecordTypeId: '+oppty.RecordTypeId);
          }          
          //Stage check - cannot create a quote if Not Sold
          else if(oppty.StageName == NOT_SOLD){
              ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You cannot create a quote on a Not Sold opportunity.'));
              okay = false;
              System.debug('checkOpportunity invalid Status: '+oppty.StageName);
          }          
           
          //Field check - fields must be populated prior to creating a quote
          /*  These checks are not required for HRS, may be required for MMS but requirements are still being worked out
          else if (okay){
              if (oppty.NextStep == null && oppty.Probability >= 40 && oppty.Probability <= 80){
                  message = (message == null ? 'Next Step (when Probability is between 40-80%)' : null);
              }
              else {
                  hasNextStep = true;
              }
              
              if (oppty.Payroll_Current_Prior_Method__c != null){
                  hasPayCurPriorMeth = true;
              }
              else {
                  message = (message == null ? 'Payroll Current-Prior Method' : message+', Payroll Current-Prior Method');
              }
              
              if (oppty.Primary_Competition__c != null){
                  hasPrimComp = true;  
              }
              else {
                  message = (message == null ? 'Primary Competition' : message+', Primary Competition');
              }
              
              if (message != null){
                 okay = false;
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You must populate '+message+' on opportunity before creating a quote.')); 
                 System.debug('checkOpportunity missing data in opportunity fields. Next Step: '+oppty.NextStep+' Payroll Current-Prior Method: '+oppty.Payroll_Current_Prior_Method__c+' Primary Competition: '+oppty.Primary_Competition__c); 
              }
          }  // if (okay)
        */        
      }
        
      return (okay && oppty != null && oppty.Id != null);
   } // checkOpportunity
}