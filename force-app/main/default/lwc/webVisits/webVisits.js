import { LightningElement, api, wire, track} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import BANNERICONS_IMAGE from '@salesforce/resourceUrl/BannerIcons';


export default class WebVisits extends LightningElement {   
    @api recordId;
    @api objectApiName;
    @track webVisitHigh;
    @track webVisitMedium;
    @track webVisitLow;
    @track webVisitNone;
    @track imageURL;
    @track webVisitField;

    connectedCallback() {
        if(this.objectApiName==='Contact') {
            this.webVisitField = 'Contact.Web_Visit_Rate__c';
        }
        if(this.objectApiName==='Lead') {
            this.webVisitField = 'Lead.Web_Visit_Rate__c';
        }
    }
    @wire (getRecord, {recordId : '$recordId', 
                   fields: '$webVisitField'
        })
    loadWebVisits({ error, data }) {
        if (error) {
            console.log('error:', 
                error.body.errorCode, 
                error.body.message
            );
        } else if (data) {
            this.webVisitValue = data.fields.Web_Visit_Rate__c.value;

            if(this.webVisitValue == 'Low'){
                this.imageURL = BANNERICONS_IMAGE + '/LightningIcons/WebVisitLow.png';
                this.webVisitLow = 'Low';
            }

            else if(this.webVisitValue == 'Medium'){
                this.imageURL = BANNERICONS_IMAGE + '/LightningIcons/WebVisitMedium.png';
                this.webVisitMedium = 'Medium';
            }

            else if(this.webVisitValue == 'High'){
                this.imageURL = BANNERICONS_IMAGE + '/LightningIcons/WebVisitHigh.png';
                this.webVisitHigh = 'High';
            }
            else {
                this.webVisitNone = 'Not enough Data';
            }
        }
    }
}