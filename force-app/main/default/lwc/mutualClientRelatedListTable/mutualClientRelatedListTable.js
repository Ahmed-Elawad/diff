/**
 * History
 * -------------------------------------------------------------------
 * 04-05-2023    Vinay    Created.
 * 
 * --------------------------------------------------------------------
 *
 */
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import processMutualClientRelation from '@salesforce/apex/MutualClientRelationMethods.handleMutualClientVerification';
import getReferralAccountId from '@salesforce/apex/MutualClientRelationMethods.getReferralAccountId';
import updateProspectAccount from '@salesforce/apex/MutualClientRelationMethods.updateProspectAccount';
import removeCPAFromAccount from '@salesforce/apex/MutualClientRelationMethods.removeCPAFromAccount';
import getUserDetalsAndRefOwnereAndARM from '@salesforce/apex/MutualClientRelationMethods.getUserDetalsAndRefOwnereAndARM';

const columns = [
    {
        type:"button",
        fixedWidth: 100,
        typeAttributes: {
            label: 'Verify',
            name: 'verify',
            variant: 'brand'
        }
    },
    {
        type:"button",
        fixedWidth: 150,
        typeAttributes: {
            label: 'Update CPA',
            name: 'update cpa',
            variant: 'brand'
        }
    },

    {label: 'Prospect-Client Name', fieldName: 'url', type: 'url', sortable: true, typeAttributes: { label:{fieldName: 'Name'}, target: '_blank'} },
    {label: 'CPA Full Name', fieldName: 'cpaFullName', type: 'text', sortable: true
    //,
    //     typeAttributes: {
    //         object: 'Account',
    //         fieldName: 'CPA_Name_Ref__c',
    //         value: { fieldName: 'CPA_Name_Ref__c' },
    //         context: { fieldName: 'Id' },
    //         name: 'Referral_Contact__c',
    //         fields: ['Referral_Contact__c.Name'],
    //         target: '_self'
    //     },
    // editable: true
    },
    //{label: 'Fed Id Name', fieldName: 'Fed_ID_Name__c', type: 'text'},
    //{label: 'Bis ID', fieldName: 'Bis_ID__c', type: 'number'},
    //{label: 'Created Date', fieldName: 'CreatedDate', type: 'date'},
    {label: 'Prospect-Client Number', fieldName: 'AccountNumber', type: 'text' , sortable: true},
    {label: 'Verification Date', fieldName: 'verificationDate', type: 'date' , sortable: true},
    {label: 'Verification Type', fieldName: 'verificationType', type: 'text' , sortable: true},
    {label: 'Verified By', fieldName: 'verifiedBy', type: 'text' , sortable: true},
    {label: 'Type', fieldName: 'Type', type: 'text' , sortable: true },
    {label: 'Billing State/Province', fieldName: 'state', type: 'text' , sortable: true},
    //{label: 'Billing ZIP/Postal Code', fieldName: 'postalcode', type: 'text'},
    {label: 'Employees', fieldName: 'NumberOfEmployees', type: 'text' , sortable: true},
    {label: 'Owner Last Name', fieldName: 'lastname', type: 'text' , sortable: true},
    //{label: 'Paychex 401K Assets', fieldName: 'Paychex_401K_Assets__c', type: 'currency'},
    //{label: 'Aggregate 401K Assets', fieldName: 'X401K_Assets__c', type: 'currency'},
];

