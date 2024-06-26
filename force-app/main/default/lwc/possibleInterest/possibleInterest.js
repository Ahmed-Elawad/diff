import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import POSSIBLEINTEREST_FIELD from '@salesforce/schema/Contact.Marketing_Product_Interest__c';

export default class PossibleInterest extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track possibleInterestValue;
    @track interestField;

    connectedCallback() {
        console.log('data this.objectApiName:'+this.objectApiName);
        if(this.objectApiName==='Contact') {
            console.log('data contact:');
            this.interestField = 'Contact.Marketing_Product_Interest__c';
        }
        if(this.objectApiName==='Lead') {
            console.log('data Lead:');
            this.interestField = 'Lead.Marketing_Product_Interest__c';
        }
        console.log('data interest:', this.interestField);
    }
    @wire (getRecord, {recordId : '$recordId', fields: '$interestField'})

    loadInterest({ error, data }) {
        if (error) {
            console.log('error:', 
                error.body.errorCode, 
                error.body.message
            );
        } else if (data) {
            this.possibleInterestValue = data.fields.Marketing_Product_Interest__c.value;
            console.log('data interest:', this.possibleInterestValue);
            if(this.possibleInterestValue == null){
                this.possibleInterestValue = 'Not Enough Data'
            }


        }
    }
}