import { LightningElement, wire, api } from 'lwc';
import getAccountCPA from '@salesforce/apex/MutualClientRelationMethods.getAccountCPA';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import processMutualClientRelation from '@salesforce/apex/MutualClientRelationMethods.handleMutualClientVerification';
import removeCPAFromAccount from '@salesforce/apex/MutualClientRelationMethods.removeCPAFromAccount';
import { refreshApex } from '@salesforce/apex';
import uId from '@salesforce/user/Id';

export default class AccountReferralPartner extends LightningElement {
    @api recordId;
    accountData;
    verificationDate;
    referralType;
    accountDetails;
    cpaname;
    isLoading = false;
    userId = uId;
    
    @wire(getAccountCPA, {accountId : '$recordId'} )
    getAccountData(wireResult){
        const { data, error } = wireResult;
        this.accountDetails = wireResult;
        if (data) {
            console.log('dataaa', data);
            this.accountData = data;
            if(this.accountData.CPA_Name_Ref__r){
                this.cpaname = this.accountData.CPA_Name_Ref__r.Name;
                this.referralType = this.accountData.CPA_Name_Ref__r.PrimaryReferralType__c;
            }
            if(this.accountData.MutualClientRelations__r && this.accountData.MutualClientRelations__r.length > 0){
                this.verificationDate = this.accountData.MutualClientRelations__r[0].ReferralSourceVerificationDate__c;
            }
           
            
        } else if (error) {
           console.log('errprrr',JSON.stringify(error));
        }
    }
    handleRemoveCPA(){
        console.log(this.userId);
        console.log(this.accountData.OwnerId);
        //console.log(this.userId != this.accountData.OwnerId);
        if(this.userId !== this.accountData.OwnerId){
             this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'You don\'t have the necessary privileges to edit this record.',
                            variant: 'error',
                        })
                    );
                    return;
        }
        this.isLoading = true;
        removeCPAFromAccount({accountId : this.recordId})
        .then(response=>{
            this.isLoading = false;
            console.log(response);
            refreshApex(this.accountDetails);
            this.dispatchEvent(new CustomEvent('verification', {
                detail: {
                    data: 'SUCCESS'
                }
            }));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'CPA Removed Successfully !!',
                    variant: 'success',
                })
            );

            this.handleVerificationCancel();
        })

        .catch(error=>{
            this.isLoading = false;
            console.log(JSON.stringify(error));
        })
    }

    verifyCPA(){
      console.log(this.userId);
        console.log(this.accountData.OwnerId);
        // console.log(this.userId this.accountData.OwnerId);
        if(this.userId !== this.accountData.OwnerId){
             this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'You don\'t have the necessary privileges to edit this record.',
                            variant: 'error',
                        })
                    );
                    return;
        }
        this.isLoading = true;
        processMutualClientRelation({accountId : this.recordId})
                .then(() => {
                    refreshApex(this.accountDetails);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Verified Successfully !!',
                            variant: 'success',
                        })
                    );
                     this.isLoading = false;
                })
                .catch(error => {
                     this.isLoading = false;
                    console.log('error verifying ==>', error);
                })
    }

    
}