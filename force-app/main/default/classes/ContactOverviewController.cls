//***8/15/2016 Josh Cartwright Created
//07/06/2020  Jacob Hinds         Added without sharing per PMD



public without sharing class ContactOverviewController {

    private Contact currentContact;
    public ApexPages.StandardController contactController {get; set;}
    public string sensitivities {get; set;}
    public integer numPORecs {get;set;}
    public string pOData {get;set;}
    public Prospect_Ownership__c pORec; 
    public string NSSOwner {get;set;}
    public user NSSUsr; 
 //   public string optyCRInfo{get;set;}
    public integer numOpty {get;set;}
   
    
    public ContactOverviewController(ApexPages.StandardController controller) {
        this.contactController = controller; 
        initialize(ApexPages.currentPage().getParameters().get('id'));
    }
      
    public void initialize(id id){ 
          if(id != NULL){
            
            /*
              List<Contact> currentContacts = [select id, name,PrimaryReferralType__c,SignificantContact__c, Sensitivity_401_k__c, 
              Sensitivity_BeneTrac__c,Sensitivity_FSA__c, Sensitivity_Health_Ins__c, Sensitivity_Icon__c, Sensitivity_PAO__c, 
              Sensitivity_Sales_Tax__c,Sensitivity_Wrks_Comp__c, Accountid 
              from Contact where id = :id];
              
              if(currentContacts.size() != 0){
                currentContact = currentContacts.get(0); 
                sensitivities = ''; 
                for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
                   if (psf.OnContact__c) {
                      Boolean isSensitive = (Boolean)currentContact.get(psf.FieldName__c);
                      if (isSensitive) {
                         if (String.isNotBlank(sensitivities)) {
                            sensitivities += ', ';
                         }
                         sensitivities += psf.Label__c;
                      }
                   }
                } // for (ProductSensitivityFields__c
                
 
              }
      */
    String[] sensitivityFldNames = new String[]{};
    String query = 'Select Id, Name, PrimaryReferralType__c, Accountid, SignificantContact__c  ';
    for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
         if (psf.OnContact__c && String.isNotBlank(psf.FieldName__c)) {
      sensitivityFldNames.add(psf.FieldName__c);
      query += ','+psf.FieldName__c;
        }//if 
    } // for (ProductSensitivityFields__c psf
    query += ' from Contact where Id = :id';

    List<Contact> currentContacts = Database.query(query);

       if(currentContacts.size() != 0){
          currentContact = currentContacts.get(0); 
          sensitivities = ''; 
       for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
           if (psf.OnContact__c) { 
            Boolean isSensitive = (Boolean)currentContact.get(psf.FieldName__c);
            if (isSensitive) {
               if (String.isNotBlank(sensitivities)) {
                  sensitivities += ', ';
               }//if
           sensitivities += psf.Label__c;
           }//if
         }//if 
                } // for (ProductSensitivityFields__c
             } // if (currentContacts.size()

      
      
      }//if
      
      NSSOwnership(currentContact.Accountid); 
      optyCRData(currentContact.id); 
        
    }     //initialize    
    
    private void NSSOwnership (id id){
                                        
        list<Prospect_Ownership__c> pOList = [select name, NSR_Name__r.Name,  NSS_Source__c, StartDate__c 
                                             from Prospect_Ownership__c where EndDate__c =null and Prospect_Client__c =:id order by StartDate__c desc ];                                        


        
        numPORecs = pOList.size(); 
        if(pOList.size()!= 0 && !pOlist.isEmpty()){             
            pORec  = pOList[0]; 

//build POData string to display on page
            NSSOwner = pORec.NSR_Name__r.Name;      
            pOData = ' NSR:' + NSSOwner;
            pOData += ', NSS Source: ' +pORec.NSS_Source__c;  
            POData += ', Total Open NSS Records: ' + numPORecs;     
            }//if

        
    }//NSSOwnership 
    
    private void optyCRData(id id){
        list<OpportunityContactRole> optyCRList = [select ContactId, OpportunityId, Opportunity.StageName from OpportunityContactRole where Opportunity.StageName ='pending' and ContactId =:id] ;
        
        numOpty = optyCRList.size(); 
        
        
    }//optyData
    
    public boolean hasSensitivities{
        get {return (sensitivities != '');}
        
    }//hasSensitivities 
    
    public boolean isReferral{
        get{return (string.isNotBlank(currentcontact.PrimaryReferralType__c));}
    }//isreferral
    
    public boolean isSignificantCntct{
        get{return (currentContact.SignificantContact__c);}
    }//isSignificantCntct

    

}//ContactOverviewController