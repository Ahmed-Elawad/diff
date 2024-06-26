import { LightningElement,api,wire } from 'lwc';
import TIMEZONE from '@salesforce/i18n/timezone';
import getActivitiesForReferralContact from '@salesforce/apex/CadenceTouchpointExtension.getActivitiesForReferralContact';
const columns = [
    { label: 'Subject', fieldName:'Link' , type:'url',typeAttributes: { label: { fieldName: 'Subject' }, target: '_self'}},
    { label: 'Activity Date', fieldName: 'ActivityDate', type: 'date', typeAttributes:{
        year:"2-digit",
        month:"short",
        day:"2-digit",
        timeZone: 'UTC',
        timeZoneName: 'short'
    }},
    { label: 'Time', fieldName: 'ActivityTime', type: "date",
    typeAttributes:{
        hour: "2-digit",
        minute: "2-digit",
        timeZone: TIMEZONE,
        timeZoneName: 'short'
    } },
    { label: 'Related To', fieldName: 'ContactName', },
    { label: 'Activity Type', fieldName: 'ActivityType' },
    { label: 'Owner', fieldName: 'OwnerName' },
    { label: 'Status', fieldName: 'Status' }
];
export default class ActivitiesForReferralAccountsLRP extends LightningElement {
    @api recordId;
    listOfActivities;
    get styleAttr() {
        return `width: 100%`;
    }
    @wire(getActivitiesForReferralContact,{refActId :'$recordId'})
    getActivities({data,error}){
        if(data){
            console.log("We've received data for this page");
            //console.log(data);
            this.listOfActivities = data;
            let tempData = data;
            // if need for it modify data here 
            tempData = tempData.map((rec)=>{
                rec = JSON.parse(JSON.stringify(rec));
                console.log(rec);
                rec.Link = '/'+rec.Id;
                return rec;
            });
            this.listOfActivities = tempData;
            console.log('this is tempdata: '+JSON.stringify(tempData[0]));
        }
        else if(error){
            this.listOfActivities=[];
            console.log(error);
        }
    }
    columns = columns;
}