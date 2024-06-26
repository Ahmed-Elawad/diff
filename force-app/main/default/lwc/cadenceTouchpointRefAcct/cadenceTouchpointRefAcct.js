import { LightningElement,api,wire } from 'lwc';
// import a method to grab all of these things(try to limit it to an object that has it all vs multiple queries)
import NAME_FIELD from '@salesforce/schema/Referral_Account__c.Name';
import BUSINESS_FIELD from '@salesforce/schema/Referral_Account__c.Referral_Source_Business_Type__c';
import REFERRAL_TYPE_FIELD from '@salesforce/schema/Referral_Account__c.Referral_Type__c';
import LAST_REFERRAL_FIELD from '@salesforce/schema/Referral_Account__c.LatestReferralDate__c';
import CPA_ROTATION_FIELD from '@salesforce/schema/Referral_Account__c.Group__c';
import NUM_OF_MUTUAL_CLIENTS_FIELD from '@salesforce/schema/Referral_Account__c.Number_of_Mutual_Clients__c';
import PARENT_REFERRAL_ACCOUNT_FIELD from '@salesforce/schema/Referral_Account__c.Parent_Referral_Account__c';
import STREET_FIELD from '@salesforce/schema/Referral_Account__c.Street_Address_1__c';
import CITY_FIELD from '@salesforce/schema/Referral_Account__c.City__c';
import STATE_FIELD from '@salesforce/schema/Referral_Account__c.State_Province__c';
import ZIP_FIELD from '@salesforce/schema/Referral_Account__c.Zip_Postal_Code__c';
import WEBSITE_FIELD from '@salesforce/schema/Referral_Account__c.Website__c';
import ARM_OWNER_FIELD from '@salesforce/schema/Referral_Account__c.ARM_Owner__c';
import getLastMeetingDate from '@salesforce/apex/CadenceTouchpointExtension.getLastMeetingDate';
import getnumOfOpenOpps from '@salesforce/apex/CadenceTouchpointExtension.getnumOfOpenOpps';
import getCurrentMutualAndProspectClientCount from '@salesforce/apex/CadenceTouchpointExtension.getCurrentMutualAndProspectClientCount';
import getReferralsInPastMonths from '@salesforce/apex/CadenceTouchpointExtension.getReferralsInPastMonths';
import getCurrentMutualCount from '@salesforce/apex/CadenceTouchpointExtension.getCurrentMutualCount';
export default class CadenceTouchpointRefAcct extends LightningElement {
@api refacct;
fields =[NAME_FIELD,BUSINESS_FIELD,REFERRAL_TYPE_FIELD,LAST_REFERRAL_FIELD,CPA_ROTATION_FIELD,NUM_OF_MUTUAL_CLIENTS_FIELD,PARENT_REFERRAL_ACCOUNT_FIELD,STREET_FIELD,CITY_FIELD,STATE_FIELD,ZIP_FIELD,WEBSITE_FIELD,ARM_OWNER_FIELD];

oppNum;
lastMeetingDate;
totalRefsInPastYear;
totalMutualAndProspectClients;
mutualCurrentClients;
@wire(getReferralsInPastMonths,{refActId:'$refacct', pastMonths:12})
getRefs({data,error}){
    // console.log(typeof(12));
    // console.log("data showing up for referrals: "+data);
    // console.log("is there an error:"+error);
    if(data){
        console.log('We made it into the Referrals callback');
        console.log(data);
        this.totalRefsInPastYear = data;
    }else{
        this.totalRefsInPastYear = 0;
    }
    if(error){
        console.log('Referral In Past Year error');
        console.log(error);
    }
}

@wire(getCurrentMutualAndProspectClientCount,{refActId:'$refacct'})
getMutualANdProspectClientsCount({data,error}){
    console.log("mutual and prospect clients data: "+data);
    console.log("mutual and prospect clients error: "+error);
    if(data){
        console.log('We made it into the Mutual and Prospect callback');
        console.log(data);
        this.totalMutualAndProspectClients = data;
    }else{
        this.totalMutualAndProspectClients = 0;
    }
    if(error){
        console.log('Total Mutual and Prospect CLients error');
        console.log(error);
    }
}
@wire(getCurrentMutualCount,{refActId:'$refacct'})
getClientsCount({data,error}){
    if(data){
        console.log('We made it into the Mutual clients callback');
        console.log(data);
        this.mutualCurrentClients = data;
    }else{
        this.mutualCurrentClients = 0;
    }
    if(error){
        console.log('Total Mutual CLients error');
        console.log(error);
    }
}
@wire(getnumOfOpenOpps,{refActId:'$refacct'})
getOppsCount({data,error}){
    if(data){
        console.log('We made it into the NumOfOpenOpps callback');
        console.log(data);
        this.oppNum = data;
    }else{
        this.oppNum = 0;
    }
    if(error){
        console.log('Total Open Opportunites error');
        console.log(error);
    }
}
@wire(getLastMeetingDate,{refActId:'$refacct'})
getLastMeeting({data,error}){
    if(data){
        console.log('We made it into the GetLastMeeting callback');
        this.lastMeetingDate = data;
        console.log(data);

    }
    if(error){
        console.log('Last Meeting Date error');
        console.log(error);
    }
}

/* will need a wire to grab the: 
 Number of Open Opportunities,
 Last Meeting Date,
 Total Referrals Last 12 Months,
 Total Mutual /Prospect Clients
*/

}