import { LightningElement, api, wire, track } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import ACCOUNT_RECORDTYPE_FIELD from "@salesforce/schema/Account.RecordTypeId";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';


export default class BuisinessProfileEditForm extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api isloaded = false ; 
  @api qualifiedMSG = false ; 
  @api childLoad =false; 
  @api dummyRecidrecordId; 
  connectedCallback(){
    this.dummyRecid = this.recordId; 
    this.childLoad = false ; 
  }

  @api contactColumns = [
    { label: 'CONTACT NAME', fieldName: 'LinkName', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_top' } },
    { label: 'Email', fieldName: 'Email', type: 'email' },
    { label: 'Phone', fieldName: 'Phone', type: "phone" },
    { label: 'Qualified', fieldName: 'Profiled__c', type: "checkbox" } 
  ]

  @api businessProfileColumns = [
    { label: 'Business Profile Name', fieldName: 'LinkName', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_top' } },
    { label: 'Key Influencer', fieldName: 'Key_Influencer__r_LinkName',  type: 'url', typeAttributes: { label: { fieldName: 'Key_Influencer__r_Name' }, target: '_top' } },
    { label: 'Decision Maker', fieldName: 'Decision_Maker__r_LinkName',  type: 'url', typeAttributes: { label: { fieldName: 'Decision_Maker__r_Name' }, target: '_top' } },
    { label: 'Products Currently Utilizing', fieldName: 'Products_Currently_Utilizing1__c' },
    { label: 'Vendor Name', fieldName: 'Vendor_Name__c' }
  ]

  // @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_RECORDTYPE_FIELD] })
  // acc;
  @api handleSubmit(event) {
    this.isloaded = true ;
    this.childLoad = true ;  
    console.log('onsubmit event recordEditForm'+ event.detail.fields);
}
@api handleSuccess(event){
     this.isloaded = false  ; 
     this.dummyRecid = 'this.recordId'; 
    this.childLoad =true; 
    this.dispatchEvent(new CloseActionScreenEvent());   
  const event2 = new ShowToastEvent({
    title: 'Record Updated',
    message: 'Details updated sucessfully',
    variant: 'success',
    mode: 'dismissable'
});
this.dispatchEvent(event2);
}

@api troughQualified(event){
  console.log('evt',event.target.value);
  if (event.target.value === true ) {
    this.qualifiedMSG = true; 
}else{
  this.qualifiedMSG = false ; 
}
}

navigateToNewContactWithDefaults() {
  const defaultValues = encodeDefaultFieldValues({
      FirstName: 'Morag',
      LastName: 'de Fault',
      LeadSource: 'Other'
  });

  console.log(defaultValues);
  this[NavigationMixin.Navigate]({
      type: 'standard__objectPage',
      attributes: {
          objectApiName: 'Account',
          actionName: 'new'
      }
  });
}
}