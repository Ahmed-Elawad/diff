import { LightningElement, api, wire,track} from 'lwc';
import getMutualClientsForTouchPointwithAcctIdandRefBusiType from '@salesforce/apex/CadenceTouchpointExtension.getMutualClientsForTouchPointwithAcctIdandRefBusiType';

const columns = [
    { label: 'Name', fieldName: 'Link', type:'url', typeAttributes: { label: { fieldName: 'Name' , sortable : true} } },
    { label: 'Contact', fieldName: 'SignificantContactName' , sortable : true},
    { label: 'EEs', fieldName: 'NumberOfEmployees', sortable : true },
    { label: 'Type', fieldName: 'Type' , sortable : true},
    { label: 'Owner', fieldName: 'OwnerName', sortable : true },
    { label: 'Run Date', fieldName: 'First_Run_Date__c', type: 'date',typeAttributes: {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit"
    } , sortable : true},
    { label: 'State', fieldName: 'State' , sortable : true },
    { label: 'Zip', fieldName: 'Zip' , sortable : true },
    { label: 'Paychex 401K Assets', fieldName: 'Paychex_401K_Assets__c' , type: 'currency', sortable : true },
    { label: 'Aggregate 401K Assets', fieldName: 'X401K_Assets__c', type: 'currency', sortable : true },
];
export default class CadenceTouchpointMutualClients extends LightningElement {
    @api dtdata;
    @api refactid; 
    @api refferalSourceBussType; 
    @track sortBy ='Type';
    @track sortDirection;
    mutuals;
    mutualsPopulated = false;
    @track sumPayChecx = 0;
    @track sumAggregate = 0;
    account = 'a0603000000OXZnAAO';
    @wire(getMutualClientsForTouchPointwithAcctIdandRefBusiType, {refActId :'$refactid', refferalSourceBussType : '$refferalSourceBussType'})
    getMutuals({data,error}){
        console.log("Wire alert, wee woo wee woo!", this.refactid)
        
        if(data){
            for( let paychex=0; paychex<data.length; paychex++){
                if(data[paychex].Paychex_401K_Assets__c!=null){
                    console.log('payx: '+data[paychex].Paychex_401K_Assets__c);

                    this.sumPayChecx += data[paychex].Paychex_401K_Assets__c;
                }
                if(data[paychex].X401K_Assets__c!=null){
                    console.log('aggregate: '+data[paychex].X401K_Assets__c);

                this.sumAggregate += data[paychex].X401K_Assets__c;
                }
            }
            console.log('Final payx: '+typeof(this.sumPayChecx));
            console.log('Final Aggregate: '+typeof(this.sumAggregate));
            // this.sumAggregate = this.sumAggregate;
            // this.sumPayChecx = Integer.valueOf(this.sumPayChecx);

            console.log("this api transfer worked!")
           console.log(data);
            this.mutuals = data;
            console.log(this.mutuals);
            // modification map
            this.mutuals = this.mutuals.map(mc=>{
                let mc2 = JSON.parse(JSON.stringify(mc));
                console.log(mc2);
                if(mc.SignificantContact__r != undefined||mc.SignificantContact__r != null ){
                 mc2.SignificantContactName = mc.SignificantContact__r.Name;
                }
                if(mc.Owner.LastName!=undefined|| mc.Owner.LastName!=null){
                 mc2.OwnerName = mc.Owner.LastName;
                }
                if(mc.ShippingAddress!= undefined || mc.ShippingAddress!=null){
                    mc2.Zip = mc.ShippingAddress.postalCode;
                    mc2.State = mc.ShippingAddress.state;
                }
                mc2.Link = '/'+mc2.Id;
                // this.sumPayChecx += mc.Paychex_401K_Assets__c;
                // this.sumAggregate += mc.X401K_Assets__c;

                 return mc2;
             });
             this.sortData('Type','asc');
            this.mutualsPopulated = true;
            console.log(this.mutuals);
            console.log("we got some More data this is the mutuals list!^^^")
            console.log("we got some More data this is the mutuals list!^^^", this.sumPayChecx )
            console.log("we got some More data this is the mutuals list!^^^",  this.sumAggregate)
        }
        else if(error){
            console.log("Houston we've got a problem: "+error);
            alert(JSON.stringify(error));
        }
    };
    
    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.mutuals));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.mutuals = parseData;
    }    

    columns = columns;
}