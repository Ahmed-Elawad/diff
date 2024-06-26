import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getMetadata from '@salesforce/apex/MPSC_Service_FormData.getMetadata';
import REFERENCE_NAME_FIELD from '@salesforce/schema/Reference_MPSC_Service_Submission__c.Name';
import REFERENCE_At_Risk_Reason_Reason_for_Leaving__c from '@salesforce/schema/Reference_MPSC_Service_Submission__c.At_Risk_Reason_Reason_for_Leaving__c';
import REFERENCE_Is_the_Client_ASO__c from '@salesforce/schema/Reference_MPSC_Service_Submission__c.Is_the_Client_ASO__c';
import REFERENCE_CASE_Field from '@salesforce/schema/Reference_MPSC_Service_Submission__c.Case__c';
import REFERENCE_CREATEDBY from '@salesforce/schema/Reference_MPSC_Service_Submission__c.CreatedById';
import REFERENCE_Error_Responsibility_Client__c from '@salesforce/schema/Reference_MPSC_Service_Submission__c.Error_Responsibility_Client__c';
import REFERENCE_Error_Responsibility_Paychex__c from '@salesforce/schema/Reference_MPSC_Service_Submission__c.Error_Responsibility_Paychex__c';
import REFERENCE_Expected_Term_Date__c from '@salesforce/schema/Reference_MPSC_Service_Submission__c.Expected_Term_Date__c';
import REFERENCE_LastModifiedById from '@salesforce/schema/Reference_MPSC_Service_Submission__c.LastModifiedById';
import REFERENCE_OwnerId from '@salesforce/schema/Reference_MPSC_Service_Submission__c.OwnerId';
import REFERENCE_Prospect_Client_Name__c from '@salesforce/schema/Reference_MPSC_Service_Submission__c.Prospect_Client_Name__c';
import REFERENCE_Reason_for_Leaving_2__c from '@salesforce/schema/Reference_MPSC_Service_Submission__c.Reason_for_Leaving_2__c';
import REFERENCE_Submission_Details__c from '@salesforce/schema/Reference_MPSC_Service_Submission__c.Submission_Details__c';
import REFERENCE_Training_Type__c from '@salesforce/schema/Reference_MPSC_Service_Submission__c.Training_Type__c';


const FIELDS = ['Case.Status', 'Case.Type', 'Case.Sub_Type__c'];


