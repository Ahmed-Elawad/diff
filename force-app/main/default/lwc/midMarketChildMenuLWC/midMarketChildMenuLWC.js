import { LightningElement,api } from 'lwc';
export default class MidMarketChildMenuLWC extends LightningElement {
    @api tile;
    connectedCallback() {
        console.log('child data tile->'+JSON.stringify(this.tile));
    }
    handleCardClick() {
        const selectEvent = new CustomEvent('selectedtile', {
            detail: this.tile
        });
        this.dispatchEvent(selectEvent);
    }
}