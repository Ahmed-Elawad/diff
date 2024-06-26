import { LightningElement,api,wire } from 'lwc';
import getOpportunityWithAcctId from '@salesforce/apex/CadenceTouchpointExtension.getOpportunityWithAcctId';

const columns = [
    { label: 'Name', fieldName:'OppLink' , type:'url',typeAttributes: { label: { fieldName: 'Name' }, target: '_self'}  },
    { label: 'Owner', fieldName: 'OwnerName' },
    { label: 'Status', fieldName: 'StageName' },
    { label: 'Run Date', fieldName: 'CloseDate',type: 'date',typeAttributes: {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit"
    } },
    { label: 'Created Date', fieldName: 'Created_Date_Time__c',type: 'date',typeAttributes: {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit"
    } },
    { label: 'Referral Contact', fieldName: 'ReferralContactName' },
];
export default class CadenceTouchpointReferrals extends LightningElement {
    
    
    @api refactid; 
    Opptys;
    OpptysPopulated;
    @wire(getOpportunityWithAcctId,{refActId :'$refactid'})
    getOpptyList({data,error}){
        if(data){
            console.log('We got data');
            this.Opptys =[...data];
            this.Opptys = this.Opptys.map(opp=>{
                let opp2 = JSON.parse(JSON.stringify(opp));
                console.log(opp2);
                if(opp.OwnerContact__r != undefined||opp.OwnerContact__r != null ){
                 opp2.OwnerName = opp.OwnerContact__r.Name;
                }
                if(opp.ReferralContact__r != undefined|| opp.ReferralContact__r != null){
                    opp2.ReferralContactName = opp.ReferralContact__r.Name;
                }
                opp2.OppLink = '/'+opp2.Id;
                 return opp2;
             });
            this.OpptysPopulated = true;
            console.log(this.Opptys);

        }
        if(error){
            console.log(error);
            console.log('Opportunity/Referral data was not properly received');
        }
    }
    columns = columns;
}