export default class mPSC_Service_Submission_Form extends LightningElement {
    FINAL_REFERENCE_MPSC_SERVICE_SUBMISSION_FIELDS =[];
    LossFields = [REFERENCE_NAME_FIELD,REFERENCE_Is_the_Client_ASO__c,REFERENCE_At_Risk_Reason_Reason_for_Leaving__c,REFERENCE_Reason_for_Leaving_2__c,REFERENCE_Expected_Term_Date__c,REFERENCE_CASE_Field,REFERENCE_Prospect_Client_Name__c,REFERENCE_Submission_Details__c];
    TaxPayAdjustmentFields = [REFERENCE_NAME_FIELD,REFERENCE_Error_Responsibility_Client__c,REFERENCE_Error_Responsibility_Paychex__c,REFERENCE_CASE_Field,REFERENCE_Prospect_Client_Name__c,REFERENCE_CREATEDBY,REFERENCE_LastModifiedById,REFERENCE_Submission_Details__c];
    RetentionSubmissionFields = [REFERENCE_NAME_FIELD,REFERENCE_CASE_Field,REFERENCE_Prospect_Client_Name__c,REFERENCE_CREATEDBY,REFERENCE_LastModifiedById,REFERENCE_Submission_Details__c];
    MpscClientTrainingnFields = [REFERENCE_NAME_FIELD,REFERENCE_Training_Type__c,REFERENCE_CASE_Field,REFERENCE_Prospect_Client_Name__c,REFERENCE_CREATEDBY,REFERENCE_LastModifiedById,REFERENCE_Submission_Details__c];
    @api recordId;
    @track showSpinner = false;
    @track showIframe = false;
    @track showDetailTemp=false;
    @track showDetail = false; // Initialize to false initially
    @track lastStatus;
    @track lastType;
    @track lastSubType;
    @track showSharepoint = false; //Sharepoint
    childREcordId;
    iFrameUrl;
    height = '600px';
   // referrerPolicy = 'no-referrer';
    width = '100%';
    //sandbox = 'allow-forms allow-pointer-lock  allow-scripts';
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        this.showIframe=false;
        this.showDetailTemp=false;  
        if (error) {
            console.error('Error occurred:', error);
            this.showSpinner = false; // Hide spinner if there's an error
            return;
        }
        if (data) {
            const status = getFieldValue(data, 'Case.Status');
            const type = getFieldValue(data, 'Case.Type');
            const subType = getFieldValue(data, 'Case.Sub_Type__c');
            console.log('data-->'+JSON.stringify(data));
            
            if (status !== this.lastStatus ||
                type !== this.lastType ||
                subType !== this.lastSubType) {
                this.lastStatus = status;
                this.lastType = type;
                this.lastSubType = subType;
                this.updateFinalReferenceFieldsByCaseType();
                this.updateComponent();
            }
        }
    }

    updateComponent() {
        this.showSpinner = true; // Show spinner when data fetching begins
        console.log(this.recordId);
        getMetadata({ recordID: this.recordId })
            .then(res => {
                console.log('res: '+ res);
                if (res && res.includes('https')) {
                    //Add functionality for Sharepoint
                    /*
                    if (this.lastStatus === 'New' && this.lastType === 'Taxpay Adjustments'){
                        this.showSharepoint = true;
                        this.iFrameUrl = res;
                        this.showIframe = false;
                        this.showDetail = false;
                    }
                    else{*/
                        this.iFrameUrl = res;
                        this.showIframe = true;
                        this.showDetail = false; // Hide detail component when showing iframe
                        this.showSharepoint = false;
                    //}
                } else if (res === null) {
                    this.showDetail = false;
                    this.showIframe = false;
                } else {
                    this.childREcordId = res;
                    this.showDetail = true;
                    this.showDetailTemp = true;
                    this.showSharepoint = false;
                }
            })
            .catch(error => {
                console.error('Error occurred:', JSON.stringify(error));
            })
            .finally(() => {
                this.showSpinner = false; // Hide spinner when data fetching is complete
            });
    }

    showNotification() {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Case Details Updated',
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }
    updateFinalReferenceFieldsByCaseType(){
        if(this.lastType=='Loss'){
            this.FINAL_REFERENCE_MPSC_SERVICE_SUBMISSION_FIELDS = this.LossFields;
        }
        else if(this.lastType=='Taxpay Adjustments'){
            this.FINAL_REFERENCE_MPSC_SERVICE_SUBMISSION_FIELDS = this.TaxPayAdjustmentFields; 
        }else if(this.lastType=='Retention' || this.lastType=='BCIS' || this.lastType=='Amended Returns'){
            //console.log('retention');
            this.FINAL_REFERENCE_MPSC_SERVICE_SUBMISSION_FIELDS = this.RetentionSubmissionFields; 
        }else if(this.lastType=='MPSC Client Training'){
            //console.log('MPSC Client Training	');
            this.FINAL_REFERENCE_MPSC_SERVICE_SUBMISSION_FIELDS = this.MpscClientTrainingnFields; 
        }else{
            this.FINAL_REFERENCE_MPSC_SERVICE_SUBMISSION_FIELDS = [REFERENCE_NAME_FIELD,REFERENCE_At_Risk_Reason_Reason_for_Leaving__c,REFERENCE_Is_the_Client_ASO__c,REFERENCE_Error_Responsibility_Client__c,REFERENCE_Error_Responsibility_Paychex__c,REFERENCE_Expected_Term_Date__c,REFERENCE_OwnerId,REFERENCE_Reason_for_Leaving_2__c,REFERENCE_Training_Type__c,REFERENCE_CASE_Field,REFERENCE_Prospect_Client_Name__c,REFERENCE_CREATEDBY,REFERENCE_LastModifiedById,REFERENCE_Submission_Details__c];
        }
    }
}