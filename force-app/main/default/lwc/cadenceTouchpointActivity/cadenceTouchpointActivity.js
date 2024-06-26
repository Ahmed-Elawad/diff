import { LightningElement,api,wire } from 'lwc';
import getActivitiesForReferralContact from '@salesforce/apex/CadenceTouchpointExtension.getActivitiesForReferralContact';
import getLatestActivity from '@salesforce/apex/ActivityHelper.getLatestActivity';
const columns = [
    {label:'Contact',fieldname:'ContactName'},
    {label:'Subject',fieldname:'Subject'},
    {label:'Activity Date',fieldname:'ActivityDate', type: 'text'},
    {label:'Owner',fieldname:'OwnerName'},
    {label:'Activity Type',fieldname:'ActivityType'},
];
const columns2 = [
    { label: 'Subject', fieldName: 'subject', type: 'text'},
    { label: 'Activity Date', fieldName: 'activityDate', type: 'date-local', typeAttributes: {
            year: '2-digit',
            month: 'numeric',
            day: 'numeric'}},
    { label: 'Contact Name', fieldName: 'contactName', type: 'text'},
    { label: 'Activity Type', fieldName: 'activityType', type: 'text'},
    { label: 'Owner Name', fieldName: 'ownerName', type: 'text'}
  ];
export default class CadenceTouchpointActivity extends LightningElement {
    @api refacct;
    //@api touchpoint;
    activitiesList;
    activitiesList2;
    //activitiesListBuilt;
    temp = false;

    @wire(getLatestActivity, {recId :'$touchpoint'})
    getActivitiesII({data,error}){
        if(data){
            console.log("Jermaines Code return: "+data);
            this.activitiesList2= data;
        }
        console.log("Jermaines Code return: "+data);
        if(error){
            console.log(error);
        }
    };
    
    @wire(getActivitiesForReferralContact, {refActId :'$refacct'})
    async getActivities({data,error}){
        if(data){
            var d2 = [...data];
            console.log("the Callback worked");
            console.log(data);
             d2 =  d2.map( ( rec)=>{
                rec = JSON.parse(JSON.stringify(rec));
                console.log(rec.ActivityDate);
                rec.ActivityDate = new Date(rec.ActivityDate);
                rec.Link = '/'+ rec.Id;
                return rec;

            });
            d2 = d2.sort((firstItem, secondItem) =>secondItem.ActivityDate - firstItem.ActivityDate);

            this.activitiesList = d2;
            console.log(this.activitiesList);
            
        }
        if(error){
            console.log(error);
        }else{
            console.log('unknown error');
        }

    }
    
    columns = columns;
}