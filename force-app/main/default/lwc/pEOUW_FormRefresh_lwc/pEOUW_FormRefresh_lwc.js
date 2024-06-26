import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getPEOchecklistDetails from "@salesforce/apex/CommunityFileUploadController.getPEOchecklistDetails"
import { getRecordNotifyChange } from "lightning/uiRecordApi";
const FIELDS = ['PEO_Onboarding_Checklist__c.HSF_Submission_Status__c', 'PEO_Onboarding_Checklist__c.HSF_Submission_Response__c'];
import { RefreshEvent } from 'lightning/refresh';

export default class PEOUW_FormRefresh_lwc extends LightningElement {
    @api Id;
    @api objectName;
    @track peoChkData;
    data;
    error;
    @track buttonClass = 'slds-button slds-button__icon_large buttonSpecs';

    refreshRecord() {
        console.log('Refresh Method call');
        this.buttonClass = 'slds-button slds-button__icon_large buttonSpecs rotated';
        getPEOchecklistDetails({ accountId: this.Id })
        .then((data) => {
        if (data) {
            console.log('Refresh Method call data:');
            console.log(data);
            this.peoChkData = data;
            this.buttonClass = 'slds-button slds-button__icon_large buttonSpecs';
            const evt= new CustomEvent('myUpdatedChecklist', {detail:
                {peoChkData:this.peoChkData
                }});
            this.dispatchEvent(evt);
        } 
        })
        .catch((error) => {
        this.error = error;
        console.log('Refresh Method call ERROR:');
        console.log(error);
        });
        }

}