/** This class is used to get all the Opportunities related to the Referral Account which has Hosted_Client__c = True
* and update the related opp fields: Approved_Quote_Exception_Reason__c and Approved_Quotes_Exception__c
* was created based on the APR: https://issues.paychex.com/browse/SFDC-19204
* History
* -------
02/28/2023 Jaipal  Created

**/
public without sharing class UpdateOppFieldsQueueable implements Queueable {
    
    public Id refAcctId ; 
    public UpdateOppFieldsQueueable(Id refAcctId){
        this.refAcctId = refAcctId; 
    }
    
    public void checkRefAccts(){ 
        List<Opportunity> oppstoUpdate = new List<Opportunity>();
        //fetching all the opportunities related to the Referral Account which has Hosted_Client__c as True
        oppstoUpdate = [Select Id, Name, StageName, Referral_Account__c, Approved_Quotes_Exception__c, Approved_Quote_Exception_Reason__c From Opportunity Where Referral_Account__c =: refAcctId AND StageName!=: Label.OppStage_Lost AND StageName!=: Label.OppStage_Disqualified AND LeadSource LIKE :Label.LeadSource_ReferralCPA_start];
        for(Opportunity opp : oppsToUpdate){
            
            opp.Approved_Quote_Exception_Reason__c = Label.Approved_Quote_Exception_Reason;
            opp.Approved_Quotes_Exception__c = true;
            
        } //for(Opportunity opp
        
        if(!oppsToUpdate.isEmpty()){
            OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
            DMLHelper.performDML2(oppstoUpdate,DmlHelper.DML_UPDATE,'UpdateOppFieldsQueueable','checkRefAccts','Update Opps From Referral Accounts',null);
        }
    }//checkRefAccts
    public void execute(QueueableContext context) {
        checkRefAccts();
    }
}//UpdateOppFieldsQueueable