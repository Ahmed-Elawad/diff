import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import BUYERJOURNEY_FIELD from '@salesforce/schema/Contact.Buyer_Journey__c';
import Banner_Icons from '@salesforce/resourceUrl/BannerIcons';


export default class BuyerJourney extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track buyerJourneyValue;
    @track buyerJourneyDisplayValue;
    @track buyerJourneyImageValue;
    @track buyerJourneyEvaluation;
    @track buyerJourneyEducation;
    @track buyerJourneyAwareness;
    @track buyerJourneyNone;
    @track imageURL;
    @track buyerJourneyField;

    connectedCallback() {
        if(this.objectApiName==='Contact') {
            this.buyerJourneyField = 'Contact.Buyer_Journey__c';
        }
        if(this.objectApiName==='Lead') {
            this.buyerJourneyField = 'Lead.Buyer_Journey__c';
        }
    }
    @wire (getRecord, {recordId : '$recordId', 
                   fields: '$buyerJourneyField'
        })
    loadbuyerJourney({ error, data }) {
        if (error) {
            console.log('error:', 
                error.body.errorCode, 
                error.body.message
            );
        } else if (data) {
            this.buyerJourneyValue = data.fields.Buyer_Journey__c.value;
            if(this.buyerJourneyValue == 'Not enough data' || this.buyerJourneyValue == null){
                this.buyerJourneyNone = 'Not enough data';
            }
            else{
                this.buyerJourneyDisplayValue = this.buyerJourneyValue.split(" ")[0];
                this.buyerJourneyImageValue = this.buyerJourneyValue.split(" ")[1];
                
                if(this.buyerJourneyImageValue!= null){
                    if(this.buyerJourneyImageValue == 'Low'){
                        this.imageURL = Banner_Icons + '/LightningIcons/BuyerJourneyLow.png';
                    }
                    else if(this.buyerJourneyImageValue == 'Medium'){
                        this.imageURL = Banner_Icons + '/LightningIcons/BuyerJourneyMedium.png';
                    }
                    else if(this.buyerJourneyImageValue == 'High'){
                        this.imageURL = Banner_Icons + '/LightningIcons/BuyerJourneyHigh.png';
                    }
                }  

                
                if(this.buyerJourneyDisplayValue == 'Awareness'){
                    this.buyerJourneyAwareness = 'Awareness';
                }
                else if(this.buyerJourneyDisplayValue == 'Education'){
                    this.buyerJourneyEducation = 'Education';
                }
                else if(this.buyerJourneyDisplayValue == 'Evaluation'){
                    this.buyerJourneyEvaluation = 'Evaluation';
                }
            }
        }
    }
}