import { LightningElement, api, wire, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';
import CAMPAIGN_FIELD from '@salesforce/schema/Contact.LatestCampaign__c';
import NAME_FIELD from '@salesforce/schema/Contact.LatestCampaign__r.Name';

export default class LatestCampaign extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;


    @wire (getRecord, {recordId : '$recordId', 
                   fields:
                         [CAMPAIGN_FIELD, NAME_FIELD]
        })
    record;
    get Name() {
        return getFieldValue(this.record.data, NAME_FIELD);
    }
    get CampId() {
        return getFieldValue(this.record.data, CAMPAIGN_FIELD);
    }


    viewRecord(event) {
        // Navigate to Account record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": event.target.value,
                "objectApiName": "Campaign",
                "actionName": "view"
            },
        });
    }
}