export default class MutualClientRelatedListTable extends LightningElement {
    @api tableData;
    @api parentRecordId;
    @api parentObjectType;
    refAccountId;
    filter;
    displayVerification;
    accountId;
    columns = columns;
    displaySpinner;
    sortBy;
    sortDirection;
    updatedCPAFullNameId;
    isLoading = false;
    clientName;
    isOwnerOrArmOwner(){
        var result = this.userDetails;
        console.log('result', result);
        return result.data.isOwnerOrARM
    }
    connectedCallback() {
         if(this.parentObjectType === 'Referral_Account__c') {
             this.refAccountId = this.parentRecordId;
         }
         else if (this.parentObjectType === 'Referral_Contact__c') {
                getReferralAccountId({referralContactId : this.parentRecordId})
                .then(data => {
                    if(data) {
                       this.refAccountId = data;
                    }
                });
          }
    }
    @wire(getUserDetalsAndRefOwnereAndARM,{refAccId : '$refAccountId'})
    userDetails;
    generateFilterValue() {
        if(this.parentObjectType === 'Referral_Account__c') {
            this.filter = `Referral_Account__c = '${this.parentRecordId}'`;
            this.refAccountId = this.parentRecordId;
        } else if (this.parentObjectType === 'Referral_Contact__c') {
            getReferralAccountId({referralContactId : this.parentRecordId})
                .then(data => {
                    if(data) {
                        this.filter = `Referral_Account__c = '${data}'`;
                    }
                });
        }
        console.log('filter===>', this.filter);
    }
    handleRemoveCPA(){
        this.isLoading = true;
        removeCPAFromAccount({accountId : this.accountId})
        .then(response=>{
            this.isLoading = false;
            console.log(response);
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
    handleRowAction(event) {
        let actionName = event.detail.action.name;
        let row = event.detail.row;
        try{
              console.log('tuserdetails',this.userDetails);
        // console.log('this.isOwnerOrArmOwner',this.isOwnerOrArmOwner());
        }
        catch(error){
            console.log(error);
        }
        var res = JSON.parse(this.userDetails.data);
        console.log(res.isOwnerOrARM);
        if(!res.isOwnerOrARM){
              this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'You don\'t have the necessary privileges to edit this record.',
                            variant: 'error',
                        })
                    );
                    return;
        }
        switch (actionName) {
            case 'verify':
                processMutualClientRelation({accountId : row.Id})
                .then(() => {

                    this.dispatchEvent(new CustomEvent('verification', {
                        detail: {
                            data: row
                        }
                    }));


                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Verified Successfully !!',
                            variant: 'success',
                        })
                    );
                    

                    
                })
                .catch(error => {
                    console.log('error verifying ==>', error);
                })
                //this.updateVerification(row.Id);
                break;
            case 'update cpa':
                this.generateFilterValue();
                this.displayVerification = true;
                this.accountId = row.Id;
                this.clientName = row.Name;
                //this.updateVerification(row.Id);
                break;
            default:
            //Add code for default behaviour if needed.
        }
    }

    handleVerificationCancel() {
        this.displayVerification = false;
    }


    handleVerificationSave() {
        updateProspectAccount({accountId : this.accountId, cpaFullName: this.updatedCPAFullNameId})
        .then(()=> {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Updated Successfully !!',
                    variant: 'success',
                })
            );
            const cpaNameChangeEvent = new CustomEvent('cpafullnamechange');
            this.dispatchEvent(cpaNameChangeEvent);
        })
        .catch(error => {
            console.log('error updating cpa', JSON.stringify(error))
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Occured while updating !!',
                    message: JSON.stringify(error),
                    variant: 'error',
                })
            );
        });
        this.displayVerification = false;
    }

    handleSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldName, direction) {
        if (fieldName === 'Prospect-Client Name') {
            fieldName = 'Name';
        }
        let parseData = JSON.parse(JSON.stringify(this.tableData));

        let keyValue = a => {
            return a[fieldName];
        }

        let isReverse = direction === 'asc' ? 1 : -1;

        parseData.sort((x, y) => {
            if(!keyValue(x)) {
                return isReverse * -1; 
            }

            if(!keyValue(y)) {
                return isReverse * 1; 
            }
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';

            return isReverse * ((x > y) - (y > x));
        });
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.tableData = parseData;
    }


    handleCPAFullNameChange(event) {
        this.updatedCPAFullNameId = event.detail;
    }

}