import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class MidMarket_redirectToRecordPage extends NavigationMixin(LightningElement) {
    @api recordId;
    connectedCallback() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }
}