import { LightningElement, api, track, wire} from 'lwc';
import updateRecord from '@salesforce/apex/UnsubscribeEmailController.updateRecord';
import myPaychex_icon from '@salesforce/resourceUrl/PayxWebLogo';
import myHeader_icon from '@salesforce/resourceUrl/TierIIImage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class UnsubscribeFromEmails extends LightningElement {  
  
    @api emailEntered;
    @track resultRecords;
    paychexLogo = myPaychex_icon;
    headerPng = myHeader_icon;
    chkEmailAddress(event){
        const userInput = event.target.value;
        this.emailEntered= userInput;
        console.log("Puitha Code return data", this.emailEntered);
    }
    
    unsubscribe(event) { 
        var flag = true;
        const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        let email = this.template.querySelector('[data-id="txtEmailAddress"]');
        let emailVal = email.value;
        if (emailVal.match(emailRegex)) {
            email.setCustomValidity("");
            console.log('button invoked'+this.emailEntered);
            const toastModel = this.template.querySelector('[data-id="toastModel"]');
            toastModel.className = 'slds-show';
            //this.template.querySelector('[data-id="txtEmailAddress"]').value = null;     
            updateRecord({emailString: this.emailEntered})               
        }
        else {
            flag = false;
            email.setCustomValidity("Please enter valid email");
        }
        email.reportValidity();

        
        return flag;   
    }  
    closeModel() {
        const toastModel = this.template.querySelector('[data-id="toastModel"]');
        toastModel.className = 'slds-hide';
    }

    get mainDivClass() { 
        return 'slds-notify slds-notify_toast slds-theme_success';
      }

    get messageDivClass() { 
        return 'slds-icon_container slds-icon-utility-success slds-m-right_small slds-no-flex slds-align-top';
    }
    get iconName() {
        return 'utility:success';
    }
    get closeDivClass(){
        return 'slds-button slds-button_icon slds-button_icon-inverse';
    }
    get closeIconName() {
        return 'utility:close';
    }
    
}