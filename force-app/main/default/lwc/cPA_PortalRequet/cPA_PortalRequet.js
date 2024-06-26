import { LightningElement } from 'lwc';
import insertCPAPortalRequest from '@salesforce/apex/CPA_PortalRequetController.insertCPAPortalRequest';
import cpaTitle from '@salesforce/label/c.CPAPortalRequestTitle';
import cpaSubTitle from '@salesforce/label/c.CPAPortalRequestSubTitle';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CPA_PortalRequet extends LightningElement {
    firstName;
    lastName;
    emailAddress;
    firmName;
    zipCode;
    phoneNumber;
    clientNumber;
    disableBtn = true;
    title = cpaTitle;
    subTitle = cpaSubTitle;

    handleInputFirstName(event) {
        this.firstName = event.detail.value;
        this.validateInputs();
    }

    handleInputLastName(event) {
        this.lastName = event.detail.value;
        this.validateInputs();
    }

    handleInputEmailAddress(event) {
        this.emailAddress = event.detail.value;
        this.validateInputs();
    }

    handleInputFirmName(event) {
        this.firmName = event.detail.value;
        this.validateInputs();
    }

    handleInputZipCode(event) {
        this.zipCode = event.detail.value;
        this.validateInputs();
    }

    handleInputPhoneNumber(event) {
        this.phoneNumber = event.detail.value;
        this.validateInputs();
    }

    handleInputClientNumber(event) {
        this.clientNumber = event.detail.value;
        this.validateInputs();
    }

    insertCPARequest(event) {
        var jsonString = '{ "First_Name__c":"'+this.firstName+'", "Last_Name__c":"'+this.lastName+'", "Email__c":"'+this.emailAddress+'", "Firm_Name__c":"'+this.firmName+'", "Firm_Zip_Code__c":"'+this.zipCode+'", "Phone_Number__c":"'+this.phoneNumber+'", "Name":"'+this.lastName+'"}';
        console.log('jsonString='+jsonString);
        insertCPAPortalRequest({inputJson: jsonString})
            .then((data) =>{
                console.log("recordId="+JSON.stringify(data));
                this.showToast('Success','Information has been saved successfully','success');
                this.clearAllValues();
            })
            .catch((error)=>{
                console.log("Error="+JSON.stringify(error));
                this.showToast('Error','Something went wrong. PLease try after sometime or contact to Admin.','error');
            });
    }

    /**
     * Show toast Message
     */
     showToast(_title,_message,_variant){
        const event = new ShowToastEvent({
            title: _title,
            message: _message,
            variant: _variant
        });
        this.dispatchEvent(event);
    }

    validateInputs() {
        this.disableBtn = [this.firstName, this.lastName, this.emailAddress, this.firmName, this.zipCode, this.phoneNumber].some(value => !value)
    }

    clearAllValues() {
        this.firstName = "";
        this.lastName = "";
        this.emailAddress = "";
        this.firmName = "";
        this.zipCode = "";
        this.phoneNumber = "";
        this.clientNumber = "";
        this.disableBtn = true;
    }
}