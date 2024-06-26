/*
* small controller for the Referral visual force page, not the component
* 
* History
* -------
* 03/21/2020 Cindy Freeman   Created
  10/04/2022 Pujitha Madamanchi Missing zip code for Lead
  11/15/2023 Pujitha Madamanchi Missing zip code for Contact
  12/08/2023 Pujitha Madamanchi Add null check

*/ 

public class ReferralControllerSmall {
    public Boolean isPopup{get;private set;}
    public String refObjectId{get;set;}  
    public Boolean displayZip{get;set;}
    
    // Constructor.
    public ReferralControllerSmall() {
        System.debug('ReferralControllerSmall here at constructor');
        String isPopupCheck = System.currentPageReference().getParameters().get('IsPopup');
        // default to a false value
        isPopup = (String.isNotBlank(isPopupCheck) && isPopupCheck == 'true');
        
        displayZip = false;
        // get the id of the object we originated from. If nothing is passed in here this should be an error!
        refObjectId = System.currentPageReference().getParameters().get('Id');
        Id checkId = (Id)refObjectId;
        if(checkId!=null && checkId.getSObjectType() == Lead.sObjectType){
            displayZip = checkZipCode(checkId,true,false);
        }
        if(checkId!=null && checkId.getSObjectType() == Contact.sObjectType){
            displayZip = checkZipCode(checkId, false, true);
        }
    }
    
    public static Boolean checkZipCode(Id recordId, Boolean isLead, Boolean isContact){
        Boolean isZipMissing = false;
        Set<Id> recordIdSet = new Set<Id>{recordId};
        if(isLead){
           Lead[] leads = new Lead[]{};
           leads = ReferralQueries.selectLeads(recordIdSet,null);
            //As we will only have 1 lead, using the first one
           if(!leads.isEmpty() && leads[0].PostalCode == null){
              isZipMissing = true;
           }                
        }    
        else if(isContact){
            Contact ctct = new Contact();
            ctct = ReferralQueries.selectContact(recordId);
            if(ctct!=null && ctct.Account.Owner_Zip_Code__c==null){
                isZipMissing = true;
            }
        }
        return isZipMissing;
    }
}