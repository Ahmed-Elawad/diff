import { LightningElement, api,wire } from 'lwc';
import getTilesData from "@salesforce/apex/MidMarketMenuLwcController.getMenuMetaData";
import {
    FlowAttributeChangeEvent,
    FlowNavigationNextEvent,
} from 'lightning/flowSupport';
export default class MidMarketParentMenuLWC extends LightningElement {
    tilesDataSuper=[];
    tilesData = [];
    @wire(getTilesData) 
    wiredTilesDataSuper({error,data}){
        if(data){
            console.log('-->'+JSON.stringify(data));
            this.tilesDataSuper = data;
            this.tilesData = [...this.tilesDataSuper];
        }
    }
    @api outputType;
    @api outputSubType;
    @api outputFlowUrl;
    @api
    availableActions = [];
    
    connectedCallback() {

    }

    handleSearchTermChange(event){
        this.tilesData = [...this.tilesDataSuper];
        const searchTerm = event.target.value;
        console.log('searchTerm3: ' + searchTerm);
        const result = this.tilesData.filter((tileS) => tileS.Title__c.toLowerCase().startsWith( searchTerm.toLowerCase()));
        console.log('result: ' + result);
        this.tilesData = [...result];
        this.template.querySelector('lightning-tabset').activeTabValue ="all";
    }

    handleBearView(event) {
		// Get bear record id from bearview event
		const titleId = event.detail.Title__c;
        console.log('titleId1: ' + titleId);
        this.outputType = event.detail.Type__c;
        this.outputSubType = event.detail.Subtype__c;
        this.outputFlowUrl = event.detail.URL__c;
        this.dispatchEvent(new FlowAttributeChangeEvent('outputType',this.outputType));
        this.dispatchEvent(new FlowAttributeChangeEvent('outputSubType',this.outputSubType));
        this.dispatchEvent(new FlowAttributeChangeEvent('outputFlowUrl',this.outputFlowUrl));
		
        // check if NEXT is allowed on this screen
        if (this.availableActions.find((action) => action === 'NEXT')) {
            // navigate to the next screen
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
        
	}

}