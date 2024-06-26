/*
*This class is created to submit referral from P&C Quote Data
*History
*------------------
*09/25/2023 Pratik Das         Created APR0154201: Add process/button to P&C Quote Data
*/ 

public class SubmitReferralQuoteDataController{
    //public List<PC_Quote_Data__c> lstpcQuoteData=new List<PC_Quote_Data__c>();
    public List<PC_Quote_Data__c> lstpcQuoteData{set;get;}
    public Static Id accountId {get; set;}
    public Id pcQuoteId=null;
    public SubmitReferralQuoteDataController(){
        system.debug('MA'+System.currentPageReference().getParameters().get('Id'));
        pcQuoteId=System.currentPageReference().getParameters().get('Id');
        if(pcQuoteId!=null){ 
            //List<PC_Quote_Data__c> lstpcQuoteData=pcQuoteData(pcQuoteId);
            lstpcQuoteData=pcQuoteData(pcQuoteId);
            if(lstpcQuoteData[0].Opportunity__c!=null){
                //getPCDataForVf(lstpcQuoteData);
              //system.debug('MA2'+'Please Proceed');
              //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Please Proceed'));
              accountId=lstpcQuoteData[0].Opportunity__r.Account.Id;
            }
            else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, 'Could not find a Opportunity Record'));
            }
            
        }
    }

    public  List<PC_Quote_Data__c> pcQuoteData(Id pcQuoteId){
        return [Select id,Opportunity__c,Opportunity__r.Account.Id,Do_you_have_Workers_Comp__c,Workers_Comp_Carrier_Name__c,Renewal_Date__c,Notes__c  from PC_Quote_Data__c where Id=:pcQuoteId limit 1];
    }

    
    
    public PageReference redirectReferral() {
        //PageReference pr = new PageReference('/apex/Referral?Id='+accountId+'&startedFrom=Account');
        PageReference pr = Page.Referral;
        pr.getParameters().put('Id',lstpcQuoteData[0].Opportunity__r.Account.Id);
        pr.getParameters().put('startedFrom','Account');
        pr.getParameters().put('pcQuoteId',pcQuoteId);
        pr.setRedirect(true);
        return pr;
    }


}