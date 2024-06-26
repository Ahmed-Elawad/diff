import ReferralAccount from "@salesforce/schema/Referral_Contact__c.Referral_Account__c";
import ReferralAccountMangedChanel from "@salesforce/schema/Referral_Contact__c.Referral_Account__r.Managed_by_Channel__c";
import { LightningElement, api, wire, track } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";

export default class EnrollForAICPAProgram extends LightningElement {
  @api recordId;
  @track isLoad = false;
  todaydate;
  @track v;

  get todaydateVal() {
    if (this.todaydate === undefined) {
      this.todaydate = new Date().toISOString().substring(0, 10);
    }
    return this.todaydate;
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [ReferralAccount, ReferralAccountMangedChanel]
  })
  RCData;

  get RefAccountId() {
    return this.RCData.data
      ? this.RCData.data.fields.Referral_Account__c.value
      : null;
  }

  get RefAccountManagedByChannel() {
    console.log('vr', this.RCData.data);
    //return true; 
    return getFieldValue(this.RCData.data, ReferralAccountMangedChanel);
  }

  connectedCallback() {}
  singleOnSubmitMethod() {
    
     const isInputsCorrect = [...this.template.querySelectorAll('lightning-input-field')]
    .reduce((validSoFar, input_Field_Reference) => {
      input_Field_Reference.reportValidity();
        return validSoFar && input_Field_Reference.reportValidity();
    }, true);
    if(isInputsCorrect ){
    let varAicpMemb = this.template.querySelector(
      'lightning-input-field[data-id="idAICPMN"]'
    ).value;
    let varStateCpa = this.template.querySelector(
      'lightning-input-field[data-id="idStatCPALN"]'
    ).value;

    if (!varAicpMemb && !varStateCpa) {
      const evt = new ShowToastEvent({
        title: "Required fileds missing",
        message: "Please Fill AICPA Member Number Or State CPA License Number",
        variant: "error",
        mode: "dismissible"
      });
      this.dispatchEvent(evt);
    } else {
      let f1frm = this.template.querySelector(
        'lightning-record-edit-form[data-id="f1"]'
      );
      console.log("vr1", JSON.stringify(f1frm));
      f1frm.submit();
      this.isLoad = true;
    }
  }
  }

  async onF1Success() {
    this.isLoad = true;
    let f2 = this.template.querySelector(
      'lightning-record-edit-form[data-id="f2"]'
    );
    f2.submit();
  }
  refreshPage() {
    console.log("vr 3", this.v);
    const evt = new ShowToastEvent({
      title: " Enrolled in CPA.co/Paychex Program",
      message:
        "Thank you. The CPA has been enrolled in the CPA.com/Paychex Parnter Program",
      variant: "success",
      mode: "dismissable"
    });
    this.dispatchEvent(evt);
    window.location.reload();
  }
  closeAction() {
    // this.isLoad =false;
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  validateFields() {
    this.template.querySelectorAll('lightning-input-field').forEach(element => {
        element.reportValidity();
    });
}
}