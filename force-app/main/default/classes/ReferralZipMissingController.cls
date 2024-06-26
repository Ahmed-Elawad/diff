/*
* 
* 
* History
* -------
* 10/04/2022 Pujitha Madamanchi   Created
  11/15/2023 Pujitha Madamanchi   Added Contact
*/ 
public with sharing class ReferralZipMissingController {
    
    public String refObjectId{get;set;}
    public Lead lead {get;set;}
    public Contact ctct {get;set;}
    public Account acc {get;set;}
    private PageReference returnURL;
    public Boolean isLead {get;set;}
    public Boolean isContact {get;set;}

    public ReferralZipMissingController() {
        refObjectId = System.currentPageReference().getParameters().get('Id');
        System.debug('ReferralZipMissingController refObjectId'+refObjectId);
        Id checkId = (Id)refObjectId;
        isLead = checkId.getSObjectType() == Schema.Lead.SObjectType;
        isContact = checkId.getSObjectType() == Schema.Contact.SObjectType;
        lead = new Lead();
        ctct = new Contact();
        if(isLead){
            lead = [Select Id,PostalCode from Lead WHERE Id =:(Id)refObjectId limit 1];
            returnURL = new PageReference('/'+lead.Id);
        }
        else if(isContact){
            ctct = [Select Id, AccountId, Account.ShippingPostalCode, Account.Owner_Zip_Code__c from Contact WHERE Id =:(Id)refObjectId limit 1];
            returnURL = new PageReference('/'+ctct.Id);
        }
    }

    public PageReference cancel(){
        return returnURL;
    }

    public PageReference save(){
        PageReference returnURL;
        
        try{
            if(isLead){
                update lead;
                returnURL = Page.Referral;
                returnURL.setRedirect(true);
                returnURL.getParameters().put('Id', lead.Id); 
                returnURL.getParameters().put('startedFrom', 'Lead');
                returnURL.getParameters().put('functionType', 'NSS');
                System.debug('returnURL::'+returnURL);
            }
            else if(isContact){
                acc = [Select Id, ShippingPostalCode from Account where Id=:ctct.AccountId];
                acc.ShippingPostalCode = ctct.Account.ShippingPostalCode;
                update acc;
                returnURL = Page.Referral;
                returnURL.setRedirect(true);
                returnURL.getParameters().put('Id', ctct.Id); 
                returnURL.getParameters().put('startedFrom', 'Contact');
                returnURL.getParameters().put('functionType', 'NSS');
                System.debug('returnURL::'+returnURL);
            }
                     
            
        }
        catch(Exception e){
            ApexPages.addMessages(e);
        }
        return returnURL;
    }
}