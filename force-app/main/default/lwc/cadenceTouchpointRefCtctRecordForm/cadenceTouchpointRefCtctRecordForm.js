import { LightningElement, api, wire} from 'lwc';
import getReferralContactswithAcctId from '@salesforce/apex/CadenceTouchpointExtension.getReferralContactswithAcctId';
import getTPRefctcts from '@salesforce/apex/CadenceTouchpointExtension.getTPRefctcts';

import updateRefctcts from '@salesforce/apex/CadenceTouchpointExtension.updateRefctcts';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import NAME_FIELD from '@salesforce/schema/Referral_Contact__c.Name';
import ID_FIELD from '@salesforce/schema/Referral_Contact__c.Id';
import EMAIL_FIELD from '@salesforce/schema/Referral_Contact__c.Email__c';
import PHONE_FIELD from '@salesforce/schema/Referral_Contact__c.Phone__c';
import TITLE_FIELD from '@salesforce/schema/Referral_Contact__c.Title__c';
import PAYXID_FIELD from '@salesforce/schema/Referral_Contact__c.PAYX_ID__c';
import LAST_ACTIVITY_FIELD from '@salesforce/schema/Referral_Contact__c.Last_Activity_Date__c';
import BIRTHDAY_FIELD from '@salesforce/schema/Referral_Contact__c.Birthday__c';
import SCORE_FIELD from '@salesforce/schema/Referral_Contact__c.ScoreTotalReferrals__c';
//import OPP_FIELD from '@salesforce/schema/Referral_Contact__c.Opportunities_to_Refer_Last_12_Months__c';
import LINKEDIN_FIELD from '@salesforce/schema/Referral_Contact__c.LinkedIn_Profile__c';
import AICPA_FIELD from '@salesforce/schema/Referral_Contact__c.AICPA__c';
const columns = [
    { label: 'Name', fieldName:'Link' , type:'url',typeAttributes: { label: { fieldName: 'Name' }, target: '_self'}  },
    { label: 'Email', fieldName: 'Email__c', editable: true},
    { label: 'Phone', fieldName: 'Phone__c', type: 'clickToDialCustom', typeAttributes: {
        phoneValue: { fieldName: 'Phone__c' }}, editable: true},
    { label: 'Mobile', fieldName: 'Mobile_Phone__c', type: 'clickToDialCustom', typeAttributes: {
        phoneValue: { fieldName: 'Mobile_Phone__c' }}, editable: true},
    { label: 'Title', fieldName: 'Title__c', editable: true},
    { label: 'AICPA ID', fieldName: 'AICPA__c', editable: true},
    { label: 'Last Activity', fieldName: 'Last_Activity_Date', type:'date', 
        typeAttributes:{
            month: "2-digit",
            day: "2-digit", 
            year:"2-digit",
        }
    },

    { label: 'Score', fieldName: 'ScoreTotalReferrals'},
    { label: 'Referral Past Year', fieldName: 'Referrals_In_Last_Year' }
    ];

const columns1 = [
        { label: 'Name', fieldName:'Link' , type:'url',typeAttributes: { label: { fieldName: 'Name' }, target: '_self'}  },
        { label: 'Email', fieldName: 'Email__c', editable: true},
        { label: 'Phone', fieldName: 'Phone__c', type: 'phone', editable: true},
        { label: 'Mobile', fieldName: 'Mobile_Phone__c', type: 'phone', editable: true},
        { label: 'Title', fieldName: 'Title__c', editable: true},
        { label: 'AICPA ID', fieldName: 'AICPA__c', editable: true},
        { label: 'Last Activity', fieldName: 'Last_Activity_Date', type:'date', 
            typeAttributes:{
                month: "2-digit",
                day: "2-digit", 
                year:"2-digit",
            }
        },
    
        { label: 'Score', fieldName: 'ScoreTotalReferrals'},
        { label: 'Referral Past Year', fieldName: 'Referrals_In_Last_Year' }
        ];
export default class CadenceTouchpointRefCtctRecordForm extends LightningElement {
@api refacct;
@api refisTelemarketing;
refctcts;
wiredRefctcts;
//columns = columns;
// fields =[NAME_FIELD,EMAIL_FIELD,PHONE_FIELD,TITLE_FIELD,PAYXID_FIELD,LAST_ACTIVITY_FIELD,BIRTHDAY_FIELD,SCORE_FIELD,OPP_FIELD,LINKEDIN_FIELD,AICPA_FIELD];
fields =[NAME_FIELD,EMAIL_FIELD,PHONE_FIELD,TITLE_FIELD,PAYXID_FIELD,LAST_ACTIVITY_FIELD,BIRTHDAY_FIELD,SCORE_FIELD,LINKEDIN_FIELD,AICPA_FIELD];
draftValues  = [];
finalcolumns = columns1;

@wire(getTPRefctcts,{refActId :'$refacct'})
getRefCtct(value){
this.wiredRefctcts = value;
    const {data,error} = value;
    if(data){
        console.log('data that came in:'+data);
        let tempRefctcts = JSON.parse(JSON.stringify(data));
        tempRefctcts = tempRefctcts.map((rec)=>{
            console.log(rec.Id);
            rec.Link = "/"+rec.Id;
            rec.Email__c = rec.Email;
            rec.Phone__c = rec.Phone;
            rec.Mobile_Phone__c = rec.Mobile_Phone;
            rec.Title__c = rec.Title;
            rec.AICPA__c = rec.AICPA;

            return rec;
        });
        //console.log("Temp Referral contacts: "+JSON.stringify(tempRefctcts));

        this.refctcts = tempRefctcts;
        this.theId = data.Id;
        console.log('REFCONTACTS RECEIVED');
        console.log("modified data[0]: "+JSON.stringify(tempRefctcts[0]));
        if(this.refisTelemarketing){
            this.finalcolumns = columns;
        }
    }
    if(error){
        console.log('It dont like the data sent in');
        console.log(error);
    }
}

async handleSave( event ) {
    console.log("THE DRAFT VALUES: "+JSON.stringify(event.detail.draftValues));
    const fields = {}; 
    
        fields[ID_FIELD.fieldApiName] = event.detail.draftValues[0].Id;
        // fields[FIRSTNAME_FIELD.fieldApiName] = event.detail.draftValues[0].FirstName;
        // fields[LASTNAME_FIELD.fieldApiName] = event.detail.draftValues[0].LastName;
        //console.log("ID FIELD: "+fields[ID_FIELD.fieldApiName]);
        let test1 = this.refctcts;
        let test2 = event.detail.draftValues;
        let test3 = [];
        console.log(test2);

        test2.forEach((rec)=>{
            console.log("current record ID: "+rec.id);
            var rowId = rec.id.split('-');
            var indexInQuestion = rowId[1];
            console.log('row-'+indexInQuestion);
            if(rec.id == 'row-'+indexInQuestion){
                console.log('index: '+indexInQuestion);
                console.log("original record"+JSON.stringify(test1[indexInQuestion]));
                console.log(test1[indexInQuestion].Id);
                rec.id = test1[indexInQuestion].Id;
                test3.push(rec);
                console.log(rec);
            }else{
                console.log("row-index did not work");
            }
        });
        console.log("test 3 :"+JSON.stringify(test3));
        const updatedFields = test3;

    await updateRefctcts( { data: updatedFields } )
    .then( result => {

        console.log( JSON.stringify( "Apex update result: " + result ) );
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Referral Contact(s) updated',
                variant: 'success'
            })
        );
        
        refreshApex( this.wiredRefctcts ).then( () => {
            this.draftValues = [];
        });        

    });

    

}

}