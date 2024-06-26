import { LightningElement, api, track, wire  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import relatedListResource from '@salesforce/resourceUrl/relatedListResource';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import Contact_OBJECT from "@salesforce/schema/Contact";

export default class RelatedListNewEditPopup extends LightningElement {
    showModal = false
    @api sobjectLabel
    @api sobjectApiName    
    @api recordId
    @api accountRecordPassId ; 
    @api recordName
    // @track isContact; 
    @track contactRecordTypeId; 
    @api objectApiName;
    @track objectInfo;
    @track conOptions = [];


    @api show() {
        this.showModal = true;
    }

    @api hide() {
        this.showModal = false;
    }
    handleClose() {
        this.showModal = false;     
    }
    handleDialogClose(){
        this.handleClose()
    }

    isNew(){
        
        return this.recordId == null
    }
    get header(){
        return this.isNew() ? `New ${this.sobjectLabel}` : `Edit ${this.recordName}`
    }

    handleSave(){
       if(this.isContact) {
        this.template.querySelector('lightning-record-edit-form').submit();
       }
       else{
        this.template.querySelector('lightning-record-form').submit();
       }           
    }    
    handleSuccess(event){
        this.hide()
        let name = this.recordName
        if(this.isNew()){
            if(event.detail.fields.Name){
                name = event.detail.fields.Name.value
            }else if(event.detail.fields.LastName){
                name = [event.detail.fields.FirstName.value, event.detail.fields.LastName.value].filter(Boolean).join(" ")
            }
        } 
        name = name ? `"${name}"` : ''
        
        const message = `${this.sobjectLabel} ${name} was ${(this.isNew() ? "created" : "saved")}.`
        const evt = new ShowToastEvent({
            title: message,
            variant: "success"
        });
        this.dispatchEvent(evt);
        this.dispatchEvent(new CustomEvent("refreshdata"));                  
    }    

    renderedCallback() {
        loadStyle(this, relatedListResource + '/relatedListNewEditPopup.css')
    }         
    connectedCallback(){
        // if(){
           
        // }
    }

    get isContact(){
        let rtn = false ; 
        if(this.sobjectLabel === 'Contact' && this.recordId == null){
            rtn = true; 
                    }
                    return rtn ; 
    }


  @wire(getObjectInfo, { objectApiName: Contact_OBJECT })
  conObjectInfo({data, error}) {
    if(data) {
        let optionsValues = [];
        // map of record type Info
        const rtInfos = data.recordTypeInfos;

        // getting map values
        let rtValues = Object.values(rtInfos);

        for(let i = 0; i < rtValues.length; i++) {
            if(rtValues[i].name !== 'Master') {
                optionsValues.push({
                    label: rtValues[i].name,
                    value: rtValues[i].recordTypeId
                })
            }
        }

        this.conOptions = optionsValues;
    }
    else if(error) {
        window.console.log('Error ===> '+JSON.stringify(error));
    }
}

  get recordTypeId() {
    // Returns a map of record type Ids
    const rtis = this.objectInfo.data.recordTypeInfos;
    return Object.keys(rtis).find((rti) => rtis[rti].name === "Special Account");
  }

  // Handling on change value
  handleChangeConRectyp(event) {
    this.contactRecordTypeId = event.detail.value;
    }
    handleSuccessContactForm(){
        console.log('savehit');
    }
    handleConSub(event){
        event.preventDefault();
        const fields = event.detail.fields;
        fields.recordTypeId = this.contactRecordTypeId;
        this.template.querySelector('lightning-record-edit-form').submit(fields);


    }
}